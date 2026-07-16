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
    final waiting = _waiting;
    _waiting = null;
    if (waiting != null && !waiting.isCompleted) {
      waiting.completeError(
        const SignalingClientException(SignalingClientErrorCode.closed),
      );
    }
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
