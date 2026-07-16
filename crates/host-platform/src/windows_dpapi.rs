// SPDX-License-Identifier: MPL-2.0

#![allow(unsafe_code)]

use std::{path::PathBuf, ptr, slice};

use windows_sys::Win32::{
    Foundation::LocalFree,
    Security::Cryptography::{
        CRYPT_INTEGER_BLOB, CRYPTPROTECT_UI_FORBIDDEN, CryptProtectData, CryptUnprotectData,
    },
};
use zeroize::{Zeroize, Zeroizing};

use crate::{
    PROTECTED_SECRET_BYTES, ProtectedSecret, ProtectedSecretStore, RestrictedFsError,
    SecretStoreError, atomic_write_private, read_private_file, remove_private_file,
};

const DPAPI_ENTROPY: &[u8] = b"roammand-host-identity-dpapi-v1";
const MAX_DPAPI_BLOB_BYTES: usize = 4_096;

pub struct WindowsDpapiSecretStore {
    path: PathBuf,
    entropy: Vec<u8>,
}

impl WindowsDpapiSecretStore {
    #[must_use]
    pub fn new(path: PathBuf) -> Self {
        Self {
            path,
            entropy: DPAPI_ENTROPY.to_vec(),
        }
    }

    #[doc(hidden)]
    #[must_use]
    pub fn with_entropy_for_testing(path: PathBuf, entropy: Vec<u8>) -> Self {
        Self { path, entropy }
    }
}

impl ProtectedSecretStore for WindowsDpapiSecretStore {
    fn load(&self) -> Result<Option<ProtectedSecret>, SecretStoreError> {
        if !self
            .path
            .try_exists()
            .map_err(|_| SecretStoreError::Unavailable)?
        {
            return Ok(None);
        }
        let ciphertext = read_private_file(&self.path, MAX_DPAPI_BLOB_BYTES).map_err(|error| {
            if matches!(error, RestrictedFsError::FileTooLarge) {
                SecretStoreError::Corrupt
            } else {
                SecretStoreError::Unavailable
            }
        })?;
        let mut plaintext = unprotect(&ciphertext, &self.entropy)?;
        if plaintext.len() != PROTECTED_SECRET_BYTES {
            plaintext.zeroize();
            return Err(SecretStoreError::Corrupt);
        }
        Ok(Some(Zeroizing::new(plaintext)))
    }

    fn store(&self, secret: &[u8]) -> Result<(), SecretStoreError> {
        if secret.len() != PROTECTED_SECRET_BYTES {
            return Err(SecretStoreError::InvalidSecretLength);
        }
        let mut ciphertext = protect(secret, &self.entropy)?;
        let result = atomic_write_private(&self.path, &ciphertext)
            .map_err(|_| SecretStoreError::Unavailable);
        ciphertext.zeroize();
        result
    }

    fn delete(&self) -> Result<(), SecretStoreError> {
        remove_private_file(&self.path).map_err(|_| SecretStoreError::Unavailable)
    }
}

fn protect(plaintext: &[u8], entropy: &[u8]) -> Result<Vec<u8>, SecretStoreError> {
    let input = blob(plaintext)?;
    let entropy = blob(entropy)?;
    let mut output = CRYPT_INTEGER_BLOB::default();
    // SAFETY: both input blobs borrow valid slices for the duration of the
    // call. Optional pointers are null, UI is forbidden, and Windows owns the
    // output allocation until it is copied and released below.
    if unsafe {
        CryptProtectData(
            &raw const input,
            ptr::null(),
            &raw const entropy,
            ptr::null(),
            ptr::null(),
            CRYPTPROTECT_UI_FORBIDDEN,
            &raw mut output,
        )
    } == 0
    {
        return Err(SecretStoreError::Unavailable);
    }
    copy_and_free(output).ok_or(SecretStoreError::Unavailable)
}

fn unprotect(ciphertext: &[u8], entropy: &[u8]) -> Result<Vec<u8>, SecretStoreError> {
    let input = blob(ciphertext).map_err(|_| SecretStoreError::Corrupt)?;
    let entropy = blob(entropy).map_err(|_| SecretStoreError::Corrupt)?;
    let mut output = CRYPT_INTEGER_BLOB::default();
    // SAFETY: both blobs borrow valid slices for the call. No description is
    // requested, UI is forbidden, and the output is released after copying.
    if unsafe {
        CryptUnprotectData(
            &raw const input,
            ptr::null_mut(),
            &raw const entropy,
            ptr::null(),
            ptr::null(),
            CRYPTPROTECT_UI_FORBIDDEN,
            &raw mut output,
        )
    } == 0
    {
        return Err(SecretStoreError::Corrupt);
    }
    copy_and_free(output).ok_or(SecretStoreError::Corrupt)
}

fn blob(bytes: &[u8]) -> Result<CRYPT_INTEGER_BLOB, SecretStoreError> {
    Ok(CRYPT_INTEGER_BLOB {
        cbData: u32::try_from(bytes.len()).map_err(|_| SecretStoreError::Corrupt)?,
        pbData: bytes.as_ptr().cast_mut(),
    })
}

fn copy_and_free(output: CRYPT_INTEGER_BLOB) -> Option<Vec<u8>> {
    if output.pbData.is_null() {
        return None;
    }
    let length = usize::try_from(output.cbData).ok()?;
    // SAFETY: successful DPAPI calls return `cbData` initialized bytes at
    // `pbData`; they are copied before the Windows allocation is freed once.
    let copied = unsafe { slice::from_raw_parts(output.pbData, length) }.to_vec();
    // SAFETY: DPAPI allocates `pbData` with `LocalAlloc`; ownership transfers to
    // the caller and is released exactly once here.
    unsafe {
        LocalFree(output.pbData.cast());
    }
    Some(copied)
}
