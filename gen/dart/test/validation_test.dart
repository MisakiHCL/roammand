// SPDX-License-Identifier: Apache-2.0

import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:roammand_protocol/roammand_protocol.dart';
import 'package:test/test.dart';

void main() {
  group('session status validation', () {
    test('accepts CONNECTED with a 16-byte session ID', () {
      final status = SessionStatus(
        sessionId: _bytes(16),
        state: SessionState.SESSION_STATE_CONNECTED,
      );

      expect(() => validateSessionStatus(status), returnsNormally);
    });

    test('rejects unknown numeric SessionState', () {
      final encoded = <int>[
        ...SessionStatus(sessionId: _bytes(16)).writeToBuffer(),
        0x10,
        99,
      ];
      final status = SessionStatus.fromBuffer(encoded);

      expect(
        () => validateSessionStatus(status),
        _throwsValidation(ProtocolValidationErrorCode.invalidEnum),
      );
    });

    test('rejects FAILED without UnifiedError', () {
      final status = SessionStatus(
        sessionId: _bytes(16),
        state: SessionState.SESSION_STATE_FAILED,
      );

      expect(
        () => validateSessionStatus(status),
        _throwsValidation(ProtocolValidationErrorCode.invalidState),
      );
    });

    test('rejects active state without a 16-byte session ID', () {
      final status = SessionStatus(
        state: SessionState.SESSION_STATE_CONNECTING,
      );

      expect(
        () => validateSessionStatus(status),
        _throwsValidation(ProtocolValidationErrorCode.invalidLength),
      );
    });
  });

  group('remote session status snapshot validation', () {
    test('binds active state to one Controller device ID', () {
      final idle = RemoteSessionStatusSnapshot(
        sessionStatus: SessionStatus(state: SessionState.SESSION_STATE_IDLE),
      );
      final connected = RemoteSessionStatusSnapshot(
        sessionStatus: SessionStatus(
          sessionId: _bytes(16),
          state: SessionState.SESSION_STATE_CONNECTED,
        ),
        controllerDeviceId: _bytes(32),
      );

      expect(() => validateRemoteSessionStatusSnapshot(idle), returnsNormally);
      expect(
        () => validateRemoteSessionStatusSnapshot(
          idle.deepCopy()..controllerDeviceId = _bytes(32),
        ),
        _throwsValidation(ProtocolValidationErrorCode.invalidState),
      );
      expect(
        () => validateRemoteSessionStatusSnapshot(
          connected.deepCopy()..controllerDeviceId = _bytes(31),
        ),
        _throwsValidation(ProtocolValidationErrorCode.invalidLength),
      );
    });
  });

  test('rejects oversized signaling before decoding', () {
    expect(
      () => decodeAndValidateSignalingEnvelope(
        Uint8List(maxSignalingEnvelopeBytes + 1),
      ),
      _throwsValidation(ProtocolValidationErrorCode.messageTooLarge),
    );
  });

  test('rejects a 129-byte device display name', () {
    final identity = _validIdentity()..displayName = 'x' * 129;

    expect(
      () => validateDeviceIdentity(identity),
      _throwsValidation(ProtocolValidationErrorCode.invalidUtf8Length),
    );
  });

  test('rejects QR rendezvous lifetime above two minutes', () {
    final envelope = _validSignalingEnvelope()
      ..pairing = PairingMessage(
        qrRendezvous: QrPairingRendezvous(
          rendezvousId: _bytes(16),
          hostIdentity: _validIdentity(),
          hostPublicKeyFingerprintSha256: _bytes(32),
          hostEphemeralPublicKey: _bytes(32),
          signalingEndpoint: 'wss://signal.example.test',
          issuedAtUnixMs: Int64(1000),
          expiresAtUnixMs: Int64(121001),
        ),
      );

    expect(
      () => decodeAndValidateSignalingEnvelope(envelope.writeToBuffer()),
      _throwsValidation(ProtocolValidationErrorCode.invalidLifetime),
    );
  });

  test('rejects oversized reliable input before decoding', () {
    expect(
      () => decodeAndValidateReliableInputEnvelope(
        Uint8List(maxReliableInputEnvelopeBytes + 1),
      ),
      _throwsValidation(ProtocolValidationErrorCode.messageTooLarge),
    );
  });

  test('rejects oversized pointer-fast input before decoding', () {
    expect(
      () => decodeAndValidatePointerFastEnvelope(
        Uint8List(maxPointerFastEnvelopeBytes + 1),
      ),
      _throwsValidation(ProtocolValidationErrorCode.messageTooLarge),
    );
  });

  test('rejects signaling and input envelopes without oneof payloads', () {
    final signaling = _validSignalingEnvelope();
    final reliable = ReliableInputEnvelope(
      protocolVersion: _version(),
      sessionId: _bytes(16),
    );
    final pointerFast = PointerFastEnvelope(
      protocolVersion: _version(),
      sessionId: _bytes(16),
    );

    expect(
      () => decodeAndValidateSignalingEnvelope(signaling.writeToBuffer()),
      _throwsValidation(ProtocolValidationErrorCode.missingPayload),
    );
    expect(
      () => decodeAndValidateReliableInputEnvelope(reliable.writeToBuffer()),
      _throwsValidation(ProtocolValidationErrorCode.missingPayload),
    );
    expect(
      () => decodeAndValidatePointerFastEnvelope(pointerFast.writeToBuffer()),
      _throwsValidation(ProtocolValidationErrorCode.missingPayload),
    );
  });

  group('privileged bridge validation', () {
    test('accepts a controlled protected desktop status', () {
      final status = PrivilegedBridgeStatusSnapshot(
        state: PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_CONTROLLED,
        interactiveSession: _validPrivilegedSession(),
        helperConnected: true,
        activeControllerDisplayName: 'My phone',
      );

      expect(
        () => validatePrivilegedBridgeStatusSnapshot(status),
        returnsNormally,
      );
    });

    test('rejects READY without a connected helper', () {
      final status = PrivilegedBridgeStatusSnapshot(
        state: PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_READY,
        interactiveSession: _validPrivilegedSession(),
      );

      expect(
        () => validatePrivilegedBridgeStatusSnapshot(status),
        _throwsValidation(ProtocolValidationErrorCode.invalidState),
      );
    });

    test('rejects oversized and unsequenced bridge frames', () {
      expect(
        () => decodeAndValidatePrivilegedBridgeClientFrame(
          Uint8List(maxPrivilegedBridgeFrameBytes + 1),
        ),
        _throwsValidation(ProtocolValidationErrorCode.messageTooLarge),
      );
      final frame = PrivilegedBridgeClientFrame(
        protocolVersion: _version(),
        requestId: 'lease-1',
        sequence: Int64.ZERO,
        acquireLease: AcquirePrivilegedLeaseRequest(
          sessionId: _bytes(16),
          generation: Int64.ONE,
          permissions: <SessionPermission>[
            SessionPermission.SESSION_PERMISSION_VIEW_SCREEN,
          ],
          controllerDisplayName: 'My phone',
        ),
      );

      expect(
        () =>
            decodeAndValidatePrivilegedBridgeClientFrame(frame.writeToBuffer()),
        _throwsValidation(ProtocolValidationErrorCode.invalidState),
      );
    });
  });
}

