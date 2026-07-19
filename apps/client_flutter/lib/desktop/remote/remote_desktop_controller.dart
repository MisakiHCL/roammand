// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:math';

import 'package:crypto/crypto.dart' as hashes;
import 'package:cryptography/cryptography.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:roammand/controller/session/controller_session_identity.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

import '../../diagnostics/diagnostics_collector.dart';
import '../../diagnostics/diagnostics_model.dart';
import 'controller_signaling_link.dart';
import 'input_sender.dart';
import 'peer_session.dart';
import 'reconnect_policy.dart';
import 'session_authenticator.dart';
import 'signaling_client.dart';

export 'controller_signaling_link.dart';
export '../../diagnostics/diagnostics_model.dart' show DiagnosticsReport;

const _sessionIdBytes = 16;
const _nonceBytes = 32;
const _authenticationLifetime = Duration(seconds: 30);
const _maximumPendingLocalCandidates = 64;
const _diagnosticsStatsInterval = Duration(seconds: 5);
const _appVersion = String.fromEnvironment(
  'ROAMMAND_APP_VERSION',
  defaultValue: '0.0.1',
);

enum RemoteDesktopState {
  idle,
  connecting,
  authenticating,
  negotiating,
  connected,
  reconnecting,
  closing,
  failed,
}

enum RemoteDesktopErrorCode {
  configuration,
  localIdentity,
  signaling,
  authentication,
  peer,
  remote,
}

final class RemoteReconnectProgress {
  const RemoteReconnectProgress({
    required this.attempt,
    required this.maximumAttempts,
    required this.elapsed,
    required this.recoveryWindow,
  });

  final int attempt;
  final int maximumAttempts;
  final Duration elapsed;
  final Duration recoveryWindow;

  Duration get remaining => recoveryWindow - elapsed;
}

abstract interface class RemoteDesktopViewModel implements Listenable {
  RemoteDesktopState get state;

  RemoteDesktopErrorCode? get errorCode;

  RemoteReconnectProgress? get reconnectProgress;

  DiagnosticsReport get diagnosticsReport;

  bool get canRetry;

  Object get videoRenderer;

  RemoteInputSender? get inputSender;

  Future<void> connect(RemoteDesktopTarget target);

  Future<void> retry();

  Future<void> close();

  void dispose();
}

final class RemoteDesktopTarget {
  RemoteDesktopTarget({
    required DeviceIdentity hostIdentity,
    required this.signalingEndpoint,
  }) : hostIdentity = hostIdentity.deepCopy();

  final DeviceIdentity hostIdentity;
  final Uri signalingEndpoint;

  void validate() {
    try {
      validateDeviceIdentity(hostIdentity);
      validateSignalingEndpoint(signalingEndpoint);
    } catch (_) {
      throw const RemoteDesktopException(RemoteDesktopErrorCode.configuration);
    }
  }
}

final class RemoteDesktopException implements Exception {
  const RemoteDesktopException(this.code);

  final RemoteDesktopErrorCode code;

  @override
  String toString() => 'RemoteDesktopException(${code.name})';
}

