// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as hashes;
import 'package:cryptography/cryptography.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/mobile/identity/mobile_device_identity.dart';
import 'package:roammand/pairing/controller_pairing_engine.dart';
import 'package:roammand/pairing/controller_pairing_models.dart';
import 'package:roammand/pairing/pairing_signaling_client.dart';
import 'package:roammand/pairing/trusted_host_repository.dart';
import 'package:roammand/pairing/trusted_host_store.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

void main() {
  test(
    'QR pairing authenticates both identities and persists accepted Host',
    () async {
      final fixture = await PairingFixture.create();
      addTearDown(fixture.close);
      final states = <ControllerPairingState>[];
      final subscription = fixture.engine.states.listen(
        (snapshot) => states.add(snapshot.state),
      );
      addTearDown(subscription.cancel);

      final pairing = fixture.engine.pairQr(fixture.invitation);
      final session = await fixture.waitForHello();
      await fixture.route(await session.hostProof());
      await session.expectControllerReady();
      expect(
        fixture.engine.snapshot.state,
        ControllerPairingState.waitingHostDecision,
      );
      expect(fixture.engine.snapshot.sasWords, isEmpty);

      await fixture.route(await session.finalDecision(accepted: true));
      final result = await pairing;

      expect(result.state, ControllerPairingState.accepted);
      expect(fixture.repository.hosts, hasLength(1));
      expect(
        fixture.repository.hosts.single.hostIdentity.deviceId,
        fixture.hostIdentity.deviceId,
      );
      expect(
        fixture.repository.hosts.single.pairedAtUnixMs,
        fixture.nowUnixMs + 10,
      );
      expect(
        states,
        containsAllInOrder(<ControllerPairingState>[
          ControllerPairingState.connecting,
          ControllerPairingState.verifyingHost,
          ControllerPairingState.waitingHostDecision,
          ControllerPairingState.accepted,
        ]),
      );
      expect(fixture.link.closeCount, 1);
      expect(fixture.controllerEphemeralPrivate, everyElement(0));
    },
  );

  test(
    'desktop code requires Host invitation and exposes the fixed four-word SAS',
    () async {
      final fixture = await PairingFixture.create(
        kind: PairingInvitationKind.PAIRING_INVITATION_KIND_DESKTOP_CODE,
      );
      addTearDown(fixture.close);

      final pairing = fixture.engine.pairDesktopCode(
        pairingCode: 'abcd-2345',
        signalingEndpoint: fixture.endpoint,
      );
      await fixture.route(
        PairingMessage(hostInvitation: fixture.invitation).writeToBuffer(),
      );
      final session = await fixture.waitForHello();
      await fixture.route(await session.hostProof());
      await session.expectControllerReady();

      expect(
        fixture.engine.snapshot.state,
        ControllerPairingState.waitingHostDecision,
      );
      expect(
        fixture.engine.snapshot.sasWords,
        pairingSasWords(session.transcriptSha256, fixture.wordList),
      );
      expect(fixture.engine.snapshot.sasWords, hasLength(4));

      await fixture.route(await session.finalDecision(accepted: false));
      expect((await pairing).state, ControllerPairingState.rejected);
      expect(fixture.repository.hosts, isEmpty);
    },
  );

  test(
    'sender, sequence, signature, ciphertext, message, and size attacks fail closed',
    () async {
      for (var attack = 0; attack < 6; attack += 1) {
        final fixture = await PairingFixture.create();
        final pairing = fixture.engine.pairQr(fixture.invitation);
        final session = await fixture.waitForHello();
        Uint8List proof;
        List<int>? sender;
        switch (attack) {
          case 0:
            proof = await session.hostProof();
            sender = List<int>.filled(32, 0x77);
          case 1:
            proof = await session.hostProof(sequence: 2);
          case 2:
            proof = await session.hostProof(invalidSignature: true);
          case 3:
            proof = await session.hostProof()
              ..[20] ^= 1;
          case 4:
            proof = Uint8List.fromList(<int>[0x08, 0x01]);
          case 5:
            proof = Uint8List(maxOpaqueSignalingEnvelopeBytes + 1);
          default:
            throw StateError('unknown attack');
        }
        await fixture.route(proof, senderDeviceId: sender);

        expect(
          (await pairing).state,
          ControllerPairingState.failed,
          reason: 'attack $attack',
        );
        expect(fixture.repository.hosts, isEmpty);
        expect(fixture.link.closeCount, 1);
        await fixture.close();
      }
    },
  );

  test('expired rendezvous never reports acceptance', () async {
    final fixture = await PairingFixture.create();
    addTearDown(fixture.close);
    final pairing = fixture.engine.pairQr(fixture.invitation);
    final session = await fixture.waitForHello();
    fixture.nowUnixMs = fixture.expiresAtUnixMs + 1;
    await fixture.route(await session.hostProof());

    expect((await pairing).state, ControllerPairingState.expired);
    expect(fixture.repository.hosts, isEmpty);
  });

  test('persistence failure never reports acceptance', () async {
    final fixture = await PairingFixture.create(failPersistence: true);
    addTearDown(fixture.close);
    final pairing = fixture.engine.pairQr(fixture.invitation);
    final session = await fixture.waitForHello();
    await fixture.route(await session.hostProof());
    await session.expectControllerReady();
    await fixture.route(await session.finalDecision(accepted: true));

    final result = await pairing;
    expect(result.state, ControllerPairingState.failed);
    expect(result.error, ControllerPairingError.persistence);
    expect(fixture.repository.hosts, isEmpty);
  });

  test('cancellation never reports acceptance', () async {
    final fixture = await PairingFixture.create();
    addTearDown(fixture.close);
    final pairing = fixture.engine.pairQr(fixture.invitation);
    await fixture.waitForHello();
    await fixture.engine.cancel();

    expect((await pairing).state, ControllerPairingState.cancelled);
    expect(fixture.link.closeCount, 1);
  });

  test('invalid invitations and signaling failures are classified', () async {
    final invalidQr = await PairingFixture.create();
    addTearDown(invalidQr.close);
    final substituted = invalidQr.invitation.deepCopy()
      ..hostPublicKeyFingerprintSha256[0] ^= 1;
    final invalidQrResult = await invalidQr.engine.pairQr(substituted);
    expect(invalidQrResult.state, ControllerPairingState.failed);
    expect(invalidQrResult.error, ControllerPairingError.invalidInvitation);
    expect(invalidQr.link.relayed, isEmpty);

    final invalidCode = await PairingFixture.create();
    addTearDown(invalidCode.close);
    final invalidCodeResult = await invalidCode.engine.pairDesktopCode(
      pairingCode: 'not-a-code',
      signalingEndpoint: invalidCode.endpoint,
    );
    expect(invalidCodeResult.error, ControllerPairingError.invalidInvitation);

    final failedJoin = await PairingFixture.create(failJoin: true);
    addTearDown(failedJoin.close);
    final failedJoinResult = await failedJoin.engine.pairQr(
      failedJoin.invitation,
    );
    expect(failedJoinResult.state, ControllerPairingState.failed);
    expect(failedJoinResult.error, ControllerPairingError.signaling);
  });

  test(
    'injected rendezvous timeout expires and clears pairing state',
    () async {
      final fixture = await PairingFixture.create(timeoutWaiting: true);
      addTearDown(fixture.close);

      final result = await fixture.engine.pairQr(fixture.invitation);

      expect(result.state, ControllerPairingState.expired);
      expect(result.error, ControllerPairingError.expired);
      expect(fixture.repository.hosts, isEmpty);
      expect(fixture.controllerEphemeralPrivate, everyElement(0));
    },
  );
}

