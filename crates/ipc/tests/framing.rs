// SPDX-License-Identifier: MPL-2.0

use roammand_ipc::{FrameDecoder, FrameError, encode_frame, encode_frame_with_limit};
use roammand_protocol::protocol_limits::MAX_LOCAL_IPC_FRAME_BYTES;

#[test]
fn encodes_a_big_endian_length_prefix() {
    let encoded = encode_frame(&[0xaa, 0xbb, 0xcc]).expect("frame must encode");
    assert_eq!(encoded, [0, 0, 0, 3, 0xaa, 0xbb, 0xcc]);
}

#[test]
fn rejects_zero_length_and_oversized_frames() {
    assert_eq!(encode_frame(&[]), Err(FrameError::ZeroLength));
    assert_eq!(
        encode_frame(&vec![0; MAX_LOCAL_IPC_FRAME_BYTES + 1]),
        Err(FrameError::FrameTooLarge)
    );

    let mut zero = FrameDecoder::new();
    assert_eq!(zero.push(&0_u32.to_be_bytes()), Err(FrameError::ZeroLength));
    let mut oversized = FrameDecoder::new();
    assert_eq!(
        oversized.push(
            &u32::try_from(MAX_LOCAL_IPC_FRAME_BYTES + 1)
                .expect("limit fits u32")
                .to_be_bytes()
        ),
        Err(FrameError::FrameTooLarge)
    );
}

#[test]
fn an_explicit_protocol_limit_does_not_change_the_existing_default() {
    assert_eq!(
        encode_frame_with_limit(&[0x11; 9], 8),
        Err(FrameError::FrameTooLarge)
    );
    let mut decoder = FrameDecoder::with_limit(8).expect("nonzero limit");
    assert_eq!(
        decoder.push(&9_u32.to_be_bytes()),
        Err(FrameError::FrameTooLarge)
    );
    assert!(matches!(
        FrameDecoder::with_limit(0),
        Err(FrameError::InvalidLimit)
    ));
    assert!(encode_frame(&[0x11; 9]).is_ok());
}

#[test]
fn every_chunk_boundary_decodes_the_same_frames() {
    let expected = vec![b"first".to_vec(), vec![0x22; 257], b"third".to_vec()];
    let encoded = expected
        .iter()
        .flat_map(|payload| encode_frame(payload).expect("frame must encode"))
        .collect::<Vec<_>>();

    for chunk_size in 1..=encoded.len() {
        let mut decoder = FrameDecoder::new();
        let mut frames = Vec::new();
        for chunk in encoded.chunks(chunk_size) {
            frames.extend(decoder.push(chunk).expect("chunk must decode"));
            assert!(decoder.buffered_bytes() <= MAX_LOCAL_IPC_FRAME_BYTES);
        }
        decoder.finish().expect("complete stream must finish");
        assert_eq!(frames, expected, "chunk size {chunk_size}");
    }
}

#[test]
fn detects_truncated_header_and_payload_at_eof() {
    let mut header = FrameDecoder::new();
    header.push(&[0, 0, 0]).expect("partial header is buffered");
    assert_eq!(header.finish(), Err(FrameError::Truncated));

    let mut payload = FrameDecoder::new();
    payload
        .push(&[0, 0, 0, 4, 0x11, 0x22])
        .expect("partial payload is buffered");
    assert_eq!(payload.finish(), Err(FrameError::Truncated));
}

#[test]
fn decoder_is_poisoned_after_an_invalid_length() {
    let mut decoder = FrameDecoder::new();
    assert_eq!(decoder.push(&[0, 0, 0, 0]), Err(FrameError::ZeroLength));
    assert_eq!(decoder.push(&[0, 0, 0, 1, 0x11]), Err(FrameError::Failed));
    assert_eq!(decoder.finish(), Err(FrameError::Failed));
}

#[test]
fn deterministic_arbitrary_chunks_never_exceed_the_frame_bound() {
    const CASES: usize = 512;
    let mut random = DeterministicBytes::new(0x4d37_5a91_22f0_18c3);
    for case in 0..CASES {
        let length = random.usize(4097);
        let mut encoded = vec![0_u8; length];
        random.fill(&mut encoded);
        let mut decoder = FrameDecoder::new();
        let mut offset = 0;
        while offset < encoded.len() {
            let chunk_length = random.usize(97).max(1).min(encoded.len() - offset);
            let result = decoder.push(&encoded[offset..offset + chunk_length]);
            assert!(
                decoder.buffered_bytes() <= MAX_LOCAL_IPC_FRAME_BYTES,
                "case {case} buffered too much data"
            );
            offset += chunk_length;
            if result.is_err() {
                assert_eq!(decoder.finish(), Err(FrameError::Failed));
                break;
            }
        }
    }
}

#[test]
fn deterministic_payloads_round_trip_across_arbitrary_chunks() {
    const CASES: usize = 256;
    let mut random = DeterministicBytes::new(0x7c19_d4e2_a861_0bb5);
    for case in 0..CASES {
        let length = random.usize(2048) + 1;
        let mut payload = vec![0_u8; length];
        random.fill(&mut payload);
        let encoded = encode_frame(&payload).expect("bounded payload must encode");
        let mut decoder = FrameDecoder::new();
        let mut frames = Vec::new();
        let mut offset = 0;
        while offset < encoded.len() {
            let chunk_length = random.usize(73).max(1).min(encoded.len() - offset);
            frames.extend(
                decoder
                    .push(&encoded[offset..offset + chunk_length])
                    .expect("encoded payload must decode"),
            );
            offset += chunk_length;
        }
        decoder.finish().expect("round trip must end on a boundary");
        assert_eq!(frames, [payload], "case {case}");
    }
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