final class RemoteDesktopController extends ChangeNotifier
    implements RemoteDesktopViewModel {
  factory RemoteDesktopController({
    required ControllerSessionIdentity identity,
    required ControllerSignalingLink signaling,
    required ControllerPeerSession peer,
    Uint8List Function(int length)? randomBytes,
    int Function()? nowUnixMs,
    ReconnectScheduler? reconnectScheduler,
    DiagnosticsCollector? diagnostics,
  }) => RemoteDesktopController._(
    identity,
    signaling,
    peer,
    randomBytes ?? _secureRandomBytes,
    nowUnixMs ?? _systemNowUnixMs,
    reconnectScheduler ?? const TimerReconnectScheduler(),
    diagnostics,
  );

  RemoteDesktopController._(
    this._identity,
    this._signaling,
    this._peer,
    this._randomBytes,
    this._nowUnixMs,
    this._reconnectScheduler,
    DiagnosticsCollector? diagnostics,
  ) : _diagnostics =
          diagnostics ??
          DiagnosticsCollector(
            metadata: DiagnosticsMetadata(
              appVersion: _appVersion,
              protocolMajor: protocolMajorVersion,
              protocolMinor: minimumProtocolMinorVersion,
              osFamily: _currentOsFamily(),
            ),
            nowUnixMs: _nowUnixMs,
          );

  final ControllerSessionIdentity _identity;
  final ControllerSignalingLink _signaling;
  final ControllerPeerSession _peer;
  final Uint8List Function(int length) _randomBytes;
  final int Function() _nowUnixMs;
  final ReconnectScheduler _reconnectScheduler;
  final DiagnosticsCollector _diagnostics;
  final List<IceCandidate> _pendingLocalCandidates = <IceCandidate>[];

  RemoteDesktopState _state = RemoteDesktopState.idle;
  RemoteDesktopErrorCode? _errorCode;
  RemoteReconnectProgress? _reconnectProgress;
  RemoteDesktopTarget? _target;
  DeviceIdentity? _controllerIdentity;
  Uint8List? _sessionId;
  SessionOfferAuthentication? _offer;
  SessionAnswerAuthentication? _answer;
  SessionReconnectAuthentication? _reconnect;
  WebRtcSessionDescription? _answerDescription;
  RemoteInputSender? _inputSender;
  StreamSubscription<SignalingRoutedSession>? _signalingSubscription;
  StreamSubscription<ControllerPeerEvent>? _peerSubscription;
  StreamSubscription<IceCandidate>? _candidateSubscription;
  Future<void>? _closeFuture;
  ReconnectAttemptSequence? _reconnectSequence;
  ReconnectTimer? _reconnectTimer;
  Timer? _diagnosticsTimer;
  bool _offerSent = false;
  bool _signalingRecoveryRequired = false;
  bool _resourcesClosed = false;
  bool _disposed = false;
  bool _statsCollectionInFlight = false;
  int _requestSequence = 0;
  int _reconnectGeneration = 0;
  RemoteDesktopErrorCode _reconnectFailureCode = RemoteDesktopErrorCode.peer;

  @override
  RemoteDesktopState get state => _state;
  @override
  RemoteDesktopErrorCode? get errorCode => _errorCode;
  @override
  RemoteReconnectProgress? get reconnectProgress => _reconnectProgress;
  @override
  bool get canRetry => false;
  @override
  DiagnosticsReport get diagnosticsReport => _diagnostics.snapshot();
  @override
  Object get videoRenderer => _peer.videoRenderer;
  @override
  RemoteInputSender? get inputSender => _inputSender;

  @override
  Future<void> retry() async {
    throw const RemoteDesktopException(RemoteDesktopErrorCode.configuration);
  }

  @override
  Future<void> connect(RemoteDesktopTarget target) async {
    if (_state != RemoteDesktopState.idle || _closeFuture != null) {
      throw const RemoteDesktopException(RemoteDesktopErrorCode.configuration);
    }
    target.validate();
    _target = target;
    _setState(RemoteDesktopState.connecting);
    var operation = _RemoteDebugOperation.openIdentity;
    try {
      final controllerIdentity = await _identity.open();
      validateDeviceIdentity(controllerIdentity);
      _controllerIdentity = controllerIdentity.deepCopy();
      _sessionId = _checkedRandom(_sessionIdBytes);
      _signalingSubscription = _signaling.routedSessions.listen(
        (event) => unawaited(_handleRouted(event)),
        onError: (Object error) {
          _debugRemoteFailure(_RemoteDebugOperation.signalingStream, error);
          unawaited(_handleRecoverableFailure(signaling: true));
        },
        onDone: () {
          _debugRemoteReason(_RemoteDebugOperation.signalingStream, 'closed');
          unawaited(_handleRecoverableFailure(signaling: true));
        },
      );
      _peerSubscription = _peer.events.listen(
        _handlePeerEvent,
        onError: (Object error) {
          _debugRemoteFailure(_RemoteDebugOperation.peerStream, error);
          unawaited(_handleRecoverableFailure());
        },
      );
      _candidateSubscription = _peer.localCandidates.listen(
        (candidate) => unawaited(_handleLocalCandidate(candidate)),
        onError: (Object error) {
          _debugRemoteFailure(_RemoteDebugOperation.candidateStream, error);
          unawaited(_handleRecoverableFailure());
        },
      );
      operation = _RemoteDebugOperation.connectSignaling;
      await _signaling.connect(controllerIdentity.deviceId);
      operation = _RemoteDebugOperation.createPeerOffer;
      final peerOffer = await _peer.start();
      _setState(RemoteDesktopState.authenticating);
      operation = _RemoteDebugOperation.sendAuthenticatedOffer;
      await _sendAuthenticatedOffer(peerOffer);
      _setState(RemoteDesktopState.negotiating);
    } on RemoteDesktopException catch (error) {
      _debugRemoteFailure(operation, error);
      await _fail(error.code);
    } on ControllerSessionIdentityException catch (error) {
      _debugRemoteFailure(operation, error);
      await _fail(RemoteDesktopErrorCode.localIdentity);
    } on SignalingClientException catch (error) {
      _debugRemoteFailure(operation, error);
      await _fail(RemoteDesktopErrorCode.signaling);
    } on SessionAnswerAuthenticationException catch (error) {
      _debugRemoteFailure(operation, error);
      await _fail(RemoteDesktopErrorCode.authentication);
    } on PeerSessionException catch (error) {
      _debugRemoteFailure(operation, error);
      await _fail(RemoteDesktopErrorCode.peer);
    } catch (error) {
      _debugRemoteFailure(operation, error);
      await _fail(RemoteDesktopErrorCode.peer);
    }
  }

  Future<void> _sendAuthenticatedOffer(ControllerPeerOffer peerOffer) async {
    final controllerIdentity = _controllerIdentity!;
    final target = _target!;
    final offer = _createOffer(controllerIdentity, target, peerOffer);
    final transcript = encodeSessionOfferTranscript(offer);
    final signature = await _identity.signOffer(transcript);
    await _validateLocalSignature(signature, controllerIdentity, transcript);
    offer.signature = signature;
    _offer = offer;
    _answer = null;
    _reconnect = null;
    _answerDescription = null;
    await _relay(sessionAuthentication: SessionAuthentication(offer: offer));
    await _relay(
      webRtcNegotiation: WebRtcNegotiation(
        sessionId: offer.sessionId,
        description: WebRtcSessionDescription(
          type: SessionDescriptionType.SESSION_DESCRIPTION_TYPE_OFFER,
          sdp: peerOffer.sdp,
          dtlsFingerprintSha256: peerOffer.dtlsFingerprintSha256,
        ),
      ),
    );
    _offerSent = true;
    for (final candidate in List<IceCandidate>.of(_pendingLocalCandidates)) {
      await _relayCandidate(candidate);
    }
    _pendingLocalCandidates.clear();
  }

  SessionOfferAuthentication _createOffer(
    DeviceIdentity controller,
    RemoteDesktopTarget target,
    ControllerPeerOffer peerOffer,
  ) {
    final now = _nowUnixMs();
    return SessionOfferAuthentication(
      controllerDeviceId: controller.deviceId,
      hostDeviceId: target.hostIdentity.deviceId,
      sessionId: _sessionId,
      nonce: _checkedRandom(_nonceBytes),
      issuedAtUnixMs: Int64(now),
      expiresAtUnixMs: Int64(now + _authenticationLifetime.inMilliseconds),
      requestedPermissions: const <SessionPermission>[
        SessionPermission.SESSION_PERMISSION_VIEW_SCREEN,
        SessionPermission.SESSION_PERMISSION_CONTROL_INPUT,
      ],
      offerSha256: hashes.sha256.convert(peerOffer.sdp.codeUnits).bytes,
      controllerDtlsFingerprintSha256: peerOffer.dtlsFingerprintSha256,
    );
  }

  Future<void> _handleRouted(SignalingRoutedSession routed) async {
    if (_state == RemoteDesktopState.closing ||
        _state == RemoteDesktopState.failed ||
        _state == RemoteDesktopState.idle) {
      return;
    }
    var operation = _RemoteDebugOperation.decodeRoutedEnvelope;
    try {
      final target = _target!;
      final controller = _controllerIdentity!;
      final sessionId = _sessionId!;
      final envelope = decodeAndValidateSignalingEnvelope(
        routed.opaqueEnvelope,
      );
      if (!_bytesEqual(routed.senderDeviceId, target.hostIdentity.deviceId) ||
          !_bytesEqual(envelope.senderDeviceId, target.hostIdentity.deviceId) ||
          !_bytesEqual(envelope.recipientDeviceId, controller.deviceId)) {
        throw const RemoteDesktopException(
          RemoteDesktopErrorCode.authentication,
        );
      }
      switch (envelope.whichPayload()) {
        case SignalingEnvelope_Payload.sessionAuthentication:
          final authentication = envelope.sessionAuthentication;
          switch (authentication.whichPayload()) {
            case SessionAuthentication_Payload.answer:
              if (!_bytesEqual(authentication.answer.sessionId, sessionId)) {
                throw const RemoteDesktopException(
                  RemoteDesktopErrorCode.authentication,
                );
              }
              _answer = authentication.answer.deepCopy();
            case SessionAuthentication_Payload.reconnect:
              if (_reconnectSequence == null ||
                  !_bytesEqual(authentication.reconnect.sessionId, sessionId)) {
                throw const RemoteDesktopException(
                  RemoteDesktopErrorCode.authentication,
                );
              }
              _reconnect = authentication.reconnect.deepCopy();
            case SessionAuthentication_Payload.offer:
            case SessionAuthentication_Payload.notSet:
              throw const RemoteDesktopException(
                RemoteDesktopErrorCode.authentication,
              );
          }
          operation = _RemoteDebugOperation.applyRemoteAnswer;
          await _tryApplyAnswer();
        case SignalingEnvelope_Payload.webrtcNegotiation:
          final negotiation = envelope.webrtcNegotiation;
          if (!_bytesEqual(negotiation.sessionId, sessionId)) {
            throw const RemoteDesktopException(
              RemoteDesktopErrorCode.authentication,
            );
          }
          switch (negotiation.whichPayload()) {
            case WebRtcNegotiation_Payload.description:
              if (negotiation.description.type !=
                  SessionDescriptionType.SESSION_DESCRIPTION_TYPE_ANSWER) {
                throw const RemoteDesktopException(
                  RemoteDesktopErrorCode.authentication,
                );
              }
              _answerDescription = negotiation.description.deepCopy();
              operation = _RemoteDebugOperation.applyRemoteAnswer;
              await _tryApplyAnswer();
            case WebRtcNegotiation_Payload.iceCandidate:
              operation = _RemoteDebugOperation.addRemoteCandidate;
              await _peer.addRemoteCandidate(negotiation.iceCandidate);
            case WebRtcNegotiation_Payload.endOfCandidates:
            case WebRtcNegotiation_Payload.notSet:
              break;
          }
        case SignalingEnvelope_Payload.error:
          _debugRemoteReason(
            _RemoteDebugOperation.remoteError,
            envelope.error.code.name,
          );
          if (_reconnectSequence != null && envelope.error.retryable) {
            await _handleRecoverableFailure(signaling: true);
            return;
          }
          throw const RemoteDesktopException(RemoteDesktopErrorCode.remote);
        case SignalingEnvelope_Payload.sessionStatus:
          if (envelope.sessionStatus.state ==
                  SessionState.SESSION_STATE_FAILED ||
              envelope.sessionStatus.state ==
                  SessionState.SESSION_STATE_CLOSING) {
            throw const RemoteDesktopException(RemoteDesktopErrorCode.remote);
          }
        case SignalingEnvelope_Payload.capabilityNegotiation:
        case SignalingEnvelope_Payload.pairing:
        case SignalingEnvelope_Payload.notSet:
          throw const RemoteDesktopException(RemoteDesktopErrorCode.signaling);
      }
    } on RemoteDesktopException catch (error) {
      _debugRemoteFailure(operation, error);
      await _fail(error.code);
    } on SessionAnswerAuthenticationException catch (error) {
      _debugRemoteFailure(operation, error);
      await _fail(RemoteDesktopErrorCode.authentication);
    } on SessionReconnectAuthenticationException catch (error) {
      _debugRemoteFailure(operation, error);
      await _fail(RemoteDesktopErrorCode.authentication);
    } on ProtocolValidationException catch (error) {
      _debugRemoteFailure(operation, error);
      await _fail(RemoteDesktopErrorCode.signaling);
    } on PeerSessionException catch (error) {
      _debugRemoteFailure(operation, error);
      await _fail(RemoteDesktopErrorCode.peer);
    } catch (error) {
      _debugRemoteFailure(operation, error);
      await _fail(RemoteDesktopErrorCode.peer);
    }
  }

  Future<void> _tryApplyAnswer() async {
    final answer = _answer;
    final reconnect = _reconnect;
    final description = _answerDescription;
    final offer = _offer;
    final target = _target;
    if ((answer == null && reconnect == null) ||
        description == null ||
        offer == null ||
        target == null) {
      return;
    }
    final fingerprint = extractSha256DtlsFingerprint(description.sdp);
    if (!_bytesEqual(fingerprint, description.dtlsFingerprintSha256)) {
      throw const RemoteDesktopException(RemoteDesktopErrorCode.authentication);
    }
    if (reconnect != null) {
      final verified =
          await SessionReconnectVerifier(
            expectedHost: target.hostIdentity,
          ).verify(
            offer: offer,
            reconnect: reconnect,
            answerSdp: description.sdp,
            hostDtlsFingerprintSha256: fingerprint,
            previousGeneration: _reconnectGeneration,
            nowUnixMs: _nowUnixMs(),
          );
      _reconnectGeneration = verified.generation;
    } else {
      await SessionAnswerVerifier(expectedHost: target.hostIdentity).verify(
        offer: offer,
        answer: answer!,
        answerSdp: description.sdp,
        hostDtlsFingerprintSha256: fingerprint,
        nowUnixMs: _nowUnixMs(),
      );
      if (_reconnectSequence != null) {
        _reconnectGeneration = 0;
      }
    }
    await _peer.applyVerifiedAnswer(description.sdp);
    _inputSender ??= RemoteInputSender(
      sessionId: offer.sessionId,
      reliable: _peer.reliableInput,
      fast: _peer.fastInput,
    );
    _answer = null;
    _reconnect = null;
    _answerDescription = null;
    _setState(RemoteDesktopState.connecting);
  }

  Future<void> _handleLocalCandidate(IceCandidate candidate) async {
    if (!_offerSent) {
      if (_pendingLocalCandidates.length >= _maximumPendingLocalCandidates) {
        await _fail(RemoteDesktopErrorCode.peer);
        return;
      }
      _pendingLocalCandidates.add(candidate.deepCopy());
      return;
    }
    try {
      await _relayCandidate(candidate);
    } catch (error) {
      _debugRemoteFailure(_RemoteDebugOperation.relayLocalCandidate, error);
      if (_reconnectSequence != null) {
        await _handleRecoverableFailure(signaling: true);
      } else {
        await _fail(RemoteDesktopErrorCode.signaling);
      }
    }
  }

  Future<void> _relayCandidate(IceCandidate candidate) => _relay(
    webRtcNegotiation: WebRtcNegotiation(
      sessionId: _sessionId,
      iceCandidate: candidate,
    ),
  );

  Future<void> _relay({
    SessionAuthentication? sessionAuthentication,
    WebRtcNegotiation? webRtcNegotiation,
    SessionStatus? sessionStatus,
  }) async {
    final controller = _controllerIdentity!;
    final target = _target!;
    final envelope = SignalingEnvelope(
      protocolVersion: ProtocolVersion(
        major: protocolMajorVersion,
        minor: minimumProtocolMinorVersion,
      ),
      senderDeviceId: controller.deviceId,
      recipientDeviceId: target.hostIdentity.deviceId,
      requestId: 'session-${++_requestSequence}',
      sentAtUnixMs: Int64(_nowUnixMs()),
      sessionAuthentication: sessionAuthentication,
      webrtcNegotiation: webRtcNegotiation,
      sessionStatus: sessionStatus,
    );
    final encoded = Uint8List.fromList(envelope.writeToBuffer());
    decodeAndValidateSignalingEnvelope(encoded);
    await _signaling.relay(target.hostIdentity.deviceId, encoded);
  }

  void _handlePeerEvent(ControllerPeerEvent event) {
    _debugRemoteReason(_RemoteDebugOperation.peerEvent, event.name);
    switch (event) {
      case ControllerPeerEvent.connected:
        if (_state == RemoteDesktopState.connecting) {
          if (_reconnectSequence != null) {
            _completeReconnect();
          } else {
            _setState(RemoteDesktopState.connected);
          }
        } else if (_state == RemoteDesktopState.reconnecting) {
          _completeReconnect();
        }
      case ControllerPeerEvent.disconnected:
      case ControllerPeerEvent.failed:
        unawaited(_handleRecoverableFailure());
    }
  }

  Future<void> _handleRecoverableFailure({bool signaling = false}) async {
    if (_state == RemoteDesktopState.failed ||
        _state == RemoteDesktopState.closing ||
        _state == RemoteDesktopState.idle) {
      return;
    }
    if (_inputSender == null && _state != RemoteDesktopState.reconnecting) {
      await _fail(
        signaling
            ? RemoteDesktopErrorCode.signaling
            : RemoteDesktopErrorCode.peer,
      );
      return;
    }
    _signalingRecoveryRequired |= signaling;
    if (signaling) {
      _reconnectFailureCode = RemoteDesktopErrorCode.signaling;
    }
    if (_reconnectSequence != null) {
      if (_state != RemoteDesktopState.reconnecting) {
        _setState(RemoteDesktopState.reconnecting);
      }
      return;
    }
    _reconnectFailureCode = signaling
        ? RemoteDesktopErrorCode.signaling
        : RemoteDesktopErrorCode.peer;
    _reconnectSequence = const ReconnectPolicy().start();
    _setState(RemoteDesktopState.reconnecting);
    try {
      await _inputSender?.suspend();
    } catch (_) {}
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    final sequence = _reconnectSequence;
    if (sequence == null || !sequence.active || _reconnectTimer != null) {
      return;
    }
    final ticket = sequence.scheduleNext();
    if (ticket == null) {
      if (sequence.exhausted) {
        unawaited(_fail(_reconnectFailureCode));
      }
      return;
    }
    final policy = const ReconnectPolicy();
    _reconnectProgress = RemoteReconnectProgress(
      attempt: ticket.attempt,
      maximumAttempts: policy.attemptDelays.length,
      elapsed: ticket.elapsed,
      recoveryWindow: policy.recoveryWindow,
    );
    _diagnostics.recordReconnect(
      attempt: ticket.attempt,
      delay: ticket.delay,
      outcome: DiagnosticsReconnectOutcome.scheduled,
      totalElapsed: ticket.elapsed,
    );
    if (!_disposed) {
      notifyListeners();
    }
    _reconnectTimer = _reconnectScheduler.schedule(ticket.delay, () {
      _reconnectTimer = null;
      if (_state == RemoteDesktopState.connecting) {
        _waitForCurrentConnection(ticket);
        return;
      }
      unawaited(_runReconnectAttempt(ticket));
    });
  }

  void _waitForCurrentConnection(ReconnectAttemptTicket ticket) {
    final sequence = _reconnectSequence;
    if (sequence == null || !sequence.begin(ticket)) {
      return;
    }
    unawaited(_finishReconnectAttempt(sequence, ticket));
  }

  Future<void> _runReconnectAttempt(ReconnectAttemptTicket ticket) async {
    final sequence = _reconnectSequence;
    if (sequence == null || !sequence.begin(ticket)) {
      return;
    }
    _diagnostics.recordReconnect(
      attempt: ticket.attempt,
      delay: ticket.delay,
      outcome: DiagnosticsReconnectOutcome.attempted,
      totalElapsed: ticket.elapsed,
    );
    try {
      if (_signalingRecoveryRequired) {
        await _signaling.recover();
        _signalingRecoveryRequired = false;
      }
      _offerSent = false;
      _pendingLocalCandidates.clear();
      final peerOffer = await _peer.restartIce();
      await _sendAuthenticatedOffer(peerOffer);
    } on SignalingClientException {
      _signalingRecoveryRequired = true;
      _reconnectFailureCode = RemoteDesktopErrorCode.signaling;
    } on PeerSessionException {
      // The bounded policy owns peer retries.
    } on ControllerSessionIdentityException {
      await _fail(RemoteDesktopErrorCode.localIdentity);
      return;
    } on RemoteDesktopException catch (error) {
      await _fail(error.code);
      return;
    } on ProtocolValidationException {
      await _fail(RemoteDesktopErrorCode.signaling);
      return;
    } catch (_) {
      await _fail(RemoteDesktopErrorCode.peer);
      return;
    }
    await _finishReconnectAttempt(sequence, ticket);
  }

  Future<void> _finishReconnectAttempt(
    ReconnectAttemptSequence sequence,
    ReconnectAttemptTicket ticket,
  ) async {
    if (!sequence.complete(ticket)) return;
    if (sequence.exhausted) {
      _diagnostics.recordReconnect(
        attempt: ticket.attempt,
        delay: ticket.delay,
        outcome: DiagnosticsReconnectOutcome.exhausted,
        totalElapsed: ticket.elapsed,
      );
      await _fail(_reconnectFailureCode);
      return;
    }
    _scheduleReconnect();
  }

  void _completeReconnect() {
    final progress = _reconnectProgress;
    if (progress != null) {
      _diagnostics.recordReconnect(
        attempt: progress.attempt,
        delay: Duration.zero,
        outcome: DiagnosticsReconnectOutcome.recovered,
        totalElapsed: progress.elapsed,
      );
    }
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectSequence?.recovered();
    _reconnectSequence = null;
    _reconnectProgress = null;
    _signalingRecoveryRequired = false;
    try {
      _inputSender?.resume();
    } on InputSenderException {
      unawaited(_fail(RemoteDesktopErrorCode.peer));
      return;
    }
    _setState(RemoteDesktopState.connected);
  }

  @override
  Future<void> close() => _closeFuture ??= _closeResources(setIdle: true);

  Future<void> _fail(RemoteDesktopErrorCode code) async {
    if (_state == RemoteDesktopState.failed ||
        _state == RemoteDesktopState.closing ||
        _state == RemoteDesktopState.idle) {
      return;
    }
    _debugRemoteReason(_RemoteDebugOperation.terminalFailure, code.name);
    _errorCode = code;
    _diagnostics.recordError(
      _diagnosticErrorCategory(code),
      _diagnosticErrorCode(code),
    );
    await _closeResources(setIdle: false);
    _setState(RemoteDesktopState.failed);
  }

  Future<void> _closeResources({required bool setIdle}) async {
    if (_resourcesClosed) {
      if (setIdle) {
        _errorCode = null;
        _setState(RemoteDesktopState.idle);
      }
      return;
    }
    _resourcesClosed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _stopDiagnosticsStats();
    _reconnectSequence?.cancel();
    _reconnectSequence = null;
    _reconnectProgress = null;
    _setState(RemoteDesktopState.closing);
    final input = _inputSender;
    _inputSender = null;
    try {
      await input?.close();
    } catch (_) {}
    if (_offerSent) {
      try {
        await _relay(
          sessionStatus: SessionStatus(
            sessionId: _sessionId,
            state: SessionState.SESSION_STATE_CLOSING,
          ),
        );
      } catch (error) {
        // Cleanup must still finish if signaling was already interrupted.
        _debugRemoteFailure(_RemoteDebugOperation.relayClosingStatus, error);
      }
    }
    await _candidateSubscription?.cancel();
    _candidateSubscription = null;
    await _peerSubscription?.cancel();
    _peerSubscription = null;
    await _signalingSubscription?.cancel();
    _signalingSubscription = null;
    await _peer.close();
    await _signaling.close();
    await _identity.close();
    _pendingLocalCandidates.clear();
    _offerSent = false;
    _offer = null;
    _answer = null;
    _reconnect = null;
    _answerDescription = null;
    _sessionId = null;
    _reconnectGeneration = 0;
    _signalingRecoveryRequired = false;
    if (setIdle) {
      _errorCode = null;
      _setState(RemoteDesktopState.idle);
    }
  }

  Future<void> _validateLocalSignature(
    List<int> signature,
    DeviceIdentity identity,
    Uint8List transcript,
  ) async {
    if (signature.length != signatureBytes) {
      throw const RemoteDesktopException(RemoteDesktopErrorCode.authentication);
    }
    final valid = await Ed25519().verify(
      transcript,
      signature: Signature(
        signature,
        publicKey: SimplePublicKey(
          identity.publicKey,
          type: KeyPairType.ed25519,
        ),
      ),
    );
    if (!valid) {
      throw const RemoteDesktopException(RemoteDesktopErrorCode.authentication);
    }
  }

  Uint8List _checkedRandom(int length) {
    final value = _randomBytes(length);
    if (value.length != length) {
      value.fillRange(0, value.length, 0);
      throw const RemoteDesktopException(RemoteDesktopErrorCode.configuration);
    }
    return Uint8List.fromList(value);
  }

  void _setState(RemoteDesktopState state) {
    if (_state != state) {
      if (kDebugMode) {
        debugPrint('[remote] state=${state.name}');
      }
      _diagnostics.recordState(_diagnosticSessionState(state));
    }
    _state = state;
    if (state == RemoteDesktopState.connected) {
      _startDiagnosticsStats();
    } else if (state == RemoteDesktopState.reconnecting ||
        state == RemoteDesktopState.closing ||
        state == RemoteDesktopState.failed ||
        state == RemoteDesktopState.idle) {
      _stopDiagnosticsStats();
    }
    if (!_disposed) {
      notifyListeners();
    }
  }

  void _startDiagnosticsStats() {
    if (_diagnosticsTimer != null || _resourcesClosed) {
      return;
    }
    _diagnosticsTimer = Timer.periodic(
      _diagnosticsStatsInterval,
      (_) => unawaited(_collectDiagnosticsStats()),
    );
  }

  void _stopDiagnosticsStats() {
    _diagnosticsTimer?.cancel();
    _diagnosticsTimer = null;
  }

  Future<void> _collectDiagnosticsStats() async {
    if (_statsCollectionInFlight || _state != RemoteDesktopState.connected) {
      return;
    }
    _statsCollectionInFlight = true;
    try {
      final stats = await _peer.getAggregateStats();
      if (stats != null && _state == RemoteDesktopState.connected) {
        _diagnostics.recordStats(stats);
      }
    } catch (_) {
      // Diagnostics are best effort and never affect session behavior.
    } finally {
      _statsCollectionInFlight = false;
    }
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    unawaited(close());
    super.dispose();
  }
}

