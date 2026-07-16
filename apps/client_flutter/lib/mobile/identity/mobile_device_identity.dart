// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:roammand/pairing/controller_pairing_identity.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

const mobileIdentitySeedBytes = 32;
const maxDeviceDisplayNameUtf8Bytes = 128;

final class MobileDeviceIdentity implements ControllerPairingIdentity {
  MobileDeviceIdentity._(this._identity, this._keyPair, this._algorithm);

  final DeviceIdentity _identity;
  final KeyPair _keyPair;
  final Ed25519 _algorithm;

  static Future<MobileDeviceIdentity> fromSeed({
    required List<int> seed,
    required String displayName,
    required DevicePlatform platform,
  }) async {
    if (seed.length != mobileIdentitySeedBytes ||
        seed.any((byte) => byte < 0 || byte > 255)) {
      throw ArgumentError.value(seed, 'seed', 'Invalid Ed25519 seed');
    }
    final confirmedName = validateConfirmedDeviceName(displayName);
    if (platform != DevicePlatform.DEVICE_PLATFORM_IOS &&
        platform != DevicePlatform.DEVICE_PLATFORM_ANDROID) {
      throw ArgumentError.value(platform, 'platform', 'Not a mobile platform');
    }
    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPairFromSeed(seed);
    final publicKey = await keyPair.extractPublicKey();
    final identity = DeviceIdentity(
      deviceId: deriveDeviceIdV1(publicKey.bytes),
      publicKeyAlgorithm: PublicKeyAlgorithm.PUBLIC_KEY_ALGORITHM_ED25519,
      publicKey: publicKey.bytes,
      displayName: confirmedName,
      platform: platform,
    );
    return MobileDeviceIdentity._(identity, keyPair, algorithm);
  }

  @override
  DeviceIdentity get publicIdentity => _identity.deepCopy();

  @override
  Future<Uint8List> sign(List<int> message) async {
    final signature = await _algorithm.sign(message, keyPair: _keyPair);
    return Uint8List.fromList(signature.bytes);
  }

  @override
  String toString() {
    final idPrefix = _identity.deviceId
        .take(4)
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return 'MobileDeviceIdentity(deviceId: $idPrefix…)';
  }
}

String validateConfirmedDeviceName(String value) {
  final normalized = normalizeDeviceName(value);
  if (normalized == null) {
    throw ArgumentError.value(value, 'displayName', 'Invalid device name');
  }
  return normalized;
}

String? normalizeDeviceName(String? value) {
  final normalized = value?.trim();
  if (normalized == null ||
      normalized.isEmpty ||
      utf8.encode(normalized).length > maxDeviceDisplayNameUtf8Bytes ||
      normalized.runes.any((rune) => rune < 0x20 || rune == 0x7f)) {
    return null;
  }
  return normalized;
}
