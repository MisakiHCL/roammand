// SPDX-License-Identifier: Apache-2.0

import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart' as pb;

import 'generated/roammand/v1/authorization.pb.dart';
import 'generated/roammand/v1/error.pb.dart';
import 'generated/roammand/v1/identity.pb.dart';
import 'generated/roammand/v1/input.pb.dart';
import 'generated/roammand/v1/local_ipc.pb.dart';
import 'generated/roammand/v1/pairing.pb.dart';
import 'generated/roammand/v1/privileged_bridge.pb.dart';
import 'generated/roammand/v1/session.pb.dart';
import 'generated/roammand/v1/signaling.pb.dart';
import 'generated/roammand/v1/status.pb.dart';
import 'generated/roammand/v1/version.pb.dart';
import 'generated/roammand/v1/webrtc.pb.dart';
import 'protocol_limits.dart';

enum ProtocolValidationErrorCode {
  messageTooLarge('message_too_large'),
  invalidProtocolVersion('invalid_protocol_version'),
  missingPayload('missing_payload'),
  invalidLength('invalid_length'),
  invalidEnum('invalid_enum'),
  invalidState('invalid_state'),
  invalidUtf8Length('invalid_utf8_length'),
  invalidLifetime('invalid_lifetime'),
  duplicateValue('duplicate_value');

  const ProtocolValidationErrorCode(this.wireName);

  final String wireName;
}

final class ProtocolValidationException implements Exception {
  const ProtocolValidationException(this.code);

  final ProtocolValidationErrorCode code;

  @override
  String toString() => 'ProtocolValidationException(${code.wireName})';
}

SignalingEnvelope decodeAndValidateSignalingEnvelope(Uint8List encoded) {
  _validateEncodedLength(encoded, maxSignalingEnvelopeBytes);
  final envelope = _decode(() => SignalingEnvelope.fromBuffer(encoded));
  _validateSignalingEnvelope(envelope);
  return envelope;
}

ReliableInputEnvelope decodeAndValidateReliableInputEnvelope(
  Uint8List encoded,
) {
  _validateEncodedLength(encoded, maxReliableInputEnvelopeBytes);
  final envelope = _decode(() => ReliableInputEnvelope.fromBuffer(encoded));
  _validateProtocolVersionPresence(
    envelope.hasProtocolVersion(),
    envelope.protocolVersion,
  );
  if (envelope.whichEvent() == ReliableInputEnvelope_Event.notSet) {
    _fail(ProtocolValidationErrorCode.missingPayload);
  }
  _validateFixedLength(envelope.sessionId, sessionIdBytes);
  _validateReliableEvent(envelope);
  return envelope;
}

PointerFastEnvelope decodeAndValidatePointerFastEnvelope(Uint8List encoded) {
  _validateEncodedLength(encoded, maxPointerFastEnvelopeBytes);
  final envelope = _decode(() => PointerFastEnvelope.fromBuffer(encoded));
  _validateProtocolVersionPresence(
    envelope.hasProtocolVersion(),
    envelope.protocolVersion,
  );
  if (envelope.whichEvent() == PointerFastEnvelope_Event.notSet) {
    _fail(ProtocolValidationErrorCode.missingPayload);
  }
  _validateFixedLength(envelope.sessionId, sessionIdBytes);
  return envelope;
}

PrivilegedBridgeClientFrame decodeAndValidatePrivilegedBridgeClientFrame(
  Uint8List encoded,
) {
  _validateEncodedLength(encoded, maxPrivilegedBridgeFrameBytes);
  final frame = _decode(() => PrivilegedBridgeClientFrame.fromBuffer(encoded));
  _validatePrivilegedBridgeFrameHeader(
    frame.hasProtocolVersion(),
    frame.protocolVersion,
    frame.requestId,
    frame.sequence,
  );
  if (frame.whichPayload() == PrivilegedBridgeClientFrame_Payload.notSet) {
    _fail(ProtocolValidationErrorCode.missingPayload);
  }
  return frame;
}