enum _RemoteDebugOperation {
  openIdentity,
  connectSignaling,
  createPeerOffer,
  sendAuthenticatedOffer,
  decodeRoutedEnvelope,
  applyRemoteAnswer,
  addRemoteCandidate,
  relayLocalCandidate,
  relayClosingStatus,
  signalingStream,
  peerStream,
  candidateStream,
  remoteError,
  peerEvent,
  terminalFailure,
}

void _debugRemoteFailure(_RemoteDebugOperation operation, Object error) {
  if (!kDebugMode) return;
  final cause = switch (error) {
    RemoteDesktopException(:final code) => code.name,
    SignalingClientException(:final code) => code.name,
    SessionAnswerAuthenticationException(:final code) => code.name,
    SessionReconnectAuthenticationException(:final code) => code.name,
    PeerSessionException(:final code) => code.name,
    ProtocolValidationException(:final code) => code.wireName,
    ControllerSessionIdentityException() => 'identityUnavailable',
    _ => error.runtimeType.toString(),
  };
  _debugRemoteReason(operation, cause);
}

void _debugRemoteReason(_RemoteDebugOperation operation, String cause) {
  if (!kDebugMode) return;
  debugPrint('[remote] operation=${operation.name} cause=$cause');
}

Uint8List _secureRandomBytes(int length) {
  final random = Random.secure();
  return Uint8List.fromList(
    List<int>.generate(length, (_) => random.nextInt(256), growable: false),
  );
}

