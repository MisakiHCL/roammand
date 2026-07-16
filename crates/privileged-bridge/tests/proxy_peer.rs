// SPDX-License-Identifier: MPL-2.0

use std::{
    collections::VecDeque,
    sync::{Arc, Mutex},
};

use roammand_host_webrtc::{
    HostWebRtcError, IceTransportPolicy, PeerAnswer, PeerBackend, PeerIceCandidate,
    RemoteInputSink, SessionConfig,
};
use roammand_privileged_bridge::{
    lease::LeaseId,
    proxy::{
        BridgeRequest, BridgeResponse, BridgeWire, ProxyError, ProxyEvent, ProxyRoute,
        ValidatedInput, new_proxy_parts,
    },
};
use roammand_protocol::roammand::v1::{ButtonAction, KeyboardAction, PointerButton};

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
enum ResponseMutation {
    None,
    WrongRoute,
    WrongSequence,
    TransportError,
}

struct FakeWire {
    route: ProxyRoute,
    operations: Arc<Mutex<Vec<String>>>,
    events: VecDeque<BridgeResponse<ProxyEvent>>,
    mutation: ResponseMutation,
}

impl FakeWire {
    fn response<T>(&self, request: BridgeRequest, value: T) -> BridgeResponse<T> {
        let mut route = request.route;
        let mut sequence = request.sequence;
        match self.mutation {
            ResponseMutation::None | ResponseMutation::TransportError => {}
            ResponseMutation::WrongRoute => route = ProxyRoute::new(LeaseId::new([0x99; 16]), 99),
            ResponseMutation::WrongSequence => sequence += 1,
        }
        BridgeResponse {
            route,
            sequence,
            value,
        }
    }

    fn record(&self, value: &str) {
        self.operations
            .lock()
            .expect("operations")
            .push(value.to_owned());
    }
}

impl BridgeWire for FakeWire {
    fn start(
        &mut self,
        request: BridgeRequest,
        _config: &SessionConfig,
        _offer_sdp: &str,
    ) -> Result<BridgeResponse<PeerAnswer>, ProxyError> {
        self.record("start");
        if matches!(self.mutation, ResponseMutation::TransportError) {
            return Err(ProxyError::Transport);
        }
        Ok(self.response(request, answer()))
    }

    fn restart(
        &mut self,
        request: BridgeRequest,
        _config: &SessionConfig,
        _offer_sdp: &str,
    ) -> Result<BridgeResponse<PeerAnswer>, ProxyError> {
        self.record("restart");
        self.route = request.route;
        Ok(self.response(request, answer()))
    }

    fn add_candidate(
        &mut self,
        request: BridgeRequest,
        _candidate: &PeerIceCandidate,
    ) -> Result<BridgeResponse<()>, ProxyError> {
        self.record("candidate");
        Ok(self.response(request, ()))
    }

    fn input(
        &mut self,
        request: BridgeRequest,
        _input: ValidatedInput<'_>,
    ) -> Result<BridgeResponse<()>, ProxyError> {
        self.record("input");
        Ok(self.response(request, ()))
    }

    fn close(&mut self, request: BridgeRequest) -> Result<BridgeResponse<()>, ProxyError> {
        self.record("close");
        Ok(self.response(request, ()))
    }

    fn release(&mut self, request: BridgeRequest) -> Result<BridgeResponse<()>, ProxyError> {
        self.record("release");
        Ok(self.response(request, ()))
    }

    fn try_event(&mut self) -> Result<Option<BridgeResponse<ProxyEvent>>, ProxyError> {
        if matches!(self.mutation, ResponseMutation::TransportError) {
            return Err(ProxyError::Transport);
        }
        Ok(self.events.pop_front())
    }

    fn fail_closed(&mut self) {
        self.record("fail-closed");
    }
}

#[test]
fn peer_input_and_raw_events_share_one_route() {
    let route = ProxyRoute::new(LeaseId::new([0x11; 16]), 7);
    let operations = Arc::new(Mutex::new(Vec::new()));
    let raw = vec![0x41; 32];
    let wire = FakeWire {
        route,
        operations: Arc::clone(&operations),
        events: VecDeque::from([BridgeResponse {
            route,
            sequence: 1,
            value: ProxyEvent::ReliableInput(raw.clone()),
        }]),
        mutation: ResponseMutation::None,
    };
    let parts = new_proxy_parts(route, Box::new(wire));
    let (mut peer, mut input, events, _) = parts.into_parts();
    let config = SessionConfig::new(IceTransportPolicy::All);

    assert_eq!(peer.start(&config, "offer").expect("start"), answer());
    input
        .keyboard(KeyboardAction::Down, 0x04, 0)
        .expect("typed input");
    peer.add_remote_ice_candidate(&PeerIceCandidate {
        candidate: "candidate".to_owned(),
        sdp_mid: "0".to_owned(),
        sdp_m_line_index: 0,
    })
    .expect("candidate");
    assert_eq!(
        events.try_recv().expect("event"),
        Some(ProxyEvent::ReliableInput(raw))
    );
    input.release_all().expect("release input");
    peer.close().expect("close");
    peer.close().expect("idempotent close");

    assert_eq!(
        *operations.lock().expect("operations"),
        ["start", "input", "candidate", "input", "close", "release"]
    );
}

