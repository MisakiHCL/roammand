// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:roammand/design_system/roammand_surfaces.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';

import 'package:roammand/network/network_service_configuration.dart';
import 'package:roammand/network/network_service_controller.dart';

const _pagePadding = 24.0;
const _sectionSpacing = 24.0;
const _fieldSpacing = 16.0;
const _maximumContentWidth = 720.0;

final class NetworkServiceSettingsResult {
  const NetworkServiceSettingsResult({
    required this.changed,
    required this.signalingChanged,
  });

  final bool changed;
  final bool signalingChanged;
}

final class NetworkServiceSettingsPage extends StatefulWidget {
  const NetworkServiceSettingsPage({
    required this.controller,
    required this.warnAboutHostRestart,
    this.mobileContext = false,
    this.showAppBar = true,
    this.onComplete,
    super.key,
  });

  final NetworkServiceController controller;
  final bool warnAboutHostRestart;
  final bool mobileContext;
  final bool showAppBar;
  final ValueChanged<NetworkServiceSettingsResult>? onComplete;

  @override
  State<NetworkServiceSettingsPage> createState() =>
      _NetworkServiceSettingsPageState();
}

final class _NetworkServiceSettingsPageState
    extends State<NetworkServiceSettingsPage> {
  late NetworkServiceProfileKind _kind;
  late final TextEditingController _signaling;
  late final TextEditingController _stunUrls;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final configuration = widget.controller.configuration;
    final editable = configuration.kind == NetworkServiceProfileKind.custom
        ? configuration
        : NetworkServiceConfiguration.official();
    _kind = configuration.kind;
    _signaling = TextEditingController(
      text: editable.signalingEndpoint.toString(),
    );
    _stunUrls = TextEditingController(text: editable.stunUrls.join('\n'));
  }

  @override
  void dispose() {
    _signaling.dispose();
    _stunUrls.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(title: Text(strings.networkSettingsTitle))
          : null,
      body: RoammandBackdrop(
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ListView(
              padding: const EdgeInsets.all(_pagePadding),
              children: <Widget>[
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _maximumContentWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        strings.networkSettingsBody,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (widget.mobileContext) ...<Widget>[
                        const SizedBox(height: 12),
                        Text(strings.networkMobileHostBindingNotice),
                      ],
                      const SizedBox(height: _sectionSpacing),
                      Text(
                        strings.networkProfileLabel,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        key: const Key('network-profile-selector'),
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          ChoiceChip(
                            key: const Key('network-profile-official'),
                            avatar: const Icon(
                              Icons.verified_outlined,
                              size: 20,
                            ),
                            label: Text(strings.networkOfficialProfile),
                            selected:
                                _kind == NetworkServiceProfileKind.official,
                            onSelected: _saving
                                ? null
                                : (_) => setState(() {
                                    _kind = NetworkServiceProfileKind.official;
                                    _error = null;
                                  }),
                          ),
                          ChoiceChip(
                            key: const Key('network-profile-custom'),
                            avatar: const Icon(Icons.dns_outlined, size: 20),
                            label: Text(strings.networkCustomProfile),
                            selected: _kind == NetworkServiceProfileKind.custom,
                            onSelected: _saving
                                ? null
                                : (_) => setState(() {
                                    _kind = NetworkServiceProfileKind.custom;
                                    _error = null;
                                  }),
                          ),
                        ],
                      ),
                      const SizedBox(height: _fieldSpacing),
                      Text(
                        _kind == NetworkServiceProfileKind.official
                            ? strings.networkOfficialProfileBody
                            : strings.networkCustomProfileBody,
                      ),
                      const SizedBox(height: _sectionSpacing),
                      if (_kind == NetworkServiceProfileKind.official)
                        _OfficialConfigurationCard(
                          configuration: NetworkServiceConfiguration.official(),
                        )
                      else
                        _buildCustomForm(strings),
                      if (_error case final error?) ...<Widget>[
                        const SizedBox(height: _fieldSpacing),
                        Text(
                          error,
                          key: const Key('network-settings-error'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: _sectionSpacing),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.end,
                        children: <Widget>[
                          if (widget.controller.configuration.kind ==
                              NetworkServiceProfileKind.custom)
                            OutlinedButton(
                              key: const Key('network-restore-defaults'),
                              onPressed: _saving
                                  ? null
                                  : () => _commit(
                                      NetworkServiceConfiguration.official(),
                                    ),
                              child: Text(strings.networkRestoreAction),
                            ),
                          FilledButton.icon(
                            key: const Key('network-save'),
                            onPressed: _saving ? null : _save,
                            icon: _saving
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined, size: 20),
                            label: Text(
                              _saving
                                  ? strings.networkSavingAction
                                  : strings.networkSaveAction,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomForm(AppLocalizations strings) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      TextField(
        key: const Key('network-signaling-endpoint'),
        controller: _signaling,
        enabled: !_saving,
        keyboardType: TextInputType.url,
        autocorrect: false,
        decoration: InputDecoration(
          labelText: strings.networkSignalingEndpointLabel,
          hintText: strings.networkSignalingEndpointHint,
        ),
      ),
      const SizedBox(height: _fieldSpacing),
      TextField(
        key: const Key('network-stun-urls'),
        controller: _stunUrls,
        enabled: !_saving,
        keyboardType: TextInputType.url,
        autocorrect: false,
        minLines: 2,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: strings.networkStunUrlsLabel,
          hintText: strings.networkStunUrlsHint,
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: 8),
      Text(strings.networkStunOptionalNotice),
    ],
  );

  Future<void> _save() async {
    late final NetworkServiceConfiguration candidate;
    try {
      candidate = _kind == NetworkServiceProfileKind.official
          ? NetworkServiceConfiguration.official()
          : NetworkServiceConfiguration(
              kind: NetworkServiceProfileKind.custom,
              signalingEndpoint: Uri.parse(_signaling.text.trim()),
              stunUrls: _stunUrls.text
                  .split(RegExp(r'[,\n]'))
                  .map((value) => value.trim()),
            );
      candidate.validate();
    } on NetworkServiceConfigurationException catch (error) {
      setState(() => _error = _validationMessage(error));
      return;
    } catch (_) {
      setState(
        () => _error = AppLocalizations.of(context).networkInvalidSignaling,
      );
      return;
    }
    await _commit(candidate);
  }

  Future<void> _commit(NetworkServiceConfiguration candidate) async {
    final previous = widget.controller.configuration;
    if (previous == candidate) {
      if (mounted) {
        _complete(
          const NetworkServiceSettingsResult(
            changed: false,
            signalingChanged: false,
          ),
        );
      }
      return;
    }
    if (widget.warnAboutHostRestart && !await _confirmHostRestart()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (candidate.kind == NetworkServiceProfileKind.official) {
        await widget.controller.restoreOfficial();
      } else {
        await widget.controller.useCustom(candidate);
      }
      if (!mounted) return;
      _complete(
        NetworkServiceSettingsResult(
          changed: true,
          signalingChanged:
              previous.signalingEndpoint != candidate.signalingEndpoint,
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = AppLocalizations.of(context).networkSaveFailed;
        });
      }
    }
  }

  void _complete(NetworkServiceSettingsResult result) {
    final onComplete = widget.onComplete;
    if (onComplete != null) {
      onComplete(result);
      return;
    }
    Navigator.pop(context, result);
  }

  Future<bool> _confirmHostRestart() async {
    final strings = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(strings.networkChangeHostTitle),
            content: Text(strings.networkChangeHostBody),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(strings.cancelAction),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(strings.networkConfirmChangeAction),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _validationMessage(NetworkServiceConfigurationException error) {
    final strings = AppLocalizations.of(context);
    return switch (error.code) {
      NetworkServiceConfigurationError.invalidSignalingEndpoint =>
        strings.networkInvalidSignaling,
      NetworkServiceConfigurationError.invalidStunUrls =>
        strings.networkInvalidStun,
      NetworkServiceConfigurationError.invalidVersion ||
      NetworkServiceConfigurationError.invalidProfile ||
      NetworkServiceConfigurationError.invalidPeerConfiguration =>
        strings.networkInvalidConfiguration,
    };
  }
}

final class _OfficialConfigurationCard extends StatelessWidget {
  const _OfficialConfigurationCard({required this.configuration});

  final NetworkServiceConfiguration configuration;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              strings.networkSignalingEndpointLabel,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            SelectableText(configuration.signalingEndpoint.toString()),
            const SizedBox(height: 16),
            Text(
              strings.networkStunUrlsLabel,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              configuration.stunUrls.isEmpty
                  ? strings.networkStunOptionalNotice
                  : configuration.stunUrls.join('\n'),
            ),
          ],
        ),
      ),
    );
  }
}
