// SPDX-License-Identifier: MPL-2.0

use roammand_host_agent::{SignalingEvent, VerifiedSessionOffer};
use roammand_protocol::roammand::v1::{
    DeviceIdentity, DevicePlatform, PublicKeyAlgorithm, SessionPermission,
};

const NAME_SENTINEL: &str = "PRIVATE_DEVICE_NAME_8317";

#[test]
fn signaling_event_debug_retains_only_kind_and_bounded_counts() {
    let event = SignalingEvent::RoutedSession {
        sender_device_id: vec![0xf3; 32],
        opaque_envelope: vec![0xe7; 19],
    };

    let debug = format!("{event:?}");
    assert!(debug.contains("routed_session"));
    assert!(debug.contains("opaque_bytes"));
    assert!(debug.contains("19"));
    assert!(!debug.contains("243"));
    assert!(!debug.contains("231"));
}

#[test]
fn verified_offer_debug_redacts_identity_and_session_data() {
    let offer = VerifiedSessionOffer {
        controller: DeviceIdentity {
            device_id: vec![0xf3; 32],
            public_key: vec![0xe7; 32],
            display_name: NAME_SENTINEL.to_owned(),
            platform: DevicePlatform::Android as i32,
            public_key_algorithm: PublicKeyAlgorithm::Ed25519 as i32,
        },
        session_id: vec![0xd9; 16],
        permissions: vec![SessionPermission::ControlInput],
    };

    let debug = format!("{offer:?}");
    assert!(debug.contains("REDACTED"));
    for forbidden in [NAME_SENTINEL, "243", "231", "217", "ControlInput"] {
        assert!(
            !debug.contains(forbidden),
            "debug exposed {forbidden}: {debug}"
        );
    }
}
