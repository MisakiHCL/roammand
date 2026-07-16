// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:typed_data';

import 'signaling_client.dart';

const _heartbeatInterval = Duration(seconds: 20);

abstract interface class ControllerSignalingLink {
  Stream<SignalingRoutedSession> get routedSessions;

  Future<void> connect(List<int> controllerDeviceId);

  Future<void> recover();

  Future<void> relay(List<int> hostDeviceId, Uint8List opaqueEnvelope);

  Future<void> close();
}

final class WebSocketControllerSignalingLink
    implements ControllerSignalingLink {
  factory WebSocketControllerSignalingLink({
    required Uri endpoint,
    String Function()? requestIdFactory,
    Future<SignalingTransport> Function(Uri endpoint)? transportFactory,
  }) => WebSocketControllerSignalingLink._(
    endpoint,
    requestIdFactory,
    transportFactory ?? WebSocketSignalingTransport.connect,
  );

  WebSocketControllerSignalingLink._(
    this.endpoint,
    this._requestIdFactory,
    this._transportFactory,
  );

  final Uri endpoint;
  final String Function()? _requestIdFactory;
  final Future<SignalingTransport> Function(Uri endpoint) _transportFactory;
  final StreamController<SignalingRoutedSession> _routed =
      StreamController<SignalingRoutedSession>.broadcast();
  SignalingTransport? _transport;
  DesktopSignalingProtocol? _protocol;
  Uint8List? _controllerDeviceId;
  Timer? _heartbeatTimer;
  Future<void>? _receiveTask;
  Future<void>? _recoveryFuture;
  bool _closed = false;
  int _transportGeneration = 0;
  int _reportedFailureGeneration = 0;
  int _sequence = 0;

  @override
  Stream<SignalingRoutedSession> get routedSessions => _routed.stream;

  @override
  Future<void> connect(List<int> controllerDeviceId) async {
    if (_transport != null || _controllerDeviceId != null || _closed) {
      throw const SignalingClientException(
        SignalingClientErrorCode.invalidState,
      );
    }
    _controllerDeviceId = Uint8List.fromList(controllerDeviceId);
    try {
      await _openTransport();
    } catch (_) {
      _controllerDeviceId = null;
      await _resetTransport();
      rethrow;
    }
  }

  Future<void> _openTransport() async {
    if (_closed || _controllerDeviceId == null || _transport != null) {
      throw const SignalingClientException(
        SignalingClientErrorCode.invalidState,
      );
    }
    final generation = ++_transportGeneration;
    final protocol = DesktopSignalingProtocol(_controllerDeviceId!);
    final transport = await _transportFactory(endpoint);
    if (_closed || generation != _transportGeneration) {
      await transport.close();
      throw const SignalingClientException(SignalingClientErrorCode.closed);
    }
    _protocol = protocol;
    _transport = transport;
    try {
      transport.send(protocol.registration(_requestId('register')));
      final registered = protocol.handleBinary(await transport.receiveBinary());
      if (registered is! SignalingRegistered) {
        throw const SignalingClientException(
          SignalingClientErrorCode.unexpectedPayload,
        );
      }
      _receiveTask = _receiveLoop(transport, protocol, generation);
      _heartbeatTimer = Timer.periodic(
        _heartbeatInterval,
        (_) => _sendHeartbeat(generation),
      );
    } catch (_) {
      await _resetTransport();
      rethrow;
    }
  }

  @override
  Future<void> recover() {
    final existing = _recoveryFuture;
    if (existing != null) {
      return existing;
    }
    if (_closed || _controllerDeviceId == null) {
      return Future<void>.error(
        const SignalingClientException(SignalingClientErrorCode.closed),
      );
    }
    final recovery = _recoverTransport();
    _recoveryFuture = recovery;
    return recovery;
  }

  Future<void> _recoverTransport() async {
    try {
      await _resetTransport();
      await _openTransport();
    } finally {
      _recoveryFuture = null;
    }
  }

  @override
  Future<void> relay(List<int> hostDeviceId, Uint8List opaqueEnvelope) async {
    final transport = _transport;
    final protocol = _protocol;
    if (_closed || transport == null || protocol == null) {
      throw const SignalingClientException(SignalingClientErrorCode.closed);
    }
    transport.send(
      protocol.relaySession(hostDeviceId, opaqueEnvelope, _requestId('relay')),
    );
  }

  Future<void> _receiveLoop(
    SignalingTransport transport,
    DesktopSignalingProtocol protocol,
    int generation,
  ) async {
    try {
      while (!_closed && generation == _transportGeneration) {
        final event = protocol.handleBinary(await transport.receiveBinary());
        if (_closed || generation != _transportGeneration) {
          return;
        }
        switch (event) {
          case SignalingRoutedSession():
            _routed.add(event);
          case SignalingRemoteError():
            _reportFailure(generation);
          case SignalingRegistered():
          case SignalingHeartbeatAcknowledged():
            break;
        }
      }
    } catch (_) {
      if (!_closed && generation == _transportGeneration) {
        _reportFailure(generation);
      }
    }
  }

  void _sendHeartbeat(int generation) {
    final transport = _transport;
    final protocol = _protocol;
    if (_closed ||
        generation != _transportGeneration ||
        transport == null ||
        protocol == null) {
      return;
    }
    try {
      transport.send(protocol.heartbeat(_requestId('heartbeat')));
    } catch (_) {
      if (!_closed && generation == _transportGeneration) {
        _reportFailure(generation);
      }
    }
  }

  void _reportFailure(int generation) {
    if (_reportedFailureGeneration == generation || _routed.isClosed) {
      return;
    }
    _reportedFailureGeneration = generation;
    _routed.addError(
      const SignalingClientException(SignalingClientErrorCode.transport),
    );
  }

  String _requestId(String prefix) =>
      _requestIdFactory?.call() ?? '$prefix-${++_sequence}';

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _controllerDeviceId = null;
    await _resetTransport();
    final recovery = _recoveryFuture;
    if (recovery != null) {
      try {
        await recovery;
      } catch (_) {}
    }
    await _routed.close();
  }

  Future<void> _resetTransport() async {
    _transportGeneration += 1;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    final transport = _transport;
    _transport = null;
    _protocol = null;
    final receiveTask = _receiveTask;
    _receiveTask = null;
    await transport?.close();
    if (receiveTask != null) {
      try {
        await receiveTask;
      } catch (_) {}
    }
  }
}
