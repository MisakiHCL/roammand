// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as paths;
import 'package:path_provider/path_provider.dart';

import 'diagnostics_model.dart';

const _maximumTargetNameAttempts = 100;

enum DiagnosticsExportErrorCode { directoryUnavailable, tooLarge, writeFailed }

final class DiagnosticsExportException implements Exception {
  const DiagnosticsExportException(this.code);

  final DiagnosticsExportErrorCode code;

  @override
  String toString() => 'DiagnosticsExportException(${code.name})';
}

final class DiagnosticsExportResult {
  const DiagnosticsExportResult({
    required this.path,
    required this.byteLength,
    required this.usedDocumentsFallback,
  });

  final String path;
  final int byteLength;
  final bool usedDocumentsFallback;
}

abstract interface class DiagnosticsReportExporter {
  Future<DiagnosticsExportResult> export(DiagnosticsReport report);
}

abstract interface class DiagnosticsDirectoryProvider {
  Future<Directory?> downloadsDirectory();

  Future<Directory> documentsDirectory();
}

final class PlatformDiagnosticsDirectoryProvider
    implements DiagnosticsDirectoryProvider {
  const PlatformDiagnosticsDirectoryProvider();

  @override
  Future<Directory?> downloadsDirectory() async {
    try {
      return await getDownloadsDirectory();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Directory> documentsDirectory() => getApplicationDocumentsDirectory();
}

final class FileDiagnosticsExporter implements DiagnosticsReportExporter {
  factory FileDiagnosticsExporter.production() => FileDiagnosticsExporter(
    directories: const PlatformDiagnosticsDirectoryProvider(),
    nowUtc: () => DateTime.now().toUtc(),
  );

  factory FileDiagnosticsExporter({
    required DiagnosticsDirectoryProvider directories,
    required DateTime Function() nowUtc,
  }) => FileDiagnosticsExporter._(directories, nowUtc);

  const FileDiagnosticsExporter._(this._directories, this._nowUtc);

  final DiagnosticsDirectoryProvider _directories;
  final DateTime Function() _nowUtc;

  @override
  Future<DiagnosticsExportResult> export(DiagnosticsReport report) async {
    final bytes = utf8.encode(report.encodeJson());
    if (bytes.length > maximumDiagnosticsFileBytes) {
      throw const DiagnosticsExportException(
        DiagnosticsExportErrorCode.tooLarge,
      );
    }

    Directory? downloads;
    try {
      downloads = await _directories.downloadsDirectory();
    } catch (_) {
      downloads = null;
    }
    if (downloads != null) {
      try {
        return await _write(downloads, bytes, usedDocumentsFallback: false);
      } catch (_) {
        // Fall through to the app documents directory.
      }
    }
    try {
      final documents = await _directories.documentsDirectory();
      return await _write(documents, bytes, usedDocumentsFallback: true);
    } catch (_) {
      throw const DiagnosticsExportException(
        DiagnosticsExportErrorCode.writeFailed,
      );
    }
  }

  Future<DiagnosticsExportResult> _write(
    Directory directory,
    List<int> bytes, {
    required bool usedDocumentsFallback,
  }) async {
    final existingDirectoryType = await FileSystemEntity.type(
      directory.path,
      followLinks: false,
    );
    if (existingDirectoryType != FileSystemEntityType.notFound &&
        existingDirectoryType != FileSystemEntityType.directory) {
      throw const DiagnosticsExportException(
        DiagnosticsExportErrorCode.writeFailed,
      );
    }
    if (existingDirectoryType == FileSystemEntityType.notFound) {
      await directory.create(recursive: true);
    }
    if (await FileSystemEntity.type(directory.path, followLinks: false) !=
        FileSystemEntityType.directory) {
      throw const DiagnosticsExportException(
        DiagnosticsExportErrorCode.writeFailed,
      );
    }
    final target = await _reserveTarget(directory, _nowUtc());
    try {
      await target.writeAsBytes(bytes, flush: true);
    } catch (_) {
      await _deletePartialFile(target);
      rethrow;
    }
    return DiagnosticsExportResult(
      path: target.path,
      byteLength: bytes.length,
      usedDocumentsFallback: usedDocumentsFallback,
    );
  }
}

Future<File> _reserveTarget(Directory directory, DateTime timestamp) async {
  final base = 'roammand-diagnostics-${_timestamp(timestamp)}';
  for (var suffix = 0; suffix < _maximumTargetNameAttempts; suffix += 1) {
    final name = suffix == 0
        ? '$base.json'
        : '$base-${suffix.toString().padLeft(2, '0')}.json';
    final candidate = File(paths.join(directory.path, name));
    try {
      await candidate.create(exclusive: true);
      return candidate;
    } on PathExistsException {
      // Concurrent exports and pre-positioned entries must never be reused.
    }
  }
  throw const DiagnosticsExportException(
    DiagnosticsExportErrorCode.writeFailed,
  );
}

Future<void> _deletePartialFile(File target) async {
  try {
    final type = await FileSystemEntity.type(target.path, followLinks: false);
    if (type == FileSystemEntityType.file ||
        type == FileSystemEntityType.link) {
      await target.delete();
    }
  } catch (_) {
    // Cleanup is best effort and must not replace the original write error.
  }
}

String _timestamp(DateTime value) {
  final utc = value.toUtc();
  return '${utc.year.toString().padLeft(4, '0')}'
      '${utc.month.toString().padLeft(2, '0')}'
      '${utc.day.toString().padLeft(2, '0')}-'
      '${utc.hour.toString().padLeft(2, '0')}'
      '${utc.minute.toString().padLeft(2, '0')}'
      '${utc.second.toString().padLeft(2, '0')}Z';
}
