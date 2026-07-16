// SPDX-License-Identifier: Apache-2.0

// This is a generated file - do not edit.
//
// Generated from roammand/v1/webrtc.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use sessionDescriptionTypeDescriptor instead')
const SessionDescriptionType$json = {
  '1': 'SessionDescriptionType',
  '2': [
    {'1': 'SESSION_DESCRIPTION_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'SESSION_DESCRIPTION_TYPE_OFFER', '2': 1},
    {'1': 'SESSION_DESCRIPTION_TYPE_ANSWER', '2': 2},
  ],
};

/// Descriptor for `SessionDescriptionType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sessionDescriptionTypeDescriptor = $convert.base64Decode(
    'ChZTZXNzaW9uRGVzY3JpcHRpb25UeXBlEigKJFNFU1NJT05fREVTQ1JJUFRJT05fVFlQRV9VTl'
    'NQRUNJRklFRBAAEiIKHlNFU1NJT05fREVTQ1JJUFRJT05fVFlQRV9PRkZFUhABEiMKH1NFU1NJ'
    'T05fREVTQ1JJUFRJT05fVFlQRV9BTlNXRVIQAg==');

@$core.Deprecated('Use webRtcSessionDescriptionDescriptor instead')
const WebRtcSessionDescription$json = {
  '1': 'WebRtcSessionDescription',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.roammand.v1.SessionDescriptionType',
      '10': 'type'
    },
    {'1': 'sdp', '3': 2, '4': 1, '5': 9, '10': 'sdp'},
    {
      '1': 'dtls_fingerprint_sha256',
      '3': 3,
      '4': 1,
      '5': 12,
      '10': 'dtlsFingerprintSha256'
    },
  ],
};

/// Descriptor for `WebRtcSessionDescription`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List webRtcSessionDescriptionDescriptor = $convert.base64Decode(
    'ChhXZWJSdGNTZXNzaW9uRGVzY3JpcHRpb24SNwoEdHlwZRgBIAEoDjIjLnJvYW1tYW5kLnYxLl'
    'Nlc3Npb25EZXNjcmlwdGlvblR5cGVSBHR5cGUSEAoDc2RwGAIgASgJUgNzZHASNgoXZHRsc19m'
    'aW5nZXJwcmludF9zaGEyNTYYAyABKAxSFWR0bHNGaW5nZXJwcmludFNoYTI1Ng==');

@$core.Deprecated('Use iceCandidateDescriptor instead')
const IceCandidate$json = {
  '1': 'IceCandidate',
  '2': [
    {'1': 'candidate', '3': 1, '4': 1, '5': 9, '10': 'candidate'},
    {'1': 'sdp_mid', '3': 2, '4': 1, '5': 9, '10': 'sdpMid'},
    {'1': 'sdp_m_line_index', '3': 3, '4': 1, '5': 13, '10': 'sdpMLineIndex'},
  ],
};

/// Descriptor for `IceCandidate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List iceCandidateDescriptor = $convert.base64Decode(
    'CgxJY2VDYW5kaWRhdGUSHAoJY2FuZGlkYXRlGAEgASgJUgljYW5kaWRhdGUSFwoHc2RwX21pZB'
    'gCIAEoCVIGc2RwTWlkEicKEHNkcF9tX2xpbmVfaW5kZXgYAyABKA1SDXNkcE1MaW5lSW5kZXg=');

@$core.Deprecated('Use endOfCandidatesDescriptor instead')
const EndOfCandidates$json = {
  '1': 'EndOfCandidates',
};

/// Descriptor for `EndOfCandidates`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List endOfCandidatesDescriptor =
    $convert.base64Decode('Cg9FbmRPZkNhbmRpZGF0ZXM=');

@$core.Deprecated('Use webRtcNegotiationDescriptor instead')
const WebRtcNegotiation$json = {
  '1': 'WebRtcNegotiation',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 12, '10': 'sessionId'},
    {
      '1': 'description',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.WebRtcSessionDescription',
      '9': 0,
      '10': 'description'
    },
    {
      '1': 'ice_candidate',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.IceCandidate',
      '9': 0,
      '10': 'iceCandidate'
    },
    {
      '1': 'end_of_candidates',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.EndOfCandidates',
      '9': 0,
      '10': 'endOfCandidates'
    },
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `WebRtcNegotiation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List webRtcNegotiationDescriptor = $convert.base64Decode(
    'ChFXZWJSdGNOZWdvdGlhdGlvbhIdCgpzZXNzaW9uX2lkGAEgASgMUglzZXNzaW9uSWQSSQoLZG'
    'VzY3JpcHRpb24YAiABKAsyJS5yb2FtbWFuZC52MS5XZWJSdGNTZXNzaW9uRGVzY3JpcHRpb25I'
    'AFILZGVzY3JpcHRpb24SQAoNaWNlX2NhbmRpZGF0ZRgDIAEoCzIZLnJvYW1tYW5kLnYxLkljZU'
    'NhbmRpZGF0ZUgAUgxpY2VDYW5kaWRhdGUSSgoRZW5kX29mX2NhbmRpZGF0ZXMYBCABKAsyHC5y'
    'b2FtbWFuZC52MS5FbmRPZkNhbmRpZGF0ZXNIAFIPZW5kT2ZDYW5kaWRhdGVzQgkKB3BheWxvYW'
    'Q=');
