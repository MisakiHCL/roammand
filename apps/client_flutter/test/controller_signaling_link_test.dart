// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/desktop/remote/remote_desktop_controller.dart';
import 'package:roammand/desktop/remote/signaling_client.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

final _controllerId = List<int>.filled(32, 0x31);
final _hostId = List<int>.filled(32, 0x41);

void main() {
  test('recovers WSS registration without closing the routed stream', () async {
    final first = _FakeSignalingTransport()..enqueue(_registered('request-1'));
    final second = _FakeSignalingTransport()..enqueue(_registered('request-2'));
    final transports = Queue<_FakeSignalingTransport>.of(
      <_FakeSignalingTransport>[first, second],
    );
    var factoryCalls = 0;
    var requestSequence = 0;
    final link = WebSocketControllerSignalingLink(
      endpoint: Uri.parse('wss://signal.example.test/v1/connect'),
      requestIdFactory: () => 'request-${++requestSequence}',
      transportFactory: (_) async {
        factoryCalls += 1;
        return transports.removeFirst();
      },
    );
    final routed = <SignalingRoutedSession>[];
    final errors = <Object>[];
    final subscription = link.routedSessions.listen(
      routed.add,
      onError: errors.add,
    );

    await link.connect(_controllerId);
    first.emit(_routed(0x51));
    await pumpEventQueue();
    expect(routed, hasLength(1));

    first.fail();
    await pumpEventQueue();
    expect(errors, hasLength(1));

    final recovery = link.recover();
    final coalesced = link.recover();
    expect(identical(recovery, coalesced), isTrue);
    await recovery;
    expect(factoryCalls, 2);
    expect(first.closeCount, 1);

    second.emit(_routed(0x61));
    await pumpEventQueue();
    expect(routed, hasLength(2));
    expect(routed.last.opaqueEnvelope, List<int>.filled(8, 0x61));
    expect(errors, hasLength(1));

    await link.close();
    await link.close();
    await subscription.cancel();
    expect(second.closeCount, 1);
  });

  test('preserves a stable remote signaling error for diagnostics', () async {
    final transport = _FakeSignalingTransport()
      ..enqueue(_registered('request-1'));
    var requestSequence = 0;
    final link = WebSocketControllerSignalingLink(
      endpoint: Uri.parse('wss://signal.example.test/v1/connect'),
      requestIdFactory: () => 'request-${++requestSequence}',
      transportFactory: (_) async => transport,
    );
    final errors = <Object>[];
    final subscription = link.routedSessions.listen(
      (_) {},
      onError: errors.add,
    );

    await link.connect(_controllerId);
    transport.emit(
      SignalingServerFrame(
        protocolVersion: ProtocolVersion(major: 1, minor: 0),
        requestId: 'relay-1',
        error: UnifiedError(
          code: ErrorCode.ERROR_CODE_DEVICE_OFFLINE,
          retryable: true,
        ),
      ),
    );
    await pumpEventQueue();

    expect(errors, hasLength(1));
    final error = errors.single as SignalingRemoteException;
    expect(error.code, ErrorCode.ERROR_CODE_DEVICE_OFFLINE);
    expect(error.retryable, isTrue);
    expect(error.toString(), contains('ERROR_CODE_DEVICE_OFFLINE'));

    await link.close();
    await subscription.cancel();
  });

  test('closes the routed stream when transport cleanup fails', () async {
    final transport = _FakeSignalingTransport()
      ..enqueue(_registered('request-1'))
      ..failClose = true;
    final link = WebSocketControllerSignalingLink(
      endpoint: Uri.parse('wss://signal.example.test/v1/connect'),
      requestIdFactory: () => 'request-1',
      transportFactory: (_) async => transport,
    );

    await link.connect(_controllerId);
    await link.close();

    expect(transport.closeCount, 1);
    await expectLater(link.routedSessions, emitsDone);
  });

  test('a late registration response cannot revive a closed link', () async {
    final transport = _FakeSignalingTransport()
      ..keepPendingReceiveOnClose = true;
    final link = WebSocketControllerSignalingLink(
      endpoint: Uri.parse('wss://signal.example.test/v1/connect'),
      requestIdFactory: () => 'request-1',
      transportFactory: (_) async => transport,
    );
    final connecting = link.connect(_controllerId);
    final connectResult = expectLater(
      connecting,
      throwsA(
        isA<SignalingClientException>().having(
          (error) => error.code,
          'code',
          SignalingClientErrorCode.closed,
        ),
      ),
    );
    while (transport.sent.isEmpty) {
      await Future<void>.delayed(Duration.zero);
    }

    await link.close();
    transport.emit(_registered('request-1'));
    await connectResult;

    expect(transport.closeCount, 1);
    await expectLater(link.routedSessions, emitsDone);
  });

  test('bounds transport creation and closes a late transport', () async {
    final pending = Completer<SignalingTransport>();
    final link = WebSocketControllerSignalingLink(
      endpoint: Uri.parse('wss://signal.example.test/v1/connect'),
      transportConnectTimeout: const Duration(milliseconds: 10),
      transportFactory: (_) => pending.future,
    );

    await expectLater(
      link.connect(_controllerId),
      throwsA(
        isA<SignalingClientException>().having(
          (error) => error.code,
          'code',
          SignalingClientErrorCode.timeout,
        ),
      ),
    );

    final lateTransport = _FakeSignalingTransport();
    pending.complete(lateTransport);
    await pumpEventQueue();
    expect(lateTransport.closeCount, 1);
    await link.close();
  });

  test('bounds registration response time and closes transport', () async {
    final transport = _FakeSignalingTransport();
    final link = WebSocketControllerSignalingLink(
      endpoint: Uri.parse('wss://signal.example.test/v1/connect'),
      registrationTimeout: const Duration(milliseconds: 10),
      transportFactory: (_) async => transport,
    );

    await expectLater(
      link.connect(_controllerId),
      throwsA(
        isA<SignalingClientException>().having(
          (error) => error.code,
          'code',
          SignalingClientErrorCode.timeout,
        ),
      ),
    );

    expect(transport.sent.single.hasRegister(), isTrue);
    expect(transport.closeCount, 1);
    await link.close();
  });

  test(
    'fails a half-open connection when a heartbeat is not acknowledged',
    () async {
      final transport = _FakeSignalingTransport()
        ..enqueue(_registered('request-1'));
      var requestSequence = 0;
      final link = WebSocketControllerSignalingLink(
        endpoint: Uri.parse('wss://signal.example.test/v1/connect'),
        requestIdFactory: () => 'request-${++requestSequence}',
        heartbeatInterval: const Duration(milliseconds: 10),
        transportFactory: (_) async => transport,
      );
      final failure = expectLater(
        link.routedSessions,
        emitsError(
          isA<SignalingClientException>().having(
            (error) => error.code,
            'code',
            SignalingClientErrorCode.timeout,
          ),
        ),
      );

      await link.connect(_controllerId);
      await failure.timeout(const Duration(seconds: 1));

      expect(
        transport.sent.where((frame) => frame.hasHeartbeat()),
        hasLength(1),
      );
      await link.close();
    },
  );

  test(
    'rejects a heartbeat acknowledgement with the wrong request ID',
    () async {
      final transport = _FakeSignalingTransport()
        ..enqueue(_registered('request-1'));
      var requestSequence = 0;
      final link = WebSocketControllerSignalingLink(
        endpoint: Uri.parse('wss://signal.example.test/v1/connect'),
        requestIdFactory: () => 'request-${++requestSequence}',
        heartbeatInterval: const Duration(milliseconds: 20),
        transportFactory: (_) async => transport,
      );
      final failure = expectLater(
        link.routedSessions,
        emitsError(
          isA<SignalingClientException>().having(
            (error) => error.code,
            'code',
            SignalingClientErrorCode.correlationMismatch,
          ),
        ),
      );

      await link.connect(_controllerId);
      while (!transport.sent.any((frame) => frame.hasHeartbeat())) {
        await Future<void>.delayed(Duration.zero);
      }
      transport.emit(
        SignalingServerFrame(
          protocolVersion: ProtocolVersion(major: 1, minor: 0),
          requestId: 'stale-heartbeat',
          heartbeatAcknowledged: HeartbeatAcknowledged(
            serverTimeUnixMs: Int64(1000),
            presenceExpiresAtUnixMs: Int64(46000),
          ),
        ),
      );
      await failure.timeout(const Duration(seconds: 1));

      await link.close();
    },
  );

  test('bounds cleanup of a stale transport generation', () async {
    final transportGate = Completer<SignalingTransport>();
    final transport = _FakeSignalingTransport()..closeGate = Completer<void>();
    final link = WebSocketControllerSignalingLink(
      endpoint: Uri.parse('wss://signal.example.test/v1/connect'),
      transportShutdownTimeout: const Duration(milliseconds: 10),
      transportFactory: (_) => transportGate.future,
    );
    final connecting = link.connect(_controllerId);

    await link.close();
    transportGate.complete(transport);

    await expectLater(
      connecting,
      throwsA(
        isA<SignalingClientException>().having(
          (error) => error.code,
          'code',
          SignalingClientErrorCode.closed,
        ),
      ),
    ).timeout(const Duration(seconds: 1));
    expect(transport.closeCount, 1);
    transport.closeGate?.complete();
  });
}

