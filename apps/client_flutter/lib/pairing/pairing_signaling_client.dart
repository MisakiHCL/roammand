// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:roammand/desktop/remote/signaling_client.dart';
import 'package:roammand_protocol/roammand_protocol.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'desktop_pairing_code.dart';

const _webSocketSubprotocol = 'roammand-signaling.v1.protobuf';
const _legacyWebSocketSubprotocol = 'personal-remote-signaling.v1.protobuf';
const _requestIdBytes = 64;
const _rememberedRequestIds = 64;
const _defaultRequestTimeout = Duration(seconds: 5);
const _defaultHeartbeatInterval = Duration(seconds: 15);

enum PairingSignalingErrorCode {
  invalidState,
  invalidInput,
  invalidFrame,
  protocolUnsupported,
  correlationMismatch,
  unexpectedPeer,
  frameTooLarge,
  remote,
  timeout,
  transport,
  subprotocolRequired,
  closed,
}

final class PairingSignalingException implements Exception {
  const PairingSignalingException(this.code);

  final PairingSignalingErrorCode code;

  @override
  String toString() => 'PairingSignalingException(${code.name})';
}

final class PairingSignalingJoin {
  PairingSignalingJoin({
    required List<int> rendezvousId,
    required List<int> hostDeviceId,
    required this.expiresAtUnixMs,
  }) : rendezvousId = Uint8List.fromList(rendezvousId),
       hostDeviceId = Uint8List.fromList(hostDeviceId);

  final Uint8List rendezvousId;
  final Uint8List hostDeviceId;
  final int expiresAtUnixMs;
}

sealed class PairingSignalingEvent {
  const PairingSignalingEvent();
}

final class PairingSignalingRouted extends PairingSignalingEvent {
  PairingSignalingRouted({
    required List<int> rendezvousId,
    required List<int> senderDeviceId,
    required List<int> opaqueEnvelope,
  }) : rendezvousId = Uint8List.fromList(rendezvousId),
       senderDeviceId = Uint8List.fromList(senderDeviceId),
       opaqueEnvelope = Uint8List.fromList(opaqueEnvelope);

  final Uint8List rendezvousId;
  final Uint8List senderDeviceId;
  final Uint8List opaqueEnvelope;
}

final class PairingSignalingClosed extends PairingSignalingEvent {
  PairingSignalingClosed({
    required List<int> rendezvousId,
    required this.completion,
  }) : rendezvousId = Uint8List.fromList(rendezvousId);

  final Uint8List rendezvousId;
  final PairingRendezvousCompletion completion;
}

final class PairingSignalingRemoteError extends PairingSignalingEvent {
  const PairingSignalingRemoteError({
    required this.code,
    required this.retryable,
  });

  final ErrorCode code;
  final bool retryable;
}

abstract interface class PairingSignalingTransport {
  Stream<Uint8List> get frames;

  Future<void> send(Uint8List frame);

  Future<void> close();
}

typedef PairingSignalingConnector =
    Future<PairingSignalingTransport> Function(Uri endpoint);

abstract interface class ControllerPairingSignalingLink {
  Stream<PairingSignalingEvent> get events;

  Future<void> connect(Uri endpoint, List<int> controllerDeviceId);

  Future<PairingSignalingJoin> joinQr(List<int> rendezvousId);

  Future<PairingSignalingJoin> joinDesktopCode(String pairingCode);

  Future<void> relay(List<int> rendezvousId, Uint8List opaqueEnvelope);

  Future<void> close();
}

final class WebSocketPairingSignalingTransport
    implements PairingSignalingTransport {
  WebSocketPairingSignalingTransport._(this._channel);

  final WebSocketChannel _channel;
  bool _closed = false;

  static Future<PairingSignalingTransport> connect(Uri endpoint) async {
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
        throw const PairingSignalingException(
          PairingSignalingErrorCode.subprotocolRequired,
        );
      }
      return WebSocketPairingSignalingTransport._(channel);
    } on PairingSignalingException {
      rethrow;
    } catch (_) {
      throw const PairingSignalingException(
        PairingSignalingErrorCode.transport,
      );
    }
  }

  @override
  Stream<Uint8List> get frames => _channel.stream.map((message) {
    if (message is! List<int>) {
      throw const PairingSignalingException(
        PairingSignalingErrorCode.invalidFrame,
      );
    }
    return Uint8List.fromList(message);
  });

  @override
  Future<void> send(Uint8List frame) async {
    if (_closed) {
      throw const PairingSignalingException(PairingSignalingErrorCode.closed);
    }
    _channel.sink.add(frame);
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await _channel.sink.close();
  }
}

