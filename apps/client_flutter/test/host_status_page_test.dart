// SPDX-License-Identifier: MPL-2.0

import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/desktop/host_agent/host_agent_controller.dart';
import 'package:roammand/desktop/host_agent/host_agent_process.dart';
import 'package:roammand/desktop/host_agent/host_status_page.dart';
import 'package:roammand/desktop/permissions/macos_host_permissions.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand/network/network_service_configuration.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

const _permissionReadyTestDelay = Duration(seconds: 1);

void main() {
  testWidgets('shows ready Host identity and confirms revocation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = WidgetFakeHostAgentApi();
    final controller = HostAgentController(
      clientFactory: () => api,
      refreshInterval: const Duration(hours: 1),
    );
    await tester.pumpWidget(_app(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('This Mac'), findsOneWidget);
    expect(find.text('Test Host'), findsOneWidget);
    expect(find.text('Safety code: 63 0D CD 29 66 C4 33 66'), findsOneWidget);
    expect(find.text('Add a new device'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('My Phone'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('My Phone'), findsOneWidget);
    expect(find.textContaining('Never'), findsOneWidget);
    expect(find.textContaining('2024'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Remove access').first,
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Remove access').first);
    await tester.pumpAndSettle();
    expect(find.text('Stop allowing My Phone?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(api.revokeCount, 0);

    await tester.tap(find.text('Remove access').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove access').last);
    await tester.pumpAndSettle();
    expect(api.revokeCount, 1);
    expect(
      find.text('No devices have permission to control this Mac.'),
      findsOneWidget,
    );

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

    expect(find.text('这台 Mac'), findsOneWidget);
    expect(find.text('Roammand 后台服务未运行'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);

    api.connectError = false;
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(find.text('Test Host'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('shows a concrete protected-session startup failure', (
    tester,
  ) async {
    final api = WidgetFakeHostAgentApi()..connectError = true;
    final controller = HostAgentController(
      clientFactory: () => api,
      processLifecycle: const WidgetFailingHostAgentProcessLifecycle(
        HostAgentStartupFailure.protectedSessionAgentUnavailable,
      ),
      refreshInterval: const Duration(hours: 1),
    );
    await tester.pumpWidget(
      _app(controller: controller, locale: const Locale('zh')),
    );
    await tester.pumpAndSettle();

    expect(find.text('锁屏控制暂不可用'), findsOneWidget);
    expect(find.textContaining('锁屏和登录界面'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('blocks Host actions until both macOS permissions are ready', (
    tester,
  ) async {
    final api = WidgetFakeHostAgentApi();
    final host = HostAgentController(
      clientFactory: () => api,
      refreshInterval: const Duration(hours: 1),
    );
    final permissionService = _FakeMacOsPermissionService();
    final permissions = MacOsHostPermissionsController(
      service: permissionService,
    );
    addTearDown(permissions.dispose);

    await tester.pumpWidget(
      _app(controller: host, macOsPermissionsController: permissions),
    );
    await tester.pumpAndSettle();

    expect(find.text('Finish Mac permissions'), findsOneWidget);
    expect(find.text('Add a new device'), findsNothing);

    permissionService.status = const MacOsHostPermissionStatus(
      screenRecording: true,
      accessibility: true,
    );
    await permissions.refresh();
    await tester.pumpAndSettle();

    expect(find.text('Finish Mac permissions'), findsNothing);
    expect(find.text('Add a new device'), findsOneWidget);
  });

  testWidgets('refreshes macOS permissions immediately after app resume', (
    tester,
  ) async {
    final host = HostAgentController(
      clientFactory: WidgetFakeHostAgentApi.new,
      refreshInterval: const Duration(hours: 1),
    );
    final permissionService = _FakeMacOsPermissionService();
    final permissions = MacOsHostPermissionsController(
      service: permissionService,
    );
    addTearDown(permissions.dispose);

    await tester.pumpWidget(
      _app(controller: host, macOsPermissionsController: permissions),
    );
    await tester.pumpAndSettle();
    expect(permissionService.checkCount, 1);
    expect(find.text('Finish Mac permissions'), findsOneWidget);

    permissionService.status = const MacOsHostPermissionStatus(
      screenRecording: true,
      accessibility: true,
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(permissionService.checkCount, 2);
    await tester.pump(_permissionReadyTestDelay);
    await tester.pumpAndSettle();
    expect(find.text('Add a new device'), findsOneWidget);
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

    expect(find.text('Getting this Mac ready…'), findsOneWidget);

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

    expect(find.text("This Mac's status is unavailable"), findsOneWidget);
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
    expect(find.text('Remote control readiness'), findsOneWidget);
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
      find.text('远程控制状态'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('远程控制状态'), findsOneWidget);
    expect(find.text('需要开启 macOS 权限'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

Widget _app({
  required HostAgentController controller,
  Locale? locale,
  MacOsHostPermissionsController? macOsPermissionsController,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: HostStatusPage(
      controller: controller,
      macOsPermissionsController: macOsPermissionsController,
      signalingEndpoint: 'wss://signal.example.test/v1/connect',
    ),
  );
}

final class _FakeMacOsPermissionService implements MacOsHostPermissionService {
  MacOsHostPermissionStatus status = const MacOsHostPermissionStatus(
    screenRecording: false,
    accessibility: false,
  );
  int checkCount = 0;

  @override
  Future<MacOsHostPermissionStatus> check() async {
    checkCount += 1;
    return status;
  }

  @override
  Future<MacOsHostPermissionStatus> request(
    MacOsHostPermission permission,
  ) async => status;
}

final class WidgetFailingHostAgentProcessLifecycle
    implements HostAgentProcessLifecycle {
  const WidgetFailingHostAgentProcessLifecycle(this.lastStartupFailure);

  @override
  final HostAgentStartupFailure lastStartupFailure;

  @override
  Future<bool> restart(NetworkServiceConfiguration configuration) async =>
      false;

  @override
  Future<bool> start() async => false;

  @override
  Future<void> stop() async {}
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
        publicKeyAlgorithm: PublicKeyAlgorithm.PUBLIC_KEY_ALGORITHM_ED25519,
        publicKey: List<int>.generate(32, (index) => index),
        displayName: 'Test Host',
        platform: DevicePlatform.DEVICE_PLATFORM_MACOS,
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
