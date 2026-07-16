// SPDX-License-Identifier: Apache-2.0

// This is a generated file - do not edit.
//
// Generated from roammand/v1/privileged_bridge.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use privilegedBridgeStateDescriptor instead')
const PrivilegedBridgeState$json = {
  '1': 'PrivilegedBridgeState',
  '2': [
    {'1': 'PRIVILEGED_BRIDGE_STATE_UNSPECIFIED', '2': 0},
    {'1': 'PRIVILEGED_BRIDGE_STATE_NOT_INSTALLED', '2': 1},
    {'1': 'PRIVILEGED_BRIDGE_STATE_APPROVAL_REQUIRED', '2': 2},
    {'1': 'PRIVILEGED_BRIDGE_STATE_PERMISSION_REQUIRED', '2': 3},
    {'1': 'PRIVILEGED_BRIDGE_STATE_USER_SESSION_ONLY', '2': 4},
    {'1': 'PRIVILEGED_BRIDGE_STATE_READY', '2': 5},
    {'1': 'PRIVILEGED_BRIDGE_STATE_TRANSITIONING', '2': 6},
    {'1': 'PRIVILEGED_BRIDGE_STATE_CONTROLLED', '2': 7},
    {'1': 'PRIVILEGED_BRIDGE_STATE_FAILED', '2': 8},
  ],
};

/// Descriptor for `PrivilegedBridgeState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List privilegedBridgeStateDescriptor = $convert.base64Decode(
    'ChVQcml2aWxlZ2VkQnJpZGdlU3RhdGUSJwojUFJJVklMRUdFRF9CUklER0VfU1RBVEVfVU5TUE'
    'VDSUZJRUQQABIpCiVQUklWSUxFR0VEX0JSSURHRV9TVEFURV9OT1RfSU5TVEFMTEVEEAESLQop'
    'UFJJVklMRUdFRF9CUklER0VfU1RBVEVfQVBQUk9WQUxfUkVRVUlSRUQQAhIvCitQUklWSUxFR0'
    'VEX0JSSURHRV9TVEFURV9QRVJNSVNTSU9OX1JFUVVJUkVEEAMSLQopUFJJVklMRUdFRF9CUklE'
    'R0VfU1RBVEVfVVNFUl9TRVNTSU9OX09OTFkQBBIhCh1QUklWSUxFR0VEX0JSSURHRV9TVEFURV'
    '9SRUFEWRAFEikKJVBSSVZJTEVHRURfQlJJREdFX1NUQVRFX1RSQU5TSVRJT05JTkcQBhImCiJQ'
    'UklWSUxFR0VEX0JSSURHRV9TVEFURV9DT05UUk9MTEVEEAcSIgoeUFJJVklMRUdFRF9CUklER0'
    'VfU1RBVEVfRkFJTEVEEAg=');

@$core.Deprecated('Use interactiveDesktopKindDescriptor instead')
const InteractiveDesktopKind$json = {
  '1': 'InteractiveDesktopKind',
  '2': [
    {'1': 'INTERACTIVE_DESKTOP_KIND_UNSPECIFIED', '2': 0},
    {'1': 'INTERACTIVE_DESKTOP_KIND_NORMAL', '2': 1},
    {'1': 'INTERACTIVE_DESKTOP_KIND_LOCKED_LOGIN', '2': 2},
    {'1': 'INTERACTIVE_DESKTOP_KIND_SECURE', '2': 3},
    {'1': 'INTERACTIVE_DESKTOP_KIND_UNAVAILABLE', '2': 4},
  ],
};

/// Descriptor for `InteractiveDesktopKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List interactiveDesktopKindDescriptor = $convert.base64Decode(
    'ChZJbnRlcmFjdGl2ZURlc2t0b3BLaW5kEigKJElOVEVSQUNUSVZFX0RFU0tUT1BfS0lORF9VTl'
    'NQRUNJRklFRBAAEiMKH0lOVEVSQUNUSVZFX0RFU0tUT1BfS0lORF9OT1JNQUwQARIpCiVJTlRF'
    'UkFDVElWRV9ERVNLVE9QX0tJTkRfTE9DS0VEX0xPR0lOEAISIwofSU5URVJBQ1RJVkVfREVTS1'
    'RPUF9LSU5EX1NFQ1VSRRADEigKJElOVEVSQUNUSVZFX0RFU0tUT1BfS0lORF9VTkFWQUlMQUJM'
    'RRAE');

@$core.Deprecated('Use privilegedBridgeRoleDescriptor instead')
const PrivilegedBridgeRole$json = {
  '1': 'PrivilegedBridgeRole',
  '2': [
    {'1': 'PRIVILEGED_BRIDGE_ROLE_UNSPECIFIED', '2': 0},
    {'1': 'PRIVILEGED_BRIDGE_ROLE_HOST_AGENT', '2': 1},
    {'1': 'PRIVILEGED_BRIDGE_ROLE_SESSION_HELPER', '2': 2},
  ],
};

/// Descriptor for `PrivilegedBridgeRole`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List privilegedBridgeRoleDescriptor = $convert.base64Decode(
    'ChRQcml2aWxlZ2VkQnJpZGdlUm9sZRImCiJQUklWSUxFR0VEX0JSSURHRV9ST0xFX1VOU1BFQ0'
    'lGSUVEEAASJQohUFJJVklMRUdFRF9CUklER0VfUk9MRV9IT1NUX0FHRU5UEAESKQolUFJJVklM'
    'RUdFRF9CUklER0VfUk9MRV9TRVNTSU9OX0hFTFBFUhAC');

@$core.Deprecated('Use privilegedIceTransportPolicyDescriptor instead')
const PrivilegedIceTransportPolicy$json = {
  '1': 'PrivilegedIceTransportPolicy',
  '2': [
    {'1': 'PRIVILEGED_ICE_TRANSPORT_POLICY_UNSPECIFIED', '2': 0},
    {'1': 'PRIVILEGED_ICE_TRANSPORT_POLICY_ALL', '2': 1},
    {'1': 'PRIVILEGED_ICE_TRANSPORT_POLICY_RELAY', '2': 2},
  ],
};

/// Descriptor for `PrivilegedIceTransportPolicy`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List privilegedIceTransportPolicyDescriptor = $convert.base64Decode(
    'ChxQcml2aWxlZ2VkSWNlVHJhbnNwb3J0UG9saWN5Ei8KK1BSSVZJTEVHRURfSUNFX1RSQU5TUE'
    '9SVF9QT0xJQ1lfVU5TUEVDSUZJRUQQABInCiNQUklWSUxFR0VEX0lDRV9UUkFOU1BPUlRfUE9M'
    'SUNZX0FMTBABEikKJVBSSVZJTEVHRURfSUNFX1RSQU5TUE9SVF9QT0xJQ1lfUkVMQVkQAg==');

