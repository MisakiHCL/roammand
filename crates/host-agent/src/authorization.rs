// SPDX-License-Identifier: MPL-2.0

use std::{
    collections::{BTreeMap, BTreeSet, HashSet},
    sync::Arc,
};

use ed25519_dalek::VerifyingKey;
use roammand_protocol::{
    identity_derivation::derive_device_id_v1,
    protocol_limits::{DEVICE_ID_BYTES, MAX_CONTROLLER_GRANTS},
    roammand::v1::{ControllerGrant, ControllerGrantView, DeviceIdentity, SessionPermission},
    validation::validate_device_identity,
};
use thiserror::Error;

use crate::grant_store::{GrantStore, GrantStoreError};

const GRANT_ID_BYTES: usize = 16;
const GRANT_ID_GENERATION_ATTEMPTS: usize = 16;

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub enum AuthorizationError {
    #[error("authorization store failed")]
    Store(#[from] GrantStoreError),
    #[error("host identity is invalid")]
    InvalidHostIdentity,
    #[error("stored controller grant is invalid")]
    InvalidStoredGrant,
    #[error("stored grant identifier is duplicated")]
    DuplicateGrantId,
    #[error("stored controller grant is duplicated")]
    DuplicateController,
    #[error("controller identity is invalid")]
    InvalidController,
    #[error("a Host cannot authorize itself as a Controller")]
    SelfGrant,
    #[error("controller grant permissions are invalid")]
    InvalidPermissions,
    #[error("controller already has a different grant")]
    GrantConflict,
    #[error("controller grant limit reached")]
    GrantLimit,
    #[error("secure grant identifier generation failed")]
    RandomGeneration,
    #[error("controller grant was not found")]
    GrantNotFound,
}

pub struct AuthorizationRegistry {
    host_device_id: Vec<u8>,
    store: Arc<dyn GrantStore>,
    grants_by_controller: BTreeMap<Vec<u8>, ControllerGrantView>,
}

impl AuthorizationRegistry {
    /// Loads and validates all persisted one-way Controller grants.
    ///
    /// # Errors
    ///
    /// Returns an error for an invalid Host identifier, corrupt persisted
    /// grants, duplicate identifiers/controllers, or a store failure.
    pub fn load(
        host_device_id: Vec<u8>,
        store: Arc<dyn GrantStore>,
    ) -> Result<Self, AuthorizationError> {
        if host_device_id.len() != DEVICE_ID_BYTES {
            return Err(AuthorizationError::InvalidHostIdentity);
        }
        let loaded = store.load(&host_device_id)?;
        if loaded.len() > MAX_CONTROLLER_GRANTS {
            return Err(AuthorizationError::InvalidStoredGrant);
        }

        let mut grant_ids = HashSet::with_capacity(loaded.len());
        let mut grants_by_controller = BTreeMap::new();
        for view in loaded {
            let controller_id = validate_stored_grant(&view, &host_device_id)?;
            let grant_id = &view
                .grant
                .as_ref()
                .ok_or(AuthorizationError::InvalidStoredGrant)?
                .grant_id;
            if !grant_ids.insert(grant_id.clone()) {
                return Err(AuthorizationError::DuplicateGrantId);
            }
            if grants_by_controller.insert(controller_id, view).is_some() {
                return Err(AuthorizationError::DuplicateController);
            }
        }

        Ok(Self {
            host_device_id,
            store,
            grants_by_controller,
        })
    }

    #[must_use]
    pub fn list_controller_grants(&self) -> Vec<ControllerGrantView> {
        self.grants_by_controller.values().cloned().collect()
    }

    #[must_use]
    pub fn controller_grant(&self, controller_device_id: &[u8]) -> Option<&ControllerGrantView> {
        self.grants_by_controller.get(controller_device_id)
    }

    /// Creates a one-way Controller → Host grant or returns an identical grant.
    ///
    /// # Errors
    ///
    /// Returns an error for invalid identity/permissions, self-authorization,
    /// conflicting existing authorization, limits, randomness, or persistence.
    pub fn create_controller_grant(
        &mut self,
        controller: DeviceIdentity,
        permissions: &[SessionPermission],
        created_at_unix_ms: u64,
    ) -> Result<ControllerGrantView, AuthorizationError> {
        validate_controller(&controller)?;
        if controller.device_id == self.host_device_id {
            return Err(AuthorizationError::SelfGrant);
        }
        let normalized_permissions = normalize_permissions(permissions)?;

        if let Some(existing) = self.grants_by_controller.get(&controller.device_id) {
            let existing_grant = existing
                .grant
                .as_ref()
                .ok_or(AuthorizationError::InvalidStoredGrant)?;
            if existing_grant.controller.as_ref() == Some(&controller)
                && existing_grant.permissions == normalized_permissions
            {
                return Ok(existing.clone());
            }
            return Err(AuthorizationError::GrantConflict);
        }
        if self.grants_by_controller.len() >= MAX_CONTROLLER_GRANTS {
            return Err(AuthorizationError::GrantLimit);
        }

        let view = ControllerGrantView {
            grant: Some(ControllerGrant {
                grant_id: self.generate_grant_id()?,
                host_device_id: self.host_device_id.clone(),
                controller: Some(controller.clone()),
                created_at_unix_ms,
                permissions: normalized_permissions,
            }),
            last_successful_connection_at_unix_ms: 0,
        };
        let mut next = self.list_controller_grants();
        next.push(view.clone());
        sort_grants(&mut next);
        self.store.persist(&self.host_device_id, &next)?;
        self.grants_by_controller
            .insert(controller.device_id, view.clone());
        Ok(view)
    }

    /// Records a successful remote session authentication for a Controller.
    ///
    /// # Errors
    ///
    /// Returns an error when the Controller has no grant or persistence fails.
    pub fn record_authenticated_session(
        &mut self,
        controller_device_id: &[u8],
        authenticated_at_unix_ms: u64,
    ) -> Result<ControllerGrantView, AuthorizationError> {
        let existing = self
            .grants_by_controller
            .get(controller_device_id)
            .ok_or(AuthorizationError::GrantNotFound)?;
        if authenticated_at_unix_ms <= existing.last_successful_connection_at_unix_ms {
            return Ok(existing.clone());
        }

        let mut updated = existing.clone();
        updated.last_successful_connection_at_unix_ms = authenticated_at_unix_ms;
        let mut next = self.list_controller_grants();
        let next_entry = next
            .iter_mut()
            .find(|view| controller_device_id_for(view) == Some(controller_device_id))
            .ok_or(AuthorizationError::InvalidStoredGrant)?;
        *next_entry = updated.clone();
        self.store.persist(&self.host_device_id, &next)?;
        self.grants_by_controller
            .insert(controller_device_id.to_vec(), updated.clone());
        Ok(updated)
    }

    /// Persistently removes a grant before changing the in-memory registry.
    ///
    /// # Errors
    ///
    /// Returns an error when the grant does not exist or persistence fails.
    pub fn revoke_controller_grant(
        &mut self,
        grant_id: &[u8],
    ) -> Result<ControllerGrantView, AuthorizationError> {
        let controller_id = self
            .grants_by_controller
            .iter()
            .find_map(|(controller_id, view)| {
                (view
                    .grant
                    .as_ref()
                    .is_some_and(|grant| grant.grant_id == grant_id))
                .then(|| controller_id.clone())
            })
            .ok_or(AuthorizationError::GrantNotFound)?;
        let mut next = self.list_controller_grants();
        next.retain(|view| controller_device_id_for(view) != Some(controller_id.as_slice()));
        self.store.persist(&self.host_device_id, &next)?;
        self.grants_by_controller
            .remove(&controller_id)
            .ok_or(AuthorizationError::InvalidStoredGrant)
    }

    fn generate_grant_id(&self) -> Result<Vec<u8>, AuthorizationError> {
        for _ in 0..GRANT_ID_GENERATION_ATTEMPTS {
            let mut grant_id = [0_u8; GRANT_ID_BYTES];
            getrandom::fill(&mut grant_id).map_err(|_| AuthorizationError::RandomGeneration)?;
            let already_exists = self.grants_by_controller.values().any(|view| {
                view.grant
                    .as_ref()
                    .is_some_and(|grant| grant.grant_id == grant_id)
            });
            if !already_exists {
                return Ok(grant_id.to_vec());
            }
        }
        Err(AuthorizationError::RandomGeneration)
    }
}

fn validate_stored_grant(
    view: &ControllerGrantView,
    expected_host_device_id: &[u8],
) -> Result<Vec<u8>, AuthorizationError> {
    let grant = view
        .grant
        .as_ref()
        .ok_or(AuthorizationError::InvalidStoredGrant)?;
    if grant.grant_id.len() != GRANT_ID_BYTES || grant.host_device_id != expected_host_device_id {
        return Err(AuthorizationError::InvalidStoredGrant);
    }
    let controller = grant
        .controller
        .as_ref()
        .ok_or(AuthorizationError::InvalidStoredGrant)?;
    validate_controller(controller).map_err(|_| AuthorizationError::InvalidStoredGrant)?;
    if controller.device_id == expected_host_device_id {
        return Err(AuthorizationError::InvalidStoredGrant);
    }
    let normalized = normalize_stored_permissions(&grant.permissions)
        .map_err(|_| AuthorizationError::InvalidStoredGrant)?;
    if normalized != grant.permissions {
        return Err(AuthorizationError::InvalidStoredGrant);
    }
    Ok(controller.device_id.clone())
}

fn validate_controller(controller: &DeviceIdentity) -> Result<(), AuthorizationError> {
    validate_device_identity(controller).map_err(|_| AuthorizationError::InvalidController)?;
    let public_key: [u8; 32] = controller
        .public_key
        .as_slice()
        .try_into()
        .map_err(|_| AuthorizationError::InvalidController)?;
    VerifyingKey::from_bytes(&public_key).map_err(|_| AuthorizationError::InvalidController)?;
    let derived =
        derive_device_id_v1(&public_key).map_err(|_| AuthorizationError::InvalidController)?;
    if controller.device_id != derived {
        return Err(AuthorizationError::InvalidController);
    }
    Ok(())
}

fn normalize_permissions(
    permissions: &[SessionPermission],
) -> Result<Vec<i32>, AuthorizationError> {
    normalize_stored_permissions(
        &permissions
            .iter()
            .map(|permission| *permission as i32)
            .collect::<Vec<_>>(),
    )
}

fn normalize_stored_permissions(permissions: &[i32]) -> Result<Vec<i32>, AuthorizationError> {
    if permissions.is_empty() {
        return Err(AuthorizationError::InvalidPermissions);
    }
    let mut normalized = BTreeSet::new();
    for value in permissions {
        let permission = SessionPermission::try_from(*value)
            .map_err(|_| AuthorizationError::InvalidPermissions)?;
        if permission == SessionPermission::Unspecified || !normalized.insert(*value) {
            return Err(AuthorizationError::InvalidPermissions);
        }
    }
    if normalized.contains(&(SessionPermission::ControlInput as i32))
        && !normalized.contains(&(SessionPermission::ViewScreen as i32))
    {
        return Err(AuthorizationError::InvalidPermissions);
    }
    Ok(normalized.into_iter().collect())
}

fn controller_device_id_for(view: &ControllerGrantView) -> Option<&[u8]> {
    view.grant
        .as_ref()?
        .controller
        .as_ref()
        .map(|controller| controller.device_id.as_slice())
}

fn sort_grants(grants: &mut [ControllerGrantView]) {
    grants.sort_by(|left, right| {
        controller_device_id_for(left).cmp(&controller_device_id_for(right))
    });
}
