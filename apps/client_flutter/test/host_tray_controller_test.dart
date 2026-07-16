// SPDX-License-Identifier: MPL-2.0

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/desktop/tray/host_tray_controller.dart';
import 'package:roammand/desktop/tray/host_tray_models.dart';
import 'package:roammand/desktop/tray/host_tray_port.dart';

void main() {
  test('builds semantic menus only when visible state changes', () async {
    final port = FakeHostTrayPort();
    final controller = HostTrayController(
      port: port,
      emergencyStop: () async {},
      confirmControlledExit: () async => true,
    );
    const ready = HostTraySnapshot(
      statusLabel: 'Ready',
      showLabel: 'Show',
      emergencyStopLabel: 'Emergency stop',
      exitLabel: 'Exit',
      controlActive: false,
    );
    await controller.start(iconAssetPath: 'tray.png', snapshot: ready);
    expect(port.initializeCount, 1);
    expect(port.menus.single.statusLabel, 'Ready');
    expect(port.menus.single.emergencyStopEnabled, isFalse);

    await controller.update(ready);
    expect(port.menus, hasLength(1));
    await controller.update(
      const HostTraySnapshot(
        statusLabel: 'Controlled by My phone',
        showLabel: 'Show',
        emergencyStopLabel: 'Emergency stop',
        exitLabel: 'Exit',
        controlActive: true,
      ),
    );
    expect(port.menus, hasLength(2));
    expect(port.menus.last.emergencyStopEnabled, isTrue);
  });

  test(
    'shows, hides, stops and confirms controlled exit exactly once',
    () async {
      final port = FakeHostTrayPort();
      var emergencyStops = 0;
      var allowExit = false;
      final controller = HostTrayController(
        port: port,
        emergencyStop: () async => emergencyStops += 1,
        confirmControlledExit: () async => allowExit,
      );
      await controller.start(
        iconAssetPath: 'tray.png',
        snapshot: const HostTraySnapshot(
          statusLabel: 'Controlled',
          showLabel: 'Show',
          emergencyStopLabel: 'Emergency stop',
          exitLabel: 'Exit',
          controlActive: true,
        ),
      );

      await port.emit(HostTrayCommand.showWindow);
      await port.emit(HostTrayCommand.windowCloseRequested);
      await port.emit(HostTrayCommand.emergencyStop);
      expect(port.showCount, 1);
      expect(port.hideCount, 1);
      expect(emergencyStops, 1);

      await port.emit(HostTrayCommand.exitApplication);
      expect(port.exitCount, 0);
      allowExit = true;
      await port.emit(HostTrayCommand.exitApplication);
      expect(emergencyStops, 2);
      expect(port.exitCount, 1);

      await controller.dispose();
      await controller.dispose();
      expect(port.disposeCount, 1);
    },
  );

  test('publishes the latest locale after delayed initialization', () async {
    final initializeGate = Completer<void>();
    final port = FakeHostTrayPort()..initializeGate = initializeGate;
    final controller = HostTrayController(
      port: port,
      emergencyStop: () async {},
      confirmControlledExit: () async => true,
    );
    const english = HostTraySnapshot(
      statusLabel: 'Ready',
      showLabel: 'Show',
      emergencyStopLabel: 'Emergency stop',
      exitLabel: 'Exit',
      controlActive: false,
    );
    const chinese = HostTraySnapshot(
      statusLabel: '可以远程控制',
      showLabel: '显示',
      emergencyStopLabel: '紧急停止',
      exitLabel: '退出',
      controlActive: false,
    );

    final starting = controller.start(
      iconAssetPath: 'tray.png',
      snapshot: english,
    );
    await Future<void>.delayed(Duration.zero);
    final updating = controller.update(chinese);
    initializeGate.complete();
    await Future.wait(<Future<void>>[starting, updating]);

    expect(port.menus, hasLength(1));
    expect(port.menus.single.statusLabel, chinese.statusLabel);
    expect(port.menus.single.showLabel, chinese.showLabel);
    await controller.dispose();
  });
}

final class FakeHostTrayPort implements HostTrayPort {
  Future<void> Function(HostTrayCommand command)? _onCommand;
  final List<HostTrayMenu> menus = <HostTrayMenu>[];
  int initializeCount = 0;
  int showCount = 0;
  int hideCount = 0;
  int exitCount = 0;
  int disposeCount = 0;
  Completer<void>? initializeGate;

  @override
  Future<void> initialize({
    required String iconAssetPath,
    required Future<void> Function(HostTrayCommand command) onCommand,
  }) async {
    initializeCount += 1;
    _onCommand = onCommand;
    await initializeGate?.future;
  }

  Future<void> emit(HostTrayCommand command) async => _onCommand!(command);

  @override
  Future<void> updateMenu(HostTrayMenu menu) async => menus.add(menu);

  @override
  Future<void> showWindow() async => showCount += 1;

  @override
  Future<void> hideWindow() async => hideCount += 1;

  @override
  Future<void> exitApplication() async => exitCount += 1;

  @override
  Future<void> dispose() async => disposeCount += 1;
}
