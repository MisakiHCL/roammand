// SPDX-License-Identifier: Apache-2.0

package canonical

import (
	"crypto/sha256"
	"encoding/binary"
)

const (
	transcriptMagic     = "PRDT"
	transcriptVersion   = uint16(1)
	headerLength        = 10
	fieldHeaderLength   = 6
	maxFields           = 16
	maxFieldLength      = 1024
	maxTranscriptLength = 4096
)

type Purpose uint16

const (
	PurposePairingSAS       Purpose = 1
	PurposeSessionOffer     Purpose = 2
	PurposeSessionAnswer    Purpose = 3
	PurposeSessionReconnect Purpose = 4
)

type Field struct {
	Tag   uint16
	Value []byte
}

type Transcript struct {
	Purpose Purpose
	Fields  []Field
}

type ErrorCode string

const (
	ErrorBadMagic          ErrorCode = "bad_magic"
	ErrorUnknownVersion    ErrorCode = "unknown_version"
	ErrorUnknownPurpose    ErrorCode = "unknown_purpose"
	ErrorTooManyFields     ErrorCode = "too_many_fields"
	ErrorDuplicateField    ErrorCode = "duplicate_field"
	ErrorFieldOrder        ErrorCode = "field_order"
	ErrorFieldTooLong      ErrorCode = "field_too_long"
	ErrorTranscriptTooLong ErrorCode = "transcript_too_long"
	ErrorUnexpectedField   ErrorCode = "unexpected_field"
	ErrorMissingField      ErrorCode = "missing_field"
	ErrorInvalidFieldLen   ErrorCode = "invalid_field_length"
	ErrorTrailingBytes     ErrorCode = "trailing_bytes"
	ErrorTruncated         ErrorCode = "truncated"
)

type TranscriptError struct {
	Code ErrorCode
}

func (e *TranscriptError) Error() string {
	return "canonical transcript: " + string(e.Code)
}

func Encode(transcript Transcript) ([]byte, error) {
	if err := validateFields(transcript.Purpose, transcript.Fields); err != nil {
		return nil, err
	}

	encodedLength := headerLength
	for _, field := range transcript.Fields {
		encodedLength += fieldHeaderLength + len(field.Value)
	}
	if encodedLength > maxTranscriptLength {
		return nil, newError(ErrorTranscriptTooLong)
	}

	output := make([]byte, 0, encodedLength)
	output = append(output, transcriptMagic...)
	output = binary.BigEndian.AppendUint16(output, transcriptVersion)
	output = binary.BigEndian.AppendUint16(output, uint16(transcript.Purpose))
	output = binary.BigEndian.AppendUint16(output, uint16(len(transcript.Fields)))
	for _, field := range transcript.Fields {
		output = binary.BigEndian.AppendUint16(output, field.Tag)
		output = binary.BigEndian.AppendUint32(output, uint32(len(field.Value)))
		output = append(output, field.Value...)
	}
	return output, nil
}

func Decode(encoded []byte) (Transcript, error) {
	if len(encoded) > maxTranscriptLength {
		return Transcript{}, newError(ErrorTranscriptTooLong)
	}

	reader := transcriptReader{encoded: encoded}
	magic, err := reader.read(len(transcriptMagic))
	if err != nil {
		return Transcript{}, err
	}
	if string(magic) != transcriptMagic {
		return Transcript{}, newError(ErrorBadMagic)
	}
	version, err := reader.readUint16()
	if err != nil {
		return Transcript{}, err
	}
	if version != transcriptVersion {
		return Transcript{}, newError(ErrorUnknownVersion)
	}
	purposeValue, err := reader.readUint16()
	if err != nil {
		return Transcript{}, err
	}
	purpose := Purpose(purposeValue)
	if _, ok := tagsForPurpose(purpose); !ok {
		return Transcript{}, newError(ErrorUnknownPurpose)
	}
	fieldCount, err := reader.readUint16()
	if err != nil {
		return Transcript{}, err
	}
	if fieldCount > maxFields {
		return Transcript{}, newError(ErrorTooManyFields)
	}

	fields := make([]Field, 0, fieldCount)
	var previousTag uint16
	hasPreviousTag := false
	for range fieldCount {
		tag, err := reader.readUint16()
		if err != nil {
			return Transcript{}, err
		}
		if hasPreviousTag && tag == previousTag {
			return Transcript{}, newError(ErrorDuplicateField)
		}
		if hasPreviousTag && tag < previousTag {
			return Transcript{}, newError(ErrorFieldOrder)
		}
		previousTag = tag
		hasPreviousTag = true

		length, err := reader.readUint32()
		if err != nil {
			return Transcript{}, err
		}
		if length > maxFieldLength {
			return Transcript{}, newError(ErrorFieldTooLong)
		}
		value, err := reader.read(int(length))
		if err != nil {
			return Transcript{}, err
		}
		fields = append(fields, Field{Tag: tag, Value: append([]byte(nil), value...)})
	}

	if !reader.finished() {
		return Transcript{}, newError(ErrorTrailingBytes)
	}
	if err := validateFields(purpose, fields); err != nil {
		return Transcript{}, err
	}
	return Transcript{Purpose: purpose, Fields: fields}, nil
}

