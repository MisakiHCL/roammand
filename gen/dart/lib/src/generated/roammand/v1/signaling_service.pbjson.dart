// SPDX-License-Identifier: Apache-2.0

// This is a generated file - do not edit.
//
// Generated from roammand/v1/signaling_service.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use pairingRendezvousKindDescriptor instead')
const PairingRendezvousKind$json = {
  '1': 'PairingRendezvousKind',
  '2': [
    {'1': 'PAIRING_RENDEZVOUS_KIND_UNSPECIFIED', '2': 0},
    {'1': 'PAIRING_RENDEZVOUS_KIND_QR', '2': 1},
    {'1': 'PAIRING_RENDEZVOUS_KIND_DESKTOP_CODE', '2': 2},
  ],
};

/// Descriptor for `PairingRendezvousKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List pairingRendezvousKindDescriptor = $convert.base64Decode(
    'ChVQYWlyaW5nUmVuZGV6dm91c0tpbmQSJwojUEFJUklOR19SRU5ERVpWT1VTX0tJTkRfVU5TUE'
    'VDSUZJRUQQABIeChpQQUlSSU5HX1JFTkRFWlZPVVNfS0lORF9RUhABEigKJFBBSVJJTkdfUkVO'
    'REVaVk9VU19LSU5EX0RFU0tUT1BfQ09ERRAC');

@$core.Deprecated('Use pairingRendezvousCompletionDescriptor instead')
const PairingRendezvousCompletion$json = {
  '1': 'PairingRendezvousCompletion',
  '2': [
    {'1': 'PAIRING_RENDEZVOUS_COMPLETION_UNSPECIFIED', '2': 0},
    {'1': 'PAIRING_RENDEZVOUS_COMPLETION_SUCCEEDED', '2': 1},
    {'1': 'PAIRING_RENDEZVOUS_COMPLETION_REJECTED', '2': 2},
    {'1': 'PAIRING_RENDEZVOUS_COMPLETION_EXPIRED', '2': 3},
    {'1': 'PAIRING_RENDEZVOUS_COMPLETION_DISCONNECTED', '2': 4},
  ],
};

/// Descriptor for `PairingRendezvousCompletion`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List pairingRendezvousCompletionDescriptor = $convert.base64Decode(
    'ChtQYWlyaW5nUmVuZGV6dm91c0NvbXBsZXRpb24SLQopUEFJUklOR19SRU5ERVpWT1VTX0NPTV'
    'BMRVRJT05fVU5TUEVDSUZJRUQQABIrCidQQUlSSU5HX1JFTkRFWlZPVVNfQ09NUExFVElPTl9T'
    'VUNDRUVERUQQARIqCiZQQUlSSU5HX1JFTkRFWlZPVVNfQ09NUExFVElPTl9SRUpFQ1RFRBACEi'
    'kKJVBBSVJJTkdfUkVOREVaVk9VU19DT01QTEVUSU9OX0VYUElSRUQQAxIuCipQQUlSSU5HX1JF'
    'TkRFWlZPVVNfQ09NUExFVElPTl9ESVNDT05ORUNURUQQBA==');

@$core.Deprecated('Use registerDeviceDescriptor instead')
const RegisterDevice$json = {
  '1': 'RegisterDevice',
  '2': [
    {'1': 'device_id', '3': 1, '4': 1, '5': 12, '10': 'deviceId'},
  ],
};

/// Descriptor for `RegisterDevice`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List registerDeviceDescriptor = $convert.base64Decode(
    'Cg5SZWdpc3RlckRldmljZRIbCglkZXZpY2VfaWQYASABKAxSCGRldmljZUlk');

@$core.Deprecated('Use registrationAcceptedDescriptor instead')
const RegistrationAccepted$json = {
  '1': 'RegistrationAccepted',
  '2': [
    {'1': 'device_id', '3': 1, '4': 1, '5': 12, '10': 'deviceId'},
    {
      '1': 'presence_expires_at_unix_ms',
      '3': 2,
      '4': 1,
      '5': 4,
      '10': 'presenceExpiresAtUnixMs'
    },
  ],
};

/// Descriptor for `RegistrationAccepted`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List registrationAcceptedDescriptor = $convert.base64Decode(
    'ChRSZWdpc3RyYXRpb25BY2NlcHRlZBIbCglkZXZpY2VfaWQYASABKAxSCGRldmljZUlkEjwKG3'
    'ByZXNlbmNlX2V4cGlyZXNfYXRfdW5peF9tcxgCIAEoBFIXcHJlc2VuY2VFeHBpcmVzQXRVbml4'
    'TXM=');

