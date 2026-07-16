// SPDX-License-Identifier: MPL-2.0

use roammand_host_webrtc::{PeerAnswer, PeerIceCandidate, SessionGate};

const CANDIDATE_SENTINEL: &str = "candidate:SECRET_IP_192_0_2_61";
const SDP_SENTINEL: &str = "v=0 SECRET_SDP_4921";

#[test]
fn peer_debug_output_redacts_sdp_candidates_and_fingerprints() {
    let candidate = PeerIceCandidate {
        candidate: CANDIDATE_SENTINEL.to_owned(),
        sdp_mid: "SECRET_MID_7731".to_owned(),
        sdp_m_line_index: 47,
    };
    let answer = PeerAnswer {
        sdp: SDP_SENTINEL.to_owned(),
        dtls_fingerprint_sha256: vec![0xf3; 32],
    };

    let candidate_debug = format!("{candidate:?}");
    assert!(candidate_debug.contains("REDACTED"));
    assert!(!candidate_debug.contains(CANDIDATE_SENTINEL));
    assert!(!candidate_debug.contains("SECRET_MID_7731"));
    assert!(!candidate_debug.contains("47"));

    let answer_debug = format!("{answer:?}");
    assert!(answer_debug.contains("REDACTED"));
    assert!(!answer_debug.contains(SDP_SENTINEL));
    assert!(!answer_debug.contains("243"));
}

#[test]
fn session_lease_debug_redacts_the_session_identifier() {
    let mut gate = SessionGate::new();
    let lease = gate
        .acquire(&[0xd9; 16])
        .expect("valid session identifier must acquire the gate");

    let debug = format!("{lease:?}");
    assert!(debug.contains("REDACTED"));
    assert!(!debug.contains("217"));
}