@$core.Deprecated('Use privilegedPeerStateDescriptor instead')
const PrivilegedPeerState$json = {
  '1': 'PrivilegedPeerState',
  '2': [
    {'1': 'PRIVILEGED_PEER_STATE_UNSPECIFIED', '2': 0},
    {'1': 'PRIVILEGED_PEER_STATE_NEW', '2': 1},
    {'1': 'PRIVILEGED_PEER_STATE_NEGOTIATING', '2': 2},
    {'1': 'PRIVILEGED_PEER_STATE_CONNECTED', '2': 3},
    {'1': 'PRIVILEGED_PEER_STATE_DISCONNECTED', '2': 4},
    {'1': 'PRIVILEGED_PEER_STATE_FAILED', '2': 5},
    {'1': 'PRIVILEGED_PEER_STATE_CLOSED', '2': 6},
  ],
};

/// Descriptor for `PrivilegedPeerState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List privilegedPeerStateDescriptor = $convert.base64Decode(
    'ChNQcml2aWxlZ2VkUGVlclN0YXRlEiUKIVBSSVZJTEVHRURfUEVFUl9TVEFURV9VTlNQRUNJRk'
    'lFRBAAEh0KGVBSSVZJTEVHRURfUEVFUl9TVEFURV9ORVcQARIlCiFQUklWSUxFR0VEX1BFRVJf'
    'U1RBVEVfTkVHT1RJQVRJTkcQAhIjCh9QUklWSUxFR0VEX1BFRVJfU1RBVEVfQ09OTkVDVEVEEA'
    'MSJgoiUFJJVklMRUdFRF9QRUVSX1NUQVRFX0RJU0NPTk5FQ1RFRBAEEiAKHFBSSVZJTEVHRURf'
    'UEVFUl9TVEFURV9GQUlMRUQQBRIgChxQUklWSUxFR0VEX1BFRVJfU1RBVEVfQ0xPU0VEEAY=');

@$core.Deprecated('Use privilegedSessionDescriptorDescriptor instead')
const PrivilegedSessionDescriptor$json = {
  '1': 'PrivilegedSessionDescriptor',
  '2': [
    {
      '1': 'platform',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.roammand.v1.DevicePlatform',
      '10': 'platform'
    },
    {'1': 'os_session_id', '3': 2, '4': 1, '5': 4, '10': 'osSessionId'},
    {
      '1': 'desktop_kind',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.roammand.v1.InteractiveDesktopKind',
      '10': 'desktopKind'
    },
    {'1': 'generation', '3': 4, '4': 1, '5': 4, '10': 'generation'},
  ],
};

/// Descriptor for `PrivilegedSessionDescriptor`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List privilegedSessionDescriptorDescriptor = $convert.base64Decode(
    'ChtQcml2aWxlZ2VkU2Vzc2lvbkRlc2NyaXB0b3ISNwoIcGxhdGZvcm0YASABKA4yGy5yb2FtbW'
    'FuZC52MS5EZXZpY2VQbGF0Zm9ybVIIcGxhdGZvcm0SIgoNb3Nfc2Vzc2lvbl9pZBgCIAEoBFIL'
    'b3NTZXNzaW9uSWQSRgoMZGVza3RvcF9raW5kGAMgASgOMiMucm9hbW1hbmQudjEuSW50ZXJhY3'
    'RpdmVEZXNrdG9wS2luZFILZGVza3RvcEtpbmQSHgoKZ2VuZXJhdGlvbhgEIAEoBFIKZ2VuZXJh'
    'dGlvbg==');

