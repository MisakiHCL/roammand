// SPDX-License-Identifier: MPL-2.0

#![cfg(unix)]

use std::{
    io::{Read, Write},
    os::unix::net::UnixStream,
    time::Duration,
};

use roammand_privileged_bridge::{
    framing::encode_bridge_frame, transport::LocalBridgeTransport,
    unix_runtime::UnixStreamTransport,
};

#[test]
fn unix_stream_transport_frames_partial_reads_and_nonblocking_polls() {
    let (client, mut server) = UnixStream::pair().expect("pair");
    let mut transport =
        UnixStreamTransport::new(client, Duration::from_secs(1)).expect("transport");
    assert_eq!(transport.try_receive().expect("empty"), None);

    let first = encode_bridge_frame(b"first").expect("first");
    server.write_all(&first[..3]).expect("partial");
    assert_eq!(transport.try_receive().expect("partial"), None);
    server.write_all(&first[3..]).expect("remainder");
    assert_eq!(transport.receive().expect("frame"), b"first");

    transport.send(b"second").expect("send");
    let mut encoded = vec![0_u8; 10];
    server.read_exact(&mut encoded).expect("read");
    assert_eq!(encoded, encode_bridge_frame(b"second").expect("encoded"));
}

#[test]
fn fail_closed_shuts_down_both_stream_directions() {
    let (client, mut server) = UnixStream::pair().expect("pair");
    let mut transport =
        UnixStreamTransport::new(client, Duration::from_secs(1)).expect("transport");
    transport.fail_closed();

    assert!(transport.send(b"blocked").is_err());
    let mut byte = [0_u8; 1];
    assert_eq!(server.read(&mut byte).expect("eof"), 0);
}