PrivilegedBridgeServerFrame decodeAndValidatePrivilegedBridgeServerFrame(
  Uint8List encoded,
) {
  _validateEncodedLength(encoded, maxPrivilegedBridgeFrameBytes);
  final frame = _decode(() => PrivilegedBridgeServerFrame.fromBuffer(encoded));
  _validatePrivilegedBridgeFrameHeader(
    frame.hasProtocolVersion(),
    frame.protocolVersion,
    frame.requestId,
    frame.sequence,
  );
  if (frame.whichPayload() == PrivilegedBridgeServerFrame_Payload.notSet) {
    _fail(ProtocolValidationErrorCode.missingPayload);
  }
  return frame;
}

void validatePrivilegedBridgeStatusSnapshot(
  PrivilegedBridgeStatusSnapshot snapshot,
) {
  _validateEnum(snapshot.state, PrivilegedBridgeState.values);
  _validateUtf8Length(
    snapshot.activeControllerDisplayName,
    maxDeviceNameUtf8Bytes,
  );

  switch (snapshot.state) {
    case PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_NOT_INSTALLED:
    case PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_APPROVAL_REQUIRED:
    case PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_PERMISSION_REQUIRED:
    case PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_USER_SESSION_ONLY:
      if (snapshot.hasInteractiveSession() ||
          snapshot.helperConnected ||
          snapshot.activeControllerDisplayName.isNotEmpty ||
          snapshot.hasError()) {
        _fail(ProtocolValidationErrorCode.invalidState);
      }
    case PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_READY:
      if (!snapshot.hasInteractiveSession()) {
        _fail(ProtocolValidationErrorCode.missingPayload);
      }
      _validatePrivilegedSessionDescriptor(snapshot.interactiveSession);
      if (!snapshot.helperConnected ||
          snapshot.activeControllerDisplayName.isNotEmpty ||
          snapshot.hasError()) {
        _fail(ProtocolValidationErrorCode.invalidState);
      }
    case PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_TRANSITIONING:
      if (snapshot.hasInteractiveSession()) {
        _validatePrivilegedSessionDescriptor(snapshot.interactiveSession);
      }
      if (snapshot.hasError()) {
        _fail(ProtocolValidationErrorCode.invalidState);
      }
    case PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_CONTROLLED:
      if (!snapshot.hasInteractiveSession()) {
        _fail(ProtocolValidationErrorCode.missingPayload);
      }
      _validatePrivilegedSessionDescriptor(snapshot.interactiveSession);
      if (!snapshot.helperConnected ||
          snapshot.activeControllerDisplayName.isEmpty ||
          snapshot.hasError()) {
        _fail(ProtocolValidationErrorCode.invalidState);
      }
    case PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_FAILED:
      if (snapshot.helperConnected ||
          snapshot.activeControllerDisplayName.isNotEmpty) {
        _fail(ProtocolValidationErrorCode.invalidState);
      }
      if (!snapshot.hasError()) {
        _fail(ProtocolValidationErrorCode.missingPayload);
      }
      _validateUnifiedError(snapshot.error);
    case PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_UNSPECIFIED:
      _fail(ProtocolValidationErrorCode.invalidEnum);
  }
}

void validateSessionStatus(SessionStatus status) {
  if (status.sessionId.isNotEmpty &&
      status.sessionId.length != sessionIdBytes) {
    _fail(ProtocolValidationErrorCode.invalidLength);
  }
  _validateEnum(status.state, SessionState.values);

  switch (status.state) {
    case SessionState.SESSION_STATE_IDLE:
      if (status.sessionId.isNotEmpty || status.hasError()) {
        _fail(ProtocolValidationErrorCode.invalidState);
      }
    case SessionState.SESSION_STATE_SIGNALING:
    case SessionState.SESSION_STATE_AUTHENTICATING:
    case SessionState.SESSION_STATE_CONNECTING:
    case SessionState.SESSION_STATE_CONNECTED:
    case SessionState.SESSION_STATE_RECONNECTING:
    case SessionState.SESSION_STATE_CLOSING:
      _validateFixedLength(status.sessionId, sessionIdBytes);
      if (status.hasError()) {
        _fail(ProtocolValidationErrorCode.invalidState);
      }
    case SessionState.SESSION_STATE_FAILED:
      _validateFixedLength(status.sessionId, sessionIdBytes);
      if (!status.hasError()) {
        _fail(ProtocolValidationErrorCode.invalidState);
      }
      _validateUnifiedError(status.error);
    case SessionState.SESSION_STATE_UNSPECIFIED:
      _fail(ProtocolValidationErrorCode.invalidEnum);
  }
}

