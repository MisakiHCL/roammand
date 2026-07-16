// SPDX-License-Identifier: MPL-2.0

#![cfg(windows)]

use roammand_host_platform::windows_scan_code_for_usb_hid;

#[test]
fn maps_usb_hid_usages_to_windows_scan_codes() {
    assert_eq!(windows_scan_code_for_usb_hid(0x04), Some(0x1e));
    assert_eq!(windows_scan_code_for_usb_hid(0x28), Some(0x1c));
    assert_eq!(windows_scan_code_for_usb_hid(0x50), Some(0x4b));
    assert_eq!(windows_scan_code_for_usb_hid(0xe7), Some(0x5c));
    assert_eq!(windows_scan_code_for_usb_hid(0x73), None);
}