SignalingServerFrame _registered(String requestId) => SignalingServerFrame(
  protocolVersion: ProtocolVersion(major: 1, minor: 0),
  requestId: requestId,
  registered: RegistrationAccepted(
    deviceId: _controllerId,
    presenceExpiresAtUnixMs: Int64(1900000060000),
  ),
);

SignalingServerFrame _routed(int byte) => SignalingServerFrame(
  protocolVersion: ProtocolVersion(major: 1, minor: 0),
  routedSession: RoutedSessionEnvelope(
    senderDeviceId: _hostId,
    opaqueEnvelope: List<int>.filled(8, byte),
  ),
);

final class _FakeSignalingTransport implements SignalingTransport {
  final Queue<Uint8List> _queued = Queue<Uint8List>();
  final List<SignalingClientFrame> sent = <SignalingClientFrame>[];
  Completer<Uint8List>? _waiting;
  var closeCount = 0;
  var failClose = false;
  var keepPendingReceiveOnClose = false;
  Completer<void>? closeGate;

  void enqueue(SignalingServerFrame frame) {
    _queued.add(Uint8List.fromList(frame.writeToBuffer()));
  }

  void emit(SignalingServerFrame frame) {
    final waiting = _waiting;
    if (waiting == null || waiting.isCompleted) {
      throw StateError('transport has no pending receive');
    }
    _waiting = null;
    waiting.complete(Uint8List.fromList(frame.writeToBuffer()));
  }

  void fail() {
    final waiting = _waiting;
    if (waiting == null || waiting.isCompleted) {
      throw StateError('transport has no pending receive');
    }
    _waiting = null;
    waiting.completeError(
      const SignalingClientException(SignalingClientErrorCode.transport),
    );
  }

  @override
  Future<void> close() async {
    closeCount += 1;
    if (failClose) {
      throw StateError('transport cleanup failed');
    }
    final waiting = _waiting;
    if (!keepPendingReceiveOnClose) {
      _waiting = null;
    }
    if (!keepPendingReceiveOnClose && waiting != null && !waiting.isCompleted) {
      waiting.completeError(
        const SignalingClientException(SignalingClientErrorCode.closed),
      );
    }
    await closeGate?.future;
  }

  @override
  Future<Uint8List> receiveBinary() async {
    if (_queued.isNotEmpty) {
      return _queued.removeFirst();
    }
    final waiting = Completer<Uint8List>();
    _waiting = waiting;
    return waiting.future;
  }

  @override
  void send(SignalingClientFrame frame) {
    sent.add(frame.deepCopy());
  }
}