void validateRemoteSessionStatusSnapshot(RemoteSessionStatusSnapshot snapshot) {
  if (!snapshot.hasSessionStatus()) {
    _fail(ProtocolValidationErrorCode.missingPayload);
  }
  validateSessionStatus(snapshot.sessionStatus);
  if (snapshot.sessionStatus.state == SessionState.SESSION_STATE_IDLE) {
    if (snapshot.controllerDeviceId.isNotEmpty) {
      _fail(ProtocolValidationErrorCode.invalidState);
    }
    return;
  }
  _validateFixedLength(snapshot.controllerDeviceId, deviceIdBytes);
}

void validateDeviceIdentity(DeviceIdentity identity) {
  _validateFixedLength(identity.deviceId, deviceIdBytes);
  _validateFixedLength(identity.publicKey, publicKeyBytes);
  if (identity.publicKeyAlgorithm !=
      PublicKeyAlgorithm.PUBLIC_KEY_ALGORITHM_ED25519) {
    _fail(ProtocolValidationErrorCode.invalidEnum);
  }
  _validateEnum(identity.platform, DevicePlatform.values);
  _validateUtf8Length(identity.displayName, maxDeviceNameUtf8Bytes);
}

void _validateSignalingEnvelope(SignalingEnvelope envelope) {
  _validateProtocolVersionPresence(
    envelope.hasProtocolVersion(),
    envelope.protocolVersion,
  );
  if (envelope.whichPayload() == SignalingEnvelope_Payload.notSet) {
    _fail(ProtocolValidationErrorCode.missingPayload);
  }
  _validateFixedLength(envelope.senderDeviceId, deviceIdBytes);
  _validateFixedLength(envelope.recipientDeviceId, deviceIdBytes);
  _validateUtf8Length(envelope.requestId, maxRequestIdUtf8Bytes);

  switch (envelope.whichPayload()) {
    case SignalingEnvelope_Payload.capabilityNegotiation:
      _validateCapabilityNegotiation(envelope.capabilityNegotiation);
    case SignalingEnvelope_Payload.pairing:
      _validatePairingMessage(envelope.pairing);
    case SignalingEnvelope_Payload.sessionAuthentication:
      _validateSessionAuthentication(envelope.sessionAuthentication);
    case SignalingEnvelope_Payload.webrtcNegotiation:
      _validateWebRtcNegotiation(envelope.webrtcNegotiation);
    case SignalingEnvelope_Payload.sessionStatus:
      validateSessionStatus(envelope.sessionStatus);
    case SignalingEnvelope_Payload.error:
      _validateUnifiedError(envelope.error);
    case SignalingEnvelope_Payload.notSet:
      _fail(ProtocolValidationErrorCode.missingPayload);
  }
}

void _validateCapabilityNegotiation(CapabilityNegotiation negotiation) {
  _validateProtocolVersionPresence(
    negotiation.hasProtocolVersion(),
    negotiation.protocolVersion,
  );
  final seen = <int>{};
  _validateUniqueEnums(
    negotiation.requiredCapabilities,
    Capability.values,
    seen,
  );
  _validateUniqueEnums(
    negotiation.optionalCapabilities,
    Capability.values,
    seen,
  );
}

