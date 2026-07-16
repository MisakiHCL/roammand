// SPDX-License-Identifier: MPL-2.0

#![allow(unsafe_code)]

use std::{ffi::OsStr, os::windows::ffi::OsStrExt, path::Path, ptr};

use windows_sys::Win32::{
    Foundation::{CloseHandle, FreeLibrary, HANDLE, HMODULE, WAIT_OBJECT_0},
    Security::{
        DuplicateTokenEx, SecurityImpersonation, SetTokenInformation, TOKEN_ALL_ACCESS,
        TOKEN_ASSIGN_PRIMARY, TOKEN_DUPLICATE, TOKEN_QUERY, TokenPrimary, TokenSessionId,
    },
    System::{
        JobObjects::{
            AssignProcessToJobObject, CreateJobObjectW, JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE,
            JOBOBJECT_EXTENDED_LIMIT_INFORMATION, JobObjectExtendedLimitInformation,
            SetInformationJobObject,
        },
        LibraryLoader::{GetProcAddress, LoadLibraryW},
        RemoteDesktop::WTSGetActiveConsoleSessionId,
        StationsAndDesktops::{
            CloseDesktop, DESKTOP_READOBJECTS, GetUserObjectInformationW, OpenInputDesktop,
            UOI_NAME,
        },
        Threading::{
            CreateProcessAsUserW, CreateProcessW, GetCurrentProcess, OpenProcessToken,
            PROCESS_INFORMATION, STARTUPINFOW, TerminateProcess, WaitForSingleObject,
        },
    },
};

use thiserror::Error;

use crate::windows::WindowsDesktop;

const STOP_TIMEOUT_MS: u32 = 5_000;
const HELPER_EXIT_CODE: u32 = 1;
const MAX_DESKTOP_NAME_BYTES: usize = 512;

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub enum WindowsProcessError {
    #[error("Windows Helper process operation failed")]
    Failed,
}

pub struct WindowsHelperProcess {
    process: HANDLE,
    job: HANDLE,
}

impl WindowsHelperProcess {
    /// Launches the exact installed Helper into one Windows session/desktop and
    /// binds it to a kill-on-close job.
    ///
    /// # Errors
    ///
    /// Rejects invalid path/session/desktop/generation values and any token,
    /// process, or job-object failure.
    pub fn launch(
        executable: &Path,
        session_id: u32,
        desktop: WindowsDesktop,
        generation: u64,
    ) -> Result<Self, WindowsProcessError> {
        if !executable.is_absolute() || session_id == 0 || generation == 0 {
            return Err(WindowsProcessError::Failed);
        }
        let desktop_name = desktop.name().ok_or(WindowsProcessError::Failed)?;
        let desktop_argument = match desktop {
            WindowsDesktop::Default => "normal",
            WindowsDesktop::Winlogon => "locked",
            WindowsDesktop::Unknown => return Err(WindowsProcessError::Failed),
        };
        let executable_text = executable.to_str().ok_or(WindowsProcessError::Failed)?;
        if executable_text.contains(['\0', '"', '\r', '\n']) {
            return Err(WindowsProcessError::Failed);
        }
        let primary_token = session_primary_token(session_id)?;

        let application = wide_null(executable.as_os_str());
        let mut command = wide_null(OsStr::new(&format!(
            "\"{executable_text}\" windows-helper {desktop_argument} {generation}"
        )));
        let mut desktop_name = wide_null(OsStr::new(desktop_name));
        let startup = STARTUPINFOW {
            cb: u32::try_from(size_of::<STARTUPINFOW>())
                .map_err(|_| WindowsProcessError::Failed)?,
            lpDesktop: desktop_name.as_mut_ptr(),
            ..Default::default()
        };
        let mut process = PROCESS_INFORMATION::default();
        // SAFETY: all UTF-16 buffers are NUL-terminated and live through the
        // call; process/thread outputs point to initialized storage.
        if unsafe {
            CreateProcessAsUserW(
                primary_token.0,
                application.as_ptr(),
                command.as_mut_ptr(),
                ptr::null(),
                ptr::null(),
                0,
                0,
                ptr::null(),
                ptr::null(),
                &raw const startup,
                &raw mut process,
            )
        } == 0
        {
            return Err(WindowsProcessError::Failed);
        }
        // SAFETY: CreateProcessAsUserW returned both uniquely owned handles.
        unsafe {
            CloseHandle(process.hThread);
        }
        let process_handle = HandleGuard(process.hProcess);
        // SAFETY: null attributes/name create one unnamed private job.
        let job = unsafe { CreateJobObjectW(ptr::null(), ptr::null()) };
        if job.is_null() {
            return Err(WindowsProcessError::Failed);
        }
        let job = HandleGuard(job);
        let mut limits = JOBOBJECT_EXTENDED_LIMIT_INFORMATION::default();
        limits.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
        // SAFETY: the job is open and the information structure/payload length are exact.
        if unsafe {
            SetInformationJobObject(
                job.0,
                JobObjectExtendedLimitInformation,
                (&raw const limits).cast(),
                u32::try_from(size_of::<JOBOBJECT_EXTENDED_LIMIT_INFORMATION>())
                    .map_err(|_| WindowsProcessError::Failed)?,
            )
        } == 0
            // SAFETY: both handles are open and owned for this launch.
            || unsafe { AssignProcessToJobObject(job.0, process_handle.0) } == 0
        {
            return Err(WindowsProcessError::Failed);
        }
        Ok(Self {
            process: process_handle.release(),
            job: job.release(),
        })
    }