@$core.Deprecated('Use privilegedBridgeStatusSnapshotDescriptor instead')
const PrivilegedBridgeStatusSnapshot$json = {
  '1': 'PrivilegedBridgeStatusSnapshot',
  '2': [
    {
      '1': 'state',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.roammand.v1.PrivilegedBridgeState',
      '10': 'state'
    },
    {
      '1': 'interactive_session',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PrivilegedSessionDescriptor',
      '10': 'interactiveSession'
    },
    {'1': 'helper_connected', '3': 3, '4': 1, '5': 8, '10': 'helperConnected'},
    {
      '1': 'active_controller_display_name',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'activeControllerDisplayName'
    },
    {
      '1': 'error',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.UnifiedError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `PrivilegedBridgeStatusSnapshot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List privilegedBridgeStatusSnapshotDescriptor = $convert.base64Decode(
    'Ch5Qcml2aWxlZ2VkQnJpZGdlU3RhdHVzU25hcHNob3QSOAoFc3RhdGUYASABKA4yIi5yb2FtbW'
    'FuZC52MS5Qcml2aWxlZ2VkQnJpZGdlU3RhdGVSBXN0YXRlElkKE2ludGVyYWN0aXZlX3Nlc3Np'
    'b24YAiABKAsyKC5yb2FtbWFuZC52MS5Qcml2aWxlZ2VkU2Vzc2lvbkRlc2NyaXB0b3JSEmludG'
    'VyYWN0aXZlU2Vzc2lvbhIpChBoZWxwZXJfY29ubmVjdGVkGAMgASgIUg9oZWxwZXJDb25uZWN0'
    'ZWQSQwoeYWN0aXZlX2NvbnRyb2xsZXJfZGlzcGxheV9uYW1lGAQgASgJUhthY3RpdmVDb250cm'
    '9sbGVyRGlzcGxheU5hbWUSLwoFZXJyb3IYBSABKAsyGS5yb2FtbWFuZC52MS5VbmlmaWVkRXJy'
    'b3JSBWVycm9y');

@$core.Deprecated('Use privilegedBridgeChallengeDescriptor instead')
const PrivilegedBridgeChallenge$json = {
  '1': 'PrivilegedBridgeChallenge',
  '2': [
    {
      '1': 'broker_instance_id',
      '3': 1,
      '4': 1,
      '5': 12,
      '10': 'brokerInstanceId'
    },
    {'1': 'server_nonce', '3': 2, '4': 1, '5': 12, '10': 'serverNonce'},
  ],
};

/// Descriptor for `PrivilegedBridgeChallenge`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List privilegedBridgeChallengeDescriptor =
    $convert.base64Decode(
        'ChlQcml2aWxlZ2VkQnJpZGdlQ2hhbGxlbmdlEiwKEmJyb2tlcl9pbnN0YW5jZV9pZBgBIAEoDF'
        'IQYnJva2VySW5zdGFuY2VJZBIhCgxzZXJ2ZXJfbm9uY2UYAiABKAxSC3NlcnZlck5vbmNl');

@$core.Deprecated('Use privilegedBridgeAuthenticateDescriptor instead')
const PrivilegedBridgeAuthenticate$json = {
  '1': 'PrivilegedBridgeAuthenticate',
  '2': [
    {
      '1': 'role',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.roammand.v1.PrivilegedBridgeRole',
      '10': 'role'
    },
    {'1': 'client_nonce', '3': 2, '4': 1, '5': 12, '10': 'clientNonce'},
    {'1': 'client_proof', '3': 3, '4': 1, '5': 12, '10': 'clientProof'},
    {
      '1': 'executable_sha256',
      '3': 4,
      '4': 1,
      '5': 12,
      '10': 'executableSha256'
    },
    {'1': 'os_session_id', '3': 5, '4': 1, '5': 4, '10': 'osSessionId'},
  ],
};

/// Descriptor for `PrivilegedBridgeAuthenticate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List privilegedBridgeAuthenticateDescriptor = $convert.base64Decode(
    'ChxQcml2aWxlZ2VkQnJpZGdlQXV0aGVudGljYXRlEjUKBHJvbGUYASABKA4yIS5yb2FtbWFuZC'
    '52MS5Qcml2aWxlZ2VkQnJpZGdlUm9sZVIEcm9sZRIhCgxjbGllbnRfbm9uY2UYAiABKAxSC2Ns'
    'aWVudE5vbmNlEiEKDGNsaWVudF9wcm9vZhgDIAEoDFILY2xpZW50UHJvb2YSKwoRZXhlY3V0YW'
    'JsZV9zaGEyNTYYBCABKAxSEGV4ZWN1dGFibGVTaGEyNTYSIgoNb3Nfc2Vzc2lvbl9pZBgFIAEo'
    'BFILb3NTZXNzaW9uSWQ=');

@$core.Deprecated('Use privilegedBridgeAuthenticatedDescriptor instead')
const PrivilegedBridgeAuthenticated$json = {
  '1': 'PrivilegedBridgeAuthenticated',
  '2': [
    {'1': 'server_proof', '3': 1, '4': 1, '5': 12, '10': 'serverProof'},
  ],
};

/// Descriptor for `PrivilegedBridgeAuthenticated`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List privilegedBridgeAuthenticatedDescriptor =
    $convert.base64Decode(
        'Ch1Qcml2aWxlZ2VkQnJpZGdlQXV0aGVudGljYXRlZBIhCgxzZXJ2ZXJfcHJvb2YYASABKAxSC3'
        'NlcnZlclByb29m');

@$core.Deprecated('Use privilegedLeaseDescriptor instead')
const PrivilegedLease$json = {
  '1': 'PrivilegedLease',
  '2': [
    {'1': 'lease_id', '3': 1, '4': 1, '5': 12, '10': 'leaseId'},
    {'1': 'generation', '3': 2, '4': 1, '5': 4, '10': 'generation'},
    {'1': 'issued_at_unix_ms', '3': 3, '4': 1, '5': 4, '10': 'issuedAtUnixMs'},
    {
      '1': 'expires_at_unix_ms',
      '3': 4,
      '4': 1,
      '5': 4,
      '10': 'expiresAtUnixMs'
    },
    {'1': 'session_id', '3': 5, '4': 1, '5': 12, '10': 'sessionId'},
    {
      '1': 'permissions',
      '3': 6,
      '4': 3,
      '5': 14,
      '6': '.roammand.v1.SessionPermission',
      '10': 'permissions'
    },
    {
      '1': 'controller_display_name',
      '3': 7,
      '4': 1,
      '5': 9,
      '10': 'controllerDisplayName'
    },
  ],
};

/// Descriptor for `PrivilegedLease`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List privilegedLeaseDescriptor = $convert.base64Decode(
    'Cg9Qcml2aWxlZ2VkTGVhc2USGQoIbGVhc2VfaWQYASABKAxSB2xlYXNlSWQSHgoKZ2VuZXJhdG'
    'lvbhgCIAEoBFIKZ2VuZXJhdGlvbhIpChFpc3N1ZWRfYXRfdW5peF9tcxgDIAEoBFIOaXNzdWVk'
    'QXRVbml4TXMSKwoSZXhwaXJlc19hdF91bml4X21zGAQgASgEUg9leHBpcmVzQXRVbml4TXMSHQ'
    'oKc2Vzc2lvbl9pZBgFIAEoDFIJc2Vzc2lvbklkEkAKC3Blcm1pc3Npb25zGAYgAygOMh4ucm9h'
    'bW1hbmQudjEuU2Vzc2lvblBlcm1pc3Npb25SC3Blcm1pc3Npb25zEjYKF2NvbnRyb2xsZXJfZG'
    'lzcGxheV9uYW1lGAcgASgJUhVjb250cm9sbGVyRGlzcGxheU5hbWU=');

@$core.Deprecated('Use acquirePrivilegedLeaseRequestDescriptor instead')
const AcquirePrivilegedLeaseRequest$json = {
  '1': 'AcquirePrivilegedLeaseRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 12, '10': 'sessionId'},
    {'1': 'generation', '3': 2, '4': 1, '5': 4, '10': 'generation'},
    {
      '1': 'permissions',
      '3': 3,
      '4': 3,
      '5': 14,
      '6': '.roammand.v1.SessionPermission',
      '10': 'permissions'
    },
    {
      '1': 'controller_display_name',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'controllerDisplayName'
    },
  ],
};

/// Descriptor for `AcquirePrivilegedLeaseRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List acquirePrivilegedLeaseRequestDescriptor = $convert.base64Decode(
    'Ch1BY3F1aXJlUHJpdmlsZWdlZExlYXNlUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgMUglzZX'
    'NzaW9uSWQSHgoKZ2VuZXJhdGlvbhgCIAEoBFIKZ2VuZXJhdGlvbhJACgtwZXJtaXNzaW9ucxgD'
    'IAMoDjIeLnJvYW1tYW5kLnYxLlNlc3Npb25QZXJtaXNzaW9uUgtwZXJtaXNzaW9ucxI2Chdjb2'
    '50cm9sbGVyX2Rpc3BsYXlfbmFtZRgEIAEoCVIVY29udHJvbGxlckRpc3BsYXlOYW1l');

@$core.Deprecated('Use renewPrivilegedLeaseRequestDescriptor instead')
const RenewPrivilegedLeaseRequest$json = {
  '1': 'RenewPrivilegedLeaseRequest',
  '2': [
    {'1': 'lease_id', '3': 1, '4': 1, '5': 12, '10': 'leaseId'},
    {'1': 'generation', '3': 2, '4': 1, '5': 4, '10': 'generation'},
  ],
};

