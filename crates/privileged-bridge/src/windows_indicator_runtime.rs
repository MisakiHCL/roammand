// SPDX-License-Identifier: MPL-2.0

#![allow(unsafe_code)]

use std::{
    ffi::OsStr,
    os::windows::ffi::OsStrExt,
    path::PathBuf,
    ptr,
    sync::{
        Arc,
        atomic::{AtomicBool, Ordering},
    },
    thread,
    time::Duration,
};

use windows_sys::Win32::{
    Foundation::{HWND, LPARAM, LRESULT, WPARAM},
    Globalization::GetUserDefaultLocaleName,
    Graphics::Gdi::{COLOR_WINDOW, HBRUSH},
    System::LibraryLoader::GetModuleHandleW,
    UI::WindowsAndMessaging::{
        CREATESTRUCTW, CS_HREDRAW, CS_VREDRAW, CreateWindowExW, DefWindowProcW, DestroyWindow,
        DispatchMessageW, GWLP_USERDATA, GetMessageW, GetSystemMetrics, GetWindowLongPtrW, HMENU,
        HWND_TOPMOST, KillTimer, MSG, PostQuitMessage, RegisterClassW, SM_CXSCREEN, SM_CYSCREEN,
        SW_HIDE, SW_SHOWNOACTIVATE, SWP_NOACTIVATE, SWP_NOMOVE, SWP_NOSIZE, SWP_SHOWWINDOW,
        SetTimer, SetWindowLongPtrW, SetWindowPos, SetWindowTextW, ShowWindow, TranslateMessage,
        WM_CLOSE, WM_COMMAND, WM_DESTROY, WM_NCCREATE, WM_TIMER, WNDCLASSW, WS_CAPTION, WS_CHILD,
        WS_EX_TOOLWINDOW, WS_EX_TOPMOST, WS_POPUP, WS_TABSTOP, WS_VISIBLE,
    },
};

use crate::{
    indicator_copy::{ProtectedIndicatorCopy, protected_indicator_copy},
    native_indicator::{NativeIndicatorClient, NativeIndicatorRuntime, native_indicator_channel},
    windows::WindowsDesktop,
    windows_process_runtime::{current_input_desktop, spawn_helper_replacement},
};

const WINDOW_CLASS: &str = "RoammandProtectedIndicatorV1";
const STATIC_CLASS: &str = "STATIC";
const BUTTON_CLASS: &str = "BUTTON";
const WINDOW_WIDTH: i32 = 440;
const WINDOW_HEIGHT: i32 = 168;
const HORIZONTAL_INSET: i32 = 24;
const LABEL_WIDTH: i32 = WINDOW_WIDTH - 2 * HORIZONTAL_INSET;
const STATUS_TOP: i32 = 32;
const DETAIL_TOP: i32 = 68;
const LABEL_HEIGHT: i32 = 28;
const BUTTON_WIDTH: i32 = 112;
const BUTTON_HEIGHT: i32 = 36;
const BUTTON_TOP: i32 = 108;
const BUTTON_ID: usize = 1_001;
const REFRESH_TIMER_ID: usize = 1;
const REFRESH_INTERVAL_MS: u32 = 50;
const DESKTOP_POLL_INTERVAL: Duration = Duration::from_millis(100);
// Windows defines LOCALE_NAME_MAX_LENGTH as 85 UTF-16 code units.
const LOCALE_NAME_CAPACITY: usize = 85;

struct WindowState {
    runtime: NativeIndicatorRuntime,
    copy: ProtectedIndicatorCopy,
    last_revision: u64,
    status: HWND,
    detail: HWND,
}

/// Supervises one Helper worker, its local indicator, and UAC/desktop
/// migration as one fail-closed lifetime.
///
/// # Errors
///
/// Fails when the worker, UI, desktop monitor, or replacement launch fails.
pub fn run_supervised_windows_helper<F>(
    executable: PathBuf,
    assigned_desktop: WindowsDesktop,
    generation: u64,
    worker: F,
) -> Result<(), &'static str>
where
    F: FnOnce(NativeIndicatorClient, Arc<AtomicBool>) -> Result<(), ()> + Send + 'static,
{
    let next_generation = generation
        .checked_add(1)
        .ok_or("Helper generation overflowed")?;
    let shutdown = Arc::new(AtomicBool::new(false));
    let monitor_shutdown = Arc::clone(&shutdown);
    let monitor = thread::spawn(move || {
        while !monitor_shutdown.load(Ordering::Relaxed) {
            match current_input_desktop() {
                Ok(current) if current != assigned_desktop => {
                    let result = spawn_helper_replacement(&executable, current, next_generation);
                    monitor_shutdown.store(true, Ordering::Relaxed);
                    return result;
                }
                Ok(_) => thread::sleep(DESKTOP_POLL_INTERVAL),
                Err(error) => {
                    monitor_shutdown.store(true, Ordering::Relaxed);
                    return Err(error);
                }
            }
        }
        Ok(())
    });
    let (indicator, indicator_runtime) = native_indicator_channel();
    let worker_indicator = indicator.clone();
    let worker_shutdown = Arc::clone(&shutdown);
    let worker = thread::spawn(move || {
        let result = worker(worker_indicator.clone(), worker_shutdown);
        worker_indicator.finish();
        result
    });
    let ui_result = run_windows_indicator(indicator_runtime);
    shutdown.store(true, Ordering::Relaxed);
    let worker_result = worker
        .join()
        .map_err(|_| "Helper worker failed")?
        .map_err(|()| "Helper runtime failed");
    let monitor_result = monitor
        .join()
        .map_err(|_| "Helper desktop monitor failed")?
        .map_err(|_| "Helper desktop migration failed");
    ui_result.and(worker_result).and(monitor_result)
}

