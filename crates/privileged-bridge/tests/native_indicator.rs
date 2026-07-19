// SPDX-License-Identifier: MPL-2.0

#[cfg(feature = "native-webrtc")]
use roammand_privileged_bridge::{
    helper::HelperBackend, native_helper::NativeHelperBackend, proxy::ProxyEvent,
};
use roammand_privileged_bridge::{
    indicator::IndicatorStatusKey, native_indicator::native_indicator_channel,
};

#[test]
fn local_stop_is_one_shot_and_tears_down_the_shared_surface() {
    let (client, runtime) = native_indicator_channel();
    client
        .show_controlled("Controller phone")
        .expect("show indicator");
    let visible = runtime.snapshot();
    let presentation = visible.presentation.expect("presentation");
    assert_eq!(
        presentation.controller_display_name(),
        Some("Controller phone")
    );
    assert_eq!(presentation.status_key(), IndicatorStatusKey::Controlled);

    assert!(runtime.local_stop());
    assert!(!runtime.local_stop());
    assert!(client.take_local_stop());
    assert!(!client.take_local_stop());
    assert_eq!(
        runtime
            .snapshot()
            .presentation
            .expect("stopping presentation")
            .status_key(),
        IndicatorStatusKey::Stopping
    );

    client.hide();
    assert!(runtime.snapshot().presentation.is_none());
    runtime.finish();
    assert!(runtime.snapshot().finished);
}

#[test]
fn repeated_controlled_state_does_not_republish_the_surface() {
    let (client, runtime) = native_indicator_channel();
    client.show_controlled("Controller phone").expect("show");
    let revision = runtime.snapshot().revision;

    client
        .show_controlled("Controller phone")
        .expect("repeat show");

    assert_eq!(runtime.snapshot().revision, revision);
}

#[test]
#[cfg(feature = "native-webrtc")]
fn protected_local_stop_reaches_the_host_as_a_terminal_event() {
    let (client, runtime) = native_indicator_channel();
    client.show_controlled("Controller phone").expect("show");
    let mut backend = NativeHelperBackend::new().with_indicator(client);

    assert!(runtime.local_stop());
    assert_eq!(
        backend.try_event().expect("terminal event"),
        Some(ProxyEvent::LocalStop)
    );
    assert_eq!(backend.try_event().expect("event consumed"), None);
}
