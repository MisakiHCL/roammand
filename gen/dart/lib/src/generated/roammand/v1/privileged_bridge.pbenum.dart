// SPDX-License-Identifier: Apache-2.0

// This is a generated file - do not edit.
//
// Generated from roammand/v1/privileged_bridge.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class PrivilegedBridgeState extends $pb.ProtobufEnum {
  static const PrivilegedBridgeState PRIVILEGED_BRIDGE_STATE_UNSPECIFIED =
      PrivilegedBridgeState._(
          0, _omitEnumNames ? '' : 'PRIVILEGED_BRIDGE_STATE_UNSPECIFIED');
  static const PrivilegedBridgeState PRIVILEGED_BRIDGE_STATE_NOT_INSTALLED =
      PrivilegedBridgeState._(
          1, _omitEnumNames ? '' : 'PRIVILEGED_BRIDGE_STATE_NOT_INSTALLED');
  static const PrivilegedBridgeState PRIVILEGED_BRIDGE_STATE_APPROVAL_REQUIRED =
      PrivilegedBridgeState._(
          2, _omitEnumNames ? '' : 'PRIVILEGED_BRIDGE_STATE_APPROVAL_REQUIRED');
  static const PrivilegedBridgeState
      PRIVILEGED_BRIDGE_STATE_PERMISSION_REQUIRED = PrivilegedBridgeState._(3,
          _omitEnumNames ? '' : 'PRIVILEGED_BRIDGE_STATE_PERMISSION_REQUIRED');
  static const PrivilegedBridgeState PRIVILEGED_BRIDGE_STATE_USER_SESSION_ONLY =
      PrivilegedBridgeState._(
          4, _omitEnumNames ? '' : 'PRIVILEGED_BRIDGE_STATE_USER_SESSION_ONLY');
  static const PrivilegedBridgeState PRIVILEGED_BRIDGE_STATE_READY =
      PrivilegedBridgeState._(
          5, _omitEnumNames ? '' : 'PRIVILEGED_BRIDGE_STATE_READY');
  static const PrivilegedBridgeState PRIVILEGED_BRIDGE_STATE_TRANSITIONING =
      PrivilegedBridgeState._(
          6, _omitEnumNames ? '' : 'PRIVILEGED_BRIDGE_STATE_TRANSITIONING');
  static const PrivilegedBridgeState PRIVILEGED_BRIDGE_STATE_CONTROLLED =
      PrivilegedBridgeState._(
          7, _omitEnumNames ? '' : 'PRIVILEGED_BRIDGE_STATE_CONTROLLED');
  static const PrivilegedBridgeState PRIVILEGED_BRIDGE_STATE_FAILED =
      PrivilegedBridgeState._(
          8, _omitEnumNames ? '' : 'PRIVILEGED_BRIDGE_STATE_FAILED');

  static const $core.List<PrivilegedBridgeState> values =
      <PrivilegedBridgeState>[
    PRIVILEGED_BRIDGE_STATE_UNSPECIFIED,
    PRIVILEGED_BRIDGE_STATE_NOT_INSTALLED,
    PRIVILEGED_BRIDGE_STATE_APPROVAL_REQUIRED,
    PRIVILEGED_BRIDGE_STATE_PERMISSION_REQUIRED,
    PRIVILEGED_BRIDGE_STATE_USER_SESSION_ONLY,
    PRIVILEGED_BRIDGE_STATE_READY,
    PRIVILEGED_BRIDGE_STATE_TRANSITIONING,
    PRIVILEGED_BRIDGE_STATE_CONTROLLED,
    PRIVILEGED_BRIDGE_STATE_FAILED,
  ];

  static final $core.List<PrivilegedBridgeState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 8);
  static PrivilegedBridgeState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PrivilegedBridgeState._(super.value, super.name);
}

class InteractiveDesktopKind extends $pb.ProtobufEnum {
  static const InteractiveDesktopKind INTERACTIVE_DESKTOP_KIND_UNSPECIFIED =
      InteractiveDesktopKind._(
          0, _omitEnumNames ? '' : 'INTERACTIVE_DESKTOP_KIND_UNSPECIFIED');
  static const InteractiveDesktopKind INTERACTIVE_DESKTOP_KIND_NORMAL =
      InteractiveDesktopKind._(
          1, _omitEnumNames ? '' : 'INTERACTIVE_DESKTOP_KIND_NORMAL');
  static const InteractiveDesktopKind INTERACTIVE_DESKTOP_KIND_LOCKED_LOGIN =
      InteractiveDesktopKind._(
          2, _omitEnumNames ? '' : 'INTERACTIVE_DESKTOP_KIND_LOCKED_LOGIN');
  static const InteractiveDesktopKind INTERACTIVE_DESKTOP_KIND_SECURE =
      InteractiveDesktopKind._(
          3, _omitEnumNames ? '' : 'INTERACTIVE_DESKTOP_KIND_SECURE');
  static const InteractiveDesktopKind INTERACTIVE_DESKTOP_KIND_UNAVAILABLE =
      InteractiveDesktopKind._(
          4, _omitEnumNames ? '' : 'INTERACTIVE_DESKTOP_KIND_UNAVAILABLE');

  static const $core.List<InteractiveDesktopKind> values =
      <InteractiveDesktopKind>[
    INTERACTIVE_DESKTOP_KIND_UNSPECIFIED,
    INTERACTIVE_DESKTOP_KIND_NORMAL,
    INTERACTIVE_DESKTOP_KIND_LOCKED_LOGIN,
    INTERACTIVE_DESKTOP_KIND_SECURE,
    INTERACTIVE_DESKTOP_KIND_UNAVAILABLE,
  ];

