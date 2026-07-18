// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';

import 'roammand_brand_mark.dart';
import 'roammand_colors.dart';

final class RoammandBackdrop extends StatelessWidget {
  const RoammandBackdrop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            RoammandColors.canvas,
            Color(0xFF0D1129),
            RoammandColors.canvas,
          ],
          stops: <double>[0, 0.52, 1],
        ),
      ),
      child: child,
    ),
  );
}

final class RoammandStatusPage extends StatelessWidget {
  const RoammandStatusPage({
    required this.message,
    this.progress = false,
    this.action,
    super.key,
  });

  final String message;
  final bool progress;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: RoammandBackdrop(
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const RoammandBrandMark(size: 88),
                const SizedBox(height: 24),
                if (progress) ...<Widget>[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                ],
                Text(message, textAlign: TextAlign.center),
                if (action case final widget?) ...<Widget>[
                  const SizedBox(height: 24),
                  widget,
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

final class RoammandPageHero extends StatelessWidget {
  const RoammandPageHero({
    required this.eyebrow,
    required this.title,
    required this.body,
    this.showMark = true,
    this.markSize,
    this.horizontalBreakpoint = 520,
    this.action,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String body;
  final bool showMark;
  final double? markSize;
  final double horizontalBreakpoint;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          eyebrow.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: RoammandColors.signalCyan,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(body, style: theme.textTheme.bodyLarge),
        if (action case final widget?) ...<Widget>[
          const SizedBox(height: 20),
          widget,
        ],
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal =
            showMark && constraints.maxWidth >= horizontalBreakpoint;
        if (!showMark) return copy;
        if (horizontal) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              RoammandBrandMark(size: markSize ?? 112),
              const SizedBox(width: 28),
              Expanded(child: copy),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            RoammandBrandMark(size: markSize ?? 88),
            const SizedBox(height: 24),
            copy,
          ],
        );
      },
    );
  }
}

enum RoammandStatusTone { neutral, online, attention, emergency }

final class RoammandStatusPill extends StatelessWidget {
  const RoammandStatusPill({
    required this.label,
    required this.tone,
    this.icon,
    super.key,
  });

  final String label;
  final RoammandStatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final foreground = switch (tone) {
      RoammandStatusTone.neutral => RoammandColors.auroraSoft,
      RoammandStatusTone.online => RoammandColors.online,
      RoammandStatusTone.attention => RoammandColors.attention,
      RoammandStatusTone.emergency => RoammandColors.emergency,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.38)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon ?? Icons.circle,
              size: icon == null ? 8 : 16,
              color: foreground,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
