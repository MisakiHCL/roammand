// SPDX-License-Identifier: MPL-2.0

import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/desktop/host_agent/host_agent_controller.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

void main() {
  test('connects, refreshes, reacts to events, and revokes a grant', () async {
    final api = FakeHostAgentApi();
    final controller = HostAgentController(
      clientFactory: () => api,
      refreshInterval: const Duration(hours: 1),
    );

    await controller.start();

    expect(controller.state, HostAgentViewState.ready);
    expect(controller.status?.identity.displayName, 'Test Host');
    expect(controller.grants, hasLength(1));
    expect(api.connectCount, 1);
    expect(api.statusCount, 1);
    expect(api.listCount, 1);

    await controller.refresh();
    expect(api.statusCount, 2);
    api.events.add(SessionTerminatedEvent());
    await Future<void>.delayed(Duration.zero);
    expect(api.statusCount, 3);

    await controller.revokeControllerGrant(api.grantId);
    expect(api.revokeCount, 1);
    expect(controller.grants, isEmpty);
    controller.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(api.closeCount, 1);
  });

  test('reports offline, retries, and ignores disposed timer work', () async {
    final failing = FakeHostAgentApi()..connectError = true;
    final recovered = FakeHostAgentApi();
    var attempts = 0;
    final controller = HostAgentController(
      clientFactory: () => attempts++ == 0 ? failing : recovered,
      refreshInterval: const Duration(milliseconds: 10),
    );

    await controller.start();
    expect(controller.state, HostAgentViewState.offline);
    await controller.retry();
    expect(controller.state, HostAgentViewState.ready);
    await Future<void>.delayed(const Duration(milliseconds: 25));
    expect(recovered.statusCount, greaterThan(1));
    controller.dispose();
    await Future<void>.delayed(Duration.zero);
    final countAtDispose = recovered.statusCount;
    await Future<void>.delayed(const Duration(milliseconds: 25));
    expect(recovered.statusCount, countAtDispose);
    expect(failing.closeCount, 1);
    expect(recovered.closeCount, 1);
  });

  test('restores and monotonically merges Host pairing state', () async {
    final api = FakeHostAgentApi();
    final controller = HostAgentController(
      clientFactory: () => api,
      refreshInterval: const Duration(hours: 1),
    );

    await controller.start();
    expect(
      controller.pairingStatus?.state,
      HostPairingState.HOST_PAIRING_STATE_IDLE,
    );

    api.pairingStatus = _pairingStatus(
      HostPairingState.HOST_PAIRING_STATE_CREATING,
      1,
    );
    await controller.startHostQrPairing('wss://signal.example.test/v1/ws');
    expect(api.startQrCount, 1);
    expect(controller.pairingStatus?.revision.toInt(), 1);

    api.pairingEvents.add(
      _pairingStatus(
        HostPairingState.HOST_PAIRING_STATE_WAITING_LOCAL_DECISION,
        3,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(controller.pairingStatus?.revision.toInt(), 3);

    api.pairingEvents.add(
      _pairingStatus(HostPairingState.HOST_PAIRING_STATE_INVITING, 2),
    );
    await Future<void>.delayed(Duration.zero);
    expect(
      controller.pairingStatus?.state,
      HostPairingState.HOST_PAIRING_STATE_WAITING_LOCAL_DECISION,
    );

    final rendezvousId = List<int>.filled(16, 0x51);
    final controllerId = List<int>.filled(32, 0x61);
    api.pairingStatus = _pairingStatus(
      HostPairingState.HOST_PAIRING_STATE_CANCELLED,
      4,
    );
    await controller.cancelHostPairing(rendezvousId);
    await controller.acceptHostPairing(rendezvousId, controllerId);
    await controller.rejectHostPairing(rendezvousId, controllerId);
    await controller.startHostDesktopCodePairing(
      'wss://signal.example.test/v1/ws',
    );
    expect(api.cancelPairingCount, 1);
    expect(api.acceptPairingCount, 1);
    expect(api.rejectPairingCount, 1);
    expect(api.startDesktopCodeCount, 1);

    controller.dispose();
    await Future<void>.delayed(Duration.zero);
  });

  test('merges bridge generations and runs one local emergency stop', () async {
    final api = FakeHostAgentApi()
      ..bridgeStatus = _bridgeStatus(
        PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_CONTROLLED,
        3,
      );
    final controller = HostAgentController(
      clientFactory: () => api,
      refreshInterval: const Duration(hours: 1),
    );
    await controller.start();
    expect(
      controller.privilegedBridgeStatus?.state,
      PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_CONTROLLED,
    );

    api.bridgeEvents.add(
      _bridgeStatus(PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_READY, 2),
    );
    api.bridgeEvents.add(
      _bridgeStatus(
        PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_TRANSITIONING,
        4,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(
      controller.privilegedBridgeStatus?.interactiveSession.generation.toInt(),
      4,
    );

    api.emergencyStopGate = Completer<void>();
    final stopping = controller.emergencyStopRemoteSession();
    await Future<void>.delayed(Duration.zero);
    expect(controller.isEmergencyStopPending, isTrue);
    await controller.emergencyStopRemoteSession();
    expect(api.emergencyStopCount, 1);
    api.emergencyStopGate!.complete();
    await stopping;
    expect(controller.isEmergencyStopPending, isFalse);
    expect(controller.emergencyStopOutcome, EmergencyStopOutcome.succeeded);
    expect(controller.grants, hasLength(1));

    controller.dispose();
    await Future<void>.delayed(Duration.zero);
  });
}

class FakeHostAgentApi implements HostAgentApi {
  final StreamController<SessionTerminatedEvent> events =
      StreamController<SessionTerminatedEvent>.broadcast();
  final StreamController<HostPairingStatusSnapshot> pairingEvents =
      StreamController<HostPairingStatusSnapshot>.broadcast();
  final StreamController<PrivilegedBridgeStatusSnapshot> bridgeEvents =
      StreamController<PrivilegedBridgeStatusSnapshot>.broadcast();
  final List<int> grantId = List<int>.filled(16, 0x51);
  bool connectError = false;
  bool revoked = false;
  int connectCount = 0;
  int statusCount = 0;
  int listCount = 0;
  int revokeCount = 0;
  int closeCount = 0;
  int startQrCount = 0;
  int startDesktopCodeCount = 0;
  int cancelPairingCount = 0;
  int acceptPairingCount = 0;
  int rejectPairingCount = 0;
  int emergencyStopCount = 0;
  Completer<void>? emergencyStopGate;
  PrivilegedBridgeStatusSnapshot bridgeStatus = _bridgeStatus(
    PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_READY,
    1,
  );
  HostPairingStatusSnapshot pairingStatus = _pairingStatus(
    HostPairingState.HOST_PAIRING_STATE_IDLE,
    0,
  );

  @override
  Stream<SessionTerminatedEvent> get sessionTerminations => events.stream;

  @override
  Stream<HostPairingStatusSnapshot> get hostPairingStates =>
      pairingEvents.stream;

  @override
  Stream<PrivilegedBridgeStatusSnapshot> get privilegedBridgeStates =>
      bridgeEvents.stream;

  @override
  Future<EmergencyStopRemoteSessionResult> emergencyStopRemoteSession() async {
    emergencyStopCount += 1;
    await emergencyStopGate?.future;
    return EmergencyStopRemoteSessionResult(terminatedSessionCount: 1);
  }

  @override
  Future<void> connect() async {
    connectCount += 1;
    if (connectError) {
      throw const HostAgentDisconnectedException();
    }
  }

  @override
  Future<HostStatus> getHostStatus() async {
    statusCount += 1;
    return HostStatus(
      identity: DeviceIdentity(
        deviceId: List<int>.generate(32, (index) => index),
        displayName: 'Test Host',
      ),
      agentInstanceId: List<int>.filled(16, 0x11),
      controllerGrantCount: revoked ? 0 : 1,
      privilegedBridge: bridgeStatus,
    );
  }

  @override
  Future<List<ControllerGrantView>> listControllerGrants() async {
    listCount += 1;
    if (revoked) {
      return <ControllerGrantView>[];
    }
    return <ControllerGrantView>[
      ControllerGrantView(
        grant: ControllerGrant(
          grantId: grantId,
          controller: DeviceIdentity(
            deviceId: List<int>.filled(32, 0x61),
            displayName: 'My Phone',
          ),
          permissions: <SessionPermission>[
            SessionPermission.SESSION_PERMISSION_VIEW_SCREEN,
          ],
        ),
      ),
    ];
  }

  @override
  Future<ControllerGrantRevoked> revokeControllerGrant(
    List<int> grantId,
  ) async {
    revokeCount += 1;
    revoked = true;
    return ControllerGrantRevoked(grantId: grantId);
  }

  @override
  Future<ControllerGrantView> createControllerGrant(
    DeviceIdentity controller,
    Iterable<SessionPermission> permissions,
  ) => throw UnimplementedError();

  @override
  Future<CanonicalTranscriptSignature> signCanonicalTranscript(
    List<int> canonicalTranscript,
  ) => throw UnimplementedError();

  @override
  Future<void> close() async {
    closeCount += 1;
    await events.close();
    await pairingEvents.close();
    await bridgeEvents.close();
  }

  @override
  Future<SessionOfferSignature> signSessionOffer(
    List<int> canonicalTranscript,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PairingTranscriptSignature> signPairingTranscript(
    List<int> canonicalTranscript,
    PairingIdentityRole role,
  ) => throw UnimplementedError();

  @override
  Future<HostPairingStatusSnapshot> getHostPairingStatus() async =>
      pairingStatus;

  @override
  Future<HostPairingStatusSnapshot> startHostQrPairing(
    String signalingEndpoint,
  ) async {
    startQrCount += 1;
    return pairingStatus;
  }

  @override
  Future<HostPairingStatusSnapshot> startHostDesktopCodePairing(
    String signalingEndpoint,
  ) async {
    startDesktopCodeCount += 1;
    return pairingStatus;
  }

  @override
  Future<HostPairingStatusSnapshot> cancelHostPairing(
    List<int> rendezvousId,
  ) async {
    cancelPairingCount += 1;
    return pairingStatus;
  }

  @override
  Future<HostPairingStatusSnapshot> acceptHostPairing(
    List<int> rendezvousId,
    List<int> controllerDeviceId,
  ) async {
    acceptPairingCount += 1;
    return pairingStatus;
  }

  @override
  Future<HostPairingStatusSnapshot> rejectHostPairing(
    List<int> rendezvousId,
    List<int> controllerDeviceId,
  ) async {
    rejectPairingCount += 1;
    return pairingStatus;
  }
}

HostPairingStatusSnapshot _pairingStatus(
  HostPairingState state,
  int revision,
) => HostPairingStatusSnapshot(state: state, revision: Int64(revision));

PrivilegedBridgeStatusSnapshot _bridgeStatus(
  PrivilegedBridgeState state,
  int generation,
) => PrivilegedBridgeStatusSnapshot(
  state: state,
  helperConnected: true,
  activeControllerDisplayName: 'My phone',
  interactiveSession: PrivilegedSessionDescriptor(
    osSessionId: Int64(7),
    desktopKind: InteractiveDesktopKind.INTERACTIVE_DESKTOP_KIND_NORMAL,
    generation: Int64(generation),
  ),
);
