// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:roammand/pairing/trusted_host_repository.dart';
import 'package:roammand/pairing/trusted_host_store.dart';

import '../remote/remote_desktop_controller.dart';

enum TrustedComputersState { loading, ready, error }

typedef TrustedHostRepositoryFactory = Future<TrustedHostRepository> Function();

final class TrustedComputersController extends ChangeNotifier {
  TrustedComputersController({required this.repositoryFactory});

  factory TrustedComputersController.applicationSupport() =>
      TrustedComputersController(
        repositoryFactory: () async => TrustedHostRepository(
          persistence: await TrustedHostStore.applicationSupport(),
        ),
      );

  final TrustedHostRepositoryFactory repositoryFactory;
  TrustedComputersState _state = TrustedComputersState.loading;
  TrustedHostRepository? _repository;
  StreamSubscription<List<TrustedHostRecord>>? _subscription;
  List<TrustedHostRecord> _hosts = const <TrustedHostRecord>[];
  final Set<String> _deleting = <String>{};
  bool _started = false;
  bool _disposed = false;

  TrustedComputersState get state => _state;
  List<TrustedHostRecord> get hosts =>
      List<TrustedHostRecord>.unmodifiable(_hosts);
  TrustedHostRepository? get repository => _repository;

  bool isDeleting(List<int> hostDeviceId) =>
      _deleting.contains(_deviceKey(hostDeviceId));

  Future<void> start() async {
    if (_started || _disposed) {
      return;
    }
    _started = true;
    try {
      final repository = await repositoryFactory();
      if (_disposed) {
        await repository.close();
        return;
      }
      _repository = repository;
      await repository.initialize();
      if (_disposed) {
        return;
      }
      _hosts = repository.hosts;
      _subscription = repository.changes.listen(
        _replaceHosts,
        onError: (_) => _fail(),
      );
      _state = TrustedComputersState.ready;
      notifyListeners();
    } catch (_) {
      _fail();
    }
  }

  RemoteDesktopTarget targetFor(TrustedHostRecord host) {
    final target = RemoteDesktopTarget(
      hostIdentity: host.hostIdentity,
      signalingEndpoint: host.signalingEndpoint,
    );
    target.validate();
    return target;
  }

  Future<bool> deleteLocal(List<int> hostDeviceId) async {
    final repository = _readyRepository();
    final key = _deviceKey(hostDeviceId);
    if (!_deleting.add(key)) {
      return false;
    }
    _notify();
    try {
      return await repository.deleteLocal(hostDeviceId);
    } catch (_) {
      _fail();
      return false;
    } finally {
      _deleting.remove(key);
      _notify();
    }
  }

  Future<void> markSuccessfulConnection(
    TrustedHostRecord host, {
    required int nowUnixMs,
  }) async {
    try {
      await _readyRepository().markSuccessfulConnection(
        host.hostIdentity.deviceId,
        nowUnixMs: nowUnixMs,
      );
    } catch (_) {
      _fail();
    }
  }

  TrustedHostRepository _readyRepository() {
    final repository = _repository;
    if (_disposed ||
        _state != TrustedComputersState.ready ||
        repository == null) {
      throw StateError('Trusted computers are unavailable');
    }
    return repository;
  }

  void _replaceHosts(List<TrustedHostRecord> hosts) {
    if (_disposed) {
      return;
    }
    _hosts = List<TrustedHostRecord>.unmodifiable(hosts);
    _notify();
  }

  void _fail() {
    if (_disposed) {
      return;
    }
    _state = TrustedComputersState.error;
    _hosts = const <TrustedHostRecord>[];
    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    unawaited(_subscription?.cancel());
    _subscription = null;
    final repository = _repository;
    _repository = null;
    if (repository != null) {
      unawaited(repository.close());
    }
    super.dispose();
  }
}

String _deviceKey(List<int> deviceId) => base64UrlEncode(deviceId);
