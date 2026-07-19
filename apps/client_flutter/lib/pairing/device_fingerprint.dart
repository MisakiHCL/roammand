// SPDX-License-Identifier: MPL-2.0

import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:roammand_protocol/roammand_protocol.dart';

const shortDeviceFingerprintBytes = 8;
const _emptyFingerprint = '—';
const _fingerprintSeparator = ' ';

Uint8List computeDevicePublicKeyFingerprintSha256(DeviceIdentity identity) =>
    Uint8List.fromList(crypto.sha256.convert(identity.publicKey).bytes);

/// Formats a short device fingerprint consistently on every platform.
String formatShortDeviceFingerprint(List<int> fingerprint) {
  final visible = fingerprint.take(shortDeviceFingerprintBytes);
  if (visible.isEmpty) return _emptyFingerprint;
  return visible
      .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join(_fingerprintSeparator);
}