@$core.Deprecated('Use heartbeatDescriptor instead')
const Heartbeat$json = {
  '1': 'Heartbeat',
};

/// Descriptor for `Heartbeat`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List heartbeatDescriptor =
    $convert.base64Decode('CglIZWFydGJlYXQ=');

@$core.Deprecated('Use heartbeatAcknowledgedDescriptor instead')
const HeartbeatAcknowledged$json = {
  '1': 'HeartbeatAcknowledged',
  '2': [
    {
      '1': 'server_time_unix_ms',
      '3': 1,
      '4': 1,
      '5': 4,
      '10': 'serverTimeUnixMs'
    },
    {
      '1': 'presence_expires_at_unix_ms',
      '3': 2,
      '4': 1,
      '5': 4,
      '10': 'presenceExpiresAtUnixMs'
    },
  ],
};

/// Descriptor for `HeartbeatAcknowledged`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List heartbeatAcknowledgedDescriptor = $convert.base64Decode(
    'ChVIZWFydGJlYXRBY2tub3dsZWRnZWQSLQoTc2VydmVyX3RpbWVfdW5peF9tcxgBIAEoBFIQc2'
    'VydmVyVGltZVVuaXhNcxI8ChtwcmVzZW5jZV9leHBpcmVzX2F0X3VuaXhfbXMYAiABKARSF3By'
    'ZXNlbmNlRXhwaXJlc0F0VW5peE1z');

@$core.Deprecated('Use presenceQueryDescriptor instead')
const PresenceQuery$json = {
  '1': 'PresenceQuery',
  '2': [
    {'1': 'device_id', '3': 1, '4': 1, '5': 12, '10': 'deviceId'},
  ],
};

/// Descriptor for `PresenceQuery`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List presenceQueryDescriptor = $convert.base64Decode(
    'Cg1QcmVzZW5jZVF1ZXJ5EhsKCWRldmljZV9pZBgBIAEoDFIIZGV2aWNlSWQ=');

@$core.Deprecated('Use presenceResultDescriptor instead')
const PresenceResult$json = {
  '1': 'PresenceResult',
  '2': [
    {'1': 'device_id', '3': 1, '4': 1, '5': 12, '10': 'deviceId'},
    {'1': 'online', '3': 2, '4': 1, '5': 8, '10': 'online'},
  ],
};

/// Descriptor for `PresenceResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List presenceResultDescriptor = $convert.base64Decode(
    'Cg5QcmVzZW5jZVJlc3VsdBIbCglkZXZpY2VfaWQYASABKAxSCGRldmljZUlkEhYKBm9ubGluZR'
    'gCIAEoCFIGb25saW5l');

@$core.Deprecated('Use createPairingRendezvousDescriptor instead')
const CreatePairingRendezvous$json = {
  '1': 'CreatePairingRendezvous',
  '2': [
    {'1': 'rendezvous_id', '3': 1, '4': 1, '5': 12, '10': 'rendezvousId'},
    {
      '1': 'kind',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.roammand.v1.PairingRendezvousKind',
      '10': 'kind'
    },
    {'1': 'pairing_code', '3': 3, '4': 1, '5': 9, '10': 'pairingCode'},
  ],
};

/// Descriptor for `CreatePairingRendezvous`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createPairingRendezvousDescriptor = $convert.base64Decode(
    'ChdDcmVhdGVQYWlyaW5nUmVuZGV6dm91cxIjCg1yZW5kZXp2b3VzX2lkGAEgASgMUgxyZW5kZX'
    'p2b3VzSWQSNgoEa2luZBgCIAEoDjIiLnJvYW1tYW5kLnYxLlBhaXJpbmdSZW5kZXp2b3VzS2lu'
    'ZFIEa2luZBIhCgxwYWlyaW5nX2NvZGUYAyABKAlSC3BhaXJpbmdDb2Rl');

