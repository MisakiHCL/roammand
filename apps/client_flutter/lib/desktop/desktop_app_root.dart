// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:roammand/l10n/app_locale_controller.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';

import 'home/desktop_home_page.dart';
import 'host_agent/host_agent_controller.dart';
import 'host_agent/host_status_page.dart';
import 'host_agent/privileged_bridge_presenter.dart';
import 'tray/flutter_host_tray_port.dart';
import 'tray/host_tray_controller.dart';
import 'tray/host_tray_models.dart';
import 'tray/host_tray_port.dart';

export 'tray/flutter_host_tray_port.dart' show prepareDesktopWindow;

const _macosTrayIcon = 'assets/brand/roammand_tray_template.png';
const _windowsTrayIcon = 'windows/runner/resources/app_icon.ico';
const _signalingEndpoint = String.fromEnvironment(
  'ROAMMAND_SIGNALING_ENDPOINT',
);

final class DesktopAppRoot extends StatefulWidget {
  const DesktopAppRoot({
    super.key,
    this.hostAgentController,
    this.trayPort,
    this.home,
    this.signalingEndpoint = _signalingEndpoint,
    this.disposeHostAgentController = false,
    this.localePreference = AppLocalePreference.system,
    this.onLocalePreferenceChanged,
  });

  final HostAgentController? hostAgentController;
  final HostTrayPort? trayPort;
  final Widget? home;
  final String signalingEndpoint;
  final bool disposeHostAgentController;
  final AppLocalePreference localePreference;
  final Future<void> Function(AppLocalePreference preference)?
  onLocalePreferenceChanged;

  @override
  State<DesktopAppRoot> createState() => _DesktopAppRootState();
}

final class _DesktopAppRootState extends State<DesktopAppRoot> {
  late final HostAgentController _hostAgent;
  late final HostTrayPort _trayPort;
  late final HostTrayController _tray;
  late final bool _ownsHostAgent;
  bool _trayStarted = false;

  @override
  void initState() {
    super.initState();
    _ownsHostAgent = widget.hostAgentController == null;
    _hostAgent = widget.hostAgentController ?? HostAgentController();
    _trayPort = widget.trayPort ?? FlutterHostTrayPort();
    _tray = HostTrayController(
      port: _trayPort,
      emergencyStop: _hostAgent.emergencyStopRemoteSession,
      confirmControlledExit: _confirmControlledExit,
    );
    _hostAgent.addListener(_onHostChanged);
    unawaited(_hostAgent.start());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final strings = AppLocalizations.of(context);
    final snapshot = _traySnapshot(strings);
    if (_trayStarted) {
      unawaited(_tray.update(snapshot));
      return;
    }
    _trayStarted = true;
    unawaited(_tray.start(iconAssetPath: _trayIconAsset, snapshot: snapshot));
  }

  void _onHostChanged() {
    if (!mounted || !_trayStarted) {
      return;
    }
    unawaited(_tray.update(_traySnapshot(AppLocalizations.of(context))));
  }

  HostTraySnapshot _traySnapshot(AppLocalizations strings) {
    final bridge = presentPrivilegedBridge(_hostAgent.privilegedBridgeStatus);
    final statusLabel = switch (_hostAgent.state) {
      HostAgentViewState.connecting => strings.hostAgentConnectingTitle,
      HostAgentViewState.offline => strings.hostAgentOfflineTitle,
      HostAgentViewState.error => strings.hostAgentErrorTitle,
      HostAgentViewState.ready => _bridgeStatusLabel(strings, bridge),
    };
    return HostTraySnapshot(
      statusLabel: statusLabel,
      showLabel: strings.trayShowAction,
      emergencyStopLabel: strings.emergencyStopAction,
      exitLabel: strings.trayExitAction,
      controlActive: bridge.showEmergencyStop,
    );
  }

  Future<bool> _confirmControlledExit() async {
    await _trayPort.showWindow();
    if (!mounted) {
      return false;
    }
    final strings = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(strings.trayExitControlledTitle),
            content: Text(strings.trayExitControlledBody),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(strings.cancelAction),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(strings.trayConfirmExitAction),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) =>
      widget.home ??
      DesktopHomePage(
        localePreference: widget.localePreference,
        onLocalePreferenceChanged: widget.onLocalePreferenceChanged,
        hostPage: HostStatusPage(
          controller: _hostAgent,
          autoStart: false,
          disposeController: false,
          showAppBar: false,
          signalingEndpoint: widget.signalingEndpoint,
        ),
      );

  @override
  void dispose() {
    _hostAgent.removeListener(_onHostChanged);
    if (_ownsHostAgent || widget.disposeHostAgentController) {
      _hostAgent.dispose();
    }
    unawaited(_tray.dispose());
    super.dispose();
  }
}

String get _trayIconAsset =>
    Platform.isWindows ? _windowsTrayIcon : _macosTrayIcon;

String _bridgeStatusLabel(
  AppLocalizations strings,
  PrivilegedBridgePresentation presentation,
) => switch (presentation.kind) {
  PrivilegedBridgePresentationKind.notInstalled =>
    strings.privilegedBridgeNotInstalledTitle,
  PrivilegedBridgePresentationKind.approvalRequired =>
    strings.privilegedBridgeApprovalRequiredTitle,
  PrivilegedBridgePresentationKind.permissionRequired =>
    strings.privilegedBridgePermissionRequiredTitle,
  PrivilegedBridgePresentationKind.userSessionOnly =>
    strings.privilegedBridgeUserSessionOnlyTitle,
  PrivilegedBridgePresentationKind.readyNormal =>
    strings.privilegedBridgeReadyNormalTitle,
  PrivilegedBridgePresentationKind.readyLockedLogin =>
    strings.privilegedBridgeReadyLockedTitle,
  PrivilegedBridgePresentationKind.readySecure =>
    strings.privilegedBridgeReadySecureTitle,
  PrivilegedBridgePresentationKind.readyUnavailable =>
    strings.privilegedBridgeReadyUnavailableTitle,
  PrivilegedBridgePresentationKind.transitioning =>
    strings.privilegedBridgeTransitioningTitle,
  PrivilegedBridgePresentationKind.reconnecting =>
    strings.privilegedBridgeReconnectingTitle,
  PrivilegedBridgePresentationKind.controlled =>
    presentation.controllerDisplayName == null
        ? strings.privilegedBridgeControlledUnknownTitle
        : strings.privilegedBridgeControlledTitle(
            presentation.controllerDisplayName!,
          ),
  PrivilegedBridgePresentationKind.failed =>
    strings.privilegedBridgeFailedTitle,
  PrivilegedBridgePresentationKind.unknown =>
    strings.privilegedBridgeUnknownTitle,
};
