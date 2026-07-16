// SPDX-License-Identifier: MPL-2.0

mod config;
mod input;
mod peer;
mod session;

#[cfg(feature = "native-webrtc")]
pub mod native;

use thiserror::Error;

pub use config::{
    DATA_CHANNEL_INPUT_RELIABLE, DATA_CHANNEL_POINTER_FAST, DataChannelConfig,
    DataChannelReliability, IceTransportPolicy, SessionConfig, VideoCodec,
};
pub use input::{NORMALIZED_POINTER_MAX, RemoteInputSink};
pub use peer::{PeerAnswer, PeerBackend, PeerIceCandidate};
pub use session::{
    HostPeerSession, HostSessionState, InputDisposition, PointerDisposition, SessionGate,
    SessionLease,
};

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub enum HostWebRtcError {
    #[error("remote session identity is invalid")]
    InvalidSession,
    #[error("remote session permissions are invalid")]
    InvalidPermissions,
    #[error("remote session state is invalid")]
    InvalidState,
    #[error("remote session offer SDP is invalid")]
    InvalidSdp,
    #[error("remote session answer is invalid")]
    InvalidAnswer,
    #[error("remote session peer backend failed")]
    PeerFailure,
    #[error("remote input injection failed")]
    InputFailure,
    #[error("remote input permission was not granted")]
    InputPermissionDenied,
    #[error("remote input envelope is invalid")]
    InvalidInputEnvelope,
    #[error("remote input targets another session")]
    SessionMismatch,
    #[error("reliable input sequence is invalid")]
    ReliableSequence,
    #[error("remote pointer coordinates are invalid")]
    InvalidCoordinates,
    #[error("remote keyboard usage is invalid")]
    InvalidKeyboardUsage,
    #[error("remote keyboard modifier bits are invalid")]
    InvalidModifierBits,
    #[error("remote pointer button bits are invalid")]
    InvalidPointerButtons,
    #[error("remote pointer scroll delta is invalid")]
    InvalidScrollDelta,
    #[error("remote pressed-input state is invalid")]
    PressedInputState,
    #[error("Host already has an active inbound session")]
    DeviceBusy,
    #[error("remote session lease is invalid")]
    InvalidLease,
}
