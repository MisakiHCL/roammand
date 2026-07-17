// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/desktop/host_agent/host_agent_process.dart';

void main() {
  test('explicit executable override wins on every desktop platform', () {
    expect(
      resolveHostAgentExecutable(
        environment: const <String, String>{
          hostAgentExecutableEnvironment: '/tmp/custom-host-agent',
        },
        resolvedExecutable:
            '/Applications/Roammand.app/Contents/MacOS/roammand',
        isMacOS: true,
        isWindows: false,
      ),
      '/tmp/custom-host-agent',
    );
  });

  test('installed desktop locations remain deterministic', () {
    expect(
      resolveHostAgentExecutable(
        environment: const <String, String>{},
        resolvedExecutable:
            '/Applications/Roammand.app/Contents/MacOS/roammand',
        isMacOS: true,
        isWindows: false,
      ),
      '/Library/PrivilegedHelperTools/roammand-host-agent',
    );
    expect(
      resolveHostAgentExecutable(
        environment: const <String, String>{},
        resolvedExecutable: r'C:\Program Files\Roammand\roammand.exe',
        isMacOS: false,
        isWindows: true,
      ),
      r'C:\Program Files\Roammand\roammand-host-agent.exe',
    );
  });

  test('unsupported platforms do not invent a Host Agent location', () {
    expect(
      resolveHostAgentExecutable(
        environment: const <String, String>{},
        resolvedExecutable: '/tmp/roammand',
        isMacOS: false,
        isWindows: false,
      ),
      isNull,
    );
  });
}
