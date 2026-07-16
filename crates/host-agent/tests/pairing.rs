// SPDX-License-Identifier: MPL-2.0

use std::{collections::VecDeque, sync::Arc};

use ed25519_dalek::{Signature, Signer, SigningKey, Verifier, VerifyingKey};
use prost::Message;
use roammand_host_agent::{
    AuthorizationRegistry, HostIdentity, HostPairingCoordinator, MemoryGrantStore,
    PairingCoordinatorError, PairingOutbound, PairingRandom, PairingRandomError, SignalingEvent,
};
use roammand_host_platform::{MemorySecretStore, ProtectedSecretStore};
use roammand_protocol::{
    canonical_transcript::{
        CanonicalTranscript, TranscriptField, TranscriptPurpose, encode, sha256,
    },
    identity_derivation::derive_device_id_v1,
    pairing_crypto::{
        CryptoDirection, PairingKeySchedule, derive_pairing_keys, open_pairing_payload,
        pairing_aad, seal_pairing_payload, x25519_public_key, x25519_shared_secret,
    },
    roammand::v1::{
        ControllerPairingHello, ControllerPairingReady, DeviceIdentity, DevicePlatform,
        EncryptedPairingEnvelope, HostPairingState, PairingDecisionStatus, PairingDirection,
        PairingInvitationKind, PairingMessage, PairingPlaintext, PairingRendezvousCompletion,
        PairingRendezvousKind, ProtocolVersion, PublicKeyAlgorithm, pairing_message,
        pairing_plaintext,
    },
};

const NOW: u64 = 1_000;
const LOCAL_EXPIRES: u64 = 121_000;
const SERVER_EXPIRES: u64 = 200_000;
const RENDEZVOUS_ID: [u8; 16] = [0x51; 16];
const CONTROLLER_EPHEMERAL_PRIVATE: [u8; 32] = [0x31; 32];

#[test]
fn authenticated_qr_pairing_gates_the_permanent_grant_on_local_acceptance() {
    let mut harness = Harness::joined(PairingInvitationKind::Qr);
    assert_eq!(
        harness.coordinator.snapshot().expires_at_unix_ms,
        LOCAL_EXPIRES
    );
    assert_eq!(
        harness.coordinator.snapshot().state,
        HostPairingState::VerifyingController as i32
    );

    let keys = harness.exchange_identity();
    let waiting = harness.coordinator.snapshot();
    assert_eq!(waiting.state, HostPairingState::WaitingLocalDecision as i32);
    assert_eq!(waiting.pending_controller, Some(harness.controller.clone()));
    assert!(waiting.sas_words.is_empty());
    assert!(harness.registry.list_controller_grants().is_empty());

    harness
        .coordinator
        .accept(
            &RENDEZVOUS_ID,
            &harness.controller.device_id,
            &mut harness.registry,
            NOW + 10,
        )
        .expect("authenticated local acceptance must succeed");
    assert_eq!(
        harness.coordinator.snapshot().state,
        HostPairingState::Accepted as i32
    );
    assert_eq!(harness.registry.list_controller_grants().len(), 1);

    let outbound = harness.coordinator.take_outbound();
    assert_eq!(outbound.len(), 2);
    let decision = decrypt_final_decision(&outbound[0], &keys, &harness);
    assert_eq!(decision.status, PairingDecisionStatus::Accepted as i32);
    assert!(decision.grant.is_some());
    assert!(matches!(
        outbound[1],
        PairingOutbound::Complete {
            completion: PairingRendezvousCompletion::Succeeded,
            ..
        }
    ));

    harness
        .coordinator
        .return_to_idle()
        .expect("terminal state must return to idle");
    assert_eq!(
        harness.coordinator.snapshot().state,
        HostPairingState::Idle as i32
    );
}

