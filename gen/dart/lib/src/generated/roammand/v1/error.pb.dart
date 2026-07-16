// SPDX-License-Identifier: Apache-2.0

// This is a generated file - do not edit.
//
// Generated from roammand/v1/error.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'error.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'error.pbenum.dart';

class RetryAfterDetails extends $pb.GeneratedMessage {
  factory RetryAfterDetails({
    $fixnum.Int64? retryAfterMs,
  }) {
    final result = create();
    if (retryAfterMs != null) result.retryAfterMs = retryAfterMs;
    return result;
  }

  RetryAfterDetails._();

  factory RetryAfterDetails.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RetryAfterDetails.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RetryAfterDetails',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'retryAfterMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RetryAfterDetails clone() => RetryAfterDetails()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RetryAfterDetails copyWith(void Function(RetryAfterDetails) updates) =>
      super.copyWith((message) => updates(message as RetryAfterDetails))
          as RetryAfterDetails;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RetryAfterDetails create() => RetryAfterDetails._();
  @$core.override
  RetryAfterDetails createEmptyInstance() => create();
  static $pb.PbList<RetryAfterDetails> createRepeated() =>
      $pb.PbList<RetryAfterDetails>();
  @$core.pragma('dart2js:noInline')
  static RetryAfterDetails getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RetryAfterDetails>(create);
  static RetryAfterDetails? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get retryAfterMs => $_getI64(0);
  @$pb.TagNumber(1)
  set retryAfterMs($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRetryAfterMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearRetryAfterMs() => $_clearField(1);
}

class PermissionDetails extends $pb.GeneratedMessage {
  factory PermissionDetails({
    $core.String? permission,
  }) {
    final result = create();
    if (permission != null) result.permission = permission;
    return result;
  }

  PermissionDetails._();

  factory PermissionDetails.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PermissionDetails.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PermissionDetails',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'permission')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PermissionDetails clone() => PermissionDetails()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PermissionDetails copyWith(void Function(PermissionDetails) updates) =>
      super.copyWith((message) => updates(message as PermissionDetails))
          as PermissionDetails;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PermissionDetails create() => PermissionDetails._();
  @$core.override
  PermissionDetails createEmptyInstance() => create();
  static $pb.PbList<PermissionDetails> createRepeated() =>
      $pb.PbList<PermissionDetails>();
  @$core.pragma('dart2js:noInline')
  static PermissionDetails getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PermissionDetails>(create);
  static PermissionDetails? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get permission => $_getSZ(0);
  @$pb.TagNumber(1)
  set permission($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPermission() => $_has(0);
  @$pb.TagNumber(1)
  void clearPermission() => $_clearField(1);
}

class CodecDetails extends $pb.GeneratedMessage {
  factory CodecDetails({
    $core.Iterable<$core.String>? supportedCodecs,
  }) {
    final result = create();
    if (supportedCodecs != null) result.supportedCodecs.addAll(supportedCodecs);
    return result;
  }

  CodecDetails._();

  factory CodecDetails.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CodecDetails.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CodecDetails',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'supportedCodecs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CodecDetails clone() => CodecDetails()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CodecDetails copyWith(void Function(CodecDetails) updates) =>
      super.copyWith((message) => updates(message as CodecDetails))
          as CodecDetails;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CodecDetails create() => CodecDetails._();
  @$core.override
  CodecDetails createEmptyInstance() => create();
  static $pb.PbList<CodecDetails> createRepeated() =>
      $pb.PbList<CodecDetails>();
  @$core.pragma('dart2js:noInline')
  static CodecDetails getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CodecDetails>(create);
  static CodecDetails? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get supportedCodecs => $_getList(0);
}

class TransportDetails extends $pb.GeneratedMessage {
  factory TransportDetails({
    $core.String? transport,
  }) {
    final result = create();
    if (transport != null) result.transport = transport;
    return result;
  }

  TransportDetails._();

  factory TransportDetails.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TransportDetails.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TransportDetails',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'transport')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TransportDetails clone() => TransportDetails()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TransportDetails copyWith(void Function(TransportDetails) updates) =>
      super.copyWith((message) => updates(message as TransportDetails))
          as TransportDetails;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TransportDetails create() => TransportDetails._();
  @$core.override
  TransportDetails createEmptyInstance() => create();
  static $pb.PbList<TransportDetails> createRepeated() =>
      $pb.PbList<TransportDetails>();
  @$core.pragma('dart2js:noInline')
  static TransportDetails getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TransportDetails>(create);
  static TransportDetails? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get transport => $_getSZ(0);
  @$pb.TagNumber(1)
  set transport($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTransport() => $_has(0);
  @$pb.TagNumber(1)
  void clearTransport() => $_clearField(1);
}

enum UnifiedError_Details { retryAfter, permission, codec, transport, notSet }

class UnifiedError extends $pb.GeneratedMessage {
  factory UnifiedError({
    ErrorCode? code,
    $core.String? messageKey,
    $core.bool? retryable,
    $core.String? requestId,
    RetryAfterDetails? retryAfter,
    PermissionDetails? permission,
    CodecDetails? codec,
    TransportDetails? transport,
  }) {
    final result = create();
    if (code != null) result.code = code;
    if (messageKey != null) result.messageKey = messageKey;
    if (retryable != null) result.retryable = retryable;
    if (requestId != null) result.requestId = requestId;
    if (retryAfter != null) result.retryAfter = retryAfter;
    if (permission != null) result.permission = permission;
    if (codec != null) result.codec = codec;
    if (transport != null) result.transport = transport;
    return result;
  }

