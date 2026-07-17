// SPDX-License-Identifier: MPL-2.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:roammand/design_system/roammand_brand_mark.dart';
import 'package:roammand/design_system/roammand_surfaces.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

import '../pairing/host_pairing_section.dart';
import '../desktop_app_bar.dart';
import 'host_agent_controller.dart';
import 'host_agent_process.dart';
import 'privileged_bridge_presenter.dart';

const _pagePadding = 24.0;
const _sectionSpacing = 24.0;
const _itemSpacing = 12.0;
const _cardPadding = 20.0;
const _maximumContentWidth = 960.0;
const _fingerprintBytes = 8;

final class HostStatusPage extends StatefulWidget {
  const HostStatusPage({
    super.key,
    this.controller,
    this.showAppBar = true,
    this.signalingEndpoint = '',
    this.nowUnixMs,
    this.autoStart = true,
    this.disposeController = true,
  });

  final HostAgentController? controller;
  final bool showAppBar;
  final String signalingEndpoint;
  final int Function()? nowUnixMs;
  final bool autoStart;
  final bool disposeController;

  @override
  State<HostStatusPage> createState() => _HostStatusPageState();
}

final class _HostStatusPageState extends State<HostStatusPage> {
  late final HostAgentController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? HostAgentController();
    _controller.addListener(_onChanged);
    if (widget.autoStart) {
      unawaited(_controller.start());
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    if (widget.disposeController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: widget.showAppBar
          ? RoammandDesktopAppBar(
              platform: Theme.of(context).platform,
              title: RoammandAppBarTitle(title: strings.desktopHostTitle),
            )
          : null,
      body: RoammandBackdrop(
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maximumContentWidth),
              child: ListView(
                padding: const EdgeInsets.all(_pagePadding),
                children: <Widget>[
                  _buildStateCard(context, strings),
                  if (_controller.state ==
                      HostAgentViewState.ready) ...<Widget>[
                    const SizedBox(height: _sectionSpacing),
                    HostPairingSection(
                      controller: _controller,
                      signalingEndpoint: widget.signalingEndpoint,
                      nowUnixMs: widget.nowUnixMs,
                    ),
                    const SizedBox(height: _sectionSpacing),
                    _buildControllers(context, strings),
                    const SizedBox(height: _sectionSpacing),
                    _buildPrivilegedBridgeCard(context, strings),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivilegedBridgeCard(
    BuildContext context,
    AppLocalizations strings,
  ) {
    final presentation = presentPrivilegedBridge(
      _controller.privilegedBridgeStatus,
    );
    final copy = _bridgeCopy(strings, presentation);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              strings.privilegedBridgeSectionTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: _itemSpacing),
            Wrap(
              spacing: _itemSpacing,
              runSpacing: _itemSpacing,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Icon(_bridgeIcon(presentation.kind), size: 32),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        copy.title,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(copy.body),
                    ],
                  ),
                ),
                if (presentation.showEmergencyStop)
                  FilledButton.icon(
                    onPressed: _controller.isEmergencyStopPending
                        ? null
                        : () => _confirmEmergencyStop(context, strings),
                    icon: _controller.isEmergencyStopPending
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.stop_circle_outlined, size: 20),
                    label: Text(
                      _controller.isEmergencyStopPending
                          ? strings.emergencyStoppingAction
                          : strings.emergencyStopAction,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmEmergencyStop(
    BuildContext context,
    AppLocalizations strings,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.emergencyStopDialogTitle),
        content: Text(strings.emergencyStopDialogBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.confirmEmergencyStopAction),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) {
      return;
    }
    await _controller.emergencyStopRemoteSession();
    if (!context.mounted) {
      return;
    }
    final message =
        _controller.emergencyStopOutcome == EmergencyStopOutcome.succeeded
        ? strings.emergencyStopSucceeded
        : strings.emergencyStopFailed;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildStateCard(BuildContext context, AppLocalizations strings) {
    final offlineCopy = _hostAgentOfflineCopy(
      strings,
      _controller.startupFailure,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_cardPadding),
        child: switch (_controller.state) {
          HostAgentViewState.connecting => _MessageState(
            icon: const SizedBox.square(
              dimension: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            title: strings.hostAgentConnectingTitle,
            body: strings.hostAgentConnectingBody,
          ),
          HostAgentViewState.offline => _MessageState(
            icon: const Icon(Icons.desktop_access_disabled_outlined, size: 32),
            title: offlineCopy.title,
            body: offlineCopy.body,
            action: FilledButton.icon(
              onPressed: _controller.retry,
              icon: const Icon(Icons.refresh, size: 20),
              label: Text(strings.retryAction),
            ),
          ),
          HostAgentViewState.error => _MessageState(
            icon: Icon(
              Icons.error_outline,
              size: 32,
              color: Theme.of(context).colorScheme.error,
            ),
            title: strings.hostAgentErrorTitle,
            body: strings.hostAgentErrorBody,
            action: FilledButton.icon(
              onPressed: _controller.retry,
              icon: const Icon(Icons.refresh, size: 20),
              label: Text(strings.retryAction),
            ),
          ),
          HostAgentViewState.ready => _buildReadyHeader(context, strings),
        },
      ),
    );
  }

  Widget _buildReadyHeader(BuildContext context, AppLocalizations strings) {
    final status = _controller.status;
    if (status == null || !status.hasIdentity()) {
      return _MessageState(
        icon: Icon(
          Icons.error_outline,
          size: 32,
          color: Theme.of(context).colorScheme.error,
        ),
        title: strings.hostAgentErrorTitle,
        body: strings.hostAgentErrorBody,
      );
    }
    final identity = status.identity;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          strings.hostIdentitySectionTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: _itemSpacing),
        Wrap(
          spacing: _itemSpacing,
          runSpacing: _itemSpacing,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            const Icon(Icons.computer_outlined, size: 32),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    identity.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    strings.hostShortFingerprint(
                      _shortFingerprint(identity.deviceId),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.authorizedControllerCount(
                      _controller.grants.length,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: _controller.isRefreshing ? null : _controller.refresh,
              icon: _controller.isRefreshing
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 20),
              label: Text(strings.refreshAction),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControllers(BuildContext context, AppLocalizations strings) {
    final grants = _controller.grants;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          strings.authorizedControllersSectionTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: _itemSpacing),
        if (grants.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(_cardPadding),
              child: Text(strings.noAuthorizedControllers),
            ),
          )
        else
          for (final view in grants) ...<Widget>[
            _buildGrantCard(context, strings, view),
            const SizedBox(height: _itemSpacing),
          ],
      ],
    );
  }

