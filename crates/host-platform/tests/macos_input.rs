// SPDX-License-Identifier: MPL-2.0

#![cfg(target_os = "macos")]

use roammand_host_platform::macos_keycode_for_usb_hid;

#[test]
fn maps_usb_hid_usages_to_quartz_keycodes() {
    assert_eq!(macos_keycode_for_usb_hid(0x04), Some(0));
    assert_eq!(macos_keycode_for_usb_hid(0x28), Some(36));
    assert_eq!(macos_keycode_for_usb_hid(0x50), Some(123));
    assert_eq!(macos_keycode_for_usb_hid(0xe7), Some(54));
    assert_eq!(macos_keycode_for_usb_hid(0x73), None);
}
