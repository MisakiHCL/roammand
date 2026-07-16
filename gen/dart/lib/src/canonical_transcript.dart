// SPDX-License-Identifier: Apache-2.0

import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

enum TranscriptPurpose {
  pairingSas(1),
  sessionOffer(2),
  sessionAnswer(3),
  sessionReconnect(4);

  const TranscriptPurpose(this.code);

  final int code;

  static TranscriptPurpose fromCode(int code) {
    for (final purpose in values) {
      if (purpose.code == code) {
        return purpose;
      }
    }
    throw TranscriptException(TranscriptErrorCode.unknownPurpose);
  }
}

enum TranscriptErrorCode {
  badMagic('bad_magic'),
  unknownVersion('unknown_version'),
  unknownPurpose('unknown_purpose'),
  tooManyFields('too_many_fields'),
  duplicateField('duplicate_field'),
  fieldOrder('field_order'),
  fieldTooLong('field_too_long'),
  transcriptTooLong('transcript_too_long'),
  missingField('missing_field'),
  unexpectedField('unexpected_field'),
  invalidFieldLength('invalid_field_length'),
  trailingBytes('trailing_bytes'),
  truncated('truncated');

  const TranscriptErrorCode(this.wireName);

  final String wireName;
}

final class TranscriptException implements Exception {
  const TranscriptException(this.code);

  final TranscriptErrorCode code;

  @override
  String toString() => 'TranscriptException(${code.wireName})';
}

final class TranscriptField {
  TranscriptField(this.tag, List<int> value)
    : _value = Uint8List.fromList(value);

  final int tag;
  final Uint8List _value;

  Uint8List get value => Uint8List.fromList(_value);
}

final class CanonicalTranscript {
  CanonicalTranscript(this.purpose, Iterable<TranscriptField> fields)
    : fields = List<TranscriptField>.unmodifiable(fields);

  final TranscriptPurpose purpose;
  final List<TranscriptField> fields;
}

abstract final class CanonicalTranscriptV1 {
  static const _magic = <int>[0x50, 0x52, 0x44, 0x54];
  static const _version = 1;
  static const _headerLength = 10;
  static const _fieldHeaderLength = 6;
  static const _maxFields = 16;
  static const _maxFieldLength = 1024;
  static const _maxTranscriptLength = 4096;

  static const _requiredTags = <TranscriptPurpose, List<int>>{
    TranscriptPurpose.pairingSas: [1, 2, 3, 4, 5, 6, 7],
    TranscriptPurpose.sessionOffer: [1, 2, 8, 9, 10, 11, 12, 13, 14],
    TranscriptPurpose.sessionAnswer: [1, 2, 8, 9, 10, 11, 12, 13, 14, 15, 16],
    TranscriptPurpose.sessionReconnect: [
      1,
      2,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
    ],
  };

  static const _fieldLengths = <int, int>{
    1: 32,
    2: 32,
    3: 16,
    4: 32,
    5: 32,
    6: 32,
    7: 32,
    8: 16,
    9: 32,
    10: 8,
    11: 8,
    12: 4,
    13: 32,
    14: 32,
    15: 32,
    16: 32,
    17: 4,
  };

  static Uint8List encode(
    TranscriptPurpose purpose,
    List<TranscriptField> fields,
  ) {
    _validateFields(purpose, fields);
    final encodedLength = fields.fold<int>(
      _headerLength,
      (length, field) => length + _fieldHeaderLength + field._value.length,
    );
    if (encodedLength > _maxTranscriptLength) {
      throw const TranscriptException(TranscriptErrorCode.transcriptTooLong);
    }

    final output = BytesBuilder(copy: false)
      ..add(_magic)
      ..add(_uint16(_version))
      ..add(_uint16(purpose.code))
      ..add(_uint16(fields.length));
    for (final field in fields) {
      output
        ..add(_uint16(field.tag))
        ..add(_uint32(field._value.length))
        ..add(field._value);
    }
    return output.takeBytes();
  }

