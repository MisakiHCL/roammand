// SPDX-License-Identifier: MPL-2.0

fn main() {
    println!("cargo:rerun-if-env-changed=CARGO_FEATURE_NATIVE_WEBRTC");
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() == Ok("macos")
        && std::env::var_os("CARGO_FEATURE_NATIVE_WEBRTC").is_some()
    {
        // WebRTC ships Objective-C categories inside a static archive. This
        // flag must be present when linking the final Host executable or the
        // category implementations are discarded.
        println!("cargo:rustc-link-arg=-ObjC");
    }
}
