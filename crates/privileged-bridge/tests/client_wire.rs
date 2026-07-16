// SPDX-License-Identifier: MPL-2.0

use std::sync::{
    Arc, Mutex,
    atomic::{AtomicU64, Ordering},
};

use roammand_host_webrtc::{IceTransportPolicy, PeerIceCandidate, SessionConfig};
use roammand_privileged_bridge::{
    client::{
        BridgeClock, BridgeConnection, BridgeIceServer, BridgePeerOptions, BridgeRpc,
        BridgeRpcConnector, ProtobufBridgeWire, RpcProxyPartsFactory,
    },
    lease::LeaseId,
    proxy::{
        BridgeRequest, BridgeWire, ProxyError, ProxyEvent, ProxyPartsFactory, ProxyRoute,
        ProxySessionContext, ValidatedInput,
    },
};
use roammand_protocol::roammand::v1::{
    IceCandidate, PrivilegedBridgeClientFrame, PrivilegedBridgeServerFrame,
    PrivilegedCommandAccepted, PrivilegedLease, PrivilegedLocalIceCandidate, PrivilegedPeerAnswer,
    ProtocolVersion, SessionDescriptionType, SessionPermission, TextInputEvent,
    WebRtcSessionDescription, privileged_bridge_client_frame, privileged_bridge_server_frame,
    privileged_input_command,
};

const OFFER_SDP: &str = concat!(
    "v=0\r\n",
    "a=fingerprint:sha-256 ",
    "11:11:11:11:11:11:11:11:11:11:11:11:11:11:11:11:",
    "11:11:11:11:11:11:11:11:11:11:11:11:11:11:11:11\r\n"
);

type ObservedContext = (Vec<u8>, Vec<SessionPermission>, String);

#[derive(Clone, Copy)]
enum ReplyMutation {
    None,
    WrongRequestId,
}

struct FakeRpc {
    calls: Arc<Mutex<Vec<PrivilegedBridgeClientFrame>>>,
    failed: Arc<Mutex<bool>>,
    route: ProxyRoute,
    mutation: ReplyMutation,
    event: Option<PrivilegedBridgeServerFrame>,
}

struct RecordingConnector {
    observed: Arc<Mutex<Vec<ObservedContext>>>,
    route: ProxyRoute,
}

struct FakeClock(Arc<AtomicU64>);

impl BridgeClock for FakeClock {
    fn now_ms(&self) -> u64 {
        self.0.load(Ordering::Relaxed)
    }
}

impl BridgeRpcConnector for RecordingConnector {
    fn connect(&mut self, context: &ProxySessionContext) -> Result<BridgeConnection, ProxyError> {
        self.observed.lock().expect("observed").push((
            context.session_id().to_vec(),
            context.permissions().to_vec(),
            context.controller_display_name().to_owned(),
        ));
        Ok(BridgeConnection::new(
            self.route,
            Box::new(FakeRpc {
                calls: Arc::new(Mutex::new(Vec::new())),
                failed: Arc::new(Mutex::new(false)),
                route: self.route,
                mutation: ReplyMutation::None,
                event: None,
            }),
        ))
    }
}

impl BridgeRpc for FakeRpc {
    fn call(
        &mut self,
        request: PrivilegedBridgeClientFrame,
    ) -> Result<PrivilegedBridgeServerFrame, ProxyError> {
        self.calls.lock().expect("calls").push(request.clone());
        let request_id = match self.mutation {
            ReplyMutation::None => request.request_id.clone(),
            ReplyMutation::WrongRequestId => "stale-request".to_owned(),
        };
        let payload = match request.payload {
            Some(
                privileged_bridge_client_frame::Payload::StartPeer(_)
                | privileged_bridge_client_frame::Payload::RestartPeer(_),
            ) => privileged_bridge_server_frame::Payload::PeerAnswer(PrivilegedPeerAnswer {
                lease_id: self.route.lease_id.into_bytes().to_vec(),
                generation: self.route.generation,
                answer: Some(WebRtcSessionDescription {
                    r#type: SessionDescriptionType::Answer as i32,
                    sdp: "answer-sdp".to_owned(),
                    dtls_fingerprint_sha256: vec![0x22; 32],
                }),
            }),
            Some(privileged_bridge_client_frame::Payload::RenewLease(_)) => {
                privileged_bridge_server_frame::Payload::Lease(PrivilegedLease {
                    lease_id: self.route.lease_id.into_bytes().to_vec(),
                    generation: self.route.generation,
                    issued_at_unix_ms: 5_000,
                    expires_at_unix_ms: 20_000,
                    session_id: vec![0x71; 16],
                    permissions: vec![SessionPermission::ViewScreen as i32],
                    controller_display_name: "Controller".to_owned(),
                })
            }
            Some(_) => privileged_bridge_server_frame::Payload::CommandAccepted(
                PrivilegedCommandAccepted {
                    lease_id: self.route.lease_id.into_bytes().to_vec(),
                    generation: self.route.generation,
                },
            ),
            None => return Err(ProxyError::Transport),
        };
        Ok(PrivilegedBridgeServerFrame {
            protocol_version: Some(version()),
            request_id,
            sequence: request.sequence,
            payload: Some(payload),
        })
    }

