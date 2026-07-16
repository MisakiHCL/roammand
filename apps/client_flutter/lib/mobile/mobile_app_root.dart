// SPDX-License-Identifier: MPL-2.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:roammand/design_system/roammand_surfaces.dart';
import 'package:roammand/l10n/app_locale_controller.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand/mobile/home/mobile_home_page.dart';
import 'package:roammand/mobile/identity/device_name_provider.dart';
import 'package:roammand/mobile/identity/mobile_device_identity.dart';
import 'package:roammand/mobile/identity/mobile_identity_onboarding.dart';
import 'package:roammand/mobile/identity/mobile_identity_store.dart';
import 'package:roammand/pairing/trusted_host_repository.dart';
import 'package:roammand/pairing/trusted_host_store.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

final class MobileAppRoot extends StatefulWidget {
  const MobileAppRoot({
    required this.platform,
    this.localePreference = AppLocalePreference.system,
    this.onLocalePreferenceChanged,
    super.key,
  });

  final DevicePlatform platform;
  final AppLocalePreference localePreference;
  final Future<void> Function(AppLocalePreference preference)?
  onLocalePreferenceChanged;

  @override
  State<MobileAppRoot> createState() => _MobileAppRootState();
}

final class _MobileAppRootState extends State<MobileAppRoot> {
  late final MobileIdentityStore _identityStore;
  MobileDeviceIdentity? _identity;
  TrustedHostRepository? _trustedHosts;
  bool _loadingHosts = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _identityStore = MobileIdentityStore(platform: widget.platform);
  }

  Future<void> _identityReady(MobileDeviceIdentity identity) async {
    if (_loadingHosts || _trustedHosts != null) return;
    setState(() {
      _identity = identity;
      _loadingHosts = true;
      _failed = false;
    });
    TrustedHostRepository? repository;
    try {
      final store = await TrustedHostStore.applicationSupport();
      repository = TrustedHostRepository(persistence: store);
      await repository.initialize();
      if (!mounted) {
        await repository.close();
        return;
      }
      setState(() {
        _trustedHosts = repository;
        _loadingHosts = false;
      });
    } catch (_) {
      await repository?.close();
      if (mounted) {
        setState(() {
          _loadingHosts = false;
          _failed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    unawaited(_trustedHosts?.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final identity = _identity;
    final trustedHosts = _trustedHosts;
    if (identity != null && trustedHosts != null) {
      return MobileHomePage(
        identity: identity,
        trustedHosts: trustedHosts,
        localePreference: widget.localePreference,
        onLocalePreferenceChanged: widget.onLocalePreferenceChanged,
      );
    }
    if (_failed) {
      final strings = AppLocalizations.of(context);
      return RoammandStatusPage(
        message: strings.trustedComputersLoadFailed,
        action: FilledButton.icon(
          onPressed: identity == null ? null : () => _identityReady(identity),
          icon: const Icon(Icons.refresh, size: 20),
          label: Text(strings.retryAction),
        ),
      );
    }
    if (_loadingHosts) {
      return RoammandStatusPage(
        message: AppLocalizations.of(context).mobileIdentityLoading,
        progress: true,
      );
    }
    return MobileIdentityOnboarding(
      store: _identityStore,
      nameProvider: DeviceNameProvider(),
      onReady: _identityReady,
    );
  }
}
