// SPDX-License-Identifier: Apache-2.0

// This is a generated file - do not edit.
//
// Generated from roammand/v1/local_ipc.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use localIpcChallengeDescriptor instead')
const LocalIpcChallenge$json = {
  '1': 'LocalIpcChallenge',
  '2': [
    {
      '1': 'agent_instance_id',
      '3': 1,
      '4': 1,
      '5': 12,
      '10': 'agentInstanceId'
    },
    {'1': 'server_nonce', '3': 2, '4': 1, '5': 12, '10': 'serverNonce'},
  ],
};

/// Descriptor for `LocalIpcChallenge`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List localIpcChallengeDescriptor = $convert.base64Decode(
    'ChFMb2NhbElwY0NoYWxsZW5nZRIqChFhZ2VudF9pbnN0YW5jZV9pZBgBIAEoDFIPYWdlbnRJbn'
    'N0YW5jZUlkEiEKDHNlcnZlcl9ub25jZRgCIAEoDFILc2VydmVyTm9uY2U=');

@$core.Deprecated('Use localIpcAuthenticateDescriptor instead')
const LocalIpcAuthenticate$json = {
  '1': 'LocalIpcAuthenticate',
  '2': [
    {'1': 'client_nonce', '3': 1, '4': 1, '5': 12, '10': 'clientNonce'},
    {'1': 'client_proof', '3': 2, '4': 1, '5': 12, '10': 'clientProof'},
  ],
};

/// Descriptor for `LocalIpcAuthenticate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List localIpcAuthenticateDescriptor = $convert.base64Decode(
    'ChRMb2NhbElwY0F1dGhlbnRpY2F0ZRIhCgxjbGllbnRfbm9uY2UYASABKAxSC2NsaWVudE5vbm'
    'NlEiEKDGNsaWVudF9wcm9vZhgCIAEoDFILY2xpZW50UHJvb2Y=');

@$core.Deprecated('Use localIpcAuthenticatedDescriptor instead')
const LocalIpcAuthenticated$json = {
  '1': 'LocalIpcAuthenticated',
  '2': [
    {'1': 'server_proof', '3': 1, '4': 1, '5': 12, '10': 'serverProof'},
  ],
};

/// Descriptor for `LocalIpcAuthenticated`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List localIpcAuthenticatedDescriptor = $convert.base64Decode(
    'ChVMb2NhbElwY0F1dGhlbnRpY2F0ZWQSIQoMc2VydmVyX3Byb29mGAEgASgMUgtzZXJ2ZXJQcm'
    '9vZg==');

@$core.Deprecated('Use getHostStatusRequestDescriptor instead')
const GetHostStatusRequest$json = {
  '1': 'GetHostStatusRequest',
};

/// Descriptor for `GetHostStatusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getHostStatusRequestDescriptor =
    $convert.base64Decode('ChRHZXRIb3N0U3RhdHVzUmVxdWVzdA==');

@$core.Deprecated('Use hostStatusDescriptor instead')
const HostStatus$json = {
  '1': 'HostStatus',
  '2': [
    {
      '1': 'identity',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.DeviceIdentity',
      '10': 'identity'
    },
    {
      '1': 'agent_instance_id',
      '3': 2,
      '4': 1,
      '5': 12,
      '10': 'agentInstanceId'
    },
    {
      '1': 'agent_started_at_unix_ms',
      '3': 3,
      '4': 1,
      '5': 4,
      '10': 'agentStartedAtUnixMs'
    },
    {
      '1': 'controller_grant_count',
      '3': 4,
      '4': 1,
      '5': 13,
      '10': 'controllerGrantCount'
    },
    {
      '1': 'privileged_bridge',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PrivilegedBridgeStatusSnapshot',
      '10': 'privilegedBridge'
    },
  ],
};

/// Descriptor for `HostStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hostStatusDescriptor = $convert.base64Decode(
    'CgpIb3N0U3RhdHVzEjcKCGlkZW50aXR5GAEgASgLMhsucm9hbW1hbmQudjEuRGV2aWNlSWRlbn'
    'RpdHlSCGlkZW50aXR5EioKEWFnZW50X2luc3RhbmNlX2lkGAIgASgMUg9hZ2VudEluc3RhbmNl'
    'SWQSNgoYYWdlbnRfc3RhcnRlZF9hdF91bml4X21zGAMgASgEUhRhZ2VudFN0YXJ0ZWRBdFVuaX'
    'hNcxI0ChZjb250cm9sbGVyX2dyYW50X2NvdW50GAQgASgNUhRjb250cm9sbGVyR3JhbnRDb3Vu'
    'dBJYChFwcml2aWxlZ2VkX2JyaWRnZRgFIAEoCzIrLnJvYW1tYW5kLnYxLlByaXZpbGVnZWRCcm'
    'lkZ2VTdGF0dXNTbmFwc2hvdFIQcHJpdmlsZWdlZEJyaWRnZQ==');

@$core.Deprecated('Use controllerGrantViewDescriptor instead')
const ControllerGrantView$json = {
  '1': 'ControllerGrantView',
  '2': [
    {
      '1': 'grant',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.ControllerGrant',
      '10': 'grant'
    },
    {
      '1': 'last_successful_connection_at_unix_ms',
      '3': 2,
      '4': 1,
      '5': 4,
      '10': 'lastSuccessfulConnectionAtUnixMs'
    },
  ],
};

