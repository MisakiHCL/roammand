// SPDX-License-Identifier: Apache-2.0

// This is a generated file - do not edit.
//
// Generated from roammand/v1/authorization.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class GrantRevocationReason extends $pb.ProtobufEnum {
  static const GrantRevocationReason GRANT_REVOCATION_REASON_UNSPECIFIED =
      GrantRevocationReason._(
          0, _omitEnumNames ? '' : 'GRANT_REVOCATION_REASON_UNSPECIFIED');
  static const GrantRevocationReason GRANT_REVOCATION_REASON_USER_REQUESTED =
      GrantRevocationReason._(
          1, _omitEnumNames ? '' : 'GRANT_REVOCATION_REASON_USER_REQUESTED');
  static const GrantRevocationReason GRANT_REVOCATION_REASON_IDENTITY_RESET =
      GrantRevocationReason._(
          2, _omitEnumNames ? '' : 'GRANT_REVOCATION_REASON_IDENTITY_RESET');
  static const GrantRevocationReason GRANT_REVOCATION_REASON_SECURITY_RESPONSE =
      GrantRevocationReason._(
          3, _omitEnumNames ? '' : 'GRANT_REVOCATION_REASON_SECURITY_RESPONSE');

  static const $core.List<GrantRevocationReason> values =
      <GrantRevocationReason>[
    GRANT_REVOCATION_REASON_UNSPECIFIED,
    GRANT_REVOCATION_REASON_USER_REQUESTED,
    GRANT_REVOCATION_REASON_IDENTITY_RESET,
    GRANT_REVOCATION_REASON_SECURITY_RESPONSE,
  ];

  static final $core.List<GrantRevocationReason?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static GrantRevocationReason? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const GrantRevocationReason._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
