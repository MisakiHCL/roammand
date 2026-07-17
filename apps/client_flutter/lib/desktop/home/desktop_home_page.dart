// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:roammand/design_system/roammand_brand_mark.dart';
import 'package:roammand/design_system/roammand_surfaces.dart';
import 'package:roammand/l10n/app_language_menu.dart';
import 'package:roammand/l10n/app_locale_controller.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand/network/network_service_configuration.dart';
import 'package:roammand/network/network_service_controller.dart';
import 'package:roammand/network/network_service_settings_page.dart';
import 'package:roammand/pairing/trusted_host_repository.dart';

import '../host_agent/host_agent_client.dart';
import '../host_agent/host_status_page.dart';
import '../desktop_app_bar.dart';
import '../pairing/desktop_pairing_dialog.dart';
import '../remote/peer_session.dart';
import '../remote/host_agent_controller_session_identity.dart';
import '../remote/remote_desktop_controller.dart';
import '../remote/remote_desktop_page.dart';
import '../remote/retryable_remote_desktop_controller.dart';
import '../remote/signaling_client.dart';
import 'host_connection_descriptor.dart';
import 'trusted_computers_controller.dart';
import 'trusted_host_card.dart';

export 'host_connection_descriptor.dart' show HostConnectionDescriptorException;

const _wideLayoutBreakpoint = 720.0;
const _pagePadding = 24.0;
const _sectionSpacing = 24.0;
const _itemSpacing = 12.0;
const _cardPadding = 24.0;
const _maximumContentWidth = 760.0;
const _signalingEndpointEnvironment = 'ROAMMAND_SIGNALING_ENDPOINT';
const _signalingEndpoint = String.fromEnvironment(
  _signalingEndpointEnvironment,
);

typedef RemoteDesktopLauncher =
    Future<bool> Function(BuildContext context, RemoteDesktopTarget target);

enum _DesktopTab { thisComputer, remoteControl }

const _desktopTabOrder = <_DesktopTab>[
  _DesktopTab.thisComputer,
  _DesktopTab.remoteControl,
];

final class DesktopHomePage extends StatefulWidget {
  const DesktopHomePage({
    super.key,
    this.hostPage,
    this.launchRemote,
    this.signalingEndpoint = _signalingEndpoint,
    this.networkServices,
    this.trustedComputersController,
    this.pairingSessionFactory,
    this.nowUnixMs,
    this.localePreference = AppLocalePreference.system,
    this.onLocalePreferenceChanged,
  });

  final Widget? hostPage;
  final RemoteDesktopLauncher? launchRemote;
  final String signalingEndpoint;
  final NetworkServiceController? networkServices;
  final TrustedComputersController? trustedComputersController;
  final DesktopPairingSessionFactory? pairingSessionFactory;
  final int Function()? nowUnixMs;
  final AppLocalePreference localePreference;
  final Future<void> Function(AppLocalePreference preference)?
  onLocalePreferenceChanged;

  @override
  State<DesktopHomePage> createState() => _DesktopHomePageState();
}

final class _DesktopHomePageState extends State<DesktopHomePage> {
  late final TrustedComputersController _trustedComputers;
  final Set<String> _connectingHosts = <String>{};
  _DesktopTab _selectedTab = _desktopTabOrder.first;

  @override
  void initState() {
    super.initState();
    _trustedComputers =
        widget.trustedComputersController ??
        TrustedComputersController.applicationSupport();
    _trustedComputers.addListener(_onTrustedComputersChanged);
    unawaited(_trustedComputers.start());
  }

  @override
  void dispose() {
    _trustedComputers
      ..removeListener(_onTrustedComputersChanged)
      ..dispose();
    super.dispose();
  }

