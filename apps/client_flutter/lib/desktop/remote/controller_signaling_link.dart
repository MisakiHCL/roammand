// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:typed_data';

import 'signaling_client.dart';

const _defaultHeartbeatInterval = Duration(seconds: 20);
const _transportConnectTimeout = Duration(seconds: 10);
const _registrationTimeout = Duration(seconds: 5);
const _defaultTransportShutdownTimeout = Duration(seconds: 2);

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
    Duration transportConnectTimeout = _transportConnectTimeout,
    Duration registrationTimeout = _registrationTimeout,
    Duration heartbeatInterval = _defaultHeartbeatInterval,
    Duration transportShutdownTimeout = _defaultTransportShutdownTimeout,
  }) => WebSocketControllerSignalingLink._(
    endpoint,
    requestIdFactory,
    transportFactory ?? WebSocketSignalingTransport.connect,
    transportConnectTimeout,
    registrationTimeout,
    heartbeatInterval,
    transportShutdownTimeout,
  );

  WebSocketControllerSignalingLink._(
    this.endpoint,
    this._requestIdFactory,
    this._transportFactory,
    this.transportConnectTimeout,
    this.registrationTimeout,
    this.heartbeatInterval,
    this.transportShutdownTimeout,
  ) : assert(transportConnectTimeout > Duration.zero),
      assert(registrationTimeout > Duration.zero),
      assert(heartbeatInterval > Duration.zero),
      assert(transportShutdownTimeout > Duration.zero);

  final Uri endpoint;
  final String Function()? _requestIdFactory;
  final Future<SignalingTransport> Function(Uri endpoint) _transportFactory;
  final Duration transportConnectTimeout;
  final Duration registrationTimeout;
  final Duration heartbeatInterval;
  final Duration transportShutdownTimeout;
  final StreamController<SignalingRoutedSession> _routed =
      StreamController<SignalingRoutedSession>.broadcast();
  SignalingTransport? _transport;
  DesktopSignalingProtocol? _protocol;
  Uint8List? _controllerDeviceId;
  Timer? _heartbeatTimer;
  Future<void>? _receiveTask;
  Future<void>? _recoveryFuture;
  String? _pendingHeartbeatRequestId;
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
    final transport = await _connectTransport();
    if (_closed || generation != _transportGeneration) {
      await _closeLateTransport(transport, transportShutdownTimeout);
      throw const SignalingClientException(SignalingClientErrorCode.closed);
    }
    _protocol = protocol;
    _transport = transport;
    try {
      transport.send(protocol.registration(_requestId('register')));
      final registrationFrame = await transport.receiveBinary().timeout(
        registrationTimeout,
        onTimeout: () => throw const SignalingClientException(
          SignalingClientErrorCode.timeout,
        ),
      );
      if (_closed || generation != _transportGeneration) {
        throw const SignalingClientException(SignalingClientErrorCode.closed);
      }
      final registered = protocol.handleBinary(registrationFrame);
      if (registered is! SignalingRegistered) {
        throw const SignalingClientException(
          SignalingClientErrorCode.unexpectedPayload,
        );
      }
      _receiveTask = _receiveLoop(transport, protocol, generation);
      _heartbeatTimer = Timer.periodic(
        heartbeatInterval,
        (_) => _sendHeartbeat(generation),
      );
    } catch (_) {
      await _resetTransport();
      rethrow;
    }
  }

  Future<SignalingTransport> _connectTransport() async {
    final pending = _transportFactory(endpoint);
    return pending.timeout(
      transportConnectTimeout,
      onTimeout: () {
        // Future.timeout cannot cancel the underlying socket attempt. If it
        // completes later, close that unowned transport immediately.
        unawaited(
          pending.then<void>(
            (transport) =>
                _closeLateTransport(transport, transportShutdownTimeout),
            onError: (_) {},
          ),
        );
        throw const SignalingClientException(SignalingClientErrorCode.timeout);
      },
    );
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
            _reportFailure(
              generation,
              SignalingRemoteException(
                code: event.code,
                retryable: event.retryable,
              ),
            );
          case SignalingHeartbeatAcknowledged(:final requestId):
            if (requestId != _pendingHeartbeatRequestId) {
              throw const SignalingClientException(
                SignalingClientErrorCode.correlationMismatch,
              );
            }
            _pendingHeartbeatRequestId = null;
          case SignalingRegistered():
            break;
        }
      }
    } catch (error) {
      if (!_closed && generation == _transportGeneration) {
        _reportFailure(
          generation,
          error is SignalingClientException ? error : null,
        );
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
    if (_pendingHeartbeatRequestId != null) {
      _reportFailure(
        generation,
        const SignalingClientException(SignalingClientErrorCode.timeout),
      );
      return;
    }
    try {
      final requestId = _requestId('heartbeat');
      _pendingHeartbeatRequestId = requestId;
      transport.send(protocol.heartbeat(requestId));
    } catch (_) {
      _pendingHeartbeatRequestId = null;
      if (!_closed && generation == _transportGeneration) {
        _reportFailure(generation);
      }
    }
  }

  void _reportFailure(int generation, [Object? cause]) {
    if (_reportedFailureGeneration == generation || _routed.isClosed) {
      return;
    }
    _reportedFailureGeneration = generation;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _routed.addError(
      cause ??
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
    _pendingHeartbeatRequestId = null;
    final transport = _transport;
    _transport = null;
    _protocol = null;
    final receiveTask = _receiveTask;
    _receiveTask = null;
    var transportClosed = true;
    try {
      await transport?.close().timeout(transportShutdownTimeout);
    } catch (_) {
      // A failed close may leave receiveBinary blocked indefinitely. The
      // generation gate still prevents that stale task from publishing.
      transportClosed = false;
    }
    if (receiveTask != null && transportClosed) {
      try {
        await receiveTask.timeout(transportShutdownTimeout);
      } catch (_) {}
    }
  }
}

Future<void> _closeLateTransport(
  SignalingTransport transport,
  Duration timeout,
) async {
  try {
    await transport.close().timeout(timeout);
  } catch (_) {
    // This transport no longer belongs to a live connection generation.
  }
}
