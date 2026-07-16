// SPDX-License-Identifier: MPL-2.0

mod authorization;
mod grant_store;
mod identity;
mod pairing;
mod pairing_crypto;
mod remote_reconnect;
mod remote_runtime;
mod remote_session;
mod remote_session_bridge;
#[cfg(feature = "native-webrtc")]
mod remote_session_native;
mod remote_session_state;
mod runtime;
mod service;
mod session_auth;
mod sessions;
mod signaling;

pub use authorization::{AuthorizationError, AuthorizationRegistry};
pub use grant_store::{FileGrantStore, GrantStore, GrantStoreError, MemoryGrantStore};
pub use identity::{HostIdentity, IdentityError};
pub use pairing::{
    HostPairingCoordinator, PairingCoordinatorError, PairingOutbound, PairingRandom,
    PairingRandomError,
};
pub use remote_runtime::{
    PrivilegedBridgeRuntimeConfig, RemoteIceServerConfig, RemoteRuntimeConfig,
};
pub use remote_session::{
    RemotePeerEvent, RemotePeerEventSource, RemoteSessionContext, RemoteSessionCoordinator,
    RemoteSessionError, RemoteSessionFactory, RemoteSessionOutbound, RemoteSessionParts,
};
pub use remote_session_bridge::BridgeRemoteSessionFactory;
#[cfg(feature = "native-webrtc")]
pub use remote_session_native::NativeRemoteSessionFactory;
pub use runtime::{
    AgentRuntime, AgentRuntimeConfig, RunningAgent, RuntimeError, production_config_from_env,
    wait_for_shutdown_signal,
};
pub use service::{BridgeStatusError, HostService};
pub use session_auth::{
    OfferVerifier, SessionAuthenticationError, VerifiedSessionOffer,
    encode_session_answer_transcript, encode_session_offer_transcript,
    encode_session_reconnect_transcript,
};
pub use sessions::SessionRegistryError;
pub use signaling::{
    SignalingClientError, SignalingEvent, SignalingOutbox, SignalingProtocol,
    WebSocketSignalingTransport, validate_signaling_endpoint,
};

pub const COMPONENT_NAME: &str = "roammand-host-agent";

#[cfg(test)]
mod tests {
    use super::COMPONENT_NAME;
    #[cfg(all(feature = "native-webrtc", target_os = "macos"))]
    use roammand_host_webrtc::native::probe_native_video_codecs;
    use roammand_protocol::roammand::v1::ProtocolVersion;

    #[test]
    fn component_name_is_stable() {
        assert_eq!(COMPONENT_NAME, "roammand-host-agent");
    }

    #[test]
    fn host_agent_compiles_against_generated_protocol_types() {
        let version = ProtocolVersion { major: 1, minor: 0 };

        assert_eq!(version.major, 1);
        assert_eq!(version.minor, 0);
    }

    #[cfg(all(feature = "native-webrtc", target_os = "macos"))]
    #[test]
    fn final_host_target_links_native_webrtc_objc_categories() {
        assert!(!probe_native_video_codecs().is_empty());
    }
}
