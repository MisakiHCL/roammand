// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as paths;
import 'package:path_provider/path_provider.dart';

import 'diagnostics_model.dart';

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
    await directory.create(recursive: true);
    final target = await _unusedTarget(directory, _nowUtc());
    final temporary = File('${target.path}.tmp');
    if (await temporary.exists()) {
      await temporary.delete();
    }
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(target.path);
    } catch (_) {
      if (await temporary.exists()) {
        await temporary.delete();
      }
      rethrow;
    }
    return DiagnosticsExportResult(
      path: target.path,
      byteLength: bytes.length,
      usedDocumentsFallback: usedDocumentsFallback,
    );
  }
}

Future<File> _unusedTarget(Directory directory, DateTime timestamp) async {
  final base = 'roammand-diagnostics-${_timestamp(timestamp)}';
  for (var suffix = 0; suffix < 100; suffix += 1) {
    final name = suffix == 0
        ? '$base.json'
        : '$base-${suffix.toString().padLeft(2, '0')}.json';
    final candidate = File(paths.join(directory.path, name));
    if (!await candidate.exists()) {
      return candidate;
    }
  }
  throw const DiagnosticsExportException(
    DiagnosticsExportErrorCode.writeFailed,
  );
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
