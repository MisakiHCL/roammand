// SPDX-License-Identifier: MPL-2.0

use enigo::{
    Axis, Button, Coordinate, Direction, Enigo, InputError, Key, Keyboard, Mouse, Settings,
};

use crate::{NativeButton, NativeDirection, PlatformInputBackend, PlatformInputError};

pub struct WindowsInputBackend {
    enigo: Enigo,
}

impl WindowsInputBackend {
    /// Opens the Windows `SendInput` backend.
    ///
    /// # Errors
    ///
    /// Returns a stable backend error when native initialization fails.
    pub fn new() -> Result<Self, PlatformInputError> {
        let enigo =
            Enigo::new(&Settings::default()).map_err(|_| PlatformInputError::BackendUnavailable)?;
        Ok(Self { enigo })
    }
}

impl PlatformInputBackend for WindowsInputBackend {
    fn main_display_size(&mut self) -> Result<(i32, i32), PlatformInputError> {
        self.enigo
            .main_display()
            .map_err(|error| map_input_error(&error))
    }

    fn keyboard(
        &mut self,
        usb_hid_usage: u32,
        direction: NativeDirection,
    ) -> Result<(), PlatformInputError> {
        let direction = enigo_direction(direction);
        if let Some(key) = modifier_key(usb_hid_usage) {
            return self
                .enigo
                .key(key, direction)
                .map_err(|error| map_input_error(&error));
        }
        let scan_code = windows_scan_code_for_usb_hid(usb_hid_usage)
            .ok_or(PlatformInputError::UnsupportedKeyboardUsage)?;
        self.enigo
            .raw(scan_code, direction)
            .map_err(|error| map_input_error(&error))
    }

    fn pointer_button(
        &mut self,
        button: NativeButton,
        direction: NativeDirection,
    ) -> Result<(), PlatformInputError> {
        self.enigo
            .button(enigo_button(button), enigo_direction(direction))
            .map_err(|error| map_input_error(&error))
    }

    fn pointer_move(&mut self, x: i32, y: i32) -> Result<(), PlatformInputError> {
        self.enigo
            .move_mouse(x, y, Coordinate::Abs)
            .map_err(|error| map_input_error(&error))
    }

    fn pointer_scroll(&mut self, delta_x: i32, delta_y: i32) -> Result<(), PlatformInputError> {
        if delta_x != 0 {
            self.enigo
                .scroll(delta_x, Axis::Horizontal)
                .map_err(|error| map_input_error(&error))?;
        }
        if delta_y != 0 {
            self.enigo
                .scroll(delta_y, Axis::Vertical)
                .map_err(|error| map_input_error(&error))?;
        }
        Ok(())
    }

    fn text(&mut self, text: &str) -> Result<(), PlatformInputError> {
        self.enigo
            .text(text)
            .map_err(|error| map_input_error(&error))
    }
}

#[must_use]
#[allow(clippy::match_same_arms)]
pub fn windows_scan_code_for_usb_hid(usage: u32) -> Option<u16> {
    match usage {
        0x04..=0x1d => Some(
            [
                0x1e, 0x30, 0x2e, 0x20, 0x12, 0x21, 0x22, 0x23, 0x17, 0x24, 0x25, 0x26, 0x32, 0x31,
                0x18, 0x19, 0x10, 0x13, 0x1f, 0x14, 0x16, 0x2f, 0x11, 0x2d, 0x15, 0x2c,
            ][(usage - 0x04) as usize],
        ),
        0x1e..=0x26 => {
            Some([0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a][(usage - 0x1e) as usize])
        }
        0x27 => Some(0x0b),
        0x28 => Some(0x1c),
        0x29 => Some(0x01),
        0x2a => Some(0x0e),
        0x2b => Some(0x0f),
        0x2c => Some(0x39),
        0x2d => Some(0x0c),
        0x2e => Some(0x0d),
        0x2f => Some(0x1a),
        0x30 => Some(0x1b),
        0x31 | 0x32 => Some(0x2b),
        0x33 => Some(0x27),
        0x34 => Some(0x28),
        0x35 => Some(0x29),
        0x36 => Some(0x33),
        0x37 => Some(0x34),
        0x38 => Some(0x35),
        0x39 => Some(0x3a),
        0x3a..=0x43 => u16::try_from(usage - 0x3a).ok().map(|offset| 0x3b + offset),
        0x44 => Some(0x57),
        0x45 => Some(0x58),
        0x46 => Some(0x37),
        0x47 => Some(0x46),
        0x48 => Some(0x45),
        0x49 => Some(0x52),
        0x4a => Some(0x47),
        0x4b => Some(0x49),
        0x4c => Some(0x53),
        0x4d => Some(0x4f),
        0x4e => Some(0x51),
        0x4f => Some(0x4d),
        0x50 => Some(0x4b),
        0x51 => Some(0x50),
        0x52 => Some(0x48),
        0x53 => Some(0x45),
        0x54 => Some(0x35),
        0x55 => Some(0x37),
        0x56 => Some(0x4a),
        0x57 => Some(0x4e),
        0x58 => Some(0x1c),
        0x59 => Some(0x4f),
        0x5a => Some(0x50),
        0x5b => Some(0x51),
        0x5c => Some(0x4b),
        0x5d => Some(0x4c),
        0x5e => Some(0x4d),
        0x5f => Some(0x47),
        0x60 => Some(0x48),
        0x61 => Some(0x49),
        0x62 => Some(0x52),
        0x63 => Some(0x53),
        0xe0 | 0xe4 => Some(0x1d),
        0xe1 => Some(0x2a),
        0xe2 | 0xe6 => Some(0x38),
        0xe3 => Some(0x5b),
        0xe5 => Some(0x36),
        0xe7 => Some(0x5c),
        _ => None,
    }
}

const fn modifier_key(usage: u32) -> Option<Key> {
    match usage {
        0xe0 => Some(Key::LControl),
        0xe1 => Some(Key::LShift),
        0xe2 => Some(Key::LMenu),
        0xe3 => Some(Key::LWin),
        0xe4 => Some(Key::RControl),
        0xe5 => Some(Key::RShift),
        0xe6 => Some(Key::RMenu),
        0xe7 => Some(Key::RWin),
        _ => None,
    }
}

const fn enigo_direction(direction: NativeDirection) -> Direction {
    match direction {
        NativeDirection::Press => Direction::Press,
        NativeDirection::Release => Direction::Release,
    }
}

const fn enigo_button(button: NativeButton) -> Button {
    match button {
        NativeButton::Left => Button::Left,
        NativeButton::Right => Button::Right,
        NativeButton::Middle => Button::Middle,
    }
}

fn map_input_error(error: &InputError) -> PlatformInputError {
    match error {
        InputError::Simulate(_) => PlatformInputError::PartialInjection,
        _ => PlatformInputError::InjectionFailed,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn classifies_send_input_partial_batch_failure() {
        assert_eq!(
            map_input_error(&InputError::Simulate("partial SendInput batch")),
            PlatformInputError::PartialInjection
        );
    }
}