  static CanonicalTranscript decode(Uint8List encoded) {
    if (encoded.length > _maxTranscriptLength) {
      throw const TranscriptException(TranscriptErrorCode.transcriptTooLong);
    }

    var offset = 0;
    void requireBytes(int count) {
      if (offset + count > encoded.length) {
        throw const TranscriptException(TranscriptErrorCode.truncated);
      }
    }

    int readUint16() {
      requireBytes(2);
      final value = ByteData.sublistView(encoded).getUint16(offset, Endian.big);
      offset += 2;
      return value;
    }

    int readUint32() {
      requireBytes(4);
      final value = ByteData.sublistView(encoded).getUint32(offset, Endian.big);
      offset += 4;
      return value;
    }

    requireBytes(_magic.length);
    for (final byte in _magic) {
      if (encoded[offset++] != byte) {
        throw const TranscriptException(TranscriptErrorCode.badMagic);
      }
    }

    if (readUint16() != _version) {
      throw const TranscriptException(TranscriptErrorCode.unknownVersion);
    }
    final purpose = TranscriptPurpose.fromCode(readUint16());
    final fieldCount = readUint16();
    if (fieldCount > _maxFields) {
      throw const TranscriptException(TranscriptErrorCode.tooManyFields);
    }

    final fields = <TranscriptField>[];
    var previousTag = -1;
    for (var index = 0; index < fieldCount; index++) {
      final tag = readUint16();
      if (tag == previousTag) {
        throw const TranscriptException(TranscriptErrorCode.duplicateField);
      }
      if (tag < previousTag) {
        throw const TranscriptException(TranscriptErrorCode.fieldOrder);
      }
      previousTag = tag;

      final length = readUint32();
      if (length > _maxFieldLength) {
        throw const TranscriptException(TranscriptErrorCode.fieldTooLong);
      }
      requireBytes(length);
      fields.add(
        TranscriptField(tag, encoded.sublist(offset, offset + length)),
      );
      offset += length;
    }

    if (offset != encoded.length) {
      throw const TranscriptException(TranscriptErrorCode.trailingBytes);
    }
    _validateFields(purpose, fields);
    return CanonicalTranscript(purpose, fields);
  }

  static Uint8List sha256(Uint8List encoded) =>
      Uint8List.fromList(crypto.sha256.convert(encoded).bytes);

  static void _validateFields(
    TranscriptPurpose purpose,
    List<TranscriptField> fields,
  ) {
    if (fields.length > _maxFields) {
      throw const TranscriptException(TranscriptErrorCode.tooManyFields);
    }

    final requiredTags = _requiredTags[purpose]!;
    var previousTag = -1;
    for (final field in fields) {
      if (field.tag == previousTag) {
        throw const TranscriptException(TranscriptErrorCode.duplicateField);
      }
      if (field.tag < previousTag) {
        throw const TranscriptException(TranscriptErrorCode.fieldOrder);
      }
      previousTag = field.tag;

      if (field._value.length > _maxFieldLength) {
        throw const TranscriptException(TranscriptErrorCode.fieldTooLong);
      }
      if (!requiredTags.contains(field.tag)) {
        throw const TranscriptException(TranscriptErrorCode.unexpectedField);
      }
      if (field._value.length != _fieldLengths[field.tag]) {
        throw const TranscriptException(TranscriptErrorCode.invalidFieldLength);
      }
    }

    if (fields.length < requiredTags.length) {
      throw const TranscriptException(TranscriptErrorCode.missingField);
    }
    if (fields.length > requiredTags.length) {
      throw const TranscriptException(TranscriptErrorCode.unexpectedField);
    }
    for (var index = 0; index < requiredTags.length; index++) {
      if (fields[index].tag != requiredTags[index]) {
        throw const TranscriptException(TranscriptErrorCode.missingField);
      }
    }
  }

  static Uint8List _uint16(int value) {
    final bytes = ByteData(2)..setUint16(0, value, Endian.big);
    return bytes.buffer.asUint8List();
  }

  static Uint8List _uint32(int value) {
    final bytes = ByteData(4)..setUint32(0, value, Endian.big);
    return bytes.buffer.asUint8List();
  }
}
