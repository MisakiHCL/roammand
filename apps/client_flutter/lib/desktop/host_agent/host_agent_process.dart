// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:roammand/network/network_service_configuration.dart';

const hostAgentAutoStartEnvironment = 'ROAMMAND_HOST_AGENT_AUTOSTART';
const hostAgentExecutableEnvironment = 'ROAMMAND_HOST_AGENT_EXECUTABLE';

const _hostAgentCommand = 'serve';
const _macosInstalledHostAgent =
    '/Library/PrivilegedHelperTools/roammand-host-agent';
const _windowsHostAgentFileName = 'roammand-host-agent.exe';
const _managedProcessShutdownTimeout = Duration(seconds: 3);
const _forcedProcessShutdownTimeout = Duration(seconds: 1);
const _startupErrorPrefix = 'ROAMMAND_STARTUP_ERROR=';
const _maximumStartupDiagnosticLineBytes = 256;

const _signalingEndpointEnvironment = 'ROAMMAND_SIGNALING_ENDPOINT';
const _iceTransportPolicyEnvironment = 'ROAMMAND_ICE_TRANSPORT_POLICY';
const _stunUrlsEnvironment = 'ROAMMAND_STUN_URLS';
const _inheritedHostAgentEnvironmentKeys = <String>{
  // Current-user directories used by the Agent on macOS and Windows.
  'HOME',
  'LOCALAPPDATA',
  'USERPROFILE',
  // Minimal process/runtime environment needed across supported desktops.
  'PATH',
  'PATHEXT',
  'SystemRoot',
  'SYSTEMROOT',
  'WINDIR',
  'TMPDIR',
  'TEMP',
  'TMP',
  'LANG',
  'LC_ALL',
  'LC_CTYPE',
  // Explicitly supported development and packaging overrides.
  'ROAMMAND_DATA_DIR',
  'ROAMMAND_RUNTIME_DIR',
  'ROAMMAND_DEVICE_NAME',
  'ROAMMAND_ALLOW_INSECURE_LAN_SIGNALING',
};

enum HostAgentStartupFailure {
  automaticStartupDisabled,
  executableUnavailable,
  processLaunchFailed,
  protectedSessionAgentUnavailable,
  privilegedBridgeUnavailable,
  desktopPermissionsRequired,
  configurationInvalid,
  unexpectedExit,
}

abstract interface class HostAgentProcessLifecycle {
  /// Last bounded, non-sensitive startup failure reported by this lifecycle.
  HostAgentStartupFailure? get lastStartupFailure;

  /// Starts or preserves a Host Agent owned by this lifecycle.
  ///
  /// Returns false when automatic startup is disabled or no installed
  /// executable is available. An independently running Agent is never owned.
  Future<bool> start();

  /// Restarts only an Agent previously started by this lifecycle.
  ///
  /// Returns false when the connected Agent is independently managed.
  Future<bool> restart(NetworkServiceConfiguration configuration);

  /// Stops only the process that was started by this lifecycle.
  Future<void> stop();
}

final class DesktopHostAgentProcess implements HostAgentProcessLifecycle {
  DesktopHostAgentProcess({
    required NetworkServiceConfiguration configuration,
    Map<String, String>? parentEnvironment,
    String? Function()? executableResolver,
  }) : _parentEnvironment = parentEnvironment ?? Platform.environment,
       // Public constructor labels keep dependency injection readable.
       // ignore: prefer_initializing_formals
       _executableResolver = executableResolver,
       // Public constructor labels keep dependency injection readable.
       // ignore: prefer_initializing_formals
       _configuration = configuration;

  final Map<String, String> _parentEnvironment;
  final String? Function()? _executableResolver;
  NetworkServiceConfiguration _configuration;

  Process? _process;
  Future<bool>? _startOperation;
  Future<bool>? _restartOperation;
  Future<void>? _stopOperation;
  bool _managedProcessStarted = false;
  bool _closed = false;
  HostAgentStartupFailure? _lastStartupFailure;

  @override
  HostAgentStartupFailure? get lastStartupFailure => _lastStartupFailure;

  @override
  Future<bool> start() {
    final pending = _startOperation;
    if (pending != null) {
      return pending;
    }
    final operation = _start();
    _startOperation = operation;
    return operation.whenComplete(() {
      if (identical(_startOperation, operation)) {
        _startOperation = null;
      }
    });
  }

  Future<bool> _start() async {
    _lastStartupFailure = null;
    if (_closed) {
      return false;
    }
    if (_process != null) {
      return true;
    }
    if (!_automaticStartupEnabled(_parentEnvironment)) {
      _lastStartupFailure = HostAgentStartupFailure.automaticStartupDisabled;
      return false;
    }
    final executable =
        _executableResolver?.call() ??
        resolveHostAgentExecutable(
          environment: _parentEnvironment,
          resolvedExecutable: Platform.resolvedExecutable,
          isMacOS: Platform.isMacOS,
          isWindows: Platform.isWindows,
        );
    if (executable == null || !await File(executable).exists()) {
      _lastStartupFailure = HostAgentStartupFailure.executableUnavailable;
      return false;
    }

    final Process process;
    try {
      process = await Process.start(
        executable,
        const <String>[_hostAgentCommand],
        environment: hostAgentProcessEnvironment(
          configuration: _configuration,
          parentEnvironment: _parentEnvironment,
        ),
        includeParentEnvironment: false,
        mode: ProcessStartMode.normal,
      );
    } on ProcessException {
      _lastStartupFailure = HostAgentStartupFailure.processLaunchFailed;
      return false;
    }
    if (_closed) {
      await _terminateProcess(process);
      return false;
    }
    _process = process;
    _managedProcessStarted = true;
    unawaited(_drain(process.stdout));
    final startupFailure = _observeStartupFailure(process.stderr);
    unawaited(
      process.exitCode.then((_) async {
        final reportedFailure = await startupFailure;
        if (identical(_process, process)) {
          _process = null;
          _lastStartupFailure =
              reportedFailure ?? HostAgentStartupFailure.unexpectedExit;
        }
      }),
    );
    return true;
  }

