// SPDX-License-Identifier: MPL-2.0

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/desktop/permissions/macos_host_permissions.dart';

void main() {
  test('decodes the bounded permission command exit status', () {
    expect(MacOsHostPermissionStatus.fromExitCode(40).ready, isTrue);
    expect(MacOsHostPermissionStatus.fromExitCode(41).screenRecording, isFalse);
    expect(MacOsHostPermissionStatus.fromExitCode(42).accessibility, isFalse);
    expect(
      () => MacOsHostPermissionStatus.fromExitCode(2),
      throwsA(isA<MacOsHostPermissionException>()),
    );
  });

  test('requests each permission explicitly and reaches ready state', () async {
    final service = _GrantingPermissionService();
    final controller = MacOsHostPermissionsController(service: service);
    addTearDown(controller.dispose);

    await controller.start();
    expect(controller.blocksConnections, isTrue);

    await controller.request(MacOsHostPermission.screenRecording);
    expect(controller.status?.screenRecording, isTrue);
    expect(controller.status?.accessibility, isFalse);

    await controller.request(MacOsHostPermission.accessibility);
    expect(controller.ready, isTrue);
    expect(service.requests, <MacOsHostPermission>[
      MacOsHostPermission.screenRecording,
      MacOsHostPermission.accessibility,
    ]);
  });

  test('opens System Settings without also showing a native prompt', () async {
    final invocations = <(String, List<String>)>[];
    final history = _MemoryScreenRecordingRequestHistory(requested: true);
    final service = ProcessMacOsHostPermissionService(
      executableResolver: () async => '/test/roammand-session-agent',
      screenRecordingRequestHistory: history,
      processRunner: (executable, arguments) async {
        invocations.add((executable, List<String>.of(arguments)));
        if (executable == '/usr/bin/open') {
          return ProcessResult(1, 0, '', '');
        }
        return ProcessResult(1, 43, '', '');
      },
    );

    await service.request(MacOsHostPermission.screenRecording);
    await service.request(MacOsHostPermission.accessibility);

    expect(invocations, hasLength(4));
    expect(
      invocations.where((invocation) => invocation.$1 == '/usr/bin/open'),
      hasLength(2),
    );
    expect(
      invocations
          .expand((invocation) => invocation.$2)
          .where((argument) => argument.startsWith('macos-request-')),
      isEmpty,
    );
    expect(invocations.map((invocation) => invocation.$2.single), <String>[
      'x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture',
      'macos-permission-status',
      'x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility',
      'macos-permission-status',
    ]);
  });

  test(
    'falls back to the native prompt when System Settings cannot open',
    () async {
      final invocations = <(String, List<String>)>[];
      final history = _MemoryScreenRecordingRequestHistory(requested: true);
      final service = ProcessMacOsHostPermissionService(
        executableResolver: () async => '/test/roammand-session-agent',
        screenRecordingRequestHistory: history,
        processRunner: (executable, arguments) async {
          invocations.add((executable, List<String>.of(arguments)));
          return ProcessResult(
            1,
            executable == '/usr/bin/open' ? 1 : 43,
            '',
            '',
          );
        },
      );

      await service.request(MacOsHostPermission.screenRecording);

      expect(invocations, hasLength(2));
      expect(invocations.first.$1, '/usr/bin/open');
      expect(invocations.last.$1, '/test/roammand-session-agent');
      expect(invocations.last.$2, <String>['macos-request-screen-recording']);
    },
  );

  test('registers Screen Recording before opening its settings pane', () async {
    final invocations = <(String, List<String>)>[];
    final history = _MemoryScreenRecordingRequestHistory();
    final service = ProcessMacOsHostPermissionService(
      executableResolver: () async => '/test/roammand-session-agent',
      screenRecordingRequestHistory: history,
      processRunner: (executable, arguments) async {
        invocations.add((executable, List<String>.of(arguments)));
        return ProcessResult(1, executable == '/usr/bin/open' ? 0 : 43, '', '');
      },
    );

    await service.request(MacOsHostPermission.screenRecording);

    expect(history.requested, isTrue);
    expect(invocations, hasLength(1));
    expect(invocations.single.$1, '/test/roammand-session-agent');
    expect(invocations.single.$2, <String>['macos-request-screen-recording']);

    await service.request(MacOsHostPermission.screenRecording);

    expect(invocations, hasLength(3));
    expect(invocations[1].$1, '/usr/bin/open');
    expect(invocations[2].$2, <String>['macos-permission-status']);
  });
}

final class _MemoryScreenRecordingRequestHistory
    implements MacOsScreenRecordingRequestHistory {
  _MemoryScreenRecordingRequestHistory({this.requested = false});

  bool requested;

  @override
  Future<void> markRequested() async => requested = true;

  @override
  Future<bool> wasRequested() async => requested;
}

final class _GrantingPermissionService implements MacOsHostPermissionService {
  bool screenRecording = false;
  bool accessibility = false;
  final List<MacOsHostPermission> requests = <MacOsHostPermission>[];

  MacOsHostPermissionStatus get status => MacOsHostPermissionStatus(
    screenRecording: screenRecording,
    accessibility: accessibility,
  );

  @override
  Future<MacOsHostPermissionStatus> check() async => status;

  @override
  Future<MacOsHostPermissionStatus> request(
    MacOsHostPermission permission,
  ) async {
    requests.add(permission);
    switch (permission) {
      case MacOsHostPermission.screenRecording:
        screenRecording = true;
      case MacOsHostPermission.accessibility:
        accessibility = true;
    }
    return status;
  }
}
