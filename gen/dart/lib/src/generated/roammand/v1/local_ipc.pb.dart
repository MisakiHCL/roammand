// SPDX-License-Identifier: Apache-2.0

// This is a generated file - do not edit.
//
// Generated from roammand/v1/local_ipc.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'authorization.pb.dart' as $2;
import 'error.pb.dart' as $6;
import 'identity.pb.dart' as $0;
import 'pairing.pb.dart' as $4;
import 'privileged_bridge.pb.dart' as $1;
import 'session.pbenum.dart' as $7;
import 'status.pb.dart' as $3;
import 'version.pb.dart' as $5;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class LocalIpcChallenge extends $pb.GeneratedMessage {
  factory LocalIpcChallenge({
    $core.List<$core.int>? agentInstanceId,
    $core.List<$core.int>? serverNonce,
  }) {
    final result = create();
    if (agentInstanceId != null) result.agentInstanceId = agentInstanceId;
    if (serverNonce != null) result.serverNonce = serverNonce;
    return result;
  }

  LocalIpcChallenge._();

  factory LocalIpcChallenge.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LocalIpcChallenge.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LocalIpcChallenge',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'agentInstanceId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'serverNonce', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocalIpcChallenge clone() => LocalIpcChallenge()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocalIpcChallenge copyWith(void Function(LocalIpcChallenge) updates) =>
      super.copyWith((message) => updates(message as LocalIpcChallenge))
          as LocalIpcChallenge;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LocalIpcChallenge create() => LocalIpcChallenge._();
  @$core.override
  LocalIpcChallenge createEmptyInstance() => create();
  static $pb.PbList<LocalIpcChallenge> createRepeated() =>
      $pb.PbList<LocalIpcChallenge>();
  @$core.pragma('dart2js:noInline')
  static LocalIpcChallenge getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LocalIpcChallenge>(create);
  static LocalIpcChallenge? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get agentInstanceId => $_getN(0);
  @$pb.TagNumber(1)
  set agentInstanceId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAgentInstanceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAgentInstanceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get serverNonce => $_getN(1);
  @$pb.TagNumber(2)
  set serverNonce($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasServerNonce() => $_has(1);
  @$pb.TagNumber(2)
  void clearServerNonce() => $_clearField(2);
}

class LocalIpcAuthenticate extends $pb.GeneratedMessage {
  factory LocalIpcAuthenticate({
    $core.List<$core.int>? clientNonce,
    $core.List<$core.int>? clientProof,
  }) {
    final result = create();
    if (clientNonce != null) result.clientNonce = clientNonce;
    if (clientProof != null) result.clientProof = clientProof;
    return result;
  }

  LocalIpcAuthenticate._();

  factory LocalIpcAuthenticate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LocalIpcAuthenticate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LocalIpcAuthenticate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'clientNonce', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'clientProof', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocalIpcAuthenticate clone() =>
      LocalIpcAuthenticate()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocalIpcAuthenticate copyWith(void Function(LocalIpcAuthenticate) updates) =>
      super.copyWith((message) => updates(message as LocalIpcAuthenticate))
          as LocalIpcAuthenticate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LocalIpcAuthenticate create() => LocalIpcAuthenticate._();
  @$core.override
  LocalIpcAuthenticate createEmptyInstance() => create();
  static $pb.PbList<LocalIpcAuthenticate> createRepeated() =>
      $pb.PbList<LocalIpcAuthenticate>();
  @$core.pragma('dart2js:noInline')
  static LocalIpcAuthenticate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LocalIpcAuthenticate>(create);
  static LocalIpcAuthenticate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get clientNonce => $_getN(0);
  @$pb.TagNumber(1)
  set clientNonce($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasClientNonce() => $_has(0);
  @$pb.TagNumber(1)
  void clearClientNonce() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get clientProof => $_getN(1);
  @$pb.TagNumber(2)
  set clientProof($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasClientProof() => $_has(1);
  @$pb.TagNumber(2)
  void clearClientProof() => $_clearField(2);
}

class LocalIpcAuthenticated extends $pb.GeneratedMessage {
  factory LocalIpcAuthenticated({
    $core.List<$core.int>? serverProof,
  }) {
    final result = create();
    if (serverProof != null) result.serverProof = serverProof;
    return result;
  }

  LocalIpcAuthenticated._();

  factory LocalIpcAuthenticated.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LocalIpcAuthenticated.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LocalIpcAuthenticated',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'serverProof', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocalIpcAuthenticated clone() =>
      LocalIpcAuthenticated()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocalIpcAuthenticated copyWith(
          void Function(LocalIpcAuthenticated) updates) =>
      super.copyWith((message) => updates(message as LocalIpcAuthenticated))
          as LocalIpcAuthenticated;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LocalIpcAuthenticated create() => LocalIpcAuthenticated._();
  @$core.override
  LocalIpcAuthenticated createEmptyInstance() => create();
  static $pb.PbList<LocalIpcAuthenticated> createRepeated() =>
      $pb.PbList<LocalIpcAuthenticated>();
  @$core.pragma('dart2js:noInline')
  static LocalIpcAuthenticated getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LocalIpcAuthenticated>(create);
  static LocalIpcAuthenticated? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get serverProof => $_getN(0);
  @$pb.TagNumber(1)
  set serverProof($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerProof() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerProof() => $_clearField(1);
}

class GetHostStatusRequest extends $pb.GeneratedMessage {
  factory GetHostStatusRequest() => create();

  GetHostStatusRequest._();

  factory GetHostStatusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetHostStatusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetHostStatusRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetHostStatusRequest clone() =>
      GetHostStatusRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetHostStatusRequest copyWith(void Function(GetHostStatusRequest) updates) =>
      super.copyWith((message) => updates(message as GetHostStatusRequest))
          as GetHostStatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetHostStatusRequest create() => GetHostStatusRequest._();
  @$core.override
  GetHostStatusRequest createEmptyInstance() => create();
  static $pb.PbList<GetHostStatusRequest> createRepeated() =>
      $pb.PbList<GetHostStatusRequest>();
  @$core.pragma('dart2js:noInline')
  static GetHostStatusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetHostStatusRequest>(create);
  static GetHostStatusRequest? _defaultInstance;
}

class HostStatus extends $pb.GeneratedMessage {
  factory HostStatus({
    $0.DeviceIdentity? identity,
    $core.List<$core.int>? agentInstanceId,
    $fixnum.Int64? agentStartedAtUnixMs,
    $core.int? controllerGrantCount,
    $1.PrivilegedBridgeStatusSnapshot? privilegedBridge,
  }) {
    final result = create();
    if (identity != null) result.identity = identity;
    if (agentInstanceId != null) result.agentInstanceId = agentInstanceId;
    if (agentStartedAtUnixMs != null)
      result.agentStartedAtUnixMs = agentStartedAtUnixMs;
    if (controllerGrantCount != null)
      result.controllerGrantCount = controllerGrantCount;
    if (privilegedBridge != null) result.privilegedBridge = privilegedBridge;
    return result;
  }

  HostStatus._();

  factory HostStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HostStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HostStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..aOM<$0.DeviceIdentity>(1, _omitFieldNames ? '' : 'identity',
        subBuilder: $0.DeviceIdentity.create)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'agentInstanceId', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'agentStartedAtUnixMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.int>(
        4, _omitFieldNames ? '' : 'controllerGrantCount', $pb.PbFieldType.OU3)
    ..aOM<$1.PrivilegedBridgeStatusSnapshot>(
        5, _omitFieldNames ? '' : 'privilegedBridge',
        subBuilder: $1.PrivilegedBridgeStatusSnapshot.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HostStatus clone() => HostStatus()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HostStatus copyWith(void Function(HostStatus) updates) =>
      super.copyWith((message) => updates(message as HostStatus)) as HostStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HostStatus create() => HostStatus._();
  @$core.override
  HostStatus createEmptyInstance() => create();
  static $pb.PbList<HostStatus> createRepeated() => $pb.PbList<HostStatus>();
  @$core.pragma('dart2js:noInline')
  static HostStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HostStatus>(create);
  static HostStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $0.DeviceIdentity get identity => $_getN(0);
  @$pb.TagNumber(1)
  set identity($0.DeviceIdentity value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasIdentity() => $_has(0);
  @$pb.TagNumber(1)
  void clearIdentity() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.DeviceIdentity ensureIdentity() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get agentInstanceId => $_getN(1);
  @$pb.TagNumber(2)
  set agentInstanceId($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAgentInstanceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAgentInstanceId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get agentStartedAtUnixMs => $_getI64(2);
  @$pb.TagNumber(3)
  set agentStartedAtUnixMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAgentStartedAtUnixMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearAgentStartedAtUnixMs() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get controllerGrantCount => $_getIZ(3);
  @$pb.TagNumber(4)
  set controllerGrantCount($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasControllerGrantCount() => $_has(3);
  @$pb.TagNumber(4)
  void clearControllerGrantCount() => $_clearField(4);

  @$pb.TagNumber(5)
  $1.PrivilegedBridgeStatusSnapshot get privilegedBridge => $_getN(4);
  @$pb.TagNumber(5)
  set privilegedBridge($1.PrivilegedBridgeStatusSnapshot value) =>
      $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasPrivilegedBridge() => $_has(4);
  @$pb.TagNumber(5)
  void clearPrivilegedBridge() => $_clearField(5);
  @$pb.TagNumber(5)
  $1.PrivilegedBridgeStatusSnapshot ensurePrivilegedBridge() => $_ensure(4);
}

class ControllerGrantView extends $pb.GeneratedMessage {
  factory ControllerGrantView({
    $2.ControllerGrant? grant,
    $fixnum.Int64? lastSuccessfulConnectionAtUnixMs,
  }) {
    final result = create();
    if (grant != null) result.grant = grant;
    if (lastSuccessfulConnectionAtUnixMs != null)
      result.lastSuccessfulConnectionAtUnixMs =
          lastSuccessfulConnectionAtUnixMs;
    return result;
  }

  ControllerGrantView._();

  factory ControllerGrantView.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ControllerGrantView.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ControllerGrantView',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..aOM<$2.ControllerGrant>(1, _omitFieldNames ? '' : 'grant',
        subBuilder: $2.ControllerGrant.create)
    ..a<$fixnum.Int64>(
        2,
        _omitFieldNames ? '' : 'lastSuccessfulConnectionAtUnixMs',
        $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControllerGrantView clone() => ControllerGrantView()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControllerGrantView copyWith(void Function(ControllerGrantView) updates) =>
      super.copyWith((message) => updates(message as ControllerGrantView))
          as ControllerGrantView;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ControllerGrantView create() => ControllerGrantView._();
  @$core.override
  ControllerGrantView createEmptyInstance() => create();
  static $pb.PbList<ControllerGrantView> createRepeated() =>
      $pb.PbList<ControllerGrantView>();
  @$core.pragma('dart2js:noInline')
  static ControllerGrantView getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ControllerGrantView>(create);
  static ControllerGrantView? _defaultInstance;

  @$pb.TagNumber(1)
  $2.ControllerGrant get grant => $_getN(0);
  @$pb.TagNumber(1)
  set grant($2.ControllerGrant value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasGrant() => $_has(0);
  @$pb.TagNumber(1)
  void clearGrant() => $_clearField(1);
  @$pb.TagNumber(1)
  $2.ControllerGrant ensureGrant() => $_ensure(0);

  @$pb.TagNumber(2)
  $fixnum.Int64 get lastSuccessfulConnectionAtUnixMs => $_getI64(1);
  @$pb.TagNumber(2)
  set lastSuccessfulConnectionAtUnixMs($fixnum.Int64 value) =>
      $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLastSuccessfulConnectionAtUnixMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearLastSuccessfulConnectionAtUnixMs() => $_clearField(2);
}

class ListControllerGrantsRequest extends $pb.GeneratedMessage {
  factory ListControllerGrantsRequest() => create();

  ListControllerGrantsRequest._();

  factory ListControllerGrantsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListControllerGrantsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListControllerGrantsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListControllerGrantsRequest clone() =>
      ListControllerGrantsRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListControllerGrantsRequest copyWith(
          void Function(ListControllerGrantsRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ListControllerGrantsRequest))
          as ListControllerGrantsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListControllerGrantsRequest create() =>
      ListControllerGrantsRequest._();
  @$core.override
  ListControllerGrantsRequest createEmptyInstance() => create();
  static $pb.PbList<ListControllerGrantsRequest> createRepeated() =>
      $pb.PbList<ListControllerGrantsRequest>();
  @$core.pragma('dart2js:noInline')
  static ListControllerGrantsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListControllerGrantsRequest>(create);
  static ListControllerGrantsRequest? _defaultInstance;
}

class ControllerGrantList extends $pb.GeneratedMessage {
  factory ControllerGrantList({
    $core.Iterable<ControllerGrantView>? grants,
  }) {
    final result = create();
    if (grants != null) result.grants.addAll(grants);
    return result;
  }

  ControllerGrantList._();

  factory ControllerGrantList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ControllerGrantList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ControllerGrantList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..pc<ControllerGrantView>(
        1, _omitFieldNames ? '' : 'grants', $pb.PbFieldType.PM,
        subBuilder: ControllerGrantView.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControllerGrantList clone() => ControllerGrantList()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControllerGrantList copyWith(void Function(ControllerGrantList) updates) =>
      super.copyWith((message) => updates(message as ControllerGrantList))
          as ControllerGrantList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ControllerGrantList create() => ControllerGrantList._();
  @$core.override
  ControllerGrantList createEmptyInstance() => create();
  static $pb.PbList<ControllerGrantList> createRepeated() =>
      $pb.PbList<ControllerGrantList>();
  @$core.pragma('dart2js:noInline')
  static ControllerGrantList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ControllerGrantList>(create);
  static ControllerGrantList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ControllerGrantView> get grants => $_getList(0);
}

class CreateControllerGrantRequest extends $pb.GeneratedMessage {
  factory CreateControllerGrantRequest({
    $0.DeviceIdentity? controller,
    $core.Iterable<$7.SessionPermission>? permissions,
  }) {
    final result = create();
    if (controller != null) result.controller = controller;
    if (permissions != null) result.permissions.addAll(permissions);
    return result;
  }

  CreateControllerGrantRequest._();

  factory CreateControllerGrantRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateControllerGrantRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateControllerGrantRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..aOM<$0.DeviceIdentity>(1, _omitFieldNames ? '' : 'controller',
        subBuilder: $0.DeviceIdentity.create)
    ..pc<$7.SessionPermission>(
        2, _omitFieldNames ? '' : 'permissions', $pb.PbFieldType.KE,
        valueOf: $7.SessionPermission.valueOf,
        enumValues: $7.SessionPermission.values,
        defaultEnumValue: $7.SessionPermission.SESSION_PERMISSION_UNSPECIFIED)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateControllerGrantRequest clone() =>
      CreateControllerGrantRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateControllerGrantRequest copyWith(
          void Function(CreateControllerGrantRequest) updates) =>
      super.copyWith(
              (message) => updates(message as CreateControllerGrantRequest))
          as CreateControllerGrantRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateControllerGrantRequest create() =>
      CreateControllerGrantRequest._();
  @$core.override
  CreateControllerGrantRequest createEmptyInstance() => create();
  static $pb.PbList<CreateControllerGrantRequest> createRepeated() =>
      $pb.PbList<CreateControllerGrantRequest>();
  @$core.pragma('dart2js:noInline')
  static CreateControllerGrantRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateControllerGrantRequest>(create);
  static CreateControllerGrantRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $0.DeviceIdentity get controller => $_getN(0);
  @$pb.TagNumber(1)
  set controller($0.DeviceIdentity value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasController() => $_has(0);
  @$pb.TagNumber(1)
  void clearController() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.DeviceIdentity ensureController() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<$7.SessionPermission> get permissions => $_getList(1);
}

class ControllerGrantCreated extends $pb.GeneratedMessage {
  factory ControllerGrantCreated({
    ControllerGrantView? grant,
  }) {
    final result = create();
    if (grant != null) result.grant = grant;
    return result;
  }

  ControllerGrantCreated._();

  factory ControllerGrantCreated.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ControllerGrantCreated.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ControllerGrantCreated',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..aOM<ControllerGrantView>(1, _omitFieldNames ? '' : 'grant',
        subBuilder: ControllerGrantView.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControllerGrantCreated clone() =>
      ControllerGrantCreated()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControllerGrantCreated copyWith(
          void Function(ControllerGrantCreated) updates) =>
      super.copyWith((message) => updates(message as ControllerGrantCreated))
          as ControllerGrantCreated;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ControllerGrantCreated create() => ControllerGrantCreated._();
  @$core.override
  ControllerGrantCreated createEmptyInstance() => create();
  static $pb.PbList<ControllerGrantCreated> createRepeated() =>
      $pb.PbList<ControllerGrantCreated>();
  @$core.pragma('dart2js:noInline')
  static ControllerGrantCreated getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ControllerGrantCreated>(create);
  static ControllerGrantCreated? _defaultInstance;

  @$pb.TagNumber(1)
  ControllerGrantView get grant => $_getN(0);
  @$pb.TagNumber(1)
  set grant(ControllerGrantView value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasGrant() => $_has(0);
  @$pb.TagNumber(1)
  void clearGrant() => $_clearField(1);
  @$pb.TagNumber(1)
  ControllerGrantView ensureGrant() => $_ensure(0);
}

class SignCanonicalTranscriptRequest extends $pb.GeneratedMessage {
  factory SignCanonicalTranscriptRequest({
    $core.List<$core.int>? canonicalTranscript,
  }) {
    final result = create();
    if (canonicalTranscript != null)
      result.canonicalTranscript = canonicalTranscript;
    return result;
  }

  SignCanonicalTranscriptRequest._();

  factory SignCanonicalTranscriptRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SignCanonicalTranscriptRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SignCanonicalTranscriptRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'canonicalTranscript', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SignCanonicalTranscriptRequest clone() =>
      SignCanonicalTranscriptRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SignCanonicalTranscriptRequest copyWith(
          void Function(SignCanonicalTranscriptRequest) updates) =>
      super.copyWith(
              (message) => updates(message as SignCanonicalTranscriptRequest))
          as SignCanonicalTranscriptRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SignCanonicalTranscriptRequest create() =>
      SignCanonicalTranscriptRequest._();
  @$core.override
  SignCanonicalTranscriptRequest createEmptyInstance() => create();
  static $pb.PbList<SignCanonicalTranscriptRequest> createRepeated() =>
      $pb.PbList<SignCanonicalTranscriptRequest>();
  @$core.pragma('dart2js:noInline')
  static SignCanonicalTranscriptRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SignCanonicalTranscriptRequest>(create);
  static SignCanonicalTranscriptRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get canonicalTranscript => $_getN(0);
  @$pb.TagNumber(1)
  set canonicalTranscript($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCanonicalTranscript() => $_has(0);
  @$pb.TagNumber(1)
  void clearCanonicalTranscript() => $_clearField(1);
}

class CanonicalTranscriptSignature extends $pb.GeneratedMessage {
  factory CanonicalTranscriptSignature({
    $core.List<$core.int>? hostDeviceId,
    $core.List<$core.int>? hostPublicKey,
    $core.List<$core.int>? signature,
    $core.List<$core.int>? transcriptSha256,
  }) {
    final result = create();
    if (hostDeviceId != null) result.hostDeviceId = hostDeviceId;
    if (hostPublicKey != null) result.hostPublicKey = hostPublicKey;
    if (signature != null) result.signature = signature;
    if (transcriptSha256 != null) result.transcriptSha256 = transcriptSha256;
    return result;
  }

  CanonicalTranscriptSignature._();

  factory CanonicalTranscriptSignature.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CanonicalTranscriptSignature.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CanonicalTranscriptSignature',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'hostDeviceId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'hostPublicKey', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'signature', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'transcriptSha256', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CanonicalTranscriptSignature clone() =>
      CanonicalTranscriptSignature()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CanonicalTranscriptSignature copyWith(
          void Function(CanonicalTranscriptSignature) updates) =>
      super.copyWith(
              (message) => updates(message as CanonicalTranscriptSignature))
          as CanonicalTranscriptSignature;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CanonicalTranscriptSignature create() =>
      CanonicalTranscriptSignature._();
  @$core.override
  CanonicalTranscriptSignature createEmptyInstance() => create();
  static $pb.PbList<CanonicalTranscriptSignature> createRepeated() =>
      $pb.PbList<CanonicalTranscriptSignature>();
  @$core.pragma('dart2js:noInline')
  static CanonicalTranscriptSignature getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CanonicalTranscriptSignature>(create);
  static CanonicalTranscriptSignature? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get hostDeviceId => $_getN(0);
  @$pb.TagNumber(1)
  set hostDeviceId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasHostDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearHostDeviceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get hostPublicKey => $_getN(1);
  @$pb.TagNumber(2)
  set hostPublicKey($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHostPublicKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearHostPublicKey() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get signature => $_getN(2);
  @$pb.TagNumber(3)
  set signature($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSignature() => $_has(2);
  @$pb.TagNumber(3)
  void clearSignature() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get transcriptSha256 => $_getN(3);
  @$pb.TagNumber(4)
  set transcriptSha256($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTranscriptSha256() => $_has(3);
  @$pb.TagNumber(4)
  void clearTranscriptSha256() => $_clearField(4);
}

class SignSessionOfferRequest extends $pb.GeneratedMessage {
  factory SignSessionOfferRequest({
    $core.List<$core.int>? canonicalTranscript,
  }) {
    final result = create();
    if (canonicalTranscript != null)
      result.canonicalTranscript = canonicalTranscript;
    return result;
  }

  SignSessionOfferRequest._();

  factory SignSessionOfferRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SignSessionOfferRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SignSessionOfferRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'canonicalTranscript', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SignSessionOfferRequest clone() =>
      SignSessionOfferRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SignSessionOfferRequest copyWith(
          void Function(SignSessionOfferRequest) updates) =>
      super.copyWith((message) => updates(message as SignSessionOfferRequest))
          as SignSessionOfferRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SignSessionOfferRequest create() => SignSessionOfferRequest._();
  @$core.override
  SignSessionOfferRequest createEmptyInstance() => create();
  static $pb.PbList<SignSessionOfferRequest> createRepeated() =>
      $pb.PbList<SignSessionOfferRequest>();
  @$core.pragma('dart2js:noInline')
  static SignSessionOfferRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SignSessionOfferRequest>(create);
  static SignSessionOfferRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get canonicalTranscript => $_getN(0);
  @$pb.TagNumber(1)
  set canonicalTranscript($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCanonicalTranscript() => $_has(0);
  @$pb.TagNumber(1)
  void clearCanonicalTranscript() => $_clearField(1);
}

class SessionOfferSignature extends $pb.GeneratedMessage {
  factory SessionOfferSignature({
    $core.List<$core.int>? controllerDeviceId,
    $core.List<$core.int>? controllerPublicKey,
    $core.List<$core.int>? signature,
    $core.List<$core.int>? transcriptSha256,
  }) {
    final result = create();
    if (controllerDeviceId != null)
      result.controllerDeviceId = controllerDeviceId;
    if (controllerPublicKey != null)
      result.controllerPublicKey = controllerPublicKey;
    if (signature != null) result.signature = signature;
    if (transcriptSha256 != null) result.transcriptSha256 = transcriptSha256;
    return result;
  }

  SessionOfferSignature._();

  factory SessionOfferSignature.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SessionOfferSignature.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SessionOfferSignature',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'controllerDeviceId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'controllerPublicKey', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'signature', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'transcriptSha256', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionOfferSignature clone() =>
      SessionOfferSignature()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionOfferSignature copyWith(
          void Function(SessionOfferSignature) updates) =>
      super.copyWith((message) => updates(message as SessionOfferSignature))
          as SessionOfferSignature;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SessionOfferSignature create() => SessionOfferSignature._();
  @$core.override
  SessionOfferSignature createEmptyInstance() => create();
  static $pb.PbList<SessionOfferSignature> createRepeated() =>
      $pb.PbList<SessionOfferSignature>();
  @$core.pragma('dart2js:noInline')
  static SessionOfferSignature getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SessionOfferSignature>(create);
  static SessionOfferSignature? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get controllerDeviceId => $_getN(0);
  @$pb.TagNumber(1)
  set controllerDeviceId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasControllerDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearControllerDeviceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controllerPublicKey => $_getN(1);
  @$pb.TagNumber(2)
  set controllerPublicKey($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasControllerPublicKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearControllerPublicKey() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get signature => $_getN(2);
  @$pb.TagNumber(3)
  set signature($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSignature() => $_has(2);
  @$pb.TagNumber(3)
  void clearSignature() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get transcriptSha256 => $_getN(3);
  @$pb.TagNumber(4)
  set transcriptSha256($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTranscriptSha256() => $_has(3);
  @$pb.TagNumber(4)
  void clearTranscriptSha256() => $_clearField(4);
}

class GetRemoteSessionStatusRequest extends $pb.GeneratedMessage {
  factory GetRemoteSessionStatusRequest() => create();

  GetRemoteSessionStatusRequest._();

  factory GetRemoteSessionStatusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetRemoteSessionStatusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetRemoteSessionStatusRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRemoteSessionStatusRequest clone() =>
      GetRemoteSessionStatusRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRemoteSessionStatusRequest copyWith(
          void Function(GetRemoteSessionStatusRequest) updates) =>
      super.copyWith(
              (message) => updates(message as GetRemoteSessionStatusRequest))
          as GetRemoteSessionStatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetRemoteSessionStatusRequest create() =>
      GetRemoteSessionStatusRequest._();
  @$core.override
  GetRemoteSessionStatusRequest createEmptyInstance() => create();
  static $pb.PbList<GetRemoteSessionStatusRequest> createRepeated() =>
      $pb.PbList<GetRemoteSessionStatusRequest>();
  @$core.pragma('dart2js:noInline')
  static GetRemoteSessionStatusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetRemoteSessionStatusRequest>(create);
  static GetRemoteSessionStatusRequest? _defaultInstance;
}

class RemoteSessionStatusSnapshot extends $pb.GeneratedMessage {
  factory RemoteSessionStatusSnapshot({
    $3.SessionStatus? sessionStatus,
    $core.List<$core.int>? controllerDeviceId,
  }) {
    final result = create();
    if (sessionStatus != null) result.sessionStatus = sessionStatus;
    if (controllerDeviceId != null)
      result.controllerDeviceId = controllerDeviceId;
    return result;
  }

  RemoteSessionStatusSnapshot._();

  factory RemoteSessionStatusSnapshot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RemoteSessionStatusSnapshot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteSessionStatusSnapshot',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..aOM<$3.SessionStatus>(1, _omitFieldNames ? '' : 'sessionStatus',
        subBuilder: $3.SessionStatus.create)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'controllerDeviceId', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteSessionStatusSnapshot clone() =>
      RemoteSessionStatusSnapshot()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteSessionStatusSnapshot copyWith(
          void Function(RemoteSessionStatusSnapshot) updates) =>
      super.copyWith(
              (message) => updates(message as RemoteSessionStatusSnapshot))
          as RemoteSessionStatusSnapshot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RemoteSessionStatusSnapshot create() =>
      RemoteSessionStatusSnapshot._();
  @$core.override
  RemoteSessionStatusSnapshot createEmptyInstance() => create();
  static $pb.PbList<RemoteSessionStatusSnapshot> createRepeated() =>
      $pb.PbList<RemoteSessionStatusSnapshot>();
  @$core.pragma('dart2js:noInline')
  static RemoteSessionStatusSnapshot getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoteSessionStatusSnapshot>(create);
  static RemoteSessionStatusSnapshot? _defaultInstance;

  @$pb.TagNumber(1)
  $3.SessionStatus get sessionStatus => $_getN(0);
  @$pb.TagNumber(1)
  set sessionStatus($3.SessionStatus value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionStatus() => $_clearField(1);
  @$pb.TagNumber(1)
  $3.SessionStatus ensureSessionStatus() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controllerDeviceId => $_getN(1);
  @$pb.TagNumber(2)
  set controllerDeviceId($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasControllerDeviceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearControllerDeviceId() => $_clearField(2);
}

class StartHostQrPairingRequest extends $pb.GeneratedMessage {
  factory StartHostQrPairingRequest({
    $core.String? signalingEndpoint,
  }) {
    final result = create();
    if (signalingEndpoint != null) result.signalingEndpoint = signalingEndpoint;
    return result;
  }

  StartHostQrPairingRequest._();

  factory StartHostQrPairingRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StartHostQrPairingRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartHostQrPairingRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'signalingEndpoint')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartHostQrPairingRequest clone() =>
      StartHostQrPairingRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartHostQrPairingRequest copyWith(
          void Function(StartHostQrPairingRequest) updates) =>
      super.copyWith((message) => updates(message as StartHostQrPairingRequest))
          as StartHostQrPairingRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartHostQrPairingRequest create() => StartHostQrPairingRequest._();
  @$core.override
  StartHostQrPairingRequest createEmptyInstance() => create();
  static $pb.PbList<StartHostQrPairingRequest> createRepeated() =>
      $pb.PbList<StartHostQrPairingRequest>();
  @$core.pragma('dart2js:noInline')
  static StartHostQrPairingRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartHostQrPairingRequest>(create);
  static StartHostQrPairingRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get signalingEndpoint => $_getSZ(0);
  @$pb.TagNumber(1)
  set signalingEndpoint($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSignalingEndpoint() => $_has(0);
  @$pb.TagNumber(1)
  void clearSignalingEndpoint() => $_clearField(1);
}

class StartHostDesktopCodePairingRequest extends $pb.GeneratedMessage {
  factory StartHostDesktopCodePairingRequest({
    $core.String? signalingEndpoint,
  }) {
    final result = create();
    if (signalingEndpoint != null) result.signalingEndpoint = signalingEndpoint;
    return result;
  }

  StartHostDesktopCodePairingRequest._();

  factory StartHostDesktopCodePairingRequest.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StartHostDesktopCodePairingRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartHostDesktopCodePairingRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'signalingEndpoint')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartHostDesktopCodePairingRequest clone() =>
      StartHostDesktopCodePairingRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartHostDesktopCodePairingRequest copyWith(
          void Function(StartHostDesktopCodePairingRequest) updates) =>
      super.copyWith((message) =>
              updates(message as StartHostDesktopCodePairingRequest))
          as StartHostDesktopCodePairingRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartHostDesktopCodePairingRequest create() =>
      StartHostDesktopCodePairingRequest._();
  @$core.override
  StartHostDesktopCodePairingRequest createEmptyInstance() => create();
  static $pb.PbList<StartHostDesktopCodePairingRequest> createRepeated() =>
      $pb.PbList<StartHostDesktopCodePairingRequest>();
  @$core.pragma('dart2js:noInline')
  static StartHostDesktopCodePairingRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartHostDesktopCodePairingRequest>(
          create);
  static StartHostDesktopCodePairingRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get signalingEndpoint => $_getSZ(0);
  @$pb.TagNumber(1)
  set signalingEndpoint($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSignalingEndpoint() => $_has(0);
  @$pb.TagNumber(1)
  void clearSignalingEndpoint() => $_clearField(1);
}

class CancelHostPairingRequest extends $pb.GeneratedMessage {
  factory CancelHostPairingRequest({
    $core.List<$core.int>? rendezvousId,
  }) {
    final result = create();
    if (rendezvousId != null) result.rendezvousId = rendezvousId;
    return result;
  }

  CancelHostPairingRequest._();

  factory CancelHostPairingRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CancelHostPairingRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CancelHostPairingRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'rendezvousId', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelHostPairingRequest clone() =>
      CancelHostPairingRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelHostPairingRequest copyWith(
          void Function(CancelHostPairingRequest) updates) =>
      super.copyWith((message) => updates(message as CancelHostPairingRequest))
          as CancelHostPairingRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CancelHostPairingRequest create() => CancelHostPairingRequest._();
  @$core.override
  CancelHostPairingRequest createEmptyInstance() => create();
  static $pb.PbList<CancelHostPairingRequest> createRepeated() =>
      $pb.PbList<CancelHostPairingRequest>();
  @$core.pragma('dart2js:noInline')
  static CancelHostPairingRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CancelHostPairingRequest>(create);
  static CancelHostPairingRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get rendezvousId => $_getN(0);
  @$pb.TagNumber(1)
  set rendezvousId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRendezvousId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRendezvousId() => $_clearField(1);
}

class GetHostPairingStatusRequest extends $pb.GeneratedMessage {
  factory GetHostPairingStatusRequest() => create();

  GetHostPairingStatusRequest._();

  factory GetHostPairingStatusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetHostPairingStatusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetHostPairingStatusRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetHostPairingStatusRequest clone() =>
      GetHostPairingStatusRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetHostPairingStatusRequest copyWith(
          void Function(GetHostPairingStatusRequest) updates) =>
      super.copyWith(
              (message) => updates(message as GetHostPairingStatusRequest))
          as GetHostPairingStatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetHostPairingStatusRequest create() =>
      GetHostPairingStatusRequest._();
  @$core.override
  GetHostPairingStatusRequest createEmptyInstance() => create();
  static $pb.PbList<GetHostPairingStatusRequest> createRepeated() =>
      $pb.PbList<GetHostPairingStatusRequest>();
  @$core.pragma('dart2js:noInline')
  static GetHostPairingStatusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetHostPairingStatusRequest>(create);
  static GetHostPairingStatusRequest? _defaultInstance;
}

class AcceptHostPairingRequest extends $pb.GeneratedMessage {
  factory AcceptHostPairingRequest({
    $core.List<$core.int>? rendezvousId,
    $core.List<$core.int>? controllerDeviceId,
  }) {
    final result = create();
    if (rendezvousId != null) result.rendezvousId = rendezvousId;
    if (controllerDeviceId != null)
      result.controllerDeviceId = controllerDeviceId;
    return result;
  }

  AcceptHostPairingRequest._();

  factory AcceptHostPairingRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AcceptHostPairingRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AcceptHostPairingRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'rendezvousId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'controllerDeviceId', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcceptHostPairingRequest clone() =>
      AcceptHostPairingRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcceptHostPairingRequest copyWith(
          void Function(AcceptHostPairingRequest) updates) =>
      super.copyWith((message) => updates(message as AcceptHostPairingRequest))
          as AcceptHostPairingRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AcceptHostPairingRequest create() => AcceptHostPairingRequest._();
  @$core.override
  AcceptHostPairingRequest createEmptyInstance() => create();
  static $pb.PbList<AcceptHostPairingRequest> createRepeated() =>
      $pb.PbList<AcceptHostPairingRequest>();
  @$core.pragma('dart2js:noInline')
  static AcceptHostPairingRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AcceptHostPairingRequest>(create);
  static AcceptHostPairingRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get rendezvousId => $_getN(0);
  @$pb.TagNumber(1)
  set rendezvousId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRendezvousId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRendezvousId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controllerDeviceId => $_getN(1);
  @$pb.TagNumber(2)
  set controllerDeviceId($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasControllerDeviceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearControllerDeviceId() => $_clearField(2);
}

class RejectHostPairingRequest extends $pb.GeneratedMessage {
  factory RejectHostPairingRequest({
    $core.List<$core.int>? rendezvousId,
    $core.List<$core.int>? controllerDeviceId,
  }) {
    final result = create();
    if (rendezvousId != null) result.rendezvousId = rendezvousId;
    if (controllerDeviceId != null)
      result.controllerDeviceId = controllerDeviceId;
    return result;
  }

  RejectHostPairingRequest._();

  factory RejectHostPairingRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RejectHostPairingRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RejectHostPairingRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'rendezvousId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'controllerDeviceId', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RejectHostPairingRequest clone() =>
      RejectHostPairingRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RejectHostPairingRequest copyWith(
          void Function(RejectHostPairingRequest) updates) =>
      super.copyWith((message) => updates(message as RejectHostPairingRequest))
          as RejectHostPairingRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RejectHostPairingRequest create() => RejectHostPairingRequest._();
  @$core.override
  RejectHostPairingRequest createEmptyInstance() => create();
  static $pb.PbList<RejectHostPairingRequest> createRepeated() =>
      $pb.PbList<RejectHostPairingRequest>();
  @$core.pragma('dart2js:noInline')
  static RejectHostPairingRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RejectHostPairingRequest>(create);
  static RejectHostPairingRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get rendezvousId => $_getN(0);
  @$pb.TagNumber(1)
  set rendezvousId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRendezvousId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRendezvousId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controllerDeviceId => $_getN(1);
  @$pb.TagNumber(2)
  set controllerDeviceId($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasControllerDeviceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearControllerDeviceId() => $_clearField(2);
}

class SignPairingTranscriptRequest extends $pb.GeneratedMessage {
  factory SignPairingTranscriptRequest({
    $core.List<$core.int>? canonicalTranscript,
    $4.PairingIdentityRole? role,
  }) {
    final result = create();
    if (canonicalTranscript != null)
      result.canonicalTranscript = canonicalTranscript;
    if (role != null) result.role = role;
    return result;
  }

  SignPairingTranscriptRequest._();

  factory SignPairingTranscriptRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SignPairingTranscriptRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SignPairingTranscriptRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'canonicalTranscript', $pb.PbFieldType.OY)
    ..e<$4.PairingIdentityRole>(
        2, _omitFieldNames ? '' : 'role', $pb.PbFieldType.OE,
        defaultOrMaker:
            $4.PairingIdentityRole.PAIRING_IDENTITY_ROLE_UNSPECIFIED,
        valueOf: $4.PairingIdentityRole.valueOf,
        enumValues: $4.PairingIdentityRole.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SignPairingTranscriptRequest clone() =>
      SignPairingTranscriptRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SignPairingTranscriptRequest copyWith(
          void Function(SignPairingTranscriptRequest) updates) =>
      super.copyWith(
              (message) => updates(message as SignPairingTranscriptRequest))
          as SignPairingTranscriptRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SignPairingTranscriptRequest create() =>
      SignPairingTranscriptRequest._();
  @$core.override
  SignPairingTranscriptRequest createEmptyInstance() => create();
  static $pb.PbList<SignPairingTranscriptRequest> createRepeated() =>
      $pb.PbList<SignPairingTranscriptRequest>();
  @$core.pragma('dart2js:noInline')
  static SignPairingTranscriptRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SignPairingTranscriptRequest>(create);
  static SignPairingTranscriptRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get canonicalTranscript => $_getN(0);
  @$pb.TagNumber(1)
  set canonicalTranscript($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCanonicalTranscript() => $_has(0);
  @$pb.TagNumber(1)
  void clearCanonicalTranscript() => $_clearField(1);

  @$pb.TagNumber(2)
  $4.PairingIdentityRole get role => $_getN(1);
  @$pb.TagNumber(2)
  set role($4.PairingIdentityRole value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasRole() => $_has(1);
  @$pb.TagNumber(2)
  void clearRole() => $_clearField(2);
}

class PairingTranscriptSignature extends $pb.GeneratedMessage {
  factory PairingTranscriptSignature({
    $4.PairingIdentityRole? role,
    $core.List<$core.int>? signerDeviceId,
    $core.List<$core.int>? signerPublicKey,
    $core.List<$core.int>? signature,
    $core.List<$core.int>? transcriptSha256,
  }) {
    final result = create();
    if (role != null) result.role = role;
    if (signerDeviceId != null) result.signerDeviceId = signerDeviceId;
    if (signerPublicKey != null) result.signerPublicKey = signerPublicKey;
    if (signature != null) result.signature = signature;
    if (transcriptSha256 != null) result.transcriptSha256 = transcriptSha256;
    return result;
  }

  PairingTranscriptSignature._();

  factory PairingTranscriptSignature.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PairingTranscriptSignature.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PairingTranscriptSignature',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..e<$4.PairingIdentityRole>(
        1, _omitFieldNames ? '' : 'role', $pb.PbFieldType.OE,
        defaultOrMaker:
            $4.PairingIdentityRole.PAIRING_IDENTITY_ROLE_UNSPECIFIED,
        valueOf: $4.PairingIdentityRole.valueOf,
        enumValues: $4.PairingIdentityRole.values)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'signerDeviceId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'signerPublicKey', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'signature', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'transcriptSha256', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingTranscriptSignature clone() =>
      PairingTranscriptSignature()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingTranscriptSignature copyWith(
          void Function(PairingTranscriptSignature) updates) =>
      super.copyWith(
              (message) => updates(message as PairingTranscriptSignature))
          as PairingTranscriptSignature;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PairingTranscriptSignature create() => PairingTranscriptSignature._();
  @$core.override
  PairingTranscriptSignature createEmptyInstance() => create();
  static $pb.PbList<PairingTranscriptSignature> createRepeated() =>
      $pb.PbList<PairingTranscriptSignature>();
  @$core.pragma('dart2js:noInline')
  static PairingTranscriptSignature getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PairingTranscriptSignature>(create);
  static PairingTranscriptSignature? _defaultInstance;

  @$pb.TagNumber(1)
  $4.PairingIdentityRole get role => $_getN(0);
  @$pb.TagNumber(1)
  set role($4.PairingIdentityRole value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRole() => $_has(0);
  @$pb.TagNumber(1)
  void clearRole() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get signerDeviceId => $_getN(1);
  @$pb.TagNumber(2)
  set signerDeviceId($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSignerDeviceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSignerDeviceId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get signerPublicKey => $_getN(2);
  @$pb.TagNumber(3)
  set signerPublicKey($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSignerPublicKey() => $_has(2);
  @$pb.TagNumber(3)
  void clearSignerPublicKey() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get signature => $_getN(3);
  @$pb.TagNumber(4)
  set signature($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSignature() => $_has(3);
  @$pb.TagNumber(4)
  void clearSignature() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.int> get transcriptSha256 => $_getN(4);
  @$pb.TagNumber(5)
  set transcriptSha256($core.List<$core.int> value) => $_setBytes(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTranscriptSha256() => $_has(4);
  @$pb.TagNumber(5)
  void clearTranscriptSha256() => $_clearField(5);
}

class HostPairingStateChangedEvent extends $pb.GeneratedMessage {
  factory HostPairingStateChangedEvent({
    $4.HostPairingStatusSnapshot? status,
  }) {
    final result = create();
    if (status != null) result.status = status;
    return result;
  }

  HostPairingStateChangedEvent._();

  factory HostPairingStateChangedEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HostPairingStateChangedEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HostPairingStateChangedEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..aOM<$4.HostPairingStatusSnapshot>(1, _omitFieldNames ? '' : 'status',
        subBuilder: $4.HostPairingStatusSnapshot.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HostPairingStateChangedEvent clone() =>
      HostPairingStateChangedEvent()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HostPairingStateChangedEvent copyWith(
          void Function(HostPairingStateChangedEvent) updates) =>
      super.copyWith(
              (message) => updates(message as HostPairingStateChangedEvent))
          as HostPairingStateChangedEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HostPairingStateChangedEvent create() =>
      HostPairingStateChangedEvent._();
  @$core.override
  HostPairingStateChangedEvent createEmptyInstance() => create();
  static $pb.PbList<HostPairingStateChangedEvent> createRepeated() =>
      $pb.PbList<HostPairingStateChangedEvent>();
  @$core.pragma('dart2js:noInline')
  static HostPairingStateChangedEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HostPairingStateChangedEvent>(create);
  static HostPairingStateChangedEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $4.HostPairingStatusSnapshot get status => $_getN(0);
  @$pb.TagNumber(1)
  set status($4.HostPairingStatusSnapshot value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);
  @$pb.TagNumber(1)
  $4.HostPairingStatusSnapshot ensureStatus() => $_ensure(0);
}

class RevokeControllerGrantRequest extends $pb.GeneratedMessage {
  factory RevokeControllerGrantRequest({
    $core.List<$core.int>? grantId,
  }) {
    final result = create();
    if (grantId != null) result.grantId = grantId;
    return result;
  }

  RevokeControllerGrantRequest._();

  factory RevokeControllerGrantRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RevokeControllerGrantRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RevokeControllerGrantRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'grantId', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeControllerGrantRequest clone() =>
      RevokeControllerGrantRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeControllerGrantRequest copyWith(
          void Function(RevokeControllerGrantRequest) updates) =>
      super.copyWith(
              (message) => updates(message as RevokeControllerGrantRequest))
          as RevokeControllerGrantRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RevokeControllerGrantRequest create() =>
      RevokeControllerGrantRequest._();
  @$core.override
  RevokeControllerGrantRequest createEmptyInstance() => create();
  static $pb.PbList<RevokeControllerGrantRequest> createRepeated() =>
      $pb.PbList<RevokeControllerGrantRequest>();
  @$core.pragma('dart2js:noInline')
  static RevokeControllerGrantRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RevokeControllerGrantRequest>(create);
  static RevokeControllerGrantRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get grantId => $_getN(0);
  @$pb.TagNumber(1)
  set grantId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGrantId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGrantId() => $_clearField(1);
}

class ControllerGrantRevoked extends $pb.GeneratedMessage {
  factory ControllerGrantRevoked({
    $core.List<$core.int>? grantId,
    $core.int? terminatedSessionCount,
  }) {
    final result = create();
    if (grantId != null) result.grantId = grantId;
    if (terminatedSessionCount != null)
      result.terminatedSessionCount = terminatedSessionCount;
    return result;
  }

  ControllerGrantRevoked._();

  factory ControllerGrantRevoked.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ControllerGrantRevoked.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ControllerGrantRevoked',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'grantId', $pb.PbFieldType.OY)
    ..a<$core.int>(
        2, _omitFieldNames ? '' : 'terminatedSessionCount', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControllerGrantRevoked clone() =>
      ControllerGrantRevoked()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControllerGrantRevoked copyWith(
          void Function(ControllerGrantRevoked) updates) =>
      super.copyWith((message) => updates(message as ControllerGrantRevoked))
          as ControllerGrantRevoked;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ControllerGrantRevoked create() => ControllerGrantRevoked._();
  @$core.override
  ControllerGrantRevoked createEmptyInstance() => create();
  static $pb.PbList<ControllerGrantRevoked> createRepeated() =>
      $pb.PbList<ControllerGrantRevoked>();
  @$core.pragma('dart2js:noInline')
  static ControllerGrantRevoked getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ControllerGrantRevoked>(create);
  static ControllerGrantRevoked? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get grantId => $_getN(0);
  @$pb.TagNumber(1)
  set grantId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGrantId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGrantId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get terminatedSessionCount => $_getIZ(1);
  @$pb.TagNumber(2)
  set terminatedSessionCount($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTerminatedSessionCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearTerminatedSessionCount() => $_clearField(2);
}

class SessionTerminatedEvent extends $pb.GeneratedMessage {
  factory SessionTerminatedEvent({
    $core.List<$core.int>? sessionId,
    $core.List<$core.int>? controllerDeviceId,
    $6.ErrorCode? reason,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (controllerDeviceId != null)
      result.controllerDeviceId = controllerDeviceId;
    if (reason != null) result.reason = reason;
    return result;
  }

  SessionTerminatedEvent._();

  factory SessionTerminatedEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SessionTerminatedEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SessionTerminatedEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'sessionId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'controllerDeviceId', $pb.PbFieldType.OY)
    ..e<$6.ErrorCode>(3, _omitFieldNames ? '' : 'reason', $pb.PbFieldType.OE,
        defaultOrMaker: $6.ErrorCode.ERROR_CODE_UNSPECIFIED,
        valueOf: $6.ErrorCode.valueOf,
        enumValues: $6.ErrorCode.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionTerminatedEvent clone() =>
      SessionTerminatedEvent()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionTerminatedEvent copyWith(
          void Function(SessionTerminatedEvent) updates) =>
      super.copyWith((message) => updates(message as SessionTerminatedEvent))
          as SessionTerminatedEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SessionTerminatedEvent create() => SessionTerminatedEvent._();
  @$core.override
  SessionTerminatedEvent createEmptyInstance() => create();
  static $pb.PbList<SessionTerminatedEvent> createRepeated() =>
      $pb.PbList<SessionTerminatedEvent>();
  @$core.pragma('dart2js:noInline')
  static SessionTerminatedEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SessionTerminatedEvent>(create);
  static SessionTerminatedEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get sessionId => $_getN(0);
  @$pb.TagNumber(1)
  set sessionId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controllerDeviceId => $_getN(1);
  @$pb.TagNumber(2)
  set controllerDeviceId($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasControllerDeviceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearControllerDeviceId() => $_clearField(2);

  @$pb.TagNumber(3)
  $6.ErrorCode get reason => $_getN(2);
  @$pb.TagNumber(3)
  set reason($6.ErrorCode value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasReason() => $_has(2);
  @$pb.TagNumber(3)
  void clearReason() => $_clearField(3);
}

class HostAuthorizationSnapshot extends $pb.GeneratedMessage {
  factory HostAuthorizationSnapshot({
    $core.List<$core.int>? hostDeviceId,
    $core.Iterable<ControllerGrantView>? grants,
  }) {
    final result = create();
    if (hostDeviceId != null) result.hostDeviceId = hostDeviceId;
    if (grants != null) result.grants.addAll(grants);
    return result;
  }

  HostAuthorizationSnapshot._();

  factory HostAuthorizationSnapshot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HostAuthorizationSnapshot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HostAuthorizationSnapshot',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'hostDeviceId', $pb.PbFieldType.OY)
    ..pc<ControllerGrantView>(
        2, _omitFieldNames ? '' : 'grants', $pb.PbFieldType.PM,
        subBuilder: ControllerGrantView.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HostAuthorizationSnapshot clone() =>
      HostAuthorizationSnapshot()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HostAuthorizationSnapshot copyWith(
          void Function(HostAuthorizationSnapshot) updates) =>
      super.copyWith((message) => updates(message as HostAuthorizationSnapshot))
          as HostAuthorizationSnapshot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HostAuthorizationSnapshot create() => HostAuthorizationSnapshot._();
  @$core.override
  HostAuthorizationSnapshot createEmptyInstance() => create();
  static $pb.PbList<HostAuthorizationSnapshot> createRepeated() =>
      $pb.PbList<HostAuthorizationSnapshot>();
  @$core.pragma('dart2js:noInline')
  static HostAuthorizationSnapshot getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HostAuthorizationSnapshot>(create);
  static HostAuthorizationSnapshot? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get hostDeviceId => $_getN(0);
  @$pb.TagNumber(1)
  set hostDeviceId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasHostDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearHostDeviceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<ControllerGrantView> get grants => $_getList(1);
}

class EmergencyStopRemoteSessionRequest extends $pb.GeneratedMessage {
  factory EmergencyStopRemoteSessionRequest() => create();

  EmergencyStopRemoteSessionRequest._();

  factory EmergencyStopRemoteSessionRequest.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EmergencyStopRemoteSessionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EmergencyStopRemoteSessionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EmergencyStopRemoteSessionRequest clone() =>
      EmergencyStopRemoteSessionRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EmergencyStopRemoteSessionRequest copyWith(
          void Function(EmergencyStopRemoteSessionRequest) updates) =>
      super.copyWith((message) =>
              updates(message as EmergencyStopRemoteSessionRequest))
          as EmergencyStopRemoteSessionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EmergencyStopRemoteSessionRequest create() =>
      EmergencyStopRemoteSessionRequest._();
  @$core.override
  EmergencyStopRemoteSessionRequest createEmptyInstance() => create();
  static $pb.PbList<EmergencyStopRemoteSessionRequest> createRepeated() =>
      $pb.PbList<EmergencyStopRemoteSessionRequest>();
  @$core.pragma('dart2js:noInline')
  static EmergencyStopRemoteSessionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EmergencyStopRemoteSessionRequest>(
          create);
  static EmergencyStopRemoteSessionRequest? _defaultInstance;
}

class EmergencyStopRemoteSessionResult extends $pb.GeneratedMessage {
  factory EmergencyStopRemoteSessionResult({
    $core.int? terminatedSessionCount,
  }) {
    final result = create();
    if (terminatedSessionCount != null)
      result.terminatedSessionCount = terminatedSessionCount;
    return result;
  }

  EmergencyStopRemoteSessionResult._();

  factory EmergencyStopRemoteSessionResult.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EmergencyStopRemoteSessionResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EmergencyStopRemoteSessionResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.int>(
        1, _omitFieldNames ? '' : 'terminatedSessionCount', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EmergencyStopRemoteSessionResult clone() =>
      EmergencyStopRemoteSessionResult()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EmergencyStopRemoteSessionResult copyWith(
          void Function(EmergencyStopRemoteSessionResult) updates) =>
      super.copyWith(
              (message) => updates(message as EmergencyStopRemoteSessionResult))
          as EmergencyStopRemoteSessionResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EmergencyStopRemoteSessionResult create() =>
      EmergencyStopRemoteSessionResult._();
  @$core.override
  EmergencyStopRemoteSessionResult createEmptyInstance() => create();
  static $pb.PbList<EmergencyStopRemoteSessionResult> createRepeated() =>
      $pb.PbList<EmergencyStopRemoteSessionResult>();
  @$core.pragma('dart2js:noInline')
  static EmergencyStopRemoteSessionResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EmergencyStopRemoteSessionResult>(
          create);
  static EmergencyStopRemoteSessionResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get terminatedSessionCount => $_getIZ(0);
  @$pb.TagNumber(1)
  set terminatedSessionCount($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTerminatedSessionCount() => $_has(0);
  @$pb.TagNumber(1)
  void clearTerminatedSessionCount() => $_clearField(1);
}

enum LocalIpcClientFrame_Payload {
  authenticate,
  getHostStatus,
  listControllerGrants,
  createControllerGrant,
  signCanonicalTranscript,
  revokeControllerGrant,
  signSessionOffer,
  getRemoteSessionStatus,
  startHostQrPairing,
  startHostDesktopCodePairing,
  cancelHostPairing,
  getHostPairingStatus,
  acceptHostPairing,
  rejectHostPairing,
  signPairingTranscript,
  emergencyStopRemoteSession,
  notSet
}

class LocalIpcClientFrame extends $pb.GeneratedMessage {
  factory LocalIpcClientFrame({
    $5.ProtocolVersion? protocolVersion,
    $core.String? requestId,
    LocalIpcAuthenticate? authenticate,
    GetHostStatusRequest? getHostStatus,
    ListControllerGrantsRequest? listControllerGrants,
    CreateControllerGrantRequest? createControllerGrant,
    SignCanonicalTranscriptRequest? signCanonicalTranscript,
    RevokeControllerGrantRequest? revokeControllerGrant,
    SignSessionOfferRequest? signSessionOffer,
    GetRemoteSessionStatusRequest? getRemoteSessionStatus,
    StartHostQrPairingRequest? startHostQrPairing,
    StartHostDesktopCodePairingRequest? startHostDesktopCodePairing,
    CancelHostPairingRequest? cancelHostPairing,
    GetHostPairingStatusRequest? getHostPairingStatus,
    AcceptHostPairingRequest? acceptHostPairing,
    RejectHostPairingRequest? rejectHostPairing,
    SignPairingTranscriptRequest? signPairingTranscript,
    EmergencyStopRemoteSessionRequest? emergencyStopRemoteSession,
  }) {
    final result = create();
    if (protocolVersion != null) result.protocolVersion = protocolVersion;
    if (requestId != null) result.requestId = requestId;
    if (authenticate != null) result.authenticate = authenticate;
    if (getHostStatus != null) result.getHostStatus = getHostStatus;
    if (listControllerGrants != null)
      result.listControllerGrants = listControllerGrants;
    if (createControllerGrant != null)
      result.createControllerGrant = createControllerGrant;
    if (signCanonicalTranscript != null)
      result.signCanonicalTranscript = signCanonicalTranscript;
    if (revokeControllerGrant != null)
      result.revokeControllerGrant = revokeControllerGrant;
    if (signSessionOffer != null) result.signSessionOffer = signSessionOffer;
    if (getRemoteSessionStatus != null)
      result.getRemoteSessionStatus = getRemoteSessionStatus;
    if (startHostQrPairing != null)
      result.startHostQrPairing = startHostQrPairing;
    if (startHostDesktopCodePairing != null)
      result.startHostDesktopCodePairing = startHostDesktopCodePairing;
    if (cancelHostPairing != null) result.cancelHostPairing = cancelHostPairing;
    if (getHostPairingStatus != null)
      result.getHostPairingStatus = getHostPairingStatus;
    if (acceptHostPairing != null) result.acceptHostPairing = acceptHostPairing;
    if (rejectHostPairing != null) result.rejectHostPairing = rejectHostPairing;
    if (signPairingTranscript != null)
      result.signPairingTranscript = signPairingTranscript;
    if (emergencyStopRemoteSession != null)
      result.emergencyStopRemoteSession = emergencyStopRemoteSession;
    return result;
  }

  LocalIpcClientFrame._();

  factory LocalIpcClientFrame.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LocalIpcClientFrame.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, LocalIpcClientFrame_Payload>
      _LocalIpcClientFrame_PayloadByTag = {
    10: LocalIpcClientFrame_Payload.authenticate,
    11: LocalIpcClientFrame_Payload.getHostStatus,
    12: LocalIpcClientFrame_Payload.listControllerGrants,
    13: LocalIpcClientFrame_Payload.createControllerGrant,
    14: LocalIpcClientFrame_Payload.signCanonicalTranscript,
    15: LocalIpcClientFrame_Payload.revokeControllerGrant,
    16: LocalIpcClientFrame_Payload.signSessionOffer,
    17: LocalIpcClientFrame_Payload.getRemoteSessionStatus,
    18: LocalIpcClientFrame_Payload.startHostQrPairing,
    19: LocalIpcClientFrame_Payload.startHostDesktopCodePairing,
    20: LocalIpcClientFrame_Payload.cancelHostPairing,
    21: LocalIpcClientFrame_Payload.getHostPairingStatus,
    22: LocalIpcClientFrame_Payload.acceptHostPairing,
    23: LocalIpcClientFrame_Payload.rejectHostPairing,
    24: LocalIpcClientFrame_Payload.signPairingTranscript,
    25: LocalIpcClientFrame_Payload.emergencyStopRemoteSession,
    0: LocalIpcClientFrame_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LocalIpcClientFrame',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..oo(0, [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25])
    ..aOM<$5.ProtocolVersion>(1, _omitFieldNames ? '' : 'protocolVersion',
        subBuilder: $5.ProtocolVersion.create)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..aOM<LocalIpcAuthenticate>(10, _omitFieldNames ? '' : 'authenticate',
        subBuilder: LocalIpcAuthenticate.create)
    ..aOM<GetHostStatusRequest>(11, _omitFieldNames ? '' : 'getHostStatus',
        subBuilder: GetHostStatusRequest.create)
    ..aOM<ListControllerGrantsRequest>(
        12, _omitFieldNames ? '' : 'listControllerGrants',
        subBuilder: ListControllerGrantsRequest.create)
    ..aOM<CreateControllerGrantRequest>(
        13, _omitFieldNames ? '' : 'createControllerGrant',
        subBuilder: CreateControllerGrantRequest.create)
    ..aOM<SignCanonicalTranscriptRequest>(
        14, _omitFieldNames ? '' : 'signCanonicalTranscript',
        subBuilder: SignCanonicalTranscriptRequest.create)
    ..aOM<RevokeControllerGrantRequest>(
        15, _omitFieldNames ? '' : 'revokeControllerGrant',
        subBuilder: RevokeControllerGrantRequest.create)
    ..aOM<SignSessionOfferRequest>(
        16, _omitFieldNames ? '' : 'signSessionOffer',
        subBuilder: SignSessionOfferRequest.create)
    ..aOM<GetRemoteSessionStatusRequest>(
        17, _omitFieldNames ? '' : 'getRemoteSessionStatus',
        subBuilder: GetRemoteSessionStatusRequest.create)
    ..aOM<StartHostQrPairingRequest>(
        18, _omitFieldNames ? '' : 'startHostQrPairing',
        subBuilder: StartHostQrPairingRequest.create)
    ..aOM<StartHostDesktopCodePairingRequest>(
        19, _omitFieldNames ? '' : 'startHostDesktopCodePairing',
        subBuilder: StartHostDesktopCodePairingRequest.create)
    ..aOM<CancelHostPairingRequest>(
        20, _omitFieldNames ? '' : 'cancelHostPairing',
        subBuilder: CancelHostPairingRequest.create)
    ..aOM<GetHostPairingStatusRequest>(
        21, _omitFieldNames ? '' : 'getHostPairingStatus',
        subBuilder: GetHostPairingStatusRequest.create)
    ..aOM<AcceptHostPairingRequest>(
        22, _omitFieldNames ? '' : 'acceptHostPairing',
        subBuilder: AcceptHostPairingRequest.create)
    ..aOM<RejectHostPairingRequest>(
        23, _omitFieldNames ? '' : 'rejectHostPairing',
        subBuilder: RejectHostPairingRequest.create)
    ..aOM<SignPairingTranscriptRequest>(
        24, _omitFieldNames ? '' : 'signPairingTranscript',
        subBuilder: SignPairingTranscriptRequest.create)
    ..aOM<EmergencyStopRemoteSessionRequest>(
        25, _omitFieldNames ? '' : 'emergencyStopRemoteSession',
        subBuilder: EmergencyStopRemoteSessionRequest.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocalIpcClientFrame clone() => LocalIpcClientFrame()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocalIpcClientFrame copyWith(void Function(LocalIpcClientFrame) updates) =>
      super.copyWith((message) => updates(message as LocalIpcClientFrame))
          as LocalIpcClientFrame;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LocalIpcClientFrame create() => LocalIpcClientFrame._();
  @$core.override
  LocalIpcClientFrame createEmptyInstance() => create();
  static $pb.PbList<LocalIpcClientFrame> createRepeated() =>
      $pb.PbList<LocalIpcClientFrame>();
  @$core.pragma('dart2js:noInline')
  static LocalIpcClientFrame getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LocalIpcClientFrame>(create);
  static LocalIpcClientFrame? _defaultInstance;

  LocalIpcClientFrame_Payload whichPayload() =>
      _LocalIpcClientFrame_PayloadByTag[$_whichOneof(0)]!;
  void clearPayload() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $5.ProtocolVersion get protocolVersion => $_getN(0);
  @$pb.TagNumber(1)
  set protocolVersion($5.ProtocolVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProtocolVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearProtocolVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  $5.ProtocolVersion ensureProtocolVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get requestId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRequestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestId() => $_clearField(2);

  @$pb.TagNumber(10)
  LocalIpcAuthenticate get authenticate => $_getN(2);
  @$pb.TagNumber(10)
  set authenticate(LocalIpcAuthenticate value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasAuthenticate() => $_has(2);
  @$pb.TagNumber(10)
  void clearAuthenticate() => $_clearField(10);
  @$pb.TagNumber(10)
  LocalIpcAuthenticate ensureAuthenticate() => $_ensure(2);

  @$pb.TagNumber(11)
  GetHostStatusRequest get getHostStatus => $_getN(3);
  @$pb.TagNumber(11)
  set getHostStatus(GetHostStatusRequest value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasGetHostStatus() => $_has(3);
  @$pb.TagNumber(11)
  void clearGetHostStatus() => $_clearField(11);
  @$pb.TagNumber(11)
  GetHostStatusRequest ensureGetHostStatus() => $_ensure(3);

  @$pb.TagNumber(12)
  ListControllerGrantsRequest get listControllerGrants => $_getN(4);
  @$pb.TagNumber(12)
  set listControllerGrants(ListControllerGrantsRequest value) =>
      $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasListControllerGrants() => $_has(4);
  @$pb.TagNumber(12)
  void clearListControllerGrants() => $_clearField(12);
  @$pb.TagNumber(12)
  ListControllerGrantsRequest ensureListControllerGrants() => $_ensure(4);

  @$pb.TagNumber(13)
  CreateControllerGrantRequest get createControllerGrant => $_getN(5);
  @$pb.TagNumber(13)
  set createControllerGrant(CreateControllerGrantRequest value) =>
      $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasCreateControllerGrant() => $_has(5);
  @$pb.TagNumber(13)
  void clearCreateControllerGrant() => $_clearField(13);
  @$pb.TagNumber(13)
  CreateControllerGrantRequest ensureCreateControllerGrant() => $_ensure(5);

  @$pb.TagNumber(14)
  SignCanonicalTranscriptRequest get signCanonicalTranscript => $_getN(6);
  @$pb.TagNumber(14)
  set signCanonicalTranscript(SignCanonicalTranscriptRequest value) =>
      $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasSignCanonicalTranscript() => $_has(6);
  @$pb.TagNumber(14)
  void clearSignCanonicalTranscript() => $_clearField(14);
  @$pb.TagNumber(14)
  SignCanonicalTranscriptRequest ensureSignCanonicalTranscript() => $_ensure(6);

  @$pb.TagNumber(15)
  RevokeControllerGrantRequest get revokeControllerGrant => $_getN(7);
  @$pb.TagNumber(15)
  set revokeControllerGrant(RevokeControllerGrantRequest value) =>
      $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasRevokeControllerGrant() => $_has(7);
  @$pb.TagNumber(15)
  void clearRevokeControllerGrant() => $_clearField(15);
  @$pb.TagNumber(15)
  RevokeControllerGrantRequest ensureRevokeControllerGrant() => $_ensure(7);

  @$pb.TagNumber(16)
  SignSessionOfferRequest get signSessionOffer => $_getN(8);
  @$pb.TagNumber(16)
  set signSessionOffer(SignSessionOfferRequest value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasSignSessionOffer() => $_has(8);
  @$pb.TagNumber(16)
  void clearSignSessionOffer() => $_clearField(16);
  @$pb.TagNumber(16)
  SignSessionOfferRequest ensureSignSessionOffer() => $_ensure(8);

  @$pb.TagNumber(17)
  GetRemoteSessionStatusRequest get getRemoteSessionStatus => $_getN(9);
  @$pb.TagNumber(17)
  set getRemoteSessionStatus(GetRemoteSessionStatusRequest value) =>
      $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasGetRemoteSessionStatus() => $_has(9);
  @$pb.TagNumber(17)
  void clearGetRemoteSessionStatus() => $_clearField(17);
  @$pb.TagNumber(17)
  GetRemoteSessionStatusRequest ensureGetRemoteSessionStatus() => $_ensure(9);

  @$pb.TagNumber(18)
  StartHostQrPairingRequest get startHostQrPairing => $_getN(10);
  @$pb.TagNumber(18)
  set startHostQrPairing(StartHostQrPairingRequest value) =>
      $_setField(18, value);
  @$pb.TagNumber(18)
  $core.bool hasStartHostQrPairing() => $_has(10);
  @$pb.TagNumber(18)
  void clearStartHostQrPairing() => $_clearField(18);
  @$pb.TagNumber(18)
  StartHostQrPairingRequest ensureStartHostQrPairing() => $_ensure(10);

  @$pb.TagNumber(19)
  StartHostDesktopCodePairingRequest get startHostDesktopCodePairing =>
      $_getN(11);
  @$pb.TagNumber(19)
  set startHostDesktopCodePairing(StartHostDesktopCodePairingRequest value) =>
      $_setField(19, value);
  @$pb.TagNumber(19)
  $core.bool hasStartHostDesktopCodePairing() => $_has(11);
  @$pb.TagNumber(19)
  void clearStartHostDesktopCodePairing() => $_clearField(19);
  @$pb.TagNumber(19)
  StartHostDesktopCodePairingRequest ensureStartHostDesktopCodePairing() =>
      $_ensure(11);

  @$pb.TagNumber(20)
  CancelHostPairingRequest get cancelHostPairing => $_getN(12);
  @$pb.TagNumber(20)
  set cancelHostPairing(CancelHostPairingRequest value) =>
      $_setField(20, value);
  @$pb.TagNumber(20)
  $core.bool hasCancelHostPairing() => $_has(12);
  @$pb.TagNumber(20)
  void clearCancelHostPairing() => $_clearField(20);
  @$pb.TagNumber(20)
  CancelHostPairingRequest ensureCancelHostPairing() => $_ensure(12);

  @$pb.TagNumber(21)
  GetHostPairingStatusRequest get getHostPairingStatus => $_getN(13);
  @$pb.TagNumber(21)
  set getHostPairingStatus(GetHostPairingStatusRequest value) =>
      $_setField(21, value);
  @$pb.TagNumber(21)
  $core.bool hasGetHostPairingStatus() => $_has(13);
  @$pb.TagNumber(21)
  void clearGetHostPairingStatus() => $_clearField(21);
  @$pb.TagNumber(21)
  GetHostPairingStatusRequest ensureGetHostPairingStatus() => $_ensure(13);

  @$pb.TagNumber(22)
  AcceptHostPairingRequest get acceptHostPairing => $_getN(14);
  @$pb.TagNumber(22)
  set acceptHostPairing(AcceptHostPairingRequest value) =>
      $_setField(22, value);
  @$pb.TagNumber(22)
  $core.bool hasAcceptHostPairing() => $_has(14);
  @$pb.TagNumber(22)
  void clearAcceptHostPairing() => $_clearField(22);
  @$pb.TagNumber(22)
  AcceptHostPairingRequest ensureAcceptHostPairing() => $_ensure(14);

  @$pb.TagNumber(23)
  RejectHostPairingRequest get rejectHostPairing => $_getN(15);
  @$pb.TagNumber(23)
  set rejectHostPairing(RejectHostPairingRequest value) =>
      $_setField(23, value);
  @$pb.TagNumber(23)
  $core.bool hasRejectHostPairing() => $_has(15);
  @$pb.TagNumber(23)
  void clearRejectHostPairing() => $_clearField(23);
  @$pb.TagNumber(23)
  RejectHostPairingRequest ensureRejectHostPairing() => $_ensure(15);

  @$pb.TagNumber(24)
  SignPairingTranscriptRequest get signPairingTranscript => $_getN(16);
  @$pb.TagNumber(24)
  set signPairingTranscript(SignPairingTranscriptRequest value) =>
      $_setField(24, value);
  @$pb.TagNumber(24)
  $core.bool hasSignPairingTranscript() => $_has(16);
  @$pb.TagNumber(24)
  void clearSignPairingTranscript() => $_clearField(24);
  @$pb.TagNumber(24)
  SignPairingTranscriptRequest ensureSignPairingTranscript() => $_ensure(16);

  @$pb.TagNumber(25)
  EmergencyStopRemoteSessionRequest get emergencyStopRemoteSession =>
      $_getN(17);
  @$pb.TagNumber(25)
  set emergencyStopRemoteSession(EmergencyStopRemoteSessionRequest value) =>
      $_setField(25, value);
  @$pb.TagNumber(25)
  $core.bool hasEmergencyStopRemoteSession() => $_has(17);
  @$pb.TagNumber(25)
  void clearEmergencyStopRemoteSession() => $_clearField(25);
  @$pb.TagNumber(25)
  EmergencyStopRemoteSessionRequest ensureEmergencyStopRemoteSession() =>
      $_ensure(17);
}

enum LocalIpcServerFrame_Payload {
  challenge,
  authenticated,
  hostStatus,
  controllerGrantList,
  controllerGrantCreated,
  canonicalTranscriptSignature,
  controllerGrantRevoked,
  sessionOfferSignature,
  remoteSessionStatus,
  sessionTerminated,
  error,
  hostPairingStatus,
  pairingTranscriptSignature,
  hostPairingStateChanged,
  emergencyStopRemoteSessionResult,
  notSet
}

class LocalIpcServerFrame extends $pb.GeneratedMessage {
  factory LocalIpcServerFrame({
    $5.ProtocolVersion? protocolVersion,
    $core.String? requestId,
    LocalIpcChallenge? challenge,
    LocalIpcAuthenticated? authenticated,
    HostStatus? hostStatus,
    ControllerGrantList? controllerGrantList,
    ControllerGrantCreated? controllerGrantCreated,
    CanonicalTranscriptSignature? canonicalTranscriptSignature,
    ControllerGrantRevoked? controllerGrantRevoked,
    SessionOfferSignature? sessionOfferSignature,
    RemoteSessionStatusSnapshot? remoteSessionStatus,
    SessionTerminatedEvent? sessionTerminated,
    $6.UnifiedError? error,
    $4.HostPairingStatusSnapshot? hostPairingStatus,
    PairingTranscriptSignature? pairingTranscriptSignature,
    HostPairingStateChangedEvent? hostPairingStateChanged,
    EmergencyStopRemoteSessionResult? emergencyStopRemoteSessionResult,
  }) {
    final result = create();
    if (protocolVersion != null) result.protocolVersion = protocolVersion;
    if (requestId != null) result.requestId = requestId;
    if (challenge != null) result.challenge = challenge;
    if (authenticated != null) result.authenticated = authenticated;
    if (hostStatus != null) result.hostStatus = hostStatus;
    if (controllerGrantList != null)
      result.controllerGrantList = controllerGrantList;
    if (controllerGrantCreated != null)
      result.controllerGrantCreated = controllerGrantCreated;
    if (canonicalTranscriptSignature != null)
      result.canonicalTranscriptSignature = canonicalTranscriptSignature;
    if (controllerGrantRevoked != null)
      result.controllerGrantRevoked = controllerGrantRevoked;
    if (sessionOfferSignature != null)
      result.sessionOfferSignature = sessionOfferSignature;
    if (remoteSessionStatus != null)
      result.remoteSessionStatus = remoteSessionStatus;
    if (sessionTerminated != null) result.sessionTerminated = sessionTerminated;
    if (error != null) result.error = error;
    if (hostPairingStatus != null) result.hostPairingStatus = hostPairingStatus;
    if (pairingTranscriptSignature != null)
      result.pairingTranscriptSignature = pairingTranscriptSignature;
    if (hostPairingStateChanged != null)
      result.hostPairingStateChanged = hostPairingStateChanged;
    if (emergencyStopRemoteSessionResult != null)
      result.emergencyStopRemoteSessionResult =
          emergencyStopRemoteSessionResult;
    return result;
  }

  LocalIpcServerFrame._();

  factory LocalIpcServerFrame.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LocalIpcServerFrame.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, LocalIpcServerFrame_Payload>
      _LocalIpcServerFrame_PayloadByTag = {
    10: LocalIpcServerFrame_Payload.challenge,
    11: LocalIpcServerFrame_Payload.authenticated,
    20: LocalIpcServerFrame_Payload.hostStatus,
    21: LocalIpcServerFrame_Payload.controllerGrantList,
    22: LocalIpcServerFrame_Payload.controllerGrantCreated,
    23: LocalIpcServerFrame_Payload.canonicalTranscriptSignature,
    24: LocalIpcServerFrame_Payload.controllerGrantRevoked,
    25: LocalIpcServerFrame_Payload.sessionOfferSignature,
    26: LocalIpcServerFrame_Payload.remoteSessionStatus,
    28: LocalIpcServerFrame_Payload.sessionTerminated,
    29: LocalIpcServerFrame_Payload.error,
    30: LocalIpcServerFrame_Payload.hostPairingStatus,
    31: LocalIpcServerFrame_Payload.pairingTranscriptSignature,
    32: LocalIpcServerFrame_Payload.hostPairingStateChanged,
    33: LocalIpcServerFrame_Payload.emergencyStopRemoteSessionResult,
    0: LocalIpcServerFrame_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LocalIpcServerFrame',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..oo(0, [10, 11, 20, 21, 22, 23, 24, 25, 26, 28, 29, 30, 31, 32, 33])
    ..aOM<$5.ProtocolVersion>(1, _omitFieldNames ? '' : 'protocolVersion',
        subBuilder: $5.ProtocolVersion.create)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..aOM<LocalIpcChallenge>(10, _omitFieldNames ? '' : 'challenge',
        subBuilder: LocalIpcChallenge.create)
    ..aOM<LocalIpcAuthenticated>(11, _omitFieldNames ? '' : 'authenticated',
        subBuilder: LocalIpcAuthenticated.create)
    ..aOM<HostStatus>(20, _omitFieldNames ? '' : 'hostStatus',
        subBuilder: HostStatus.create)
    ..aOM<ControllerGrantList>(21, _omitFieldNames ? '' : 'controllerGrantList',
        subBuilder: ControllerGrantList.create)
    ..aOM<ControllerGrantCreated>(
        22, _omitFieldNames ? '' : 'controllerGrantCreated',
        subBuilder: ControllerGrantCreated.create)
    ..aOM<CanonicalTranscriptSignature>(
        23, _omitFieldNames ? '' : 'canonicalTranscriptSignature',
        subBuilder: CanonicalTranscriptSignature.create)
    ..aOM<ControllerGrantRevoked>(
        24, _omitFieldNames ? '' : 'controllerGrantRevoked',
        subBuilder: ControllerGrantRevoked.create)
    ..aOM<SessionOfferSignature>(
        25, _omitFieldNames ? '' : 'sessionOfferSignature',
        subBuilder: SessionOfferSignature.create)
    ..aOM<RemoteSessionStatusSnapshot>(
        26, _omitFieldNames ? '' : 'remoteSessionStatus',
        subBuilder: RemoteSessionStatusSnapshot.create)
    ..aOM<SessionTerminatedEvent>(
        28, _omitFieldNames ? '' : 'sessionTerminated',
        subBuilder: SessionTerminatedEvent.create)
    ..aOM<$6.UnifiedError>(29, _omitFieldNames ? '' : 'error',
        subBuilder: $6.UnifiedError.create)
    ..aOM<$4.HostPairingStatusSnapshot>(
        30, _omitFieldNames ? '' : 'hostPairingStatus',
        subBuilder: $4.HostPairingStatusSnapshot.create)
    ..aOM<PairingTranscriptSignature>(
        31, _omitFieldNames ? '' : 'pairingTranscriptSignature',
        subBuilder: PairingTranscriptSignature.create)
    ..aOM<HostPairingStateChangedEvent>(
        32, _omitFieldNames ? '' : 'hostPairingStateChanged',
        subBuilder: HostPairingStateChangedEvent.create)
    ..aOM<EmergencyStopRemoteSessionResult>(
        33, _omitFieldNames ? '' : 'emergencyStopRemoteSessionResult',
        subBuilder: EmergencyStopRemoteSessionResult.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocalIpcServerFrame clone() => LocalIpcServerFrame()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocalIpcServerFrame copyWith(void Function(LocalIpcServerFrame) updates) =>
      super.copyWith((message) => updates(message as LocalIpcServerFrame))
          as LocalIpcServerFrame;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LocalIpcServerFrame create() => LocalIpcServerFrame._();
  @$core.override
  LocalIpcServerFrame createEmptyInstance() => create();
  static $pb.PbList<LocalIpcServerFrame> createRepeated() =>
      $pb.PbList<LocalIpcServerFrame>();
  @$core.pragma('dart2js:noInline')
  static LocalIpcServerFrame getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LocalIpcServerFrame>(create);
  static LocalIpcServerFrame? _defaultInstance;

  LocalIpcServerFrame_Payload whichPayload() =>
      _LocalIpcServerFrame_PayloadByTag[$_whichOneof(0)]!;
  void clearPayload() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $5.ProtocolVersion get protocolVersion => $_getN(0);
  @$pb.TagNumber(1)
  set protocolVersion($5.ProtocolVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProtocolVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearProtocolVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  $5.ProtocolVersion ensureProtocolVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get requestId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRequestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestId() => $_clearField(2);

  @$pb.TagNumber(10)
  LocalIpcChallenge get challenge => $_getN(2);
  @$pb.TagNumber(10)
  set challenge(LocalIpcChallenge value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasChallenge() => $_has(2);
  @$pb.TagNumber(10)
  void clearChallenge() => $_clearField(10);
  @$pb.TagNumber(10)
  LocalIpcChallenge ensureChallenge() => $_ensure(2);

  @$pb.TagNumber(11)
  LocalIpcAuthenticated get authenticated => $_getN(3);
  @$pb.TagNumber(11)
  set authenticated(LocalIpcAuthenticated value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasAuthenticated() => $_has(3);
  @$pb.TagNumber(11)
  void clearAuthenticated() => $_clearField(11);
  @$pb.TagNumber(11)
  LocalIpcAuthenticated ensureAuthenticated() => $_ensure(3);

  @$pb.TagNumber(20)
  HostStatus get hostStatus => $_getN(4);
  @$pb.TagNumber(20)
  set hostStatus(HostStatus value) => $_setField(20, value);
  @$pb.TagNumber(20)
  $core.bool hasHostStatus() => $_has(4);
  @$pb.TagNumber(20)
  void clearHostStatus() => $_clearField(20);
  @$pb.TagNumber(20)
  HostStatus ensureHostStatus() => $_ensure(4);

  @$pb.TagNumber(21)
  ControllerGrantList get controllerGrantList => $_getN(5);
  @$pb.TagNumber(21)
  set controllerGrantList(ControllerGrantList value) => $_setField(21, value);
  @$pb.TagNumber(21)
  $core.bool hasControllerGrantList() => $_has(5);
  @$pb.TagNumber(21)
  void clearControllerGrantList() => $_clearField(21);
  @$pb.TagNumber(21)
  ControllerGrantList ensureControllerGrantList() => $_ensure(5);

  @$pb.TagNumber(22)
  ControllerGrantCreated get controllerGrantCreated => $_getN(6);
  @$pb.TagNumber(22)
  set controllerGrantCreated(ControllerGrantCreated value) =>
      $_setField(22, value);
  @$pb.TagNumber(22)
  $core.bool hasControllerGrantCreated() => $_has(6);
  @$pb.TagNumber(22)
  void clearControllerGrantCreated() => $_clearField(22);
  @$pb.TagNumber(22)
  ControllerGrantCreated ensureControllerGrantCreated() => $_ensure(6);

  @$pb.TagNumber(23)
  CanonicalTranscriptSignature get canonicalTranscriptSignature => $_getN(7);
  @$pb.TagNumber(23)
  set canonicalTranscriptSignature(CanonicalTranscriptSignature value) =>
      $_setField(23, value);
  @$pb.TagNumber(23)
  $core.bool hasCanonicalTranscriptSignature() => $_has(7);
  @$pb.TagNumber(23)
  void clearCanonicalTranscriptSignature() => $_clearField(23);
  @$pb.TagNumber(23)
  CanonicalTranscriptSignature ensureCanonicalTranscriptSignature() =>
      $_ensure(7);

  @$pb.TagNumber(24)
  ControllerGrantRevoked get controllerGrantRevoked => $_getN(8);
  @$pb.TagNumber(24)
  set controllerGrantRevoked(ControllerGrantRevoked value) =>
      $_setField(24, value);
  @$pb.TagNumber(24)
  $core.bool hasControllerGrantRevoked() => $_has(8);
  @$pb.TagNumber(24)
  void clearControllerGrantRevoked() => $_clearField(24);
  @$pb.TagNumber(24)
  ControllerGrantRevoked ensureControllerGrantRevoked() => $_ensure(8);

  @$pb.TagNumber(25)
  SessionOfferSignature get sessionOfferSignature => $_getN(9);
  @$pb.TagNumber(25)
  set sessionOfferSignature(SessionOfferSignature value) =>
      $_setField(25, value);
  @$pb.TagNumber(25)
  $core.bool hasSessionOfferSignature() => $_has(9);
  @$pb.TagNumber(25)
  void clearSessionOfferSignature() => $_clearField(25);
  @$pb.TagNumber(25)
  SessionOfferSignature ensureSessionOfferSignature() => $_ensure(9);

  @$pb.TagNumber(26)
  RemoteSessionStatusSnapshot get remoteSessionStatus => $_getN(10);
  @$pb.TagNumber(26)
  set remoteSessionStatus(RemoteSessionStatusSnapshot value) =>
      $_setField(26, value);
  @$pb.TagNumber(26)
  $core.bool hasRemoteSessionStatus() => $_has(10);
  @$pb.TagNumber(26)
  void clearRemoteSessionStatus() => $_clearField(26);
  @$pb.TagNumber(26)
  RemoteSessionStatusSnapshot ensureRemoteSessionStatus() => $_ensure(10);

  @$pb.TagNumber(28)
  SessionTerminatedEvent get sessionTerminated => $_getN(11);
  @$pb.TagNumber(28)
  set sessionTerminated(SessionTerminatedEvent value) => $_setField(28, value);
  @$pb.TagNumber(28)
  $core.bool hasSessionTerminated() => $_has(11);
  @$pb.TagNumber(28)
  void clearSessionTerminated() => $_clearField(28);
  @$pb.TagNumber(28)
  SessionTerminatedEvent ensureSessionTerminated() => $_ensure(11);

  @$pb.TagNumber(29)
  $6.UnifiedError get error => $_getN(12);
  @$pb.TagNumber(29)
  set error($6.UnifiedError value) => $_setField(29, value);
  @$pb.TagNumber(29)
  $core.bool hasError() => $_has(12);
  @$pb.TagNumber(29)
  void clearError() => $_clearField(29);
  @$pb.TagNumber(29)
  $6.UnifiedError ensureError() => $_ensure(12);

  @$pb.TagNumber(30)
  $4.HostPairingStatusSnapshot get hostPairingStatus => $_getN(13);
  @$pb.TagNumber(30)
  set hostPairingStatus($4.HostPairingStatusSnapshot value) =>
      $_setField(30, value);
  @$pb.TagNumber(30)
  $core.bool hasHostPairingStatus() => $_has(13);
  @$pb.TagNumber(30)
  void clearHostPairingStatus() => $_clearField(30);
  @$pb.TagNumber(30)
  $4.HostPairingStatusSnapshot ensureHostPairingStatus() => $_ensure(13);

  @$pb.TagNumber(31)
  PairingTranscriptSignature get pairingTranscriptSignature => $_getN(14);
  @$pb.TagNumber(31)
  set pairingTranscriptSignature(PairingTranscriptSignature value) =>
      $_setField(31, value);
  @$pb.TagNumber(31)
  $core.bool hasPairingTranscriptSignature() => $_has(14);
  @$pb.TagNumber(31)
  void clearPairingTranscriptSignature() => $_clearField(31);
  @$pb.TagNumber(31)
  PairingTranscriptSignature ensurePairingTranscriptSignature() => $_ensure(14);

  @$pb.TagNumber(32)
  HostPairingStateChangedEvent get hostPairingStateChanged => $_getN(15);
  @$pb.TagNumber(32)
  set hostPairingStateChanged(HostPairingStateChangedEvent value) =>
      $_setField(32, value);
  @$pb.TagNumber(32)
  $core.bool hasHostPairingStateChanged() => $_has(15);
  @$pb.TagNumber(32)
  void clearHostPairingStateChanged() => $_clearField(32);
  @$pb.TagNumber(32)
  HostPairingStateChangedEvent ensureHostPairingStateChanged() => $_ensure(15);

  @$pb.TagNumber(33)
  EmergencyStopRemoteSessionResult get emergencyStopRemoteSessionResult =>
      $_getN(16);
  @$pb.TagNumber(33)
  set emergencyStopRemoteSessionResult(
          EmergencyStopRemoteSessionResult value) =>
      $_setField(33, value);
  @$pb.TagNumber(33)
  $core.bool hasEmergencyStopRemoteSessionResult() => $_has(16);
  @$pb.TagNumber(33)
  void clearEmergencyStopRemoteSessionResult() => $_clearField(33);
  @$pb.TagNumber(33)
  EmergencyStopRemoteSessionResult ensureEmergencyStopRemoteSessionResult() =>
      $_ensure(16);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
