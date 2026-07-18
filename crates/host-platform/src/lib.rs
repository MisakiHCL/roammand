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

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct MacOsDesktopPermissionStatus {
    pub screen_recording: bool,
    pub accessibility: bool,
}

impl MacOsDesktopPermissionStatus {
    #[must_use]
    pub const fn ready(self) -> bool {
        self.screen_recording && self.accessibility
    }

    #[must_use]
    pub const fn exit_code(self) -> u8 {
        ((!self.screen_recording) as u8) | (((!self.accessibility) as u8) << 1)
    }
}

#[cfg(all(target_os = "macos", feature = "native-webrtc"))]
#[must_use]
pub fn macos_desktop_permission_status(
    request_screen_recording: bool,
    request_accessibility: bool,
) -> MacOsDesktopPermissionStatus {
    MacOsDesktopPermissionStatus {
        screen_recording: roammand_host_webrtc::native::macos_screen_capture_access(
            request_screen_recording,
        ),
        accessibility: MacOsInputBackend::new(request_accessibility).is_ok(),
    }
}

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

#[cfg(test)]
mod permission_tests {
    use super::MacOsDesktopPermissionStatus;

    #[test]
    fn encodes_only_missing_permissions_in_the_exit_status() {
        assert_eq!(
            MacOsDesktopPermissionStatus {
                screen_recording: true,
                accessibility: true,
            }
            .exit_code(),
            0
        );
        assert_eq!(
            MacOsDesktopPermissionStatus {
                screen_recording: false,
                accessibility: true,
            }
            .exit_code(),
            1
        );
        assert_eq!(
            MacOsDesktopPermissionStatus {
                screen_recording: true,
                accessibility: false,
            }
            .exit_code(),
            2
        );
        assert_eq!(
            MacOsDesktopPermissionStatus {
                screen_recording: false,
                accessibility: false,
            }
            .exit_code(),
            3
        );
    }
}
