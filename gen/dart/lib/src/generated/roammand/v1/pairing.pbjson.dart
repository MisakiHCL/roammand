// SPDX-License-Identifier: Apache-2.0

// This is a generated file - do not edit.
//
// Generated from roammand/v1/pairing.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use pairingDecisionStatusDescriptor instead')
const PairingDecisionStatus$json = {
  '1': 'PairingDecisionStatus',
  '2': [
    {'1': 'PAIRING_DECISION_STATUS_UNSPECIFIED', '2': 0},
    {'1': 'PAIRING_DECISION_STATUS_PENDING', '2': 1},
    {'1': 'PAIRING_DECISION_STATUS_ACCEPTED', '2': 2},
    {'1': 'PAIRING_DECISION_STATUS_REJECTED', '2': 3},
    {'1': 'PAIRING_DECISION_STATUS_EXPIRED', '2': 4},
  ],
};

/// Descriptor for `PairingDecisionStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List pairingDecisionStatusDescriptor = $convert.base64Decode(
    'ChVQYWlyaW5nRGVjaXNpb25TdGF0dXMSJwojUEFJUklOR19ERUNJU0lPTl9TVEFUVVNfVU5TUE'
    'VDSUZJRUQQABIjCh9QQUlSSU5HX0RFQ0lTSU9OX1NUQVRVU19QRU5ESU5HEAESJAogUEFJUklO'
    'R19ERUNJU0lPTl9TVEFUVVNfQUNDRVBURUQQAhIkCiBQQUlSSU5HX0RFQ0lTSU9OX1NUQVRVU1'
    '9SRUpFQ1RFRBADEiMKH1BBSVJJTkdfREVDSVNJT05fU1RBVFVTX0VYUElSRUQQBA==');

@$core.Deprecated('Use pairingDirectionDescriptor instead')
const PairingDirection$json = {
  '1': 'PairingDirection',
  '2': [
    {'1': 'PAIRING_DIRECTION_UNSPECIFIED', '2': 0},
    {'1': 'PAIRING_DIRECTION_CONTROLLER_TO_HOST', '2': 1},
    {'1': 'PAIRING_DIRECTION_HOST_TO_CONTROLLER', '2': 2},
  ],
};

/// Descriptor for `PairingDirection`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List pairingDirectionDescriptor = $convert.base64Decode(
    'ChBQYWlyaW5nRGlyZWN0aW9uEiEKHVBBSVJJTkdfRElSRUNUSU9OX1VOU1BFQ0lGSUVEEAASKA'
    'okUEFJUklOR19ESVJFQ1RJT05fQ09OVFJPTExFUl9UT19IT1NUEAESKAokUEFJUklOR19ESVJF'
    'Q1RJT05fSE9TVF9UT19DT05UUk9MTEVSEAI=');

@$core.Deprecated('Use pairingIdentityRoleDescriptor instead')
const PairingIdentityRole$json = {
  '1': 'PairingIdentityRole',
  '2': [
    {'1': 'PAIRING_IDENTITY_ROLE_UNSPECIFIED', '2': 0},
    {'1': 'PAIRING_IDENTITY_ROLE_CONTROLLER', '2': 1},
    {'1': 'PAIRING_IDENTITY_ROLE_HOST', '2': 2},
  ],
};

/// Descriptor for `PairingIdentityRole`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List pairingIdentityRoleDescriptor = $convert.base64Decode(
    'ChNQYWlyaW5nSWRlbnRpdHlSb2xlEiUKIVBBSVJJTkdfSURFTlRJVFlfUk9MRV9VTlNQRUNJRk'
    'lFRBAAEiQKIFBBSVJJTkdfSURFTlRJVFlfUk9MRV9DT05UUk9MTEVSEAESHgoaUEFJUklOR19J'
    'REVOVElUWV9ST0xFX0hPU1QQAg==');

@$core.Deprecated('Use pairingInvitationKindDescriptor instead')
const PairingInvitationKind$json = {
  '1': 'PairingInvitationKind',
  '2': [
    {'1': 'PAIRING_INVITATION_KIND_UNSPECIFIED', '2': 0},
    {'1': 'PAIRING_INVITATION_KIND_QR', '2': 1},
    {'1': 'PAIRING_INVITATION_KIND_DESKTOP_CODE', '2': 2},
  ],
};

/// Descriptor for `PairingInvitationKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List pairingInvitationKindDescriptor = $convert.base64Decode(
    'ChVQYWlyaW5nSW52aXRhdGlvbktpbmQSJwojUEFJUklOR19JTlZJVEFUSU9OX0tJTkRfVU5TUE'
    'VDSUZJRUQQABIeChpQQUlSSU5HX0lOVklUQVRJT05fS0lORF9RUhABEigKJFBBSVJJTkdfSU5W'
    'SVRBVElPTl9LSU5EX0RFU0tUT1BfQ09ERRAC');

