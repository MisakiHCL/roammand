// SPDX-License-Identifier: MPL-2.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:roammand/about/roammand_about_page.dart';
import 'package:roammand/about/roammand_links.dart';
import 'package:roammand/design_system/roammand_back_button.dart';
import 'package:roammand/design_system/roammand_colors.dart';
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
    this.linkLauncher = launchExternalLink,
    this.versionLoader = loadAppVersion,
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
  final ExternalLinkLauncher linkLauncher;
  final AppVersionLoader versionLoader;

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
    final canPop = ModalRoute.of(context)?.canPop ?? false;
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
                if (widget.mobileContext) ...<Widget>[
                  const SizedBox(height: _sectionSpacing),
                  _SettingsSection(
                    title: strings.settingsHelpSection,
                    children: <Widget>[
                      ListTile(
                        key: const Key('settings-about-roammand'),
                        leading: const Icon(Icons.info_outline_rounded),
                        title: Text(strings.aboutSettingsTitle),
                        subtitle: Text(strings.aboutSettingsBody),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _openAbout,
                      ),
                    ],
                  ),
                ],
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
          ? AppBar(
              automaticallyImplyLeading: false,
              leading: canPop
                  ? RoammandBackButton(
                      buttonKey: const Key('desktop-settings-back'),
                      onPressed: () => Navigator.of(context).maybePop(),
                    )
                  : null,
              title: Text(strings.settingsTitle),
            )
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
        _LanguageSelector(
          key: const Key('settings-language-selector'),
          value: _localePreference,
          labels: <AppLocalePreference, String>{
            AppLocalePreference.system: strings.languageSystemOption,
            AppLocalePreference.english: strings.languageEnglishOption,
            AppLocalePreference.simplifiedChinese:
                strings.languageSimplifiedChineseOption,
          },
          onSelected: widget.onLocalePreferenceChanged == null
              ? null
              : (preference) {
                  if (preference == _localePreference) return;
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

  Future<void> _openAbout() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => RoammandAboutPage(
          linkLauncher: widget.linkLauncher,
          versionLoader: widget.versionLoader,
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

final class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({
    required this.value,
    required this.labels,
    required this.onSelected,
    super.key,
  });

  final AppLocalePreference value;
  final Map<AppLocalePreference, String> labels;
  final ValueChanged<AppLocalePreference>? onSelected;

  @override
  Widget build(BuildContext context) {
    final enabled = onSelected != null;
    return PopupMenuButton<AppLocalePreference>(
      enabled: enabled,
      initialValue: value,
      onSelected: onSelected,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      elevation: 20,
      color: RoammandColors.elevatedSurface,
      surfaceTintColor: Colors.transparent,
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 360),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: RoammandColors.outline),
      ),
      itemBuilder: (context) => <PopupMenuEntry<AppLocalePreference>>[
        for (final preference in AppLocalePreference.values)
          PopupMenuItem<AppLocalePreference>(
            key: Key('settings-language-${preference.storageValue}'),
            value: preference,
            height: 48,
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 24,
                  child: preference == value
                      ? const Icon(
                          Icons.check_rounded,
                          size: 20,
                          color: RoammandColors.signalCyan,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    labels[preference]!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: RoammandColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: enabled ? 1 : 0.48,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: RoammandColors.elevatedSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: RoammandColors.outline),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.translate_rounded,
                  size: 20,
                  color: RoammandColors.auroraSoft,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    labels[value]!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: RoammandColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 24,
                  color: RoammandColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
