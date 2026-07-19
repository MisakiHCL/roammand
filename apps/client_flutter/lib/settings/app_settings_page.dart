// SPDX-License-Identifier: MPL-2.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:roammand/design_system/roammand_progress_indicator.dart';
import 'package:roammand/design_system/roammand_surfaces.dart';
import 'package:roammand/l10n/app_locale_controller.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand/network/network_service_controller.dart';
import 'package:roammand/mobile/widgets/mobile_page_header.dart';
import 'package:roammand/settings/network/network_service_settings_page.dart';
import 'package:roammand/settings/uninstall/app_uninstaller.dart';

const _pagePadding = 24.0;
const _sectionSpacing = 24.0;
const _itemSpacing = 12.0;
const _maximumContentWidth = 720.0;

final class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({
    required this.localePreference,
    required this.networkServices,
    required this.mobileContext,
    this.onLocalePreferenceChanged,
    this.showAppBar = true,
    this.onOpenNetworkSettings,
    this.uninstaller,
    this.beforeUninstall,
    super.key,
  });

  final AppLocalePreference localePreference;
  final Future<void> Function(AppLocalePreference preference)?
  onLocalePreferenceChanged;
  final NetworkServiceController networkServices;
  final bool mobileContext;
  final bool showAppBar;
  final VoidCallback? onOpenNetworkSettings;
  final AppUninstaller? uninstaller;
  final Future<void> Function()? beforeUninstall;

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

final class _AppSettingsPageState extends State<AppSettingsPage> {
  late AppLocalePreference _localePreference;
  late Future<AppUninstallAvailability>? _uninstallAvailability;
  bool _uninstalling = false;

  @override
  void initState() {
    super.initState();
    _localePreference = widget.localePreference;
    _uninstallAvailability = widget.uninstaller?.availability();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final useMobileHeader = widget.mobileContext && widget.showAppBar;
    final pageContent = Align(
      alignment: Alignment.topCenter,
      child: ListView(
        padding: const EdgeInsets.all(_pagePadding),
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maximumContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _SettingsSection(
                  title: strings.settingsGeneralSection,
                  children: <Widget>[_languageTile(strings)],
                ),
                const SizedBox(height: _sectionSpacing),
                _SettingsSection(
                  title: strings.settingsConnectionSection,
                  children: <Widget>[
                    ListTile(
                      key: const Key('settings-network-services'),
                      leading: const Icon(Icons.settings_ethernet),
                      title: Text(strings.networkSettingsTitle),
                      subtitle: Text(strings.networkSettingsBody),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openNetworkSettings,
                    ),
                  ],
                ),
                if (widget.uninstaller != null) ...<Widget>[
                  const SizedBox(height: _sectionSpacing),
                  _SettingsSection(
                    title: strings.settingsAdvancedSection,
                    children: <Widget>[_uninstallTile(strings)],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
    return Scaffold(
      appBar: widget.showAppBar && !widget.mobileContext
          ? AppBar(title: Text(strings.settingsTitle))
          : null,
      body: useMobileHeader
          ? MobilePageFrame(
              title: strings.settingsTitle,
              headerKey: const Key('mobile-settings-header'),
              backButtonKey: const Key('mobile-settings-back'),
              onBack: () => Navigator.of(context).maybePop(),
              child: pageContent,
            )
          : RoammandBackdrop(child: SafeArea(child: pageContent)),
    );
  }

  Widget _languageTile(AppLocalizations strings) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(Icons.language),
            const SizedBox(width: _itemSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    strings.settingsLanguageTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(strings.settingsLanguageBody),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<AppLocalePreference>(
          key: const Key('settings-language-selector'),
          initialValue: _localePreference,
          decoration: InputDecoration(labelText: strings.settingsLanguageTitle),
          items: <DropdownMenuItem<AppLocalePreference>>[
            DropdownMenuItem(
              value: AppLocalePreference.system,
              child: Text(strings.languageSystemOption),
            ),
            DropdownMenuItem(
              value: AppLocalePreference.english,
              child: Text(strings.languageEnglishOption),
            ),
            DropdownMenuItem(
              value: AppLocalePreference.simplifiedChinese,
              child: Text(strings.languageSimplifiedChineseOption),
            ),
          ],
          onChanged: widget.onLocalePreferenceChanged == null
              ? null
              : (preference) {
                  if (preference == null || preference == _localePreference) {
                    return;
                  }
                  setState(() => _localePreference = preference);
                  unawaited(widget.onLocalePreferenceChanged!(preference));
                },
        ),
      ],
    ),
  );

  Widget _uninstallTile(AppLocalizations strings) =>
      FutureBuilder<AppUninstallAvailability>(
        future: _uninstallAvailability,
        builder: (context, snapshot) {
          final availability = snapshot.data;
          final available = availability == AppUninstallAvailability.available;
          final subtitle = switch (availability) {
            AppUninstallAvailability.available => strings.uninstallSettingsBody,
            AppUninstallAvailability.developmentBuild =>
              strings.uninstallDevelopmentBuildBody,
            AppUninstallAvailability.unavailable =>
              strings.uninstallUnavailableBody,
            null => strings.uninstallCheckingBody,
          };
          return ListTile(
            key: const Key('settings-uninstall'),
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(strings.uninstallSettingsTitle),
            subtitle: Text(subtitle),
            trailing: _uninstalling
                ? const RoammandProgressIndicator()
                : const Icon(Icons.chevron_right),
            enabled: available && !_uninstalling,
            onTap: available && !_uninstalling ? _confirmUninstall : null,
          );
        },
      );

  Future<void> _openNetworkSettings() async {
    final openEmbedded = widget.onOpenNetworkSettings;
    if (openEmbedded != null) {
      openEmbedded();
      return;
    }
    final result = await Navigator.of(context)
        .push<NetworkServiceSettingsResult>(
          MaterialPageRoute<NetworkServiceSettingsResult>(
            builder: (_) => NetworkServiceSettingsPage(
              controller: widget.networkServices,
              warnAboutHostRestart: !widget.mobileContext,
              mobileContext: widget.mobileContext,
            ),
          ),
        );
    if (!mounted || result == null || !result.changed) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.signalingChanged
              ? AppLocalizations.of(context).networkHostMigrationSaved
              : AppLocalizations.of(context).networkConfigurationSaved,
        ),
      ),
    );
  }

  Future<void> _confirmUninstall() async {
    final strings = AppLocalizations.of(context);
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(strings.uninstallConfirmTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(strings.uninstallConfirmBody),
                const SizedBox(height: _itemSpacing),
                Text(strings.uninstallDeleteDataNotice),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(strings.cancelAction),
              ),
              FilledButton(
                key: const Key('confirm-uninstall'),
                onPressed: () => Navigator.pop(dialogContext, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text(strings.uninstallConfirmAction),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    setState(() => _uninstalling = true);
    try {
      await widget.beforeUninstall?.call();
      await widget.uninstaller!.uninstallProgram();
      if (mounted) {
        setState(() => _uninstalling = false);
      }
    } on Object {
      if (mounted) {
        setState(() => _uninstalling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).uninstallFailed)),
        );
      }
    }
  }
}

final class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: _itemSpacing),
      Card(child: Column(children: children)),
    ],
  );
}
