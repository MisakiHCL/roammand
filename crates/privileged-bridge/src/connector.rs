// SPDX-License-Identifier: MPL-2.0

use prost::Message;
use roammand_ipc::{AuthChannel, IpcToken, channel_client_proof, verify_channel_server_proof};
use roammand_protocol::{
    protocol_limits::{MINIMUM_PROTOCOL_MINOR_VERSION, PROTOCOL_MAJOR_VERSION},
    roammand::v1::{
        AcquirePrivilegedLeaseRequest, PrivilegedBridgeAuthenticate, PrivilegedBridgeClientFrame,
        PrivilegedBridgeRole, PrivilegedBridgeState, ProtocolVersion,
        privileged_bridge_client_frame, privileged_bridge_server_frame,
    },
    validation::decode_and_validate_privileged_bridge_server_frame,
};

use crate::{
    client::{BridgeConnection, BridgeRpc, BridgeRpcConnector},
    lease::LeaseId,
    proxy::{ProxyError, ProxyRoute, ProxySessionContext},
    rpc::FramedBridgeRpc,
    transport::LocalBridgeTransport,
};

const AUTH_REQUEST_ID: &str = "authenticate-1";
const ACQUIRE_REQUEST_ID: &str = "acquire-2";
const AUTH_SEQUENCE: u64 = 1;
const ACQUIRE_SEQUENCE: u64 = 2;

pub trait BridgeTransportConnector: Send {
    /// Opens a local-only stream after operating-system peer checks.
    ///
    /// # Errors
    ///
    /// Returns a stable category without revealing local endpoint details.
    fn connect(&mut self) -> Result<Box<dyn LocalBridgeTransport>, ProxyError>;
}

pub struct AuthenticatedBridgeConnector {
    connector: Box<dyn BridgeTransportConnector>,
    token: IpcToken,
    executable_sha256: [u8; 32],
    os_session_id: u64,
}

impl AuthenticatedBridgeConnector {
    /// Creates the fixed Host-side authentication and lease connector.
    ///
    /// # Errors
    ///
    /// Rejects missing OS session or executable identity values.
    pub fn new(
        connector: Box<dyn BridgeTransportConnector>,
        token: IpcToken,
        executable_sha256: [u8; 32],
        os_session_id: u64,
    ) -> Result<Self, ProxyError> {
        if os_session_id == 0 || executable_sha256 == [0; 32] {
            return Err(ProxyError::InvalidConfiguration);
        }
        Ok(Self {
            connector,
            token,
            executable_sha256,
            os_session_id,
        })
    }

    fn authenticate(
        &self,
        transport: &mut dyn LocalBridgeTransport,
    ) -> Result<roammand_protocol::roammand::v1::PrivilegedBridgeStatusSnapshot, ProxyError> {
        let challenge_frame = receive_server_frame(transport)?;
        let Some(privileged_bridge_server_frame::Payload::Challenge(challenge)) =
            challenge_frame.payload
        else {
            return Err(ProxyError::Rejected);
        };
        let instance_id: [u8; 16] = challenge
            .broker_instance_id
            .try_into()
            .map_err(|_| ProxyError::Rejected)?;
        let server_nonce: [u8; 32] = challenge
            .server_nonce
            .try_into()
            .map_err(|_| ProxyError::Rejected)?;
        let mut client_nonce = [0_u8; 32];
        getrandom::fill(&mut client_nonce).map_err(|_| ProxyError::Transport)?;
        let client_proof = channel_client_proof(
            &self.token,
            AuthChannel::PrivilegedHost,
            &instance_id,
            &server_nonce,
            &client_nonce,
        );
        send_client_frame(
            transport,
            &PrivilegedBridgeClientFrame {
                protocol_version: Some(version()),
                request_id: AUTH_REQUEST_ID.to_owned(),
                sequence: AUTH_SEQUENCE,
                payload: Some(privileged_bridge_client_frame::Payload::Authenticate(
                    PrivilegedBridgeAuthenticate {
                        role: PrivilegedBridgeRole::HostAgent as i32,
                        client_nonce: client_nonce.to_vec(),
                        client_proof: client_proof.to_vec(),
                        executable_sha256: self.executable_sha256.to_vec(),
                        os_session_id: self.os_session_id,
                    },
                )),
            },
        )?;
        let authenticated = receive_server_frame(transport)?;
        if authenticated.request_id != AUTH_REQUEST_ID || authenticated.sequence != AUTH_SEQUENCE {
            return Err(ProxyError::StaleResponse);
        }
        let proof = match authenticated.payload {
            Some(privileged_bridge_server_frame::Payload::Authenticated(value)) => {
                value.server_proof
            }
            _ => return Err(ProxyError::Rejected),
        };
        if !verify_channel_server_proof(
            &self.token,
            AuthChannel::PrivilegedHost,
            &instance_id,
            &server_nonce,
            &client_nonce,
            &proof,
        ) {
            return Err(ProxyError::Rejected);
        }

        let status = receive_server_frame(transport)?;
        let Some(privileged_bridge_server_frame::Payload::Status(status)) = status.payload else {
            return Err(ProxyError::Rejected);
        };
        let state =
            PrivilegedBridgeState::try_from(status.state).map_err(|_| ProxyError::Rejected)?;
        if state == PrivilegedBridgeState::UserSessionOnly && !status.helper_connected {
            return Err(ProxyError::HelperUnavailable);
        }
        if state != PrivilegedBridgeState::Ready {
            return Err(ProxyError::Rejected);
        }
        if !status.helper_connected {
            return Err(ProxyError::HelperUnavailable);
        }
        let session = status
            .interactive_session
            .as_ref()
            .ok_or(ProxyError::HelperUnavailable)?;
        if session.os_session_id != self.os_session_id || session.generation == 0 {
            return Err(ProxyError::Rejected);
        }
        Ok(status)
    }