@$core.Deprecated('Use hostPairingStateDescriptor instead')
const HostPairingState$json = {
  '1': 'HostPairingState',
  '2': [
    {'1': 'HOST_PAIRING_STATE_UNSPECIFIED', '2': 0},
    {'1': 'HOST_PAIRING_STATE_IDLE', '2': 1},
    {'1': 'HOST_PAIRING_STATE_CREATING', '2': 2},
    {'1': 'HOST_PAIRING_STATE_INVITING', '2': 3},
    {'1': 'HOST_PAIRING_STATE_VERIFYING_CONTROLLER', '2': 4},
    {'1': 'HOST_PAIRING_STATE_WAITING_LOCAL_DECISION', '2': 5},
    {'1': 'HOST_PAIRING_STATE_ACCEPTED', '2': 6},
    {'1': 'HOST_PAIRING_STATE_REJECTED', '2': 7},
    {'1': 'HOST_PAIRING_STATE_EXPIRED', '2': 8},
    {'1': 'HOST_PAIRING_STATE_CANCELLED', '2': 9},
    {'1': 'HOST_PAIRING_STATE_FAILED', '2': 10},
  ],
};

/// Descriptor for `HostPairingState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List hostPairingStateDescriptor = $convert.base64Decode(
    'ChBIb3N0UGFpcmluZ1N0YXRlEiIKHkhPU1RfUEFJUklOR19TVEFURV9VTlNQRUNJRklFRBAAEh'
    'sKF0hPU1RfUEFJUklOR19TVEFURV9JRExFEAESHwobSE9TVF9QQUlSSU5HX1NUQVRFX0NSRUFU'
    'SU5HEAISHwobSE9TVF9QQUlSSU5HX1NUQVRFX0lOVklUSU5HEAMSKwonSE9TVF9QQUlSSU5HX1'
    'NUQVRFX1ZFUklGWUlOR19DT05UUk9MTEVSEAQSLQopSE9TVF9QQUlSSU5HX1NUQVRFX1dBSVRJ'
    'TkdfTE9DQUxfREVDSVNJT04QBRIfChtIT1NUX1BBSVJJTkdfU1RBVEVfQUNDRVBURUQQBhIfCh'
    'tIT1NUX1BBSVJJTkdfU1RBVEVfUkVKRUNURUQQBxIeChpIT1NUX1BBSVJJTkdfU1RBVEVfRVhQ'
    'SVJFRBAIEiAKHEhPU1RfUEFJUklOR19TVEFURV9DQU5DRUxMRUQQCRIdChlIT1NUX1BBSVJJTk'
    'dfU1RBVEVfRkFJTEVEEAo=');

@$core.Deprecated('Use qrPairingRendezvousDescriptor instead')
const QrPairingRendezvous$json = {
  '1': 'QrPairingRendezvous',
  '2': [
    {'1': 'rendezvous_id', '3': 1, '4': 1, '5': 12, '10': 'rendezvousId'},
    {
      '1': 'host_identity',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.DeviceIdentity',
      '10': 'hostIdentity'
    },
    {
      '1': 'host_public_key_fingerprint_sha256',
      '3': 3,
      '4': 1,
      '5': 12,
      '10': 'hostPublicKeyFingerprintSha256'
    },
    {
      '1': 'host_ephemeral_public_key',
      '3': 4,
      '4': 1,
      '5': 12,
      '10': 'hostEphemeralPublicKey'
    },
    {
      '1': 'signaling_endpoint',
      '3': 5,
      '4': 1,
      '5': 9,
      '10': 'signalingEndpoint'
    },
    {'1': 'issued_at_unix_ms', '3': 6, '4': 1, '5': 4, '10': 'issuedAtUnixMs'},
    {
      '1': 'expires_at_unix_ms',
      '3': 7,
      '4': 1,
      '5': 4,
      '10': 'expiresAtUnixMs'
    },
  ],
};

/// Descriptor for `QrPairingRendezvous`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List qrPairingRendezvousDescriptor = $convert.base64Decode(
    'ChNRclBhaXJpbmdSZW5kZXp2b3VzEiMKDXJlbmRlenZvdXNfaWQYASABKAxSDHJlbmRlenZvdX'
    'NJZBJACg1ob3N0X2lkZW50aXR5GAIgASgLMhsucm9hbW1hbmQudjEuRGV2aWNlSWRlbnRpdHlS'
    'DGhvc3RJZGVudGl0eRJKCiJob3N0X3B1YmxpY19rZXlfZmluZ2VycHJpbnRfc2hhMjU2GAMgAS'
    'gMUh5ob3N0UHVibGljS2V5RmluZ2VycHJpbnRTaGEyNTYSOQoZaG9zdF9lcGhlbWVyYWxfcHVi'
    'bGljX2tleRgEIAEoDFIWaG9zdEVwaGVtZXJhbFB1YmxpY0tleRItChJzaWduYWxpbmdfZW5kcG'
    '9pbnQYBSABKAlSEXNpZ25hbGluZ0VuZHBvaW50EikKEWlzc3VlZF9hdF91bml4X21zGAYgASgE'
    'Ug5pc3N1ZWRBdFVuaXhNcxIrChJleHBpcmVzX2F0X3VuaXhfbXMYByABKARSD2V4cGlyZXNBdF'
    'VuaXhNcw==');

