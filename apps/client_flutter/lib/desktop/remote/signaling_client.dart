// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:roammand_protocol/roammand_protocol.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const _allowInsecureLanSignalingEnvironment =
    'ROAMMAND_ALLOW_INSECURE_LAN_SIGNALING';
const _allowInsecureLanSignalingRequested = bool.fromEnvironment(
  _allowInsecureLanSignalingEnvironment,
);
const _deviceIdBytes = 32;
const _maximumRequestIdBytes = 64;
const _maximumSignalingEndpointBytes = 2048;
const _webSocketSubprotocol = 'roammand-signaling.v1.protobuf';
const _legacyWebSocketSubprotocol = 'personal-remote-signaling.v1.protobuf';

enum SignalingClientErrorCode {
  invalidDeviceId,
  invalidRequestId,
  invalidState,
  correlationMismatch,
  frameTooLarge,
  opaqueEnvelopeTooLarge,
  invalidFrame,
  protocolUnsupported,
  unexpectedPayload,
  invalidErrorCode,
  invalidQueueCapacity,
  queueFull,
  invalidEndpoint,
  insecureEndpoint,
  endpointCredentials,
  transport,
  subprotocolRequired,
  closed,
}

final class SignalingClientException implements Exception {
  const SignalingClientException(this.code);

  final SignalingClientErrorCode code;

  @override
  String toString() => 'SignalingClientException(${code.name})';
}

final class SignalingRemoteException implements Exception {
  const SignalingRemoteException({required this.code, required this.retryable});

  final ErrorCode code;
  final bool retryable;

  @override
  String toString() =>
      'SignalingRemoteException(${code.name}, retryable=$retryable)';
}

sealed class SignalingEvent {
  const SignalingEvent();
}

final class SignalingRegistered extends SignalingEvent {
  const SignalingRegistered(this.presenceExpiresAtUnixMs);

  final int presenceExpiresAtUnixMs;
}

final class SignalingHeartbeatAcknowledged extends SignalingEvent {
  const SignalingHeartbeatAcknowledged({
    required this.serverTimeUnixMs,
    required this.presenceExpiresAtUnixMs,
  });

  final int serverTimeUnixMs;
  final int presenceExpiresAtUnixMs;
}

final class SignalingRoutedSession extends SignalingEvent {
  SignalingRoutedSession({
    required List<int> senderDeviceId,
    required List<int> opaqueEnvelope,
  }) : senderDeviceId = Uint8List.fromList(senderDeviceId),
       opaqueEnvelope = Uint8List.fromList(opaqueEnvelope);

  final Uint8List senderDeviceId;
  final Uint8List opaqueEnvelope;
}

final class SignalingRemoteError extends SignalingEvent {
  const SignalingRemoteError({required this.code, required this.retryable});

  final ErrorCode code;
  final bool retryable;
}

enum _ProtocolState { disconnected, registering, ready }

final class DesktopSignalingProtocol {
  DesktopSignalingProtocol(List<int> deviceId)
    : _deviceId = Uint8List.fromList(deviceId) {
    if (_deviceId.length != _deviceIdBytes) {
      _fail(SignalingClientErrorCode.invalidDeviceId);
    }
  }

  final Uint8List _deviceId;
  _ProtocolState _state = _ProtocolState.disconnected;
  String? _registrationRequestId;

  SignalingClientFrame registration(String requestId) {
    if (_state != _ProtocolState.disconnected) {
      _fail(SignalingClientErrorCode.invalidState);
    }
    _validateRequestId(requestId);
    _state = _ProtocolState.registering;
    _registrationRequestId = requestId;
    return _clientFrame(
      requestId,
      register: RegisterDevice(deviceId: _deviceId),
    );
  }

  SignalingClientFrame relaySession(
    List<int> recipientDeviceId,
    List<int> opaqueEnvelope,
    String requestId,
  ) {
    if (opaqueEnvelope.length > maxOpaqueSignalingEnvelopeBytes) {
      _fail(SignalingClientErrorCode.opaqueEnvelopeTooLarge);
    }
    if (_state != _ProtocolState.ready) {
      _fail(SignalingClientErrorCode.invalidState);
    }
    if (recipientDeviceId.length != _deviceIdBytes) {
      _fail(SignalingClientErrorCode.invalidDeviceId);
    }
    _validateRequestId(requestId);
    return _clientFrame(
      requestId,
      relaySession: RelaySessionEnvelope(
        recipientDeviceId: recipientDeviceId,
        opaqueEnvelope: opaqueEnvelope,
      ),
    );
  }

  SignalingClientFrame heartbeat(String requestId) {
    if (_state != _ProtocolState.ready) {
      _fail(SignalingClientErrorCode.invalidState);
    }
    _validateRequestId(requestId);
    return _clientFrame(requestId, heartbeat: Heartbeat());
  }

