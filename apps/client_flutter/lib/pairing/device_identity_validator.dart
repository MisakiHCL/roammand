// SPDX-License-Identifier: MPL-2.0

import 'dart:typed_data';

import 'package:roammand/pairing/device_fingerprint.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

final class DeviceIdentityValidationException implements Exception {
  const DeviceIdentityValidationException();

  @override
  String toString() => 'DeviceIdentityValidationException';
}

void validateDesktopHostIdentity(DeviceIdentity identity) {
  try {
    validateDeviceIdentity(identity);
    if (identity.displayName.isEmpty ||
        !_constantTimeEquals(
          identity.deviceId,
          deriveDeviceIdV1(identity.publicKey),
        ) ||
        (identity.platform != DevicePlatform.DEVICE_PLATFORM_MACOS &&
            identity.platform != DevicePlatform.DEVICE_PLATFORM_WINDOWS)) {
      throw const DeviceIdentityValidationException();
    }
  } on DeviceIdentityValidationException {
    rethrow;
  } catch (_) {
    throw const DeviceIdentityValidationException();
  }
}

Uint8List devicePublicKeyFingerprintSha256(DeviceIdentity identity) {
  validateDesktopHostIdentity(identity);
  return computeDevicePublicKeyFingerprintSha256(identity);
}

void validateHostFingerprint(
  DeviceIdentity identity,
  List<int> expectedFingerprint,
) {
  if (!_constantTimeEquals(
    devicePublicKeyFingerprintSha256(identity),
    expectedFingerprint,
  )) {
    throw const DeviceIdentityValidationException();
  }
}

bool _constantTimeEquals(List<int> left, List<int> right) {
  if (left.length != right.length) {
    return false;
  }
  var difference = 0;
  for (var index = 0; index < left.length; index += 1) {
    difference |= left[index] ^ right[index];
  }
  return difference == 0;
}
