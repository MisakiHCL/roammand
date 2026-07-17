// SPDX-License-Identifier: MPL-2.0
// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:fixnum/fixnum.dart';
import 'package:roammand/desktop/remote/signaling_client.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

import 'controller_pairing_identity.dart';
import 'controller_pairing_models.dart';
import 'desktop_pairing_code.dart';
import 'device_identity_validator.dart';
import 'pairing_signaling_client.dart';
import 'qr_pairing_uri.dart';
import 'trusted_host_repository.dart';

const _ephemeralPrivateKeyBytes = 32;
const _grantIdBytes = 16;

typedef PairingEventWaiter =
    Future<bool> Function(Future<bool> event, Duration timeout);

final class ControllerPairingEngine {
  ControllerPairingEngine({
    required this.identity,
    required ControllerPairingSignalingLink signaling,
    required TrustedHostRepository trustedHosts,
    required List<String> sasWordList,
    List<int> Function(int length)? randomBytes,
    int Function()? nowUnixMs,
    PairingEventWaiter? eventWaiter,
  }) : _signaling = signaling,
       _trustedHosts = trustedHosts,
       _sasWordList = List<String>.unmodifiable(sasWordList),
       _randomBytes = randomBytes ?? _secureRandomBytes,
       _nowUnixMs = nowUnixMs ?? _systemNowUnixMs,
       _eventWaiter = eventWaiter ?? _defaultEventWaiter;

  final ControllerPairingIdentity identity;
  final ControllerPairingSignalingLink _signaling;
  final TrustedHostRepository _trustedHosts;
  final List<String> _sasWordList;
  final List<int> Function(int length) _randomBytes;
  final int Function() _nowUnixMs;
  final PairingEventWaiter _eventWaiter;
  final StreamController<ControllerPairingSnapshot> _states =
      StreamController<ControllerPairingSnapshot>.broadcast(sync: true);
  ControllerPairingSnapshot _snapshot = ControllerPairingSnapshot(
    state: ControllerPairingState.idle,
  );
  StreamIterator<PairingSignalingEvent>? _events;
  Future<bool>? _pendingEvent;
  Uint8List? _ephemeralPrivateKey;
  PairingKeySchedule? _keys;
  Uint8List? _transcript;
  Uint8List? _transcriptSha256;
  HostPairingInvitation? _invitation;
  bool _started = false;
  bool _cancelled = false;
  bool _signalingClosed = false;
  bool _closed = false;
  Future<ControllerPairingSnapshot>? _pairingFuture;
  Future<void>? _closeFuture;

  Stream<ControllerPairingSnapshot> get states => _states.stream;
  ControllerPairingSnapshot get snapshot => _snapshot;

  Future<ControllerPairingSnapshot> pairQr(HostPairingInvitation invitation) =>
      _start(() => _pairQr(invitation));

  Future<ControllerPairingSnapshot> pairDesktopCode({
    required String pairingCode,
    required Uri signalingEndpoint,
  }) => _start(() => _pairDesktopCode(pairingCode, signalingEndpoint));

  Future<ControllerPairingSnapshot> _start(Future<void> Function() operation) {
    if (_started || _closed) {
      return Future<ControllerPairingSnapshot>.error(
        StateError('Controller pairing engine is single-use'),
      );
    }
    _started = true;
    return _pairingFuture = _run(operation);
  }

  Future<ControllerPairingSnapshot> _run(
    Future<void> Function() operation,
  ) async {
    try {
      await operation();
    } on _PairingFailure catch (failure) {
      if (!_cancelled) {
        _publishTerminal(failure.state, failure.error);
      }
    } catch (_) {
      if (!_cancelled) {
        _publishTerminal(
          ControllerPairingState.failed,
          ControllerPairingError.internal,
        );
      }
    } finally {
      _clearSecrets();
      await _cancelEvents();
      await _closeSignaling();
    }
    return _snapshot;
  }

