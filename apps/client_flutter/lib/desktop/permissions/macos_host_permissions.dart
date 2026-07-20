// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../host_agent/host_agent_process.dart';

const _installedSessionAgent =
    '/Applications/Roammand.app/Contents/Library/LoginItems/'
    'RoammandSessionAgent.app/'
    'Contents/MacOS/roammand-session-agent';
const _installedHostAgent =
    '/Library/PrivilegedHelperTools/roammand-host-agent';
const _permissionStatusCommand = 'macos-permission-status';
const _requestScreenRecordingCommand = 'macos-request-screen-recording';
const _requestAccessibilityCommand = 'macos-request-accessibility';
const _openCommand = '/usr/bin/open';
const _screenRecordingSettings =
    'x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture';
const _accessibilitySettings =
    'x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility';
const _permissionPollDelays = <Duration>[
  Duration(seconds: 2),
  Duration(seconds: 10),
  Duration(seconds: 30),
  Duration(minutes: 1),
];
const _permissionExitCodeBase = 40;
const _screenRecordingRequestAttemptedStorageKey =
    'macos_screen_recording_request_attempted_v1';

enum MacOsHostPermission { screenRecording, accessibility }

final class MacOsHostPermissionStatus {
  const MacOsHostPermissionStatus({
    required this.screenRecording,
    required this.accessibility,
  });

  factory MacOsHostPermissionStatus.fromExitCode(int exitCode) {
    final permissionBits = exitCode - _permissionExitCodeBase;
    if (permissionBits < 0 || permissionBits > 3) {
      throw const MacOsHostPermissionException();
    }
    return MacOsHostPermissionStatus(
      screenRecording: permissionBits & 1 == 0,
      accessibility: permissionBits & 2 == 0,
    );
  }

  final bool screenRecording;
  final bool accessibility;

  bool get ready => screenRecording && accessibility;

  bool granted(MacOsHostPermission permission) => switch (permission) {
    MacOsHostPermission.screenRecording => screenRecording,
    MacOsHostPermission.accessibility => accessibility,
  };
}

final class MacOsHostPermissionException implements Exception {
  const MacOsHostPermissionException();
}

abstract interface class MacOsHostPermissionService {
  Future<MacOsHostPermissionStatus> check();

  Future<MacOsHostPermissionStatus> request(MacOsHostPermission permission);
}

abstract interface class MacOsPermissionPollHandle {
  void cancel();
}

typedef MacOsPermissionPollScheduler =
    MacOsPermissionPollHandle Function(
      Duration delay,
      void Function() callback,
    );

abstract interface class MacOsScreenRecordingRequestHistory {
  Future<bool> wasRequested();

  Future<void> markRequested();
}

final class SharedPreferencesMacOsScreenRecordingRequestHistory
    implements MacOsScreenRecordingRequestHistory {
  SharedPreferencesMacOsScreenRecordingRequestHistory({
    SharedPreferencesAsync? preferences,
  }) : // Public constructor labels keep dependency injection readable.
       // ignore: prefer_initializing_formals
       _preferences = preferences;

  SharedPreferencesAsync? _preferences;

  SharedPreferencesAsync get _resolvedPreferences =>
      _preferences ??= SharedPreferencesAsync();

  @override
  Future<bool> wasRequested() async =>
      await _resolvedPreferences.getBool(
        _screenRecordingRequestAttemptedStorageKey,
      ) ??
      false;

  @override
  Future<void> markRequested() => _resolvedPreferences.setBool(
    _screenRecordingRequestAttemptedStorageKey,
    true,
  );
}

typedef MacOsPermissionExecutableResolver = Future<String?> Function();
typedef MacOsPermissionCommandRunner =
    Future<ProcessResult> Function(String executable, List<String> arguments);