/// Descriptor for `RenewPrivilegedLeaseRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List renewPrivilegedLeaseRequestDescriptor =
    $convert.base64Decode(
        'ChtSZW5ld1ByaXZpbGVnZWRMZWFzZVJlcXVlc3QSGQoIbGVhc2VfaWQYASABKAxSB2xlYXNlSW'
        'QSHgoKZ2VuZXJhdGlvbhgCIAEoBFIKZ2VuZXJhdGlvbg==');

@$core.Deprecated('Use releasePrivilegedLeaseRequestDescriptor instead')
const ReleasePrivilegedLeaseRequest$json = {
  '1': 'ReleasePrivilegedLeaseRequest',
  '2': [
    {'1': 'lease_id', '3': 1, '4': 1, '5': 12, '10': 'leaseId'},
    {'1': 'generation', '3': 2, '4': 1, '5': 4, '10': 'generation'},
  ],
};

/// Descriptor for `ReleasePrivilegedLeaseRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List releasePrivilegedLeaseRequestDescriptor =
    $convert.base64Decode(
        'Ch1SZWxlYXNlUHJpdmlsZWdlZExlYXNlUmVxdWVzdBIZCghsZWFzZV9pZBgBIAEoDFIHbGVhc2'
        'VJZBIeCgpnZW5lcmF0aW9uGAIgASgEUgpnZW5lcmF0aW9u');

@$core.Deprecated('Use privilegedIceServerDescriptor instead')
const PrivilegedIceServer$json = {
  '1': 'PrivilegedIceServer',
  '2': [
    {'1': 'urls', '3': 1, '4': 3, '5': 9, '10': 'urls'},
    {'1': 'username', '3': 2, '4': 1, '5': 9, '10': 'username'},
    {'1': 'credential', '3': 3, '4': 1, '5': 9, '10': 'credential'},
  ],
};

/// Descriptor for `PrivilegedIceServer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List privilegedIceServerDescriptor = $convert.base64Decode(
    'ChNQcml2aWxlZ2VkSWNlU2VydmVyEhIKBHVybHMYASADKAlSBHVybHMSGgoIdXNlcm5hbWUYAi'
    'ABKAlSCHVzZXJuYW1lEh4KCmNyZWRlbnRpYWwYAyABKAlSCmNyZWRlbnRpYWw=');

@$core.Deprecated('Use privilegedPeerConfigurationDescriptor instead')
const PrivilegedPeerConfiguration$json = {
  '1': 'PrivilegedPeerConfiguration',
  '2': [
    {
      '1': 'ice_transport_policy',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.roammand.v1.PrivilegedIceTransportPolicy',
      '10': 'iceTransportPolicy'
    },
    {
      '1': 'ice_servers',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.roammand.v1.PrivilegedIceServer',
      '10': 'iceServers'
    },
  ],
};

/// Descriptor for `PrivilegedPeerConfiguration`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List privilegedPeerConfigurationDescriptor = $convert.base64Decode(
    'ChtQcml2aWxlZ2VkUGVlckNvbmZpZ3VyYXRpb24SWwoUaWNlX3RyYW5zcG9ydF9wb2xpY3kYAS'
    'ABKA4yKS5yb2FtbWFuZC52MS5Qcml2aWxlZ2VkSWNlVHJhbnNwb3J0UG9saWN5UhJpY2VUcmFu'
    'c3BvcnRQb2xpY3kSQQoLaWNlX3NlcnZlcnMYAiADKAsyIC5yb2FtbWFuZC52MS5Qcml2aWxlZ2'
    'VkSWNlU2VydmVyUgppY2VTZXJ2ZXJz');

@$core.Deprecated('Use startPrivilegedPeerRequestDescriptor instead')
const StartPrivilegedPeerRequest$json = {
  '1': 'StartPrivilegedPeerRequest',
  '2': [
    {'1': 'lease_id', '3': 1, '4': 1, '5': 12, '10': 'leaseId'},
    {'1': 'generation', '3': 2, '4': 1, '5': 4, '10': 'generation'},
    {
      '1': 'configuration',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PrivilegedPeerConfiguration',
      '10': 'configuration'
    },
    {
      '1': 'offer',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.WebRtcSessionDescription',
      '10': 'offer'
    },
    {
      '1': 'controller_display_name',
      '3': 5,
      '4': 1,
      '5': 9,
      '10': 'controllerDisplayName'
    },
  ],
};

/// Descriptor for `StartPrivilegedPeerRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startPrivilegedPeerRequestDescriptor = $convert.base64Decode(
    'ChpTdGFydFByaXZpbGVnZWRQZWVyUmVxdWVzdBIZCghsZWFzZV9pZBgBIAEoDFIHbGVhc2VJZB'
    'IeCgpnZW5lcmF0aW9uGAIgASgEUgpnZW5lcmF0aW9uEk4KDWNvbmZpZ3VyYXRpb24YAyABKAsy'
    'KC5yb2FtbWFuZC52MS5Qcml2aWxlZ2VkUGVlckNvbmZpZ3VyYXRpb25SDWNvbmZpZ3VyYXRpb2'
    '4SOwoFb2ZmZXIYBCABKAsyJS5yb2FtbWFuZC52MS5XZWJSdGNTZXNzaW9uRGVzY3JpcHRpb25S'
    'BW9mZmVyEjYKF2NvbnRyb2xsZXJfZGlzcGxheV9uYW1lGAUgASgJUhVjb250cm9sbGVyRGlzcG'
    'xheU5hbWU=');

@$core.Deprecated('Use restartPrivilegedPeerRequestDescriptor instead')
const RestartPrivilegedPeerRequest$json = {
  '1': 'RestartPrivilegedPeerRequest',
  '2': [
    {'1': 'lease_id', '3': 1, '4': 1, '5': 12, '10': 'leaseId'},
    {'1': 'generation', '3': 2, '4': 1, '5': 4, '10': 'generation'},
    {
      '1': 'configuration',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PrivilegedPeerConfiguration',
      '10': 'configuration'
    },
    {
      '1': 'offer',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.WebRtcSessionDescription',
      '10': 'offer'
    },
    {
      '1': 'controller_display_name',
      '3': 5,
      '4': 1,
      '5': 9,
      '10': 'controllerDisplayName'
    },
  ],
};