@$core.Deprecated('Use desktopPairingRendezvousDescriptor instead')
const DesktopPairingRendezvous$json = {
  '1': 'DesktopPairingRendezvous',
  '2': [
    {'1': 'rendezvous_id', '3': 1, '4': 1, '5': 12, '10': 'rendezvousId'},
    {'1': 'pairing_code', '3': 2, '4': 1, '5': 9, '10': 'pairingCode'},
    {
      '1': 'host_identity',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.DeviceIdentity',
      '10': 'hostIdentity'
    },
    {
      '1': 'host_ephemeral_public_key',
      '3': 4,
      '4': 1,
      '5': 12,
      '10': 'hostEphemeralPublicKey'
    },
    {'1': 'issued_at_unix_ms', '3': 5, '4': 1, '5': 4, '10': 'issuedAtUnixMs'},
    {
      '1': 'expires_at_unix_ms',
      '3': 6,
      '4': 1,
      '5': 4,
      '10': 'expiresAtUnixMs'
    },
  ],
};

/// Descriptor for `DesktopPairingRendezvous`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List desktopPairingRendezvousDescriptor = $convert.base64Decode(
    'ChhEZXNrdG9wUGFpcmluZ1JlbmRlenZvdXMSIwoNcmVuZGV6dm91c19pZBgBIAEoDFIMcmVuZG'
    'V6dm91c0lkEiEKDHBhaXJpbmdfY29kZRgCIAEoCVILcGFpcmluZ0NvZGUSQAoNaG9zdF9pZGVu'
    'dGl0eRgDIAEoCzIbLnJvYW1tYW5kLnYxLkRldmljZUlkZW50aXR5Ugxob3N0SWRlbnRpdHkSOQ'
    'oZaG9zdF9lcGhlbWVyYWxfcHVibGljX2tleRgEIAEoDFIWaG9zdEVwaGVtZXJhbFB1YmxpY0tl'
    'eRIpChFpc3N1ZWRfYXRfdW5peF9tcxgFIAEoBFIOaXNzdWVkQXRVbml4TXMSKwoSZXhwaXJlc1'
    '9hdF91bml4X21zGAYgASgEUg9leHBpcmVzQXRVbml4TXM=');

@$core.Deprecated('Use pairingHelloDescriptor instead')
const PairingHello$json = {
  '1': 'PairingHello',
  '2': [
    {'1': 'rendezvous_id', '3': 1, '4': 1, '5': 12, '10': 'rendezvousId'},
    {
      '1': 'identity',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.DeviceIdentity',
      '10': 'identity'
    },
    {
      '1': 'ephemeral_public_key',
      '3': 3,
      '4': 1,
      '5': 12,
      '10': 'ephemeralPublicKey'
    },
  ],
};

/// Descriptor for `PairingHello`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pairingHelloDescriptor = $convert.base64Decode(
    'CgxQYWlyaW5nSGVsbG8SIwoNcmVuZGV6dm91c19pZBgBIAEoDFIMcmVuZGV6dm91c0lkEjcKCG'
    'lkZW50aXR5GAIgASgLMhsucm9hbW1hbmQudjEuRGV2aWNlSWRlbnRpdHlSCGlkZW50aXR5EjAK'
    'FGVwaGVtZXJhbF9wdWJsaWNfa2V5GAMgASgMUhJlcGhlbWVyYWxQdWJsaWNLZXk=');

@$core.Deprecated('Use pairingConfirmationDataDescriptor instead')
const PairingConfirmationData$json = {
  '1': 'PairingConfirmationData',
  '2': [
    {
      '1': 'controller_device_id',
      '3': 1,
      '4': 1,
      '5': 12,
      '10': 'controllerDeviceId'
    },
    {'1': 'host_device_id', '3': 2, '4': 1, '5': 12, '10': 'hostDeviceId'},
    {'1': 'rendezvous_id', '3': 3, '4': 1, '5': 12, '10': 'rendezvousId'},
    {
      '1': 'controller_identity_public_key',
      '3': 4,
      '4': 1,
      '5': 12,
      '10': 'controllerIdentityPublicKey'
    },
    {
      '1': 'host_identity_public_key',
      '3': 5,
      '4': 1,
      '5': 12,
      '10': 'hostIdentityPublicKey'
    },
    {
      '1': 'controller_ephemeral_public_key',
      '3': 6,
      '4': 1,
      '5': 12,
      '10': 'controllerEphemeralPublicKey'
    },
    {
      '1': 'host_ephemeral_public_key',
      '3': 7,
      '4': 1,
      '5': 12,
      '10': 'hostEphemeralPublicKey'
    },
    {
      '1': 'transcript_sha256',
      '3': 8,
      '4': 1,
      '5': 12,
      '10': 'transcriptSha256'
    },
  ],
};

