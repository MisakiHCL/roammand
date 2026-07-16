// SPDX-License-Identifier: MPL-2.0

#![cfg(feature = "native-webrtc")]

use std::{sync::mpsc::sync_channel, time::Duration};

use futures::executor::block_on;
use libwebrtc::{
    MediaType,
    data_channel::DataChannelInit,
    media_stream_track::MediaStreamTrack,
    peer_connection::{AnswerOptions, OfferOptions},
    peer_connection_factory::{
        PeerConnectionFactory, RtcConfiguration, native::PeerConnectionFactoryExt,
    },
    rtp_transceiver::{RtpTransceiverDirection, RtpTransceiverInit},
    video_source::{VideoResolution, native::NativeVideoSource},
};
use roammand_host_webrtc::{
    DATA_CHANNEL_INPUT_RELIABLE, DATA_CHANNEL_POINTER_FAST,
    native::{
        LIBWEBRTC_RELEASE_TAG, NativeDataChannelKind, NativeSourceDescriptor,
        classify_data_channel, parse_dtls_sha256_fingerprint, preferred_video_codec_mime_types,
        probe_native_video_codecs, select_main_display_source_id,
    },
};

#[test]
fn pins_release_and_orders_h264_before_vp8() {
    assert_eq!(LIBWEBRTC_RELEASE_TAG, "webrtc-24f6822-2");
    let available = vec![
        "video/VP9".to_owned(),
        "video/VP8".to_owned(),
        "video/H264".to_owned(),
        "video/rtx".to_owned(),
        "video/h264".to_owned(),
    ];
    assert_eq!(
        preferred_video_codec_mime_types(&available),
        vec!["video/H264", "video/h264", "video/VP8"]
    );
}

#[test]
fn accepts_only_the_two_protocol_data_channels() {
    assert_eq!(
        classify_data_channel(DATA_CHANNEL_INPUT_RELIABLE),
        Some(NativeDataChannelKind::ReliableInput)
    );
    assert_eq!(
        classify_data_channel(DATA_CHANNEL_POINTER_FAST),
        Some(NativeDataChannelKind::FastPointer)
    );
    assert_eq!(classify_data_channel("other"), None);
}

#[test]
fn parses_exact_sha256_dtls_fingerprint() {
    let expected = (0_u8..32).collect::<Vec<_>>();
    let encoded = expected
        .iter()
        .map(|byte| format!("{byte:02X}"))
        .collect::<Vec<_>>()
        .join(":");
    let sdp = format!("v=0\r\na=fingerprint:sha-256 {encoded}\r\n");
    assert_eq!(parse_dtls_sha256_fingerprint(&sdp), Some(expected));
    assert_eq!(
        parse_dtls_sha256_fingerprint("v=0\r\na=fingerprint:sha-1 00:11\r\n"),
        None
    );
}

#[test]
fn selects_only_the_main_display_source() {
    let sources = vec![
        NativeSourceDescriptor {
            source_id: 7,
            display_id: 8,
        },
        NativeSourceDescriptor {
            source_id: 8,
            display_id: 7,
        },
    ];
    assert_eq!(select_main_display_source_id(&sources, 8), Some(8));
    assert_eq!(select_main_display_source_id(&sources, 99), None);
}

#[test]
fn initializes_native_factory_with_required_video_codecs() {
    let codecs = probe_native_video_codecs();
    assert!(
        codecs
            .iter()
            .any(|mime| mime.eq_ignore_ascii_case("video/H264"))
    );
    assert!(
        codecs
            .iter()
            .any(|mime| mime.eq_ignore_ascii_case("video/VP8"))
    );
}