Matcher _throwsValidation(ProtocolValidationErrorCode code) => throwsA(
  isA<ProtocolValidationException>().having(
    (error) => error.code,
    'code',
    code,
  ),
);

ProtocolVersion _version() => ProtocolVersion(major: 1, minor: 0);

DeviceIdentity _validIdentity() => DeviceIdentity(
  deviceId: _bytes(32),
  publicKeyAlgorithm: PublicKeyAlgorithm.PUBLIC_KEY_ALGORITHM_ED25519,
  publicKey: _bytes(32),
  displayName: 'Host',
  platform: DevicePlatform.DEVICE_PLATFORM_MACOS,
);

SignalingEnvelope _validSignalingEnvelope() => SignalingEnvelope(
  protocolVersion: _version(),
  senderDeviceId: _bytes(32),
  recipientDeviceId: _bytes(32),
  requestId: 'request-1',
);

PrivilegedSessionDescriptor _validPrivilegedSession() =>
    PrivilegedSessionDescriptor(
      platform: DevicePlatform.DEVICE_PLATFORM_MACOS,
      osSessionId: Int64(501),
      desktopKind: InteractiveDesktopKind.INTERACTIVE_DESKTOP_KIND_NORMAL,
      generation: Int64.ONE,
    );

Uint8List _bytes(int length) =>
    Uint8List.fromList(List<int>.generate(length, (index) => index & 0xff));