#[test]
fn desktop_code_requires_crypto_ready_and_shows_fixed_sas_before_rejection() {
    let mut harness = Harness::joined(PairingInvitationKind::DesktopCode);
    let invitation = harness.invitation();
    assert_eq!(invitation.pairing_code.len(), 8);
    assert!(
        invitation
            .pairing_code
            .bytes()
            .all(|value| { value.is_ascii_uppercase() || matches!(value, b'2'..=b'7') })
    );
    assert!(harness.registry.list_controller_grants().is_empty());
    assert_eq!(
        harness.coordinator.accept(
            &RENDEZVOUS_ID,
            &harness.controller.device_id,
            &mut harness.registry,
            NOW,
        ),
        Err(PairingCoordinatorError::InvalidState)
    );

    let keys = harness.exchange_identity();
    let snapshot = harness.coordinator.snapshot();
    assert_eq!(snapshot.sas_words.len(), 4);
    assert!(
        snapshot.sas_words.iter().all(|word| {
            !word.is_empty() && word.bytes().all(|value| value.is_ascii_lowercase())
        })
    );
    harness
        .coordinator
        .reject(&RENDEZVOUS_ID, &harness.controller.device_id, NOW + 10)
        .expect("Host may reject only a verified Controller");
    assert!(harness.registry.list_controller_grants().is_empty());
    let outbound = harness.coordinator.take_outbound();
    let decision = decrypt_final_decision(&outbound[0], &keys, &harness);
    assert_eq!(decision.status, PairingDecisionStatus::Rejected as i32);
    assert!(decision.grant.is_none());
    assert!(matches!(
        outbound[1],
        PairingOutbound::Complete {
            completion: PairingRendezvousCompletion::Rejected,
            ..
        }
    ));
}

#[test]
fn mutation_replay_expiry_disconnect_and_store_failure_fail_closed() {
    let mut mutated = Harness::joined(PairingInvitationKind::Qr);
    mutated.send_hello();
    let mut ready = mutated.controller_ready();
    let last = ready.len() - 1;
    ready[last] ^= 0x01;
    assert_eq!(
        mutated.coordinator.handle_signaling_event(
            SignalingEvent::RoutedPairing {
                rendezvous_id: RENDEZVOUS_ID.to_vec(),
                sender_device_id: mutated.controller.device_id.clone(),
                opaque_envelope: ready,
            },
            &mutated.host,
            NOW + 2,
        ),
        Err(PairingCoordinatorError::Authentication)
    );
    assert_eq!(
        mutated.coordinator.snapshot().state,
        HostPairingState::Failed as i32
    );
    assert!(mutated.registry.list_controller_grants().is_empty());

    let mut expired = Harness::joined(PairingInvitationKind::Qr);
    expired.coordinator.tick(LOCAL_EXPIRES);
    assert_eq!(
        expired.coordinator.snapshot().state,
        HostPairingState::Expired as i32
    );
    assert!(expired.registry.list_controller_grants().is_empty());

    let mut disconnected = Harness::joined(PairingInvitationKind::Qr);
    disconnected.coordinator.signaling_lost();
    assert_eq!(
        disconnected.coordinator.snapshot().state,
        HostPairingState::Failed as i32
    );

    let store = Arc::new(MemoryGrantStore::new());
    let mut failed_store = Harness::joined_with_store(PairingInvitationKind::Qr, store.clone());
    let keys = failed_store.exchange_identity();
    store.fail_next_persist();
    assert!(matches!(
        failed_store.coordinator.accept(
            &RENDEZVOUS_ID,
            &failed_store.controller.device_id,
            &mut failed_store.registry,
            NOW + 10,
        ),
        Err(PairingCoordinatorError::Authorization(_))
    ));
    assert_eq!(
        failed_store.coordinator.snapshot().state,
        HostPairingState::Failed as i32
    );
    assert!(failed_store.registry.list_controller_grants().is_empty());
    assert!(failed_store.coordinator.take_outbound().iter().all(|item| {
        !matches!(item, PairingOutbound::Relay { opaque_envelope, .. }
            if decrypt_final_decision_bytes(opaque_envelope, &keys, &failed_store)
                .is_some_and(|decision| decision.status == PairingDecisionStatus::Accepted as i32))
    }));
}