  Widget _buildGrantCard(
    BuildContext context,
    AppLocalizations strings,
    ControllerGrantView view,
  ) {
    final grant = view.hasGrant() ? view.grant : null;
    final controller = grant?.hasController() ?? false
        ? grant!.controller
        : null;
    final controllerName = controller?.displayName.isNotEmpty ?? false
        ? controller!.displayName
        : strings.unknownControllerName;
    final grantId = grant?.grantId ?? const <int>[];
    final revoking = _controller.isRevoking(grantId);
    final created = grant == null || grant.createdAtUnixMs.toInt() == 0
        ? strings.unknownDate
        : _formatDateTime(context, grant.createdAtUnixMs.toInt());
    final lastConnected = view.lastSuccessfulConnectionAtUnixMs.toInt() == 0
        ? strings.neverConnected
        : _formatDateTime(
            context,
            view.lastSuccessfulConnectionAtUnixMs.toInt(),
          );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_cardPadding),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: _itemSpacing,
          runSpacing: _itemSpacing,
          children: <Widget>[
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    controllerName,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(strings.grantCreatedLabel(created)),
                  const SizedBox(height: 4),
                  Text(strings.grantLastConnectedLabel(lastConnected)),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: grant == null || revoking
                  ? null
                  : () => _confirmRevoke(
                      context,
                      strings,
                      controllerName,
                      grantId,
                    ),
              icon: revoking
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.link_off, size: 20),
              label: Text(
                revoking ? strings.revokingAction : strings.revokeAction,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRevoke(
    BuildContext context,
    AppLocalizations strings,
    String controllerName,
    List<int> grantId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.revokeDialogTitle(controllerName)),
        content: Text(strings.revokeDialogBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.confirmRevokeAction),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await _controller.revokeControllerGrant(grantId);
    }
  }
}

({String title, String body}) _hostAgentOfflineCopy(
  AppLocalizations strings,
  HostAgentStartupFailure? failure,
) {
  return switch (failure) {
    HostAgentStartupFailure.protectedSessionAgentUnavailable => (
      title: strings.hostAgentProtectedSessionUnavailableTitle,
      body: strings.hostAgentProtectedSessionUnavailableBody,
    ),
    HostAgentStartupFailure.privilegedBridgeUnavailable => (
      title: strings.hostAgentPrivilegedBridgeUnavailableTitle,
      body: strings.hostAgentPrivilegedBridgeUnavailableBody,
    ),
    HostAgentStartupFailure.executableUnavailable => (
      title: strings.hostAgentComponentMissingTitle,
      body: strings.hostAgentComponentMissingBody,
    ),
    HostAgentStartupFailure.processLaunchFailed => (
      title: strings.hostAgentLaunchFailedTitle,
      body: strings.hostAgentLaunchFailedBody,
    ),
    HostAgentStartupFailure.configurationInvalid => (
      title: strings.hostAgentConfigurationInvalidTitle,
      body: strings.hostAgentConfigurationInvalidBody,
    ),
    HostAgentStartupFailure.unexpectedExit => (
      title: strings.hostAgentUnexpectedExitTitle,
      body: strings.hostAgentUnexpectedExitBody,
    ),
    HostAgentStartupFailure.automaticStartupDisabled || null => (
      title: strings.hostAgentOfflineTitle,
      body: strings.hostAgentOfflineBody,
    ),
  };
}