#[test]
fn completes_native_offer_answer_for_protocol_data_channels() {
    let factory = PeerConnectionFactory::default();
    let controller = factory
        .create_peer_connection(RtcConfiguration::default())
        .expect("controller peer must initialize");
    let host = factory
        .create_peer_connection(RtcConfiguration::default())
        .expect("host peer must initialize");
    let reliable = controller
        .create_data_channel(DATA_CHANNEL_INPUT_RELIABLE, DataChannelInit::default())
        .expect("reliable channel must initialize");
    let fast = controller
        .create_data_channel(
            DATA_CHANNEL_POINTER_FAST,
            DataChannelInit {
                ordered: false,
                max_retransmits: Some(0),
                ..DataChannelInit::default()
            },
        )
        .expect("fast channel must initialize");

    let answer_sdp = block_on(async {
        let offer = controller
            .create_offer(OfferOptions::default())
            .await
            .expect("offer must be created");
        controller
            .set_local_description(offer.clone())
            .await
            .expect("controller local offer must be set");
        host.set_remote_description(offer)
            .await
            .expect("host remote offer must be set");
        let answer = host
            .create_answer(AnswerOptions::default())
            .await
            .expect("answer must be created");
        host.set_local_description(answer.clone())
            .await
            .expect("host local answer must be set");
        controller
            .set_remote_description(answer.clone())
            .await
            .expect("controller remote answer must be set");
        answer.to_string()
    });

    assert_eq!(reliable.label(), DATA_CHANNEL_INPUT_RELIABLE);
    assert_eq!(fast.label(), DATA_CHANNEL_POINTER_FAST);
    assert_eq!(
        parse_dtls_sha256_fingerprint(&answer_sdp).map(|value| value.len()),
        Some(32)
    );
    reliable.close();
    fast.close();
    controller.close();
    host.close();
}

#[tokio::test(flavor = "current_thread")]
async fn negotiates_host_video_for_a_recvonly_controller() {
    let factory = PeerConnectionFactory::default();
    let controller = factory
        .create_peer_connection(RtcConfiguration::default())
        .expect("controller peer must initialize");
    let host = factory
        .create_peer_connection(RtcConfiguration::default())
        .expect("host peer must initialize");
    controller
        .add_transceiver_for_media(
            MediaType::Video,
            RtpTransceiverInit {
                direction: RtpTransceiverDirection::RecvOnly,
                stream_ids: Vec::new(),
                send_encodings: Vec::new(),
            },
        )
        .expect("controller video transceiver must initialize");

    let source = NativeVideoSource::new(
        VideoResolution {
            width: 640,
            height: 360,
        },
        true,
    );
    let track = factory.create_video_track("host-video", source);

    let (track_sender, track_receiver) = sync_channel(1);
    controller.on_track(Some(Box::new(move |event| {
        let _ = track_sender.try_send((event.track.id(), event.streams.len()));
    })));

    let offer = controller
        .create_offer(OfferOptions {
            offer_to_receive_video: true,
            ..OfferOptions::default()
        })
        .await
        .expect("controller offer must be created");
    controller
        .set_local_description(offer.clone())
        .await
        .expect("controller local offer must be set");
    host.set_remote_description(offer)
        .await
        .expect("host remote offer must be set");
    host.add_track(MediaStreamTrack::from(track), &["host-screen"])
        .expect("host video track must attach to the offered transceiver");
    let host_video = host
        .transceivers()
        .into_iter()
        .find(|transceiver| {
            transceiver
                .sender()
                .track()
                .is_some_and(|track| track.id() == "host-video")
        })
        .expect("host video transceiver must be associated");
    let codecs = factory
        .get_rtp_sender_capabilities(MediaType::Video)
        .codecs
        .into_iter()
        .filter(|codec| {
            codec.mime_type.eq_ignore_ascii_case("video/H264")
                || codec.mime_type.eq_ignore_ascii_case("video/VP8")
        })
        .collect();
    host_video
        .set_codec_preferences(codecs)
        .expect("host video codecs must initialize");
    let answer = host
        .create_answer(AnswerOptions::default())
        .await
        .expect("host answer must be created");
    host.set_local_description(answer.clone())
        .await
        .expect("host local answer must be set");
    controller
        .set_remote_description(answer.clone())
        .await
        .expect("controller remote answer must be set");
    let answer_sdp = answer.to_string();

    assert!(answer_sdp.contains("m=video "));
    assert!(answer_sdp.contains("a=sendonly"));
    assert!(answer_sdp.contains("a=msid:host-screen "));
    let (_, stream_count) = track_receiver
        .recv_timeout(Duration::from_secs(3))
        .expect("controller must receive the Host video track");
    assert_eq!(stream_count, 1);
    controller.close();
    host.close();
}