/// Runs the topmost protected-session `Win32` surface on the Helper's assigned
/// desktop until its worker marks the shared indicator finished.
///
/// # Errors
///
/// Fails closed for window-class, window creation, timer, or message-loop
/// errors.
pub fn run_windows_indicator(runtime: NativeIndicatorRuntime) -> Result<(), &'static str> {
    // SAFETY: a null module name requests the current executable module.
    let instance = unsafe { GetModuleHandleW(ptr::null()) };
    if instance.is_null() {
        return Err("indicator module failed");
    }
    let class = wide_null(WINDOW_CLASS);
    let window_class = WNDCLASSW {
        style: CS_HREDRAW | CS_VREDRAW,
        lpfnWndProc: Some(window_proc),
        hInstance: instance,
        hbrBackground: (usize::try_from(COLOR_WINDOW + 1).map_err(|_| "indicator color failed")?
            as HBRUSH),
        lpszClassName: class.as_ptr(),
        ..Default::default()
    };
    // SAFETY: the class structure and UTF-16 class name live through registration.
    if unsafe { RegisterClassW(&raw const window_class) } == 0 {
        return Err("indicator class failed");
    }

    let language = windows_language_tag();
    let copy = protected_indicator_copy(&language);
    let mut state = Box::new(WindowState {
        runtime,
        copy,
        last_revision: 0,
        status: ptr::null_mut(),
        detail: ptr::null_mut(),
    });
    let title = wide_null(copy.product_name);
    let x = (screen_metric(SM_CXSCREEN)? - WINDOW_WIDTH) / 2;
    let y = (screen_metric(SM_CYSCREEN)? - WINDOW_HEIGHT) / 2;
    // SAFETY: all class/title buffers are NUL-terminated and the boxed state
    // remains at a stable address until the message loop ends.
    let window = unsafe {
        CreateWindowExW(
            WS_EX_TOPMOST | WS_EX_TOOLWINDOW,
            class.as_ptr(),
            title.as_ptr(),
            WS_POPUP | WS_CAPTION,
            x,
            y,
            WINDOW_WIDTH,
            WINDOW_HEIGHT,
            ptr::null_mut(),
            ptr::null_mut(),
            instance,
            (&raw mut *state).cast(),
        )
    };
    if window.is_null() {
        return Err("indicator window failed");
    }

    state.status = create_child(
        window,
        instance,
        STATIC_CLASS,
        copy.controlled,
        HORIZONTAL_INSET,
        STATUS_TOP,
        LABEL_WIDTH,
        LABEL_HEIGHT,
        0,
    )?;
    state.detail = create_child(
        window,
        instance,
        STATIC_CLASS,
        "",
        HORIZONTAL_INSET,
        DETAIL_TOP,
        LABEL_WIDTH,
        LABEL_HEIGHT,
        0,
    )?;
    let _stop = create_child(
        window,
        instance,
        BUTTON_CLASS,
        copy.stop,
        (WINDOW_WIDTH - BUTTON_WIDTH) / 2,
        BUTTON_TOP,
        BUTTON_WIDTH,
        BUTTON_HEIGHT,
        BUTTON_ID,
    )?;
    // SAFETY: the window is live and owns this non-callback timer.
    if unsafe { SetTimer(window, REFRESH_TIMER_ID, REFRESH_INTERVAL_MS, None) } == 0 {
        // SAFETY: the window is uniquely owned by this UI thread.
        unsafe { DestroyWindow(window) };
        return Err("indicator timer failed");
    }

    let mut message = MSG::default();
    loop {
        // SAFETY: the MSG output pointer is valid for each blocking read.
        let result = unsafe { GetMessageW(&raw mut message, ptr::null_mut(), 0, 0) };
        if result == -1 {
            return Err("indicator message loop failed");
        }
        if result == 0 {
            break;
        }
        // SAFETY: GetMessageW produced one initialized message.
        unsafe {
            TranslateMessage(&raw const message);
            DispatchMessageW(&raw const message);
        }
    }
    Ok(())
}

