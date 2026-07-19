// SPDX-License-Identifier: MPL-2.0

#![allow(unsafe_code)]

use std::cell::{Cell, OnceCell};

use objc2::{DefinedClass, MainThreadOnly, define_class, msg_send, rc::Retained, sel};
use objc2_app_kit::{
    NSApplication, NSApplicationActivationPolicy, NSApplicationDelegate, NSBackingStoreType,
    NSButton, NSColor, NSFont, NSPanel, NSScreen, NSStatusWindowLevel, NSTextAlignment,
    NSTextField, NSWindowButton, NSWindowStyleMask, NSWindowTitleVisibility,
};
use objc2_foundation::{
    MainThreadMarker, NSLocale, NSNotification, NSObject, NSObjectProtocol, NSPoint, NSRect,
    NSSize, NSString, NSTimer,
};

use crate::{
    indicator_copy::{ProtectedIndicatorCopy, protected_indicator_copy},
    native_indicator::NativeIndicatorRuntime,
};

const WINDOW_WIDTH: f64 = 400.0;
const SCREEN_INSET: f64 = 16.0;
const VERTICAL_INSET: f64 = 12.0;
const STATUS_LEFT: f64 = 40.0;
const DETAIL_TOP: f64 = VERTICAL_INSET;
const LABEL_WIDTH: f64 = 252.0;
const LABEL_HEIGHT: f64 = 24.0;
const LABEL_SPACING: f64 = 0.0;
const STATUS_TOP: f64 = DETAIL_TOP + LABEL_HEIGHT + LABEL_SPACING;
const BUTTON_WIDTH: f64 = 76.0;
const BUTTON_HEIGHT: f64 = 32.0;
const BUTTON_LEFT: f64 = 308.0;
const REFRESH_SECONDS: f64 = 0.05;
const SURFACE_COLOR: (f64, f64, f64, f64) = (0.035, 0.043, 0.122, 0.96);
const ACTIVE_COLOR: (f64, f64, f64, f64) = (0.196, 0.788, 0.953, 1.0);
const SECONDARY_TEXT_COLOR: (f64, f64, f64, f64) = (0.722, 0.733, 0.839, 1.0);

struct DelegateIvars {
    runtime: NativeIndicatorRuntime,
    copy: ProtectedIndicatorCopy,
    last_revision: Cell<u64>,
    window: OnceCell<Retained<NSPanel>>,
    status: OnceCell<Retained<NSTextField>>,
    detail: OnceCell<Retained<NSTextField>>,
}

define_class!(
    // SAFETY: NSObject has no additional subclassing requirements and all UI
    // state is confined to AppKit's main thread.
    #[unsafe(super = NSObject)]
    #[thread_kind = MainThreadOnly]
    #[ivars = DelegateIvars]
    struct IndicatorDelegate;

    // SAFETY: NSObjectProtocol has no additional safety requirements.
    unsafe impl NSObjectProtocol for IndicatorDelegate {}

    // SAFETY: each selector has the exact AppKit delegate signature.
    unsafe impl NSApplicationDelegate for IndicatorDelegate {
        #[unsafe(method(applicationDidFinishLaunching:))]
        fn did_finish_launching(&self, notification: &NSNotification) {
            self.create_window();
            let app = notification
                .object()
                .and_then(|object| object.downcast::<NSApplication>().ok())
                .expect("AppKit launch notification");
            app.setActivationPolicy(NSApplicationActivationPolicy::Accessory);
            // SAFETY: the target and selector are implemented by this retained
            // main-thread-only delegate; the run loop retains the timer.
            unsafe {
                NSTimer::scheduledTimerWithTimeInterval_target_selector_userInfo_repeats(
                    REFRESH_SECONDS,
                    self,
                    sel!(refreshIndicator:),
                    None,
                    true,
                );
            }
        }
    }

    impl IndicatorDelegate {
        #[unsafe(method(refreshIndicator:))]
        fn refresh_indicator(&self, _timer: &NSTimer) {
            let snapshot = self.ivars().runtime.snapshot();
            if snapshot.revision == self.ivars().last_revision.get() {
                return;
            }
            self.ivars().last_revision.set(snapshot.revision);
            let window = self.ivars().window.get().expect("indicator window");
            if snapshot.finished {
                window.orderOut(None);
                NSApplication::sharedApplication(self.mtm()).terminate(None);
                return;
            }
            let Some(presentation) = snapshot.presentation else {
                window.orderOut(None);
                return;
            };
            let copy = self.ivars().copy;
            self.ivars()
                .status
                .get()
                .expect("status label")
                .setStringValue(&NSString::from_str(copy.status(presentation.status_key())));
            let controller = format!(
                "{}: {}",
                copy.controller_prefix,
                presentation.controller_display_name().unwrap_or_default()
            );
            self.ivars()
                .detail
                .get()
                .expect("detail label")
                .setStringValue(&NSString::from_str(&controller));
            if !window.isVisible() {
                window.orderFrontRegardless();
            }
        }

        #[unsafe(method(localStop:))]
        fn local_stop(&self, _sender: &NSObject) {
            let _ = self.ivars().runtime.local_stop();
        }
    }
);