final class PairingFixture {
  PairingFixture._({
    required this.identity,
    required this.hostKeyPair,
    required this.hostIdentity,
    required this.hostEphemeralPrivate,
    required this.invitation,
    required this.link,
    required this.persistence,
    required this.repository,
    required this.wordList,
    required this.controllerEphemeralPrivate,
    required this.engine,
  });

  static Future<PairingFixture> create({
    PairingInvitationKind kind =
        PairingInvitationKind.PAIRING_INVITATION_KIND_QR,
    bool failPersistence = false,
    bool failJoin = false,
    bool timeoutWaiting = false,
  }) async {
    final controllerSeed = Uint8List.fromList(
      List<int>.generate(32, (index) => index),
    );
    final identity = await MobileDeviceIdentity.fromSeed(
      seed: controllerSeed,
      displayName: 'My Phone',
      platform: DevicePlatform.DEVICE_PLATFORM_IOS,
    );
    final hostKeyPair = await Ed25519().newKeyPairFromSeed(
      List<int>.generate(32, (index) => 0x40 + index),
    );
    final hostPublicKey = await hostKeyPair.extractPublicKey();
    final hostIdentity = DeviceIdentity(
      deviceId: deriveDeviceIdV1(hostPublicKey.bytes),
      publicKeyAlgorithm: PublicKeyAlgorithm.PUBLIC_KEY_ALGORITHM_ED25519,
      publicKey: hostPublicKey.bytes,
      displayName: 'Office Mac',
      platform: DevicePlatform.DEVICE_PLATFORM_MACOS,
    );
    final hostEphemeralPrivate = Uint8List.fromList(
      List<int>.generate(32, (index) => 0xb0 + index),
    );
    final hostEphemeralPublic = await x25519PublicKey(hostEphemeralPrivate);
    const now = 1000;
    const expires = now + pairingRendezvousLifetimeMs;
    final invitation = HostPairingInvitation(
      protocolVersion: _version(),
      kind: kind,
      rendezvousId: List<int>.filled(16, 0x51),
      hostIdentity: hostIdentity,
      hostPublicKeyFingerprintSha256: hashes.sha256
          .convert(hostPublicKey.bytes)
          .bytes,
      hostEphemeralPublicKey: hostEphemeralPublic,
      signalingEndpoint: 'wss://signal.example.test/v1/ws',
      pairingCode:
          kind == PairingInvitationKind.PAIRING_INVITATION_KIND_DESKTOP_CODE
          ? 'ABCD2345'
          : '',
      issuedAtUnixMs: Int64(now),
      expiresAtUnixMs: Int64(expires),
    );
    final link = FakeControllerPairingLink(
      PairingSignalingJoin(
        rendezvousId: invitation.rendezvousId,
        hostDeviceId: hostIdentity.deviceId,
        expiresAtUnixMs: expires,
      ),
    )..failJoin = failJoin;
    final persistence = MemoryTrustedHostPersistence()
      ..failSave = failPersistence;
    final repository = TrustedHostRepository(persistence: persistence);
    await repository.initialize();
    final wordList = File(
      '../../conformance/wordlists/bip39-english.txt',
    ).readAsStringSync().trim().split('\n');
    final controllerEphemeralPrivate = Uint8List.fromList(
      List<int>.generate(32, (index) => 0x90 + index),
    );
    late final PairingFixture fixture;
    final engine = ControllerPairingEngine(
      identity: identity,
      signaling: link,
      trustedHosts: repository,
      sasWordList: wordList,
      randomBytes: (_) => controllerEphemeralPrivate,
      nowUnixMs: () => fixture.nowUnixMs,
      eventWaiter: timeoutWaiting
          ? (_, _) async {
              fixture.nowUnixMs = fixture.expiresAtUnixMs + 1;
              return false;
            }
          : null,
    );
    fixture = PairingFixture._(
      identity: identity,
      hostKeyPair: hostKeyPair,
      hostIdentity: hostIdentity,
      hostEphemeralPrivate: hostEphemeralPrivate,
      invitation: invitation,
      link: link,
      persistence: persistence,
      repository: repository,
      wordList: wordList,
      controllerEphemeralPrivate: controllerEphemeralPrivate,
      engine: engine,
    );
    return fixture;
  }

