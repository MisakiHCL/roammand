// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

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
const _permissionPollInterval = Duration(seconds: 2);
const _permissionExitCodeBase = 40;

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

typedef MacOsPermissionExecutableResolver = Future<String?> Function();
typedef MacOsPermissionCommandRunner =
    Future<ProcessResult> Function(String executable, List<String> arguments);

final class ProcessMacOsHostPermissionService
    implements MacOsHostPermissionService {
  ProcessMacOsHostPermissionService({
    Map<String, String>? environment,
    MacOsPermissionExecutableResolver? executableResolver,
    MacOsPermissionCommandRunner? processRunner,
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
           ));

  final Map<String, String> _environment;
  final MacOsPermissionExecutableResolver? _executableResolver;
  final MacOsPermissionCommandRunner _processRunner;

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
  MacOsHostPermissionsController({MacOsHostPermissionService? service})
    : _service = service ?? ProcessMacOsHostPermissionService();

  final MacOsHostPermissionService _service;
  MacOsHostPermissionStatus? _status;
  MacOsHostPermission? _pendingPermission;
  Timer? _pollTimer;
  bool _checking = false;
  bool _unavailable = false;
  bool _disposed = false;

  MacOsHostPermissionStatus? get status => _status;
  MacOsHostPermission? get pendingPermission => _pendingPermission;
  bool get checking => _checking;
  bool get unavailable => _unavailable;
  bool get ready => _status?.ready ?? false;
  bool get blocksConnections => !ready;

  Future<void> start() async {
    await refresh();
    if (!_disposed && !ready) {
      _pollTimer ??= Timer.periodic(
        _permissionPollInterval,
        (_) => unawaited(refresh()),
      );
    }
  }

  Future<void> refresh() async {
    if (_disposed || _checking || _pendingPermission != null) return;
    _checking = true;
    _notify();
    try {
      _status = await _service.check();
      _unavailable = false;
      if (_status!.ready) {
        _pollTimer?.cancel();
        _pollTimer = null;
      }
    } on MacOsHostPermissionException {
      _unavailable = true;
    } finally {
      _checking = false;
      _notify();
    }
  }

  Future<void> request(MacOsHostPermission permission) async {
    if (_disposed || _pendingPermission != null) return;
    _pendingPermission = permission;
    _unavailable = false;
    _notify();
    try {
      _status = await _service.request(permission);
      if (_status!.ready) {
        _pollTimer?.cancel();
        _pollTimer = null;
      } else {
        _pollTimer ??= Timer.periodic(
          _permissionPollInterval,
          (_) => unawaited(refresh()),
        );
      }
    } on MacOsHostPermissionException {
      _unavailable = true;
    } finally {
      _pendingPermission = null;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    super.dispose();
  }
}