    /// Authenticates the installed broker and returns its validated live route
    /// status without acquiring a session lease.
    ///
    /// # Errors
    ///
    /// Fails closed for unavailable transport, authentication, or route state.
    pub fn probe_status(
        &mut self,
    ) -> Result<roammand_protocol::roammand::v1::PrivilegedBridgeStatusSnapshot, ProxyError> {
        let mut transport = self.connector.connect()?;
        let status = self.authenticate(transport.as_mut());
        transport.fail_closed();
        status
    }
}

impl BridgeRpcConnector for AuthenticatedBridgeConnector {
    fn connect(&mut self, context: &ProxySessionContext) -> Result<BridgeConnection, ProxyError> {
        let mut transport = self.connector.connect()?;
        let status = match self.authenticate(transport.as_mut()) {
            Ok(status) => status,
            Err(error) => {
                transport.fail_closed();
                return Err(error);
            }
        };
        let generation = status
            .interactive_session
            .ok_or(ProxyError::Rejected)?
            .generation;
        let mut rpc = FramedBridgeRpc::new(transport);
        let response = rpc.call(PrivilegedBridgeClientFrame {
            protocol_version: Some(version()),
            request_id: ACQUIRE_REQUEST_ID.to_owned(),
            sequence: ACQUIRE_SEQUENCE,
            payload: Some(privileged_bridge_client_frame::Payload::AcquireLease(
                AcquirePrivilegedLeaseRequest {
                    session_id: context.session_id().to_vec(),
                    generation,
                    permissions: context
                        .permissions()
                        .iter()
                        .map(|permission| *permission as i32)
                        .collect(),
                    controller_display_name: context.controller_display_name().to_owned(),
                },
            )),
        })?;
        let Some(privileged_bridge_server_frame::Payload::Lease(lease)) = response.payload else {
            rpc.fail_closed();
            return Err(ProxyError::Rejected);
        };
        let Ok(lease_id) = lease.lease_id.try_into() else {
            rpc.fail_closed();
            return Err(ProxyError::InvalidMessage);
        };
        let expected_permissions = context
            .permissions()
            .iter()
            .map(|permission| *permission as i32)
            .collect::<Vec<_>>();
        if lease.generation != generation
            || lease.session_id != context.session_id()
            || lease.permissions != expected_permissions
            || lease.controller_display_name != context.controller_display_name()
        {
            rpc.fail_closed();
            return Err(ProxyError::Rejected);
        }
        Ok(BridgeConnection::with_next_frame_sequence(
            ProxyRoute::new(LeaseId::new(lease_id), lease.generation),
            Box::new(rpc),
            ACQUIRE_SEQUENCE + 1,
        ))
    }
}

fn receive_server_frame(
    transport: &mut dyn LocalBridgeTransport,
) -> Result<roammand_protocol::roammand::v1::PrivilegedBridgeServerFrame, ProxyError> {
    let encoded = transport.receive().map_err(|_| ProxyError::Transport)?;
    decode_and_validate_privileged_bridge_server_frame(&encoded)
        .map_err(|_| ProxyError::InvalidMessage)
}

fn send_client_frame(
    transport: &mut dyn LocalBridgeTransport,
    frame: &PrivilegedBridgeClientFrame,
) -> Result<(), ProxyError> {
    transport
        .send(&frame.encode_to_vec())
        .map_err(|_| ProxyError::Transport)
}

const fn version() -> ProtocolVersion {
    ProtocolVersion {
        major: PROTOCOL_MAJOR_VERSION,
        minor: MINIMUM_PROTOCOL_MINOR_VERSION,
    }
}
