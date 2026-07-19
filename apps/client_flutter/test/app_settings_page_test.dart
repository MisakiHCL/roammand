// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/l10n/app_locale_controller.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand/mobile/widgets/mobile_page_header.dart';
import 'package:roammand/network/network_service_controller.dart';
import 'package:roammand/settings/app_settings_page.dart';
import 'package:roammand/settings/uninstall/app_uninstaller.dart';

void main() {
  testWidgets('groups language, connection, and installed-app uninstall', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final networkServices = NetworkServiceController.transient();
    addTearDown(networkServices.dispose);
    final uninstaller = _FakeUninstaller();
    AppLocalePreference? selectedLocale;
    var preparedForUninstall = false;

    await tester.pumpWidget(
      _app(
        AppSettingsPage(
          localePreference: AppLocalePreference.system,
          onLocalePreferenceChanged: (preference) async {
            selectedLocale = preference;
          },
          networkServices: networkServices,
          mobileContext: false,
          uninstaller: uninstaller,
          beforeUninstall: () async {
            preparedForUninstall = true;
          },
          linkLauncher: (_) async => true,
          versionLoader: () async => '1.0.0 (3)',
        ),
        platform: TargetPlatform.macOS,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('General'), findsOneWidget);
    expect(find.text('Connection'), findsOneWidget);
    expect(find.text('About & help'), findsOneWidget);
    expect(find.text('Advanced'), findsOneWidget);
    expect(find.byKey(const Key('settings-about-roammand')), findsOneWidget);
    expect(
      find.byType(DropdownButtonFormField<AppLocalePreference>),
      findsNothing,
    );
    expect(find.byIcon(Icons.translate_rounded), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-language-selector')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    expect(selectedLocale, AppLocalePreference.english);

    await tester.tap(find.byKey(const Key('settings-network-services')));
    await tester.pumpAndSettle();
    expect(find.text('Connection service'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('settings-about-roammand')),
    );
    await tester.tap(find.byKey(const Key('settings-about-roammand')));
    await tester.pumpAndSettle();
    expect(find.text('Make this Mac reachable'), findsOneWidget);
    expect(find.byKey(const Key('about-download-ios')), findsOneWidget);
    expect(find.byType(MobilePageFrame), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('settings-uninstall')));
    await tester.tap(find.byKey(const Key('settings-uninstall')));
    await tester.pumpAndSettle();
    expect(find.textContaining('pairing records'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-uninstall')));
    await tester.pumpAndSettle();
    expect(preparedForUninstall, isTrue);
    expect(uninstaller.uninstallCount, 1);
  });

  testWidgets('hides desktop uninstall from mobile settings', (tester) async {
    final networkServices = NetworkServiceController.transient();
    addTearDown(networkServices.dispose);
    await tester.pumpWidget(
      _app(
        AppSettingsPage(
          localePreference: AppLocalePreference.system,
          onLocalePreferenceChanged: (_) async {},
          networkServices: networkServices,
          mobileContext: true,
          linkLauncher: (_) async => true,
          versionLoader: () async => '1.0.0 (3)',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('General'), findsOneWidget);
    expect(find.text('Connection'), findsOneWidget);
    expect(find.text('About & help'), findsOneWidget);
    expect(find.text('Advanced'), findsNothing);
    expect(find.byKey(const Key('settings-uninstall')), findsNothing);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(MobilePageNavigationHeader), findsOneWidget);
    expect(find.byKey(const Key('mobile-settings-back')), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('settings-about-roammand')),
    );
    await tester.tap(find.byKey(const Key('settings-about-roammand')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mobile-about-header')), findsOneWidget);
    expect(find.text('Version 1.0.0 (3)'), findsOneWidget);
  });

  testWidgets('explains why development builds cannot uninstall', (
    tester,
  ) async {
    final networkServices = NetworkServiceController.transient();
    addTearDown(networkServices.dispose);
    await tester.pumpWidget(
      _app(
        AppSettingsPage(
          localePreference: AppLocalePreference.system,
          onLocalePreferenceChanged: (_) async {},
          networkServices: networkServices,
          mobileContext: false,
          uninstaller: _FakeUninstaller(
            availabilityValue: AppUninstallAvailability.developmentBuild,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('not a development build'), findsOneWidget);
    final tile = tester.widget<ListTile>(
      find.byKey(const Key('settings-uninstall')),
    );
    expect(tile.enabled, isFalse);
  });

  testWidgets('does not show Mac companion guidance on Windows', (
    tester,
  ) async {
    final networkServices = NetworkServiceController.transient();
    addTearDown(networkServices.dispose);
    await tester.pumpWidget(
      _app(
        AppSettingsPage(
          localePreference: AppLocalePreference.system,
          networkServices: networkServices,
          mobileContext: false,
        ),
        platform: TargetPlatform.windows,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings-about-roammand')), findsNothing);
  });
}

Widget _app(Widget home, {TargetPlatform? platform}) => MaterialApp(
  theme: platform == null ? null : ThemeData(platform: platform),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

final class _FakeUninstaller implements AppUninstaller {
  _FakeUninstaller({
    this.availabilityValue = AppUninstallAvailability.available,
  });

  final AppUninstallAvailability availabilityValue;
  int uninstallCount = 0;

  @override
  Future<AppUninstallAvailability> availability() async => availabilityValue;

  @override
  Future<void> uninstallProgram() async {
    uninstallCount += 1;
  }
}
