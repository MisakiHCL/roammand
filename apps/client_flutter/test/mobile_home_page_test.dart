// SPDX-License-Identifier: MPL-2.0

import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/desktop/remote/remote_desktop_controller.dart';
import 'package:roammand/l10n/app_locale_controller.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand/mobile/home/mobile_home_page.dart';
import 'package:roammand/pairing/trusted_host_repository.dart';
import 'package:roammand/pairing/trusted_host_store.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

void main() {
  testWidgets('keeps the empty state usable on a narrow localized phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = TrustedHostRepository(persistence: _MemoryHosts());
    await repository.initialize();

    await tester.pumpWidget(
      _app(
        MobileHomePage(
          trustedHosts: repository,
          pairingPageBuilder: (_) => const SizedBox.shrink(),
        ),
        locale: const Locale('zh'),
        textScaler: const TextScaler.linear(1.4),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('我的电脑'), findsOneWidget);
    expect(find.text('扫描电脑二维码'), findsOneWidget);
    expect(find.text('尚未配对电脑'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses an in-content landscape hero and changes language', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = TrustedHostRepository(persistence: _MemoryHosts());
    await repository.initialize();
    AppLocalePreference? selectedPreference;

    await tester.pumpWidget(
      _app(
        MobileHomePage(
          trustedHosts: repository,
          pairingPageBuilder: (_) => const SizedBox.shrink(),
          localePreference: AppLocalePreference.system,
          onLocalePreferenceChanged: (preference) async {
            selectedPreference = preference;
          },
        ),
        locale: const Locale('zh'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(ListView), findsOneWidget);
    expect(find.byKey(const Key('mobile-language-menu')), findsOneWidget);
    expect(tester.widget<Text>(find.text('我的电脑')).style?.fontSize, 24);
    await tester.tap(find.byKey(const Key('mobile-language-menu')));
    await tester.pumpAndSettle();
    expect(find.text('跟随系统'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('简体中文'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(selectedPreference, AppLocalePreference.english);
    expect(tester.takeException(), isNull);
  });

  testWidgets('launches a trusted Host and records only proven connections', (
    tester,
  ) async {
    final persistence = _MemoryHosts()
      ..bindings = <TrustedHostBinding>[_host(1)];
    final repository = TrustedHostRepository(persistence: persistence);
    await repository.initialize();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
    var connected = false;
    final targets = <RemoteDesktopTarget>[];

    await tester.pumpWidget(
      _app(
        MobileHomePage(
          trustedHosts: repository,
          launchRemote: (context, target) async {
            targets.add(target);
            return connected;
          },
          nowUnixMs: () => 5000,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Office Mac 1'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
    await tester.tap(find.text('Connect'));
    await _pumpUntilConnectReady(tester, expectedButtons: 1);
    expect(repository.hosts.single.lastSuccessfulConnectionAtUnixMs, 0);

    connected = true;
    await tester.tap(find.text('Connect'));
    await _pumpUntilConnectReady(tester, expectedButtons: 1);
    expect(repository.hosts.single.lastSuccessfulConnectionAtUnixMs, 5000);
    expect(targets, hasLength(2));
    expect(
      targets.last.hostIdentity.deviceId,
      repository.hosts.single.hostIdentity.deviceId,
    );
    expect(
      targets.last.signalingEndpoint,
      Uri.parse('wss://signal.example.test/v1/connect'),
    );
  });

  testWidgets('permits only one in-flight mobile session launcher', (
    tester,
  ) async {
    final persistence = _MemoryHosts()
      ..bindings = <TrustedHostBinding>[_host(1), _host(2)];
    final repository = TrustedHostRepository(persistence: persistence);
    await repository.initialize();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
    final launched = Completer<bool>();
    var launchCount = 0;

    await tester.pumpWidget(
      _app(
        MobileHomePage(
          trustedHosts: repository,
          launchRemote: (context, target) {
            launchCount += 1;
            return launched.future;
          },
        ),
      ),
    );
    await tester.pump();

    final connectButtons = find.widgetWithText(FilledButton, 'Connect');
    expect(connectButtons, findsNWidgets(2));
    await tester.tap(connectButtons.first);
    await tester.pump();
    await tester.tap(connectButtons.last, warnIfMissed: false);
    await tester.pump();
    expect(launchCount, 1);

    launched.complete(false);
    await _pumpUntilConnectReady(tester, expectedButtons: 2);
    expect(find.widgetWithText(FilledButton, 'Connect'), findsNWidgets(2));
  });
}

Future<void> _pumpUntilConnectReady(
  WidgetTester tester, {
  required int expectedButtons,
}) async {
  for (var attempt = 0; attempt < 20; attempt += 1) {
    await tester.pump();
    if (find.widgetWithText(FilledButton, 'Connect').evaluate().length ==
        expectedButtons) {
      return;
    }
  }
  fail('mobile connect action did not become ready');
}

Widget _app(
  Widget home, {
  Locale? locale,
  TextScaler textScaler = TextScaler.noScaling,
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: textScaler),
    child: child!,
  ),
  home: home,
);

final class _MemoryHosts implements TrustedHostPersistence {
  List<TrustedHostBinding> bindings = <TrustedHostBinding>[];

  @override
  Future<List<TrustedHostBinding>> load() async =>
      bindings.map((item) => item.deepCopy()).toList();

  @override
  Future<void> save(Iterable<TrustedHostBinding> values) async {
    bindings = values.map((item) => item.deepCopy()).toList();
  }
}

TrustedHostBinding _host(int marker) {
  final key = List<int>.generate(32, (index) => index + marker);
  return TrustedHostBinding(
    hostIdentity: DeviceIdentity(
      deviceId: deriveDeviceIdV1(key),
      publicKeyAlgorithm: PublicKeyAlgorithm.PUBLIC_KEY_ALGORITHM_ED25519,
      publicKey: key,
      displayName: 'Office Mac $marker',
      platform: DevicePlatform.DEVICE_PLATFORM_MACOS,
    ),
    signalingEndpoint: 'wss://signal.example.test/v1/connect',
    pairedAtUnixMs: Int64(1000),
    displayOrder: marker - 1,
  );
}