/// Descriptor for `RestartPrivilegedPeerRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List restartPrivilegedPeerRequestDescriptor = $convert.base64Decode(
    'ChxSZXN0YXJ0UHJpdmlsZWdlZFBlZXJSZXF1ZXN0EhkKCGxlYXNlX2lkGAEgASgMUgdsZWFzZU'
    'lkEh4KCmdlbmVyYXRpb24YAiABKARSCmdlbmVyYXRpb24STgoNY29uZmlndXJhdGlvbhgDIAEo'
    'CzIoLnJvYW1tYW5kLnYxLlByaXZpbGVnZWRQZWVyQ29uZmlndXJhdGlvblINY29uZmlndXJhdG'
    'lvbhI7CgVvZmZlchgEIAEoCzIlLnJvYW1tYW5kLnYxLldlYlJ0Y1Nlc3Npb25EZXNjcmlwdGlv'
    'blIFb2ZmZXISNgoXY29udHJvbGxlcl9kaXNwbGF5X25hbWUYBSABKAlSFWNvbnRyb2xsZXJEaX'
    'NwbGF5TmFtZQ==');

@$core.Deprecated('Use addPrivilegedIceCandidateRequestDescriptor instead')
const AddPrivilegedIceCandidateRequest$json = {
  '1': 'AddPrivilegedIceCandidateRequest',
  '2': [
    {'1': 'lease_id', '3': 1, '4': 1, '5': 12, '10': 'leaseId'},
    {'1': 'generation', '3': 2, '4': 1, '5': 4, '10': 'generation'},
    {
      '1': 'candidate',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.IceCandidate',
      '10': 'candidate'
    },
  ],
};

/// Descriptor for `AddPrivilegedIceCandidateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addPrivilegedIceCandidateRequestDescriptor =
    $convert.base64Decode(
        'CiBBZGRQcml2aWxlZ2VkSWNlQ2FuZGlkYXRlUmVxdWVzdBIZCghsZWFzZV9pZBgBIAEoDFIHbG'
        'Vhc2VJZBIeCgpnZW5lcmF0aW9uGAIgASgEUgpnZW5lcmF0aW9uEjcKCWNhbmRpZGF0ZRgDIAEo'
        'CzIZLnJvYW1tYW5kLnYxLkljZUNhbmRpZGF0ZVIJY2FuZGlkYXRl');

@$core.Deprecated('Use closePrivilegedPeerRequestDescriptor instead')
const ClosePrivilegedPeerRequest$json = {
  '1': 'ClosePrivilegedPeerRequest',
  '2': [
    {'1': 'lease_id', '3': 1, '4': 1, '5': 12, '10': 'leaseId'},
    {'1': 'generation', '3': 2, '4': 1, '5': 4, '10': 'generation'},
  ],
};

/// Descriptor for `ClosePrivilegedPeerRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List closePrivilegedPeerRequestDescriptor =
    $convert.base64Decode(
        'ChpDbG9zZVByaXZpbGVnZWRQZWVyUmVxdWVzdBIZCghsZWFzZV9pZBgBIAEoDFIHbGVhc2VJZB'
        'IeCgpnZW5lcmF0aW9uGAIgASgEUgpnZW5lcmF0aW9u');

@$core.Deprecated('Use privilegedReliableInputEventDescriptor instead')
const PrivilegedReliableInputEvent$json = {
  '1': 'PrivilegedReliableInputEvent',
  '2': [
    {'1': 'lease_id', '3': 1, '4': 1, '5': 12, '10': 'leaseId'},
    {'1': 'generation', '3': 2, '4': 1, '5': 4, '10': 'generation'},
    {'1': 'encoded_envelope', '3': 3, '4': 1, '5': 12, '10': 'encodedEnvelope'},
  ],
};

/// Descriptor for `PrivilegedReliableInputEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List privilegedReliableInputEventDescriptor =
    $convert.base64Decode(
        'ChxQcml2aWxlZ2VkUmVsaWFibGVJbnB1dEV2ZW50EhkKCGxlYXNlX2lkGAEgASgMUgdsZWFzZU'
        'lkEh4KCmdlbmVyYXRpb24YAiABKARSCmdlbmVyYXRpb24SKQoQZW5jb2RlZF9lbnZlbG9wZRgD'
        'IAEoDFIPZW5jb2RlZEVudmVsb3Bl');

@$core.Deprecated('Use privilegedFastPointerEventDescriptor instead')
const PrivilegedFastPointerEvent$json = {
  '1': 'PrivilegedFastPointerEvent',
  '2': [
    {'1': 'lease_id', '3': 1, '4': 1, '5': 12, '10': 'leaseId'},
    {'1': 'generation', '3': 2, '4': 1, '5': 4, '10': 'generation'},
    {'1': 'encoded_envelope', '3': 3, '4': 1, '5': 12, '10': 'encodedEnvelope'},
  ],
};

/// Descriptor for `PrivilegedFastPointerEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List privilegedFastPointerEventDescriptor =
    $convert.base64Decode(
        'ChpQcml2aWxlZ2VkRmFzdFBvaW50ZXJFdmVudBIZCghsZWFzZV9pZBgBIAEoDFIHbGVhc2VJZB'
        'IeCgpnZW5lcmF0aW9uGAIgASgEUgpnZW5lcmF0aW9uEikKEGVuY29kZWRfZW52ZWxvcGUYAyAB'
        'KAxSD2VuY29kZWRFbnZlbG9wZQ==');

@$core.Deprecated('Use privilegedInputCommandDescriptor instead')
const PrivilegedInputCommand$json = {
  '1': 'PrivilegedInputCommand',
  '2': [
    {'1': 'lease_id', '3': 1, '4': 1, '5': 12, '10': 'leaseId'},
    {'1': 'generation', '3': 2, '4': 1, '5': 4, '10': 'generation'},
    {
      '1': 'pointer_button',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PointerButtonEvent',
      '9': 0,
      '10': 'pointerButton'
    },
    {
      '1': 'keyboard',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.KeyboardEvent',
      '9': 0,
      '10': 'keyboard'
    },
    {
      '1': 'text',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.TextInputEvent',
      '9': 0,
      '10': 'text'
    },
    {
      '1': 'pointer_move',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PointerMoveEvent',
      '9': 0,
      '10': 'pointerMove'
    },
    {
      '1': 'pointer_scroll',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PointerScrollEvent',
      '9': 0,
      '10': 'pointerScroll'
    },
    {
      '1': 'release_all',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.ReleaseAllInput',
      '9': 0,
      '10': 'releaseAll'
    },
  ],
  '8': [
    {'1': 'input'},
  ],
};

