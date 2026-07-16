// SPDX-License-Identifier: Apache-2.0

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

// Protocol V1 domain; changing it would rotate every existing device ID.
const _identityDerivationDomain = 'personal-remote-device-id-v1';
const _ed25519Algorithm = 1;
const _ed25519PublicKeyBytes = 32;

Uint8List deriveDeviceIdV1(List<int> publicKey) {
  if (publicKey.length != _ed25519PublicKeyBytes) {
    throw ArgumentError.value(
      publicKey.length,
      'publicKey.length',
      'Ed25519 public keys must contain exactly 32 bytes',
    );
  }

  final input = <int>[
    ...utf8.encode(_identityDerivationDomain),
    0,
    0,
    _ed25519Algorithm,
    ...publicKey,
  ];
  return Uint8List.fromList(crypto.sha256.convert(input).bytes);
}
