// SPDX-License-Identifier: MPL-2.0

use std::sync::{Arc, Mutex};

use roammand_privileged_bridge::{
    broker::{BrokerCore, BrokerHelper, BrokerProtocolError, HostBrokerSession},
    session::{DesktopKind, Platform, RouteEvent, RouteSession},
};
use roammand_protocol::roammand::v1::{
    AcquirePrivilegedLeaseRequest, KeyboardAction, KeyboardEvent, PrivilegedBridgeClientFrame,
    PrivilegedBridgeServerFrame, PrivilegedCommandAccepted, PrivilegedIceTransportPolicy,
    PrivilegedInputCommand, PrivilegedPeerConfiguration, ProtocolVersion,
    ReleasePrivilegedLeaseRequest, RenewPrivilegedLeaseRequest, SendSecureAttentionRequest,
    SessionDescriptionType, SessionPermission, StartPrivilegedPeerRequest,
    WebRtcSessionDescription, privileged_bridge_client_frame, privileged_bridge_server_frame,
    privileged_input_command,
};

struct FakeHelper {
    seen: Arc<Mutex<Vec<PrivilegedBridgeClientFrame>>>,
}

impl BrokerHelper for FakeHelper {
    fn exchange(
        &mut self,
        request: PrivilegedBridgeClientFrame,
    ) -> Result<PrivilegedBridgeServerFrame, BrokerProtocolError> {
        let (lease_id, generation) = request_route(&request).expect("route");
        self.seen.lock().expect("seen").push(request.clone());
        Ok(PrivilegedBridgeServerFrame {
            protocol_version: Some(version()),
            request_id: request.request_id,
            sequence: request.sequence,
            payload: Some(privileged_bridge_server_frame::Payload::CommandAccepted(
                PrivilegedCommandAccepted {
                    lease_id,
                    generation,
                },
            )),
        })
    }

    fn fail_closed(&mut self) {}
}

#[test]
fn acquires_renews_forwards_and_releases_one_route_bound_lease() {
    let broker = prepared_broker([0x11; 16]);
    let seen = Arc::new(Mutex::new(Vec::new()));
    let helper = FakeHelper {
        seen: Arc::clone(&seen),
    };
    let mut session = HostBrokerSession::new(broker, Box::new(helper));

    let acquired = session
        .handle(acquire_request(1, true), 1_000)
        .expect("acquire");
    let privileged_bridge_server_frame::Payload::Lease(lease) = acquired.payload.expect("lease")
    else {
        panic!("unexpected acquire response");
    };
    assert_eq!(lease.generation, 7);
    assert_eq!(lease.permissions.len(), 2);

    let renewed = session
        .handle(
            client_frame(
                2,
                privileged_bridge_client_frame::Payload::RenewLease(RenewPrivilegedLeaseRequest {
                    lease_id: lease.lease_id.clone(),
                    generation: 7,
                }),
            ),
            6_000,
        )
        .expect("renew");
    assert!(matches!(
        renewed.payload,
        Some(privileged_bridge_server_frame::Payload::Lease(_))
    ));

    let input = client_frame(
        3,
        privileged_bridge_client_frame::Payload::InputCommand(PrivilegedInputCommand {
            lease_id: lease.lease_id.clone(),
            generation: 7,
            input: Some(privileged_input_command::Input::Keyboard(KeyboardEvent {
                action: KeyboardAction::Down as i32,
                usb_hid_usage: 4,
                modifier_bits: 0,
            })),
        }),
    );
    assert!(matches!(
        session.handle(input, 6_001).expect("input").payload,
        Some(privileged_bridge_server_frame::Payload::CommandAccepted(_))
    ));

    assert!(matches!(
        session
            .handle(
                client_frame(
                    4,
                    privileged_bridge_client_frame::Payload::ReleaseLease(
                        ReleasePrivilegedLeaseRequest {
                            lease_id: lease.lease_id,
                            generation: 7,
                        },
                    ),
                ),
                6_002,
            )
            .expect("release")
            .payload,
        Some(privileged_bridge_server_frame::Payload::CommandAccepted(_))
    ));
    assert_eq!(seen.lock().expect("seen").len(), 2);
}

#[test]
fn control_input_is_never_forwarded_without_the_lease_permission() {
    let broker = prepared_broker([0x12; 16]);
    let seen = Arc::new(Mutex::new(Vec::new()));
    let helper = FakeHelper {
        seen: Arc::clone(&seen),
    };
    let mut session = HostBrokerSession::new(broker, Box::new(helper));
    let acquired = session
        .handle(acquire_request(1, false), 1_000)
        .expect("acquire");
    let privileged_bridge_server_frame::Payload::Lease(lease) = acquired.payload.expect("lease")
    else {
        panic!("unexpected acquire response");
    };
    let input = client_frame(
        2,
        privileged_bridge_client_frame::Payload::InputCommand(PrivilegedInputCommand {
            lease_id: lease.lease_id,
            generation: 7,
            input: Some(privileged_input_command::Input::Keyboard(KeyboardEvent {
                action: KeyboardAction::Down as i32,
                usb_hid_usage: 4,
                modifier_bits: 0,
            })),
        }),
    );

    assert_eq!(
        session.handle(input, 1_001),
        Err(BrokerProtocolError::PermissionDenied)
    );
    assert!(seen.lock().expect("seen").is_empty());
}