@$core.Deprecated('Use pairingRendezvousCreatedDescriptor instead')
const PairingRendezvousCreated$json = {
  '1': 'PairingRendezvousCreated',
  '2': [
    {'1': 'rendezvous_id', '3': 1, '4': 1, '5': 12, '10': 'rendezvousId'},
    {
      '1': 'kind',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.roammand.v1.PairingRendezvousKind',
      '10': 'kind'
    },
    {
      '1': 'expires_at_unix_ms',
      '3': 3,
      '4': 1,
      '5': 4,
      '10': 'expiresAtUnixMs'
    },
  ],
};

/// Descriptor for `PairingRendezvousCreated`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pairingRendezvousCreatedDescriptor = $convert.base64Decode(
    'ChhQYWlyaW5nUmVuZGV6dm91c0NyZWF0ZWQSIwoNcmVuZGV6dm91c19pZBgBIAEoDFIMcmVuZG'
    'V6dm91c0lkEjYKBGtpbmQYAiABKA4yIi5yb2FtbWFuZC52MS5QYWlyaW5nUmVuZGV6dm91c0tp'
    'bmRSBGtpbmQSKwoSZXhwaXJlc19hdF91bml4X21zGAMgASgEUg9leHBpcmVzQXRVbml4TXM=');

@$core.Deprecated('Use joinPairingRendezvousDescriptor instead')
const JoinPairingRendezvous$json = {
  '1': 'JoinPairingRendezvous',
  '2': [
    {
      '1': 'rendezvous_id',
      '3': 1,
      '4': 1,
      '5': 12,
      '9': 0,
      '10': 'rendezvousId'
    },
    {'1': 'pairing_code', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'pairingCode'},
  ],
  '8': [
    {'1': 'lookup'},
  ],
};

/// Descriptor for `JoinPairingRendezvous`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List joinPairingRendezvousDescriptor = $convert.base64Decode(
    'ChVKb2luUGFpcmluZ1JlbmRlenZvdXMSJQoNcmVuZGV6dm91c19pZBgBIAEoDEgAUgxyZW5kZX'
    'p2b3VzSWQSIwoMcGFpcmluZ19jb2RlGAIgASgJSABSC3BhaXJpbmdDb2RlQggKBmxvb2t1cA==');

@$core.Deprecated('Use pairingRendezvousJoinedDescriptor instead')
const PairingRendezvousJoined$json = {
  '1': 'PairingRendezvousJoined',
  '2': [
    {'1': 'rendezvous_id', '3': 1, '4': 1, '5': 12, '10': 'rendezvousId'},
    {'1': 'peer_device_id', '3': 2, '4': 1, '5': 12, '10': 'peerDeviceId'},
    {
      '1': 'expires_at_unix_ms',
      '3': 3,
      '4': 1,
      '5': 4,
      '10': 'expiresAtUnixMs'
    },
  ],
};

/// Descriptor for `PairingRendezvousJoined`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pairingRendezvousJoinedDescriptor = $convert.base64Decode(
    'ChdQYWlyaW5nUmVuZGV6dm91c0pvaW5lZBIjCg1yZW5kZXp2b3VzX2lkGAEgASgMUgxyZW5kZX'
    'p2b3VzSWQSJAoOcGVlcl9kZXZpY2VfaWQYAiABKAxSDHBlZXJEZXZpY2VJZBIrChJleHBpcmVz'
    'X2F0X3VuaXhfbXMYAyABKARSD2V4cGlyZXNBdFVuaXhNcw==');

@$core.Deprecated('Use relayPairingEnvelopeDescriptor instead')
const RelayPairingEnvelope$json = {
  '1': 'RelayPairingEnvelope',
  '2': [
    {'1': 'rendezvous_id', '3': 1, '4': 1, '5': 12, '10': 'rendezvousId'},
    {'1': 'opaque_envelope', '3': 2, '4': 1, '5': 12, '10': 'opaqueEnvelope'},
  ],
};

/// Descriptor for `RelayPairingEnvelope`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List relayPairingEnvelopeDescriptor = $convert.base64Decode(
    'ChRSZWxheVBhaXJpbmdFbnZlbG9wZRIjCg1yZW5kZXp2b3VzX2lkGAEgASgMUgxyZW5kZXp2b3'
    'VzSWQSJwoPb3BhcXVlX2VudmVsb3BlGAIgASgMUg5vcGFxdWVFbnZlbG9wZQ==');

