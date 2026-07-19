// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:roammand/design_system/roammand_progress_indicator.dart';
import 'package:roammand/design_system/roammand_colors.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';

import 'macos_host_permissions.dart';

const _cardPadding = 20.0;
const _itemSpacing = 12.0;

final class MacOsHostPermissionsCard extends StatelessWidget {
  const MacOsHostPermissionsCard({required this.controller, super.key});

  final MacOsHostPermissionsController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Card(
      key: const Key('macos-host-permissions-card'),
      child: Padding(
        padding: const EdgeInsets.all(_cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.admin_panel_settings_outlined, size: 28),
                const SizedBox(width: _itemSpacing),
                Expanded(
                  child: Text(
                    strings.macOsHostPermissionsTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (controller.checking) const RoammandProgressIndicator(),
              ],
            ),
            const SizedBox(height: _itemSpacing),
            Text(
              controller.unavailable
                  ? strings.macOsHostPermissionsUnavailable
                  : strings.macOsHostPermissionsBody,
            ),
            const SizedBox(height: _cardPadding),
            _PermissionRow(
              title: strings.macOsScreenRecordingPermission,
              granted: controller.status?.screenRecording ?? false,
              pending:
                  controller.pendingPermission ==
                  MacOsHostPermission.screenRecording,
              enabled: !controller.unavailable,
              onPressed: () =>
                  controller.request(MacOsHostPermission.screenRecording),
              strings: strings,
            ),
            const SizedBox(height: _itemSpacing),
            _PermissionRow(
              title: strings.macOsAccessibilityPermission,
              granted: controller.status?.accessibility ?? false,
              pending:
                  controller.pendingPermission ==
                  MacOsHostPermission.accessibility,
              enabled: !controller.unavailable,
              onPressed: () =>
                  controller.request(MacOsHostPermission.accessibility),
              strings: strings,
            ),
            if (controller.unavailable) ...<Widget>[
              const SizedBox(height: _cardPadding),
              OutlinedButton.icon(
                onPressed: controller.checking ? null : controller.refresh,
                icon: const Icon(Icons.refresh, size: 20),
                label: Text(strings.retryAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.title,
    required this.granted,
    required this.pending,
    required this.enabled,
    required this.onPressed,
    required this.strings,
  });

  final String title;
  final bool granted;
  final bool pending;
  final bool enabled;
  final VoidCallback onPressed;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final statusColor = granted
        ? RoammandColors.online
        : RoammandColors.attention;
    return Row(
      children: <Widget>[
        Icon(
          granted ? Icons.check_circle_outline : Icons.error_outline,
          color: statusColor,
          size: 24,
        ),
        const SizedBox(width: _itemSpacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                granted
                    ? strings.macOsPermissionGranted
                    : strings.macOsPermissionNotGranted,
              ),
            ],
          ),
        ),
        const SizedBox(width: _itemSpacing),
        if (!granted)
          FilledButton(
            onPressed: enabled && !pending ? onPressed : null,
            child: pending
                ? const RoammandProgressIndicator()
                : Text(strings.macOsPermissionSetUpAction),
          ),
      ],
    );
  }
}
