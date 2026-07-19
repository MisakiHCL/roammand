// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:roammand/design_system/roammand_back_button.dart';
import 'package:roammand/design_system/roammand_surfaces.dart';

const mobilePageHeaderHeight = 48.0;
const mobilePageHeaderHorizontalPadding = 4.0;
const mobilePageHeaderActionSize = roammandBackButtonSize;

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
  Widget build(BuildContext context) => RoammandBackButton(
    buttonKey: buttonKey,
    onPressed: onPressed,
    tooltip: tooltip,
  );
}

final class MobilePageNavigationHeader extends StatelessWidget {
  const MobilePageNavigationHeader({
    required this.safePadding,
    required this.title,
    required this.onBack,
    this.backgroundColor = Colors.transparent,
    this.surfaceKey,
    this.backButtonKey,
    this.trailing,
    super.key,
  });

  final EdgeInsets safePadding;
  final String title;
  final VoidCallback? onBack;
  final Color backgroundColor;
  final Key? surfaceKey;
  final Key? backButtonKey;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => MobilePageHeader(
    safePadding: safePadding,
    backgroundColor: backgroundColor,
    surfaceKey: surfaceKey,
    child: Row(
      children: <Widget>[
        MobilePageBackButton(
          buttonKey: backButtonKey,
          onPressed: onBack,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (trailing case final widget?) ...<Widget>[
          const SizedBox(width: 8),
          widget,
        ],
      ],
    ),
  );
}

final class MobilePageFrame extends StatelessWidget {
  const MobilePageFrame({
    required this.title,
    required this.onBack,
    required this.child,
    this.headerKey,
    this.backButtonKey,
    this.trailing,
    super.key,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget child;
  final Key? headerKey;
  final Key? backButtonKey;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => RoammandBackdrop(
    child: Column(
      children: <Widget>[
        MobilePageNavigationHeader(
          safePadding: MediaQuery.paddingOf(context),
          title: title,
          onBack: onBack,
          surfaceKey: headerKey,
          backButtonKey: backButtonKey,
          trailing: trailing,
        ),
        Expanded(child: SafeArea(top: false, child: child)),
      ],
    ),
  );
}
