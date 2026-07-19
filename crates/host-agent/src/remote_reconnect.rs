// SPDX-License-Identifier: MPL-2.0

use roammand_host_webrtc::{HostSessionState, PeerAnswer, PeerIceCandidate};
use roammand_protocol::roammand::v1::{
    ErrorCode, SessionAuthentication, SessionDescriptionType, SessionReconnectAuthentication,
    SessionState, SignalingEnvelope, WebRtcNegotiation, WebRtcSessionDescription,
    session_authentication, signaling_envelope, web_rtc_negotiation,
};

use crate::{
    RemoteSessionCoordinator, RemoteSessionError, RemoteSessionOutbound,
    remote_session::protocol_error_for,
    remote_session_state::{PENDING_SESSION_LIFETIME_MS, PendingSession},
    service::RemoteServiceError,
};

impl RemoteSessionCoordinator {
    pub(super) fn begin_active_reconnect(
        &mut self,
        now_unix_ms: u64,
    ) -> Result<(), RemoteSessionError> {
        let active = self.active.as_mut().ok_or(RemoteSessionError::Peer)?;
        active
            .session
            .begin_reconnect()
            .map_err(super::remote_session::map_peer_error)?;
        active
            .reconnect_deadline_unix_ms
            .get_or_insert(now_unix_ms.saturating_add(PENDING_SESSION_LIFETIME_MS));
        self.service
            .update_remote_status(
                active.session_id.clone(),
                active.controller_device_id.clone(),
                SessionState::Reconnecting,
                None,
            )
            .map_err(|_| RemoteSessionError::Service)
    }

    pub(super) fn expire_active_reconnect(
        &mut self,
        now_unix_ms: u64,
    ) -> Result<bool, RemoteSessionError> {
        let expired = self
            .active
            .as_ref()
            .and_then(|active| active.reconnect_deadline_unix_ms)
            .is_some_and(|deadline| now_unix_ms >= deadline);
        if expired {
            self.close_active(
                Some(super::remote_session::session_error(ErrorCode::IceFailed)),
                now_unix_ms,
            )?;
        }
        Ok(expired)
    }

    pub(super) fn handle_active_reconnect_envelope(
        &mut self,
        envelope: SignalingEnvelope,
        now_unix_ms: u64,
    ) -> Result<Vec<RemoteSessionOutbound>, RemoteSessionError> {
        let request_id = envelope.request_id.clone();
        let payload = envelope
            .payload
            .ok_or(RemoteSessionError::InvalidEnvelope)?;
        match payload {
            signaling_envelope::Payload::SessionAuthentication(authentication) => {
                let Some(session_authentication::Payload::Offer(offer)) = authentication.payload
                else {
                    return Err(RemoteSessionError::InvalidEnvelope);
                };
                self.begin_active_reconnect(now_unix_ms)?;
                let pending = self.prepare_active_reconnect(&request_id, now_unix_ms)?;
                if offer.controller_device_id != pending.controller_device_id
                    || offer.session_id != pending.session_id
                    || pending.authentication.replace(offer).is_some()
                {
                    return Err(RemoteSessionError::InvalidEnvelope);
                }
            }
            signaling_envelope::Payload::WebrtcNegotiation(negotiation) => {
                self.handle_active_negotiation(negotiation, &request_id, now_unix_ms)?;
            }
            _ => return Err(RemoteSessionError::InvalidEnvelope),
        }
        self.try_restart_active(now_unix_ms)
    }

