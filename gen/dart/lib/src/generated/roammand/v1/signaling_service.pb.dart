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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'error.pb.dart' as $1;
import 'signaling_service.pbenum.dart';
import 'version.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'signaling_service.pbenum.dart';

class RegisterDevice extends $pb.GeneratedMessage {
  factory RegisterDevice({
    $core.List<$core.int>? deviceId,
  }) {
    final result = create();
    if (deviceId != null) result.deviceId = deviceId;
    return result;
  }

  RegisterDevice._();

  factory RegisterDevice.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RegisterDevice.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RegisterDevice',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'deviceId', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterDevice clone() => RegisterDevice()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterDevice copyWith(void Function(RegisterDevice) updates) =>
      super.copyWith((message) => updates(message as RegisterDevice))
          as RegisterDevice;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RegisterDevice create() => RegisterDevice._();
  @$core.override
  RegisterDevice createEmptyInstance() => create();
  static $pb.PbList<RegisterDevice> createRepeated() =>
      $pb.PbList<RegisterDevice>();
  @$core.pragma('dart2js:noInline')
  static RegisterDevice getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RegisterDevice>(create);
  static RegisterDevice? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get deviceId => $_getN(0);
  @$pb.TagNumber(1)
  set deviceId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => $_clearField(1);
}

class RegistrationAccepted extends $pb.GeneratedMessage {
  factory RegistrationAccepted({
    $core.List<$core.int>? deviceId,
    $fixnum.Int64? presenceExpiresAtUnixMs,
  }) {
    final result = create();
    if (deviceId != null) result.deviceId = deviceId;
    if (presenceExpiresAtUnixMs != null)
      result.presenceExpiresAtUnixMs = presenceExpiresAtUnixMs;
    return result;
  }

  RegistrationAccepted._();

  factory RegistrationAccepted.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RegistrationAccepted.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RegistrationAccepted',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'deviceId', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'presenceExpiresAtUnixMs',
        $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegistrationAccepted clone() =>
      RegistrationAccepted()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegistrationAccepted copyWith(void Function(RegistrationAccepted) updates) =>
      super.copyWith((message) => updates(message as RegistrationAccepted))
          as RegistrationAccepted;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RegistrationAccepted create() => RegistrationAccepted._();
  @$core.override
  RegistrationAccepted createEmptyInstance() => create();
  static $pb.PbList<RegistrationAccepted> createRepeated() =>
      $pb.PbList<RegistrationAccepted>();
  @$core.pragma('dart2js:noInline')
  static RegistrationAccepted getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RegistrationAccepted>(create);
  static RegistrationAccepted? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get deviceId => $_getN(0);
  @$pb.TagNumber(1)
  set deviceId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get presenceExpiresAtUnixMs => $_getI64(1);
  @$pb.TagNumber(2)
  set presenceExpiresAtUnixMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPresenceExpiresAtUnixMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearPresenceExpiresAtUnixMs() => $_clearField(2);
}

class Heartbeat extends $pb.GeneratedMessage {
  factory Heartbeat() => create();

  Heartbeat._();

  factory Heartbeat.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Heartbeat.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Heartbeat',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Heartbeat clone() => Heartbeat()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Heartbeat copyWith(void Function(Heartbeat) updates) =>
      super.copyWith((message) => updates(message as Heartbeat)) as Heartbeat;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Heartbeat create() => Heartbeat._();
  @$core.override
  Heartbeat createEmptyInstance() => create();
  static $pb.PbList<Heartbeat> createRepeated() => $pb.PbList<Heartbeat>();
  @$core.pragma('dart2js:noInline')
  static Heartbeat getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Heartbeat>(create);
  static Heartbeat? _defaultInstance;
}

class HeartbeatAcknowledged extends $pb.GeneratedMessage {
  factory HeartbeatAcknowledged({
    $fixnum.Int64? serverTimeUnixMs,
    $fixnum.Int64? presenceExpiresAtUnixMs,
  }) {
    final result = create();
    if (serverTimeUnixMs != null) result.serverTimeUnixMs = serverTimeUnixMs;
    if (presenceExpiresAtUnixMs != null)
      result.presenceExpiresAtUnixMs = presenceExpiresAtUnixMs;
    return result;
  }

  HeartbeatAcknowledged._();

  factory HeartbeatAcknowledged.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HeartbeatAcknowledged.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HeartbeatAcknowledged',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'serverTimeUnixMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'presenceExpiresAtUnixMs',
        $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HeartbeatAcknowledged clone() =>
      HeartbeatAcknowledged()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HeartbeatAcknowledged copyWith(
          void Function(HeartbeatAcknowledged) updates) =>
      super.copyWith((message) => updates(message as HeartbeatAcknowledged))
          as HeartbeatAcknowledged;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HeartbeatAcknowledged create() => HeartbeatAcknowledged._();
  @$core.override
  HeartbeatAcknowledged createEmptyInstance() => create();
  static $pb.PbList<HeartbeatAcknowledged> createRepeated() =>
      $pb.PbList<HeartbeatAcknowledged>();
  @$core.pragma('dart2js:noInline')
  static HeartbeatAcknowledged getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HeartbeatAcknowledged>(create);
  static HeartbeatAcknowledged? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get serverTimeUnixMs => $_getI64(0);
  @$pb.TagNumber(1)
  set serverTimeUnixMs($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerTimeUnixMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerTimeUnixMs() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get presenceExpiresAtUnixMs => $_getI64(1);
  @$pb.TagNumber(2)
  set presenceExpiresAtUnixMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPresenceExpiresAtUnixMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearPresenceExpiresAtUnixMs() => $_clearField(2);
}

class PresenceQuery extends $pb.GeneratedMessage {
  factory PresenceQuery({
    $core.List<$core.int>? deviceId,
  }) {
    final result = create();
    if (deviceId != null) result.deviceId = deviceId;
    return result;
  }