final class ProcessMacOsHostPermissionService
    implements MacOsHostPermissionService {
  ProcessMacOsHostPermissionService({
    Map<String, String>? environment,
    MacOsPermissionExecutableResolver? executableResolver,
    MacOsPermissionCommandRunner? processRunner,
    MacOsScreenRecordingRequestHistory? screenRecordingRequestHistory,
  }) : _environment = environment ?? Platform.environment,
       // Public constructor labels keep dependency injection readable.
       // ignore: prefer_initializing_formals
       _executableResolver = executableResolver,
       _processRunner =
           processRunner ??
           ((executable, arguments) => Process.run(
             executable,
             arguments,
             includeParentEnvironment: false,
           )),
       _screenRecordingRequestHistory =
           screenRecordingRequestHistory ??
           SharedPreferencesMacOsScreenRecordingRequestHistory();

  final Map<String, String> _environment;
  final MacOsPermissionExecutableResolver? _executableResolver;
  final MacOsPermissionCommandRunner _processRunner;
  final MacOsScreenRecordingRequestHistory _screenRecordingRequestHistory;

  @override
  Future<MacOsHostPermissionStatus> check() =>
      _runPermissionCommand(_permissionStatusCommand);

  @override
  Future<MacOsHostPermissionStatus> request(
    MacOsHostPermission permission,
  ) async {
    final command = switch (permission) {
      MacOsHostPermission.screenRecording => _requestScreenRecordingCommand,
      MacOsHostPermission.accessibility => _requestAccessibilityCommand,
    };
    if (permission == MacOsHostPermission.screenRecording &&
        !await _screenRecordingWasRequested()) {
      final status = await _runPermissionCommand(command);
      await _markScreenRecordingRequested();
      return status;
    }
    try {
      await _openSettings(permission);
    } on MacOsHostPermissionException {
      // The native request is a fallback for systems where the privacy pane
      // cannot be opened. Never run both paths together: its system-owned
      // prompt is asynchronous and would otherwise overlap System Settings.
      return _runPermissionCommand(command);
    }
    return check();
  }

  Future<bool> _screenRecordingWasRequested() async {
    try {
      return await _screenRecordingRequestHistory.wasRequested();
    } on Object {
      return false;
    }
  }

  Future<void> _markScreenRecordingRequested() async {
    try {
      await _screenRecordingRequestHistory.markRequested();
    } on Object {
      // Losing this optional UX marker must not block the system permission
      // request. A later attempt may show the native prompt again.
    }
  }

  Future<MacOsHostPermissionStatus> _runPermissionCommand(
    String command,
  ) async {
    final executable =
        await (_executableResolver?.call() ?? _resolveExecutable());
    if (executable == null) {
      throw const MacOsHostPermissionException();
    }
    try {
      final result = await _processRunner(executable, <String>[command]);
      return MacOsHostPermissionStatus.fromExitCode(result.exitCode);
    } on ProcessException {
      throw const MacOsHostPermissionException();
    }
  }

  Future<String?> _resolveExecutable() async {
    final override = _environment[hostAgentExecutableEnvironment]?.trim();
    for (final candidate in <String?>[
      if (override != null && override.isNotEmpty) override,
      _installedSessionAgent,
      _installedHostAgent,
    ]) {
      if (candidate != null && await File(candidate).exists()) {
        return candidate;
      }
    }
    return null;
  }

  Future<void> _openSettings(MacOsHostPermission permission) async {
    final destination = switch (permission) {
      MacOsHostPermission.screenRecording => _screenRecordingSettings,
      MacOsHostPermission.accessibility => _accessibilitySettings,
    };
    try {
      final result = await _processRunner(_openCommand, <String>[destination]);
      if (result.exitCode != 0) {
        throw const MacOsHostPermissionException();
      }
    } on ProcessException {
      throw const MacOsHostPermissionException();
    }
  }
}

final class MacOsHostPermissionsController extends ChangeNotifier {
  MacOsHostPermissionsController({
    MacOsHostPermissionService? service,
    MacOsPermissionPollScheduler? pollScheduler,
  }) : _service = service ?? ProcessMacOsHostPermissionService(),
       _pollScheduler = pollScheduler ?? _schedulePermissionPoll;

