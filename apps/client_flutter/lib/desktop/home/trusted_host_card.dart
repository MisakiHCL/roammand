// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:roammand/design_system/roammand_progress_indicator.dart';
import 'package:roammand/design_system/roammand_colors.dart';
import 'package:roammand/design_system/roammand_surfaces.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand/pairing/trusted_host_repository.dart';

const _cardPadding = 20.0;
const _spacing = 12.0;

final class TrustedHostCard extends StatelessWidget {
  const TrustedHostCard({
    required this.host,
    required this.connecting,
    required this.deleting,
    required this.onConnect,
    required this.onDelete,
    super.key,
  });

  final TrustedHostRecord host;
  final bool connecting;
  final bool deleting;
  final VoidCallback? onConnect;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final paired = _formatDateTime(context, host.pairedAtUnixMs);
    final lastConnected = host.lastSuccessfulConnectionAtUnixMs == 0
        ? strings.neverConnected
        : _formatDateTime(context, host.lastSuccessfulConnectionAtUnixMs);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_cardPadding),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: _spacing,
          runSpacing: _spacing,
          children: <Widget>[
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: RoammandColors.auroraIndigo.withValues(
                        alpha: 0.14,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.computer_outlined,
                      color: RoammandColors.auroraSoft,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          host.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        RoammandStatusPill(
                          label: strings.computerReadyLabel,
                          tone: RoammandStatusTone.online,
                        ),
                        const SizedBox(height: 12),
                        Text(strings.trustedHostPairedLabel(paired)),
                        const SizedBox(height: 4),
                        Text(
                          strings.trustedHostLastConnectedLabel(lastConnected),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: _spacing,
              runSpacing: _spacing,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: deleting || connecting ? null : onDelete,
                  icon: deleting
                      ? const RoammandProgressIndicator(
                          size: roammandCompactProgressIndicatorSize,
                        )
                      : const Icon(Icons.delete_outline, size: 20),
                  label: Text(strings.deleteTrustedHostAction),
                ),
                FilledButton.icon(
                  onPressed: deleting || connecting ? null : onConnect,
                  icon: connecting
                      ? const RoammandProgressIndicator(
                          size: roammandCompactProgressIndicatorSize,
                        )
                      : const Icon(Icons.arrow_forward, size: 20),
                  label: Text(
                    connecting
                        ? strings.connectingAction
                        : strings.openRemoteAction,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(BuildContext context, int unixMs) {
  final value = DateTime.fromMillisecondsSinceEpoch(unixMs).toLocal();
  final localizations = MaterialLocalizations.of(context);
  return '${localizations.formatFullDate(value)} ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(value))}';
}
