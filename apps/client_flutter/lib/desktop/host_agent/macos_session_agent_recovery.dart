// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:io';

const _currentUserIdCommand = '/usr/bin/id';
const _launchctlCommand = '/bin/launchctl';
const _sessionAgentLabel = 'dev.roammand.SessionAgent';
const _sessionAgentSettleDelay = Duration(seconds: 1);
final _validUserId = RegExp(r'^[1-9][0-9]{0,9}$');

typedef MacOsRecoveryCommandRunner =
    Future<ProcessResult> Function(String executable, List<String> arguments);
typedef MacOsRecoveryDelay = Future<void> Function(Duration duration);

/// Restarts the installed per-user Session Agent after macOS TCC changes.
///
/// Accessibility and Screen Recording decisions may not become visible to an
/// already-running background process. The GUI calls this bounded recovery
/// before retrying a Host startup that reported an unavailable Session Agent.
Future<bool> restartInstalledMacOsSessionAgent({
  bool? isMacOS,
  MacOsRecoveryCommandRunner? commandRunner,
  MacOsRecoveryDelay? delay,
}) async {
  if (!(isMacOS ?? Platform.isMacOS)) return false;
  final run = commandRunner ?? _runCommand;
  try {
    final userIdResult = await run(_currentUserIdCommand, const <String>['-u']);
    final userId = userIdResult.stdout.toString().trim();
    if (userIdResult.exitCode != 0 || !_validUserId.hasMatch(userId)) {
      return false;
    }
    final restartResult = await run(_launchctlCommand, <String>[
      'kickstart',
      '-k',
      'gui/$userId/$_sessionAgentLabel',
    ]);
    if (restartResult.exitCode != 0) return false;
    await (delay ?? Future<void>.delayed)(_sessionAgentSettleDelay);
    return true;
  } on ProcessException {
    return false;
  }
}

Future<ProcessResult> _runCommand(String executable, List<String> arguments) =>
    Process.run(executable, arguments, includeParentEnvironment: false);