    fn try_event(&mut self) -> Result<Option<PrivilegedBridgeServerFrame>, ProxyError> {
        Ok(self.event.take())
    }

    fn fail_closed(&mut self) {
        *self.failed.lock().expect("failed") = true;
    }
}

#[test]
fn maps_typed_peer_input_and_event_messages_without_exposing_credentials() {
    let route = ProxyRoute::new(LeaseId::new([0x41; 16]), 9);
    let calls = Arc::new(Mutex::new(Vec::new()));
    let failed = Arc::new(Mutex::new(false));
    let event_candidate = IceCandidate {
        candidate: "candidate:local".to_owned(),
        sdp_mid: "0".to_owned(),
        sdp_m_line_index: 0,
    };
    let rpc = FakeRpc {
        calls: Arc::clone(&calls),
        failed,
        route,
        mutation: ReplyMutation::None,
        event: Some(PrivilegedBridgeServerFrame {
            protocol_version: Some(version()),
            request_id: "event-1".to_owned(),
            sequence: 1,
            payload: Some(privileged_bridge_server_frame::Payload::LocalIceCandidate(
                PrivilegedLocalIceCandidate {
                    lease_id: route.lease_id.into_bytes().to_vec(),
                    generation: route.generation,
                    candidate: Some(event_candidate.clone()),
                },
            )),
        }),
    };
    let options = BridgePeerOptions::new(vec![
        BridgeIceServer::new(
            vec!["turns:relay.example.test:5349".to_owned()],
            "relay-user".to_owned(),
            "relay-secret".to_owned(),
        )
        .expect("ice server"),
    ])
    .expect("peer options");
    assert!(!format!("{options:?}").contains("relay-secret"));
    let mut wire = ProtobufBridgeWire::new(Box::new(rpc), options, "Controller phone".to_owned())
        .expect("wire");
    let config = SessionConfig::new(IceTransportPolicy::Relay);

    let answer = wire
        .start(BridgeRequest { route, sequence: 1 }, &config, OFFER_SDP)
        .expect("start")
        .value;
    assert_eq!(answer.sdp, "answer-sdp");
    wire.input(
        BridgeRequest { route, sequence: 2 },
        ValidatedInput::Text("hello"),
    )
    .expect("input");
    wire.add_candidate(
        BridgeRequest { route, sequence: 3 },
        &PeerIceCandidate {
            candidate: "candidate:remote".to_owned(),
            sdp_mid: "0".to_owned(),
            sdp_m_line_index: 0,
        },
    )
    .expect("candidate");

    assert_eq!(
        wire.try_event().expect("event"),
        Some(roammand_privileged_bridge::proxy::BridgeResponse {
            route,
            sequence: 1,
            value: ProxyEvent::LocalIceCandidate(PeerIceCandidate {
                candidate: event_candidate.candidate,
                sdp_mid: event_candidate.sdp_mid,
                sdp_m_line_index: 0,
            }),
        })
    );

    let calls = calls.lock().expect("calls");
    let privileged_bridge_client_frame::Payload::StartPeer(start) =
        calls[0].payload.as_ref().expect("start payload")
    else {
        panic!("unexpected start payload");
    };
    let configuration = start.configuration.as_ref().expect("configuration");
    assert_eq!(start.controller_display_name, "Controller phone");
    assert_eq!(configuration.ice_servers[0].credential, "relay-secret");
    assert_eq!(
        start.offer.as_ref().expect("offer").dtls_fingerprint_sha256,
        vec![0x11; 32]
    );
    let privileged_bridge_client_frame::Payload::InputCommand(input) =
        calls[1].payload.as_ref().expect("input payload")
    else {
        panic!("unexpected input payload");
    };
    assert!(matches!(
        input.input,
        Some(privileged_input_command::Input::Text(TextInputEvent { ref text })) if text == "hello"
    ));
}