  final MacOsHostPermissionService _service;
  final MacOsPermissionPollScheduler _pollScheduler;
  MacOsHostPermissionStatus? _status;
  MacOsHostPermission? _pendingPermission;
  MacOsPermissionPollHandle? _pollTimer;
  bool _checking = false;
  bool _unavailable = false;
  bool _disposed = false;
  int _pollDelayIndex = 0;
  int _statusOperationGeneration = 0;

  MacOsHostPermissionStatus? get status => _status;
  MacOsHostPermission? get pendingPermission => _pendingPermission;
  bool get checking => _checking;
  bool get unavailable => _unavailable;
  bool get ready => _status?.ready ?? false;
  bool get blocksConnections => !ready;

  Future<void> start() async {
    await refresh();
  }

  Future<void> refresh() async {
    if (_disposed || _checking || _pendingPermission != null) return;
    final operationGeneration = ++_statusOperationGeneration;
    _checking = true;
    _notify();
    try {
      final status = await _service.check();
      if (_operationIsCurrent(operationGeneration)) {
        _status = status;
        _unavailable = false;
      }
    } on MacOsHostPermissionException {
      if (_operationIsCurrent(operationGeneration)) {
        _unavailable = true;
      }
    } finally {
      _checking = false;
      if (_operationIsCurrent(operationGeneration)) {
        if (ready) {
          _cancelPolling(resetBackoff: true);
        } else {
          _scheduleNextPoll();
        }
      } else if (!_disposed && _pendingPermission == null && !ready) {
        // A newer request may have scheduled a poll while this stale check was
        // still running. If that poll fired and observed `_checking`, restore
        // the polling chain now that the in-flight check has actually ended.
        _scheduleNextPoll();
      }
      _notify();
    }
  }

  Future<void> request(MacOsHostPermission permission) async {
    if (_disposed || _pendingPermission != null) return;
    final operationGeneration = ++_statusOperationGeneration;
    _cancelPolling(resetBackoff: true);
    _pendingPermission = permission;
    _unavailable = false;
    _notify();
    try {
      final status = await _service.request(permission);
      if (_operationIsCurrent(operationGeneration)) {
        _status = status;
        _unavailable = false;
      }
      if (_operationIsCurrent(operationGeneration) && status.ready) {
        _cancelPolling(resetBackoff: true);
      }
    } on MacOsHostPermissionException {
      if (_operationIsCurrent(operationGeneration)) {
        _unavailable = true;
      }
    } finally {
      if (_operationIsCurrent(operationGeneration)) {
        _pendingPermission = null;
        if (!ready) {
          _scheduleNextPoll();
        }
      }
      _notify();
    }
  }

  void _scheduleNextPoll() {
    if (_disposed ||
        ready ||
        _pendingPermission != null ||
        _pollTimer != null) {
      return;
    }
    final delay = _permissionPollDelays[_pollDelayIndex];
    if (_pollDelayIndex < _permissionPollDelays.length - 1) {
      _pollDelayIndex += 1;
    }
    _pollTimer = _pollScheduler(delay, () {
      _pollTimer = null;
      unawaited(refresh());
    });
  }

  void _cancelPolling({required bool resetBackoff}) {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (resetBackoff) {
      _pollDelayIndex = 0;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool _operationIsCurrent(int generation) =>
      !_disposed && generation == _statusOperationGeneration;

  @override
  void dispose() {
    _disposed = true;
    _statusOperationGeneration += 1;
    _cancelPolling(resetBackoff: true);
    super.dispose();
  }
}

final class _TimerPermissionPollHandle implements MacOsPermissionPollHandle {
  const _TimerPermissionPollHandle(this._timer);

  final Timer _timer;

  @override
  void cancel() => _timer.cancel();
}

MacOsPermissionPollHandle _schedulePermissionPoll(
  Duration delay,
  void Function() callback,
) => _TimerPermissionPollHandle(Timer(delay, callback));
