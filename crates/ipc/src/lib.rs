// SPDX-License-Identifier: MPL-2.0

#![forbid(unsafe_code)]

mod auth;
mod framing;
mod protocol;

pub use auth::{
    AuthChannel, IpcToken, channel_client_proof, channel_server_proof, client_proof, server_proof,
    verify_channel_client_proof, verify_channel_server_proof,
};
pub use framing::{FrameDecoder, FrameError, encode_frame, encode_frame_with_limit};
pub use protocol::{ProtocolError, ServerProtocol};
