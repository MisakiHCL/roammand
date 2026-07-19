// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/pairing/device_identity_validator.dart';
import 'package:roammand/pairing/device_fingerprint.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

void main() {
  test(
    'desktop Host identity binds device ID, key, platform and fingerprint',
    () {
      final identity = _identity(DevicePlatform.DEVICE_PLATFORM_MACOS);
      final fingerprint = devicePublicKeyFingerprintSha256(identity);

      expect(() => validateDesktopHostIdentity(identity), returnsNormally);
      expect(fingerprint, hasLength(32));
      expect(
        formatShortDeviceFingerprint(fingerprint),
        matches(RegExp(r'^[0-9A-F]{2}( [0-9A-F]{2}){7}$')),
      );
      expect(
        () => validateHostFingerprint(identity, fingerprint),
        returnsNormally,
      );
    },
  );

  test('desktop Host identity rejects substituted fields', () {
    final valid = _identity(DevicePlatform.DEVICE_PLATFORM_WINDOWS);
    final fingerprint = devicePublicKeyFingerprintSha256(valid);
    for (final identity in <DeviceIdentity>[
      valid.deepCopy()..deviceId[0] ^= 1,
      valid.deepCopy()..publicKey.removeLast(),
      valid.deepCopy()..platform = DevicePlatform.DEVICE_PLATFORM_ANDROID,
      valid.deepCopy()..displayName = '',
    ]) {
      expect(
        () => validateDesktopHostIdentity(identity),
        throwsA(isA<DeviceIdentityValidationException>()),
      );
    }
    expect(
      () =>
          validateHostFingerprint(valid, List<int>.from(fingerprint)..[0] ^= 1),
      throwsA(isA<DeviceIdentityValidationException>()),
    );
  });

  test('fingerprint formatting is uppercase, grouped, and bounded', () {
    expect(
      formatShortDeviceFingerprint(<int>[
        0x0c,
        0xd1,
        0xc9,
        0x12,
        0xf4,
        0xcc,
        0x07,
        0x2e,
        0xff,
      ]),
      '0C D1 C9 12 F4 CC 07 2E',
    );
    expect(formatShortDeviceFingerprint(const <int>[]), '—');
  });
}

DeviceIdentity _identity(DevicePlatform platform) {
  final publicKey = List<int>.generate(32, (index) => index + 1);
  return DeviceIdentity(
    deviceId: deriveDeviceIdV1(publicKey),
    publicKeyAlgorithm: PublicKeyAlgorithm.PUBLIC_KEY_ALGORITHM_ED25519,
    publicKey: publicKey,
    displayName: 'Living room Mac',
    platform: platform,
  );
}
