// SPDX-License-Identifier: MPL-2.0

import 'host_tray_models.dart';

abstract interface class HostTrayPort {
  Future<void> initialize({
    required String iconAssetPath,
    required Future<void> Function(HostTrayCommand command) onCommand,
  });

  Future<void> updateMenu(HostTrayMenu menu);

  Future<void> showWindow();

  Future<void> hideWindow();

  Future<void> exitApplication();

  Future<void> dispose();
}
