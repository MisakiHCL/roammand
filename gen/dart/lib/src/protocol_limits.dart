// SPDX-License-Identifier: Apache-2.0

const protocolMajorVersion = 1;
const minimumProtocolMinorVersion = 0;

const pairingRendezvousLifetimeMs = 120000;
const maxSignalingEnvelopeBytes = 262144;
const maxOpaqueSignalingEnvelopeBytes = 262144;
const maxSignalingServiceFrameBytes = 263168;
const maxReliableInputEnvelopeBytes = 16384;
const maxPointerFastEnvelopeBytes = 256;
const maxLocalIpcFrameBytes = 65536;
const maxPrivilegedBridgeFrameBytes = 262144;
const maxHostAuthorizationSnapshotBytes = 1048576;
const maxControllerGrants = 256;
const maxTrustedHosts = 256;
const maxTrustedHostSnapshotBytes = 1048576;
const maxPairingCiphertextBytes = 65536;
const maxPrivilegedIceServers = 8;
const maxPrivilegedIceUrlsPerServer = 16;

const maxDeviceNameUtf8Bytes = 128;
const maxRequestIdUtf8Bytes = 64;
const maxMessageKeyUtf8Bytes = 128;
const maxSignalingEndpointUtf8Bytes = 2048;
const maxSdpUtf8Bytes = 131072;
const maxIceCandidateUtf8Bytes = 4096;
const maxSdpMidUtf8Bytes = 64;
const maxTextInputUtf8Bytes = 4096;
const maxErrorDetailUtf8Bytes = 256;

const deviceIdBytes = 32;
const publicKeyBytes = 32;
const rendezvousIdBytes = 16;
const sessionIdBytes = 16;
const nonceOrHashBytes = 32;
const signatureBytes = 64;
const desktopPairingCodeBytes = 8;
const localIpcTokenBytes = 32;
const agentInstanceIdBytes = 16;
const privilegedBridgeInstanceIdBytes = 16;
const privilegedBridgeNonceBytes = 32;
const privilegedBridgeProofBytes = 32;
const privilegedLeaseIdBytes = 16;
const executableSha256Bytes = 32;
const pairingSasWordCount = 4;
