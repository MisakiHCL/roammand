// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';

import 'roammand_colors.dart';

const roammandBackButtonSize = 40.0;
const roammandBackIconSize = 24.0;

/// The shared iOS-style back action used on mobile and desktop.
final class RoammandBackButton extends StatelessWidget {
  const RoammandBackButton({
    required this.onPressed,
    this.buttonKey,
    this.tooltip,
    super.key,
  });

  final VoidCallback? onPressed;
  final Key? buttonKey;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => IconButton(
    key: buttonKey,
    onPressed: onPressed,
    tooltip: tooltip ?? MaterialLocalizations.of(context).backButtonTooltip,
    constraints: const BoxConstraints.tightFor(
      width: roammandBackButtonSize,
      height: roammandBackButtonSize,
    ),
    padding: const EdgeInsets.all(8),
    icon: const Icon(
      Icons.arrow_back_ios_new_rounded,
      color: RoammandColors.textSecondary,
      size: roammandBackIconSize,
    ),
  );
}
