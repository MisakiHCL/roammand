#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly IMAGE="$(mktemp -t roammand-schema.XXXXXX)"
readonly REQUIRED_SYMBOLS=(
  ProtocolVersion
  Capability
  CapabilityNegotiation
  DevicePlatform
  PublicKeyAlgorithm
  DeviceIdentity
  ControllerGrant
  GrantRevocation
  GrantRevocationReason
  QrPairingRendezvous
  DesktopPairingRendezvous
  PairingHello
  PairingConfirmationData
  PairingDecision
  PairingMessage
  PairingDirection
  PairingInvitationKind
  HostPairingInvitation
  ControllerPairingHello
  HostPairingProof
  ControllerPairingReady
  PairingFinalDecision
  PairingPlaintext
  EncryptedPairingEnvelope
  TrustedHostBinding
  TrustedHostSnapshot
  HostPairingState
  HostPairingStatusSnapshot
  SessionPermission
  SessionOfferAuthentication
  SessionAnswerAuthentication
  SessionReconnectAuthentication
  SessionAuthentication
  SessionDescriptionType
  WebRtcSessionDescription
  IceCandidate
  WebRtcNegotiation
  ReliableInputEnvelope
  PointerFastEnvelope
  SessionState
  SessionStatus
  ErrorCode
  UnifiedError
  SignalingEnvelope
  SignalingClientFrame
  SignalingServerFrame
  RegisterDevice
  RegistrationAccepted
  CreatePairingRendezvous
  PairingRendezvousCreated
  JoinPairingRendezvous
  PairingRendezvousJoined
  RelayPairingEnvelope
  RoutedPairingEnvelope
  CompletePairingRendezvous
  PairingRendezvousClosed
  RelaySessionEnvelope
  RoutedSessionEnvelope
  LocalIpcChallenge
  LocalIpcAuthenticate
  LocalIpcAuthenticated
  GetHostStatusRequest
  HostStatus
  ListControllerGrantsRequest
  ControllerGrantList
  ControllerGrantView
  CreateControllerGrantRequest
  ControllerGrantCreated
  SignCanonicalTranscriptRequest
  CanonicalTranscriptSignature
  SignSessionOfferRequest
  SessionOfferSignature
  GetRemoteSessionStatusRequest
  RemoteSessionStatusSnapshot
  StartHostQrPairingRequest
  StartHostDesktopCodePairingRequest
  CancelHostPairingRequest
  GetHostPairingStatusRequest
  AcceptHostPairingRequest
  RejectHostPairingRequest
  SignPairingTranscriptRequest
  PairingTranscriptSignature
  HostPairingStateChangedEvent
  RevokeControllerGrantRequest
  ControllerGrantRevoked
  SessionTerminatedEvent
  HostAuthorizationSnapshot
  PrivilegedBridgeState
  InteractiveDesktopKind
  PrivilegedSessionDescriptor
  PrivilegedBridgeStatusSnapshot
  PrivilegedBridgeChallenge
  PrivilegedBridgeAuthenticate
  PrivilegedBridgeAuthenticated
  PrivilegedLease
  AcquirePrivilegedLeaseRequest
  RenewPrivilegedLeaseRequest
  ReleasePrivilegedLeaseRequest
  StartPrivilegedPeerRequest
  RestartPrivilegedPeerRequest
  AddPrivilegedIceCandidateRequest
  ClosePrivilegedPeerRequest
  PrivilegedReliableInputEvent
  PrivilegedFastPointerEvent
  PrivilegedInputCommand
  SendSecureAttentionRequest
  PrivilegedCommandAccepted
  PrivilegedBridgeClientFrame
  PrivilegedBridgeServerFrame
  EmergencyStopRemoteSessionRequest
  EmergencyStopRemoteSessionResult
  LocalIpcClientFrame
  LocalIpcServerFrame
)

require_text() {
  local path="$1"
  local expected="$2"

  if ! rg -q --fixed-strings "$expected" "$path"; then
    printf 'missing schema contract text in %s: %s\n' "$path" "$expected" >&2
    exit 1
  fi
}

require_pattern() {
  local path="$1"
  local expected="$2"

  if ! rg -q "$expected" "$path"; then
    printf 'missing schema contract pattern in %s: %s\n' "$path" "$expected" >&2
    exit 1
  fi
}

trap 'rm -f "$IMAGE"' EXIT
cd "$ROOT_DIR"
buf build -o "$IMAGE#format=json"

for symbol in "${REQUIRED_SYMBOLS[@]}"; do
  if ! rg -q "\"name\": ?\"${symbol}\"" "$IMAGE"; then
    printf 'missing schema symbol: %s\n' "$symbol" >&2
    exit 1
  fi
done

require_text schema/proto/roammand/v1/signaling_service.proto \
  'message SignalingClientFrame'
require_text schema/proto/roammand/v1/signaling_service.proto \
  'message SignalingServerFrame'
require_text schema/proto/roammand/v1/signaling_service.proto \
  'bytes opaque_envelope = 2;'
require_text schema/proto/roammand/v1/error.proto \
  'ERROR_CODE_INVALID_REQUEST = 17;'
require_pattern gen/go/validation/limits.go \
  'MaxSignalingServiceFrameBytes[[:space:]]*=[[:space:]]*263_168'
require_text schema/proto/roammand/v1/local_ipc.proto \
  'message LocalIpcClientFrame'
require_text schema/proto/roammand/v1/local_ipc.proto \
  'message LocalIpcServerFrame'
require_text schema/proto/roammand/v1/local_ipc.proto \
  'oneof payload {'
require_text schema/proto/roammand/v1/local_ipc.proto \
  'ProtocolVersion protocol_version = 1;'
require_text schema/proto/roammand/v1/local_ipc.proto \
  'UnifiedError error = 29;'
require_text schema/proto/roammand/v1/local_ipc.proto \
  'SignPairingTranscriptRequest sign_pairing_transcript = 24;'
require_text schema/proto/roammand/v1/local_ipc.proto \
  'PrivilegedBridgeStatusSnapshot privileged_bridge = 5;'
require_text schema/proto/roammand/v1/local_ipc.proto \
  'EmergencyStopRemoteSessionRequest emergency_stop_remote_session = 25;'
require_text schema/proto/roammand/v1/local_ipc.proto \
  'EmergencyStopRemoteSessionResult emergency_stop_remote_session_result = 33;'

require_text schema/proto/roammand/v1/privileged_bridge.proto \
  'message PrivilegedBridgeClientFrame'
require_text schema/proto/roammand/v1/privileged_bridge.proto \
  'message PrivilegedBridgeServerFrame'
require_text schema/proto/roammand/v1/privileged_bridge.proto \
  'bytes lease_id = 1;'
require_text schema/proto/roammand/v1/privileged_bridge.proto \
  'SendSecureAttentionRequest send_secure_attention = 26;'
require_text schema/proto/roammand/v1/privileged_bridge.proto \
  'PrivilegedCommandAccepted command_accepted = 27;'

if rg -n '(^|[[:space:]_])(private_key|secret_key|private_seed|keypair|grant_snapshot|pairing_secret|shell|general_command)[[:space:]]*=' \
  schema/proto/roammand/v1/privileged_bridge.proto; then
  printf 'privileged bridge schema exposes forbidden authority or secret material\n' >&2
  exit 1
fi

if rg -n '(^|[[:space:]])(private_key|secret_key|private_seed|keypair)[[:space:]]*=' \
  schema/proto/roammand/v1/local_ipc.proto; then
  printf 'local IPC schema exposes forbidden secret material\n' >&2
  exit 1
fi

printf 'schema contract ok\n'
