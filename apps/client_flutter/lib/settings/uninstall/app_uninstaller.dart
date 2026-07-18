// SPDX-License-Identifier: MPL-2.0

import 'dart:io';

const macosInstalledAppExecutable =
    '/Applications/Roammand.app/Contents/MacOS/roammand';
const macosInstalledUninstaller =
    '/Library/Application Support/Roammand/uninstall-macos.sh';
const _osascriptExecutable = '/usr/bin/osascript';
const _authorizedUninstallScript =
    'do shell script (quoted form of '
    '"$macosInstalledUninstaller") '
    'with administrator privileges';

enum AppUninstallAvailability { available, developmentBuild, unavailable }

final class AppUninstallException implements Exception {
  const AppUninstallException();

  @override
  String toString() => 'AppUninstallException([REDACTED])';
}

abstract interface class AppUninstaller {
  Future<AppUninstallAvailability> availability();

  /// Requests operating-system authorization and removes installed program
  /// files, local identity, pairings, preferences, and app-specific system
  /// permissions.
  Future<void> uninstallProgram();
}

typedef UninstallFileExists = Future<bool> Function(String path);
typedef AuthorizedUninstallRunner = Future<int> Function();

final class MacOsAppUninstaller implements AppUninstaller {
  MacOsAppUninstaller({
    String? resolvedExecutable,
    UninstallFileExists? fileExists,
    AuthorizedUninstallRunner? runAuthorizedUninstaller,
  }) : _resolvedExecutable = resolvedExecutable ?? Platform.resolvedExecutable,
       _fileExists = fileExists ?? ((path) => File(path).exists()),
       _runAuthorizedUninstaller =
           runAuthorizedUninstaller ?? _runAuthorizedMacOsUninstaller;

  final String _resolvedExecutable;
  final UninstallFileExists _fileExists;
  final AuthorizedUninstallRunner _runAuthorizedUninstaller;

  @override
  Future<AppUninstallAvailability> availability() async {
    if (_resolvedExecutable != macosInstalledAppExecutable) {
      return AppUninstallAvailability.developmentBuild;
    }
    return await _fileExists(macosInstalledUninstaller)
        ? AppUninstallAvailability.available
        : AppUninstallAvailability.unavailable;
  }

  @override
  Future<void> uninstallProgram() async {
    if (await availability() != AppUninstallAvailability.available) {
      throw const AppUninstallException();
    }
    if (await _runAuthorizedUninstaller() != 0) {
      throw const AppUninstallException();
    }
  }
}

Future<int> _runAuthorizedMacOsUninstaller() async {
  try {
    final result = await Process.run(
      _osascriptExecutable,
      const <String>['-e', _authorizedUninstallScript],
      environment: const <String, String>{
        'PATH': '/usr/bin:/bin:/usr/sbin:/sbin',
      },
      includeParentEnvironment: false,
    );
    return result.exitCode;
  } on ProcessException {
    return 1;
  }
}