impl IndicatorDelegate {
    fn new(
        mtm: MainThreadMarker,
        runtime: NativeIndicatorRuntime,
        copy: ProtectedIndicatorCopy,
    ) -> Retained<Self> {
        let this = Self::alloc(mtm).set_ivars(DelegateIvars {
            runtime,
            copy,
            last_revision: Cell::new(0),
            window: OnceCell::new(),
            status: OnceCell::new(),
            detail: OnceCell::new(),
        });
        // SAFETY: this invokes NSObject's designated initializer.
        unsafe { msg_send![super(this), init] }
    }

    fn create_window(&self) {
        let mtm = self.mtm();
        let copy = self.ivars().copy;
        let window_height = indicator_content_height();
        let frame = NSRect::new(
            NSPoint::new(0.0, 0.0),
            NSSize::new(WINDOW_WIDTH, window_height),
        );
        // SAFETY: released-when-closed is disabled below, and the retained
        // panel remains in the delegate for the complete application run.
        let window = NSPanel::initWithContentRect_styleMask_backing_defer(
            NSPanel::alloc(mtm),
            frame,
            NSWindowStyleMask::Titled
                | NSWindowStyleMask::FullSizeContentView
                | NSWindowStyleMask::NonactivatingPanel,
            NSBackingStoreType::Buffered,
            false,
        );
        // SAFETY: this panel is retained by the delegate until termination.
        unsafe { window.setReleasedWhenClosed(false) };
        window.setTitle(&NSString::from_str(copy.product_name));
        window.setTitleVisibility(NSWindowTitleVisibility::Hidden);
        window.setTitlebarAppearsTransparent(true);
        window.setBackgroundColor(Some(&native_color(SURFACE_COLOR)));
        window.setLevel(NSStatusWindowLevel);
        window.setFloatingPanel(true);
        window.setBecomesKeyOnlyIfNeeded(true);
        for button_kind in [
            NSWindowButton::CloseButton,
            NSWindowButton::MiniaturizeButton,
            NSWindowButton::ZoomButton,
        ] {
            if let Some(button) = window.standardWindowButton(button_kind) {
                button.setHidden(true);
                button.removeFromSuperview();
            }
        }
        if let Some(screen) = NSScreen::mainScreen(mtm) {
            let visible = screen.visibleFrame();
            window.setFrameOrigin(NSPoint::new(
                visible.origin.x + visible.size.width - WINDOW_WIDTH - SCREEN_INSET,
                visible.origin.y + visible.size.height - window_height - SCREEN_INSET,
            ));
        } else {
            window.center();
        }

        let activity = NSTextField::labelWithString(&NSString::from_str("●"), mtm);
        activity.setFrame(NSRect::new(
            NSPoint::new(16.0, STATUS_TOP),
            NSSize::new(16.0, LABEL_HEIGHT),
        ));
        activity.setTextColor(Some(&native_color(ACTIVE_COLOR)));

        let status = NSTextField::labelWithString(&NSString::from_str(copy.controlled), mtm);
        status.setFrame(NSRect::new(
            NSPoint::new(STATUS_LEFT, STATUS_TOP),
            NSSize::new(LABEL_WIDTH, LABEL_HEIGHT),
        ));
        status.setAlignment(NSTextAlignment::Left);
        status.setFont(Some(&NSFont::boldSystemFontOfSize(14.0)));
        status.setTextColor(Some(&NSColor::whiteColor()));

        let detail = NSTextField::labelWithString(&NSString::from_str(""), mtm);
        detail.setFrame(NSRect::new(
            NSPoint::new(STATUS_LEFT, DETAIL_TOP),
            NSSize::new(LABEL_WIDTH, LABEL_HEIGHT),
        ));
        detail.setAlignment(NSTextAlignment::Left);
        detail.setFont(Some(&NSFont::systemFontOfSize(12.0)));
        detail.setTextColor(Some(&native_color(SECONDARY_TEXT_COLOR)));

        // SAFETY: the target and localStop: selector belong to this retained
        // delegate. No remote IPC command can invoke this AppKit action.
        let stop = unsafe {
            NSButton::buttonWithTitle_target_action(
                &NSString::from_str(copy.stop),
                Some(self),
                Some(sel!(localStop:)),
                mtm,
            )
        };
        stop.setFrame(NSRect::new(
            NSPoint::new(
                BUTTON_LEFT,
                ((window_height - BUTTON_HEIGHT) / 2.0).max(0.0),
            ),
            NSSize::new(BUTTON_WIDTH, BUTTON_HEIGHT),
        ));
        stop.setBordered(false);
        stop.setContentTintColor(Some(&NSColor::whiteColor()));
        stop.setFont(Some(&NSFont::boldSystemFontOfSize(13.0)));

        let content = window.contentView().expect("panel content view");
        // SAFETY: all subviews are retained by the panel content hierarchy.
        content.addSubview(&activity);
        content.addSubview(&status);
        content.addSubview(&detail);
        content.addSubview(&stop);
        window.orderOut(None);
        self.ivars()
            .status
            .set(status)
            .expect("status initialized once");
        self.ivars()
            .detail
            .set(detail)
            .expect("detail initialized once");
        self.ivars()
            .window
            .set(window)
            .expect("window initialized once");
    }
}

