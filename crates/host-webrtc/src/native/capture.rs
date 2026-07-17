// SPDX-License-Identifier: MPL-2.0

use std::{
    sync::{
        Arc,
        atomic::{AtomicBool, Ordering},
        mpsc::{Receiver, RecvTimeoutError, sync_channel},
    },
    thread::{self, JoinHandle},
    time::{Duration, Instant, SystemTime, UNIX_EPOCH},
};

use crate::HostWebRtcError;
#[cfg(target_os = "macos")]
use core_graphics::access::ScreenCaptureAccess;
#[cfg(not(target_os = "macos"))]
use libwebrtc::desktop_capturer::{
    CaptureError, CaptureSource, DesktopCaptureSourceType, DesktopCapturer, DesktopCapturerOptions,
    DesktopFrame,
};
use libwebrtc::{
    native::yuv_helper,
    video_frame::{I420Buffer, VideoFrame, VideoRotation},
    video_source::{VideoResolution, native::NativeVideoSource},
};
#[cfg(not(target_os = "macos"))]
use std::sync::mpsc::SyncSender;

#[cfg(target_os = "macos")]
mod macos;
#[cfg(target_os = "macos")]
use macos::DesktopCaptureDriver;

const BYTES_PER_DESKTOP_PIXEL: u32 = 4;
const CAPTURE_FRAME_INTERVAL: Duration = Duration::from_millis(33);
const CAPTURE_RESULT_TIMEOUT: Duration = Duration::from_millis(250);
const INITIAL_CAPTURE_TIMEOUT: Duration = Duration::from_secs(5);
const INITIAL_CAPTURE_RETRY_INTERVAL: Duration = Duration::from_millis(100);
const MAXIMUM_CAPTURE_DIMENSION: i32 = 16_384;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct NativeSourceDescriptor {
    pub source_id: u64,
    pub display_id: i64,
}

#[must_use]
pub fn select_main_display_source_id(
    sources: &[NativeSourceDescriptor],
    main_display_source_id: u64,
) -> Option<u64> {
    sources
        .iter()
        .find(|source| source.source_id == main_display_source_id)
        .map(|source| source.source_id)
}

pub(crate) struct CapturePipeline {
    source: NativeVideoSource,
    stop: Arc<AtomicBool>,
    thread: Option<JoinHandle<()>>,
}

impl CapturePipeline {
    pub(crate) fn start() -> Result<Self, HostWebRtcError> {
        #[cfg(target_os = "macos")]
        ensure_screen_capture_access()?;
        let mut capturer = DesktopCaptureDriver::new()?;
        let (sender, receiver) = sync_channel(1);
        capturer.start(sender);

        let first = receive_initial_frame(
            &receiver,
            || capturer.capture_frame(),
            INITIAL_CAPTURE_TIMEOUT,
            INITIAL_CAPTURE_RETRY_INTERVAL,
        )?;
        let resolution = VideoResolution {
            width: u32::try_from(first.width).map_err(|_| HostWebRtcError::PeerFailure)?,
            height: u32::try_from(first.height).map_err(|_| HostWebRtcError::PeerFailure)?,
        };
        let video_source = NativeVideoSource::new(resolution, true);
        publish_frame(&video_source, &first)?;

        let stop = Arc::new(AtomicBool::new(false));
        let thread_stop = Arc::clone(&stop);
        let thread_source = video_source.clone();
        let capture_thread = thread::Builder::new()
            .name("roammand-main-display-capture".to_owned())
            .spawn(move || {
                capture_loop(&mut capturer, &receiver, &thread_source, &thread_stop);
            })
            .map_err(|_| HostWebRtcError::PeerFailure)?;

        Ok(Self {
            source: video_source,
            stop,
            thread: Some(capture_thread),
        })
    }

    pub(crate) fn source(&self) -> NativeVideoSource {
        self.source.clone()
    }

    pub(crate) fn stop(&mut self) {
        self.stop.store(true, Ordering::Release);
        if let Some(thread) = self.thread.take() {
            let _ = thread.join();
        }
    }
}

#[cfg(not(target_os = "macos"))]
struct DesktopCaptureDriver {
    handle: DesktopCapturer,
    source: Option<CaptureSource>,
}

#[cfg(not(target_os = "macos"))]
impl DesktopCaptureDriver {
    fn new() -> Result<Self, HostWebRtcError> {
        let mut options = DesktopCapturerOptions::new(DesktopCaptureSourceType::Screen);
        options.set_include_cursor(false);
        let handle = DesktopCapturer::new(options).ok_or(HostWebRtcError::PeerFailure)?;
        let source = main_display_source(&handle)?;
        Ok(Self {
            handle,
            source: Some(source),
        })
    }

