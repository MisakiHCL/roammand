// SPDX-License-Identifier: MPL-2.0

use std::sync::{
    Arc, Mutex, MutexGuard,
    atomic::{AtomicBool, Ordering},
};

use crate::indicator::{
    IndicatorAction, IndicatorController, IndicatorError, IndicatorPresentation,
};

#[derive(Clone)]
pub struct NativeIndicatorClient {
    shared: Arc<SharedIndicator>,
}

pub struct NativeIndicatorRuntime {
    shared: Arc<SharedIndicator>,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct NativeIndicatorSnapshot {
    pub revision: u64,
    pub presentation: Option<IndicatorPresentation>,
    pub finished: bool,
}

struct SharedIndicator {
    state: Mutex<SharedState>,
    local_stop: AtomicBool,
}

struct SharedState {
    controller: IndicatorController,
    revision: u64,
    finished: bool,
}

#[must_use]
pub fn native_indicator_channel() -> (NativeIndicatorClient, NativeIndicatorRuntime) {
    let shared = Arc::new(SharedIndicator {
        state: Mutex::new(SharedState {
            controller: IndicatorController::new(),
            revision: 1,
            finished: false,
        }),
        local_stop: AtomicBool::new(false),
    });
    (
        NativeIndicatorClient {
            shared: Arc::clone(&shared),
        },
        NativeIndicatorRuntime { shared },
    )
}

impl NativeIndicatorClient {
    /// Publishes one authenticated Controller name to the local-only surface.
    ///
    /// # Errors
    ///
    /// Rejects invalid names and a runtime that has already finished.
    pub fn show_controlled(&self, controller_display_name: &str) -> Result<(), IndicatorError> {
        let mut state = self.shared.state();
        if state.finished {
            return Err(IndicatorError::RemoteCommandRejected);
        }
        let actions = state.controller.show_controlled(controller_display_name)?;
        if actions.is_empty() {
            return Ok(());
        }
        self.shared.local_stop.store(false, Ordering::Release);
        state.bump_revision();
        Ok(())
    }

    pub fn hide(&self) {
        let mut state = self.shared.state();
        if !state.controller.teardown().is_empty() {
            state.bump_revision();
        }
    }

    pub fn finish(&self) {
        self.shared.finish();
    }

    #[must_use]
    pub fn take_local_stop(&self) -> bool {
        self.shared.local_stop.swap(false, Ordering::AcqRel)
    }
}

impl NativeIndicatorRuntime {
    #[must_use]
    pub fn snapshot(&self) -> NativeIndicatorSnapshot {
        let state = self.shared.state();
        NativeIndicatorSnapshot {
            revision: state.revision,
            presentation: state.controller.presentation(),
            finished: state.finished,
        }
    }

    #[must_use]
    pub fn local_stop(&self) -> bool {
        let mut state = self.shared.state();
        let actions = state.controller.local_stop();
        let emitted = actions
            .iter()
            .any(|action| matches!(action, IndicatorAction::EmergencyStop));
        if emitted {
            self.shared.local_stop.store(true, Ordering::Release);
            state.bump_revision();
        }
        emitted
    }

    pub fn finish(&self) {
        self.shared.finish();
    }
}

impl SharedIndicator {
    fn finish(&self) {
        let mut state = self.state();
        if state.finished {
            return;
        }
        let _ = state.controller.teardown();
        state.finished = true;
        state.bump_revision();
    }

    fn state(&self) -> MutexGuard<'_, SharedState> {
        self.state
            .lock()
            .unwrap_or_else(std::sync::PoisonError::into_inner)
    }
}

impl SharedState {
    fn bump_revision(&mut self) {
        self.revision = self.revision.saturating_add(1);
    }
}