fn indicator_content_height() -> f64 {
    let label_content_height = STATUS_TOP + LABEL_HEIGHT + VERTICAL_INSET;
    let button_content_height = BUTTON_HEIGHT + 2.0 * VERTICAL_INSET;
    label_content_height.max(button_content_height)
}

fn native_color((red, green, blue, alpha): (f64, f64, f64, f64)) -> Retained<NSColor> {
    NSColor::colorWithSRGBRed_green_blue_alpha(red, green, blue, alpha)
}

/// Runs the protected `AppKit` indicator on the process main thread until the
/// Helper worker marks the shared runtime finished.
///
/// # Errors
///
/// Fails if invoked away from the process main thread.
pub fn run_macos_indicator(runtime: NativeIndicatorRuntime) -> Result<(), &'static str> {
    let mtm = MainThreadMarker::new().ok_or("indicator requires the main thread")?;
    let language = NSLocale::preferredLanguages()
        .firstObject()
        .map_or_else(|| "en".to_owned(), |value| value.to_string());
    let app = NSApplication::sharedApplication(mtm);
    let delegate = IndicatorDelegate::new(mtm, runtime, protected_indicator_copy(&language));
    app.setDelegate(Some(objc2::runtime::ProtocolObject::from_ref(&*delegate)));
    app.run();
    Ok(())
}
