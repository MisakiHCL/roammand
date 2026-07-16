// SPDX-License-Identifier: MPL-2.0

#![allow(unsafe_code)]

use std::{ffi::OsStr, io, os::windows::ffi::OsStrExt, path::Path, ptr, slice};

use windows_sys::{
    Win32::{
        Foundation::{CloseHandle, ERROR_SUCCESS, HANDLE, LocalFree},
        Security::{
            ACL,
            Authorization::{
                ConvertSidToStringSidW, ConvertStringSecurityDescriptorToSecurityDescriptorW,
                SDDL_REVISION_1, SE_FILE_OBJECT, SetNamedSecurityInfoW,
            },
            DACL_SECURITY_INFORMATION, GetSecurityDescriptorDacl, GetTokenInformation,
            PROTECTED_DACL_SECURITY_INFORMATION, PSECURITY_DESCRIPTOR, SECURITY_ATTRIBUTES,
            TOKEN_QUERY, TOKEN_USER, TokenUser,
        },
        System::{
            Pipes::GetNamedPipeClientProcessId,
            Threading::{
                GetCurrentProcess, OpenProcess, OpenProcessToken, PROCESS_QUERY_LIMITED_INFORMATION,
            },
        },
    },
    core::PWSTR,
};

pub(crate) fn restrict_path_to_current_user_and_system(path: &Path) -> io::Result<()> {
    let sddl = current_user_dacl_sddl()?;
    let wide_sddl = wide_null(OsStr::new(&sddl));
    let wide_path = wide_null(path.as_os_str());
    let mut descriptor: PSECURITY_DESCRIPTOR = ptr::null_mut();

    // SAFETY: `wide_sddl` is NUL-terminated and lives through the call. The
    // output pointer is initialized to null and is released with `LocalFree`.
    if unsafe {
        ConvertStringSecurityDescriptorToSecurityDescriptorW(
            wide_sddl.as_ptr(),
            SDDL_REVISION_1,
            &raw mut descriptor,
            ptr::null_mut(),
        )
    } == 0
    {
        return Err(io::Error::last_os_error());
    }
    let descriptor_guard = LocalAllocation(descriptor);

    let mut dacl_present = 0;
    let mut dacl_defaulted = 0;
    let mut dacl: *mut ACL = ptr::null_mut();
    // SAFETY: the descriptor was produced by Windows and remains owned by the
    // guard. All output pointers refer to initialized local variables.
    if unsafe {
        GetSecurityDescriptorDacl(
            descriptor_guard.0,
            &raw mut dacl_present,
            &raw mut dacl,
            &raw mut dacl_defaulted,
        )
    } == 0
        || dacl_present == 0
        || dacl.is_null()
    {
        return Err(io::Error::last_os_error());
    }

    // SAFETY: `wide_path` is NUL-terminated, and `dacl` remains valid while
    // `descriptor_guard` is alive. Owner/group/SACL are intentionally null.
    let status = unsafe {
        SetNamedSecurityInfoW(
            wide_path.as_ptr(),
            SE_FILE_OBJECT,
            DACL_SECURITY_INFORMATION | PROTECTED_DACL_SECURITY_INFORMATION,
            ptr::null_mut(),
            ptr::null_mut(),
            dacl,
            ptr::null(),
        )
    };
    if status != ERROR_SUCCESS {
        return Err(io::Error::from_raw_os_error(
            i32::try_from(status).unwrap_or(i32::MAX),
        ));
    }
    Ok(())
}

pub(crate) fn current_user_sid_string() -> io::Result<String> {
    let mut token: HANDLE = ptr::null_mut();
    // SAFETY: `token` is a valid output pointer. The pseudo-process handle is
    // borrowed and the returned token is closed by `HandleGuard`.
    if unsafe { OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &raw mut token) } == 0 {
        return Err(io::Error::last_os_error());
    }
    let token_guard = HandleGuard(token);
    token_sid_string(token_guard.0)
}

pub(crate) fn named_pipe_peer_matches_current_user(pipe: HANDLE) -> io::Result<bool> {
    let expected_sid = current_user_sid_string()?;
    let mut client_process_id = 0_u32;
    // SAFETY: `pipe` is an open connected local named-pipe server handle and
    // the process identifier output points to initialized writable storage.
    if unsafe { GetNamedPipeClientProcessId(pipe, &raw mut client_process_id) } == 0 {
        return Err(io::Error::last_os_error());
    }
    // SAFETY: the process ID came from the connected pipe. The returned handle
    // is owned by `HandleGuard` and requests only token-query access.
    let process = unsafe { OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, 0, client_process_id) };
    if process.is_null() {
        return Err(io::Error::last_os_error());
    }
    let process_guard = HandleGuard(process);
    let mut token: HANDLE = ptr::null_mut();
    // SAFETY: the connected client process handle remains open, `token` is a
    // valid output pointer, and the returned token is closed by its guard.
    if unsafe { OpenProcessToken(process_guard.0, TOKEN_QUERY, &raw mut token) } == 0 {
        return Err(io::Error::last_os_error());
    }
    let token_guard = HandleGuard(token);
    let actual_sid = token_sid_string(token_guard.0)?;
    Ok(same_windows_user_sid_for_testing(
        &expected_sid,
        &actual_sid,
    ))
}