@$core.Deprecated('Use routedPairingEnvelopeDescriptor instead')
const RoutedPairingEnvelope$json = {
  '1': 'RoutedPairingEnvelope',
  '2': [
    {'1': 'rendezvous_id', '3': 1, '4': 1, '5': 12, '10': 'rendezvousId'},
    {'1': 'sender_device_id', '3': 2, '4': 1, '5': 12, '10': 'senderDeviceId'},
    {'1': 'opaque_envelope', '3': 3, '4': 1, '5': 12, '10': 'opaqueEnvelope'},
  ],
};

/// Descriptor for `RoutedPairingEnvelope`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List routedPairingEnvelopeDescriptor = $convert.base64Decode(
    'ChVSb3V0ZWRQYWlyaW5nRW52ZWxvcGUSIwoNcmVuZGV6dm91c19pZBgBIAEoDFIMcmVuZGV6dm'
    '91c0lkEigKEHNlbmRlcl9kZXZpY2VfaWQYAiABKAxSDnNlbmRlckRldmljZUlkEicKD29wYXF1'
    'ZV9lbnZlbG9wZRgDIAEoDFIOb3BhcXVlRW52ZWxvcGU=');

@$core.Deprecated('Use completePairingRendezvousDescriptor instead')
const CompletePairingRendezvous$json = {
  '1': 'CompletePairingRendezvous',
  '2': [
    {'1': 'rendezvous_id', '3': 1, '4': 1, '5': 12, '10': 'rendezvousId'},
    {
      '1': 'completion',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.roammand.v1.PairingRendezvousCompletion',
      '10': 'completion'
    },
  ],
};

/// Descriptor for `CompletePairingRendezvous`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List completePairingRendezvousDescriptor = $convert.base64Decode(
    'ChlDb21wbGV0ZVBhaXJpbmdSZW5kZXp2b3VzEiMKDXJlbmRlenZvdXNfaWQYASABKAxSDHJlbm'
    'RlenZvdXNJZBJICgpjb21wbGV0aW9uGAIgASgOMigucm9hbW1hbmQudjEuUGFpcmluZ1JlbmRl'
    'enZvdXNDb21wbGV0aW9uUgpjb21wbGV0aW9u');

@$core.Deprecated('Use pairingRendezvousClosedDescriptor instead')
const PairingRendezvousClosed$json = {
  '1': 'PairingRendezvousClosed',
  '2': [
    {'1': 'rendezvous_id', '3': 1, '4': 1, '5': 12, '10': 'rendezvousId'},
    {
      '1': 'completion',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.roammand.v1.PairingRendezvousCompletion',
      '10': 'completion'
    },
  ],
};

/// Descriptor for `PairingRendezvousClosed`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pairingRendezvousClosedDescriptor = $convert.base64Decode(
    'ChdQYWlyaW5nUmVuZGV6dm91c0Nsb3NlZBIjCg1yZW5kZXp2b3VzX2lkGAEgASgMUgxyZW5kZX'
    'p2b3VzSWQSSAoKY29tcGxldGlvbhgCIAEoDjIoLnJvYW1tYW5kLnYxLlBhaXJpbmdSZW5kZXp2'
    'b3VzQ29tcGxldGlvblIKY29tcGxldGlvbg==');

@$core.Deprecated('Use relaySessionEnvelopeDescriptor instead')
const RelaySessionEnvelope$json = {
  '1': 'RelaySessionEnvelope',
  '2': [
    {
      '1': 'recipient_device_id',
      '3': 1,
      '4': 1,
      '5': 12,
      '10': 'recipientDeviceId'
    },
    {'1': 'opaque_envelope', '3': 2, '4': 1, '5': 12, '10': 'opaqueEnvelope'},
  ],
};

/// Descriptor for `RelaySessionEnvelope`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List relaySessionEnvelopeDescriptor = $convert.base64Decode(
    'ChRSZWxheVNlc3Npb25FbnZlbG9wZRIuChNyZWNpcGllbnRfZGV2aWNlX2lkGAEgASgMUhFyZW'
    'NpcGllbnREZXZpY2VJZBInCg9vcGFxdWVfZW52ZWxvcGUYAiABKAxSDm9wYXF1ZUVudmVsb3Bl');

@$core.Deprecated('Use routedSessionEnvelopeDescriptor instead')
const RoutedSessionEnvelope$json = {
  '1': 'RoutedSessionEnvelope',
  '2': [
    {'1': 'sender_device_id', '3': 1, '4': 1, '5': 12, '10': 'senderDeviceId'},
    {'1': 'opaque_envelope', '3': 2, '4': 1, '5': 12, '10': 'opaqueEnvelope'},
  ],
};

