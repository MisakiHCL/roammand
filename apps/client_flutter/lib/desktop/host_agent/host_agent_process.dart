// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

const hostAgentAutoStartEnvironment = 'ROAMMAND_HOST_AGENT_AUTOSTART';
const hostAgentExecutableEnvironment = 'ROAMMAND_HOST_AGENT_EXECUTABLE';

const _hostAgentCommand = 'serve';
const _macosInstalledHostAgent =
    '/Library/PrivilegedHelperTools/roammand-host-agent';
const _windowsHostAgentFileName = 'roammand-host-agent.exe';
const _managedProcessShutdownTimeout = Duration(seconds: 3);
const _forcedProcessShutdownTimeout = Duration(seconds: 1);

const _signalingEndpointEnvironment = 'ROAMMAND_SIGNALING_ENDPOINT';
const _iceTransportPolicyEnvironment = 'ROAMMAND_ICE_TRANSPORT_POLICY';
const _turnUrlsEnvironment = 'ROAMMAND_TURN_URLS';
const _turnUsernameEnvironment = 'ROAMMAND_TURN_USERNAME';
const _turnPasswordEnvironment = 'ROAMMAND_TURN_PASSWORD';

const _compiledIceTransportPolicy = String.fromEnvironment(
  _iceTransportPolicyEnvironment,
);
const _compiledTurnUrls = String.fromEnvironment(_turnUrlsEnvironment);
const _compiledTurnUsername = String.fromEnvironment(_turnUsernameEnvironment);
const _compiledTurnPassword = String.fromEnvironment(_turnPasswordEnvironment);

abstract interface class HostAgentProcessLifecycle {
  /// Starts or preserves a Host Agent owned by this lifecycle.
  ///
  /// Returns false when automatic startup is disabled or no installed
  /// executable is available. An independently running Agent is never owned.
  Future<bool> start();

  /// Stops only the process that was started by this lifecycle.
  Future<void> stop();
}

final class DesktopHostAgentProcess implements HostAgentProcessLifecycle {
  DesktopHostAgentProcess({
    required String signalingEndpoint,
    Map<String, String>? parentEnvironment,
    String? Function()? executableResolver,
  }) : _parentEnvironment = parentEnvironment ?? Platform.environment,
       // Public constructor labels keep dependency injection readable.
       // ignore: prefer_initializing_formals
       _executableResolver = executableResolver,
       _launchEnvironment = _compiledLaunchEnvironment(signalingEndpoint);

  final Map<String, String> _parentEnvironment;
  final String? Function()? _executableResolver;
  final Map<String, String> _launchEnvironment;

  Process? _process;
  Future<bool>? _startOperation;
  Future<void>? _stopOperation;
  bool _closed = false;

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
    if (_closed) {
      return false;
    }
    if (_process != null) {
      return true;
    }
    if (!_automaticStartupEnabled(_parentEnvironment)) {
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
      return false;
    }

    final Process process;
    try {
      process = await Process.start(
        executable,
        const <String>[_hostAgentCommand],
        environment: _launchEnvironment,
        includeParentEnvironment: true,
        mode: ProcessStartMode.normal,
      );
    } on ProcessException {
      return false;
    }
    if (_closed) {
      await _terminateProcess(process);
      return false;
    }
    _process = process;
    unawaited(_drain(process.stdout));
    unawaited(_drain(process.stderr));
    unawaited(
      process.exitCode.then((_) {
        if (identical(_process, process)) {
          _process = null;
        }
      }),
    );
    return true;
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

Map<String, String> _compiledLaunchEnvironment(String signalingEndpoint) {
  final values = <String, String>{
    _signalingEndpointEnvironment: signalingEndpoint,
    _iceTransportPolicyEnvironment: _compiledIceTransportPolicy,
    _turnUrlsEnvironment: _compiledTurnUrls,
    _turnUsernameEnvironment: _compiledTurnUsername,
    _turnPasswordEnvironment: _compiledTurnPassword,
  };
  values.removeWhere((_, value) => value.trim().isEmpty);
  return values;
}

Future<void> _drain(Stream<List<int>> stream) async {
  try {
    await stream.drain<void>();
  } on Object {
    // Output is intentionally discarded to avoid blocked pipes and unbounded
    // child logs. Readiness and failures surface through authenticated IPC.
  }
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
