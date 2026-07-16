// SPDX-License-Identifier: MPL-2.0

use std::sync::Arc;

use ed25519_dalek::{Signer, SigningKey};
use roammand_host_agent::{
    AuthorizationRegistry, MemoryGrantStore, OfferVerifier, SessionAuthenticationError,
    encode_session_offer_transcript,
};
use roammand_protocol::{
    canonical_transcript::sha256,
    identity_derivation::derive_device_id_v1,
    roammand::v1::{
        DeviceIdentity, DevicePlatform, PublicKeyAlgorithm, SessionOfferAuthentication,
        SessionPermission,
    },
};

const NOW_UNIX_MS: u64 = 1_900_000_000_000;
const OFFER_SDP: &str = "v=0\r\na=fingerprint:sha-256 AA:BB\r\n";
const HOST_DEVICE_ID: [u8; 32] = [0x31; 32];
const CONTROLLER_FINGERPRINT: [u8; 32] = [0x41; 32];

#[test]
fn verifies_an_authorized_offer_once() {
    let mut fixture = Fixture::new(&[
        SessionPermission::ViewScreen,
        SessionPermission::ControlInput,
    ]);
    let authentication = fixture.signed_offer(&[
        SessionPermission::ViewScreen,
        SessionPermission::ControlInput,
    ]);

    let verified = fixture
        .verifier
        .verify(
            &authentication,
            OFFER_SDP,
            &CONTROLLER_FINGERPRINT,
            &fixture.authorization,
            NOW_UNIX_MS,
        )
        .expect("valid offer must authenticate");

    assert_eq!(verified.controller.device_id, fixture.controller.device_id);
    assert_eq!(verified.session_id, authentication.session_id);
    assert_eq!(
        verified.permissions,
        vec![
            SessionPermission::ViewScreen,
            SessionPermission::ControlInput
        ]
    );
    assert_eq!(
        fixture.verifier.verify(
            &authentication,
            OFFER_SDP,
            &CONTROLLER_FINGERPRINT,
            &fixture.authorization,
            NOW_UNIX_MS,
        ),
        Err(SessionAuthenticationError::Replay)
    );
}

#[test]
fn rejects_offer_before_peer_creation_for_every_security_binding() {
    let cases = [
        Case::InvalidSignature,
        Case::HostMismatch,
        Case::OfferHashMismatch,
        Case::FingerprintMismatch,
        Case::NotYetValid,
        Case::Expired,
        Case::LifetimeTooLong,
        Case::DuplicatePermission,
        Case::PermissionDenied,
        Case::ControllerNotAuthorized,
    ];

    for case in cases {
        let mut fixture = Fixture::new(&[SessionPermission::ViewScreen]);
        let mut authentication = fixture.signed_offer(&[SessionPermission::ViewScreen]);
        let mut offer_sdp = OFFER_SDP;
        let mut fingerprint = CONTROLLER_FINGERPRINT;
        let mut now = NOW_UNIX_MS;
        match case {
            Case::InvalidSignature => authentication.signature[0] ^= 0xff,
            Case::HostMismatch => {
                authentication.host_device_id = vec![0x99; 32];
                fixture.resign(&mut authentication);
            }
            Case::OfferHashMismatch => offer_sdp = "v=0\r\nchanged\r\n",
            Case::FingerprintMismatch => fingerprint = [0x55; 32],
            Case::NotYetValid => now = authentication.issued_at_unix_ms - 10_001,
            Case::Expired => now = authentication.expires_at_unix_ms + 1,
            Case::LifetimeTooLong => {
                authentication.expires_at_unix_ms = authentication.issued_at_unix_ms + 30_001;
                fixture.resign(&mut authentication);
            }
            Case::DuplicatePermission => {
                authentication
                    .requested_permissions
                    .push(SessionPermission::ViewScreen as i32);
            }
            Case::PermissionDenied => {
                authentication.requested_permissions = vec![
                    SessionPermission::ViewScreen as i32,
                    SessionPermission::ControlInput as i32,
                ];
                fixture.resign(&mut authentication);
            }
            Case::ControllerNotAuthorized => {
                fixture.authorization = AuthorizationRegistry::load(
                    HOST_DEVICE_ID.to_vec(),
                    Arc::new(MemoryGrantStore::new()),
                )
                .expect("empty authorization registry must load");
            }
        }

        assert_eq!(
            fixture.verifier.verify(
                &authentication,
                offer_sdp,
                &fingerprint,
                &fixture.authorization,
                now,
            ),
            Err(case.expected()),
            "case {case:?}"
        );
    }
}

