// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:roammand/design_system/roammand_brand_mark.dart';
import 'package:roammand/design_system/roammand_surfaces.dart';
import 'package:roammand/l10n/app_locale_controller.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand/network/network_service_configuration.dart';
import 'package:roammand/network/network_service_controller.dart';
import 'package:roammand/pairing/trusted_host_repository.dart';
import 'package:roammand/settings/app_settings_page.dart';
import 'package:roammand/settings/network/network_service_settings_page.dart';
import 'package:roammand/settings/uninstall/app_uninstaller.dart';
import 'package:window_manager/window_manager.dart';

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
const _compactPagePadding = 20.0;
const _compactSectionSpacing = 16.0;
const _compactCardPadding = 20.0;
const _compactHeroBreakpoint = 440.0;
const _compactHeroMarkSize = 64.0;
const _compactEmptyIconSize = 40.0;
const _macosSidebarWidth = 208.0;
const _macosTitleBarHeight = 48.0;
const _sidebarPadding = 16.0;
const _sidebarItemHeight = 44.0;
const _sidebarItemRadius = 12.0;
const _signalingEndpointEnvironment = 'ROAMMAND_SIGNALING_ENDPOINT';
const _signalingEndpoint = String.fromEnvironment(
  _signalingEndpointEnvironment,
);

typedef RemoteDesktopLauncher =
    Future<bool> Function(BuildContext context, RemoteDesktopTarget target);

enum _DesktopTab { thisComputer, remoteControl }

enum _DesktopDetail { settings, networkSettings }

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
    this.uninstaller,
    this.beforeUninstall,
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
  final AppUninstaller? uninstaller;
  final Future<void> Function()? beforeUninstall;

  @override
  State<DesktopHomePage> createState() => _DesktopHomePageState();
}

final class _DesktopHomePageState extends State<DesktopHomePage> {
  late final TrustedComputersController _trustedComputers;
  final Set<String> _connectingHosts = <String>{};
  _DesktopTab _selectedTab = _desktopTabOrder.first;
  _DesktopDetail? _detail;

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
    final platform = Theme.of(context).platform;
    final controlPage = _buildControlPage(
      context,
      strings,
      compact: platform == TargetPlatform.macOS,
    );
    final tabOrder = _desktopTabOrder;
    final selectedIndex = tabOrder.indexOf(_selectedTab);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _wideLayoutBreakpoint;
        if (wide && platform == TargetPlatform.macOS) {
          return _buildMacOsLayout(
            strings,
            hostPage,
            controlPage,
            tabOrder,
            selectedIndex,
          );
        }
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