/// Descriptor for `PrivilegedInputCommand`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List privilegedInputCommandDescriptor = $convert.base64Decode(
    'ChZQcml2aWxlZ2VkSW5wdXRDb21tYW5kEhkKCGxlYXNlX2lkGAEgASgMUgdsZWFzZUlkEh4KCm'
    'dlbmVyYXRpb24YAiABKARSCmdlbmVyYXRpb24SSAoOcG9pbnRlcl9idXR0b24YCiABKAsyHy5y'
    'b2FtbWFuZC52MS5Qb2ludGVyQnV0dG9uRXZlbnRIAFINcG9pbnRlckJ1dHRvbhI4CghrZXlib2'
    'FyZBgLIAEoCzIaLnJvYW1tYW5kLnYxLktleWJvYXJkRXZlbnRIAFIIa2V5Ym9hcmQSMQoEdGV4'
    'dBgMIAEoCzIbLnJvYW1tYW5kLnYxLlRleHRJbnB1dEV2ZW50SABSBHRleHQSQgoMcG9pbnRlcl'
    '9tb3ZlGA0gASgLMh0ucm9hbW1hbmQudjEuUG9pbnRlck1vdmVFdmVudEgAUgtwb2ludGVyTW92'
    'ZRJICg5wb2ludGVyX3Njcm9sbBgOIAEoCzIfLnJvYW1tYW5kLnYxLlBvaW50ZXJTY3JvbGxFdm'
    'VudEgAUg1wb2ludGVyU2Nyb2xsEj8KC3JlbGVhc2VfYWxsGA8gASgLMhwucm9hbW1hbmQudjEu'
    'UmVsZWFzZUFsbElucHV0SABSCnJlbGVhc2VBbGxCBwoFaW5wdXQ=');

@$core.Deprecated('Use sendSecureAttentionRequestDescriptor instead')
const SendSecureAttentionRequest$json = {
  '1': 'SendSecureAttentionRequest',
  '2': [
    {'1': 'lease_id', '3': 1, '4': 1, '5': 12, '10': 'leaseId'},
    {'1': 'generation', '3': 2, '4': 1, '5': 4, '10': 'generation'},
  ],
};

/// Descriptor for `SendSecureAttentionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sendSecureAttentionRequestDescriptor =
    $convert.base64Decode(
        'ChpTZW5kU2VjdXJlQXR0ZW50aW9uUmVxdWVzdBIZCghsZWFzZV9pZBgBIAEoDFIHbGVhc2VJZB'
        'IeCgpnZW5lcmF0aW9uGAIgASgEUgpnZW5lcmF0aW9u');

@$core.Deprecated('Use registerPrivilegedHelperRequestDescriptor instead')
const RegisterPrivilegedHelperRequest$json = {
  '1': 'RegisterPrivilegedHelperRequest',
  '2': [
    {
      '1': 'session',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PrivilegedSessionDescriptor',
      '10': 'session'
    },
  ],
};

/// Descriptor for `RegisterPrivilegedHelperRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List registerPrivilegedHelperRequestDescriptor =
    $convert.base64Decode(
        'Ch9SZWdpc3RlclByaXZpbGVnZWRIZWxwZXJSZXF1ZXN0EkIKB3Nlc3Npb24YASABKAsyKC5yb2'
        'FtbWFuZC52MS5Qcml2aWxlZ2VkU2Vzc2lvbkRlc2NyaXB0b3JSB3Nlc3Npb24=');

@$core.Deprecated('Use privilegedHelperRegisteredDescriptor instead')
const PrivilegedHelperRegistered$json = {
  '1': 'PrivilegedHelperRegistered',
  '2': [
    {
      '1': 'session',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PrivilegedSessionDescriptor',
      '10': 'session'
    },
  ],
};

/// Descriptor for `PrivilegedHelperRegistered`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List privilegedHelperRegisteredDescriptor =
    $convert.base64Decode(
        'ChpQcml2aWxlZ2VkSGVscGVyUmVnaXN0ZXJlZBJCCgdzZXNzaW9uGAEgASgLMigucm9hbW1hbm'
        'QudjEuUHJpdmlsZWdlZFNlc3Npb25EZXNjcmlwdG9yUgdzZXNzaW9u');

@$core.Deprecated('Use privilegedPeerStateChangedDescriptor instead')
const PrivilegedPeerStateChanged$json = {
  '1': 'PrivilegedPeerStateChanged',
  '2': [
    {'1': 'lease_id', '3': 1, '4': 1, '5': 12, '10': 'leaseId'},
    {'1': 'generation', '3': 2, '4': 1, '5': 4, '10': 'generation'},
    {
      '1': 'state',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.roammand.v1.PrivilegedPeerState',
      '10': 'state'
    },
  ],
};

/// Descriptor for `PrivilegedPeerStateChanged`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List privilegedPeerStateChangedDescriptor =
    $convert.base64Decode(
        'ChpQcml2aWxlZ2VkUGVlclN0YXRlQ2hhbmdlZBIZCghsZWFzZV9pZBgBIAEoDFIHbGVhc2VJZB'
        'IeCgpnZW5lcmF0aW9uGAIgASgEUgpnZW5lcmF0aW9uEjYKBXN0YXRlGAMgASgOMiAucm9hbW1h'
        'bmQudjEuUHJpdmlsZWdlZFBlZXJTdGF0ZVIFc3RhdGU=');

@$core.Deprecated('Use privilegedPeerAnswerDescriptor instead')
const PrivilegedPeerAnswer$json = {
  '1': 'PrivilegedPeerAnswer',
  '2': [
    {'1': 'lease_id', '3': 1, '4': 1, '5': 12, '10': 'leaseId'},
    {'1': 'generation', '3': 2, '4': 1, '5': 4, '10': 'generation'},
    {
      '1': 'answer',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.WebRtcSessionDescription',
      '10': 'answer'
    },
  ],
};

/// Descriptor for `PrivilegedPeerAnswer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List privilegedPeerAnswerDescriptor = $convert.base64Decode(
    'ChRQcml2aWxlZ2VkUGVlckFuc3dlchIZCghsZWFzZV9pZBgBIAEoDFIHbGVhc2VJZBIeCgpnZW'
    '5lcmF0aW9uGAIgASgEUgpnZW5lcmF0aW9uEj0KBmFuc3dlchgDIAEoCzIlLnJvYW1tYW5kLnYx'
    'LldlYlJ0Y1Nlc3Npb25EZXNjcmlwdGlvblIGYW5zd2Vy');

@$core.Deprecated('Use privilegedLocalIceCandidateDescriptor instead')
const PrivilegedLocalIceCandidate$json = {
  '1': 'PrivilegedLocalIceCandidate',
  '2': [
    {'1': 'lease_id', '3': 1, '4': 1, '5': 12, '10': 'leaseId'},
    {'1': 'generation', '3': 2, '4': 1, '5': 4, '10': 'generation'},
    {
      '1': 'candidate',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.IceCandidate',
      '10': 'candidate'
    },
  ],
};