  final MobileDeviceIdentity identity;
  final KeyPair hostKeyPair;
  final DeviceIdentity hostIdentity;
  final Uint8List hostEphemeralPrivate;
  final HostPairingInvitation invitation;
  final FakeControllerPairingLink link;
  final MemoryTrustedHostPersistence persistence;
  final TrustedHostRepository repository;
  final List<String> wordList;
  final Uint8List controllerEphemeralPrivate;
  final ControllerPairingEngine engine;
  final Uri endpoint = Uri.parse('wss://signal.example.test/v1/ws');
  int nowUnixMs = 1000;
  int get expiresAtUnixMs => invitation.expiresAtUnixMs.toInt();

  Future<HostSession> waitForHello() async {
    while (link.relayed.isEmpty) {
      await Future<void>.delayed(Duration.zero);
    }
    final helloMessage = PairingMessage.fromBuffer(link.relayed.first);
    expect(helloMessage.hasControllerHello(), isTrue);
    final hello = helloMessage.controllerHello;
    final transcript = _pairingTranscript(
      identity.publicIdentity,
      hostIdentity,
      invitation.rendezvousId,
      hello.ephemeralPublicKey,
      invitation.hostEphemeralPublicKey,
    );
    expect(hello.transcriptSha256, CanonicalTranscriptV1.sha256(transcript));
    final valid = await Ed25519().verify(
      transcript,
      signature: Signature(
        hello.signature,
        publicKey: SimplePublicKey(
          identity.publicIdentity.publicKey,
          type: KeyPairType.ed25519,
        ),
      ),
    );
    expect(valid, isTrue);
    final shared = await x25519SharedSecret(
      hostEphemeralPrivate,
      Uint8List.fromList(hello.ephemeralPublicKey),
    );
    final keys = await derivePairingKeys(
      shared,
      CanonicalTranscriptV1.sha256(transcript),
    );
    return HostSession(this, hello, transcript, keys);
  }

