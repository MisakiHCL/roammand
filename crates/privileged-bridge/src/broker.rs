// SPDX-License-Identifier: MPL-2.0

use crate::{
    lease::{
        AcquireLease, Lease, LeaseError, LeaseId, LeaseManager, SessionId, SystemLeaseIdSource,
    },
    proxy::ProxyRoute,
    session::{RouteEvent, SessionAction, SessionError, SessionStateMachine},
};
use roammand_protocol::roammand::v1::{
    PrivilegedBridgeClientFrame, PrivilegedBridgeServerFrame, PrivilegedLease, ProtocolVersion,
    SessionPermission, privileged_bridge_client_frame, privileged_bridge_server_frame,
};
use thiserror::Error;

#[derive(Debug)]
pub struct BrokerCore {
    leases: LeaseManager,
    routes: SessionStateMachine,
    ids: SystemLeaseIdSource,
}

impl BrokerCore {
    #[must_use]
    pub const fn new(instance_id: [u8; 16]) -> Self {
        Self {
            leases: LeaseManager::new(instance_id),
            routes: SessionStateMachine::new(),
            ids: SystemLeaseIdSource,
        }
    }

    /// Registers the one authenticated current-user Host.
    ///
    /// # Errors
    ///
    /// Returns normal lease errors for repeated or stale connections.
    pub fn connect_host(&mut self, generation: u64) -> Result<(), LeaseError> {
        self.leases.connect_host(generation)
    }

    #[must_use]
    pub fn disconnect_host(&mut self) -> bool {
        self.leases.disconnect_host()
    }

    /// Applies an OS graphical-session observation.
    ///
    /// # Errors
    ///
    /// Rejects stale, conflicting, or gapped routes without changing state.
    pub fn observe_route(&mut self, event: RouteEvent) -> Result<Vec<SessionAction>, SessionError> {
        self.routes.apply(event)
    }

    /// Acquires the sole ephemeral route lease using OS randomness.
    ///
    /// # Errors
    ///
    /// Returns normal fail-closed lease errors.
    pub fn acquire(&mut self, request: AcquireLease, now_ms: u64) -> Result<Lease, LeaseError> {
        self.leases.acquire(request, now_ms, &mut self.ids)
    }

    /// Renews the active route lease.
    ///
    /// # Errors
    ///
    /// Returns the stable lease state error from the manager.
    pub fn renew(
        &mut self,
        id: LeaseId,
        generation: u64,
        now_ms: u64,
    ) -> Result<Lease, LeaseError> {
        self.leases.renew(id, generation, now_ms)
    }

    /// Authorizes the next exact routed operation.
    ///
    /// # Errors
    ///
    /// Rejects stale, expired, or out-of-order operations.
    pub fn authorize_command(
        &mut self,
        id: LeaseId,
        generation: u64,
        sequence: u64,
        now_ms: u64,
    ) -> Result<(), LeaseError> {
        self.leases
            .authorize_command(id, generation, sequence, now_ms)
    }

    /// Releases the active route lease idempotently.
    ///
    /// # Errors
    ///
    /// Rejects a foreign or stale lease reference.
    pub fn release(&mut self, id: LeaseId, generation: u64) -> Result<bool, LeaseError> {
        self.leases.release(id, generation)
    }

    /// Enables the current route only after lease acquisition.
    ///
    /// # Errors
    ///
    /// Rejects an unavailable or stale graphical route.
    pub fn begin_control(&mut self, generation: u64) -> Result<(), SessionError> {
        self.routes.begin_control(generation)
    }

    #[must_use]
    pub const fn routes(&self) -> &SessionStateMachine {
        &self.routes
    }

    #[must_use]
    pub const fn leases(&self) -> &LeaseManager {
        &self.leases
    }
}

pub trait BrokerHelper: Send {
    /// Forwards one broker-authorized typed request to the current Helper.
    ///
    /// # Errors
    ///
    /// Returns a stable error without exposing native peer data.
    fn exchange(
        &mut self,
        request: PrivilegedBridgeClientFrame,
    ) -> Result<PrivilegedBridgeServerFrame, BrokerProtocolError>;

