// SPDX-License-Identifier: Apache-2.0

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'protocol_limits.dart';

const _pairingAadMagic = <int>[0x50, 0x52, 0x44, 0x50];
const _pairingCryptoVersion = 1;
const _aesGcmTagBytes = 16;
const _maximumSequence = 0x7fffffffffffffff;
// Protocol V1 domains remain stable so existing grants can still pair.
const _controllerToHostInfo =
    'personal-remote-desktop/pairing/v1/controller-to-host';
const _hostToControllerInfo =
    'personal-remote-desktop/pairing/v1/host-to-controller';

enum PairingCryptoDirection {
  controllerToHost(1, <int>[0x43, 0x32, 0x48, 0x01]),
  hostToController(2, <int>[0x48, 0x32, 0x43, 0x01]);

  const PairingCryptoDirection(this.code, this.noncePrefix);

  final int code;
  final List<int> noncePrefix;
}

enum PairingCryptoErrorCode {
  invalidLength,
  invalidSequence,
  invalidPublicKey,
  invalidWordList,
  authenticationFailed,
}

final class PairingCryptoException implements Exception {
  const PairingCryptoException(this.code);

  final PairingCryptoErrorCode code;

  @override
  String toString() => 'PairingCryptoException(${code.name})';
}

final class PairingKeySchedule {
  PairingKeySchedule(List<int> controllerToHost, List<int> hostToController)
    : controllerToHost = Uint8List.fromList(controllerToHost),
      hostToController = Uint8List.fromList(hostToController);

  final Uint8List controllerToHost;
  final Uint8List hostToController;
}

final class PairingSequenceValidator {
  int _next = 1;
  bool _exhausted = false;

  int get next => _next;

  void accept(int sequence) {
    if (_exhausted || sequence != _next || sequence > _maximumSequence) {
      throw const PairingCryptoException(
        PairingCryptoErrorCode.invalidSequence,
      );
    }
    if (sequence == _maximumSequence) {
      _exhausted = true;
    } else {
      _next += 1;
    }
  }
}

Future<Uint8List> x25519PublicKey(Uint8List privateKey) async {
  _requireLength(privateKey, publicKeyBytes);
  final keyPair = await X25519().newKeyPairFromSeed(privateKey);
  final publicKey = await keyPair.extractPublicKey();
  return Uint8List.fromList(publicKey.bytes);
}

Future<Uint8List> x25519SharedSecret(
  Uint8List privateKey,
  Uint8List remotePublicKey,
) async {
  _requireLength(privateKey, publicKeyBytes);
  _requireLength(remotePublicKey, publicKeyBytes);
  try {
    final algorithm = X25519();
    final keyPair = await algorithm.newKeyPairFromSeed(privateKey);
    final shared = await algorithm.sharedSecretKey(
      keyPair: keyPair,
      remotePublicKey: SimplePublicKey(
        remotePublicKey,
        type: KeyPairType.x25519,
      ),
    );
    final bytes = Uint8List.fromList(await shared.extractBytes());
    if (bytes.every((byte) => byte == 0)) {
      throw const PairingCryptoException(
        PairingCryptoErrorCode.invalidPublicKey,
      );
    }
    return bytes;
  } on PairingCryptoException {
    rethrow;
  } on Exception {
    throw const PairingCryptoException(PairingCryptoErrorCode.invalidPublicKey);
  }
}

List<int> pairingSasIndexes(Uint8List transcriptSha256) {
  _requireLength(transcriptSha256, nonceOrHashBytes);
  return List<int>.unmodifiable(<int>[
    (transcriptSha256[0] << 3) | (transcriptSha256[1] >> 5),
    ((transcriptSha256[1] & 0x1f) << 6) | (transcriptSha256[2] >> 2),
    ((transcriptSha256[2] & 0x03) << 9) |
        (transcriptSha256[3] << 1) |
        (transcriptSha256[4] >> 7),
    ((transcriptSha256[4] & 0x7f) << 4) | (transcriptSha256[5] >> 4),
  ]);
}

List<String> pairingSasWords(
  Uint8List transcriptSha256,
  List<String> wordList,
) {
  if (wordList.length != 2048 ||
      wordList.any(
        (word) =>
            word.isEmpty ||
            word.length > 8 ||
            !RegExp(r'^[a-z]+$').hasMatch(word),
      )) {
    throw const PairingCryptoException(PairingCryptoErrorCode.invalidWordList);
  }
  return List<String>.unmodifiable(
    pairingSasIndexes(transcriptSha256).map((index) => wordList[index]),
  );
}