    fn start(&mut self, sender: SyncSender<CaptureMessage>) {
        let source = self
            .source
            .take()
            .expect("capture source is consumed only once");
        self.handle.start_capture(Some(source), move |result| {
            publish_capture_result(&sender, result);
        });
    }

    fn capture_frame(&mut self) {
        self.handle.capture_frame();
    }
}

#[cfg(target_os = "macos")]
fn ensure_screen_capture_access() -> Result<(), HostWebRtcError> {
    let access = ScreenCaptureAccess;
    if access.preflight() || access.request() {
        Ok(())
    } else {
        Err(HostWebRtcError::PeerFailure)
    }
}

impl Drop for CapturePipeline {
    fn drop(&mut self) {
        self.stop();
    }
}

#[cfg(not(target_os = "macos"))]
fn main_display_source(capturer: &DesktopCapturer) -> Result<CaptureSource, HostWebRtcError> {
    let sources = capturer.get_source_list();
    if sources.is_empty() {
        return Err(HostWebRtcError::PeerFailure);
    }
    let descriptors = sources
        .iter()
        .map(|source| NativeSourceDescriptor {
            source_id: source.id(),
            display_id: source.display_id(),
        })
        .collect::<Vec<_>>();
    let main_display_source_id = platform_main_display_source_id(&descriptors);
    let selected_id = select_main_display_source_id(&descriptors, main_display_source_id)
        .ok_or(HostWebRtcError::PeerFailure)?;
    sources
        .into_iter()
        .find(|source| source.id() == selected_id)
        .ok_or(HostWebRtcError::PeerFailure)
}

#[cfg(target_os = "windows")]
fn platform_main_display_source_id(sources: &[NativeSourceDescriptor]) -> u64 {
    sources
        .first()
        .expect("capture sources are checked non-empty")
        .source_id
}

#[cfg(not(any(target_os = "macos", windows)))]
fn platform_main_display_source_id(sources: &[NativeSourceDescriptor]) -> u64 {
    sources
        .first()
        .expect("capture sources are checked non-empty")
        .source_id
}

enum CaptureMessage {
    Frame(OwnedDesktopFrame),
    TemporaryError,
    PermanentError,
    InvalidFrame,
}

struct OwnedDesktopFrame {
    width: i32,
    height: i32,
    stride: u32,
    data: Vec<u8>,
}

impl OwnedDesktopFrame {
    #[cfg(not(target_os = "macos"))]
    fn copy_from(frame: &DesktopFrame) -> Result<Self, HostWebRtcError> {
        Self::copy_from_parts(frame.width(), frame.height(), frame.stride(), frame.data())
    }

    fn copy_from_parts(
        width: i32,
        height: i32,
        stride: u32,
        data: &[u8],
    ) -> Result<Self, HostWebRtcError> {
        let required = required_frame_bytes(width, height, stride)?;
        if data.len() < required {
            return Err(HostWebRtcError::PeerFailure);
        }
        Ok(Self {
            width,
            height,
            stride,
            data: data[..required].to_vec(),
        })
    }
}

fn required_frame_bytes(width: i32, height: i32, stride: u32) -> Result<usize, HostWebRtcError> {
    if width <= 0
        || height <= 0
        || width > MAXIMUM_CAPTURE_DIMENSION
        || height > MAXIMUM_CAPTURE_DIMENSION
    {
        return Err(HostWebRtcError::PeerFailure);
    }
    let minimum_stride = u32::try_from(width)
        .ok()
        .and_then(|value| value.checked_mul(BYTES_PER_DESKTOP_PIXEL))
        .ok_or(HostWebRtcError::PeerFailure)?;
    let required = usize::try_from(stride)
        .ok()
        .and_then(|value| value.checked_mul(usize::try_from(height).ok()?))
        .ok_or(HostWebRtcError::PeerFailure)?;
    if stride < minimum_stride {
        return Err(HostWebRtcError::PeerFailure);
    }
    Ok(required)
}

#[cfg(not(target_os = "macos"))]
fn publish_capture_result(
    sender: &SyncSender<CaptureMessage>,
    result: Result<DesktopFrame, CaptureError>,
) {
    let message = match result {
        Ok(frame) => match OwnedDesktopFrame::copy_from(&frame) {
            Ok(frame) => CaptureMessage::Frame(frame),
            Err(_) => CaptureMessage::InvalidFrame,
        },
        Err(CaptureError::Temporary) => CaptureMessage::TemporaryError,
        Err(CaptureError::Permanent) => CaptureMessage::PermanentError,
    };
    let _ = sender.try_send(message);
}