#[test]
fn substituted_identity_transcript_signature_and_sender_are_rejected() {
    for mutation in [
        HelloMutation::Sender,
        HelloMutation::Identity,
        HelloMutation::Transcript,
        HelloMutation::Signature,
    ] {
        assert_hello_rejected(mutation);
    }
}

#[test]
fn duplicate_and_skipped_controller_sequences_terminate_pairing() {
    let mut replay = Harness::joined(PairingInvitationKind::Qr);
    replay.exchange_identity();
    let ready = replay.controller_ready();
    assert_eq!(
        replay.coordinator.handle_signaling_event(
            SignalingEvent::RoutedPairing {
                rendezvous_id: RENDEZVOUS_ID.to_vec(),
                sender_device_id: replay.controller.device_id.clone(),
                opaque_envelope: ready,
            },
            &replay.host,
            NOW + 4,
        ),
        Err(PairingCoordinatorError::Authentication)
    );
    assert_eq!(
        replay.coordinator.snapshot().state,
        HostPairingState::Failed as i32
    );

    let mut skipped = Harness::joined(PairingInvitationKind::Qr);
    skipped.send_hello();
    let ready = skipped.controller_ready();
    let mut message = PairingMessage::decode(ready.as_slice()).expect("ready message");
    let Some(pairing_message::Payload::EncryptedEnvelope(envelope)) = message.payload.as_mut()
    else {
        panic!("encrypted ready envelope");
    };
    envelope.sequence = 2;
    assert_eq!(
        skipped.coordinator.handle_signaling_event(
            SignalingEvent::RoutedPairing {
                rendezvous_id: RENDEZVOUS_ID.to_vec(),
                sender_device_id: skipped.controller.device_id.clone(),
                opaque_envelope: message.encode_to_vec(),
            },
            &skipped.host,
            NOW + 3,
        ),
        Err(PairingCoordinatorError::Authentication)
    );
    assert_eq!(
        skipped.coordinator.snapshot().state,
        HostPairingState::Failed as i32
    );
}

#[test]
fn one_active_pairing_cancel_shutdown_and_debug_output_are_sanitized() {
    let host = host_identity();
    let mut coordinator = HostPairingCoordinator::with_random(
        host.device_identity().clone(),
        Box::new(FixedRandom::new()),
    )
    .expect("coordinator");
    coordinator.signaling_connected();
    coordinator
        .start(
            PairingInvitationKind::DesktopCode,
            "wss://signal.example.test/v1/ws",
            NOW,
        )
        .expect("first pairing");
    assert_eq!(
        coordinator.start(
            PairingInvitationKind::Qr,
            "wss://signal.example.test/v1/ws",
            NOW,
        ),
        Err(PairingCoordinatorError::InvalidState)
    );
    let debug = format!("{coordinator:?}");
    assert!(debug.contains("REDACTED"));
    assert!(!debug.contains("ABCDEFGH"));
    assert!(!debug.contains(&"41".repeat(32)));
    coordinator
        .cancel(&RENDEZVOUS_ID, NOW + 1)
        .expect("cancel active pairing");
    assert_eq!(
        coordinator.snapshot().state,
        HostPairingState::Cancelled as i32
    );

    coordinator.return_to_idle().expect("idle after cancel");
    coordinator.shutdown();
    assert_eq!(coordinator.snapshot().state, HostPairingState::Idle as i32);
}

struct Harness {
    coordinator: HostPairingCoordinator,
    host: HostIdentity,
    controller_key: SigningKey,
    controller: DeviceIdentity,
    registry: AuthorizationRegistry,
    keys: Option<PairingKeySchedule>,
    invitation: roammand_protocol::roammand::v1::HostPairingInvitation,
}

impl Harness {
    fn joined(kind: PairingInvitationKind) -> Self {
        Self::joined_with_store(kind, Arc::new(MemoryGrantStore::new()))
    }

