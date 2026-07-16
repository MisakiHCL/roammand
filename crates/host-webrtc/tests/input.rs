// SPDX-License-Identifier: MPL-2.0

use std::sync::{Arc, Mutex};

use prost::Message;
use roammand_host_webrtc::{
    HostPeerSession, HostSessionState, HostWebRtcError, IceTransportPolicy, InputDisposition,
    PeerAnswer, PeerBackend, PointerDisposition, RemoteInputSink, SessionConfig,
};
use roammand_protocol::protocol_limits::{
    MAX_POINTER_FAST_ENVELOPE_BYTES, MAX_RELIABLE_INPUT_ENVELOPE_BYTES,
};
use roammand_protocol::roammand::v1::{
    ButtonAction, KeyboardAction, KeyboardEvent, PointerButton, PointerButtonEvent,
    PointerFastEnvelope, PointerMoveEvent, ProtocolVersion, ReleaseAllInput, ReliableInputEnvelope,
    SessionPermission, TextInputEvent, pointer_fast_envelope, reliable_input_envelope,
};

#[test]
fn reliable_input_preserves_sequence_and_releases_pressed_state() {
    let events = Arc::new(Mutex::new(Vec::<String>::new()));
    let mut session = connected_session(Arc::clone(&events));

    assert_eq!(
        session.handle_reliable(&reliable_keyboard(1, KeyboardAction::Down, 0x04)),
        Ok(InputDisposition::Applied)
    );
    assert_eq!(
        session.handle_reliable(&reliable_button(2, ButtonAction::Down)),
        Ok(InputDisposition::Applied)
    );
    assert_eq!(
        session.handle_reliable(&reliable_keyboard(2, KeyboardAction::Up, 0x04)),
        Err(HostWebRtcError::ReliableSequence)
    );
    assert_eq!(
        session.handle_reliable(&reliable_keyboard(4, KeyboardAction::Up, 0x04)),
        Err(HostWebRtcError::ReliableSequence)
    );
    assert_eq!(
        session.handle_reliable(&reliable_release_all(3)),
        Ok(InputDisposition::Applied)
    );
    session.close().expect("session must close");

    assert_eq!(
        *events.lock().expect("events lock"),
        vec!["key-down:4", "button-down:1", "release-all", "release-all"]
    );
}

#[test]
fn rejects_wrong_session_coordinates_usage_and_missing_permission() {
    let events = Arc::new(Mutex::new(Vec::<String>::new()));
    let mut session = connected_session(Arc::clone(&events));
    let wrong_session_frame = reliable_button(1, ButtonAction::Down);
    let mut wrong_session = ReliableInputEnvelope::decode(wrong_session_frame.as_slice())
        .expect("test frame must decode");
    wrong_session.session_id = vec![0x99; 16];
    assert_eq!(
        session.handle_reliable(&wrong_session.encode_to_vec()),
        Err(HostWebRtcError::SessionMismatch)
    );

    let bad_coordinate_frame = reliable_button(1, ButtonAction::Down);
    let mut bad_coordinate = ReliableInputEnvelope::decode(bad_coordinate_frame.as_slice())
        .expect("test frame must decode");
    let Some(reliable_input_envelope::Event::PointerButton(button)) = bad_coordinate.event.as_mut()
    else {
        panic!("button event");
    };
    button.x = 10_001;
    assert_eq!(
        session.handle_reliable(&bad_coordinate.encode_to_vec()),
        Err(HostWebRtcError::InvalidCoordinates)
    );

    assert_eq!(
        session.handle_reliable(&reliable_keyboard(1, KeyboardAction::Down, 0)),
        Err(HostWebRtcError::InvalidKeyboardUsage)
    );

    let mut view_only = HostPeerSession::new(
        vec![0x71; 16],
        &[SessionPermission::ViewScreen],
        SessionConfig::new(IceTransportPolicy::All),
        Box::new(NoopPeer),
        Box::new(RecordingInput::new(events)),
    )
    .expect("view-only session must construct");
    view_only.accept_offer("v=0\r\n").expect("offer");
    view_only.mark_connected().expect("connect");
    assert_eq!(
        view_only.handle_reliable(&reliable_release_all(1)),
        Err(HostWebRtcError::InputPermissionDenied)
    );
}

#[test]
fn pointer_fast_drops_stale_movement_without_blocking() {
    let events = Arc::new(Mutex::new(Vec::<String>::new()));
    let mut session = connected_session(Arc::clone(&events));

    assert_eq!(
        session.handle_pointer_fast(&pointer_move(10, 5000, 5000)),
        Ok(PointerDisposition::Applied)
    );
    assert_eq!(
        session.handle_pointer_fast(&pointer_move(9, 4000, 4000)),
        Ok(PointerDisposition::DroppedStale)
    );
    assert_eq!(
        session.handle_pointer_fast(&pointer_move(11, -1, 5000)),
        Err(HostWebRtcError::InvalidCoordinates)
    );
    assert_eq!(*events.lock().expect("events lock"), vec!["move:5000:5000"]);
}