    fn handle_active_negotiation(
        &mut self,
        negotiation: WebRtcNegotiation,
        request_id: &str,
        now_unix_ms: u64,
    ) -> Result<(), RemoteSessionError> {
        let active = self.active.as_ref().ok_or(RemoteSessionError::Peer)?;
        if negotiation.session_id != active.session_id {
            return Err(RemoteSessionError::InvalidEnvelope);
        }
        match negotiation
            .payload
            .ok_or(RemoteSessionError::InvalidEnvelope)?
        {
            web_rtc_negotiation::Payload::IceCandidate(candidate)
                if active.reconnect.is_none()
                    && matches!(
                        active.session.state(),
                        HostSessionState::Negotiating | HostSessionState::Connected
                    ) =>
            {
                self.active
                    .as_mut()
                    .ok_or(RemoteSessionError::Peer)?
                    .session
                    .add_remote_ice_candidate(&PeerIceCandidate {
                        candidate: candidate.candidate,
                        sdp_mid: candidate.sdp_mid,
                        sdp_m_line_index: candidate.sdp_m_line_index,
                    })
                    .map_err(|_| RemoteSessionError::Peer)
            }
            web_rtc_negotiation::Payload::IceCandidate(candidate) => self
                .prepare_active_reconnect(request_id, now_unix_ms)?
                .push_candidate(PeerIceCandidate {
                    candidate: candidate.candidate,
                    sdp_mid: candidate.sdp_mid,
                    sdp_m_line_index: candidate.sdp_m_line_index,
                }),
            web_rtc_negotiation::Payload::Description(description) => {
                if SessionDescriptionType::try_from(description.r#type)
                    != Ok(SessionDescriptionType::Offer)
                {
                    return Err(RemoteSessionError::InvalidEnvelope);
                }
                self.begin_active_reconnect(now_unix_ms)?;
                let pending = self.prepare_active_reconnect(request_id, now_unix_ms)?;
                if pending.description.replace(description).is_some() {
                    return Err(RemoteSessionError::InvalidEnvelope);
                }
                Ok(())
            }
            web_rtc_negotiation::Payload::EndOfCandidates(_) => Ok(()),
        }
    }

    fn prepare_active_reconnect(
        &mut self,
        request_id: &str,
        now_unix_ms: u64,
    ) -> Result<&mut PendingSession, RemoteSessionError> {
        let active = self.active.as_mut().ok_or(RemoteSessionError::Peer)?;
        let pending = active.reconnect.get_or_insert_with(|| {
            PendingSession::new(
                active.controller_device_id.clone(),
                active.session_id.clone(),
                request_id.to_owned(),
                now_unix_ms,
            )
        });
        request_id.clone_into(&mut pending.request_id);
        Ok(pending)
    }

    fn try_restart_active(
        &mut self,
        now_unix_ms: u64,
    ) -> Result<Vec<RemoteSessionOutbound>, RemoteSessionError> {
        let ready = self
            .active
            .as_ref()
            .and_then(|active| active.reconnect.as_ref())
            .is_some_and(PendingSession::is_ready);
        if !ready {
            return Ok(Vec::new());
        }
        let pending = self
            .active
            .as_mut()
            .and_then(|active| active.reconnect.take())
            .ok_or(RemoteSessionError::Service)?;
        let context = (
            pending.controller_device_id.clone(),
            pending.request_id.clone(),
        );
        match self.restart_active(pending, now_unix_ms) {
            Ok(restarted) => self.reconnect_outbound(restarted, &context.1, now_unix_ms),
            Err(error) => {
                let code = if error == RemoteSessionError::Peer {
                    ErrorCode::IceFailed
                } else {
                    protocol_error_for(error)
                };
                Ok(vec![self.error_outbound(
                    &context.0,
                    &context.1,
                    code,
                    now_unix_ms,
                )?])
            }
        }
    }

    fn restart_active(
        &mut self,
        pending: PendingSession,
        now_unix_ms: u64,
    ) -> Result<RestartedSession, RemoteSessionError> {
        let authentication = pending
            .authentication
            .ok_or(RemoteSessionError::InvalidEnvelope)?;
        let description = pending
            .description
            .ok_or(RemoteSessionError::InvalidEnvelope)?;
        let verified = self
            .service
            .verify_remote_offer(
                &mut self.verifier,
                &authentication,
                &description.sdp,
                &description.dtls_fingerprint_sha256,
                now_unix_ms,
            )
            .map_err(map_reconnect_service_error)?;
        let active = self.active.as_mut().ok_or(RemoteSessionError::Peer)?;
        if verified.controller.device_id != active.controller_device_id
            || verified.session_id != active.session_id
        {
            return Err(RemoteSessionError::Authentication);
        }
        let generation = active
            .reconnect_generation
            .checked_add(1)
            .ok_or(RemoteSessionError::Service)?;
        let answer = active
            .session
            .accept_reconnect_offer(&description.sdp)
            .map_err(|_| RemoteSessionError::Peer)?;
        let reconnect_authentication = self
            .service
            .sign_remote_reconnect(
                &authentication,
                &answer.sdp,
                &answer.dtls_fingerprint_sha256,
                generation,
            )
            .map_err(map_reconnect_service_error)?;
        for candidate in &pending.candidates {
            active
                .session
                .add_remote_ice_candidate(candidate)
                .map_err(|_| RemoteSessionError::Peer)?;
        }
        active.reconnect_generation = generation;
        Ok(RestartedSession {
            controller_device_id: active.controller_device_id.clone(),
            session_id: active.session_id.clone(),
            answer,
            authentication: reconnect_authentication,
        })
    }

    fn reconnect_outbound(
        &self,
        restarted: RestartedSession,
        request_id: &str,
        now_unix_ms: u64,
    ) -> Result<Vec<RemoteSessionOutbound>, RemoteSessionError> {
        let authentication =
            signaling_envelope::Payload::SessionAuthentication(SessionAuthentication {
                payload: Some(session_authentication::Payload::Reconnect(
                    restarted.authentication,
                )),
            });
        let description = signaling_envelope::Payload::WebrtcNegotiation(WebRtcNegotiation {
            session_id: restarted.session_id,
            payload: Some(web_rtc_negotiation::Payload::Description(
                WebRtcSessionDescription {
                    r#type: SessionDescriptionType::Answer as i32,
                    sdp: restarted.answer.sdp,
                    dtls_fingerprint_sha256: restarted.answer.dtls_fingerprint_sha256,
                },
            )),
        });
        Ok(vec![
            self.outbound(
                &restarted.controller_device_id,
                request_id,
                now_unix_ms,
                authentication,
            )?,
            self.outbound(
                &restarted.controller_device_id,
                request_id,
                now_unix_ms,
                description,
            )?,
        ])
    }
}

struct RestartedSession {
    controller_device_id: Vec<u8>,
    session_id: Vec<u8>,
    answer: PeerAnswer,
    authentication: SessionReconnectAuthentication,
}

const fn map_reconnect_service_error(error: RemoteServiceError) -> RemoteSessionError {
    super::remote_session::map_service_error(error)
}
