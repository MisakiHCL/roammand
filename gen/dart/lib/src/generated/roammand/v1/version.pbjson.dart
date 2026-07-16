// SPDX-License-Identifier: Apache-2.0

// This is a generated file - do not edit.
//
// Generated from roammand/v1/version.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use capabilityDescriptor instead')
const Capability$json = {
  '1': 'Capability',
  '2': [
    {'1': 'CAPABILITY_UNSPECIFIED', '2': 0},
    {'1': 'CAPABILITY_QR_PAIRING', '2': 1},
    {'1': 'CAPABILITY_DESKTOP_CODE_PAIRING', '2': 2},
    {'1': 'CAPABILITY_PAIRING_SAS', '2': 3},
    {'1': 'CAPABILITY_SESSION_AUTH_ED25519', '2': 4},
    {'1': 'CAPABILITY_WEBRTC_H264', '2': 5},
    {'1': 'CAPABILITY_WEBRTC_VP8', '2': 6},
    {'1': 'CAPABILITY_ICE_RESTART', '2': 7},
    {'1': 'CAPABILITY_INPUT_RELIABLE', '2': 8},
    {'1': 'CAPABILITY_POINTER_FAST', '2': 9},
  ],
};

/// Descriptor for `Capability`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List capabilityDescriptor = $convert.base64Decode(
    'CgpDYXBhYmlsaXR5EhoKFkNBUEFCSUxJVFlfVU5TUEVDSUZJRUQQABIZChVDQVBBQklMSVRZX1'
    'FSX1BBSVJJTkcQARIjCh9DQVBBQklMSVRZX0RFU0tUT1BfQ09ERV9QQUlSSU5HEAISGgoWQ0FQ'
    'QUJJTElUWV9QQUlSSU5HX1NBUxADEiMKH0NBUEFCSUxJVFlfU0VTU0lPTl9BVVRIX0VEMjU1MT'
    'kQBBIaChZDQVBBQklMSVRZX1dFQlJUQ19IMjY0EAUSGQoVQ0FQQUJJTElUWV9XRUJSVENfVlA4'
    'EAYSGgoWQ0FQQUJJTElUWV9JQ0VfUkVTVEFSVBAHEh0KGUNBUEFCSUxJVFlfSU5QVVRfUkVMSU'
    'FCTEUQCBIbChdDQVBBQklMSVRZX1BPSU5URVJfRkFTVBAJ');

@$core.Deprecated('Use protocolVersionDescriptor instead')
const ProtocolVersion$json = {
  '1': 'ProtocolVersion',
  '2': [
    {'1': 'major', '3': 1, '4': 1, '5': 13, '10': 'major'},
    {'1': 'minor', '3': 2, '4': 1, '5': 13, '10': 'minor'},
  ],
};

/// Descriptor for `ProtocolVersion`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protocolVersionDescriptor = $convert.base64Decode(
    'Cg9Qcm90b2NvbFZlcnNpb24SFAoFbWFqb3IYASABKA1SBW1ham9yEhQKBW1pbm9yGAIgASgNUg'
    'VtaW5vcg==');

@$core.Deprecated('Use capabilityNegotiationDescriptor instead')
const CapabilityNegotiation$json = {
  '1': 'CapabilityNegotiation',
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
      '1': 'required_capabilities',
      '3': 2,
      '4': 3,
      '5': 14,
      '6': '.roammand.v1.Capability',
      '10': 'requiredCapabilities'
    },
    {
      '1': 'optional_capabilities',
      '3': 3,
      '4': 3,
      '5': 14,
      '6': '.roammand.v1.Capability',
      '10': 'optionalCapabilities'
    },
  ],
};

/// Descriptor for `CapabilityNegotiation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List capabilityNegotiationDescriptor = $convert.base64Decode(
    'ChVDYXBhYmlsaXR5TmVnb3RpYXRpb24SRwoQcHJvdG9jb2xfdmVyc2lvbhgBIAEoCzIcLnJvYW'
    '1tYW5kLnYxLlByb3RvY29sVmVyc2lvblIPcHJvdG9jb2xWZXJzaW9uEkwKFXJlcXVpcmVkX2Nh'
    'cGFiaWxpdGllcxgCIAMoDjIXLnJvYW1tYW5kLnYxLkNhcGFiaWxpdHlSFHJlcXVpcmVkQ2FwYW'
    'JpbGl0aWVzEkwKFW9wdGlvbmFsX2NhcGFiaWxpdGllcxgDIAMoDjIXLnJvYW1tYW5kLnYxLkNh'
    'cGFiaWxpdHlSFG9wdGlvbmFsQ2FwYWJpbGl0aWVz');