  Widget _buildMacOsLayout(
    AppLocalizations strings,
    Widget hostPage,
    Widget controlPage,
    List<_DesktopTab> tabOrder,
    int selectedIndex,
  ) {
    final detail = _detail;
    return PopScope(
      canPop: detail == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _detail != null) {
          _closeDetail();
        }
      },
      child: Scaffold(
        body: Row(
          children: <Widget>[
            _MacOsDesktopSidebar(
              strings: strings,
              selectedIndex: selectedIndex,
              settingsSelected: detail != null,
              destinations: <_SidebarDestination>[
                for (final tab in tabOrder) _sidebarDestination(tab, strings),
              ],
              onDestinationSelected: _select,
              onSettingsSelected: _showSettingsPanel,
              showSettings: widget.networkServices != null,
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            Expanded(
              child: Column(
                children: <Widget>[
                  _DesktopContentHeader(
                    title: _contentTitle(strings),
                    onBack: detail == null ? null : _closeDetail,
                  ),
                  Expanded(
                    child: detail == null
                        ? IndexedStack(
                            index: selectedIndex,
                            children: <Widget>[
                              for (final tab in tabOrder)
                                _pageForTab(tab, hostPage, controlPage),
                            ],
                          )
                        : ColoredBox(
                            key: const Key('desktop-detail-panel'),
                            color: Theme.of(context).scaffoldBackgroundColor,
                            child: _detailPage(detail),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _contentTitle(AppLocalizations strings) => switch (_detail) {
    _DesktopDetail.settings => strings.settingsTitle,
    _DesktopDetail.networkSettings => strings.networkSettingsTitle,
    null => switch (_selectedTab) {
      _DesktopTab.thisComputer => strings.thisComputerTab,
      _DesktopTab.remoteControl => strings.remoteControlTab,
    },
  };

  Widget _detailPage(_DesktopDetail detail) {
    final networkServices = widget.networkServices!;
    return switch (detail) {
      _DesktopDetail.settings => AppSettingsPage(
        localePreference: widget.localePreference,
        onLocalePreferenceChanged: widget.onLocalePreferenceChanged,
        networkServices: networkServices,
        mobileContext: false,
        showAppBar: false,
        onOpenNetworkSettings: _showNetworkSettingsPanel,
        uninstaller: widget.uninstaller,
        beforeUninstall: widget.beforeUninstall,
      ),
      _DesktopDetail.networkSettings => NetworkServiceSettingsPage(
        controller: networkServices,
        warnAboutHostRestart: true,
        showAppBar: false,
        onComplete: _finishNetworkSettings,
      ),
    };
  }

  _SidebarDestination _sidebarDestination(
    _DesktopTab tab,
    AppLocalizations strings,
  ) => switch (tab) {
    _DesktopTab.thisComputer => _SidebarDestination(
      icon: Icons.computer_outlined,
      selectedIcon: Icons.computer,
      label: strings.thisComputerTab,
    ),
    _DesktopTab.remoteControl => _SidebarDestination(
      icon: Icons.desktop_windows_outlined,
      selectedIcon: Icons.desktop_windows,
      label: strings.remoteControlTab,
    ),
  };

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
    final actions = <Widget>[
      if (widget.networkServices != null)
        IconButton(
          key: const Key('desktop-settings'),
          onPressed: _openSettings,
          tooltip: strings.settingsTooltip,
          icon: const Icon(Icons.settings_outlined, size: 20),
        ),
      const SizedBox(width: 8),
    ];
    return actions.length == 1 ? null : actions;
  }

  Widget _buildControlPage(
    BuildContext context,
    AppLocalizations strings, {
    required bool compact,
  }) {
    final endpointReady = _validSignalingEndpoint(_activeSignalingEndpoint);
    final pagePadding = compact ? _compactPagePadding : _pagePadding;
    final sectionSpacing = compact ? _compactSectionSpacing : _sectionSpacing;
    final cardPadding = compact ? _compactCardPadding : 28.0;
    return RoammandBackdrop(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ListView(
            key: const Key('desktop-remote-control-list'),
            padding: EdgeInsets.all(pagePadding),
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
                          padding: EdgeInsets.all(cardPadding),
                          child: RoammandPageHero(
                            eyebrow: strings.brandPrivacyLabel,
                            title: strings.trustedComputersTitle,
                            body: strings.desktopHomeSubtitle,
                            markSize: compact ? _compactHeroMarkSize : null,
                            horizontalBreakpoint: compact
                                ? _compactHeroBreakpoint
                                : 520,
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
                      SizedBox(height: sectionSpacing),
                      ..._buildTrustedComputerState(
                        context,
                        strings,
                        compact: compact,
                      ),
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
    AppLocalizations strings, {
    required bool compact,
  }) => switch (_trustedComputers.state) {
    TrustedComputersState.loading => <Widget>[
      const Center(child: CircularProgressIndicator()),
    ],
    TrustedComputersState.error => <Widget>[
      Card(
        child: Padding(
          padding: EdgeInsets.all(compact ? _compactCardPadding : _cardPadding),
          child: Text(strings.trustedComputersLoadFailed),
        ),
      ),
    ],
    TrustedComputersState.ready when _trustedComputers.hosts.isEmpty =>
      <Widget>[
        Card(
          child: Padding(
            padding: EdgeInsets.all(compact ? _compactCardPadding : 28),
            child: Column(
              children: <Widget>[
                if (compact)
                  Icon(
                    Icons.computer_outlined,
                    size: _compactEmptyIconSize,
                    color: Theme.of(context).colorScheme.secondary,
                  )
                else
                  const RoammandBrandMark(size: 72),
                SizedBox(height: compact ? 12 : 20),
                Text(
                  strings.trustedComputersEmptyTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: compact ? 4 : 8),
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
    if (_selectedTab != selectedTab || _detail != null) {
      setState(() {
        _selectedTab = selectedTab;
        _detail = null;
      });
    }
  }

  void _showSettingsPanel() {
    if (_detail != _DesktopDetail.settings) {
      setState(() => _detail = _DesktopDetail.settings);
    }
  }

  void _showNetworkSettingsPanel() {
    if (_detail != _DesktopDetail.networkSettings) {
      setState(() => _detail = _DesktopDetail.networkSettings);
    }
  }

  void _closeDetail() {
    if (_detail == null) return;
    setState(() {
      _detail = _detail == _DesktopDetail.networkSettings
          ? _DesktopDetail.settings
          : null;
    });
  }

  void _finishNetworkSettings(NetworkServiceSettingsResult result) {
    if (!mounted) return;
    setState(() => _detail = _DesktopDetail.settings);
    if (!result.changed) return;
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

  Future<void> _openSettings() async {
    final controller = widget.networkServices;
    if (controller == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AppSettingsPage(
          localePreference: widget.localePreference,
          onLocalePreferenceChanged: widget.onLocalePreferenceChanged,
          networkServices: controller,
          mobileContext: false,
          uninstaller: widget.uninstaller,
          beforeUninstall: widget.beforeUninstall,
        ),
      ),
    );
  }
}

final class _SidebarDestination {
  const _SidebarDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

final class _MacOsDesktopSidebar extends StatelessWidget {
  const _MacOsDesktopSidebar({
    required this.strings,
    required this.selectedIndex,
    required this.settingsSelected,
    required this.destinations,
    required this.onDestinationSelected,
    required this.onSettingsSelected,
    required this.showSettings,
  });

  final AppLocalizations strings;
  final int selectedIndex;
  final bool settingsSelected;
  final List<_SidebarDestination> destinations;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onSettingsSelected;
  final bool showSettings;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      key: const Key('desktop-navigation-sidebar'),
      color: colorScheme.surface,
      child: SizedBox(
        width: _macosSidebarWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const DragToMoveArea(child: SizedBox(height: _macosTitleBarHeight)),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _sidebarPadding,
                8,
                _sidebarPadding,
                20,
              ),
              child: Row(
                key: const Key('desktop-sidebar-brand'),
                children: <Widget>[
                  const RoammandBrandMark(size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      strings.appTitle,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
            for (var index = 0; index < destinations.length; index++)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _sidebarPadding,
                  vertical: 4,
                ),
                child: _SidebarItem(
                  destination: destinations[index],
                  selected: !settingsSelected && index == selectedIndex,
                  onTap: () => onDestinationSelected(index),
                ),
              ),
            const Spacer(),
            if (showSettings)
              Padding(
                padding: const EdgeInsets.all(_sidebarPadding),
                child: _SidebarItem(
                  key: const Key('desktop-settings'),
                  destination: _SidebarDestination(
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings,
                    label: strings.settingsTitle,
                  ),
                  selected: settingsSelected,
                  onTap: onSettingsSelected,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

final class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final _SidebarDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? colorScheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(_sidebarItemRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_sidebarItemRadius),
        child: SizedBox(
          height: _sidebarItemHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: <Widget>[
                Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    destination.label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _DesktopContentHeader extends StatelessWidget {
  const _DesktopContentHeader({required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    child: SizedBox(
      height: _macosTitleBarHeight,
      child: Row(
        children: <Widget>[
          if (onBack != null)
            IconButton(
              key: const Key('desktop-detail-back'),
              onPressed: onBack,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: const Icon(Icons.arrow_back, size: 20),
            )
          else
            const SizedBox(width: 16),
          Expanded(
            child: DragToMoveArea(
              child: SizedBox.expand(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    ),
  );
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