void _validatePairingMessage(PairingMessage message) {
  switch (message.whichPayload()) {
    case PairingMessage_Payload.qrRendezvous:
      final rendezvous = message.qrRendezvous;
      _validateFixedLength(rendezvous.rendezvousId, rendezvousIdBytes);
      validateDeviceIdentity(rendezvous.hostIdentity);
      _validateFixedLength(
        rendezvous.hostPublicKeyFingerprintSha256,
        nonceOrHashBytes,
      );
      _validateFixedLength(rendezvous.hostEphemeralPublicKey, publicKeyBytes);
      _validateUtf8Length(
        rendezvous.signalingEndpoint,
        maxSignalingEndpointUtf8Bytes,
      );
      _validateRendezvousLifetime(
        rendezvous.issuedAtUnixMs,
        rendezvous.expiresAtUnixMs,
      );
    case PairingMessage_Payload.desktopRendezvous:
      final rendezvous = message.desktopRendezvous;
      _validateFixedLength(rendezvous.rendezvousId, rendezvousIdBytes);
      if (utf8.encode(rendezvous.pairingCode).length !=
          desktopPairingCodeBytes) {
        _fail(ProtocolValidationErrorCode.invalidLength);
      }
      if (!RegExp(r'^[A-Z2-7]{8}$').hasMatch(rendezvous.pairingCode)) {
        _fail(ProtocolValidationErrorCode.invalidState);
      }
      validateDeviceIdentity(rendezvous.hostIdentity);
      _validateFixedLength(rendezvous.hostEphemeralPublicKey, publicKeyBytes);
      _validateRendezvousLifetime(
        rendezvous.issuedAtUnixMs,
        rendezvous.expiresAtUnixMs,
      );
    case PairingMessage_Payload.hello:
      _validateFixedLength(message.hello.rendezvousId, rendezvousIdBytes);
      validateDeviceIdentity(message.hello.identity);
      _validateFixedLength(message.hello.ephemeralPublicKey, publicKeyBytes);
    case PairingMessage_Payload.confirmation:
      _validatePairingConfirmation(message.confirmation);
    case PairingMessage_Payload.decision:
      final decision = message.decision;
      _validateEnum(decision.status, PairingDecisionStatus.values);
      if (decision.hasController()) {
        validateDeviceIdentity(decision.controller);
      }
      if (decision.hasConfirmation()) {
        _validatePairingConfirmation(decision.confirmation);
      }
      if (decision.hasGrant()) {
        _validateControllerGrant(decision.grant);
      }
    case PairingMessage_Payload.hostInvitation:
      _validateHostPairingInvitation(message.hostInvitation);
    case PairingMessage_Payload.controllerHello:
      _validateControllerPairingHello(message.controllerHello);
    case PairingMessage_Payload.encryptedEnvelope:
      _validateEncryptedPairingEnvelope(message.encryptedEnvelope);
    case PairingMessage_Payload.notSet:
      _fail(ProtocolValidationErrorCode.missingPayload);
  }
}

void _validateHostPairingInvitation(HostPairingInvitation invitation) {
  _validateProtocolVersionPresence(
    invitation.hasProtocolVersion(),
    invitation.protocolVersion,
  );
  _validateEnum(invitation.kind, PairingInvitationKind.values);
  _validateFixedLength(invitation.rendezvousId, rendezvousIdBytes);
  if (!invitation.hasHostIdentity()) {
    _fail(ProtocolValidationErrorCode.missingPayload);
  }
  validateDeviceIdentity(invitation.hostIdentity);
  _validateFixedLength(
    invitation.hostPublicKeyFingerprintSha256,
    nonceOrHashBytes,
  );
  _validateFixedLength(invitation.hostEphemeralPublicKey, publicKeyBytes);
  _validateUtf8Length(
    invitation.signalingEndpoint,
    maxSignalingEndpointUtf8Bytes,
  );
  switch (invitation.kind) {
    case PairingInvitationKind.PAIRING_INVITATION_KIND_QR:
      if (invitation.pairingCode.isNotEmpty) {
        _fail(ProtocolValidationErrorCode.invalidState);
      }
    case PairingInvitationKind.PAIRING_INVITATION_KIND_DESKTOP_CODE:
      _validateDesktopPairingCode(invitation.pairingCode);
    case PairingInvitationKind.PAIRING_INVITATION_KIND_UNSPECIFIED:
      _fail(ProtocolValidationErrorCode.invalidEnum);
  }
  _validateRendezvousLifetime(
    invitation.issuedAtUnixMs,
    invitation.expiresAtUnixMs,
  );
}

