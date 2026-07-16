// SPDX-License-Identifier: MPL-2.0

#![deny(unsafe_code)]

use std::path::Path;

mod input;
mod local_transport;
#[cfg(target_os = "macos")]
mod macos_input;
#[cfg(target_os = "macos")]
mod macos_keychain;
mod restricted_fs;
mod runtime_paths;
mod secret_store;
#[cfg(unix)]
mod unix_transport;
#[cfg(windows)]
mod windows_dpapi;
#[cfg(windows)]
mod windows_input;
#[cfg(windows)]
mod windows_security;
#[cfg(windows)]
mod windows_transport;

pub use input::{
    NativeButton, NativeDirection, PRESSED_LEFT_BUTTON_BIT, PRESSED_MIDDLE_BUTTON_BIT,
    PRESSED_RIGHT_BUTTON_BIT, PlatformInputBackend, PlatformInputError, PlatformInputSink,
};
pub use local_transport::LocalTransportError;
#[cfg(target_os = "macos")]
pub use macos_input::{MacOsInputBackend, macos_keycode_for_usb_hid};
#[cfg(target_os = "macos")]
pub use macos_keychain::MacOsKeychainSecretStore;
pub use restricted_fs::{
    RestrictedFsError, atomic_write_private, ensure_private_directory, read_private_file,
    remove_private_file,
};
pub use runtime_paths::RuntimePaths;
pub use secret_store::{
    MemorySecretStore, PROTECTED_SECRET_BYTES, ProtectedSecret, ProtectedSecretStore,
    SecretStoreError,
};
#[cfg(unix)]
pub use unix_transport::UnixLocalListener;
#[cfg(windows)]
pub use windows_dpapi::WindowsDpapiSecretStore;
#[cfg(windows)]
pub use windows_input::{WindowsInputBackend, windows_scan_code_for_usb_hid};
#[cfg(windows)]
pub use windows_security::{
    same_windows_user_sid_for_testing, windows_current_user_dacl_sddl_for_testing,
};
#[cfg(windows)]
pub use windows_transport::WindowsLocalListener;

/// Opens the platform-protected store used by the Host identity.
///
/// # Errors
///
/// Returns [`SecretStoreError::UnsupportedPlatform`] outside macOS and Windows.
#[allow(unused_variables)]
pub fn host_identity_secret_store(
    data_dir: &Path,
) -> Result<Box<dyn ProtectedSecretStore>, SecretStoreError> {
    #[cfg(target_os = "macos")]
    return Ok(Box::new(MacOsKeychainSecretStore::for_host_identity()));

    #[cfg(windows)]
    return Ok(Box::new(WindowsDpapiSecretStore::new(
        data_dir.join("host-identity.dpapi"),
    )));

    #[cfg(not(any(target_os = "macos", windows)))]
    Err(SecretStoreError::UnsupportedPlatform)
}

/// Opens the platform input sink used for one authenticated remote session.
///
/// On macOS, `open_permission_prompt` controls whether Accessibility preflight
/// may show the system prompt. Windows ignores that value.
///
/// # Errors
///
/// Returns a stable permission, backend, display, or unsupported-platform error.
#[allow(unused_variables)]
pub fn remote_input_sink(
    open_permission_prompt: bool,
) -> Result<Box<dyn roammand_host_webrtc::RemoteInputSink>, PlatformInputError> {
    #[cfg(target_os = "macos")]
    return Ok(Box::new(PlatformInputSink::new(MacOsInputBackend::new(
        open_permission_prompt,
    )?)?));

    #[cfg(windows)]
    return Ok(Box::new(PlatformInputSink::new(
        WindowsInputBackend::new()?
    )?));

    #[cfg(not(any(target_os = "macos", windows)))]
    Err(PlatformInputError::UnsupportedPlatform)
}
