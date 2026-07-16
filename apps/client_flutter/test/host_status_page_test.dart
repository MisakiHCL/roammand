// SPDX-License-Identifier: MPL-2.0

import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/desktop/host_agent/host_agent_controller.dart';
import 'package:roammand/desktop/host_agent/host_status_page.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

void main() {
  testWidgets('shows ready Host identity and confirms revocation', (
    tester,
  ) async {
    final api = WidgetFakeHostAgentApi();
    final controller = HostAgentController(
      clientFactory: () => api,
      refreshInterval: const Duration(hours: 1),
    );
    await tester.pumpWidget(_app(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Desktop Host'), findsOneWidget);
    expect(find.text('Test Host'), findsOneWidget);
    expect(find.textContaining('00010203'), findsOneWidget);
    expect(find.text('Add a new device'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('My Phone'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('My Phone'), findsOneWidget);
    expect(find.textContaining('Never'), findsOneWidget);
    expect(find.textContaining('2024'), findsWidgets);

    await tester.tap(find.text('Revoke').first);
    await tester.pumpAndSettle();
    expect(find.text('Revoke My Phone?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(api.revokeCount, 0);

    await tester.tap(find.text('Revoke').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Revoke access'));
    await tester.pumpAndSettle();
    expect(api.revokeCount, 1);
    expect(find.text('No controllers are authorized yet.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('shows Chinese offline state and retries', (tester) async {
    final api = WidgetFakeHostAgentApi()..connectError = true;
    final controller = HostAgentController(
      clientFactory: () => api,
      refreshInterval: const Duration(hours: 1),
    );
    await tester.pumpWidget(
      _app(controller: controller, locale: const Locale('zh')),
    );
    await tester.pumpAndSettle();

    expect(find.text('桌面主机'), findsOneWidget);
    expect(find.text('主机代理未运行'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);

    api.connectError = false;
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(find.text('Test Host'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('shows connecting state without starting a process', (
    tester,
  ) async {
    final api = WidgetFakeHostAgentApi()..connectGate = Completer<void>();
    final controller = HostAgentController(
      clientFactory: () => api,
      refreshInterval: const Duration(hours: 1),
    );
    await tester.pumpWidget(_app(controller: controller));
    await tester.pump();

    expect(find.text('Connecting to Host Agent…'), findsOneWidget);

    api.connectGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Test Host'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('shows a stable error state', (tester) async {
    final api = WidgetFakeHostAgentApi()..statusError = true;
    final controller = HostAgentController(
      clientFactory: () => api,
      refreshInterval: const Duration(hours: 1),
    );
    await tester.pumpWidget(_app(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Host status is unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('handles a narrow window and long controller name', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = WidgetFakeHostAgentApi()
      ..controllerName =
          'A very long controller name that must not overflow the narrow window';
    final controller = HostAgentController(
      clientFactory: () => api,
      refreshInterval: const Duration(hours: 1),
    );
    await tester.pumpWidget(_app(controller: controller));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(HostStatusPage), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('shows controlled bridge and confirms one emergency stop', (
    tester,
  ) async {
    final api = WidgetFakeHostAgentApi()
      ..bridgeStatus = _bridgeStatus(
        PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_CONTROLLED,
        helperConnected: true,
      );
    final controller = HostAgentController(
      clientFactory: () => api,
      refreshInterval: const Duration(hours: 1),
    );
    await tester.pumpWidget(_app(controller: controller));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Emergency stop'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Privileged session bridge'), findsOneWidget);
    expect(find.text('Controlled by My Phone'), findsOneWidget);
    final emergencyButton = find.widgetWithText(FilledButton, 'Emergency stop');
    await tester.ensureVisible(emergencyButton);
    await tester.pumpAndSettle();
    await tester.tap(emergencyButton);
    await tester.pumpAndSettle();
    expect(find.text('Stop remote control?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(api.emergencyStopCount, 0);

    await tester.ensureVisible(emergencyButton);
    await tester.tap(emergencyButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stop now'));
    await tester.pumpAndSettle();
    expect(api.emergencyStopCount, 1);
    expect(find.text('Remote control stopped.'), findsOneWidget);
    expect(find.text('My Phone'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('localizes bridge permission state in Chinese', (tester) async {
    final api = WidgetFakeHostAgentApi()
      ..bridgeStatus = _bridgeStatus(
        PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_PERMISSION_REQUIRED,
      );
    final controller = HostAgentController(
      clientFactory: () => api,
      refreshInterval: const Duration(hours: 1),
    );
    await tester.pumpWidget(
      _app(controller: controller, locale: const Locale('zh')),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('特权会话桥接'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('特权会话桥接'), findsOneWidget);
    expect(find.text('需要系统权限'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

Widget _app({required HostAgentController controller, Locale? locale}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: HostStatusPage(
      controller: controller,
      signalingEndpoint: 'wss://signal.example.test/v1/connect',
    ),
  );
}

class WidgetFakeHostAgentApi implements HostAgentApi {
  final StreamController<SessionTerminatedEvent> _events =
      StreamController<SessionTerminatedEvent>.broadcast();
  final List<int> _grantId = List<int>.filled(16, 0x51);
  bool connectError = false;
  bool statusError = false;
  bool revoked = false;
  String controllerName = 'My Phone';
  Completer<void>? connectGate;
  int revokeCount = 0;
  int emergencyStopCount = 0;
  PrivilegedBridgeStatusSnapshot bridgeStatus = _bridgeStatus(
    PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_READY,
  );

  @override
  Stream<SessionTerminatedEvent> get sessionTerminations => _events.stream;

  @override
  Stream<HostPairingStatusSnapshot> get hostPairingStates =>
      const Stream<HostPairingStatusSnapshot>.empty();

  @override
  Stream<PrivilegedBridgeStatusSnapshot> get privilegedBridgeStates =>
      const Stream<PrivilegedBridgeStatusSnapshot>.empty();

  @override
  Future<EmergencyStopRemoteSessionResult> emergencyStopRemoteSession() async {
    emergencyStopCount += 1;
    return EmergencyStopRemoteSessionResult(terminatedSessionCount: 1);
  }

  @override
  Future<void> connect() async {
    if (connectError) {
      throw const HostAgentDisconnectedException();
    }
    await connectGate?.future;
  }

  @override
  Future<HostStatus> getHostStatus() async {
    if (statusError) {
      throw const HostAgentProtocolException();
    }
    return HostStatus(
      identity: DeviceIdentity(
        deviceId: List<int>.generate(32, (index) => index),
        displayName: 'Test Host',
      ),
      agentInstanceId: List<int>.filled(16, 0x11),
      controllerGrantCount: revoked ? 0 : 2,
      privilegedBridge: bridgeStatus,
    );
  }

  @override
  Future<List<ControllerGrantView>> listControllerGrants() async => revoked
      ? <ControllerGrantView>[]
      : <ControllerGrantView>[
          ControllerGrantView(
            grant: ControllerGrant(
              grantId: _grantId,
              createdAtUnixMs: Int64(1704067200000),
              controller: DeviceIdentity(
                deviceId: List<int>.filled(32, 0x61),
                displayName: controllerName,
              ),
            ),
          ),
          ControllerGrantView(
            grant: ControllerGrant(
              grantId: List<int>.filled(16, 0x52),
              createdAtUnixMs: Int64(1704067200000),
              controller: DeviceIdentity(
                deviceId: List<int>.filled(32, 0x62),
                displayName: 'Tablet',
              ),
            ),
            lastSuccessfulConnectionAtUnixMs: Int64(1704153600000),
          ),
        ];

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
    if (!_events.isClosed) {
      await _events.close();
    }
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
      HostPairingStatusSnapshot(
        state: HostPairingState.HOST_PAIRING_STATE_IDLE,
      );

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

PrivilegedBridgeStatusSnapshot _bridgeStatus(
  PrivilegedBridgeState state, {
  bool helperConnected = true,
}) => PrivilegedBridgeStatusSnapshot(
  state: state,
  helperConnected: helperConnected,
  activeControllerDisplayName: 'My Phone',
  interactiveSession: PrivilegedSessionDescriptor(
    osSessionId: Int64(7),
    desktopKind: InteractiveDesktopKind.INTERACTIVE_DESKTOP_KIND_NORMAL,
    generation: Int64(1),
  ),
);
