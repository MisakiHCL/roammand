// SPDX-License-Identifier: Apache-2.0

// This is a generated file - do not edit.
//
// Generated from roammand/v1/session.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'session.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'session.pbenum.dart';

class SessionOfferAuthentication extends $pb.GeneratedMessage {
  factory SessionOfferAuthentication({
    $core.List<$core.int>? controllerDeviceId,
    $core.List<$core.int>? hostDeviceId,
    $core.List<$core.int>? sessionId,
    $core.List<$core.int>? nonce,
    $fixnum.Int64? issuedAtUnixMs,
    $fixnum.Int64? expiresAtUnixMs,
    $core.Iterable<SessionPermission>? requestedPermissions,
    $core.List<$core.int>? offerSha256,
    $core.List<$core.int>? controllerDtlsFingerprintSha256,
    $core.List<$core.int>? signature,
  }) {
    final result = create();
    if (controllerDeviceId != null)
      result.controllerDeviceId = controllerDeviceId;
    if (hostDeviceId != null) result.hostDeviceId = hostDeviceId;
    if (sessionId != null) result.sessionId = sessionId;
    if (nonce != null) result.nonce = nonce;
    if (issuedAtUnixMs != null) result.issuedAtUnixMs = issuedAtUnixMs;
    if (expiresAtUnixMs != null) result.expiresAtUnixMs = expiresAtUnixMs;
    if (requestedPermissions != null)
      result.requestedPermissions.addAll(requestedPermissions);
    if (offerSha256 != null) result.offerSha256 = offerSha256;
    if (controllerDtlsFingerprintSha256 != null)
      result.controllerDtlsFingerprintSha256 = controllerDtlsFingerprintSha256;
    if (signature != null) result.signature = signature;
    return result;
  }

  SessionOfferAuthentication._();