#[test]
fn wrong_route_or_sequence_fails_closed() {
    for mutation in [
        ResponseMutation::WrongRoute,
        ResponseMutation::WrongSequence,
    ] {
        let route = ProxyRoute::new(LeaseId::new([0x21; 16]), 3);
        let operations = Arc::new(Mutex::new(Vec::new()));
        let wire = FakeWire {
            route,
            operations: Arc::clone(&operations),
            events: VecDeque::new(),
            mutation,
        };
        let parts = new_proxy_parts(route, Box::new(wire));
        let (mut peer, mut input, _, _) = parts.into_parts();
        assert_eq!(
            peer.start(&SessionConfig::new(IceTransportPolicy::Relay), "offer"),
            Err(HostWebRtcError::PeerFailure)
        );
        assert_eq!(
            input.pointer_move(1, 2, 0),
            Err(HostWebRtcError::InputFailure)
        );
        assert_eq!(
            *operations.lock().expect("operations"),
            ["start", "fail-closed"]
        );
    }
}

#[test]
fn wire_errors_fail_the_shared_proxy_closed() {
    let route = ProxyRoute::new(LeaseId::new([0x29; 16]), 3);
    let operations = Arc::new(Mutex::new(Vec::new()));
    let wire = FakeWire {
        route,
        operations: Arc::clone(&operations),
        events: VecDeque::new(),
        mutation: ResponseMutation::TransportError,
    };
    let parts = new_proxy_parts(route, Box::new(wire));
    let (mut peer, mut input, _, _) = parts.into_parts();

    assert_eq!(
        peer.start(&SessionConfig::new(IceTransportPolicy::All), "offer"),
        Err(HostWebRtcError::PeerFailure)
    );
    assert_eq!(
        input.pointer_move(1, 2, 0),
        Err(HostWebRtcError::InputFailure)
    );
    assert_eq!(
        *operations.lock().expect("operations"),
        ["start", "fail-closed"]
    );
}

#[test]
fn event_wire_errors_fail_the_shared_proxy_closed() {
    let route = ProxyRoute::new(LeaseId::new([0x2a; 16]), 3);
    let operations = Arc::new(Mutex::new(Vec::new()));
    let wire = FakeWire {
        route,
        operations: Arc::clone(&operations),
        events: VecDeque::new(),
        mutation: ResponseMutation::TransportError,
    };
    let parts = new_proxy_parts(route, Box::new(wire));
    let (_, mut input, events, _) = parts.into_parts();

    assert_eq!(events.try_recv(), Err(ProxyError::Transport));
    assert_eq!(
        input.pointer_move(1, 2, 0),
        Err(HostWebRtcError::InputFailure)
    );
    assert_eq!(*operations.lock().expect("operations"), ["fail-closed"]);
}

#[test]
fn migration_restarts_on_the_new_generation_and_rejects_stale_events() {
    let old = ProxyRoute::new(LeaseId::new([0x31; 16]), 8);
    let new = ProxyRoute::new(LeaseId::new([0x32; 16]), 9);
    let operations = Arc::new(Mutex::new(Vec::new()));
    let wire = FakeWire {
        route: old,
        operations,
        events: VecDeque::from([BridgeResponse {
            route: old,
            sequence: 1,
            value: ProxyEvent::Connected,
        }]),
        mutation: ResponseMutation::None,
    };
    let parts = new_proxy_parts(old, Box::new(wire));
    let (mut peer, _, events, route_control) = parts.into_parts();
    route_control.migrate(new).expect("next generation");

    peer.restart(&SessionConfig::new(IceTransportPolicy::All), "offer")
        .expect("restart new route");
    assert_eq!(events.try_recv(), Err(ProxyError::StaleRoute));
}

fn answer() -> PeerAnswer {
    PeerAnswer {
        sdp: "answer".to_owned(),
        dtls_fingerprint_sha256: vec![0x55; 32],
    }
}

#[allow(dead_code)]
fn all_validated_input_variants_compile() -> [ValidatedInput<'static>; 6] {
    [
        ValidatedInput::Keyboard(KeyboardAction::Up, 0x04, 0),
        ValidatedInput::PointerButton(PointerButton::Left, ButtonAction::Up, 1, 2),
        ValidatedInput::PointerMove(1, 2, 0),
        ValidatedInput::PointerScroll(1, 2),
        ValidatedInput::Text("hello"),
        ValidatedInput::ReleaseAll,
    ]
}
