// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:roammand/design_system/roammand_colors.dart';
import 'package:roammand/design_system/roammand_surfaces.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';

import 'device_name_provider.dart';
import 'mobile_device_identity.dart';
import 'mobile_identity_store.dart';

const _pagePadding = 24.0;
const _sectionSpacing = 16.0;
const _maximumContentWidth = 560.0;

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
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maximumContentWidth),
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  _pagePadding,
                  _pagePadding,
                  _pagePadding,
                  _pagePadding + MediaQuery.viewInsetsOf(context).bottom,
                ),
                children: <Widget>[
                  RoammandPageHero(
                    eyebrow: strings.brandPrivacyLabel,
                    title: strings.mobileOnboardingTitle,
                    body: strings.mobileOnboardingBody,
                  ),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(_pagePadding),
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
                              errorText: _failed
                                  ? strings.mobileIdentityFailed
                                  : null,
                            ),
                            onSubmitted: (_) => _confirm(),
                          ),
                          const SizedBox(height: _sectionSpacing),
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
                          const SizedBox(height: _pagePadding),
                          FilledButton.icon(
                            onPressed: _saving ? null : _confirm,
                            icon: _saving
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.arrow_forward, size: 20),
                            label: Text(strings.mobileConfirmIdentityAction),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
