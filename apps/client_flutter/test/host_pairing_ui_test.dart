// SPDX-License-Identifier: MPL-2.0

import 'dart:async';

import 'package:crypto/crypto.dart' as hashes;
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/desktop/host_agent/host_agent_controller.dart';
import 'package:roammand/desktop/host_agent/host_status_page.dart';
import 'package:roammand/desktop/pairing/host_pairing_dialog.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand/pairing/qr_pairing_uri.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

const _endpoint = 'wss://signal.example.test/v1/connect';

void main() {
  testWidgets('starts a QR invitation with exact QR data and cancellation', (
    tester,
  ) async {
    final api = PairingUiFakeHostAgentApi();
    final controller = _controller(api);
    await tester.pumpWidget(_app(controller, nowUnixMs: () => api.nowUnixMs));
    await tester.pumpAndSettle();

    expect(find.text('Add a new device'), findsOneWidget);
    expect(find.text('Show mobile QR code'), findsOneWidget);
    expect(find.text('Generate computer pairing code'), findsOneWidget);

    await tester.tap(find.text('Show mobile QR code'));
    await _pumpDialog(tester);

    expect(api.startQrCount, 1);
    final qr = tester.widget<HostPairingQrCode>(find.byType(HostPairingQrCode));
    expect(qr.data, encodeQrPairingUri(api.pairingStatus.invitation));
    expect(find.textContaining('Expires in'), findsOneWidget);
    final initialCountdown = tester
        .widget<Text>(find.textContaining('Expires in'))
        .data;
    api.nowUnixMs += Duration.millisecondsPerSecond;
    await tester.pump(const Duration(seconds: 1));
    expect(
      tester.widget<Text>(find.textContaining('Expires in')).data,
      isNot(initialCountdown),
    );
    expect(find.text('Compare these four words'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Show mobile QR code'),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('Cancel pairing'));
    await tester.pumpAndSettle();
    expect(api.cancelCount, 1);
    expect(find.text('Pairing cancelled'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(HostPairingQrCode), findsNothing);
  });

  testWidgets('shows desktop code, Controller proof, SAS, and one-way grant', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = PairingUiFakeHostAgentApi();
    final controller = _controller(api);
    await tester.pumpWidget(_app(controller, nowUnixMs: () => api.nowUnixMs));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Generate computer pairing code'));
    await _pumpDialog(tester);
    expect(find.text('ABCD-2345'), findsOneWidget);

    api.emitWaitingDecision();
    await tester.pump();
    expect(
      find.text(
        'A very long phone name that still fits safely in a narrow window',
      ),
      findsOneWidget,
    );
    expect(find.text('iPhone or iPad'), findsOneWidget);
    expect(find.textContaining('51515151'), findsOneWidget);
    expect(find.text('Compare these four words'), findsOneWidget);
    for (final word in api.sasWords) {
      expect(find.text(word), findsOneWidget);
    }
    expect(
      find.textContaining('permanent, one-way permission'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Allow control'));
    await tester.pumpAndSettle();
    expect(api.acceptCount, 1);
    expect(find.text('Device allowed'), findsOneWidget);
  });

  testWidgets('rejects or reports failure in Chinese without implicit allow', (
    tester,
  ) async {
    final api = PairingUiFakeHostAgentApi();
    final controller = _controller(api);
    await tester.pumpWidget(
      _app(
        controller,
        locale: const Locale('zh'),
        nowUnixMs: () => api.nowUnixMs,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('添加新设备'), findsOneWidget);
    await tester.tap(find.text('生成电脑配对码'));
    await _pumpDialog(tester);
    api.emitWaitingDecision();
    await tester.pump();
    expect(find.text('允许控制'), findsOneWidget);
    expect(find.text('拒绝'), findsOneWidget);

    await tester.tap(find.text('拒绝'));
    await tester.pumpAndSettle();
    expect(api.rejectCount, 1);
    expect(api.acceptCount, 0);
    expect(find.text('已拒绝此设备'), findsOneWidget);

    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('显示手机二维码'));
    await _pumpDialog(tester);
    api.emitFailure();
    await tester.pump();
    expect(find.text('配对失败'), findsOneWidget);
    expect(api.acceptCount, 0);
  });

  testWidgets('restores an active invitation without starting another', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = PairingUiFakeHostAgentApi()..primeDesktopInvitation();
    final controller = _controller(api);
    await tester.pumpWidget(_app(controller, nowUnixMs: () => api.nowUnixMs));
    await tester.pumpAndSettle();

    expect(find.text('View current pairing'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Show mobile QR code'),
          )
          .onPressed,
      isNull,
    );
    await tester.scrollUntilVisible(
      find.text('View current pairing'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('View current pairing'));
    await _pumpDialog(tester);
    expect(find.text('ABCD-2345'), findsOneWidget);
    expect(api.startQrCount, 0);
  });
}

Future<void> _pumpDialog(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

HostAgentController _controller(PairingUiFakeHostAgentApi api) =>
    HostAgentController(
      clientFactory: () => api,
      refreshInterval: const Duration(hours: 1),
    );

Widget _app(
  HostAgentController controller, {
  required int Function() nowUnixMs,
  Locale? locale,
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: HostStatusPage(
    controller: controller,
    signalingEndpoint: _endpoint,
    nowUnixMs: nowUnixMs,
  ),
);

final class PairingUiFakeHostAgentApi implements HostAgentApi {
  PairingUiFakeHostAgentApi()
    : _hostIdentity = _desktopIdentity('Test Host', 0x20),
      _controllerIdentity = _mobileIdentity(
        'A very long phone name that still fits safely in a narrow window',
        0x40,
      );

  final StreamController<SessionTerminatedEvent> _sessionEvents =
      StreamController<SessionTerminatedEvent>.broadcast();
  final StreamController<HostPairingStatusSnapshot> _pairingEvents =
      StreamController<HostPairingStatusSnapshot>.broadcast();
  final DeviceIdentity _hostIdentity;
  final DeviceIdentity _controllerIdentity;
  final List<String> sasWords = const <String>[
    'abandon',
    'ability',
    'able',
    'about',
  ];
  HostPairingStatusSnapshot pairingStatus = HostPairingStatusSnapshot(
    state: HostPairingState.HOST_PAIRING_STATE_IDLE,
  );
  int _revision = 0;
  int startQrCount = 0;
  int cancelCount = 0;
  int acceptCount = 0;
  int rejectCount = 0;
  int nowUnixMs = 1700000000000;

  @override
  Stream<SessionTerminatedEvent> get sessionTerminations =>
      _sessionEvents.stream;

  @override
  Stream<HostPairingStatusSnapshot> get hostPairingStates =>
      _pairingEvents.stream;

  @override
  Stream<PrivilegedBridgeStatusSnapshot> get privilegedBridgeStates =>
      const Stream<PrivilegedBridgeStatusSnapshot>.empty();

  @override
  Future<EmergencyStopRemoteSessionResult> emergencyStopRemoteSession() async =>
      EmergencyStopRemoteSessionResult();

  @override
  Future<void> connect() async {}

  @override
  Future<HostStatus> getHostStatus() async => HostStatus(
    identity: _hostIdentity,
    agentInstanceId: List<int>.filled(16, 0x11),
  );

  @override
  Future<List<ControllerGrantView>> listControllerGrants() async =>
      const <ControllerGrantView>[];

  @override
  Future<HostPairingStatusSnapshot> getHostPairingStatus() async =>
      pairingStatus;

  @override
  Future<HostPairingStatusSnapshot> startHostQrPairing(
    String signalingEndpoint,
  ) async {
    startQrCount += 1;
    return _start(PairingInvitationKind.PAIRING_INVITATION_KIND_QR);
  }

  @override
  Future<HostPairingStatusSnapshot> startHostDesktopCodePairing(
    String signalingEndpoint,
  ) async => _start(PairingInvitationKind.PAIRING_INVITATION_KIND_DESKTOP_CODE);

  HostPairingStatusSnapshot _start(PairingInvitationKind kind) {
    final now = nowUnixMs;
    final invitation = HostPairingInvitation(
      protocolVersion: ProtocolVersion(major: 1),
      kind: kind,
      rendezvousId: List<int>.filled(16, 0x31),
      hostIdentity: _hostIdentity,
      hostPublicKeyFingerprintSha256: hashes.sha256
          .convert(_hostIdentity.publicKey)
          .bytes,
      hostEphemeralPublicKey: List<int>.filled(32, 0x71),
      signalingEndpoint: _endpoint,
      pairingCode:
          kind == PairingInvitationKind.PAIRING_INVITATION_KIND_DESKTOP_CODE
          ? 'ABCD2345'
          : '',
      issuedAtUnixMs: Int64(now),
      expiresAtUnixMs: Int64(now + pairingRendezvousLifetimeMs),
    );
    pairingStatus = HostPairingStatusSnapshot(
      state: HostPairingState.HOST_PAIRING_STATE_INVITING,
      revision: Int64(++_revision),
      invitation: invitation,
      expiresAtUnixMs: invitation.expiresAtUnixMs,
    );
    return pairingStatus;
  }

  void primeDesktopInvitation() {
    _start(PairingInvitationKind.PAIRING_INVITATION_KIND_DESKTOP_CODE);
  }

  void emitWaitingDecision() {
    pairingStatus = HostPairingStatusSnapshot(
      state: HostPairingState.HOST_PAIRING_STATE_WAITING_LOCAL_DECISION,
      revision: Int64(++_revision),
      invitation: pairingStatus.invitation,
      pendingController: _controllerIdentity,
      pendingControllerFingerprintSha256: List<int>.filled(32, 0x51),
      sasWords: sasWords,
      expiresAtUnixMs: pairingStatus.expiresAtUnixMs,
    );
    _pairingEvents.add(pairingStatus);
  }

  void emitFailure() {
    pairingStatus = HostPairingStatusSnapshot(
      state: HostPairingState.HOST_PAIRING_STATE_FAILED,
      revision: Int64(++_revision),
    );
    _pairingEvents.add(pairingStatus);
  }

  @override
  Future<HostPairingStatusSnapshot> cancelHostPairing(
    List<int> rendezvousId,
  ) async {
    cancelCount += 1;
    return _terminal(HostPairingState.HOST_PAIRING_STATE_CANCELLED);
  }

  @override
  Future<HostPairingStatusSnapshot> acceptHostPairing(
    List<int> rendezvousId,
    List<int> controllerDeviceId,
  ) async {
    acceptCount += 1;
    return _terminal(HostPairingState.HOST_PAIRING_STATE_ACCEPTED);
  }

  @override
  Future<HostPairingStatusSnapshot> rejectHostPairing(
    List<int> rendezvousId,
    List<int> controllerDeviceId,
  ) async {
    rejectCount += 1;
    return _terminal(HostPairingState.HOST_PAIRING_STATE_REJECTED);
  }

  HostPairingStatusSnapshot _terminal(HostPairingState state) {
    pairingStatus = HostPairingStatusSnapshot(
      state: state,
      revision: Int64(++_revision),
    );
    return pairingStatus;
  }

  @override
  Future<void> close() async {
    await _sessionEvents.close();
    await _pairingEvents.close();
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
  Future<SessionOfferSignature> signSessionOffer(
    List<int> canonicalTranscript,
  ) => throw UnimplementedError();

  @override
  Future<PairingTranscriptSignature> signPairingTranscript(
    List<int> canonicalTranscript,
    PairingIdentityRole role,
  ) => throw UnimplementedError();
}

DeviceIdentity _desktopIdentity(String name, int seed) {
  final publicKey = List<int>.generate(32, (index) => seed + index);
  return DeviceIdentity(
    deviceId: deriveDeviceIdV1(publicKey),
    publicKeyAlgorithm: PublicKeyAlgorithm.PUBLIC_KEY_ALGORITHM_ED25519,
    publicKey: publicKey,
    displayName: name,
    platform: DevicePlatform.DEVICE_PLATFORM_MACOS,
  );
}

DeviceIdentity _mobileIdentity(String name, int seed) {
  final publicKey = List<int>.generate(32, (index) => seed + index);
  return DeviceIdentity(
    deviceId: deriveDeviceIdV1(publicKey),
    publicKeyAlgorithm: PublicKeyAlgorithm.PUBLIC_KEY_ALGORITHM_ED25519,
    publicKey: publicKey,
    displayName: name,
    platform: DevicePlatform.DEVICE_PLATFORM_IOS,
  );
}