#[derive(Clone, Copy, Debug)]
enum Case {
    InvalidSignature,
    HostMismatch,
    OfferHashMismatch,
    FingerprintMismatch,
    NotYetValid,
    Expired,
    LifetimeTooLong,
    DuplicatePermission,
    PermissionDenied,
    ControllerNotAuthorized,
}

impl Case {
    const fn expected(self) -> SessionAuthenticationError {
        match self {
            Self::InvalidSignature => SessionAuthenticationError::InvalidSignature,
            Self::HostMismatch => SessionAuthenticationError::HostMismatch,
            Self::OfferHashMismatch => SessionAuthenticationError::OfferHashMismatch,
            Self::FingerprintMismatch => SessionAuthenticationError::FingerprintMismatch,
            Self::NotYetValid => SessionAuthenticationError::NotYetValid,
            Self::Expired => SessionAuthenticationError::Expired,
            Self::LifetimeTooLong => SessionAuthenticationError::LifetimeTooLong,
            Self::DuplicatePermission => SessionAuthenticationError::InvalidPermissions,
            Self::PermissionDenied => SessionAuthenticationError::PermissionDenied,
            Self::ControllerNotAuthorized => SessionAuthenticationError::ControllerNotAuthorized,
        }
    }
}

struct Fixture {
    controller_key: SigningKey,
    controller: DeviceIdentity,
    authorization: AuthorizationRegistry,
    verifier: OfferVerifier,
}

impl Fixture {
    fn new(granted_permissions: &[SessionPermission]) -> Self {
        let controller_key = SigningKey::from_bytes(&[0x61; 32]);
        let public_key = controller_key.verifying_key().to_bytes();
        let controller = DeviceIdentity {
            device_id: derive_device_id_v1(&public_key)
                .expect("controller ID must derive")
                .to_vec(),
            public_key_algorithm: PublicKeyAlgorithm::Ed25519 as i32,
            public_key: public_key.to_vec(),
            display_name: "Controller".to_owned(),
            platform: DevicePlatform::Macos as i32,
        };
        let mut authorization =
            AuthorizationRegistry::load(HOST_DEVICE_ID.to_vec(), Arc::new(MemoryGrantStore::new()))
                .expect("authorization registry must load");
        authorization
            .create_controller_grant(controller.clone(), granted_permissions, NOW_UNIX_MS - 1)
            .expect("test grant must be created");
        Self {
            controller_key,
            controller,
            authorization,
            verifier: OfferVerifier::new(HOST_DEVICE_ID.to_vec())
                .expect("Host device ID must be valid"),
        }
    }

    fn signed_offer(&self, permissions: &[SessionPermission]) -> SessionOfferAuthentication {
        let mut authentication = SessionOfferAuthentication {
            controller_device_id: self.controller.device_id.clone(),
            host_device_id: HOST_DEVICE_ID.to_vec(),
            session_id: vec![0x71; 16],
            nonce: vec![0x72; 32],
            issued_at_unix_ms: NOW_UNIX_MS - 5_000,
            expires_at_unix_ms: NOW_UNIX_MS + 5_000,
            requested_permissions: permissions
                .iter()
                .map(|permission| *permission as i32)
                .collect(),
            offer_sha256: sha256(OFFER_SDP.as_bytes()).to_vec(),
            controller_dtls_fingerprint_sha256: CONTROLLER_FINGERPRINT.to_vec(),
            signature: Vec::new(),
        };
        self.resign(&mut authentication);
        authentication
    }

    fn resign(&self, authentication: &mut SessionOfferAuthentication) {
        authentication.signature = self
            .controller_key
            .sign(
                &encode_session_offer_transcript(authentication)
                    .expect("test offer transcript must encode"),
            )
            .to_bytes()
            .to_vec();
    }
}
