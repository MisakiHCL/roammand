// SPDX-License-Identifier: MPL-2.0

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:roammand/network/network_service_configuration.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

import 'host_agent_client.dart';
import 'host_agent_process.dart';

export 'host_agent_models.dart';

const _defaultRefreshInterval = Duration(seconds: 30);
const _managedStartupRetryDelays = <Duration>[
  Duration(milliseconds: 50),
  Duration(milliseconds: 100),
  Duration(milliseconds: 200),
  Duration(milliseconds: 400),
  Duration(milliseconds: 800),
  Duration(milliseconds: 1500),
];

enum HostAgentViewState { connecting, ready, offline, error }

enum EmergencyStopOutcome { idle, succeeded, failed }

enum ManagedHostAgentRestartOutcome { restarted, notOwned, unavailable }

final class HostAgentController extends ChangeNotifier {
  HostAgentController({
    HostAgentApi Function()? clientFactory,
    HostAgentProcessLifecycle? processLifecycle,
    this.refreshInterval = _defaultRefreshInterval,
  }) : _clientFactory = clientFactory ?? HostAgentClient.new,
       // Public constructor labels keep dependency injection readable.
       // ignore: prefer_initializing_formals
       _processLifecycle = processLifecycle;

  final HostAgentApi Function() _clientFactory;
  final HostAgentProcessLifecycle? _processLifecycle;
  final Duration refreshInterval;

  HostAgentViewState _state = HostAgentViewState.connecting;
  HostStatus? _status;
  List<ControllerGrantView> _grants = const <ControllerGrantView>[];
  HostPairingStatusSnapshot? _pairingStatus;
  PrivilegedBridgeStatusSnapshot? _privilegedBridgeStatus;
  final Set<String> _revokingGrantIds = <String>{};
  HostAgentApi? _client;
  StreamSubscription<SessionTerminatedEvent>? _eventSubscription;
  StreamSubscription<HostPairingStatusSnapshot>? _pairingSubscription;
  StreamSubscription<PrivilegedBridgeStatusSnapshot>? _bridgeSubscription;
  Timer? _refreshTimer;
  bool _refreshing = false;
  bool _pairingActionPending = false;
  bool _emergencyStopPending = false;
  EmergencyStopOutcome _emergencyStopOutcome = EmergencyStopOutcome.idle;
  int _bridgeGeneration = 0;
  bool _disposed = false;
  bool _notifierDisposed = false;
  int _generation = 0;
  Future<void>? _shutdownOperation;

  HostAgentViewState get state => _state;
  HostStatus? get status => _status;
  List<ControllerGrantView> get grants => _grants;
  HostPairingStatusSnapshot? get pairingStatus => _pairingStatus;
  PrivilegedBridgeStatusSnapshot? get privilegedBridgeStatus =>
      _privilegedBridgeStatus;
  bool get isRefreshing => _refreshing;
  bool get isPairingActionPending => _pairingActionPending;
  bool get isEmergencyStopPending => _emergencyStopPending;
  EmergencyStopOutcome get emergencyStopOutcome => _emergencyStopOutcome;

  bool isRevoking(List<int> grantId) =>
      _revokingGrantIds.contains(_grantKey(grantId));

  Future<void> start() => _connectWithManagedFallback();

  Future<void> retry() => _connectWithManagedFallback();

  Future<ManagedHostAgentRestartOutcome> applyNetworkConfiguration(
    NetworkServiceConfiguration configuration,
  ) async {
    configuration.validate();
    final processLifecycle = _processLifecycle;
    if (_disposed || processLifecycle == null) {
      return ManagedHostAgentRestartOutcome.notOwned;
    }
    await _prepareForManagedRestart();
    if (_disposed) return ManagedHostAgentRestartOutcome.unavailable;
    bool restarted;
    try {
      restarted = await processLifecycle.restart(configuration);
    } on Object {
      restarted = false;
    }
    if (_disposed) return ManagedHostAgentRestartOutcome.unavailable;
    if (!restarted) {
      await _connect();
      return ManagedHostAgentRestartOutcome.notOwned;
    }
    for (final delay in _managedStartupRetryDelays) {
      await Future<void>.delayed(delay);
      if (_disposed) return ManagedHostAgentRestartOutcome.unavailable;
      await _connect();
      if (_state == HostAgentViewState.ready) {
        return ManagedHostAgentRestartOutcome.restarted;
      }
      if (_state != HostAgentViewState.offline) break;
    }
    return ManagedHostAgentRestartOutcome.unavailable;
  }

  Future<void> _connectWithManagedFallback() async {
    await _connect();
    final processLifecycle = _processLifecycle;
    if (_disposed ||
        _state != HostAgentViewState.offline ||
        processLifecycle == null) {
      return;
    }
    bool managedProcessAvailable;
    try {
      managedProcessAvailable = await processLifecycle.start();
    } on Object {
      managedProcessAvailable = false;
    }
    if (_disposed || !managedProcessAvailable) {
      return;
    }
    for (final delay in _managedStartupRetryDelays) {
      await Future<void>.delayed(delay);
      if (_disposed) {
        return;
      }
      await _connect();
      if (_disposed || _state == HostAgentViewState.ready) {
        return;
      }
      if (_state != HostAgentViewState.offline) {
        return;
      }
    }
  }

