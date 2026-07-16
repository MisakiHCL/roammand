// SPDX-License-Identifier: Apache-2.0

// This is a generated file - do not edit.
//
// Generated from roammand/v1/input.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use pointerButtonDescriptor instead')
const PointerButton$json = {
  '1': 'PointerButton',
  '2': [
    {'1': 'POINTER_BUTTON_UNSPECIFIED', '2': 0},
    {'1': 'POINTER_BUTTON_LEFT', '2': 1},
    {'1': 'POINTER_BUTTON_RIGHT', '2': 2},
    {'1': 'POINTER_BUTTON_MIDDLE', '2': 3},
  ],
};

/// Descriptor for `PointerButton`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List pointerButtonDescriptor = $convert.base64Decode(
    'Cg1Qb2ludGVyQnV0dG9uEh4KGlBPSU5URVJfQlVUVE9OX1VOU1BFQ0lGSUVEEAASFwoTUE9JTl'
    'RFUl9CVVRUT05fTEVGVBABEhgKFFBPSU5URVJfQlVUVE9OX1JJR0hUEAISGQoVUE9JTlRFUl9C'
    'VVRUT05fTUlERExFEAM=');

@$core.Deprecated('Use buttonActionDescriptor instead')
const ButtonAction$json = {
  '1': 'ButtonAction',
  '2': [
    {'1': 'BUTTON_ACTION_UNSPECIFIED', '2': 0},
    {'1': 'BUTTON_ACTION_DOWN', '2': 1},
    {'1': 'BUTTON_ACTION_UP', '2': 2},
    {'1': 'BUTTON_ACTION_CLICK', '2': 3},
    {'1': 'BUTTON_ACTION_DOUBLE_CLICK', '2': 4},
  ],
};

/// Descriptor for `ButtonAction`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List buttonActionDescriptor = $convert.base64Decode(
    'CgxCdXR0b25BY3Rpb24SHQoZQlVUVE9OX0FDVElPTl9VTlNQRUNJRklFRBAAEhYKEkJVVFRPTl'
    '9BQ1RJT05fRE9XThABEhQKEEJVVFRPTl9BQ1RJT05fVVAQAhIXChNCVVRUT05fQUNUSU9OX0NM'
    'SUNLEAMSHgoaQlVUVE9OX0FDVElPTl9ET1VCTEVfQ0xJQ0sQBA==');

@$core.Deprecated('Use keyboardActionDescriptor instead')
const KeyboardAction$json = {
  '1': 'KeyboardAction',
  '2': [
    {'1': 'KEYBOARD_ACTION_UNSPECIFIED', '2': 0},
    {'1': 'KEYBOARD_ACTION_DOWN', '2': 1},
    {'1': 'KEYBOARD_ACTION_UP', '2': 2},
  ],
};

/// Descriptor for `KeyboardAction`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List keyboardActionDescriptor = $convert.base64Decode(
    'Cg5LZXlib2FyZEFjdGlvbhIfChtLRVlCT0FSRF9BQ1RJT05fVU5TUEVDSUZJRUQQABIYChRLRV'
    'lCT0FSRF9BQ1RJT05fRE9XThABEhYKEktFWUJPQVJEX0FDVElPTl9VUBAC');

@$core.Deprecated('Use sessionControlActionDescriptor instead')
const SessionControlAction$json = {
  '1': 'SessionControlAction',
  '2': [
    {'1': 'SESSION_CONTROL_ACTION_UNSPECIFIED', '2': 0},
    {'1': 'SESSION_CONTROL_ACTION_CLOSE', '2': 1},
    {'1': 'SESSION_CONTROL_ACTION_EMERGENCY_STOP', '2': 2},
  ],
};

/// Descriptor for `SessionControlAction`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sessionControlActionDescriptor = $convert.base64Decode(
    'ChRTZXNzaW9uQ29udHJvbEFjdGlvbhImCiJTRVNTSU9OX0NPTlRST0xfQUNUSU9OX1VOU1BFQ0'
    'lGSUVEEAASIAocU0VTU0lPTl9DT05UUk9MX0FDVElPTl9DTE9TRRABEikKJVNFU1NJT05fQ09O'
    'VFJPTF9BQ1RJT05fRU1FUkdFTkNZX1NUT1AQAg==');

@$core.Deprecated('Use pointerButtonEventDescriptor instead')
const PointerButtonEvent$json = {
  '1': 'PointerButtonEvent',
  '2': [
    {
      '1': 'button',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.roammand.v1.PointerButton',
      '10': 'button'
    },
    {
      '1': 'action',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.roammand.v1.ButtonAction',
      '10': 'action'
    },
    {'1': 'x', '3': 3, '4': 1, '5': 17, '10': 'x'},
    {'1': 'y', '3': 4, '4': 1, '5': 17, '10': 'y'},
  ],
};

