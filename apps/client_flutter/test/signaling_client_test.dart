// SPDX-License-Identifier: MPL-2.0

import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/desktop/remote/signaling_client.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

final _deviceId = List<int>.filled(32, 0x31);
final _peerId = List<int>.filled(32, 0x41);
const _compiledInsecureLanSignalingRequested = bool.fromEnvironment(
  'ROAMMAND_ALLOW_INSECURE_LAN_SIGNALING',
);

void main() {
  test('registers, relays, heartbeats and routes binary protobuf', () {
    final protocol = DesktopSignalingProtocol(_deviceId);
    final registration = protocol.registration('register-1');
    expect(registration.register.deviceId, _deviceId);

    final registered = _serverFrame(
      'register-1',
      registered: RegistrationAccepted(
        deviceId: _deviceId,
        presenceExpiresAtUnixMs: Int64(2000),
      ),
    );
    final registeredEvent = protocol.handleBinary(
      Uint8List.fromList(registered.writeToBuffer()),
    );
    expect(registeredEvent, isA<SignalingRegistered>());

    final relay = protocol.relaySession(
      _peerId,
      List<int>.filled(128, 0x51),
      'relay-1',
    );
    expect(relay.relaySession.recipientDeviceId, _peerId);
    expect(relay.relaySession.opaqueEnvelope, hasLength(128));
    expect(protocol.heartbeat('heartbeat-1').hasHeartbeat(), isTrue);
    final heartbeatAcknowledged = protocol.handleBinary(
      _serverFrame(
        'heartbeat-1',
        heartbeatAcknowledged: HeartbeatAcknowledged(
          serverTimeUnixMs: Int64(1000),
          presenceExpiresAtUnixMs: Int64(46000),
        ),
      ).writeToBuffer(),
    );
    expect(
      (heartbeatAcknowledged as SignalingHeartbeatAcknowledged).requestId,
      'heartbeat-1',
    );

    final routed = _serverFrame(
      '',
      routedSession: RoutedSessionEnvelope(
        senderDeviceId: _peerId,
        opaqueEnvelope: List<int>.filled(64, 0x61),
      ),
    );
    final event = protocol.handleBinary(
      Uint8List.fromList(routed.writeToBuffer()),
    );
    expect(event, isA<SignalingRoutedSession>());
    final routedEvent = event as SignalingRoutedSession;
    expect(routedEvent.senderDeviceId, _peerId);
    expect(routedEvent.opaqueEnvelope, hasLength(64));
  });

  test('rejects state, correlation, version, limits and remote errors', () {
    final protocol = DesktopSignalingProtocol(_deviceId);
    expect(
      () => protocol.relaySession(_peerId, <int>[1], 'relay-1'),
      _throws(SignalingClientErrorCode.invalidState),
    );
    protocol.registration('register-1');

    final wrongId = _serverFrame(
      'other',
      registered: RegistrationAccepted(
        deviceId: _deviceId,
        presenceExpiresAtUnixMs: Int64(2000),
      ),
    );
    expect(
      () => protocol.handleBinary(wrongId.writeToBuffer()),
      _throws(SignalingClientErrorCode.correlationMismatch),
    );
    expect(
      () => protocol.handleBinary(Uint8List(maxSignalingServiceFrameBytes + 1)),
      _throws(SignalingClientErrorCode.frameTooLarge),
    );

    wrongId
      ..requestId = 'register-1'
      ..protocolVersion = ProtocolVersion(major: 99, minor: 0);
    expect(
      () => protocol.handleBinary(wrongId.writeToBuffer()),
      _throws(SignalingClientErrorCode.protocolUnsupported),
    );

    final remoteError = _serverFrame(
      'register-1',
      error: UnifiedError(
        code: ErrorCode.ERROR_CODE_PAIRING_RATE_LIMITED,
        messageKey: 'signaling.rate_limited',
        retryable: true,
        requestId: 'register-1',
      ),
    );
    final event = protocol.handleBinary(remoteError.writeToBuffer());
    expect(event, isA<SignalingRemoteError>());
    expect((event as SignalingRemoteError).retryable, isTrue);

    expect(
      () => protocol.relaySession(
        _peerId,
        Uint8List(maxOpaqueSignalingEnvelopeBytes + 1),
        'relay-2',
      ),
      _throws(SignalingClientErrorCode.opaqueEnvelopeTooLarge),
    );

    expect(
      () => DesktopSignalingProtocol(
        _deviceId,
      ).registration(List<String>.filled(33, 'é').join()),
      _throws(SignalingClientErrorCode.invalidRequestId),
    );
  });

  test('bounds the outbox and endpoint policy', () {
    final outbox = SignalingOutbox(2)
      ..tryPush(<int>[1])
      ..tryPush(<int>[2]);
    expect(
      () => outbox.tryPush(<int>[3]),
      _throws(SignalingClientErrorCode.queueFull),
    );
    expect(outbox.pop(), <int>[1]);
    expect(outbox.pop(), <int>[2]);
    expect(outbox.pop(), isNull);

    expect(
      () => validateSignalingEndpoint(
        Uri.parse('wss://signal.example.test/v1/ws'),
      ),
      returnsNormally,
    );
    expect(
      () => validateSignalingEndpoint(Uri.parse('ws://127.0.0.1:8080/v1/ws')),
      returnsNormally,
    );
    expect(
      () => validateSignalingEndpoint(
        Uri.parse('ws://signal.example.test/v1/ws'),
      ),
      _throws(SignalingClientErrorCode.insecureEndpoint),
    );
    expect(
      () => validateSignalingEndpointWithPolicy(
        Uri.parse('ws://192.168.3.168:8080/v1/ws'),
        allowInsecureLan: false,
      ),
      _throws(SignalingClientErrorCode.insecureEndpoint),
    );
    expect(
      () => validateSignalingEndpoint(
        Uri.parse('wss://user:secret@signal.example.test/v1/ws'),
      ),
      _throws(SignalingClientErrorCode.endpointCredentials),
    );
  });

  test('allows explicit insecure LAN signaling only for debug builds', () {
    expect(
      insecureLanSignalingEnabled(debugBuild: true, requested: true),
      isTrue,
    );
    expect(
      insecureLanSignalingEnabled(debugBuild: false, requested: true),
      isFalse,
    );
    expect(
      insecureLanSignalingEnabled(debugBuild: true, requested: false),
      isFalse,
    );

    for (final endpoint in <String>[
      'ws://10.0.0.8:8080/v1/ws',
      'ws://172.16.4.2:8080/v1/ws',
      'ws://172.31.255.254:8080/v1/ws',
      'ws://192.168.3.168:8080/v1/ws',
      'ws://[fd00::8]:8080/v1/ws',
    ]) {
      expect(
        () => validateSignalingEndpointWithPolicy(
          Uri.parse(endpoint),
          allowInsecureLan: true,
        ),
        returnsNormally,
        reason: endpoint,
      );
    }

    for (final endpoint in <String>[
      'ws://172.15.255.254:8080/v1/ws',
      'ws://172.32.0.1:8080/v1/ws',
      'ws://8.8.8.8:8080/v1/ws',
      'ws://signal.example.test:8080/v1/ws',
      'ws://[2001:4860:4860::8888]:8080/v1/ws',
    ]) {
      expect(
        () => validateSignalingEndpointWithPolicy(
          Uri.parse(endpoint),
          allowInsecureLan: true,
        ),
        _throws(SignalingClientErrorCode.insecureEndpoint),
        reason: endpoint,
      );
    }
  });

  test('applies the compiled Debug LAN opt-in to the public validator', () {
    expect(
      () =>
          validateSignalingEndpoint(Uri.parse('ws://192.168.3.168:8080/v1/ws')),
      _compiledInsecureLanSignalingRequested
          ? returnsNormally
          : _throws(SignalingClientErrorCode.insecureEndpoint),
    );
  });
}

Matcher _throws(SignalingClientErrorCode code) => throwsA(
  isA<SignalingClientException>().having((error) => error.code, 'code', code),
);

SignalingServerFrame _serverFrame(
  String requestId, {
  RegistrationAccepted? registered,
  HeartbeatAcknowledged? heartbeatAcknowledged,
  RoutedSessionEnvelope? routedSession,
  UnifiedError? error,
}) => SignalingServerFrame(
  protocolVersion: ProtocolVersion(major: 1, minor: 0),
  requestId: requestId,
  registered: registered,
  heartbeatAcknowledged: heartbeatAcknowledged,
  routedSession: routedSession,
  error: error,
);
