// SPDX-License-Identifier: MPL-2.0

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'macOS desktop Runner can reach the separate current-user Host Agent',
    () {
      for (final fileName in <String>[
        'macos/Runner/DebugProfile.entitlements',
        'macos/Runner/Release.entitlements',
      ]) {
        final contents = File(fileName).readAsStringSync();
        expect(
          RegExp(
            r'<key>com\.apple\.security\.app-sandbox</key>\s*<false/>',
          ).hasMatch(contents),
          isTrue,
          reason: fileName,
        );
      }
    },
  );

  test('macOS title bar blends native window controls into Flutter', () {
    final window = File(
      'macos/Runner/MainFlutterWindow.swift',
    ).readAsStringSync();

    expect(window, contains('titleVisibility = .hidden'));
    expect(window, contains('titlebarAppearsTransparent = true'));
    expect(window, contains('styleMask.insert(.fullSizeContentView)'));
    expect(window, contains('self.minSize = minimumWindowSize'));
  });

  test('mobile identity and camera platform policy is explicit', () {
    final androidManifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(androidManifest, contains('android.permission.CAMERA'));
    expect(androidManifest, contains('android.hardware.camera.any'));
    expect(androidManifest, contains('android:required="false"'));
    expect(androidManifest, contains('android:allowBackup="false"'));

    final androidBuild = File(
      'android/app/build.gradle.kts',
    ).readAsStringSync();
    expect(androidBuild, contains('minSdk = 24'));

    final iosInfo = File('ios/Runner/Info.plist').readAsStringSync();
    expect(iosInfo, contains('<key>NSCameraUsageDescription</key>'));
    expect(iosInfo, contains('<key>NSAppTransportSecurity</key>'));
    expect(
      RegExp(r'<key>NSAllowsLocalNetworking</key>\s*<true/>').hasMatch(iosInfo),
      isTrue,
    );
    expect(iosInfo, isNot(contains('<key>NSAllowsArbitraryLoads</key>')));
    expect(iosInfo, contains('<key>NSLocalNetworkUsageDescription</key>'));
    for (final fileName in <String>[
      'ios/Runner/en.lproj/InfoPlist.strings',
      'ios/Runner/zh-Hans.lproj/InfoPlist.strings',
    ]) {
      expect(
        File(fileName).readAsStringSync(),
        contains('"NSLocalNetworkUsageDescription"'),
        reason: fileName,
      );
    }
    expect(
      RegExp(r'<key>UIFileSharingEnabled</key>\s*<true/>').hasMatch(iosInfo),
      isTrue,
    );
    expect(
      RegExp(
        r'<key>LSSupportsOpeningDocumentsInPlace</key>\s*<true/>',
      ).hasMatch(iosInfo),
      isTrue,
    );
    final iosEntitlements = File(
      'ios/Runner/Runner.entitlements',
    ).readAsStringSync();
    expect(iosEntitlements, contains('<key>keychain-access-groups</key>'));
    final iosProject = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    expect(
      RegExp(
        r'CODE_SIGN_ENTITLEMENTS = Runner/Runner\.entitlements;',
      ).allMatches(iosProject),
      hasLength(3),
    );

    final androidDebugManifest = File(
      'android/app/src/debug/AndroidManifest.xml',
    ).readAsStringSync();
    expect(
      androidDebugManifest,
      contains('android:usesCleartextTraffic="true"'),
    );
    expect(
      androidManifest,
      isNot(contains('android:usesCleartextTraffic="true"')),
    );
  });

  test('Apple signing identity is loaded only from an ignored local file', () {
    final rootIgnore = File('../../.gitignore').readAsStringSync();
    expect(rootIgnore, contains('*.p8'));
    final appIgnore = File('.gitignore').readAsStringSync();
    expect(appIgnore, contains('/apple/Signing.local.xcconfig'));
    expect(appIgnore, contains('/apple/ExportOptions.local.plist'));

    final signing = File('apple/Signing.xcconfig').readAsStringSync();
    expect(signing, contains('#include? "Signing.local.xcconfig"'));
    expect(
      signing,
      contains('PRODUCT_BUNDLE_IDENTIFIER = \$(ROAMMAND_APPLE_BUNDLE_ID)'),
    );
    expect(signing, contains('DEVELOPMENT_TEAM = \$(ROAMMAND_APPLE_TEAM_ID)'));

    for (final fileName in <String>[
      'ios/Flutter/Debug.xcconfig',
      'ios/Flutter/Release.xcconfig',
    ]) {
      expect(
        File(fileName).readAsStringSync(),
        contains('#include "../../apple/Signing.xcconfig"'),
        reason: fileName,
      );
    }
    expect(
      File('macos/Runner/Configs/AppInfo.xcconfig').readAsStringSync(),
      contains('#include "../../../apple/Signing.xcconfig"'),
    );

    final iosProject = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    expect(
      RegExp(r'DEVELOPMENT_TEAM = [A-Z0-9]{10};').hasMatch(iosProject),
      isFalse,
    );
    expect(
      iosProject,
      isNot(contains('PRODUCT_BUNDLE_IDENTIFIER = dev.roammand.app;')),
    );
  });

  test(
    'Apple signing configurator validates and writes a private override',
    () {
      final temporary = Directory.systemTemp.createTempSync(
        'roammand-apple-signing-',
      );
      addTearDown(() => temporary.deleteSync(recursive: true));
      final output = '${temporary.path}/Signing.local.xcconfig';
      final script = File(
        '../../scripts/configure_apple_signing.sh',
      ).absolute.path;

      final configured = Process.runSync(script, <String>[
        '--team-id',
        'A1B2C3D4E5',
        '--bundle-id',
        'com.example.remote',
        '--output',
        output,
      ]);
      expect(configured.exitCode, 0, reason: configured.stderr as String);
      expect(
        File(output).readAsStringSync(),
        contains('ROAMMAND_APPLE_TEAM_ID = A1B2C3D4E5'),
      );
      expect(
        File(output).readAsStringSync(),
        contains('ROAMMAND_APPLE_BUNDLE_ID = com.example.remote'),
      );

      final checked = Process.runSync(script, <String>[
        '--check',
        '--output',
        output,
      ]);
      expect(checked.exitCode, 0, reason: checked.stderr as String);

      final invalid = Process.runSync(script, <String>[
        '--team-id',
        'not-a-team',
        '--bundle-id',
        'not-a-bundle-id',
        '--output',
        output,
      ]);
      expect(invalid.exitCode, isNonZero);
    },
  );
}