fn receive_initial_frame(
    receiver: &Receiver<CaptureMessage>,
    mut request_frame: impl FnMut(),
    timeout: Duration,
    retry_interval: Duration,
) -> Result<OwnedDesktopFrame, HostWebRtcError> {
    let deadline = Instant::now() + timeout;
    loop {
        request_frame();
        let remaining = deadline.saturating_duration_since(Instant::now());
        if remaining.is_zero() {
            return Err(HostWebRtcError::PeerFailure);
        }
        match receiver.recv_timeout(remaining.min(CAPTURE_RESULT_TIMEOUT)) {
            Ok(CaptureMessage::Frame(frame)) => return Ok(frame),
            Ok(CaptureMessage::TemporaryError) | Err(RecvTimeoutError::Timeout) => {}
            Ok(CaptureMessage::PermanentError | CaptureMessage::InvalidFrame)
            | Err(RecvTimeoutError::Disconnected) => return Err(HostWebRtcError::PeerFailure),
        }
        let remaining = deadline.saturating_duration_since(Instant::now());
        if remaining.is_zero() {
            return Err(HostWebRtcError::PeerFailure);
        }
        thread::sleep(retry_interval.min(remaining));
    }
}

fn capture_loop(
    capturer: &mut DesktopCaptureDriver,
    receiver: &Receiver<CaptureMessage>,
    source: &NativeVideoSource,
    stop: &AtomicBool,
) {
    let resolution = source.video_resolution();
    while !stop.load(Ordering::Acquire) {
        let started = std::time::Instant::now();
        capturer.capture_frame();
        match receiver.recv_timeout(CAPTURE_RESULT_TIMEOUT) {
            Ok(CaptureMessage::Frame(frame)) => {
                let same_resolution = u32::try_from(frame.width).ok() == Some(resolution.width)
                    && u32::try_from(frame.height).ok() == Some(resolution.height);
                if !same_resolution || publish_frame(source, &frame).is_err() {
                    break;
                }
            }
            Ok(CaptureMessage::TemporaryError) | Err(RecvTimeoutError::Timeout) => {}
            Ok(CaptureMessage::PermanentError | CaptureMessage::InvalidFrame)
            | Err(RecvTimeoutError::Disconnected) => break,
        }
        if let Some(remaining) = CAPTURE_FRAME_INTERVAL.checked_sub(started.elapsed()) {
            thread::sleep(remaining);
        }
    }
}

fn publish_frame(
    source: &NativeVideoSource,
    frame: &OwnedDesktopFrame,
) -> Result<(), HostWebRtcError> {
    let width = u32::try_from(frame.width).map_err(|_| HostWebRtcError::PeerFailure)?;
    let height = u32::try_from(frame.height).map_err(|_| HostWebRtcError::PeerFailure)?;
    let mut buffer = I420Buffer::new(width, height);
    let (stride_y, stride_u, stride_v) = buffer.strides();
    let (data_y, data_u, data_v) = buffer.data_mut();
    yuv_helper::argb_to_i420(
        &frame.data,
        frame.stride,
        data_y,
        stride_y,
        data_u,
        stride_u,
        data_v,
        stride_v,
        frame.width,
        frame.height,
    );
    let timestamp_us = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_micros()
        .try_into()
        .unwrap_or(i64::MAX);
    source.capture_frame(&VideoFrame {
        rotation: VideoRotation::VideoRotation0,
        timestamp_us,
        buffer,
    });
    Ok(())
}

#[cfg(test)]
mod tests {
    use std::collections::VecDeque;

    use super::*;

    #[test]
    fn initial_capture_retries_temporary_errors_until_a_frame_arrives() {
        let (sender, receiver) = sync_channel(1);
        let mut messages = VecDeque::from([
            CaptureMessage::TemporaryError,
            CaptureMessage::TemporaryError,
            CaptureMessage::Frame(OwnedDesktopFrame {
                width: 1,
                height: 1,
                stride: BYTES_PER_DESKTOP_PIXEL,
                data: vec![0; BYTES_PER_DESKTOP_PIXEL as usize],
            }),
        ]);

        let frame = receive_initial_frame(
            &receiver,
            || {
                sender
                    .try_send(messages.pop_front().expect("test message must exist"))
                    .expect("test message must send");
            },
            Duration::from_secs(1),
            Duration::ZERO,
        )
        .expect("temporary errors must be retried");

        assert_eq!((frame.width, frame.height), (1, 1));
        assert!(messages.is_empty());
    }
}
