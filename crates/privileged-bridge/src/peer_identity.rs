// SPDX-License-Identifier: MPL-2.0

use std::fmt;

use thiserror::Error;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum PeerRole {
    HostAgent,
    SessionHelper,
}

#[derive(Clone, Copy, Eq, PartialEq)]
pub enum PeerPrincipal {
    Unix {
        actual_uid: u32,
        expected_uid: u32,
    },
    Windows {
        sid_matches: bool,
        administrator_or_system: bool,
    },
}

#[derive(Clone, Eq, PartialEq)]
#[allow(clippy::struct_excessive_bools)]
pub struct ExecutableEvidence {
    pub absolute: bool,
    pub installed_location: bool,
    pub trusted_owner: bool,
    pub immutable_parent_directories: bool,
    pub actual_sha256: Option<[u8; 32]>,
    pub manifest_sha256: [u8; 32],
    pub signing_identity_matches: Option<bool>,
    pub signing_identity_required: bool,
}

#[derive(Clone, Eq, PartialEq)]
pub struct PeerIdentityEvidence {
    pub role: PeerRole,
    pub local_transport: bool,
    pub process_id: Option<u32>,
    pub principal: Option<PeerPrincipal>,
    pub os_session_id: Option<u64>,
    pub expected_os_session_id: u64,
    pub executable: Option<ExecutableEvidence>,
}

#[allow(clippy::missing_fields_in_debug)]
impl fmt::Debug for PeerIdentityEvidence {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter
            .debug_struct("PeerIdentityEvidence")
            .field("role", &self.role)
            .field("gates", &RedactedGates)
            .finish()
    }
}

struct RedactedGates;

impl fmt::Debug for RedactedGates {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str("[REDACTED]")
    }
}

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub enum PeerIdentityError {
    #[error("peer identity rejected")]
    Rejected,
}

#[derive(Clone, Copy, Eq, PartialEq)]
pub struct VerifiedPeer {
    role: PeerRole,
    os_session_id: u64,
}

impl VerifiedPeer {
    #[must_use]
    pub const fn role(&self) -> PeerRole {
        self.role
    }

    #[must_use]
    pub const fn os_session_id(&self) -> u64 {
        self.os_session_id
    }
}

#[allow(clippy::missing_fields_in_debug)]
impl fmt::Debug for VerifiedPeer {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter
            .debug_struct("VerifiedPeer")
            .field("role", &self.role)
            .field("session", &"[REDACTED]")
            .finish()
    }
}

/// Applies every local peer, principal, session, installation, ownership, hash,
/// and optional signing-identity gate as one fail-closed decision.
///
/// # Errors
///
/// Returns only [`PeerIdentityError::Rejected`] so diagnostics cannot disclose
/// which local identity evidence was observed.
pub fn validate_peer_identity(
    evidence: &PeerIdentityEvidence,
) -> Result<VerifiedPeer, PeerIdentityError> {
    if !evidence.local_transport || evidence.process_id.is_none_or(|pid| pid == 0) {
        return Err(PeerIdentityError::Rejected);
    }
    let principal_matches = match evidence.principal {
        Some(PeerPrincipal::Unix {
            actual_uid,
            expected_uid,
        }) => actual_uid == expected_uid,
        Some(PeerPrincipal::Windows {
            sid_matches,
            administrator_or_system,
        }) => sid_matches && administrator_or_system,
        None => false,
    };
    if !principal_matches {
        return Err(PeerIdentityError::Rejected);
    }
    let os_session_id = evidence
        .os_session_id
        .filter(|value| *value != 0 && *value == evidence.expected_os_session_id)
        .ok_or(PeerIdentityError::Rejected)?;
    let executable = evidence
        .executable
        .as_ref()
        .ok_or(PeerIdentityError::Rejected)?;
    if !executable.absolute
        || !executable.installed_location
        || !executable.trusted_owner
        || !executable.immutable_parent_directories
        || executable.actual_sha256 != Some(executable.manifest_sha256)
        || executable.signing_identity_matches == Some(false)
        || (executable.signing_identity_required
            && executable.signing_identity_matches != Some(true))
    {
        return Err(PeerIdentityError::Rejected);
    }
    Ok(VerifiedPeer {
        role: evidence.role,
        os_session_id,
    })
}