#[test]
fn input_injection_failure_emergency_closes_and_releases_state() {
    let events = Arc::new(Mutex::new(Vec::<String>::new()));
    let mut session = HostPeerSession::new(
        vec![0x71; 16],
        &[
            SessionPermission::ViewScreen,
            SessionPermission::ControlInput,
        ],
        SessionConfig::new(IceTransportPolicy::All),
        Box::new(NoopPeer),
        Box::new(FailingInput::new(Arc::clone(&events))),
    )
    .expect("session must construct");
    session.accept_offer("v=0\r\n").expect("offer");
    session.mark_connected().expect("connect");

    assert_eq!(
        session.handle_reliable(&reliable_keyboard(1, KeyboardAction::Down, 0x04)),
        Err(HostWebRtcError::InputFailure)
    );
    assert_eq!(session.state(), HostSessionState::Closed);
    assert_eq!(
        *events.lock().expect("events lock"),
        vec!["key-attempt:4", "release-all"]
    );
}

#[test]
fn text_input_requires_a_bounded_non_empty_utf8_batch() {
    let events = Arc::new(Mutex::new(Vec::<String>::new()));
    let mut session = connected_session(Arc::clone(&events));

    assert_eq!(
        session.handle_reliable(&reliable_text(1, "你好")),
        Ok(InputDisposition::Applied)
    );
    assert_eq!(
        session.handle_reliable(&reliable_text(2, "")),
        Err(HostWebRtcError::InvalidInputEnvelope)
    );
    assert_eq!(
        session.handle_reliable(&reliable_text(2, &"é".repeat(513))),
        Err(HostWebRtcError::InvalidInputEnvelope)
    );
    assert_eq!(*events.lock().expect("events lock"), vec!["text:你好"]);
}

#[test]
fn deterministic_arbitrary_data_channel_payloads_fail_closed() {
    const CASES: usize = 512;
    let mut random = DeterministicBytes::new(0xa821_9c07_54de_31f2);
    for case in 0..CASES {
        let reliable_length = random.usize(MAX_RELIABLE_INPUT_ENVELOPE_BYTES + 2);
        let pointer_length = random.usize(MAX_POINTER_FAST_ENVELOPE_BYTES + 2);
        let mut reliable = vec![0_u8; reliable_length];
        let mut pointer = vec![0_u8; pointer_length];
        random.fill(&mut reliable);
        random.fill(&mut pointer);

        let events = Arc::new(Mutex::new(Vec::<String>::new()));
        let mut session = connected_session(events);
        let reliable_result = session.handle_reliable(&reliable);
        if reliable_length > MAX_RELIABLE_INPUT_ENVELOPE_BYTES {
            assert_eq!(
                reliable_result,
                Err(HostWebRtcError::InvalidInputEnvelope),
                "reliable case {case}"
            );
        }
        let pointer_result = session.handle_pointer_fast(&pointer);
        if pointer_length > MAX_POINTER_FAST_ENVELOPE_BYTES {
            assert_eq!(
                pointer_result,
                Err(HostWebRtcError::InvalidInputEnvelope),
                "pointer case {case}"
            );
        }
        assert!(matches!(
            session.state(),
            HostSessionState::Connected | HostSessionState::Closed
        ));
    }
}

fn connected_session(events: Arc<Mutex<Vec<String>>>) -> HostPeerSession {
    let mut session = HostPeerSession::new(
        vec![0x71; 16],
        &[
            SessionPermission::ViewScreen,
            SessionPermission::ControlInput,
        ],
        SessionConfig::new(IceTransportPolicy::All),
        Box::new(NoopPeer),
        Box::new(RecordingInput::new(events)),
    )
    .expect("session must construct");
    session.accept_offer("v=0\r\n").expect("offer");
    session.mark_connected().expect("connect");
    session
}

fn reliable_keyboard(sequence: u64, action: KeyboardAction, usage: u32) -> Vec<u8> {
    ReliableInputEnvelope {
        protocol_version: Some(version()),
        session_id: vec![0x71; 16],
        sequence,
        event: Some(reliable_input_envelope::Event::Keyboard(KeyboardEvent {
            action: action as i32,
            usb_hid_usage: usage,
            modifier_bits: 0,
        })),
    }
    .encode_to_vec()
}

fn reliable_button(sequence: u64, action: ButtonAction) -> Vec<u8> {
    ReliableInputEnvelope {
        protocol_version: Some(version()),
        session_id: vec![0x71; 16],
        sequence,
        event: Some(reliable_input_envelope::Event::PointerButton(
            PointerButtonEvent {
                button: PointerButton::Left as i32,
                action: action as i32,
                x: 5000,
                y: 5000,
            },
        )),
    }
    .encode_to_vec()
}