    /// Polls one unsolicited Helper event.
    ///
    /// # Errors
    ///
    /// Returns a stable Helper transport or message error.
    fn try_event(&mut self) -> Result<Option<PrivilegedBridgeServerFrame>, BrokerProtocolError> {
        Ok(None)
    }

    fn fail_closed(&mut self);
}

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub enum BrokerProtocolError {
    #[error("broker message is invalid")]
    InvalidMessage,
    #[error("broker lease rejected the request")]
    Lease,
    #[error("broker permission denied the request")]
    PermissionDenied,
    #[error("broker Helper failed")]
    Helper,
    #[error("broker Helper response is stale")]
    StaleResponse,
}

pub struct HostBrokerSession {
    broker: BrokerCore,
    helper: Box<dyn BrokerHelper>,
    permissions: Vec<i32>,
    operation_sequence: u64,
    secure_attention_allowed: bool,
}

impl HostBrokerSession {
    #[must_use]
    pub fn new(broker: BrokerCore, helper: Box<dyn BrokerHelper>) -> Self {
        Self {
            broker,
            helper,
            permissions: Vec::new(),
            operation_sequence: 0,
            secure_attention_allowed: false,
        }
    }

    #[must_use]
    pub const fn with_secure_attention(mut self, allowed: bool) -> Self {
        self.secure_attention_allowed = allowed;
        self
    }

    /// Applies one strictly decoded Host request against the active lease.
    ///
    /// # Errors
    ///
    /// Rejects invalid state, permissions, route references, and stale Helper responses.
    pub fn handle(
        &mut self,
        request: PrivilegedBridgeClientFrame,
        now_ms: u64,
    ) -> Result<PrivilegedBridgeServerFrame, BrokerProtocolError> {
        let payload = request
            .payload
            .clone()
            .ok_or(BrokerProtocolError::InvalidMessage)?;
        match payload {
            privileged_bridge_client_frame::Payload::AcquireLease(value) => {
                self.acquire(&request, value, now_ms)
            }
            privileged_bridge_client_frame::Payload::RenewLease(value) => {
                let route = parse_route(&value.lease_id, value.generation)?;
                let lease = self
                    .broker
                    .renew(route.lease_id, route.generation, now_ms)
                    .map_err(|_| BrokerProtocolError::Lease)?;
                Ok(lease_response(&request, &lease, &self.permissions))
            }
            privileged_bridge_client_frame::Payload::ReleaseLease(value) => {
                let route = parse_route(&value.lease_id, value.generation)?;
                let response = self.forward(request, route)?;
                self.broker
                    .release(route.lease_id, route.generation)
                    .map_err(|_| BrokerProtocolError::Lease)?;
                self.permissions.clear();
                Ok(response)
            }
            privileged_bridge_client_frame::Payload::InputCommand(_) => {
                if !self
                    .permissions
                    .contains(&(SessionPermission::ControlInput as i32))
                {
                    return Err(BrokerProtocolError::PermissionDenied);
                }
                self.forward_authorized(request, now_ms)
            }
            privileged_bridge_client_frame::Payload::SendSecureAttention(_) => {
                if !self.secure_attention_allowed
                    || !self
                        .permissions
                        .contains(&(SessionPermission::ControlInput as i32))
                {
                    return Err(BrokerProtocolError::PermissionDenied);
                }
                self.forward_authorized(request, now_ms)
            }
            privileged_bridge_client_frame::Payload::StartPeer(_)
            | privileged_bridge_client_frame::Payload::RestartPeer(_)
            | privileged_bridge_client_frame::Payload::AddIceCandidate(_)
            | privileged_bridge_client_frame::Payload::ClosePeer(_) => {
                self.forward_authorized(request, now_ms)
            }
            privileged_bridge_client_frame::Payload::Authenticate(_)
            | privileged_bridge_client_frame::Payload::RegisterHelper(_) => {
                Err(BrokerProtocolError::InvalidMessage)
            }
        }
    }

