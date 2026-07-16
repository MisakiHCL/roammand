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
  final StreamController<QrScannerEvent> _events =
      StreamController<QrScannerEvent>.broadcast(sync: true);
  int stopCalls = 0;
  void emit(QrScannerEvent event) => _events.add(event);
  @override
  Stream<QrScannerEvent> get events => _events.stream;
  @override
  Widget buildPreview() => const ColoredBox(color: Colors.black);
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async => stopCalls += 1;
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
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
