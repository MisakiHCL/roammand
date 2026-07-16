// SPDX-License-Identifier: Apache-2.0

// This is a generated file - do not edit.
//
// Generated from roammand/v1/status.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class SessionState extends $pb.ProtobufEnum {
  static const SessionState SESSION_STATE_UNSPECIFIED =
      SessionState._(0, _omitEnumNames ? '' : 'SESSION_STATE_UNSPECIFIED');
  static const SessionState SESSION_STATE_IDLE =
      SessionState._(1, _omitEnumNames ? '' : 'SESSION_STATE_IDLE');
  static const SessionState SESSION_STATE_SIGNALING =
      SessionState._(2, _omitEnumNames ? '' : 'SESSION_STATE_SIGNALING');
  static const SessionState SESSION_STATE_AUTHENTICATING =
      SessionState._(3, _omitEnumNames ? '' : 'SESSION_STATE_AUTHENTICATING');
  static const SessionState SESSION_STATE_CONNECTING =
      SessionState._(4, _omitEnumNames ? '' : 'SESSION_STATE_CONNECTING');
  static const SessionState SESSION_STATE_CONNECTED =
      SessionState._(5, _omitEnumNames ? '' : 'SESSION_STATE_CONNECTED');
  static const SessionState SESSION_STATE_RECONNECTING =
      SessionState._(6, _omitEnumNames ? '' : 'SESSION_STATE_RECONNECTING');
  static const SessionState SESSION_STATE_FAILED =
      SessionState._(7, _omitEnumNames ? '' : 'SESSION_STATE_FAILED');
  static const SessionState SESSION_STATE_CLOSING =
      SessionState._(8, _omitEnumNames ? '' : 'SESSION_STATE_CLOSING');

  static const $core.List<SessionState> values = <SessionState>[
    SESSION_STATE_UNSPECIFIED,
    SESSION_STATE_IDLE,
    SESSION_STATE_SIGNALING,
    SESSION_STATE_AUTHENTICATING,
    SESSION_STATE_CONNECTING,
    SESSION_STATE_CONNECTED,
    SESSION_STATE_RECONNECTING,
    SESSION_STATE_FAILED,
    SESSION_STATE_CLOSING,
  ];

  static final $core.List<SessionState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 8);
  static SessionState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SessionState._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
