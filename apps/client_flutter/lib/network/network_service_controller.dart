// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'network_service_configuration.dart';

const networkServiceConfigurationStorageKey =
    'network_service_configuration_v1';
const _maximumStoredConfigurationBytes = 16 * 1024;

abstract interface class NetworkServiceConfigurationStore {
  Future<NetworkServiceConfiguration?> load();

  Future<void> save(NetworkServiceConfiguration configuration);

  Future<void> clear();
}

final class PersistentNetworkServiceConfigurationStore
    implements NetworkServiceConfigurationStore {
  PersistentNetworkServiceConfigurationStore({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<NetworkServiceConfiguration?> load() async {
    final encoded = await _preferences.getString(
      networkServiceConfigurationStorageKey,
    );
    if (encoded == null) return null;
    if (utf8.encode(encoded).length > _maximumStoredConfigurationBytes) {
      throw const FormatException('network service configuration is too large');
    }
    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('network service configuration is invalid');
    }
    return NetworkServiceConfiguration.fromJson(decoded);
  }

  @override
  Future<void> save(NetworkServiceConfiguration configuration) async {
    configuration.validate();
    final encoded = jsonEncode(configuration.toJson());
    if (utf8.encode(encoded).length > _maximumStoredConfigurationBytes) {
      throw const FormatException('network service configuration is too large');
    }
    await _preferences.setString(
      networkServiceConfigurationStorageKey,
      encoded,
    );
  }

  @override
  Future<void> clear() async {
    await _preferences.remove(networkServiceConfigurationStorageKey);
  }
}

final class NetworkServiceController extends ChangeNotifier {
  NetworkServiceController({
    required NetworkServiceConfigurationStore store,
    required NetworkServiceConfiguration configuration,
  }) : // Public constructor labels keep dependency injection readable.
       // ignore: prefer_initializing_formals
       _store = store,
       // Public constructor labels keep dependency injection readable.
       // ignore: prefer_initializing_formals
       _configuration = configuration;

  factory NetworkServiceController.transient({
    NetworkServiceConfiguration? configuration,
  }) => NetworkServiceController(
    store: const _TransientNetworkServiceConfigurationStore(),
    configuration: configuration ?? NetworkServiceConfiguration.official(),
  );

  final NetworkServiceConfigurationStore _store;
  NetworkServiceConfiguration _configuration;
  Future<void> _pendingWrite = Future<void>.value();
  bool _disposed = false;

  NetworkServiceConfiguration get configuration => _configuration;

  static Future<NetworkServiceController> load({
    NetworkServiceConfigurationStore? store,
  }) async {
    final resolvedStore = store ?? PersistentNetworkServiceConfigurationStore();
    var configuration = NetworkServiceConfiguration.official();
    try {
      configuration = await resolvedStore.load() ?? configuration;
    } on FormatException {
      await _clearCorruptConfiguration(resolvedStore);
    } on NetworkServiceConfigurationException {
      await _clearCorruptConfiguration(resolvedStore);
    } catch (_) {
      // A missing or corrupt optional preference must not prevent app startup.
    }
    return NetworkServiceController(
      store: resolvedStore,
      configuration: configuration,
    );
  }

  Future<void> useCustom(NetworkServiceConfiguration configuration) {
    if (configuration.kind != NetworkServiceProfileKind.custom) {
      throw const NetworkServiceConfigurationException(
        NetworkServiceConfigurationError.invalidProfile,
      );
    }
    configuration.validate();
    return _enqueue(() async {
      await _store.save(configuration);
      if (!_disposed && _configuration != configuration) {
        _configuration = configuration;
        notifyListeners();
      }
    });
  }

  Future<void> restoreOfficial() => _enqueue(() async {
    await _store.clear();
    final official = NetworkServiceConfiguration.official();
    if (!_disposed && _configuration != official) {
      _configuration = official;
      notifyListeners();
    }
  });

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _pendingWrite.then((_) => operation());
    _pendingWrite = result.catchError((_) {});
    return result;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

Future<void> _clearCorruptConfiguration(
  NetworkServiceConfigurationStore store,
) async {
  try {
    await store.clear();
  } catch (_) {
    // Recovery still uses the official profile if cleanup is unavailable.
  }
}

final class _TransientNetworkServiceConfigurationStore
    implements NetworkServiceConfigurationStore {
  const _TransientNetworkServiceConfigurationStore();

  @override
  Future<void> clear() async {}

  @override
  Future<NetworkServiceConfiguration?> load() async => null;

  @override
  Future<void> save(NetworkServiceConfiguration configuration) async {}
}
