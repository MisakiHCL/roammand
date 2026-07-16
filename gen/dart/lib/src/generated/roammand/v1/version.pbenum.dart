// SPDX-License-Identifier: Apache-2.0

// This is a generated file - do not edit.
//
// Generated from roammand/v1/version.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class Capability extends $pb.ProtobufEnum {
  static const Capability CAPABILITY_UNSPECIFIED =
      Capability._(0, _omitEnumNames ? '' : 'CAPABILITY_UNSPECIFIED');
  static const Capability CAPABILITY_QR_PAIRING =
      Capability._(1, _omitEnumNames ? '' : 'CAPABILITY_QR_PAIRING');
  static const Capability CAPABILITY_DESKTOP_CODE_PAIRING =
      Capability._(2, _omitEnumNames ? '' : 'CAPABILITY_DESKTOP_CODE_PAIRING');
  static const Capability CAPABILITY_PAIRING_SAS =
      Capability._(3, _omitEnumNames ? '' : 'CAPABILITY_PAIRING_SAS');
  static const Capability CAPABILITY_SESSION_AUTH_ED25519 =
      Capability._(4, _omitEnumNames ? '' : 'CAPABILITY_SESSION_AUTH_ED25519');
  static const Capability CAPABILITY_WEBRTC_H264 =
      Capability._(5, _omitEnumNames ? '' : 'CAPABILITY_WEBRTC_H264');
  static const Capability CAPABILITY_WEBRTC_VP8 =
      Capability._(6, _omitEnumNames ? '' : 'CAPABILITY_WEBRTC_VP8');
  static const Capability CAPABILITY_ICE_RESTART =
      Capability._(7, _omitEnumNames ? '' : 'CAPABILITY_ICE_RESTART');
  static const Capability CAPABILITY_INPUT_RELIABLE =
      Capability._(8, _omitEnumNames ? '' : 'CAPABILITY_INPUT_RELIABLE');
  static const Capability CAPABILITY_POINTER_FAST =
      Capability._(9, _omitEnumNames ? '' : 'CAPABILITY_POINTER_FAST');

  static const $core.List<Capability> values = <Capability>[
    CAPABILITY_UNSPECIFIED,
    CAPABILITY_QR_PAIRING,
    CAPABILITY_DESKTOP_CODE_PAIRING,
    CAPABILITY_PAIRING_SAS,
    CAPABILITY_SESSION_AUTH_ED25519,
    CAPABILITY_WEBRTC_H264,
    CAPABILITY_WEBRTC_VP8,
    CAPABILITY_ICE_RESTART,
    CAPABILITY_INPUT_RELIABLE,
    CAPABILITY_POINTER_FAST,
  ];

  static final $core.List<Capability?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 9);
  static Capability? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Capability._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