    fn joined_with_store(kind: PairingInvitationKind, store: Arc<MemoryGrantStore>) -> Self {
        let host = host_identity();
        let controller_key = SigningKey::from_bytes(&[0x61; 32]);
        let controller = controller_identity(&controller_key);
        let registry = AuthorizationRegistry::load(host.device_identity().device_id.clone(), store)
            .expect("registry");
        let mut coordinator = HostPairingCoordinator::with_random(
            host.device_identity().clone(),
            Box::new(FixedRandom::new()),
        )
        .expect("coordinator");
        coordinator.signaling_connected();
        coordinator
            .start(kind, "wss://signal.example.test/v1/ws", NOW)
            .expect("start");
        assert_eq!(
            coordinator.snapshot().state,
            HostPairingState::Creating as i32
        );
        let create = coordinator.take_outbound();
        assert!(matches!(
            create.as_slice(),
            [PairingOutbound::Create {
                rendezvous_id,
                ..
            }] if rendezvous_id == &RENDEZVOUS_ID
        ));
        coordinator
            .handle_signaling_event(
                SignalingEvent::PairingCreated {
                    rendezvous_id: RENDEZVOUS_ID.to_vec(),
                    kind: signaling_kind(kind),
                    expires_at_unix_ms: SERVER_EXPIRES,
                },
                &host,
                NOW,
            )
            .expect("created");
        assert_eq!(
            coordinator.snapshot().state,
            HostPairingState::Inviting as i32
        );
        coordinator
            .handle_signaling_event(
                SignalingEvent::PairingJoined {
                    rendezvous_id: RENDEZVOUS_ID.to_vec(),
                    peer_device_id: controller.device_id.clone(),
                    expires_at_unix_ms: SERVER_EXPIRES,
                },
                &host,
                NOW + 1,
            )
            .expect("joined");
        if kind == PairingInvitationKind::DesktopCode {
            let outbound = coordinator.take_outbound();
            assert!(matches!(
                outbound.as_slice(),
                [PairingOutbound::Relay { .. }]
            ));
        }
        let invitation = coordinator
            .snapshot()
            .invitation
            .expect("active invitation");
        Self {
            coordinator,
            host,
            controller_key,
            controller,
            registry,
            keys: None,
            invitation,
        }
    }

    fn invitation(&self) -> roammand_protocol::roammand::v1::HostPairingInvitation {
        self.invitation.clone()
    }

    fn send_hello(&mut self) {
        let invitation = self.invitation();
        let opaque = self.controller_hello();
        self.coordinator
            .handle_signaling_event(
                SignalingEvent::RoutedPairing {
                    rendezvous_id: RENDEZVOUS_ID.to_vec(),
                    sender_device_id: self.controller.device_id.clone(),
                    opaque_envelope: opaque,
                },
                &self.host,
                NOW + 2,
            )
            .expect("Controller hello");
        let shared = x25519_shared_secret(
            &CONTROLLER_EPHEMERAL_PRIVATE,
            &invitation.host_ephemeral_public_key,
        )
        .expect("shared secret");
        self.keys = Some(
            derive_pairing_keys(&shared, &current_transcript_sha256(self, &invitation))
                .expect("pairing keys"),
        );
        let host_proof = self.coordinator.take_outbound();
        assert!(matches!(
            host_proof.as_slice(),
            [PairingOutbound::Relay { .. }]
        ));
        verify_host_proof(&host_proof[0], self);
    }

    fn controller_hello(&self) -> Vec<u8> {
        let invitation = self.invitation();
        let controller_ephemeral_public =
            x25519_public_key(&CONTROLLER_EPHEMERAL_PRIVATE).expect("controller public key");
        let transcript = pairing_transcript(
            &self.controller,
            invitation.host_identity.as_ref().expect("Host identity"),
            &invitation.rendezvous_id,
            &controller_ephemeral_public,
            &invitation.host_ephemeral_public_key,
        );
        PairingMessage {
            payload: Some(pairing_message::Payload::ControllerHello(
                ControllerPairingHello {
                    rendezvous_id: invitation.rendezvous_id,
                    identity: Some(self.controller.clone()),
                    ephemeral_public_key: controller_ephemeral_public.to_vec(),
                    transcript_sha256: sha256(&transcript).to_vec(),
                    signature: self.controller_key.sign(&transcript).to_bytes().to_vec(),
                },
            )),
        }
        .encode_to_vec()
    }

