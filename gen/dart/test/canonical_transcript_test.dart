// SPDX-License-Identifier: Apache-2.0

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:roammand_protocol/roammand_protocol.dart';
import 'package:test/test.dart';

void main() {
  test('all Canonical Transcript V1 golden cases match', () {
    final fixture = _loadFixture('canonical_transcript_v1.json');
    final values = (fixture['values'] as Map<String, dynamic>).map(
      (tag, value) => MapEntry(int.parse(tag), _hexDecode(value as String)),
    );

    for (final entry in fixture['cases'] as List<dynamic>) {
      final vector = entry as Map<String, dynamic>;
      final purpose = TranscriptPurpose.fromCode(vector['purpose'] as int);
      final fields = (vector['tags'] as List<dynamic>)
          .map((tag) => tag as int)
          .map((tag) => TranscriptField(tag, values[tag]!))
          .toList();

      final encoded = CanonicalTranscriptV1.encode(purpose, fields);
      expect(_hexEncode(encoded), vector['expected_transcript_hex']);
      expect(
        _hexEncode(CanonicalTranscriptV1.sha256(encoded)),
        vector['expected_sha256_hex'],
      );

      final decoded = CanonicalTranscriptV1.decode(encoded);
      expect(decoded.purpose, purpose);
      expect(decoded.fields.map((field) => field.tag), vector['tags']);
      for (final field in decoded.fields) {
        expect(field.value, values[field.tag]);
      }
    }
  });

  test('all invalid Canonical Transcript V1 cases return stable errors', () {
    final fixture = _loadFixture('canonical_transcript_v1_invalid.json');

    for (final entry in fixture['cases'] as List<dynamic>) {
      final vector = entry as Map<String, dynamic>;
      final bytes = vector.containsKey('repeat_hex')
          ? _repeatHex(
              vector['repeat_hex'] as String,
              vector['repeat_count'] as int,
            )
          : _hexDecode(vector['transcript_hex'] as String);

      expect(
        () => CanonicalTranscriptV1.decode(bytes),
        throwsA(
          isA<TranscriptException>().having(
            (error) => error.code.wireName,
            'code',
            vector['expected_error'],
          ),
        ),
        reason: vector['name'] as String,
      );
    }
  });

  test('every non-increasing adjacent pairing tag is rejected', () {
    final fixture = _loadFixture('canonical_transcript_v1.json');
    final pairing = (fixture['cases'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .singleWhere((vector) => vector['name'] == 'pairing_sas');
    final encoded = _hexDecode(pairing['expected_transcript_hex'] as String);
    final tagOffsets = _tagOffsets(encoded);

    for (var index = 1; index < tagOffsets.length; index++) {
      final previousTag = ByteData.sublistView(
        encoded,
      ).getUint16(tagOffsets[index - 1], Endian.big);
      for (final mutation in <(int, TranscriptErrorCode)>[
        (previousTag, TranscriptErrorCode.duplicateField),
        (previousTag - 1, TranscriptErrorCode.fieldOrder),
      ]) {
        final mutated = Uint8List.fromList(encoded);
        ByteData.sublistView(
          mutated,
        ).setUint16(tagOffsets[index], mutation.$1, Endian.big);

        expect(
          () => CanonicalTranscriptV1.decode(mutated),
          throwsA(
            isA<TranscriptException>().having(
              (error) => error.code,
              'code',
              mutation.$2,
            ),
          ),
          reason: 'adjacent tag index $index with ${mutation.$2.wireName}',
        );
      }
    }
  });
}

Map<String, dynamic> _loadFixture(String name) {
  final file = File('../../conformance/protocol_vectors/$name');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

Uint8List _hexDecode(String value) {
  if (value.length.isOdd) {
    throw FormatException('hex value must contain complete bytes');
  }
  return Uint8List.fromList([
    for (var offset = 0; offset < value.length; offset += 2)
      int.parse(value.substring(offset, offset + 2), radix: 16),
  ]);
}

String _hexEncode(List<int> value) =>
    value.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

Uint8List _repeatHex(String value, int count) {
  final bytes = _hexDecode(value);
  return Uint8List.fromList([
    for (var index = 0; index < count; index++) ...bytes,
  ]);
}

List<int> _tagOffsets(Uint8List encoded) {
  const headerLength = 10;
  const fieldHeaderLength = 6;
  final data = ByteData.sublistView(encoded);
  final fieldCount = data.getUint16(8, Endian.big);
  final offsets = <int>[];
  var offset = headerLength;
  for (var index = 0; index < fieldCount; index++) {
    offsets.add(offset);
    final length = data.getUint32(offset + 2, Endian.big);
    offset += fieldHeaderLength + length;
  }
  return offsets;
}
