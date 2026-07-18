// SPDX-License-Identifier: MPL-2.0

mod capture;
mod peer;

pub const LIBWEBRTC_RELEASE_TAG: &str = "webrtc-24f6822-2";

#[cfg(target_os = "macos")]
pub use capture::macos_screen_capture_access;
pub use capture::{NativeSourceDescriptor, select_main_display_source_id};
pub use peer::{
    NativeConnectionState, NativeDataChannelKind, NativeIceServer, NativePeerBackend,
    NativePeerEvent, NativePeerEventReceiveError, NativePeerEvents, NativePeerOptions,
    classify_data_channel, parse_dtls_sha256_fingerprint, preferred_video_codec_mime_types,
    probe_native_video_codecs,
};
