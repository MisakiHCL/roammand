// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:roammand/about/roammand_links.dart';
import 'package:roammand/design_system/roammand_back_button.dart';
import 'package:roammand/design_system/roammand_colors.dart';
import 'package:roammand/design_system/roammand_surfaces.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand/mobile/widgets/mobile_page_header.dart';

const _pagePadding = 24.0;
const _sectionSpacing = 16.0;
const _maximumContentWidth = 720.0;

typedef AppVersionLoader = Future<String> Function();

enum RoammandAboutAudience { mobileController, desktopHost }

Future<String> loadAppVersion() async {
  final info = await PackageInfo.fromPlatform();
  return info.buildNumber.isEmpty
      ? info.version
      : '${info.version} (${info.buildNumber})';
}

final class RoammandAboutPage extends StatefulWidget {
  const RoammandAboutPage({
    this.audience = RoammandAboutAudience.mobileController,
    this.showAppBar = true,
    this.linkLauncher = launchExternalLink,
    this.versionLoader = loadAppVersion,
    super.key,
  });

  final RoammandAboutAudience audience;
  final bool showAppBar;
  final ExternalLinkLauncher linkLauncher;
  final AppVersionLoader versionLoader;

  @override
  State<RoammandAboutPage> createState() => _RoammandAboutPageState();
}

final class _RoammandAboutPageState extends State<RoammandAboutPage> {
  late Future<String> _version;

  @override
  void initState() {
    super.initState();
    _version = widget.versionLoader();
  }

  @override
  void didUpdateWidget(covariant RoammandAboutPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.versionLoader != widget.versionLoader) {
      _version = widget.versionLoader();
    }
  }

  Future<void> _open(Uri uri) async {
    var opened = false;
    try {
      opened = await widget.linkLauncher(uri);
    } on Object {
      opened = false;
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).externalLinkFailed),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final desktopHost = widget.audience == RoammandAboutAudience.desktopHost;
    final content = ListView(
      padding: const EdgeInsets.all(_pagePadding),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maximumContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                RoammandPageHero(
                  eyebrow: strings.brandPrivacyLabel,
                  title: desktopHost
                      ? strings.desktopAboutHeroTitle
                      : strings.aboutHeroTitle,
                  body: desktopHost
                      ? strings.desktopAboutHeroBody
                      : strings.aboutHeroBody,
                  markSize: 72,
                ),
                const SizedBox(height: 24),
                _AboutCard(
                  icon: Icons.route_outlined,
                  title: strings.aboutGettingStartedTitle,
                  body: desktopHost
                      ? strings.desktopAboutGettingStartedBody
                      : strings.aboutGettingStartedBody,
                  child: Column(
                    children: <Widget>[
                      _SetupStep(
                        number: 1,
                        text: desktopHost
                            ? strings.desktopSetupStepPermissions
                            : strings.mobileSetupStepInstall,
                      ),
                      _SetupStep(
                        number: 2,
                        text: desktopHost
                            ? strings.desktopSetupStepCreateQr
                            : strings.mobileSetupStepCreateQr,
                      ),
                      _SetupStep(
                        number: 3,
                        text: desktopHost
                            ? strings.desktopSetupStepScanApprove
                            : strings.mobileSetupStepScanApprove,
                        last: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: _sectionSpacing),
                _AboutCard(
                  icon: desktopHost
                      ? Icons.phone_iphone_rounded
                      : Icons.laptop_mac_outlined,
                  title: desktopHost
                      ? strings.aboutIosAppTitle
                      : strings.aboutMacAppTitle,
                  body: desktopHost
                      ? strings.aboutIosAppBody
                      : strings.aboutMacAppBody,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      FilledButton.icon(
                        key: Key(
                          desktopHost
                              ? 'about-download-ios'
                              : 'about-download-macos',
                        ),
                        onPressed: () => _open(
                          desktopHost
                              ? iosAppStorePageUri
                              : macOsDownloadPageUri,
                        ),
                        icon: const Icon(Icons.open_in_new, size: 20),
                        label: Text(
                          desktopHost
                              ? strings.aboutIosDownloadAction
                              : strings.mobileMacDownloadAction,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        desktopHost
                            ? strings.aboutIosDownloadNote
                            : strings.aboutMacDownloadNote,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: _sectionSpacing),
                _AboutCard(
                  icon: Icons.menu_book_outlined,
                  title: strings.aboutHelpTitle,
                  body: strings.aboutHelpBody,
                  child: OutlinedButton.icon(
                    key: const Key('about-open-guide'),
                    onPressed: () => _open(roammandUserGuideUri(locale)),
                    icon: const Icon(Icons.article_outlined, size: 20),
                    label: Text(strings.aboutOpenGuideAction),
                  ),
                ),
                const SizedBox(height: _sectionSpacing),
                _AboutCard(
                  icon: Icons.code_rounded,
                  title: strings.aboutOpenSourceTitle,
                  body: strings.aboutOpenSourceBody,
                  child: OutlinedButton.icon(
                    key: const Key('about-open-github'),
                    onPressed: () => _open(roammandRepositoryUri),
                    icon: const Icon(Icons.open_in_new, size: 20),
                    label: Text(strings.aboutOpenGitHubAction),
                  ),
                ),
                const SizedBox(height: _sectionSpacing),
                _AboutCard(
                  icon: Icons.shield_outlined,
                  title: strings.aboutPrivacyTitle,
                  body: desktopHost
                      ? strings.desktopAboutPrivacyBody
                      : strings.aboutPrivacyBody,
                ),
                const SizedBox(height: 24),
                FutureBuilder<String>(
                  future: _version,
                  builder: (context, snapshot) => Text(
                    strings.aboutVersionLabel(snapshot.data ?? '—'),
                    key: const Key('about-version'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: RoammandColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    if (!desktopHost) {
      return Scaffold(
        body: MobilePageFrame(
          title: strings.aboutPageTitle,
          headerKey: const Key('mobile-about-header'),
          backButtonKey: const Key('mobile-about-back'),
          onBack: () => Navigator.of(context).maybePop(),
          child: content,
        ),
      );
    }
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              automaticallyImplyLeading: false,
              leading: (ModalRoute.of(context)?.canPop ?? false)
                  ? RoammandBackButton(
                      buttonKey: const Key('desktop-about-back'),
                      onPressed: () => Navigator.of(context).maybePop(),
                    )
                  : null,
              title: Text(strings.aboutPageTitle),
            )
          : null,
      body: RoammandBackdrop(child: SafeArea(child: content)),
    );
  }
}

final class _AboutCard extends StatelessWidget {
  const _AboutCard({
    required this.icon,
    required this.title,
    required this.body,
    this.child,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, color: RoammandColors.auroraSoft),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(body),
          if (child case final content?) ...<Widget>[
            const SizedBox(height: 16),
            content,
          ],
        ],
      ),
    ),
  );
}

final class _SetupStep extends StatelessWidget {
  const _SetupStep({
    required this.number,
    required this.text,
    this.last = false,
  });

  final int number;
  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: last ? 0 : 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: RoammandColors.auroraIndigo.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$number',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: RoammandColors.auroraSoft,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
