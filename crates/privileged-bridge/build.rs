// SPDX-License-Identifier: MPL-2.0

fn main() {
    println!("cargo:rerun-if-env-changed=CARGO_FEATURE_NATIVE_WEBRTC");
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() == Ok("macos")
        && std::env::var_os("CARGO_FEATURE_NATIVE_WEBRTC").is_some()
    {
        // WebRTC ships Objective-C categories inside a static archive. This
        // flag must reach the final Bridge/Session Agent executable so the
        // category implementations survive Release linking.
        println!("cargo:rustc-link-arg-bin=roammand-privileged-bridge=-ObjC");
    }
}
