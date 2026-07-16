// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:roammand/desktop/host_agent/host_agent_controller.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand/pairing/desktop_pairing_code.dart';
import 'package:roammand/pairing/qr_pairing_uri.dart';
import 'package:roammand_protocol/roammand_protocol.dart';
import 'package:qr_flutter/qr_flutter.dart';

const _dialogMaximumWidth = 560.0;
const _dialogSpacing = 16.0;
const _compactSpacing = 8.0;
const _qrSize = 240.0;
const _fingerprintBytes = 8;
const _countdownTick = Duration(seconds: 1);

Future<void> showHostPairingDialog(
  BuildContext context,
  HostAgentController controller, {
  int Function()? nowUnixMs,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) =>
      HostPairingDialog(controller: controller, nowUnixMs: nowUnixMs),
);

final class HostPairingDialog extends StatefulWidget {
  const HostPairingDialog({
    required this.controller,
    this.nowUnixMs,
    super.key,
  });

  final HostAgentController controller;
  final int Function()? nowUnixMs;

  @override
  State<HostPairingDialog> createState() => _HostPairingDialogState();
}

final class _HostPairingDialogState extends State<HostPairingDialog> {
  Timer? _countdownTimer;
  HostPairingStatusSnapshot? _lastActiveStatus;

  @override
  void initState() {
    super.initState();
    _rememberActive(widget.controller.pairingStatus);
    widget.controller.addListener(_onControllerChanged);
    _countdownTimer = Timer.periodic(_countdownTick, (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    _rememberActive(widget.controller.pairingStatus);
    if (mounted) {
      setState(() {});
    }
  }

  void _rememberActive(HostPairingStatusSnapshot? status) {
    if (status?.hasInvitation() ?? false) {
      _lastActiveStatus = status!.deepCopy();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final status = widget.controller.pairingStatus;
    final displayStatus = status?.hasInvitation() ?? false
        ? status
        : _lastActiveStatus;
    final kind = displayStatus?.invitation.kind;
    return AlertDialog(
      title: Text(
        kind == PairingInvitationKind.PAIRING_INVITATION_KIND_DESKTOP_CODE
            ? strings.hostPairingCodeTitle
            : strings.hostPairingQrTitle,
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _dialogMaximumWidth),
        child: SingleChildScrollView(
          child: _buildContent(context, strings, status, displayStatus),
        ),
      ),
      actions: _buildActions(context, strings, status, displayStatus),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations strings,
    HostPairingStatusSnapshot? status,
    HostPairingStatusSnapshot? displayStatus,
  ) {
    if (status == null) {
      return _MessageBody(
        icon: Icons.error_outline,
        text: strings.hostPairingFailed,
      );
    }
    if (_isTerminal(status.state)) {
      return _MessageBody(
        icon: _terminalIcon(status.state),
        text: _terminalText(strings, status.state),
      );
    }
    if (status.state == HostPairingState.HOST_PAIRING_STATE_CREATING) {
      return _ProgressBody(text: strings.hostPairingCreating);
    }
    if (displayStatus == null || !displayStatus.hasInvitation()) {
      return _MessageBody(
        icon: Icons.error_outline,
        text: strings.hostPairingFailed,
      );
    }

    final invitation = displayStatus.invitation;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildInvitation(strings, invitation),
        const SizedBox(height: _dialogSpacing),
        Text(
          strings.hostPairingExpiresIn(
            _formatRemaining(displayStatus.expiresAtUnixMs.toInt()),
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: _dialogSpacing),
        if (status.state ==
            HostPairingState.HOST_PAIRING_STATE_VERIFYING_CONTROLLER)
          _ProgressBody(text: strings.hostPairingVerifyingController)
        else if (status.state ==
            HostPairingState.HOST_PAIRING_STATE_WAITING_LOCAL_DECISION)
          _buildControllerDecision(context, strings, status, invitation.kind)
        else
          _ProgressBody(text: strings.hostPairingWaitingController),
      ],
    );
  }

  Widget _buildInvitation(
    AppLocalizations strings,
    HostPairingInvitation invitation,
  ) {
    if (invitation.kind ==
        PairingInvitationKind.PAIRING_INVITATION_KIND_DESKTOP_CODE) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(strings.hostPairingCodeInstructions),
          const SizedBox(height: _compactSpacing),
          SelectableText(
            formatDesktopPairingCode(invitation.pairingCode),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
            ),
          ),
        ],
      );
    }
    try {
      final data = encodeQrPairingUri(invitation);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(strings.hostPairingQrInstructions),
          const SizedBox(height: _compactSpacing),
          HostPairingQrCode(
            data: data,
            semanticsLabel: strings.hostPairingQrSemantics,
          ),
        ],
      );
    } catch (_) {
      return _MessageBody(
        icon: Icons.error_outline,
        text: strings.hostPairingFailed,
      );
    }
  }

  Widget _buildControllerDecision(
    BuildContext context,
    AppLocalizations strings,
    HostPairingStatusSnapshot status,
    PairingInvitationKind kind,
  ) {
    if (!status.hasPendingController()) {
      return _MessageBody(
        icon: Icons.error_outline,
        text: strings.hostPairingFailed,
      );
    }
    final controller = status.pendingController;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(_dialogSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              strings.hostPairingPendingControllerTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: _compactSpacing),
            Text(
              controller.displayName.isEmpty
                  ? strings.unknownControllerName
                  : controller.displayName,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(_platformName(strings, controller.platform)),
            const SizedBox(height: 4),
            SelectableText(
              strings.hostPairingControllerFingerprint(
                _shortFingerprint(status.pendingControllerFingerprintSha256),
              ),
            ),
            if (kind ==
                PairingInvitationKind
                    .PAIRING_INVITATION_KIND_DESKTOP_CODE) ...<Widget>[
              const SizedBox(height: _dialogSpacing),
              Text(
                strings.hostPairingCompareSas,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: _compactSpacing),
              Wrap(
                spacing: _compactSpacing,
                runSpacing: _compactSpacing,
                children: <Widget>[
                  for (final word in status.sasWords) Chip(label: Text(word)),
                ],
              ),
              const SizedBox(height: _compactSpacing),
              Text(strings.hostPairingSasInstructions),
            ],
            const SizedBox(height: _dialogSpacing),
            Text(strings.hostPairingOneWayGrant),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    AppLocalizations strings,
    HostPairingStatusSnapshot? status,
    HostPairingStatusSnapshot? displayStatus,
  ) {
    if (status == null ||
        _isTerminal(status.state) ||
        (status.state != HostPairingState.HOST_PAIRING_STATE_CREATING &&
            displayStatus?.hasInvitation() != true)) {
      return <Widget>[
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.closeAction),
        ),
      ];
    }
    final pending = widget.controller.isPairingActionPending;
    if (status.state ==
            HostPairingState.HOST_PAIRING_STATE_WAITING_LOCAL_DECISION &&
        status.hasPendingController() &&
        displayStatus?.hasInvitation() == true) {
      final rendezvousId = displayStatus!.invitation.rendezvousId;
      final controllerId = status.pendingController.deviceId;
      return <Widget>[
        TextButton(
          onPressed: pending
              ? null
              : () => widget.controller.rejectHostPairing(
                  rendezvousId,
                  controllerId,
                ),
          child: Text(strings.hostPairingRejectAction),
        ),
        FilledButton(
          onPressed: pending
              ? null
              : () => widget.controller.acceptHostPairing(
                  rendezvousId,
                  controllerId,
                ),
          child: Text(
            pending
                ? strings.hostPairingActionPending
                : strings.hostPairingAllowAction,
          ),
        ),
      ];
    }
    final rendezvousId = displayStatus?.hasInvitation() ?? false
        ? displayStatus!.invitation.rendezvousId
        : const <int>[];
    return <Widget>[
      TextButton(
        onPressed: pending || rendezvousId.isEmpty
            ? null
            : () => widget.controller.cancelHostPairing(rendezvousId),
        child: Text(
          pending
              ? strings.hostPairingActionPending
              : strings.hostPairingCancelAction,
        ),
      ),
    ];
  }

  String _formatRemaining(int expiresAtUnixMs) {
    final remainingMs = max(
      0,
      expiresAtUnixMs -
          (widget.nowUnixMs?.call() ?? DateTime.now().millisecondsSinceEpoch),
    );
    final seconds = (remainingMs / Duration.millisecondsPerSecond).ceil();
    final minutesPart = seconds ~/ Duration.secondsPerMinute;
    final secondsPart = seconds % Duration.secondsPerMinute;
    return '$minutesPart:${secondsPart.toString().padLeft(2, '0')}';
  }
}

