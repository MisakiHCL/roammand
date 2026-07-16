// SPDX-License-Identifier: Apache-2.0

package pairing

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/ecdh"
	"crypto/hkdf"
	"crypto/sha256"
	"encoding/binary"
	"errors"
)

const (
	digestBytes               = 32
	deviceIDBytes             = 32
	rendezvousIDBytes         = 16
	aesGCMTagBytes            = 16
	maxPairingCiphertextBytes = 65_536
	wordListLength            = 2_048
	pairingCryptoVersion      = uint16(1)
	maxPairingSequence        = uint64(1<<63 - 1)
	// Protocol V1 domains remain stable so existing grants can still pair.
	controllerToHostInfo = "personal-remote-desktop/pairing/v1/controller-to-host"
	hostToControllerInfo = "personal-remote-desktop/pairing/v1/host-to-controller"
)

var (
	ErrInvalidLength       = errors.New("pairing crypto length is invalid")
	ErrInvalidSequence     = errors.New("pairing crypto sequence is invalid")
	ErrInvalidDirection    = errors.New("pairing crypto direction is invalid")
	ErrInvalidPublicKey    = errors.New("pairing X25519 public key is invalid")
	ErrInvalidWordList     = errors.New("pairing SAS word list is invalid")
	ErrAuthentication      = errors.New("pairing payload authentication failed")
	pairingAADMagic        = [4]byte{'P', 'R', 'D', 'P'}
	controllerToHostPrefix = [4]byte{'C', '2', 'H', 1}
	hostToControllerPrefix = [4]byte{'H', '2', 'C', 1}
)

type Direction uint8

const (
	DirectionControllerToHost Direction = 1
	DirectionHostToController Direction = 2
)

type KeySchedule struct {
	ControllerToHost [32]byte
	HostToController [32]byte
}

type SequenceValidator struct {
	next      uint64
	exhausted bool
}

func NewSequenceValidator() *SequenceValidator {
	return &SequenceValidator{next: 1}
}

func (v *SequenceValidator) Next() uint64 {
	return v.next
}

func (v *SequenceValidator) Accept(sequence uint64) error {
	if v == nil || v.exhausted || sequence != v.next || sequence > maxPairingSequence {
		return ErrInvalidSequence
	}
	if sequence == maxPairingSequence {
		v.exhausted = true
	} else {
		v.next++
	}
	return nil
}

func X25519PublicKey(privateKey []byte) ([]byte, error) {
	if len(privateKey) != digestBytes {
		return nil, ErrInvalidLength
	}
	key, err := ecdh.X25519().NewPrivateKey(privateKey)
	if err != nil {
		return nil, ErrInvalidLength
	}
	return append([]byte(nil), key.PublicKey().Bytes()...), nil
}

func X25519SharedSecret(privateKey, remotePublicKey []byte) ([]byte, error) {
	if len(privateKey) != digestBytes || len(remotePublicKey) != digestBytes {
		return nil, ErrInvalidLength
	}
	curve := ecdh.X25519()
	private, err := curve.NewPrivateKey(privateKey)
	if err != nil {
		return nil, ErrInvalidLength
	}
	public, err := curve.NewPublicKey(remotePublicKey)
	if err != nil {
		return nil, ErrInvalidLength
	}
	shared, err := private.ECDH(public)
	if err != nil {
		return nil, ErrInvalidPublicKey
	}
	allZero := true
	for _, value := range shared {
		allZero = allZero && value == 0
	}
	if allZero {
		return nil, ErrInvalidPublicKey
	}
	return shared, nil
}

func SASIndexes(transcriptSHA256 []byte) ([4]uint16, error) {
	if len(transcriptSHA256) != digestBytes {
		return [4]uint16{}, ErrInvalidLength
	}
	return [4]uint16{
		uint16(transcriptSHA256[0])<<3 | uint16(transcriptSHA256[1]>>5),
		uint16(transcriptSHA256[1]&0x1f)<<6 | uint16(transcriptSHA256[2]>>2),
		uint16(transcriptSHA256[2]&0x03)<<9 | uint16(transcriptSHA256[3])<<1 | uint16(transcriptSHA256[4]>>7),
		uint16(transcriptSHA256[4]&0x7f)<<4 | uint16(transcriptSHA256[5]>>4),
	}, nil
}

