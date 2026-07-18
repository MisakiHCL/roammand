// SPDX-License-Identifier: MPL-2.0

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