    fn controller_ready(&self) -> Vec<u8> {
        let invitation = self.invitation();
        let keys = self.keys.as_ref().expect("identity exchange keys");
        let transcript_sha256 = current_transcript_sha256(self, &invitation);
        let plaintext = PairingPlaintext {
            payload: Some(pairing_plaintext::Payload::ControllerReady(
                ControllerPairingReady {
                    transcript_sha256: transcript_sha256.to_vec(),
                },
            )),
        }
        .encode_to_vec();
        seal_controller_message(
            &keys.controller_to_host,
            &invitation,
            &self.controller.device_id,
            &plaintext,
        )
    }

    fn exchange_identity(&mut self) -> PairingKeySchedule {
        self.send_hello();
        let ready = self.controller_ready();
        self.coordinator
            .handle_signaling_event(
                SignalingEvent::RoutedPairing {
                    rendezvous_id: RENDEZVOUS_ID.to_vec(),
                    sender_device_id: self.controller.device_id.clone(),
                    opaque_envelope: ready,
                },
                &self.host,
                NOW + 3,
            )
            .expect("Controller ready");
        self.keys.clone().expect("keys")
    }
}

#[derive(Clone, Copy)]
enum HelloMutation {
    Sender,
    Identity,
    Transcript,
    Signature,
}

fn assert_hello_rejected(mutation: HelloMutation) {
    let mut harness = Harness::joined(PairingInvitationKind::Qr);
    let mut sender = harness.controller.device_id.clone();
    let mut message = PairingMessage::decode(harness.controller_hello().as_slice())
        .expect("Controller hello message");
    let Some(pairing_message::Payload::ControllerHello(hello)) = message.payload.as_mut() else {
        panic!("Controller hello payload");
    };
    match mutation {
        HelloMutation::Sender => sender[0] ^= 0x01,
        HelloMutation::Identity => {
            hello
                .identity
                .as_mut()
                .expect("Controller identity")
                .device_id[0] ^= 0x01;
        }
        HelloMutation::Transcript => hello.transcript_sha256[0] ^= 0x01,
        HelloMutation::Signature => hello.signature[0] ^= 0x01,
    }
    assert_eq!(
        harness.coordinator.handle_signaling_event(
            SignalingEvent::RoutedPairing {
                rendezvous_id: RENDEZVOUS_ID.to_vec(),
                sender_device_id: sender,
                opaque_envelope: message.encode_to_vec(),
            },
            &harness.host,
            NOW + 2,
        ),
        Err(PairingCoordinatorError::Authentication)
    );
    assert_eq!(
        harness.coordinator.snapshot().state,
        HostPairingState::Failed as i32
    );
    assert!(harness.registry.list_controller_grants().is_empty());
}

struct FixedRandom {
    bytes: VecDeque<u8>,
}

impl FixedRandom {
    fn new() -> Self {
        let mut bytes = VecDeque::new();
        bytes.extend([0x51; 16]);
        bytes.extend([0x41; 32]);
        bytes.extend([0x00; 5]);
        Self { bytes }
    }
}

impl PairingRandom for FixedRandom {
    fn fill(&mut self, output: &mut [u8]) -> Result<(), PairingRandomError> {
        for value in output {
            *value = self
                .bytes
                .pop_front()
                .ok_or(PairingRandomError::Unavailable)?;
        }
        Ok(())
    }
}