  Future<void> _pairQr(HostPairingInvitation value) async {
    final invitation = _validateQr(value);
    _invitation = invitation;
    _publish(
      ControllerPairingState.connecting,
      invitation: invitation,
      expiresAtUnixMs: invitation.expiresAtUnixMs.toInt(),
    );
    _subscribeToEvents();
    await _connect(Uri.parse(invitation.signalingEndpoint));
    final joined = await _joinQr(invitation.rendezvousId);
    if (!_bytesEqual(joined.rendezvousId, invitation.rendezvousId) ||
        !_bytesEqual(joined.hostDeviceId, invitation.hostIdentity.deviceId)) {
      _authenticationFailure();
    }
    invitation.expiresAtUnixMs = Int64(
      min(invitation.expiresAtUnixMs.toInt(), joined.expiresAtUnixMs),
    );
    _ensureNotExpired(invitation.expiresAtUnixMs.toInt());
    await _beginAuthenticatedPairing(invitation);
    await _completeAuthenticatedPairing(invitation);
  }

  Future<void> _pairDesktopCode(String rawCode, Uri endpoint) async {
    late final String code;
    try {
      code = normalizeDesktopPairingCode(rawCode);
      validateSignalingEndpoint(endpoint);
    } catch (_) {
      throw const _PairingFailure(
        ControllerPairingState.failed,
        ControllerPairingError.invalidInvitation,
      );
    }
    _publish(ControllerPairingState.connecting);
    _subscribeToEvents();
    await _connect(endpoint);
    final joined = await _joinDesktopCode(code);
    _ensureNotExpired(joined.expiresAtUnixMs);
    _publish(
      ControllerPairingState.waitingHostInvitation,
      expiresAtUnixMs: joined.expiresAtUnixMs,
    );
    final routed = await _nextRouted(joined.expiresAtUnixMs);
    final message = _decodePairingMessage(routed.opaqueEnvelope);
    if (!message.hasHostInvitation()) {
      _authenticationFailure();
    }
    final invitation = _validateDesktopInvitation(
      message.hostInvitation,
      code,
      endpoint,
      joined,
    );
    _invitation = invitation;
    await _beginAuthenticatedPairing(invitation);
    await _completeAuthenticatedPairing(invitation);
  }

  Future<void> _connect(Uri endpoint) async {
    try {
      await _signaling.connect(endpoint, identity.publicIdentity.deviceId);
    } catch (_) {
      throw const _PairingFailure(
        ControllerPairingState.failed,
        ControllerPairingError.signaling,
      );
    }
  }

  Future<PairingSignalingJoin> _joinQr(List<int> rendezvousId) async {
    try {
      return await _signaling.joinQr(rendezvousId);
    } catch (_) {
      throw const _PairingFailure(
        ControllerPairingState.failed,
        ControllerPairingError.signaling,
      );
    }
  }

  Future<PairingSignalingJoin> _joinDesktopCode(String code) async {
    try {
      return await _signaling.joinDesktopCode(code);
    } catch (_) {
      throw const _PairingFailure(
        ControllerPairingState.failed,
        ControllerPairingError.signaling,
      );
    }
  }

