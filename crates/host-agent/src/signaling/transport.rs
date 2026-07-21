// SPDX-License-Identifier: MPL-2.0

use std::{env, ffi::OsStr, time::Duration};

use futures_util::{SinkExt, StreamExt};
use prost::Message;
use roammand_protocol::{
    protocol_limits::{MAX_SIGNALING_ENDPOINT_UTF8_BYTES, MAX_SIGNALING_SERVICE_FRAME_BYTES},
    roammand::v1::SignalingClientFrame,
};
use tokio::{net::TcpStream, time::timeout};
use tokio_tungstenite::{
    MaybeTlsStream, WebSocketStream, connect_async_with_config,
    tungstenite::{
        Error as WebSocketError, Message as WebSocketMessage,
        client::IntoClientRequest,
        http::{HeaderValue, header::SEC_WEBSOCKET_PROTOCOL},
        protocol::WebSocketConfig,
    },
};
use url::{Host, Url};

use super::SignalingClientError;

const SIGNALING_WEBSOCKET_SUBPROTOCOL: &str = "roammand-signaling.v1.protobuf";
const LEGACY_SIGNALING_WEBSOCKET_SUBPROTOCOL: &str = "personal-remote-signaling.v1.protobuf";
const OFFERED_SIGNALING_WEBSOCKET_SUBPROTOCOLS: &str =
    "roammand-signaling.v1.protobuf, personal-remote-signaling.v1.protobuf";
const ALLOW_INSECURE_LAN_SIGNALING_ENV: &str = "ROAMMAND_ALLOW_INSECURE_LAN_SIGNALING";
const SIGNALING_TRANSPORT_TIMEOUT: Duration = Duration::from_secs(5);
// tungstenite applies both limits to decoded WebSocket payload bytes, excluding
// the WebSocket header, so the protobuf protocol cap needs no framing overhead.
const SIGNALING_WEBSOCKET_MAX_MESSAGE_BYTES: usize = MAX_SIGNALING_SERVICE_FRAME_BYTES;
const SIGNALING_WEBSOCKET_MAX_FRAME_PAYLOAD_BYTES: usize = MAX_SIGNALING_SERVICE_FRAME_BYTES;
const SIGNALING_DISABLE_NAGLE: bool = false;

pub struct WebSocketSignalingTransport {
    socket: WebSocketStream<MaybeTlsStream<TcpStream>>,
}

impl WebSocketSignalingTransport {
    /// Connects with the required binary protobuf subprotocol.
    ///
    /// # Errors
    ///
    /// Returns a stable error for endpoint policy, handshake, TLS, or
    /// subprotocol failures. Endpoint credentials are never retained.
    pub async fn connect(endpoint: &str) -> Result<Self, SignalingClientError> {
        validate_signaling_endpoint(endpoint)?;
        let mut request = endpoint
            .into_client_request()
            .map_err(|_| SignalingClientError::InvalidEndpoint)?;
        request.headers_mut().insert(
            SEC_WEBSOCKET_PROTOCOL,
            HeaderValue::from_static(OFFERED_SIGNALING_WEBSOCKET_SUBPROTOCOLS),
        );
        let websocket_config = WebSocketConfig::default()
            .max_message_size(Some(SIGNALING_WEBSOCKET_MAX_MESSAGE_BYTES))
            .max_frame_size(Some(SIGNALING_WEBSOCKET_MAX_FRAME_PAYLOAD_BYTES));
        let (socket, response) = timeout(
            SIGNALING_TRANSPORT_TIMEOUT,
            connect_async_with_config(request, Some(websocket_config), SIGNALING_DISABLE_NAGLE),
        )
        .await
        .map_err(|_| SignalingClientError::Transport)?
        .map_err(|_| SignalingClientError::Transport)?;
        let selected = response
            .headers()
            .get(SEC_WEBSOCKET_PROTOCOL)
            .and_then(|value| value.to_str().ok());
        if selected != Some(SIGNALING_WEBSOCKET_SUBPROTOCOL)
            && selected != Some(LEGACY_SIGNALING_WEBSOCKET_SUBPROTOCOL)
        {
            return Err(SignalingClientError::SubprotocolRequired);
        }
        Ok(Self { socket })
    }

    /// Sends one bounded protobuf frame as a binary WebSocket message.
    ///
    /// # Errors
    ///
    /// Returns a stable error for oversized frames or transport failure.
    pub async fn send(&mut self, frame: &SignalingClientFrame) -> Result<(), SignalingClientError> {
        let encoded = frame.encode_to_vec();
        if encoded.len() > MAX_SIGNALING_SERVICE_FRAME_BYTES {
            return Err(SignalingClientError::FrameTooLarge);
        }
        timeout(
            SIGNALING_TRANSPORT_TIMEOUT,
            self.socket.send(WebSocketMessage::Binary(encoded.into())),
        )
        .await
        .map_err(|_| SignalingClientError::Transport)?
        .map_err(|_| SignalingClientError::Transport)
    }

