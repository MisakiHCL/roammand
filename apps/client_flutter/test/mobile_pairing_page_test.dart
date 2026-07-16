// SPDX-License-Identifier: MPL-2.0

import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand/mobile/identity/mobile_device_identity.dart';
import 'package:roammand/mobile/pairing/mobile_pairing_page.dart';
import 'package:roammand/mobile/pairing/qr_scanner.dart';
import 'package:roammand/mobile/widgets/mobile_page_header.dart';
import 'package:roammand/pairing/controller_pairing_models.dart';
import 'package:roammand/pairing/qr_pairing_uri.dart';
import 'package:roammand/pairing/trusted_host_repository.dart';
import 'package:roammand/pairing/trusted_host_store.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

void main() {
  testWidgets('uses camera only and claims the first valid QR exactly once', (
    tester,
  ) async {
    const now = 1_000_000;
    final scanner = _FakeScanner();
    final session = _FakeSession();
    final identity = await MobileDeviceIdentity.fromSeed(
      seed: List<int>.generate(32, (index) => index),
      displayName: 'My phone',
      platform: DevicePlatform.DEVICE_PLATFORM_ANDROID,
    );
    final repository = TrustedHostRepository(persistence: _MemoryHosts());
    await repository.initialize();

    await tester.pumpWidget(
      _app(
        MobilePairingPage(
          identity: identity,
          trustedHosts: repository,
          scanner: scanner,
          sessionFactory: () async => session,
          nowUnixMs: () => now,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('gallery'), findsNothing);
    final encoded = encodeQrPairingUri(_invitation(now));
    scanner.emit(QrScannerCode(encoded));
    scanner.emit(QrScannerCode(encoded));
    await tester.pump();
    await tester.pump();

    expect(scanner.stopCalls, 1);
    expect(session.pairCalls, 1);
    session.complete();
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await scanner.close();
    await repository.close();
  });

  testWidgets('keeps scanning after an invalid or expired QR', (tester) async {
    final scanner = _FakeScanner();
    final identity = await MobileDeviceIdentity.fromSeed(
      seed: List<int>.filled(32, 7),
      displayName: 'Phone',
      platform: DevicePlatform.DEVICE_PLATFORM_IOS,
    );
    final repository = TrustedHostRepository(persistence: _MemoryHosts());
    await repository.initialize();

    await tester.pumpWidget(
      _app(
        MobilePairingPage(
          identity: identity,
          trustedHosts: repository,
          scanner: scanner,
          sessionFactory: () async => _FakeSession(),
          nowUnixMs: () => 2_000_000,
        ),
      ),
    );
    await tester.pump();
    scanner.emit(const QrScannerCode('not-a-pairing-uri'));
    await tester.pump();

    expect(find.textContaining('invalid or expired'), findsOneWidget);
    expect(scanner.stopCalls, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await scanner.close();
    await repository.close();
  });

  testWidgets('closes the scanner route automatically after pairing succeeds', (
    tester,
  ) async {
    const now = 1_000_000;
    final scanner = _FakeScanner();
    final session = _FakeSession();
    final identity = await MobileDeviceIdentity.fromSeed(
      seed: List<int>.filled(32, 12),
      displayName: 'Phone',
      platform: DevicePlatform.DEVICE_PLATFORM_IOS,
    );
    final repository = TrustedHostRepository(persistence: _MemoryHosts());
    await repository.initialize();
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: Text('home')),
      ),
    );
    unawaited(
      navigatorKey.currentState!.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => MobilePairingPage(
            identity: identity,
            trustedHosts: repository,
            scanner: scanner,
            sessionFactory: () async => session,
            nowUnixMs: () => now,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    scanner.emit(QrScannerCode(encodeQrPairingUri(_invitation(now))));
    await tester.pump();
    await tester.pump();
    expect(find.byType(MobilePairingPage), findsOneWidget);

    session.complete();
    await tester.pumpAndSettle();

    expect(find.byType(MobilePairingPage), findsNothing);
    expect(find.text('home'), findsOneWidget);
    await scanner.close();
    await repository.close();
  });

  testWidgets('fills the scanner page and exposes floating camera controls', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    tester.view.padding = const FakeViewPadding(left: 132, right: 72);
    addTearDown(() {
      tester.view.padding = FakeViewPadding.zero;
      return tester.binding.setSurfaceSize(null);
    });
    final scanner = _FakeScanner();
    final identity = await MobileDeviceIdentity.fromSeed(
      seed: List<int>.filled(32, 8),
      displayName: 'Phone',
      platform: DevicePlatform.DEVICE_PLATFORM_IOS,
    );
    final repository = TrustedHostRepository(persistence: _MemoryHosts());
    await repository.initialize();

    await tester.pumpWidget(
      _app(
        MobilePairingPage(
          identity: identity,
          trustedHosts: repository,
          scanner: scanner,
          sessionFactory: () async => _FakeSession(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(AppBar), findsNothing);
    expect(find.text('Scan QR code'), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('fake-scanner-preview'))),
      const Size(844, 390),
    );
    expect(
      tester.getSize(find.byKey(const Key('mobile-scanner-mask'))),
      const Size(844, 390),
    );
    expect(find.byKey(const Key('mobile-scanner-close')), findsOneWidget);
    expect(find.byType(MobilePageBackButton), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.byKey(const Key('mobile-scanner-torch')), findsOneWidget);
    expect(
      find.byKey(const Key('mobile-scanner-switch-camera')),
      findsOneWidget,
    );
    expect(
      tester.getRect(find.byKey(const Key('mobile-scanner-header'))),
      const Rect.fromLTWH(0, 0, 844, mobilePageHeaderHeight),
    );
    expect(
      tester.getRect(find.byKey(const Key('mobile-scanner-close'))).left,
      greaterThanOrEqualTo(44),
    );
    expect(
      tester
          .getRect(find.byKey(const Key('mobile-scanner-switch-camera')))
          .right,
      lessThanOrEqualTo(820),
    );
    for (final buttonKey in <Key>[
      const Key('mobile-scanner-close'),
      const Key('mobile-scanner-torch'),
      const Key('mobile-scanner-switch-camera'),
    ]) {
      expect(
        find.ancestor(
          of: find.byKey(buttonKey),
          matching: find.byWidgetPredicate(
            (widget) => widget is Material && widget.shape is CircleBorder,
          ),
        ),
        findsNothing,
      );
    }

    await tester.tap(find.byKey(const Key('mobile-scanner-torch')));
    await tester.tap(find.byKey(const Key('mobile-scanner-switch-camera')));
    expect(scanner.toggleTorchCalls, 1);
    expect(scanner.switchCameraCalls, 1);

    final initialFocusArea = tester.getRect(
      find.byKey(const Key('mobile-scanner-focus-area')),
    );
    final initialMessage = tester.getRect(
      find.byKey(const Key('mobile-scanner-message')),
    );
    scanner.emit(const QrScannerCode('invalid-code'));
    await tester.pump();
    final focusArea = tester.getRect(
      find.byKey(const Key('mobile-scanner-focus-area')),
    );
    final message = tester.getRect(
      find.byKey(const Key('mobile-scanner-message')),
    );
    expect(focusArea, initialFocusArea);
    expect(message, initialMessage);
    expect(focusArea.bottom, lessThanOrEqualTo(message.top));
    expect(find.byKey(const Key('mobile-scanner-feedback')), findsOneWidget);
    expect(
      tester
          .widget<Text>(
            find.text(
              'Point the camera at the QR code shown on your computer.',
            ),
          )
          .style
          ?.fontSize,
      12,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await scanner.close();
    await repository.close();
  });

  testWidgets('does not restart while the first permission request is active', (
    tester,
  ) async {
    final startGate = Completer<void>();
    final scanner = _FakeScanner(startGate: startGate);
    final identity = await MobileDeviceIdentity.fromSeed(
      seed: List<int>.filled(32, 9),
      displayName: 'Phone',
      platform: DevicePlatform.DEVICE_PLATFORM_IOS,
    );
    final repository = TrustedHostRepository(persistence: _MemoryHosts());
    await repository.initialize();

    await tester.pumpWidget(
      _app(
        MobilePairingPage(
          identity: identity,
          trustedHosts: repository,
          scanner: scanner,
          sessionFactory: () async => _FakeSession(),
        ),
      ),
    );
    await tester.pump();
    expect(scanner.startCalls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(scanner.pauseCalls, 0);
    expect(scanner.resumeCalls, 0);
    expect(find.text('The camera could not be started.'), findsNothing);

    startGate.complete();
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await scanner.close();
    await repository.close();
  });

  testWidgets('clears a transient camera error when scanning becomes ready', (
    tester,
  ) async {
    final scanner = _FakeScanner();
    final identity = await MobileDeviceIdentity.fromSeed(
      seed: List<int>.filled(32, 10),
      displayName: 'Phone',
      platform: DevicePlatform.DEVICE_PLATFORM_IOS,
    );
    final repository = TrustedHostRepository(persistence: _MemoryHosts());
    await repository.initialize();

    await tester.pumpWidget(
      _app(
        MobilePairingPage(
          identity: identity,
          trustedHosts: repository,
          scanner: scanner,
          sessionFactory: () async => _FakeSession(),
        ),
      ),
    );
    await tester.pump();
    final initialFocusArea = tester.getRect(
      find.byKey(const Key('mobile-scanner-focus-area')),
    );

    scanner.emit(const QrScannerFailed(QrScannerFailure.initialization));
    await tester.pump();
    expect(find.text('The camera could not be started.'), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const Key('mobile-scanner-focus-area'))),
      initialFocusArea,
    );

    scanner.emit(const QrScannerReady());
    await tester.pumpAndSettle();
    expect(find.text('The camera could not be started.'), findsNothing);
    expect(
      tester.getRect(find.byKey(const Key('mobile-scanner-focus-area'))),
      initialFocusArea,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await scanner.close();
    await repository.close();
  });

  testWidgets('shows an actionable signaling failure after scanning', (
    tester,
  ) async {
    const now = 1_000_000;
    final scanner = _FakeScanner();
    final session = _FakeSession();
    final identity = await MobileDeviceIdentity.fromSeed(
      seed: List<int>.filled(32, 11),
      displayName: 'Phone',
      platform: DevicePlatform.DEVICE_PLATFORM_IOS,
    );
    final repository = TrustedHostRepository(persistence: _MemoryHosts());
    await repository.initialize();

    await tester.pumpWidget(
      _app(
        MobilePairingPage(
          identity: identity,
          trustedHosts: repository,
          scanner: scanner,
          sessionFactory: () async => session,
          nowUnixMs: () => now,
        ),
      ),
    );
    await tester.pump();
    scanner.emit(QrScannerCode(encodeQrPairingUri(_invitation(now))));
    await tester.pump();
    await tester.pump();
    session.fail(ControllerPairingError.signaling);
    await tester.pump();

    expect(find.textContaining('signaling service'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await scanner.close();
    await repository.close();
  });
}

Widget _app(Widget home) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

HostPairingInvitation _invitation(int now) {
  final publicKey = List<int>.generate(32, (index) => index + 1);
  return HostPairingInvitation(
    protocolVersion: ProtocolVersion(major: 1, minor: 0),
    kind: PairingInvitationKind.PAIRING_INVITATION_KIND_QR,
    rendezvousId: List<int>.generate(16, (index) => index),
    hostIdentity: DeviceIdentity(
      deviceId: deriveDeviceIdV1(publicKey),
      publicKeyAlgorithm: PublicKeyAlgorithm.PUBLIC_KEY_ALGORITHM_ED25519,
      publicKey: publicKey,
      displayName: 'Office Mac',
      platform: DevicePlatform.DEVICE_PLATFORM_MACOS,
    ),
    hostEphemeralPublicKey: List<int>.filled(32, 9),
    hostPublicKeyFingerprintSha256: sha256.convert(publicKey).bytes,
    signalingEndpoint: 'wss://signal.example.test/v1/connect',
    issuedAtUnixMs: Int64(now),
    expiresAtUnixMs: Int64(now + 120000),
  );
}

final class _FakeScanner implements QrScannerSession {
  _FakeScanner({this.startGate});

  final Completer<void>? startGate;
  final StreamController<QrScannerEvent> _events =
      StreamController<QrScannerEvent>.broadcast(sync: true);
  int startCalls = 0;
  int stopCalls = 0;
  int pauseCalls = 0;
  int resumeCalls = 0;
  int toggleTorchCalls = 0;
  int switchCameraCalls = 0;
  void emit(QrScannerEvent event) => _events.add(event);
  @override
  Stream<QrScannerEvent> get events => _events.stream;
  @override
  Widget buildPreview() =>
      const ColoredBox(key: Key('fake-scanner-preview'), color: Colors.black);
  @override
  Future<void> start() async {
    startCalls += 1;
    await startGate?.future;
  }

  @override
  Future<void> stop() async => stopCalls += 1;
  @override
  Future<void> pause() async => pauseCalls += 1;
  @override
  Future<void> resume() async => resumeCalls += 1;
  @override
  Future<void> toggleTorch() async => toggleTorchCalls += 1;
  @override
  Future<void> switchCamera() async => switchCameraCalls += 1;
  @override
  Future<void> close() => _events.close();
}

final class _FakeSession implements MobileControllerPairingSession {
  final StreamController<ControllerPairingSnapshot> _states =
      StreamController<ControllerPairingSnapshot>.broadcast(sync: true);
  final Completer<ControllerPairingSnapshot> result =
      Completer<ControllerPairingSnapshot>();
  int pairCalls = 0;
  void complete() {
    if (!result.isCompleted) {
      final accepted = ControllerPairingSnapshot(
        state: ControllerPairingState.accepted,
      );
      _states.add(accepted);
      result.complete(accepted);
    }
  }

  void fail(ControllerPairingError error) {
    if (result.isCompleted) return;
    final failed = ControllerPairingSnapshot(
      state: ControllerPairingState.failed,
      error: error,
    );
    _states.add(failed);
    result.complete(failed);
  }

  @override
  Stream<ControllerPairingSnapshot> get states => _states.stream;
  @override
  ControllerPairingSnapshot get snapshot =>
      ControllerPairingSnapshot(state: ControllerPairingState.idle);
  @override
  Future<ControllerPairingSnapshot> pairQr(HostPairingInvitation invitation) {
    pairCalls += 1;
    return result.future;
  }

  @override
  Future<void> cancel() async {}
  @override
  Future<void> close() async {
    if (!result.isCompleted) result.complete(snapshot);
    await _states.close();
  }
}

final class _MemoryHosts implements TrustedHostPersistence {
  @override
  Future<List<TrustedHostBinding>> load() async => <TrustedHostBinding>[];
  @override
  Future<void> save(Iterable<TrustedHostBinding> bindings) async {}
}