int _systemNowUnixMs() => DateTime.now().millisecondsSinceEpoch;

DiagnosticsOsFamily _currentOsFamily() => switch (defaultTargetPlatform) {
  TargetPlatform.android => DiagnosticsOsFamily.android,
  TargetPlatform.iOS => DiagnosticsOsFamily.ios,
  TargetPlatform.linux => DiagnosticsOsFamily.linux,
  TargetPlatform.macOS => DiagnosticsOsFamily.macos,
  TargetPlatform.windows => DiagnosticsOsFamily.windows,
  TargetPlatform.fuchsia => DiagnosticsOsFamily.unknown,
};

DiagnosticsSessionState _diagnosticSessionState(RemoteDesktopState state) =>
    switch (state) {
      RemoteDesktopState.idle => DiagnosticsSessionState.idle,
      RemoteDesktopState.connecting => DiagnosticsSessionState.connecting,
      RemoteDesktopState.authenticating =>
        DiagnosticsSessionState.authenticating,
      RemoteDesktopState.negotiating => DiagnosticsSessionState.negotiating,
      RemoteDesktopState.connected => DiagnosticsSessionState.connected,
      RemoteDesktopState.reconnecting => DiagnosticsSessionState.reconnecting,
      RemoteDesktopState.closing => DiagnosticsSessionState.closing,
      RemoteDesktopState.failed => DiagnosticsSessionState.failed,
    };

