// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roammand/design_system/roammand_progress_indicator.dart';
import 'package:roammand/design_system/roammand_text_input.dart';
import 'package:roammand/desktop/host_agent/host_agent_client.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand/pairing/controller_pairing_engine.dart';
import 'package:roammand/pairing/controller_pairing_models.dart';
import 'package:roammand/pairing/desktop_pairing_code.dart';
import 'package:roammand/pairing/device_fingerprint.dart';
import 'package:roammand/pairing/pairing_signaling_client.dart';
import 'package:roammand/pairing/trusted_host_repository.dart';

import 'desktop_controller_pairing_identity.dart';

const _dialogWidth = 520.0;
const _spacing = 16.0;
const _compactSpacing = 8.0;
const _wordListAsset = 'assets/bip39-english.txt';

abstract interface class DesktopPairingSession {
  Stream<ControllerPairingSnapshot> get states;
  ControllerPairingSnapshot get snapshot;

  Future<ControllerPairingSnapshot> pairDesktopCode({
    required String pairingCode,
    required Uri signalingEndpoint,
  });

  Future<void> cancel();
  Future<void> close();
}

typedef DesktopPairingSessionFactory = Future<DesktopPairingSession> Function();

Future<void> showDesktopPairingDialog(
  BuildContext context, {
  required Uri signalingEndpoint,
  TrustedHostRepository? trustedHosts,
  DesktopPairingSessionFactory? sessionFactory,
}) {
  if (sessionFactory == null && trustedHosts == null) {
    throw ArgumentError('trustedHosts is required for production pairing');
  }
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => DesktopPairingDialog(
      signalingEndpoint: signalingEndpoint,
      sessionFactory:
          sessionFactory ??
          () => createDesktopPairingSession(trustedHosts: trustedHosts!),
    ),
  );
}

Future<DesktopPairingSession> createDesktopPairingSession({
  required TrustedHostRepository trustedHosts,
}) async {
  final hostAgent = HostAgentClient();
  ControllerPairingEngine? engine;
  try {
    await hostAgent.connect();
    final status = await hostAgent.getHostStatus();
    if (!status.hasIdentity()) {
      throw const DesktopControllerPairingIdentityException();
    }
    final identity = DesktopControllerPairingIdentity(
      identity: status.identity,
      signTranscript: hostAgent.signPairingTranscript,
    );
    final words = (await rootBundle.loadString(
      _wordListAsset,
    )).trim().split('\n');
    engine = ControllerPairingEngine(
      identity: identity,
      signaling: PairingSignalingClient(),
      trustedHosts: trustedHosts,
      sasWordList: words,
    );
    return _EngineDesktopPairingSession(engine, hostAgent);
  } catch (_) {
    await engine?.close();
    await hostAgent.close();
    rethrow;
  }
}

final class DesktopPairingDialog extends StatefulWidget {
  const DesktopPairingDialog({
    required this.signalingEndpoint,
    required this.sessionFactory,
    super.key,
  });

  final Uri signalingEndpoint;
  final DesktopPairingSessionFactory sessionFactory;

  @override
  State<DesktopPairingDialog> createState() => _DesktopPairingDialogState();
}

