// SPDX-License-Identifier: MPL-2.0

import 'dart:io';

import 'package:flutter/services.dart';

const macosInstalledAppExecutable =
    '/Applications/Roammand.app/Contents/MacOS/roammand';
const macosInstalledUninstaller =
    '/Library/Application Support/Roammand/uninstall-macos.sh';
const _uninstallerChannelName = 'dev.roammand/uninstaller';
const _uninstallMethodName = 'uninstall';
const _uninstallerChannel = MethodChannel(_uninstallerChannelName);

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
    await _uninstallerChannel.invokeMethod<void>(_uninstallMethodName);
    return 0;
  } on PlatformException catch (_) {
    return 1;
  } on MissingPluginException catch (_) {
    return 1;
  }
}