({String title, String body}) _bridgeCopy(
  AppLocalizations strings,
  PrivilegedBridgePresentation presentation,
) => switch (presentation.kind) {
  PrivilegedBridgePresentationKind.notInstalled => (
    title: strings.privilegedBridgeNotInstalledTitle,
    body: strings.privilegedBridgeNotInstalledBody,
  ),
  PrivilegedBridgePresentationKind.approvalRequired => (
    title: strings.privilegedBridgeApprovalRequiredTitle,
    body: strings.privilegedBridgeApprovalRequiredBody,
  ),
  PrivilegedBridgePresentationKind.permissionRequired => (
    title: strings.privilegedBridgePermissionRequiredTitle,
    body: strings.privilegedBridgePermissionRequiredBody,
  ),
  PrivilegedBridgePresentationKind.userSessionOnly => (
    title: strings.privilegedBridgeUserSessionOnlyTitle,
    body: strings.privilegedBridgeUserSessionOnlyBody,
  ),
  PrivilegedBridgePresentationKind.readyNormal => (
    title: strings.privilegedBridgeReadyNormalTitle,
    body: strings.privilegedBridgeReadyNormalBody,
  ),
  PrivilegedBridgePresentationKind.readyLockedLogin => (
    title: strings.privilegedBridgeReadyLockedTitle,
    body: strings.privilegedBridgeReadyLockedBody,
  ),
  PrivilegedBridgePresentationKind.readySecure => (
    title: strings.privilegedBridgeReadySecureTitle,
    body: strings.privilegedBridgeReadySecureBody,
  ),
  PrivilegedBridgePresentationKind.readyUnavailable => (
    title: strings.privilegedBridgeReadyUnavailableTitle,
    body: strings.privilegedBridgeReadyUnavailableBody,
  ),
  PrivilegedBridgePresentationKind.transitioning => (
    title: strings.privilegedBridgeTransitioningTitle,
    body: strings.privilegedBridgeTransitioningBody,
  ),
  PrivilegedBridgePresentationKind.reconnecting => (
    title: strings.privilegedBridgeReconnectingTitle,
    body: strings.privilegedBridgeReconnectingBody,
  ),
  PrivilegedBridgePresentationKind.controlled => (
    title: presentation.controllerDisplayName == null
        ? strings.privilegedBridgeControlledUnknownTitle
        : strings.privilegedBridgeControlledTitle(
            presentation.controllerDisplayName!,
          ),
    body: strings.privilegedBridgeControlledBody,
  ),
  PrivilegedBridgePresentationKind.failed => (
    title: strings.privilegedBridgeFailedTitle,
    body: strings.privilegedBridgeFailedBody,
  ),
  PrivilegedBridgePresentationKind.unknown => (
    title: strings.privilegedBridgeUnknownTitle,
    body: strings.privilegedBridgeUnknownBody,
  ),
};

IconData _bridgeIcon(PrivilegedBridgePresentationKind kind) => switch (kind) {
  PrivilegedBridgePresentationKind.controlled => Icons.screen_share_outlined,
  PrivilegedBridgePresentationKind.transitioning ||
  PrivilegedBridgePresentationKind.reconnecting => Icons.sync,
  PrivilegedBridgePresentationKind.failed ||
  PrivilegedBridgePresentationKind.unknown => Icons.error_outline,
  PrivilegedBridgePresentationKind.notInstalled ||
  PrivilegedBridgePresentationKind.approvalRequired ||
  PrivilegedBridgePresentationKind.permissionRequired ||
  PrivilegedBridgePresentationKind.userSessionOnly => Icons.security_outlined,
  PrivilegedBridgePresentationKind.readyNormal ||
  PrivilegedBridgePresentationKind.readyLockedLogin ||
  PrivilegedBridgePresentationKind.readySecure ||
  PrivilegedBridgePresentationKind.readyUnavailable =>
    Icons.verified_user_outlined,
};

final class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final Widget icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: _itemSpacing,
      runSpacing: _itemSpacing,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        icon,
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(body),
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

String _shortFingerprint(List<int> deviceId) {
  final visible = deviceId.take(_fingerprintBytes);
  if (visible.isEmpty) {
    return '—';
  }
  return visible
      .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join();
}

String _formatDateTime(BuildContext context, int unixMs) {
  final value = DateTime.fromMillisecondsSinceEpoch(unixMs).toLocal();
  final localizations = MaterialLocalizations.of(context);
  return '${localizations.formatFullDate(value)} ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(value))}';
}