/// Descriptor for `RoutedSessionEnvelope`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List routedSessionEnvelopeDescriptor = $convert.base64Decode(
    'ChVSb3V0ZWRTZXNzaW9uRW52ZWxvcGUSKAoQc2VuZGVyX2RldmljZV9pZBgBIAEoDFIOc2VuZG'
    'VyRGV2aWNlSWQSJwoPb3BhcXVlX2VudmVsb3BlGAIgASgMUg5vcGFxdWVFbnZlbG9wZQ==');

@$core.Deprecated('Use signalingClientFrameDescriptor instead')
const SignalingClientFrame$json = {
  '1': 'SignalingClientFrame',
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
      '1': 'register',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.RegisterDevice',
      '9': 0,
      '10': 'register'
    },
    {
      '1': 'heartbeat',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.Heartbeat',
      '9': 0,
      '10': 'heartbeat'
    },
    {
      '1': 'presence_query',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PresenceQuery',
      '9': 0,
      '10': 'presenceQuery'
    },
    {
      '1': 'create_rendezvous',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.CreatePairingRendezvous',
      '9': 0,
      '10': 'createRendezvous'
    },
    {
      '1': 'join_rendezvous',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.JoinPairingRendezvous',
      '9': 0,
      '10': 'joinRendezvous'
    },
    {
      '1': 'relay_pairing',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.RelayPairingEnvelope',
      '9': 0,
      '10': 'relayPairing'
    },
    {
      '1': 'complete_rendezvous',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.CompletePairingRendezvous',
      '9': 0,
      '10': 'completeRendezvous'
    },
    {
      '1': 'relay_session',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.RelaySessionEnvelope',
      '9': 0,
      '10': 'relaySession'
    },
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `SignalingClientFrame`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signalingClientFrameDescriptor = $convert.base64Decode(
    'ChRTaWduYWxpbmdDbGllbnRGcmFtZRJHChBwcm90b2NvbF92ZXJzaW9uGAEgASgLMhwucm9hbW'
    '1hbmQudjEuUHJvdG9jb2xWZXJzaW9uUg9wcm90b2NvbFZlcnNpb24SHQoKcmVxdWVzdF9pZBgC'
    'IAEoCVIJcmVxdWVzdElkEjkKCHJlZ2lzdGVyGAogASgLMhsucm9hbW1hbmQudjEuUmVnaXN0ZX'
    'JEZXZpY2VIAFIIcmVnaXN0ZXISNgoJaGVhcnRiZWF0GAsgASgLMhYucm9hbW1hbmQudjEuSGVh'
    'cnRiZWF0SABSCWhlYXJ0YmVhdBJDCg5wcmVzZW5jZV9xdWVyeRgMIAEoCzIaLnJvYW1tYW5kLn'
    'YxLlByZXNlbmNlUXVlcnlIAFINcHJlc2VuY2VRdWVyeRJTChFjcmVhdGVfcmVuZGV6dm91cxgN'
    'IAEoCzIkLnJvYW1tYW5kLnYxLkNyZWF0ZVBhaXJpbmdSZW5kZXp2b3VzSABSEGNyZWF0ZVJlbm'
    'RlenZvdXMSTQoPam9pbl9yZW5kZXp2b3VzGA4gASgLMiIucm9hbW1hbmQudjEuSm9pblBhaXJp'
    'bmdSZW5kZXp2b3VzSABSDmpvaW5SZW5kZXp2b3VzEkgKDXJlbGF5X3BhaXJpbmcYDyABKAsyIS'
    '5yb2FtbWFuZC52MS5SZWxheVBhaXJpbmdFbnZlbG9wZUgAUgxyZWxheVBhaXJpbmcSWQoTY29t'
    'cGxldGVfcmVuZGV6dm91cxgQIAEoCzImLnJvYW1tYW5kLnYxLkNvbXBsZXRlUGFpcmluZ1Jlbm'
    'RlenZvdXNIAFISY29tcGxldGVSZW5kZXp2b3VzEkgKDXJlbGF5X3Nlc3Npb24YESABKAsyIS5y'
    'b2FtbWFuZC52MS5SZWxheVNlc3Npb25FbnZlbG9wZUgAUgxyZWxheVNlc3Npb25CCQoHcGF5bG'
    '9hZA==');