#[allow(clippy::too_many_arguments)]
fn create_child(
    parent: HWND,
    instance: *mut core::ffi::c_void,
    class: &str,
    text: &str,
    x: i32,
    y: i32,
    width: i32,
    height: i32,
    identifier: usize,
) -> Result<HWND, &'static str> {
    let class = wide_null(class);
    let text = wide_null(text);
    let menu = if identifier == 0 {
        ptr::null_mut()
    } else {
        identifier as HMENU
    };
    // SAFETY: all buffers and parent/module handles are valid for creation.
    let child = unsafe {
        CreateWindowExW(
            0,
            class.as_ptr(),
            text.as_ptr(),
            WS_CHILD | WS_VISIBLE | if identifier == 0 { 0 } else { WS_TABSTOP },
            x,
            y,
            width,
            height,
            parent,
            menu,
            instance,
            ptr::null_mut(),
        )
    };
    if child.is_null() {
        Err("indicator control failed")
    } else {
        Ok(child)
    }
}

unsafe extern "system" fn window_proc(
    window: HWND,
    message: u32,
    wparam: WPARAM,
    lparam: LPARAM,
) -> LRESULT {
    if message == WM_NCCREATE {
        let create = lparam as *const CREATESTRUCTW;
        if create.is_null() {
            return 0;
        }
        // SAFETY: WM_NCCREATE supplies a valid CREATESTRUCTW for this call.
        let state = unsafe { (*create).lpCreateParams }.cast::<WindowState>();
        // SAFETY: GWLP_USERDATA stores the stable boxed state pointer.
        unsafe { SetWindowLongPtrW(window, GWLP_USERDATA, state as isize) };
    }
    // SAFETY: GWLP_USERDATA is either zero or the WindowState pointer stored above.
    let state = unsafe { GetWindowLongPtrW(window, GWLP_USERDATA) } as *mut WindowState;
    match message {
        WM_TIMER if wparam == REFRESH_TIMER_ID && !state.is_null() => {
            // SAFETY: the box outlives the message loop and is mutated only on this thread.
            unsafe { refresh_window(window, &mut *state) };
            0
        }
        WM_COMMAND if (wparam & 0xffff) == BUTTON_ID && !state.is_null() => {
            // SAFETY: the state pointer is live for the full message loop.
            let _ = unsafe { &*state }.runtime.local_stop();
            0
        }
        WM_CLOSE => 0,
        WM_DESTROY => {
            // SAFETY: this timer and message loop belong to the destroyed window.
            unsafe {
                KillTimer(window, REFRESH_TIMER_ID);
                PostQuitMessage(0);
            }
            0
        }
        _ => {
            // SAFETY: unhandled messages are forwarded unchanged to the system procedure.
            unsafe { DefWindowProcW(window, message, wparam, lparam) }
        }
    }
}

unsafe fn refresh_window(window: HWND, state: &mut WindowState) {
    let snapshot = state.runtime.snapshot();
    if snapshot.revision == state.last_revision {
        return;
    }
    state.last_revision = snapshot.revision;
    if snapshot.finished {
        // SAFETY: the window is live on this UI thread.
        unsafe { DestroyWindow(window) };
        return;
    }
    let Some(presentation) = snapshot.presentation else {
        // SAFETY: the window is live on this UI thread.
        unsafe { ShowWindow(window, SW_HIDE) };
        return;
    };
    let status = wide_null(state.copy.status(presentation.status_key()));
    let controller = wide_null(&format!(
        "{}: {}",
        state.copy.controller_prefix,
        presentation.controller_display_name().unwrap_or_default()
    ));
    // SAFETY: both child controls and text buffers are valid for these calls.
    unsafe {
        SetWindowTextW(state.status, status.as_ptr());
        SetWindowTextW(state.detail, controller.as_ptr());
        ShowWindow(window, SW_SHOWNOACTIVATE);
        SetWindowPos(
            window,
            HWND_TOPMOST,
            0,
            0,
            0,
            0,
            SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_SHOWWINDOW,
        );
    }
}

fn windows_language_tag() -> String {
    let mut buffer = [0_u16; LOCALE_NAME_CAPACITY];
    // SAFETY: the output buffer is writable for its declared UTF-16 length.
    let length = unsafe {
        GetUserDefaultLocaleName(
            buffer.as_mut_ptr(),
            i32::try_from(buffer.len()).unwrap_or(i32::MAX),
        )
    };
    if length <= 1 {
        return "en".to_owned();
    }
    let text_length = usize::try_from(length - 1).unwrap_or_default();
    String::from_utf16(&buffer[..text_length]).unwrap_or_else(|_| "en".to_owned())
}

fn screen_metric(index: i32) -> Result<i32, &'static str> {
    // SAFETY: the metric index is one of the two documented screen dimensions.
    let value = unsafe { GetSystemMetrics(index) };
    if value <= 0 {
        Err("indicator screen failed")
    } else {
        Ok(value)
    }
}

fn wide_null(value: &str) -> Vec<u16> {
    OsStr::new(value).encode_wide().chain([0]).collect()
}
