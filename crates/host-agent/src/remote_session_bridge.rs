// SPDX-License-Identifier: MPL-2.0

use roammand_host_webrtc::SessionConfig;
use roammand_privileged_bridge::proxy::{
    ProxyEvent, ProxyEvents, ProxyPartsFactory, ProxySessionContext,
};

use crate::{
    RemotePeerEvent, RemotePeerEventSource, RemoteSessionContext, RemoteSessionError,
    RemoteSessionFactory, RemoteSessionParts,
};

pub struct BridgeRemoteSessionFactory {
    factory: Box<dyn ProxyPartsFactory>,
}

impl BridgeRemoteSessionFactory {
    #[must_use]
    pub fn new(factory: Box<dyn ProxyPartsFactory>) -> Self {
        Self { factory }
    }
}

impl RemoteSessionFactory for BridgeRemoteSessionFactory {
    fn create(
        &mut self,
        config: &SessionConfig,
        context: &RemoteSessionContext,
    ) -> Result<RemoteSessionParts, RemoteSessionError> {
        let context = ProxySessionContext::new(
            context.session_id().to_vec(),
            context.permissions().to_vec(),
            context.controller_display_name().to_owned(),
        )
        .map_err(|_| RemoteSessionError::Peer)?;
        let (peer, input, events, _route_control) = self
            .factory
            .create(config, &context)
            .map_err(|_| RemoteSessionError::Peer)?
            .into_parts();
        Ok(RemoteSessionParts::new(
            Box::new(peer),
            Box::new(input),
            Box::new(BridgeEventSource(events)),
        ))
    }
}

struct BridgeEventSource(ProxyEvents);

impl RemotePeerEventSource for BridgeEventSource {
    fn try_recv(&self) -> Result<Option<RemotePeerEvent>, RemoteSessionError> {
        self.0
            .try_recv()
            .map(|event| event.map(map_event))
            .map_err(|_| RemoteSessionError::Peer)
    }
}

fn map_event(event: ProxyEvent) -> RemotePeerEvent {
    match event {
        ProxyEvent::Connected => RemotePeerEvent::Connected,
        ProxyEvent::Disconnected => RemotePeerEvent::Disconnected,
        ProxyEvent::Failed => RemotePeerEvent::Failed,
        ProxyEvent::LocalIceCandidate(value) => RemotePeerEvent::LocalIceCandidate(value),
        ProxyEvent::ReliableInput(value) => RemotePeerEvent::ReliableInput(value),
        ProxyEvent::FastPointer(value) => RemotePeerEvent::FastPointer(value),
    }
}
