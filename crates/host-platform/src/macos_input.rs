// SPDX-License-Identifier: MPL-2.0

use enigo::{
    Axis, Button, Coordinate, Direction, Enigo, InputError, Keyboard, Mouse, NewConError, Settings,
};

use crate::{NativeButton, NativeDirection, PlatformInputBackend, PlatformInputError};

pub struct MacOsInputBackend {
    enigo: Enigo,
}

impl MacOsInputBackend {
    /// Opens the macOS Quartz input backend and performs Accessibility preflight.
    ///
    /// # Errors
    ///
    /// Returns [`PlatformInputError::PermissionDenied`] when Accessibility is
    /// not granted, or a stable backend error for other initialization failures.
    pub fn new(open_permission_prompt: bool) -> Result<Self, PlatformInputError> {
        let settings = Settings {
            open_prompt_to_get_permissions: open_permission_prompt,
            ..Settings::default()
        };
        let enigo = Enigo::new(&settings).map_err(map_connection_error)?;
        Ok(Self { enigo })
    }
}

impl PlatformInputBackend for MacOsInputBackend {
    fn main_display_size(&mut self) -> Result<(i32, i32), PlatformInputError> {
        self.enigo.main_display().map_err(map_input_error)
    }

    fn keyboard(
        &mut self,
        usb_hid_usage: u32,
        direction: NativeDirection,
    ) -> Result<(), PlatformInputError> {
        let keycode = macos_keycode_for_usb_hid(usb_hid_usage)
            .ok_or(PlatformInputError::UnsupportedKeyboardUsage)?;
        self.enigo
            .raw(keycode, enigo_direction(direction))
            .map_err(map_input_error)
    }

    fn pointer_button(
        &mut self,
        button: NativeButton,
        direction: NativeDirection,
    ) -> Result<(), PlatformInputError> {
        self.enigo
            .button(enigo_button(button), enigo_direction(direction))
            .map_err(map_input_error)
    }

    fn pointer_move(&mut self, x: i32, y: i32) -> Result<(), PlatformInputError> {
        self.enigo
            .move_mouse(x, y, Coordinate::Abs)
            .map_err(map_input_error)
    }

    fn pointer_scroll(&mut self, delta_x: i32, delta_y: i32) -> Result<(), PlatformInputError> {
        if delta_x != 0 {
            self.enigo
                .scroll(delta_x, Axis::Horizontal)
                .map_err(map_input_error)?;
        }
        if delta_y != 0 {
            self.enigo
                .scroll(delta_y, Axis::Vertical)
                .map_err(map_input_error)?;
        }
        Ok(())
    }

    fn text(&mut self, text: &str) -> Result<(), PlatformInputError> {
        self.enigo.text(text).map_err(map_input_error)
    }
}

#[must_use]
pub const fn macos_keycode_for_usb_hid(usage: u32) -> Option<u16> {
    match usage {
        0x04 => Some(0),
        0x05 => Some(11),
        0x06 => Some(8),
        0x07 => Some(2),
        0x08 => Some(14),
        0x09 => Some(3),
        0x0a => Some(5),
        0x0b => Some(4),
        0x0c => Some(34),
        0x0d => Some(38),
        0x0e => Some(40),
        0x0f => Some(37),
        0x10 => Some(46),
        0x11 => Some(45),
        0x12 => Some(31),
        0x13 => Some(35),
        0x14 => Some(12),
        0x15 => Some(15),
        0x16 => Some(1),
        0x17 => Some(17),
        0x18 => Some(32),
        0x19 => Some(9),
        0x1a => Some(13),
        0x1b => Some(7),
        0x1c => Some(16),
        0x1d => Some(6),
        0x1e..=0x26 => Some([18, 19, 20, 21, 23, 22, 26, 28, 25][(usage - 0x1e) as usize]),
        0x27 => Some(29),
        0x28 => Some(36),
        0x29 => Some(53),
        0x2a => Some(51),
        0x2b => Some(48),
        0x2c => Some(49),
        0x2d => Some(27),
        0x2e => Some(24),
        0x2f => Some(33),
        0x30 => Some(30),
        0x31 | 0x32 => Some(42),
        0x33 => Some(41),
        0x34 => Some(39),
        0x35 => Some(50),
        0x36 => Some(43),
        0x37 => Some(47),
        0x38 => Some(44),
        0x39 => Some(57),
        0x3a..=0x45 => {
            Some([122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111][(usage - 0x3a) as usize])
        }
        0x49 => Some(114),
        0x4a => Some(115),
        0x4b => Some(116),
        0x4c => Some(117),
        0x4d => Some(119),
        0x4e => Some(121),
        0x4f => Some(124),
        0x50 => Some(123),
        0x51 => Some(125),
        0x52 => Some(126),
        0x53 => Some(71),
        0x54 => Some(75),
        0x55 => Some(67),
        0x56 => Some(78),
        0x57 => Some(69),
        0x58 => Some(76),
        0x59..=0x61 => Some([83, 84, 85, 86, 87, 88, 89, 91, 92][(usage - 0x59) as usize]),
        0x62 => Some(82),
        0x63 => Some(65),
        0x67 => Some(81),
        0xe0 => Some(59),
        0xe1 => Some(56),
        0xe2 => Some(58),
        0xe3 => Some(55),
        0xe4 => Some(62),
        0xe5 => Some(60),
        0xe6 => Some(61),
        0xe7 => Some(54),
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

const fn map_connection_error(error: NewConError) -> PlatformInputError {
    match error {
        NewConError::NoPermission => PlatformInputError::PermissionDenied,
        _ => PlatformInputError::BackendUnavailable,
    }
}

fn map_input_error(_error: InputError) -> PlatformInputError {
    PlatformInputError::InjectionFailed
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn classifies_accessibility_permission_failure() {
        assert_eq!(
            map_connection_error(NewConError::NoPermission),
            PlatformInputError::PermissionDenied
        );
    }
}