  Future<void> _beginAuthenticatedPairing(
    HostPairingInvitation invitation,
  ) async {
    _ensureNotExpired(invitation.expiresAtUnixMs.toInt());
    final random = _randomBytes(_ephemeralPrivateKeyBytes);
    if (random.length != _ephemeralPrivateKeyBytes ||
        random.any((byte) => byte < 0 || byte > 255)) {
      throw const _PairingFailure(
        ControllerPairingState.failed,
        ControllerPairingError.internal,
      );
    }
    _ephemeralPrivateKey = random is Uint8List
        ? random
        : Uint8List.fromList(random);
    try {
      final ephemeralPublicKey = await x25519PublicKey(_ephemeralPrivateKey!);
      final transcript = _encodePairingTranscript(
        identity.publicIdentity,
        invitation.hostIdentity,
        invitation.rendezvousId,
        ephemeralPublicKey,
        invitation.hostEphemeralPublicKey,
      );
      final transcriptSha256 = CanonicalTranscriptV1.sha256(transcript);
      _transcript = transcript;
      _transcriptSha256 = transcriptSha256;
      final sharedSecret = await x25519SharedSecret(
        _ephemeralPrivateKey!,
        Uint8List.fromList(invitation.hostEphemeralPublicKey),
      );
      try {
        _keys = await derivePairingKeys(sharedSecret, transcriptSha256);
      } finally {
        sharedSecret.fillRange(0, sharedSecret.length, 0);
      }
      final signature = await identity.sign(transcript);
      final hello = PairingMessage(
        controllerHello: ControllerPairingHello(
          rendezvousId: invitation.rendezvousId,
          identity: identity.publicIdentity,
          ephemeralPublicKey: ephemeralPublicKey,
          transcriptSha256: transcriptSha256,
          signature: signature,
        ),
      );
      _publish(
        ControllerPairingState.verifyingHost,
        invitation: invitation,
        expiresAtUnixMs: invitation.expiresAtUnixMs.toInt(),
      );
      await _relay(hello.writeToBuffer());
    } catch (error) {
      if (error is _PairingFailure) {
        rethrow;
      }
      _authenticationFailure();
    }
  }

  Future<void> _completeAuthenticatedPairing(
    HostPairingInvitation invitation,
  ) async {
    final proofEvent = await _nextRouted(invitation.expiresAtUnixMs.toInt());
    final proofPlaintext = await _openHostPlaintext(proofEvent, sequence: 1);
    if (!proofPlaintext.hasHostProof()) {
      _authenticationFailure();
    }
    await _verifyHostProof(proofPlaintext.hostProof, invitation);
    await _sendControllerReady(invitation);
    final sasWords =
        invitation.kind ==
            PairingInvitationKind.PAIRING_INVITATION_KIND_DESKTOP_CODE
        ? pairingSasWords(_transcriptSha256!, _sasWordList)
        : const <String>[];
    _publish(
      ControllerPairingState.waitingHostDecision,
      invitation: invitation,
      sasWords: sasWords,
      expiresAtUnixMs: invitation.expiresAtUnixMs.toInt(),
    );

    final decisionEvent = await _nextEvent(invitation.expiresAtUnixMs.toInt());
    if (decisionEvent is PairingSignalingClosed) {
      _handleSignalingClosed(decisionEvent);
    }
    if (decisionEvent is PairingSignalingRemoteError) {
      _handleRemoteError(decisionEvent);
    }
    if (decisionEvent is! PairingSignalingRouted) {
      _authenticationFailure();
    }
    final decisionPlaintext = await _openHostPlaintext(
      decisionEvent,
      sequence: 2,
    );
    if (!decisionPlaintext.hasFinalDecision()) {
      _authenticationFailure();
    }
    await _handleFinalDecision(decisionPlaintext.finalDecision, invitation);
  }

  Future<void> _verifyHostProof(
    HostPairingProof proof,
    HostPairingInvitation invitation,
  ) async {
    _ensureNotExpired(invitation.expiresAtUnixMs.toInt());
    if (!proof.hasConfirmation() ||
        proof.hostSignature.length != signatureBytes ||
        proof.expiresAtUnixMs.toInt() != invitation.expiresAtUnixMs.toInt() ||
        !_confirmationMatches(proof.confirmation, invitation)) {
      _authenticationFailure();
    }
    final valid = await Ed25519().verify(
      _transcript!,
      signature: Signature(
        proof.hostSignature,
        publicKey: SimplePublicKey(
          invitation.hostIdentity.publicKey,
          type: KeyPairType.ed25519,
        ),
      ),
    );
    if (!valid) {
      _authenticationFailure();
    }
  }