DiagnosticsErrorCategory _diagnosticErrorCategory(
  RemoteDesktopErrorCode code,
) => switch (code) {
  RemoteDesktopErrorCode.configuration =>
    DiagnosticsErrorCategory.configuration,
  RemoteDesktopErrorCode.localIdentity =>
    DiagnosticsErrorCategory.localIdentity,
  RemoteDesktopErrorCode.signaling => DiagnosticsErrorCategory.signaling,
  RemoteDesktopErrorCode.authentication =>
    DiagnosticsErrorCategory.authentication,
  RemoteDesktopErrorCode.peer => DiagnosticsErrorCategory.peer,
  RemoteDesktopErrorCode.remote => DiagnosticsErrorCategory.remote,
};

DiagnosticsErrorCode _diagnosticErrorCode(
  RemoteDesktopErrorCode code,
) => switch (code) {
  RemoteDesktopErrorCode.configuration => DiagnosticsErrorCode.configuration,
  RemoteDesktopErrorCode.localIdentity =>
    DiagnosticsErrorCode.identityUnavailable,
  RemoteDesktopErrorCode.signaling => DiagnosticsErrorCode.signalingUnavailable,
  RemoteDesktopErrorCode.authentication =>
    DiagnosticsErrorCode.authenticationFailed,
  RemoteDesktopErrorCode.peer => DiagnosticsErrorCode.iceFailed,
  RemoteDesktopErrorCode.remote => DiagnosticsErrorCode.remoteFailed,
};

bool _bytesEqual(List<int> left, List<int> right) {
  if (left.length != right.length) {
    return false;
  }
  var difference = 0;
  for (var index = 0; index < left.length; index += 1) {
    difference |= left[index] ^ right[index];
  }
  return difference == 0;
}