/// Descriptor for `PairingConfirmationData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pairingConfirmationDataDescriptor = $convert.base64Decode(
    'ChdQYWlyaW5nQ29uZmlybWF0aW9uRGF0YRIwChRjb250cm9sbGVyX2RldmljZV9pZBgBIAEoDF'
    'ISY29udHJvbGxlckRldmljZUlkEiQKDmhvc3RfZGV2aWNlX2lkGAIgASgMUgxob3N0RGV2aWNl'
    'SWQSIwoNcmVuZGV6dm91c19pZBgDIAEoDFIMcmVuZGV6dm91c0lkEkMKHmNvbnRyb2xsZXJfaW'
    'RlbnRpdHlfcHVibGljX2tleRgEIAEoDFIbY29udHJvbGxlcklkZW50aXR5UHVibGljS2V5EjcK'
    'GGhvc3RfaWRlbnRpdHlfcHVibGljX2tleRgFIAEoDFIVaG9zdElkZW50aXR5UHVibGljS2V5Ek'
    'UKH2NvbnRyb2xsZXJfZXBoZW1lcmFsX3B1YmxpY19rZXkYBiABKAxSHGNvbnRyb2xsZXJFcGhl'
    'bWVyYWxQdWJsaWNLZXkSOQoZaG9zdF9lcGhlbWVyYWxfcHVibGljX2tleRgHIAEoDFIWaG9zdE'
    'VwaGVtZXJhbFB1YmxpY0tleRIrChF0cmFuc2NyaXB0X3NoYTI1NhgIIAEoDFIQdHJhbnNjcmlw'
    'dFNoYTI1Ng==');

@$core.Deprecated('Use pairingDecisionDescriptor instead')
const PairingDecision$json = {
  '1': 'PairingDecision',
  '2': [
    {
      '1': 'status',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.roammand.v1.PairingDecisionStatus',
      '10': 'status'
    },
    {
      '1': 'controller',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.DeviceIdentity',
      '10': 'controller'
    },
    {
      '1': 'confirmation',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PairingConfirmationData',
      '10': 'confirmation'
    },
    {
      '1': 'grant',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.ControllerGrant',
      '10': 'grant'
    },
  ],
};

/// Descriptor for `PairingDecision`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pairingDecisionDescriptor = $convert.base64Decode(
    'Cg9QYWlyaW5nRGVjaXNpb24SOgoGc3RhdHVzGAEgASgOMiIucm9hbW1hbmQudjEuUGFpcmluZ0'
    'RlY2lzaW9uU3RhdHVzUgZzdGF0dXMSOwoKY29udHJvbGxlchgCIAEoCzIbLnJvYW1tYW5kLnYx'
    'LkRldmljZUlkZW50aXR5Ugpjb250cm9sbGVyEkgKDGNvbmZpcm1hdGlvbhgDIAEoCzIkLnJvYW'
    '1tYW5kLnYxLlBhaXJpbmdDb25maXJtYXRpb25EYXRhUgxjb25maXJtYXRpb24SMgoFZ3JhbnQY'
    'BCABKAsyHC5yb2FtbWFuZC52MS5Db250cm9sbGVyR3JhbnRSBWdyYW50');

@$core.Deprecated('Use hostPairingInvitationDescriptor instead')
const HostPairingInvitation$json = {
  '1': 'HostPairingInvitation',
  '2': [
    {
      '1': 'protocol_version',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.ProtocolVersion',
      '10': 'protocolVersion'
    },
    {
      '1': 'kind',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.roammand.v1.PairingInvitationKind',
      '10': 'kind'
    },
    {'1': 'rendezvous_id', '3': 3, '4': 1, '5': 12, '10': 'rendezvousId'},
    {
      '1': 'host_identity',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.DeviceIdentity',
      '10': 'hostIdentity'
    },
    {
      '1': 'host_public_key_fingerprint_sha256',
      '3': 5,
      '4': 1,
      '5': 12,
      '10': 'hostPublicKeyFingerprintSha256'
    },
    {
      '1': 'host_ephemeral_public_key',
      '3': 6,
      '4': 1,
      '5': 12,
      '10': 'hostEphemeralPublicKey'
    },
    {
      '1': 'signaling_endpoint',
      '3': 7,
      '4': 1,
      '5': 9,
      '10': 'signalingEndpoint'
    },
    {'1': 'pairing_code', '3': 8, '4': 1, '5': 9, '10': 'pairingCode'},
    {'1': 'issued_at_unix_ms', '3': 9, '4': 1, '5': 4, '10': 'issuedAtUnixMs'},
    {
      '1': 'expires_at_unix_ms',
      '3': 10,
      '4': 1,
      '5': 4,
      '10': 'expiresAtUnixMs'
    },
  ],
};

