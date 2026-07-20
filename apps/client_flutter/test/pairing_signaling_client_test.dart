// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/pairing/pairing_signaling_client.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

void main() {
  test(
    'registers, joins QR rendezvous, relays, and routes only the bound Host',
    () async {
      final fixture = _Fixture();
      final client = fixture.client;
      final controllerId = List<int>.filled(32, 0x61);
      final hostId = List<int>.filled(32, 0x71);
      final rendezvousId = List<int>.filled(16, 0x51);

      final connecting = client.connect(
        Uri.parse('wss://signal.example.test/v1/ws'),
        controllerId,
      );
      final registration = await fixture.transport.takeFrame();
      expect(registration.register.deviceId, controllerId);
      fixture.transport.server(
        SignalingServerFrame(
          protocolVersion: _version(),
          requestId: registration.requestId,
          registered: RegistrationAccepted(
            deviceId: controllerId,
            presenceExpiresAtUnixMs: Int64(2000),
          ),
        ),
      );
      await connecting;

      final joining = client.joinQr(rendezvousId);
      final join = await fixture.transport.takeFrame();
      expect(join.joinRendezvous.rendezvousId, rendezvousId);
      fixture.transport.server(
        SignalingServerFrame(
          protocolVersion: _version(),
          requestId: join.requestId,
          rendezvousJoined: PairingRendezvousJoined(
            rendezvousId: rendezvousId,
            peerDeviceId: hostId,
            expiresAtUnixMs: Int64(120000),
          ),
        ),
      );
      final joined = await joining;
      expect(joined.hostDeviceId, hostId);
      expect(joined.rendezvousId, rendezvousId);

      await client.relay(rendezvousId, Uint8List.fromList(<int>[1, 2, 3]));
      final relay = await fixture.transport.takeFrame();
      expect(relay.relayPairing.rendezvousId, rendezvousId);
      expect(relay.relayPairing.opaqueEnvelope, <int>[1, 2, 3]);

      final routed = client.events.first;
      fixture.transport.server(
        SignalingServerFrame(
          protocolVersion: _version(),
          routedPairing: RoutedPairingEnvelope(
            rendezvousId: rendezvousId,
            senderDeviceId: hostId,
            opaqueEnvelope: <int>[4, 5, 6],
          ),
        ),
      );
      final event = (await routed) as PairingSignalingRouted;
      expect(event.opaqueEnvelope, <int>[4, 5, 6]);
      await client.close();
      expect(fixture.transport.closeCount, 1);
    },
  );

  test('normalizes a desktop code and reports authenticated closure', () async {
    final fixture = _Fixture();
    await fixture.connect();
    final hostId = List<int>.filled(32, 0x71);
    final rendezvousId = List<int>.filled(16, 0x51);

    final joining = fixture.client.joinDesktopCode('abcd-2345');
    final join = await fixture.transport.takeFrame();
    expect(join.joinRendezvous.pairingCode, 'ABCD2345');
    fixture.transport.server(
      SignalingServerFrame(
        protocolVersion: _version(),
        requestId: join.requestId,
        rendezvousJoined: PairingRendezvousJoined(
          rendezvousId: rendezvousId,
          peerDeviceId: hostId,
          expiresAtUnixMs: Int64(120000),
        ),
      ),
    );
    await joining;

    final closed = fixture.client.events.first;
    fixture.transport.server(
      SignalingServerFrame(
        protocolVersion: _version(),
        rendezvousClosed: PairingRendezvousClosed(
          rendezvousId: rendezvousId,
          completion: PairingRendezvousCompletion
              .PAIRING_RENDEZVOUS_COMPLETION_REJECTED,
        ),
      ),
    );
    expect(
      ((await closed) as PairingSignalingClosed).completion,
      PairingRendezvousCompletion.PAIRING_RENDEZVOUS_COMPLETION_REJECTED,
    );
    await fixture.client.close();
  });

  test('renews presence while waiting for the Host decision', () async {
    final fixture = _Fixture(
      heartbeatInterval: const Duration(milliseconds: 10),
    );
    await fixture.connect();
    await fixture.join();

    final heartbeat = await fixture.transport.takeFrame();
    expect(heartbeat.hasHeartbeat(), isTrue);
    fixture.transport.server(
      SignalingServerFrame(
        protocolVersion: _version(),
        requestId: heartbeat.requestId,
        heartbeatAcknowledged: HeartbeatAcknowledged(
          serverTimeUnixMs: Int64(1000),
          presenceExpiresAtUnixMs: Int64(46000),
        ),
      ),
    );
    final nextHeartbeat = await fixture.transport.takeFrame();
    expect(nextHeartbeat.hasHeartbeat(), isTrue);

    await fixture.client.close();
    expect(fixture.transport.closeCount, 1);
  });

  test('closes a transport that arrives after the client is closed', () async {
    final connectorStarted = Completer<void>();
    final transportGate = Completer<PairingSignalingTransport>();
    final transport = _CloseTrackingPairingSignalingTransport();
    final client = PairingSignalingClient(
      connector: (_) {
        connectorStarted.complete();
        return transportGate.future;
      },
    );
    final connecting = client.connect(
      Uri.parse('wss://signal.example.test/v1/ws'),
      List<int>.filled(32, 0x61),
    );
    final connectionResult = expectLater(
      connecting,
      throwsA(
        isA<PairingSignalingException>().having(
          (error) => error.code,
          'code',
          PairingSignalingErrorCode.closed,
        ),
      ),
    );
    await connectorStarted.future;

    await client.close();
    expect(transport.closeCount, 0);

    transportGate.complete(transport);
    await connectionResult;

    expect(transport.closeCount, 1);
    expect(transport.sent, isEmpty);
    await client.close();
    expect(transport.closeCount, 1);
  });

  test('close during a pending registration send has no stray error', () async {
    final transport = _PendingSendPairingSignalingTransport();
    final client = PairingSignalingClient(connector: (_) async => transport);
    final connecting = client.connect(
      Uri.parse('wss://signal.example.test/v1/ws'),
      List<int>.filled(32, 0x61),
    );
    final connectionResult = expectLater(
      connecting,
      throwsA(isA<PairingSignalingException>()),
    );
    await transport.sendStarted.future;

    await client.close();
    await connectionResult;

    expect(transport.closeCount, 1);
  });

  test('a completed join response cannot revive a closed client', () async {
    final fixture = _Fixture(syncIncoming: true);
    await fixture.connect();
    final rendezvousId = List<int>.filled(16, 0x51);
    final joining = fixture.client.joinQr(rendezvousId);
    final joinFrame = await fixture.transport.takeFrame();
    final joinResult = expectLater(
      joining,
      throwsA(
        isA<PairingSignalingException>().having(
          (error) => error.code,
          'code',
          PairingSignalingErrorCode.closed,
        ),
      ),
    );

    fixture.transport.server(
      SignalingServerFrame(
        protocolVersion: _version(),
        requestId: joinFrame.requestId,
        rendezvousJoined: PairingRendezvousJoined(
          rendezvousId: rendezvousId,
          peerDeviceId: List<int>.filled(32, 0x71),
          expiresAtUnixMs: Int64(120000),
        ),
      ),
    );
    await fixture.client.close();
    await joinResult;

    await expectLater(
      fixture.client.relay(rendezvousId, Uint8List.fromList(<int>[1])),
      throwsA(isA<PairingSignalingException>()),
    );
  });

  test('transport cleanup failure does not skip client cleanup', () async {
    final fixture = _Fixture();
    await fixture.connect();
    fixture.transport.failClose = true;

    await fixture.client.close();

    expect(fixture.transport.closeCount, 1);
    await expectLater(fixture.client.events, emitsDone);
    await expectLater(
      fixture.client.relay(
        List<int>.filled(16, 0x51),
        Uint8List.fromList(<int>[1]),
      ),
      throwsA(isA<PairingSignalingException>()),
    );
  });

  test(
    'fails closed for sender substitution, malformed enums, and oversized frames',
    () async {
      for (final attack in <void Function(_Fixture)>[
        (fixture) => fixture.transport.server(
          SignalingServerFrame(
            protocolVersion: _version(),
            routedPairing: RoutedPairingEnvelope(
              rendezvousId: List<int>.filled(16, 0x51),
              senderDeviceId: List<int>.filled(32, 0x72),
              opaqueEnvelope: <int>[1],
            ),
          ),
        ),
        (fixture) {
          final rendezvousId = List<int>.filled(16, 0x51);
          final invalidClosed = PairingRendezvousClosed.fromBuffer(<int>[
            0x0a,
            rendezvousId.length,
            ...rendezvousId,
            0x10,
            99,
          ]);
          final frame = SignalingServerFrame(
            protocolVersion: _version(),
            rendezvousClosed: invalidClosed,
          );
          fixture.transport.server(frame);
        },
        (fixture) => fixture.transport.incoming.add(
          Uint8List(maxSignalingServiceFrameBytes + 1),
        ),
      ]) {
        final fixture = _Fixture();
        await fixture.connect();
        await fixture.join();
        final error = expectLater(
          fixture.client.events,
          emitsError(isA<PairingSignalingException>()),
        );
        attack(fixture);
        await error;
        expect(fixture.transport.closeCount, 1);
      }
    },
  );
}