final class _DesktopPairingDialogState extends State<DesktopPairingDialog> {
  final TextEditingController _codeController = TextEditingController();
  DesktopPairingSession? _session;
  StreamSubscription<ControllerPairingSnapshot>? _subscription;
  ControllerPairingSnapshot _snapshot = ControllerPairingSnapshot(
    state: ControllerPairingState.idle,
  );
  Timer? _countdownTimer;
  bool _invalidCode = false;
  bool _creatingSession = false;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
    unawaited(_session?.close());
    _session = null;
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(strings.desktopPairingDialogTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _dialogWidth),
        child: SingleChildScrollView(child: _buildContent(context, strings)),
      ),
      actions: _buildActions(context, strings),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations strings) {
    if (_creatingSession) {
      return _ProgressMessage(text: strings.desktopPairingConnecting);
    }
    return switch (_snapshot.state) {
      ControllerPairingState.idle => TextField(
        key: const Key('desktop-pairing-code'),
        controller: _codeController,
        autofocus: true,
        autocorrect: false,
        enableSuggestions: false,
        cursorOpacityAnimates: RoammandTextInputPolicy.cursorOpacityAnimates,
        enableIMEPersonalizedLearning:
            RoammandTextInputPolicy.enableImePersonalizedLearning,
        textCapitalization: TextCapitalization.characters,
        inputFormatters: <TextInputFormatter>[_DesktopPairingCodeFormatter()],
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: strings.desktopPairingCodeLabel,
          hintText: strings.desktopPairingCodeHint,
          errorText: _invalidCode ? strings.invalidDesktopPairingCode : null,
        ),
        onSubmitted: (_) => _startPairing(),
      ),
      ControllerPairingState.connecting ||
      ControllerPairingState.waitingHostInvitation => _ProgressMessage(
        text: strings.desktopPairingConnecting,
      ),
      ControllerPairingState.verifyingHost => _ProgressMessage(
        text: strings.desktopPairingVerifying,
      ),
      ControllerPairingState.waitingHostDecision => _buildWaitingHost(
        context,
        strings,
      ),
      ControllerPairingState.accepted => _TerminalMessage(
        icon: Icons.check_circle_outline,
        text: strings.desktopPairingSuccess,
      ),
      ControllerPairingState.rejected => _TerminalMessage(
        icon: Icons.block_outlined,
        text: strings.desktopPairingRejected,
      ),
      ControllerPairingState.expired => _TerminalMessage(
        icon: Icons.timer_off_outlined,
        text: strings.desktopPairingExpired,
      ),
      ControllerPairingState.cancelled => _TerminalMessage(
        icon: Icons.cancel_outlined,
        text: strings.hostPairingCancelled,
      ),
      ControllerPairingState.failed => _TerminalMessage(
        icon: Icons.error_outline,
        text: strings.desktopPairingFailed,
      ),
    };
  }

  Widget _buildWaitingHost(BuildContext context, AppLocalizations strings) {
    final host = _snapshot.hostIdentity;
    if (host == null || _snapshot.sasWords.length != 4) {
      return _TerminalMessage(
        icon: Icons.error_outline,
        text: strings.desktopPairingFailed,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          host.displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        SelectableText(
          strings.hostShortFingerprint(
            formatShortDeviceFingerprint(_snapshot.hostFingerprintSha256),
          ),
        ),
        const SizedBox(height: _spacing),
        Text(
          strings.hostPairingCompareSas,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: _compactSpacing),
        Wrap(
          spacing: _compactSpacing,
          runSpacing: _compactSpacing,
          children: <Widget>[
            for (final word in _snapshot.sasWords) Chip(label: Text(word)),
          ],
        ),
        const SizedBox(height: _compactSpacing),
        Text(strings.hostPairingSasInstructions),
        const SizedBox(height: _spacing),
        _ProgressMessage(text: strings.desktopPairingWaitingApproval),
        if (_snapshot.expiresAtUnixMs > 0) ...<Widget>[
          const SizedBox(height: _compactSpacing),
          Text(
            strings.hostPairingExpiresIn(
              _formatRemaining(_snapshot.expiresAtUnixMs),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  List<Widget> _buildActions(BuildContext context, AppLocalizations strings) {
    if (_snapshot.isTerminal) {
      return <Widget>[
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.closeAction),
        ),
      ];
    }
    if (_snapshot.state == ControllerPairingState.idle && !_creatingSession) {
      return <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.cancelAction),
        ),
        FilledButton(onPressed: _startPairing, child: Text(strings.pairAction)),
      ];
    }
    return <Widget>[
      TextButton(
        onPressed: _session == null ? null : _cancel,
        child: Text(strings.hostPairingCancelAction),
      ),
    ];
  }

  Future<void> _startPairing() async {
    late final String code;
    try {
      code = normalizeDesktopPairingCode(_codeController.text);
    } catch (_) {
      setState(() => _invalidCode = true);
      return;
    }
    setState(() {
      _invalidCode = false;
      _creatingSession = true;
    });
    try {
      final session = await widget.sessionFactory();
      if (!mounted) {
        await session.close();
        return;
      }
      _session = session;
      _subscription = session.states.listen(_onSnapshot);
      _creatingSession = false;
      _onSnapshot(
        ControllerPairingSnapshot(state: ControllerPairingState.connecting),
      );
      unawaited(
        session
            .pairDesktopCode(
              pairingCode: code,
              signalingEndpoint: widget.signalingEndpoint,
            )
            .then(_onSnapshot)
            .catchError((Object _) {
              _onSnapshot(
                ControllerPairingSnapshot(
                  state: ControllerPairingState.failed,
                  error: ControllerPairingError.internal,
                ),
              );
            }),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _creatingSession = false;
          _snapshot = ControllerPairingSnapshot(
            state: ControllerPairingState.failed,
            error: ControllerPairingError.internal,
          );
        });
      }
    }
  }

  void _onSnapshot(ControllerPairingSnapshot snapshot) {
    if (!mounted) {
      return;
    }
    setState(() => _snapshot = snapshot);
    if (snapshot.expiresAtUnixMs > 0 && _countdownTimer == null) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
    if (snapshot.isTerminal) {
      _countdownTimer?.cancel();
      _countdownTimer = null;
    }
  }

  Future<void> _cancel() async {
    await _session?.cancel();
  }
}

final class _EngineDesktopPairingSession implements DesktopPairingSession {
  _EngineDesktopPairingSession(this._engine, this._hostAgent);

  final ControllerPairingEngine _engine;
  final HostAgentApi _hostAgent;

  @override
  Stream<ControllerPairingSnapshot> get states => _engine.states;

  @override
  ControllerPairingSnapshot get snapshot => _engine.snapshot;

  @override
  Future<ControllerPairingSnapshot> pairDesktopCode({
    required String pairingCode,
    required Uri signalingEndpoint,
  }) => _engine.pairDesktopCode(
    pairingCode: pairingCode,
    signalingEndpoint: signalingEndpoint,
  );

  @override
  Future<void> cancel() => _engine.cancel();

  @override
  Future<void> close() async {
    await _engine.close();
    await _hostAgent.close();
  }
}

final class _DesktopPairingCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text
        .replaceAll('-', '')
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z2-7]'), '');
    final bounded = raw.substring(0, min(raw.length, 8));
    final formatted = bounded.length > 4
        ? '${bounded.substring(0, 4)}-${bounded.substring(4)}'
        : bounded;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

final class _ProgressMessage extends StatelessWidget {
  const _ProgressMessage({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      const RoammandProgressIndicator(),
      const SizedBox(width: _compactSpacing),
      Flexible(child: Text(text)),
    ],
  );
}

final class _TerminalMessage extends StatelessWidget {
  const _TerminalMessage({required this.icon, required this.text});
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

String _formatRemaining(int expiresAtUnixMs) {
  final remainingMs = max(
    0,
    expiresAtUnixMs - DateTime.now().millisecondsSinceEpoch,
  );
  final seconds = (remainingMs / Duration.millisecondsPerSecond).ceil();
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}