/// Descriptor for `ControllerGrantView`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List controllerGrantViewDescriptor = $convert.base64Decode(
    'ChNDb250cm9sbGVyR3JhbnRWaWV3EjIKBWdyYW50GAEgASgLMhwucm9hbW1hbmQudjEuQ29udH'
    'JvbGxlckdyYW50UgVncmFudBJPCiVsYXN0X3N1Y2Nlc3NmdWxfY29ubmVjdGlvbl9hdF91bml4'
    'X21zGAIgASgEUiBsYXN0U3VjY2Vzc2Z1bENvbm5lY3Rpb25BdFVuaXhNcw==');

@$core.Deprecated('Use listControllerGrantsRequestDescriptor instead')
const ListControllerGrantsRequest$json = {
  '1': 'ListControllerGrantsRequest',
};

/// Descriptor for `ListControllerGrantsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listControllerGrantsRequestDescriptor =
    $convert.base64Decode('ChtMaXN0Q29udHJvbGxlckdyYW50c1JlcXVlc3Q=');

@$core.Deprecated('Use controllerGrantListDescriptor instead')
const ControllerGrantList$json = {
  '1': 'ControllerGrantList',
  '2': [
    {
      '1': 'grants',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.roammand.v1.ControllerGrantView',
      '10': 'grants'
    },
  ],
};

/// Descriptor for `ControllerGrantList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List controllerGrantListDescriptor = $convert.base64Decode(
    'ChNDb250cm9sbGVyR3JhbnRMaXN0EjgKBmdyYW50cxgBIAMoCzIgLnJvYW1tYW5kLnYxLkNvbn'
    'Ryb2xsZXJHcmFudFZpZXdSBmdyYW50cw==');

@$core.Deprecated('Use createControllerGrantRequestDescriptor instead')
const CreateControllerGrantRequest$json = {
  '1': 'CreateControllerGrantRequest',
  '2': [
    {
      '1': 'controller',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.DeviceIdentity',
      '10': 'controller'
    },
    {
      '1': 'permissions',
      '3': 2,
      '4': 3,
      '5': 14,
      '6': '.roammand.v1.SessionPermission',
      '10': 'permissions'
    },
  ],
};

/// Descriptor for `CreateControllerGrantRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createControllerGrantRequestDescriptor =
    $convert.base64Decode(
        'ChxDcmVhdGVDb250cm9sbGVyR3JhbnRSZXF1ZXN0EjsKCmNvbnRyb2xsZXIYASABKAsyGy5yb2'
        'FtbWFuZC52MS5EZXZpY2VJZGVudGl0eVIKY29udHJvbGxlchJACgtwZXJtaXNzaW9ucxgCIAMo'
        'DjIeLnJvYW1tYW5kLnYxLlNlc3Npb25QZXJtaXNzaW9uUgtwZXJtaXNzaW9ucw==');

@$core.Deprecated('Use controllerGrantCreatedDescriptor instead')
const ControllerGrantCreated$json = {
  '1': 'ControllerGrantCreated',
  '2': [
    {
      '1': 'grant',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.ControllerGrantView',
      '10': 'grant'
    },
  ],
};

/// Descriptor for `ControllerGrantCreated`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List controllerGrantCreatedDescriptor =
    $convert.base64Decode(
        'ChZDb250cm9sbGVyR3JhbnRDcmVhdGVkEjYKBWdyYW50GAEgASgLMiAucm9hbW1hbmQudjEuQ2'
        '9udHJvbGxlckdyYW50Vmlld1IFZ3JhbnQ=');

@$core.Deprecated('Use signCanonicalTranscriptRequestDescriptor instead')
const SignCanonicalTranscriptRequest$json = {
  '1': 'SignCanonicalTranscriptRequest',
  '2': [
    {
      '1': 'canonical_transcript',
      '3': 1,
      '4': 1,
      '5': 12,
      '10': 'canonicalTranscript'
    },
  ],
};

/// Descriptor for `SignCanonicalTranscriptRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signCanonicalTranscriptRequestDescriptor =
    $convert.base64Decode(
        'Ch5TaWduQ2Fub25pY2FsVHJhbnNjcmlwdFJlcXVlc3QSMQoUY2Fub25pY2FsX3RyYW5zY3JpcH'
        'QYASABKAxSE2Nhbm9uaWNhbFRyYW5zY3JpcHQ=');

@$core.Deprecated('Use canonicalTranscriptSignatureDescriptor instead')
const CanonicalTranscriptSignature$json = {
  '1': 'CanonicalTranscriptSignature',
  '2': [
    {'1': 'host_device_id', '3': 1, '4': 1, '5': 12, '10': 'hostDeviceId'},
    {'1': 'host_public_key', '3': 2, '4': 1, '5': 12, '10': 'hostPublicKey'},
    {'1': 'signature', '3': 3, '4': 1, '5': 12, '10': 'signature'},
    {
      '1': 'transcript_sha256',
      '3': 4,
      '4': 1,
      '5': 12,
      '10': 'transcriptSha256'
    },
  ],
};

/// Descriptor for `CanonicalTranscriptSignature`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List canonicalTranscriptSignatureDescriptor = $convert.base64Decode(
    'ChxDYW5vbmljYWxUcmFuc2NyaXB0U2lnbmF0dXJlEiQKDmhvc3RfZGV2aWNlX2lkGAEgASgMUg'
    'xob3N0RGV2aWNlSWQSJgoPaG9zdF9wdWJsaWNfa2V5GAIgASgMUg1ob3N0UHVibGljS2V5EhwK'
    'CXNpZ25hdHVyZRgDIAEoDFIJc2lnbmF0dXJlEisKEXRyYW5zY3JpcHRfc2hhMjU2GAQgASgMUh'
    'B0cmFuc2NyaXB0U2hhMjU2');

