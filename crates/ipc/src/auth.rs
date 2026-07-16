// SPDX-License-Identifier: MPL-2.0

use std::fmt;

use hmac::{Hmac, KeyInit, Mac};
use sha2::Sha256;
use zeroize::Zeroizing;

const CLIENT_PROOF_DOMAIN: &[u8] = b"PRD-IPC-CLIENT-V1";
const SERVER_PROOF_DOMAIN: &[u8] = b"PRD-IPC-SERVER-V1";
const PRIVILEGED_HOST_CLIENT_DOMAIN: &[u8] = b"PRD-BRIDGE-HOST-CLIENT-V1";
const PRIVILEGED_HOST_SERVER_DOMAIN: &[u8] = b"PRD-BRIDGE-HOST-SERVER-V1";
const PRIVILEGED_HELPER_CLIENT_DOMAIN: &[u8] = b"PRD-BRIDGE-HELPER-CLIENT-V1";
const PRIVILEGED_HELPER_SERVER_DOMAIN: &[u8] = b"PRD-BRIDGE-HELPER-SERVER-V1";

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum AuthChannel {
    FlutterHost,
    PrivilegedHost,
    PrivilegedHelper,
}

pub struct IpcToken(Zeroizing<[u8; 32]>);

impl IpcToken {
    #[must_use]
    pub fn new(bytes: [u8; 32]) -> Self {
        Self(Zeroizing::new(bytes))
    }

    pub(crate) fn as_bytes(&self) -> &[u8; 32] {
        &self.0
    }
}

impl fmt::Debug for IpcToken {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str("IpcToken([REDACTED])")
    }
}

#[must_use]
pub fn client_proof(
    token: &IpcToken,
    instance_id: &[u8; 16],
    server_nonce: &[u8; 32],
    client_nonce: &[u8; 32],
) -> [u8; 32] {
    channel_client_proof(
        token,
        AuthChannel::FlutterHost,
        instance_id,
        server_nonce,
        client_nonce,
    )
}

#[must_use]
pub fn server_proof(
    token: &IpcToken,
    instance_id: &[u8; 16],
    server_nonce: &[u8; 32],
    client_nonce: &[u8; 32],
) -> [u8; 32] {
    channel_server_proof(
        token,
        AuthChannel::FlutterHost,
        instance_id,
        server_nonce,
        client_nonce,
    )
}

#[must_use]
pub fn channel_client_proof(
    token: &IpcToken,
    channel: AuthChannel,
    instance_id: &[u8; 16],
    server_nonce: &[u8; 32],
    client_nonce: &[u8; 32],
) -> [u8; 32] {
    proof(
        token,
        client_domain(channel),
        instance_id,
        server_nonce,
        client_nonce,
    )
}

#[must_use]
pub fn channel_server_proof(
    token: &IpcToken,
    channel: AuthChannel,
    instance_id: &[u8; 16],
    server_nonce: &[u8; 32],
    client_nonce: &[u8; 32],
) -> [u8; 32] {
    proof(
        token,
        server_domain(channel),
        instance_id,
        server_nonce,
        client_nonce,
    )
}

#[must_use]
pub fn verify_channel_client_proof(
    token: &IpcToken,
    channel: AuthChannel,
    instance_id: &[u8; 16],
    server_nonce: &[u8; 32],
    client_nonce: &[u8; 32],
    candidate: &[u8],
) -> bool {
    proof_mac(
        token,
        client_domain(channel),
        instance_id,
        server_nonce,
        client_nonce,
    )
    .verify_slice(candidate)
    .is_ok()
}

#[must_use]
pub fn verify_channel_server_proof(
    token: &IpcToken,
    channel: AuthChannel,
    instance_id: &[u8; 16],
    server_nonce: &[u8; 32],
    client_nonce: &[u8; 32],
    candidate: &[u8],
) -> bool {
    proof_mac(
        token,
        server_domain(channel),
        instance_id,
        server_nonce,
        client_nonce,
    )
    .verify_slice(candidate)
    .is_ok()
}

pub(crate) fn verify_client_proof(
    token: &IpcToken,
    instance_id: &[u8; 16],
    server_nonce: &[u8; 32],
    client_nonce: &[u8; 32],
    candidate: &[u8],
) -> bool {
    verify_channel_client_proof(
        token,
        AuthChannel::FlutterHost,
        instance_id,
        server_nonce,
        client_nonce,
        candidate,
    )
}

const fn client_domain(channel: AuthChannel) -> &'static [u8] {
    match channel {
        AuthChannel::FlutterHost => CLIENT_PROOF_DOMAIN,
        AuthChannel::PrivilegedHost => PRIVILEGED_HOST_CLIENT_DOMAIN,
        AuthChannel::PrivilegedHelper => PRIVILEGED_HELPER_CLIENT_DOMAIN,
    }
}

const fn server_domain(channel: AuthChannel) -> &'static [u8] {
    match channel {
        AuthChannel::FlutterHost => SERVER_PROOF_DOMAIN,
        AuthChannel::PrivilegedHost => PRIVILEGED_HOST_SERVER_DOMAIN,
        AuthChannel::PrivilegedHelper => PRIVILEGED_HELPER_SERVER_DOMAIN,
    }
}

fn proof(
    token: &IpcToken,
    domain: &[u8],
    instance_id: &[u8; 16],
    server_nonce: &[u8; 32],
    client_nonce: &[u8; 32],
) -> [u8; 32] {
    let tag = proof_mac(token, domain, instance_id, server_nonce, client_nonce).finalize();
    let mut proof = [0_u8; 32];
    proof.copy_from_slice(tag.as_bytes());
    proof
}

fn proof_mac(
    token: &IpcToken,
    domain: &[u8],
    instance_id: &[u8; 16],
    server_nonce: &[u8; 32],
    client_nonce: &[u8; 32],
) -> Hmac<Sha256> {
    let mut mac =
        Hmac::<Sha256>::new_from_slice(token.as_bytes()).expect("HMAC accepts a key of any length");
    mac.update(domain);
    mac.update(instance_id);
    mac.update(server_nonce);
    mac.update(client_nonce);
    mac
}