  Future<void> route(Uint8List bytes, {List<int>? senderDeviceId}) async {
    link.eventsController.add(
      PairingSignalingRouted(
        rendezvousId: invitation.rendezvousId,
        senderDeviceId: senderDeviceId ?? hostIdentity.deviceId,
        opaqueEnvelope: bytes,
      ),
    );
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> close() async {
    await engine.close();
    await repository.close();
    await link.dispose();
  }
}

final class HostSession {
  HostSession(this.fixture, this.hello, this.transcript, this.keys)
    : transcriptSha256 = CanonicalTranscriptV1.sha256(transcript);

  final PairingFixture fixture;
  final ControllerPairingHello hello;
  final Uint8List transcript;
  final Uint8List transcriptSha256;
  final PairingKeySchedule keys;

  Future<Uint8List> hostProof({
    int sequence = 1,
    bool invalidSignature = false,
  }) async {
    final signature = await Ed25519().sign(
      transcript,
      keyPair: fixture.hostKeyPair,
    );
    final hostSignature = List<int>.of(signature.bytes);
    if (invalidSignature) {
      hostSignature[0] ^= 1;
    }
    return _sealHost(
      sequence,
      PairingPlaintext(
        hostProof: HostPairingProof(
          confirmation: PairingConfirmationData(
            controllerDeviceId: fixture.identity.publicIdentity.deviceId,
            hostDeviceId: fixture.hostIdentity.deviceId,
            rendezvousId: fixture.invitation.rendezvousId,
            controllerIdentityPublicKey:
                fixture.identity.publicIdentity.publicKey,
            hostIdentityPublicKey: fixture.hostIdentity.publicKey,
            controllerEphemeralPublicKey: hello.ephemeralPublicKey,
            hostEphemeralPublicKey: fixture.invitation.hostEphemeralPublicKey,
            transcriptSha256: transcriptSha256,
          ),
          hostSignature: hostSignature,
          expiresAtUnixMs: fixture.invitation.expiresAtUnixMs,
        ),
      ),
    );
  }

  Future<void> expectControllerReady() async {
    while (fixture.link.relayed.length < 2) {
      await Future<void>.delayed(Duration.zero);
    }
    final message = PairingMessage.fromBuffer(fixture.link.relayed[1]);
    final envelope = message.encryptedEnvelope;
    expect(
      envelope.protocolVersion.hasMinor(),
      isFalse,
      reason: 'prost rejects explicitly encoded proto3 zero defaults',
    );
    expect(envelope.sequence.toInt(), 1);
    final aad = pairingAad(
      direction: PairingCryptoDirection.controllerToHost,
      sequence: 1,
      rendezvousId: Uint8List.fromList(fixture.invitation.rendezvousId),
      controllerDeviceId: Uint8List.fromList(
        fixture.identity.publicIdentity.deviceId,
      ),
      hostDeviceId: Uint8List.fromList(fixture.hostIdentity.deviceId),
    );
    final plaintext = PairingPlaintext.fromBuffer(
      await openPairingPayload(
        key: keys.controllerToHost,
        direction: PairingCryptoDirection.controllerToHost,
        sequence: 1,
        aad: aad,
        ciphertextAndTag: Uint8List.fromList(envelope.ciphertext),
      ),
    );
    expect(plaintext.controllerReady.transcriptSha256, transcriptSha256);
  }

  Future<Uint8List> finalDecision({required bool accepted}) => _sealHost(
    2,
    PairingPlaintext(
      finalDecision: PairingFinalDecision(
        status: accepted
            ? PairingDecisionStatus.PAIRING_DECISION_STATUS_ACCEPTED
            : PairingDecisionStatus.PAIRING_DECISION_STATUS_REJECTED,
        transcriptSha256: transcriptSha256,
        grant: accepted
            ? ControllerGrant(
                grantId: List<int>.filled(16, 0x31),
                hostDeviceId: fixture.hostIdentity.deviceId,
                controller: fixture.identity.publicIdentity,
                createdAtUnixMs: Int64(fixture.nowUnixMs + 10),
                permissions: <SessionPermission>[
                  SessionPermission.SESSION_PERMISSION_VIEW_SCREEN,
                  SessionPermission.SESSION_PERMISSION_CONTROL_INPUT,
                ],
              )
            : null,
      ),
    ),
  );

