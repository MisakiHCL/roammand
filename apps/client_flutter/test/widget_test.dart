// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/design_system/roammand_theme.dart';
import 'package:roammand/l10n/app_locale_controller.dart';
import 'package:roammand/main.dart';

void main() {
  testWidgets('shows the localized pre-release status', (tester) async {
    await tester.pumpWidget(const RoammandApp(desktopHostEnabled: false));

    expect(find.text('Roammand'), findsOneWidget);
    expect(find.text('Remote control is not available yet.'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('routes a mobile build to the mobile product entry', (
    tester,
  ) async {
    await tester.pumpWidget(
      const RoammandApp(
        desktopHostEnabled: false,
        mobileHome: Scaffold(body: Text('mobile-product-entry')),
      ),
    );

    expect(find.text('mobile-product-entry'), findsOneWidget);
    expect(find.text('Remote control is not available yet.'), findsNothing);
  });

  testWidgets('applies and persists a runtime language change', (tester) async {
    final store = _WidgetLocaleStore();
    final controller = AppLocaleController(store: store);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      RoammandApp(desktopHostEnabled: false, localeController: controller),
    );

    expect(find.text('Remote control is not available yet.'), findsOneWidget);

    await controller.setPreference(AppLocalePreference.simplifiedChinese);
    await tester.pumpAndSettle();

    expect(find.text('远程控制功能尚未开放。'), findsOneWidget);
    expect(store.savedPreferences, <AppLocalePreference>[
      AppLocalePreference.simplifiedChinese,
    ]);
  });

  testWidgets('uses compact typography on macOS only', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await tester.pumpWidget(const RoammandApp(desktopHostEnabled: false));

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme?.textTheme.titleLarge?.fontSize, 18);
      expect(app.theme?.textTheme.bodyLarge?.fontSize, 13);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('keeps regular typography on Windows', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await tester.pumpWidget(const RoammandApp(desktopHostEnabled: false));

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final regular = RoammandTheme.dark().textTheme;
      expect(
        app.theme?.textTheme.titleLarge?.fontSize,
        regular.titleLarge?.fontSize,
      );
      expect(
        app.theme?.textTheme.bodyLarge?.fontSize,
        regular.bodyLarge?.fontSize,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

final class _WidgetLocaleStore implements AppLocalePreferenceStore {
  final List<AppLocalePreference> savedPreferences = <AppLocalePreference>[];

  @override
  Future<AppLocalePreference> load() async => AppLocalePreference.system;

  @override
  Future<void> save(AppLocalePreference preference) async {
    savedPreferences.add(preference);
  }
}
