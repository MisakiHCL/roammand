// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:roammand/design_system/roammand_brand_mark.dart';
import 'package:roammand/design_system/roammand_colors.dart';
import 'package:roammand/design_system/roammand_progress_indicator.dart';
import 'package:roammand/design_system/roammand_surfaces.dart';
import 'package:roammand/desktop/remote/remote_desktop_controller.dart';
import 'package:roammand/l10n/app_locale_controller.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand/identity/device_display_name.dart';
import 'package:roammand/mobile/identity/mobile_device_identity.dart';
import 'package:roammand/mobile/pairing/mobile_pairing_page.dart';
import 'package:roammand/mobile/remote/mobile_remote_launcher.dart';
import 'package:roammand/network/network_service_controller.dart';
import 'package:roammand/pairing/trusted_host_repository.dart';
import 'package:roammand/pairing/device_identity_validator.dart';
import 'package:roammand/pairing/device_fingerprint.dart';
import 'package:roammand/settings/app_settings_page.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

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
  String? _deletingHostKey;

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

  Future<void> _rename(TrustedHostRecord host) async {
    final strings = AppLocalizations.of(context);
    final renamed = await showDialog<String>(
      context: context,
      builder: (_) => _TrustedHostRenameDialog(
        initialName: host.displayName,
        strings: strings,
      ),
    );
    if (renamed == null || renamed == host.displayName) return;
    try {
      await widget.trustedHosts.renameLocal(
        host.hostIdentity.deviceId,
        displayName: renamed,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.renameTrustedHostFailed)),
        );
      }
    }
  }

  Future<void> _confirmDelete(TrustedHostRecord host) async {
    final hostKey = _hostKey(host);
    if (_deletingHostKey != null || _connectingHostKey == hostKey) return;
    final strings = AppLocalizations.of(context);
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
            key: const Key('confirm-delete-trusted-host'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.confirmDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deletingHostKey = hostKey);
    try {
      await widget.trustedHosts.deleteLocal(host.hostIdentity.deviceId);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.deleteTrustedHostFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingHostKey = null);
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
          if (widget.networkServices != null)
            IconButton.filledTonal(
              key: const Key('mobile-settings'),
              onPressed: _openSettings,
              tooltip: strings.settingsTooltip,
              icon: const Icon(Icons.settings_outlined, size: 20),
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
            deleting: _deletingHostKey == _hostKey(host),
            enabled:
                _connectingHostKey == null &&
                _deletingHostKey == null &&
                (widget.identity != null || widget.launchRemote != null),
            onConnect: () => _connect(host),
            onRename: () => _rename(host),
            onDelete: () => _confirmDelete(host),
          ),
          const SizedBox(height: _itemSpacing),
        ],
    ],
  );

  Future<void> _openSettings() async {
    final controller = widget.networkServices;
    if (controller == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AppSettingsPage(
          localePreference: widget.localePreference,
          onLocalePreferenceChanged: widget.onLocalePreferenceChanged,
          networkServices: controller,
          mobileContext: true,
        ),
      ),
    );
  }
}

final class _TrustedHostRenameDialog extends StatefulWidget {
  const _TrustedHostRenameDialog({
    required this.initialName,
    required this.strings,
  });

  final String initialName;
  final AppLocalizations strings;

  @override
  State<_TrustedHostRenameDialog> createState() =>
      _TrustedHostRenameDialogState();
}

final class _TrustedHostRenameDialogState
    extends State<_TrustedHostRenameDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final normalized = normalizeDeviceDisplayName(_controller.text);
    if (normalized == null) {
      setState(() => _errorText = widget.strings.trustedHostNameInvalid);
      return;
    }
    Navigator.pop(context, normalized);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.strings.renameTrustedHostTitle),
    content: TextField(
      key: const Key('trusted-host-name-field'),
      controller: _controller,
      autofocus: true,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: widget.strings.trustedHostNameLabel,
        errorText: _errorText,
      ),
      onChanged: (_) {
        if (_errorText != null) {
          setState(() => _errorText = null);
        }
      },
      onSubmitted: (_) => _submit(),
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(widget.strings.cancelAction),
      ),
      FilledButton(
        key: const Key('save-trusted-host-name'),
        onPressed: _submit,
        child: Text(widget.strings.renameTrustedHostSaveAction),
      ),
    ],
  );
}

final class _MobileTrustedHostCard extends StatelessWidget {
  const _MobileTrustedHostCard({
    required this.host,
    required this.connecting,
    required this.deleting,
    required this.enabled,
    required this.onConnect,
    required this.onRename,
    required this.onDelete,
  });

  final TrustedHostRecord host;
  final bool connecting;
  final bool deleting;
  final bool enabled;
  final VoidCallback onConnect;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final lastConnected = host.lastSuccessfulConnectionAtUnixMs == 0
        ? strings.neverConnected
        : _formatDateTime(context, host.lastSuccessfulConnectionAtUnixMs);
    final identity = host.hostIdentity;
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
                        label: _platformLabel(strings, identity.platform),
                        tone: RoammandStatusTone.neutral,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  key: const Key('rename-trusted-host'),
                  onPressed: deleting ? null : onRename,
                  tooltip: strings.renameTrustedHostAction,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
                IconButton(
                  key: const Key('delete-trusted-host'),
                  onPressed: connecting || deleting ? null : onDelete,
                  tooltip: strings.deleteTrustedHostAction,
                  icon: deleting
                      ? const RoammandProgressIndicator()
                      : const Icon(Icons.delete_outline, size: 20),
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
            const SizedBox(height: 4),
            Text(
              strings.hostShortFingerprint(
                formatShortDeviceFingerprint(
                  devicePublicKeyFingerprintSha256(identity),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: enabled ? onConnect : null,
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

String _platformLabel(AppLocalizations strings, DevicePlatform platform) =>
    switch (platform) {
      DevicePlatform.DEVICE_PLATFORM_MACOS => strings.devicePlatformMacos,
      DevicePlatform.DEVICE_PLATFORM_WINDOWS => strings.devicePlatformWindows,
      _ => strings.devicePlatformUnknown,
    };

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
