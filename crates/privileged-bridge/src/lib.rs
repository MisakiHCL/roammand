// SPDX-License-Identifier: MPL-2.0

pub mod auth;
pub mod broker;
pub mod client;
mod connector;
pub mod framing;
pub mod helper;
pub mod indicator;
pub mod indicator_copy;
pub mod installed;
pub mod lease;
pub mod macos;
#[cfg(all(target_os = "macos", feature = "native-webrtc"))]
pub mod macos_indicator_runtime;
#[cfg(target_os = "macos")]
mod macos_peer_runtime;
#[cfg(feature = "native-webrtc")]
pub mod native_helper;
pub mod native_indicator;
pub mod peer_identity;
pub mod proxy;
pub mod rpc;
pub mod runtime;
pub mod session;
pub mod status;
pub mod transport;
#[cfg(unix)]
pub mod unix_runtime;
pub mod windows;
#[cfg(windows)]
pub mod windows_indicator_runtime;
#[cfg(windows)]
pub mod windows_process_runtime;
#[cfg(windows)]
pub mod windows_runtime;