@$core.Deprecated('Use signalingServerFrameDescriptor instead')
const SignalingServerFrame$json = {
  '1': 'SignalingServerFrame',
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
      '1': 'registered',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.RegistrationAccepted',
      '9': 0,
      '10': 'registered'
    },
    {
      '1': 'heartbeat_acknowledged',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.HeartbeatAcknowledged',
      '9': 0,
      '10': 'heartbeatAcknowledged'
    },
    {
      '1': 'presence_result',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PresenceResult',
      '9': 0,
      '10': 'presenceResult'
    },
    {
      '1': 'rendezvous_created',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PairingRendezvousCreated',
      '9': 0,
      '10': 'rendezvousCreated'
    },
    {
      '1': 'rendezvous_joined',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PairingRendezvousJoined',
      '9': 0,
      '10': 'rendezvousJoined'
    },
    {
      '1': 'routed_pairing',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.RoutedPairingEnvelope',
      '9': 0,
      '10': 'routedPairing'
    },
    {
      '1': 'rendezvous_closed',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PairingRendezvousClosed',
      '9': 0,
      '10': 'rendezvousClosed'
    },
    {
      '1': 'routed_session',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.RoutedSessionEnvelope',
      '9': 0,
      '10': 'routedSession'
    },
    {
      '1': 'error',
      '3': 18,
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

/// Descriptor for `SignalingServerFrame`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signalingServerFrameDescriptor = $convert.base64Decode(
    'ChRTaWduYWxpbmdTZXJ2ZXJGcmFtZRJHChBwcm90b2NvbF92ZXJzaW9uGAEgASgLMhwucm9hbW'
    '1hbmQudjEuUHJvdG9jb2xWZXJzaW9uUg9wcm90b2NvbFZlcnNpb24SHQoKcmVxdWVzdF9pZBgC'
    'IAEoCVIJcmVxdWVzdElkEkMKCnJlZ2lzdGVyZWQYCiABKAsyIS5yb2FtbWFuZC52MS5SZWdpc3'
    'RyYXRpb25BY2NlcHRlZEgAUgpyZWdpc3RlcmVkElsKFmhlYXJ0YmVhdF9hY2tub3dsZWRnZWQY'
    'CyABKAsyIi5yb2FtbWFuZC52MS5IZWFydGJlYXRBY2tub3dsZWRnZWRIAFIVaGVhcnRiZWF0QW'
    'Nrbm93bGVkZ2VkEkYKD3ByZXNlbmNlX3Jlc3VsdBgMIAEoCzIbLnJvYW1tYW5kLnYxLlByZXNl'
    'bmNlUmVzdWx0SABSDnByZXNlbmNlUmVzdWx0ElYKEnJlbmRlenZvdXNfY3JlYXRlZBgNIAEoCz'
    'IlLnJvYW1tYW5kLnYxLlBhaXJpbmdSZW5kZXp2b3VzQ3JlYXRlZEgAUhFyZW5kZXp2b3VzQ3Jl'
    'YXRlZBJTChFyZW5kZXp2b3VzX2pvaW5lZBgOIAEoCzIkLnJvYW1tYW5kLnYxLlBhaXJpbmdSZW'
    '5kZXp2b3VzSm9pbmVkSABSEHJlbmRlenZvdXNKb2luZWQSSwoOcm91dGVkX3BhaXJpbmcYDyAB'
    'KAsyIi5yb2FtbWFuZC52MS5Sb3V0ZWRQYWlyaW5nRW52ZWxvcGVIAFINcm91dGVkUGFpcmluZx'
    'JTChFyZW5kZXp2b3VzX2Nsb3NlZBgQIAEoCzIkLnJvYW1tYW5kLnYxLlBhaXJpbmdSZW5kZXp2'
    'b3VzQ2xvc2VkSABSEHJlbmRlenZvdXNDbG9zZWQSSwoOcm91dGVkX3Nlc3Npb24YESABKAsyIi'
    '5yb2FtbWFuZC52MS5Sb3V0ZWRTZXNzaW9uRW52ZWxvcGVIAFINcm91dGVkU2Vzc2lvbhIxCgVl'
    'cnJvchgSIAEoCzIZLnJvYW1tYW5kLnYxLlVuaWZpZWRFcnJvckgAUgVlcnJvckIJCgdwYXlsb2'
    'Fk');
