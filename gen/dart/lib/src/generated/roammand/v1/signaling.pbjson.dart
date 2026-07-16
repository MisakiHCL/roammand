// SPDX-License-Identifier: Apache-2.0

// This is a generated file - do not edit.
//
// Generated from roammand/v1/signaling.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use signalingEnvelopeDescriptor instead')
const SignalingEnvelope$json = {
  '1': 'SignalingEnvelope',
  '2': [
    {
      '1': 'protocol_version',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.ProtocolVersion',
      '10': 'protocolVersion'
    },
    {'1': 'sender_device_id', '3': 2, '4': 1, '5': 12, '10': 'senderDeviceId'},
    {
      '1': 'recipient_device_id',
      '3': 3,
      '4': 1,
      '5': 12,
      '10': 'recipientDeviceId'
    },
    {'1': 'request_id', '3': 4, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'sent_at_unix_ms', '3': 5, '4': 1, '5': 4, '10': 'sentAtUnixMs'},
    {
      '1': 'capability_negotiation',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.CapabilityNegotiation',
      '9': 0,
      '10': 'capabilityNegotiation'
    },
    {
      '1': 'pairing',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PairingMessage',
      '9': 0,
      '10': 'pairing'
    },
    {
      '1': 'session_authentication',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.SessionAuthentication',
      '9': 0,
      '10': 'sessionAuthentication'
    },
    {
      '1': 'webrtc_negotiation',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.WebRtcNegotiation',
      '9': 0,
      '10': 'webrtcNegotiation'
    },
    {
      '1': 'session_status',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.SessionStatus',
      '9': 0,
      '10': 'sessionStatus'
    },
    {
      '1': 'error',
      '3': 15,
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

/// Descriptor for `SignalingEnvelope`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signalingEnvelopeDescriptor = $convert.base64Decode(
    'ChFTaWduYWxpbmdFbnZlbG9wZRJHChBwcm90b2NvbF92ZXJzaW9uGAEgASgLMhwucm9hbW1hbm'
    'QudjEuUHJvdG9jb2xWZXJzaW9uUg9wcm90b2NvbFZlcnNpb24SKAoQc2VuZGVyX2RldmljZV9p'
    'ZBgCIAEoDFIOc2VuZGVyRGV2aWNlSWQSLgoTcmVjaXBpZW50X2RldmljZV9pZBgDIAEoDFIRcm'
    'VjaXBpZW50RGV2aWNlSWQSHQoKcmVxdWVzdF9pZBgEIAEoCVIJcmVxdWVzdElkEiUKD3NlbnRf'
    'YXRfdW5peF9tcxgFIAEoBFIMc2VudEF0VW5peE1zElsKFmNhcGFiaWxpdHlfbmVnb3RpYXRpb2'
    '4YCiABKAsyIi5yb2FtbWFuZC52MS5DYXBhYmlsaXR5TmVnb3RpYXRpb25IAFIVY2FwYWJpbGl0'
    'eU5lZ290aWF0aW9uEjcKB3BhaXJpbmcYCyABKAsyGy5yb2FtbWFuZC52MS5QYWlyaW5nTWVzc2'
    'FnZUgAUgdwYWlyaW5nElsKFnNlc3Npb25fYXV0aGVudGljYXRpb24YDCABKAsyIi5yb2FtbWFu'
    'ZC52MS5TZXNzaW9uQXV0aGVudGljYXRpb25IAFIVc2Vzc2lvbkF1dGhlbnRpY2F0aW9uEk8KEn'
    'dlYnJ0Y19uZWdvdGlhdGlvbhgNIAEoCzIeLnJvYW1tYW5kLnYxLldlYlJ0Y05lZ290aWF0aW9u'
    'SABSEXdlYnJ0Y05lZ290aWF0aW9uEkMKDnNlc3Npb25fc3RhdHVzGA4gASgLMhoucm9hbW1hbm'
    'QudjEuU2Vzc2lvblN0YXR1c0gAUg1zZXNzaW9uU3RhdHVzEjEKBWVycm9yGA8gASgLMhkucm9h'
    'bW1hbmQudjEuVW5pZmllZEVycm9ySABSBWVycm9yQgkKB3BheWxvYWQ=');
