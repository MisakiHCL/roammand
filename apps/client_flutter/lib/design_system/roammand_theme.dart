// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';

import 'roammand_colors.dart';

const _compactDisplaySmallSize = 30.0;
const _compactHeadlineLargeSize = 26.0;
const _compactHeadlineMediumSize = 22.0;
const _compactHeadlineSmallSize = 18.0;
const _compactTitleLargeSize = 18.0;
const _compactTitleMediumSize = 14.0;
const _compactTitleSmallSize = 13.0;
const _compactBodyLargeSize = 13.0;
const _compactBodyMediumSize = 13.0;
const _compactLabelLargeSize = 13.0;

abstract final class RoammandTheme {
  static ThemeData dark({bool compactDesktop = false}) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: RoammandColors.auroraIndigo,
      brightness: Brightness.dark,
    );
    final scheme = baseScheme.copyWith(
      primary: RoammandColors.auroraIndigo,
      onPrimary: RoammandColors.canvas,
      primaryContainer: RoammandColors.elevatedSurface,
      onPrimaryContainer: RoammandColors.textPrimary,
      secondary: RoammandColors.signalCyan,
      onSecondary: RoammandColors.canvas,
      secondaryContainer: const Color(0xFF123C55),
      onSecondaryContainer: RoammandColors.textPrimary,
      error: RoammandColors.emergency,
      onError: RoammandColors.canvas,
      errorContainer: const Color(0xFF4D2238),
      onErrorContainer: const Color(0xFFFFD9E0),
      surface: RoammandColors.deepSurface,
      onSurface: RoammandColors.textPrimary,
      surfaceContainerHighest: RoammandColors.elevatedSurface,
      onSurfaceVariant: RoammandColors.textSecondary,
      outline: RoammandColors.outline,
      outlineVariant: const Color(0xFF292D4E),
      inverseSurface: RoammandColors.inverseSurface,
      onInverseSurface: RoammandColors.inverseInk,
      inversePrimary: const Color(0xFF4F4BC9),
      shadow: Colors.black,
      scrim: Colors.black,
    );
    final base = ThemeData(
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: RoammandColors.canvas,
      useMaterial3: true,
    );
    final brandedTextTheme = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
        color: RoammandColors.textPrimary,
      ),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: RoammandColors.textPrimary,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: RoammandColors.textPrimary,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: RoammandColors.textPrimary,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: RoammandColors.textPrimary,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: RoammandColors.textPrimary,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        height: 1.45,
        color: RoammandColors.textPrimary,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        height: 1.45,
        color: RoammandColors.textSecondary,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
    final textTheme = compactDesktop
        ? brandedTextTheme.copyWith(
            displaySmall: brandedTextTheme.displaySmall?.copyWith(
              fontSize: _compactDisplaySmallSize,
            ),
            headlineLarge: brandedTextTheme.headlineLarge?.copyWith(
              fontSize: _compactHeadlineLargeSize,
            ),
            headlineMedium: brandedTextTheme.headlineMedium?.copyWith(
              fontSize: _compactHeadlineMediumSize,
            ),
            headlineSmall: brandedTextTheme.headlineSmall?.copyWith(
              fontSize: _compactHeadlineSmallSize,
            ),
            titleLarge: brandedTextTheme.titleLarge?.copyWith(
              fontSize: _compactTitleLargeSize,
            ),
            titleMedium: brandedTextTheme.titleMedium?.copyWith(
              fontSize: _compactTitleMediumSize,
            ),
            titleSmall: brandedTextTheme.titleSmall?.copyWith(
              fontSize: _compactTitleSmallSize,
            ),
            bodyLarge: brandedTextTheme.bodyLarge?.copyWith(
              fontSize: _compactBodyLargeSize,
            ),
            bodyMedium: brandedTextTheme.bodyMedium?.copyWith(
              fontSize: _compactBodyMediumSize,
            ),
            labelLarge: brandedTextTheme.labelLarge?.copyWith(
              fontSize: _compactLabelLargeSize,
            ),
          )
        : brandedTextTheme;
    final controlHeight = compactDesktop ? 40.0 : 48.0;
    final buttonPadding = EdgeInsets.symmetric(
      horizontal: compactDesktop ? 16 : 20,
      vertical: compactDesktop ? 8 : 12,
    );
    final roundedRectangle = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    return base.copyWith(
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: RoammandColors.canvas,
      canvasColor: RoammandColors.canvas,
      dividerColor: scheme.outlineVariant,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: RoammandColors.canvas,
        foregroundColor: RoammandColors.textPrimary,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: RoammandColors.deepSurface,
        surfaceTintColor: Colors.transparent,
        shape: roundedRectangle.copyWith(
          side: const BorderSide(color: RoammandColors.outline),
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 24,
        backgroundColor: RoammandColors.elevatedSurface,
        surfaceTintColor: Colors.transparent,
        shape: roundedRectangle,
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(0, controlHeight),
          padding: buttonPadding,
          backgroundColor: RoammandColors.inverseSurface,
          foregroundColor: RoammandColors.inverseInk,
          disabledBackgroundColor: RoammandColors.outline,
          disabledForegroundColor: RoammandColors.textSecondary,
          textStyle: textTheme.labelLarge,
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(0, controlHeight),
          padding: buttonPadding,
          foregroundColor: RoammandColors.textPrimary,
          side: const BorderSide(color: RoammandColors.outline),
          textStyle: textTheme.labelLarge,
          shape: buttonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: Size.square(compactDesktop ? 40 : 44),
          foregroundColor: RoammandColors.auroraSoft,
          textStyle: textTheme.labelLarge,
          shape: buttonShape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: Size.square(compactDesktop ? 40 : 44),
          foregroundColor: RoammandColors.textSecondary,
          highlightColor: RoammandColors.auroraIndigo.withValues(alpha: 0.16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: RoammandColors.deepSurface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: compactDesktop ? 12 : 16,
        ),
        labelStyle: const TextStyle(color: RoammandColors.textSecondary),
        hintStyle: const TextStyle(color: RoammandColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: RoammandColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: RoammandColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: RoammandColors.auroraIndigo,
            width: 2,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: compactDesktop ? 64 : 72,
        elevation: 0,
        backgroundColor: RoammandColors.deepSurface,
        indicatorColor: RoammandColors.auroraIndigo.withValues(alpha: 0.22),
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: RoammandColors.deepSurface,
        indicatorColor: RoammandColors.auroraIndigo.withValues(alpha: 0.22),
        selectedIconTheme: const IconThemeData(
          color: RoammandColors.auroraSoft,
        ),
        unselectedIconTheme: const IconThemeData(
          color: RoammandColors.textSecondary,
        ),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: RoammandColors.textPrimary,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: RoammandColors.textSecondary,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: RoammandColors.signalCyan,
        linearTrackColor: RoammandColors.elevatedSurface,
        circularTrackColor: RoammandColors.elevatedSurface,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: RoammandColors.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: RoammandColors.inverseInk,
        ),
        actionTextColor: const Color(0xFF4F4BC9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: RoammandColors.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: RoammandColors.inverseInk,
        ),
      ),
    );
  }
}