final class HostPairingQrCode extends StatelessWidget {
  const HostPairingQrCode({
    required this.data,
    required this.semanticsLabel,
    super.key,
  });

  final String data;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: _qrSize,
    child: ColoredBox(
      color: Colors.white,
      child: QrImageView(
        data: data,
        size: _qrSize,
        semanticsLabel: semanticsLabel,
        padding: const EdgeInsets.all(_compactSpacing),
      ),
    ),
  );
}

final class _ProgressBody extends StatelessWidget {
  const _ProgressBody({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      const SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      const SizedBox(width: _compactSpacing),
      Flexible(child: Text(text)),
    ],
  );
}

final class _MessageBody extends StatelessWidget {
  const _MessageBody({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Icon(icon, size: 32),
      const SizedBox(width: _compactSpacing),
      Flexible(child: Text(text)),
    ],
  );
}

bool _isTerminal(HostPairingState state) => switch (state) {
  HostPairingState.HOST_PAIRING_STATE_ACCEPTED ||
  HostPairingState.HOST_PAIRING_STATE_REJECTED ||
  HostPairingState.HOST_PAIRING_STATE_EXPIRED ||
  HostPairingState.HOST_PAIRING_STATE_CANCELLED ||
  HostPairingState.HOST_PAIRING_STATE_FAILED => true,
  _ => false,
};