void _validateControllerPairingHello(ControllerPairingHello hello) {
  _validateFixedLength(hello.rendezvousId, rendezvousIdBytes);
  if (!hello.hasIdentity()) {
    _fail(ProtocolValidationErrorCode.missingPayload);
  }
  validateDeviceIdentity(hello.identity);
  _validateFixedLength(hello.ephemeralPublicKey, publicKeyBytes);
  _validateFixedLength(hello.transcriptSha256, nonceOrHashBytes);
  _validateFixedLength(hello.signature, signatureBytes);
}

void _validateEncryptedPairingEnvelope(EncryptedPairingEnvelope envelope) {
  _validateProtocolVersionPresence(
    envelope.hasProtocolVersion(),
    envelope.protocolVersion,
  );
  _validateFixedLength(envelope.rendezvousId, rendezvousIdBytes);
  _validateEnum(envelope.direction, PairingDirection.values);
  if (envelope.sequence <= Int64.ZERO ||
      envelope.ciphertext.isEmpty ||
      envelope.ciphertext.length > maxPairingCiphertextBytes) {
    _fail(ProtocolValidationErrorCode.invalidLength);
  }
}

void _validateDesktopPairingCode(String code) {
  if (utf8.encode(code).length != desktopPairingCodeBytes) {
    _fail(ProtocolValidationErrorCode.invalidLength);
  }
  if (!RegExp(r'^[A-Z2-7]{8}$').hasMatch(code)) {
    _fail(ProtocolValidationErrorCode.invalidState);
  }
}

void _validatePairingConfirmation(PairingConfirmationData confirmation) {
  _validateFixedLength(confirmation.controllerDeviceId, deviceIdBytes);
  _validateFixedLength(confirmation.hostDeviceId, deviceIdBytes);
  _validateFixedLength(confirmation.rendezvousId, rendezvousIdBytes);
  _validateFixedLength(
    confirmation.controllerIdentityPublicKey,
    publicKeyBytes,
  );
  _validateFixedLength(confirmation.hostIdentityPublicKey, publicKeyBytes);
  _validateFixedLength(
    confirmation.controllerEphemeralPublicKey,
    publicKeyBytes,
  );
  _validateFixedLength(confirmation.hostEphemeralPublicKey, publicKeyBytes);
  _validateFixedLength(confirmation.transcriptSha256, nonceOrHashBytes);
}

void _validateControllerGrant(ControllerGrant grant) {
  _validateFixedLength(grant.grantId, rendezvousIdBytes);
  _validateFixedLength(grant.hostDeviceId, deviceIdBytes);
  validateDeviceIdentity(grant.controller);
  _validateUniqueEnums(grant.permissions, SessionPermission.values, <int>{});
}

void _validateSessionAuthentication(SessionAuthentication authentication) {
  switch (authentication.whichPayload()) {
    case SessionAuthentication_Payload.offer:
      final offer = authentication.offer;
      _validateSessionAuthenticationBase(
        controllerDeviceId: offer.controllerDeviceId,
        hostDeviceId: offer.hostDeviceId,
        sessionId: offer.sessionId,
        nonce: offer.nonce,
        issuedAt: offer.issuedAtUnixMs,
        expiresAt: offer.expiresAtUnixMs,
        permissions: offer.requestedPermissions,
        offerHash: offer.offerSha256,
        controllerFingerprint: offer.controllerDtlsFingerprintSha256,
        signature: offer.signature,
      );
    case SessionAuthentication_Payload.answer:
      final answer = authentication.answer;
      _validateSessionAuthenticationBase(
        controllerDeviceId: answer.controllerDeviceId,
        hostDeviceId: answer.hostDeviceId,
        sessionId: answer.sessionId,
        nonce: answer.nonce,
        issuedAt: answer.issuedAtUnixMs,
        expiresAt: answer.expiresAtUnixMs,
        permissions: answer.requestedPermissions,
        offerHash: answer.offerSha256,
        controllerFingerprint: answer.controllerDtlsFingerprintSha256,
        signature: answer.signature,
      );
      _validateFixedLength(answer.answerSha256, nonceOrHashBytes);
      _validateFixedLength(answer.hostDtlsFingerprintSha256, nonceOrHashBytes);
    case SessionAuthentication_Payload.reconnect:
      final reconnect = authentication.reconnect;
      _validateSessionAuthenticationBase(
        controllerDeviceId: reconnect.controllerDeviceId,
        hostDeviceId: reconnect.hostDeviceId,
        sessionId: reconnect.sessionId,
        nonce: reconnect.nonce,
        issuedAt: reconnect.issuedAtUnixMs,
        expiresAt: reconnect.expiresAtUnixMs,
        permissions: reconnect.requestedPermissions,
        offerHash: reconnect.offerSha256,
        controllerFingerprint: reconnect.controllerDtlsFingerprintSha256,
        signature: reconnect.signature,
      );
      _validateFixedLength(reconnect.answerSha256, nonceOrHashBytes);
      _validateFixedLength(
        reconnect.hostDtlsFingerprintSha256,
        nonceOrHashBytes,
      );
    case SessionAuthentication_Payload.notSet:
      _fail(ProtocolValidationErrorCode.missingPayload);
  }
}