#[test]
fn rejects_a_response_with_the_wrong_request_correlation() {
    let route = ProxyRoute::new(LeaseId::new([0x51; 16]), 4);
    let failed = Arc::new(Mutex::new(false));
    let rpc = FakeRpc {
        calls: Arc::new(Mutex::new(Vec::new())),
        failed: Arc::clone(&failed),
        route,
        mutation: ReplyMutation::WrongRequestId,
        event: None,
    };
    let mut wire = ProtobufBridgeWire::new(
        Box::new(rpc),
        BridgePeerOptions::new(Vec::new()).expect("options"),
        "Controller".to_owned(),
    )
    .expect("wire");

    assert_eq!(
        wire.start(
            BridgeRequest { route, sequence: 1 },
            &SessionConfig::new(IceTransportPolicy::All),
            OFFER_SDP,
        ),
        Err(ProxyError::StaleResponse)
    );
    assert!(*failed.lock().expect("failed"));
}

#[test]
fn factory_acquires_a_route_from_only_the_verified_session_context() {
    let observed = Arc::new(Mutex::new(Vec::new()));
    let route = ProxyRoute::new(LeaseId::new([0x61; 16]), 12);
    let mut factory = RpcProxyPartsFactory::new(
        Box::new(RecordingConnector {
            observed: Arc::clone(&observed),
            route,
        }),
        BridgePeerOptions::new(Vec::new()).expect("options"),
    );
    let context = ProxySessionContext::new(
        vec![0x71; 16],
        vec![
            SessionPermission::ViewScreen,
            SessionPermission::ControlInput,
        ],
        "Controller phone".to_owned(),
    )
    .expect("verified context");
    let debug = format!("{context:?}");
    assert!(!debug.contains("Controller phone"));
    assert!(!debug.contains("71"));

    let parts = factory
        .create(&SessionConfig::new(IceTransportPolicy::All), &context)
        .expect("proxy parts");
    let (_, _, _, route_control) = parts.into_parts();
    assert_eq!(
        route_control.migrate(route),
        Err(ProxyError::InvalidMigration)
    );
    assert_eq!(
        *observed.lock().expect("observed"),
        [(
            vec![0x71; 16],
            vec![
                SessionPermission::ViewScreen,
                SessionPermission::ControlInput,
            ],
            "Controller phone".to_owned(),
        )]
    );
}

#[test]
fn renews_the_lease_at_five_seconds_without_changing_proxy_sequences() {
    let route = ProxyRoute::new(LeaseId::new([0x62; 16]), 7);
    let calls = Arc::new(Mutex::new(Vec::new()));
    let now_ms = Arc::new(AtomicU64::new(0));
    let rpc = FakeRpc {
        calls: Arc::clone(&calls),
        failed: Arc::new(Mutex::new(false)),
        route,
        mutation: ReplyMutation::None,
        event: None,
    };
    let mut wire = ProtobufBridgeWire::with_clock(
        Box::new(rpc),
        BridgePeerOptions::new(Vec::new()).expect("options"),
        "Controller".to_owned(),
        route,
        3,
        Box::new(FakeClock(Arc::clone(&now_ms))),
    )
    .expect("wire");

    assert_eq!(wire.try_event(), Ok(None));
    now_ms.store(5_000, Ordering::Relaxed);
    assert_eq!(wire.try_event(), Ok(None));
    let response = wire
        .input(
            BridgeRequest { route, sequence: 1 },
            ValidatedInput::ReleaseAll,
        )
        .expect("input");
    assert_eq!(response.sequence, 1);

    let calls = calls.lock().expect("calls");
    assert_eq!(calls[0].sequence, 3);
    assert!(matches!(
        calls[0].payload,
        Some(privileged_bridge_client_frame::Payload::RenewLease(_))
    ));
    assert_eq!(calls[1].sequence, 4);
}

const fn version() -> ProtocolVersion {
    ProtocolVersion { major: 1, minor: 0 }
}
