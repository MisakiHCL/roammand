// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:roammand/design_system/roammand_colors.dart';

const mobilePageHeaderHeight = 48.0;
const mobilePageHeaderHorizontalPadding = 4.0;
const mobilePageHeaderActionSize = 40.0;

final class MobilePageHeader extends StatelessWidget {
  const MobilePageHeader({
    required this.safePadding,
    required this.child,
    this.backgroundColor = Colors.transparent,
    this.surfaceKey,
    super.key,
  });

  final EdgeInsets safePadding;
  final Widget child;
  final Color backgroundColor;
  final Key? surfaceKey;

  @override
  Widget build(BuildContext context) => Material(
    key: surfaceKey,
    color: backgroundColor,
    child: SizedBox(
      height: mobilePageHeaderHeight + safePadding.top,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          safePadding.left + mobilePageHeaderHorizontalPadding,
          safePadding.top,
          safePadding.right + mobilePageHeaderHorizontalPadding,
          0,
        ),
        child: child,
      ),
    ),
  );
}

final class MobilePageBackButton extends StatelessWidget {
  const MobilePageBackButton({
    required this.onPressed,
    required this.tooltip,
    this.buttonKey,
    super.key,
  });

  final VoidCallback? onPressed;
  final String tooltip;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) => IconButton(
    key: buttonKey,
    onPressed: onPressed,
    tooltip: tooltip,
    constraints: const BoxConstraints.tightFor(
      width: mobilePageHeaderActionSize,
      height: mobilePageHeaderActionSize,
    ),
    padding: const EdgeInsets.all(8),
    icon: const Icon(
      Icons.arrow_back,
      color: RoammandColors.textPrimary,
      size: 20,
    ),
  );
}