#[test]
fn secure_attention_requires_the_broker_assigned_protected_route() {
    let seen = Arc::new(Mutex::new(Vec::new()));
    let helper = FakeHelper {
        seen: Arc::clone(&seen),
    };
    let mut session = HostBrokerSession::new(prepared_broker([0x13; 16]), Box::new(helper));
    let acquired = session
        .handle(acquire_request(1, true), 1_000)
        .expect("acquire");
    let privileged_bridge_server_frame::Payload::Lease(lease) = acquired.payload.expect("lease")
    else {
        panic!("unexpected acquire response");
    };
    let request = client_frame(
        2,
        privileged_bridge_client_frame::Payload::SendSecureAttention(SendSecureAttentionRequest {
            lease_id: lease.lease_id.clone(),
            generation: 7,
        }),
    );
    assert_eq!(
        session.handle(request.clone(), 1_001),
        Err(BrokerProtocolError::PermissionDenied)
    );
    assert!(seen.lock().expect("seen").is_empty());

    let helper = FakeHelper {
        seen: Arc::clone(&seen),
    };
    let mut protected = HostBrokerSession::new(prepared_broker([0x14; 16]), Box::new(helper))
        .with_secure_attention(true);
    let acquired = protected
        .handle(acquire_request(1, true), 1_000)
        .expect("protected acquire");
    let privileged_bridge_server_frame::Payload::Lease(lease) = acquired.payload.expect("lease")
    else {
        panic!("unexpected protected acquire response");
    };
    let request = client_frame(
        2,
        privileged_bridge_client_frame::Payload::SendSecureAttention(SendSecureAttentionRequest {
            lease_id: lease.lease_id,
            generation: 7,
        }),
    );
    assert!(protected.handle(request, 1_001).is_ok());
    assert_eq!(seen.lock().expect("seen").len(), 1);
}

#[test]
fn peer_start_name_must_match_the_authenticated_lease() {
    let seen = Arc::new(Mutex::new(Vec::new()));
    let helper = FakeHelper {
        seen: Arc::clone(&seen),
    };
    let mut session = HostBrokerSession::new(prepared_broker([0x15; 16]), Box::new(helper));
    let acquired = session
        .handle(acquire_request(1, true), 1_000)
        .expect("acquire");
    let privileged_bridge_server_frame::Payload::Lease(lease) = acquired.payload.expect("lease")
    else {
        panic!("unexpected acquire response");
    };
    let request = client_frame(
        2,
        privileged_bridge_client_frame::Payload::StartPeer(StartPrivilegedPeerRequest {
            lease_id: lease.lease_id,
            generation: lease.generation,
            configuration: Some(PrivilegedPeerConfiguration {
                ice_transport_policy: PrivilegedIceTransportPolicy::All as i32,
                ice_servers: Vec::new(),
            }),
            offer: Some(WebRtcSessionDescription {
                r#type: SessionDescriptionType::Offer as i32,
                sdp: "offer".to_owned(),
                dtls_fingerprint_sha256: vec![0x41; 32],
            }),
            controller_display_name: "Impostor".to_owned(),
        }),
    );

    assert_eq!(
        session.handle(request, 1_001),
        Err(BrokerProtocolError::InvalidMessage)
    );
    assert!(seen.lock().expect("seen").is_empty());
}

fn acquire_request(sequence: u64, control: bool) -> PrivilegedBridgeClientFrame {
    let mut permissions = vec![SessionPermission::ViewScreen as i32];
    if control {
        permissions.push(SessionPermission::ControlInput as i32);
    }
    client_frame(
        sequence,
        privileged_bridge_client_frame::Payload::AcquireLease(AcquirePrivilegedLeaseRequest {
            session_id: vec![0x31; 16],
            generation: 7,
            permissions,
            controller_display_name: "Controller".to_owned(),
        }),
    )
}

fn client_frame(
    sequence: u64,
    payload: privileged_bridge_client_frame::Payload,
) -> PrivilegedBridgeClientFrame {
    PrivilegedBridgeClientFrame {
        protocol_version: Some(version()),
        request_id: format!("request-{sequence}"),
        sequence,
        payload: Some(payload),
    }
}

const fn version() -> ProtocolVersion {
    ProtocolVersion { major: 1, minor: 0 }
}

fn request_route(request: &PrivilegedBridgeClientFrame) -> Option<(Vec<u8>, u64)> {
    match request.payload.as_ref()? {
        privileged_bridge_client_frame::Payload::InputCommand(value) => {
            Some((value.lease_id.clone(), value.generation))
        }
        privileged_bridge_client_frame::Payload::ReleaseLease(value) => {
            Some((value.lease_id.clone(), value.generation))
        }
        privileged_bridge_client_frame::Payload::SendSecureAttention(value) => {
            Some((value.lease_id.clone(), value.generation))
        }
        privileged_bridge_client_frame::Payload::StartPeer(value) => {
            Some((value.lease_id.clone(), value.generation))
        }
        _ => None,
    }
}

fn prepared_broker(instance_id: [u8; 16]) -> BrokerCore {
    let mut broker = BrokerCore::new(instance_id);
    broker
        .observe_route(RouteEvent::SessionAvailable(RouteSession {
            platform: Platform::Macos,
            os_session_id: 501,
            desktop: DesktopKind::Normal,
            generation: 7,
        }))
        .expect("route");
    broker.connect_host(7).expect("host");
    broker
}
