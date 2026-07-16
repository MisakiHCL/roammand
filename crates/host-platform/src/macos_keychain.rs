// SPDX-License-Identifier: MPL-2.0

use security_framework::passwords::{
    PasswordOptions, delete_generic_password, generic_password, set_generic_password,
};
use security_framework_sys::base::errSecItemNotFound;
use zeroize::Zeroizing;

use crate::{PROTECTED_SECRET_BYTES, ProtectedSecret, ProtectedSecretStore, SecretStoreError};

const KEYCHAIN_SERVICE: &str = "dev.roammand.host-agent";
const HOST_IDENTITY_ACCOUNT: &str = "host-ed25519-identity-v1";

pub struct MacOsKeychainSecretStore {
    account: String,
}

impl MacOsKeychainSecretStore {
    #[must_use]
    pub fn new(account: String) -> Self {
        Self { account }
    }

    #[must_use]
    pub fn for_host_identity() -> Self {
        Self::new(HOST_IDENTITY_ACCOUNT.to_owned())
    }
}

impl ProtectedSecretStore for MacOsKeychainSecretStore {
    fn load(&self) -> Result<Option<ProtectedSecret>, SecretStoreError> {
        let options = PasswordOptions::new_generic_password(KEYCHAIN_SERVICE, &self.account);
        match generic_password(options) {
            Ok(secret) if secret.len() == PROTECTED_SECRET_BYTES => {
                Ok(Some(Zeroizing::new(secret)))
            }
            Ok(mut secret) => {
                zeroize::Zeroize::zeroize(&mut secret);
                Err(SecretStoreError::Corrupt)
            }
            Err(error) if error.code() == errSecItemNotFound => Ok(None),
            Err(_) => Err(SecretStoreError::Unavailable),
        }
    }

    fn store(&self, secret: &[u8]) -> Result<(), SecretStoreError> {
        if secret.len() != PROTECTED_SECRET_BYTES {
            return Err(SecretStoreError::InvalidSecretLength);
        }
        set_generic_password(KEYCHAIN_SERVICE, &self.account, secret)
            .map_err(|_| SecretStoreError::Unavailable)
    }

    fn delete(&self) -> Result<(), SecretStoreError> {
        match delete_generic_password(KEYCHAIN_SERVICE, &self.account) {
            Ok(()) => Ok(()),
            Err(error) if error.code() == errSecItemNotFound => Ok(()),
            Err(_) => Err(SecretStoreError::Unavailable),
        }
    }
}
