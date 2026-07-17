// SPDX-License-Identifier: MPL-2.0

import 'host_tray_models.dart';
import 'host_tray_port.dart';

final class HostTrayController {
  HostTrayController({
    required HostTrayPort port,
    required Future<void> Function() emergencyStop,
    required Future<bool> Function() confirmControlledExit,
    required Future<void> Function() beforeExit,
  }) : // Public constructor labels keep dependency injection readable.
       // ignore: prefer_initializing_formals
       _port = port,
       // ignore: prefer_initializing_formals
       _emergencyStop = emergencyStop,
       // ignore: prefer_initializing_formals
       _confirmControlledExit = confirmControlledExit,
       // ignore: prefer_initializing_formals
       _beforeExit = beforeExit;

  final HostTrayPort _port;
  final Future<void> Function() _emergencyStop;
  final Future<bool> Function() _confirmControlledExit;
  final Future<void> Function() _beforeExit;

  HostTraySnapshot? _snapshot;
  HostTraySnapshot? _desiredSnapshot;
  Future<void> _previousOperation = Future<void>.value();
  bool _started = false;
  bool _commandPending = false;
  bool _disposed = false;

  Future<void> start({
    required String iconAssetPath,
    required HostTraySnapshot snapshot,
  }) {
    if (_started || _disposed) {
      return _previousOperation;
    }
    _started = true;
    _desiredSnapshot = snapshot;
    return _enqueue(() async {
      if (_disposed) {
        return;
      }
      await _port.initialize(
        iconAssetPath: iconAssetPath,
        onCommand: _handleCommand,
      );
      await _flushDesiredSnapshot();
    });
  }

  Future<void> update(HostTraySnapshot snapshot) {
    if (!_started || _disposed || snapshot == _desiredSnapshot) {
      return _previousOperation;
    }
    _desiredSnapshot = snapshot;
    return _enqueue(_flushDesiredSnapshot);
  }

  Future<void> _flushDesiredSnapshot() async {
    final desiredSnapshot = _desiredSnapshot;
    if (_disposed || desiredSnapshot == null || desiredSnapshot == _snapshot) {
      return;
    }
    await _port.updateMenu(HostTrayMenu.fromSnapshot(desiredSnapshot));
    _snapshot = desiredSnapshot;
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final scheduled = _previousOperation.then((_) => operation());
    _previousOperation = scheduled;
    return scheduled;
  }

  Future<void> _handleCommand(HostTrayCommand command) async {
    if (_disposed || _commandPending) {
      return;
    }
    _commandPending = true;
    try {
      switch (command) {
        case HostTrayCommand.showWindow:
          await _port.showWindow();
        case HostTrayCommand.windowCloseRequested:
          await _port.hideWindow();
        case HostTrayCommand.emergencyStop:
          if (_snapshot?.controlActive ?? false) {
            await _emergencyStop();
          }
        case HostTrayCommand.exitApplication:
          if ((_snapshot?.controlActive ?? false) &&
              !await _confirmControlledExit()) {
            return;
          }
          if (_snapshot?.controlActive ?? false) {
            await _emergencyStop();
          }
          await _beforeExit();
          await _port.exitApplication();
      }
    } finally {
      _commandPending = false;
    }
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    try {
      await _previousOperation;
    } finally {
      await _port.dispose();
    }
  }
}