  Future<void> refresh() async {
    final client = _client;
    if (_disposed ||
        _state != HostAgentViewState.ready ||
        client == null ||
        _refreshing) {
      return;
    }
    final generation = _generation;
    _refreshing = true;
    _notify();
    try {
      await _loadSnapshot(client, generation);
    } catch (error) {
      _handleFailure(error, generation);
    } finally {
      if (!_disposed && generation == _generation) {
        _refreshing = false;
        _notify();
      }
    }
  }

  Future<void> revokeControllerGrant(List<int> grantId) async {
    final client = _client;
    if (_disposed || _state != HostAgentViewState.ready || client == null) {
      return;
    }
    final key = _grantKey(grantId);
    if (!_revokingGrantIds.add(key)) {
      return;
    }
    _notify();
    final generation = _generation;
    try {
      await client.revokeControllerGrant(grantId);
      await _loadSnapshot(client, generation);
    } catch (error) {
      _handleFailure(error, generation);
    } finally {
      if (!_disposed && generation == _generation) {
        _revokingGrantIds.remove(key);
        _notify();
      }
    }
  }

  Future<void> emergencyStopRemoteSession() async {
    final client = _client;
    if (_disposed ||
        _state != HostAgentViewState.ready ||
        client == null ||
        _emergencyStopPending) {
      return;
    }
    final generation = _generation;
    _emergencyStopPending = true;
    _emergencyStopOutcome = EmergencyStopOutcome.idle;
    _notify();
    try {
      await client.emergencyStopRemoteSession();
      if (!_disposed && generation == _generation) {
        _emergencyStopOutcome = EmergencyStopOutcome.succeeded;
      }
    } catch (_) {
      if (!_disposed && generation == _generation) {
        _emergencyStopOutcome = EmergencyStopOutcome.failed;
      }
    } finally {
      if (!_disposed && generation == _generation) {
        _emergencyStopPending = false;
        _notify();
      }
    }
  }

  Future<void> startHostQrPairing(String signalingEndpoint) =>
      _runPairingAction(
        (client) => client.startHostQrPairing(signalingEndpoint),
      );

  Future<void> startHostDesktopCodePairing(String signalingEndpoint) =>
      _runPairingAction(
        (client) => client.startHostDesktopCodePairing(signalingEndpoint),
      );

  Future<void> cancelHostPairing(List<int> rendezvousId) =>
      _runPairingAction((client) => client.cancelHostPairing(rendezvousId));

  Future<void> acceptHostPairing(
    List<int> rendezvousId,
    List<int> controllerDeviceId,
  ) => _runPairingAction(
    (client) => client.acceptHostPairing(rendezvousId, controllerDeviceId),
    refreshGrants: true,
  );

  Future<void> rejectHostPairing(
    List<int> rendezvousId,
    List<int> controllerDeviceId,
  ) => _runPairingAction(
    (client) => client.rejectHostPairing(rendezvousId, controllerDeviceId),
  );

  Future<void> _runPairingAction(
    Future<HostPairingStatusSnapshot> Function(HostAgentApi client) action, {
    bool refreshGrants = false,
  }) async {
    final client = _client;
    if (_disposed ||
        _state != HostAgentViewState.ready ||
        client == null ||
        _pairingActionPending) {
      return;
    }
    final generation = _generation;
    _pairingActionPending = true;
    _notify();
    try {
      _mergePairingStatus(await action(client), generation);
      if (refreshGrants) {
        final grants = await client.listControllerGrants();
        if (!_disposed && generation == _generation) {
          _grants = List<ControllerGrantView>.unmodifiable(grants);
        }
      }
    } catch (error) {
      _handleFailure(error, generation);
    } finally {
      if (!_disposed && generation == _generation) {
        _pairingActionPending = false;
        _notify();
      }
    }
  }

  Future<void> _connect() async {
    if (_disposed) {
      return;
    }
    final generation = ++_generation;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    await _pairingSubscription?.cancel();
    _pairingSubscription = null;
    await _bridgeSubscription?.cancel();
    _bridgeSubscription = null;
    final previous = _client;
    _client = null;
    if (previous != null) {
      await previous.close();
    }
    if (_disposed || generation != _generation) {
      return;
    }

    _state = HostAgentViewState.connecting;
    _status = null;
    _grants = const <ControllerGrantView>[];
    _pairingStatus = null;
    _privilegedBridgeStatus = null;
    _bridgeGeneration = 0;
    _pairingActionPending = false;
    _emergencyStopPending = false;
    _emergencyStopOutcome = EmergencyStopOutcome.idle;
    _notify();
    final client = _clientFactory();
    _client = client;
    try {
      await client.connect();
      if (_disposed || generation != _generation) {
        await client.close();
        return;
      }
      _eventSubscription = client.sessionTerminations.listen(
        (_) => unawaited(refresh()),
        onError: (_) =>
            _handleFailure(const HostAgentDisconnectedException(), generation),
        onDone: () =>
            _handleFailure(const HostAgentDisconnectedException(), generation),
      );
      _pairingSubscription = client.hostPairingStates.listen(
        (status) => _mergePairingStatus(status, generation),
        onError: (_) =>
            _handleFailure(const HostAgentDisconnectedException(), generation),
        onDone: () =>
            _handleFailure(const HostAgentDisconnectedException(), generation),
      );
      _bridgeSubscription = client.privilegedBridgeStates.listen(
        (status) => _mergePrivilegedBridgeStatus(status, generation),
        onError: (_) =>
            _handleFailure(const HostAgentDisconnectedException(), generation),
        onDone: () =>
            _handleFailure(const HostAgentDisconnectedException(), generation),
      );
      await _loadSnapshot(client, generation);
      if (_disposed || generation != _generation) {
        return;
      }
      _state = HostAgentViewState.ready;
      _refreshTimer = Timer.periodic(
        refreshInterval,
        (_) => unawaited(refresh()),
      );
      _notify();
    } catch (error) {
      _handleFailure(error, generation);
    }
  }

