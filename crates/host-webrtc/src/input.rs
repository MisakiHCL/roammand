// SPDX-License-Identifier: MPL-2.0

use roammand_protocol::roammand::v1::{ButtonAction, KeyboardAction, PointerButton};

use crate::HostWebRtcError;

pub const NORMALIZED_POINTER_MAX: i32 = 10_000;

pub trait RemoteInputSink: Send {
    /// Injects one validated USB HID keyboard transition.
    ///
    /// # Errors
    ///
    /// Returns an input injection or platform permission error.
    fn keyboard(
        &mut self,
        _action: KeyboardAction,
        _usb_hid_usage: u32,
        _modifier_bits: u32,
    ) -> Result<(), HostWebRtcError> {
        Err(HostWebRtcError::InputFailure)
    }

    /// Injects one validated pointer button action.
    ///
    /// # Errors
    ///
    /// Returns an input injection or platform permission error.
    fn pointer_button(
        &mut self,
        _button: PointerButton,
        _action: ButtonAction,
        _x: i32,
        _y: i32,
    ) -> Result<(), HostWebRtcError> {
        Err(HostWebRtcError::InputFailure)
    }

    /// Injects the latest validated normalized pointer position.
    ///
    /// # Errors
    ///
    /// Returns an input injection or platform permission error.
    fn pointer_move(
        &mut self,
        _x: i32,
        _y: i32,
        _pressed_button_bits: u32,
    ) -> Result<(), HostWebRtcError> {
        Err(HostWebRtcError::InputFailure)
    }

    /// Injects one validated pointer scroll delta.
    ///
    /// # Errors
    ///
    /// Returns an input injection or platform permission error.
    fn pointer_scroll(&mut self, _delta_x: i32, _delta_y: i32) -> Result<(), HostWebRtcError> {
        Err(HostWebRtcError::InputFailure)
    }

    /// Injects validated text through the platform text-input path.
    ///
    /// # Errors
    ///
    /// Returns an input injection or platform permission error.
    fn text(&mut self, _text: &str) -> Result<(), HostWebRtcError> {
        Err(HostWebRtcError::InputFailure)
    }

    /// Releases every key and pointer button idempotently.
    ///
    /// # Errors
    ///
    /// Returns an input injection or platform permission error.
    fn release_all(&mut self) -> Result<(), HostWebRtcError>;
}