  factory SessionOfferAuthentication.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SessionOfferAuthentication.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SessionOfferAuthentication',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'controllerDeviceId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'hostDeviceId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'sessionId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'nonce', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'issuedAtUnixMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        6, _omitFieldNames ? '' : 'expiresAtUnixMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pc<SessionPermission>(
        7, _omitFieldNames ? '' : 'requestedPermissions', $pb.PbFieldType.KE,
        valueOf: SessionPermission.valueOf,
        enumValues: SessionPermission.values,
        defaultEnumValue: SessionPermission.SESSION_PERMISSION_UNSPECIFIED)
    ..a<$core.List<$core.int>>(
        8, _omitFieldNames ? '' : 'offerSha256', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        9,
        _omitFieldNames ? '' : 'controllerDtlsFingerprintSha256',
        $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        10, _omitFieldNames ? '' : 'signature', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionOfferAuthentication clone() =>
      SessionOfferAuthentication()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionOfferAuthentication copyWith(
          void Function(SessionOfferAuthentication) updates) =>
      super.copyWith(
              (message) => updates(message as SessionOfferAuthentication))
          as SessionOfferAuthentication;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SessionOfferAuthentication create() => SessionOfferAuthentication._();
  @$core.override
  SessionOfferAuthentication createEmptyInstance() => create();
  static $pb.PbList<SessionOfferAuthentication> createRepeated() =>
      $pb.PbList<SessionOfferAuthentication>();
  @$core.pragma('dart2js:noInline')
  static SessionOfferAuthentication getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SessionOfferAuthentication>(create);
  static SessionOfferAuthentication? _defaultInstance;

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
  $core.List<$core.int> get sessionId => $_getN(2);
  @$pb.TagNumber(3)
  set sessionId($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSessionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSessionId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get nonce => $_getN(3);
  @$pb.TagNumber(4)
  set nonce($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNonce() => $_has(3);
  @$pb.TagNumber(4)
  void clearNonce() => $_clearField(4);

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

  @$pb.TagNumber(7)
  $pb.PbList<SessionPermission> get requestedPermissions => $_getList(6);

  @$pb.TagNumber(8)
  $core.List<$core.int> get offerSha256 => $_getN(7);
  @$pb.TagNumber(8)
  set offerSha256($core.List<$core.int> value) => $_setBytes(7, value);
  @$pb.TagNumber(8)
  $core.bool hasOfferSha256() => $_has(7);
  @$pb.TagNumber(8)
  void clearOfferSha256() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.List<$core.int> get controllerDtlsFingerprintSha256 => $_getN(8);
  @$pb.TagNumber(9)
  set controllerDtlsFingerprintSha256($core.List<$core.int> value) =>
      $_setBytes(8, value);
  @$pb.TagNumber(9)
  $core.bool hasControllerDtlsFingerprintSha256() => $_has(8);
  @$pb.TagNumber(9)
  void clearControllerDtlsFingerprintSha256() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.List<$core.int> get signature => $_getN(9);
  @$pb.TagNumber(10)
  set signature($core.List<$core.int> value) => $_setBytes(9, value);
  @$pb.TagNumber(10)
  $core.bool hasSignature() => $_has(9);
  @$pb.TagNumber(10)
  void clearSignature() => $_clearField(10);
}

class SessionAnswerAuthentication extends $pb.GeneratedMessage {
  factory SessionAnswerAuthentication({
    $core.List<$core.int>? controllerDeviceId,
    $core.List<$core.int>? hostDeviceId,
    $core.List<$core.int>? sessionId,
    $core.List<$core.int>? nonce,
    $fixnum.Int64? issuedAtUnixMs,
    $fixnum.Int64? expiresAtUnixMs,
    $core.Iterable<SessionPermission>? requestedPermissions,
    $core.List<$core.int>? offerSha256,
    $core.List<$core.int>? controllerDtlsFingerprintSha256,
    $core.List<$core.int>? answerSha256,
    $core.List<$core.int>? hostDtlsFingerprintSha256,
    $core.List<$core.int>? signature,
  }) {
    final result = create();
    if (controllerDeviceId != null)
      result.controllerDeviceId = controllerDeviceId;
    if (hostDeviceId != null) result.hostDeviceId = hostDeviceId;
    if (sessionId != null) result.sessionId = sessionId;
    if (nonce != null) result.nonce = nonce;
    if (issuedAtUnixMs != null) result.issuedAtUnixMs = issuedAtUnixMs;
    if (expiresAtUnixMs != null) result.expiresAtUnixMs = expiresAtUnixMs;
    if (requestedPermissions != null)
      result.requestedPermissions.addAll(requestedPermissions);
    if (offerSha256 != null) result.offerSha256 = offerSha256;
    if (controllerDtlsFingerprintSha256 != null)
      result.controllerDtlsFingerprintSha256 = controllerDtlsFingerprintSha256;
    if (answerSha256 != null) result.answerSha256 = answerSha256;
    if (hostDtlsFingerprintSha256 != null)
      result.hostDtlsFingerprintSha256 = hostDtlsFingerprintSha256;
    if (signature != null) result.signature = signature;
    return result;
  }

  SessionAnswerAuthentication._();

  factory SessionAnswerAuthentication.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SessionAnswerAuthentication.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SessionAnswerAuthentication',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'controllerDeviceId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'hostDeviceId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'sessionId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'nonce', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'issuedAtUnixMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        6, _omitFieldNames ? '' : 'expiresAtUnixMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pc<SessionPermission>(
        7, _omitFieldNames ? '' : 'requestedPermissions', $pb.PbFieldType.KE,
        valueOf: SessionPermission.valueOf,
        enumValues: SessionPermission.values,
        defaultEnumValue: SessionPermission.SESSION_PERMISSION_UNSPECIFIED)
    ..a<$core.List<$core.int>>(
        8, _omitFieldNames ? '' : 'offerSha256', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        9,
        _omitFieldNames ? '' : 'controllerDtlsFingerprintSha256',
        $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        10, _omitFieldNames ? '' : 'answerSha256', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(11,
        _omitFieldNames ? '' : 'hostDtlsFingerprintSha256', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        12, _omitFieldNames ? '' : 'signature', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionAnswerAuthentication clone() =>
      SessionAnswerAuthentication()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionAnswerAuthentication copyWith(
          void Function(SessionAnswerAuthentication) updates) =>
      super.copyWith(
              (message) => updates(message as SessionAnswerAuthentication))
          as SessionAnswerAuthentication;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SessionAnswerAuthentication create() =>
      SessionAnswerAuthentication._();
  @$core.override
  SessionAnswerAuthentication createEmptyInstance() => create();
  static $pb.PbList<SessionAnswerAuthentication> createRepeated() =>
      $pb.PbList<SessionAnswerAuthentication>();
  @$core.pragma('dart2js:noInline')
  static SessionAnswerAuthentication getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SessionAnswerAuthentication>(create);
  static SessionAnswerAuthentication? _defaultInstance;

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
  $core.List<$core.int> get sessionId => $_getN(2);
  @$pb.TagNumber(3)
  set sessionId($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSessionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSessionId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get nonce => $_getN(3);
  @$pb.TagNumber(4)
  set nonce($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNonce() => $_has(3);
  @$pb.TagNumber(4)
  void clearNonce() => $_clearField(4);

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

  @$pb.TagNumber(7)
  $pb.PbList<SessionPermission> get requestedPermissions => $_getList(6);

  @$pb.TagNumber(8)
  $core.List<$core.int> get offerSha256 => $_getN(7);
  @$pb.TagNumber(8)
  set offerSha256($core.List<$core.int> value) => $_setBytes(7, value);
  @$pb.TagNumber(8)
  $core.bool hasOfferSha256() => $_has(7);
  @$pb.TagNumber(8)
  void clearOfferSha256() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.List<$core.int> get controllerDtlsFingerprintSha256 => $_getN(8);
  @$pb.TagNumber(9)
  set controllerDtlsFingerprintSha256($core.List<$core.int> value) =>
      $_setBytes(8, value);
  @$pb.TagNumber(9)
  $core.bool hasControllerDtlsFingerprintSha256() => $_has(8);
  @$pb.TagNumber(9)
  void clearControllerDtlsFingerprintSha256() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.List<$core.int> get answerSha256 => $_getN(9);
  @$pb.TagNumber(10)
  set answerSha256($core.List<$core.int> value) => $_setBytes(9, value);
  @$pb.TagNumber(10)
  $core.bool hasAnswerSha256() => $_has(9);
  @$pb.TagNumber(10)
  void clearAnswerSha256() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.List<$core.int> get hostDtlsFingerprintSha256 => $_getN(10);
  @$pb.TagNumber(11)
  set hostDtlsFingerprintSha256($core.List<$core.int> value) =>
      $_setBytes(10, value);
  @$pb.TagNumber(11)
  $core.bool hasHostDtlsFingerprintSha256() => $_has(10);
  @$pb.TagNumber(11)
  void clearHostDtlsFingerprintSha256() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.List<$core.int> get signature => $_getN(11);
  @$pb.TagNumber(12)
  set signature($core.List<$core.int> value) => $_setBytes(11, value);
  @$pb.TagNumber(12)
  $core.bool hasSignature() => $_has(11);
  @$pb.TagNumber(12)
  void clearSignature() => $_clearField(12);
}

class SessionReconnectAuthentication extends $pb.GeneratedMessage {
  factory SessionReconnectAuthentication({
    $core.List<$core.int>? controllerDeviceId,
    $core.List<$core.int>? hostDeviceId,
    $core.List<$core.int>? sessionId,
    $core.List<$core.int>? nonce,
    $fixnum.Int64? issuedAtUnixMs,
    $fixnum.Int64? expiresAtUnixMs,
    $core.Iterable<SessionPermission>? requestedPermissions,
    $core.List<$core.int>? offerSha256,
    $core.List<$core.int>? controllerDtlsFingerprintSha256,
    $core.List<$core.int>? answerSha256,
    $core.List<$core.int>? hostDtlsFingerprintSha256,
    $core.int? reconnectGeneration,
    $core.List<$core.int>? signature,
  }) {
    final result = create();
    if (controllerDeviceId != null)
      result.controllerDeviceId = controllerDeviceId;
    if (hostDeviceId != null) result.hostDeviceId = hostDeviceId;
    if (sessionId != null) result.sessionId = sessionId;
    if (nonce != null) result.nonce = nonce;
    if (issuedAtUnixMs != null) result.issuedAtUnixMs = issuedAtUnixMs;
    if (expiresAtUnixMs != null) result.expiresAtUnixMs = expiresAtUnixMs;
    if (requestedPermissions != null)
      result.requestedPermissions.addAll(requestedPermissions);
    if (offerSha256 != null) result.offerSha256 = offerSha256;
    if (controllerDtlsFingerprintSha256 != null)
      result.controllerDtlsFingerprintSha256 = controllerDtlsFingerprintSha256;
    if (answerSha256 != null) result.answerSha256 = answerSha256;
    if (hostDtlsFingerprintSha256 != null)
      result.hostDtlsFingerprintSha256 = hostDtlsFingerprintSha256;
    if (reconnectGeneration != null)
      result.reconnectGeneration = reconnectGeneration;
    if (signature != null) result.signature = signature;
    return result;
  }

  SessionReconnectAuthentication._();

  factory SessionReconnectAuthentication.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SessionReconnectAuthentication.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SessionReconnectAuthentication',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'controllerDeviceId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'hostDeviceId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'sessionId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'nonce', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'issuedAtUnixMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        6, _omitFieldNames ? '' : 'expiresAtUnixMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pc<SessionPermission>(
        7, _omitFieldNames ? '' : 'requestedPermissions', $pb.PbFieldType.KE,
        valueOf: SessionPermission.valueOf,
        enumValues: SessionPermission.values,
        defaultEnumValue: SessionPermission.SESSION_PERMISSION_UNSPECIFIED)
    ..a<$core.List<$core.int>>(
        8, _omitFieldNames ? '' : 'offerSha256', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        9,
        _omitFieldNames ? '' : 'controllerDtlsFingerprintSha256',
        $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        10, _omitFieldNames ? '' : 'answerSha256', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(11,
        _omitFieldNames ? '' : 'hostDtlsFingerprintSha256', $pb.PbFieldType.OY)
    ..a<$core.int>(
        12, _omitFieldNames ? '' : 'reconnectGeneration', $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(
        13, _omitFieldNames ? '' : 'signature', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionReconnectAuthentication clone() =>
      SessionReconnectAuthentication()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionReconnectAuthentication copyWith(
          void Function(SessionReconnectAuthentication) updates) =>
      super.copyWith(
              (message) => updates(message as SessionReconnectAuthentication))
          as SessionReconnectAuthentication;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SessionReconnectAuthentication create() =>
      SessionReconnectAuthentication._();
  @$core.override
  SessionReconnectAuthentication createEmptyInstance() => create();
  static $pb.PbList<SessionReconnectAuthentication> createRepeated() =>
      $pb.PbList<SessionReconnectAuthentication>();
  @$core.pragma('dart2js:noInline')
  static SessionReconnectAuthentication getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SessionReconnectAuthentication>(create);
  static SessionReconnectAuthentication? _defaultInstance;

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
  $core.List<$core.int> get sessionId => $_getN(2);
  @$pb.TagNumber(3)
  set sessionId($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSessionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSessionId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get nonce => $_getN(3);
  @$pb.TagNumber(4)
  set nonce($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNonce() => $_has(3);
  @$pb.TagNumber(4)
  void clearNonce() => $_clearField(4);

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

  @$pb.TagNumber(7)
  $pb.PbList<SessionPermission> get requestedPermissions => $_getList(6);

  @$pb.TagNumber(8)
  $core.List<$core.int> get offerSha256 => $_getN(7);
  @$pb.TagNumber(8)
  set offerSha256($core.List<$core.int> value) => $_setBytes(7, value);
  @$pb.TagNumber(8)
  $core.bool hasOfferSha256() => $_has(7);
  @$pb.TagNumber(8)
  void clearOfferSha256() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.List<$core.int> get controllerDtlsFingerprintSha256 => $_getN(8);
  @$pb.TagNumber(9)
  set controllerDtlsFingerprintSha256($core.List<$core.int> value) =>
      $_setBytes(8, value);
  @$pb.TagNumber(9)
  $core.bool hasControllerDtlsFingerprintSha256() => $_has(8);
  @$pb.TagNumber(9)
  void clearControllerDtlsFingerprintSha256() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.List<$core.int> get answerSha256 => $_getN(9);
  @$pb.TagNumber(10)
  set answerSha256($core.List<$core.int> value) => $_setBytes(9, value);
  @$pb.TagNumber(10)
  $core.bool hasAnswerSha256() => $_has(9);
  @$pb.TagNumber(10)
  void clearAnswerSha256() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.List<$core.int> get hostDtlsFingerprintSha256 => $_getN(10);
  @$pb.TagNumber(11)
  set hostDtlsFingerprintSha256($core.List<$core.int> value) =>
      $_setBytes(10, value);
  @$pb.TagNumber(11)
  $core.bool hasHostDtlsFingerprintSha256() => $_has(10);
  @$pb.TagNumber(11)
  void clearHostDtlsFingerprintSha256() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get reconnectGeneration => $_getIZ(11);
  @$pb.TagNumber(12)
  set reconnectGeneration($core.int value) => $_setUnsignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasReconnectGeneration() => $_has(11);
  @$pb.TagNumber(12)
  void clearReconnectGeneration() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.List<$core.int> get signature => $_getN(12);
  @$pb.TagNumber(13)
  set signature($core.List<$core.int> value) => $_setBytes(12, value);
  @$pb.TagNumber(13)
  $core.bool hasSignature() => $_has(12);
  @$pb.TagNumber(13)
  void clearSignature() => $_clearField(13);
}

enum SessionAuthentication_Payload { offer, answer, reconnect, notSet }

class SessionAuthentication extends $pb.GeneratedMessage {
  factory SessionAuthentication({
    SessionOfferAuthentication? offer,
    SessionAnswerAuthentication? answer,
    SessionReconnectAuthentication? reconnect,
  }) {
    final result = create();
    if (offer != null) result.offer = offer;
    if (answer != null) result.answer = answer;
    if (reconnect != null) result.reconnect = reconnect;
    return result;
  }

  SessionAuthentication._();

  factory SessionAuthentication.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SessionAuthentication.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, SessionAuthentication_Payload>
      _SessionAuthentication_PayloadByTag = {
    1: SessionAuthentication_Payload.offer,
    2: SessionAuthentication_Payload.answer,
    3: SessionAuthentication_Payload.reconnect,
    0: SessionAuthentication_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SessionAuthentication',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3])
    ..aOM<SessionOfferAuthentication>(1, _omitFieldNames ? '' : 'offer',
        subBuilder: SessionOfferAuthentication.create)
    ..aOM<SessionAnswerAuthentication>(2, _omitFieldNames ? '' : 'answer',
        subBuilder: SessionAnswerAuthentication.create)
    ..aOM<SessionReconnectAuthentication>(3, _omitFieldNames ? '' : 'reconnect',
        subBuilder: SessionReconnectAuthentication.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionAuthentication clone() =>
      SessionAuthentication()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionAuthentication copyWith(
          void Function(SessionAuthentication) updates) =>
      super.copyWith((message) => updates(message as SessionAuthentication))
          as SessionAuthentication;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SessionAuthentication create() => SessionAuthentication._();
  @$core.override
  SessionAuthentication createEmptyInstance() => create();
  static $pb.PbList<SessionAuthentication> createRepeated() =>
      $pb.PbList<SessionAuthentication>();
  @$core.pragma('dart2js:noInline')
  static SessionAuthentication getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SessionAuthentication>(create);
  static SessionAuthentication? _defaultInstance;

  SessionAuthentication_Payload whichPayload() =>
      _SessionAuthentication_PayloadByTag[$_whichOneof(0)]!;
  void clearPayload() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  SessionOfferAuthentication get offer => $_getN(0);
  @$pb.TagNumber(1)
  set offer(SessionOfferAuthentication value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasOffer() => $_has(0);
  @$pb.TagNumber(1)
  void clearOffer() => $_clearField(1);
  @$pb.TagNumber(1)
  SessionOfferAuthentication ensureOffer() => $_ensure(0);

  @$pb.TagNumber(2)
  SessionAnswerAuthentication get answer => $_getN(1);
  @$pb.TagNumber(2)
  set answer(SessionAnswerAuthentication value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasAnswer() => $_has(1);
  @$pb.TagNumber(2)
  void clearAnswer() => $_clearField(2);
  @$pb.TagNumber(2)
  SessionAnswerAuthentication ensureAnswer() => $_ensure(1);

  @$pb.TagNumber(3)
  SessionReconnectAuthentication get reconnect => $_getN(2);
  @$pb.TagNumber(3)
  set reconnect(SessionReconnectAuthentication value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasReconnect() => $_has(2);
  @$pb.TagNumber(3)
  void clearReconnect() => $_clearField(3);
  @$pb.TagNumber(3)
  SessionReconnectAuthentication ensureReconnect() => $_ensure(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
