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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'authorization.pb.dart' as $1;
import 'error.pb.dart' as $3;
import 'identity.pb.dart' as $0;
import 'pairing.pbenum.dart';
import 'version.pb.dart' as $2;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'pairing.pbenum.dart';

class QrPairingRendezvous extends $pb.GeneratedMessage {
  factory QrPairingRendezvous({
    $core.List<$core.int>? rendezvousId,
    $0.DeviceIdentity? hostIdentity,
    $core.List<$core.int>? hostPublicKeyFingerprintSha256,
    $core.List<$core.int>? hostEphemeralPublicKey,
    $core.String? signalingEndpoint,
    $fixnum.Int64? issuedAtUnixMs,
    $fixnum.Int64? expiresAtUnixMs,
  }) {
    final result = create();
    if (rendezvousId != null) result.rendezvousId = rendezvousId;
    if (hostIdentity != null) result.hostIdentity = hostIdentity;
    if (hostPublicKeyFingerprintSha256 != null)
      result.hostPublicKeyFingerprintSha256 = hostPublicKeyFingerprintSha256;
    if (hostEphemeralPublicKey != null)
      result.hostEphemeralPublicKey = hostEphemeralPublicKey;
    if (signalingEndpoint != null) result.signalingEndpoint = signalingEndpoint;
    if (issuedAtUnixMs != null) result.issuedAtUnixMs = issuedAtUnixMs;
    if (expiresAtUnixMs != null) result.expiresAtUnixMs = expiresAtUnixMs;
    return result;
  }

  QrPairingRendezvous._();

