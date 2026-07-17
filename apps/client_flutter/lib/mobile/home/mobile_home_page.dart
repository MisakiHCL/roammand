// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:roammand/design_system/roammand_brand_mark.dart';
import 'package:roammand/design_system/roammand_colors.dart';
import 'package:roammand/design_system/roammand_surfaces.dart';
import 'package:roammand/desktop/remote/remote_desktop_controller.dart';
import 'package:roammand/l10n/app_language_menu.dart';
import 'package:roammand/l10n/app_locale_controller.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand/mobile/identity/mobile_device_identity.dart';
import 'package:roammand/mobile/pairing/mobile_pairing_page.dart';
import 'package:roammand/mobile/remote/mobile_remote_launcher.dart';
import 'package:roammand/network/network_service_controller.dart';
import 'package:roammand/network/network_service_settings_page.dart';
import 'package:roammand/pairing/trusted_host_repository.dart';

const _pagePadding = 24.0;
const _itemSpacing = 12.0;
const _landscapeSectionSpacing = 32.0;
const _maximumContentWidth = 1120.0;
const _landscapeLayoutBreakpoint = 680.0;
const _homeHeadlineFontSize = 24.0;
const _homeTitleFontSize = 16.0;
const _homeBodyFontSize = 12.0;

typedef MobilePairingPageBuilder = Widget Function(BuildContext context);

final class MobileHomePage extends StatefulWidget {
  const MobileHomePage({
    required this.trustedHosts,
    this.networkServices,
    this.identity,
    this.pairingPageBuilder,
    this.launchRemote,
    this.nowUnixMs,
    this.localePreference = AppLocalePreference.system,
    this.onLocalePreferenceChanged,
    super.key,
  });

  final TrustedHostRepository trustedHosts;
  final NetworkServiceController? networkServices;
  final MobileDeviceIdentity? identity;
  final MobilePairingPageBuilder? pairingPageBuilder;
  final MobileRemoteLauncher? launchRemote;
  final int Function()? nowUnixMs;
  final AppLocalePreference localePreference;
  final Future<void> Function(AppLocalePreference preference)?
  onLocalePreferenceChanged;

  @override
  State<MobileHomePage> createState() => _MobileHomePageState();
}

final class _MobileHomePageState extends State<MobileHomePage> {
  StreamSubscription<List<TrustedHostRecord>>? _subscription;
  late List<TrustedHostRecord> _hosts;
  String? _connectingHostKey;

  @override
  void initState() {
    super.initState();
    _hosts = widget.trustedHosts.hosts;
    _subscription = widget.trustedHosts.changes.listen((hosts) {
      if (mounted) setState(() => _hosts = hosts);
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  Future<void> _scan() async {
    final page =
        widget.pairingPageBuilder?.call(context) ??
        MobilePairingPage(
          identity: widget.identity!,
          trustedHosts: widget.trustedHosts,
          networkServices: widget.networkServices,
        );
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _connect(TrustedHostRecord host) async {
    if (_connectingHostKey != null) return;
    final identity = widget.identity;
    final launcher =
        widget.launchRemote ??
        (identity == null
            ? null
            : (BuildContext context, RemoteDesktopTarget target) =>
                  launchMobileRemoteDesktop(
                    context,
                    identity: identity,
                    target: target,
                    networkConfiguration: widget.networkServices?.configuration,
                  ));
    if (launcher == null) return;
    final hostKey = _hostKey(host);
    setState(() => _connectingHostKey = hostKey);
    try {
      final connected = await launcher(
        context,
        RemoteDesktopTarget(
          hostIdentity: host.hostIdentity,
          signalingEndpoint: host.signalingEndpoint,
        ),
      );
      if (connected) {
        await widget.trustedHosts.markSuccessfulConnection(
          host.hostIdentity.deviceId,
          nowUnixMs:
              widget.nowUnixMs?.call() ?? DateTime.now().millisecondsSinceEpoch,
        );
      }
    } catch (_) {
      if (mounted) {
        final strings = AppLocalizations.of(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.remoteConnectionFailed)));
      }
    } finally {
      if (mounted) setState(() => _connectingHostKey = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Theme(
      data: _compactHomeTheme(Theme.of(context)),
      child: Scaffold(
        body: RoammandBackdrop(
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: _maximumContentWidth,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) => ListView(
                    padding: const EdgeInsets.fromLTRB(
                      _pagePadding,
                      _pagePadding,
                      _pagePadding,
                      40,
                    ),
                    children: <Widget>[
                      if (constraints.maxWidth >= _landscapeLayoutBreakpoint)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(flex: 3, child: _buildHero(strings)),
                            const SizedBox(width: _landscapeSectionSpacing),
                            Expanded(flex: 4, child: _buildHosts(strings)),
                          ],
                        )
                      else ...<Widget>[
                        _buildHero(strings),
                        const SizedBox(height: 24),
                        _buildHosts(strings),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(AppLocalizations strings) => RoammandPageHero(
    eyebrow: strings.brandPrivacyLabel,
    title: strings.mobileHomeTitle,
    body: strings.mobileHomeSubtitle,
    markSize: 72,
    action: Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          FilledButton.icon(
            onPressed:
                widget.identity != null || widget.pairingPageBuilder != null
                ? _scan
                : null,
            icon: const Icon(Icons.qr_code_scanner, size: 20),
            label: Text(strings.mobileScanQrAction),
          ),
          if (widget.onLocalePreferenceChanged case final onChanged?)
            AppLanguageMenu(
              key: const Key('mobile-language-menu'),
              preference: widget.localePreference,
              onPreferenceChanged: onChanged,
            ),
          if (widget.networkServices != null)
            IconButton.filledTonal(
              key: const Key('mobile-network-settings'),
              onPressed: _openNetworkSettings,
              tooltip: strings.networkSettingsTooltip,
              icon: const Icon(Icons.settings_ethernet, size: 20),
            ),
        ],
      ),
    ),
  );

  Widget _buildHosts(AppLocalizations strings) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      if (_hosts.isEmpty)
        _EmptyState(strings: strings)
      else
        for (final host in _hosts) ...<Widget>[
          _MobileTrustedHostCard(
            host: host,
            connecting: _connectingHostKey == _hostKey(host),
            enabled:
                _connectingHostKey == null &&
                (widget.identity != null || widget.launchRemote != null),
            onConnect: () => _connect(host),
          ),
          const SizedBox(height: _itemSpacing),
        ],
    ],
  );

  Future<void> _openNetworkSettings() async {
    final controller = widget.networkServices;
    if (controller == null) return;
    final result = await Navigator.of(context)
        .push<NetworkServiceSettingsResult>(
          MaterialPageRoute<NetworkServiceSettingsResult>(
            builder: (_) => NetworkServiceSettingsPage(
              controller: controller,
              warnAboutHostRestart: false,
              mobileContext: true,
            ),
          ),
        );
    if (!mounted || result == null || !result.changed) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).networkConfigurationSaved),
      ),
    );
  }
}

