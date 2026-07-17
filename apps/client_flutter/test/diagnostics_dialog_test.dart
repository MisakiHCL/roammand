// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/diagnostics/diagnostics_collector.dart';
import 'package:roammand/diagnostics/diagnostics_dialog.dart';
import 'package:roammand/diagnostics/diagnostics_exporter.dart';
import 'package:roammand/diagnostics/diagnostics_model.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('previews included/excluded data before user-triggered save', (
    tester,
  ) async {
    final exporter = _Exporter();
    await tester.pumpWidget(_app(exporter));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(exporter.count, 0);
    expect(find.text('Privacy-protected diagnostics'), findsOneWidget);
    expect(find.text('Included'), findsOneWidget);
    expect(find.text('Excluded'), findsOneWidget);
    expect(
      find.textContaining('Overall connection-quality measurements'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Input content and coordinates'),
      findsOneWidget,
    );

    await tester.tap(find.text('Save report'));
    await tester.pumpAndSettle();
    expect(exporter.count, 1);
    expect(
      find.text('Saved locally to /safe/diagnostics.json'),
      findsOneWidget,
    );
  });

  testWidgets('shows a localized save failure without closing the preview', (
    tester,
  ) async {
    final exporter = _Exporter(fail: true);
    await tester.pumpWidget(_app(exporter, locale: const Locale('zh')));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存报告'));
    await tester.pumpAndSettle();

    expect(find.text('无法保存诊断报告。'), findsOneWidget);
    expect(find.text('隐私保护的诊断报告'), findsOneWidget);
  });
}

final class _Exporter implements DiagnosticsReportExporter {
  _Exporter({this.fail = false});

  final bool fail;
  int count = 0;

  @override
  Future<DiagnosticsExportResult> export(DiagnosticsReport report) async {
    count += 1;
    if (fail) {
      throw const DiagnosticsExportException(
        DiagnosticsExportErrorCode.writeFailed,
      );
    }
    return const DiagnosticsExportResult(
      path: '/safe/diagnostics.json',
      byteLength: 100,
      usedDocumentsFallback: false,
    );
  }
}

Widget _app(_Exporter exporter, {Locale? locale}) {
  final report = DiagnosticsCollector(
    metadata: const DiagnosticsMetadata(
      appVersion: '0.0.1',
      protocolMajor: 1,
      protocolMinor: 0,
      osFamily: DiagnosticsOsFamily.macos,
    ),
    nowUnixMs: () => 1000,
  ).snapshot();
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => showDiagnosticsDialog(
            context,
            report: report,
            exporter: exporter,
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  );
}