/// Descriptor for `PrivilegedLocalIceCandidate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List privilegedLocalIceCandidateDescriptor =
    $convert.base64Decode(
        'ChtQcml2aWxlZ2VkTG9jYWxJY2VDYW5kaWRhdGUSGQoIbGVhc2VfaWQYASABKAxSB2xlYXNlSW'
        'QSHgoKZ2VuZXJhdGlvbhgCIAEoBFIKZ2VuZXJhdGlvbhI3CgljYW5kaWRhdGUYAyABKAsyGS5y'
        'b2FtbWFuZC52MS5JY2VDYW5kaWRhdGVSCWNhbmRpZGF0ZQ==');

@$core.Deprecated('Use privilegedCommandAcceptedDescriptor instead')
const PrivilegedCommandAccepted$json = {
  '1': 'PrivilegedCommandAccepted',
  '2': [
    {'1': 'lease_id', '3': 1, '4': 1, '5': 12, '10': 'leaseId'},
    {'1': 'generation', '3': 2, '4': 1, '5': 4, '10': 'generation'},
  ],
};

/// Descriptor for `PrivilegedCommandAccepted`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List privilegedCommandAcceptedDescriptor =
    $convert.base64Decode(
        'ChlQcml2aWxlZ2VkQ29tbWFuZEFjY2VwdGVkEhkKCGxlYXNlX2lkGAEgASgMUgdsZWFzZUlkEh'
        '4KCmdlbmVyYXRpb24YAiABKARSCmdlbmVyYXRpb24=');

