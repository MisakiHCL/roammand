// SPDX-License-Identifier: Apache-2.0

// This is a generated file - do not edit.
//
// Generated from roammand/v1/signaling_service.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class PairingRendezvousKind extends $pb.ProtobufEnum {
  static const PairingRendezvousKind PAIRING_RENDEZVOUS_KIND_UNSPECIFIED =
      PairingRendezvousKind._(
          0, _omitEnumNames ? '' : 'PAIRING_RENDEZVOUS_KIND_UNSPECIFIED');
  static const PairingRendezvousKind PAIRING_RENDEZVOUS_KIND_QR =
      PairingRendezvousKind._(
          1, _omitEnumNames ? '' : 'PAIRING_RENDEZVOUS_KIND_QR');
  static const PairingRendezvousKind PAIRING_RENDEZVOUS_KIND_DESKTOP_CODE =
      PairingRendezvousKind._(
          2, _omitEnumNames ? '' : 'PAIRING_RENDEZVOUS_KIND_DESKTOP_CODE');

  static const $core.List<PairingRendezvousKind> values =
      <PairingRendezvousKind>[
    PAIRING_RENDEZVOUS_KIND_UNSPECIFIED,
    PAIRING_RENDEZVOUS_KIND_QR,
    PAIRING_RENDEZVOUS_KIND_DESKTOP_CODE,
  ];

  static final $core.List<PairingRendezvousKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static PairingRendezvousKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PairingRendezvousKind._(super.value, super.name);
}

class PairingRendezvousCompletion extends $pb.ProtobufEnum {
  static const PairingRendezvousCompletion
      PAIRING_RENDEZVOUS_COMPLETION_UNSPECIFIED = PairingRendezvousCompletion._(
          0, _omitEnumNames ? '' : 'PAIRING_RENDEZVOUS_COMPLETION_UNSPECIFIED');
  static const PairingRendezvousCompletion
      PAIRING_RENDEZVOUS_COMPLETION_SUCCEEDED = PairingRendezvousCompletion._(
          1, _omitEnumNames ? '' : 'PAIRING_RENDEZVOUS_COMPLETION_SUCCEEDED');
  static const PairingRendezvousCompletion
      PAIRING_RENDEZVOUS_COMPLETION_REJECTED = PairingRendezvousCompletion._(
          2, _omitEnumNames ? '' : 'PAIRING_RENDEZVOUS_COMPLETION_REJECTED');
  static const PairingRendezvousCompletion
      PAIRING_RENDEZVOUS_COMPLETION_EXPIRED = PairingRendezvousCompletion._(
          3, _omitEnumNames ? '' : 'PAIRING_RENDEZVOUS_COMPLETION_EXPIRED');
  static const PairingRendezvousCompletion
      PAIRING_RENDEZVOUS_COMPLETION_DISCONNECTED =
      PairingRendezvousCompletion._(4,
          _omitEnumNames ? '' : 'PAIRING_RENDEZVOUS_COMPLETION_DISCONNECTED');

  static const $core.List<PairingRendezvousCompletion> values =
      <PairingRendezvousCompletion>[
    PAIRING_RENDEZVOUS_COMPLETION_UNSPECIFIED,
    PAIRING_RENDEZVOUS_COMPLETION_SUCCEEDED,
    PAIRING_RENDEZVOUS_COMPLETION_REJECTED,
    PAIRING_RENDEZVOUS_COMPLETION_EXPIRED,
    PAIRING_RENDEZVOUS_COMPLETION_DISCONNECTED,
  ];

  static final $core.List<PairingRendezvousCompletion?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static PairingRendezvousCompletion? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PairingRendezvousCompletion._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