final class _Fixture {
  _Fixture({
    Duration heartbeatInterval = const Duration(seconds: 15),
    bool syncIncoming = false,
  }) : transport = FakePairingSignalingTransport(syncIncoming: syncIncoming) {
    client = PairingSignalingClient(
      connector: (_) async => transport,
      requestIdFactory: () => 'request-${requestSequence++}',
      heartbeatInterval: heartbeatInterval,
    );
  }

  final FakePairingSignalingTransport transport;
  var requestSequence = 0;
  late final PairingSignalingClient client;

  Future<void> connect() async {
    final connecting = client.connect(
      Uri.parse('wss://signal.example.test/v1/ws'),
      List<int>.filled(32, 0x61),
    );
    final frame = await transport.takeFrame();
    transport.server(
      SignalingServerFrame(
        protocolVersion: _version(),
        requestId: frame.requestId,
        registered: RegistrationAccepted(
          deviceId: List<int>.filled(32, 0x61),
          presenceExpiresAtUnixMs: Int64(2000),
        ),
      ),
    );
    await connecting;
  }

  Future<void> join() async {
    final joining = client.joinQr(List<int>.filled(16, 0x51));
    final frame = await transport.takeFrame();
    transport.server(
      SignalingServerFrame(
        protocolVersion: _version(),
        requestId: frame.requestId,
        rendezvousJoined: PairingRendezvousJoined(
          rendezvousId: List<int>.filled(16, 0x51),
          peerDeviceId: List<int>.filled(32, 0x71),
          expiresAtUnixMs: Int64(120000),
        ),
      ),
    );
    await joining;
  }
}