enum _ClientState { disconnected, connecting, ready, joining, joined, closed }

final class PairingSignalingClient implements ControllerPairingSignalingLink {
  PairingSignalingClient({
    PairingSignalingConnector? connector,
    String Function()? requestIdFactory,
    this.requestTimeout = _defaultRequestTimeout,
    this.heartbeatInterval = _defaultHeartbeatInterval,
  }) : _connector = connector ?? WebSocketPairingSignalingTransport.connect,
       // ignore: prefer_initializing_formals, keeps the public argument readable.
       _requestIdFactory = requestIdFactory,
       assert(heartbeatInterval > Duration.zero);

  final PairingSignalingConnector _connector;
  final String Function()? _requestIdFactory;
  final Duration requestTimeout;
  final Duration heartbeatInterval;
  final StreamController<PairingSignalingEvent> _events =
      StreamController<PairingSignalingEvent>.broadcast(sync: true);
  final Queue<String> _issuedRequestOrder = Queue<String>();
  final Set<String> _issuedRequestIds = <String>{};
  final Set<String> _heartbeatRequestIds = <String>{};
  _ClientState _state = _ClientState.disconnected;
  PairingSignalingTransport? _transport;
  StreamSubscription<Uint8List>? _subscription;
  Completer<void>? _registration;
  String? _registrationRequestId;
  Completer<PairingSignalingJoin>? _join;
  String? _joinRequestId;
  Uint8List? _expectedRendezvousId;
  Uint8List? _controllerDeviceId;
  PairingSignalingJoin? _active;
  Timer? _heartbeatTimer;
  Future<void>? _closeFuture;
  int _requestSequence = 0;

  @override
  Stream<PairingSignalingEvent> get events => _events.stream;

  @override
  Future<void> connect(Uri endpoint, List<int> controllerDeviceId) async {
    if (_state != _ClientState.disconnected ||
        controllerDeviceId.length != deviceIdBytes) {
      throw const PairingSignalingException(
        PairingSignalingErrorCode.invalidState,
      );
    }
    validateSignalingEndpoint(endpoint);
    _state = _ClientState.connecting;
    _controllerDeviceId = Uint8List.fromList(controllerDeviceId);
    try {
      final transport = await _connector(endpoint);
      _transport = transport;
      _subscription = transport.frames.listen(
        _onFrame,
        onError: (_) => _fail(
          const PairingSignalingException(PairingSignalingErrorCode.transport),
        ),
        onDone: () => _fail(
          const PairingSignalingException(PairingSignalingErrorCode.closed),
        ),
      );
      final requestId = _nextRequestId();
      _registrationRequestId = requestId;
      _registration = Completer<void>();
      await _send(
        SignalingClientFrame(
          protocolVersion: _version(),
          requestId: requestId,
          register: RegisterDevice(deviceId: _controllerDeviceId),
        ),
      );
      await _registration!.future.timeout(
        requestTimeout,
        onTimeout: () => throw const PairingSignalingException(
          PairingSignalingErrorCode.timeout,
        ),
      );
      _state = _ClientState.ready;
      _heartbeatTimer = Timer.periodic(
        heartbeatInterval,
        (_) => _sendHeartbeat(),
      );
    } on PairingSignalingException {
      await close();
      rethrow;
    } catch (_) {
      await close();
      throw const PairingSignalingException(
        PairingSignalingErrorCode.transport,
      );
    }
  }

  @override
  Future<PairingSignalingJoin> joinQr(List<int> rendezvousId) {
    if (rendezvousId.length != rendezvousIdBytes) {
      throw const PairingSignalingException(
        PairingSignalingErrorCode.invalidInput,
      );
    }
    return _joinRendezvous(
      JoinPairingRendezvous(rendezvousId: rendezvousId),
      Uint8List.fromList(rendezvousId),
    );
  }

