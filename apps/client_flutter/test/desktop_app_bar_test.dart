// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/design_system/roammand_back_button.dart';
import 'package:roammand/desktop/desktop_app_bar.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  testWidgets('reserves macOS traffic lights inside the draggable app bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.macOS),
        home: const Scaffold(
          appBar: RoammandDesktopAppBar(
            platform: TargetPlatform.macOS,
            title: Text('Roammand'),
          ),
        ),
      ),
    );

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.leadingWidth, 80);
    expect(appBar.toolbarHeight, 40);
    expect(find.byType(DragToMoveArea), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
    expect(find.byType(RoammandBackButton), findsNothing);
  });

  testWidgets('keeps the remote back action clear of macOS traffic lights', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.macOS),
        home: const Scaffold(
          appBar: RoammandDesktopAppBar(
            platform: TargetPlatform.macOS,
            title: Text('Remote desktop'),
            showBackButton: true,
          ),
        ),
      ),
    );

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.leadingWidth, 120);
    expect(find.byType(BackButton), findsNothing);
    expect(find.byType(RoammandBackButton), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
  });

  testWidgets('keeps the standard app bar geometry on Windows', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.windows),
        home: const Scaffold(
          appBar: RoammandDesktopAppBar(
            platform: TargetPlatform.windows,
            title: Text('Remote desktop'),
            showBackButton: true,
          ),
        ),
      ),
    );

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.leadingWidth, isNull);
    expect(appBar.toolbarHeight, kToolbarHeight);
    expect(find.byType(DragToMoveArea), findsNothing);
    expect(find.byType(BackButton), findsNothing);
    expect(find.byType(RoammandBackButton), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
  });
}
