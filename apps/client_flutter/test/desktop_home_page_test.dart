// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:convert';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/desktop/home/desktop_home_page.dart';
import 'package:roammand/desktop/home/trusted_computers_controller.dart';
import 'package:roammand/desktop/remote/remote_desktop_controller.dart';
import 'package:roammand/design_system/roammand_back_button.dart';
import 'package:roammand/design_system/roammand_theme.dart';
import 'package:roammand/l10n/app_locale_controller.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand/network/network_service_controller.dart';
import 'package:roammand/pairing/trusted_host_repository.dart';
import 'package:roammand/pairing/trusted_host_store.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

void main() {
  testWidgets('opens on This computer and lists it first', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final persistence = HomeMemoryPersistence();
    await tester.pumpWidget(
      _app(
        DesktopHomePage(
          hostPage: const Text('this-computer-content'),
          trustedComputersController: _trustedController(persistence),
          signalingEndpoint: _endpoint,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('desktop-navigation-sidebar')), findsOneWidget);
    expect(find.byKey(const Key('desktop-sidebar-brand')), findsOneWidget);
    expect(find.text('this-computer-content'), findsOneWidget);
    expect(find.text('My computers'), findsNothing);

    await tester.tap(find.text('Remote control'));
    await tester.pumpAndSettle();
    expect(find.text('My computers'), findsOneWidget);
  });

  testWidgets('uses the same This computer default on Windows', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final persistence = HomeMemoryPersistence();
    await tester.pumpWidget(
      _app(
        DesktopHomePage(
          hostPage: const Text('this-computer-content'),
          trustedComputersController: _trustedController(persistence),
          signalingEndpoint: _endpoint,
        ),
        platform: TargetPlatform.windows,
      ),
    );
    await tester.pumpAndSettle();

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.selectedIndex, 0);
    expect((rail.destinations.first.label as Text).data, 'This computer');
    expect(find.text('this-computer-content'), findsOneWidget);
    expect(find.text('My computers'), findsNothing);

    await tester.tap(find.text('Remote control'));
    await tester.pumpAndSettle();
    expect(find.text('My computers'), findsOneWidget);
  });

  testWidgets('fits the empty remote page in the default macOS window', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final persistence = HomeMemoryPersistence();
    await tester.pumpWidget(
      _app(
        DesktopHomePage(
          hostPage: const Text('this-computer-content'),
          trustedComputersController: _trustedController(persistence),
          signalingEndpoint: _endpoint,
        ),
        theme: RoammandTheme.dark(
          compactDesktop: true,
        ).copyWith(platform: TargetPlatform.macOS),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remote control'));
    await tester.pumpAndSettle();

    final list = find.byKey(const Key('desktop-remote-control-list'));
    final scrollable = find.descendant(
      of: list,
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable).position;

    expect(position.maxScrollExtent, 0);
    expect(find.text('No computers paired yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('connects only from a persisted Host and timestamps success', (
    tester,
  ) async {
    final persistence = HomeMemoryPersistence()
      ..bindings = <TrustedHostBinding>[_binding()];
    final trusted = _trustedController(persistence);
    RemoteDesktopTarget? launched;
    final launchGate = Completer<bool>();
    var launchCount = 0;
    await tester.pumpWidget(
      _app(
        DesktopHomePage(
          hostPage: const SizedBox.shrink(),
          trustedComputersController: trusted,
          signalingEndpoint: _endpoint,
          nowUnixMs: () => 2000,
          launchRemote: (context, target) {
            launchCount += 1;
            launched = target;
            return launchGate.future;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _openRemoteControl(tester);

    expect(find.text('My computers'), findsOneWidget);
    expect(find.text('Office Mac'), findsOneWidget);
    expect(find.byKey(const Key('host-connection-descriptor')), findsNothing);
    final connectAction = find.text('Connect');
    await tester.ensureVisible(connectAction);
    await tester.pumpAndSettle();
    await tester.tap(connectAction);
    await tester.pump();
    await tester.tap(find.text('Connecting…'));
    expect(launchCount, 1);
    launchGate.complete(true);
    await tester.pumpAndSettle();

    expect(launched, isNotNull);
    expect(launched!.hostIdentity.displayName, 'Office Mac');
    expect(launched!.signalingEndpoint.scheme, 'wss');
    expect(
      persistence.bindings.single.lastSuccessfulConnectionAtUnixMs,
      Int64(2000),
    );
  });

  testWidgets('explains that deletion is local and does not revoke Host', (
    tester,
  ) async {
    final persistence = HomeMemoryPersistence()
      ..bindings = <TrustedHostBinding>[_binding()];
    await tester.pumpWidget(
      _app(
        DesktopHomePage(
          hostPage: const SizedBox.shrink(),
          trustedComputersController: _trustedController(persistence),
          signalingEndpoint: _endpoint,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _openRemoteControl(tester);

    final deleteAction = find.text('Delete');
    await tester.ensureVisible(deleteAction);
    await tester.pumpAndSettle();
    await tester.tap(deleteAction);
    await tester.pumpAndSettle();
    expect(find.textContaining('fully remove access'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Office Mac'), findsOneWidget);

    await tester.ensureVisible(deleteAction);
    await tester.pumpAndSettle();
    await tester.tap(deleteAction);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete locally'));
    await tester.pumpAndSettle();
    expect(find.text('No computers paired yet'), findsOneWidget);
    expect(persistence.bindings, isEmpty);
  });

  testWidgets(
    'shows localized empty and narrow states without maintenance UI',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final persistence = HomeMemoryPersistence();
      await tester.pumpWidget(
        _app(
          DesktopHomePage(
            hostPage: const Text('本机内容'),
            trustedComputersController: _trustedController(persistence),
            signalingEndpoint: _endpoint,
          ),
          locale: const Locale('zh'),
        ),
      );
      await tester.pumpAndSettle();

      final navigation = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navigation.selectedIndex, 0);
      expect(
        (navigation.destinations.first as NavigationDestination).label,
        '此电脑',
      );
      expect(find.text('本机内容'), findsOneWidget);

      await tester.tap(find.text('远程控制'));
      await tester.pumpAndSettle();

      expect(find.text('我的电脑'), findsOneWidget);
      expect(find.text('尚未配对电脑'), findsOneWidget);
      expect(find.text('配对电脑'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.textContaining('连接描述符'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('offers system, English, and Simplified Chinese', (tester) async {
    final persistence = HomeMemoryPersistence();
    final networkServices = NetworkServiceController.transient();
    addTearDown(networkServices.dispose);
    AppLocalePreference? selectedPreference;
    await tester.pumpWidget(
      _app(
        DesktopHomePage(
          hostPage: const Text('this-computer-content'),
          trustedComputersController: _trustedController(persistence),
          signalingEndpoint: _endpoint,
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

    await tester.tap(find.byKey(const Key('desktop-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-language-selector')));
    await tester.pumpAndSettle();
    expect(find.text('跟随系统'), findsWidgets);
    expect(find.text('English'), findsWidgets);
    expect(find.text('简体中文'), findsWidgets);

    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    expect(selectedPreference, AppLocalePreference.english);
  });

  testWidgets(
    'keeps macOS navigation fixed while detail pages cover only the right pane',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final persistence = HomeMemoryPersistence();
      final networkServices = NetworkServiceController.transient();
      addTearDown(networkServices.dispose);
      await tester.pumpWidget(
        _app(
          DesktopHomePage(
            hostPage: const Text('this-computer-content'),
            trustedComputersController: _trustedController(persistence),
            signalingEndpoint: _endpoint,
            networkServices: networkServices,
            linkLauncher: (_) async => true,
            versionLoader: () async => '1.0.0 (3)',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sidebar = find.byKey(const Key('desktop-navigation-sidebar'));
      await tester.tap(find.byKey(const Key('desktop-settings')));
      await tester.pumpAndSettle();

      final detail = find.byKey(const Key('desktop-detail-panel'));
      expect(sidebar, findsOneWidget);
      expect(detail, findsOneWidget);
      expect(
        tester.getRect(detail).left,
        greaterThanOrEqualTo(tester.getRect(sidebar).right),
      );
      expect(find.text('Settings'), findsWidgets);
      expect(find.byType(RoammandBackButton), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

      await tester.tap(find.byKey(const Key('settings-about-roammand')));
      await tester.pumpAndSettle();
      expect(find.text('Make this Mac reachable'), findsOneWidget);
      expect(find.byKey(const Key('about-download-ios')), findsOneWidget);
      expect(sidebar, findsOneWidget);
      expect(detail, findsOneWidget);

      await tester.tap(find.byKey(const Key('desktop-detail-back')));
      await tester.pumpAndSettle();
      expect(find.text('General'), findsOneWidget);

      await tester.tap(find.byKey(const Key('settings-network-services')));
      await tester.pumpAndSettle();
      expect(find.text('Connection service'), findsWidgets);
      expect(detail, findsOneWidget);

      await tester.tap(find.byKey(const Key('desktop-detail-back')));
      await tester.pumpAndSettle();
      expect(find.text('General'), findsOneWidget);

      await tester.tap(find.byKey(const Key('desktop-detail-back')));
      await tester.pumpAndSettle();
      expect(detail, findsNothing);

      await tester.tap(find.byKey(const Key('desktop-settings')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings-network-services')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('This computer').first);
      await tester.pumpAndSettle();
      expect(detail, findsNothing);
      expect(find.text('this-computer-content'), findsOneWidget);
    },
  );

  test(
    'developer descriptor parser remains strict but absent from product UI',
    () {
      final valid = jsonDecode(_descriptor()) as Map<String, dynamic>;
      expect(
        parseHostConnectionDescriptor(jsonEncode(valid)),
        isA<RemoteDesktopTarget>(),
      );

      for (final changed in <Map<String, dynamic>>[
        <String, dynamic>{...valid, 'privateKey': 'secret'},
        <String, dynamic>{...valid, 'version': 2},
        <String, dynamic>{...valid, 'signaling': 'ws://example.test/v1/ws'},
      ]) {
        expect(
          () => parseHostConnectionDescriptor(jsonEncode(changed)),
          throwsA(isA<HostConnectionDescriptorException>()),
        );
      }
    },
  );
}

Future<void> _openRemoteControl(WidgetTester tester) async {
  await tester.tap(find.text('Remote control'));
  await tester.pumpAndSettle();
}

const _endpoint = 'wss://signal.example.test/v1/connect';

Widget _app(
  Widget home, {
  Locale? locale,
  TargetPlatform platform = TargetPlatform.macOS,
  ThemeData? theme,
}) => MaterialApp(
  locale: locale,
  theme: theme ?? ThemeData(platform: platform),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

TrustedComputersController _trustedController(
  HomeMemoryPersistence persistence,
) => TrustedComputersController(
  repositoryFactory: () async =>
      TrustedHostRepository(persistence: persistence),
);

final class HomeMemoryPersistence implements TrustedHostPersistence {
  List<TrustedHostBinding> bindings = <TrustedHostBinding>[];

  @override
  Future<List<TrustedHostBinding>> load() async =>
      bindings.map((binding) => binding.deepCopy()).toList();

  @override
  Future<void> save(Iterable<TrustedHostBinding> bindings) async {
    this.bindings = bindings.map((binding) => binding.deepCopy()).toList();
  }
}

TrustedHostBinding _binding() {
  final publicKey = List<int>.generate(32, (index) => index + 1);
  return TrustedHostBinding(
    hostIdentity: DeviceIdentity(
      deviceId: deriveDeviceIdV1(publicKey),
      publicKeyAlgorithm: PublicKeyAlgorithm.PUBLIC_KEY_ALGORITHM_ED25519,
      publicKey: publicKey,
      displayName: 'Office Mac',
      platform: DevicePlatform.DEVICE_PLATFORM_MACOS,
    ),
    signalingEndpoint: _endpoint,
    pairedAtUnixMs: Int64(1000),
  );
}

String _descriptor() {
  final binding = _binding();
  return encodeHostConnectionDescriptor(
    RemoteDesktopTarget(
      hostIdentity: binding.hostIdentity,
      signalingEndpoint: Uri.parse(binding.signalingEndpoint),
    ),
  );
}