  void _onTrustedComputersChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  String get _activeSignalingEndpoint =>
      widget.networkServices?.configuration.signalingEndpoint.toString() ??
      widget.signalingEndpoint;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final hostPage =
        widget.hostPage ??
        HostStatusPage(
          showAppBar: false,
          signalingEndpoint: _activeSignalingEndpoint,
        );
    final controlPage = _buildControlPage(context, strings);
    final platform = Theme.of(context).platform;
    final tabOrder = _desktopTabOrder;
    final selectedIndex = tabOrder.indexOf(_selectedTab);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _wideLayoutBreakpoint;
        if (wide) {
          return Scaffold(
            appBar: RoammandDesktopAppBar(
              platform: platform,
              title: RoammandAppBarTitle(title: strings.appTitle),
              actions: _appBarActions(strings),
            ),
            body: Row(
              children: <Widget>[
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: _select,
                  labelType: NavigationRailLabelType.all,
                  destinations: <NavigationRailDestination>[
                    for (final tab in tabOrder) _railDestination(tab, strings),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: IndexedStack(
                    index: selectedIndex,
                    children: <Widget>[
                      for (final tab in tabOrder)
                        _pageForTab(tab, hostPage, controlPage),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return Scaffold(
          appBar: RoammandDesktopAppBar(
            platform: platform,
            title: RoammandAppBarTitle(title: strings.appTitle),
            actions: _appBarActions(strings),
          ),
          body: IndexedStack(
            index: selectedIndex,
            children: <Widget>[
              for (final tab in tabOrder)
                _pageForTab(tab, hostPage, controlPage),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: _select,
            destinations: <NavigationDestination>[
              for (final tab in tabOrder) _navigationDestination(tab, strings),
            ],
          ),
        );
      },
    );
  }

  NavigationRailDestination _railDestination(
    _DesktopTab tab,
    AppLocalizations strings,
  ) => switch (tab) {
    _DesktopTab.thisComputer => NavigationRailDestination(
      icon: const Icon(Icons.computer_outlined),
      selectedIcon: const Icon(Icons.computer),
      label: Text(strings.thisComputerTab),
    ),
    _DesktopTab.remoteControl => NavigationRailDestination(
      icon: const Icon(Icons.desktop_windows_outlined),
      selectedIcon: const Icon(Icons.desktop_windows),
      label: Text(strings.remoteControlTab),
    ),
  };

  NavigationDestination _navigationDestination(
    _DesktopTab tab,
    AppLocalizations strings,
  ) => switch (tab) {
    _DesktopTab.thisComputer => NavigationDestination(
      icon: const Icon(Icons.computer_outlined),
      selectedIcon: const Icon(Icons.computer),
      label: strings.thisComputerTab,
    ),
    _DesktopTab.remoteControl => NavigationDestination(
      icon: const Icon(Icons.desktop_windows_outlined),
      selectedIcon: const Icon(Icons.desktop_windows),
      label: strings.remoteControlTab,
    ),
  };

  Widget _pageForTab(_DesktopTab tab, Widget hostPage, Widget controlPage) =>
      switch (tab) {
        _DesktopTab.thisComputer => hostPage,
        _DesktopTab.remoteControl => controlPage,
      };

  List<Widget>? _appBarActions(AppLocalizations strings) {
    final onLocalePreferenceChanged = widget.onLocalePreferenceChanged;
    final actions = <Widget>[
      if (widget.networkServices != null)
        IconButton(
          key: const Key('desktop-network-settings'),
          onPressed: _openNetworkSettings,
          tooltip: strings.networkSettingsTooltip,
          icon: const Icon(Icons.settings_ethernet, size: 20),
        ),
      if (onLocalePreferenceChanged != null)
        AppLanguageMenu(
          key: const Key('language-menu'),
          preference: widget.localePreference,
          onPreferenceChanged: onLocalePreferenceChanged,
        ),
      const SizedBox(width: 8),
    ];
    return actions.length == 1 ? null : actions;
  }

  Widget _buildControlPage(BuildContext context, AppLocalizations strings) {
    final endpointReady = _validSignalingEndpoint(_activeSignalingEndpoint);
    return RoammandBackdrop(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ListView(
            padding: const EdgeInsets.all(_pagePadding),
            children: <Widget>[
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _maximumContentWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: RoammandPageHero(
                            eyebrow: strings.brandPrivacyLabel,
                            title: strings.trustedComputersTitle,
                            body: strings.desktopHomeSubtitle,
                            action: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                FilledButton.icon(
                                  onPressed:
                                      endpointReady &&
                                          _trustedComputers.state ==
                                              TrustedComputersState.ready
                                      ? _pairComputer
                                      : null,
                                  icon: const Icon(Icons.add_link, size: 20),
                                  label: Text(strings.pairComputerAction),
                                ),
                                if (!endpointReady) ...<Widget>[
                                  const SizedBox(height: _itemSpacing),
                                  RoammandStatusPill(
                                    label: strings.hostPairingEndpointMissing,
                                    tone: RoammandStatusTone.attention,
                                    icon: Icons.info_outline,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: _sectionSpacing),
                      ..._buildTrustedComputerState(context, strings),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTrustedComputerState(
    BuildContext context,
    AppLocalizations strings,
  ) => switch (_trustedComputers.state) {
    TrustedComputersState.loading => <Widget>[
      const Center(child: CircularProgressIndicator()),
    ],
    TrustedComputersState.error => <Widget>[
      Card(
        child: Padding(
          padding: const EdgeInsets.all(_cardPadding),
          child: Text(strings.trustedComputersLoadFailed),
        ),
      ),
    ],
    TrustedComputersState.ready when _trustedComputers.hosts.isEmpty =>
      <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: <Widget>[
                const RoammandBrandMark(size: 72),
                const SizedBox(height: 20),
                Text(
                  strings.trustedComputersEmptyTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  strings.trustedComputersEmptyBody,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    TrustedComputersState.ready => <Widget>[
      for (final host in _trustedComputers.hosts) ...<Widget>[
        TrustedHostCard(
          host: host,
          connecting: _connectingHosts.contains(_hostKey(host)),
          deleting: _trustedComputers.isDeleting(host.hostIdentity.deviceId),
          onConnect: () => _connect(host),
          onDelete: () => _confirmDelete(context, strings, host),
        ),
        const SizedBox(height: _itemSpacing),
      ],
    ],
  };

  void _select(int index) {
    final selectedTab = _desktopTabOrder[index];
    if (_selectedTab != selectedTab) {
      setState(() => _selectedTab = selectedTab);
    }
  }

  Future<void> _pairComputer() async {
    final repository = _trustedComputers.repository;
    if (repository == null) {
      return;
    }
    await showDesktopPairingDialog(
      context,
      signalingEndpoint: Uri.parse(_activeSignalingEndpoint),
      trustedHosts: repository,
      sessionFactory: widget.pairingSessionFactory,
    );
  }

  Future<void> _connect(TrustedHostRecord host) async {
    final key = _hostKey(host);
    if (!_connectingHosts.add(key)) {
      return;
    }
    setState(() {});
    try {
      final target = _trustedComputers.targetFor(host);
      final connected = widget.launchRemote == null
          ? await _launchRemote(
              context,
              target,
              widget.networkServices?.configuration ??
                  NetworkServiceConfiguration.official(),
            )
          : await widget.launchRemote!(context, target);
      if (connected) {
        await _trustedComputers.markSuccessfulConnection(
          host,
          nowUnixMs:
              widget.nowUnixMs?.call() ?? DateTime.now().millisecondsSinceEpoch,
        );
      }
    } finally {
      _connectingHosts.remove(key);
      if (mounted) setState(() {});
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppLocalizations strings,
    TrustedHostRecord host,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.deleteTrustedHostTitle(host.displayName)),
        content: Text(strings.deleteTrustedHostBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.confirmDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await _trustedComputers.deleteLocal(host.hostIdentity.deviceId);
    }
  }

  Future<void> _openNetworkSettings() async {
    final controller = widget.networkServices;
    if (controller == null) return;
    final result = await Navigator.of(context)
        .push<NetworkServiceSettingsResult>(
          MaterialPageRoute<NetworkServiceSettingsResult>(
            builder: (_) => NetworkServiceSettingsPage(
              controller: controller,
              warnAboutHostRestart: true,
            ),
          ),
        );
    if (!mounted || result == null || !result.changed) return;
    final strings = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.signalingChanged
              ? strings.networkHostMigrationSaved
              : strings.networkConfigurationSaved,
        ),
      ),
    );
  }
}

Future<bool> _launchRemote(
  BuildContext context,
  RemoteDesktopTarget target,
  NetworkServiceConfiguration networkConfiguration,
) async {
  final peerConfiguration = networkConfiguration.toPeerConfiguration();
  final controller = RetryableRemoteDesktopController(
    createController: () => RemoteDesktopController(
      identity: HostAgentControllerSessionIdentity(HostAgentClient()),
      signaling: WebSocketControllerSignalingLink(
        endpoint: target.signalingEndpoint,
      ),
      peer: ControllerPeerSession.production(configuration: peerConfiguration),
    ),
  );
  var connected = false;
  void observeConnection() {
    if (controller.state == RemoteDesktopState.connected) {
      connected = true;
    }
  }

  controller.addListener(observeConnection);
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (context) =>
          RemoteDesktopPage(target: target, controller: controller),
    ),
  );
  controller.removeListener(observeConnection);
  return connected;
}

String encodeHostConnectionDescriptor(RemoteDesktopTarget target) {
  return encodePublicHostConnectionDescriptor(
    PublicHostConnectionDescriptor(
      identity: target.hostIdentity,
      signalingEndpoint: target.signalingEndpoint,
    ),
  );
}

RemoteDesktopTarget parseHostConnectionDescriptor(String encoded) {
  try {
    final descriptor = parsePublicHostConnectionDescriptor(encoded);
    final target = RemoteDesktopTarget(
      hostIdentity: descriptor.identity,
      signalingEndpoint: descriptor.signalingEndpoint,
    );
    target.validate();
    return target;
  } on HostConnectionDescriptorException {
    rethrow;
  } catch (_) {
    throw const HostConnectionDescriptorException();
  }
}

bool _validSignalingEndpoint(String value) {
  try {
    validateSignalingEndpoint(Uri.parse(value));
    return true;
  } catch (_) {
    return false;
  }
}

String _hostKey(TrustedHostRecord host) =>
    base64UrlEncode(host.hostIdentity.deviceId);