/// Descriptor for `PointerButtonEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pointerButtonEventDescriptor = $convert.base64Decode(
    'ChJQb2ludGVyQnV0dG9uRXZlbnQSMgoGYnV0dG9uGAEgASgOMhoucm9hbW1hbmQudjEuUG9pbn'
    'RlckJ1dHRvblIGYnV0dG9uEjEKBmFjdGlvbhgCIAEoDjIZLnJvYW1tYW5kLnYxLkJ1dHRvbkFj'
    'dGlvblIGYWN0aW9uEgwKAXgYAyABKBFSAXgSDAoBeRgEIAEoEVIBeQ==');

@$core.Deprecated('Use keyboardEventDescriptor instead')
const KeyboardEvent$json = {
  '1': 'KeyboardEvent',
  '2': [
    {
      '1': 'action',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.roammand.v1.KeyboardAction',
      '10': 'action'
    },
    {'1': 'usb_hid_usage', '3': 2, '4': 1, '5': 13, '10': 'usbHidUsage'},
    {'1': 'modifier_bits', '3': 3, '4': 1, '5': 13, '10': 'modifierBits'},
  ],
};

/// Descriptor for `KeyboardEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keyboardEventDescriptor = $convert.base64Decode(
    'Cg1LZXlib2FyZEV2ZW50EjMKBmFjdGlvbhgBIAEoDjIbLnJvYW1tYW5kLnYxLktleWJvYXJkQW'
    'N0aW9uUgZhY3Rpb24SIgoNdXNiX2hpZF91c2FnZRgCIAEoDVILdXNiSGlkVXNhZ2USIwoNbW9k'
    'aWZpZXJfYml0cxgDIAEoDVIMbW9kaWZpZXJCaXRz');

@$core.Deprecated('Use textInputEventDescriptor instead')
const TextInputEvent$json = {
  '1': 'TextInputEvent',
  '2': [
    {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
  ],
};

/// Descriptor for `TextInputEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List textInputEventDescriptor =
    $convert.base64Decode('Cg5UZXh0SW5wdXRFdmVudBISCgR0ZXh0GAEgASgJUgR0ZXh0');

@$core.Deprecated('Use sessionControlEventDescriptor instead')
const SessionControlEvent$json = {
  '1': 'SessionControlEvent',
  '2': [
    {
      '1': 'action',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.roammand.v1.SessionControlAction',
      '10': 'action'
    },
  ],
};

/// Descriptor for `SessionControlEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionControlEventDescriptor = $convert.base64Decode(
    'ChNTZXNzaW9uQ29udHJvbEV2ZW50EjkKBmFjdGlvbhgBIAEoDjIhLnJvYW1tYW5kLnYxLlNlc3'
    'Npb25Db250cm9sQWN0aW9uUgZhY3Rpb24=');

@$core.Deprecated('Use releaseAllInputDescriptor instead')
const ReleaseAllInput$json = {
  '1': 'ReleaseAllInput',
};

/// Descriptor for `ReleaseAllInput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List releaseAllInputDescriptor =
    $convert.base64Decode('Cg9SZWxlYXNlQWxsSW5wdXQ=');

@$core.Deprecated('Use pointerMoveEventDescriptor instead')
const PointerMoveEvent$json = {
  '1': 'PointerMoveEvent',
  '2': [
    {'1': 'x', '3': 1, '4': 1, '5': 17, '10': 'x'},
    {'1': 'y', '3': 2, '4': 1, '5': 17, '10': 'y'},
    {
      '1': 'pressed_button_bits',
      '3': 3,
      '4': 1,
      '5': 13,
      '10': 'pressedButtonBits'
    },
  ],
};

/// Descriptor for `PointerMoveEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pointerMoveEventDescriptor = $convert.base64Decode(
    'ChBQb2ludGVyTW92ZUV2ZW50EgwKAXgYASABKBFSAXgSDAoBeRgCIAEoEVIBeRIuChNwcmVzc2'
    'VkX2J1dHRvbl9iaXRzGAMgASgNUhFwcmVzc2VkQnV0dG9uQml0cw==');

@$core.Deprecated('Use pointerScrollEventDescriptor instead')
const PointerScrollEvent$json = {
  '1': 'PointerScrollEvent',
  '2': [
    {'1': 'delta_x', '3': 1, '4': 1, '5': 17, '10': 'deltaX'},
    {'1': 'delta_y', '3': 2, '4': 1, '5': 17, '10': 'deltaY'},
  ],
};

