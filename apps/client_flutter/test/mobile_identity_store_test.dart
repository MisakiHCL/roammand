// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/mobile/identity/mobile_device_identity.dart';
import 'package:roammand/mobile/identity/mobile_identity_store.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

void main() {
  test(
    'creates once, persists one protected record, and loads the same identity',
    () async {
      final storage = FakeMobileIdentitySecureStore();
      var randomCalls = 0;
      final store = MobileIdentityStore(
        secureStore: storage,
        platform: DevicePlatform.DEVICE_PLATFORM_ANDROID,
        randomBytes: (length) {
          randomCalls += 1;
          return List<int>.generate(length, (index) => index);
        },
      );

      final results = await Future.wait(<Future<MobileDeviceIdentity>>[
        store.loadOrCreate(confirmedDisplayName: 'My Pixel'),
        store.loadOrCreate(confirmedDisplayName: 'Ignored second name'),
      ]);
      final loaded = await store.load();

      expect(randomCalls, 1);
      expect(storage.writeCount, 1);
      expect(storage.values.keys, <String>[mobileIdentityStorageKey]);
      expect(
        results[0].publicIdentity.deviceId,
        results[1].publicIdentity.deviceId,
      );
      expect(
        loaded?.publicIdentity.deviceId,
        results[0].publicIdentity.deviceId,
      );
      expect(loaded?.publicIdentity.displayName, 'My Pixel');
      expect(
        storage.values.values.single,
        isNot(contains('Ignored second name')),
      );
    },
  );

  test('requires an explicitly confirmed valid name before creating', () async {
    final storage = FakeMobileIdentitySecureStore();
    final store = MobileIdentityStore(
      secureStore: storage,
      platform: DevicePlatform.DEVICE_PLATFORM_IOS,
      randomBytes: (_) => List<int>.filled(mobileIdentitySeedBytes, 7),
    );

    await expectLater(
      store.loadOrCreate(confirmedDisplayName: '  '),
      throwsArgumentError,
    );
    expect(storage.writeCount, 0);
    expect(storage.values, isEmpty);
  });

  test(
    'corrupt records and public-key substitution fail without silent reset',
    () async {
      final storage = FakeMobileIdentitySecureStore();
      final store = MobileIdentityStore(
        secureStore: storage,
        platform: DevicePlatform.DEVICE_PLATFORM_ANDROID,
        randomBytes: (_) => List<int>.filled(mobileIdentitySeedBytes, 9),
      );
      await store.loadOrCreate(confirmedDisplayName: 'Phone');
      final writesAfterCreate = storage.writeCount;
      final record =
          jsonDecode(storage.values[mobileIdentityStorageKey]!)
              as Map<String, dynamic>;
      record['publicKey'] = base64UrlEncode(List<int>.filled(32, 0xff));
      storage.values[mobileIdentityStorageKey] = jsonEncode(record);

      await expectLater(
        store.load(),
        throwsA(
          isA<MobileIdentityStoreException>().having(
            (error) => error.code,
            'code',
            MobileIdentityStoreError.corruptRecord,
          ),
        ),
      );
      expect(storage.writeCount, writesAfterCreate);

      record['seed'] = base64UrlEncode(
        List<int>.filled(mobileIdentitySeedBytes - 1, 7),
      );
      storage.values[mobileIdentityStorageKey] = jsonEncode(record);
      await expectLater(
        store.load(),
        throwsA(_storeError(MobileIdentityStoreError.corruptRecord)),
      );
      expect(storage.writeCount, writesAfterCreate);

      storage.values[mobileIdentityStorageKey] = '{truncated';
      await expectLater(
        store.loadOrCreate(confirmedDisplayName: 'Replacement'),
        throwsA(isA<MobileIdentityStoreException>()),
      );
      expect(storage.writeCount, writesAfterCreate);
    },
  );

  test('secure-store read and write failures remain explicit', () async {
    final readFailure = FakeMobileIdentitySecureStore()..failRead = true;
    final readStore = MobileIdentityStore(
      secureStore: readFailure,
      platform: DevicePlatform.DEVICE_PLATFORM_IOS,
      randomBytes: (_) => List<int>.filled(mobileIdentitySeedBytes, 1),
    );
    await expectLater(
      readStore.load(),
      throwsA(_storeError(MobileIdentityStoreError.unavailable)),
    );

    final writeFailure = FakeMobileIdentitySecureStore()..failWrite = true;
    final writeStore = MobileIdentityStore(
      secureStore: writeFailure,
      platform: DevicePlatform.DEVICE_PLATFORM_IOS,
      randomBytes: (_) => List<int>.filled(mobileIdentitySeedBytes, 1),
    );
    await expectLater(
      writeStore.loadOrCreate(confirmedDisplayName: 'Phone'),
      throwsA(_storeError(MobileIdentityStoreError.unavailable)),
    );
    expect(writeFailure.values, isEmpty);
  });
}

Matcher _storeError(MobileIdentityStoreError code) =>
    isA<MobileIdentityStoreException>().having(
      (error) => error.code,
      'code',
      code,
    );

final class FakeMobileIdentitySecureStore implements MobileIdentitySecureStore {
  final Map<String, String> values = <String, String>{};
  bool failRead = false;
  bool failWrite = false;
  int writeCount = 0;

  @override
  Future<String?> read(String key) async {
    if (failRead) {
      throw StateError('read failed');
    }
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (failWrite) {
      throw StateError('write failed');
    }
    writeCount += 1;
    values[key] = value;
  }
}
