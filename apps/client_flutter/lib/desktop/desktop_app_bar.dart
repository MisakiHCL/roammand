// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:roammand/design_system/roammand_back_button.dart';
import 'package:window_manager/window_manager.dart';

const _macosTrafficLightsWidth = 80.0;
const _macosToolbarHeight = 40.0;

final class RoammandDesktopAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const RoammandDesktopAppBar({
    required this.platform,
    required this.title,
    this.actions,
    this.showBackButton = false,
    super.key,
  });

  final TargetPlatform platform;
  final Widget title;
  final List<Widget>? actions;
  final bool showBackButton;

  @override
  Size get preferredSize => Size.fromHeight(
    platform == TargetPlatform.macOS ? _macosToolbarHeight : kToolbarHeight,
  );

  @override
  Widget build(BuildContext context) {
    final macos = platform == TargetPlatform.macOS;
    final toolbarHeight = macos ? _macosToolbarHeight : kToolbarHeight;
    return AppBar(
      toolbarHeight: toolbarHeight,
      automaticallyImplyLeading: false,
      leading: _leading(context, macos, toolbarHeight),
      leadingWidth: macos
          ? _macosTrafficLightsWidth + (showBackButton ? toolbarHeight : 0)
          : null,
      titleSpacing: macos ? 0 : NavigationToolbar.kMiddleSpacing,
      title: macos
          ? DragToMoveArea(
              child: SizedBox(
                width: double.infinity,
                height: toolbarHeight,
                child: Align(alignment: Alignment.centerLeft, child: title),
              ),
            )
          : title,
      actions: actions,
    );
  }

  Widget? _leading(BuildContext context, bool macos, double toolbarHeight) {
    final backButton = RoammandBackButton(
      onPressed: () => Navigator.of(context).maybePop(),
    );
    if (!macos) {
      return showBackButton ? backButton : null;
    }
    return Row(
      children: <Widget>[
        const SizedBox(width: _macosTrafficLightsWidth),
        if (showBackButton) SizedBox(width: toolbarHeight, child: backButton),
      ],
    );
  }
}
