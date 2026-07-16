// SPDX-License-Identifier: MPL-2.0

use roammand_privileged_bridge::framing::{
    BridgeFrameDecoder, EventQueue, EventQueueError, RequestError, RequestTracker,
    decode_exact_bridge_frame, encode_bridge_frame,
};
use roammand_protocol::protocol_limits::MAX_PRIVILEGED_BRIDGE_FRAME_BYTES;

#[test]
fn bridge_frames_are_big_endian_bounded_and_exact() {
    assert_eq!(
        encode_bridge_frame(&[0xaa, 0xbb]).expect("encode"),
        [0, 0, 0, 2, 0xaa, 0xbb]
    );
    assert!(encode_bridge_frame(&[]).is_err());
    assert!(encode_bridge_frame(&vec![0; MAX_PRIVILEGED_BRIDGE_FRAME_BYTES + 1]).is_err());
    assert_eq!(
        decode_exact_bridge_frame(&[0, 0, 0, 2, 0xaa, 0xbb]).expect("exact"),
        [0xaa, 0xbb]
    );
    assert!(decode_exact_bridge_frame(&[0, 0, 0, 2, 0xaa]).is_err());
    assert!(decode_exact_bridge_frame(&[0, 0, 0, 1, 0xaa, 0]).is_err());

    let mut decoder = BridgeFrameDecoder::new();
    assert!(decoder.push(&[0, 0]).expect("partial header").is_empty());
    assert_eq!(
        decoder.push(&[0, 2, 0xaa, 0xbb]).expect("remainder"),
        [vec![0xaa, 0xbb]]
    );
    decoder.finish().expect("complete");
}

#[test]
fn request_tracking_is_bounded_and_rejects_stale_responses() {
    let mut tracker = RequestTracker::new();
    for index in 0..32 {
        tracker
            .begin(format!("request-{index}"))
            .expect("within limit");
    }
    assert_eq!(
        tracker.begin("overflow".to_owned()),
        Err(RequestError::PendingLimit)
    );
    assert_eq!(
        tracker.complete("unknown"),
        Err(RequestError::StaleResponse)
    );
    tracker.complete("request-0").expect("known response");
    assert_eq!(
        tracker.complete("request-0"),
        Err(RequestError::StaleResponse)
    );
}

#[test]
fn fast_pointer_coalesces_and_critical_overflow_fails_closed() {
    let mut queue = EventQueue::new();
    queue.push_fast(1_u16).expect("fast");
    queue.push_fast(2_u16).expect("coalesce");
    assert_eq!(queue.pop_fast(), Some(2));

    for value in 0..256_u16 {
        queue.push_critical(value).expect("within limit");
    }
    assert_eq!(
        queue.push_critical(256),
        Err(EventQueueError::CriticalOverflow)
    );
    assert!(queue.is_failed());
    assert_eq!(queue.pop_critical(), Err(EventQueueError::Failed));
    assert_eq!(queue.push_fast(3), Err(EventQueueError::Failed));
}