  bool _confirmationMatches(
    PairingConfirmationData confirmation,
    HostPairingInvitation invitation,
  ) =>
      _bytesEqual(
        confirmation.controllerDeviceId,
        identity.publicIdentity.deviceId,
      ) &&
      _bytesEqual(
        confirmation.hostDeviceId,
        invitation.hostIdentity.deviceId,
      ) &&
      _bytesEqual(confirmation.rendezvousId, invitation.rendezvousId) &&
      _bytesEqual(
        confirmation.controllerIdentityPublicKey,
        identity.publicIdentity.publicKey,
      ) &&
      _bytesEqual(
        confirmation.hostIdentityPublicKey,
        invitation.hostIdentity.publicKey,
      ) &&
      _bytesEqual(
        confirmation.controllerEphemeralPublicKey,
        _controllerEphemeralPublicKey,
      ) &&
      _bytesEqual(
        confirmation.hostEphemeralPublicKey,
        invitation.hostEphemeralPublicKey,
      ) &&
      _bytesEqual(confirmation.transcriptSha256, _transcriptSha256!);

  List<int> get _controllerEphemeralPublicKey {
    final decoded = CanonicalTranscriptV1.decode(_transcript!);
    return decoded.fields.singleWhere((field) => field.tag == 6).value;
  }

  Future<void> _sendControllerReady(HostPairingInvitation invitation) async {
    final plaintext = PairingPlaintext(
      controllerReady: ControllerPairingReady(
        transcriptSha256: _transcriptSha256,
      ),
    );
    await _relay(
      await _sealControllerPlaintext(plaintext, invitation, sequence: 1),
    );
  }

  Future<void> _handleFinalDecision(
    PairingFinalDecision decision,
    HostPairingInvitation invitation,
  ) async {
    if (!_bytesEqual(decision.transcriptSha256, _transcriptSha256!)) {
      _authenticationFailure();
    }
    switch (decision.status) {
      case PairingDecisionStatus.PAIRING_DECISION_STATUS_ACCEPTED:
        if (!decision.hasGrant() || !_validGrant(decision.grant, invitation)) {
          _authenticationFailure();
        }
        try {
          await _trustedHosts.savePairing(
            TrustedHostBinding(
              hostIdentity: invitation.hostIdentity,
              signalingEndpoint: invitation.signalingEndpoint,
              pairedAtUnixMs: decision.grant.createdAtUnixMs,
            ),
          );
        } catch (_) {
          throw const _PairingFailure(
            ControllerPairingState.failed,
            ControllerPairingError.persistence,
          );
        }
        _publishTerminal(ControllerPairingState.accepted, null);
      case PairingDecisionStatus.PAIRING_DECISION_STATUS_REJECTED:
        if (decision.hasGrant()) {
          _authenticationFailure();
        }
        _publishTerminal(ControllerPairingState.rejected, null);
      case PairingDecisionStatus.PAIRING_DECISION_STATUS_EXPIRED:
        if (decision.hasGrant()) {
          _authenticationFailure();
        }
        throw const _PairingFailure(
          ControllerPairingState.expired,
          ControllerPairingError.expired,
        );
      case PairingDecisionStatus.PAIRING_DECISION_STATUS_UNSPECIFIED:
      case PairingDecisionStatus.PAIRING_DECISION_STATUS_PENDING:
        _authenticationFailure();
    }
  }

  bool _validGrant(ControllerGrant grant, HostPairingInvitation invitation) {
    try {
      validateDeviceIdentity(grant.controller);
      final permissions = grant.permissions.toSet();
      return grant.grantId.length == _grantIdBytes &&
          _bytesEqual(grant.hostDeviceId, invitation.hostIdentity.deviceId) &&
          _identityMatches(grant.controller, identity.publicIdentity) &&
          grant.createdAtUnixMs > Int64.ZERO &&
          permissions.length == 2 &&
          permissions.contains(
            SessionPermission.SESSION_PERMISSION_VIEW_SCREEN,
          ) &&
          permissions.contains(
            SessionPermission.SESSION_PERMISSION_CONTROL_INPUT,
          );
    } catch (_) {
      return false;
    }
  }

