// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/desktop/remote/peer_session.dart';
import 'package:roammand/network/network_service_configuration.dart';
import 'package:roammand/network/network_service_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  test('official defaults use secure signaling and public STUN', () {
    final official = NetworkServiceConfiguration.official();
    expect(official.kind, NetworkServiceProfileKind.official);
    expect(official.signalingEndpoint.scheme, 'wss');
    expect(official.signalingEndpoint.host, 'signal.hcl.life');
    expect(official.stunUrls, <String>['stun:stun.hcl.life:3478']);

    final custom = _custom();
    custom.validate();
    final peer = custom.toPeerConfiguration();
    expect(peer.iceTransportPolicy, DesktopIceTransportPolicy.all);
    expect(peer.iceServers.single.urls, <String>[
      'stun:one.example.test:3478',
      'stuns:two.example.test:5349',
    ]);
    expect(peer.iceServers.single.username, isEmpty);
    expect(peer.iceServers.single.credential, isEmpty);
  });

  test('rejects plaintext public signaling and non-STUN ICE addresses', () {
    expect(
      () => NetworkServiceConfiguration(
        kind: NetworkServiceProfileKind.custom,
        signalingEndpoint: Uri.parse('ws://signal.example.test/v1/connect'),
      ).validate(),
      throwsA(isA<NetworkServiceConfigurationException>()),
    );
    expect(
      () => NetworkServiceConfiguration(
        kind: NetworkServiceProfileKind.custom,
        signalingEndpoint: Uri.parse('wss://signal.example.test/v1/connect'),
        stunUrls: const <String>['turn:turn.example.test:3478'],
      ).validate(),
      throwsA(
        isA<NetworkServiceConfigurationException>().having(
          (error) => error.code,
          'code',
          NetworkServiceConfigurationError.invalidStunUrls,
        ),
      ),
    );
    for (final invalid in <String>[
      'stun:',
      'stun:user@host:3478',
      'stun:x#y',
    ]) {
      expect(
        () => NetworkServiceConfiguration(
          kind: NetworkServiceProfileKind.custom,
          signalingEndpoint: Uri.parse('wss://signal.example.test/v1/connect'),
          stunUrls: <String>[invalid],
        ).validate(),
        throwsA(isA<NetworkServiceConfigurationException>()),
        reason: invalid,
      );
    }
  });

  test('persists custom configuration and clears it on restore', () async {
    final store = _MemoryNetworkServiceStore();
    final controller = await NetworkServiceController.load(store: store);
    var notifications = 0;
    controller.addListener(() => notifications += 1);

    await controller.useCustom(_custom());
    expect(controller.configuration, _custom());
    expect(store.saved, _custom());
    expect(notifications, 1);

    await controller.restoreOfficial();
    expect(controller.configuration.kind, NetworkServiceProfileKind.official);
    expect(store.clearCount, 1);
    expect(notifications, 2);
    controller.dispose();
  });

  test('does not notify after a pending write outlives disposal', () async {
    final store = _GatedNetworkServiceStore();
    final controller = await NetworkServiceController.load(store: store);
    final saving = controller.useCustom(_custom());
    await store.saveStarted.future;

    controller.dispose();
    store.saveGate.complete();

    await expectLater(saving, completes);
    expect(controller.configuration.kind, NetworkServiceProfileKind.official);
  });

  test('does not erase a profile after a transient read failure', () async {
    final store = _FailingLoadNetworkServiceStore();

    final controller = await NetworkServiceController.load(store: store);

    expect(controller.configuration.kind, NetworkServiceProfileKind.official);
    expect(store.clearCount, 0);
    controller.dispose();
  });

  test('round trips the persisted signaling and STUN configuration', () {
    final original = _custom();
    final decoded = NetworkServiceConfiguration.fromJson(original.toJson());
    expect(decoded, original);
    expect(decoded.stunUrls, _custom().stunUrls);
  });

  group('persistent configuration store', () {
    late SharedPreferencesAsync preferences;

    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      preferences = SharedPreferencesAsync();
    });

    test('persists only public signaling and STUN values', () async {
      final store = PersistentNetworkServiceConfigurationStore(
        preferences: preferences,
      );

      await store.save(_custom());

      final encoded = await preferences.getString(
        networkServiceConfigurationStorageKey,
      );
      expect(encoded, isNotNull);
      expect(
        (jsonDecode(encoded!) as Map<String, dynamic>)['stunUrls'],
        _custom().stunUrls,
      );
      expect(await store.load(), _custom());

      await store.clear();
      expect(
        await preferences.getString(networkServiceConfigurationStorageKey),
        isNull,
      );
    });

    test('supports a signaling-only local development profile', () async {
      final store = PersistentNetworkServiceConfigurationStore(
        preferences: preferences,
      );
      final signalingOnly = NetworkServiceConfiguration(
        kind: NetworkServiceProfileKind.custom,
        signalingEndpoint: Uri.parse('wss://signal.example.test/v1/connect'),
      );

      await store.save(signalingOnly);
      expect(await store.load(), signalingOnly);
    });

    test(
      'rejects a corrupt stored profile and lets startup use official',
      () async {
        await preferences.setString(
          networkServiceConfigurationStorageKey,
          jsonEncode(
            _custom().toJson()..['stunUrls'] = <String>['https://bad'],
          ),
        );
        final store = PersistentNetworkServiceConfigurationStore(
          preferences: preferences,
        );

        await expectLater(
          store.load(),
          throwsA(isA<NetworkServiceConfigurationException>()),
        );
        final controller = await NetworkServiceController.load(store: store);
        expect(
          controller.configuration.kind,
          NetworkServiceProfileKind.official,
        );
        expect(
          await preferences.getString(networkServiceConfigurationStorageKey),
          isNull,
        );
        controller.dispose();
      },
    );

    test('enforces the stored limit in UTF-8 bytes', () async {
      final store = PersistentNetworkServiceConfigurationStore(
        preferences: preferences,
      );
      final unicodeHost = List<String>.filled(700, '例').join();
      final largeUnicodeConfiguration = NetworkServiceConfiguration(
        kind: NetworkServiceProfileKind.custom,
        signalingEndpoint: Uri.parse('wss://signal.example.test/v1/connect'),
        stunUrls: List<String>.filled(8, 'stun:$unicodeHost.test'),
      );

      await expectLater(
        store.save(largeUnicodeConfiguration),
        throwsA(isA<FormatException>()),
      );
      expect(
        await preferences.getString(networkServiceConfigurationStorageKey),
        isNull,
      );
    });
  });
}

