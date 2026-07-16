// SPDX-License-Identifier: Apache-2.0

import 'package:roammand_protocol/roammand_protocol.dart';
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

void main() {
  test('generated protocol version is type safe', () {
    final version = ProtocolVersion(major: 1, minor: 0);

    expect(version.major, 1);
    expect(version.minor, 0);
  });

  test('generated local IPC frames are type safe', () {
    final frame = LocalIpcClientFrame(
      protocolVersion: ProtocolVersion(major: 1, minor: 0),
      requestId: 'status-1',
      getHostStatus: GetHostStatusRequest(),
    );

    expect(frame.whichPayload(), LocalIpcClientFrame_Payload.getHostStatus);
    expect(maxLocalIpcFrameBytes, 65536);
    expect(localIpcTokenBytes, 32);
    expect(agentInstanceIdBytes, 16);
    expect(maxControllerGrants, 256);
    expect(maxHostAuthorizationSnapshotBytes, 1048576);
  });

  test('generated remote session IPC types are role specific', () {
    final signRequest = LocalIpcClientFrame(
      protocolVersion: ProtocolVersion(major: 1, minor: 0),
      requestId: 'sign-offer-1',
      signSessionOffer: SignSessionOfferRequest(
        canonicalTranscript: List<int>.filled(128, 0x11),
      ),
    );
    final signature = SessionOfferSignature(
      controllerDeviceId: List<int>.filled(32, 0x11),
      controllerPublicKey: List<int>.filled(32, 0x11),
      signature: List<int>.filled(64, 0x11),
      transcriptSha256: List<int>.filled(32, 0x11),
    );
    final statusRequest = GetRemoteSessionStatusRequest();
    final snapshot = RemoteSessionStatusSnapshot(
      sessionStatus: SessionStatus(state: SessionState.SESSION_STATE_IDLE),
    );

    expect(
      signRequest.whichPayload(),
      LocalIpcClientFrame_Payload.signSessionOffer,
    );
    expect(signature.signature, hasLength(64));
    expect(statusRequest, isA<GetRemoteSessionStatusRequest>());
    expect(snapshot.sessionStatus.state, SessionState.SESSION_STATE_IDLE);
  });

  test('generated pairing and host trust types are role specific', () {
    final hello = ControllerPairingHello(
      rendezvousId: List<int>.filled(16, 0x11),
      identity: DeviceIdentity(displayName: 'Controller'),
      ephemeralPublicKey: List<int>.filled(32, 0x22),
      transcriptSha256: List<int>.filled(32, 0x33),
      signature: List<int>.filled(64, 0x44),
    );
    final envelope = EncryptedPairingEnvelope(
      direction: PairingDirection.PAIRING_DIRECTION_CONTROLLER_TO_HOST,
      sequence: Int64.ONE,
      ciphertext: List<int>.filled(48, 0x55),
    );
    final request = LocalIpcClientFrame(
      protocolVersion: ProtocolVersion(major: 1, minor: 0),
      requestId: 'pairing-sign-1',
      signPairingTranscript: SignPairingTranscriptRequest(
        canonicalTranscript: List<int>.filled(256, 0x66),
        role: PairingIdentityRole.PAIRING_IDENTITY_ROLE_CONTROLLER,
      ),
    );
    final snapshot = TrustedHostSnapshot(
      protocolVersion: ProtocolVersion(major: 1, minor: 0),
      bindings: <TrustedHostBinding>[TrustedHostBinding()],
    );

    expect(hello.signature, hasLength(64));
    expect(envelope.sequence, Int64.ONE);
    expect(
      request.whichPayload(),
      LocalIpcClientFrame_Payload.signPairingTranscript,
    );
    expect(snapshot.bindings, hasLength(1));
  });
}