  Future<PairingPlaintext> _openHostPlaintext(
    PairingSignalingRouted event, {
    required int sequence,
  }) async {
    final invitation = _invitation!;
    if (!_bytesEqual(event.rendezvousId, invitation.rendezvousId) ||
        !_bytesEqual(event.senderDeviceId, invitation.hostIdentity.deviceId)) {
      _authenticationFailure();
    }
    final message = _decodePairingMessage(event.opaqueEnvelope);
    if (!message.hasEncryptedEnvelope()) {
      _authenticationFailure();
    }
    final envelope = message.encryptedEnvelope;
    if (!envelope.hasProtocolVersion() ||
        envelope.protocolVersion.major != protocolMajorVersion ||
        envelope.protocolVersion.minor < minimumProtocolMinorVersion ||
        !_bytesEqual(envelope.rendezvousId, invitation.rendezvousId) ||
        envelope.direction !=
            PairingDirection.PAIRING_DIRECTION_HOST_TO_CONTROLLER ||
        envelope.sequence.toInt() != sequence) {
      _authenticationFailure();
    }
    try {
      final aad = pairingAad(
        direction: PairingCryptoDirection.hostToController,
        sequence: sequence,
        rendezvousId: Uint8List.fromList(invitation.rendezvousId),
        controllerDeviceId: Uint8List.fromList(
          identity.publicIdentity.deviceId,
        ),
        hostDeviceId: Uint8List.fromList(invitation.hostIdentity.deviceId),
      );
      final plaintext = await openPairingPayload(
        key: _keys!.hostToController,
        direction: PairingCryptoDirection.hostToController,
        sequence: sequence,
        aad: aad,
        ciphertextAndTag: Uint8List.fromList(envelope.ciphertext),
      );
      final decoded = PairingPlaintext.fromBuffer(plaintext);
      if (!_bytesEqual(decoded.writeToBuffer(), plaintext)) {
        _authenticationFailure();
      }
      return decoded;
    } catch (error) {
      if (error is _PairingFailure) {
        rethrow;
      }
      _authenticationFailure();
    }
  }

  Future<Uint8List> _sealControllerPlaintext(
    PairingPlaintext plaintext,
    HostPairingInvitation invitation, {
    required int sequence,
  }) async {
    final aad = pairingAad(
      direction: PairingCryptoDirection.controllerToHost,
      sequence: sequence,
      rendezvousId: Uint8List.fromList(invitation.rendezvousId),
      controllerDeviceId: Uint8List.fromList(identity.publicIdentity.deviceId),
      hostDeviceId: Uint8List.fromList(invitation.hostIdentity.deviceId),
    );
    final ciphertext = await sealPairingPayload(
      key: _keys!.controllerToHost,
      direction: PairingCryptoDirection.controllerToHost,
      sequence: sequence,
      aad: aad,
      plaintext: Uint8List.fromList(plaintext.writeToBuffer()),
    );
    return Uint8List.fromList(
      PairingMessage(
        encryptedEnvelope: EncryptedPairingEnvelope(
          protocolVersion: _version(),
          rendezvousId: invitation.rendezvousId,
          direction: PairingDirection.PAIRING_DIRECTION_CONTROLLER_TO_HOST,
          sequence: Int64(sequence),
          ciphertext: ciphertext,
        ),
      ).writeToBuffer(),
    );
  }

  Future<void> _relay(List<int> encoded) async {
    try {
      await _signaling.relay(
        _invitation!.rendezvousId,
        Uint8List.fromList(encoded),
      );
    } catch (_) {
      throw const _PairingFailure(
        ControllerPairingState.failed,
        ControllerPairingError.signaling,
      );
    }
  }