/// Descriptor for `PointerScrollEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pointerScrollEventDescriptor = $convert.base64Decode(
    'ChJQb2ludGVyU2Nyb2xsRXZlbnQSFwoHZGVsdGFfeBgBIAEoEVIGZGVsdGFYEhcKB2RlbHRhX3'
    'kYAiABKBFSBmRlbHRhWQ==');

@$core.Deprecated('Use reliableInputEnvelopeDescriptor instead')
const ReliableInputEnvelope$json = {
  '1': 'ReliableInputEnvelope',
  '2': [
    {
      '1': 'protocol_version',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.ProtocolVersion',
      '10': 'protocolVersion'
    },
    {'1': 'session_id', '3': 2, '4': 1, '5': 12, '10': 'sessionId'},
    {'1': 'sequence', '3': 3, '4': 1, '5': 4, '10': 'sequence'},
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
      '1': 'session_control',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.SessionControlEvent',
      '9': 0,
      '10': 'sessionControl'
    },
    {
      '1': 'release_all_input',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.ReleaseAllInput',
      '9': 0,
      '10': 'releaseAllInput'
    },
  ],
  '8': [
    {'1': 'event'},
  ],
};

/// Descriptor for `ReliableInputEnvelope`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reliableInputEnvelopeDescriptor = $convert.base64Decode(
    'ChVSZWxpYWJsZUlucHV0RW52ZWxvcGUSRwoQcHJvdG9jb2xfdmVyc2lvbhgBIAEoCzIcLnJvYW'
    '1tYW5kLnYxLlByb3RvY29sVmVyc2lvblIPcHJvdG9jb2xWZXJzaW9uEh0KCnNlc3Npb25faWQY'
    'AiABKAxSCXNlc3Npb25JZBIaCghzZXF1ZW5jZRgDIAEoBFIIc2VxdWVuY2USSAoOcG9pbnRlcl'
    '9idXR0b24YCiABKAsyHy5yb2FtbWFuZC52MS5Qb2ludGVyQnV0dG9uRXZlbnRIAFINcG9pbnRl'
    'ckJ1dHRvbhI4CghrZXlib2FyZBgLIAEoCzIaLnJvYW1tYW5kLnYxLktleWJvYXJkRXZlbnRIAF'
    'IIa2V5Ym9hcmQSMQoEdGV4dBgMIAEoCzIbLnJvYW1tYW5kLnYxLlRleHRJbnB1dEV2ZW50SABS'
    'BHRleHQSSwoPc2Vzc2lvbl9jb250cm9sGA0gASgLMiAucm9hbW1hbmQudjEuU2Vzc2lvbkNvbn'
    'Ryb2xFdmVudEgAUg5zZXNzaW9uQ29udHJvbBJKChFyZWxlYXNlX2FsbF9pbnB1dBgOIAEoCzIc'
    'LnJvYW1tYW5kLnYxLlJlbGVhc2VBbGxJbnB1dEgAUg9yZWxlYXNlQWxsSW5wdXRCBwoFZXZlbn'
    'Q=');

@$core.Deprecated('Use pointerFastEnvelopeDescriptor instead')
const PointerFastEnvelope$json = {
  '1': 'PointerFastEnvelope',
  '2': [
    {
      '1': 'protocol_version',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.ProtocolVersion',
      '10': 'protocolVersion'
    },
    {'1': 'session_id', '3': 2, '4': 1, '5': 12, '10': 'sessionId'},
    {'1': 'sequence', '3': 3, '4': 1, '5': 4, '10': 'sequence'},
    {
      '1': 'move',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PointerMoveEvent',
      '9': 0,
      '10': 'move'
    },
    {
      '1': 'scroll',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PointerScrollEvent',
      '9': 0,
      '10': 'scroll'
    },
  ],
  '8': [
    {'1': 'event'},
  ],
};

/// Descriptor for `PointerFastEnvelope`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pointerFastEnvelopeDescriptor = $convert.base64Decode(
    'ChNQb2ludGVyRmFzdEVudmVsb3BlEkcKEHByb3RvY29sX3ZlcnNpb24YASABKAsyHC5yb2FtbW'
    'FuZC52MS5Qcm90b2NvbFZlcnNpb25SD3Byb3RvY29sVmVyc2lvbhIdCgpzZXNzaW9uX2lkGAIg'
    'ASgMUglzZXNzaW9uSWQSGgoIc2VxdWVuY2UYAyABKARSCHNlcXVlbmNlEjMKBG1vdmUYCiABKA'
    'syHS5yb2FtbWFuZC52MS5Qb2ludGVyTW92ZUV2ZW50SABSBG1vdmUSOQoGc2Nyb2xsGAsgASgL'
    'Mh8ucm9hbW1hbmQudjEuUG9pbnRlclNjcm9sbEV2ZW50SABSBnNjcm9sbEIHCgVldmVudA==');