    pub fn stop(mut self) {
        self.terminate();
    }

    fn terminate(&mut self) {
        if !self.process.is_null() {
            // SAFETY: the process handle is owned. Termination is the
            // fail-closed fallback and waiting is bounded.
            unsafe {
                TerminateProcess(self.process, HELPER_EXIT_CODE);
                let _ = WaitForSingleObject(self.process, STOP_TIMEOUT_MS) == WAIT_OBJECT_0;
            }
        }
        self.close_handles();
    }

    fn close_handles(&mut self) {
        // Closing the job first guarantees any still-running Helper is killed.
        if !self.job.is_null() {
            // SAFETY: the job handle is uniquely owned.
            unsafe { CloseHandle(self.job) };
            self.job = ptr::null_mut();
        }
        if !self.process.is_null() {
            // SAFETY: the process handle is uniquely owned.
            unsafe { CloseHandle(self.process) };
            self.process = ptr::null_mut();
        }
    }
}

impl Drop for WindowsHelperProcess {
    fn drop(&mut self) {
        self.terminate();
    }
}

fn session_primary_token(session_id: u32) -> Result<HandleGuard, WindowsProcessError> {
    let mut process_token: HANDLE = ptr::null_mut();
    // SAFETY: the process pseudo-handle is borrowed and the token output is valid.
    if unsafe {
        OpenProcessToken(
            GetCurrentProcess(),
            TOKEN_ASSIGN_PRIMARY | TOKEN_DUPLICATE | TOKEN_QUERY,
            &raw mut process_token,
        )
    } == 0
    {
        return Err(WindowsProcessError::Failed);
    }
    let process_token = HandleGuard(process_token);
    let mut primary_token: HANDLE = ptr::null_mut();
    // SAFETY: the source token is open, output pointer is valid, and no
    // security attributes are inherited.
    if unsafe {
        DuplicateTokenEx(
            process_token.0,
            TOKEN_ALL_ACCESS,
            ptr::null(),
            SecurityImpersonation,
            TokenPrimary,
            &raw mut primary_token,
        )
    } == 0
    {
        return Err(WindowsProcessError::Failed);
    }
    let primary_token = HandleGuard(primary_token);
    // SAFETY: the duplicated primary token is owned and the session value
    // pointer/length are exact.
    if unsafe {
        SetTokenInformation(
            primary_token.0,
            TokenSessionId,
            (&raw const session_id).cast(),
            u32::try_from(size_of::<u32>()).map_err(|_| WindowsProcessError::Failed)?,
        )
    } == 0
    {
        return Err(WindowsProcessError::Failed);
    }
    Ok(primary_token)
}

/// Returns the active physical console session.
///
/// # Errors
///
/// Rejects session zero and the Windows no-console sentinel.
pub fn active_console_session_id() -> Result<u32, WindowsProcessError> {
    // SAFETY: this function takes no pointers and returns a value.
    let session_id = unsafe { WTSGetActiveConsoleSessionId() };
    if matches!(session_id, 0 | u32::MAX) {
        Err(WindowsProcessError::Failed)
    } else {
        Ok(session_id)
    }
}

/// Returns the active input desktop visible to this in-session `LocalSystem` Helper.
///
/// # Errors
///
/// Fails closed if the desktop cannot be opened, named, or classified.
pub fn current_input_desktop() -> Result<WindowsDesktop, WindowsProcessError> {
    // SAFETY: this requests a non-inherited read-only handle to the current input desktop.
    let desktop = unsafe { OpenInputDesktop(0, 0, DESKTOP_READOBJECTS) };
    if desktop.is_null() {
        return Err(WindowsProcessError::Failed);
    }
    let desktop = DesktopGuard(desktop);
    let mut needed = 0_u32;
    // SAFETY: a zero-length first query returns the required byte count.
    unsafe {
        GetUserObjectInformationW(desktop.0, UOI_NAME, ptr::null_mut(), 0, &raw mut needed);
    }
    let needed = usize::try_from(needed).map_err(|_| WindowsProcessError::Failed)?;
    if needed < size_of::<u16>() || needed > MAX_DESKTOP_NAME_BYTES {
        return Err(WindowsProcessError::Failed);
    }
    let mut name = vec![0_u16; needed.div_ceil(size_of::<u16>())];
    let mut actual = 0_u32;
    // SAFETY: the desktop handle is open and the byte-sized output buffer is exact.
    if unsafe {
        GetUserObjectInformationW(
            desktop.0,
            UOI_NAME,
            name.as_mut_ptr().cast(),
            u32::try_from(needed).map_err(|_| WindowsProcessError::Failed)?,
            &raw mut actual,
        )
    } == 0
        || usize::try_from(actual).map_err(|_| WindowsProcessError::Failed)? > needed
    {
        return Err(WindowsProcessError::Failed);
    }
    if name.last() == Some(&0) {
        name.pop();
    }
    classify_desktop_name(&String::from_utf16(&name).map_err(|_| WindowsProcessError::Failed)?)
}