fn host_identity() -> HostIdentity {
    let store = MemorySecretStore::new();
    store.store(&[0x42; 32]).expect("Host seed");
    HostIdentity::load_or_create(&store, "Office Mac", DevicePlatform::Macos)
        .expect("Host identity")
}

fn controller_identity(key: &SigningKey) -> DeviceIdentity {
    let public_key = key.verifying_key().to_bytes();
    DeviceIdentity {
        device_id: derive_device_id_v1(&public_key)
            .expect("Controller ID")
            .to_vec(),
        public_key_algorithm: PublicKeyAlgorithm::Ed25519 as i32,
        public_key: public_key.to_vec(),
        display_name: "My Phone".to_owned(),
        platform: DevicePlatform::Ios as i32,
    }
}

fn pairing_transcript(
    controller: &DeviceIdentity,
    host: &DeviceIdentity,
    rendezvous_id: &[u8],
    controller_ephemeral_public_key: &[u8],
    host_ephemeral_public_key: &[u8],
) -> Vec<u8> {
    let values = [
        controller.device_id.as_slice(),
        host.device_id.as_slice(),
        rendezvous_id,
        controller.public_key.as_slice(),
        host.public_key.as_slice(),
        controller_ephemeral_public_key,
        host_ephemeral_public_key,
    ];
    encode(&CanonicalTranscript {
        purpose: TranscriptPurpose::PairingSas,
        fields: values
            .into_iter()
            .enumerate()
            .map(|(index, value)| TranscriptField {
                tag: u16::try_from(index + 1).expect("tag"),
                value: value.to_vec(),
            })
            .collect(),
    })
    .expect("pairing transcript")
}

fn current_transcript_sha256(
    harness: &Harness,
    invitation: &roammand_protocol::roammand::v1::HostPairingInvitation,
) -> [u8; 32] {
    let controller_ephemeral_public =
        x25519_public_key(&CONTROLLER_EPHEMERAL_PRIVATE).expect("Controller public key");
    sha256(&pairing_transcript(
        &harness.controller,
        invitation.host_identity.as_ref().expect("Host identity"),
        &invitation.rendezvous_id,
        &controller_ephemeral_public,
        &invitation.host_ephemeral_public_key,
    ))
}

fn seal_controller_message(
    key: &[u8],
    invitation: &roammand_protocol::roammand::v1::HostPairingInvitation,
    controller_device_id: &[u8],
    plaintext: &[u8],
) -> Vec<u8> {
    let host_device_id = &invitation
        .host_identity
        .as_ref()
        .expect("Host identity")
        .device_id;
    let aad = pairing_aad(
        CryptoDirection::ControllerToHost,
        1,
        &invitation.rendezvous_id,
        controller_device_id,
        host_device_id,
    )
    .expect("Controller AAD");
    let ciphertext =
        seal_pairing_payload(key, CryptoDirection::ControllerToHost, 1, &aad, plaintext)
            .expect("Controller encryption");
    PairingMessage {
        payload: Some(pairing_message::Payload::EncryptedEnvelope(
            EncryptedPairingEnvelope {
                protocol_version: Some(ProtocolVersion { major: 1, minor: 0 }),
                rendezvous_id: invitation.rendezvous_id.clone(),
                direction: PairingDirection::ControllerToHost as i32,
                sequence: 1,
                ciphertext,
            },
        )),
    }
    .encode_to_vec()
}

fn decrypt_final_decision(
    outbound: &PairingOutbound,
    keys: &PairingKeySchedule,
    harness: &Harness,
) -> roammand_protocol::roammand::v1::PairingFinalDecision {
    let PairingOutbound::Relay {
        opaque_envelope, ..
    } = outbound
    else {
        panic!("expected final decision relay");
    };
    decrypt_final_decision_bytes(opaque_envelope, keys, harness).expect("final decision")
}

