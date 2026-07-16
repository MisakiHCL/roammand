// SPDX-License-Identifier: Apache-2.0

// This is a generated file - do not edit.
//
// Generated from roammand/v1/error.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ErrorCode extends $pb.ProtobufEnum {
  static const ErrorCode ERROR_CODE_UNSPECIFIED =
      ErrorCode._(0, _omitEnumNames ? '' : 'ERROR_CODE_UNSPECIFIED');
  static const ErrorCode ERROR_CODE_PAIRING_CODE_EXPIRED =
      ErrorCode._(1, _omitEnumNames ? '' : 'ERROR_CODE_PAIRING_CODE_EXPIRED');
  static const ErrorCode ERROR_CODE_PAIRING_RATE_LIMITED =
      ErrorCode._(2, _omitEnumNames ? '' : 'ERROR_CODE_PAIRING_RATE_LIMITED');
  static const ErrorCode ERROR_CODE_PAIRING_REJECTED =
      ErrorCode._(3, _omitEnumNames ? '' : 'ERROR_CODE_PAIRING_REJECTED');
  static const ErrorCode ERROR_CODE_DEVICE_OFFLINE =
      ErrorCode._(4, _omitEnumNames ? '' : 'ERROR_CODE_DEVICE_OFFLINE');
  static const ErrorCode ERROR_CODE_DEVICE_BUSY =
      ErrorCode._(5, _omitEnumNames ? '' : 'ERROR_CODE_DEVICE_BUSY');
  static const ErrorCode ERROR_CODE_AUTH_INVALID =
      ErrorCode._(6, _omitEnumNames ? '' : 'ERROR_CODE_AUTH_INVALID');
  static const ErrorCode ERROR_CODE_AUTH_REVOKED =
      ErrorCode._(7, _omitEnumNames ? '' : 'ERROR_CODE_AUTH_REVOKED');
  static const ErrorCode ERROR_CODE_SESSION_REPLAYED =
      ErrorCode._(8, _omitEnumNames ? '' : 'ERROR_CODE_SESSION_REPLAYED');
  static const ErrorCode ERROR_CODE_ICE_FAILED =
      ErrorCode._(9, _omitEnumNames ? '' : 'ERROR_CODE_ICE_FAILED');
  static const ErrorCode ERROR_CODE_TURN_UNAVAILABLE =
      ErrorCode._(10, _omitEnumNames ? '' : 'ERROR_CODE_TURN_UNAVAILABLE');
  static const ErrorCode ERROR_CODE_CODEC_NEGOTIATION_FAILED = ErrorCode._(
      11, _omitEnumNames ? '' : 'ERROR_CODE_CODEC_NEGOTIATION_FAILED');
  static const ErrorCode ERROR_CODE_CAPTURE_PERMISSION_REQUIRED = ErrorCode._(
      12, _omitEnumNames ? '' : 'ERROR_CODE_CAPTURE_PERMISSION_REQUIRED');
  static const ErrorCode ERROR_CODE_INPUT_PERMISSION_REQUIRED = ErrorCode._(
      13, _omitEnumNames ? '' : 'ERROR_CODE_INPUT_PERMISSION_REQUIRED');
  static const ErrorCode ERROR_CODE_CAPTURE_FAILED =
      ErrorCode._(14, _omitEnumNames ? '' : 'ERROR_CODE_CAPTURE_FAILED');
  static const ErrorCode ERROR_CODE_INPUT_INJECTION_FAILED = ErrorCode._(
      15, _omitEnumNames ? '' : 'ERROR_CODE_INPUT_INJECTION_FAILED');
  static const ErrorCode ERROR_CODE_APP_MOVED_TO_BACKGROUND = ErrorCode._(
      16, _omitEnumNames ? '' : 'ERROR_CODE_APP_MOVED_TO_BACKGROUND');
  static const ErrorCode ERROR_CODE_INVALID_REQUEST =
      ErrorCode._(17, _omitEnumNames ? '' : 'ERROR_CODE_INVALID_REQUEST');
  static const ErrorCode ERROR_CODE_PROTOCOL_UNSUPPORTED =
      ErrorCode._(18, _omitEnumNames ? '' : 'ERROR_CODE_PROTOCOL_UNSUPPORTED');
  static const ErrorCode ERROR_CODE_MESSAGE_TOO_LARGE =
      ErrorCode._(19, _omitEnumNames ? '' : 'ERROR_CODE_MESSAGE_TOO_LARGE');
  static const ErrorCode ERROR_CODE_SERVER_UNAVAILABLE =
      ErrorCode._(20, _omitEnumNames ? '' : 'ERROR_CODE_SERVER_UNAVAILABLE');
  static const ErrorCode ERROR_CODE_PRIVILEGED_BRIDGE_UNAVAILABLE = ErrorCode._(
      21, _omitEnumNames ? '' : 'ERROR_CODE_PRIVILEGED_BRIDGE_UNAVAILABLE');
  static const ErrorCode ERROR_CODE_PRIVILEGED_CLIENT_UNTRUSTED = ErrorCode._(
      22, _omitEnumNames ? '' : 'ERROR_CODE_PRIVILEGED_CLIENT_UNTRUSTED');
  static const ErrorCode ERROR_CODE_PRIVILEGED_LEASE_EXPIRED = ErrorCode._(
      23, _omitEnumNames ? '' : 'ERROR_CODE_PRIVILEGED_LEASE_EXPIRED');
  static const ErrorCode ERROR_CODE_SECURE_ATTENTION_UNAVAILABLE = ErrorCode._(
      24, _omitEnumNames ? '' : 'ERROR_CODE_SECURE_ATTENTION_UNAVAILABLE');
  static const ErrorCode ERROR_CODE_LOCAL_EMERGENCY_STOP =
      ErrorCode._(25, _omitEnumNames ? '' : 'ERROR_CODE_LOCAL_EMERGENCY_STOP');

  static const $core.List<ErrorCode> values = <ErrorCode>[
    ERROR_CODE_UNSPECIFIED,
    ERROR_CODE_PAIRING_CODE_EXPIRED,
    ERROR_CODE_PAIRING_RATE_LIMITED,
    ERROR_CODE_PAIRING_REJECTED,
    ERROR_CODE_DEVICE_OFFLINE,
    ERROR_CODE_DEVICE_BUSY,
    ERROR_CODE_AUTH_INVALID,
    ERROR_CODE_AUTH_REVOKED,
    ERROR_CODE_SESSION_REPLAYED,
    ERROR_CODE_ICE_FAILED,
    ERROR_CODE_TURN_UNAVAILABLE,
    ERROR_CODE_CODEC_NEGOTIATION_FAILED,
    ERROR_CODE_CAPTURE_PERMISSION_REQUIRED,
    ERROR_CODE_INPUT_PERMISSION_REQUIRED,
    ERROR_CODE_CAPTURE_FAILED,
    ERROR_CODE_INPUT_INJECTION_FAILED,
    ERROR_CODE_APP_MOVED_TO_BACKGROUND,
    ERROR_CODE_INVALID_REQUEST,
    ERROR_CODE_PROTOCOL_UNSUPPORTED,
    ERROR_CODE_MESSAGE_TOO_LARGE,
    ERROR_CODE_SERVER_UNAVAILABLE,
    ERROR_CODE_PRIVILEGED_BRIDGE_UNAVAILABLE,
    ERROR_CODE_PRIVILEGED_CLIENT_UNTRUSTED,
    ERROR_CODE_PRIVILEGED_LEASE_EXPIRED,
    ERROR_CODE_SECURE_ATTENTION_UNAVAILABLE,
    ERROR_CODE_LOCAL_EMERGENCY_STOP,
  ];

  static final $core.List<ErrorCode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 25);
  static ErrorCode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ErrorCode._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