void _validateSessionAuthenticationBase({
  required List<int> controllerDeviceId,
  required List<int> hostDeviceId,
  required List<int> sessionId,
  required List<int> nonce,
  required Int64 issuedAt,
  required Int64 expiresAt,
  required Iterable<SessionPermission> permissions,
  required List<int> offerHash,
  required List<int> controllerFingerprint,
  required List<int> signature,
}) {
  _validateFixedLength(controllerDeviceId, deviceIdBytes);
  _validateFixedLength(hostDeviceId, deviceIdBytes);
  _validateFixedLength(sessionId, sessionIdBytes);
  _validateFixedLength(nonce, nonceOrHashBytes);
  _validateFixedLength(offerHash, nonceOrHashBytes);
  _validateFixedLength(controllerFingerprint, nonceOrHashBytes);
  _validateFixedLength(signature, signatureBytes);
  _validateUniqueEnums(permissions, SessionPermission.values, <int>{});
  if (expiresAt < issuedAt) {
    _fail(ProtocolValidationErrorCode.invalidLifetime);
  }
}

void _validateWebRtcNegotiation(WebRtcNegotiation negotiation) {
  if (negotiation.whichPayload() == WebRtcNegotiation_Payload.notSet) {
    _fail(ProtocolValidationErrorCode.missingPayload);
  }
  _validateFixedLength(negotiation.sessionId, sessionIdBytes);
  switch (negotiation.whichPayload()) {
    case WebRtcNegotiation_Payload.description:
      final description = negotiation.description;
      _validateFixedLength(description.dtlsFingerprintSha256, nonceOrHashBytes);
      _validateEnum(description.type, SessionDescriptionType.values);
      _validateUtf8Length(description.sdp, maxSdpUtf8Bytes);
    case WebRtcNegotiation_Payload.iceCandidate:
      _validateUtf8Length(
        negotiation.iceCandidate.candidate,
        maxIceCandidateUtf8Bytes,
      );
      _validateUtf8Length(negotiation.iceCandidate.sdpMid, maxSdpMidUtf8Bytes);
    case WebRtcNegotiation_Payload.endOfCandidates:
      break;
    case WebRtcNegotiation_Payload.notSet:
      _fail(ProtocolValidationErrorCode.missingPayload);
  }
}

void _validateReliableEvent(ReliableInputEnvelope envelope) {
  switch (envelope.whichEvent()) {
    case ReliableInputEnvelope_Event.pointerButton:
      _validateEnum(envelope.pointerButton.button, PointerButton.values);
      _validateEnum(envelope.pointerButton.action, ButtonAction.values);
    case ReliableInputEnvelope_Event.keyboard:
      _validateEnum(envelope.keyboard.action, KeyboardAction.values);
    case ReliableInputEnvelope_Event.text:
      _validateUtf8Length(envelope.text.text, maxTextInputUtf8Bytes);
    case ReliableInputEnvelope_Event.sessionControl:
      _validateEnum(
        envelope.sessionControl.action,
        SessionControlAction.values,
      );
    case ReliableInputEnvelope_Event.releaseAllInput:
      break;
    case ReliableInputEnvelope_Event.notSet:
      _fail(ProtocolValidationErrorCode.missingPayload);
  }
}