/// Descriptor for `HostPairingInvitation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hostPairingInvitationDescriptor = $convert.base64Decode(
    'ChVIb3N0UGFpcmluZ0ludml0YXRpb24SRwoQcHJvdG9jb2xfdmVyc2lvbhgBIAEoCzIcLnJvYW'
    '1tYW5kLnYxLlByb3RvY29sVmVyc2lvblIPcHJvdG9jb2xWZXJzaW9uEjYKBGtpbmQYAiABKA4y'
    'Ii5yb2FtbWFuZC52MS5QYWlyaW5nSW52aXRhdGlvbktpbmRSBGtpbmQSIwoNcmVuZGV6dm91c1'
    '9pZBgDIAEoDFIMcmVuZGV6dm91c0lkEkAKDWhvc3RfaWRlbnRpdHkYBCABKAsyGy5yb2FtbWFu'
    'ZC52MS5EZXZpY2VJZGVudGl0eVIMaG9zdElkZW50aXR5EkoKImhvc3RfcHVibGljX2tleV9maW'
    '5nZXJwcmludF9zaGEyNTYYBSABKAxSHmhvc3RQdWJsaWNLZXlGaW5nZXJwcmludFNoYTI1NhI5'
    'Chlob3N0X2VwaGVtZXJhbF9wdWJsaWNfa2V5GAYgASgMUhZob3N0RXBoZW1lcmFsUHVibGljS2'
    'V5Ei0KEnNpZ25hbGluZ19lbmRwb2ludBgHIAEoCVIRc2lnbmFsaW5nRW5kcG9pbnQSIQoMcGFp'
    'cmluZ19jb2RlGAggASgJUgtwYWlyaW5nQ29kZRIpChFpc3N1ZWRfYXRfdW5peF9tcxgJIAEoBF'
    'IOaXNzdWVkQXRVbml4TXMSKwoSZXhwaXJlc19hdF91bml4X21zGAogASgEUg9leHBpcmVzQXRV'
    'bml4TXM=');

@$core.Deprecated('Use controllerPairingHelloDescriptor instead')
const ControllerPairingHello$json = {
  '1': 'ControllerPairingHello',
  '2': [
    {'1': 'rendezvous_id', '3': 1, '4': 1, '5': 12, '10': 'rendezvousId'},
    {
      '1': 'identity',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.DeviceIdentity',
      '10': 'identity'
    },
    {
      '1': 'ephemeral_public_key',
      '3': 3,
      '4': 1,
      '5': 12,
      '10': 'ephemeralPublicKey'
    },
    {
      '1': 'transcript_sha256',
      '3': 4,
      '4': 1,
      '5': 12,
      '10': 'transcriptSha256'
    },
    {'1': 'signature', '3': 5, '4': 1, '5': 12, '10': 'signature'},
  ],
};

/// Descriptor for `ControllerPairingHello`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List controllerPairingHelloDescriptor = $convert.base64Decode(
    'ChZDb250cm9sbGVyUGFpcmluZ0hlbGxvEiMKDXJlbmRlenZvdXNfaWQYASABKAxSDHJlbmRlen'
    'ZvdXNJZBI3CghpZGVudGl0eRgCIAEoCzIbLnJvYW1tYW5kLnYxLkRldmljZUlkZW50aXR5Ughp'
    'ZGVudGl0eRIwChRlcGhlbWVyYWxfcHVibGljX2tleRgDIAEoDFISZXBoZW1lcmFsUHVibGljS2'
    'V5EisKEXRyYW5zY3JpcHRfc2hhMjU2GAQgASgMUhB0cmFuc2NyaXB0U2hhMjU2EhwKCXNpZ25h'
    'dHVyZRgFIAEoDFIJc2lnbmF0dXJl');

@$core.Deprecated('Use hostPairingProofDescriptor instead')
const HostPairingProof$json = {
  '1': 'HostPairingProof',
  '2': [
    {
      '1': 'confirmation',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PairingConfirmationData',
      '10': 'confirmation'
    },
    {'1': 'host_signature', '3': 2, '4': 1, '5': 12, '10': 'hostSignature'},
    {
      '1': 'expires_at_unix_ms',
      '3': 3,
      '4': 1,
      '5': 4,
      '10': 'expiresAtUnixMs'
    },
  ],
};

/// Descriptor for `HostPairingProof`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hostPairingProofDescriptor = $convert.base64Decode(
    'ChBIb3N0UGFpcmluZ1Byb29mEkgKDGNvbmZpcm1hdGlvbhgBIAEoCzIkLnJvYW1tYW5kLnYxLl'
    'BhaXJpbmdDb25maXJtYXRpb25EYXRhUgxjb25maXJtYXRpb24SJQoOaG9zdF9zaWduYXR1cmUY'
    'AiABKAxSDWhvc3RTaWduYXR1cmUSKwoSZXhwaXJlc19hdF91bml4X21zGAMgASgEUg9leHBpcm'
    'VzQXRVbml4TXM=');

