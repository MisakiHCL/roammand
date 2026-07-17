// SPDX-License-Identifier: MPL-2.0

import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/desktop/desktop_app_root.dart';
import 'package:roammand/desktop/host_agent/host_agent_controller.dart';
import 'package:roammand/desktop/host_agent/host_status_page.dart';
import 'package:roammand/desktop/tray/host_tray_models.dart';
import 'package:roammand/desktop/tray/host_tray_port.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

void main() {
  testWidgets('passes the production signaling endpoint to Host pairing', (
    tester,
  ) async {
    final host = HostAgentController(
      clientFactory: TrayFakeHostAgentApi.new,
      refreshInterval: const Duration(hours: 1),
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DesktopAppRoot(
          hostAgentController: host,
          disposeHostAgentController: true,
          trayPort: TrayFakePort(),
          signalingEndpoint: 'wss://signal.example.test/v1/connect',
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    final hostPage = tester.widget<HostStatusPage>(
      find.byType(HostStatusPage, skipOffstage: false),
    );
    expect(hostPage.signalingEndpoint, 'wss://signal.example.test/v1/connect');
  });

  testWidgets('keeps desktop lifecycle in tray and hides on window close', (
    tester,
  ) async {
    final api = TrayFakeHostAgentApi();
    final host = HostAgentController(
      clientFactory: () => api,
      refreshInterval: const Duration(hours: 1),
    );
    final tray = TrayFakePort();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DesktopAppRoot(
          hostAgentController: host,
          disposeHostAgentController: true,
          trayPort: tray,
          home: const Text('desktop-root'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tray.initializeCount, 1);
    expect(tray.menus.single.tooltipLabel, 'Roammand');
    expect(tray.menus.single.exitLabel, 'Quit Roammand');

    api.bridgeEvents.add(_bridgeStatus(controlled: true));
    await tester.pump();
    expect(tray.menus, hasLength(1));
    await tray.emit(HostTrayCommand.windowCloseRequested);
    expect(tray.hideCount, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tray.disposeCount, 1);
  });

  testWidgets('tray exit closes an owned Host Agent before the application', (
    tester,
  ) async {
    final api = TrayFakeHostAgentApi();
    final host = HostAgentController(
      clientFactory: () => api,
      refreshInterval: const Duration(hours: 1),
    );
    final tray = TrayFakePort();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DesktopAppRoot(
          hostAgentController: host,
          disposeHostAgentController: true,
          trayPort: tray,
          home: const Text('desktop-root'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.runAsync(() => tray.emit(HostTrayCommand.exitApplication));

    expect(api.closeCount, 1);
    expect(tray.exitCount, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

final class TrayFakePort implements HostTrayPort {
  Future<void> Function(HostTrayCommand command)? _onCommand;
  final List<HostTrayMenu> menus = <HostTrayMenu>[];
  int initializeCount = 0;
  int hideCount = 0;
  int exitCount = 0;
  int disposeCount = 0;

  @override
  Future<void> initialize({
    required String iconAssetPath,
    required Future<void> Function(HostTrayCommand command) onCommand,
  }) async {
    initializeCount += 1;
    _onCommand = onCommand;
  }

  Future<void> emit(HostTrayCommand command) => _onCommand!(command);

  @override
  Future<void> updateMenu(HostTrayMenu menu) async => menus.add(menu);

  @override
  Future<void> showWindow() async {}

  @override
  Future<void> hideWindow() async => hideCount += 1;

  @override
  Future<void> exitApplication() async => exitCount += 1;

  @override
  Future<void> dispose() async => disposeCount += 1;
}

final class TrayFakeHostAgentApi implements HostAgentApi {
  final StreamController<SessionTerminatedEvent> sessionEvents =
      StreamController<SessionTerminatedEvent>.broadcast();
  final StreamController<HostPairingStatusSnapshot> pairingEvents =
      StreamController<HostPairingStatusSnapshot>.broadcast();
  final StreamController<PrivilegedBridgeStatusSnapshot> bridgeEvents =
      StreamController<PrivilegedBridgeStatusSnapshot>.broadcast();
  int closeCount = 0;

  @override
  Stream<SessionTerminatedEvent> get sessionTerminations =>
      sessionEvents.stream;

  @override
  Stream<HostPairingStatusSnapshot> get hostPairingStates =>
      pairingEvents.stream;

  @override
  Stream<PrivilegedBridgeStatusSnapshot> get privilegedBridgeStates =>
      bridgeEvents.stream;

  @override
  Future<void> connect() async {}

  @override
  Future<HostStatus> getHostStatus() async => HostStatus(
    identity: DeviceIdentity(
      deviceId: List<int>.filled(32, 0x11),
      displayName: 'Test Host',
    ),
    agentInstanceId: List<int>.filled(16, 0x22),
    privilegedBridge: _bridgeStatus(),
  );

  @override
  Future<List<ControllerGrantView>> listControllerGrants() async =>
      <ControllerGrantView>[];

  @override
  Future<HostPairingStatusSnapshot> getHostPairingStatus() async =>
      HostPairingStatusSnapshot(
        state: HostPairingState.HOST_PAIRING_STATE_IDLE,
      );

  @override
  Future<EmergencyStopRemoteSessionResult> emergencyStopRemoteSession() async =>
      EmergencyStopRemoteSessionResult(terminatedSessionCount: 1);

  @override
  Future<void> close() async {
    closeCount += 1;
    await sessionEvents.close();
    await pairingEvents.close();
    await bridgeEvents.close();
  }

  @override
  Future<ControllerGrantView> createControllerGrant(
    DeviceIdentity controller,
    Iterable<SessionPermission> permissions,
  ) => throw UnimplementedError();

  @override
  Future<ControllerGrantRevoked> revokeControllerGrant(List<int> grantId) =>
      throw UnimplementedError();

  @override
  Future<CanonicalTranscriptSignature> signCanonicalTranscript(
    List<int> canonicalTranscript,
  ) => throw UnimplementedError();

  @override
  Future<PairingTranscriptSignature> signPairingTranscript(
    List<int> canonicalTranscript,
    PairingIdentityRole role,
  ) => throw UnimplementedError();

  @override
  Future<SessionOfferSignature> signSessionOffer(
    List<int> canonicalTranscript,
  ) => throw UnimplementedError();

  @override
  Future<HostPairingStatusSnapshot> startHostQrPairing(
    String signalingEndpoint,
  ) => throw UnimplementedError();

  @override
  Future<HostPairingStatusSnapshot> startHostDesktopCodePairing(
    String signalingEndpoint,
  ) => throw UnimplementedError();

  @override
  Future<HostPairingStatusSnapshot> cancelHostPairing(List<int> rendezvousId) =>
      throw UnimplementedError();

  @override
  Future<HostPairingStatusSnapshot> acceptHostPairing(
    List<int> rendezvousId,
    List<int> controllerDeviceId,
  ) => throw UnimplementedError();

  @override
  Future<HostPairingStatusSnapshot> rejectHostPairing(
    List<int> rendezvousId,
    List<int> controllerDeviceId,
  ) => throw UnimplementedError();
}

PrivilegedBridgeStatusSnapshot _bridgeStatus({bool controlled = false}) =>
    PrivilegedBridgeStatusSnapshot(
      state: controlled
          ? PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_CONTROLLED
          : PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_READY,
      helperConnected: true,
      activeControllerDisplayName: 'My phone',
      interactiveSession: PrivilegedSessionDescriptor(
        osSessionId: Int64(7),
        desktopKind: InteractiveDesktopKind.INTERACTIVE_DESKTOP_KIND_NORMAL,
        generation: Int64(controlled ? 2 : 1),
      ),
    );
