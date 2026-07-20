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
      beforeExit: () async {},
    );
    const ready = HostTraySnapshot(
      tooltipLabel: 'Roammand',
      exitLabel: 'Quit Roammand',
      controlActive: false,
    );
    await controller.start(iconAssetPath: 'tray.png', snapshot: ready);
    expect(port.initializeCount, 1);
    expect(port.menus.single.tooltipLabel, 'Roammand');
    expect(port.menus.single.exitLabel, 'Quit Roammand');

    await controller.update(ready);
    expect(port.menus, hasLength(1));
    await controller.update(
      const HostTraySnapshot(
        tooltipLabel: 'Roammand',
        exitLabel: 'Quit Roammand',
        controlActive: true,
      ),
    );
    expect(port.menus, hasLength(1));
  });

  test(
    'shows, hides, stops and confirms controlled exit exactly once',
    () async {
      final port = FakeHostTrayPort();
      var emergencyStops = 0;
      var beforeExitCalls = 0;
      var allowExit = false;
      final controller = HostTrayController(
        port: port,
        emergencyStop: () async => emergencyStops += 1,
        confirmControlledExit: () async => allowExit,
        beforeExit: () async => beforeExitCalls += 1,
      );
      await controller.start(
        iconAssetPath: 'tray.png',
        snapshot: const HostTraySnapshot(
          tooltipLabel: 'Roammand',
          exitLabel: 'Quit Roammand',
          controlActive: true,
        ),
      );

      await port.emit(HostTrayCommand.showWindow);
      await port.emit(HostTrayCommand.windowCloseRequested);
      expect(port.showCount, 1);
      expect(port.hideCount, 1);
      expect(emergencyStops, 0);

      await port.emit(HostTrayCommand.exitApplication);
      expect(port.exitCount, 0);
      expect(beforeExitCalls, 0);
      allowExit = true;
      await port.emit(HostTrayCommand.exitApplication);
      expect(emergencyStops, 1);
      expect(beforeExitCalls, 1);
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
      beforeExit: () async {},
    );
    const english = HostTraySnapshot(
      tooltipLabel: 'Roammand',
      exitLabel: 'Quit Roammand',
      controlActive: false,
    );
    const chinese = HostTraySnapshot(
      tooltipLabel: 'Roammand',
      exitLabel: '退出 Roammand',
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
    expect(port.menus.single.tooltipLabel, chinese.tooltipLabel);
    expect(port.menus.single.exitLabel, chinese.exitLabel);
    await controller.dispose();
  });

  test(
    'continues updates and disposes after a queued operation fails',
    () async {
      final port = FakeHostTrayPort();
      final controller = HostTrayController(
        port: port,
        emergencyStop: () async {},
        confirmControlledExit: () async => true,
        beforeExit: () async {},
      );
      const ready = HostTraySnapshot(
        tooltipLabel: 'Roammand',
        exitLabel: 'Quit Roammand',
        controlActive: false,
      );
      const recovered = HostTraySnapshot(
        tooltipLabel: 'Roammand',
        exitLabel: 'Exit Roammand',
        controlActive: true,
      );
      const localized = HostTraySnapshot(
        tooltipLabel: 'Roammand',
        exitLabel: '退出 Roammand',
        controlActive: true,
      );

      await controller.start(iconAssetPath: 'tray.png', snapshot: ready);
      port.failNextMenuUpdate = true;
      await expectLater(controller.update(localized), throwsStateError);

      await controller.update(recovered);
      expect(port.menus.last.exitLabel, recovered.exitLabel);

      port.failNextMenuUpdate = true;
      await expectLater(controller.update(ready), throwsStateError);
      await controller.dispose();

      expect(port.updateMenuAttempts, 4);
      expect(port.disposeCount, 1);
    },
  );

  test(
    'retries initialization and blocks updates after start failure',
    () async {
      final port = FakeHostTrayPort()..failNextInitialize = true;
      final controller = HostTrayController(
        port: port,
        emergencyStop: () async {},
        confirmControlledExit: () async => true,
        beforeExit: () async {},
      );
      const first = HostTraySnapshot(
        tooltipLabel: 'Roammand',
        exitLabel: 'Quit Roammand',
        controlActive: false,
      );
      const recovered = HostTraySnapshot(
        tooltipLabel: 'Roammand',
        exitLabel: 'Exit Roammand',
        controlActive: false,
      );

      await expectLater(
        controller.start(iconAssetPath: 'tray.png', snapshot: first),
        throwsStateError,
      );
      await controller.update(recovered);
      expect(port.updateMenuAttempts, 0);

      await controller.start(iconAssetPath: 'tray.png', snapshot: recovered);
      expect(port.initializeCount, 2);
      expect(port.menus.single.exitLabel, recovered.exitLabel);
      await controller.dispose();
    },
  );
}

final class FakeHostTrayPort implements HostTrayPort {
  Future<void> Function(HostTrayCommand command)? _onCommand;
  final List<HostTrayMenu> menus = <HostTrayMenu>[];
  int initializeCount = 0;
  int showCount = 0;
  int hideCount = 0;
  int exitCount = 0;
  int disposeCount = 0;
  int updateMenuAttempts = 0;
  bool failNextMenuUpdate = false;
  bool failNextInitialize = false;
  Completer<void>? initializeGate;

  @override
  Future<void> initialize({
    required String iconAssetPath,
    required Future<void> Function(HostTrayCommand command) onCommand,
  }) async {
    initializeCount += 1;
    if (failNextInitialize) {
      failNextInitialize = false;
      throw StateError('simulated tray initialization failure');
    }
    _onCommand = onCommand;
    await initializeGate?.future;
  }

  Future<void> emit(HostTrayCommand command) async => _onCommand!(command);

  @override
  Future<void> updateMenu(HostTrayMenu menu) async {
    updateMenuAttempts += 1;
    if (failNextMenuUpdate) {
      failNextMenuUpdate = false;
      throw StateError('simulated tray update failure');
    }
    menus.add(menu);
  }

  @override
  Future<void> showWindow() async => showCount += 1;

  @override
  Future<void> hideWindow() async => hideCount += 1;

  @override
  Future<void> exitApplication() async => exitCount += 1;

  @override
  Future<void> dispose() async => disposeCount += 1;
}
