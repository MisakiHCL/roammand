// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/settings/uninstall/app_uninstaller.dart';

const _uninstallerChannel = MethodChannel('dev.roammand/uninstaller');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('only enables uninstall for a complete installed macOS app', () async {
    final installed = MacOsAppUninstaller(
      resolvedExecutable: macosInstalledAppExecutable,
      fileExists: (_) async => true,
    );
    final development = MacOsAppUninstaller(
      resolvedExecutable: '/tmp/roammand',
      fileExists: (_) async => true,
    );
    final incomplete = MacOsAppUninstaller(
      resolvedExecutable: macosInstalledAppExecutable,
      fileExists: (_) async => false,
    );

    expect(await installed.availability(), AppUninstallAvailability.available);
    expect(
      await development.availability(),
      AppUninstallAvailability.developmentBuild,
    );
    expect(
      await incomplete.availability(),
      AppUninstallAvailability.unavailable,
    );
  });

  test('uses the authorized runner and redacts failures', () async {
    var runCount = 0;
    final successful = MacOsAppUninstaller(
      resolvedExecutable: macosInstalledAppExecutable,
      fileExists: (_) async => true,
      runAuthorizedUninstaller: () async {
        runCount += 1;
        return 0;
      },
    );
    await successful.uninstallProgram();
    expect(runCount, 1);

    final failed = MacOsAppUninstaller(
      resolvedExecutable: macosInstalledAppExecutable,
      fileExists: (_) async => true,
      runAuthorizedUninstaller: () async => 1,
    );
    await expectLater(
      failed.uninstallProgram(),
      throwsA(
        isA<AppUninstallException>().having(
          (error) => error.toString(),
          'redacted text',
          contains('[REDACTED]'),
        ),
      ),
    );
  });

  test(
    'routes installed-app uninstall through native macOS authorization',
    () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      MethodCall? receivedCall;
      messenger.setMockMethodCallHandler(_uninstallerChannel, (call) async {
        receivedCall = call;
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(_uninstallerChannel, null),
      );

      final uninstaller = MacOsAppUninstaller(
        resolvedExecutable: macosInstalledAppExecutable,
        fileExists: (_) async => true,
      );
      await uninstaller.uninstallProgram();

      expect(receivedCall?.method, 'uninstall');
      expect(receivedCall?.arguments, isNull);
    },
  );
}
