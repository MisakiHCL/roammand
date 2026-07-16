// SPDX-License-Identifier: Apache-2.0

pub mod canonical_transcript;
pub mod identity_derivation;
pub mod pairing_crypto;
pub mod protocol_limits;
pub mod validation;

pub mod roammand {
    #[allow(clippy::all, clippy::pedantic)]
    pub mod v1 {
        include!("generated/roammand.v1.rs");
    }
}

#[cfg(test)]
mod tests {
    use super::roammand::v1::ProtocolVersion;

    #[test]
    fn generated_protocol_version_is_type_safe() {
        let version = ProtocolVersion { major: 1, minor: 0 };

        assert_eq!(version.major, 1);
        assert_eq!(version.minor, 0);
    }
}
