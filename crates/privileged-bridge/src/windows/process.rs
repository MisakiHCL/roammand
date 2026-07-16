// SPDX-License-Identifier: MPL-2.0

use thiserror::Error;

use super::WindowsDesktop;

const MAX_APPLICATION_BYTES: usize = 512;
const SESSION_HELPER_ARGUMENT: &str = "--session-helper";
const SESSION_ID_ARGUMENT: &str = "--session-id";
const BOOTSTRAP_HANDLE_ARGUMENT: &str = "--bootstrap-handle";

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct HelperLaunchSpec {
    application_name: String,
    command_line: String,
    desktop_name: &'static str,
    inherited_handles: [usize; 1],
    kill_on_job_close: bool,
}

impl HelperLaunchSpec {
    /// Creates an exact `CreateProcessAsUser` input without shell lookup.
    ///
    /// # Errors
    ///
    /// Rejects non-installed path shapes, injection characters, session zero,
    /// unknown desktops, and missing one-time bootstrap handles.
    pub fn new(
        application_name: &str,
        session_id: u32,
        desktop: WindowsDesktop,
        bootstrap_handle: usize,
    ) -> Result<Self, HelperLaunchError> {
        validate_application(application_name)?;
        if session_id == 0 || bootstrap_handle == 0 {
            return Err(HelperLaunchError::InvalidLaunch);
        }
        let desktop_name = desktop.name().ok_or(HelperLaunchError::InvalidLaunch)?;
        let command_line = format!(
            "\"{application_name}\" {SESSION_HELPER_ARGUMENT} {SESSION_ID_ARGUMENT} {session_id} {BOOTSTRAP_HANDLE_ARGUMENT} {bootstrap_handle}"
        );
        Ok(Self {
            application_name: application_name.to_owned(),
            command_line,
            desktop_name,
            inherited_handles: [bootstrap_handle],
            kill_on_job_close: true,
        })
    }

    #[must_use]
    pub fn application_name(&self) -> &str {
        &self.application_name
    }

    #[must_use]
    pub fn command_line(&self) -> &str {
        &self.command_line
    }

    #[must_use]
    pub const fn desktop_name(&self) -> &'static str {
        self.desktop_name
    }

    #[must_use]
    pub const fn inherited_handles(&self) -> &[usize] {
        &self.inherited_handles
    }

    #[must_use]
    pub const fn kill_on_job_close(&self) -> bool {
        self.kill_on_job_close
    }
}

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub enum HelperLaunchError {
    #[error("Windows session Helper launch rejected")]
    InvalidLaunch,
}

fn validate_application(value: &str) -> Result<(), HelperLaunchError> {
    let bytes = value.as_bytes();
    if value.is_empty()
        || value.len() > MAX_APPLICATION_BYTES
        || bytes.len() < 4
        || !bytes[0].is_ascii_alphabetic()
        || bytes[1] != b':'
        || !matches!(bytes[2], b'\\' | b'/')
        || value.starts_with(r"\\")
        || !value.to_ascii_lowercase().ends_with(".exe")
        || value
            .chars()
            .any(|character| matches!(character, '\0' | '\r' | '\n' | '"'))
        || value
            .split(['\\', '/'])
            .any(|component| matches!(component, "." | ".."))
    {
        return Err(HelperLaunchError::InvalidLaunch);
    }
    Ok(())
}
