// SPDX-License-Identifier: Apache-2.0

// This is a generated file - do not edit.
//
// Generated from roammand/v1/webrtc.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class SessionDescriptionType extends $pb.ProtobufEnum {
  static const SessionDescriptionType SESSION_DESCRIPTION_TYPE_UNSPECIFIED =
      SessionDescriptionType._(
          0, _omitEnumNames ? '' : 'SESSION_DESCRIPTION_TYPE_UNSPECIFIED');
  static const SessionDescriptionType SESSION_DESCRIPTION_TYPE_OFFER =
      SessionDescriptionType._(
          1, _omitEnumNames ? '' : 'SESSION_DESCRIPTION_TYPE_OFFER');
  static const SessionDescriptionType SESSION_DESCRIPTION_TYPE_ANSWER =
      SessionDescriptionType._(
          2, _omitEnumNames ? '' : 'SESSION_DESCRIPTION_TYPE_ANSWER');

  static const $core.List<SessionDescriptionType> values =
      <SessionDescriptionType>[
    SESSION_DESCRIPTION_TYPE_UNSPECIFIED,
    SESSION_DESCRIPTION_TYPE_OFFER,
    SESSION_DESCRIPTION_TYPE_ANSWER,
  ];

  static final $core.List<SessionDescriptionType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static SessionDescriptionType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SessionDescriptionType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