    /// Receives the next binary WebSocket payload and handles ping/pong.
    ///
    /// # Errors
    ///
    /// Returns a stable error for closure, non-binary application messages,
    /// oversized frames, or transport failure.
    pub async fn receive_binary(&mut self) -> Result<Vec<u8>, SignalingClientError> {
        loop {
            let message = self
                .socket
                .next()
                .await
                .ok_or(SignalingClientError::Closed)?
                .map_err(|error| map_websocket_receive_error(&error))?;
            match message {
                WebSocketMessage::Binary(encoded) => {
                    if encoded.len() > MAX_SIGNALING_SERVICE_FRAME_BYTES {
                        return Err(SignalingClientError::FrameTooLarge);
                    }
                    return Ok(encoded.to_vec());
                }
                WebSocketMessage::Ping(payload) => timeout(
                    SIGNALING_TRANSPORT_TIMEOUT,
                    self.socket.send(WebSocketMessage::Pong(payload)),
                )
                .await
                .map_err(|_| SignalingClientError::Transport)?
                .map_err(|_| SignalingClientError::Transport)?,
                WebSocketMessage::Pong(_) => {}
                WebSocketMessage::Close(_) => return Err(SignalingClientError::Closed),
                WebSocketMessage::Text(_) | WebSocketMessage::Frame(_) => {
                    return Err(SignalingClientError::InvalidFrame);
                }
            }
        }
    }

    /// Closes the WebSocket connection idempotently at the protocol layer.
    ///
    /// # Errors
    ///
    /// Returns a stable transport error when the close frame cannot be sent.
    pub async fn close(&mut self) -> Result<(), SignalingClientError> {
        timeout(SIGNALING_TRANSPORT_TIMEOUT, self.socket.close(None))
            .await
            .map_err(|_| SignalingClientError::Transport)?
            .map_err(|_| SignalingClientError::Transport)
    }
}

fn map_websocket_receive_error(error: &WebSocketError) -> SignalingClientError {
    match error {
        WebSocketError::Capacity(_) => SignalingClientError::FrameTooLarge,
        _ => SignalingClientError::Transport,
    }
}

/// Enforces TLS except for loopback and explicitly enabled private-network
/// development endpoints.
///
/// # Errors
///
/// Returns an error for malformed, credential-bearing, unsupported, or
/// disallowed plaintext endpoints.
pub fn validate_signaling_endpoint(endpoint: &str) -> Result<(), SignalingClientError> {
    let requested = env::var_os(ALLOW_INSECURE_LAN_SIGNALING_ENV);
    validate_signaling_endpoint_with_policy(
        endpoint,
        insecure_lan_signaling_enabled(cfg!(debug_assertions), requested.as_deref()),
    )
}

fn insecure_lan_signaling_enabled(debug_build: bool, requested: Option<&OsStr>) -> bool {
    debug_build && requested == Some(OsStr::new("true"))
}

fn validate_signaling_endpoint_with_policy(
    endpoint: &str,
    allow_insecure_lan: bool,
) -> Result<(), SignalingClientError> {
    if endpoint.len() > MAX_SIGNALING_ENDPOINT_UTF8_BYTES {
        return Err(SignalingClientError::InvalidEndpoint);
    }
    let url = Url::parse(endpoint).map_err(|_| SignalingClientError::InvalidEndpoint)?;
    if !url.username().is_empty() || url.password().is_some() {
        return Err(SignalingClientError::EndpointCredentials);
    }
    match url.scheme() {
        "wss" => Ok(()),
        "ws" if is_loopback(&url) => Ok(()),
        "ws" if allow_insecure_lan && is_private_network_address(&url) => Ok(()),
        "ws" => Err(SignalingClientError::InsecureEndpoint),
        _ => Err(SignalingClientError::InvalidEndpoint),
    }
}

fn is_private_network_address(url: &Url) -> bool {
    match url.host() {
        Some(Host::Ipv4(address)) => address.is_private(),
        Some(Host::Ipv6(address)) => address.is_unique_local(),
        Some(Host::Domain(_)) | None => false,
    }
}

fn is_loopback(url: &Url) -> bool {
    match url.host() {
        Some(Host::Domain(domain)) => domain.eq_ignore_ascii_case("localhost"),
        Some(Host::Ipv4(address)) => address.is_loopback(),
        Some(Host::Ipv6(address)) => address.is_loopback(),
        None => false,
    }
}

#[cfg(test)]
mod tests {
    use std::ffi::OsStr;

    use super::{
        SignalingClientError, insecure_lan_signaling_enabled,
        validate_signaling_endpoint_with_policy,
    };

    #[test]
    fn enables_insecure_lan_only_for_explicit_debug_configuration() {
        assert!(insecure_lan_signaling_enabled(
            true,
            Some(OsStr::new("true"))
        ));
        assert!(!insecure_lan_signaling_enabled(
            false,
            Some(OsStr::new("true"))
        ));
        assert!(!insecure_lan_signaling_enabled(
            true,
            Some(OsStr::new("false"))
        ));
        assert!(!insecure_lan_signaling_enabled(true, None));
    }

    #[test]
    fn allows_only_private_address_literals_when_development_policy_is_enabled() {
        for endpoint in [
            "ws://10.0.0.8:8080/v1/ws",
            "ws://172.16.4.2:8080/v1/ws",
            "ws://172.31.255.254:8080/v1/ws",
            "ws://192.168.3.168:8080/v1/ws",
            "ws://[fd00::8]:8080/v1/ws",
        ] {
            assert_eq!(
                validate_signaling_endpoint_with_policy(endpoint, true),
                Ok(()),
                "{endpoint}"
            );
        }

        for endpoint in [
            "ws://172.15.255.254:8080/v1/ws",
            "ws://172.32.0.1:8080/v1/ws",
            "ws://8.8.8.8:8080/v1/ws",
            "ws://signal.example.test:8080/v1/ws",
            "ws://[2001:4860:4860::8888]:8080/v1/ws",
        ] {
            assert_eq!(
                validate_signaling_endpoint_with_policy(endpoint, true),
                Err(SignalingClientError::InsecureEndpoint),
                "{endpoint}"
            );
        }
    }
}