void _validateUnifiedError(UnifiedError error) {
  _validateEnum(error.code, ErrorCode.values);
  _validateUtf8Length(error.messageKey, maxMessageKeyUtf8Bytes);
  _validateUtf8Length(error.requestId, maxRequestIdUtf8Bytes);
  switch (error.whichDetails()) {
    case UnifiedError_Details.permission:
      _validateUtf8Length(error.permission.permission, maxErrorDetailUtf8Bytes);
    case UnifiedError_Details.codec:
      for (final codec in error.codec.supportedCodecs) {
        _validateUtf8Length(codec, maxErrorDetailUtf8Bytes);
      }
    case UnifiedError_Details.transport:
      _validateUtf8Length(error.transport.transport, maxErrorDetailUtf8Bytes);
    case UnifiedError_Details.retryAfter:
    case UnifiedError_Details.notSet:
      break;
  }
}

void _validateProtocolVersionPresence(bool isPresent, ProtocolVersion version) {
  if (!isPresent ||
      version.major != protocolMajorVersion ||
      version.minor < minimumProtocolMinorVersion) {
    _fail(ProtocolValidationErrorCode.invalidProtocolVersion);
  }
}

void _validateUniqueEnums<T extends pb.ProtobufEnum>(
  Iterable<T> values,
  List<T> allowed,
  Set<int> seen,
) {
  for (final value in values) {
    _validateEnum(value, allowed);
    if (!seen.add(value.value)) {
      _fail(ProtocolValidationErrorCode.duplicateValue);
    }
  }
}

void _validatePrivilegedBridgeFrameHeader(
  bool hasVersion,
  ProtocolVersion version,
  String requestId,
  Int64 sequence,
) {
  _validateProtocolVersionPresence(hasVersion, version);
  _validateUtf8Length(requestId, maxRequestIdUtf8Bytes);
  if (sequence == Int64.ZERO) {
    _fail(ProtocolValidationErrorCode.invalidState);
  }
}

void _validatePrivilegedSessionDescriptor(
  PrivilegedSessionDescriptor descriptor,
) {
  if (descriptor.platform != DevicePlatform.DEVICE_PLATFORM_WINDOWS &&
      descriptor.platform != DevicePlatform.DEVICE_PLATFORM_MACOS) {
    _fail(ProtocolValidationErrorCode.invalidEnum);
  }
  _validateEnum(descriptor.desktopKind, InteractiveDesktopKind.values);
  if (descriptor.osSessionId == Int64.ZERO ||
      descriptor.generation == Int64.ZERO) {
    _fail(ProtocolValidationErrorCode.invalidState);
  }
}

void _validateEnum<T extends pb.ProtobufEnum>(T value, List<T> allowed) {
  if (value.value == 0 || !allowed.contains(value)) {
    _fail(ProtocolValidationErrorCode.invalidEnum);
  }
}

void _validateRendezvousLifetime(Int64 issuedAt, Int64 expiresAt) {
  if (expiresAt < issuedAt ||
      expiresAt - issuedAt > Int64(pairingRendezvousLifetimeMs)) {
    _fail(ProtocolValidationErrorCode.invalidLifetime);
  }
}

void _validateEncodedLength(Uint8List encoded, int maximum) {
  if (encoded.length > maximum) {
    _fail(ProtocolValidationErrorCode.messageTooLarge);
  }
}

void _validateFixedLength(List<int> value, int expected) {
  if (value.length != expected) {
    _fail(ProtocolValidationErrorCode.invalidLength);
  }
}

void _validateUtf8Length(String value, int maximum) {
  if (utf8.encode(value).length > maximum) {
    _fail(ProtocolValidationErrorCode.invalidUtf8Length);
  }
}

T _decode<T>(T Function() decode) {
  try {
    return decode();
  } on Exception {
    _fail(ProtocolValidationErrorCode.invalidLength);
  }
}

Never _fail(ProtocolValidationErrorCode code) {
  throw ProtocolValidationException(code);
}
