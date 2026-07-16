// SPDX-License-Identifier: MPL-2.0

use std::sync::{Arc, Mutex};

use roammand_host_webrtc::{
    HostPeerSession, HostWebRtcError, IceTransportPolicy, PeerAnswer, PeerBackend, RemoteInputSink,
    SessionConfig,
};
use roammand_protocol::roammand::v1::SessionPermission;

#[test]
fn ten_connect_close_cycles_release_every_resource() {
    let ledger = Arc::new(Mutex::new(ResourceLedger::default()));

    for cycle in 0_u8..10 {
        let mut session = HostPeerSession::new(
            vec![cycle; 16],
            &[
                SessionPermission::ViewScreen,
                SessionPermission::ControlInput,
            ],
            SessionConfig::new(IceTransportPolicy::All),
            Box::new(ResourcePeer::new(Arc::clone(&ledger))),
            Box::new(ResourceInput::new(Arc::clone(&ledger))),
        )
        .expect("session must construct");
        session.accept_offer("v=0\r\n").expect("offer");
        session.mark_connected().expect("connect");
        session.close().expect("close");
        assert_eq!(
            *ledger.lock().expect("ledger lock"),
            ResourceLedger::default(),
            "cycle {cycle}"
        );
    }
}

#[derive(Clone, Debug, Default, Eq, PartialEq)]
struct ResourceLedger {
    capture: usize,
    source: usize,
    track: usize,
    channels: usize,
    peer: usize,
    callbacks: usize,
    pressed_input: usize,
}

struct ResourcePeer {
    ledger: Arc<Mutex<ResourceLedger>>,
    open: bool,
}

impl ResourcePeer {
    fn new(ledger: Arc<Mutex<ResourceLedger>>) -> Self {
        Self {
            ledger,
            open: false,
        }
    }
}

impl PeerBackend for ResourcePeer {
    fn start(
        &mut self,
        _config: &SessionConfig,
        _offer_sdp: &str,
    ) -> Result<PeerAnswer, HostWebRtcError> {
        let mut ledger = self.ledger.lock().expect("ledger lock");
        ledger.capture += 1;
        ledger.source += 1;
        ledger.track += 1;
        ledger.channels += 2;
        ledger.peer += 1;
        ledger.callbacks += 1;
        self.open = true;
        Ok(PeerAnswer {
            sdp: "answer".to_owned(),
            dtls_fingerprint_sha256: vec![0x41; 32],
        })
    }

    fn close(&mut self) -> Result<(), HostWebRtcError> {
        if self.open {
            let mut ledger = self.ledger.lock().expect("ledger lock");
            ledger.capture -= 1;
            ledger.source -= 1;
            ledger.track -= 1;
            ledger.channels -= 2;
            ledger.peer -= 1;
            ledger.callbacks -= 1;
            self.open = false;
        }
        Ok(())
    }
}

struct ResourceInput {
    ledger: Arc<Mutex<ResourceLedger>>,
}

impl ResourceInput {
    fn new(ledger: Arc<Mutex<ResourceLedger>>) -> Self {
        Self { ledger }
    }
}

impl RemoteInputSink for ResourceInput {
    fn release_all(&mut self) -> Result<(), HostWebRtcError> {
        self.ledger.lock().expect("ledger lock").pressed_input = 0;
        Ok(())
    }
}