NetworkServiceConfiguration _custom() => NetworkServiceConfiguration(
  kind: NetworkServiceProfileKind.custom,
  signalingEndpoint: Uri.parse('wss://signal.example.test/v1/connect'),
  stunUrls: const <String>[
    'stun:one.example.test:3478',
    'stuns:two.example.test:5349',
  ],
);

final class _MemoryNetworkServiceStore
    implements NetworkServiceConfigurationStore {
  NetworkServiceConfiguration? saved;
  int clearCount = 0;

  @override
  Future<void> clear() async {
    clearCount += 1;
    saved = null;
  }

  @override
  Future<NetworkServiceConfiguration?> load() async => saved;

  @override
  Future<void> save(NetworkServiceConfiguration configuration) async {
    saved = configuration;
  }
}

final class _GatedNetworkServiceStore
    implements NetworkServiceConfigurationStore {
  final Completer<void> saveStarted = Completer<void>();
  final Completer<void> saveGate = Completer<void>();

  @override
  Future<void> clear() async {}

  @override
  Future<NetworkServiceConfiguration?> load() async => null;

  @override
  Future<void> save(NetworkServiceConfiguration configuration) async {
    saveStarted.complete();
    await saveGate.future;
  }
}

final class _FailingLoadNetworkServiceStore
    implements NetworkServiceConfigurationStore {
  int clearCount = 0;

  @override
  Future<void> clear() async => clearCount += 1;

  @override
  Future<NetworkServiceConfiguration?> load() async {
    throw StateError('temporary storage failure');
  }

  @override
  Future<void> save(NetworkServiceConfiguration configuration) async {}
}
