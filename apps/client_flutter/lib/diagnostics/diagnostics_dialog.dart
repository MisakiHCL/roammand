// SPDX-License-Identifier: MPL-2.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';

import 'diagnostics_exporter.dart';
import 'diagnostics_model.dart';

const _dialogWidth = 560.0;
const _sectionSpacing = 16.0;
const _itemSpacing = 4.0;

Future<void> showDiagnosticsDialog(
  BuildContext context, {
  required DiagnosticsReport report,
  DiagnosticsReportExporter? exporter,
}) => showDialog<void>(
  context: context,
  builder: (context) => _DiagnosticsDialog(
    report: report,
    exporter: exporter ?? FileDiagnosticsExporter.production(),
  ),
);

final class _DiagnosticsDialog extends StatefulWidget {
  const _DiagnosticsDialog({required this.report, required this.exporter});

  final DiagnosticsReport report;
  final DiagnosticsReportExporter exporter;

  @override
  State<_DiagnosticsDialog> createState() => _DiagnosticsDialogState();
}

final class _DiagnosticsDialogState extends State<_DiagnosticsDialog> {
  bool _saving = false;
  String? _savedPath;
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(strings.diagnosticsTitle),
      content: SizedBox(
        width: _dialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(strings.diagnosticsPreviewBody),
              const SizedBox(height: _sectionSpacing),
              Text(
                strings.diagnosticsIncludedTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: _itemSpacing),
              for (final item in _included(strings)) Text('• $item'),
              const SizedBox(height: _sectionSpacing),
              Text(
                strings.diagnosticsExcludedTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: _itemSpacing),
              for (final item in _excluded(strings)) Text('• $item'),
              const SizedBox(height: _sectionSpacing),
              Text(
                strings.diagnosticsEventSummary(
                  widget.report.events.length,
                  widget.report.truncated
                      ? strings.diagnosticsTruncatedYes
                      : strings.diagnosticsTruncatedNo,
                ),
              ),
              if (_savedPath case final path?) ...<Widget>[
                const SizedBox(height: _sectionSpacing),
                SelectableText(strings.diagnosticsSaved(path)),
              ],
              if (_failed) ...<Widget>[
                const SizedBox(height: _sectionSpacing),
                Text(
                  strings.diagnosticsSaveFailed,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(strings.closeAction),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : () => unawaited(_save()),
          icon: const Icon(Icons.download_outlined, size: 20),
          label: Text(
            _saving
                ? strings.diagnosticsSavingAction
                : strings.diagnosticsSaveAction,
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _failed = false;
      _savedPath = null;
    });
    try {
      final result = await widget.exporter.export(widget.report);
      if (mounted) {
        setState(() => _savedPath = result.path);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _failed = true);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

List<String> _included(AppLocalizations strings) => <String>[
  strings.diagnosticsIncludedVersions,
  strings.diagnosticsIncludedSession,
  strings.diagnosticsIncludedReconnect,
  strings.diagnosticsIncludedWebRtc,
];

List<String> _excluded(AppLocalizations strings) => <String>[
  strings.diagnosticsExcludedDeviceIdentifiers,
  strings.diagnosticsExcludedDeviceNames,
  strings.diagnosticsExcludedKeys,
  strings.diagnosticsExcludedTokens,
  strings.diagnosticsExcludedSdpIce,
  strings.diagnosticsExcludedNetworkAddresses,
  strings.diagnosticsExcludedInput,
  strings.diagnosticsExcludedScreen,
  strings.diagnosticsExcludedRawPayloads,
  strings.diagnosticsExcludedRawStats,
];