Future<PairingKeySchedule> derivePairingKeys(
  Uint8List sharedSecret,
  Uint8List transcriptSha256,
) async {
  _requireLength(sharedSecret, publicKeyBytes);
  _requireLength(transcriptSha256, nonceOrHashBytes);
  if (sharedSecret.every((byte) => byte == 0)) {
    throw const PairingCryptoException(PairingCryptoErrorCode.invalidPublicKey);
  }
  final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  Future<Uint8List> derive(String info) async => Uint8List.fromList(
    await (await hkdf.deriveKey(
      secretKey: SecretKey(sharedSecret),
      nonce: transcriptSha256,
      info: utf8.encode(info),
    )).extractBytes(),
  );

  return PairingKeySchedule(
    await derive(_controllerToHostInfo),
    await derive(_hostToControllerInfo),
  );
}

Uint8List pairingNonce(PairingCryptoDirection direction, int sequence) {
  if (sequence <= 0 || sequence > _maximumSequence) {
    throw const PairingCryptoException(PairingCryptoErrorCode.invalidSequence);
  }
  final bytes = Uint8List(12)..setRange(0, 4, direction.noncePrefix);
  ByteData.sublistView(bytes).setUint64(4, sequence, Endian.big);
  return bytes;
}

Uint8List pairingAad({
  required PairingCryptoDirection direction,
  required int sequence,
  required Uint8List rendezvousId,
  required Uint8List controllerDeviceId,
  required Uint8List hostDeviceId,
}) {
  _requireLength(rendezvousId, rendezvousIdBytes);
  _requireLength(controllerDeviceId, deviceIdBytes);
  _requireLength(hostDeviceId, deviceIdBytes);
  pairingNonce(direction, sequence);
  final header = ByteData(11)
    ..setUint16(0, _pairingCryptoVersion, Endian.big)
    ..setUint8(2, direction.code)
    ..setUint64(3, sequence, Endian.big);
  return (BytesBuilder(copy: false)
        ..add(_pairingAadMagic)
        ..add(header.buffer.asUint8List())
        ..add(rendezvousId)
        ..add(controllerDeviceId)
        ..add(hostDeviceId))
      .takeBytes();
}

Future<Uint8List> sealPairingPayload({
  required Uint8List key,
  required PairingCryptoDirection direction,
  required int sequence,
  required Uint8List aad,
  required Uint8List plaintext,
}) async {
  _requireLength(key, 32);
  if (plaintext.length > maxPairingCiphertextBytes - _aesGcmTagBytes) {
    throw const PairingCryptoException(PairingCryptoErrorCode.invalidLength);
  }
  final box = await AesGcm.with256bits().encrypt(
    plaintext,
    secretKey: SecretKey(key),
    nonce: pairingNonce(direction, sequence),
    aad: aad,
  );
  return Uint8List.fromList(<int>[...box.cipherText, ...box.mac.bytes]);
}

Future<Uint8List> openPairingPayload({
  required Uint8List key,
  required PairingCryptoDirection direction,
  required int sequence,
  required Uint8List aad,
  required Uint8List ciphertextAndTag,
}) async {
  _requireLength(key, 32);
  if (ciphertextAndTag.length < _aesGcmTagBytes ||
      ciphertextAndTag.length > maxPairingCiphertextBytes) {
    throw const PairingCryptoException(PairingCryptoErrorCode.invalidLength);
  }
  final split = ciphertextAndTag.length - _aesGcmTagBytes;
  try {
    return Uint8List.fromList(
      await AesGcm.with256bits().decrypt(
        SecretBox(
          ciphertextAndTag.sublist(0, split),
          nonce: pairingNonce(direction, sequence),
          mac: Mac(ciphertextAndTag.sublist(split)),
        ),
        secretKey: SecretKey(key),
        aad: aad,
      ),
    );
  } on SecretBoxAuthenticationError {
    throw const PairingCryptoException(
      PairingCryptoErrorCode.authenticationFailed,
    );
  }
}

void _requireLength(List<int> value, int expected) {
  if (value.length != expected) {
    throw const PairingCryptoException(PairingCryptoErrorCode.invalidLength);
  }
}
