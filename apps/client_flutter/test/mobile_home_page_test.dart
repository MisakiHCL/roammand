// SPDX-License-Identifier: MPL-2.0

import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/about/roammand_links.dart';
import 'package:roammand/design_system/roammand_colors.dart';
import 'package:roammand/desktop/remote/remote_desktop_controller.dart';
import 'package:roammand/l10n/app_locale_controller.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand/mobile/home/mobile_home_page.dart';
import 'package:roammand/mobile/identity/mobile_device_identity.dart';
import 'package:roammand/network/network_service_controller.dart';
import 'package:roammand/pairing/trusted_host_repository.dart';
import 'package:roammand/pairing/trusted_host_store.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

void main() {
  testWidgets('shows the saved mobile device name and a plain settings icon', (
    tester,
  ) async {
    final repository = TrustedHostRepository(persistence: _MemoryHosts());
    await repository.initialize();
    final networkServices = NetworkServiceController.transient();
    addTearDown(networkServices.dispose);
    final identity = await MobileDeviceIdentity.fromSeed(
      seed: List<int>.generate(mobileIdentitySeedBytes, (index) => index),
      displayName: 'Pocket iPhone',
      platform: DevicePlatform.DEVICE_PLATFORM_IOS,
    );

    await tester.pumpWidget(
      _app(
        MobileHomePage(
          trustedHosts: repository,
          identity: identity,
          networkServices: networkServices,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mobile-device-name')), findsOneWidget);
    expect(find.text('Device name: Pocket iPhone'), findsOneWidget);
    final settings = tester.widget<IconButton>(
      find.byKey(const Key('mobile-settings')),
    );
    expect(settings.style?.backgroundColor?.resolve(<WidgetState>{}), isNull);
    expect(
      settings.style?.foregroundColor?.resolve(<WidgetState>{}),
      RoammandColors.textPrimary,
    );
  });

  testWidgets('keeps the empty state usable on a narrow localized phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = TrustedHostRepository(persistence: _MemoryHosts());
    await repository.initialize();
    final networkServices = NetworkServiceController.transient();
    addTearDown(networkServices.dispose);

    await tester.pumpWidget(
      _app(
        MobileHomePage(
          trustedHosts: repository,
          pairingPageBuilder: (_) => const SizedBox.shrink(),
          networkServices: networkServices,
        ),
        locale: const Locale('zh'),
        textScaler: const TextScaler.linear(1.4),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('我的电脑'), findsOneWidget);
    expect(find.text('扫描电脑二维码'), findsOneWidget);
    expect(find.text('请先在 Mac 上开始'), findsOneWidget);
    expect(find.textContaining('这台设备是控制端'), findsOneWidget);
    expect(find.text('在要控制的 Mac 上安装并打开 Roammand。'), findsOneWidget);
    expect(find.text('获取 Roammand Mac 版'), findsOneWidget);
    expect(find.text('了解 Roammand 如何工作'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens Mac download and in-app help from the empty state', (
    tester,
  ) async {
    final repository = TrustedHostRepository(persistence: _MemoryHosts());
    await repository.initialize();
    final opened = <Uri>[];

    await tester.pumpWidget(
      _app(
        MobileHomePage(
          trustedHosts: repository,
          pairingPageBuilder: (_) => const SizedBox.shrink(),
          linkLauncher: (uri) async {
            opened.add(uri);
            return true;
          },
          versionLoader: () async => '1.0.0 (3)',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('mobile-download-macos')));
    await tester.tap(find.byKey(const Key('mobile-download-macos')));
    await tester.pump();
    expect(opened, <Uri>[macOsDownloadPageUri]);

    await tester.ensureVisible(find.byKey(const Key('mobile-open-about')));
    await tester.tap(find.byKey(const Key('mobile-open-about')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mobile-about-header')), findsOneWidget);
    expect(find.text('About Roammand'), findsWidgets);
    expect(find.text('Version 1.0.0 (3)'), findsOneWidget);
  });

  testWidgets('uses an in-content landscape hero and changes language', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = TrustedHostRepository(persistence: _MemoryHosts());
    await repository.initialize();
    final networkServices = NetworkServiceController.transient();
    addTearDown(networkServices.dispose);
    AppLocalePreference? selectedPreference;

    await tester.pumpWidget(
      _app(
        MobileHomePage(
          trustedHosts: repository,
          pairingPageBuilder: (_) => const SizedBox.shrink(),
          networkServices: networkServices,
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
    expect(find.byKey(const Key('mobile-settings')), findsOneWidget);
    expect(tester.widget<Text>(find.text('我的电脑')).style?.fontSize, 24);
    await tester.tap(find.byKey(const Key('mobile-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-language-selector')));
    await tester.pumpAndSettle();
    expect(find.text('跟随系统'), findsWidgets);
    expect(find.text('English'), findsWidgets);
    expect(find.text('简体中文'), findsWidgets);

    await tester.tap(find.text('English').last);
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

  testWidgets('renames one paired computer only on this device', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() {
      tester.view.viewInsets = FakeViewPadding.zero;
      return tester.binding.setSurfaceSize(null);
    });
    final first = _host(1)..hostIdentity.displayName = 'Roammand Host';
    final second = _host(2)..hostIdentity.displayName = 'Roammand Host';
    final persistence = _MemoryHosts()
      ..bindings = <TrustedHostBinding>[first, second];
    final repository = TrustedHostRepository(persistence: persistence);
    await repository.initialize();

    await tester.pumpWidget(
      _app(
        MobileHomePage(
          trustedHosts: repository,
          launchRemote: (context, target) async => false,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Roammand Host'), findsNWidgets(2));
    await tester.tap(find.byKey(const Key('rename-trusted-host')).first);
    await tester.pump();
    tester.view.viewInsets = const FakeViewPadding(bottom: 180);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('trusted-host-rename-dialog')), findsOneWidget);
    final renameField = tester.widget<TextField>(
      find.byKey(const Key('trusted-host-name-field')),
    );
    expect(renameField.cursorOpacityAnimates, isFalse);
    expect(renameField.enableIMEPersonalizedLearning, isFalse);
    expect(
      tester.getSize(find.byKey(const Key('trusted-host-name-field'))).height,
      48,
    );
    expect(
      tester.getSize(find.byKey(const Key('save-trusted-host-name'))).height,
      36,
    );
    expect(tester.takeException(), isNull);
    await tester.enterText(
      find.byKey(const Key('trusted-host-name-field')),
      'Studio Mac',
    );
    await tester.ensureVisible(find.byKey(const Key('save-trusted-host-name')));
    await tester.tap(find.byKey(const Key('save-trusted-host-name')));
    await tester.pumpAndSettle();

    expect(find.text('Studio Mac'), findsOneWidget);
    expect(find.text('Roammand Host'), findsOneWidget);
    expect(repository.hosts.first.localAlias, 'Studio Mac');
    expect(repository.hosts.first.hostIdentity.displayName, 'Roammand Host');
    expect(repository.hosts.last.localAlias, isNull);
    expect(find.text('Mac'), findsNWidgets(2));
    expect(find.textContaining('Safety code:'), findsNWidgets(2));
  });

  testWidgets('deletes a paired computer only after confirmation', (
    tester,
  ) async {
    final persistence = _MemoryHosts()
      ..bindings = <TrustedHostBinding>[_host(1), _host(2)];
    final repository = TrustedHostRepository(persistence: persistence);
    await repository.initialize();

    await tester.pumpWidget(
      _app(
        MobileHomePage(
          trustedHosts: repository,
          launchRemote: (context, target) async => false,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('delete-trusted-host')).first);
    await tester.pumpAndSettle();
    expect(find.text('Delete Office Mac 1 from this device?'), findsOneWidget);
    expect(repository.hosts, hasLength(2));

    await tester.tap(find.byKey(const Key('confirm-delete-trusted-host')));
    await tester.pumpAndSettle();

    expect(repository.hosts, hasLength(1));
    expect(repository.hosts.single.displayName, 'Office Mac 2');
    expect(persistence.bindings.single.displayOrder, 0);
    expect(find.text('Office Mac 1'), findsNothing);
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
