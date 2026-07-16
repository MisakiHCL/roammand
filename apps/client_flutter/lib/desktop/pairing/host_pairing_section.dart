// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:roammand/desktop/host_agent/host_agent_controller.dart';
import 'package:roammand/desktop/remote/signaling_client.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

import 'host_pairing_dialog.dart';

const _sectionPadding = 20.0;
const _sectionSpacing = 12.0;

final class HostPairingSection extends StatelessWidget {
  const HostPairingSection({
    required this.controller,
    required this.signalingEndpoint,
    this.nowUnixMs,
    super.key,
  });

  final HostAgentController controller;
  final String signalingEndpoint;
  final int Function()? nowUnixMs;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final active = _isActive(controller.pairingStatus?.state);
    final endpointReady = _validEndpoint(signalingEndpoint);
    final canStart =
        endpointReady &&
        !active &&
        !controller.isPairingActionPending &&
        controller.state == HostAgentViewState.ready;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          strings.hostPairingSectionTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: _sectionSpacing),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(_sectionPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(strings.hostPairingSectionBody),
                if (!endpointReady) ...<Widget>[
                  const SizedBox(height: _sectionSpacing),
                  Text(
                    strings.hostPairingEndpointMissing,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: _sectionSpacing),
                Wrap(
                  spacing: _sectionSpacing,
                  runSpacing: _sectionSpacing,
                  children: <Widget>[
                    FilledButton.icon(
                      key: const ValueKey<String>('host-pairing-start-qr'),
                      onPressed: canStart ? () => _startQr(context) : null,
                      icon: const Icon(Icons.qr_code_2, size: 20),
                      label: Text(strings.hostPairingStartQrAction),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey<String>('host-pairing-start-code'),
                      onPressed: canStart ? () => _startCode(context) : null,
                      icon: const Icon(Icons.pin_outlined, size: 20),
                      label: Text(strings.hostPairingStartCodeAction),
                    ),
                    if (active)
                      TextButton.icon(
                        key: const ValueKey<String>('host-pairing-view-active'),
                        onPressed: () => showHostPairingDialog(
                          context,
                          controller,
                          nowUnixMs: nowUnixMs,
                        ),
                        icon: const Icon(Icons.open_in_new, size: 20),
                        label: Text(strings.hostPairingViewActiveAction),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _startQr(BuildContext context) async {
    await controller.startHostQrPairing(signalingEndpoint);
    if (context.mounted && _canDisplay(controller.pairingStatus?.state)) {
      await showHostPairingDialog(context, controller, nowUnixMs: nowUnixMs);
    }
  }

  Future<void> _startCode(BuildContext context) async {
    await controller.startHostDesktopCodePairing(signalingEndpoint);
    if (context.mounted && _canDisplay(controller.pairingStatus?.state)) {
      await showHostPairingDialog(context, controller, nowUnixMs: nowUnixMs);
    }
  }
}

bool _validEndpoint(String value) {
  try {
    validateSignalingEndpoint(Uri.parse(value));
    return true;
  } catch (_) {
    return false;
  }
}

bool _isActive(HostPairingState? state) => switch (state) {
  HostPairingState.HOST_PAIRING_STATE_CREATING ||
  HostPairingState.HOST_PAIRING_STATE_INVITING ||
  HostPairingState.HOST_PAIRING_STATE_VERIFYING_CONTROLLER ||
  HostPairingState.HOST_PAIRING_STATE_WAITING_LOCAL_DECISION => true,
  _ => false,
};

bool _canDisplay(HostPairingState? state) =>
    state != null &&
    state != HostPairingState.HOST_PAIRING_STATE_UNSPECIFIED &&
    state != HostPairingState.HOST_PAIRING_STATE_IDLE;