    /// Polls one event and verifies it still belongs to the active lease.
    ///
    /// # Errors
    ///
    /// Rejects stale or malformed Helper events.
    pub fn try_event(
        &mut self,
    ) -> Result<Option<PrivilegedBridgeServerFrame>, BrokerProtocolError> {
        let Some(response) = self.helper.try_event()? else {
            return Ok(None);
        };
        let active = self
            .broker
            .leases()
            .active()
            .ok_or(BrokerProtocolError::Lease)?;
        let expected = ProxyRoute::new(active.id(), active.generation());
        if response_route(&response)? != expected {
            self.helper.fail_closed();
            return Err(BrokerProtocolError::StaleResponse);
        }
        Ok(Some(response))
    }

    #[must_use]
    pub fn expire(&mut self, now_ms: u64) -> bool {
        if self.broker.leases.expire(now_ms).is_some() {
            self.helper.fail_closed();
            self.permissions.clear();
            return true;
        }
        false
    }

    pub fn fail_closed(&mut self) {
        self.helper.fail_closed();
        let _ = self.broker.disconnect_host();
        self.permissions.clear();
    }

    fn acquire(
        &mut self,
        request: &PrivilegedBridgeClientFrame,
        value: roammand_protocol::roammand::v1::AcquirePrivilegedLeaseRequest,
        now_ms: u64,
    ) -> Result<PrivilegedBridgeServerFrame, BrokerProtocolError> {
        let session_id: [u8; 16] = value
            .session_id
            .try_into()
            .map_err(|_| BrokerProtocolError::InvalidMessage)?;
        let may_control_input = value
            .permissions
            .contains(&(SessionPermission::ControlInput as i32));
        let lease = self
            .broker
            .acquire(
                AcquireLease {
                    session_id: SessionId::new(session_id),
                    generation: value.generation,
                    controller_display_name: value.controller_display_name,
                    may_control_input,
                },
                now_ms,
            )
            .map_err(|_| BrokerProtocolError::Lease)?;
        self.broker
            .begin_control(lease.generation())
            .map_err(|_| BrokerProtocolError::Lease)?;
        self.permissions = value.permissions;
        self.operation_sequence = 0;
        Ok(lease_response(request, &lease, &self.permissions))
    }

    fn forward_authorized(
        &mut self,
        request: PrivilegedBridgeClientFrame,
        now_ms: u64,
    ) -> Result<PrivilegedBridgeServerFrame, BrokerProtocolError> {
        if let Some(controller_display_name) = request_controller_display_name(&request) {
            let expected = self
                .broker
                .leases()
                .active()
                .ok_or(BrokerProtocolError::Lease)?
                .controller_display_name();
            if controller_display_name != expected {
                return Err(BrokerProtocolError::InvalidMessage);
            }
        }
        let route = request_route(&request)?;
        self.operation_sequence = self
            .operation_sequence
            .checked_add(1)
            .ok_or(BrokerProtocolError::Lease)?;
        self.broker
            .authorize_command(
                route.lease_id,
                route.generation,
                self.operation_sequence,
                now_ms,
            )
            .map_err(|_| BrokerProtocolError::Lease)?;
        self.forward(request, route)
    }

    fn forward(
        &mut self,
        request: PrivilegedBridgeClientFrame,
        route: ProxyRoute,
    ) -> Result<PrivilegedBridgeServerFrame, BrokerProtocolError> {
        let request_id = request.request_id.clone();
        let sequence = request.sequence;
        let response = self.helper.exchange(request)?;
        if response.request_id != request_id
            || response.sequence != sequence
            || response_route(&response)? != route
        {
            self.helper.fail_closed();
            return Err(BrokerProtocolError::StaleResponse);
        }
        Ok(response)
    }
}

fn request_controller_display_name(request: &PrivilegedBridgeClientFrame) -> Option<&str> {
    match request.payload.as_ref()? {
        privileged_bridge_client_frame::Payload::StartPeer(value) => {
            Some(&value.controller_display_name)
        }
        privileged_bridge_client_frame::Payload::RestartPeer(value) => {
            Some(&value.controller_display_name)
        }
        _ => None,
    }
}

