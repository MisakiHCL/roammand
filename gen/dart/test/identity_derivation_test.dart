// SPDX-License-Identifier: Apache-2.0

import 'dart:convert';
import 'dart:io';

import 'package:roammand_protocol/roammand_protocol.dart';
import 'package:test/test.dart';

void main() {
  test('Identity Derivation V1 matches every golden vector', () {
    final fixture =
        jsonDecode(
              File(
                '../../conformance/protocol_vectors/identity_derivation_v1.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;

    for (final entry in fixture['cases'] as List<dynamic>) {
      final vector = entry as Map<String, dynamic>;
      expect(
        _hexEncode(
          deriveDeviceIdV1(_hexDecode(vector['public_key_hex'] as String)),
        ),
        vector['expected_device_id_hex'],
        reason: vector['name'] as String,
      );
    }
  });

  test('Identity Derivation V1 rejects non-Ed25519 key lengths', () {
    expect(
      () => deriveDeviceIdV1(List<int>.filled(31, 0)),
      throwsArgumentError,
    );
    expect(
      () => deriveDeviceIdV1(List<int>.filled(33, 0)),
      throwsArgumentError,
    );
  });
}

List<int> _hexDecode(String value) => [
  for (var offset = 0; offset < value.length; offset += 2)
    int.parse(value.substring(offset, offset + 2), radix: 16),
];

String _hexEncode(List<int> value) =>
    value.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
