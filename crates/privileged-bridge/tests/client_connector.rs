// SPDX-License-Identifier: MPL-2.0

use std::{
    collections::VecDeque,
    sync::{Arc, Mutex},
};

use prost::Message;
use roammand_ipc::{AuthChannel, IpcToken, channel_server_proof};
use roammand_privileged_bridge::{
    client::{AuthenticatedBridgeConnector, BridgeRpcConnector, BridgeTransportConnector},
    proxy::{ProxyError, ProxySessionContext},
    transport::{LocalBridgeTransport, TransportError},
};
use roammand_protocol::{
    roammand::v1::{
        AcquirePrivilegedLeaseRequest, DevicePlatform, InteractiveDesktopKind,
        PrivilegedBridgeAuthenticated, PrivilegedBridgeChallenge, PrivilegedBridgeClientFrame,
        PrivilegedBridgeServerFrame, PrivilegedBridgeState, PrivilegedBridgeStatusSnapshot,
        PrivilegedLease, PrivilegedSessionDescriptor, ProtocolVersion, SessionPermission,
        privileged_bridge_client_frame, privileged_bridge_server_frame,
    },
    validation::decode_and_validate_privileged_bridge_client_frame,
};

const TOKEN_BYTES: [u8; 32] = [0x31; 32];
const INSTANCE_ID: [u8; 16] = [0x41; 16];
const SERVER_NONCE: [u8; 32] = [0x51; 32];
const EXECUTABLE_HASH: [u8; 32] = [0x61; 32];

struct FakeConnector {
    state: Arc<Mutex<FakeState>>,
}

struct FakeState {
    incoming: VecDeque<Vec<u8>>,
    sent: Vec<PrivilegedBridgeClientFrame>,
    failed: bool,
    corrupt_server_proof: bool,
}

struct FakeTransport {
    state: Arc<Mutex<FakeState>>,
}

impl BridgeTransportConnector for FakeConnector {
    fn connect(&mut self) -> Result<Box<dyn LocalBridgeTransport>, ProxyError> {
        Ok(Box::new(FakeTransport {
            state: Arc::clone(&self.state),
        }))
    }
}

impl LocalBridgeTransport for FakeTransport {
    fn send(&mut self, frame: &[u8]) -> Result<(), TransportError> {
        let request = decode_and_validate_privileged_bridge_client_frame(frame)
            .map_err(|_| TransportError::FailedClosed)?;
        let mut state = self.state.lock().expect("state");
        state.sent.push(request.clone());
        match request.payload.as_ref().expect("payload") {
            privileged_bridge_client_frame::Payload::Authenticate(authenticate) => {
                let client_nonce: [u8; 32] = authenticate
                    .client_nonce
                    .as_slice()
                    .try_into()
                    .expect("nonce");
                let mut proof = channel_server_proof(
                    &IpcToken::new(TOKEN_BYTES),
                    AuthChannel::PrivilegedHost,
                    &INSTANCE_ID,
                    &SERVER_NONCE,
                    &client_nonce,
                );
                if state.corrupt_server_proof {
                    proof[0] ^= 0xff;
                }
                state.incoming.push_back(
                    server_frame(
                        &request.request_id,
                        request.sequence,
                        privileged_bridge_server_frame::Payload::Authenticated(
                            PrivilegedBridgeAuthenticated {
                                server_proof: proof.to_vec(),
                            },
                        ),
                    )
                    .encode_to_vec(),
                );
                state.incoming.push_back(
                    server_frame(
                        "status-1",
                        1,
                        privileged_bridge_server_frame::Payload::Status(ready_status()),
                    )
                    .encode_to_vec(),
                );
            }
            privileged_bridge_client_frame::Payload::AcquireLease(acquire) => {
                state.incoming.push_back(
                    server_frame(
                        &request.request_id,
                        request.sequence,
                        privileged_bridge_server_frame::Payload::Lease(lease(acquire)),
                    )
                    .encode_to_vec(),
                );
            }
            _ => return Err(TransportError::FailedClosed),
        }
        Ok(())
    }

    fn receive(&mut self) -> Result<Vec<u8>, TransportError> {
        self.state
            .lock()
            .expect("state")
            .incoming
            .pop_front()
            .ok_or(TransportError::Disconnected)
    }

    fn try_receive(&mut self) -> Result<Option<Vec<u8>>, TransportError> {
        Ok(self.state.lock().expect("state").incoming.pop_front())
    }