final class FakePairingSignalingTransport implements PairingSignalingTransport {
  FakePairingSignalingTransport({bool syncIncoming = false})
    : incoming = StreamController<Uint8List>(sync: syncIncoming);

  final StreamController<Uint8List> incoming;
  final List<Uint8List> sent = <Uint8List>[];
  int closeCount = 0;
  bool failClose = false;

  @override
  Stream<Uint8List> get frames => incoming.stream;

  @override
  Future<void> send(Uint8List frame) async {
    sent.add(Uint8List.fromList(frame));
  }

  Future<SignalingClientFrame> takeFrame() async {
    while (sent.isEmpty) {
      await Future<void>.delayed(Duration.zero);
    }
    return SignalingClientFrame.fromBuffer(sent.removeAt(0));
  }

  void server(SignalingServerFrame frame) {
    incoming.add(Uint8List.fromList(frame.writeToBuffer()));
  }

  @override
  Future<void> close() async {
    closeCount += 1;
    await incoming.close();
    sent.clear();
    if (failClose) {
      throw StateError('transport cleanup failed');
    }
  }
}

final class _CloseTrackingPairingSignalingTransport
    implements PairingSignalingTransport {
  final List<Uint8List> sent = <Uint8List>[];
  int closeCount = 0;

  @override
  Stream<Uint8List> get frames => const Stream<Uint8List>.empty();

  @override
  Future<void> send(Uint8List frame) async {
    sent.add(Uint8List.fromList(frame));
  }

  @override
  Future<void> close() async {
    closeCount += 1;
  }
}

final class _PendingSendPairingSignalingTransport
    implements PairingSignalingTransport {
  final StreamController<Uint8List> _incoming =
      StreamController<Uint8List>.broadcast();
  final Completer<void> _pendingSend = Completer<void>();
  final Completer<void> sendStarted = Completer<void>();
  int closeCount = 0;

  @override
  Stream<Uint8List> get frames => _incoming.stream;

  @override
  Future<void> send(Uint8List frame) async {
    sendStarted.complete();
    await _pendingSend.future;
  }

  @override
  Future<void> close() async {
    closeCount += 1;
    if (!_pendingSend.isCompleted) {
      _pendingSend.completeError(StateError('transport closed'));
    }
    await _incoming.close();
  }
}

ProtocolVersion _version() => ProtocolVersion(
  major: protocolMajorVersion,
  minor: minimumProtocolMinorVersion,
);