  UnifiedError._();

  factory UnifiedError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UnifiedError.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, UnifiedError_Details>
      _UnifiedError_DetailsByTag = {
    10: UnifiedError_Details.retryAfter,
    11: UnifiedError_Details.permission,
    12: UnifiedError_Details.codec,
    13: UnifiedError_Details.transport,
    0: UnifiedError_Details.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UnifiedError',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..oo(0, [10, 11, 12, 13])
    ..e<ErrorCode>(1, _omitFieldNames ? '' : 'code', $pb.PbFieldType.OE,
        defaultOrMaker: ErrorCode.ERROR_CODE_UNSPECIFIED,
        valueOf: ErrorCode.valueOf,
        enumValues: ErrorCode.values)
    ..aOS(2, _omitFieldNames ? '' : 'messageKey')
    ..aOB(3, _omitFieldNames ? '' : 'retryable')
    ..aOS(4, _omitFieldNames ? '' : 'requestId')
    ..aOM<RetryAfterDetails>(10, _omitFieldNames ? '' : 'retryAfter',
        subBuilder: RetryAfterDetails.create)
    ..aOM<PermissionDetails>(11, _omitFieldNames ? '' : 'permission',
        subBuilder: PermissionDetails.create)
    ..aOM<CodecDetails>(12, _omitFieldNames ? '' : 'codec',
        subBuilder: CodecDetails.create)
    ..aOM<TransportDetails>(13, _omitFieldNames ? '' : 'transport',
        subBuilder: TransportDetails.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnifiedError clone() => UnifiedError()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnifiedError copyWith(void Function(UnifiedError) updates) =>
      super.copyWith((message) => updates(message as UnifiedError))
          as UnifiedError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UnifiedError create() => UnifiedError._();
  @$core.override
  UnifiedError createEmptyInstance() => create();
  static $pb.PbList<UnifiedError> createRepeated() =>
      $pb.PbList<UnifiedError>();
  @$core.pragma('dart2js:noInline')
  static UnifiedError getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UnifiedError>(create);
  static UnifiedError? _defaultInstance;

  UnifiedError_Details whichDetails() =>
      _UnifiedError_DetailsByTag[$_whichOneof(0)]!;
  void clearDetails() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ErrorCode get code => $_getN(0);
  @$pb.TagNumber(1)
  set code(ErrorCode value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get messageKey => $_getSZ(1);
  @$pb.TagNumber(2)
  set messageKey($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessageKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessageKey() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get retryable => $_getBF(2);
  @$pb.TagNumber(3)
  set retryable($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRetryable() => $_has(2);
  @$pb.TagNumber(3)
  void clearRetryable() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get requestId => $_getSZ(3);
  @$pb.TagNumber(4)
  set requestId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRequestId() => $_has(3);
  @$pb.TagNumber(4)
  void clearRequestId() => $_clearField(4);

  @$pb.TagNumber(10)
  RetryAfterDetails get retryAfter => $_getN(4);
  @$pb.TagNumber(10)
  set retryAfter(RetryAfterDetails value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasRetryAfter() => $_has(4);
  @$pb.TagNumber(10)
  void clearRetryAfter() => $_clearField(10);
  @$pb.TagNumber(10)
  RetryAfterDetails ensureRetryAfter() => $_ensure(4);

  @$pb.TagNumber(11)
  PermissionDetails get permission => $_getN(5);
  @$pb.TagNumber(11)
  set permission(PermissionDetails value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasPermission() => $_has(5);
  @$pb.TagNumber(11)
  void clearPermission() => $_clearField(11);
  @$pb.TagNumber(11)
  PermissionDetails ensurePermission() => $_ensure(5);

  @$pb.TagNumber(12)
  CodecDetails get codec => $_getN(6);
  @$pb.TagNumber(12)
  set codec(CodecDetails value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasCodec() => $_has(6);
  @$pb.TagNumber(12)
  void clearCodec() => $_clearField(12);
  @$pb.TagNumber(12)
  CodecDetails ensureCodec() => $_ensure(6);

  @$pb.TagNumber(13)
  TransportDetails get transport => $_getN(7);
  @$pb.TagNumber(13)
  set transport(TransportDetails value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasTransport() => $_has(7);
  @$pb.TagNumber(13)
  void clearTransport() => $_clearField(13);
  @$pb.TagNumber(13)
  TransportDetails ensureTransport() => $_ensure(7);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
