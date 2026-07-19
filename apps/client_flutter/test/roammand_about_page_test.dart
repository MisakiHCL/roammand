// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/about/roammand_about_page.dart';
import 'package:roammand/about/roammand_links.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('explains Mac setup and opens official project resources', (
    tester,
  ) async {
    final opened = <Uri>[];
    await tester.pumpWidget(
      _app(
        RoammandAboutPage(
          linkLauncher: (uri) async {
            opened.add(uri);
            return true;
          },
          versionLoader: () async => '1.0.0 (3)',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your Mac, within reach'), findsOneWidget);
    expect(find.text('How to get started'), findsOneWidget);
    expect(find.text('Roammand for Mac'), findsOneWidget);
    expect(find.text('Open source on GitHub'), findsOneWidget);
    expect(find.text('Private by design'), findsOneWidget);
    expect(find.text('Version 1.0.0 (3)'), findsOneWidget);

    await _tapVisible(tester, const Key('about-download-macos'));
    await _tapVisible(tester, const Key('about-open-guide'));
    await _tapVisible(tester, const Key('about-open-github'));

    expect(opened, <Uri>[
      macOsDownloadPageUri,
      roammandUserGuideUri(const Locale('en')),
      roammandRepositoryUri,
    ]);
  });

  testWidgets('uses the Chinese guide and reports link failures', (
    tester,
  ) async {
    Uri? opened;
    await tester.pumpWidget(
      _app(
        RoammandAboutPage(
          linkLauncher: (uri) async {
            opened = uri;
            return false;
          },
          versionLoader: () async => '1.0.0 (3)',
        ),
        locale: const Locale('zh'),
      ),
    );
    await tester.pumpAndSettle();

    await _tapVisible(tester, const Key('about-open-guide'));
    expect(opened, roammandUserGuideUri(const Locale('zh')));
    expect(find.text('无法打开链接，请稍后重试。'), findsOneWidget);
  });

  testWidgets('explains the Mac host role and opens the iOS companion app', (
    tester,
  ) async {
    final opened = <Uri>[];
    await tester.pumpWidget(
      _app(
        RoammandAboutPage(
          audience: RoammandAboutAudience.desktopHost,
          linkLauncher: (uri) async {
            opened.add(uri);
            return true;
          },
          versionLoader: () async => '1.0.0 (3)',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Make this Mac reachable'), findsOneWidget);
    expect(find.text('Roammand for iPhone and iPad'), findsOneWidget);
    expect(find.textContaining('Screen Recording'), findsOneWidget);
    expect(find.byKey(const Key('mobile-about-header')), findsNothing);
    expect(find.byType(AppBar), findsOneWidget);

    await _tapVisible(tester, const Key('about-download-ios'));
    await _tapVisible(tester, const Key('about-open-guide'));
    await _tapVisible(tester, const Key('about-open-github'));

    expect(opened, <Uri>[
      iosAppStorePageUri,
      roammandUserGuideUri(const Locale('en')),
      roammandRepositoryUri,
    ]);
  });

  testWidgets('remains scrollable on a narrow phone with large Chinese text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        RoammandAboutPage(
          linkLauncher: (_) async => true,
          versionLoader: () async => '1.0.0 (3)',
        ),
        locale: const Locale('zh'),
        textScaler: const TextScaler.linear(1.4),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('about-version')),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('版本 1.0.0 (3)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _tapVisible(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
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
