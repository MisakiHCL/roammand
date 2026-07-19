// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:roammand/design_system/roammand_colors.dart';
import 'package:roammand/design_system/roammand_progress_indicator.dart';
import 'package:roammand/design_system/roammand_surfaces.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';

import 'device_name_provider.dart';
import 'mobile_device_identity.dart';
import 'mobile_identity_store.dart';

const _pagePadding = 24.0;
const _sectionSpacing = 16.0;
const _maximumContentWidth = 560.0;
const _maximumLandscapeContentWidth = 960.0;
const _landscapePagePadding = 16.0;
const _landscapeColumnSpacing = 24.0;
const _landscapeCardPadding = 16.0;
const _landscapeSectionSpacing = 12.0;

final class MobileIdentityOnboarding extends StatefulWidget {
  const MobileIdentityOnboarding({
    required this.store,
    required this.nameProvider,
    required this.onReady,
    super.key,
  });

  final MobileIdentityStore store;
  final DeviceNameProvider nameProvider;
  final ValueChanged<MobileDeviceIdentity> onReady;

  @override
  State<MobileIdentityOnboarding> createState() =>
      _MobileIdentityOnboardingState();
}

final class _MobileIdentityOnboardingState
    extends State<MobileIdentityOnboarding> {
  final TextEditingController _name = TextEditingController();
  bool _started = false;
  bool _loading = true;
  bool _saving = false;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    try {
      final existing = await widget.store.load();
      if (!mounted) return;
      if (existing != null) {
        widget.onReady(existing);
        return;
      }
      final strings = AppLocalizations.of(context);
      final suggested = await widget.nameProvider.suggest(
        localizedFallback: strings.mobileDeviceFallbackName,
      );
      if (!mounted) return;
      _name.text = suggested;
      setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _retryLoad() {
    setState(() {
      _failed = false;
      _loading = true;
    });
    _load();
  }

  Future<void> _confirm() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      final identity = await widget.store.loadOrCreate(
        confirmedDisplayName: _name.text,
      );
      if (mounted) {
        setState(() => _saving = false);
        widget.onReady(identity);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (_loading && !_failed) {
      return RoammandStatusPage(
        message: strings.mobileIdentityLoading,
        progress: true,
      );
    }
    if (_failed && _loading) {
      return RoammandStatusPage(
        message: strings.mobileIdentityFailed,
        action: FilledButton.icon(
          onPressed: _retryLoad,
          icon: const Icon(Icons.refresh, size: 20),
          label: Text(strings.retryAction),
        ),
      );
    }
    return Scaffold(
      body: RoammandBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final landscape = constraints.maxWidth > constraints.maxHeight;
              return landscape
                  ? _buildLandscape(context, strings, constraints)
                  : _buildPortrait(context, strings);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPortrait(BuildContext context, AppLocalizations strings) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maximumContentWidth),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            _pagePadding,
            _pagePadding,
            _pagePadding,
            _pagePadding + MediaQuery.viewInsetsOf(context).bottom,
          ),
          children: <Widget>[
            _buildHero(strings),
            const SizedBox(height: 32),
            _buildIdentityCard(context, strings),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscape(
    BuildContext context,
    AppLocalizations strings,
    BoxConstraints viewportConstraints,
  ) {
    final bottomPadding =
        _landscapePagePadding + MediaQuery.viewInsetsOf(context).bottom;
    final totalVerticalPadding = _landscapePagePadding + bottomPadding;
    final minimumContentHeight =
        viewportConstraints.maxHeight > totalVerticalPadding
        ? viewportConstraints.maxHeight - totalVerticalPadding
        : 0.0;
    return SingleChildScrollView(
      key: const Key('mobile-identity-landscape-layout'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        _landscapePagePadding,
        _landscapePagePadding,
        _landscapePagePadding,
        bottomPadding,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minimumContentHeight),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: _maximumLandscapeContentWidth,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(child: _buildHero(strings, compact: true)),
                const SizedBox(width: _landscapeColumnSpacing),
                Expanded(
                  child: _buildIdentityCard(context, strings, compact: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(AppLocalizations strings, {bool compact = false}) {
    return RoammandPageHero(
      eyebrow: strings.brandPrivacyLabel,
      title: strings.mobileOnboardingTitle,
      body: strings.mobileOnboardingBody,
      markSize: compact ? 64 : null,
      horizontalBreakpoint: compact ? double.infinity : 520,
    );
  }

  Widget _buildIdentityCard(
    BuildContext context,
    AppLocalizations strings, {
    bool compact = false,
  }) {
    final cardPadding = compact ? _landscapeCardPadding : _pagePadding;
    final sectionSpacing = compact ? _landscapeSectionSpacing : _sectionSpacing;
    return Card(
      key: const Key('mobile-identity-card'),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _name,
              enabled: !_saving,
              maxLength: 128,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: strings.mobileDeviceNameLabel,
                prefixIcon: const Icon(Icons.phone_iphone),
                errorText: _failed ? strings.mobileIdentityFailed : null,
              ),
              onSubmitted: (_) => _confirm(),
            ),
            SizedBox(height: sectionSpacing),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.shield_outlined,
                  size: 20,
                  color: RoammandColors.online,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    strings.mobileIdentitySecurityNote,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? _sectionSpacing : _pagePadding),
            FilledButton.icon(
              onPressed: _saving ? null : _confirm,
              icon: _saving
                  ? const RoammandProgressIndicator()
                  : const Icon(Icons.arrow_forward, size: 20),
              label: Text(strings.mobileConfirmIdentityAction),
            ),
          ],
        ),
      ),
    );
  }
}