@$core.Deprecated('Use signSessionOfferRequestDescriptor instead')
const SignSessionOfferRequest$json = {
  '1': 'SignSessionOfferRequest',
  '2': [
    {
      '1': 'canonical_transcript',
      '3': 1,
      '4': 1,
      '5': 12,
      '10': 'canonicalTranscript'
    },
  ],
};

/// Descriptor for `SignSessionOfferRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signSessionOfferRequestDescriptor =
    $convert.base64Decode(
        'ChdTaWduU2Vzc2lvbk9mZmVyUmVxdWVzdBIxChRjYW5vbmljYWxfdHJhbnNjcmlwdBgBIAEoDF'
        'ITY2Fub25pY2FsVHJhbnNjcmlwdA==');

@$core.Deprecated('Use sessionOfferSignatureDescriptor instead')
const SessionOfferSignature$json = {
  '1': 'SessionOfferSignature',
  '2': [
    {
      '1': 'controller_device_id',
      '3': 1,
      '4': 1,
      '5': 12,
      '10': 'controllerDeviceId'
    },
    {
      '1': 'controller_public_key',
      '3': 2,
      '4': 1,
      '5': 12,
      '10': 'controllerPublicKey'
    },
    {'1': 'signature', '3': 3, '4': 1, '5': 12, '10': 'signature'},
    {
      '1': 'transcript_sha256',
      '3': 4,
      '4': 1,
      '5': 12,
      '10': 'transcriptSha256'
    },
  ],
};

/// Descriptor for `SessionOfferSignature`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionOfferSignatureDescriptor = $convert.base64Decode(
    'ChVTZXNzaW9uT2ZmZXJTaWduYXR1cmUSMAoUY29udHJvbGxlcl9kZXZpY2VfaWQYASABKAxSEm'
    'NvbnRyb2xsZXJEZXZpY2VJZBIyChVjb250cm9sbGVyX3B1YmxpY19rZXkYAiABKAxSE2NvbnRy'
    'b2xsZXJQdWJsaWNLZXkSHAoJc2lnbmF0dXJlGAMgASgMUglzaWduYXR1cmUSKwoRdHJhbnNjcm'
    'lwdF9zaGEyNTYYBCABKAxSEHRyYW5zY3JpcHRTaGEyNTY=');

@$core.Deprecated('Use getRemoteSessionStatusRequestDescriptor instead')
const GetRemoteSessionStatusRequest$json = {
  '1': 'GetRemoteSessionStatusRequest',
};

/// Descriptor for `GetRemoteSessionStatusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getRemoteSessionStatusRequestDescriptor =
    $convert.base64Decode('Ch1HZXRSZW1vdGVTZXNzaW9uU3RhdHVzUmVxdWVzdA==');

@$core.Deprecated('Use remoteSessionStatusSnapshotDescriptor instead')
const RemoteSessionStatusSnapshot$json = {
  '1': 'RemoteSessionStatusSnapshot',
  '2': [
    {
      '1': 'session_status',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.SessionStatus',
      '10': 'sessionStatus'
    },
    {
      '1': 'controller_device_id',
      '3': 2,
      '4': 1,
      '5': 12,
      '10': 'controllerDeviceId'
    },
  ],
};

/// Descriptor for `RemoteSessionStatusSnapshot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List remoteSessionStatusSnapshotDescriptor =
    $convert.base64Decode(
        'ChtSZW1vdGVTZXNzaW9uU3RhdHVzU25hcHNob3QSQQoOc2Vzc2lvbl9zdGF0dXMYASABKAsyGi'
        '5yb2FtbWFuZC52MS5TZXNzaW9uU3RhdHVzUg1zZXNzaW9uU3RhdHVzEjAKFGNvbnRyb2xsZXJf'
        'ZGV2aWNlX2lkGAIgASgMUhJjb250cm9sbGVyRGV2aWNlSWQ=');

@$core.Deprecated('Use startHostQrPairingRequestDescriptor instead')
const StartHostQrPairingRequest$json = {
  '1': 'StartHostQrPairingRequest',
  '2': [
    {
      '1': 'signaling_endpoint',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'signalingEndpoint'
    },
  ],
};

/// Descriptor for `StartHostQrPairingRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startHostQrPairingRequestDescriptor =
    $convert.base64Decode(
        'ChlTdGFydEhvc3RRclBhaXJpbmdSZXF1ZXN0Ei0KEnNpZ25hbGluZ19lbmRwb2ludBgBIAEoCV'
        'IRc2lnbmFsaW5nRW5kcG9pbnQ=');

@$core.Deprecated('Use startHostDesktopCodePairingRequestDescriptor instead')
const StartHostDesktopCodePairingRequest$json = {
  '1': 'StartHostDesktopCodePairingRequest',
  '2': [
    {
      '1': 'signaling_endpoint',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'signalingEndpoint'
    },
  ],
};

/// Descriptor for `StartHostDesktopCodePairingRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startHostDesktopCodePairingRequestDescriptor =
    $convert.base64Decode(
        'CiJTdGFydEhvc3REZXNrdG9wQ29kZVBhaXJpbmdSZXF1ZXN0Ei0KEnNpZ25hbGluZ19lbmRwb2'
        'ludBgBIAEoCVIRc2lnbmFsaW5nRW5kcG9pbnQ=');

@$core.Deprecated('Use cancelHostPairingRequestDescriptor instead')
const CancelHostPairingRequest$json = {
  '1': 'CancelHostPairingRequest',
  '2': [
    {'1': 'rendezvous_id', '3': 1, '4': 1, '5': 12, '10': 'rendezvousId'},
  ],
};

