// SPDX-License-Identifier: MPL-2.0

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/diagnostics/diagnostics_collector.dart';
import 'package:roammand/diagnostics/diagnostics_exporter.dart';
import 'package:roammand/diagnostics/diagnostics_model.dart';

void main() {
  test('writes to Downloads only after explicit export', () async {
    final root = await Directory.systemTemp.createTemp('roammand-diagnostics-');
    addTearDown(() => root.delete(recursive: true));
    final downloads = Directory('${root.path}/Downloads')..createSync();
    final documents = Directory('${root.path}/Documents')..createSync();
    final exporter = FileDiagnosticsExporter(
      directories: _Directories(downloads: downloads, documents: documents),
      nowUtc: () => DateTime.utc(2026, 7, 14, 8, 9, 10),
    );

    expect(downloads.listSync(), isEmpty);
    expect(documents.listSync(), isEmpty);
    final result = await exporter.export(_report());

    expect(result.usedDocumentsFallback, isFalse);
    expect(
      result.path,
      '${downloads.path}${Platform.pathSeparator}'
      'roammand-diagnostics-20260714-080910Z.json',
    );
    final file = File(result.path);
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), lessThanOrEqualTo(maximumDiagnosticsFileBytes));
    expect(downloads.listSync().whereType<File>(), hasLength(1));
    expect(
      downloads.listSync().map((entry) => entry.path),
      isNot(contains(endsWith('.tmp'))),
    );
    expect(documents.listSync(), isEmpty);
  });

  test(
    'concurrent exports reserve distinct targets without overwrite',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'roammand-diagnostics-',
      );
      addTearDown(() => root.delete(recursive: true));
      final downloads = Directory('${root.path}/Downloads')..createSync();
      final documents = Directory('${root.path}/Documents')..createSync();
      final exporter = FileDiagnosticsExporter(
        directories: _Directories(downloads: downloads, documents: documents),
        nowUtc: () => DateTime.utc(2026, 7, 14, 8, 9, 10),
      );

      final results = await Future.wait(
        List<Future<DiagnosticsExportResult>>.generate(
          16,
          (_) => exporter.export(_report()),
        ),
      );

      expect(results.map((result) => result.path).toSet(), hasLength(16));
      expect(downloads.listSync().whereType<File>(), hasLength(16));
      for (final result in results) {
        expect(File(result.path).lengthSync(), result.byteLength);
      }
      expect(documents.listSync(), isEmpty);
    },
  );

  test('falls back to app documents and rejects oversized output', () async {
    final root = await Directory.systemTemp.createTemp('roammand-diagnostics-');
    addTearDown(() => root.delete(recursive: true));
    final documents = Directory('${root.path}/Documents')..createSync();
    final exporter = FileDiagnosticsExporter(
      directories: _Directories(documents: documents),
      nowUtc: () => DateTime.utc(2026, 7, 14),
    );

    final result = await exporter.export(_report());
    expect(result.usedDocumentsFallback, isTrue);
    expect(File(result.path).parent.path, documents.path);

    final oversized = DiagnosticsCollector(
      metadata: DiagnosticsMetadata(
        appVersion: 'x' * maximumDiagnosticsFileBytes,
        protocolMajor: 1,
        protocolMinor: 0,
        osFamily: DiagnosticsOsFamily.ios,
      ),
      nowUnixMs: () => 1,
    ).snapshot();
    await expectLater(
      exporter.export(oversized),
      throwsA(
        isA<DiagnosticsExportException>().having(
          (error) => error.code,
          'code',
          DiagnosticsExportErrorCode.tooLarge,
        ),
      ),
    );
    expect(documents.listSync().whereType<File>(), hasLength(1));
  });

  test('does not follow pre-positioned export symlinks', () async {
    if (Platform.isWindows) {
      return;
    }
    final root = await Directory.systemTemp.createTemp('roammand-diagnostics-');
    addTearDown(() => root.delete(recursive: true));
    final downloads = Directory('${root.path}/Downloads')..createSync();
    final documents = Directory('${root.path}/Documents')..createSync();
    const timestamp = '20260714-080910Z';
    final target = '${downloads.path}/roammand-diagnostics-$timestamp.json';
    final legacyTemporary = '$target.tmp';
    final targetVictim = File('${root.path}/target-victim.json');
    final temporaryVictim = File('${root.path}/temporary-victim.json');
    await Link(target).create(targetVictim.path);
    await Link(legacyTemporary).create(temporaryVictim.path);
    final exporter = FileDiagnosticsExporter(
      directories: _Directories(downloads: downloads, documents: documents),
      nowUtc: () => DateTime.utc(2026, 7, 14, 8, 9, 10),
    );

    final result = await exporter.export(_report());

    expect(
      result.path,
      '${downloads.path}/roammand-diagnostics-$timestamp-01.json',
    );
    expect(
      await FileSystemEntity.type(target, followLinks: false),
      FileSystemEntityType.link,
    );
    expect(
      await FileSystemEntity.type(legacyTemporary, followLinks: false),
      FileSystemEntityType.link,
    );
    expect(targetVictim.existsSync(), isFalse);
    expect(temporaryVictim.existsSync(), isFalse);
  });

  test('rejects a symlinked export directory and uses the fallback', () async {
    if (Platform.isWindows) {
      return;
    }
    final root = await Directory.systemTemp.createTemp('roammand-diagnostics-');
    addTearDown(() => root.delete(recursive: true));
    final redirectedDownloads = Directory('${root.path}/RedirectedDownloads');
    final downloadsLink = Link('${root.path}/Downloads');
    await downloadsLink.create(redirectedDownloads.path);
    final documents = Directory('${root.path}/Documents')..createSync();
    final exporter = FileDiagnosticsExporter(
      directories: _Directories(
        downloads: Directory(downloadsLink.path),
        documents: documents,
      ),
      nowUtc: () => DateTime.utc(2026, 7, 14),
    );

    final result = await exporter.export(_report());

    expect(result.usedDocumentsFallback, isTrue);
    expect(File(result.path).parent.path, documents.path);
    expect(redirectedDownloads.existsSync(), isFalse);
  });
}

final class _Directories implements DiagnosticsDirectoryProvider {
  const _Directories({this.downloads, required this.documents});

  final Directory? downloads;
  final Directory documents;

  @override
  Future<Directory?> downloadsDirectory() async => downloads;

  @override
  Future<Directory> documentsDirectory() async => documents;
}

DiagnosticsReport _report() {
  final collector = DiagnosticsCollector(
    metadata: const DiagnosticsMetadata(
      appVersion: '0.0.1',
      protocolMajor: 1,
      protocolMinor: 0,
      osFamily: DiagnosticsOsFamily.macos,
    ),
    nowUnixMs: () => 1000,
  )..recordState(DiagnosticsSessionState.connected);
  return collector.snapshot();
}