  Future<Uint8List> _sealHost(int sequence, PairingPlaintext plaintext) async {
    final aad = pairingAad(
      direction: PairingCryptoDirection.hostToController,
      sequence: sequence,
      rendezvousId: Uint8List.fromList(fixture.invitation.rendezvousId),
      controllerDeviceId: Uint8List.fromList(
        fixture.identity.publicIdentity.deviceId,
      ),
      hostDeviceId: Uint8List.fromList(fixture.hostIdentity.deviceId),
    );
    final ciphertext = await sealPairingPayload(
      key: keys.hostToController,
      direction: PairingCryptoDirection.hostToController,
      sequence: sequence,
      aad: aad,
      plaintext: Uint8List.fromList(plaintext.writeToBuffer()),
    );
    return Uint8List.fromList(
      PairingMessage(
        encryptedEnvelope: EncryptedPairingEnvelope(
          protocolVersion: _version(),
          rendezvousId: fixture.invitation.rendezvousId,
          direction: PairingDirection.PAIRING_DIRECTION_HOST_TO_CONTROLLER,
          sequence: Int64(sequence),
          ciphertext: ciphertext,
        ),
      ).writeToBuffer(),
    );
  }
}

final class FakeControllerPairingLink
    implements ControllerPairingSignalingLink {
  FakeControllerPairingLink(this.joinResult);

  final PairingSignalingJoin joinResult;
  final StreamController<PairingSignalingEvent> eventsController =
      StreamController<PairingSignalingEvent>.broadcast();
  final List<Uint8List> relayed = <Uint8List>[];
  int closeCount = 0;
  bool failJoin = false;

  @override
  Stream<PairingSignalingEvent> get events => eventsController.stream;

  @override
  Future<void> connect(Uri endpoint, List<int> controllerDeviceId) async {}

  @override
  Future<PairingSignalingJoin> joinQr(List<int> rendezvousId) async =>
      failJoin ? throw StateError('join failed') : joinResult;

  @override
  Future<PairingSignalingJoin> joinDesktopCode(String pairingCode) async =>
      failJoin ? throw StateError('join failed') : joinResult;

  @override
  Future<void> relay(List<int> rendezvousId, Uint8List opaqueEnvelope) async {
    relayed.add(Uint8List.fromList(opaqueEnvelope));
  }

  @override
  Future<void> close() async {
    closeCount += 1;
  }

  Future<void> dispose() async {
    if (!eventsController.isClosed) {
      await eventsController.close();
    }
  }
}

final class MemoryTrustedHostPersistence implements TrustedHostPersistence {
  bool failSave = false;
  List<TrustedHostBinding> bindings = <TrustedHostBinding>[];

  @override
  Future<List<TrustedHostBinding>> load() async =>
      bindings.map((binding) => binding.deepCopy()).toList();

  @override
  Future<void> save(Iterable<TrustedHostBinding> bindings) async {
    if (failSave) {
      throw const TrustedHostStoreException(TrustedHostStoreError.unavailable);
    }
    this.bindings = bindings.map((binding) => binding.deepCopy()).toList();
  }
}

Uint8List _pairingTranscript(
  DeviceIdentity controller,
  DeviceIdentity host,
  List<int> rendezvousId,
  List<int> controllerEphemeralPublicKey,
  List<int> hostEphemeralPublicKey,
) => CanonicalTranscriptV1.encode(
  TranscriptPurpose.pairingSas,
  <TranscriptField>[
    TranscriptField(1, controller.deviceId),
    TranscriptField(2, host.deviceId),
    TranscriptField(3, rendezvousId),
    TranscriptField(4, controller.publicKey),
    TranscriptField(5, host.publicKey),
    TranscriptField(6, controllerEphemeralPublicKey),
    TranscriptField(7, hostEphemeralPublicKey),
  ],
);

ProtocolVersion _version() => ProtocolVersion(
  major: protocolMajorVersion,
  minor: minimumProtocolMinorVersion,
);