pub(crate) struct CurrentUserSecurityAttributes {
    attributes: SECURITY_ATTRIBUTES,
    _descriptor: LocalAllocation,
}

impl CurrentUserSecurityAttributes {
    pub(crate) fn new() -> io::Result<Self> {
        let sddl = current_user_dacl_sddl()?;
        let descriptor = descriptor_from_sddl(&sddl)?;
        let attributes = SECURITY_ATTRIBUTES {
            nLength: u32::try_from(size_of::<SECURITY_ATTRIBUTES>())
                .map_err(|_| io::Error::other("security attributes size overflow"))?,
            lpSecurityDescriptor: descriptor.0,
            bInheritHandle: 0,
        };
        Ok(Self {
            attributes,
            _descriptor: descriptor,
        })
    }

    pub(crate) fn as_mut_ptr(&mut self) -> *mut core::ffi::c_void {
        (&raw mut self.attributes).cast()
    }
}

#[doc(hidden)]
pub fn windows_current_user_dacl_sddl_for_testing() -> io::Result<String> {
    current_user_dacl_sddl()
}

#[doc(hidden)]
#[must_use]
pub fn same_windows_user_sid_for_testing(expected: &str, actual: &str) -> bool {
    expected == actual
}

fn current_user_dacl_sddl() -> io::Result<String> {
    Ok(format!(
        "D:P(A;;FA;;;SY)(A;;FA;;;{})",
        current_user_sid_string()?
    ))
}

fn descriptor_from_sddl(sddl: &str) -> io::Result<LocalAllocation> {
    let wide_sddl = wide_null(OsStr::new(sddl));
    let mut descriptor: PSECURITY_DESCRIPTOR = ptr::null_mut();
    // SAFETY: `wide_sddl` is NUL-terminated and lives through the call. The
    // returned descriptor is owned by the local-allocation guard.
    if unsafe {
        ConvertStringSecurityDescriptorToSecurityDescriptorW(
            wide_sddl.as_ptr(),
            SDDL_REVISION_1,
            &raw mut descriptor,
            ptr::null_mut(),
        )
    } == 0
    {
        return Err(io::Error::last_os_error());
    }
    Ok(LocalAllocation(descriptor))
}

fn token_sid_string(token: HANDLE) -> io::Result<String> {
    let mut required_bytes = 0_u32;
    // SAFETY: a null buffer with zero length is the documented size query.
    unsafe {
        GetTokenInformation(
            token,
            TokenUser,
            ptr::null_mut(),
            0,
            &raw mut required_bytes,
        );
    }
    if required_bytes == 0 {
        return Err(io::Error::last_os_error());
    }

    let word_bytes = size_of::<usize>();
    let word_count = usize::try_from(required_bytes)
        .map_err(|_| io::Error::other("token information is too large"))?
        .div_ceil(word_bytes);
    let mut storage = vec![0_usize; word_count];
    // SAFETY: `storage` is aligned for `TOKEN_USER` and has at least
    // `required_bytes` writable bytes. Windows initializes the structure.
    if unsafe {
        GetTokenInformation(
            token,
            TokenUser,
            storage.as_mut_ptr().cast(),
            required_bytes,
            &raw mut required_bytes,
        )
    } == 0
    {
        return Err(io::Error::last_os_error());
    }
    // SAFETY: the successful call initialized a `TOKEN_USER` at the start of
    // the suitably aligned storage, and its SID is valid for this scope.
    let token_user = unsafe { &*storage.as_ptr().cast::<TOKEN_USER>() };
    let mut sid_text: PWSTR = ptr::null_mut();
    // SAFETY: the token SID is valid until `storage` is dropped. Windows
    // allocates the returned NUL-terminated string for `LocalFree`.
    if unsafe { ConvertSidToStringSidW(token_user.User.Sid, &raw mut sid_text) } == 0 {
        return Err(io::Error::last_os_error());
    }
    let _sid_guard = LocalAllocation(sid_text.cast());
    let mut length = 0_usize;
    // SAFETY: `sid_text` points to a Windows-allocated NUL-terminated UTF-16
    // string. The loop reads only through its terminator.
    while unsafe { *sid_text.add(length) } != 0 {
        length += 1;
    }
    // SAFETY: the preceding loop established exactly `length` initialized
    // UTF-16 code units before the terminator.
    let text = unsafe { slice::from_raw_parts(sid_text, length) };
    String::from_utf16(text).map_err(|_| io::Error::other("current SID is not valid UTF-16"))
}

fn wide_null(value: &OsStr) -> Vec<u16> {
    value.encode_wide().chain([0]).collect()
}

struct HandleGuard(HANDLE);

impl Drop for HandleGuard {
    fn drop(&mut self) {
        // SAFETY: the handle was returned by `OpenProcessToken` and is owned by
        // this guard exactly once.
        unsafe {
            CloseHandle(self.0);
        }
    }
}

struct LocalAllocation(*mut core::ffi::c_void);

impl Drop for LocalAllocation {
    fn drop(&mut self) {
        // SAFETY: the pointer was allocated by a Win32 API documented to use
        // `LocalAlloc`, and the guard owns it exactly once.
        unsafe {
            LocalFree(self.0);
        }
    }
}
