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

final class ProcessMacOsHostPermissionService
    implements MacOsHostPermissionService {
  ProcessMacOsHostPermissionService({Map<String, String>? environment})
    : _environment = environment ?? Platform.environment;

  final Map<String, String> _environment;

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
    final status = await _runPermissionCommand(command);
    if (!status.granted(permission)) {
      await _openSettings(permission);
    }
    return status;
  }

  Future<MacOsHostPermissionStatus> _runPermissionCommand(
    String command,
  ) async {
    final executable = await _resolveExecutable();
    if (executable == null) {
      throw const MacOsHostPermissionException();
    }
    try {
      final result = await Process.run(executable, <String>[
        command,
      ], includeParentEnvironment: false);
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
      final result = await Process.run(_openCommand, <String>[
        destination,
      ], includeParentEnvironment: false);
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