  @override
  Future<PairingSignalingJoin> joinDesktopCode(String pairingCode) =>
      _joinRendezvous(
        JoinPairingRendezvous(
          pairingCode: normalizeDesktopPairingCode(pairingCode),
        ),
        null,
      );

  Future<PairingSignalingJoin> _joinRendezvous(
    JoinPairingRendezvous request,
    Uint8List? expectedRendezvousId,
  ) async {
    if (_state != _ClientState.ready) {
      throw const PairingSignalingException(
        PairingSignalingErrorCode.invalidState,
      );
    }
    _state = _ClientState.joining;
    final requestId = _nextRequestId();
    _joinRequestId = requestId;
    _expectedRendezvousId = expectedRendezvousId;
    _join = Completer<PairingSignalingJoin>();
    try {
      await _send(
        SignalingClientFrame(
          protocolVersion: _version(),
          requestId: requestId,
          joinRendezvous: request,
        ),
      );
      final joined = await _join!.future.timeout(
        requestTimeout,
        onTimeout: () => throw const PairingSignalingException(
          PairingSignalingErrorCode.timeout,
        ),
      );
      _active = joined;
      _state = _ClientState.joined;
      return joined;
    } on PairingSignalingException {
      await close();
      rethrow;
    }
  }

  @override
  Future<void> relay(List<int> rendezvousId, Uint8List opaqueEnvelope) async {
    final active = _active;
    if (_state != _ClientState.joined ||
        active == null ||
        !_bytesEqual(rendezvousId, active.rendezvousId) ||
        opaqueEnvelope.isEmpty ||
        opaqueEnvelope.length > maxOpaqueSignalingEnvelopeBytes) {
      throw const PairingSignalingException(
        PairingSignalingErrorCode.invalidState,
      );
    }
    await _send(
      SignalingClientFrame(
        protocolVersion: _version(),
        requestId: _nextRequestId(),
        relayPairing: RelayPairingEnvelope(
          rendezvousId: rendezvousId,
          opaqueEnvelope: opaqueEnvelope,
        ),
      ),
    );
  }

  Future<void> _send(SignalingClientFrame frame) async {
    final encoded = frame.writeToBuffer();
    if (encoded.length > maxSignalingServiceFrameBytes) {
      throw const PairingSignalingException(
        PairingSignalingErrorCode.frameTooLarge,
      );
    }
    _rememberRequestId(frame.requestId);
    final transport = _transport;
    if (transport == null) {
      throw const PairingSignalingException(PairingSignalingErrorCode.closed);
    }
    try {
      await transport.send(Uint8List.fromList(encoded));
    } catch (_) {
      throw const PairingSignalingException(
        PairingSignalingErrorCode.transport,
      );
    }
  }

  void _onFrame(Uint8List encoded) {
    try {
      if (encoded.length > maxSignalingServiceFrameBytes) {
        throw const PairingSignalingException(
          PairingSignalingErrorCode.frameTooLarge,
        );
      }
      final frame = SignalingServerFrame.fromBuffer(encoded);
      if (!_bytesEqual(frame.writeToBuffer(), encoded)) {
        throw const PairingSignalingException(
          PairingSignalingErrorCode.invalidFrame,
        );
      }
      _handleFrame(frame);
    } on PairingSignalingException catch (error) {
      _fail(error);
    } catch (_) {
      _fail(
        const PairingSignalingException(PairingSignalingErrorCode.invalidFrame),
      );
    }
  }

  void _handleFrame(SignalingServerFrame frame) {
    if (!frame.hasProtocolVersion() ||
        frame.protocolVersion.major != protocolMajorVersion ||
        frame.protocolVersion.minor < minimumProtocolMinorVersion) {
      throw const PairingSignalingException(
        PairingSignalingErrorCode.protocolUnsupported,
      );
    }
    if (frame.hasError()) {
      _handleRemoteError(frame);
      return;
    }
    if (frame.hasHeartbeatAcknowledged()) {
      _handleHeartbeatAcknowledged(frame);
      return;
    }
    switch (_state) {
      case _ClientState.connecting:
        _handleRegistration(frame);
      case _ClientState.joining:
        _handleJoined(frame);
      case _ClientState.joined:
        _handleEvent(frame);
      case _ClientState.disconnected:
      case _ClientState.ready:
      case _ClientState.closed:
        throw const PairingSignalingException(
          PairingSignalingErrorCode.invalidState,
        );
    }
  }

