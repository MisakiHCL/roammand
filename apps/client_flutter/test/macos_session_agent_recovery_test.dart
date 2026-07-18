// SPDX-License-Identifier: MPL-2.0

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/desktop/host_agent/macos_session_agent_recovery.dart';

void main() {
  test('restarts only the current user Session Agent launchd job', () async {
    final invocations = <(String, List<String>)>[];
    final delays = <Duration>[];

    final restarted = await restartInstalledMacOsSessionAgent(
      isMacOS: true,
      commandRunner: (executable, arguments) async {
        invocations.add((executable, List<String>.of(arguments)));
        if (executable == '/usr/bin/id') {
          return ProcessResult(1, 0, '501\n', '');
        }
        return ProcessResult(2, 0, '', '');
      },
      delay: (duration) async => delays.add(duration),
    );

    expect(restarted, isTrue);
    expect(invocations, hasLength(2));
    expect(invocations[0].$1, '/usr/bin/id');
    expect(invocations[0].$2, <String>['-u']);
    expect(invocations[1].$1, '/bin/launchctl');
    expect(invocations[1].$2, <String>[
      'kickstart',
      '-k',
      'gui/501/dev.roammand.SessionAgent',
    ]);
    expect(delays, <Duration>[const Duration(seconds: 1)]);
  });

  test('rejects an untrusted user id before invoking launchctl', () async {
    final executables = <String>[];

    final restarted = await restartInstalledMacOsSessionAgent(
      isMacOS: true,
      commandRunner: (executable, arguments) async {
        executables.add(executable);
        return ProcessResult(1, 0, '501/../../system\n', '');
      },
      delay: (_) async {},
    );

    expect(restarted, isFalse);
    expect(executables, <String>['/usr/bin/id']);
  });

  test('does not invoke macOS commands on another platform', () async {
    var invoked = false;

    final restarted = await restartInstalledMacOsSessionAgent(
      isMacOS: false,
      commandRunner: (executable, arguments) async {
        invoked = true;
        return ProcessResult(1, 0, '', '');
      },
      delay: (_) async {},
    );

    expect(restarted, isFalse);
    expect(invoked, isFalse);
  });
}
