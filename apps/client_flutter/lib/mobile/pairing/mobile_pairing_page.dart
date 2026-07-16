// SPDX-License-Identifier: MPL-2.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roammand/design_system/roammand_surfaces.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand/mobile/identity/mobile_device_identity.dart';
import 'package:roammand/pairing/controller_pairing_engine.dart';
import 'package:roammand/pairing/controller_pairing_models.dart';
import 'package:roammand/pairing/pairing_signaling_client.dart';
import 'package:roammand/pairing/qr_pairing_uri.dart';
import 'package:roammand/pairing/trusted_host_repository.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

import 'qr_scanner.dart';

const _wordListAsset = 'assets/bip39-english.txt';
const _pagePadding = 16.0;
const _sectionSpacing = 16.0;
const _previewAspectRatio = 3 / 4;
const _fingerprintBytes = 8;

abstract interface class MobileControllerPairingSession {
  Stream<ControllerPairingSnapshot> get states;
  ControllerPairingSnapshot get snapshot;
  Future<ControllerPairingSnapshot> pairQr(HostPairingInvitation invitation);
  Future<void> cancel();
  Future<void> close();
}

typedef MobilePairingSessionFactory =
    Future<MobileControllerPairingSession> Function();

Future<MobileControllerPairingSession> createMobilePairingSession({
  required MobileDeviceIdentity identity,
  required TrustedHostRepository trustedHosts,
}) async {
  final words = (await rootBundle.loadString(
    _wordListAsset,
  )).trim().split('\n');
  return _EngineMobilePairingSession(
    ControllerPairingEngine(
      identity: identity,
      signaling: PairingSignalingClient(),
      trustedHosts: trustedHosts,
      sasWordList: words,
    ),
  );
}

final class MobilePairingPage extends StatefulWidget {
  const MobilePairingPage({
    required this.identity,
    required this.trustedHosts,
    this.scanner,
    this.sessionFactory,
    this.nowUnixMs,
    super.key,
  });

  final MobileDeviceIdentity identity;
  final TrustedHostRepository trustedHosts;
  final QrScannerSession? scanner;
  final MobilePairingSessionFactory? sessionFactory;
  final int Function()? nowUnixMs;

  @override
  State<MobilePairingPage> createState() => _MobilePairingPageState();
}