/// Descriptor for `CancelHostPairingRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cancelHostPairingRequestDescriptor =
    $convert.base64Decode(
        'ChhDYW5jZWxIb3N0UGFpcmluZ1JlcXVlc3QSIwoNcmVuZGV6dm91c19pZBgBIAEoDFIMcmVuZG'
        'V6dm91c0lk');

@$core.Deprecated('Use getHostPairingStatusRequestDescriptor instead')
const GetHostPairingStatusRequest$json = {
  '1': 'GetHostPairingStatusRequest',
};

/// Descriptor for `GetHostPairingStatusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getHostPairingStatusRequestDescriptor =
    $convert.base64Decode('ChtHZXRIb3N0UGFpcmluZ1N0YXR1c1JlcXVlc3Q=');

@$core.Deprecated('Use acceptHostPairingRequestDescriptor instead')
const AcceptHostPairingRequest$json = {
  '1': 'AcceptHostPairingRequest',
  '2': [
    {'1': 'rendezvous_id', '3': 1, '4': 1, '5': 12, '10': 'rendezvousId'},
    {
      '1': 'controller_device_id',
      '3': 2,
      '4': 1,
      '5': 12,
      '10': 'controllerDeviceId'
    },
  ],
};

/// Descriptor for `AcceptHostPairingRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List acceptHostPairingRequestDescriptor = $convert.base64Decode(
    'ChhBY2NlcHRIb3N0UGFpcmluZ1JlcXVlc3QSIwoNcmVuZGV6dm91c19pZBgBIAEoDFIMcmVuZG'
    'V6dm91c0lkEjAKFGNvbnRyb2xsZXJfZGV2aWNlX2lkGAIgASgMUhJjb250cm9sbGVyRGV2aWNl'
    'SWQ=');

@$core.Deprecated('Use rejectHostPairingRequestDescriptor instead')
const RejectHostPairingRequest$json = {
  '1': 'RejectHostPairingRequest',
  '2': [
    {'1': 'rendezvous_id', '3': 1, '4': 1, '5': 12, '10': 'rendezvousId'},
    {
      '1': 'controller_device_id',
      '3': 2,
      '4': 1,
      '5': 12,
      '10': 'controllerDeviceId'
    },
  ],
};

/// Descriptor for `RejectHostPairingRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rejectHostPairingRequestDescriptor = $convert.base64Decode(
    'ChhSZWplY3RIb3N0UGFpcmluZ1JlcXVlc3QSIwoNcmVuZGV6dm91c19pZBgBIAEoDFIMcmVuZG'
    'V6dm91c0lkEjAKFGNvbnRyb2xsZXJfZGV2aWNlX2lkGAIgASgMUhJjb250cm9sbGVyRGV2aWNl'
    'SWQ=');

@$core.Deprecated('Use signPairingTranscriptRequestDescriptor instead')
const SignPairingTranscriptRequest$json = {
  '1': 'SignPairingTranscriptRequest',
  '2': [
    {
      '1': 'canonical_transcript',
      '3': 1,
      '4': 1,
      '5': 12,
      '10': 'canonicalTranscript'
    },
    {
      '1': 'role',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.roammand.v1.PairingIdentityRole',
      '10': 'role'
    },
  ],
};

/// Descriptor for `SignPairingTranscriptRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signPairingTranscriptRequestDescriptor =
    $convert.base64Decode(
        'ChxTaWduUGFpcmluZ1RyYW5zY3JpcHRSZXF1ZXN0EjEKFGNhbm9uaWNhbF90cmFuc2NyaXB0GA'
        'EgASgMUhNjYW5vbmljYWxUcmFuc2NyaXB0EjQKBHJvbGUYAiABKA4yIC5yb2FtbWFuZC52MS5Q'
        'YWlyaW5nSWRlbnRpdHlSb2xlUgRyb2xl');

@$core.Deprecated('Use pairingTranscriptSignatureDescriptor instead')
const PairingTranscriptSignature$json = {
  '1': 'PairingTranscriptSignature',
  '2': [
    {
      '1': 'role',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.roammand.v1.PairingIdentityRole',
      '10': 'role'
    },
    {'1': 'signer_device_id', '3': 2, '4': 1, '5': 12, '10': 'signerDeviceId'},
    {
      '1': 'signer_public_key',
      '3': 3,
      '4': 1,
      '5': 12,
      '10': 'signerPublicKey'
    },
    {'1': 'signature', '3': 4, '4': 1, '5': 12, '10': 'signature'},
    {
      '1': 'transcript_sha256',
      '3': 5,
      '4': 1,
      '5': 12,
      '10': 'transcriptSha256'
    },
  ],
};

/// Descriptor for `PairingTranscriptSignature`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pairingTranscriptSignatureDescriptor = $convert.base64Decode(
    'ChpQYWlyaW5nVHJhbnNjcmlwdFNpZ25hdHVyZRI0CgRyb2xlGAEgASgOMiAucm9hbW1hbmQudj'
    'EuUGFpcmluZ0lkZW50aXR5Um9sZVIEcm9sZRIoChBzaWduZXJfZGV2aWNlX2lkGAIgASgMUg5z'
    'aWduZXJEZXZpY2VJZBIqChFzaWduZXJfcHVibGljX2tleRgDIAEoDFIPc2lnbmVyUHVibGljS2'
    'V5EhwKCXNpZ25hdHVyZRgEIAEoDFIJc2lnbmF0dXJlEisKEXRyYW5zY3JpcHRfc2hhMjU2GAUg'
    'ASgMUhB0cmFuc2NyaXB0U2hhMjU2');