    fn fail_closed(&mut self) {
        self.state.lock().expect("state").failed = true;
    }
}

#[test]
fn authenticates_discovers_the_route_and_acquires_the_exact_verified_lease() {
    let state = fake_state(false);
    let mut connector = AuthenticatedBridgeConnector::new(
        Box::new(FakeConnector {
            state: Arc::clone(&state),
        }),
        IpcToken::new(TOKEN_BYTES),
        EXECUTABLE_HASH,
        501,
    )
    .expect("connector");
    let context = ProxySessionContext::new(
        vec![0x71; 16],
        vec![
            SessionPermission::ViewScreen,
            SessionPermission::ControlInput,
        ],
        "Controller".to_owned(),
    )
    .expect("context");

    let connection = connector.connect(&context).expect("connection");
    assert_eq!(connection.route().generation, 7);
    let state = state.lock().expect("state");
    assert!(!state.failed);
    let privileged_bridge_client_frame::Payload::Authenticate(authenticate) =
        state.sent[0].payload.as_ref().expect("authenticate")
    else {
        panic!("unexpected first request");
    };
    assert_eq!(authenticate.executable_sha256, EXECUTABLE_HASH);
    assert_eq!(authenticate.os_session_id, 501);
    let privileged_bridge_client_frame::Payload::AcquireLease(acquire) =
        state.sent[1].payload.as_ref().expect("acquire")
    else {
        panic!("unexpected second request");
    };
    assert_eq!(acquire.session_id, context.session_id());
    assert_eq!(acquire.generation, 7);
    assert_eq!(
        acquire.permissions,
        vec![
            SessionPermission::ViewScreen as i32,
            SessionPermission::ControlInput as i32,
        ]
    );
}

#[test]
fn rejects_an_invalid_broker_proof_before_acquiring_a_lease() {
    let state = fake_state(true);
    let mut connector = AuthenticatedBridgeConnector::new(
        Box::new(FakeConnector {
            state: Arc::clone(&state),
        }),
        IpcToken::new(TOKEN_BYTES),
        EXECUTABLE_HASH,
        501,
    )
    .expect("connector");
    let context = ProxySessionContext::new(
        vec![0x71; 16],
        vec![SessionPermission::ViewScreen],
        "Controller".to_owned(),
    )
    .expect("context");

    assert!(matches!(
        connector.connect(&context),
        Err(ProxyError::Rejected)
    ));
    let state = state.lock().expect("state");
    assert!(state.failed);
    assert_eq!(state.sent.len(), 1);
}

fn fake_state(corrupt_server_proof: bool) -> Arc<Mutex<FakeState>> {
    Arc::new(Mutex::new(FakeState {
        incoming: VecDeque::from([server_frame(
            "challenge-1",
            1,
            privileged_bridge_server_frame::Payload::Challenge(PrivilegedBridgeChallenge {
                broker_instance_id: INSTANCE_ID.to_vec(),
                server_nonce: SERVER_NONCE.to_vec(),
            }),
        )
        .encode_to_vec()]),
        sent: Vec::new(),
        failed: false,
        corrupt_server_proof,
    }))
}

fn ready_status() -> PrivilegedBridgeStatusSnapshot {
    PrivilegedBridgeStatusSnapshot {
        state: PrivilegedBridgeState::Ready as i32,
        interactive_session: Some(PrivilegedSessionDescriptor {
            platform: DevicePlatform::Macos as i32,
            os_session_id: 501,
            desktop_kind: InteractiveDesktopKind::Normal as i32,
            generation: 7,
        }),
        helper_connected: true,
        active_controller_display_name: String::new(),
        error: None,
    }
}

fn lease(acquire: &AcquirePrivilegedLeaseRequest) -> PrivilegedLease {
    PrivilegedLease {
        lease_id: vec![0x81; 16],
        generation: acquire.generation,
        issued_at_unix_ms: 10,
        expires_at_unix_ms: 20,
        session_id: acquire.session_id.clone(),
        permissions: acquire.permissions.clone(),
        controller_display_name: acquire.controller_display_name.clone(),
    }
}

fn server_frame(
    request_id: &str,
    sequence: u64,
    payload: privileged_bridge_server_frame::Payload,
) -> PrivilegedBridgeServerFrame {
    PrivilegedBridgeServerFrame {
        protocol_version: Some(ProtocolVersion { major: 1, minor: 0 }),
        request_id: request_id.to_owned(),
        sequence,
        payload: Some(payload),
    }
}
