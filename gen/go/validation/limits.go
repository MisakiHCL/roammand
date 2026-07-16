// SPDX-License-Identifier: Apache-2.0

package validation

const (
	ProtocolMajorVersion        = uint32(1)
	MinimumProtocolMinorVersion = uint32(0)

	PairingRendezvousLifetimeMS       = uint64(120_000)
	MaxSignalingEnvelopeBytes         = 262_144
	MaxOpaqueSignalingEnvelopeBytes   = 262_144
	MaxSignalingServiceFrameBytes     = 263_168
	MaxReliableInputEnvelopeBytes     = 16_384
	MaxPointerFastEnvelopeBytes       = 256
	MaxLocalIPCFrameBytes             = 65_536
	MaxPrivilegedBridgeFrameBytes     = 262_144
	MaxHostAuthorizationSnapshotBytes = 1_048_576
	MaxControllerGrants               = 256
	MaxTrustedHosts                   = 256
	MaxTrustedHostSnapshotBytes       = 1_048_576
	MaxPairingCiphertextBytes         = 65_536
	MaxPrivilegedICEServers           = 8
	MaxPrivilegedICEURLsPerServer     = 16

	MaxDeviceNameUTF8Bytes        = 128
	MaxRequestIDUTF8Bytes         = 64
	MaxMessageKeyUTF8Bytes        = 128
	MaxSignalingEndpointUTF8Bytes = 2_048
	MaxSDPUTF8Bytes               = 131_072
	MaxICECandidateUTF8Bytes      = 4_096
	MaxSDPMidUTF8Bytes            = 64
	MaxTextInputUTF8Bytes         = 4_096
	MaxErrorDetailUTF8Bytes       = 256

	DeviceIDBytes                   = 32
	PublicKeyBytes                  = 32
	RendezvousIDBytes               = 16
	SessionIDBytes                  = 16
	NonceOrHashBytes                = 32
	SignatureBytes                  = 64
	DesktopPairingCodeBytes         = 8
	LocalIPCTokenBytes              = 32
	AgentInstanceIDBytes            = 16
	PrivilegedBridgeInstanceIDBytes = 16
	PrivilegedBridgeNonceBytes      = 32
	PrivilegedBridgeProofBytes      = 32
	PrivilegedLeaseIDBytes          = 16
	ExecutableSHA256Bytes           = 32
	PairingSASWordCount             = 4
)