@$core.Deprecated('Use hostPairingStateChangedEventDescriptor instead')
const HostPairingStateChangedEvent$json = {
  '1': 'HostPairingStateChangedEvent',
  '2': [
    {
      '1': 'status',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.HostPairingStatusSnapshot',
      '10': 'status'
    },
  ],
};

/// Descriptor for `HostPairingStateChangedEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hostPairingStateChangedEventDescriptor =
    $convert.base64Decode(
        'ChxIb3N0UGFpcmluZ1N0YXRlQ2hhbmdlZEV2ZW50Ej4KBnN0YXR1cxgBIAEoCzImLnJvYW1tYW'
        '5kLnYxLkhvc3RQYWlyaW5nU3RhdHVzU25hcHNob3RSBnN0YXR1cw==');

@$core.Deprecated('Use revokeControllerGrantRequestDescriptor instead')
const RevokeControllerGrantRequest$json = {
  '1': 'RevokeControllerGrantRequest',
  '2': [
    {'1': 'grant_id', '3': 1, '4': 1, '5': 12, '10': 'grantId'},
  ],
};

/// Descriptor for `RevokeControllerGrantRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List revokeControllerGrantRequestDescriptor =
    $convert.base64Decode(
        'ChxSZXZva2VDb250cm9sbGVyR3JhbnRSZXF1ZXN0EhkKCGdyYW50X2lkGAEgASgMUgdncmFudE'
        'lk');

@$core.Deprecated('Use controllerGrantRevokedDescriptor instead')
const ControllerGrantRevoked$json = {
  '1': 'ControllerGrantRevoked',
  '2': [
    {'1': 'grant_id', '3': 1, '4': 1, '5': 12, '10': 'grantId'},
    {
      '1': 'terminated_session_count',
      '3': 2,
      '4': 1,
      '5': 13,
      '10': 'terminatedSessionCount'
    },
  ],
};

/// Descriptor for `ControllerGrantRevoked`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List controllerGrantRevokedDescriptor = $convert.base64Decode(
    'ChZDb250cm9sbGVyR3JhbnRSZXZva2VkEhkKCGdyYW50X2lkGAEgASgMUgdncmFudElkEjgKGH'
    'Rlcm1pbmF0ZWRfc2Vzc2lvbl9jb3VudBgCIAEoDVIWdGVybWluYXRlZFNlc3Npb25Db3VudA==');

@$core.Deprecated('Use sessionTerminatedEventDescriptor instead')
const SessionTerminatedEvent$json = {
  '1': 'SessionTerminatedEvent',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 12, '10': 'sessionId'},
    {
      '1': 'controller_device_id',
      '3': 2,
      '4': 1,
      '5': 12,
      '10': 'controllerDeviceId'
    },
    {
      '1': 'reason',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.roammand.v1.ErrorCode',
      '10': 'reason'
    },
  ],
};

/// Descriptor for `SessionTerminatedEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionTerminatedEventDescriptor = $convert.base64Decode(
    'ChZTZXNzaW9uVGVybWluYXRlZEV2ZW50Eh0KCnNlc3Npb25faWQYASABKAxSCXNlc3Npb25JZB'
    'IwChRjb250cm9sbGVyX2RldmljZV9pZBgCIAEoDFISY29udHJvbGxlckRldmljZUlkEi4KBnJl'
    'YXNvbhgDIAEoDjIWLnJvYW1tYW5kLnYxLkVycm9yQ29kZVIGcmVhc29u');

@$core.Deprecated('Use hostAuthorizationSnapshotDescriptor instead')
const HostAuthorizationSnapshot$json = {
  '1': 'HostAuthorizationSnapshot',
  '2': [
    {'1': 'host_device_id', '3': 1, '4': 1, '5': 12, '10': 'hostDeviceId'},
    {
      '1': 'grants',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.roammand.v1.ControllerGrantView',
      '10': 'grants'
    },
  ],
};

/// Descriptor for `HostAuthorizationSnapshot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hostAuthorizationSnapshotDescriptor = $convert.base64Decode(
    'ChlIb3N0QXV0aG9yaXphdGlvblNuYXBzaG90EiQKDmhvc3RfZGV2aWNlX2lkGAEgASgMUgxob3'
    'N0RGV2aWNlSWQSOAoGZ3JhbnRzGAIgAygLMiAucm9hbW1hbmQudjEuQ29udHJvbGxlckdyYW50'
    'Vmlld1IGZ3JhbnRz');

@$core.Deprecated('Use emergencyStopRemoteSessionRequestDescriptor instead')
const EmergencyStopRemoteSessionRequest$json = {
  '1': 'EmergencyStopRemoteSessionRequest',
};

/// Descriptor for `EmergencyStopRemoteSessionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List emergencyStopRemoteSessionRequestDescriptor =
    $convert.base64Decode('CiFFbWVyZ2VuY3lTdG9wUmVtb3RlU2Vzc2lvblJlcXVlc3Q=');

@$core.Deprecated('Use emergencyStopRemoteSessionResultDescriptor instead')
const EmergencyStopRemoteSessionResult$json = {
  '1': 'EmergencyStopRemoteSessionResult',
  '2': [
    {
      '1': 'terminated_session_count',
      '3': 1,
      '4': 1,
      '5': 13,
      '10': 'terminatedSessionCount'
    },
  ],
};