fn lease_response(
    request: &PrivilegedBridgeClientFrame,
    lease: &Lease,
    permissions: &[i32],
) -> PrivilegedBridgeServerFrame {
    response_frame(
        request,
        privileged_bridge_server_frame::Payload::Lease(PrivilegedLease {
            lease_id: lease.id().into_bytes().to_vec(),
            generation: lease.generation(),
            issued_at_unix_ms: lease.issued_at_ms(),
            expires_at_unix_ms: lease.expires_at_ms(),
            session_id: lease.session_id().into_bytes().to_vec(),
            permissions: permissions.to_vec(),
            controller_display_name: lease.controller_display_name().to_owned(),
        }),
    )
}

fn response_frame(
    request: &PrivilegedBridgeClientFrame,
    payload: privileged_bridge_server_frame::Payload,
) -> PrivilegedBridgeServerFrame {
    PrivilegedBridgeServerFrame {
        protocol_version: Some(ProtocolVersion { major: 1, minor: 0 }),
        request_id: request.request_id.clone(),
        sequence: request.sequence,
        payload: Some(payload),
    }
}

fn request_route(request: &PrivilegedBridgeClientFrame) -> Result<ProxyRoute, BrokerProtocolError> {
    let payload = request
        .payload
        .as_ref()
        .ok_or(BrokerProtocolError::InvalidMessage)?;
    let (lease_id, generation) = match payload {
        privileged_bridge_client_frame::Payload::StartPeer(value) => {
            (&value.lease_id, value.generation)
        }
        privileged_bridge_client_frame::Payload::RestartPeer(value) => {
            (&value.lease_id, value.generation)
        }
        privileged_bridge_client_frame::Payload::AddIceCandidate(value) => {
            (&value.lease_id, value.generation)
        }
        privileged_bridge_client_frame::Payload::SendSecureAttention(value) => {
            (&value.lease_id, value.generation)
        }
        privileged_bridge_client_frame::Payload::InputCommand(value) => {
            (&value.lease_id, value.generation)
        }
        privileged_bridge_client_frame::Payload::ClosePeer(value) => {
            (&value.lease_id, value.generation)
        }
        _ => return Err(BrokerProtocolError::InvalidMessage),
    };
    parse_route(lease_id, generation)
}

fn response_route(
    response: &PrivilegedBridgeServerFrame,
) -> Result<ProxyRoute, BrokerProtocolError> {
    let payload = response
        .payload
        .as_ref()
        .ok_or(BrokerProtocolError::InvalidMessage)?;
    let (lease_id, generation) = match payload {
        privileged_bridge_server_frame::Payload::CommandAccepted(value) => {
            (&value.lease_id, value.generation)
        }
        privileged_bridge_server_frame::Payload::PeerAnswer(value) => {
            (&value.lease_id, value.generation)
        }
        privileged_bridge_server_frame::Payload::LocalIceCandidate(value) => {
            (&value.lease_id, value.generation)
        }
        privileged_bridge_server_frame::Payload::PeerStateChanged(value) => {
            (&value.lease_id, value.generation)
        }
        privileged_bridge_server_frame::Payload::ReliableInput(value) => {
            (&value.lease_id, value.generation)
        }
        privileged_bridge_server_frame::Payload::FastPointer(value) => {
            (&value.lease_id, value.generation)
        }
        _ => return Err(BrokerProtocolError::InvalidMessage),
    };
    parse_route(lease_id, generation)
}

fn parse_route(lease_id: &[u8], generation: u64) -> Result<ProxyRoute, BrokerProtocolError> {
    let lease_id: [u8; 16] = lease_id
        .try_into()
        .map_err(|_| BrokerProtocolError::InvalidMessage)?;
    if generation == 0 {
        return Err(BrokerProtocolError::InvalidMessage);
    }
    Ok(ProxyRoute::new(LeaseId::new(lease_id), generation))
}
