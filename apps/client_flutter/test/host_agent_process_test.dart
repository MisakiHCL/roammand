// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/desktop/host_agent/host_agent_process.dart';
import 'package:roammand/network/network_service_configuration.dart';

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

  test('maps the active service profile into a child-only environment', () {
    final environment = hostAgentLaunchEnvironment(
      NetworkServiceConfiguration(
        kind: NetworkServiceProfileKind.custom,
        signalingEndpoint: Uri.parse('wss://signal.example.test/v1/connect'),
        stunUrls: const <String>['stun:stun.example.test:3478'],
      ),
    );

    expect(
      environment['ROAMMAND_SIGNALING_ENDPOINT'],
      'wss://signal.example.test/v1/connect',
    );
    expect(environment['ROAMMAND_ICE_TRANSPORT_POLICY'], 'all');
    expect(environment['ROAMMAND_STUN_URLS'], 'stun:stun.example.test:3478');
    expect(environment.containsKey('ROAMMAND_TURN_URLS'), isFalse);
    expect(environment.containsKey('ROAMMAND_TURN_USERNAME'), isFalse);
    expect(environment.containsKey('ROAMMAND_TURN_PASSWORD'), isFalse);
  });

  test('managed profile replaces inherited ICE and TURN overrides', () {
    final environment = hostAgentProcessEnvironment(
      configuration: NetworkServiceConfiguration.official(),
      parentEnvironment: const <String, String>{
        'PATH': '/usr/bin',
        'ROAMMAND_SIGNALING_ENDPOINT': 'wss://old.example.test/v1/connect',
        'ROAMMAND_STUN_URLS': 'stun:old.example.test:3478',
        'ROAMMAND_TURN_URLS': 'turn:old.example.test:3478',
        'ROAMMAND_TURN_USERNAME': 'old-user',
        'ROAMMAND_TURN_PASSWORD': 'old-password',
      },
    );

    expect(environment['PATH'], '/usr/bin');
    expect(
      environment['ROAMMAND_SIGNALING_ENDPOINT'],
      'wss://signal.hcl.life/v1/connect',
    );
    expect(environment['ROAMMAND_STUN_URLS'], 'stun:stun.hcl.life:3478');
    expect(environment.containsKey('ROAMMAND_TURN_URLS'), isFalse);
    expect(environment.containsKey('ROAMMAND_TURN_USERNAME'), isFalse);
    expect(environment.containsKey('ROAMMAND_TURN_PASSWORD'), isFalse);
  });
}
