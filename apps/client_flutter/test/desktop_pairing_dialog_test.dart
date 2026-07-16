// SPDX-License-Identifier: MPL-2.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/desktop/pairing/desktop_pairing_dialog.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand/pairing/controller_pairing_models.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

void main() {
  testWidgets('normalizes code and shows Host fingerprint and four-word SAS', (
    tester,
  ) async {
    final session = FakeDesktopPairingSession();
    await tester.pumpWidget(_app(session));
    await tester.tap(find.text('Pair a computer'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('desktop-pairing-code')),
      'abcd-2345',
    );
    await tester.tap(find.text('Pair'));
    await tester.pump();
    expect(session.code, 'ABCD2345');
    expect(session.endpoint, Uri.parse(_endpoint));

    session.waitingForDecision();
    await tester.pump();
    expect(find.text('Office Mac'), findsOneWidget);
    expect(find.textContaining('51515151'), findsOneWidget);
    expect(find.text('Compare these four words'), findsOneWidget);
    for (final word in session.words) {
      expect(find.text(word), findsOneWidget);
    }
    expect(find.text('Waiting for approval on the Host…'), findsOneWidget);
    expect(find.text('Allow control'), findsNothing);

    session.finish(ControllerPairingState.accepted);
    await tester.pumpAndSettle();
    expect(find.text('Computer paired'), findsOneWidget);
  });

  testWidgets(
    'invalid code, cancellation, and Chinese narrow layout are safe',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = FakeDesktopPairingSession();
      await tester.pumpWidget(_app(session, locale: const Locale('zh')));
      await tester.tap(find.text('配对电脑'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('desktop-pairing-code')),
        'bad',
      );
      await tester.tap(find.text('配对'));
      await tester.pump();
      expect(find.text('配对码无效。'), findsOneWidget);
      expect(session.startCount, 0);

      await tester.enterText(
        find.byKey(const Key('desktop-pairing-code')),
        'ABCD2345',
      );
      await tester.tap(find.text('配对'));
      await tester.pump();
      await tester.tap(find.text('取消配对'));
      await tester.pumpAndSettle();
      expect(session.cancelCount, 1);
      expect(find.text('配对已取消'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

const _endpoint = 'wss://signal.example.test/v1/connect';

Widget _app(FakeDesktopPairingSession session, {Locale? locale}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => showDesktopPairingDialog(
            context,
            signalingEndpoint: Uri.parse(_endpoint),
            sessionFactory: () async => session,
          ),
          child: Text(
            locale?.languageCode == 'zh' ? '配对电脑' : 'Pair a computer',
          ),
        ),
      ),
    ),
  ),
);

final class FakeDesktopPairingSession implements DesktopPairingSession {
  final StreamController<ControllerPairingSnapshot> _states =
      StreamController<ControllerPairingSnapshot>.broadcast(sync: true);
  final Completer<ControllerPairingSnapshot> _result =
      Completer<ControllerPairingSnapshot>();
  final List<String> words = const <String>[
    'abandon',
    'ability',
    'able',
    'about',
  ];
  ControllerPairingSnapshot _snapshot = ControllerPairingSnapshot(
    state: ControllerPairingState.idle,
  );
  String? code;
  Uri? endpoint;
  int startCount = 0;
  int cancelCount = 0;

  @override
  Stream<ControllerPairingSnapshot> get states => _states.stream;

  @override
  ControllerPairingSnapshot get snapshot => _snapshot;

  @override
  Future<ControllerPairingSnapshot> pairDesktopCode({
    required String pairingCode,
    required Uri signalingEndpoint,
  }) {
    startCount += 1;
    code = pairingCode;
    endpoint = signalingEndpoint;
    _emit(ControllerPairingSnapshot(state: ControllerPairingState.connecting));
    return _result.future;
  }

  void waitingForDecision() {
    final publicKey = List<int>.generate(32, (index) => index + 1);
    _emit(
      ControllerPairingSnapshot(
        state: ControllerPairingState.waitingHostDecision,
        hostIdentity: DeviceIdentity(
          deviceId: deriveDeviceIdV1(publicKey),
          publicKeyAlgorithm: PublicKeyAlgorithm.PUBLIC_KEY_ALGORITHM_ED25519,
          publicKey: publicKey,
          displayName: 'Office Mac',
          platform: DevicePlatform.DEVICE_PLATFORM_MACOS,
        ),
        hostFingerprintSha256: List<int>.filled(32, 0x51),
        sasWords: words,
        expiresAtUnixMs: DateTime.now().millisecondsSinceEpoch + 120000,
      ),
    );
  }

  void finish(ControllerPairingState state) {
    final terminal = ControllerPairingSnapshot(state: state);
    _emit(terminal);
    if (!_result.isCompleted) {
      _result.complete(terminal);
    }
  }

  void _emit(ControllerPairingSnapshot snapshot) {
    _snapshot = snapshot;
    _states.add(snapshot);
  }

  @override
  Future<void> cancel() async {
    cancelCount += 1;
    finish(ControllerPairingState.cancelled);
  }

  @override
  Future<void> close() async {
    if (!_result.isCompleted) {
      finish(ControllerPairingState.cancelled);
    }
    await _states.close();
  }
}