  SignalingEvent handleBinary(List<int> encoded) {
    if (encoded.length > maxSignalingServiceFrameBytes) {
      _fail(SignalingClientErrorCode.frameTooLarge);
    }
    late final SignalingServerFrame frame;
    try {
      frame = SignalingServerFrame.fromBuffer(encoded);
    } catch (_) {
      _fail(SignalingClientErrorCode.invalidFrame);
    }
    if (!frame.hasProtocolVersion() ||
        frame.protocolVersion.major != protocolMajorVersion) {
      _fail(SignalingClientErrorCode.protocolUnsupported);
    }
    switch (frame.whichPayload()) {
      case SignalingServerFrame_Payload.registered:
        if (_state != _ProtocolState.registering) {
          _fail(SignalingClientErrorCode.invalidState);
        }
        if (frame.requestId != _registrationRequestId) {
          _fail(SignalingClientErrorCode.correlationMismatch);
        }
        if (!_bytesEqual(frame.registered.deviceId, _deviceId)) {
          _fail(SignalingClientErrorCode.invalidDeviceId);
        }
        _state = _ProtocolState.ready;
        return SignalingRegistered(
          frame.registered.presenceExpiresAtUnixMs.toInt(),
        );
      case SignalingServerFrame_Payload.heartbeatAcknowledged:
        if (_state != _ProtocolState.ready) {
          _fail(SignalingClientErrorCode.invalidState);
        }
        _validateRequestId(frame.requestId);
        return SignalingHeartbeatAcknowledged(
          serverTimeUnixMs: frame.heartbeatAcknowledged.serverTimeUnixMs
              .toInt(),
          presenceExpiresAtUnixMs: frame
              .heartbeatAcknowledged
              .presenceExpiresAtUnixMs
              .toInt(),
        );
      case SignalingServerFrame_Payload.routedSession:
        if (_state != _ProtocolState.ready) {
          _fail(SignalingClientErrorCode.invalidState);
        }
        final routed = frame.routedSession;
        if (frame.requestId.isNotEmpty ||
            routed.senderDeviceId.length != _deviceIdBytes) {
          _fail(SignalingClientErrorCode.invalidFrame);
        }
        if (routed.opaqueEnvelope.length > maxOpaqueSignalingEnvelopeBytes) {
          _fail(SignalingClientErrorCode.opaqueEnvelopeTooLarge);
        }
        return SignalingRoutedSession(
          senderDeviceId: routed.senderDeviceId,
          opaqueEnvelope: routed.opaqueEnvelope,
        );
      case SignalingServerFrame_Payload.error:
        if (frame.error.code == ErrorCode.ERROR_CODE_UNSPECIFIED) {
          _fail(SignalingClientErrorCode.invalidErrorCode);
        }
        return SignalingRemoteError(
          code: frame.error.code,
          retryable: frame.error.retryable,
        );
      case SignalingServerFrame_Payload.notSet:
      case SignalingServerFrame_Payload.presenceResult:
      case SignalingServerFrame_Payload.rendezvousCreated:
      case SignalingServerFrame_Payload.rendezvousJoined:
      case SignalingServerFrame_Payload.routedPairing:
      case SignalingServerFrame_Payload.rendezvousClosed:
        _fail(SignalingClientErrorCode.unexpectedPayload);
    }
  }
}

final class SignalingOutbox {
  SignalingOutbox(this.capacity) {
    if (capacity <= 0) {
      _fail(SignalingClientErrorCode.invalidQueueCapacity);
    }
  }

  final int capacity;
  final Queue<Uint8List> _frames = Queue<Uint8List>();

  void tryPush(List<int> frame) {
    if (frame.length > maxSignalingServiceFrameBytes) {
      _fail(SignalingClientErrorCode.frameTooLarge);
    }
    if (_frames.length >= capacity) {
      _fail(SignalingClientErrorCode.queueFull);
    }
    _frames.add(Uint8List.fromList(frame));
  }

  Uint8List? pop() => _frames.isEmpty ? null : _frames.removeFirst();
}

abstract interface class SignalingTransport {
  void send(SignalingClientFrame frame);

  Future<Uint8List> receiveBinary();

  Future<void> close();
}

final class WebSocketSignalingTransport implements SignalingTransport {
  WebSocketSignalingTransport._(this._channel)
    : _iterator = StreamIterator<Object?>(_channel.stream);

  final WebSocketChannel _channel;
  final StreamIterator<Object?> _iterator;
  bool _closed = false;

  static Future<WebSocketSignalingTransport> connect(Uri endpoint) async {
    validateSignalingEndpoint(endpoint);
    try {
      final channel = WebSocketChannel.connect(
        endpoint,
        protocols: const <String>[
          _webSocketSubprotocol,
          _legacyWebSocketSubprotocol,
        ],
      );
      await channel.ready;
      if (channel.protocol != _webSocketSubprotocol &&
          channel.protocol != _legacyWebSocketSubprotocol) {
        await channel.sink.close();
        _fail(SignalingClientErrorCode.subprotocolRequired);
      }
      return WebSocketSignalingTransport._(channel);
    } on SignalingClientException {
      rethrow;
    } catch (_) {
      _fail(SignalingClientErrorCode.transport);
    }
  }

