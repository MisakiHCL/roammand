// SPDX-License-Identifier: Apache-2.0

pub const PROTOCOL_MAJOR_VERSION: u32 = 1;
pub const MINIMUM_PROTOCOL_MINOR_VERSION: u32 = 0;

pub const PAIRING_RENDEZVOUS_LIFETIME_MS: u64 = 120_000;
pub const MAX_SIGNALING_ENVELOPE_BYTES: usize = 262_144;
pub const MAX_OPAQUE_SIGNALING_ENVELOPE_BYTES: usize = 262_144;
pub const MAX_SIGNALING_SERVICE_FRAME_BYTES: usize = 263_168;
pub const MAX_RELIABLE_INPUT_ENVELOPE_BYTES: usize = 16_384;
pub const MAX_POINTER_FAST_ENVELOPE_BYTES: usize = 256;
pub const MAX_LOCAL_IPC_FRAME_BYTES: usize = 65_536;
pub const MAX_PRIVILEGED_BRIDGE_FRAME_BYTES: usize = 262_144;
pub const MAX_HOST_AUTHORIZATION_SNAPSHOT_BYTES: usize = 1_048_576;
pub const MAX_CONTROLLER_GRANTS: usize = 256;
pub const MAX_TRUSTED_HOSTS: usize = 256;
pub const MAX_TRUSTED_HOST_SNAPSHOT_BYTES: usize = 1_048_576;
pub const MAX_PAIRING_CIPHERTEXT_BYTES: usize = 65_536;
pub const MAX_PRIVILEGED_ICE_SERVERS: usize = 8;
pub const MAX_PRIVILEGED_ICE_URLS_PER_SERVER: usize = 16;

pub const MAX_DEVICE_NAME_UTF8_BYTES: usize = 128;
pub const MAX_REQUEST_ID_UTF8_BYTES: usize = 64;
pub const MAX_MESSAGE_KEY_UTF8_BYTES: usize = 128;
pub const MAX_SIGNALING_ENDPOINT_UTF8_BYTES: usize = 2_048;
pub const MAX_SDP_UTF8_BYTES: usize = 131_072;
pub const MAX_ICE_CANDIDATE_UTF8_BYTES: usize = 4_096;
pub const MAX_SDP_MID_UTF8_BYTES: usize = 64;
pub const MAX_TEXT_INPUT_UTF8_BYTES: usize = 4_096;
pub const MAX_ERROR_DETAIL_UTF8_BYTES: usize = 256;

pub const DEVICE_ID_BYTES: usize = 32;
pub const PUBLIC_KEY_BYTES: usize = 32;
pub const RENDEZVOUS_ID_BYTES: usize = 16;
pub const SESSION_ID_BYTES: usize = 16;
pub const NONCE_OR_HASH_BYTES: usize = 32;
pub const SIGNATURE_BYTES: usize = 64;
pub const DESKTOP_PAIRING_CODE_BYTES: usize = 8;
pub const LOCAL_IPC_TOKEN_BYTES: usize = 32;
pub const AGENT_INSTANCE_ID_BYTES: usize = 16;
pub const PRIVILEGED_BRIDGE_INSTANCE_ID_BYTES: usize = 16;
pub const PRIVILEGED_BRIDGE_NONCE_BYTES: usize = 32;
pub const PRIVILEGED_BRIDGE_PROOF_BYTES: usize = 32;
pub const PRIVILEGED_LEASE_ID_BYTES: usize = 16;
pub const EXECUTABLE_SHA256_BYTES: usize = 32;
pub const PAIRING_SAS_WORD_COUNT: usize = 4;