func SASWords(transcriptSHA256 []byte, wordList []string) ([4]string, error) {
	if len(wordList) != wordListLength {
		return [4]string{}, ErrInvalidWordList
	}
	for _, word := range wordList {
		if len(word) == 0 || len(word) > 8 {
			return [4]string{}, ErrInvalidWordList
		}
		for _, character := range []byte(word) {
			if character < 'a' || character > 'z' {
				return [4]string{}, ErrInvalidWordList
			}
		}
	}
	indexes, err := SASIndexes(transcriptSHA256)
	if err != nil {
		return [4]string{}, err
	}
	return [4]string{
		wordList[indexes[0]],
		wordList[indexes[1]],
		wordList[indexes[2]],
		wordList[indexes[3]],
	}, nil
}

func DeriveKeys(sharedSecret, transcriptSHA256 []byte) (KeySchedule, error) {
	if len(sharedSecret) != digestBytes || len(transcriptSHA256) != digestBytes {
		return KeySchedule{}, ErrInvalidLength
	}
	allZero := true
	for _, value := range sharedSecret {
		allZero = allZero && value == 0
	}
	if allZero {
		return KeySchedule{}, ErrInvalidPublicKey
	}
	controller, err := hkdf.Key(sha256.New, sharedSecret, transcriptSHA256, controllerToHostInfo, 32)
	if err != nil {
		return KeySchedule{}, err
	}
	host, err := hkdf.Key(sha256.New, sharedSecret, transcriptSHA256, hostToControllerInfo, 32)
	if err != nil {
		return KeySchedule{}, err
	}
	var schedule KeySchedule
	copy(schedule.ControllerToHost[:], controller)
	copy(schedule.HostToController[:], host)
	return schedule, nil
}

func Nonce(direction Direction, sequence uint64) ([12]byte, error) {
	if sequence == 0 || sequence > maxPairingSequence {
		return [12]byte{}, ErrInvalidSequence
	}
	prefix, err := noncePrefix(direction)
	if err != nil {
		return [12]byte{}, err
	}
	var nonce [12]byte
	copy(nonce[:4], prefix[:])
	binary.BigEndian.PutUint64(nonce[4:], sequence)
	return nonce, nil
}

func AAD(direction Direction, sequence uint64, rendezvousID, controllerDeviceID, hostDeviceID []byte) ([]byte, error) {
	if len(rendezvousID) != rendezvousIDBytes || len(controllerDeviceID) != deviceIDBytes || len(hostDeviceID) != deviceIDBytes {
		return nil, ErrInvalidLength
	}
	if _, err := Nonce(direction, sequence); err != nil {
		return nil, err
	}
	aad := make([]byte, 0, 95)
	aad = append(aad, pairingAADMagic[:]...)
	aad = binary.BigEndian.AppendUint16(aad, pairingCryptoVersion)
	aad = append(aad, byte(direction))
	aad = binary.BigEndian.AppendUint64(aad, sequence)
	aad = append(aad, rendezvousID...)
	aad = append(aad, controllerDeviceID...)
	aad = append(aad, hostDeviceID...)
	return aad, nil
}

func Seal(key []byte, direction Direction, sequence uint64, aad, plaintext []byte) ([]byte, error) {
	if len(key) != 32 || len(plaintext) > maxPairingCiphertextBytes-aesGCMTagBytes {
		return nil, ErrInvalidLength
	}
	gcm, err := newGCM(key)
	if err != nil {
		return nil, err
	}
	nonce, err := Nonce(direction, sequence)
	if err != nil {
		return nil, err
	}
	return gcm.Seal(nil, nonce[:], plaintext, aad), nil
}

func Open(key []byte, direction Direction, sequence uint64, aad, ciphertextAndTag []byte) ([]byte, error) {
	if len(key) != 32 || len(ciphertextAndTag) < aesGCMTagBytes || len(ciphertextAndTag) > maxPairingCiphertextBytes {
		return nil, ErrInvalidLength
	}
	gcm, err := newGCM(key)
	if err != nil {
		return nil, err
	}
	nonce, err := Nonce(direction, sequence)
	if err != nil {
		return nil, err
	}
	plaintext, err := gcm.Open(nil, nonce[:], ciphertextAndTag, aad)
	if err != nil {
		return nil, ErrAuthentication
	}
	return plaintext, nil
}

func noncePrefix(direction Direction) ([4]byte, error) {
	switch direction {
	case DirectionControllerToHost:
		return controllerToHostPrefix, nil
	case DirectionHostToController:
		return hostToControllerPrefix, nil
	default:
		return [4]byte{}, ErrInvalidDirection
	}
}

func newGCM(key []byte) (cipher.AEAD, error) {
	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, ErrInvalidLength
	}
	return cipher.NewGCM(block)
}