  @override
  void send(SignalingClientFrame frame) {
    if (_closed) {
      _fail(SignalingClientErrorCode.closed);
    }
    final encoded = frame.writeToBuffer();
    if (encoded.length > maxSignalingServiceFrameBytes) {
      _fail(SignalingClientErrorCode.frameTooLarge);
    }
    _channel.sink.add(Uint8List.fromList(encoded));
  }

  @override
  Future<Uint8List> receiveBinary() async {
    if (_closed) {
      _fail(SignalingClientErrorCode.closed);
    }
    try {
      if (!await _iterator.moveNext()) {
        _fail(SignalingClientErrorCode.closed);
      }
      final message = _iterator.current;
      if (message is! List<int>) {
        _fail(SignalingClientErrorCode.invalidFrame);
      }
      if (message.length > maxSignalingServiceFrameBytes) {
        _fail(SignalingClientErrorCode.frameTooLarge);
      }
      return Uint8List.fromList(message);
    } on SignalingClientException {
      rethrow;
    } catch (_) {
      _fail(SignalingClientErrorCode.transport);
    }
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    var cleanupFailed = false;
    try {
      await _iterator.cancel();
    } catch (_) {
      // The socket sink still owns resources when iterator cancellation fails.
      cleanupFailed = true;
    }
    try {
      await _channel.sink.close();
    } catch (_) {
      cleanupFailed = true;
    }
    if (cleanupFailed) {
      throw const SignalingClientException(SignalingClientErrorCode.transport);
    }
  }
}

void validateSignalingEndpoint(Uri endpoint) {
  validateSignalingEndpointWithPolicy(
    endpoint,
    allowInsecureLan: insecureLanSignalingEnabled(
      debugBuild: kDebugMode,
      requested: _allowInsecureLanSignalingRequested,
    ),
  );
}

bool insecureLanSignalingEnabled({
  required bool debugBuild,
  required bool requested,
}) => debugBuild && requested;

void validateSignalingEndpointWithPolicy(
  Uri endpoint, {
  required bool allowInsecureLan,
}) {
  if (endpoint.toString().length > _maximumSignalingEndpointBytes ||
      !endpoint.hasAuthority ||
      endpoint.host.isEmpty) {
    _fail(SignalingClientErrorCode.invalidEndpoint);
  }
  if (endpoint.userInfo.isNotEmpty) {
    _fail(SignalingClientErrorCode.endpointCredentials);
  }
  if (endpoint.scheme == 'wss') {
    return;
  }
  if (endpoint.scheme == 'ws' && _isLoopback(endpoint.host)) {
    return;
  }
  if (endpoint.scheme == 'ws' &&
      allowInsecureLan &&
      _isPrivateNetworkAddress(endpoint.host)) {
    return;
  }
  if (endpoint.scheme == 'ws') {
    _fail(SignalingClientErrorCode.insecureEndpoint);
  }
  _fail(SignalingClientErrorCode.invalidEndpoint);
}

bool _isLoopback(String host) {
  if (host.toLowerCase() == 'localhost') {
    return true;
  }
  return InternetAddress.tryParse(host)?.isLoopback ?? false;
}

bool _isPrivateNetworkAddress(String host) {
  final address = InternetAddress.tryParse(host);
  if (address == null) return false;
  final bytes = address.rawAddress;
  if (address.type == InternetAddressType.IPv4) {
    return bytes[0] == 10 ||
        (bytes[0] == 172 && bytes[1] >= 16 && bytes[1] <= 31) ||
        (bytes[0] == 192 && bytes[1] == 168);
  }
  return address.type == InternetAddressType.IPv6 &&
      bytes.isNotEmpty &&
      bytes[0] & 0xfe == 0xfc;
}

SignalingClientFrame _clientFrame(
  String requestId, {
  RegisterDevice? register,
  Heartbeat? heartbeat,
  RelaySessionEnvelope? relaySession,
}) => SignalingClientFrame(
  protocolVersion: ProtocolVersion(
    major: protocolMajorVersion,
    minor: minimumProtocolMinorVersion,
  ),
  requestId: requestId,
  register: register,
  heartbeat: heartbeat,
  relaySession: relaySession,
);

void _validateRequestId(String requestId) {
  if (requestId.isEmpty || requestId.length > _maximumRequestIdBytes) {
    _fail(SignalingClientErrorCode.invalidRequestId);
  }
}

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

Never _fail(SignalingClientErrorCode code) =>
    throw SignalingClientException(code);