/// Descriptor for `EmergencyStopRemoteSessionResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List emergencyStopRemoteSessionResultDescriptor =
    $convert.base64Decode(
        'CiBFbWVyZ2VuY3lTdG9wUmVtb3RlU2Vzc2lvblJlc3VsdBI4Chh0ZXJtaW5hdGVkX3Nlc3Npb2'
        '5fY291bnQYASABKA1SFnRlcm1pbmF0ZWRTZXNzaW9uQ291bnQ=');

@$core.Deprecated('Use localIpcClientFrameDescriptor instead')
const LocalIpcClientFrame$json = {
  '1': 'LocalIpcClientFrame',
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
    {
      '1': 'authenticate',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.LocalIpcAuthenticate',
      '9': 0,
      '10': 'authenticate'
    },
    {
      '1': 'get_host_status',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.GetHostStatusRequest',
      '9': 0,
      '10': 'getHostStatus'
    },
    {
      '1': 'list_controller_grants',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.ListControllerGrantsRequest',
      '9': 0,
      '10': 'listControllerGrants'
    },
    {
      '1': 'create_controller_grant',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.CreateControllerGrantRequest',
      '9': 0,
      '10': 'createControllerGrant'
    },
    {
      '1': 'sign_canonical_transcript',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.SignCanonicalTranscriptRequest',
      '9': 0,
      '10': 'signCanonicalTranscript'
    },
    {
      '1': 'revoke_controller_grant',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.RevokeControllerGrantRequest',
      '9': 0,
      '10': 'revokeControllerGrant'
    },
    {
      '1': 'sign_session_offer',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.SignSessionOfferRequest',
      '9': 0,
      '10': 'signSessionOffer'
    },
    {
      '1': 'get_remote_session_status',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.GetRemoteSessionStatusRequest',
      '9': 0,
      '10': 'getRemoteSessionStatus'
    },
    {
      '1': 'start_host_qr_pairing',
      '3': 18,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.StartHostQrPairingRequest',
      '9': 0,
      '10': 'startHostQrPairing'
    },
    {
      '1': 'start_host_desktop_code_pairing',
      '3': 19,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.StartHostDesktopCodePairingRequest',
      '9': 0,
      '10': 'startHostDesktopCodePairing'
    },
    {
      '1': 'cancel_host_pairing',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.CancelHostPairingRequest',
      '9': 0,
      '10': 'cancelHostPairing'
    },
    {
      '1': 'get_host_pairing_status',
      '3': 21,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.GetHostPairingStatusRequest',
      '9': 0,
      '10': 'getHostPairingStatus'
    },
    {
      '1': 'accept_host_pairing',
      '3': 22,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.AcceptHostPairingRequest',
      '9': 0,
      '10': 'acceptHostPairing'
    },
    {
      '1': 'reject_host_pairing',
      '3': 23,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.RejectHostPairingRequest',
      '9': 0,
      '10': 'rejectHostPairing'
    },
    {
      '1': 'sign_pairing_transcript',
      '3': 24,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.SignPairingTranscriptRequest',
      '9': 0,
      '10': 'signPairingTranscript'
    },
    {
      '1': 'emergency_stop_remote_session',
      '3': 25,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.EmergencyStopRemoteSessionRequest',
      '9': 0,
      '10': 'emergencyStopRemoteSession'
    },
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `LocalIpcClientFrame`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List localIpcClientFrameDescriptor = $convert.base64Decode(
    'ChNMb2NhbElwY0NsaWVudEZyYW1lEkcKEHByb3RvY29sX3ZlcnNpb24YASABKAsyHC5yb2FtbW'
    'FuZC52MS5Qcm90b2NvbFZlcnNpb25SD3Byb3RvY29sVmVyc2lvbhIdCgpyZXF1ZXN0X2lkGAIg'
    'ASgJUglyZXF1ZXN0SWQSRwoMYXV0aGVudGljYXRlGAogASgLMiEucm9hbW1hbmQudjEuTG9jYW'
    'xJcGNBdXRoZW50aWNhdGVIAFIMYXV0aGVudGljYXRlEksKD2dldF9ob3N0X3N0YXR1cxgLIAEo'
    'CzIhLnJvYW1tYW5kLnYxLkdldEhvc3RTdGF0dXNSZXF1ZXN0SABSDWdldEhvc3RTdGF0dXMSYA'
    'oWbGlzdF9jb250cm9sbGVyX2dyYW50cxgMIAEoCzIoLnJvYW1tYW5kLnYxLkxpc3RDb250cm9s'
    'bGVyR3JhbnRzUmVxdWVzdEgAUhRsaXN0Q29udHJvbGxlckdyYW50cxJjChdjcmVhdGVfY29udH'
    'JvbGxlcl9ncmFudBgNIAEoCzIpLnJvYW1tYW5kLnYxLkNyZWF0ZUNvbnRyb2xsZXJHcmFudFJl'
    'cXVlc3RIAFIVY3JlYXRlQ29udHJvbGxlckdyYW50EmkKGXNpZ25fY2Fub25pY2FsX3RyYW5zY3'
    'JpcHQYDiABKAsyKy5yb2FtbWFuZC52MS5TaWduQ2Fub25pY2FsVHJhbnNjcmlwdFJlcXVlc3RI'
    'AFIXc2lnbkNhbm9uaWNhbFRyYW5zY3JpcHQSYwoXcmV2b2tlX2NvbnRyb2xsZXJfZ3JhbnQYDy'
    'ABKAsyKS5yb2FtbWFuZC52MS5SZXZva2VDb250cm9sbGVyR3JhbnRSZXF1ZXN0SABSFXJldm9r'
    'ZUNvbnRyb2xsZXJHcmFudBJUChJzaWduX3Nlc3Npb25fb2ZmZXIYECABKAsyJC5yb2FtbWFuZC'
    '52MS5TaWduU2Vzc2lvbk9mZmVyUmVxdWVzdEgAUhBzaWduU2Vzc2lvbk9mZmVyEmcKGWdldF9y'
    'ZW1vdGVfc2Vzc2lvbl9zdGF0dXMYESABKAsyKi5yb2FtbWFuZC52MS5HZXRSZW1vdGVTZXNzaW'
    '9uU3RhdHVzUmVxdWVzdEgAUhZnZXRSZW1vdGVTZXNzaW9uU3RhdHVzElsKFXN0YXJ0X2hvc3Rf'
    'cXJfcGFpcmluZxgSIAEoCzImLnJvYW1tYW5kLnYxLlN0YXJ0SG9zdFFyUGFpcmluZ1JlcXVlc3'
    'RIAFISc3RhcnRIb3N0UXJQYWlyaW5nEncKH3N0YXJ0X2hvc3RfZGVza3RvcF9jb2RlX3BhaXJp'
    'bmcYEyABKAsyLy5yb2FtbWFuZC52MS5TdGFydEhvc3REZXNrdG9wQ29kZVBhaXJpbmdSZXF1ZX'
    'N0SABSG3N0YXJ0SG9zdERlc2t0b3BDb2RlUGFpcmluZxJXChNjYW5jZWxfaG9zdF9wYWlyaW5n'
    'GBQgASgLMiUucm9hbW1hbmQudjEuQ2FuY2VsSG9zdFBhaXJpbmdSZXF1ZXN0SABSEWNhbmNlbE'
    'hvc3RQYWlyaW5nEmEKF2dldF9ob3N0X3BhaXJpbmdfc3RhdHVzGBUgASgLMigucm9hbW1hbmQu'
    'djEuR2V0SG9zdFBhaXJpbmdTdGF0dXNSZXF1ZXN0SABSFGdldEhvc3RQYWlyaW5nU3RhdHVzEl'
    'cKE2FjY2VwdF9ob3N0X3BhaXJpbmcYFiABKAsyJS5yb2FtbWFuZC52MS5BY2NlcHRIb3N0UGFp'
    'cmluZ1JlcXVlc3RIAFIRYWNjZXB0SG9zdFBhaXJpbmcSVwoTcmVqZWN0X2hvc3RfcGFpcmluZx'
    'gXIAEoCzIlLnJvYW1tYW5kLnYxLlJlamVjdEhvc3RQYWlyaW5nUmVxdWVzdEgAUhFyZWplY3RI'
    'b3N0UGFpcmluZxJjChdzaWduX3BhaXJpbmdfdHJhbnNjcmlwdBgYIAEoCzIpLnJvYW1tYW5kLn'
    'YxLlNpZ25QYWlyaW5nVHJhbnNjcmlwdFJlcXVlc3RIAFIVc2lnblBhaXJpbmdUcmFuc2NyaXB0'
    'EnMKHWVtZXJnZW5jeV9zdG9wX3JlbW90ZV9zZXNzaW9uGBkgASgLMi4ucm9hbW1hbmQudjEuRW'
    '1lcmdlbmN5U3RvcFJlbW90ZVNlc3Npb25SZXF1ZXN0SABSGmVtZXJnZW5jeVN0b3BSZW1vdGVT'
    'ZXNzaW9uQgkKB3BheWxvYWQ=');

@$core.Deprecated('Use localIpcServerFrameDescriptor instead')
const LocalIpcServerFrame$json = {
  '1': 'LocalIpcServerFrame',
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
    {
      '1': 'challenge',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.LocalIpcChallenge',
      '9': 0,
      '10': 'challenge'
    },
    {
      '1': 'authenticated',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.LocalIpcAuthenticated',
      '9': 0,
      '10': 'authenticated'
    },
    {
      '1': 'host_status',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.HostStatus',
      '9': 0,
      '10': 'hostStatus'
    },
    {
      '1': 'controller_grant_list',
      '3': 21,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.ControllerGrantList',
      '9': 0,
      '10': 'controllerGrantList'
    },
    {
      '1': 'controller_grant_created',
      '3': 22,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.ControllerGrantCreated',
      '9': 0,
      '10': 'controllerGrantCreated'
    },
    {
      '1': 'canonical_transcript_signature',
      '3': 23,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.CanonicalTranscriptSignature',
      '9': 0,
      '10': 'canonicalTranscriptSignature'
    },
    {
      '1': 'controller_grant_revoked',
      '3': 24,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.ControllerGrantRevoked',
      '9': 0,
      '10': 'controllerGrantRevoked'
    },
    {
      '1': 'session_offer_signature',
      '3': 25,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.SessionOfferSignature',
      '9': 0,
      '10': 'sessionOfferSignature'
    },
    {
      '1': 'remote_session_status',
      '3': 26,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.RemoteSessionStatusSnapshot',
      '9': 0,
      '10': 'remoteSessionStatus'
    },
    {
      '1': 'session_terminated',
      '3': 28,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.SessionTerminatedEvent',
      '9': 0,
      '10': 'sessionTerminated'
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
    {
      '1': 'host_pairing_status',
      '3': 30,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.HostPairingStatusSnapshot',
      '9': 0,
      '10': 'hostPairingStatus'
    },
    {
      '1': 'pairing_transcript_signature',
      '3': 31,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PairingTranscriptSignature',
      '9': 0,
      '10': 'pairingTranscriptSignature'
    },
    {
      '1': 'host_pairing_state_changed',
      '3': 32,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.HostPairingStateChangedEvent',
      '9': 0,
      '10': 'hostPairingStateChanged'
    },
    {
      '1': 'emergency_stop_remote_session_result',
      '3': 33,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.EmergencyStopRemoteSessionResult',
      '9': 0,
      '10': 'emergencyStopRemoteSessionResult'
    },
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `LocalIpcServerFrame`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List localIpcServerFrameDescriptor = $convert.base64Decode(
    'ChNMb2NhbElwY1NlcnZlckZyYW1lEkcKEHByb3RvY29sX3ZlcnNpb24YASABKAsyHC5yb2FtbW'
    'FuZC52MS5Qcm90b2NvbFZlcnNpb25SD3Byb3RvY29sVmVyc2lvbhIdCgpyZXF1ZXN0X2lkGAIg'
    'ASgJUglyZXF1ZXN0SWQSPgoJY2hhbGxlbmdlGAogASgLMh4ucm9hbW1hbmQudjEuTG9jYWxJcG'
    'NDaGFsbGVuZ2VIAFIJY2hhbGxlbmdlEkoKDWF1dGhlbnRpY2F0ZWQYCyABKAsyIi5yb2FtbWFu'
    'ZC52MS5Mb2NhbElwY0F1dGhlbnRpY2F0ZWRIAFINYXV0aGVudGljYXRlZBI6Cgtob3N0X3N0YX'
    'R1cxgUIAEoCzIXLnJvYW1tYW5kLnYxLkhvc3RTdGF0dXNIAFIKaG9zdFN0YXR1cxJWChVjb250'
    'cm9sbGVyX2dyYW50X2xpc3QYFSABKAsyIC5yb2FtbWFuZC52MS5Db250cm9sbGVyR3JhbnRMaX'
    'N0SABSE2NvbnRyb2xsZXJHcmFudExpc3QSXwoYY29udHJvbGxlcl9ncmFudF9jcmVhdGVkGBYg'
    'ASgLMiMucm9hbW1hbmQudjEuQ29udHJvbGxlckdyYW50Q3JlYXRlZEgAUhZjb250cm9sbGVyR3'
    'JhbnRDcmVhdGVkEnEKHmNhbm9uaWNhbF90cmFuc2NyaXB0X3NpZ25hdHVyZRgXIAEoCzIpLnJv'
    'YW1tYW5kLnYxLkNhbm9uaWNhbFRyYW5zY3JpcHRTaWduYXR1cmVIAFIcY2Fub25pY2FsVHJhbn'
    'NjcmlwdFNpZ25hdHVyZRJfChhjb250cm9sbGVyX2dyYW50X3Jldm9rZWQYGCABKAsyIy5yb2Ft'
    'bWFuZC52MS5Db250cm9sbGVyR3JhbnRSZXZva2VkSABSFmNvbnRyb2xsZXJHcmFudFJldm9rZW'
    'QSXAoXc2Vzc2lvbl9vZmZlcl9zaWduYXR1cmUYGSABKAsyIi5yb2FtbWFuZC52MS5TZXNzaW9u'
    'T2ZmZXJTaWduYXR1cmVIAFIVc2Vzc2lvbk9mZmVyU2lnbmF0dXJlEl4KFXJlbW90ZV9zZXNzaW'
    '9uX3N0YXR1cxgaIAEoCzIoLnJvYW1tYW5kLnYxLlJlbW90ZVNlc3Npb25TdGF0dXNTbmFwc2hv'
    'dEgAUhNyZW1vdGVTZXNzaW9uU3RhdHVzElQKEnNlc3Npb25fdGVybWluYXRlZBgcIAEoCzIjLn'
    'JvYW1tYW5kLnYxLlNlc3Npb25UZXJtaW5hdGVkRXZlbnRIAFIRc2Vzc2lvblRlcm1pbmF0ZWQS'
    'MQoFZXJyb3IYHSABKAsyGS5yb2FtbWFuZC52MS5VbmlmaWVkRXJyb3JIAFIFZXJyb3ISWAoTaG'
    '9zdF9wYWlyaW5nX3N0YXR1cxgeIAEoCzImLnJvYW1tYW5kLnYxLkhvc3RQYWlyaW5nU3RhdHVz'
    'U25hcHNob3RIAFIRaG9zdFBhaXJpbmdTdGF0dXMSawoccGFpcmluZ190cmFuc2NyaXB0X3NpZ2'
    '5hdHVyZRgfIAEoCzInLnJvYW1tYW5kLnYxLlBhaXJpbmdUcmFuc2NyaXB0U2lnbmF0dXJlSABS'
    'GnBhaXJpbmdUcmFuc2NyaXB0U2lnbmF0dXJlEmgKGmhvc3RfcGFpcmluZ19zdGF0ZV9jaGFuZ2'
    'VkGCAgASgLMikucm9hbW1hbmQudjEuSG9zdFBhaXJpbmdTdGF0ZUNoYW5nZWRFdmVudEgAUhdo'
    'b3N0UGFpcmluZ1N0YXRlQ2hhbmdlZBJ/CiRlbWVyZ2VuY3lfc3RvcF9yZW1vdGVfc2Vzc2lvbl'
    '9yZXN1bHQYISABKAsyLS5yb2FtbWFuZC52MS5FbWVyZ2VuY3lTdG9wUmVtb3RlU2Vzc2lvblJl'
    'c3VsdEgAUiBlbWVyZ2VuY3lTdG9wUmVtb3RlU2Vzc2lvblJlc3VsdEIJCgdwYXlsb2Fk');