func SHA256(encoded []byte) [32]byte {
	return sha256.Sum256(encoded)
}

func validateFields(purpose Purpose, fields []Field) error {
	requiredTags, ok := tagsForPurpose(purpose)
	if !ok {
		return newError(ErrorUnknownPurpose)
	}
	if len(fields) > maxFields {
		return newError(ErrorTooManyFields)
	}

	var previousTag uint16
	hasPreviousTag := false
	for _, field := range fields {
		if hasPreviousTag && field.Tag == previousTag {
			return newError(ErrorDuplicateField)
		}
		if hasPreviousTag && field.Tag < previousTag {
			return newError(ErrorFieldOrder)
		}
		previousTag = field.Tag
		hasPreviousTag = true

		if len(field.Value) > maxFieldLength {
			return newError(ErrorFieldTooLong)
		}
		if !containsTag(requiredTags, field.Tag) {
			return newError(ErrorUnexpectedField)
		}
		if len(field.Value) != lengthForTag(field.Tag) {
			return newError(ErrorInvalidFieldLen)
		}
	}

	if len(fields) < len(requiredTags) {
		return newError(ErrorMissingField)
	}
	if len(fields) > len(requiredTags) {
		return newError(ErrorUnexpectedField)
	}
	for index, tag := range requiredTags {
		if fields[index].Tag != tag {
			return newError(ErrorMissingField)
		}
	}
	return nil
}

func tagsForPurpose(purpose Purpose) ([]uint16, bool) {
	switch purpose {
	case PurposePairingSAS:
		return []uint16{1, 2, 3, 4, 5, 6, 7}, true
	case PurposeSessionOffer:
		return []uint16{1, 2, 8, 9, 10, 11, 12, 13, 14}, true
	case PurposeSessionAnswer:
		return []uint16{1, 2, 8, 9, 10, 11, 12, 13, 14, 15, 16}, true
	case PurposeSessionReconnect:
		return []uint16{1, 2, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17}, true
	default:
		return nil, false
	}
}

func containsTag(tags []uint16, candidate uint16) bool {
	for _, tag := range tags {
		if tag == candidate {
			return true
		}
	}
	return false
}

func lengthForTag(tag uint16) int {
	switch tag {
	case 3, 8:
		return 16
	case 10, 11:
		return 8
	case 12, 17:
		return 4
	default:
		return 32
	}
}

func newError(code ErrorCode) error {
	return &TranscriptError{Code: code}
}

type transcriptReader struct {
	encoded []byte
	offset  int
}

func (r *transcriptReader) readUint16() (uint16, error) {
	value, err := r.read(2)
	if err != nil {
		return 0, err
	}
	return binary.BigEndian.Uint16(value), nil
}

func (r *transcriptReader) readUint32() (uint32, error) {
	value, err := r.read(4)
	if err != nil {
		return 0, err
	}
	return binary.BigEndian.Uint32(value), nil
}

func (r *transcriptReader) read(length int) ([]byte, error) {
	if length < 0 || length > len(r.encoded)-r.offset {
		return nil, newError(ErrorTruncated)
	}
	value := r.encoded[r.offset : r.offset+length]
	r.offset += length
	return value, nil
}

func (r *transcriptReader) finished() bool {
	return r.offset == len(r.encoded)
}