  PresenceQuery._();

  factory PresenceQuery.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PresenceQuery.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PresenceQuery',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'deviceId', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PresenceQuery clone() => PresenceQuery()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PresenceQuery copyWith(void Function(PresenceQuery) updates) =>
      super.copyWith((message) => updates(message as PresenceQuery))
          as PresenceQuery;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PresenceQuery create() => PresenceQuery._();
  @$core.override
  PresenceQuery createEmptyInstance() => create();
  static $pb.PbList<PresenceQuery> createRepeated() =>
      $pb.PbList<PresenceQuery>();
  @$core.pragma('dart2js:noInline')
  static PresenceQuery getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PresenceQuery>(create);
  static PresenceQuery? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get deviceId => $_getN(0);
  @$pb.TagNumber(1)
  set deviceId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => $_clearField(1);
}

class PresenceResult extends $pb.GeneratedMessage {
  factory PresenceResult({
    $core.List<$core.int>? deviceId,
    $core.bool? online,
  }) {
    final result = create();
    if (deviceId != null) result.deviceId = deviceId;
    if (online != null) result.online = online;
    return result;
  }

  PresenceResult._();

  factory PresenceResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PresenceResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PresenceResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'deviceId', $pb.PbFieldType.OY)
    ..aOB(2, _omitFieldNames ? '' : 'online')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PresenceResult clone() => PresenceResult()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PresenceResult copyWith(void Function(PresenceResult) updates) =>
      super.copyWith((message) => updates(message as PresenceResult))
          as PresenceResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PresenceResult create() => PresenceResult._();
  @$core.override
  PresenceResult createEmptyInstance() => create();
  static $pb.PbList<PresenceResult> createRepeated() =>
      $pb.PbList<PresenceResult>();
  @$core.pragma('dart2js:noInline')
  static PresenceResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PresenceResult>(create);
  static PresenceResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get deviceId => $_getN(0);
  @$pb.TagNumber(1)
  set deviceId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get online => $_getBF(1);
  @$pb.TagNumber(2)
  set online($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOnline() => $_has(1);
  @$pb.TagNumber(2)
  void clearOnline() => $_clearField(2);
}

class CreatePairingRendezvous extends $pb.GeneratedMessage {
  factory CreatePairingRendezvous({
    $core.List<$core.int>? rendezvousId,
    PairingRendezvousKind? kind,
    $core.String? pairingCode,
  }) {
    final result = create();
    if (rendezvousId != null) result.rendezvousId = rendezvousId;
    if (kind != null) result.kind = kind;
    if (pairingCode != null) result.pairingCode = pairingCode;
    return result;
  }

  CreatePairingRendezvous._();

  factory CreatePairingRendezvous.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreatePairingRendezvous.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreatePairingRendezvous',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'rendezvousId', $pb.PbFieldType.OY)
    ..e<PairingRendezvousKind>(
        2, _omitFieldNames ? '' : 'kind', $pb.PbFieldType.OE,
        defaultOrMaker:
            PairingRendezvousKind.PAIRING_RENDEZVOUS_KIND_UNSPECIFIED,
        valueOf: PairingRendezvousKind.valueOf,
        enumValues: PairingRendezvousKind.values)
    ..aOS(3, _omitFieldNames ? '' : 'pairingCode')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreatePairingRendezvous clone() =>
      CreatePairingRendezvous()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreatePairingRendezvous copyWith(
          void Function(CreatePairingRendezvous) updates) =>
      super.copyWith((message) => updates(message as CreatePairingRendezvous))
          as CreatePairingRendezvous;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreatePairingRendezvous create() => CreatePairingRendezvous._();
  @$core.override
  CreatePairingRendezvous createEmptyInstance() => create();
  static $pb.PbList<CreatePairingRendezvous> createRepeated() =>
      $pb.PbList<CreatePairingRendezvous>();
  @$core.pragma('dart2js:noInline')
  static CreatePairingRendezvous getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreatePairingRendezvous>(create);
  static CreatePairingRendezvous? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get rendezvousId => $_getN(0);
  @$pb.TagNumber(1)
  set rendezvousId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRendezvousId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRendezvousId() => $_clearField(1);

