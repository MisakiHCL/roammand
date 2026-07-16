// SPDX-License-Identifier: MPL-2.0

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum ServiceControl {
    Start,
    SessionChanged,
    Stop,
    Shutdown,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum ServiceAction {
    ObserveSessions,
    FreezeInput,
    ReleaseAllInput,
    StopHelper,
    CloseTransport,
}

#[derive(Debug, Default)]
pub struct ServiceCore {
    running: bool,
}

impl ServiceCore {
    #[must_use]
    pub const fn new() -> Self {
        Self { running: false }
    }

    #[must_use]
    pub fn apply(&mut self, control: ServiceControl) -> Vec<ServiceAction> {
        match control {
            ServiceControl::Start if !self.running => {
                self.running = true;
                vec![ServiceAction::ObserveSessions]
            }
            ServiceControl::SessionChanged if self.running => {
                vec![ServiceAction::FreezeInput, ServiceAction::ObserveSessions]
            }
            ServiceControl::Stop | ServiceControl::Shutdown if self.running => {
                self.running = false;
                vec![
                    ServiceAction::FreezeInput,
                    ServiceAction::ReleaseAllInput,
                    ServiceAction::StopHelper,
                    ServiceAction::CloseTransport,
                ]
            }
            ServiceControl::Start
            | ServiceControl::SessionChanged
            | ServiceControl::Stop
            | ServiceControl::Shutdown => Vec::new(),
        }
    }
}