@$core.Deprecated('Use controllerPairingReadyDescriptor instead')
const ControllerPairingReady$json = {
  '1': 'ControllerPairingReady',
  '2': [
    {
      '1': 'transcript_sha256',
      '3': 1,
      '4': 1,
      '5': 12,
      '10': 'transcriptSha256'
    },
  ],
};

/// Descriptor for `ControllerPairingReady`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List controllerPairingReadyDescriptor =
    $convert.base64Decode(
        'ChZDb250cm9sbGVyUGFpcmluZ1JlYWR5EisKEXRyYW5zY3JpcHRfc2hhMjU2GAEgASgMUhB0cm'
        'Fuc2NyaXB0U2hhMjU2');

@$core.Deprecated('Use pairingFinalDecisionDescriptor instead')
const PairingFinalDecision$json = {
  '1': 'PairingFinalDecision',
  '2': [
    {
      '1': 'status',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.roammand.v1.PairingDecisionStatus',
      '10': 'status'
    },
    {
      '1': 'transcript_sha256',
      '3': 2,
      '4': 1,
      '5': 12,
      '10': 'transcriptSha256'
    },
    {
      '1': 'grant',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.ControllerGrant',
      '10': 'grant'
    },
  ],
};

/// Descriptor for `PairingFinalDecision`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pairingFinalDecisionDescriptor = $convert.base64Decode(
    'ChRQYWlyaW5nRmluYWxEZWNpc2lvbhI6CgZzdGF0dXMYASABKA4yIi5yb2FtbWFuZC52MS5QYW'
    'lyaW5nRGVjaXNpb25TdGF0dXNSBnN0YXR1cxIrChF0cmFuc2NyaXB0X3NoYTI1NhgCIAEoDFIQ'
    'dHJhbnNjcmlwdFNoYTI1NhIyCgVncmFudBgDIAEoCzIcLnJvYW1tYW5kLnYxLkNvbnRyb2xsZX'
    'JHcmFudFIFZ3JhbnQ=');

@$core.Deprecated('Use pairingPlaintextDescriptor instead')
const PairingPlaintext$json = {
  '1': 'PairingPlaintext',
  '2': [
    {
      '1': 'host_proof',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.HostPairingProof',
      '9': 0,
      '10': 'hostProof'
    },
    {
      '1': 'controller_ready',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.ControllerPairingReady',
      '9': 0,
      '10': 'controllerReady'
    },
    {
      '1': 'final_decision',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PairingFinalDecision',
      '9': 0,
      '10': 'finalDecision'
    },
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `PairingPlaintext`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pairingPlaintextDescriptor = $convert.base64Decode(
    'ChBQYWlyaW5nUGxhaW50ZXh0Ej4KCmhvc3RfcHJvb2YYASABKAsyHS5yb2FtbWFuZC52MS5Ib3'
    'N0UGFpcmluZ1Byb29mSABSCWhvc3RQcm9vZhJQChBjb250cm9sbGVyX3JlYWR5GAIgASgLMiMu'
    'cm9hbW1hbmQudjEuQ29udHJvbGxlclBhaXJpbmdSZWFkeUgAUg9jb250cm9sbGVyUmVhZHkSSg'
    'oOZmluYWxfZGVjaXNpb24YAyABKAsyIS5yb2FtbWFuZC52MS5QYWlyaW5nRmluYWxEZWNpc2lv'
    'bkgAUg1maW5hbERlY2lzaW9uQgkKB3BheWxvYWQ=');

@$core.Deprecated('Use encryptedPairingEnvelopeDescriptor instead')
const EncryptedPairingEnvelope$json = {
  '1': 'EncryptedPairingEnvelope',
  '2': [
    {
      '1': 'protocol_version',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.ProtocolVersion',
      '10': 'protocolVersion'
    },
    {'1': 'rendezvous_id', '3': 2, '4': 1, '5': 12, '10': 'rendezvousId'},
    {
      '1': 'direction',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.roammand.v1.PairingDirection',
      '10': 'direction'
    },
    {'1': 'sequence', '3': 4, '4': 1, '5': 4, '10': 'sequence'},
    {'1': 'ciphertext', '3': 5, '4': 1, '5': 12, '10': 'ciphertext'},
  ],
};

/// Descriptor for `EncryptedPairingEnvelope`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List encryptedPairingEnvelopeDescriptor = $convert.base64Decode(
    'ChhFbmNyeXB0ZWRQYWlyaW5nRW52ZWxvcGUSRwoQcHJvdG9jb2xfdmVyc2lvbhgBIAEoCzIcLn'
    'JvYW1tYW5kLnYxLlByb3RvY29sVmVyc2lvblIPcHJvdG9jb2xWZXJzaW9uEiMKDXJlbmRlenZv'
    'dXNfaWQYAiABKAxSDHJlbmRlenZvdXNJZBI7CglkaXJlY3Rpb24YAyABKA4yHS5yb2FtbWFuZC'
    '52MS5QYWlyaW5nRGlyZWN0aW9uUglkaXJlY3Rpb24SGgoIc2VxdWVuY2UYBCABKARSCHNlcXVl'
    'bmNlEh4KCmNpcGhlcnRleHQYBSABKAxSCmNpcGhlcnRleHQ=');

@$core.Deprecated('Use trustedHostBindingDescriptor instead')
const TrustedHostBinding$json = {
  '1': 'TrustedHostBinding',
  '2': [
    {
      '1': 'host_identity',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.DeviceIdentity',
      '10': 'hostIdentity'
    },
    {
      '1': 'signaling_endpoint',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'signalingEndpoint'
    },
    {'1': 'paired_at_unix_ms', '3': 3, '4': 1, '5': 4, '10': 'pairedAtUnixMs'},
    {
      '1': 'last_successful_connection_at_unix_ms',
      '3': 4,
      '4': 1,
      '5': 4,
      '10': 'lastSuccessfulConnectionAtUnixMs'
    },
    {'1': 'display_order', '3': 5, '4': 1, '5': 13, '10': 'displayOrder'},
    {'1': 'local_alias', '3': 6, '4': 1, '5': 9, '10': 'localAlias'},
  ],
};

/// Descriptor for `TrustedHostBinding`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trustedHostBindingDescriptor = $convert.base64Decode(
    'ChJUcnVzdGVkSG9zdEJpbmRpbmcSQAoNaG9zdF9pZGVudGl0eRgBIAEoCzIbLnJvYW1tYW5kLn'
    'YxLkRldmljZUlkZW50aXR5Ugxob3N0SWRlbnRpdHkSLQoSc2lnbmFsaW5nX2VuZHBvaW50GAIg'
    'ASgJUhFzaWduYWxpbmdFbmRwb2ludBIpChFwYWlyZWRfYXRfdW5peF9tcxgDIAEoBFIOcGFpcm'
    'VkQXRVbml4TXMSTwolbGFzdF9zdWNjZXNzZnVsX2Nvbm5lY3Rpb25fYXRfdW5peF9tcxgEIAEo'
    'BFIgbGFzdFN1Y2Nlc3NmdWxDb25uZWN0aW9uQXRVbml4TXMSIwoNZGlzcGxheV9vcmRlchgFIA'
    'EoDVIMZGlzcGxheU9yZGVyEh8KC2xvY2FsX2FsaWFzGAYgASgJUgpsb2NhbEFsaWFz');

