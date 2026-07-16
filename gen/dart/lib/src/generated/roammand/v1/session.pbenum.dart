// SPDX-License-Identifier: Apache-2.0

// This is a generated file - do not edit.
//
// Generated from roammand/v1/session.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class SessionPermission extends $pb.ProtobufEnum {
  static const SessionPermission SESSION_PERMISSION_UNSPECIFIED =
      SessionPermission._(
          0, _omitEnumNames ? '' : 'SESSION_PERMISSION_UNSPECIFIED');
  static const SessionPermission SESSION_PERMISSION_VIEW_SCREEN =
      SessionPermission._(
          1, _omitEnumNames ? '' : 'SESSION_PERMISSION_VIEW_SCREEN');
  static const SessionPermission SESSION_PERMISSION_CONTROL_INPUT =
      SessionPermission._(
          2, _omitEnumNames ? '' : 'SESSION_PERMISSION_CONTROL_INPUT');

  static const $core.List<SessionPermission> values = <SessionPermission>[
    SESSION_PERMISSION_UNSPECIFIED,
    SESSION_PERMISSION_VIEW_SCREEN,
    SESSION_PERMISSION_CONTROL_INPUT,
  ];

  static final $core.List<SessionPermission?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static SessionPermission? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SessionPermission._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
