// SPDX-License-Identifier: MPL-2.0

use std::{collections::BTreeMap, sync::Mutex};

use roammand_protocol::{
    protocol_limits::{DEVICE_ID_BYTES, SESSION_ID_BYTES},
    roammand::v1::{ErrorCode, SessionTerminatedEvent},
};
use thiserror::Error;
use tokio::sync::broadcast;

const TERMINATION_EVENT_CAPACITY: usize = 32;

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub enum SessionRegistryError {
    #[error("active session identity is invalid")]
    InvalidIdentity,
    #[error("active session identifier is already registered")]
    DuplicateSession,
    #[error("active session registry is unavailable")]
    Unavailable,
}

pub(crate) struct SessionRegistry {
    sessions: Mutex<BTreeMap<Vec<u8>, Vec<u8>>>,
    terminations: broadcast::Sender<SessionTerminatedEvent>,
}

impl SessionRegistry {
    pub(crate) fn new() -> Self {
        let (terminations, _) = broadcast::channel(TERMINATION_EVENT_CAPACITY);
        Self {
            sessions: Mutex::new(BTreeMap::new()),
            terminations,
        }
    }

    pub(crate) fn register(
        &self,
        session_id: Vec<u8>,
        controller_device_id: Vec<u8>,
    ) -> Result<(), SessionRegistryError> {
        if session_id.len() != SESSION_ID_BYTES || controller_device_id.len() != DEVICE_ID_BYTES {
            return Err(SessionRegistryError::InvalidIdentity);
        }
        let mut sessions = self
            .sessions
            .lock()
            .map_err(|_| SessionRegistryError::Unavailable)?;
        if sessions.contains_key(&session_id) {
            return Err(SessionRegistryError::DuplicateSession);
        }
        sessions.insert(session_id, controller_device_id);
        Ok(())
    }

    pub(crate) fn terminate_controller(
        &self,
        controller_device_id: &[u8],
    ) -> Result<Vec<SessionTerminatedEvent>, SessionRegistryError> {
        let mut sessions = self
            .sessions
            .lock()
            .map_err(|_| SessionRegistryError::Unavailable)?;
        let session_ids = sessions
            .iter()
            .filter(|(_, controller)| controller.as_slice() == controller_device_id)
            .map(|(session_id, _)| session_id.clone())
            .collect::<Vec<_>>();
        for session_id in &session_ids {
            sessions.remove(session_id);
        }
        drop(sessions);

        let events = session_ids
            .into_iter()
            .map(|session_id| SessionTerminatedEvent {
                session_id,
                controller_device_id: controller_device_id.to_vec(),
                reason: ErrorCode::AuthRevoked as i32,
            })
            .collect::<Vec<_>>();
        for event in &events {
            let _ = self.terminations.send(event.clone());
        }
        Ok(events)
    }

    pub(crate) fn terminate_all(
        &self,
        reason: ErrorCode,
    ) -> Result<Vec<SessionTerminatedEvent>, SessionRegistryError> {
        let mut sessions = self
            .sessions
            .lock()
            .map_err(|_| SessionRegistryError::Unavailable)?;
        let active = std::mem::take(&mut *sessions);
        drop(sessions);

        let events = active
            .into_iter()
            .map(
                |(session_id, controller_device_id)| SessionTerminatedEvent {
                    session_id,
                    controller_device_id,
                    reason: reason as i32,
                },
            )
            .collect::<Vec<_>>();
        for event in &events {
            let _ = self.terminations.send(event.clone());
        }
        Ok(events)
    }

    pub(crate) fn unregister(&self, session_id: &[u8]) -> Result<bool, SessionRegistryError> {
        if session_id.len() != SESSION_ID_BYTES {
            return Err(SessionRegistryError::InvalidIdentity);
        }
        self.sessions
            .lock()
            .map(|mut sessions| sessions.remove(session_id).is_some())
            .map_err(|_| SessionRegistryError::Unavailable)
    }

    pub(crate) fn subscribe(&self) -> broadcast::Receiver<SessionTerminatedEvent> {
        self.terminations.subscribe()
    }

    pub(crate) fn count(&self) -> Result<usize, SessionRegistryError> {
        self.sessions
            .lock()
            .map(|sessions| sessions.len())
            .map_err(|_| SessionRegistryError::Unavailable)
    }
}
