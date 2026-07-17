// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:roammand/l10n/app_locale_controller.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand/network/network_service_configuration.dart';
import 'package:roammand/network/network_service_controller.dart';
import 'package:roammand/settings/uninstall/app_uninstaller.dart';

import 'home/desktop_home_page.dart';
import 'host_agent/host_agent_controller.dart';
import 'host_agent/host_agent_process.dart';
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
    this.hostAgentProcessLifecycle,
    this.networkServices,
    this.trayPort,
    this.home,
    this.signalingEndpoint = _signalingEndpoint,
    this.disposeHostAgentController = false,
    this.localePreference = AppLocalePreference.system,
    this.onLocalePreferenceChanged,
    this.appUninstaller,
  });

  final HostAgentController? hostAgentController;
  final HostAgentProcessLifecycle? hostAgentProcessLifecycle;
  final NetworkServiceController? networkServices;
  final HostTrayPort? trayPort;
  final Widget? home;
  final String signalingEndpoint;
  final bool disposeHostAgentController;
  final AppLocalePreference localePreference;
  final Future<void> Function(AppLocalePreference preference)?
  onLocalePreferenceChanged;
  final AppUninstaller? appUninstaller;

  @override
  State<DesktopAppRoot> createState() => _DesktopAppRootState();
}

final class _DesktopAppRootState extends State<DesktopAppRoot> {
  late final HostAgentController _hostAgent;
  late final NetworkServiceController _networkServices;
  late NetworkServiceConfiguration _networkConfiguration;
  late final HostTrayPort _trayPort;
  late final HostTrayController _tray;
  late final bool _ownsHostAgent;
  late final bool _ownsNetworkServices;
  bool _trayStarted = false;
  Future<void> _pendingNetworkRestart = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _ownsNetworkServices = widget.networkServices == null;
    _networkServices =
        widget.networkServices ??
        NetworkServiceController.transient(
          configuration: _legacyNetworkConfiguration(widget.signalingEndpoint),
        );
    _networkConfiguration = _networkServices.configuration;
    _networkServices.addListener(_onNetworkConfigurationChanged);
    _ownsHostAgent = widget.hostAgentController == null;
    _hostAgent =
        widget.hostAgentController ??
        HostAgentController(
          processLifecycle:
              widget.hostAgentProcessLifecycle ??
              DesktopHostAgentProcess(configuration: _networkConfiguration),
        );
    _trayPort = widget.trayPort ?? FlutterHostTrayPort();
    _tray = HostTrayController(
      port: _trayPort,
      emergencyStop: _hostAgent.emergencyStopRemoteSession,
      confirmControlledExit: _confirmControlledExit,
      beforeExit: _shutdownOwnedHostAgent,
    );
    _hostAgent.addListener(_onHostChanged);
    unawaited(_hostAgent.start());
  }

  void _onNetworkConfigurationChanged() {
    final next = _networkServices.configuration;
    if (next == _networkConfiguration) return;
    _networkConfiguration = next;
    if (mounted) setState(() {});
    _pendingNetworkRestart = _pendingNetworkRestart
        .then((_) => _hostAgent.applyNetworkConfiguration(next))
        .then<void>(
          _handleNetworkRestartOutcome,
          onError: (_) {
            if (!mounted) return;
            _showNetworkRestartMessage(
              AppLocalizations.of(context).networkHostRestartFailed,
            );
          },
        );
  }

  void _handleNetworkRestartOutcome(ManagedHostAgentRestartOutcome outcome) {
    if (!mounted) return;
    final strings = AppLocalizations.of(context);
    switch (outcome) {
      case ManagedHostAgentRestartOutcome.restarted:
        return;
      case ManagedHostAgentRestartOutcome.notOwned:
        _showNetworkRestartMessage(strings.networkExternalHostRestartRequired);
        return;
      case ManagedHostAgentRestartOutcome.unavailable:
        _showNetworkRestartMessage(strings.networkHostRestartFailed);
        return;
    }
  }

  void _showNetworkRestartMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
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
    return HostTraySnapshot(
      tooltipLabel: strings.appTitle,
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

  Future<void> _shutdownOwnedHostAgent() {
    if (!_ownsHostAgent && !widget.disposeHostAgentController) {
      return Future<void>.value();
    }
    return _hostAgent.shutdown();
  }

  Future<void> _prepareForUninstall() async {
    try {
      await _hostAgent.emergencyStopRemoteSession();
    } catch (_) {
      // The root-owned uninstaller still stops every installed process. This
      // request only gives an available Agent a chance to release input first.
    }
  }

  @override
  Widget build(BuildContext context) =>
      widget.home ??
      DesktopHomePage(
        localePreference: widget.localePreference,
        onLocalePreferenceChanged: widget.onLocalePreferenceChanged,
        networkServices: _networkServices,
        uninstaller:
            widget.appUninstaller ??
            (Platform.isMacOS ? MacOsAppUninstaller() : null),
        beforeUninstall: _prepareForUninstall,
        hostPage: HostStatusPage(
          controller: _hostAgent,
          autoStart: false,
          disposeController: false,
          showAppBar: false,
          signalingEndpoint: _networkConfiguration.signalingEndpoint.toString(),
        ),
      );

  @override
  void dispose() {
    _networkServices.removeListener(_onNetworkConfigurationChanged);
    if (_ownsNetworkServices) {
      _networkServices.dispose();
    }
    _hostAgent.removeListener(_onHostChanged);
    if (_ownsHostAgent || widget.disposeHostAgentController) {
      _hostAgent.dispose();
    }
    unawaited(_tray.dispose());
    super.dispose();
  }
}

NetworkServiceConfiguration _legacyNetworkConfiguration(String endpoint) {
  final normalized = endpoint.trim();
  if (normalized.isEmpty) return NetworkServiceConfiguration.official();
  final configuration = NetworkServiceConfiguration(
    kind: NetworkServiceProfileKind.custom,
    signalingEndpoint: Uri.parse(normalized),
  );
  configuration.validate();
  return configuration;
}

String get _trayIconAsset =>
    Platform.isWindows ? _windowsTrayIcon : _macosTrayIcon;
