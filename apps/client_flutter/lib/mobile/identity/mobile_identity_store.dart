// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

import 'mobile_device_identity.dart';

const mobileIdentityStorageKey = 'mobile_controller_identity_v1';
const _recordVersion = 1;
const _maxRecordUtf8Bytes = 2048;
const _secureStorageNamespace = 'roammand_identity';
const _recordFields = <String>{
  'version',
  'seed',
  'publicKey',
  'displayName',
  'platform',
};

enum MobileIdentityStoreError { corruptRecord, unavailable }

final class MobileIdentityStoreException implements Exception {
  const MobileIdentityStoreException(this.code);

  final MobileIdentityStoreError code;

  @override
  String toString() => 'MobileIdentityStoreException(${code.name})';
}

abstract interface class MobileIdentitySecureStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}

final class FlutterMobileIdentitySecureStore
    implements MobileIdentitySecureStore {
  FlutterMobileIdentitySecureStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.unlocked_this_device,
              synchronizable: false,
              accountName: _secureStorageNamespace,
            ),
            aOptions: AndroidOptions(
              resetOnError: false,
              migrateOnAlgorithmChange: true,
              // This is a same-device rollback copy used only while the
              // plugin migrates encryption algorithms. Platform cloud backup
              // and device-to-device transfer exclude all application data
              // through the release manifest's versioned XML rules.
              migrateWithBackup: true,
              storageNamespace: _secureStorageNamespace,
            ),
          );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

final class MobileIdentityStore {
  MobileIdentityStore({
    MobileIdentitySecureStore? secureStore,
    required this.platform,
    List<int> Function(int length)? randomBytes,
  }) : _secureStore = secureStore ?? FlutterMobileIdentitySecureStore(),
       _randomBytes = randomBytes ?? _secureRandomBytes {
    if (platform != DevicePlatform.DEVICE_PLATFORM_IOS &&
        platform != DevicePlatform.DEVICE_PLATFORM_ANDROID) {
      throw ArgumentError.value(platform, 'platform', 'Not a mobile platform');
    }
  }

  final MobileIdentitySecureStore _secureStore;
  final DevicePlatform platform;
  final List<int> Function(int length) _randomBytes;
  Future<void> _previousOperation = Future<void>.value();

  Future<MobileDeviceIdentity?> load() => _serialized(_load);

  Future<MobileDeviceIdentity> loadOrCreate({
    required String confirmedDisplayName,
  }) async {
    final displayName = validateConfirmedDeviceName(confirmedDisplayName);
    return _serialized(() async {
      final existing = await _load();
      if (existing != null) {
        return existing;
      }
      final random = _randomBytes(mobileIdentitySeedBytes);
      if (random.length != mobileIdentitySeedBytes ||
          random.any((byte) => byte < 0 || byte > 255)) {
        throw const MobileIdentityStoreException(
          MobileIdentityStoreError.unavailable,
        );
      }
      final seed = Uint8List.fromList(random);
      try {
        final identity = await MobileDeviceIdentity.fromSeed(
          seed: seed,
          displayName: displayName,
          platform: platform,
        );
        final publicIdentity = identity.publicIdentity;
        final encoded = jsonEncode(<String, Object>{
          'version': _recordVersion,
          'seed': base64UrlEncode(seed),
          'publicKey': base64UrlEncode(publicIdentity.publicKey),
          'displayName': publicIdentity.displayName,
          'platform': publicIdentity.platform.value,
        });
        await _write(encoded);
        return identity;
      } finally {
        seed.fillRange(0, seed.length, 0);
      }
    });
  }

  Future<MobileDeviceIdentity?> _load() async {
    final encoded = await _read();
    if (encoded == null) {
      return null;
    }
    if (utf8.encode(encoded).length > _maxRecordUtf8Bytes) {
      throw const MobileIdentityStoreException(
        MobileIdentityStoreError.corruptRecord,
      );
    }
    Uint8List? seed;
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic> ||
          decoded.keys.toSet().difference(_recordFields).isNotEmpty ||
          _recordFields.difference(decoded.keys.toSet()).isNotEmpty ||
          decoded['version'] != _recordVersion ||
          decoded['seed'] is! String ||
          decoded['publicKey'] is! String ||
          decoded['displayName'] is! String ||
          decoded['platform'] != platform.value) {
        throw const FormatException();
      }
      seed = Uint8List.fromList(base64Url.decode(decoded['seed'] as String));
      final persistedPublicKey = base64Url.decode(
        decoded['publicKey'] as String,
      );
      final identity = await MobileDeviceIdentity.fromSeed(
        seed: seed,
        displayName: decoded['displayName'] as String,
        platform: platform,
      );
      if (!_constantTimeEquals(
        identity.publicIdentity.publicKey,
        persistedPublicKey,
      )) {
        throw const FormatException();
      }
      return identity;
    } on MobileIdentityStoreException {
      rethrow;
    } catch (_) {
      throw const MobileIdentityStoreException(
        MobileIdentityStoreError.corruptRecord,
      );
    } finally {
      seed?.fillRange(0, seed.length, 0);
    }
  }

  Future<String?> _read() async {
    try {
      return await _secureStore.read(mobileIdentityStorageKey);
    } catch (_) {
      throw const MobileIdentityStoreException(
        MobileIdentityStoreError.unavailable,
      );
    }
  }

  Future<void> _write(String encoded) async {
    try {
      await _secureStore.write(mobileIdentityStorageKey, encoded);
    } catch (_) {
      throw const MobileIdentityStoreException(
        MobileIdentityStoreError.unavailable,
      );
    }
  }

  Future<T> _serialized<T>(Future<T> Function() operation) async {
    final preceding = _previousOperation;
    final done = Completer<void>();
    _previousOperation = done.future;
    await preceding;
    try {
      return await operation();
    } finally {
      done.complete();
    }
  }
}

List<int> _secureRandomBytes(int length) {
  final random = Random.secure();
  return List<int>.generate(
    length,
    (_) => random.nextInt(256),
    growable: false,
  );
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
