// SPDX-License-Identifier: Apache-2.0

// This is a generated file - do not edit.
//
// Generated from roammand/v1/webrtc.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'webrtc.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'webrtc.pbenum.dart';

class WebRtcSessionDescription extends $pb.GeneratedMessage {
  factory WebRtcSessionDescription({
    SessionDescriptionType? type,
    $core.String? sdp,
    $core.List<$core.int>? dtlsFingerprintSha256,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (sdp != null) result.sdp = sdp;
    if (dtlsFingerprintSha256 != null)
      result.dtlsFingerprintSha256 = dtlsFingerprintSha256;
    return result;
  }

  WebRtcSessionDescription._();

  factory WebRtcSessionDescription.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WebRtcSessionDescription.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WebRtcSessionDescription',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..e<SessionDescriptionType>(
        1, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE,
        defaultOrMaker:
            SessionDescriptionType.SESSION_DESCRIPTION_TYPE_UNSPECIFIED,
        valueOf: SessionDescriptionType.valueOf,
        enumValues: SessionDescriptionType.values)
    ..aOS(2, _omitFieldNames ? '' : 'sdp')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'dtlsFingerprintSha256', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebRtcSessionDescription clone() =>
      WebRtcSessionDescription()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebRtcSessionDescription copyWith(
          void Function(WebRtcSessionDescription) updates) =>
      super.copyWith((message) => updates(message as WebRtcSessionDescription))
          as WebRtcSessionDescription;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WebRtcSessionDescription create() => WebRtcSessionDescription._();
  @$core.override
  WebRtcSessionDescription createEmptyInstance() => create();
  static $pb.PbList<WebRtcSessionDescription> createRepeated() =>
      $pb.PbList<WebRtcSessionDescription>();
  @$core.pragma('dart2js:noInline')
  static WebRtcSessionDescription getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WebRtcSessionDescription>(create);
  static WebRtcSessionDescription? _defaultInstance;

  @$pb.TagNumber(1)
  SessionDescriptionType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SessionDescriptionType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sdp => $_getSZ(1);
  @$pb.TagNumber(2)
  set sdp($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSdp() => $_has(1);
  @$pb.TagNumber(2)
  void clearSdp() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get dtlsFingerprintSha256 => $_getN(2);
  @$pb.TagNumber(3)
  set dtlsFingerprintSha256($core.List<$core.int> value) =>
      $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDtlsFingerprintSha256() => $_has(2);
  @$pb.TagNumber(3)
  void clearDtlsFingerprintSha256() => $_clearField(3);
}

class IceCandidate extends $pb.GeneratedMessage {
  factory IceCandidate({
    $core.String? candidate,
    $core.String? sdpMid,
    $core.int? sdpMLineIndex,
  }) {
    final result = create();
    if (candidate != null) result.candidate = candidate;
    if (sdpMid != null) result.sdpMid = sdpMid;
    if (sdpMLineIndex != null) result.sdpMLineIndex = sdpMLineIndex;
    return result;
  }

  IceCandidate._();