  Future<PairingSignalingRouted> _nextRouted(int expiresAtUnixMs) async {
    final event = await _nextEvent(expiresAtUnixMs);
    if (event is PairingSignalingClosed) {
      _handleSignalingClosed(event);
    }
    if (event is PairingSignalingRemoteError) {
      _handleRemoteError(event);
    }
    if (event is! PairingSignalingRouted) {
      _authenticationFailure();
    }
    return event;
  }

  Future<PairingSignalingEvent> _nextEvent(int expiresAtUnixMs) async {
    _ensureNotExpired(expiresAtUnixMs);
    final remaining = expiresAtUnixMs - _nowUnixMs();
    try {
      final hasEvent = await _eventWaiter(
        _pendingEvent!,
        Duration(milliseconds: remaining),
      );
      if (_cancelled) {
        throw const _PairingFailure(
          ControllerPairingState.cancelled,
          ControllerPairingError.cancelled,
        );
      }
      if (!hasEvent) {
        _ensureNotExpired(expiresAtUnixMs);
        throw const _PairingFailure(
          ControllerPairingState.failed,
          ControllerPairingError.signaling,
        );
      }
      _ensureNotExpired(expiresAtUnixMs);
      final event = _events!.current;
      _pendingEvent = _events!.moveNext();
      return event;
    } on TimeoutException {
      throw const _PairingFailure(
        ControllerPairingState.expired,
        ControllerPairingError.expired,
      );
    } on _PairingFailure {
      rethrow;
    } catch (_) {
      throw const _PairingFailure(
        ControllerPairingState.failed,
        ControllerPairingError.signaling,
      );
    }
  }

  void _subscribeToEvents() {
    _events = StreamIterator<PairingSignalingEvent>(_signaling.events);
    _pendingEvent = _events!.moveNext();
  }

  Future<void> _cancelEvents() async {
    final events = _events;
    _events = null;
    _pendingEvent = null;
    await events?.cancel();
  }

  void _handleSignalingClosed(PairingSignalingClosed event) {
    switch (event.completion) {
      case PairingRendezvousCompletion.PAIRING_RENDEZVOUS_COMPLETION_REJECTED:
        throw const _PairingFailure(ControllerPairingState.rejected, null);
      case PairingRendezvousCompletion.PAIRING_RENDEZVOUS_COMPLETION_EXPIRED:
        throw const _PairingFailure(
          ControllerPairingState.expired,
          ControllerPairingError.expired,
        );
      case PairingRendezvousCompletion
          .PAIRING_RENDEZVOUS_COMPLETION_DISCONNECTED:
      case PairingRendezvousCompletion.PAIRING_RENDEZVOUS_COMPLETION_SUCCEEDED:
      case PairingRendezvousCompletion
          .PAIRING_RENDEZVOUS_COMPLETION_UNSPECIFIED:
        throw const _PairingFailure(
          ControllerPairingState.failed,
          ControllerPairingError.signaling,
        );
    }
  }

  void _handleRemoteError(PairingSignalingRemoteError event) {
    if (event.code == ErrorCode.ERROR_CODE_PAIRING_CODE_EXPIRED) {
      throw const _PairingFailure(
        ControllerPairingState.expired,
        ControllerPairingError.expired,
      );
    }
    throw const _PairingFailure(
      ControllerPairingState.failed,
      ControllerPairingError.signaling,
    );
  }

  HostPairingInvitation _validateQr(HostPairingInvitation invitation) {
    try {
      return parseQrPairingUri(
        encodeQrPairingUri(invitation),
        nowUnixMs: _nowUnixMs(),
      );
    } catch (_) {
      throw const _PairingFailure(
        ControllerPairingState.failed,
        ControllerPairingError.invalidInvitation,
      );
    }
  }