IconData _terminalIcon(HostPairingState state) => switch (state) {
  HostPairingState.HOST_PAIRING_STATE_ACCEPTED => Icons.check_circle_outline,
  HostPairingState.HOST_PAIRING_STATE_REJECTED => Icons.block_outlined,
  HostPairingState.HOST_PAIRING_STATE_EXPIRED => Icons.timer_off_outlined,
  HostPairingState.HOST_PAIRING_STATE_CANCELLED => Icons.cancel_outlined,
  _ => Icons.error_outline,
};

String _terminalText(
  AppLocalizations strings,
  HostPairingState state,
) => switch (state) {
  HostPairingState.HOST_PAIRING_STATE_ACCEPTED => strings.hostPairingAccepted,
  HostPairingState.HOST_PAIRING_STATE_REJECTED => strings.hostPairingRejected,
  HostPairingState.HOST_PAIRING_STATE_EXPIRED => strings.hostPairingExpired,
  HostPairingState.HOST_PAIRING_STATE_CANCELLED => strings.hostPairingCancelled,
  _ => strings.hostPairingFailed,
};

String _platformName(AppLocalizations strings, DevicePlatform platform) =>
    switch (platform) {
      DevicePlatform.DEVICE_PLATFORM_IOS => strings.devicePlatformIos,
      DevicePlatform.DEVICE_PLATFORM_ANDROID => strings.devicePlatformAndroid,
      DevicePlatform.DEVICE_PLATFORM_MACOS => strings.devicePlatformMacos,
      DevicePlatform.DEVICE_PLATFORM_WINDOWS => strings.devicePlatformWindows,
      _ => strings.devicePlatformUnknown,
    };

String _shortFingerprint(List<int> fingerprint) {
  final visible = fingerprint.take(_fingerprintBytes);
  if (visible.isEmpty) {
    return '—';
  }
  return visible
      .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join();
}