  void _handleRegistration(SignalingServerFrame frame) {
    final requestId = _registrationRequestId;
    if (!frame.hasRegistered() ||
        requestId == null ||
        frame.requestId != requestId ||
        !_bytesEqual(frame.registered.deviceId, _controllerDeviceId!)) {
      throw const PairingSignalingException(
        PairingSignalingErrorCode.correlationMismatch,
      );
    }
    _forgetRequestId(requestId);
    _registration?.complete();
  }

  void _handleHeartbeatAcknowledged(SignalingServerFrame frame) {
    final acknowledged = frame.heartbeatAcknowledged;
    if (!_canHeartbeat ||
        frame.requestId.isEmpty ||
        !_issuedRequestIds.contains(frame.requestId) ||
        !_heartbeatRequestIds.remove(frame.requestId) ||
        acknowledged.serverTimeUnixMs <= 0 ||
        acknowledged.presenceExpiresAtUnixMs <= acknowledged.serverTimeUnixMs) {
      throw const PairingSignalingException(
        PairingSignalingErrorCode.correlationMismatch,
      );
    }
    _forgetRequestId(frame.requestId);
  }

  void _handleJoined(SignalingServerFrame frame) {
    final requestId = _joinRequestId;
    if (!frame.hasRendezvousJoined() ||
        requestId == null ||
        frame.requestId != requestId) {
      throw const PairingSignalingException(
        PairingSignalingErrorCode.correlationMismatch,
      );
    }
    final joined = frame.rendezvousJoined;
    if (joined.rendezvousId.length != rendezvousIdBytes ||
        joined.peerDeviceId.length != deviceIdBytes ||
        joined.expiresAtUnixMs <= 0 ||
        _bytesEqual(joined.peerDeviceId, _controllerDeviceId!) ||
        (_expectedRendezvousId != null &&
            !_bytesEqual(joined.rendezvousId, _expectedRendezvousId!))) {
      throw const PairingSignalingException(
        PairingSignalingErrorCode.correlationMismatch,
      );
    }
    _forgetRequestId(requestId);
    _join?.complete(
      PairingSignalingJoin(
        rendezvousId: joined.rendezvousId,
        hostDeviceId: joined.peerDeviceId,
        expiresAtUnixMs: joined.expiresAtUnixMs.toInt(),
      ),
    );
  }

  void _handleEvent(SignalingServerFrame frame) {
    final active = _active!;
    if (frame.requestId.isNotEmpty) {
      throw const PairingSignalingException(
        PairingSignalingErrorCode.correlationMismatch,
      );
    }
    if (frame.hasRoutedPairing()) {
      final routed = frame.routedPairing;
      if (!_bytesEqual(routed.rendezvousId, active.rendezvousId) ||
          !_bytesEqual(routed.senderDeviceId, active.hostDeviceId) ||
          routed.opaqueEnvelope.isEmpty ||
          routed.opaqueEnvelope.length > maxOpaqueSignalingEnvelopeBytes) {
        throw const PairingSignalingException(
          PairingSignalingErrorCode.unexpectedPeer,
        );
      }
      _events.add(
        PairingSignalingRouted(
          rendezvousId: routed.rendezvousId,
          senderDeviceId: routed.senderDeviceId,
          opaqueEnvelope: routed.opaqueEnvelope,
        ),
      );
      return;
    }
    if (frame.hasRendezvousClosed()) {
      final closed = frame.rendezvousClosed;
      if (!_bytesEqual(closed.rendezvousId, active.rendezvousId) ||
          closed.completion ==
              PairingRendezvousCompletion
                  .PAIRING_RENDEZVOUS_COMPLETION_UNSPECIFIED) {
        throw const PairingSignalingException(
          PairingSignalingErrorCode.invalidFrame,
        );
      }
      _active = null;
      _events.add(
        PairingSignalingClosed(
          rendezvousId: closed.rendezvousId,
          completion: closed.completion,
        ),
      );
      return;
    }
    throw const PairingSignalingException(
      PairingSignalingErrorCode.invalidFrame,
    );
  }

