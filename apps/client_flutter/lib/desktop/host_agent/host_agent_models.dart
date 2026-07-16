// SPDX-License-Identifier: MPL-2.0

import 'dart:async';

import 'package:roammand_protocol/roammand_protocol.dart';

abstract interface class HostAgentSessionIdentityPort {
  Future<void> connect();

  Future<HostStatus> getHostStatus();

  Future<SessionOfferSignature> signSessionOffer(List<int> canonicalTranscript);

  Future<void> close();
}

abstract interface class HostAgentApi implements HostAgentSessionIdentityPort {
  Stream<SessionTerminatedEvent> get sessionTerminations;

  Stream<HostPairingStatusSnapshot> get hostPairingStates;

  Stream<PrivilegedBridgeStatusSnapshot> get privilegedBridgeStates;

  Future<List<ControllerGrantView>> listControllerGrants();

  Future<ControllerGrantView> createControllerGrant(
    DeviceIdentity controller,
    Iterable<SessionPermission> permissions,
  );

  Future<ControllerGrantRevoked> revokeControllerGrant(List<int> grantId);

  Future<EmergencyStopRemoteSessionResult> emergencyStopRemoteSession();

  Future<CanonicalTranscriptSignature> signCanonicalTranscript(
    List<int> canonicalTranscript,
  );

  Future<PairingTranscriptSignature> signPairingTranscript(
    List<int> canonicalTranscript,
    PairingIdentityRole role,
  );

  Future<HostPairingStatusSnapshot> startHostQrPairing(
    String signalingEndpoint,
  );

  Future<HostPairingStatusSnapshot> startHostDesktopCodePairing(
    String signalingEndpoint,
  );

  Future<HostPairingStatusSnapshot> getHostPairingStatus();

  Future<HostPairingStatusSnapshot> cancelHostPairing(List<int> rendezvousId);

  Future<HostPairingStatusSnapshot> acceptHostPairing(
    List<int> rendezvousId,
    List<int> controllerDeviceId,
  );

  Future<HostPairingStatusSnapshot> rejectHostPairing(
    List<int> rendezvousId,
    List<int> controllerDeviceId,
  );
}

sealed class HostAgentException implements Exception {
  const HostAgentException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class HostAgentProtocolException extends HostAgentException {
  const HostAgentProtocolException([
    super.message = 'Host Agent protocol failed',
  ]);
}

final class HostAgentTimeoutException extends HostAgentException {
  const HostAgentTimeoutException([
    super.message = 'Host Agent request timed out',
  ]);
}

final class HostAgentBusyException extends HostAgentException {
  const HostAgentBusyException([super.message = 'Host Agent client is busy']);
}

final class HostAgentDisconnectedException extends HostAgentException {
  const HostAgentDisconnectedException([
    super.message = 'Host Agent disconnected',
  ]);
}

final class HostAgentRemoteException extends HostAgentException {
  HostAgentRemoteException(this.error) : super(error.messageKey);

  final UnifiedError error;
}