  factory QrPairingRendezvous.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory QrPairingRendezvous.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QrPairingRendezvous',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'rendezvousId', $pb.PbFieldType.OY)
    ..aOM<$0.DeviceIdentity>(2, _omitFieldNames ? '' : 'hostIdentity',
        subBuilder: $0.DeviceIdentity.create)
    ..a<$core.List<$core.int>>(
        3,
        _omitFieldNames ? '' : 'hostPublicKeyFingerprintSha256',
        $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'hostEphemeralPublicKey', $pb.PbFieldType.OY)
    ..aOS(5, _omitFieldNames ? '' : 'signalingEndpoint')
    ..a<$fixnum.Int64>(
        6, _omitFieldNames ? '' : 'issuedAtUnixMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        7, _omitFieldNames ? '' : 'expiresAtUnixMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QrPairingRendezvous clone() => QrPairingRendezvous()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QrPairingRendezvous copyWith(void Function(QrPairingRendezvous) updates) =>
      super.copyWith((message) => updates(message as QrPairingRendezvous))
          as QrPairingRendezvous;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QrPairingRendezvous create() => QrPairingRendezvous._();
  @$core.override
  QrPairingRendezvous createEmptyInstance() => create();
  static $pb.PbList<QrPairingRendezvous> createRepeated() =>
      $pb.PbList<QrPairingRendezvous>();
  @$core.pragma('dart2js:noInline')
  static QrPairingRendezvous getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QrPairingRendezvous>(create);
  static QrPairingRendezvous? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get rendezvousId => $_getN(0);
  @$pb.TagNumber(1)
  set rendezvousId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRendezvousId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRendezvousId() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.DeviceIdentity get hostIdentity => $_getN(1);
  @$pb.TagNumber(2)
  set hostIdentity($0.DeviceIdentity value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasHostIdentity() => $_has(1);
  @$pb.TagNumber(2)
  void clearHostIdentity() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.DeviceIdentity ensureHostIdentity() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.List<$core.int> get hostPublicKeyFingerprintSha256 => $_getN(2);
  @$pb.TagNumber(3)
  set hostPublicKeyFingerprintSha256($core.List<$core.int> value) =>
      $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHostPublicKeyFingerprintSha256() => $_has(2);
  @$pb.TagNumber(3)
  void clearHostPublicKeyFingerprintSha256() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get hostEphemeralPublicKey => $_getN(3);
  @$pb.TagNumber(4)
  set hostEphemeralPublicKey($core.List<$core.int> value) =>
      $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHostEphemeralPublicKey() => $_has(3);
  @$pb.TagNumber(4)
  void clearHostEphemeralPublicKey() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get signalingEndpoint => $_getSZ(4);
  @$pb.TagNumber(5)
  set signalingEndpoint($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSignalingEndpoint() => $_has(4);
  @$pb.TagNumber(5)
  void clearSignalingEndpoint() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get issuedAtUnixMs => $_getI64(5);
  @$pb.TagNumber(6)
  set issuedAtUnixMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasIssuedAtUnixMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearIssuedAtUnixMs() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get expiresAtUnixMs => $_getI64(6);
  @$pb.TagNumber(7)
  set expiresAtUnixMs($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasExpiresAtUnixMs() => $_has(6);
  @$pb.TagNumber(7)
  void clearExpiresAtUnixMs() => $_clearField(7);
}

class DesktopPairingRendezvous extends $pb.GeneratedMessage {
  factory DesktopPairingRendezvous({
    $core.List<$core.int>? rendezvousId,
    $core.String? pairingCode,
    $0.DeviceIdentity? hostIdentity,
    $core.List<$core.int>? hostEphemeralPublicKey,
    $fixnum.Int64? issuedAtUnixMs,
    $fixnum.Int64? expiresAtUnixMs,
  }) {
    final result = create();
    if (rendezvousId != null) result.rendezvousId = rendezvousId;
    if (pairingCode != null) result.pairingCode = pairingCode;
    if (hostIdentity != null) result.hostIdentity = hostIdentity;
    if (hostEphemeralPublicKey != null)
      result.hostEphemeralPublicKey = hostEphemeralPublicKey;
    if (issuedAtUnixMs != null) result.issuedAtUnixMs = issuedAtUnixMs;
    if (expiresAtUnixMs != null) result.expiresAtUnixMs = expiresAtUnixMs;
    return result;
  }

  DesktopPairingRendezvous._();

  factory DesktopPairingRendezvous.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DesktopPairingRendezvous.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DesktopPairingRendezvous',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'rendezvousId', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'pairingCode')
    ..aOM<$0.DeviceIdentity>(3, _omitFieldNames ? '' : 'hostIdentity',
        subBuilder: $0.DeviceIdentity.create)
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'hostEphemeralPublicKey', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'issuedAtUnixMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        6, _omitFieldNames ? '' : 'expiresAtUnixMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DesktopPairingRendezvous clone() =>
      DesktopPairingRendezvous()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DesktopPairingRendezvous copyWith(
          void Function(DesktopPairingRendezvous) updates) =>
      super.copyWith((message) => updates(message as DesktopPairingRendezvous))
          as DesktopPairingRendezvous;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DesktopPairingRendezvous create() => DesktopPairingRendezvous._();
  @$core.override
  DesktopPairingRendezvous createEmptyInstance() => create();
  static $pb.PbList<DesktopPairingRendezvous> createRepeated() =>
      $pb.PbList<DesktopPairingRendezvous>();
  @$core.pragma('dart2js:noInline')
  static DesktopPairingRendezvous getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DesktopPairingRendezvous>(create);
  static DesktopPairingRendezvous? _defaultInstance;

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

  @$pb.TagNumber(3)
  $0.DeviceIdentity get hostIdentity => $_getN(2);
  @$pb.TagNumber(3)
  set hostIdentity($0.DeviceIdentity value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasHostIdentity() => $_has(2);
  @$pb.TagNumber(3)
  void clearHostIdentity() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.DeviceIdentity ensureHostIdentity() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.List<$core.int> get hostEphemeralPublicKey => $_getN(3);
  @$pb.TagNumber(4)
  set hostEphemeralPublicKey($core.List<$core.int> value) =>
      $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHostEphemeralPublicKey() => $_has(3);
  @$pb.TagNumber(4)
  void clearHostEphemeralPublicKey() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get issuedAtUnixMs => $_getI64(4);
  @$pb.TagNumber(5)
  set issuedAtUnixMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasIssuedAtUnixMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearIssuedAtUnixMs() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get expiresAtUnixMs => $_getI64(5);
  @$pb.TagNumber(6)
  set expiresAtUnixMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasExpiresAtUnixMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearExpiresAtUnixMs() => $_clearField(6);
}

class PairingHello extends $pb.GeneratedMessage {
  factory PairingHello({
    $core.List<$core.int>? rendezvousId,
    $0.DeviceIdentity? identity,
    $core.List<$core.int>? ephemeralPublicKey,
  }) {
    final result = create();
    if (rendezvousId != null) result.rendezvousId = rendezvousId;
    if (identity != null) result.identity = identity;
    if (ephemeralPublicKey != null)
      result.ephemeralPublicKey = ephemeralPublicKey;
    return result;
  }

  PairingHello._();

  factory PairingHello.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PairingHello.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PairingHello',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'rendezvousId', $pb.PbFieldType.OY)
    ..aOM<$0.DeviceIdentity>(2, _omitFieldNames ? '' : 'identity',
        subBuilder: $0.DeviceIdentity.create)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'ephemeralPublicKey', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingHello clone() => PairingHello()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingHello copyWith(void Function(PairingHello) updates) =>
      super.copyWith((message) => updates(message as PairingHello))
          as PairingHello;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PairingHello create() => PairingHello._();
  @$core.override
  PairingHello createEmptyInstance() => create();
  static $pb.PbList<PairingHello> createRepeated() =>
      $pb.PbList<PairingHello>();
  @$core.pragma('dart2js:noInline')
  static PairingHello getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PairingHello>(create);
  static PairingHello? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get rendezvousId => $_getN(0);
  @$pb.TagNumber(1)
  set rendezvousId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRendezvousId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRendezvousId() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.DeviceIdentity get identity => $_getN(1);
  @$pb.TagNumber(2)
  set identity($0.DeviceIdentity value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasIdentity() => $_has(1);
  @$pb.TagNumber(2)
  void clearIdentity() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.DeviceIdentity ensureIdentity() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.List<$core.int> get ephemeralPublicKey => $_getN(2);
  @$pb.TagNumber(3)
  set ephemeralPublicKey($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEphemeralPublicKey() => $_has(2);
  @$pb.TagNumber(3)
  void clearEphemeralPublicKey() => $_clearField(3);
}

class PairingConfirmationData extends $pb.GeneratedMessage {
  factory PairingConfirmationData({
    $core.List<$core.int>? controllerDeviceId,
    $core.List<$core.int>? hostDeviceId,
    $core.List<$core.int>? rendezvousId,
    $core.List<$core.int>? controllerIdentityPublicKey,
    $core.List<$core.int>? hostIdentityPublicKey,
    $core.List<$core.int>? controllerEphemeralPublicKey,
    $core.List<$core.int>? hostEphemeralPublicKey,
    $core.List<$core.int>? transcriptSha256,
  }) {
    final result = create();
    if (controllerDeviceId != null)
      result.controllerDeviceId = controllerDeviceId;
    if (hostDeviceId != null) result.hostDeviceId = hostDeviceId;
    if (rendezvousId != null) result.rendezvousId = rendezvousId;
    if (controllerIdentityPublicKey != null)
      result.controllerIdentityPublicKey = controllerIdentityPublicKey;
    if (hostIdentityPublicKey != null)
      result.hostIdentityPublicKey = hostIdentityPublicKey;
    if (controllerEphemeralPublicKey != null)
      result.controllerEphemeralPublicKey = controllerEphemeralPublicKey;
    if (hostEphemeralPublicKey != null)
      result.hostEphemeralPublicKey = hostEphemeralPublicKey;
    if (transcriptSha256 != null) result.transcriptSha256 = transcriptSha256;
    return result;
  }

  PairingConfirmationData._();

  factory PairingConfirmationData.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PairingConfirmationData.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PairingConfirmationData',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'controllerDeviceId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'hostDeviceId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'rendezvousId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        4,
        _omitFieldNames ? '' : 'controllerIdentityPublicKey',
        $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'hostIdentityPublicKey', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        6,
        _omitFieldNames ? '' : 'controllerEphemeralPublicKey',
        $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        7, _omitFieldNames ? '' : 'hostEphemeralPublicKey', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        8, _omitFieldNames ? '' : 'transcriptSha256', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingConfirmationData clone() =>
      PairingConfirmationData()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingConfirmationData copyWith(
          void Function(PairingConfirmationData) updates) =>
      super.copyWith((message) => updates(message as PairingConfirmationData))
          as PairingConfirmationData;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PairingConfirmationData create() => PairingConfirmationData._();
  @$core.override
  PairingConfirmationData createEmptyInstance() => create();
  static $pb.PbList<PairingConfirmationData> createRepeated() =>
      $pb.PbList<PairingConfirmationData>();
  @$core.pragma('dart2js:noInline')
  static PairingConfirmationData getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PairingConfirmationData>(create);
  static PairingConfirmationData? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get controllerDeviceId => $_getN(0);
  @$pb.TagNumber(1)
  set controllerDeviceId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasControllerDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearControllerDeviceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get hostDeviceId => $_getN(1);
  @$pb.TagNumber(2)
  set hostDeviceId($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHostDeviceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearHostDeviceId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get rendezvousId => $_getN(2);
  @$pb.TagNumber(3)
  set rendezvousId($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRendezvousId() => $_has(2);
  @$pb.TagNumber(3)
  void clearRendezvousId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get controllerIdentityPublicKey => $_getN(3);
  @$pb.TagNumber(4)
  set controllerIdentityPublicKey($core.List<$core.int> value) =>
      $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasControllerIdentityPublicKey() => $_has(3);
  @$pb.TagNumber(4)
  void clearControllerIdentityPublicKey() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.int> get hostIdentityPublicKey => $_getN(4);
  @$pb.TagNumber(5)
  set hostIdentityPublicKey($core.List<$core.int> value) =>
      $_setBytes(4, value);
  @$pb.TagNumber(5)
  $core.bool hasHostIdentityPublicKey() => $_has(4);
  @$pb.TagNumber(5)
  void clearHostIdentityPublicKey() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.List<$core.int> get controllerEphemeralPublicKey => $_getN(5);
  @$pb.TagNumber(6)
  set controllerEphemeralPublicKey($core.List<$core.int> value) =>
      $_setBytes(5, value);
  @$pb.TagNumber(6)
  $core.bool hasControllerEphemeralPublicKey() => $_has(5);
  @$pb.TagNumber(6)
  void clearControllerEphemeralPublicKey() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.List<$core.int> get hostEphemeralPublicKey => $_getN(6);
  @$pb.TagNumber(7)
  set hostEphemeralPublicKey($core.List<$core.int> value) =>
      $_setBytes(6, value);
  @$pb.TagNumber(7)
  $core.bool hasHostEphemeralPublicKey() => $_has(6);
  @$pb.TagNumber(7)
  void clearHostEphemeralPublicKey() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.List<$core.int> get transcriptSha256 => $_getN(7);
  @$pb.TagNumber(8)
  set transcriptSha256($core.List<$core.int> value) => $_setBytes(7, value);
  @$pb.TagNumber(8)
  $core.bool hasTranscriptSha256() => $_has(7);
  @$pb.TagNumber(8)
  void clearTranscriptSha256() => $_clearField(8);
}

class PairingDecision extends $pb.GeneratedMessage {
  factory PairingDecision({
    PairingDecisionStatus? status,
    $0.DeviceIdentity? controller,
    PairingConfirmationData? confirmation,
    $1.ControllerGrant? grant,
  }) {
    final result = create();
    if (status != null) result.status = status;
    if (controller != null) result.controller = controller;
    if (confirmation != null) result.confirmation = confirmation;
    if (grant != null) result.grant = grant;
    return result;
  }

  PairingDecision._();

  factory PairingDecision.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PairingDecision.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PairingDecision',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..e<PairingDecisionStatus>(
        1, _omitFieldNames ? '' : 'status', $pb.PbFieldType.OE,
        defaultOrMaker:
            PairingDecisionStatus.PAIRING_DECISION_STATUS_UNSPECIFIED,
        valueOf: PairingDecisionStatus.valueOf,
        enumValues: PairingDecisionStatus.values)
    ..aOM<$0.DeviceIdentity>(2, _omitFieldNames ? '' : 'controller',
        subBuilder: $0.DeviceIdentity.create)
    ..aOM<PairingConfirmationData>(3, _omitFieldNames ? '' : 'confirmation',
        subBuilder: PairingConfirmationData.create)
    ..aOM<$1.ControllerGrant>(4, _omitFieldNames ? '' : 'grant',
        subBuilder: $1.ControllerGrant.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingDecision clone() => PairingDecision()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingDecision copyWith(void Function(PairingDecision) updates) =>
      super.copyWith((message) => updates(message as PairingDecision))
          as PairingDecision;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PairingDecision create() => PairingDecision._();
  @$core.override
  PairingDecision createEmptyInstance() => create();
  static $pb.PbList<PairingDecision> createRepeated() =>
      $pb.PbList<PairingDecision>();
  @$core.pragma('dart2js:noInline')
  static PairingDecision getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PairingDecision>(create);
  static PairingDecision? _defaultInstance;

  @$pb.TagNumber(1)
  PairingDecisionStatus get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(PairingDecisionStatus value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.DeviceIdentity get controller => $_getN(1);
  @$pb.TagNumber(2)
  set controller($0.DeviceIdentity value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasController() => $_has(1);
  @$pb.TagNumber(2)
  void clearController() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.DeviceIdentity ensureController() => $_ensure(1);

  @$pb.TagNumber(3)
  PairingConfirmationData get confirmation => $_getN(2);
  @$pb.TagNumber(3)
  set confirmation(PairingConfirmationData value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasConfirmation() => $_has(2);
  @$pb.TagNumber(3)
  void clearConfirmation() => $_clearField(3);
  @$pb.TagNumber(3)
  PairingConfirmationData ensureConfirmation() => $_ensure(2);

  @$pb.TagNumber(4)
  $1.ControllerGrant get grant => $_getN(3);
  @$pb.TagNumber(4)
  set grant($1.ControllerGrant value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasGrant() => $_has(3);
  @$pb.TagNumber(4)
  void clearGrant() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.ControllerGrant ensureGrant() => $_ensure(3);
}

class HostPairingInvitation extends $pb.GeneratedMessage {
  factory HostPairingInvitation({
    $2.ProtocolVersion? protocolVersion,
    PairingInvitationKind? kind,
    $core.List<$core.int>? rendezvousId,
    $0.DeviceIdentity? hostIdentity,
    $core.List<$core.int>? hostPublicKeyFingerprintSha256,
    $core.List<$core.int>? hostEphemeralPublicKey,
    $core.String? signalingEndpoint,
    $core.String? pairingCode,
    $fixnum.Int64? issuedAtUnixMs,
    $fixnum.Int64? expiresAtUnixMs,
  }) {
    final result = create();
    if (protocolVersion != null) result.protocolVersion = protocolVersion;
    if (kind != null) result.kind = kind;
    if (rendezvousId != null) result.rendezvousId = rendezvousId;
    if (hostIdentity != null) result.hostIdentity = hostIdentity;
    if (hostPublicKeyFingerprintSha256 != null)
      result.hostPublicKeyFingerprintSha256 = hostPublicKeyFingerprintSha256;
    if (hostEphemeralPublicKey != null)
      result.hostEphemeralPublicKey = hostEphemeralPublicKey;
    if (signalingEndpoint != null) result.signalingEndpoint = signalingEndpoint;
    if (pairingCode != null) result.pairingCode = pairingCode;
    if (issuedAtUnixMs != null) result.issuedAtUnixMs = issuedAtUnixMs;
    if (expiresAtUnixMs != null) result.expiresAtUnixMs = expiresAtUnixMs;
    return result;
  }

  HostPairingInvitation._();

  factory HostPairingInvitation.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HostPairingInvitation.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HostPairingInvitation',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..aOM<$2.ProtocolVersion>(1, _omitFieldNames ? '' : 'protocolVersion',
        subBuilder: $2.ProtocolVersion.create)
    ..e<PairingInvitationKind>(
        2, _omitFieldNames ? '' : 'kind', $pb.PbFieldType.OE,
        defaultOrMaker:
            PairingInvitationKind.PAIRING_INVITATION_KIND_UNSPECIFIED,
        valueOf: PairingInvitationKind.valueOf,
        enumValues: PairingInvitationKind.values)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'rendezvousId', $pb.PbFieldType.OY)
    ..aOM<$0.DeviceIdentity>(4, _omitFieldNames ? '' : 'hostIdentity',
        subBuilder: $0.DeviceIdentity.create)
    ..a<$core.List<$core.int>>(
        5,
        _omitFieldNames ? '' : 'hostPublicKeyFingerprintSha256',
        $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        6, _omitFieldNames ? '' : 'hostEphemeralPublicKey', $pb.PbFieldType.OY)
    ..aOS(7, _omitFieldNames ? '' : 'signalingEndpoint')
    ..aOS(8, _omitFieldNames ? '' : 'pairingCode')
    ..a<$fixnum.Int64>(
        9, _omitFieldNames ? '' : 'issuedAtUnixMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        10, _omitFieldNames ? '' : 'expiresAtUnixMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HostPairingInvitation clone() =>
      HostPairingInvitation()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HostPairingInvitation copyWith(
          void Function(HostPairingInvitation) updates) =>
      super.copyWith((message) => updates(message as HostPairingInvitation))
          as HostPairingInvitation;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HostPairingInvitation create() => HostPairingInvitation._();
  @$core.override
  HostPairingInvitation createEmptyInstance() => create();
  static $pb.PbList<HostPairingInvitation> createRepeated() =>
      $pb.PbList<HostPairingInvitation>();
  @$core.pragma('dart2js:noInline')
  static HostPairingInvitation getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HostPairingInvitation>(create);
  static HostPairingInvitation? _defaultInstance;

  @$pb.TagNumber(1)
  $2.ProtocolVersion get protocolVersion => $_getN(0);
  @$pb.TagNumber(1)
  set protocolVersion($2.ProtocolVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProtocolVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearProtocolVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  $2.ProtocolVersion ensureProtocolVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  PairingInvitationKind get kind => $_getN(1);
  @$pb.TagNumber(2)
  set kind(PairingInvitationKind value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get rendezvousId => $_getN(2);
  @$pb.TagNumber(3)
  set rendezvousId($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRendezvousId() => $_has(2);
  @$pb.TagNumber(3)
  void clearRendezvousId() => $_clearField(3);

  @$pb.TagNumber(4)
  $0.DeviceIdentity get hostIdentity => $_getN(3);
  @$pb.TagNumber(4)
  set hostIdentity($0.DeviceIdentity value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasHostIdentity() => $_has(3);
  @$pb.TagNumber(4)
  void clearHostIdentity() => $_clearField(4);
  @$pb.TagNumber(4)
  $0.DeviceIdentity ensureHostIdentity() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.List<$core.int> get hostPublicKeyFingerprintSha256 => $_getN(4);
  @$pb.TagNumber(5)
  set hostPublicKeyFingerprintSha256($core.List<$core.int> value) =>
      $_setBytes(4, value);
  @$pb.TagNumber(5)
  $core.bool hasHostPublicKeyFingerprintSha256() => $_has(4);
  @$pb.TagNumber(5)
  void clearHostPublicKeyFingerprintSha256() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.List<$core.int> get hostEphemeralPublicKey => $_getN(5);
  @$pb.TagNumber(6)
  set hostEphemeralPublicKey($core.List<$core.int> value) =>
      $_setBytes(5, value);
  @$pb.TagNumber(6)
  $core.bool hasHostEphemeralPublicKey() => $_has(5);
  @$pb.TagNumber(6)
  void clearHostEphemeralPublicKey() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get signalingEndpoint => $_getSZ(6);
  @$pb.TagNumber(7)
  set signalingEndpoint($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSignalingEndpoint() => $_has(6);
  @$pb.TagNumber(7)
  void clearSignalingEndpoint() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get pairingCode => $_getSZ(7);
  @$pb.TagNumber(8)
  set pairingCode($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasPairingCode() => $_has(7);
  @$pb.TagNumber(8)
  void clearPairingCode() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get issuedAtUnixMs => $_getI64(8);
  @$pb.TagNumber(9)
  set issuedAtUnixMs($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasIssuedAtUnixMs() => $_has(8);
  @$pb.TagNumber(9)
  void clearIssuedAtUnixMs() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get expiresAtUnixMs => $_getI64(9);
  @$pb.TagNumber(10)
  set expiresAtUnixMs($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasExpiresAtUnixMs() => $_has(9);
  @$pb.TagNumber(10)
  void clearExpiresAtUnixMs() => $_clearField(10);
}

class ControllerPairingHello extends $pb.GeneratedMessage {
  factory ControllerPairingHello({
    $core.List<$core.int>? rendezvousId,
    $0.DeviceIdentity? identity,
    $core.List<$core.int>? ephemeralPublicKey,
    $core.List<$core.int>? transcriptSha256,
    $core.List<$core.int>? signature,
  }) {
    final result = create();
    if (rendezvousId != null) result.rendezvousId = rendezvousId;
    if (identity != null) result.identity = identity;
    if (ephemeralPublicKey != null)
      result.ephemeralPublicKey = ephemeralPublicKey;
    if (transcriptSha256 != null) result.transcriptSha256 = transcriptSha256;
    if (signature != null) result.signature = signature;
    return result;
  }

  ControllerPairingHello._();

  factory ControllerPairingHello.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ControllerPairingHello.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ControllerPairingHello',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'rendezvousId', $pb.PbFieldType.OY)
    ..aOM<$0.DeviceIdentity>(2, _omitFieldNames ? '' : 'identity',
        subBuilder: $0.DeviceIdentity.create)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'ephemeralPublicKey', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'transcriptSha256', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'signature', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControllerPairingHello clone() =>
      ControllerPairingHello()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControllerPairingHello copyWith(
          void Function(ControllerPairingHello) updates) =>
      super.copyWith((message) => updates(message as ControllerPairingHello))
          as ControllerPairingHello;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ControllerPairingHello create() => ControllerPairingHello._();
  @$core.override
  ControllerPairingHello createEmptyInstance() => create();
  static $pb.PbList<ControllerPairingHello> createRepeated() =>
      $pb.PbList<ControllerPairingHello>();
  @$core.pragma('dart2js:noInline')
  static ControllerPairingHello getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ControllerPairingHello>(create);
  static ControllerPairingHello? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get rendezvousId => $_getN(0);
  @$pb.TagNumber(1)
  set rendezvousId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRendezvousId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRendezvousId() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.DeviceIdentity get identity => $_getN(1);
  @$pb.TagNumber(2)
  set identity($0.DeviceIdentity value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasIdentity() => $_has(1);
  @$pb.TagNumber(2)
  void clearIdentity() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.DeviceIdentity ensureIdentity() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.List<$core.int> get ephemeralPublicKey => $_getN(2);
  @$pb.TagNumber(3)
  set ephemeralPublicKey($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEphemeralPublicKey() => $_has(2);
  @$pb.TagNumber(3)
  void clearEphemeralPublicKey() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get transcriptSha256 => $_getN(3);
  @$pb.TagNumber(4)
  set transcriptSha256($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTranscriptSha256() => $_has(3);
  @$pb.TagNumber(4)
  void clearTranscriptSha256() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.int> get signature => $_getN(4);
  @$pb.TagNumber(5)
  set signature($core.List<$core.int> value) => $_setBytes(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSignature() => $_has(4);
  @$pb.TagNumber(5)
  void clearSignature() => $_clearField(5);
}

class HostPairingProof extends $pb.GeneratedMessage {
  factory HostPairingProof({
    PairingConfirmationData? confirmation,
    $core.List<$core.int>? hostSignature,
    $fixnum.Int64? expiresAtUnixMs,
  }) {
    final result = create();
    if (confirmation != null) result.confirmation = confirmation;
    if (hostSignature != null) result.hostSignature = hostSignature;
    if (expiresAtUnixMs != null) result.expiresAtUnixMs = expiresAtUnixMs;
    return result;
  }

  HostPairingProof._();

  factory HostPairingProof.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HostPairingProof.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HostPairingProof',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..aOM<PairingConfirmationData>(1, _omitFieldNames ? '' : 'confirmation',
        subBuilder: PairingConfirmationData.create)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'hostSignature', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'expiresAtUnixMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HostPairingProof clone() => HostPairingProof()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HostPairingProof copyWith(void Function(HostPairingProof) updates) =>
      super.copyWith((message) => updates(message as HostPairingProof))
          as HostPairingProof;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HostPairingProof create() => HostPairingProof._();
  @$core.override
  HostPairingProof createEmptyInstance() => create();
  static $pb.PbList<HostPairingProof> createRepeated() =>
      $pb.PbList<HostPairingProof>();
  @$core.pragma('dart2js:noInline')
  static HostPairingProof getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HostPairingProof>(create);
  static HostPairingProof? _defaultInstance;

  @$pb.TagNumber(1)
  PairingConfirmationData get confirmation => $_getN(0);
  @$pb.TagNumber(1)
  set confirmation(PairingConfirmationData value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasConfirmation() => $_has(0);
  @$pb.TagNumber(1)
  void clearConfirmation() => $_clearField(1);
  @$pb.TagNumber(1)
  PairingConfirmationData ensureConfirmation() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get hostSignature => $_getN(1);
  @$pb.TagNumber(2)
  set hostSignature($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHostSignature() => $_has(1);
  @$pb.TagNumber(2)
  void clearHostSignature() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get expiresAtUnixMs => $_getI64(2);
  @$pb.TagNumber(3)
  set expiresAtUnixMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasExpiresAtUnixMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearExpiresAtUnixMs() => $_clearField(3);
}

class ControllerPairingReady extends $pb.GeneratedMessage {
  factory ControllerPairingReady({
    $core.List<$core.int>? transcriptSha256,
  }) {
    final result = create();
    if (transcriptSha256 != null) result.transcriptSha256 = transcriptSha256;
    return result;
  }

  ControllerPairingReady._();

  factory ControllerPairingReady.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ControllerPairingReady.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ControllerPairingReady',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'transcriptSha256', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControllerPairingReady clone() =>
      ControllerPairingReady()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControllerPairingReady copyWith(
          void Function(ControllerPairingReady) updates) =>
      super.copyWith((message) => updates(message as ControllerPairingReady))
          as ControllerPairingReady;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ControllerPairingReady create() => ControllerPairingReady._();
  @$core.override
  ControllerPairingReady createEmptyInstance() => create();
  static $pb.PbList<ControllerPairingReady> createRepeated() =>
      $pb.PbList<ControllerPairingReady>();
  @$core.pragma('dart2js:noInline')
  static ControllerPairingReady getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ControllerPairingReady>(create);
  static ControllerPairingReady? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get transcriptSha256 => $_getN(0);
  @$pb.TagNumber(1)
  set transcriptSha256($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTranscriptSha256() => $_has(0);
  @$pb.TagNumber(1)
  void clearTranscriptSha256() => $_clearField(1);
}

class PairingFinalDecision extends $pb.GeneratedMessage {
  factory PairingFinalDecision({
    PairingDecisionStatus? status,
    $core.List<$core.int>? transcriptSha256,
    $1.ControllerGrant? grant,
  }) {
    final result = create();
    if (status != null) result.status = status;
    if (transcriptSha256 != null) result.transcriptSha256 = transcriptSha256;
    if (grant != null) result.grant = grant;
    return result;
  }

  PairingFinalDecision._();

  factory PairingFinalDecision.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PairingFinalDecision.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PairingFinalDecision',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..e<PairingDecisionStatus>(
        1, _omitFieldNames ? '' : 'status', $pb.PbFieldType.OE,
        defaultOrMaker:
            PairingDecisionStatus.PAIRING_DECISION_STATUS_UNSPECIFIED,
        valueOf: PairingDecisionStatus.valueOf,
        enumValues: PairingDecisionStatus.values)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'transcriptSha256', $pb.PbFieldType.OY)
    ..aOM<$1.ControllerGrant>(3, _omitFieldNames ? '' : 'grant',
        subBuilder: $1.ControllerGrant.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingFinalDecision clone() =>
      PairingFinalDecision()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingFinalDecision copyWith(void Function(PairingFinalDecision) updates) =>
      super.copyWith((message) => updates(message as PairingFinalDecision))
          as PairingFinalDecision;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PairingFinalDecision create() => PairingFinalDecision._();
  @$core.override
  PairingFinalDecision createEmptyInstance() => create();
  static $pb.PbList<PairingFinalDecision> createRepeated() =>
      $pb.PbList<PairingFinalDecision>();
  @$core.pragma('dart2js:noInline')
  static PairingFinalDecision getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PairingFinalDecision>(create);
  static PairingFinalDecision? _defaultInstance;

  @$pb.TagNumber(1)
  PairingDecisionStatus get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(PairingDecisionStatus value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get transcriptSha256 => $_getN(1);
  @$pb.TagNumber(2)
  set transcriptSha256($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTranscriptSha256() => $_has(1);
  @$pb.TagNumber(2)
  void clearTranscriptSha256() => $_clearField(2);

  @$pb.TagNumber(3)
  $1.ControllerGrant get grant => $_getN(2);
  @$pb.TagNumber(3)
  set grant($1.ControllerGrant value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasGrant() => $_has(2);
  @$pb.TagNumber(3)
  void clearGrant() => $_clearField(3);
  @$pb.TagNumber(3)
  $1.ControllerGrant ensureGrant() => $_ensure(2);
}

enum PairingPlaintext_Payload {
  hostProof,
  controllerReady,
  finalDecision,
  notSet
}

class PairingPlaintext extends $pb.GeneratedMessage {
  factory PairingPlaintext({
    HostPairingProof? hostProof,
    ControllerPairingReady? controllerReady,
    PairingFinalDecision? finalDecision,
  }) {
    final result = create();
    if (hostProof != null) result.hostProof = hostProof;
    if (controllerReady != null) result.controllerReady = controllerReady;
    if (finalDecision != null) result.finalDecision = finalDecision;
    return result;
  }

  PairingPlaintext._();

  factory PairingPlaintext.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PairingPlaintext.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, PairingPlaintext_Payload>
      _PairingPlaintext_PayloadByTag = {
    1: PairingPlaintext_Payload.hostProof,
    2: PairingPlaintext_Payload.controllerReady,
    3: PairingPlaintext_Payload.finalDecision,
    0: PairingPlaintext_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PairingPlaintext',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3])
    ..aOM<HostPairingProof>(1, _omitFieldNames ? '' : 'hostProof',
        subBuilder: HostPairingProof.create)
    ..aOM<ControllerPairingReady>(2, _omitFieldNames ? '' : 'controllerReady',
        subBuilder: ControllerPairingReady.create)
    ..aOM<PairingFinalDecision>(3, _omitFieldNames ? '' : 'finalDecision',
        subBuilder: PairingFinalDecision.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingPlaintext clone() => PairingPlaintext()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingPlaintext copyWith(void Function(PairingPlaintext) updates) =>
      super.copyWith((message) => updates(message as PairingPlaintext))
          as PairingPlaintext;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PairingPlaintext create() => PairingPlaintext._();
  @$core.override
  PairingPlaintext createEmptyInstance() => create();
  static $pb.PbList<PairingPlaintext> createRepeated() =>
      $pb.PbList<PairingPlaintext>();
  @$core.pragma('dart2js:noInline')
  static PairingPlaintext getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PairingPlaintext>(create);
  static PairingPlaintext? _defaultInstance;

  PairingPlaintext_Payload whichPayload() =>
      _PairingPlaintext_PayloadByTag[$_whichOneof(0)]!;
  void clearPayload() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  HostPairingProof get hostProof => $_getN(0);
  @$pb.TagNumber(1)
  set hostProof(HostPairingProof value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHostProof() => $_has(0);
  @$pb.TagNumber(1)
  void clearHostProof() => $_clearField(1);
  @$pb.TagNumber(1)
  HostPairingProof ensureHostProof() => $_ensure(0);

  @$pb.TagNumber(2)
  ControllerPairingReady get controllerReady => $_getN(1);
  @$pb.TagNumber(2)
  set controllerReady(ControllerPairingReady value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasControllerReady() => $_has(1);
  @$pb.TagNumber(2)
  void clearControllerReady() => $_clearField(2);
  @$pb.TagNumber(2)
  ControllerPairingReady ensureControllerReady() => $_ensure(1);

  @$pb.TagNumber(3)
  PairingFinalDecision get finalDecision => $_getN(2);
  @$pb.TagNumber(3)
  set finalDecision(PairingFinalDecision value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasFinalDecision() => $_has(2);
  @$pb.TagNumber(3)
  void clearFinalDecision() => $_clearField(3);
  @$pb.TagNumber(3)
  PairingFinalDecision ensureFinalDecision() => $_ensure(2);
}

class EncryptedPairingEnvelope extends $pb.GeneratedMessage {
  factory EncryptedPairingEnvelope({
    $2.ProtocolVersion? protocolVersion,
    $core.List<$core.int>? rendezvousId,
    PairingDirection? direction,
    $fixnum.Int64? sequence,
    $core.List<$core.int>? ciphertext,
  }) {
    final result = create();
    if (protocolVersion != null) result.protocolVersion = protocolVersion;
    if (rendezvousId != null) result.rendezvousId = rendezvousId;
    if (direction != null) result.direction = direction;
    if (sequence != null) result.sequence = sequence;
    if (ciphertext != null) result.ciphertext = ciphertext;
    return result;
  }

  EncryptedPairingEnvelope._();

  factory EncryptedPairingEnvelope.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EncryptedPairingEnvelope.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EncryptedPairingEnvelope',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..aOM<$2.ProtocolVersion>(1, _omitFieldNames ? '' : 'protocolVersion',
        subBuilder: $2.ProtocolVersion.create)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'rendezvousId', $pb.PbFieldType.OY)
    ..e<PairingDirection>(
        3, _omitFieldNames ? '' : 'direction', $pb.PbFieldType.OE,
        defaultOrMaker: PairingDirection.PAIRING_DIRECTION_UNSPECIFIED,
        valueOf: PairingDirection.valueOf,
        enumValues: PairingDirection.values)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'sequence', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'ciphertext', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EncryptedPairingEnvelope clone() =>
      EncryptedPairingEnvelope()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EncryptedPairingEnvelope copyWith(
          void Function(EncryptedPairingEnvelope) updates) =>
      super.copyWith((message) => updates(message as EncryptedPairingEnvelope))
          as EncryptedPairingEnvelope;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EncryptedPairingEnvelope create() => EncryptedPairingEnvelope._();
  @$core.override
  EncryptedPairingEnvelope createEmptyInstance() => create();
  static $pb.PbList<EncryptedPairingEnvelope> createRepeated() =>
      $pb.PbList<EncryptedPairingEnvelope>();
  @$core.pragma('dart2js:noInline')
  static EncryptedPairingEnvelope getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EncryptedPairingEnvelope>(create);
  static EncryptedPairingEnvelope? _defaultInstance;

  @$pb.TagNumber(1)
  $2.ProtocolVersion get protocolVersion => $_getN(0);
  @$pb.TagNumber(1)
  set protocolVersion($2.ProtocolVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProtocolVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearProtocolVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  $2.ProtocolVersion ensureProtocolVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get rendezvousId => $_getN(1);
  @$pb.TagNumber(2)
  set rendezvousId($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRendezvousId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRendezvousId() => $_clearField(2);

  @$pb.TagNumber(3)
  PairingDirection get direction => $_getN(2);
  @$pb.TagNumber(3)
  set direction(PairingDirection value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasDirection() => $_has(2);
  @$pb.TagNumber(3)
  void clearDirection() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get sequence => $_getI64(3);
  @$pb.TagNumber(4)
  set sequence($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSequence() => $_has(3);
  @$pb.TagNumber(4)
  void clearSequence() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.int> get ciphertext => $_getN(4);
  @$pb.TagNumber(5)
  set ciphertext($core.List<$core.int> value) => $_setBytes(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCiphertext() => $_has(4);
  @$pb.TagNumber(5)
  void clearCiphertext() => $_clearField(5);
}

class TrustedHostBinding extends $pb.GeneratedMessage {
  factory TrustedHostBinding({
    $0.DeviceIdentity? hostIdentity,
    $core.String? signalingEndpoint,
    $fixnum.Int64? pairedAtUnixMs,
    $fixnum.Int64? lastSuccessfulConnectionAtUnixMs,
    $core.int? displayOrder,
  }) {
    final result = create();
    if (hostIdentity != null) result.hostIdentity = hostIdentity;
    if (signalingEndpoint != null) result.signalingEndpoint = signalingEndpoint;
    if (pairedAtUnixMs != null) result.pairedAtUnixMs = pairedAtUnixMs;
    if (lastSuccessfulConnectionAtUnixMs != null)
      result.lastSuccessfulConnectionAtUnixMs =
          lastSuccessfulConnectionAtUnixMs;
    if (displayOrder != null) result.displayOrder = displayOrder;
    return result;
  }

  TrustedHostBinding._();

  factory TrustedHostBinding.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TrustedHostBinding.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TrustedHostBinding',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..aOM<$0.DeviceIdentity>(1, _omitFieldNames ? '' : 'hostIdentity',
        subBuilder: $0.DeviceIdentity.create)
    ..aOS(2, _omitFieldNames ? '' : 'signalingEndpoint')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'pairedAtUnixMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        4,
        _omitFieldNames ? '' : 'lastSuccessfulConnectionAtUnixMs',
        $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.int>(
        5, _omitFieldNames ? '' : 'displayOrder', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TrustedHostBinding clone() => TrustedHostBinding()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TrustedHostBinding copyWith(void Function(TrustedHostBinding) updates) =>
      super.copyWith((message) => updates(message as TrustedHostBinding))
          as TrustedHostBinding;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TrustedHostBinding create() => TrustedHostBinding._();
  @$core.override
  TrustedHostBinding createEmptyInstance() => create();
  static $pb.PbList<TrustedHostBinding> createRepeated() =>
      $pb.PbList<TrustedHostBinding>();
  @$core.pragma('dart2js:noInline')
  static TrustedHostBinding getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TrustedHostBinding>(create);
  static TrustedHostBinding? _defaultInstance;

  @$pb.TagNumber(1)
  $0.DeviceIdentity get hostIdentity => $_getN(0);
  @$pb.TagNumber(1)
  set hostIdentity($0.DeviceIdentity value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHostIdentity() => $_has(0);
  @$pb.TagNumber(1)
  void clearHostIdentity() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.DeviceIdentity ensureHostIdentity() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get signalingEndpoint => $_getSZ(1);
  @$pb.TagNumber(2)
  set signalingEndpoint($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSignalingEndpoint() => $_has(1);
  @$pb.TagNumber(2)
  void clearSignalingEndpoint() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get pairedAtUnixMs => $_getI64(2);
  @$pb.TagNumber(3)
  set pairedAtUnixMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPairedAtUnixMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearPairedAtUnixMs() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get lastSuccessfulConnectionAtUnixMs => $_getI64(3);
  @$pb.TagNumber(4)
  set lastSuccessfulConnectionAtUnixMs($fixnum.Int64 value) =>
      $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLastSuccessfulConnectionAtUnixMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearLastSuccessfulConnectionAtUnixMs() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get displayOrder => $_getIZ(4);
  @$pb.TagNumber(5)
  set displayOrder($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDisplayOrder() => $_has(4);
  @$pb.TagNumber(5)
  void clearDisplayOrder() => $_clearField(5);
}

class TrustedHostSnapshot extends $pb.GeneratedMessage {
  factory TrustedHostSnapshot({
    $2.ProtocolVersion? protocolVersion,
    $core.Iterable<TrustedHostBinding>? bindings,
  }) {
    final result = create();
    if (protocolVersion != null) result.protocolVersion = protocolVersion;
    if (bindings != null) result.bindings.addAll(bindings);
    return result;
  }

  TrustedHostSnapshot._();

  factory TrustedHostSnapshot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TrustedHostSnapshot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TrustedHostSnapshot',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..aOM<$2.ProtocolVersion>(1, _omitFieldNames ? '' : 'protocolVersion',
        subBuilder: $2.ProtocolVersion.create)
    ..pc<TrustedHostBinding>(
        2, _omitFieldNames ? '' : 'bindings', $pb.PbFieldType.PM,
        subBuilder: TrustedHostBinding.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TrustedHostSnapshot clone() => TrustedHostSnapshot()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TrustedHostSnapshot copyWith(void Function(TrustedHostSnapshot) updates) =>
      super.copyWith((message) => updates(message as TrustedHostSnapshot))
          as TrustedHostSnapshot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TrustedHostSnapshot create() => TrustedHostSnapshot._();
  @$core.override
  TrustedHostSnapshot createEmptyInstance() => create();
  static $pb.PbList<TrustedHostSnapshot> createRepeated() =>
      $pb.PbList<TrustedHostSnapshot>();
  @$core.pragma('dart2js:noInline')
  static TrustedHostSnapshot getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TrustedHostSnapshot>(create);
  static TrustedHostSnapshot? _defaultInstance;

  @$pb.TagNumber(1)
  $2.ProtocolVersion get protocolVersion => $_getN(0);
  @$pb.TagNumber(1)
  set protocolVersion($2.ProtocolVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProtocolVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearProtocolVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  $2.ProtocolVersion ensureProtocolVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<TrustedHostBinding> get bindings => $_getList(1);
}

class HostPairingStatusSnapshot extends $pb.GeneratedMessage {
  factory HostPairingStatusSnapshot({
    HostPairingState? state,
    $fixnum.Int64? revision,
    HostPairingInvitation? invitation,
    $0.DeviceIdentity? pendingController,
    $core.List<$core.int>? pendingControllerFingerprintSha256,
    $core.Iterable<$core.String>? sasWords,
    $fixnum.Int64? expiresAtUnixMs,
    $3.UnifiedError? error,
  }) {
    final result = create();
    if (state != null) result.state = state;
    if (revision != null) result.revision = revision;
    if (invitation != null) result.invitation = invitation;
    if (pendingController != null) result.pendingController = pendingController;
    if (pendingControllerFingerprintSha256 != null)
      result.pendingControllerFingerprintSha256 =
          pendingControllerFingerprintSha256;
    if (sasWords != null) result.sasWords.addAll(sasWords);
    if (expiresAtUnixMs != null) result.expiresAtUnixMs = expiresAtUnixMs;
    if (error != null) result.error = error;
    return result;
  }

  HostPairingStatusSnapshot._();

  factory HostPairingStatusSnapshot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HostPairingStatusSnapshot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HostPairingStatusSnapshot',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..e<HostPairingState>(1, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE,
        defaultOrMaker: HostPairingState.HOST_PAIRING_STATE_UNSPECIFIED,
        valueOf: HostPairingState.valueOf,
        enumValues: HostPairingState.values)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<HostPairingInvitation>(3, _omitFieldNames ? '' : 'invitation',
        subBuilder: HostPairingInvitation.create)
    ..aOM<$0.DeviceIdentity>(4, _omitFieldNames ? '' : 'pendingController',
        subBuilder: $0.DeviceIdentity.create)
    ..a<$core.List<$core.int>>(
        5,
        _omitFieldNames ? '' : 'pendingControllerFingerprintSha256',
        $pb.PbFieldType.OY)
    ..pPS(6, _omitFieldNames ? '' : 'sasWords')
    ..a<$fixnum.Int64>(
        7, _omitFieldNames ? '' : 'expiresAtUnixMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<$3.UnifiedError>(8, _omitFieldNames ? '' : 'error',
        subBuilder: $3.UnifiedError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HostPairingStatusSnapshot clone() =>
      HostPairingStatusSnapshot()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HostPairingStatusSnapshot copyWith(
          void Function(HostPairingStatusSnapshot) updates) =>
      super.copyWith((message) => updates(message as HostPairingStatusSnapshot))
          as HostPairingStatusSnapshot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HostPairingStatusSnapshot create() => HostPairingStatusSnapshot._();
  @$core.override
  HostPairingStatusSnapshot createEmptyInstance() => create();
  static $pb.PbList<HostPairingStatusSnapshot> createRepeated() =>
      $pb.PbList<HostPairingStatusSnapshot>();
  @$core.pragma('dart2js:noInline')
  static HostPairingStatusSnapshot getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HostPairingStatusSnapshot>(create);
  static HostPairingStatusSnapshot? _defaultInstance;

  @$pb.TagNumber(1)
  HostPairingState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(HostPairingState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get revision => $_getI64(1);
  @$pb.TagNumber(2)
  set revision($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRevision() => $_has(1);
  @$pb.TagNumber(2)
  void clearRevision() => $_clearField(2);

  @$pb.TagNumber(3)
  HostPairingInvitation get invitation => $_getN(2);
  @$pb.TagNumber(3)
  set invitation(HostPairingInvitation value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasInvitation() => $_has(2);
  @$pb.TagNumber(3)
  void clearInvitation() => $_clearField(3);
  @$pb.TagNumber(3)
  HostPairingInvitation ensureInvitation() => $_ensure(2);

  @$pb.TagNumber(4)
  $0.DeviceIdentity get pendingController => $_getN(3);
  @$pb.TagNumber(4)
  set pendingController($0.DeviceIdentity value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasPendingController() => $_has(3);
  @$pb.TagNumber(4)
  void clearPendingController() => $_clearField(4);
  @$pb.TagNumber(4)
  $0.DeviceIdentity ensurePendingController() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.List<$core.int> get pendingControllerFingerprintSha256 => $_getN(4);
  @$pb.TagNumber(5)
  set pendingControllerFingerprintSha256($core.List<$core.int> value) =>
      $_setBytes(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPendingControllerFingerprintSha256() => $_has(4);
  @$pb.TagNumber(5)
  void clearPendingControllerFingerprintSha256() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get sasWords => $_getList(5);

  @$pb.TagNumber(7)
  $fixnum.Int64 get expiresAtUnixMs => $_getI64(6);
  @$pb.TagNumber(7)
  set expiresAtUnixMs($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasExpiresAtUnixMs() => $_has(6);
  @$pb.TagNumber(7)
  void clearExpiresAtUnixMs() => $_clearField(7);

  @$pb.TagNumber(8)
  $3.UnifiedError get error => $_getN(7);
  @$pb.TagNumber(8)
  set error($3.UnifiedError value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasError() => $_has(7);
  @$pb.TagNumber(8)
  void clearError() => $_clearField(8);
  @$pb.TagNumber(8)
  $3.UnifiedError ensureError() => $_ensure(7);
}

enum PairingMessage_Payload {
  qrRendezvous,
  desktopRendezvous,
  hello,
  confirmation,
  decision,
  hostInvitation,
  controllerHello,
  encryptedEnvelope,
  notSet
}

class PairingMessage extends $pb.GeneratedMessage {
  factory PairingMessage({
    QrPairingRendezvous? qrRendezvous,
    DesktopPairingRendezvous? desktopRendezvous,
    PairingHello? hello,
    PairingConfirmationData? confirmation,
    PairingDecision? decision,
    HostPairingInvitation? hostInvitation,
    ControllerPairingHello? controllerHello,
    EncryptedPairingEnvelope? encryptedEnvelope,
  }) {
    final result = create();
    if (qrRendezvous != null) result.qrRendezvous = qrRendezvous;
    if (desktopRendezvous != null) result.desktopRendezvous = desktopRendezvous;
    if (hello != null) result.hello = hello;
    if (confirmation != null) result.confirmation = confirmation;
    if (decision != null) result.decision = decision;
    if (hostInvitation != null) result.hostInvitation = hostInvitation;
    if (controllerHello != null) result.controllerHello = controllerHello;
    if (encryptedEnvelope != null) result.encryptedEnvelope = encryptedEnvelope;
    return result;
  }

  PairingMessage._();

  factory PairingMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PairingMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, PairingMessage_Payload>
      _PairingMessage_PayloadByTag = {
    1: PairingMessage_Payload.qrRendezvous,
    2: PairingMessage_Payload.desktopRendezvous,
    3: PairingMessage_Payload.hello,
    4: PairingMessage_Payload.confirmation,
    5: PairingMessage_Payload.decision,
    6: PairingMessage_Payload.hostInvitation,
    7: PairingMessage_Payload.controllerHello,
    8: PairingMessage_Payload.encryptedEnvelope,
    0: PairingMessage_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PairingMessage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6, 7, 8])
    ..aOM<QrPairingRendezvous>(1, _omitFieldNames ? '' : 'qrRendezvous',
        subBuilder: QrPairingRendezvous.create)
    ..aOM<DesktopPairingRendezvous>(
        2, _omitFieldNames ? '' : 'desktopRendezvous',
        subBuilder: DesktopPairingRendezvous.create)
    ..aOM<PairingHello>(3, _omitFieldNames ? '' : 'hello',
        subBuilder: PairingHello.create)
    ..aOM<PairingConfirmationData>(4, _omitFieldNames ? '' : 'confirmation',
        subBuilder: PairingConfirmationData.create)
    ..aOM<PairingDecision>(5, _omitFieldNames ? '' : 'decision',
        subBuilder: PairingDecision.create)
    ..aOM<HostPairingInvitation>(6, _omitFieldNames ? '' : 'hostInvitation',
        subBuilder: HostPairingInvitation.create)
    ..aOM<ControllerPairingHello>(7, _omitFieldNames ? '' : 'controllerHello',
        subBuilder: ControllerPairingHello.create)
    ..aOM<EncryptedPairingEnvelope>(
        8, _omitFieldNames ? '' : 'encryptedEnvelope',
        subBuilder: EncryptedPairingEnvelope.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingMessage clone() => PairingMessage()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingMessage copyWith(void Function(PairingMessage) updates) =>
      super.copyWith((message) => updates(message as PairingMessage))
          as PairingMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PairingMessage create() => PairingMessage._();
  @$core.override
  PairingMessage createEmptyInstance() => create();
  static $pb.PbList<PairingMessage> createRepeated() =>
      $pb.PbList<PairingMessage>();
  @$core.pragma('dart2js:noInline')
  static PairingMessage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PairingMessage>(create);
  static PairingMessage? _defaultInstance;

  PairingMessage_Payload whichPayload() =>
      _PairingMessage_PayloadByTag[$_whichOneof(0)]!;
  void clearPayload() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  QrPairingRendezvous get qrRendezvous => $_getN(0);
  @$pb.TagNumber(1)
  set qrRendezvous(QrPairingRendezvous value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasQrRendezvous() => $_has(0);
  @$pb.TagNumber(1)
  void clearQrRendezvous() => $_clearField(1);
  @$pb.TagNumber(1)
  QrPairingRendezvous ensureQrRendezvous() => $_ensure(0);

  @$pb.TagNumber(2)
  DesktopPairingRendezvous get desktopRendezvous => $_getN(1);
  @$pb.TagNumber(2)
  set desktopRendezvous(DesktopPairingRendezvous value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDesktopRendezvous() => $_has(1);
  @$pb.TagNumber(2)
  void clearDesktopRendezvous() => $_clearField(2);
  @$pb.TagNumber(2)
  DesktopPairingRendezvous ensureDesktopRendezvous() => $_ensure(1);

  @$pb.TagNumber(3)
  PairingHello get hello => $_getN(2);
  @$pb.TagNumber(3)
  set hello(PairingHello value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasHello() => $_has(2);
  @$pb.TagNumber(3)
  void clearHello() => $_clearField(3);
  @$pb.TagNumber(3)
  PairingHello ensureHello() => $_ensure(2);

  @$pb.TagNumber(4)
  PairingConfirmationData get confirmation => $_getN(3);
  @$pb.TagNumber(4)
  set confirmation(PairingConfirmationData value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasConfirmation() => $_has(3);
  @$pb.TagNumber(4)
  void clearConfirmation() => $_clearField(4);
  @$pb.TagNumber(4)
  PairingConfirmationData ensureConfirmation() => $_ensure(3);

  @$pb.TagNumber(5)
  PairingDecision get decision => $_getN(4);
  @$pb.TagNumber(5)
  set decision(PairingDecision value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasDecision() => $_has(4);
  @$pb.TagNumber(5)
  void clearDecision() => $_clearField(5);
  @$pb.TagNumber(5)
  PairingDecision ensureDecision() => $_ensure(4);

  @$pb.TagNumber(6)
  HostPairingInvitation get hostInvitation => $_getN(5);
  @$pb.TagNumber(6)
  set hostInvitation(HostPairingInvitation value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasHostInvitation() => $_has(5);
  @$pb.TagNumber(6)
  void clearHostInvitation() => $_clearField(6);
  @$pb.TagNumber(6)
  HostPairingInvitation ensureHostInvitation() => $_ensure(5);

  @$pb.TagNumber(7)
  ControllerPairingHello get controllerHello => $_getN(6);
  @$pb.TagNumber(7)
  set controllerHello(ControllerPairingHello value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasControllerHello() => $_has(6);
  @$pb.TagNumber(7)
  void clearControllerHello() => $_clearField(7);
  @$pb.TagNumber(7)
  ControllerPairingHello ensureControllerHello() => $_ensure(6);

  @$pb.TagNumber(8)
  EncryptedPairingEnvelope get encryptedEnvelope => $_getN(7);
  @$pb.TagNumber(8)
  set encryptedEnvelope(EncryptedPairingEnvelope value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasEncryptedEnvelope() => $_has(7);
  @$pb.TagNumber(8)
  void clearEncryptedEnvelope() => $_clearField(8);
  @$pb.TagNumber(8)
  EncryptedPairingEnvelope ensureEncryptedEnvelope() => $_ensure(7);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