  @override
  Future<bool> restart(NetworkServiceConfiguration configuration) {
    final pending = _restartOperation;
    if (pending != null) return pending;
    final operation = _restart(configuration);
    _restartOperation = operation;
    return operation.whenComplete(() {
      if (identical(_restartOperation, operation)) {
        _restartOperation = null;
      }
    });
  }

  Future<bool> _restart(NetworkServiceConfiguration configuration) async {
    configuration.validate();
    await _startOperation;
    if (_closed || !_managedProcessStarted) {
      return false;
    }
    await _stopOwnedProcess();
    if (_closed) return false;
    _configuration = configuration;
    return _start();
  }

  @override
  Future<void> stop() {
    _closed = true;
    final pending = _stopOperation;
    if (pending != null) {
      return pending;
    }
    final operation = _stopOwnedProcess();
    _stopOperation = operation;
    return operation.whenComplete(() {
      if (identical(_stopOperation, operation)) {
        _stopOperation = null;
      }
    });
  }

  Future<void> _stopOwnedProcess() async {
    await _startOperation;
    final process = _process;
    _process = null;
    if (process == null) {
      return;
    }
    await _terminateProcess(process);
  }
}

String? resolveHostAgentExecutable({
  required Map<String, String> environment,
  required String resolvedExecutable,
  required bool isMacOS,
  required bool isWindows,
}) {
  final override = environment[hostAgentExecutableEnvironment]?.trim();
  if (override != null && override.isNotEmpty) {
    return override;
  }
  if (isMacOS) {
    return _macosInstalledHostAgent;
  }
  if (isWindows) {
    return path.windows.join(
      path.windows.dirname(resolvedExecutable),
      _windowsHostAgentFileName,
    );
  }
  return null;
}

bool _automaticStartupEnabled(Map<String, String> environment) {
  final configured = environment[hostAgentAutoStartEnvironment]
      ?.trim()
      .toLowerCase();
  return configured != '0' && configured != 'false' && configured != 'no';
}

Map<String, String> hostAgentLaunchEnvironment(
  NetworkServiceConfiguration configuration,
) {
  configuration.validate();
  return <String, String>{
    _signalingEndpointEnvironment: configuration.signalingEndpoint.toString(),
    _iceTransportPolicyEnvironment: 'all',
    if (configuration.stunUrls.isNotEmpty)
      _stunUrlsEnvironment: configuration.stunUrls.join(','),
  };
}

Map<String, String> hostAgentProcessEnvironment({
  required NetworkServiceConfiguration configuration,
  required Map<String, String> parentEnvironment,
}) {
  final environment = <String, String>{};
  for (final key in _inheritedHostAgentEnvironmentKeys) {
    final value = parentEnvironment[key];
    if (value != null) {
      environment[key] = value;
    }
  }
  environment.addAll(hostAgentLaunchEnvironment(configuration));
  return environment;
}

Future<void> _drain(Stream<List<int>> stream) async {
  try {
    await stream.drain<void>();
  } on Object {
    // Output is intentionally discarded to avoid blocked pipes and unbounded
    // child logs. Readiness and failures surface through authenticated IPC.
  }
}

Future<HostAgentStartupFailure?> _observeStartupFailure(
  Stream<List<int>> stream,
) async {
  HostAgentStartupFailure? failure;
  final lineBytes = <int>[];
  try {
    await for (final chunk in stream) {
      for (final byte in chunk) {
        if (byte == 0x0a) {
          failure ??= parseHostAgentStartupFailure(
            String.fromCharCodes(lineBytes),
          );
          lineBytes.clear();
        } else if (lineBytes.length < _maximumStartupDiagnosticLineBytes) {
          lineBytes.add(byte);
        }
      }
    }
    failure ??= parseHostAgentStartupFailure(String.fromCharCodes(lineBytes));
  } on Object {
    // A broken stderr pipe is treated as an unexpected exit. Raw child output
    // is never retained or surfaced by the GUI.
  }
  return failure;
}

HostAgentStartupFailure? parseHostAgentStartupFailure(String line) {
  if (!line.startsWith(_startupErrorPrefix)) {
    return null;
  }
  return switch (line.substring(_startupErrorPrefix.length).trim()) {
    'protected_session_agent_unavailable' =>
      HostAgentStartupFailure.protectedSessionAgentUnavailable,
    'privileged_bridge_unavailable' =>
      HostAgentStartupFailure.privilegedBridgeUnavailable,
    'desktop_permissions_required' =>
      HostAgentStartupFailure.desktopPermissionsRequired,
    'remote_configuration_invalid' =>
      HostAgentStartupFailure.configurationInvalid,
    _ => HostAgentStartupFailure.unexpectedExit,
  };
}

Future<void> _terminateProcess(Process process) async {
  process.kill();
  try {
    await process.exitCode.timeout(_managedProcessShutdownTimeout);
  } on TimeoutException {
    if (!Platform.isWindows) {
      process.kill(ProcessSignal.sigkill);
    } else {
      process.kill();
    }
    try {
      await process.exitCode.timeout(_forcedProcessShutdownTimeout);
    } on TimeoutException {
      // Do not let a broken child process block the GUI exit indefinitely.
    }
  }
}