  HostPairingInvitation _validateDesktopInvitation(
    HostPairingInvitation value,
    String pairingCode,
    Uri endpoint,
    PairingSignalingJoin joined,
  ) {
    final invitation = value.deepCopy();
    try {
      if (!invitation.hasProtocolVersion() ||
          invitation.protocolVersion.major != protocolMajorVersion ||
          invitation.protocolVersion.minor < minimumProtocolMinorVersion ||
          invitation.kind !=
              PairingInvitationKind.PAIRING_INVITATION_KIND_DESKTOP_CODE ||
          invitation.pairingCode != pairingCode ||
          invitation.signalingEndpoint != endpoint.toString() ||
          invitation.rendezvousId.length != rendezvousIdBytes ||
          !invitation.hasHostIdentity() ||
          invitation.hostEphemeralPublicKey.length != publicKeyBytes ||
          !_bytesEqual(invitation.rendezvousId, joined.rendezvousId) ||
          !_bytesEqual(invitation.hostIdentity.deviceId, joined.hostDeviceId) ||
          invitation.issuedAtUnixMs <= Int64.ZERO ||
          invitation.expiresAtUnixMs < invitation.issuedAtUnixMs ||
          invitation.expiresAtUnixMs.toInt() > joined.expiresAtUnixMs ||
          invitation.expiresAtUnixMs.toInt() -
                  invitation.issuedAtUnixMs.toInt() >
              pairingRendezvousLifetimeMs) {
        throw const FormatException();
      }
      validateDesktopHostIdentity(invitation.hostIdentity);
      validateHostFingerprint(
        invitation.hostIdentity,
        invitation.hostPublicKeyFingerprintSha256,
      );
      _ensureNotExpired(invitation.expiresAtUnixMs.toInt());
      return invitation;
    } catch (error) {
      if (error is _PairingFailure) {
        rethrow;
      }
      throw const _PairingFailure(
        ControllerPairingState.failed,
        ControllerPairingError.invalidInvitation,
      );
    }
  }

  PairingMessage _decodePairingMessage(List<int> encoded) {
    if (encoded.isEmpty || encoded.length > maxOpaqueSignalingEnvelopeBytes) {
      _authenticationFailure();
    }
    try {
      final message = PairingMessage.fromBuffer(encoded);
      if (!_bytesEqual(message.writeToBuffer(), encoded) ||
          message.whichPayload() == PairingMessage_Payload.notSet) {
        _authenticationFailure();
      }
      return message;
    } catch (error) {
      if (error is _PairingFailure) {
        rethrow;
      }
      _authenticationFailure();
    }
  }

  void _ensureNotExpired(int expiresAtUnixMs) {
    if (expiresAtUnixMs <= 0 || _nowUnixMs() > expiresAtUnixMs) {
      throw const _PairingFailure(
        ControllerPairingState.expired,
        ControllerPairingError.expired,
      );
    }
  }

  Never _authenticationFailure() => throw const _PairingFailure(
    ControllerPairingState.failed,
    ControllerPairingError.authentication,
  );

  void _publish(
    ControllerPairingState state, {
    HostPairingInvitation? invitation,
    List<String> sasWords = const <String>[],
    int expiresAtUnixMs = 0,
  }) {
    final source = invitation ?? _invitation;
    _snapshot = ControllerPairingSnapshot(
      state: state,
      hostIdentity: source?.hostIdentity,
      hostFingerprintSha256:
          source?.hostPublicKeyFingerprintSha256 ?? const <int>[],
      sasWords: sasWords,
      expiresAtUnixMs: expiresAtUnixMs,
    );
    if (!_states.isClosed) {
      _states.add(_snapshot);
    }
  }