final class _MobilePairingPageState extends State<MobilePairingPage>
    with WidgetsBindingObserver {
  late final QrScannerSession _scanner;
  late final bool _ownsScanner;
  StreamSubscription<QrScannerEvent>? _scannerSubscription;
  StreamSubscription<ControllerPairingSnapshot>? _pairingSubscription;
  MobileControllerPairingSession? _session;
  ControllerPairingSnapshot _snapshot = ControllerPairingSnapshot(
    state: ControllerPairingState.idle,
  );
  QrScannerFailure? _scannerFailure;
  bool _invalidQr = false;
  bool _claimedCode = false;
  bool _creatingSession = false;
  bool _disposed = false;
  Timer? _countdown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ownsScanner = widget.scanner == null;
    _scanner = widget.scanner ?? MobileQrScannerSession();
    _scannerSubscription = _scanner.events.listen(_onScannerEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) unawaited(_scanner.start());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed || _claimedCode) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(_scanner.resume());
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      unawaited(_scanner.pause());
    }
  }

  void _onScannerEvent(QrScannerEvent event) {
    if (_disposed || _claimedCode) return;
    switch (event) {
      case QrScannerCode(:final value):
        _acceptCode(value);
      case QrScannerFailed(:final failure):
        if (mounted) setState(() => _scannerFailure = failure);
    }
  }

  Future<void> _acceptCode(String encoded) async {
    if (_claimedCode) return;
    late final HostPairingInvitation invitation;
    try {
      invitation = parseQrPairingUri(
        encoded,
        nowUnixMs:
            widget.nowUnixMs?.call() ?? DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {
      if (mounted) setState(() => _invalidQr = true);
      return;
    }
    _claimedCode = true;
    if (mounted) {
      setState(() {
        _invalidQr = false;
        _scannerFailure = null;
        _creatingSession = true;
      });
    }
    await _scanner.stop();
    if (_disposed) return;
    try {
      final session =
          await (widget.sessionFactory?.call() ??
              createMobilePairingSession(
                identity: widget.identity,
                trustedHosts: widget.trustedHosts,
              ));
      if (_disposed) {
        await session.close();
        return;
      }
      _session = session;
      _snapshot = session.snapshot;
      _pairingSubscription = session.states.listen(_onSnapshot);
      if (mounted) setState(() => _creatingSession = false);
      await session.pairQr(invitation);
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
    if (!mounted) return;
    setState(() => _snapshot = snapshot);
    _countdown?.cancel();
    if (!snapshot.isTerminal && snapshot.expiresAtUnixMs > 0) {
      _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> _cancel() async {
    await _session?.cancel();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _countdown?.cancel();
    unawaited(_scannerSubscription?.cancel());
    unawaited(_pairingSubscription?.cancel());
    unawaited(_session?.close());
    if (_ownsScanner) unawaited(_scanner.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_cancel());
      },
      child: Scaffold(
        appBar: AppBar(title: Text(strings.mobileScannerTitle)),
        body: RoammandBackdrop(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(_pagePadding),
              child: _claimedCode
                  ? _buildPairing(context, strings)
                  : _buildScanner(strings),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanner(AppLocalizations strings) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ColoredBox(
            color: Colors.black,
            child: Center(
              child: AspectRatio(
                aspectRatio: _previewAspectRatio,
                child: _scanner.buildPreview(),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: _sectionSpacing),
      Text(strings.mobileScannerInstructions, textAlign: TextAlign.center),
      if (_invalidQr || _scannerFailure != null) ...<Widget>[
        const SizedBox(height: 8),
        Text(
          _invalidQr
              ? strings.mobileInvalidQr
              : _scannerFailureText(strings, _scannerFailure!),
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ],
    ],
  );

  Widget _buildPairing(BuildContext context, AppLocalizations strings) {
    if (_creatingSession) return _progress(strings.mobilePairingJoining);
    final text = switch (_snapshot.state) {
      ControllerPairingState.idle ||
      ControllerPairingState.connecting ||
      ControllerPairingState.waitingHostInvitation =>
        strings.mobilePairingJoining,
      ControllerPairingState.verifyingHost => strings.mobilePairingVerifying,
      ControllerPairingState.waitingHostDecision =>
        strings.mobilePairingWaitingApproval,
      ControllerPairingState.accepted => strings.mobilePairingSuccess,
      ControllerPairingState.rejected => strings.mobilePairingRejected,
      ControllerPairingState.expired => strings.mobilePairingExpired,
      ControllerPairingState.cancelled => strings.mobilePairingCancelled,
      ControllerPairingState.failed => _pairingFailureText(
        strings,
        _snapshot.error,
      ),
    };
    final host = _snapshot.hostIdentity;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            _snapshot.state == ControllerPairingState.accepted
                ? Icons.check_circle_outline
                : _snapshot.isTerminal
                ? Icons.error_outline
                : Icons.verified_user_outlined,
            size: 56,
          ),
          if (host != null) ...<Widget>[
            const SizedBox(height: _sectionSpacing),
            Text(
              host.displayName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (_snapshot.hostFingerprintSha256.isNotEmpty)
              SelectableText(
                _shortFingerprint(_snapshot.hostFingerprintSha256),
              ),
          ],
          const SizedBox(height: _sectionSpacing),
          if (!_snapshot.isTerminal) const CircularProgressIndicator(),
          const SizedBox(height: _sectionSpacing),
          Text(text, textAlign: TextAlign.center),
          if (!_snapshot.isTerminal && _remainingSeconds > 0) ...<Widget>[
            const SizedBox(height: 8),
            Text(strings.pairingSecondsRemaining(_remainingSeconds)),
          ],
          if (_snapshot.isTerminal) ...<Widget>[
            const SizedBox(height: _sectionSpacing),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(MaterialLocalizations.of(context).closeButtonLabel),
            ),
          ],
        ],
      ),
    );
  }

  Widget _progress(String text) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const CircularProgressIndicator(),
        const SizedBox(height: _sectionSpacing),
        Text(text, textAlign: TextAlign.center),
      ],
    ),
  );

  int get _remainingSeconds {
    if (_snapshot.expiresAtUnixMs <= 0) return 0;
    final now =
        widget.nowUnixMs?.call() ?? DateTime.now().millisecondsSinceEpoch;
    final remaining = _snapshot.expiresAtUnixMs - now;
    return remaining <= 0 ? 0 : (remaining / 1000).ceil();
  }
}

String _pairingFailureText(
  AppLocalizations strings,
  ControllerPairingError? error,
) => switch (error) {
  ControllerPairingError.invalidInvitation => strings.mobileInvalidQr,
  ControllerPairingError.signaling => strings.mobilePairingSignalingFailed,
  ControllerPairingError.authentication =>
    strings.mobilePairingAuthenticationFailed,
  ControllerPairingError.persistence => strings.mobilePairingPersistenceFailed,
  ControllerPairingError.expired => strings.mobilePairingExpired,
  ControllerPairingError.cancelled => strings.mobilePairingCancelled,
  ControllerPairingError.internal => strings.mobilePairingInternalFailed,
  null => strings.mobilePairingFailed,
};

String _scannerFailureText(
  AppLocalizations strings,
  QrScannerFailure failure,
) => switch (failure) {
  QrScannerFailure.permissionDenied ||
  QrScannerFailure.permanentlyDenied => strings.mobileScannerPermissionDenied,
  QrScannerFailure.restricted => strings.mobileScannerRestricted,
  QrScannerFailure.noCamera => strings.mobileScannerNoCamera,
  QrScannerFailure.initialization => strings.mobileScannerInitializationFailed,
};

String _shortFingerprint(List<int> fingerprint) => fingerprint
    .take(_fingerprintBytes)
    .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
    .join(':')
    .toUpperCase();

final class _EngineMobilePairingSession
    implements MobileControllerPairingSession {
  _EngineMobilePairingSession(this._engine);
  final ControllerPairingEngine _engine;
  @override
  Stream<ControllerPairingSnapshot> get states => _engine.states;
  @override
  ControllerPairingSnapshot get snapshot => _engine.snapshot;
  @override
  Future<ControllerPairingSnapshot> pairQr(HostPairingInvitation invitation) =>
      _engine.pairQr(invitation);
  @override
  Future<void> cancel() => _engine.cancel();
  @override
  Future<void> close() => _engine.close();
}