  factory IceCandidate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IceCandidate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IceCandidate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'candidate')
    ..aOS(2, _omitFieldNames ? '' : 'sdpMid')
    ..a<$core.int>(
        3, _omitFieldNames ? '' : 'sdpMLineIndex', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IceCandidate clone() => IceCandidate()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IceCandidate copyWith(void Function(IceCandidate) updates) =>
      super.copyWith((message) => updates(message as IceCandidate))
          as IceCandidate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IceCandidate create() => IceCandidate._();
  @$core.override
  IceCandidate createEmptyInstance() => create();
  static $pb.PbList<IceCandidate> createRepeated() =>
      $pb.PbList<IceCandidate>();
  @$core.pragma('dart2js:noInline')
  static IceCandidate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<IceCandidate>(create);
  static IceCandidate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get candidate => $_getSZ(0);
  @$pb.TagNumber(1)
  set candidate($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCandidate() => $_has(0);
  @$pb.TagNumber(1)
  void clearCandidate() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sdpMid => $_getSZ(1);
  @$pb.TagNumber(2)
  set sdpMid($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSdpMid() => $_has(1);
  @$pb.TagNumber(2)
  void clearSdpMid() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get sdpMLineIndex => $_getIZ(2);
  @$pb.TagNumber(3)
  set sdpMLineIndex($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSdpMLineIndex() => $_has(2);
  @$pb.TagNumber(3)
  void clearSdpMLineIndex() => $_clearField(3);
}

class EndOfCandidates extends $pb.GeneratedMessage {
  factory EndOfCandidates() => create();

  EndOfCandidates._();

  factory EndOfCandidates.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EndOfCandidates.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EndOfCandidates',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EndOfCandidates clone() => EndOfCandidates()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EndOfCandidates copyWith(void Function(EndOfCandidates) updates) =>
      super.copyWith((message) => updates(message as EndOfCandidates))
          as EndOfCandidates;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EndOfCandidates create() => EndOfCandidates._();
  @$core.override
  EndOfCandidates createEmptyInstance() => create();
  static $pb.PbList<EndOfCandidates> createRepeated() =>
      $pb.PbList<EndOfCandidates>();
  @$core.pragma('dart2js:noInline')
  static EndOfCandidates getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EndOfCandidates>(create);
  static EndOfCandidates? _defaultInstance;
}

enum WebRtcNegotiation_Payload {
  description,
  iceCandidate,
  endOfCandidates,
  notSet
}

class WebRtcNegotiation extends $pb.GeneratedMessage {
  factory WebRtcNegotiation({
    $core.List<$core.int>? sessionId,
    WebRtcSessionDescription? description,
    IceCandidate? iceCandidate,
    EndOfCandidates? endOfCandidates,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (description != null) result.description = description;
    if (iceCandidate != null) result.iceCandidate = iceCandidate;
    if (endOfCandidates != null) result.endOfCandidates = endOfCandidates;
    return result;
  }

  WebRtcNegotiation._();

  factory WebRtcNegotiation.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WebRtcNegotiation.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, WebRtcNegotiation_Payload>
      _WebRtcNegotiation_PayloadByTag = {
    2: WebRtcNegotiation_Payload.description,
    3: WebRtcNegotiation_Payload.iceCandidate,
    4: WebRtcNegotiation_Payload.endOfCandidates,
    0: WebRtcNegotiation_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WebRtcNegotiation',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..oo(0, [2, 3, 4])
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'sessionId', $pb.PbFieldType.OY)
    ..aOM<WebRtcSessionDescription>(2, _omitFieldNames ? '' : 'description',
        subBuilder: WebRtcSessionDescription.create)
    ..aOM<IceCandidate>(3, _omitFieldNames ? '' : 'iceCandidate',
        subBuilder: IceCandidate.create)
    ..aOM<EndOfCandidates>(4, _omitFieldNames ? '' : 'endOfCandidates',
        subBuilder: EndOfCandidates.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebRtcNegotiation clone() => WebRtcNegotiation()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebRtcNegotiation copyWith(void Function(WebRtcNegotiation) updates) =>
      super.copyWith((message) => updates(message as WebRtcNegotiation))
          as WebRtcNegotiation;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WebRtcNegotiation create() => WebRtcNegotiation._();
  @$core.override
  WebRtcNegotiation createEmptyInstance() => create();
  static $pb.PbList<WebRtcNegotiation> createRepeated() =>
      $pb.PbList<WebRtcNegotiation>();
  @$core.pragma('dart2js:noInline')
  static WebRtcNegotiation getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WebRtcNegotiation>(create);
  static WebRtcNegotiation? _defaultInstance;

  WebRtcNegotiation_Payload whichPayload() =>
      _WebRtcNegotiation_PayloadByTag[$_whichOneof(0)]!;
  void clearPayload() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.List<$core.int> get sessionId => $_getN(0);
  @$pb.TagNumber(1)
  set sessionId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  WebRtcSessionDescription get description => $_getN(1);
  @$pb.TagNumber(2)
  set description(WebRtcSessionDescription value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDescription() => $_has(1);
  @$pb.TagNumber(2)
  void clearDescription() => $_clearField(2);
  @$pb.TagNumber(2)
  WebRtcSessionDescription ensureDescription() => $_ensure(1);

  @$pb.TagNumber(3)
  IceCandidate get iceCandidate => $_getN(2);
  @$pb.TagNumber(3)
  set iceCandidate(IceCandidate value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasIceCandidate() => $_has(2);
  @$pb.TagNumber(3)
  void clearIceCandidate() => $_clearField(3);
  @$pb.TagNumber(3)
  IceCandidate ensureIceCandidate() => $_ensure(2);

  @$pb.TagNumber(4)
  EndOfCandidates get endOfCandidates => $_getN(3);
  @$pb.TagNumber(4)
  set endOfCandidates(EndOfCandidates value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasEndOfCandidates() => $_has(3);
  @$pb.TagNumber(4)
  void clearEndOfCandidates() => $_clearField(4);
  @$pb.TagNumber(4)
  EndOfCandidates ensureEndOfCandidates() => $_ensure(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