final class _MobileTrustedHostCard extends StatelessWidget {
  const _MobileTrustedHostCard({
    required this.host,
    required this.connecting,
    required this.enabled,
    required this.onConnect,
  });

  final TrustedHostRecord host;
  final bool connecting;
  final bool enabled;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final lastConnected = host.lastSuccessfulConnectionAtUnixMs == 0
        ? strings.neverConnected
        : _formatDateTime(context, host.lastSuccessfulConnectionAtUnixMs);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: RoammandColors.auroraIndigo.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.computer_outlined,
                    size: 20,
                    color: RoammandColors.auroraSoft,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        host.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      RoammandStatusPill(
                        label: strings.computerReadyLabel,
                        tone: RoammandStatusTone.online,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              strings.mobileControlLaterNotice,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(strings.trustedHostLastConnectedLabel(lastConnected)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: enabled ? onConnect : null,
              icon: connecting
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
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
      ),
    );
  }
}

final class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.strings});
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: <Widget>[
          const RoammandBrandMark(size: 64),
          const SizedBox(height: 16),
          Text(
            strings.mobileHomeEmptyTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(strings.mobileHomeEmptyBody, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

String _hostKey(TrustedHostRecord host) =>
    base64UrlEncode(host.hostIdentity.deviceId);

String _formatDateTime(BuildContext context, int unixMs) {
  final value = DateTime.fromMillisecondsSinceEpoch(unixMs).toLocal();
  final localizations = MaterialLocalizations.of(context);
  return '${localizations.formatFullDate(value)} ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(value))}';
}

ThemeData _compactHomeTheme(ThemeData theme) {
  final text = theme.textTheme;
  return theme.copyWith(
    visualDensity: VisualDensity.compact,
    textTheme: text.copyWith(
      headlineMedium: text.headlineMedium?.copyWith(
        fontSize: _homeHeadlineFontSize,
      ),
      titleLarge: text.titleLarge?.copyWith(fontSize: _homeTitleFontSize),
      titleMedium: text.titleMedium?.copyWith(fontSize: _homeTitleFontSize),
      bodyLarge: text.bodyLarge?.copyWith(fontSize: _homeBodyFontSize),
      bodyMedium: text.bodyMedium?.copyWith(fontSize: _homeBodyFontSize),
      labelLarge: text.labelLarge?.copyWith(fontSize: _homeBodyFontSize),
      labelMedium: text.labelMedium?.copyWith(fontSize: _homeBodyFontSize),
    ),
  );
}
