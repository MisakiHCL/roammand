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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'authorization.pbenum.dart';
import 'identity.pb.dart' as $0;
import 'session.pbenum.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'authorization.pbenum.dart';

class ControllerGrant extends $pb.GeneratedMessage {
  factory ControllerGrant({
    $core.List<$core.int>? grantId,
    $core.List<$core.int>? hostDeviceId,
    $0.DeviceIdentity? controller,
    $fixnum.Int64? createdAtUnixMs,
    $core.Iterable<$1.SessionPermission>? permissions,
  }) {
    final result = create();
    if (grantId != null) result.grantId = grantId;
    if (hostDeviceId != null) result.hostDeviceId = hostDeviceId;
    if (controller != null) result.controller = controller;
    if (createdAtUnixMs != null) result.createdAtUnixMs = createdAtUnixMs;
    if (permissions != null) result.permissions.addAll(permissions);
    return result;
  }

  ControllerGrant._();

  factory ControllerGrant.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ControllerGrant.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ControllerGrant',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'grantId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'hostDeviceId', $pb.PbFieldType.OY)
    ..aOM<$0.DeviceIdentity>(3, _omitFieldNames ? '' : 'controller',
        subBuilder: $0.DeviceIdentity.create)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'createdAtUnixMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pc<$1.SessionPermission>(
        5, _omitFieldNames ? '' : 'permissions', $pb.PbFieldType.KE,
        valueOf: $1.SessionPermission.valueOf,
        enumValues: $1.SessionPermission.values,
        defaultEnumValue: $1.SessionPermission.SESSION_PERMISSION_UNSPECIFIED)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControllerGrant clone() => ControllerGrant()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControllerGrant copyWith(void Function(ControllerGrant) updates) =>
      super.copyWith((message) => updates(message as ControllerGrant))
          as ControllerGrant;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ControllerGrant create() => ControllerGrant._();
  @$core.override
  ControllerGrant createEmptyInstance() => create();
  static $pb.PbList<ControllerGrant> createRepeated() =>
      $pb.PbList<ControllerGrant>();
  @$core.pragma('dart2js:noInline')
  static ControllerGrant getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ControllerGrant>(create);
  static ControllerGrant? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get grantId => $_getN(0);
  @$pb.TagNumber(1)
  set grantId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGrantId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGrantId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get hostDeviceId => $_getN(1);
  @$pb.TagNumber(2)
  set hostDeviceId($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHostDeviceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearHostDeviceId() => $_clearField(2);

  @$pb.TagNumber(3)
  $0.DeviceIdentity get controller => $_getN(2);
  @$pb.TagNumber(3)
  set controller($0.DeviceIdentity value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasController() => $_has(2);
  @$pb.TagNumber(3)
  void clearController() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.DeviceIdentity ensureController() => $_ensure(2);

  @$pb.TagNumber(4)
  $fixnum.Int64 get createdAtUnixMs => $_getI64(3);
  @$pb.TagNumber(4)
  set createdAtUnixMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCreatedAtUnixMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearCreatedAtUnixMs() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$1.SessionPermission> get permissions => $_getList(4);
}

class GrantRevocation extends $pb.GeneratedMessage {
  factory GrantRevocation({
    $core.List<$core.int>? grantId,
    $fixnum.Int64? revokedAtUnixMs,
    GrantRevocationReason? reason,
  }) {
    final result = create();
    if (grantId != null) result.grantId = grantId;
    if (revokedAtUnixMs != null) result.revokedAtUnixMs = revokedAtUnixMs;
    if (reason != null) result.reason = reason;
    return result;
  }

  GrantRevocation._();

  factory GrantRevocation.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GrantRevocation.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GrantRevocation',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'grantId', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'revokedAtUnixMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..e<GrantRevocationReason>(
        3, _omitFieldNames ? '' : 'reason', $pb.PbFieldType.OE,
        defaultOrMaker:
            GrantRevocationReason.GRANT_REVOCATION_REASON_UNSPECIFIED,
        valueOf: GrantRevocationReason.valueOf,
        enumValues: GrantRevocationReason.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GrantRevocation clone() => GrantRevocation()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GrantRevocation copyWith(void Function(GrantRevocation) updates) =>
      super.copyWith((message) => updates(message as GrantRevocation))
          as GrantRevocation;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GrantRevocation create() => GrantRevocation._();
  @$core.override
  GrantRevocation createEmptyInstance() => create();
  static $pb.PbList<GrantRevocation> createRepeated() =>
      $pb.PbList<GrantRevocation>();
  @$core.pragma('dart2js:noInline')
  static GrantRevocation getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GrantRevocation>(create);
  static GrantRevocation? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get grantId => $_getN(0);
  @$pb.TagNumber(1)
  set grantId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGrantId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGrantId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get revokedAtUnixMs => $_getI64(1);
  @$pb.TagNumber(2)
  set revokedAtUnixMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRevokedAtUnixMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearRevokedAtUnixMs() => $_clearField(2);

  @$pb.TagNumber(3)
  GrantRevocationReason get reason => $_getN(2);
  @$pb.TagNumber(3)
  set reason(GrantRevocationReason value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasReason() => $_has(2);
  @$pb.TagNumber(3)
  void clearReason() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
