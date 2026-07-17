// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:io';

import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'host_tray_models.dart';
import 'host_tray_port.dart';

const _exitMenuKey = 'exit';

Future<void> prepareDesktopWindow() async {
  await windowManager.ensureInitialized();
}

final class FlutterHostTrayPort
    with TrayListener, WindowListener
    implements HostTrayPort {
  Future<void> Function(HostTrayCommand command)? _onCommand;
  bool _initialized = false;
  bool _disposed = false;

  @override
  Future<void> initialize({
    required String iconAssetPath,
    required Future<void> Function(HostTrayCommand command) onCommand,
  }) async {
    if (_initialized || _disposed) {
      return;
    }
    _initialized = true;
    _onCommand = onCommand;
    trayManager.addListener(this);
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
    await trayManager.setIcon(iconAssetPath, isTemplate: Platform.isMacOS);
  }

  @override
  Future<void> updateMenu(HostTrayMenu menu) async {
    if (!_initialized || _disposed) {
      return;
    }
    await trayManager.setToolTip(menu.tooltipLabel);
    await trayManager.setContextMenu(
      Menu(
        items: <MenuItem>[MenuItem(key: _exitMenuKey, label: menu.exitLabel)],
      ),
    );
  }

  @override
  Future<void> showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  Future<void> hideWindow() => windowManager.hide();

  @override
  Future<void> exitApplication() async {
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  @override
  void onTrayIconMouseDown() {
    _emit(HostTrayCommand.showWindow);
  }

  @override
  void onTrayIconRightMouseDown() {
    if (Platform.isMacOS) {
      unawaited(trayManager.popUpContextMenu());
    }
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    final command = switch (menuItem.key) {
      _exitMenuKey => HostTrayCommand.exitApplication,
      _ => null,
    };
    if (command != null) {
      _emit(command);
    }
  }

  @override
  void onWindowClose() {
    _emit(HostTrayCommand.windowCloseRequested);
  }

  void _emit(HostTrayCommand command) {
    final callback = _onCommand;
    if (!_disposed && callback != null) {
      unawaited(callback(command));
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _onCommand = null;
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    await trayManager.destroy();
  }
}
