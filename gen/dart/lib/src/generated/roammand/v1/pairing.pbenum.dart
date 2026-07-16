// SPDX-License-Identifier: Apache-2.0

// This is a generated file - do not edit.
//
// Generated from roammand/v1/pairing.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class PairingDecisionStatus extends $pb.ProtobufEnum {
  static const PairingDecisionStatus PAIRING_DECISION_STATUS_UNSPECIFIED =
      PairingDecisionStatus._(
          0, _omitEnumNames ? '' : 'PAIRING_DECISION_STATUS_UNSPECIFIED');
  static const PairingDecisionStatus PAIRING_DECISION_STATUS_PENDING =
      PairingDecisionStatus._(
          1, _omitEnumNames ? '' : 'PAIRING_DECISION_STATUS_PENDING');
  static const PairingDecisionStatus PAIRING_DECISION_STATUS_ACCEPTED =
      PairingDecisionStatus._(
          2, _omitEnumNames ? '' : 'PAIRING_DECISION_STATUS_ACCEPTED');
  static const PairingDecisionStatus PAIRING_DECISION_STATUS_REJECTED =
      PairingDecisionStatus._(
          3, _omitEnumNames ? '' : 'PAIRING_DECISION_STATUS_REJECTED');
  static const PairingDecisionStatus PAIRING_DECISION_STATUS_EXPIRED =
      PairingDecisionStatus._(
          4, _omitEnumNames ? '' : 'PAIRING_DECISION_STATUS_EXPIRED');

  static const $core.List<PairingDecisionStatus> values =
      <PairingDecisionStatus>[
    PAIRING_DECISION_STATUS_UNSPECIFIED,
    PAIRING_DECISION_STATUS_PENDING,
    PAIRING_DECISION_STATUS_ACCEPTED,
    PAIRING_DECISION_STATUS_REJECTED,
    PAIRING_DECISION_STATUS_EXPIRED,
  ];

  static final $core.List<PairingDecisionStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static PairingDecisionStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PairingDecisionStatus._(super.value, super.name);
}

class PairingDirection extends $pb.ProtobufEnum {
  static const PairingDirection PAIRING_DIRECTION_UNSPECIFIED =
      PairingDirection._(
          0, _omitEnumNames ? '' : 'PAIRING_DIRECTION_UNSPECIFIED');
  static const PairingDirection PAIRING_DIRECTION_CONTROLLER_TO_HOST =
      PairingDirection._(
          1, _omitEnumNames ? '' : 'PAIRING_DIRECTION_CONTROLLER_TO_HOST');
  static const PairingDirection PAIRING_DIRECTION_HOST_TO_CONTROLLER =
      PairingDirection._(
          2, _omitEnumNames ? '' : 'PAIRING_DIRECTION_HOST_TO_CONTROLLER');

  static const $core.List<PairingDirection> values = <PairingDirection>[
    PAIRING_DIRECTION_UNSPECIFIED,
    PAIRING_DIRECTION_CONTROLLER_TO_HOST,
    PAIRING_DIRECTION_HOST_TO_CONTROLLER,
  ];

  static final $core.List<PairingDirection?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static PairingDirection? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PairingDirection._(super.value, super.name);
}

class PairingIdentityRole extends $pb.ProtobufEnum {
  static const PairingIdentityRole PAIRING_IDENTITY_ROLE_UNSPECIFIED =
      PairingIdentityRole._(
          0, _omitEnumNames ? '' : 'PAIRING_IDENTITY_ROLE_UNSPECIFIED');
  static const PairingIdentityRole PAIRING_IDENTITY_ROLE_CONTROLLER =
      PairingIdentityRole._(
          1, _omitEnumNames ? '' : 'PAIRING_IDENTITY_ROLE_CONTROLLER');
  static const PairingIdentityRole PAIRING_IDENTITY_ROLE_HOST =
      PairingIdentityRole._(
          2, _omitEnumNames ? '' : 'PAIRING_IDENTITY_ROLE_HOST');

  static const $core.List<PairingIdentityRole> values = <PairingIdentityRole>[
    PAIRING_IDENTITY_ROLE_UNSPECIFIED,
    PAIRING_IDENTITY_ROLE_CONTROLLER,
    PAIRING_IDENTITY_ROLE_HOST,
  ];

  static final $core.List<PairingIdentityRole?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static PairingIdentityRole? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PairingIdentityRole._(super.value, super.name);
}

