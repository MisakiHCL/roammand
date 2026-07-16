// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/design_system/roammand_brand_mark.dart';
import 'package:roammand/design_system/roammand_colors.dart';
import 'package:roammand/design_system/roammand_theme.dart';

void main() {
  test('Night Aurora theme exposes the confirmed brand roles', () {
    final theme = RoammandTheme.dark();

    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, RoammandColors.canvas);
    expect(theme.colorScheme.primary, RoammandColors.auroraIndigo);
    expect(theme.colorScheme.secondary, RoammandColors.signalCyan);
    expect(theme.colorScheme.error, RoammandColors.emergency);
    expect(theme.cardTheme.color, RoammandColors.deepSurface);
  });

  test('core text pairs meet WCAG AA contrast', () {
    final scheme = RoammandTheme.dark().colorScheme;

    expect(
      _contrast(scheme.primary, scheme.onPrimary),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(scheme.surface, scheme.onSurface),
      greaterThanOrEqualTo(4.5),
    );
    expect(_contrast(scheme.error, scheme.onError), greaterThanOrEqualTo(4.5));
  });

  test(
    'compact typography reduces large macOS roles without shrinking labels',
    () {
      final regular = RoammandTheme.dark().textTheme;
      final compact = RoammandTheme.dark(compactTypography: true).textTheme;

      expect(compact.displaySmall?.fontSize, 32);
      expect(compact.headlineLarge?.fontSize, 28);
      expect(compact.headlineMedium?.fontSize, 24);
      expect(compact.headlineSmall?.fontSize, 20);
      expect(compact.titleLarge?.fontSize, 20);
      expect(compact.bodyLarge?.fontSize, 14);
      expect(compact.bodyMedium?.fontSize, regular.bodyMedium?.fontSize);
      expect(compact.labelSmall?.fontSize, regular.labelSmall?.fontSize);
    },
  );

  testWidgets('brand mark remains accessible at compact sizes', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: RoammandBrandMark(size: 24, semanticsLabel: 'Roammand'),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Roammand'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

double _contrast(Color first, Color second) {
  final brightest = first.computeLuminance() >= second.computeLuminance()
      ? first
      : second;
  final darkest = identical(brightest, first) ? second : first;
  return (brightest.computeLuminance() + 0.05) /
      (darkest.computeLuminance() + 0.05);
}