@$core.Deprecated('Use privilegedBridgeClientFrameDescriptor instead')
const PrivilegedBridgeClientFrame$json = {
  '1': 'PrivilegedBridgeClientFrame',
  '2': [
    {
      '1': 'protocol_version',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.ProtocolVersion',
      '10': 'protocolVersion'
    },
    {'1': 'request_id', '3': 2, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'sequence', '3': 3, '4': 1, '5': 4, '10': 'sequence'},
    {
      '1': 'authenticate',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PrivilegedBridgeAuthenticate',
      '9': 0,
      '10': 'authenticate'
    },
    {
      '1': 'register_helper',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.RegisterPrivilegedHelperRequest',
      '9': 0,
      '10': 'registerHelper'
    },
    {
      '1': 'acquire_lease',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.AcquirePrivilegedLeaseRequest',
      '9': 0,
      '10': 'acquireLease'
    },
    {
      '1': 'renew_lease',
      '3': 21,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.RenewPrivilegedLeaseRequest',
      '9': 0,
      '10': 'renewLease'
    },
    {
      '1': 'release_lease',
      '3': 22,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.ReleasePrivilegedLeaseRequest',
      '9': 0,
      '10': 'releaseLease'
    },
    {
      '1': 'start_peer',
      '3': 23,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.StartPrivilegedPeerRequest',
      '9': 0,
      '10': 'startPeer'
    },
    {
      '1': 'restart_peer',
      '3': 24,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.RestartPrivilegedPeerRequest',
      '9': 0,
      '10': 'restartPeer'
    },
    {
      '1': 'add_ice_candidate',
      '3': 25,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.AddPrivilegedIceCandidateRequest',
      '9': 0,
      '10': 'addIceCandidate'
    },
    {
      '1': 'send_secure_attention',
      '3': 26,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.SendSecureAttentionRequest',
      '9': 0,
      '10': 'sendSecureAttention'
    },
    {
      '1': 'input_command',
      '3': 27,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PrivilegedInputCommand',
      '9': 0,
      '10': 'inputCommand'
    },
    {
      '1': 'close_peer',
      '3': 28,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.ClosePrivilegedPeerRequest',
      '9': 0,
      '10': 'closePeer'
    },
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `PrivilegedBridgeClientFrame`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List privilegedBridgeClientFrameDescriptor = $convert.base64Decode(
    'ChtQcml2aWxlZ2VkQnJpZGdlQ2xpZW50RnJhbWUSRwoQcHJvdG9jb2xfdmVyc2lvbhgBIAEoCz'
    'IcLnJvYW1tYW5kLnYxLlByb3RvY29sVmVyc2lvblIPcHJvdG9jb2xWZXJzaW9uEh0KCnJlcXVl'
    'c3RfaWQYAiABKAlSCXJlcXVlc3RJZBIaCghzZXF1ZW5jZRgDIAEoBFIIc2VxdWVuY2USTwoMYX'
    'V0aGVudGljYXRlGAogASgLMikucm9hbW1hbmQudjEuUHJpdmlsZWdlZEJyaWRnZUF1dGhlbnRp'
    'Y2F0ZUgAUgxhdXRoZW50aWNhdGUSVwoPcmVnaXN0ZXJfaGVscGVyGAsgASgLMiwucm9hbW1hbm'
    'QudjEuUmVnaXN0ZXJQcml2aWxlZ2VkSGVscGVyUmVxdWVzdEgAUg5yZWdpc3RlckhlbHBlchJR'
    'Cg1hY3F1aXJlX2xlYXNlGBQgASgLMioucm9hbW1hbmQudjEuQWNxdWlyZVByaXZpbGVnZWRMZW'
    'FzZVJlcXVlc3RIAFIMYWNxdWlyZUxlYXNlEksKC3JlbmV3X2xlYXNlGBUgASgLMigucm9hbW1h'
    'bmQudjEuUmVuZXdQcml2aWxlZ2VkTGVhc2VSZXF1ZXN0SABSCnJlbmV3TGVhc2USUQoNcmVsZW'
    'FzZV9sZWFzZRgWIAEoCzIqLnJvYW1tYW5kLnYxLlJlbGVhc2VQcml2aWxlZ2VkTGVhc2VSZXF1'
    'ZXN0SABSDHJlbGVhc2VMZWFzZRJICgpzdGFydF9wZWVyGBcgASgLMicucm9hbW1hbmQudjEuU3'
    'RhcnRQcml2aWxlZ2VkUGVlclJlcXVlc3RIAFIJc3RhcnRQZWVyEk4KDHJlc3RhcnRfcGVlchgY'
    'IAEoCzIpLnJvYW1tYW5kLnYxLlJlc3RhcnRQcml2aWxlZ2VkUGVlclJlcXVlc3RIAFILcmVzdG'
    'FydFBlZXISWwoRYWRkX2ljZV9jYW5kaWRhdGUYGSABKAsyLS5yb2FtbWFuZC52MS5BZGRQcml2'
    'aWxlZ2VkSWNlQ2FuZGlkYXRlUmVxdWVzdEgAUg9hZGRJY2VDYW5kaWRhdGUSXQoVc2VuZF9zZW'
    'N1cmVfYXR0ZW50aW9uGBogASgLMicucm9hbW1hbmQudjEuU2VuZFNlY3VyZUF0dGVudGlvblJl'
    'cXVlc3RIAFITc2VuZFNlY3VyZUF0dGVudGlvbhJKCg1pbnB1dF9jb21tYW5kGBsgASgLMiMucm'
    '9hbW1hbmQudjEuUHJpdmlsZWdlZElucHV0Q29tbWFuZEgAUgxpbnB1dENvbW1hbmQSSAoKY2xv'
    'c2VfcGVlchgcIAEoCzInLnJvYW1tYW5kLnYxLkNsb3NlUHJpdmlsZWdlZFBlZXJSZXF1ZXN0SA'
    'BSCWNsb3NlUGVlckIJCgdwYXlsb2Fk');

@$core.Deprecated('Use privilegedBridgeServerFrameDescriptor instead')
const PrivilegedBridgeServerFrame$json = {
  '1': 'PrivilegedBridgeServerFrame',
  '2': [
    {
      '1': 'protocol_version',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.ProtocolVersion',
      '10': 'protocolVersion'
    },
    {'1': 'request_id', '3': 2, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'sequence', '3': 3, '4': 1, '5': 4, '10': 'sequence'},
    {
      '1': 'challenge',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PrivilegedBridgeChallenge',
      '9': 0,
      '10': 'challenge'
    },
    {
      '1': 'authenticated',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PrivilegedBridgeAuthenticated',
      '9': 0,
      '10': 'authenticated'
    },
    {
      '1': 'helper_registered',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PrivilegedHelperRegistered',
      '9': 0,
      '10': 'helperRegistered'
    },
    {
      '1': 'status',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PrivilegedBridgeStatusSnapshot',
      '9': 0,
      '10': 'status'
    },
    {
      '1': 'lease',
      '3': 21,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PrivilegedLease',
      '9': 0,
      '10': 'lease'
    },
    {
      '1': 'peer_answer',
      '3': 22,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PrivilegedPeerAnswer',
      '9': 0,
      '10': 'peerAnswer'
    },
    {
      '1': 'local_ice_candidate',
      '3': 23,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PrivilegedLocalIceCandidate',
      '9': 0,
      '10': 'localIceCandidate'
    },
    {
      '1': 'peer_state_changed',
      '3': 24,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PrivilegedPeerStateChanged',
      '9': 0,
      '10': 'peerStateChanged'
    },
    {
      '1': 'reliable_input',
      '3': 25,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PrivilegedReliableInputEvent',
      '9': 0,
      '10': 'reliableInput'
    },
    {
      '1': 'fast_pointer',
      '3': 26,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PrivilegedFastPointerEvent',
      '9': 0,
      '10': 'fastPointer'
    },
    {
      '1': 'command_accepted',
      '3': 27,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PrivilegedCommandAccepted',
      '9': 0,
      '10': 'commandAccepted'
    },
    {
      '1': 'error',
      '3': 29,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.UnifiedError',
      '9': 0,
      '10': 'error'
    },
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `PrivilegedBridgeServerFrame`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List privilegedBridgeServerFrameDescriptor = $convert.base64Decode(
    'ChtQcml2aWxlZ2VkQnJpZGdlU2VydmVyRnJhbWUSRwoQcHJvdG9jb2xfdmVyc2lvbhgBIAEoCz'
    'IcLnJvYW1tYW5kLnYxLlByb3RvY29sVmVyc2lvblIPcHJvdG9jb2xWZXJzaW9uEh0KCnJlcXVl'
    'c3RfaWQYAiABKAlSCXJlcXVlc3RJZBIaCghzZXF1ZW5jZRgDIAEoBFIIc2VxdWVuY2USRgoJY2'
    'hhbGxlbmdlGAogASgLMiYucm9hbW1hbmQudjEuUHJpdmlsZWdlZEJyaWRnZUNoYWxsZW5nZUgA'
    'UgljaGFsbGVuZ2USUgoNYXV0aGVudGljYXRlZBgLIAEoCzIqLnJvYW1tYW5kLnYxLlByaXZpbG'
    'VnZWRCcmlkZ2VBdXRoZW50aWNhdGVkSABSDWF1dGhlbnRpY2F0ZWQSVgoRaGVscGVyX3JlZ2lz'
    'dGVyZWQYDCABKAsyJy5yb2FtbWFuZC52MS5Qcml2aWxlZ2VkSGVscGVyUmVnaXN0ZXJlZEgAUh'
    'BoZWxwZXJSZWdpc3RlcmVkEkUKBnN0YXR1cxgUIAEoCzIrLnJvYW1tYW5kLnYxLlByaXZpbGVn'
    'ZWRCcmlkZ2VTdGF0dXNTbmFwc2hvdEgAUgZzdGF0dXMSNAoFbGVhc2UYFSABKAsyHC5yb2FtbW'
    'FuZC52MS5Qcml2aWxlZ2VkTGVhc2VIAFIFbGVhc2USRAoLcGVlcl9hbnN3ZXIYFiABKAsyIS5y'
    'b2FtbWFuZC52MS5Qcml2aWxlZ2VkUGVlckFuc3dlckgAUgpwZWVyQW5zd2VyEloKE2xvY2FsX2'
    'ljZV9jYW5kaWRhdGUYFyABKAsyKC5yb2FtbWFuZC52MS5Qcml2aWxlZ2VkTG9jYWxJY2VDYW5k'
    'aWRhdGVIAFIRbG9jYWxJY2VDYW5kaWRhdGUSVwoScGVlcl9zdGF0ZV9jaGFuZ2VkGBggASgLMi'
    'cucm9hbW1hbmQudjEuUHJpdmlsZWdlZFBlZXJTdGF0ZUNoYW5nZWRIAFIQcGVlclN0YXRlQ2hh'
    'bmdlZBJSCg5yZWxpYWJsZV9pbnB1dBgZIAEoCzIpLnJvYW1tYW5kLnYxLlByaXZpbGVnZWRSZW'
    'xpYWJsZUlucHV0RXZlbnRIAFINcmVsaWFibGVJbnB1dBJMCgxmYXN0X3BvaW50ZXIYGiABKAsy'
    'Jy5yb2FtbWFuZC52MS5Qcml2aWxlZ2VkRmFzdFBvaW50ZXJFdmVudEgAUgtmYXN0UG9pbnRlch'
    'JTChBjb21tYW5kX2FjY2VwdGVkGBsgASgLMiYucm9hbW1hbmQudjEuUHJpdmlsZWdlZENvbW1h'
    'bmRBY2NlcHRlZEgAUg9jb21tYW5kQWNjZXB0ZWQSMQoFZXJyb3IYHSABKAsyGS5yb2FtbWFuZC'
    '52MS5VbmlmaWVkRXJyb3JIAFIFZXJyb3JCCQoHcGF5bG9hZA==');
