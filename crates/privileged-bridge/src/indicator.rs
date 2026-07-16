// SPDX-License-Identifier: MPL-2.0

use thiserror::Error;

const PRODUCT_NAME: &str = "Roammand";
const MAX_CONTROLLER_NAME_BYTES: usize = 128;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum IndicatorPhase {
    Controlled,
    Transitioning,
    Reconnecting,
    Error,
    Stopping,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum IndicatorStatusKey {
    Controlled,
    Transitioning,
    Reconnecting,
    Error,
    Stopping,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct IndicatorPresentation {
    controller_display_name: String,
    phase: IndicatorPhase,
}

impl IndicatorPresentation {
    #[must_use]
    pub const fn product_name(&self) -> &'static str {
        PRODUCT_NAME
    }

    #[must_use]
    pub fn controller_display_name(&self) -> Option<&str> {
        Some(&self.controller_display_name)
    }

    #[must_use]
    pub const fn status_key(&self) -> IndicatorStatusKey {
        match self.phase {
            IndicatorPhase::Controlled => IndicatorStatusKey::Controlled,
            IndicatorPhase::Transitioning => IndicatorStatusKey::Transitioning,
            IndicatorPhase::Reconnecting => IndicatorStatusKey::Reconnecting,
            IndicatorPhase::Error => IndicatorStatusKey::Error,
            IndicatorPhase::Stopping => IndicatorStatusKey::Stopping,
        }
    }

    #[must_use]
    pub const fn stop_visible(&self) -> bool {
        true
    }

    #[must_use]
    pub const fn input_enabled(&self) -> bool {
        matches!(self.phase, IndicatorPhase::Controlled)
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub enum IndicatorAction {
    Show(IndicatorPresentation),
    Update(IndicatorPresentation),
    EmergencyStop,
    Destroy,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum RemoteIndicatorCommand {
    Hide,
    Close,
    Focus,
}

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub enum IndicatorError {
    #[error("protected indicator Controller name is invalid")]
    InvalidControllerName,
    #[error("remote protected indicator command rejected")]
    RemoteCommandRejected,
}

#[derive(Debug, Default)]
pub struct IndicatorController {
    presentation: Option<IndicatorPresentation>,
    stop_emitted: bool,
}

impl IndicatorController {
    #[must_use]
    pub const fn new() -> Self {
        Self {
            presentation: None,
            stop_emitted: false,
        }
    }

    /// Shows local control state using a previously authenticated public name.
    ///
    /// # Errors
    ///
    /// Rejects empty, oversized, or control-character names.
    pub fn show_controlled(
        &mut self,
        controller_display_name: &str,
    ) -> Result<Vec<IndicatorAction>, IndicatorError> {
        if controller_display_name.is_empty()
            || controller_display_name.len() > MAX_CONTROLLER_NAME_BYTES
            || controller_display_name.chars().any(char::is_control)
        {
            return Err(IndicatorError::InvalidControllerName);
        }
        let was_visible = self.presentation.is_some();
        let presentation = IndicatorPresentation {
            controller_display_name: controller_display_name.to_owned(),
            phase: IndicatorPhase::Controlled,
        };
        self.presentation = Some(presentation.clone());
        self.stop_emitted = false;
        Ok(vec![if was_visible {
            IndicatorAction::Update(presentation)
        } else {
            IndicatorAction::Show(presentation)
        }])
    }

    #[must_use]
    pub fn set_phase(&mut self, phase: IndicatorPhase) -> Vec<IndicatorAction> {
        let Some(presentation) = self.presentation.as_mut() else {
            return Vec::new();
        };
        presentation.phase = phase;
        vec![IndicatorAction::Update(presentation.clone())]
    }

    #[must_use]
    pub fn local_stop(&mut self) -> Vec<IndicatorAction> {
        if self.presentation.is_none() || self.stop_emitted {
            return Vec::new();
        }
        self.stop_emitted = true;
        let mut actions = vec![IndicatorAction::EmergencyStop];
        actions.extend(self.set_phase(IndicatorPhase::Stopping));
        actions
    }

    /// Rejects every remote attempt to manipulate the protected local surface.
    ///
    /// # Errors
    ///
    /// Always returns [`IndicatorError::RemoteCommandRejected`].
    pub const fn handle_remote(
        &self,
        _command: RemoteIndicatorCommand,
    ) -> Result<(), IndicatorError> {
        Err(IndicatorError::RemoteCommandRejected)
    }

    #[must_use]
    pub fn teardown(&mut self) -> Vec<IndicatorAction> {
        if self.presentation.take().is_none() {
            return Vec::new();
        }
        self.stop_emitted = false;
        vec![IndicatorAction::Destroy]
    }

    #[must_use]
    pub fn presentation(&self) -> Option<IndicatorPresentation> {
        self.presentation.clone()
    }
}