/// Starts the next-generation Helper on the newly observed input desktop.
/// The service-owned kill-on-close job automatically contains the child.
///
/// # Errors
///
/// Rejects invalid paths, generations, desktops, or process creation failure.
pub fn spawn_helper_replacement(
    executable: &Path,
    desktop: WindowsDesktop,
    generation: u64,
) -> Result<(), WindowsProcessError> {
    if !executable.is_absolute() || generation == 0 {
        return Err(WindowsProcessError::Failed);
    }
    let desktop_name = desktop.name().ok_or(WindowsProcessError::Failed)?;
    let desktop_argument = match desktop {
        WindowsDesktop::Default => "normal",
        WindowsDesktop::Winlogon => "secure",
        WindowsDesktop::Unknown => return Err(WindowsProcessError::Failed),
    };
    let executable_text = executable.to_str().ok_or(WindowsProcessError::Failed)?;
    if executable_text.contains(['\0', '"', '\r', '\n']) {
        return Err(WindowsProcessError::Failed);
    }
    let application = wide_null(executable.as_os_str());
    let mut command = wide_null(OsStr::new(&format!(
        "\"{executable_text}\" windows-helper {desktop_argument} {generation}"
    )));
    let mut desktop_name = wide_null(OsStr::new(desktop_name));
    let startup = STARTUPINFOW {
        cb: u32::try_from(size_of::<STARTUPINFOW>()).map_err(|_| WindowsProcessError::Failed)?,
        lpDesktop: desktop_name.as_mut_ptr(),
        ..Default::default()
    };
    let mut process = PROCESS_INFORMATION::default();
    // SAFETY: all UTF-16 buffers and process outputs are valid for the call;
    // the current LocalSystem primary token and session are intentionally inherited.
    if unsafe {
        CreateProcessW(
            application.as_ptr(),
            command.as_mut_ptr(),
            ptr::null(),
            ptr::null(),
            0,
            0,
            ptr::null(),
            ptr::null(),
            &raw const startup,
            &raw mut process,
        )
    } == 0
    {
        return Err(WindowsProcessError::Failed);
    }
    // SAFETY: both successful process creation handles are uniquely owned here.
    unsafe {
        CloseHandle(process.hThread);
        CloseHandle(process.hProcess);
    }
    Ok(())
}

/// Invokes the Windows `SendSAS` implementation from the protected Helper.
///
/// # Errors
///
/// Fails when the operating-system SAS library or entry point is unavailable.
pub fn send_secure_attention() -> Result<(), WindowsProcessError> {
    let library_name = wide_null(OsStr::new("sas.dll"));
    // SAFETY: the library name is NUL-terminated and lives through the call.
    let library = unsafe { LoadLibraryW(library_name.as_ptr()) };
    if library.is_null() {
        return Err(WindowsProcessError::Failed);
    }
    let library = LibraryGuard(library);
    // SAFETY: the module handle is open and the symbol name is NUL-terminated.
    let procedure = unsafe { GetProcAddress(library.0, c"SimulateSAS".as_ptr().cast()) }
        .ok_or(WindowsProcessError::Failed)?;
    // SAFETY: sas.dll documents SimulateSAS with this exact system ABI and one BOOL argument.
    let simulate: unsafe extern "system" fn(i32) = unsafe { std::mem::transmute(procedure) };
    // SAFETY: false requests the LocalSystem service-style SAS path.
    unsafe { simulate(0) };
    Ok(())
}

fn wide_null(value: &OsStr) -> Vec<u16> {
    value.encode_wide().chain([0]).collect()
}

struct HandleGuard(HANDLE);

struct LibraryGuard(HMODULE);

struct DesktopGuard(*mut core::ffi::c_void);

impl Drop for DesktopGuard {
    fn drop(&mut self) {
        // SAFETY: the desktop handle is uniquely owned by this guard.
        unsafe { CloseDesktop(self.0) };
    }
}

fn classify_desktop_name(value: &str) -> Result<WindowsDesktop, WindowsProcessError> {
    if value.eq_ignore_ascii_case("default") {
        Ok(WindowsDesktop::Default)
    } else if value.eq_ignore_ascii_case("winlogon") {
        Ok(WindowsDesktop::Winlogon)
    } else {
        Err(WindowsProcessError::Failed)
    }
}

impl Drop for LibraryGuard {
    fn drop(&mut self) {
        // SAFETY: the module handle is uniquely owned.
        unsafe { FreeLibrary(self.0) };
    }
}

impl HandleGuard {
    fn release(mut self) -> HANDLE {
        let handle = self.0;
        self.0 = ptr::null_mut();
        handle
    }
}

impl Drop for HandleGuard {
    fn drop(&mut self) {
        if !self.0.is_null() {
            // SAFETY: the handle is uniquely owned.
            unsafe { CloseHandle(self.0) };
        }
    }
}