@$core.Deprecated('Use trustedHostSnapshotDescriptor instead')
const TrustedHostSnapshot$json = {
  '1': 'TrustedHostSnapshot',
  '2': [
    {
      '1': 'protocol_version',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.ProtocolVersion',
      '10': 'protocolVersion'
    },
    {
      '1': 'bindings',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.roammand.v1.TrustedHostBinding',
      '10': 'bindings'
    },
  ],
};

/// Descriptor for `TrustedHostSnapshot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trustedHostSnapshotDescriptor = $convert.base64Decode(
    'ChNUcnVzdGVkSG9zdFNuYXBzaG90EkcKEHByb3RvY29sX3ZlcnNpb24YASABKAsyHC5yb2FtbW'
    'FuZC52MS5Qcm90b2NvbFZlcnNpb25SD3Byb3RvY29sVmVyc2lvbhI7CghiaW5kaW5ncxgCIAMo'
    'CzIfLnJvYW1tYW5kLnYxLlRydXN0ZWRIb3N0QmluZGluZ1IIYmluZGluZ3M=');

@$core.Deprecated('Use hostPairingStatusSnapshotDescriptor instead')
const HostPairingStatusSnapshot$json = {
  '1': 'HostPairingStatusSnapshot',
  '2': [
    {
      '1': 'state',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.roammand.v1.HostPairingState',
      '10': 'state'
    },
    {'1': 'revision', '3': 2, '4': 1, '5': 4, '10': 'revision'},
    {
      '1': 'invitation',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.HostPairingInvitation',
      '10': 'invitation'
    },
    {
      '1': 'pending_controller',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.DeviceIdentity',
      '10': 'pendingController'
    },
    {
      '1': 'pending_controller_fingerprint_sha256',
      '3': 5,
      '4': 1,
      '5': 12,
      '10': 'pendingControllerFingerprintSha256'
    },
    {'1': 'sas_words', '3': 6, '4': 3, '5': 9, '10': 'sasWords'},
    {
      '1': 'expires_at_unix_ms',
      '3': 7,
      '4': 1,
      '5': 4,
      '10': 'expiresAtUnixMs'
    },
    {
      '1': 'error',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.UnifiedError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `HostPairingStatusSnapshot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hostPairingStatusSnapshotDescriptor = $convert.base64Decode(
    'ChlIb3N0UGFpcmluZ1N0YXR1c1NuYXBzaG90EjMKBXN0YXRlGAEgASgOMh0ucm9hbW1hbmQudj'
    'EuSG9zdFBhaXJpbmdTdGF0ZVIFc3RhdGUSGgoIcmV2aXNpb24YAiABKARSCHJldmlzaW9uEkIK'
    'Cmludml0YXRpb24YAyABKAsyIi5yb2FtbWFuZC52MS5Ib3N0UGFpcmluZ0ludml0YXRpb25SCm'
    'ludml0YXRpb24SSgoScGVuZGluZ19jb250cm9sbGVyGAQgASgLMhsucm9hbW1hbmQudjEuRGV2'
    'aWNlSWRlbnRpdHlSEXBlbmRpbmdDb250cm9sbGVyElEKJXBlbmRpbmdfY29udHJvbGxlcl9maW'
    '5nZXJwcmludF9zaGEyNTYYBSABKAxSInBlbmRpbmdDb250cm9sbGVyRmluZ2VycHJpbnRTaGEy'
    'NTYSGwoJc2FzX3dvcmRzGAYgAygJUghzYXNXb3JkcxIrChJleHBpcmVzX2F0X3VuaXhfbXMYBy'
    'ABKARSD2V4cGlyZXNBdFVuaXhNcxIvCgVlcnJvchgIIAEoCzIZLnJvYW1tYW5kLnYxLlVuaWZp'
    'ZWRFcnJvclIFZXJyb3I=');

@$core.Deprecated('Use pairingMessageDescriptor instead')
const PairingMessage$json = {
  '1': 'PairingMessage',
  '2': [
    {
      '1': 'qr_rendezvous',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.QrPairingRendezvous',
      '9': 0,
      '10': 'qrRendezvous'
    },
    {
      '1': 'desktop_rendezvous',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.DesktopPairingRendezvous',
      '9': 0,
      '10': 'desktopRendezvous'
    },
    {
      '1': 'hello',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PairingHello',
      '9': 0,
      '10': 'hello'
    },
    {
      '1': 'confirmation',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PairingConfirmationData',
      '9': 0,
      '10': 'confirmation'
    },
    {
      '1': 'decision',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PairingDecision',
      '9': 0,
      '10': 'decision'
    },
    {
      '1': 'host_invitation',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.HostPairingInvitation',
      '9': 0,
      '10': 'hostInvitation'
    },
    {
      '1': 'controller_hello',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.ControllerPairingHello',
      '9': 0,
      '10': 'controllerHello'
    },
    {
      '1': 'encrypted_envelope',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.EncryptedPairingEnvelope',
      '9': 0,
      '10': 'encryptedEnvelope'
    },
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `PairingMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pairingMessageDescriptor = $convert.base64Decode(
    'Cg5QYWlyaW5nTWVzc2FnZRJHCg1xcl9yZW5kZXp2b3VzGAEgASgLMiAucm9hbW1hbmQudjEuUX'
    'JQYWlyaW5nUmVuZGV6dm91c0gAUgxxclJlbmRlenZvdXMSVgoSZGVza3RvcF9yZW5kZXp2b3Vz'
    'GAIgASgLMiUucm9hbW1hbmQudjEuRGVza3RvcFBhaXJpbmdSZW5kZXp2b3VzSABSEWRlc2t0b3'
    'BSZW5kZXp2b3VzEjEKBWhlbGxvGAMgASgLMhkucm9hbW1hbmQudjEuUGFpcmluZ0hlbGxvSABS'
    'BWhlbGxvEkoKDGNvbmZpcm1hdGlvbhgEIAEoCzIkLnJvYW1tYW5kLnYxLlBhaXJpbmdDb25maX'
    'JtYXRpb25EYXRhSABSDGNvbmZpcm1hdGlvbhI6CghkZWNpc2lvbhgFIAEoCzIcLnJvYW1tYW5k'
    'LnYxLlBhaXJpbmdEZWNpc2lvbkgAUghkZWNpc2lvbhJNCg9ob3N0X2ludml0YXRpb24YBiABKA'
    'syIi5yb2FtbWFuZC52MS5Ib3N0UGFpcmluZ0ludml0YXRpb25IAFIOaG9zdEludml0YXRpb24S'
    'UAoQY29udHJvbGxlcl9oZWxsbxgHIAEoCzIjLnJvYW1tYW5kLnYxLkNvbnRyb2xsZXJQYWlyaW'
    '5nSGVsbG9IAFIPY29udHJvbGxlckhlbGxvElYKEmVuY3J5cHRlZF9lbnZlbG9wZRgIIAEoCzIl'
    'LnJvYW1tYW5kLnYxLkVuY3J5cHRlZFBhaXJpbmdFbnZlbG9wZUgAUhFlbmNyeXB0ZWRFbnZlbG'
    '9wZUIJCgdwYXlsb2Fk');