fn verify_host_proof(outbound: &PairingOutbound, harness: &Harness) {
    let PairingOutbound::Relay {
        opaque_envelope, ..
    } = outbound
    else {
        panic!("expected Host proof relay");
    };
    let message = PairingMessage::decode(opaque_envelope.as_slice()).expect("Host proof message");
    let Some(pairing_message::Payload::EncryptedEnvelope(envelope)) = message.payload else {
        panic!("encrypted Host proof");
    };
    assert_eq!(
        envelope.direction,
        PairingDirection::HostToController as i32
    );
    assert_eq!(envelope.sequence, 1);
    let invitation = harness.invitation();
    let host = invitation.host_identity.as_ref().expect("Host identity");
    let aad = pairing_aad(
        CryptoDirection::HostToController,
        1,
        &invitation.rendezvous_id,
        &harness.controller.device_id,
        &host.device_id,
    )
    .expect("Host proof AAD");
    let plaintext = open_pairing_payload(
        &harness
            .keys
            .as_ref()
            .expect("pairing keys")
            .host_to_controller,
        CryptoDirection::HostToController,
        1,
        &aad,
        &envelope.ciphertext,
    )
    .expect("Host proof authentication");
    let plaintext = PairingPlaintext::decode(plaintext.as_slice()).expect("Host proof plaintext");
    let Some(pairing_plaintext::Payload::HostProof(proof)) = plaintext.payload else {
        panic!("Host proof payload");
    };
    assert_eq!(proof.expires_at_unix_ms, LOCAL_EXPIRES);
    let confirmation = proof.confirmation.expect("confirmation data");
    assert_eq!(
        confirmation.controller_device_id,
        harness.controller.device_id
    );
    assert_eq!(confirmation.host_device_id, host.device_id);
    assert_eq!(confirmation.rendezvous_id, RENDEZVOUS_ID);
    assert_eq!(
        confirmation.transcript_sha256,
        current_transcript_sha256(harness, &invitation)
    );
    let host_public_key: [u8; 32] = host
        .public_key
        .as_slice()
        .try_into()
        .expect("Host public key");
    let signature = Signature::try_from(proof.host_signature.as_slice()).expect("Host signature");
    let controller_ephemeral_public =
        x25519_public_key(&CONTROLLER_EPHEMERAL_PRIVATE).expect("Controller public key");
    let transcript = pairing_transcript(
        &harness.controller,
        host,
        &invitation.rendezvous_id,
        &controller_ephemeral_public,
        &invitation.host_ephemeral_public_key,
    );
    VerifyingKey::from_bytes(&host_public_key)
        .expect("Host verifying key")
        .verify(&transcript, &signature)
        .expect("Host proof signature");
}

fn decrypt_final_decision_bytes(
    opaque: &[u8],
    keys: &PairingKeySchedule,
    harness: &Harness,
) -> Option<roammand_protocol::roammand::v1::PairingFinalDecision> {
    let message = PairingMessage::decode(opaque).ok()?;
    let pairing_message::Payload::EncryptedEnvelope(envelope) = message.payload? else {
        return None;
    };
    let invitation = harness.invitation();
    let host_device_id = &invitation.host_identity.as_ref()?.device_id;
    let aad = pairing_aad(
        CryptoDirection::HostToController,
        2,
        &invitation.rendezvous_id,
        &harness.controller.device_id,
        host_device_id,
    )
    .ok()?;
    let plaintext = open_pairing_payload(
        &keys.host_to_controller,
        CryptoDirection::HostToController,
        2,
        &aad,
        &envelope.ciphertext,
    )
    .ok()?;
    let plaintext = PairingPlaintext::decode(plaintext.as_slice()).ok()?;
    let pairing_plaintext::Payload::FinalDecision(decision) = plaintext.payload? else {
        return None;
    };
    Some(decision)
}

const fn signaling_kind(kind: PairingInvitationKind) -> PairingRendezvousKind {
    match kind {
        PairingInvitationKind::Qr => PairingRendezvousKind::Qr,
        PairingInvitationKind::DesktopCode => PairingRendezvousKind::DesktopCode,
        PairingInvitationKind::Unspecified => PairingRendezvousKind::Unspecified,
    }
}
