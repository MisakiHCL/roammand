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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'error.pb.dart' as $0;
import 'identity.pbenum.dart' as $4;
import 'input.pb.dart' as $2;
import 'privileged_bridge.pbenum.dart';
import 'session.pbenum.dart' as $5;
import 'version.pb.dart' as $3;
import 'webrtc.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'privileged_bridge.pbenum.dart';

class PrivilegedSessionDescriptor extends $pb.GeneratedMessage {
  factory PrivilegedSessionDescriptor({
    $4.DevicePlatform? platform,
    $fixnum.Int64? osSessionId,
    InteractiveDesktopKind? desktopKind,
    $fixnum.Int64? generation,
  }) {
    final result = create();
    if (platform != null) result.platform = platform;
    if (osSessionId != null) result.osSessionId = osSessionId;
    if (desktopKind != null) result.desktopKind = desktopKind;
    if (generation != null) result.generation = generation;
    return result;
  }

  PrivilegedSessionDescriptor._();

  factory PrivilegedSessionDescriptor.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PrivilegedSessionDescriptor.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PrivilegedSessionDescriptor',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..e<$4.DevicePlatform>(
        1, _omitFieldNames ? '' : 'platform', $pb.PbFieldType.OE,
        defaultOrMaker: $4.DevicePlatform.DEVICE_PLATFORM_UNSPECIFIED,
        valueOf: $4.DevicePlatform.valueOf,
        enumValues: $4.DevicePlatform.values)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'osSessionId', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..e<InteractiveDesktopKind>(
        3, _omitFieldNames ? '' : 'desktopKind', $pb.PbFieldType.OE,
        defaultOrMaker:
            InteractiveDesktopKind.INTERACTIVE_DESKTOP_KIND_UNSPECIFIED,
        valueOf: InteractiveDesktopKind.valueOf,
        enumValues: InteractiveDesktopKind.values)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'generation', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedSessionDescriptor clone() =>
      PrivilegedSessionDescriptor()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedSessionDescriptor copyWith(
          void Function(PrivilegedSessionDescriptor) updates) =>
      super.copyWith(
              (message) => updates(message as PrivilegedSessionDescriptor))
          as PrivilegedSessionDescriptor;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PrivilegedSessionDescriptor create() =>
      PrivilegedSessionDescriptor._();
  @$core.override
  PrivilegedSessionDescriptor createEmptyInstance() => create();
  static $pb.PbList<PrivilegedSessionDescriptor> createRepeated() =>
      $pb.PbList<PrivilegedSessionDescriptor>();
  @$core.pragma('dart2js:noInline')
  static PrivilegedSessionDescriptor getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PrivilegedSessionDescriptor>(create);
  static PrivilegedSessionDescriptor? _defaultInstance;

  @$pb.TagNumber(1)
  $4.DevicePlatform get platform => $_getN(0);
  @$pb.TagNumber(1)
  set platform($4.DevicePlatform value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPlatform() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlatform() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get osSessionId => $_getI64(1);
  @$pb.TagNumber(2)
  set osSessionId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOsSessionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearOsSessionId() => $_clearField(2);

  @$pb.TagNumber(3)
  InteractiveDesktopKind get desktopKind => $_getN(2);
  @$pb.TagNumber(3)
  set desktopKind(InteractiveDesktopKind value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasDesktopKind() => $_has(2);
  @$pb.TagNumber(3)
  void clearDesktopKind() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get generation => $_getI64(3);
  @$pb.TagNumber(4)
  set generation($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasGeneration() => $_has(3);
  @$pb.TagNumber(4)
  void clearGeneration() => $_clearField(4);
}

class PrivilegedBridgeStatusSnapshot extends $pb.GeneratedMessage {
  factory PrivilegedBridgeStatusSnapshot({
    PrivilegedBridgeState? state,
    PrivilegedSessionDescriptor? interactiveSession,
    $core.bool? helperConnected,
    $core.String? activeControllerDisplayName,
    $0.UnifiedError? error,
  }) {
    final result = create();
    if (state != null) result.state = state;
    if (interactiveSession != null)
      result.interactiveSession = interactiveSession;
    if (helperConnected != null) result.helperConnected = helperConnected;
    if (activeControllerDisplayName != null)
      result.activeControllerDisplayName = activeControllerDisplayName;
    if (error != null) result.error = error;
    return result;
  }

  PrivilegedBridgeStatusSnapshot._();

  factory PrivilegedBridgeStatusSnapshot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PrivilegedBridgeStatusSnapshot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PrivilegedBridgeStatusSnapshot',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..e<PrivilegedBridgeState>(
        1, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE,
        defaultOrMaker:
            PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_UNSPECIFIED,
        valueOf: PrivilegedBridgeState.valueOf,
        enumValues: PrivilegedBridgeState.values)
    ..aOM<PrivilegedSessionDescriptor>(
        2, _omitFieldNames ? '' : 'interactiveSession',
        subBuilder: PrivilegedSessionDescriptor.create)
    ..aOB(3, _omitFieldNames ? '' : 'helperConnected')
    ..aOS(4, _omitFieldNames ? '' : 'activeControllerDisplayName')
    ..aOM<$0.UnifiedError>(5, _omitFieldNames ? '' : 'error',
        subBuilder: $0.UnifiedError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedBridgeStatusSnapshot clone() =>
      PrivilegedBridgeStatusSnapshot()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedBridgeStatusSnapshot copyWith(
          void Function(PrivilegedBridgeStatusSnapshot) updates) =>
      super.copyWith(
              (message) => updates(message as PrivilegedBridgeStatusSnapshot))
          as PrivilegedBridgeStatusSnapshot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PrivilegedBridgeStatusSnapshot create() =>
      PrivilegedBridgeStatusSnapshot._();
  @$core.override
  PrivilegedBridgeStatusSnapshot createEmptyInstance() => create();
  static $pb.PbList<PrivilegedBridgeStatusSnapshot> createRepeated() =>
      $pb.PbList<PrivilegedBridgeStatusSnapshot>();
  @$core.pragma('dart2js:noInline')
  static PrivilegedBridgeStatusSnapshot getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PrivilegedBridgeStatusSnapshot>(create);
  static PrivilegedBridgeStatusSnapshot? _defaultInstance;

  @$pb.TagNumber(1)
  PrivilegedBridgeState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(PrivilegedBridgeState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);

  @$pb.TagNumber(2)
  PrivilegedSessionDescriptor get interactiveSession => $_getN(1);
  @$pb.TagNumber(2)
  set interactiveSession(PrivilegedSessionDescriptor value) =>
      $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasInteractiveSession() => $_has(1);
  @$pb.TagNumber(2)
  void clearInteractiveSession() => $_clearField(2);
  @$pb.TagNumber(2)
  PrivilegedSessionDescriptor ensureInteractiveSession() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.bool get helperConnected => $_getBF(2);
  @$pb.TagNumber(3)
  set helperConnected($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHelperConnected() => $_has(2);
  @$pb.TagNumber(3)
  void clearHelperConnected() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get activeControllerDisplayName => $_getSZ(3);
  @$pb.TagNumber(4)
  set activeControllerDisplayName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasActiveControllerDisplayName() => $_has(3);
  @$pb.TagNumber(4)
  void clearActiveControllerDisplayName() => $_clearField(4);

  @$pb.TagNumber(5)
  $0.UnifiedError get error => $_getN(4);
  @$pb.TagNumber(5)
  set error($0.UnifiedError value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasError() => $_has(4);
  @$pb.TagNumber(5)
  void clearError() => $_clearField(5);
  @$pb.TagNumber(5)
  $0.UnifiedError ensureError() => $_ensure(4);
}

class PrivilegedBridgeChallenge extends $pb.GeneratedMessage {
  factory PrivilegedBridgeChallenge({
    $core.List<$core.int>? brokerInstanceId,
    $core.List<$core.int>? serverNonce,
  }) {
    final result = create();
    if (brokerInstanceId != null) result.brokerInstanceId = brokerInstanceId;
    if (serverNonce != null) result.serverNonce = serverNonce;
    return result;
  }

  PrivilegedBridgeChallenge._();

  factory PrivilegedBridgeChallenge.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PrivilegedBridgeChallenge.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PrivilegedBridgeChallenge',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'brokerInstanceId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'serverNonce', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedBridgeChallenge clone() =>
      PrivilegedBridgeChallenge()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedBridgeChallenge copyWith(
          void Function(PrivilegedBridgeChallenge) updates) =>
      super.copyWith((message) => updates(message as PrivilegedBridgeChallenge))
          as PrivilegedBridgeChallenge;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PrivilegedBridgeChallenge create() => PrivilegedBridgeChallenge._();
  @$core.override
  PrivilegedBridgeChallenge createEmptyInstance() => create();
  static $pb.PbList<PrivilegedBridgeChallenge> createRepeated() =>
      $pb.PbList<PrivilegedBridgeChallenge>();
  @$core.pragma('dart2js:noInline')
  static PrivilegedBridgeChallenge getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PrivilegedBridgeChallenge>(create);
  static PrivilegedBridgeChallenge? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get brokerInstanceId => $_getN(0);
  @$pb.TagNumber(1)
  set brokerInstanceId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBrokerInstanceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBrokerInstanceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get serverNonce => $_getN(1);
  @$pb.TagNumber(2)
  set serverNonce($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasServerNonce() => $_has(1);
  @$pb.TagNumber(2)
  void clearServerNonce() => $_clearField(2);
}

class PrivilegedBridgeAuthenticate extends $pb.GeneratedMessage {
  factory PrivilegedBridgeAuthenticate({
    PrivilegedBridgeRole? role,
    $core.List<$core.int>? clientNonce,
    $core.List<$core.int>? clientProof,
    $core.List<$core.int>? executableSha256,
    $fixnum.Int64? osSessionId,
  }) {
    final result = create();
    if (role != null) result.role = role;
    if (clientNonce != null) result.clientNonce = clientNonce;
    if (clientProof != null) result.clientProof = clientProof;
    if (executableSha256 != null) result.executableSha256 = executableSha256;
    if (osSessionId != null) result.osSessionId = osSessionId;
    return result;
  }

  PrivilegedBridgeAuthenticate._();

  factory PrivilegedBridgeAuthenticate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PrivilegedBridgeAuthenticate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PrivilegedBridgeAuthenticate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..e<PrivilegedBridgeRole>(
        1, _omitFieldNames ? '' : 'role', $pb.PbFieldType.OE,
        defaultOrMaker: PrivilegedBridgeRole.PRIVILEGED_BRIDGE_ROLE_UNSPECIFIED,
        valueOf: PrivilegedBridgeRole.valueOf,
        enumValues: PrivilegedBridgeRole.values)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'clientNonce', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'clientProof', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'executableSha256', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'osSessionId', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedBridgeAuthenticate clone() =>
      PrivilegedBridgeAuthenticate()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedBridgeAuthenticate copyWith(
          void Function(PrivilegedBridgeAuthenticate) updates) =>
      super.copyWith(
              (message) => updates(message as PrivilegedBridgeAuthenticate))
          as PrivilegedBridgeAuthenticate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PrivilegedBridgeAuthenticate create() =>
      PrivilegedBridgeAuthenticate._();
  @$core.override
  PrivilegedBridgeAuthenticate createEmptyInstance() => create();
  static $pb.PbList<PrivilegedBridgeAuthenticate> createRepeated() =>
      $pb.PbList<PrivilegedBridgeAuthenticate>();
  @$core.pragma('dart2js:noInline')
  static PrivilegedBridgeAuthenticate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PrivilegedBridgeAuthenticate>(create);
  static PrivilegedBridgeAuthenticate? _defaultInstance;

  @$pb.TagNumber(1)
  PrivilegedBridgeRole get role => $_getN(0);
  @$pb.TagNumber(1)
  set role(PrivilegedBridgeRole value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRole() => $_has(0);
  @$pb.TagNumber(1)
  void clearRole() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get clientNonce => $_getN(1);
  @$pb.TagNumber(2)
  set clientNonce($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasClientNonce() => $_has(1);
  @$pb.TagNumber(2)
  void clearClientNonce() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get clientProof => $_getN(2);
  @$pb.TagNumber(3)
  set clientProof($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasClientProof() => $_has(2);
  @$pb.TagNumber(3)
  void clearClientProof() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get executableSha256 => $_getN(3);
  @$pb.TagNumber(4)
  set executableSha256($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasExecutableSha256() => $_has(3);
  @$pb.TagNumber(4)
  void clearExecutableSha256() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get osSessionId => $_getI64(4);
  @$pb.TagNumber(5)
  set osSessionId($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasOsSessionId() => $_has(4);
  @$pb.TagNumber(5)
  void clearOsSessionId() => $_clearField(5);
}

class PrivilegedBridgeAuthenticated extends $pb.GeneratedMessage {
  factory PrivilegedBridgeAuthenticated({
    $core.List<$core.int>? serverProof,
  }) {
    final result = create();
    if (serverProof != null) result.serverProof = serverProof;
    return result;
  }

  PrivilegedBridgeAuthenticated._();

  factory PrivilegedBridgeAuthenticated.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PrivilegedBridgeAuthenticated.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PrivilegedBridgeAuthenticated',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'serverProof', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedBridgeAuthenticated clone() =>
      PrivilegedBridgeAuthenticated()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedBridgeAuthenticated copyWith(
          void Function(PrivilegedBridgeAuthenticated) updates) =>
      super.copyWith(
              (message) => updates(message as PrivilegedBridgeAuthenticated))
          as PrivilegedBridgeAuthenticated;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PrivilegedBridgeAuthenticated create() =>
      PrivilegedBridgeAuthenticated._();
  @$core.override
  PrivilegedBridgeAuthenticated createEmptyInstance() => create();
  static $pb.PbList<PrivilegedBridgeAuthenticated> createRepeated() =>
      $pb.PbList<PrivilegedBridgeAuthenticated>();
  @$core.pragma('dart2js:noInline')
  static PrivilegedBridgeAuthenticated getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PrivilegedBridgeAuthenticated>(create);
  static PrivilegedBridgeAuthenticated? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get serverProof => $_getN(0);
  @$pb.TagNumber(1)
  set serverProof($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerProof() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerProof() => $_clearField(1);
}

class PrivilegedLease extends $pb.GeneratedMessage {
  factory PrivilegedLease({
    $core.List<$core.int>? leaseId,
    $fixnum.Int64? generation,
    $fixnum.Int64? issuedAtUnixMs,
    $fixnum.Int64? expiresAtUnixMs,
    $core.List<$core.int>? sessionId,
    $core.Iterable<$5.SessionPermission>? permissions,
    $core.String? controllerDisplayName,
  }) {
    final result = create();
    if (leaseId != null) result.leaseId = leaseId;
    if (generation != null) result.generation = generation;
    if (issuedAtUnixMs != null) result.issuedAtUnixMs = issuedAtUnixMs;
    if (expiresAtUnixMs != null) result.expiresAtUnixMs = expiresAtUnixMs;
    if (sessionId != null) result.sessionId = sessionId;
    if (permissions != null) result.permissions.addAll(permissions);
    if (controllerDisplayName != null)
      result.controllerDisplayName = controllerDisplayName;
    return result;
  }

  PrivilegedLease._();

  factory PrivilegedLease.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PrivilegedLease.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PrivilegedLease',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'leaseId', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'generation', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'issuedAtUnixMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'expiresAtUnixMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'sessionId', $pb.PbFieldType.OY)
    ..pc<$5.SessionPermission>(
        6, _omitFieldNames ? '' : 'permissions', $pb.PbFieldType.KE,
        valueOf: $5.SessionPermission.valueOf,
        enumValues: $5.SessionPermission.values,
        defaultEnumValue: $5.SessionPermission.SESSION_PERMISSION_UNSPECIFIED)
    ..aOS(7, _omitFieldNames ? '' : 'controllerDisplayName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedLease clone() => PrivilegedLease()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedLease copyWith(void Function(PrivilegedLease) updates) =>
      super.copyWith((message) => updates(message as PrivilegedLease))
          as PrivilegedLease;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PrivilegedLease create() => PrivilegedLease._();
  @$core.override
  PrivilegedLease createEmptyInstance() => create();
  static $pb.PbList<PrivilegedLease> createRepeated() =>
      $pb.PbList<PrivilegedLease>();
  @$core.pragma('dart2js:noInline')
  static PrivilegedLease getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PrivilegedLease>(create);
  static PrivilegedLease? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get leaseId => $_getN(0);
  @$pb.TagNumber(1)
  set leaseId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLeaseId() => $_has(0);
  @$pb.TagNumber(1)
  void clearLeaseId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get generation => $_getI64(1);
  @$pb.TagNumber(2)
  set generation($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGeneration() => $_has(1);
  @$pb.TagNumber(2)
  void clearGeneration() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get issuedAtUnixMs => $_getI64(2);
  @$pb.TagNumber(3)
  set issuedAtUnixMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIssuedAtUnixMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearIssuedAtUnixMs() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get expiresAtUnixMs => $_getI64(3);
  @$pb.TagNumber(4)
  set expiresAtUnixMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasExpiresAtUnixMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearExpiresAtUnixMs() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.int> get sessionId => $_getN(4);
  @$pb.TagNumber(5)
  set sessionId($core.List<$core.int> value) => $_setBytes(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSessionId() => $_has(4);
  @$pb.TagNumber(5)
  void clearSessionId() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<$5.SessionPermission> get permissions => $_getList(5);

  @$pb.TagNumber(7)
  $core.String get controllerDisplayName => $_getSZ(6);
  @$pb.TagNumber(7)
  set controllerDisplayName($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasControllerDisplayName() => $_has(6);
  @$pb.TagNumber(7)
  void clearControllerDisplayName() => $_clearField(7);
}

class AcquirePrivilegedLeaseRequest extends $pb.GeneratedMessage {
  factory AcquirePrivilegedLeaseRequest({
    $core.List<$core.int>? sessionId,
    $fixnum.Int64? generation,
    $core.Iterable<$5.SessionPermission>? permissions,
    $core.String? controllerDisplayName,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (generation != null) result.generation = generation;
    if (permissions != null) result.permissions.addAll(permissions);
    if (controllerDisplayName != null)
      result.controllerDisplayName = controllerDisplayName;
    return result;
  }

  AcquirePrivilegedLeaseRequest._();

  factory AcquirePrivilegedLeaseRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AcquirePrivilegedLeaseRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AcquirePrivilegedLeaseRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'sessionId', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'generation', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pc<$5.SessionPermission>(
        3, _omitFieldNames ? '' : 'permissions', $pb.PbFieldType.KE,
        valueOf: $5.SessionPermission.valueOf,
        enumValues: $5.SessionPermission.values,
        defaultEnumValue: $5.SessionPermission.SESSION_PERMISSION_UNSPECIFIED)
    ..aOS(4, _omitFieldNames ? '' : 'controllerDisplayName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquirePrivilegedLeaseRequest clone() =>
      AcquirePrivilegedLeaseRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquirePrivilegedLeaseRequest copyWith(
          void Function(AcquirePrivilegedLeaseRequest) updates) =>
      super.copyWith(
              (message) => updates(message as AcquirePrivilegedLeaseRequest))
          as AcquirePrivilegedLeaseRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AcquirePrivilegedLeaseRequest create() =>
      AcquirePrivilegedLeaseRequest._();
  @$core.override
  AcquirePrivilegedLeaseRequest createEmptyInstance() => create();
  static $pb.PbList<AcquirePrivilegedLeaseRequest> createRepeated() =>
      $pb.PbList<AcquirePrivilegedLeaseRequest>();
  @$core.pragma('dart2js:noInline')
  static AcquirePrivilegedLeaseRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AcquirePrivilegedLeaseRequest>(create);
  static AcquirePrivilegedLeaseRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get sessionId => $_getN(0);
  @$pb.TagNumber(1)
  set sessionId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get generation => $_getI64(1);
  @$pb.TagNumber(2)
  set generation($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGeneration() => $_has(1);
  @$pb.TagNumber(2)
  void clearGeneration() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$5.SessionPermission> get permissions => $_getList(2);

  @$pb.TagNumber(4)
  $core.String get controllerDisplayName => $_getSZ(3);
  @$pb.TagNumber(4)
  set controllerDisplayName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasControllerDisplayName() => $_has(3);
  @$pb.TagNumber(4)
  void clearControllerDisplayName() => $_clearField(4);
}

class RenewPrivilegedLeaseRequest extends $pb.GeneratedMessage {
  factory RenewPrivilegedLeaseRequest({
    $core.List<$core.int>? leaseId,
    $fixnum.Int64? generation,
  }) {
    final result = create();
    if (leaseId != null) result.leaseId = leaseId;
    if (generation != null) result.generation = generation;
    return result;
  }

  RenewPrivilegedLeaseRequest._();

  factory RenewPrivilegedLeaseRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RenewPrivilegedLeaseRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RenewPrivilegedLeaseRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'leaseId', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'generation', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenewPrivilegedLeaseRequest clone() =>
      RenewPrivilegedLeaseRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenewPrivilegedLeaseRequest copyWith(
          void Function(RenewPrivilegedLeaseRequest) updates) =>
      super.copyWith(
              (message) => updates(message as RenewPrivilegedLeaseRequest))
          as RenewPrivilegedLeaseRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RenewPrivilegedLeaseRequest create() =>
      RenewPrivilegedLeaseRequest._();
  @$core.override
  RenewPrivilegedLeaseRequest createEmptyInstance() => create();
  static $pb.PbList<RenewPrivilegedLeaseRequest> createRepeated() =>
      $pb.PbList<RenewPrivilegedLeaseRequest>();
  @$core.pragma('dart2js:noInline')
  static RenewPrivilegedLeaseRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RenewPrivilegedLeaseRequest>(create);
  static RenewPrivilegedLeaseRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get leaseId => $_getN(0);
  @$pb.TagNumber(1)
  set leaseId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLeaseId() => $_has(0);
  @$pb.TagNumber(1)
  void clearLeaseId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get generation => $_getI64(1);
  @$pb.TagNumber(2)
  set generation($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGeneration() => $_has(1);
  @$pb.TagNumber(2)
  void clearGeneration() => $_clearField(2);
}

class ReleasePrivilegedLeaseRequest extends $pb.GeneratedMessage {
  factory ReleasePrivilegedLeaseRequest({
    $core.List<$core.int>? leaseId,
    $fixnum.Int64? generation,
  }) {
    final result = create();
    if (leaseId != null) result.leaseId = leaseId;
    if (generation != null) result.generation = generation;
    return result;
  }

  ReleasePrivilegedLeaseRequest._();

  factory ReleasePrivilegedLeaseRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReleasePrivilegedLeaseRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReleasePrivilegedLeaseRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'leaseId', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'generation', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReleasePrivilegedLeaseRequest clone() =>
      ReleasePrivilegedLeaseRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReleasePrivilegedLeaseRequest copyWith(
          void Function(ReleasePrivilegedLeaseRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ReleasePrivilegedLeaseRequest))
          as ReleasePrivilegedLeaseRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReleasePrivilegedLeaseRequest create() =>
      ReleasePrivilegedLeaseRequest._();
  @$core.override
  ReleasePrivilegedLeaseRequest createEmptyInstance() => create();
  static $pb.PbList<ReleasePrivilegedLeaseRequest> createRepeated() =>
      $pb.PbList<ReleasePrivilegedLeaseRequest>();
  @$core.pragma('dart2js:noInline')
  static ReleasePrivilegedLeaseRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReleasePrivilegedLeaseRequest>(create);
  static ReleasePrivilegedLeaseRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get leaseId => $_getN(0);
  @$pb.TagNumber(1)
  set leaseId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLeaseId() => $_has(0);
  @$pb.TagNumber(1)
  void clearLeaseId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get generation => $_getI64(1);
  @$pb.TagNumber(2)
  set generation($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGeneration() => $_has(1);
  @$pb.TagNumber(2)
  void clearGeneration() => $_clearField(2);
}

class PrivilegedIceServer extends $pb.GeneratedMessage {
  factory PrivilegedIceServer({
    $core.Iterable<$core.String>? urls,
    $core.String? username,
    $core.String? credential,
  }) {
    final result = create();
    if (urls != null) result.urls.addAll(urls);
    if (username != null) result.username = username;
    if (credential != null) result.credential = credential;
    return result;
  }

  PrivilegedIceServer._();

  factory PrivilegedIceServer.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PrivilegedIceServer.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PrivilegedIceServer',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'urls')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..aOS(3, _omitFieldNames ? '' : 'credential')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedIceServer clone() => PrivilegedIceServer()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedIceServer copyWith(void Function(PrivilegedIceServer) updates) =>
      super.copyWith((message) => updates(message as PrivilegedIceServer))
          as PrivilegedIceServer;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PrivilegedIceServer create() => PrivilegedIceServer._();
  @$core.override
  PrivilegedIceServer createEmptyInstance() => create();
  static $pb.PbList<PrivilegedIceServer> createRepeated() =>
      $pb.PbList<PrivilegedIceServer>();
  @$core.pragma('dart2js:noInline')
  static PrivilegedIceServer getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PrivilegedIceServer>(create);
  static PrivilegedIceServer? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get urls => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get credential => $_getSZ(2);
  @$pb.TagNumber(3)
  set credential($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCredential() => $_has(2);
  @$pb.TagNumber(3)
  void clearCredential() => $_clearField(3);
}

class PrivilegedPeerConfiguration extends $pb.GeneratedMessage {
  factory PrivilegedPeerConfiguration({
    PrivilegedIceTransportPolicy? iceTransportPolicy,
    $core.Iterable<PrivilegedIceServer>? iceServers,
  }) {
    final result = create();
    if (iceTransportPolicy != null)
      result.iceTransportPolicy = iceTransportPolicy;
    if (iceServers != null) result.iceServers.addAll(iceServers);
    return result;
  }

  PrivilegedPeerConfiguration._();

  factory PrivilegedPeerConfiguration.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PrivilegedPeerConfiguration.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PrivilegedPeerConfiguration',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..e<PrivilegedIceTransportPolicy>(
        1, _omitFieldNames ? '' : 'iceTransportPolicy', $pb.PbFieldType.OE,
        defaultOrMaker: PrivilegedIceTransportPolicy
            .PRIVILEGED_ICE_TRANSPORT_POLICY_UNSPECIFIED,
        valueOf: PrivilegedIceTransportPolicy.valueOf,
        enumValues: PrivilegedIceTransportPolicy.values)
    ..pc<PrivilegedIceServer>(
        2, _omitFieldNames ? '' : 'iceServers', $pb.PbFieldType.PM,
        subBuilder: PrivilegedIceServer.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedPeerConfiguration clone() =>
      PrivilegedPeerConfiguration()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedPeerConfiguration copyWith(
          void Function(PrivilegedPeerConfiguration) updates) =>
      super.copyWith(
              (message) => updates(message as PrivilegedPeerConfiguration))
          as PrivilegedPeerConfiguration;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PrivilegedPeerConfiguration create() =>
      PrivilegedPeerConfiguration._();
  @$core.override
  PrivilegedPeerConfiguration createEmptyInstance() => create();
  static $pb.PbList<PrivilegedPeerConfiguration> createRepeated() =>
      $pb.PbList<PrivilegedPeerConfiguration>();
  @$core.pragma('dart2js:noInline')
  static PrivilegedPeerConfiguration getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PrivilegedPeerConfiguration>(create);
  static PrivilegedPeerConfiguration? _defaultInstance;

  @$pb.TagNumber(1)
  PrivilegedIceTransportPolicy get iceTransportPolicy => $_getN(0);
  @$pb.TagNumber(1)
  set iceTransportPolicy(PrivilegedIceTransportPolicy value) =>
      $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasIceTransportPolicy() => $_has(0);
  @$pb.TagNumber(1)
  void clearIceTransportPolicy() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<PrivilegedIceServer> get iceServers => $_getList(1);
}

class StartPrivilegedPeerRequest extends $pb.GeneratedMessage {
  factory StartPrivilegedPeerRequest({
    $core.List<$core.int>? leaseId,
    $fixnum.Int64? generation,
    PrivilegedPeerConfiguration? configuration,
    $1.WebRtcSessionDescription? offer,
    $core.String? controllerDisplayName,
  }) {
    final result = create();
    if (leaseId != null) result.leaseId = leaseId;
    if (generation != null) result.generation = generation;
    if (configuration != null) result.configuration = configuration;
    if (offer != null) result.offer = offer;
    if (controllerDisplayName != null)
      result.controllerDisplayName = controllerDisplayName;
    return result;
  }

  StartPrivilegedPeerRequest._();

  factory StartPrivilegedPeerRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StartPrivilegedPeerRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartPrivilegedPeerRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'leaseId', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'generation', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<PrivilegedPeerConfiguration>(
        3, _omitFieldNames ? '' : 'configuration',
        subBuilder: PrivilegedPeerConfiguration.create)
    ..aOM<$1.WebRtcSessionDescription>(4, _omitFieldNames ? '' : 'offer',
        subBuilder: $1.WebRtcSessionDescription.create)
    ..aOS(5, _omitFieldNames ? '' : 'controllerDisplayName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartPrivilegedPeerRequest clone() =>
      StartPrivilegedPeerRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartPrivilegedPeerRequest copyWith(
          void Function(StartPrivilegedPeerRequest) updates) =>
      super.copyWith(
              (message) => updates(message as StartPrivilegedPeerRequest))
          as StartPrivilegedPeerRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartPrivilegedPeerRequest create() => StartPrivilegedPeerRequest._();
  @$core.override
  StartPrivilegedPeerRequest createEmptyInstance() => create();
  static $pb.PbList<StartPrivilegedPeerRequest> createRepeated() =>
      $pb.PbList<StartPrivilegedPeerRequest>();
  @$core.pragma('dart2js:noInline')
  static StartPrivilegedPeerRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartPrivilegedPeerRequest>(create);
  static StartPrivilegedPeerRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get leaseId => $_getN(0);
  @$pb.TagNumber(1)
  set leaseId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLeaseId() => $_has(0);
  @$pb.TagNumber(1)
  void clearLeaseId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get generation => $_getI64(1);
  @$pb.TagNumber(2)
  set generation($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGeneration() => $_has(1);
  @$pb.TagNumber(2)
  void clearGeneration() => $_clearField(2);

  @$pb.TagNumber(3)
  PrivilegedPeerConfiguration get configuration => $_getN(2);
  @$pb.TagNumber(3)
  set configuration(PrivilegedPeerConfiguration value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasConfiguration() => $_has(2);
  @$pb.TagNumber(3)
  void clearConfiguration() => $_clearField(3);
  @$pb.TagNumber(3)
  PrivilegedPeerConfiguration ensureConfiguration() => $_ensure(2);

  @$pb.TagNumber(4)
  $1.WebRtcSessionDescription get offer => $_getN(3);
  @$pb.TagNumber(4)
  set offer($1.WebRtcSessionDescription value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasOffer() => $_has(3);
  @$pb.TagNumber(4)
  void clearOffer() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.WebRtcSessionDescription ensureOffer() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.String get controllerDisplayName => $_getSZ(4);
  @$pb.TagNumber(5)
  set controllerDisplayName($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasControllerDisplayName() => $_has(4);
  @$pb.TagNumber(5)
  void clearControllerDisplayName() => $_clearField(5);
}

class RestartPrivilegedPeerRequest extends $pb.GeneratedMessage {
  factory RestartPrivilegedPeerRequest({
    $core.List<$core.int>? leaseId,
    $fixnum.Int64? generation,
    PrivilegedPeerConfiguration? configuration,
    $1.WebRtcSessionDescription? offer,
    $core.String? controllerDisplayName,
  }) {
    final result = create();
    if (leaseId != null) result.leaseId = leaseId;
    if (generation != null) result.generation = generation;
    if (configuration != null) result.configuration = configuration;
    if (offer != null) result.offer = offer;
    if (controllerDisplayName != null)
      result.controllerDisplayName = controllerDisplayName;
    return result;
  }

  RestartPrivilegedPeerRequest._();

  factory RestartPrivilegedPeerRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RestartPrivilegedPeerRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RestartPrivilegedPeerRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'leaseId', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'generation', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<PrivilegedPeerConfiguration>(
        3, _omitFieldNames ? '' : 'configuration',
        subBuilder: PrivilegedPeerConfiguration.create)
    ..aOM<$1.WebRtcSessionDescription>(4, _omitFieldNames ? '' : 'offer',
        subBuilder: $1.WebRtcSessionDescription.create)
    ..aOS(5, _omitFieldNames ? '' : 'controllerDisplayName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RestartPrivilegedPeerRequest clone() =>
      RestartPrivilegedPeerRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RestartPrivilegedPeerRequest copyWith(
          void Function(RestartPrivilegedPeerRequest) updates) =>
      super.copyWith(
              (message) => updates(message as RestartPrivilegedPeerRequest))
          as RestartPrivilegedPeerRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RestartPrivilegedPeerRequest create() =>
      RestartPrivilegedPeerRequest._();
  @$core.override
  RestartPrivilegedPeerRequest createEmptyInstance() => create();
  static $pb.PbList<RestartPrivilegedPeerRequest> createRepeated() =>
      $pb.PbList<RestartPrivilegedPeerRequest>();
  @$core.pragma('dart2js:noInline')
  static RestartPrivilegedPeerRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RestartPrivilegedPeerRequest>(create);
  static RestartPrivilegedPeerRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get leaseId => $_getN(0);
  @$pb.TagNumber(1)
  set leaseId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLeaseId() => $_has(0);
  @$pb.TagNumber(1)
  void clearLeaseId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get generation => $_getI64(1);
  @$pb.TagNumber(2)
  set generation($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGeneration() => $_has(1);
  @$pb.TagNumber(2)
  void clearGeneration() => $_clearField(2);

  @$pb.TagNumber(3)
  PrivilegedPeerConfiguration get configuration => $_getN(2);
  @$pb.TagNumber(3)
  set configuration(PrivilegedPeerConfiguration value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasConfiguration() => $_has(2);
  @$pb.TagNumber(3)
  void clearConfiguration() => $_clearField(3);
  @$pb.TagNumber(3)
  PrivilegedPeerConfiguration ensureConfiguration() => $_ensure(2);

  @$pb.TagNumber(4)
  $1.WebRtcSessionDescription get offer => $_getN(3);
  @$pb.TagNumber(4)
  set offer($1.WebRtcSessionDescription value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasOffer() => $_has(3);
  @$pb.TagNumber(4)
  void clearOffer() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.WebRtcSessionDescription ensureOffer() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.String get controllerDisplayName => $_getSZ(4);
  @$pb.TagNumber(5)
  set controllerDisplayName($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasControllerDisplayName() => $_has(4);
  @$pb.TagNumber(5)
  void clearControllerDisplayName() => $_clearField(5);
}

class AddPrivilegedIceCandidateRequest extends $pb.GeneratedMessage {
  factory AddPrivilegedIceCandidateRequest({
    $core.List<$core.int>? leaseId,
    $fixnum.Int64? generation,
    $1.IceCandidate? candidate,
  }) {
    final result = create();
    if (leaseId != null) result.leaseId = leaseId;
    if (generation != null) result.generation = generation;
    if (candidate != null) result.candidate = candidate;
    return result;
  }

  AddPrivilegedIceCandidateRequest._();

  factory AddPrivilegedIceCandidateRequest.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddPrivilegedIceCandidateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddPrivilegedIceCandidateRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'leaseId', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'generation', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<$1.IceCandidate>(3, _omitFieldNames ? '' : 'candidate',
        subBuilder: $1.IceCandidate.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddPrivilegedIceCandidateRequest clone() =>
      AddPrivilegedIceCandidateRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddPrivilegedIceCandidateRequest copyWith(
          void Function(AddPrivilegedIceCandidateRequest) updates) =>
      super.copyWith(
              (message) => updates(message as AddPrivilegedIceCandidateRequest))
          as AddPrivilegedIceCandidateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddPrivilegedIceCandidateRequest create() =>
      AddPrivilegedIceCandidateRequest._();
  @$core.override
  AddPrivilegedIceCandidateRequest createEmptyInstance() => create();
  static $pb.PbList<AddPrivilegedIceCandidateRequest> createRepeated() =>
      $pb.PbList<AddPrivilegedIceCandidateRequest>();
  @$core.pragma('dart2js:noInline')
  static AddPrivilegedIceCandidateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddPrivilegedIceCandidateRequest>(
          create);
  static AddPrivilegedIceCandidateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get leaseId => $_getN(0);
  @$pb.TagNumber(1)
  set leaseId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLeaseId() => $_has(0);
  @$pb.TagNumber(1)
  void clearLeaseId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get generation => $_getI64(1);
  @$pb.TagNumber(2)
  set generation($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGeneration() => $_has(1);
  @$pb.TagNumber(2)
  void clearGeneration() => $_clearField(2);

  @$pb.TagNumber(3)
  $1.IceCandidate get candidate => $_getN(2);
  @$pb.TagNumber(3)
  set candidate($1.IceCandidate value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCandidate() => $_has(2);
  @$pb.TagNumber(3)
  void clearCandidate() => $_clearField(3);
  @$pb.TagNumber(3)
  $1.IceCandidate ensureCandidate() => $_ensure(2);
}

class ClosePrivilegedPeerRequest extends $pb.GeneratedMessage {
  factory ClosePrivilegedPeerRequest({
    $core.List<$core.int>? leaseId,
    $fixnum.Int64? generation,
  }) {
    final result = create();
    if (leaseId != null) result.leaseId = leaseId;
    if (generation != null) result.generation = generation;
    return result;
  }

  ClosePrivilegedPeerRequest._();

  factory ClosePrivilegedPeerRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ClosePrivilegedPeerRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClosePrivilegedPeerRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'leaseId', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'generation', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClosePrivilegedPeerRequest clone() =>
      ClosePrivilegedPeerRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClosePrivilegedPeerRequest copyWith(
          void Function(ClosePrivilegedPeerRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ClosePrivilegedPeerRequest))
          as ClosePrivilegedPeerRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClosePrivilegedPeerRequest create() => ClosePrivilegedPeerRequest._();
  @$core.override
  ClosePrivilegedPeerRequest createEmptyInstance() => create();
  static $pb.PbList<ClosePrivilegedPeerRequest> createRepeated() =>
      $pb.PbList<ClosePrivilegedPeerRequest>();
  @$core.pragma('dart2js:noInline')
  static ClosePrivilegedPeerRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClosePrivilegedPeerRequest>(create);
  static ClosePrivilegedPeerRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get leaseId => $_getN(0);
  @$pb.TagNumber(1)
  set leaseId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLeaseId() => $_has(0);
  @$pb.TagNumber(1)
  void clearLeaseId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get generation => $_getI64(1);
  @$pb.TagNumber(2)
  set generation($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGeneration() => $_has(1);
  @$pb.TagNumber(2)
  void clearGeneration() => $_clearField(2);
}

class PrivilegedReliableInputEvent extends $pb.GeneratedMessage {
  factory PrivilegedReliableInputEvent({
    $core.List<$core.int>? leaseId,
    $fixnum.Int64? generation,
    $core.List<$core.int>? encodedEnvelope,
  }) {
    final result = create();
    if (leaseId != null) result.leaseId = leaseId;
    if (generation != null) result.generation = generation;
    if (encodedEnvelope != null) result.encodedEnvelope = encodedEnvelope;
    return result;
  }

  PrivilegedReliableInputEvent._();

  factory PrivilegedReliableInputEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PrivilegedReliableInputEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PrivilegedReliableInputEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'leaseId', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'generation', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'encodedEnvelope', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedReliableInputEvent clone() =>
      PrivilegedReliableInputEvent()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedReliableInputEvent copyWith(
          void Function(PrivilegedReliableInputEvent) updates) =>
      super.copyWith(
              (message) => updates(message as PrivilegedReliableInputEvent))
          as PrivilegedReliableInputEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PrivilegedReliableInputEvent create() =>
      PrivilegedReliableInputEvent._();
  @$core.override
  PrivilegedReliableInputEvent createEmptyInstance() => create();
  static $pb.PbList<PrivilegedReliableInputEvent> createRepeated() =>
      $pb.PbList<PrivilegedReliableInputEvent>();
  @$core.pragma('dart2js:noInline')
  static PrivilegedReliableInputEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PrivilegedReliableInputEvent>(create);
  static PrivilegedReliableInputEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get leaseId => $_getN(0);
  @$pb.TagNumber(1)
  set leaseId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLeaseId() => $_has(0);
  @$pb.TagNumber(1)
  void clearLeaseId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get generation => $_getI64(1);
  @$pb.TagNumber(2)
  set generation($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGeneration() => $_has(1);
  @$pb.TagNumber(2)
  void clearGeneration() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get encodedEnvelope => $_getN(2);
  @$pb.TagNumber(3)
  set encodedEnvelope($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEncodedEnvelope() => $_has(2);
  @$pb.TagNumber(3)
  void clearEncodedEnvelope() => $_clearField(3);
}

class PrivilegedFastPointerEvent extends $pb.GeneratedMessage {
  factory PrivilegedFastPointerEvent({
    $core.List<$core.int>? leaseId,
    $fixnum.Int64? generation,
    $core.List<$core.int>? encodedEnvelope,
  }) {
    final result = create();
    if (leaseId != null) result.leaseId = leaseId;
    if (generation != null) result.generation = generation;
    if (encodedEnvelope != null) result.encodedEnvelope = encodedEnvelope;
    return result;
  }

  PrivilegedFastPointerEvent._();

  factory PrivilegedFastPointerEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PrivilegedFastPointerEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PrivilegedFastPointerEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'leaseId', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'generation', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'encodedEnvelope', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedFastPointerEvent clone() =>
      PrivilegedFastPointerEvent()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedFastPointerEvent copyWith(
          void Function(PrivilegedFastPointerEvent) updates) =>
      super.copyWith(
              (message) => updates(message as PrivilegedFastPointerEvent))
          as PrivilegedFastPointerEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PrivilegedFastPointerEvent create() => PrivilegedFastPointerEvent._();
  @$core.override
  PrivilegedFastPointerEvent createEmptyInstance() => create();
  static $pb.PbList<PrivilegedFastPointerEvent> createRepeated() =>
      $pb.PbList<PrivilegedFastPointerEvent>();
  @$core.pragma('dart2js:noInline')
  static PrivilegedFastPointerEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PrivilegedFastPointerEvent>(create);
  static PrivilegedFastPointerEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get leaseId => $_getN(0);
  @$pb.TagNumber(1)
  set leaseId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLeaseId() => $_has(0);
  @$pb.TagNumber(1)
  void clearLeaseId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get generation => $_getI64(1);
  @$pb.TagNumber(2)
  set generation($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGeneration() => $_has(1);
  @$pb.TagNumber(2)
  void clearGeneration() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get encodedEnvelope => $_getN(2);
  @$pb.TagNumber(3)
  set encodedEnvelope($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEncodedEnvelope() => $_has(2);
  @$pb.TagNumber(3)
  void clearEncodedEnvelope() => $_clearField(3);
}

enum PrivilegedInputCommand_Input {
  pointerButton,
  keyboard,
  text,
  pointerMove,
  pointerScroll,
  releaseAll,
  notSet
}

class PrivilegedInputCommand extends $pb.GeneratedMessage {
  factory PrivilegedInputCommand({
    $core.List<$core.int>? leaseId,
    $fixnum.Int64? generation,
    $2.PointerButtonEvent? pointerButton,
    $2.KeyboardEvent? keyboard,
    $2.TextInputEvent? text,
    $2.PointerMoveEvent? pointerMove,
    $2.PointerScrollEvent? pointerScroll,
    $2.ReleaseAllInput? releaseAll,
  }) {
    final result = create();
    if (leaseId != null) result.leaseId = leaseId;
    if (generation != null) result.generation = generation;
    if (pointerButton != null) result.pointerButton = pointerButton;
    if (keyboard != null) result.keyboard = keyboard;
    if (text != null) result.text = text;
    if (pointerMove != null) result.pointerMove = pointerMove;
    if (pointerScroll != null) result.pointerScroll = pointerScroll;
    if (releaseAll != null) result.releaseAll = releaseAll;
    return result;
  }

  PrivilegedInputCommand._();

  factory PrivilegedInputCommand.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PrivilegedInputCommand.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, PrivilegedInputCommand_Input>
      _PrivilegedInputCommand_InputByTag = {
    10: PrivilegedInputCommand_Input.pointerButton,
    11: PrivilegedInputCommand_Input.keyboard,
    12: PrivilegedInputCommand_Input.text,
    13: PrivilegedInputCommand_Input.pointerMove,
    14: PrivilegedInputCommand_Input.pointerScroll,
    15: PrivilegedInputCommand_Input.releaseAll,
    0: PrivilegedInputCommand_Input.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PrivilegedInputCommand',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..oo(0, [10, 11, 12, 13, 14, 15])
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'leaseId', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'generation', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<$2.PointerButtonEvent>(10, _omitFieldNames ? '' : 'pointerButton',
        subBuilder: $2.PointerButtonEvent.create)
    ..aOM<$2.KeyboardEvent>(11, _omitFieldNames ? '' : 'keyboard',
        subBuilder: $2.KeyboardEvent.create)
    ..aOM<$2.TextInputEvent>(12, _omitFieldNames ? '' : 'text',
        subBuilder: $2.TextInputEvent.create)
    ..aOM<$2.PointerMoveEvent>(13, _omitFieldNames ? '' : 'pointerMove',
        subBuilder: $2.PointerMoveEvent.create)
    ..aOM<$2.PointerScrollEvent>(14, _omitFieldNames ? '' : 'pointerScroll',
        subBuilder: $2.PointerScrollEvent.create)
    ..aOM<$2.ReleaseAllInput>(15, _omitFieldNames ? '' : 'releaseAll',
        subBuilder: $2.ReleaseAllInput.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedInputCommand clone() =>
      PrivilegedInputCommand()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedInputCommand copyWith(
          void Function(PrivilegedInputCommand) updates) =>
      super.copyWith((message) => updates(message as PrivilegedInputCommand))
          as PrivilegedInputCommand;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PrivilegedInputCommand create() => PrivilegedInputCommand._();
  @$core.override
  PrivilegedInputCommand createEmptyInstance() => create();
  static $pb.PbList<PrivilegedInputCommand> createRepeated() =>
      $pb.PbList<PrivilegedInputCommand>();
  @$core.pragma('dart2js:noInline')
  static PrivilegedInputCommand getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PrivilegedInputCommand>(create);
  static PrivilegedInputCommand? _defaultInstance;

  PrivilegedInputCommand_Input whichInput() =>
      _PrivilegedInputCommand_InputByTag[$_whichOneof(0)]!;
  void clearInput() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.List<$core.int> get leaseId => $_getN(0);
  @$pb.TagNumber(1)
  set leaseId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLeaseId() => $_has(0);
  @$pb.TagNumber(1)
  void clearLeaseId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get generation => $_getI64(1);
  @$pb.TagNumber(2)
  set generation($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGeneration() => $_has(1);
  @$pb.TagNumber(2)
  void clearGeneration() => $_clearField(2);

  @$pb.TagNumber(10)
  $2.PointerButtonEvent get pointerButton => $_getN(2);
  @$pb.TagNumber(10)
  set pointerButton($2.PointerButtonEvent value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasPointerButton() => $_has(2);
  @$pb.TagNumber(10)
  void clearPointerButton() => $_clearField(10);
  @$pb.TagNumber(10)
  $2.PointerButtonEvent ensurePointerButton() => $_ensure(2);

  @$pb.TagNumber(11)
  $2.KeyboardEvent get keyboard => $_getN(3);
  @$pb.TagNumber(11)
  set keyboard($2.KeyboardEvent value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasKeyboard() => $_has(3);
  @$pb.TagNumber(11)
  void clearKeyboard() => $_clearField(11);
  @$pb.TagNumber(11)
  $2.KeyboardEvent ensureKeyboard() => $_ensure(3);

  @$pb.TagNumber(12)
  $2.TextInputEvent get text => $_getN(4);
  @$pb.TagNumber(12)
  set text($2.TextInputEvent value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasText() => $_has(4);
  @$pb.TagNumber(12)
  void clearText() => $_clearField(12);
  @$pb.TagNumber(12)
  $2.TextInputEvent ensureText() => $_ensure(4);

  @$pb.TagNumber(13)
  $2.PointerMoveEvent get pointerMove => $_getN(5);
  @$pb.TagNumber(13)
  set pointerMove($2.PointerMoveEvent value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasPointerMove() => $_has(5);
  @$pb.TagNumber(13)
  void clearPointerMove() => $_clearField(13);
  @$pb.TagNumber(13)
  $2.PointerMoveEvent ensurePointerMove() => $_ensure(5);

  @$pb.TagNumber(14)
  $2.PointerScrollEvent get pointerScroll => $_getN(6);
  @$pb.TagNumber(14)
  set pointerScroll($2.PointerScrollEvent value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasPointerScroll() => $_has(6);
  @$pb.TagNumber(14)
  void clearPointerScroll() => $_clearField(14);
  @$pb.TagNumber(14)
  $2.PointerScrollEvent ensurePointerScroll() => $_ensure(6);

  @$pb.TagNumber(15)
  $2.ReleaseAllInput get releaseAll => $_getN(7);
  @$pb.TagNumber(15)
  set releaseAll($2.ReleaseAllInput value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasReleaseAll() => $_has(7);
  @$pb.TagNumber(15)
  void clearReleaseAll() => $_clearField(15);
  @$pb.TagNumber(15)
  $2.ReleaseAllInput ensureReleaseAll() => $_ensure(7);
}

class SendSecureAttentionRequest extends $pb.GeneratedMessage {
  factory SendSecureAttentionRequest({
    $core.List<$core.int>? leaseId,
    $fixnum.Int64? generation,
  }) {
    final result = create();
    if (leaseId != null) result.leaseId = leaseId;
    if (generation != null) result.generation = generation;
    return result;
  }

  SendSecureAttentionRequest._();

  factory SendSecureAttentionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SendSecureAttentionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SendSecureAttentionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'leaseId', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'generation', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendSecureAttentionRequest clone() =>
      SendSecureAttentionRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendSecureAttentionRequest copyWith(
          void Function(SendSecureAttentionRequest) updates) =>
      super.copyWith(
              (message) => updates(message as SendSecureAttentionRequest))
          as SendSecureAttentionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SendSecureAttentionRequest create() => SendSecureAttentionRequest._();
  @$core.override
  SendSecureAttentionRequest createEmptyInstance() => create();
  static $pb.PbList<SendSecureAttentionRequest> createRepeated() =>
      $pb.PbList<SendSecureAttentionRequest>();
  @$core.pragma('dart2js:noInline')
  static SendSecureAttentionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SendSecureAttentionRequest>(create);
  static SendSecureAttentionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get leaseId => $_getN(0);
  @$pb.TagNumber(1)
  set leaseId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLeaseId() => $_has(0);
  @$pb.TagNumber(1)
  void clearLeaseId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get generation => $_getI64(1);
  @$pb.TagNumber(2)
  set generation($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGeneration() => $_has(1);
  @$pb.TagNumber(2)
  void clearGeneration() => $_clearField(2);
}

class RegisterPrivilegedHelperRequest extends $pb.GeneratedMessage {
  factory RegisterPrivilegedHelperRequest({
    PrivilegedSessionDescriptor? session,
  }) {
    final result = create();
    if (session != null) result.session = session;
    return result;
  }

  RegisterPrivilegedHelperRequest._();

  factory RegisterPrivilegedHelperRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RegisterPrivilegedHelperRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RegisterPrivilegedHelperRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..aOM<PrivilegedSessionDescriptor>(1, _omitFieldNames ? '' : 'session',
        subBuilder: PrivilegedSessionDescriptor.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterPrivilegedHelperRequest clone() =>
      RegisterPrivilegedHelperRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterPrivilegedHelperRequest copyWith(
          void Function(RegisterPrivilegedHelperRequest) updates) =>
      super.copyWith(
              (message) => updates(message as RegisterPrivilegedHelperRequest))
          as RegisterPrivilegedHelperRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RegisterPrivilegedHelperRequest create() =>
      RegisterPrivilegedHelperRequest._();
  @$core.override
  RegisterPrivilegedHelperRequest createEmptyInstance() => create();
  static $pb.PbList<RegisterPrivilegedHelperRequest> createRepeated() =>
      $pb.PbList<RegisterPrivilegedHelperRequest>();
  @$core.pragma('dart2js:noInline')
  static RegisterPrivilegedHelperRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RegisterPrivilegedHelperRequest>(
          create);
  static RegisterPrivilegedHelperRequest? _defaultInstance;

  @$pb.TagNumber(1)
  PrivilegedSessionDescriptor get session => $_getN(0);
  @$pb.TagNumber(1)
  set session(PrivilegedSessionDescriptor value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSession() => $_has(0);
  @$pb.TagNumber(1)
  void clearSession() => $_clearField(1);
  @$pb.TagNumber(1)
  PrivilegedSessionDescriptor ensureSession() => $_ensure(0);
}

class PrivilegedHelperRegistered extends $pb.GeneratedMessage {
  factory PrivilegedHelperRegistered({
    PrivilegedSessionDescriptor? session,
  }) {
    final result = create();
    if (session != null) result.session = session;
    return result;
  }

  PrivilegedHelperRegistered._();

  factory PrivilegedHelperRegistered.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PrivilegedHelperRegistered.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PrivilegedHelperRegistered',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..aOM<PrivilegedSessionDescriptor>(1, _omitFieldNames ? '' : 'session',
        subBuilder: PrivilegedSessionDescriptor.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedHelperRegistered clone() =>
      PrivilegedHelperRegistered()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedHelperRegistered copyWith(
          void Function(PrivilegedHelperRegistered) updates) =>
      super.copyWith(
              (message) => updates(message as PrivilegedHelperRegistered))
          as PrivilegedHelperRegistered;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PrivilegedHelperRegistered create() => PrivilegedHelperRegistered._();
  @$core.override
  PrivilegedHelperRegistered createEmptyInstance() => create();
  static $pb.PbList<PrivilegedHelperRegistered> createRepeated() =>
      $pb.PbList<PrivilegedHelperRegistered>();
  @$core.pragma('dart2js:noInline')
  static PrivilegedHelperRegistered getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PrivilegedHelperRegistered>(create);
  static PrivilegedHelperRegistered? _defaultInstance;

  @$pb.TagNumber(1)
  PrivilegedSessionDescriptor get session => $_getN(0);
  @$pb.TagNumber(1)
  set session(PrivilegedSessionDescriptor value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSession() => $_has(0);
  @$pb.TagNumber(1)
  void clearSession() => $_clearField(1);
  @$pb.TagNumber(1)
  PrivilegedSessionDescriptor ensureSession() => $_ensure(0);
}

class PrivilegedPeerStateChanged extends $pb.GeneratedMessage {
  factory PrivilegedPeerStateChanged({
    $core.List<$core.int>? leaseId,
    $fixnum.Int64? generation,
    PrivilegedPeerState? state,
  }) {
    final result = create();
    if (leaseId != null) result.leaseId = leaseId;
    if (generation != null) result.generation = generation;
    if (state != null) result.state = state;
    return result;
  }

  PrivilegedPeerStateChanged._();

  factory PrivilegedPeerStateChanged.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PrivilegedPeerStateChanged.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PrivilegedPeerStateChanged',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'leaseId', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'generation', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..e<PrivilegedPeerState>(
        3, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE,
        defaultOrMaker: PrivilegedPeerState.PRIVILEGED_PEER_STATE_UNSPECIFIED,
        valueOf: PrivilegedPeerState.valueOf,
        enumValues: PrivilegedPeerState.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedPeerStateChanged clone() =>
      PrivilegedPeerStateChanged()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedPeerStateChanged copyWith(
          void Function(PrivilegedPeerStateChanged) updates) =>
      super.copyWith(
              (message) => updates(message as PrivilegedPeerStateChanged))
          as PrivilegedPeerStateChanged;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PrivilegedPeerStateChanged create() => PrivilegedPeerStateChanged._();
  @$core.override
  PrivilegedPeerStateChanged createEmptyInstance() => create();
  static $pb.PbList<PrivilegedPeerStateChanged> createRepeated() =>
      $pb.PbList<PrivilegedPeerStateChanged>();
  @$core.pragma('dart2js:noInline')
  static PrivilegedPeerStateChanged getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PrivilegedPeerStateChanged>(create);
  static PrivilegedPeerStateChanged? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get leaseId => $_getN(0);
  @$pb.TagNumber(1)
  set leaseId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLeaseId() => $_has(0);
  @$pb.TagNumber(1)
  void clearLeaseId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get generation => $_getI64(1);
  @$pb.TagNumber(2)
  set generation($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGeneration() => $_has(1);
  @$pb.TagNumber(2)
  void clearGeneration() => $_clearField(2);

  @$pb.TagNumber(3)
  PrivilegedPeerState get state => $_getN(2);
  @$pb.TagNumber(3)
  set state(PrivilegedPeerState value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasState() => $_has(2);
  @$pb.TagNumber(3)
  void clearState() => $_clearField(3);
}

class PrivilegedPeerAnswer extends $pb.GeneratedMessage {
  factory PrivilegedPeerAnswer({
    $core.List<$core.int>? leaseId,
    $fixnum.Int64? generation,
    $1.WebRtcSessionDescription? answer,
  }) {
    final result = create();
    if (leaseId != null) result.leaseId = leaseId;
    if (generation != null) result.generation = generation;
    if (answer != null) result.answer = answer;
    return result;
  }

  PrivilegedPeerAnswer._();

  factory PrivilegedPeerAnswer.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PrivilegedPeerAnswer.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PrivilegedPeerAnswer',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'leaseId', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'generation', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<$1.WebRtcSessionDescription>(3, _omitFieldNames ? '' : 'answer',
        subBuilder: $1.WebRtcSessionDescription.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedPeerAnswer clone() =>
      PrivilegedPeerAnswer()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedPeerAnswer copyWith(void Function(PrivilegedPeerAnswer) updates) =>
      super.copyWith((message) => updates(message as PrivilegedPeerAnswer))
          as PrivilegedPeerAnswer;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PrivilegedPeerAnswer create() => PrivilegedPeerAnswer._();
  @$core.override
  PrivilegedPeerAnswer createEmptyInstance() => create();
  static $pb.PbList<PrivilegedPeerAnswer> createRepeated() =>
      $pb.PbList<PrivilegedPeerAnswer>();
  @$core.pragma('dart2js:noInline')
  static PrivilegedPeerAnswer getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PrivilegedPeerAnswer>(create);
  static PrivilegedPeerAnswer? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get leaseId => $_getN(0);
  @$pb.TagNumber(1)
  set leaseId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLeaseId() => $_has(0);
  @$pb.TagNumber(1)
  void clearLeaseId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get generation => $_getI64(1);
  @$pb.TagNumber(2)
  set generation($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGeneration() => $_has(1);
  @$pb.TagNumber(2)
  void clearGeneration() => $_clearField(2);

  @$pb.TagNumber(3)
  $1.WebRtcSessionDescription get answer => $_getN(2);
  @$pb.TagNumber(3)
  set answer($1.WebRtcSessionDescription value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAnswer() => $_has(2);
  @$pb.TagNumber(3)
  void clearAnswer() => $_clearField(3);
  @$pb.TagNumber(3)
  $1.WebRtcSessionDescription ensureAnswer() => $_ensure(2);
}

class PrivilegedLocalIceCandidate extends $pb.GeneratedMessage {
  factory PrivilegedLocalIceCandidate({
    $core.List<$core.int>? leaseId,
    $fixnum.Int64? generation,
    $1.IceCandidate? candidate,
  }) {
    final result = create();
    if (leaseId != null) result.leaseId = leaseId;
    if (generation != null) result.generation = generation;
    if (candidate != null) result.candidate = candidate;
    return result;
  }

  PrivilegedLocalIceCandidate._();

  factory PrivilegedLocalIceCandidate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PrivilegedLocalIceCandidate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PrivilegedLocalIceCandidate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'leaseId', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'generation', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<$1.IceCandidate>(3, _omitFieldNames ? '' : 'candidate',
        subBuilder: $1.IceCandidate.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedLocalIceCandidate clone() =>
      PrivilegedLocalIceCandidate()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedLocalIceCandidate copyWith(
          void Function(PrivilegedLocalIceCandidate) updates) =>
      super.copyWith(
              (message) => updates(message as PrivilegedLocalIceCandidate))
          as PrivilegedLocalIceCandidate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PrivilegedLocalIceCandidate create() =>
      PrivilegedLocalIceCandidate._();
  @$core.override
  PrivilegedLocalIceCandidate createEmptyInstance() => create();
  static $pb.PbList<PrivilegedLocalIceCandidate> createRepeated() =>
      $pb.PbList<PrivilegedLocalIceCandidate>();
  @$core.pragma('dart2js:noInline')
  static PrivilegedLocalIceCandidate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PrivilegedLocalIceCandidate>(create);
  static PrivilegedLocalIceCandidate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get leaseId => $_getN(0);
  @$pb.TagNumber(1)
  set leaseId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLeaseId() => $_has(0);
  @$pb.TagNumber(1)
  void clearLeaseId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get generation => $_getI64(1);
  @$pb.TagNumber(2)
  set generation($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGeneration() => $_has(1);
  @$pb.TagNumber(2)
  void clearGeneration() => $_clearField(2);

  @$pb.TagNumber(3)
  $1.IceCandidate get candidate => $_getN(2);
  @$pb.TagNumber(3)
  set candidate($1.IceCandidate value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCandidate() => $_has(2);
  @$pb.TagNumber(3)
  void clearCandidate() => $_clearField(3);
  @$pb.TagNumber(3)
  $1.IceCandidate ensureCandidate() => $_ensure(2);
}

class PrivilegedCommandAccepted extends $pb.GeneratedMessage {
  factory PrivilegedCommandAccepted({
    $core.List<$core.int>? leaseId,
    $fixnum.Int64? generation,
  }) {
    final result = create();
    if (leaseId != null) result.leaseId = leaseId;
    if (generation != null) result.generation = generation;
    return result;
  }

  PrivilegedCommandAccepted._();

  factory PrivilegedCommandAccepted.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PrivilegedCommandAccepted.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PrivilegedCommandAccepted',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'leaseId', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'generation', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedCommandAccepted clone() =>
      PrivilegedCommandAccepted()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedCommandAccepted copyWith(
          void Function(PrivilegedCommandAccepted) updates) =>
      super.copyWith((message) => updates(message as PrivilegedCommandAccepted))
          as PrivilegedCommandAccepted;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PrivilegedCommandAccepted create() => PrivilegedCommandAccepted._();
  @$core.override
  PrivilegedCommandAccepted createEmptyInstance() => create();
  static $pb.PbList<PrivilegedCommandAccepted> createRepeated() =>
      $pb.PbList<PrivilegedCommandAccepted>();
  @$core.pragma('dart2js:noInline')
  static PrivilegedCommandAccepted getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PrivilegedCommandAccepted>(create);
  static PrivilegedCommandAccepted? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get leaseId => $_getN(0);
  @$pb.TagNumber(1)
  set leaseId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLeaseId() => $_has(0);
  @$pb.TagNumber(1)
  void clearLeaseId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get generation => $_getI64(1);
  @$pb.TagNumber(2)
  set generation($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGeneration() => $_has(1);
  @$pb.TagNumber(2)
  void clearGeneration() => $_clearField(2);
}

enum PrivilegedBridgeClientFrame_Payload {
  authenticate,
  registerHelper,
  acquireLease,
  renewLease,
  releaseLease,
  startPeer,
  restartPeer,
  addIceCandidate,
  sendSecureAttention,
  inputCommand,
  closePeer,
  notSet
}

class PrivilegedBridgeClientFrame extends $pb.GeneratedMessage {
  factory PrivilegedBridgeClientFrame({
    $3.ProtocolVersion? protocolVersion,
    $core.String? requestId,
    $fixnum.Int64? sequence,
    PrivilegedBridgeAuthenticate? authenticate,
    RegisterPrivilegedHelperRequest? registerHelper,
    AcquirePrivilegedLeaseRequest? acquireLease,
    RenewPrivilegedLeaseRequest? renewLease,
    ReleasePrivilegedLeaseRequest? releaseLease,
    StartPrivilegedPeerRequest? startPeer,
    RestartPrivilegedPeerRequest? restartPeer,
    AddPrivilegedIceCandidateRequest? addIceCandidate,
    SendSecureAttentionRequest? sendSecureAttention,
    PrivilegedInputCommand? inputCommand,
    ClosePrivilegedPeerRequest? closePeer,
  }) {
    final result = create();
    if (protocolVersion != null) result.protocolVersion = protocolVersion;
    if (requestId != null) result.requestId = requestId;
    if (sequence != null) result.sequence = sequence;
    if (authenticate != null) result.authenticate = authenticate;
    if (registerHelper != null) result.registerHelper = registerHelper;
    if (acquireLease != null) result.acquireLease = acquireLease;
    if (renewLease != null) result.renewLease = renewLease;
    if (releaseLease != null) result.releaseLease = releaseLease;
    if (startPeer != null) result.startPeer = startPeer;
    if (restartPeer != null) result.restartPeer = restartPeer;
    if (addIceCandidate != null) result.addIceCandidate = addIceCandidate;
    if (sendSecureAttention != null)
      result.sendSecureAttention = sendSecureAttention;
    if (inputCommand != null) result.inputCommand = inputCommand;
    if (closePeer != null) result.closePeer = closePeer;
    return result;
  }

  PrivilegedBridgeClientFrame._();

  factory PrivilegedBridgeClientFrame.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PrivilegedBridgeClientFrame.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, PrivilegedBridgeClientFrame_Payload>
      _PrivilegedBridgeClientFrame_PayloadByTag = {
    10: PrivilegedBridgeClientFrame_Payload.authenticate,
    11: PrivilegedBridgeClientFrame_Payload.registerHelper,
    20: PrivilegedBridgeClientFrame_Payload.acquireLease,
    21: PrivilegedBridgeClientFrame_Payload.renewLease,
    22: PrivilegedBridgeClientFrame_Payload.releaseLease,
    23: PrivilegedBridgeClientFrame_Payload.startPeer,
    24: PrivilegedBridgeClientFrame_Payload.restartPeer,
    25: PrivilegedBridgeClientFrame_Payload.addIceCandidate,
    26: PrivilegedBridgeClientFrame_Payload.sendSecureAttention,
    27: PrivilegedBridgeClientFrame_Payload.inputCommand,
    28: PrivilegedBridgeClientFrame_Payload.closePeer,
    0: PrivilegedBridgeClientFrame_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PrivilegedBridgeClientFrame',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..oo(0, [10, 11, 20, 21, 22, 23, 24, 25, 26, 27, 28])
    ..aOM<$3.ProtocolVersion>(1, _omitFieldNames ? '' : 'protocolVersion',
        subBuilder: $3.ProtocolVersion.create)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'sequence', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<PrivilegedBridgeAuthenticate>(
        10, _omitFieldNames ? '' : 'authenticate',
        subBuilder: PrivilegedBridgeAuthenticate.create)
    ..aOM<RegisterPrivilegedHelperRequest>(
        11, _omitFieldNames ? '' : 'registerHelper',
        subBuilder: RegisterPrivilegedHelperRequest.create)
    ..aOM<AcquirePrivilegedLeaseRequest>(
        20, _omitFieldNames ? '' : 'acquireLease',
        subBuilder: AcquirePrivilegedLeaseRequest.create)
    ..aOM<RenewPrivilegedLeaseRequest>(21, _omitFieldNames ? '' : 'renewLease',
        subBuilder: RenewPrivilegedLeaseRequest.create)
    ..aOM<ReleasePrivilegedLeaseRequest>(
        22, _omitFieldNames ? '' : 'releaseLease',
        subBuilder: ReleasePrivilegedLeaseRequest.create)
    ..aOM<StartPrivilegedPeerRequest>(23, _omitFieldNames ? '' : 'startPeer',
        subBuilder: StartPrivilegedPeerRequest.create)
    ..aOM<RestartPrivilegedPeerRequest>(
        24, _omitFieldNames ? '' : 'restartPeer',
        subBuilder: RestartPrivilegedPeerRequest.create)
    ..aOM<AddPrivilegedIceCandidateRequest>(
        25, _omitFieldNames ? '' : 'addIceCandidate',
        subBuilder: AddPrivilegedIceCandidateRequest.create)
    ..aOM<SendSecureAttentionRequest>(
        26, _omitFieldNames ? '' : 'sendSecureAttention',
        subBuilder: SendSecureAttentionRequest.create)
    ..aOM<PrivilegedInputCommand>(27, _omitFieldNames ? '' : 'inputCommand',
        subBuilder: PrivilegedInputCommand.create)
    ..aOM<ClosePrivilegedPeerRequest>(28, _omitFieldNames ? '' : 'closePeer',
        subBuilder: ClosePrivilegedPeerRequest.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedBridgeClientFrame clone() =>
      PrivilegedBridgeClientFrame()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedBridgeClientFrame copyWith(
          void Function(PrivilegedBridgeClientFrame) updates) =>
      super.copyWith(
              (message) => updates(message as PrivilegedBridgeClientFrame))
          as PrivilegedBridgeClientFrame;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PrivilegedBridgeClientFrame create() =>
      PrivilegedBridgeClientFrame._();
  @$core.override
  PrivilegedBridgeClientFrame createEmptyInstance() => create();
  static $pb.PbList<PrivilegedBridgeClientFrame> createRepeated() =>
      $pb.PbList<PrivilegedBridgeClientFrame>();
  @$core.pragma('dart2js:noInline')
  static PrivilegedBridgeClientFrame getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PrivilegedBridgeClientFrame>(create);
  static PrivilegedBridgeClientFrame? _defaultInstance;

  PrivilegedBridgeClientFrame_Payload whichPayload() =>
      _PrivilegedBridgeClientFrame_PayloadByTag[$_whichOneof(0)]!;
  void clearPayload() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $3.ProtocolVersion get protocolVersion => $_getN(0);
  @$pb.TagNumber(1)
  set protocolVersion($3.ProtocolVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProtocolVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearProtocolVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  $3.ProtocolVersion ensureProtocolVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get requestId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRequestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get sequence => $_getI64(2);
  @$pb.TagNumber(3)
  set sequence($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSequence() => $_has(2);
  @$pb.TagNumber(3)
  void clearSequence() => $_clearField(3);

  @$pb.TagNumber(10)
  PrivilegedBridgeAuthenticate get authenticate => $_getN(3);
  @$pb.TagNumber(10)
  set authenticate(PrivilegedBridgeAuthenticate value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasAuthenticate() => $_has(3);
  @$pb.TagNumber(10)
  void clearAuthenticate() => $_clearField(10);
  @$pb.TagNumber(10)
  PrivilegedBridgeAuthenticate ensureAuthenticate() => $_ensure(3);

  @$pb.TagNumber(11)
  RegisterPrivilegedHelperRequest get registerHelper => $_getN(4);
  @$pb.TagNumber(11)
  set registerHelper(RegisterPrivilegedHelperRequest value) =>
      $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasRegisterHelper() => $_has(4);
  @$pb.TagNumber(11)
  void clearRegisterHelper() => $_clearField(11);
  @$pb.TagNumber(11)
  RegisterPrivilegedHelperRequest ensureRegisterHelper() => $_ensure(4);

  @$pb.TagNumber(20)
  AcquirePrivilegedLeaseRequest get acquireLease => $_getN(5);
  @$pb.TagNumber(20)
  set acquireLease(AcquirePrivilegedLeaseRequest value) =>
      $_setField(20, value);
  @$pb.TagNumber(20)
  $core.bool hasAcquireLease() => $_has(5);
  @$pb.TagNumber(20)
  void clearAcquireLease() => $_clearField(20);
  @$pb.TagNumber(20)
  AcquirePrivilegedLeaseRequest ensureAcquireLease() => $_ensure(5);

  @$pb.TagNumber(21)
  RenewPrivilegedLeaseRequest get renewLease => $_getN(6);
  @$pb.TagNumber(21)
  set renewLease(RenewPrivilegedLeaseRequest value) => $_setField(21, value);
  @$pb.TagNumber(21)
  $core.bool hasRenewLease() => $_has(6);
  @$pb.TagNumber(21)
  void clearRenewLease() => $_clearField(21);
  @$pb.TagNumber(21)
  RenewPrivilegedLeaseRequest ensureRenewLease() => $_ensure(6);

  @$pb.TagNumber(22)
  ReleasePrivilegedLeaseRequest get releaseLease => $_getN(7);
  @$pb.TagNumber(22)
  set releaseLease(ReleasePrivilegedLeaseRequest value) =>
      $_setField(22, value);
  @$pb.TagNumber(22)
  $core.bool hasReleaseLease() => $_has(7);
  @$pb.TagNumber(22)
  void clearReleaseLease() => $_clearField(22);
  @$pb.TagNumber(22)
  ReleasePrivilegedLeaseRequest ensureReleaseLease() => $_ensure(7);

  @$pb.TagNumber(23)
  StartPrivilegedPeerRequest get startPeer => $_getN(8);
  @$pb.TagNumber(23)
  set startPeer(StartPrivilegedPeerRequest value) => $_setField(23, value);
  @$pb.TagNumber(23)
  $core.bool hasStartPeer() => $_has(8);
  @$pb.TagNumber(23)
  void clearStartPeer() => $_clearField(23);
  @$pb.TagNumber(23)
  StartPrivilegedPeerRequest ensureStartPeer() => $_ensure(8);

  @$pb.TagNumber(24)
  RestartPrivilegedPeerRequest get restartPeer => $_getN(9);
  @$pb.TagNumber(24)
  set restartPeer(RestartPrivilegedPeerRequest value) => $_setField(24, value);
  @$pb.TagNumber(24)
  $core.bool hasRestartPeer() => $_has(9);
  @$pb.TagNumber(24)
  void clearRestartPeer() => $_clearField(24);
  @$pb.TagNumber(24)
  RestartPrivilegedPeerRequest ensureRestartPeer() => $_ensure(9);

  @$pb.TagNumber(25)
  AddPrivilegedIceCandidateRequest get addIceCandidate => $_getN(10);
  @$pb.TagNumber(25)
  set addIceCandidate(AddPrivilegedIceCandidateRequest value) =>
      $_setField(25, value);
  @$pb.TagNumber(25)
  $core.bool hasAddIceCandidate() => $_has(10);
  @$pb.TagNumber(25)
  void clearAddIceCandidate() => $_clearField(25);
  @$pb.TagNumber(25)
  AddPrivilegedIceCandidateRequest ensureAddIceCandidate() => $_ensure(10);

  @$pb.TagNumber(26)
  SendSecureAttentionRequest get sendSecureAttention => $_getN(11);
  @$pb.TagNumber(26)
  set sendSecureAttention(SendSecureAttentionRequest value) =>
      $_setField(26, value);
  @$pb.TagNumber(26)
  $core.bool hasSendSecureAttention() => $_has(11);
  @$pb.TagNumber(26)
  void clearSendSecureAttention() => $_clearField(26);
  @$pb.TagNumber(26)
  SendSecureAttentionRequest ensureSendSecureAttention() => $_ensure(11);

  @$pb.TagNumber(27)
  PrivilegedInputCommand get inputCommand => $_getN(12);
  @$pb.TagNumber(27)
  set inputCommand(PrivilegedInputCommand value) => $_setField(27, value);
  @$pb.TagNumber(27)
  $core.bool hasInputCommand() => $_has(12);
  @$pb.TagNumber(27)
  void clearInputCommand() => $_clearField(27);
  @$pb.TagNumber(27)
  PrivilegedInputCommand ensureInputCommand() => $_ensure(12);

  @$pb.TagNumber(28)
  ClosePrivilegedPeerRequest get closePeer => $_getN(13);
  @$pb.TagNumber(28)
  set closePeer(ClosePrivilegedPeerRequest value) => $_setField(28, value);
  @$pb.TagNumber(28)
  $core.bool hasClosePeer() => $_has(13);
  @$pb.TagNumber(28)
  void clearClosePeer() => $_clearField(28);
  @$pb.TagNumber(28)
  ClosePrivilegedPeerRequest ensureClosePeer() => $_ensure(13);
}

enum PrivilegedBridgeServerFrame_Payload {
  challenge,
  authenticated,
  helperRegistered,
  status,
  lease,
  peerAnswer,
  localIceCandidate,
  peerStateChanged,
  reliableInput,
  fastPointer,
  commandAccepted,
  error,
  notSet
}

class PrivilegedBridgeServerFrame extends $pb.GeneratedMessage {
  factory PrivilegedBridgeServerFrame({
    $3.ProtocolVersion? protocolVersion,
    $core.String? requestId,
    $fixnum.Int64? sequence,
    PrivilegedBridgeChallenge? challenge,
    PrivilegedBridgeAuthenticated? authenticated,
    PrivilegedHelperRegistered? helperRegistered,
    PrivilegedBridgeStatusSnapshot? status,
    PrivilegedLease? lease,
    PrivilegedPeerAnswer? peerAnswer,
    PrivilegedLocalIceCandidate? localIceCandidate,
    PrivilegedPeerStateChanged? peerStateChanged,
    PrivilegedReliableInputEvent? reliableInput,
    PrivilegedFastPointerEvent? fastPointer,
    PrivilegedCommandAccepted? commandAccepted,
    $0.UnifiedError? error,
  }) {
    final result = create();
    if (protocolVersion != null) result.protocolVersion = protocolVersion;
    if (requestId != null) result.requestId = requestId;
    if (sequence != null) result.sequence = sequence;
    if (challenge != null) result.challenge = challenge;
    if (authenticated != null) result.authenticated = authenticated;
    if (helperRegistered != null) result.helperRegistered = helperRegistered;
    if (status != null) result.status = status;
    if (lease != null) result.lease = lease;
    if (peerAnswer != null) result.peerAnswer = peerAnswer;
    if (localIceCandidate != null) result.localIceCandidate = localIceCandidate;
    if (peerStateChanged != null) result.peerStateChanged = peerStateChanged;
    if (reliableInput != null) result.reliableInput = reliableInput;
    if (fastPointer != null) result.fastPointer = fastPointer;
    if (commandAccepted != null) result.commandAccepted = commandAccepted;
    if (error != null) result.error = error;
    return result;
  }

  PrivilegedBridgeServerFrame._();

  factory PrivilegedBridgeServerFrame.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PrivilegedBridgeServerFrame.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, PrivilegedBridgeServerFrame_Payload>
      _PrivilegedBridgeServerFrame_PayloadByTag = {
    10: PrivilegedBridgeServerFrame_Payload.challenge,
    11: PrivilegedBridgeServerFrame_Payload.authenticated,
    12: PrivilegedBridgeServerFrame_Payload.helperRegistered,
    20: PrivilegedBridgeServerFrame_Payload.status,
    21: PrivilegedBridgeServerFrame_Payload.lease,
    22: PrivilegedBridgeServerFrame_Payload.peerAnswer,
    23: PrivilegedBridgeServerFrame_Payload.localIceCandidate,
    24: PrivilegedBridgeServerFrame_Payload.peerStateChanged,
    25: PrivilegedBridgeServerFrame_Payload.reliableInput,
    26: PrivilegedBridgeServerFrame_Payload.fastPointer,
    27: PrivilegedBridgeServerFrame_Payload.commandAccepted,
    29: PrivilegedBridgeServerFrame_Payload.error,
    0: PrivilegedBridgeServerFrame_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PrivilegedBridgeServerFrame',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..oo(0, [10, 11, 12, 20, 21, 22, 23, 24, 25, 26, 27, 29])
    ..aOM<$3.ProtocolVersion>(1, _omitFieldNames ? '' : 'protocolVersion',
        subBuilder: $3.ProtocolVersion.create)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'sequence', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<PrivilegedBridgeChallenge>(10, _omitFieldNames ? '' : 'challenge',
        subBuilder: PrivilegedBridgeChallenge.create)
    ..aOM<PrivilegedBridgeAuthenticated>(
        11, _omitFieldNames ? '' : 'authenticated',
        subBuilder: PrivilegedBridgeAuthenticated.create)
    ..aOM<PrivilegedHelperRegistered>(
        12, _omitFieldNames ? '' : 'helperRegistered',
        subBuilder: PrivilegedHelperRegistered.create)
    ..aOM<PrivilegedBridgeStatusSnapshot>(20, _omitFieldNames ? '' : 'status',
        subBuilder: PrivilegedBridgeStatusSnapshot.create)
    ..aOM<PrivilegedLease>(21, _omitFieldNames ? '' : 'lease',
        subBuilder: PrivilegedLease.create)
    ..aOM<PrivilegedPeerAnswer>(22, _omitFieldNames ? '' : 'peerAnswer',
        subBuilder: PrivilegedPeerAnswer.create)
    ..aOM<PrivilegedLocalIceCandidate>(
        23, _omitFieldNames ? '' : 'localIceCandidate',
        subBuilder: PrivilegedLocalIceCandidate.create)
    ..aOM<PrivilegedPeerStateChanged>(
        24, _omitFieldNames ? '' : 'peerStateChanged',
        subBuilder: PrivilegedPeerStateChanged.create)
    ..aOM<PrivilegedReliableInputEvent>(
        25, _omitFieldNames ? '' : 'reliableInput',
        subBuilder: PrivilegedReliableInputEvent.create)
    ..aOM<PrivilegedFastPointerEvent>(26, _omitFieldNames ? '' : 'fastPointer',
        subBuilder: PrivilegedFastPointerEvent.create)
    ..aOM<PrivilegedCommandAccepted>(
        27, _omitFieldNames ? '' : 'commandAccepted',
        subBuilder: PrivilegedCommandAccepted.create)
    ..aOM<$0.UnifiedError>(29, _omitFieldNames ? '' : 'error',
        subBuilder: $0.UnifiedError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedBridgeServerFrame clone() =>
      PrivilegedBridgeServerFrame()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrivilegedBridgeServerFrame copyWith(
          void Function(PrivilegedBridgeServerFrame) updates) =>
      super.copyWith(
              (message) => updates(message as PrivilegedBridgeServerFrame))
          as PrivilegedBridgeServerFrame;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PrivilegedBridgeServerFrame create() =>
      PrivilegedBridgeServerFrame._();
  @$core.override
  PrivilegedBridgeServerFrame createEmptyInstance() => create();
  static $pb.PbList<PrivilegedBridgeServerFrame> createRepeated() =>
      $pb.PbList<PrivilegedBridgeServerFrame>();
  @$core.pragma('dart2js:noInline')
  static PrivilegedBridgeServerFrame getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PrivilegedBridgeServerFrame>(create);
  static PrivilegedBridgeServerFrame? _defaultInstance;

  PrivilegedBridgeServerFrame_Payload whichPayload() =>
      _PrivilegedBridgeServerFrame_PayloadByTag[$_whichOneof(0)]!;
  void clearPayload() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $3.ProtocolVersion get protocolVersion => $_getN(0);
  @$pb.TagNumber(1)
  set protocolVersion($3.ProtocolVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProtocolVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearProtocolVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  $3.ProtocolVersion ensureProtocolVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get requestId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRequestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get sequence => $_getI64(2);
  @$pb.TagNumber(3)
  set sequence($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSequence() => $_has(2);
  @$pb.TagNumber(3)
  void clearSequence() => $_clearField(3);

  @$pb.TagNumber(10)
  PrivilegedBridgeChallenge get challenge => $_getN(3);
  @$pb.TagNumber(10)
  set challenge(PrivilegedBridgeChallenge value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasChallenge() => $_has(3);
  @$pb.TagNumber(10)
  void clearChallenge() => $_clearField(10);
  @$pb.TagNumber(10)
  PrivilegedBridgeChallenge ensureChallenge() => $_ensure(3);

  @$pb.TagNumber(11)
  PrivilegedBridgeAuthenticated get authenticated => $_getN(4);
  @$pb.TagNumber(11)
  set authenticated(PrivilegedBridgeAuthenticated value) =>
      $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasAuthenticated() => $_has(4);
  @$pb.TagNumber(11)
  void clearAuthenticated() => $_clearField(11);
  @$pb.TagNumber(11)
  PrivilegedBridgeAuthenticated ensureAuthenticated() => $_ensure(4);

  @$pb.TagNumber(12)
  PrivilegedHelperRegistered get helperRegistered => $_getN(5);
  @$pb.TagNumber(12)
  set helperRegistered(PrivilegedHelperRegistered value) =>
      $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasHelperRegistered() => $_has(5);
  @$pb.TagNumber(12)
  void clearHelperRegistered() => $_clearField(12);
  @$pb.TagNumber(12)
  PrivilegedHelperRegistered ensureHelperRegistered() => $_ensure(5);

  @$pb.TagNumber(20)
  PrivilegedBridgeStatusSnapshot get status => $_getN(6);
  @$pb.TagNumber(20)
  set status(PrivilegedBridgeStatusSnapshot value) => $_setField(20, value);
  @$pb.TagNumber(20)
  $core.bool hasStatus() => $_has(6);
  @$pb.TagNumber(20)
  void clearStatus() => $_clearField(20);
  @$pb.TagNumber(20)
  PrivilegedBridgeStatusSnapshot ensureStatus() => $_ensure(6);

  @$pb.TagNumber(21)
  PrivilegedLease get lease => $_getN(7);
  @$pb.TagNumber(21)
  set lease(PrivilegedLease value) => $_setField(21, value);
  @$pb.TagNumber(21)
  $core.bool hasLease() => $_has(7);
  @$pb.TagNumber(21)
  void clearLease() => $_clearField(21);
  @$pb.TagNumber(21)
  PrivilegedLease ensureLease() => $_ensure(7);

  @$pb.TagNumber(22)
  PrivilegedPeerAnswer get peerAnswer => $_getN(8);
  @$pb.TagNumber(22)
  set peerAnswer(PrivilegedPeerAnswer value) => $_setField(22, value);
  @$pb.TagNumber(22)
  $core.bool hasPeerAnswer() => $_has(8);
  @$pb.TagNumber(22)
  void clearPeerAnswer() => $_clearField(22);
  @$pb.TagNumber(22)
  PrivilegedPeerAnswer ensurePeerAnswer() => $_ensure(8);

  @$pb.TagNumber(23)
  PrivilegedLocalIceCandidate get localIceCandidate => $_getN(9);
  @$pb.TagNumber(23)
  set localIceCandidate(PrivilegedLocalIceCandidate value) =>
      $_setField(23, value);
  @$pb.TagNumber(23)
  $core.bool hasLocalIceCandidate() => $_has(9);
  @$pb.TagNumber(23)
  void clearLocalIceCandidate() => $_clearField(23);
  @$pb.TagNumber(23)
  PrivilegedLocalIceCandidate ensureLocalIceCandidate() => $_ensure(9);

  @$pb.TagNumber(24)
  PrivilegedPeerStateChanged get peerStateChanged => $_getN(10);
  @$pb.TagNumber(24)
  set peerStateChanged(PrivilegedPeerStateChanged value) =>
      $_setField(24, value);
  @$pb.TagNumber(24)
  $core.bool hasPeerStateChanged() => $_has(10);
  @$pb.TagNumber(24)
  void clearPeerStateChanged() => $_clearField(24);
  @$pb.TagNumber(24)
  PrivilegedPeerStateChanged ensurePeerStateChanged() => $_ensure(10);

  @$pb.TagNumber(25)
  PrivilegedReliableInputEvent get reliableInput => $_getN(11);
  @$pb.TagNumber(25)
  set reliableInput(PrivilegedReliableInputEvent value) =>
      $_setField(25, value);
  @$pb.TagNumber(25)
  $core.bool hasReliableInput() => $_has(11);
  @$pb.TagNumber(25)
  void clearReliableInput() => $_clearField(25);
  @$pb.TagNumber(25)
  PrivilegedReliableInputEvent ensureReliableInput() => $_ensure(11);

  @$pb.TagNumber(26)
  PrivilegedFastPointerEvent get fastPointer => $_getN(12);
  @$pb.TagNumber(26)
  set fastPointer(PrivilegedFastPointerEvent value) => $_setField(26, value);
  @$pb.TagNumber(26)
  $core.bool hasFastPointer() => $_has(12);
  @$pb.TagNumber(26)
  void clearFastPointer() => $_clearField(26);
  @$pb.TagNumber(26)
  PrivilegedFastPointerEvent ensureFastPointer() => $_ensure(12);

  @$pb.TagNumber(27)
  PrivilegedCommandAccepted get commandAccepted => $_getN(13);
  @$pb.TagNumber(27)
  set commandAccepted(PrivilegedCommandAccepted value) => $_setField(27, value);
  @$pb.TagNumber(27)
  $core.bool hasCommandAccepted() => $_has(13);
  @$pb.TagNumber(27)
  void clearCommandAccepted() => $_clearField(27);
  @$pb.TagNumber(27)
  PrivilegedCommandAccepted ensureCommandAccepted() => $_ensure(13);

  @$pb.TagNumber(29)
  $0.UnifiedError get error => $_getN(14);
  @$pb.TagNumber(29)
  set error($0.UnifiedError value) => $_setField(29, value);
  @$pb.TagNumber(29)
  $core.bool hasError() => $_has(14);
  @$pb.TagNumber(29)
  void clearError() => $_clearField(29);
  @$pb.TagNumber(29)
  $0.UnifiedError ensureError() => $_ensure(14);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