class PairingInvitationKind extends $pb.ProtobufEnum {
  static const PairingInvitationKind PAIRING_INVITATION_KIND_UNSPECIFIED =
      PairingInvitationKind._(
          0, _omitEnumNames ? '' : 'PAIRING_INVITATION_KIND_UNSPECIFIED');
  static const PairingInvitationKind PAIRING_INVITATION_KIND_QR =
      PairingInvitationKind._(
          1, _omitEnumNames ? '' : 'PAIRING_INVITATION_KIND_QR');
  static const PairingInvitationKind PAIRING_INVITATION_KIND_DESKTOP_CODE =
      PairingInvitationKind._(
          2, _omitEnumNames ? '' : 'PAIRING_INVITATION_KIND_DESKTOP_CODE');

  static const $core.List<PairingInvitationKind> values =
      <PairingInvitationKind>[
    PAIRING_INVITATION_KIND_UNSPECIFIED,
    PAIRING_INVITATION_KIND_QR,
    PAIRING_INVITATION_KIND_DESKTOP_CODE,
  ];

  static final $core.List<PairingInvitationKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static PairingInvitationKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PairingInvitationKind._(super.value, super.name);
}

class HostPairingState extends $pb.ProtobufEnum {
  static const HostPairingState HOST_PAIRING_STATE_UNSPECIFIED =
      HostPairingState._(
          0, _omitEnumNames ? '' : 'HOST_PAIRING_STATE_UNSPECIFIED');
  static const HostPairingState HOST_PAIRING_STATE_IDLE =
      HostPairingState._(1, _omitEnumNames ? '' : 'HOST_PAIRING_STATE_IDLE');
  static const HostPairingState HOST_PAIRING_STATE_CREATING =
      HostPairingState._(
          2, _omitEnumNames ? '' : 'HOST_PAIRING_STATE_CREATING');
  static const HostPairingState HOST_PAIRING_STATE_INVITING =
      HostPairingState._(
          3, _omitEnumNames ? '' : 'HOST_PAIRING_STATE_INVITING');
  static const HostPairingState HOST_PAIRING_STATE_VERIFYING_CONTROLLER =
      HostPairingState._(
          4, _omitEnumNames ? '' : 'HOST_PAIRING_STATE_VERIFYING_CONTROLLER');
  static const HostPairingState HOST_PAIRING_STATE_WAITING_LOCAL_DECISION =
      HostPairingState._(
          5, _omitEnumNames ? '' : 'HOST_PAIRING_STATE_WAITING_LOCAL_DECISION');
  static const HostPairingState HOST_PAIRING_STATE_ACCEPTED =
      HostPairingState._(
          6, _omitEnumNames ? '' : 'HOST_PAIRING_STATE_ACCEPTED');
  static const HostPairingState HOST_PAIRING_STATE_REJECTED =
      HostPairingState._(
          7, _omitEnumNames ? '' : 'HOST_PAIRING_STATE_REJECTED');
  static const HostPairingState HOST_PAIRING_STATE_EXPIRED =
      HostPairingState._(8, _omitEnumNames ? '' : 'HOST_PAIRING_STATE_EXPIRED');
  static const HostPairingState HOST_PAIRING_STATE_CANCELLED =
      HostPairingState._(
          9, _omitEnumNames ? '' : 'HOST_PAIRING_STATE_CANCELLED');
  static const HostPairingState HOST_PAIRING_STATE_FAILED =
      HostPairingState._(10, _omitEnumNames ? '' : 'HOST_PAIRING_STATE_FAILED');

  static const $core.List<HostPairingState> values = <HostPairingState>[
    HOST_PAIRING_STATE_UNSPECIFIED,
    HOST_PAIRING_STATE_IDLE,
    HOST_PAIRING_STATE_CREATING,
    HOST_PAIRING_STATE_INVITING,
    HOST_PAIRING_STATE_VERIFYING_CONTROLLER,
    HOST_PAIRING_STATE_WAITING_LOCAL_DECISION,
    HOST_PAIRING_STATE_ACCEPTED,
    HOST_PAIRING_STATE_REJECTED,
    HOST_PAIRING_STATE_EXPIRED,
    HOST_PAIRING_STATE_CANCELLED,
    HOST_PAIRING_STATE_FAILED,
  ];

  static final $core.List<HostPairingState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 10);
  static HostPairingState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const HostPairingState._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