fn reliable_release_all(sequence: u64) -> Vec<u8> {
    ReliableInputEnvelope {
        protocol_version: Some(version()),
        session_id: vec![0x71; 16],
        sequence,
        event: Some(reliable_input_envelope::Event::ReleaseAllInput(
            ReleaseAllInput {},
        )),
    }
    .encode_to_vec()
}

fn reliable_text(sequence: u64, text: &str) -> Vec<u8> {
    ReliableInputEnvelope {
        protocol_version: Some(version()),
        session_id: vec![0x71; 16],
        sequence,
        event: Some(reliable_input_envelope::Event::Text(TextInputEvent {
            text: text.to_owned(),
        })),
    }
    .encode_to_vec()
}

fn pointer_move(sequence: u64, x: i32, y: i32) -> Vec<u8> {
    PointerFastEnvelope {
        protocol_version: Some(version()),
        session_id: vec![0x71; 16],
        sequence,
        event: Some(pointer_fast_envelope::Event::Move(PointerMoveEvent {
            x,
            y,
            pressed_button_bits: 0,
        })),
    }
    .encode_to_vec()
}

const fn version() -> ProtocolVersion {
    ProtocolVersion { major: 1, minor: 0 }
}

struct NoopPeer;

impl PeerBackend for NoopPeer {
    fn start(
        &mut self,
        _config: &SessionConfig,
        _offer_sdp: &str,
    ) -> Result<PeerAnswer, HostWebRtcError> {
        Ok(PeerAnswer {
            sdp: "answer".to_owned(),
            dtls_fingerprint_sha256: vec![0x41; 32],
        })
    }

    fn close(&mut self) -> Result<(), HostWebRtcError> {
        Ok(())
    }
}

struct RecordingInput {
    events: Arc<Mutex<Vec<String>>>,
}

impl RecordingInput {
    fn new(events: Arc<Mutex<Vec<String>>>) -> Self {
        Self { events }
    }
}

impl RemoteInputSink for RecordingInput {
    fn keyboard(
        &mut self,
        action: KeyboardAction,
        usb_hid_usage: u32,
        _modifier_bits: u32,
    ) -> Result<(), HostWebRtcError> {
        self.events.lock().expect("events lock").push(format!(
            "key-{}:{usb_hid_usage}",
            if action == KeyboardAction::Down {
                "down"
            } else {
                "up"
            }
        ));
        Ok(())
    }

    fn pointer_button(
        &mut self,
        _button: PointerButton,
        action: ButtonAction,
        _x: i32,
        _y: i32,
    ) -> Result<(), HostWebRtcError> {
        self.events.lock().expect("events lock").push(format!(
            "button-{}:1",
            if action == ButtonAction::Down {
                "down"
            } else {
                "up"
            }
        ));
        Ok(())
    }

    fn pointer_move(
        &mut self,
        x: i32,
        y: i32,
        _pressed_button_bits: u32,
    ) -> Result<(), HostWebRtcError> {
        self.events
            .lock()
            .expect("events lock")
            .push(format!("move:{x}:{y}"));
        Ok(())
    }

    fn text(&mut self, text: &str) -> Result<(), HostWebRtcError> {
        self.events
            .lock()
            .expect("events lock")
            .push(format!("text:{text}"));
        Ok(())
    }

    fn release_all(&mut self) -> Result<(), HostWebRtcError> {
        self.events
            .lock()
            .expect("events lock")
            .push("release-all".to_owned());
        Ok(())
    }
}

struct FailingInput {
    events: Arc<Mutex<Vec<String>>>,
}

struct DeterministicBytes(u64);

impl DeterministicBytes {
    const fn new(seed: u64) -> Self {
        Self(seed)
    }

    fn next(&mut self) -> u64 {
        self.0 = self
            .0
            .wrapping_mul(6_364_136_223_846_793_005)
            .wrapping_add(1_442_695_040_888_963_407);
        self.0
    }

    fn usize(&mut self, upper: usize) -> usize {
        usize::try_from(self.next() % u64::try_from(upper).expect("upper bound fits"))
            .expect("bounded value fits")
    }

    fn fill(&mut self, output: &mut [u8]) {
        for value in output {
            *value = self.next().to_le_bytes()[0];
        }
    }
}

impl FailingInput {
    fn new(events: Arc<Mutex<Vec<String>>>) -> Self {
        Self { events }
    }
}

impl RemoteInputSink for FailingInput {
    fn keyboard(
        &mut self,
        _action: KeyboardAction,
        usb_hid_usage: u32,
        _modifier_bits: u32,
    ) -> Result<(), HostWebRtcError> {
        self.events
            .lock()
            .expect("events lock")
            .push(format!("key-attempt:{usb_hid_usage}"));
        Err(HostWebRtcError::InputFailure)
    }

    fn release_all(&mut self) -> Result<(), HostWebRtcError> {
        self.events
            .lock()
            .expect("events lock")
            .push("release-all".to_owned());
        Ok(())
    }
}
