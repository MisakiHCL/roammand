// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/design_system/roammand_back_button.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand/mobile/widgets/mobile_page_header.dart';
import 'package:roammand/network/network_service_configuration.dart';
import 'package:roammand/network/network_service_controller.dart';
import 'package:roammand/settings/network/network_service_settings_page.dart';

void main() {
  testWidgets('saves a custom profile and restores official defaults', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = NetworkServiceController.transient();
    await tester.pumpWidget(_app(controller));
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(find.byType(RoammandBackButton), findsOneWidget);
    expect(
      find.byKey(const Key('desktop-network-settings-back')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

    await tester.tap(find.text('Custom service'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('network-signaling-endpoint')),
      'wss://custom.example.test/v1/connect',
    );
    await _tapVisible(tester, find.byKey(const Key('network-save')));
    await tester.pumpAndSettle();

    expect(controller.configuration.kind, NetworkServiceProfileKind.custom);
    expect(
      controller.configuration.signalingEndpoint,
      Uri.parse('wss://custom.example.test/v1/connect'),
    );

    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    await _tapVisible(
      tester,
      find.byKey(const Key('network-restore-defaults')),
    );
    await tester.pumpAndSettle();

    expect(controller.configuration.kind, NetworkServiceProfileKind.official);
    expect(controller.configuration.signalingEndpoint.scheme, 'wss');
    controller.dispose();
  });

  testWidgets('rejects a non-STUN ICE address before persistence', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = NetworkServiceController.transient();
    await tester.pumpWidget(_app(controller));
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom service'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('network-stun-urls')),
      'turn:turn.example.test:3478',
    );
    await _tapVisible(tester, find.byKey(const Key('network-save')));
    await tester.pump();

    expect(
      find.textContaining('Enter only valid stun: or stuns: addresses'),
      findsOneWidget,
    );
    expect(controller.configuration.kind, NetworkServiceProfileKind.official);
    controller.dispose();
  });

  testWidgets('requires confirmation before restarting a desktop Host', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = NetworkServiceController.transient();
    await tester.pumpWidget(_app(controller, warnAboutHostRestart: true));
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom service'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('network-signaling-endpoint')),
      'wss://custom.example.test/v1/connect',
    );
    await _tapVisible(tester, find.byKey(const Key('network-save')));
    await tester.pumpAndSettle();

    expect(
      find.text("Change this computer's network service?"),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(controller.configuration.kind, NetworkServiceProfileKind.official);
    controller.dispose();
  });

  testWidgets('remains scrollable on a narrow localized phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = NetworkServiceController.transient();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: NetworkServiceSettingsPage(
          controller: controller,
          warnAboutHostRestart: false,
          mobileContext: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(MobilePageNavigationHeader), findsOneWidget);
    expect(
      find.byKey(const Key('mobile-network-settings-back')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('network-profile-custom')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('network-save')));
    await tester.pumpAndSettle();

    expect(find.text('保存设置'), findsOneWidget);
    expect(tester.takeException(), isNull);
    controller.dispose();
  });
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

Widget _app(
  NetworkServiceController controller, {
  bool warnAboutHostRestart = false,
}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => NetworkServiceSettingsPage(
                controller: controller,
                warnAboutHostRestart: warnAboutHostRestart,
              ),
            ),
          ),
          child: const Text('Open settings'),
        ),
      ),
    ),
  ),
);