  void _publishTerminal(
    ControllerPairingState state,
    ControllerPairingError? error,
  ) {
    if (_snapshot.isTerminal) {
      return;
    }
    final invitation = _invitation;
    _snapshot = ControllerPairingSnapshot(
      state: state,
      hostIdentity: invitation?.hostIdentity,
      hostFingerprintSha256:
          invitation?.hostPublicKeyFingerprintSha256 ?? const <int>[],
      error: error,
    );
    if (!_states.isClosed) {
      _states.add(_snapshot);
    }
  }

  Future<void> cancel() async {
    if (_closed || _snapshot.isTerminal) {
      return;
    }
    _cancelled = true;
    _publishTerminal(
      ControllerPairingState.cancelled,
      ControllerPairingError.cancelled,
    );
    await _cancelEvents();
    await _closeSignaling();
  }

  Future<void> _closeSignaling() async {
    if (_signalingClosed) {
      return;
    }
    _signalingClosed = true;
    await _signaling.close();
  }

  void _clearSecrets() {
    _ephemeralPrivateKey?.fillRange(0, _ephemeralPrivateKey!.length, 0);
    _ephemeralPrivateKey = null;
    _keys?.controllerToHost.fillRange(0, _keys!.controllerToHost.length, 0);
    _keys?.hostToController.fillRange(0, _keys!.hostToController.length, 0);
    _keys = null;
    _transcript?.fillRange(0, _transcript!.length, 0);
    _transcript = null;
    _transcriptSha256?.fillRange(0, _transcriptSha256!.length, 0);
    _transcriptSha256 = null;
  }

  Future<void> close() => _closeFuture ??= _close();

  Future<void> _close() async {
    if (_closed) {
      return;
    }
    if (_started && !_snapshot.isTerminal) {
      await cancel();
      await _pairingFuture;
    } else {
      await _closeSignaling();
    }
    _closed = true;
    _clearSecrets();
    if (!_states.isClosed) {
      await _states.close();
    }
  }
}

final class _PairingFailure implements Exception {
  const _PairingFailure(this.state, this.error);

  final ControllerPairingState state;
  final ControllerPairingError? error;
}

Uint8List _encodePairingTranscript(
  DeviceIdentity controller,
  DeviceIdentity host,
  List<int> rendezvousId,
  List<int> controllerEphemeralPublicKey,
  List<int> hostEphemeralPublicKey,
) => CanonicalTranscriptV1.encode(
  TranscriptPurpose.pairingSas,
  <TranscriptField>[
    TranscriptField(1, controller.deviceId),
    TranscriptField(2, host.deviceId),
    TranscriptField(3, rendezvousId),
    TranscriptField(4, controller.publicKey),
    TranscriptField(5, host.publicKey),
    TranscriptField(6, controllerEphemeralPublicKey),
    TranscriptField(7, hostEphemeralPublicKey),
  ],
);

bool _identityMatches(DeviceIdentity left, DeviceIdentity right) =>
    _bytesEqual(left.deviceId, right.deviceId) &&
    left.publicKeyAlgorithm == right.publicKeyAlgorithm &&
    _bytesEqual(left.publicKey, right.publicKey) &&
    left.displayName == right.displayName &&
    left.platform == right.platform;

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

List<int> _secureRandomBytes(int length) {
  final random = Random.secure();
  return List<int>.generate(
    length,
    (_) => random.nextInt(256),
    growable: false,
  );
}

int _systemNowUnixMs() => DateTime.now().millisecondsSinceEpoch;

ProtocolVersion _version() {
  final version = ProtocolVersion(major: protocolMajorVersion);
  // Keep the protobuf wire form canonical across Dart and prost: Dart records
  // an explicitly assigned zero while prost omits proto3 default values.
  if (minimumProtocolMinorVersion != 0) {
    version.minor = minimumProtocolMinorVersion;
  }
  return version;
}

Future<bool> _defaultEventWaiter(Future<bool> event, Duration timeout) =>
    event.timeout(timeout, onTimeout: () => false);