  static final $core.List<InteractiveDesktopKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static InteractiveDesktopKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const InteractiveDesktopKind._(super.value, super.name);
}

class PrivilegedBridgeRole extends $pb.ProtobufEnum {
  static const PrivilegedBridgeRole PRIVILEGED_BRIDGE_ROLE_UNSPECIFIED =
      PrivilegedBridgeRole._(
          0, _omitEnumNames ? '' : 'PRIVILEGED_BRIDGE_ROLE_UNSPECIFIED');
  static const PrivilegedBridgeRole PRIVILEGED_BRIDGE_ROLE_HOST_AGENT =
      PrivilegedBridgeRole._(
          1, _omitEnumNames ? '' : 'PRIVILEGED_BRIDGE_ROLE_HOST_AGENT');
  static const PrivilegedBridgeRole PRIVILEGED_BRIDGE_ROLE_SESSION_HELPER =
      PrivilegedBridgeRole._(
          2, _omitEnumNames ? '' : 'PRIVILEGED_BRIDGE_ROLE_SESSION_HELPER');

  static const $core.List<PrivilegedBridgeRole> values = <PrivilegedBridgeRole>[
    PRIVILEGED_BRIDGE_ROLE_UNSPECIFIED,
    PRIVILEGED_BRIDGE_ROLE_HOST_AGENT,
    PRIVILEGED_BRIDGE_ROLE_SESSION_HELPER,
  ];

  static final $core.List<PrivilegedBridgeRole?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static PrivilegedBridgeRole? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PrivilegedBridgeRole._(super.value, super.name);
}

class PrivilegedIceTransportPolicy extends $pb.ProtobufEnum {
  static const PrivilegedIceTransportPolicy
      PRIVILEGED_ICE_TRANSPORT_POLICY_UNSPECIFIED =
      PrivilegedIceTransportPolicy._(0,
          _omitEnumNames ? '' : 'PRIVILEGED_ICE_TRANSPORT_POLICY_UNSPECIFIED');
  static const PrivilegedIceTransportPolicy
      PRIVILEGED_ICE_TRANSPORT_POLICY_ALL = PrivilegedIceTransportPolicy._(
          1, _omitEnumNames ? '' : 'PRIVILEGED_ICE_TRANSPORT_POLICY_ALL');
  static const PrivilegedIceTransportPolicy
      PRIVILEGED_ICE_TRANSPORT_POLICY_RELAY = PrivilegedIceTransportPolicy._(
          2, _omitEnumNames ? '' : 'PRIVILEGED_ICE_TRANSPORT_POLICY_RELAY');

  static const $core.List<PrivilegedIceTransportPolicy> values =
      <PrivilegedIceTransportPolicy>[
    PRIVILEGED_ICE_TRANSPORT_POLICY_UNSPECIFIED,
    PRIVILEGED_ICE_TRANSPORT_POLICY_ALL,
    PRIVILEGED_ICE_TRANSPORT_POLICY_RELAY,
  ];

  static final $core.List<PrivilegedIceTransportPolicy?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static PrivilegedIceTransportPolicy? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PrivilegedIceTransportPolicy._(super.value, super.name);
}

class PrivilegedPeerState extends $pb.ProtobufEnum {
  static const PrivilegedPeerState PRIVILEGED_PEER_STATE_UNSPECIFIED =
      PrivilegedPeerState._(
          0, _omitEnumNames ? '' : 'PRIVILEGED_PEER_STATE_UNSPECIFIED');
  static const PrivilegedPeerState PRIVILEGED_PEER_STATE_NEW =
      PrivilegedPeerState._(
          1, _omitEnumNames ? '' : 'PRIVILEGED_PEER_STATE_NEW');
  static const PrivilegedPeerState PRIVILEGED_PEER_STATE_NEGOTIATING =
      PrivilegedPeerState._(
          2, _omitEnumNames ? '' : 'PRIVILEGED_PEER_STATE_NEGOTIATING');
  static const PrivilegedPeerState PRIVILEGED_PEER_STATE_CONNECTED =
      PrivilegedPeerState._(
          3, _omitEnumNames ? '' : 'PRIVILEGED_PEER_STATE_CONNECTED');
  static const PrivilegedPeerState PRIVILEGED_PEER_STATE_DISCONNECTED =
      PrivilegedPeerState._(
          4, _omitEnumNames ? '' : 'PRIVILEGED_PEER_STATE_DISCONNECTED');
  static const PrivilegedPeerState PRIVILEGED_PEER_STATE_FAILED =
      PrivilegedPeerState._(
          5, _omitEnumNames ? '' : 'PRIVILEGED_PEER_STATE_FAILED');
  static const PrivilegedPeerState PRIVILEGED_PEER_STATE_CLOSED =
      PrivilegedPeerState._(
          6, _omitEnumNames ? '' : 'PRIVILEGED_PEER_STATE_CLOSED');

  static const $core.List<PrivilegedPeerState> values = <PrivilegedPeerState>[
    PRIVILEGED_PEER_STATE_UNSPECIFIED,
    PRIVILEGED_PEER_STATE_NEW,
    PRIVILEGED_PEER_STATE_NEGOTIATING,
    PRIVILEGED_PEER_STATE_CONNECTED,
    PRIVILEGED_PEER_STATE_DISCONNECTED,
    PRIVILEGED_PEER_STATE_FAILED,
    PRIVILEGED_PEER_STATE_CLOSED,
  ];

  static final $core.List<PrivilegedPeerState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static PrivilegedPeerState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PrivilegedPeerState._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