  void _handleRemoteError(SignalingServerFrame frame) {
    if (frame.requestId.isEmpty ||
        frame.error.requestId != frame.requestId ||
        !_issuedRequestIds.contains(frame.requestId) ||
        frame.error.code == ErrorCode.ERROR_CODE_UNSPECIFIED) {
      throw const PairingSignalingException(
        PairingSignalingErrorCode.correlationMismatch,
      );
    }
    _forgetRequestId(frame.requestId);
    final error = const PairingSignalingException(
      PairingSignalingErrorCode.remote,
    );
    if (frame.requestId == _registrationRequestId &&
        !(_registration?.isCompleted ?? true)) {
      _registration?.completeError(error);
      return;
    }
    if (frame.requestId == _joinRequestId && !(_join?.isCompleted ?? true)) {
      _join?.completeError(error);
      return;
    }
    _events.add(
      PairingSignalingRemoteError(
        code: frame.error.code,
        retryable: frame.error.retryable,
      ),
    );
  }

  void _fail(PairingSignalingException error) {
    if (_state == _ClientState.closed) {
      return;
    }
    if (!(_registration?.isCompleted ?? true)) {
      _registration?.completeError(error);
    }
    if (!(_join?.isCompleted ?? true)) {
      _join?.completeError(error);
    }
    if (!_events.isClosed) {
      _events.addError(error);
    }
    unawaited(close());
  }

  bool get _canHeartbeat => switch (_state) {
    _ClientState.ready || _ClientState.joining || _ClientState.joined => true,
    _ClientState.disconnected ||
    _ClientState.connecting ||
    _ClientState.closed => false,
  };

  void _sendHeartbeat() {
    if (!_canHeartbeat) return;
    unawaited(_sendHeartbeatFrame());
  }

  Future<void> _sendHeartbeatFrame() async {
    final requestId = _nextRequestId();
    _heartbeatRequestIds.add(requestId);
    try {
      await _send(
        SignalingClientFrame(
          protocolVersion: _version(),
          requestId: requestId,
          heartbeat: Heartbeat(),
        ),
      );
    } on PairingSignalingException catch (error) {
      _heartbeatRequestIds.remove(requestId);
      _fail(error);
    } catch (_) {
      _heartbeatRequestIds.remove(requestId);
      _fail(
        const PairingSignalingException(PairingSignalingErrorCode.transport),
      );
    }
  }

  @override
  Future<void> close() => _closeFuture ??= _close();

  Future<void> _close() async {
    _state = _ClientState.closed;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    await _transport?.close();
    _transport = null;
    _active = null;
    _controllerDeviceId?.fillRange(0, _controllerDeviceId!.length, 0);
    _controllerDeviceId = null;
    _issuedRequestIds.clear();
    _issuedRequestOrder.clear();
    _heartbeatRequestIds.clear();
    if (!_events.isClosed) {
      await _events.close();
    }
  }

  String _nextRequestId() {
    final value = _requestIdFactory?.call() ?? 'pairing-${_requestSequence++}';
    if (value.isEmpty || utf8.encode(value).length > _requestIdBytes) {
      throw const PairingSignalingException(
        PairingSignalingErrorCode.invalidInput,
      );
    }
    return value;
  }

  void _rememberRequestId(String requestId) {
    if (_issuedRequestIds.add(requestId)) {
      _issuedRequestOrder.addLast(requestId);
    }
    while (_issuedRequestOrder.length > _rememberedRequestIds) {
      final forgotten = _issuedRequestOrder.removeFirst();
      _issuedRequestIds.remove(forgotten);
      _heartbeatRequestIds.remove(forgotten);
    }
  }

  void _forgetRequestId(String requestId) {
    _issuedRequestIds.remove(requestId);
    _issuedRequestOrder.remove(requestId);
    _heartbeatRequestIds.remove(requestId);
  }
}

ProtocolVersion _version() => ProtocolVersion(
  major: protocolMajorVersion,
  minor: minimumProtocolMinorVersion,
);

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