  Future<void> _prepareForManagedRestart() async {
    _generation += 1;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    final eventSubscription = _eventSubscription;
    _eventSubscription = null;
    final pairingSubscription = _pairingSubscription;
    _pairingSubscription = null;
    final bridgeSubscription = _bridgeSubscription;
    _bridgeSubscription = null;
    final client = _client;
    _client = null;
    await eventSubscription?.cancel();
    await pairingSubscription?.cancel();
    await bridgeSubscription?.cancel();
    await client?.close();
    if (_disposed) return;
    _state = HostAgentViewState.connecting;
    _status = null;
    _grants = const <ControllerGrantView>[];
    _pairingStatus = null;
    _privilegedBridgeStatus = null;
    _bridgeGeneration = 0;
    _refreshing = false;
    _pairingActionPending = false;
    _emergencyStopPending = false;
    _emergencyStopOutcome = EmergencyStopOutcome.idle;
    _notify();
  }

  Future<void> _loadSnapshot(HostAgentApi client, int generation) async {
    final status = await client.getHostStatus();
    final grants = await client.listControllerGrants();
    final pairingStatus = await client.getHostPairingStatus();
    if (_disposed || generation != _generation) {
      return;
    }
    _status = status;
    _grants = List<ControllerGrantView>.unmodifiable(grants);
    _mergePairingStatus(pairingStatus, generation, notify: false);
    if (status.hasPrivilegedBridge()) {
      _mergePrivilegedBridgeStatus(
        status.privilegedBridge,
        generation,
        notify: false,
      );
    }
  }

  void _mergePairingStatus(
    HostPairingStatusSnapshot incoming,
    int generation, {
    bool notify = true,
  }) {
    if (_disposed || generation != _generation) {
      return;
    }
    final current = _pairingStatus;
    if (current != null && incoming.revision.compareTo(current.revision) <= 0) {
      return;
    }
    _pairingStatus = incoming;
    if (notify) {
      _notify();
    }
  }

  void _mergePrivilegedBridgeStatus(
    PrivilegedBridgeStatusSnapshot incoming,
    int generation, {
    bool notify = true,
  }) {
    if (_disposed || generation != _generation) {
      return;
    }
    if (incoming.hasInteractiveSession()) {
      final incomingGeneration = incoming.interactiveSession.generation.toInt();
      if (incomingGeneration < _bridgeGeneration) {
        return;
      }
      _bridgeGeneration = incomingGeneration;
    }
    _privilegedBridgeStatus = incoming.deepCopy();
    if (notify) {
      _notify();
    }
  }

  void _handleFailure(Object error, int generation) {
    if (_disposed || generation != _generation) {
      return;
    }
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _refreshing = false;
    _pairingActionPending = false;
    _emergencyStopPending = false;
    _emergencyStopOutcome = EmergencyStopOutcome.idle;
    _state = error is HostAgentDisconnectedException
        ? HostAgentViewState.offline
        : HostAgentViewState.error;
    _status = null;
    _grants = const <ControllerGrantView>[];
    _pairingStatus = null;
    _privilegedBridgeStatus = null;
    _bridgeGeneration = 0;
    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> shutdown() {
    final pending = _shutdownOperation;
    if (pending != null) {
      return pending;
    }
    final operation = _shutdown();
    _shutdownOperation = operation;
    return operation;
  }

  Future<void> _shutdown() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _generation += 1;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    final eventSubscription = _eventSubscription;
    _eventSubscription = null;
    final pairingSubscription = _pairingSubscription;
    _pairingSubscription = null;
    final bridgeSubscription = _bridgeSubscription;
    _bridgeSubscription = null;
    final client = _client;
    _client = null;
    await eventSubscription?.cancel();
    await pairingSubscription?.cancel();
    await bridgeSubscription?.cancel();
    await client?.close();
    await _processLifecycle?.stop();
  }

  @override
  void dispose() {
    if (_notifierDisposed) {
      return;
    }
    _notifierDisposed = true;
    unawaited(shutdown());
    super.dispose();
  }
}

String _grantKey(List<int> grantId) =>
    grantId.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