  @$pb.TagNumber(2)
  PairingRendezvousKind get kind => $_getN(1);
  @$pb.TagNumber(2)
  set kind(PairingRendezvousKind value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get pairingCode => $_getSZ(2);
  @$pb.TagNumber(3)
  set pairingCode($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPairingCode() => $_has(2);
  @$pb.TagNumber(3)
  void clearPairingCode() => $_clearField(3);
}

class PairingRendezvousCreated extends $pb.GeneratedMessage {
  factory PairingRendezvousCreated({
    $core.List<$core.int>? rendezvousId,
    PairingRendezvousKind? kind,
    $fixnum.Int64? expiresAtUnixMs,
  }) {
    final result = create();
    if (rendezvousId != null) result.rendezvousId = rendezvousId;
    if (kind != null) result.kind = kind;
    if (expiresAtUnixMs != null) result.expiresAtUnixMs = expiresAtUnixMs;
    return result;
  }

  PairingRendezvousCreated._();

  factory PairingRendezvousCreated.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PairingRendezvousCreated.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PairingRendezvousCreated',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'rendezvousId', $pb.PbFieldType.OY)
    ..e<PairingRendezvousKind>(
        2, _omitFieldNames ? '' : 'kind', $pb.PbFieldType.OE,
        defaultOrMaker:
            PairingRendezvousKind.PAIRING_RENDEZVOUS_KIND_UNSPECIFIED,
        valueOf: PairingRendezvousKind.valueOf,
        enumValues: PairingRendezvousKind.values)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'expiresAtUnixMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingRendezvousCreated clone() =>
      PairingRendezvousCreated()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingRendezvousCreated copyWith(
          void Function(PairingRendezvousCreated) updates) =>
      super.copyWith((message) => updates(message as PairingRendezvousCreated))
          as PairingRendezvousCreated;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PairingRendezvousCreated create() => PairingRendezvousCreated._();
  @$core.override
  PairingRendezvousCreated createEmptyInstance() => create();
  static $pb.PbList<PairingRendezvousCreated> createRepeated() =>
      $pb.PbList<PairingRendezvousCreated>();
  @$core.pragma('dart2js:noInline')
  static PairingRendezvousCreated getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PairingRendezvousCreated>(create);
  static PairingRendezvousCreated? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get rendezvousId => $_getN(0);
  @$pb.TagNumber(1)
  set rendezvousId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRendezvousId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRendezvousId() => $_clearField(1);

  @$pb.TagNumber(2)
  PairingRendezvousKind get kind => $_getN(1);
  @$pb.TagNumber(2)
  set kind(PairingRendezvousKind value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get expiresAtUnixMs => $_getI64(2);
  @$pb.TagNumber(3)
  set expiresAtUnixMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasExpiresAtUnixMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearExpiresAtUnixMs() => $_clearField(3);
}

enum JoinPairingRendezvous_Lookup { rendezvousId, pairingCode, notSet }

class JoinPairingRendezvous extends $pb.GeneratedMessage {
  factory JoinPairingRendezvous({
    $core.List<$core.int>? rendezvousId,
    $core.String? pairingCode,
  }) {
    final result = create();
    if (rendezvousId != null) result.rendezvousId = rendezvousId;
    if (pairingCode != null) result.pairingCode = pairingCode;
    return result;
  }

  JoinPairingRendezvous._();

  factory JoinPairingRendezvous.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory JoinPairingRendezvous.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, JoinPairingRendezvous_Lookup>
      _JoinPairingRendezvous_LookupByTag = {
    1: JoinPairingRendezvous_Lookup.rendezvousId,
    2: JoinPairingRendezvous_Lookup.pairingCode,
    0: JoinPairingRendezvous_Lookup.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'JoinPairingRendezvous',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'rendezvousId', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'pairingCode')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JoinPairingRendezvous clone() =>
      JoinPairingRendezvous()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JoinPairingRendezvous copyWith(
          void Function(JoinPairingRendezvous) updates) =>
      super.copyWith((message) => updates(message as JoinPairingRendezvous))
          as JoinPairingRendezvous;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static JoinPairingRendezvous create() => JoinPairingRendezvous._();
  @$core.override
  JoinPairingRendezvous createEmptyInstance() => create();
  static $pb.PbList<JoinPairingRendezvous> createRepeated() =>
      $pb.PbList<JoinPairingRendezvous>();
  @$core.pragma('dart2js:noInline')
  static JoinPairingRendezvous getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<JoinPairingRendezvous>(create);
  static JoinPairingRendezvous? _defaultInstance;

  JoinPairingRendezvous_Lookup whichLookup() =>
      _JoinPairingRendezvous_LookupByTag[$_whichOneof(0)]!;
  void clearLookup() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.List<$core.int> get rendezvousId => $_getN(0);
  @$pb.TagNumber(1)
  set rendezvousId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRendezvousId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRendezvousId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get pairingCode => $_getSZ(1);
  @$pb.TagNumber(2)
  set pairingCode($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPairingCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearPairingCode() => $_clearField(2);
}

class PairingRendezvousJoined extends $pb.GeneratedMessage {
  factory PairingRendezvousJoined({
    $core.List<$core.int>? rendezvousId,
    $core.List<$core.int>? peerDeviceId,
    $fixnum.Int64? expiresAtUnixMs,
  }) {
    final result = create();
    if (rendezvousId != null) result.rendezvousId = rendezvousId;
    if (peerDeviceId != null) result.peerDeviceId = peerDeviceId;
    if (expiresAtUnixMs != null) result.expiresAtUnixMs = expiresAtUnixMs;
    return result;
  }

  PairingRendezvousJoined._();

  factory PairingRendezvousJoined.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PairingRendezvousJoined.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PairingRendezvousJoined',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'rendezvousId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'peerDeviceId', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'expiresAtUnixMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingRendezvousJoined clone() =>
      PairingRendezvousJoined()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingRendezvousJoined copyWith(
          void Function(PairingRendezvousJoined) updates) =>
      super.copyWith((message) => updates(message as PairingRendezvousJoined))
          as PairingRendezvousJoined;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PairingRendezvousJoined create() => PairingRendezvousJoined._();
  @$core.override
  PairingRendezvousJoined createEmptyInstance() => create();
  static $pb.PbList<PairingRendezvousJoined> createRepeated() =>
      $pb.PbList<PairingRendezvousJoined>();
  @$core.pragma('dart2js:noInline')
  static PairingRendezvousJoined getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PairingRendezvousJoined>(create);
  static PairingRendezvousJoined? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get rendezvousId => $_getN(0);
  @$pb.TagNumber(1)
  set rendezvousId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRendezvousId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRendezvousId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get peerDeviceId => $_getN(1);
  @$pb.TagNumber(2)
  set peerDeviceId($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPeerDeviceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPeerDeviceId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get expiresAtUnixMs => $_getI64(2);
  @$pb.TagNumber(3)
  set expiresAtUnixMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasExpiresAtUnixMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearExpiresAtUnixMs() => $_clearField(3);
}

class RelayPairingEnvelope extends $pb.GeneratedMessage {
  factory RelayPairingEnvelope({
    $core.List<$core.int>? rendezvousId,
    $core.List<$core.int>? opaqueEnvelope,
  }) {
    final result = create();
    if (rendezvousId != null) result.rendezvousId = rendezvousId;
    if (opaqueEnvelope != null) result.opaqueEnvelope = opaqueEnvelope;
    return result;
  }

  RelayPairingEnvelope._();

  factory RelayPairingEnvelope.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RelayPairingEnvelope.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RelayPairingEnvelope',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'rendezvousId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'opaqueEnvelope', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RelayPairingEnvelope clone() =>
      RelayPairingEnvelope()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RelayPairingEnvelope copyWith(void Function(RelayPairingEnvelope) updates) =>
      super.copyWith((message) => updates(message as RelayPairingEnvelope))
          as RelayPairingEnvelope;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RelayPairingEnvelope create() => RelayPairingEnvelope._();
  @$core.override
  RelayPairingEnvelope createEmptyInstance() => create();
  static $pb.PbList<RelayPairingEnvelope> createRepeated() =>
      $pb.PbList<RelayPairingEnvelope>();
  @$core.pragma('dart2js:noInline')
  static RelayPairingEnvelope getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RelayPairingEnvelope>(create);
  static RelayPairingEnvelope? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get rendezvousId => $_getN(0);
  @$pb.TagNumber(1)
  set rendezvousId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRendezvousId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRendezvousId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get opaqueEnvelope => $_getN(1);
  @$pb.TagNumber(2)
  set opaqueEnvelope($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOpaqueEnvelope() => $_has(1);
  @$pb.TagNumber(2)
  void clearOpaqueEnvelope() => $_clearField(2);
}

class RoutedPairingEnvelope extends $pb.GeneratedMessage {
  factory RoutedPairingEnvelope({
    $core.List<$core.int>? rendezvousId,
    $core.List<$core.int>? senderDeviceId,
    $core.List<$core.int>? opaqueEnvelope,
  }) {
    final result = create();
    if (rendezvousId != null) result.rendezvousId = rendezvousId;
    if (senderDeviceId != null) result.senderDeviceId = senderDeviceId;
    if (opaqueEnvelope != null) result.opaqueEnvelope = opaqueEnvelope;
    return result;
  }

  RoutedPairingEnvelope._();

  factory RoutedPairingEnvelope.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RoutedPairingEnvelope.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RoutedPairingEnvelope',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'rendezvousId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'senderDeviceId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'opaqueEnvelope', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoutedPairingEnvelope clone() =>
      RoutedPairingEnvelope()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoutedPairingEnvelope copyWith(
          void Function(RoutedPairingEnvelope) updates) =>
      super.copyWith((message) => updates(message as RoutedPairingEnvelope))
          as RoutedPairingEnvelope;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RoutedPairingEnvelope create() => RoutedPairingEnvelope._();
  @$core.override
  RoutedPairingEnvelope createEmptyInstance() => create();
  static $pb.PbList<RoutedPairingEnvelope> createRepeated() =>
      $pb.PbList<RoutedPairingEnvelope>();
  @$core.pragma('dart2js:noInline')
  static RoutedPairingEnvelope getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RoutedPairingEnvelope>(create);
  static RoutedPairingEnvelope? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get rendezvousId => $_getN(0);
  @$pb.TagNumber(1)
  set rendezvousId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRendezvousId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRendezvousId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get senderDeviceId => $_getN(1);
  @$pb.TagNumber(2)
  set senderDeviceId($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSenderDeviceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSenderDeviceId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get opaqueEnvelope => $_getN(2);
  @$pb.TagNumber(3)
  set opaqueEnvelope($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOpaqueEnvelope() => $_has(2);
  @$pb.TagNumber(3)
  void clearOpaqueEnvelope() => $_clearField(3);
}

class CompletePairingRendezvous extends $pb.GeneratedMessage {
  factory CompletePairingRendezvous({
    $core.List<$core.int>? rendezvousId,
    PairingRendezvousCompletion? completion,
  }) {
    final result = create();
    if (rendezvousId != null) result.rendezvousId = rendezvousId;
    if (completion != null) result.completion = completion;
    return result;
  }

  CompletePairingRendezvous._();

  factory CompletePairingRendezvous.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CompletePairingRendezvous.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CompletePairingRendezvous',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'rendezvousId', $pb.PbFieldType.OY)
    ..e<PairingRendezvousCompletion>(
        2, _omitFieldNames ? '' : 'completion', $pb.PbFieldType.OE,
        defaultOrMaker: PairingRendezvousCompletion
            .PAIRING_RENDEZVOUS_COMPLETION_UNSPECIFIED,
        valueOf: PairingRendezvousCompletion.valueOf,
        enumValues: PairingRendezvousCompletion.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompletePairingRendezvous clone() =>
      CompletePairingRendezvous()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompletePairingRendezvous copyWith(
          void Function(CompletePairingRendezvous) updates) =>
      super.copyWith((message) => updates(message as CompletePairingRendezvous))
          as CompletePairingRendezvous;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CompletePairingRendezvous create() => CompletePairingRendezvous._();
  @$core.override
  CompletePairingRendezvous createEmptyInstance() => create();
  static $pb.PbList<CompletePairingRendezvous> createRepeated() =>
      $pb.PbList<CompletePairingRendezvous>();
  @$core.pragma('dart2js:noInline')
  static CompletePairingRendezvous getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CompletePairingRendezvous>(create);
  static CompletePairingRendezvous? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get rendezvousId => $_getN(0);
  @$pb.TagNumber(1)
  set rendezvousId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRendezvousId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRendezvousId() => $_clearField(1);

  @$pb.TagNumber(2)
  PairingRendezvousCompletion get completion => $_getN(1);
  @$pb.TagNumber(2)
  set completion(PairingRendezvousCompletion value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasCompletion() => $_has(1);
  @$pb.TagNumber(2)
  void clearCompletion() => $_clearField(2);
}

class PairingRendezvousClosed extends $pb.GeneratedMessage {
  factory PairingRendezvousClosed({
    $core.List<$core.int>? rendezvousId,
    PairingRendezvousCompletion? completion,
  }) {
    final result = create();
    if (rendezvousId != null) result.rendezvousId = rendezvousId;
    if (completion != null) result.completion = completion;
    return result;
  }

  PairingRendezvousClosed._();

  factory PairingRendezvousClosed.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PairingRendezvousClosed.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PairingRendezvousClosed',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'rendezvousId', $pb.PbFieldType.OY)
    ..e<PairingRendezvousCompletion>(
        2, _omitFieldNames ? '' : 'completion', $pb.PbFieldType.OE,
        defaultOrMaker: PairingRendezvousCompletion
            .PAIRING_RENDEZVOUS_COMPLETION_UNSPECIFIED,
        valueOf: PairingRendezvousCompletion.valueOf,
        enumValues: PairingRendezvousCompletion.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingRendezvousClosed clone() =>
      PairingRendezvousClosed()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingRendezvousClosed copyWith(
          void Function(PairingRendezvousClosed) updates) =>
      super.copyWith((message) => updates(message as PairingRendezvousClosed))
          as PairingRendezvousClosed;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PairingRendezvousClosed create() => PairingRendezvousClosed._();
  @$core.override
  PairingRendezvousClosed createEmptyInstance() => create();
  static $pb.PbList<PairingRendezvousClosed> createRepeated() =>
      $pb.PbList<PairingRendezvousClosed>();
  @$core.pragma('dart2js:noInline')
  static PairingRendezvousClosed getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PairingRendezvousClosed>(create);
  static PairingRendezvousClosed? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get rendezvousId => $_getN(0);
  @$pb.TagNumber(1)
  set rendezvousId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRendezvousId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRendezvousId() => $_clearField(1);

  @$pb.TagNumber(2)
  PairingRendezvousCompletion get completion => $_getN(1);
  @$pb.TagNumber(2)
  set completion(PairingRendezvousCompletion value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasCompletion() => $_has(1);
  @$pb.TagNumber(2)
  void clearCompletion() => $_clearField(2);
}

class RelaySessionEnvelope extends $pb.GeneratedMessage {
  factory RelaySessionEnvelope({
    $core.List<$core.int>? recipientDeviceId,
    $core.List<$core.int>? opaqueEnvelope,
  }) {
    final result = create();
    if (recipientDeviceId != null) result.recipientDeviceId = recipientDeviceId;
    if (opaqueEnvelope != null) result.opaqueEnvelope = opaqueEnvelope;
    return result;
  }

  RelaySessionEnvelope._();

  factory RelaySessionEnvelope.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RelaySessionEnvelope.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RelaySessionEnvelope',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'recipientDeviceId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'opaqueEnvelope', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RelaySessionEnvelope clone() =>
      RelaySessionEnvelope()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RelaySessionEnvelope copyWith(void Function(RelaySessionEnvelope) updates) =>
      super.copyWith((message) => updates(message as RelaySessionEnvelope))
          as RelaySessionEnvelope;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RelaySessionEnvelope create() => RelaySessionEnvelope._();
  @$core.override
  RelaySessionEnvelope createEmptyInstance() => create();
  static $pb.PbList<RelaySessionEnvelope> createRepeated() =>
      $pb.PbList<RelaySessionEnvelope>();
  @$core.pragma('dart2js:noInline')
  static RelaySessionEnvelope getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RelaySessionEnvelope>(create);
  static RelaySessionEnvelope? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get recipientDeviceId => $_getN(0);
  @$pb.TagNumber(1)
  set recipientDeviceId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRecipientDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRecipientDeviceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get opaqueEnvelope => $_getN(1);
  @$pb.TagNumber(2)
  set opaqueEnvelope($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOpaqueEnvelope() => $_has(1);
  @$pb.TagNumber(2)
  void clearOpaqueEnvelope() => $_clearField(2);
}

class RoutedSessionEnvelope extends $pb.GeneratedMessage {
  factory RoutedSessionEnvelope({
    $core.List<$core.int>? senderDeviceId,
    $core.List<$core.int>? opaqueEnvelope,
  }) {
    final result = create();
    if (senderDeviceId != null) result.senderDeviceId = senderDeviceId;
    if (opaqueEnvelope != null) result.opaqueEnvelope = opaqueEnvelope;
    return result;
  }

  RoutedSessionEnvelope._();

  factory RoutedSessionEnvelope.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RoutedSessionEnvelope.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RoutedSessionEnvelope',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'senderDeviceId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'opaqueEnvelope', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoutedSessionEnvelope clone() =>
      RoutedSessionEnvelope()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoutedSessionEnvelope copyWith(
          void Function(RoutedSessionEnvelope) updates) =>
      super.copyWith((message) => updates(message as RoutedSessionEnvelope))
          as RoutedSessionEnvelope;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RoutedSessionEnvelope create() => RoutedSessionEnvelope._();
  @$core.override
  RoutedSessionEnvelope createEmptyInstance() => create();
  static $pb.PbList<RoutedSessionEnvelope> createRepeated() =>
      $pb.PbList<RoutedSessionEnvelope>();
  @$core.pragma('dart2js:noInline')
  static RoutedSessionEnvelope getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RoutedSessionEnvelope>(create);
  static RoutedSessionEnvelope? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get senderDeviceId => $_getN(0);
  @$pb.TagNumber(1)
  set senderDeviceId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSenderDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSenderDeviceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get opaqueEnvelope => $_getN(1);
  @$pb.TagNumber(2)
  set opaqueEnvelope($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOpaqueEnvelope() => $_has(1);
  @$pb.TagNumber(2)
  void clearOpaqueEnvelope() => $_clearField(2);
}

enum SignalingClientFrame_Payload {
  register,
  heartbeat,
  presenceQuery,
  createRendezvous,
  joinRendezvous,
  relayPairing,
  completeRendezvous,
  relaySession,
  notSet
}

class SignalingClientFrame extends $pb.GeneratedMessage {
  factory SignalingClientFrame({
    $0.ProtocolVersion? protocolVersion,
    $core.String? requestId,
    RegisterDevice? register,
    Heartbeat? heartbeat,
    PresenceQuery? presenceQuery,
    CreatePairingRendezvous? createRendezvous,
    JoinPairingRendezvous? joinRendezvous,
    RelayPairingEnvelope? relayPairing,
    CompletePairingRendezvous? completeRendezvous,
    RelaySessionEnvelope? relaySession,
  }) {
    final result = create();
    if (protocolVersion != null) result.protocolVersion = protocolVersion;
    if (requestId != null) result.requestId = requestId;
    if (register != null) result.register = register;
    if (heartbeat != null) result.heartbeat = heartbeat;
    if (presenceQuery != null) result.presenceQuery = presenceQuery;
    if (createRendezvous != null) result.createRendezvous = createRendezvous;
    if (joinRendezvous != null) result.joinRendezvous = joinRendezvous;
    if (relayPairing != null) result.relayPairing = relayPairing;
    if (completeRendezvous != null)
      result.completeRendezvous = completeRendezvous;
    if (relaySession != null) result.relaySession = relaySession;
    return result;
  }

  SignalingClientFrame._();

  factory SignalingClientFrame.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SignalingClientFrame.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, SignalingClientFrame_Payload>
      _SignalingClientFrame_PayloadByTag = {
    10: SignalingClientFrame_Payload.register,
    11: SignalingClientFrame_Payload.heartbeat,
    12: SignalingClientFrame_Payload.presenceQuery,
    13: SignalingClientFrame_Payload.createRendezvous,
    14: SignalingClientFrame_Payload.joinRendezvous,
    15: SignalingClientFrame_Payload.relayPairing,
    16: SignalingClientFrame_Payload.completeRendezvous,
    17: SignalingClientFrame_Payload.relaySession,
    0: SignalingClientFrame_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SignalingClientFrame',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..oo(0, [10, 11, 12, 13, 14, 15, 16, 17])
    ..aOM<$0.ProtocolVersion>(1, _omitFieldNames ? '' : 'protocolVersion',
        subBuilder: $0.ProtocolVersion.create)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..aOM<RegisterDevice>(10, _omitFieldNames ? '' : 'register',
        subBuilder: RegisterDevice.create)
    ..aOM<Heartbeat>(11, _omitFieldNames ? '' : 'heartbeat',
        subBuilder: Heartbeat.create)
    ..aOM<PresenceQuery>(12, _omitFieldNames ? '' : 'presenceQuery',
        subBuilder: PresenceQuery.create)
    ..aOM<CreatePairingRendezvous>(
        13, _omitFieldNames ? '' : 'createRendezvous',
        subBuilder: CreatePairingRendezvous.create)
    ..aOM<JoinPairingRendezvous>(14, _omitFieldNames ? '' : 'joinRendezvous',
        subBuilder: JoinPairingRendezvous.create)
    ..aOM<RelayPairingEnvelope>(15, _omitFieldNames ? '' : 'relayPairing',
        subBuilder: RelayPairingEnvelope.create)
    ..aOM<CompletePairingRendezvous>(
        16, _omitFieldNames ? '' : 'completeRendezvous',
        subBuilder: CompletePairingRendezvous.create)
    ..aOM<RelaySessionEnvelope>(17, _omitFieldNames ? '' : 'relaySession',
        subBuilder: RelaySessionEnvelope.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SignalingClientFrame clone() =>
      SignalingClientFrame()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SignalingClientFrame copyWith(void Function(SignalingClientFrame) updates) =>
      super.copyWith((message) => updates(message as SignalingClientFrame))
          as SignalingClientFrame;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SignalingClientFrame create() => SignalingClientFrame._();
  @$core.override
  SignalingClientFrame createEmptyInstance() => create();
  static $pb.PbList<SignalingClientFrame> createRepeated() =>
      $pb.PbList<SignalingClientFrame>();
  @$core.pragma('dart2js:noInline')
  static SignalingClientFrame getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SignalingClientFrame>(create);
  static SignalingClientFrame? _defaultInstance;

  SignalingClientFrame_Payload whichPayload() =>
      _SignalingClientFrame_PayloadByTag[$_whichOneof(0)]!;
  void clearPayload() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $0.ProtocolVersion get protocolVersion => $_getN(0);
  @$pb.TagNumber(1)
  set protocolVersion($0.ProtocolVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProtocolVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearProtocolVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.ProtocolVersion ensureProtocolVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get requestId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRequestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestId() => $_clearField(2);

  @$pb.TagNumber(10)
  RegisterDevice get register => $_getN(2);
  @$pb.TagNumber(10)
  set register(RegisterDevice value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasRegister() => $_has(2);
  @$pb.TagNumber(10)
  void clearRegister() => $_clearField(10);
  @$pb.TagNumber(10)
  RegisterDevice ensureRegister() => $_ensure(2);

  @$pb.TagNumber(11)
  Heartbeat get heartbeat => $_getN(3);
  @$pb.TagNumber(11)
  set heartbeat(Heartbeat value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasHeartbeat() => $_has(3);
  @$pb.TagNumber(11)
  void clearHeartbeat() => $_clearField(11);
  @$pb.TagNumber(11)
  Heartbeat ensureHeartbeat() => $_ensure(3);

  @$pb.TagNumber(12)
  PresenceQuery get presenceQuery => $_getN(4);
  @$pb.TagNumber(12)
  set presenceQuery(PresenceQuery value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasPresenceQuery() => $_has(4);
  @$pb.TagNumber(12)
  void clearPresenceQuery() => $_clearField(12);
  @$pb.TagNumber(12)
  PresenceQuery ensurePresenceQuery() => $_ensure(4);

  @$pb.TagNumber(13)
  CreatePairingRendezvous get createRendezvous => $_getN(5);
  @$pb.TagNumber(13)
  set createRendezvous(CreatePairingRendezvous value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasCreateRendezvous() => $_has(5);
  @$pb.TagNumber(13)
  void clearCreateRendezvous() => $_clearField(13);
  @$pb.TagNumber(13)
  CreatePairingRendezvous ensureCreateRendezvous() => $_ensure(5);

  @$pb.TagNumber(14)
  JoinPairingRendezvous get joinRendezvous => $_getN(6);
  @$pb.TagNumber(14)
  set joinRendezvous(JoinPairingRendezvous value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasJoinRendezvous() => $_has(6);
  @$pb.TagNumber(14)
  void clearJoinRendezvous() => $_clearField(14);
  @$pb.TagNumber(14)
  JoinPairingRendezvous ensureJoinRendezvous() => $_ensure(6);

  @$pb.TagNumber(15)
  RelayPairingEnvelope get relayPairing => $_getN(7);
  @$pb.TagNumber(15)
  set relayPairing(RelayPairingEnvelope value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasRelayPairing() => $_has(7);
  @$pb.TagNumber(15)
  void clearRelayPairing() => $_clearField(15);
  @$pb.TagNumber(15)
  RelayPairingEnvelope ensureRelayPairing() => $_ensure(7);

  @$pb.TagNumber(16)
  CompletePairingRendezvous get completeRendezvous => $_getN(8);
  @$pb.TagNumber(16)
  set completeRendezvous(CompletePairingRendezvous value) =>
      $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasCompleteRendezvous() => $_has(8);
  @$pb.TagNumber(16)
  void clearCompleteRendezvous() => $_clearField(16);
  @$pb.TagNumber(16)
  CompletePairingRendezvous ensureCompleteRendezvous() => $_ensure(8);

  @$pb.TagNumber(17)
  RelaySessionEnvelope get relaySession => $_getN(9);
  @$pb.TagNumber(17)
  set relaySession(RelaySessionEnvelope value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasRelaySession() => $_has(9);
  @$pb.TagNumber(17)
  void clearRelaySession() => $_clearField(17);
  @$pb.TagNumber(17)
  RelaySessionEnvelope ensureRelaySession() => $_ensure(9);
}

enum SignalingServerFrame_Payload {
  registered,
  heartbeatAcknowledged,
  presenceResult,
  rendezvousCreated,
  rendezvousJoined,
  routedPairing,
  rendezvousClosed,
  routedSession,
  error,
  notSet
}

class SignalingServerFrame extends $pb.GeneratedMessage {
  factory SignalingServerFrame({
    $0.ProtocolVersion? protocolVersion,
    $core.String? requestId,
    RegistrationAccepted? registered,
    HeartbeatAcknowledged? heartbeatAcknowledged,
    PresenceResult? presenceResult,
    PairingRendezvousCreated? rendezvousCreated,
    PairingRendezvousJoined? rendezvousJoined,
    RoutedPairingEnvelope? routedPairing,
    PairingRendezvousClosed? rendezvousClosed,
    RoutedSessionEnvelope? routedSession,
    $1.UnifiedError? error,
  }) {
    final result = create();
    if (protocolVersion != null) result.protocolVersion = protocolVersion;
    if (requestId != null) result.requestId = requestId;
    if (registered != null) result.registered = registered;
    if (heartbeatAcknowledged != null)
      result.heartbeatAcknowledged = heartbeatAcknowledged;
    if (presenceResult != null) result.presenceResult = presenceResult;
    if (rendezvousCreated != null) result.rendezvousCreated = rendezvousCreated;
    if (rendezvousJoined != null) result.rendezvousJoined = rendezvousJoined;
    if (routedPairing != null) result.routedPairing = routedPairing;
    if (rendezvousClosed != null) result.rendezvousClosed = rendezvousClosed;
    if (routedSession != null) result.routedSession = routedSession;
    if (error != null) result.error = error;
    return result;
  }

  SignalingServerFrame._();

  factory SignalingServerFrame.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SignalingServerFrame.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, SignalingServerFrame_Payload>
      _SignalingServerFrame_PayloadByTag = {
    10: SignalingServerFrame_Payload.registered,
    11: SignalingServerFrame_Payload.heartbeatAcknowledged,
    12: SignalingServerFrame_Payload.presenceResult,
    13: SignalingServerFrame_Payload.rendezvousCreated,
    14: SignalingServerFrame_Payload.rendezvousJoined,
    15: SignalingServerFrame_Payload.routedPairing,
    16: SignalingServerFrame_Payload.rendezvousClosed,
    17: SignalingServerFrame_Payload.routedSession,
    18: SignalingServerFrame_Payload.error,
    0: SignalingServerFrame_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SignalingServerFrame',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..oo(0, [10, 11, 12, 13, 14, 15, 16, 17, 18])
    ..aOM<$0.ProtocolVersion>(1, _omitFieldNames ? '' : 'protocolVersion',
        subBuilder: $0.ProtocolVersion.create)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..aOM<RegistrationAccepted>(10, _omitFieldNames ? '' : 'registered',
        subBuilder: RegistrationAccepted.create)
    ..aOM<HeartbeatAcknowledged>(
        11, _omitFieldNames ? '' : 'heartbeatAcknowledged',
        subBuilder: HeartbeatAcknowledged.create)
    ..aOM<PresenceResult>(12, _omitFieldNames ? '' : 'presenceResult',
        subBuilder: PresenceResult.create)
    ..aOM<PairingRendezvousCreated>(
        13, _omitFieldNames ? '' : 'rendezvousCreated',
        subBuilder: PairingRendezvousCreated.create)
    ..aOM<PairingRendezvousJoined>(
        14, _omitFieldNames ? '' : 'rendezvousJoined',
        subBuilder: PairingRendezvousJoined.create)
    ..aOM<RoutedPairingEnvelope>(15, _omitFieldNames ? '' : 'routedPairing',
        subBuilder: RoutedPairingEnvelope.create)
    ..aOM<PairingRendezvousClosed>(
        16, _omitFieldNames ? '' : 'rendezvousClosed',
        subBuilder: PairingRendezvousClosed.create)
    ..aOM<RoutedSessionEnvelope>(17, _omitFieldNames ? '' : 'routedSession',
        subBuilder: RoutedSessionEnvelope.create)
    ..aOM<$1.UnifiedError>(18, _omitFieldNames ? '' : 'error',
        subBuilder: $1.UnifiedError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SignalingServerFrame clone() =>
      SignalingServerFrame()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SignalingServerFrame copyWith(void Function(SignalingServerFrame) updates) =>
      super.copyWith((message) => updates(message as SignalingServerFrame))
          as SignalingServerFrame;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SignalingServerFrame create() => SignalingServerFrame._();
  @$core.override
  SignalingServerFrame createEmptyInstance() => create();
  static $pb.PbList<SignalingServerFrame> createRepeated() =>
      $pb.PbList<SignalingServerFrame>();
  @$core.pragma('dart2js:noInline')
  static SignalingServerFrame getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SignalingServerFrame>(create);
  static SignalingServerFrame? _defaultInstance;

  SignalingServerFrame_Payload whichPayload() =>
      _SignalingServerFrame_PayloadByTag[$_whichOneof(0)]!;
  void clearPayload() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $0.ProtocolVersion get protocolVersion => $_getN(0);
  @$pb.TagNumber(1)
  set protocolVersion($0.ProtocolVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProtocolVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearProtocolVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.ProtocolVersion ensureProtocolVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get requestId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRequestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestId() => $_clearField(2);

  @$pb.TagNumber(10)
  RegistrationAccepted get registered => $_getN(2);
  @$pb.TagNumber(10)
  set registered(RegistrationAccepted value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasRegistered() => $_has(2);
  @$pb.TagNumber(10)
  void clearRegistered() => $_clearField(10);
  @$pb.TagNumber(10)
  RegistrationAccepted ensureRegistered() => $_ensure(2);

  @$pb.TagNumber(11)
  HeartbeatAcknowledged get heartbeatAcknowledged => $_getN(3);
  @$pb.TagNumber(11)
  set heartbeatAcknowledged(HeartbeatAcknowledged value) =>
      $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasHeartbeatAcknowledged() => $_has(3);
  @$pb.TagNumber(11)
  void clearHeartbeatAcknowledged() => $_clearField(11);
  @$pb.TagNumber(11)
  HeartbeatAcknowledged ensureHeartbeatAcknowledged() => $_ensure(3);

  @$pb.TagNumber(12)
  PresenceResult get presenceResult => $_getN(4);
  @$pb.TagNumber(12)
  set presenceResult(PresenceResult value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasPresenceResult() => $_has(4);
  @$pb.TagNumber(12)
  void clearPresenceResult() => $_clearField(12);
  @$pb.TagNumber(12)
  PresenceResult ensurePresenceResult() => $_ensure(4);

  @$pb.TagNumber(13)
  PairingRendezvousCreated get rendezvousCreated => $_getN(5);
  @$pb.TagNumber(13)
  set rendezvousCreated(PairingRendezvousCreated value) =>
      $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasRendezvousCreated() => $_has(5);
  @$pb.TagNumber(13)
  void clearRendezvousCreated() => $_clearField(13);
  @$pb.TagNumber(13)
  PairingRendezvousCreated ensureRendezvousCreated() => $_ensure(5);

  @$pb.TagNumber(14)
  PairingRendezvousJoined get rendezvousJoined => $_getN(6);
  @$pb.TagNumber(14)
  set rendezvousJoined(PairingRendezvousJoined value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasRendezvousJoined() => $_has(6);
  @$pb.TagNumber(14)
  void clearRendezvousJoined() => $_clearField(14);
  @$pb.TagNumber(14)
  PairingRendezvousJoined ensureRendezvousJoined() => $_ensure(6);

  @$pb.TagNumber(15)
  RoutedPairingEnvelope get routedPairing => $_getN(7);
  @$pb.TagNumber(15)
  set routedPairing(RoutedPairingEnvelope value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasRoutedPairing() => $_has(7);
  @$pb.TagNumber(15)
  void clearRoutedPairing() => $_clearField(15);
  @$pb.TagNumber(15)
  RoutedPairingEnvelope ensureRoutedPairing() => $_ensure(7);

  @$pb.TagNumber(16)
  PairingRendezvousClosed get rendezvousClosed => $_getN(8);
  @$pb.TagNumber(16)
  set rendezvousClosed(PairingRendezvousClosed value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasRendezvousClosed() => $_has(8);
  @$pb.TagNumber(16)
  void clearRendezvousClosed() => $_clearField(16);
  @$pb.TagNumber(16)
  PairingRendezvousClosed ensureRendezvousClosed() => $_ensure(8);

  @$pb.TagNumber(17)
  RoutedSessionEnvelope get routedSession => $_getN(9);
  @$pb.TagNumber(17)
  set routedSession(RoutedSessionEnvelope value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasRoutedSession() => $_has(9);
  @$pb.TagNumber(17)
  void clearRoutedSession() => $_clearField(17);
  @$pb.TagNumber(17)
  RoutedSessionEnvelope ensureRoutedSession() => $_ensure(9);

  @$pb.TagNumber(18)
  $1.UnifiedError get error => $_getN(10);
  @$pb.TagNumber(18)
  set error($1.UnifiedError value) => $_setField(18, value);
  @$pb.TagNumber(18)
  $core.bool hasError() => $_has(10);
  @$pb.TagNumber(18)
  void clearError() => $_clearField(18);
  @$pb.TagNumber(18)
  $1.UnifiedError ensureError() => $_ensure(10);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
