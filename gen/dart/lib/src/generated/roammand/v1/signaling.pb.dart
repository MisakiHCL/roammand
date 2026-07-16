// SPDX-License-Identifier: Apache-2.0

// This is a generated file - do not edit.
//
// Generated from roammand/v1/signaling.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'error.pb.dart' as $5;
import 'pairing.pb.dart' as $1;
import 'session.pb.dart' as $2;
import 'status.pb.dart' as $4;
import 'version.pb.dart' as $0;
import 'webrtc.pb.dart' as $3;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

enum SignalingEnvelope_Payload {
  capabilityNegotiation,
  pairing,
  sessionAuthentication,
  webrtcNegotiation,
  sessionStatus,
  error,
  notSet
}

class SignalingEnvelope extends $pb.GeneratedMessage {
  factory SignalingEnvelope({
    $0.ProtocolVersion? protocolVersion,
    $core.List<$core.int>? senderDeviceId,
    $core.List<$core.int>? recipientDeviceId,
    $core.String? requestId,
    $fixnum.Int64? sentAtUnixMs,
    $0.CapabilityNegotiation? capabilityNegotiation,
    $1.PairingMessage? pairing,
    $2.SessionAuthentication? sessionAuthentication,
    $3.WebRtcNegotiation? webrtcNegotiation,
    $4.SessionStatus? sessionStatus,
    $5.UnifiedError? error,
  }) {
    final result = create();
    if (protocolVersion != null) result.protocolVersion = protocolVersion;
    if (senderDeviceId != null) result.senderDeviceId = senderDeviceId;
    if (recipientDeviceId != null) result.recipientDeviceId = recipientDeviceId;
    if (requestId != null) result.requestId = requestId;
    if (sentAtUnixMs != null) result.sentAtUnixMs = sentAtUnixMs;
    if (capabilityNegotiation != null)
      result.capabilityNegotiation = capabilityNegotiation;
    if (pairing != null) result.pairing = pairing;
    if (sessionAuthentication != null)
      result.sessionAuthentication = sessionAuthentication;
    if (webrtcNegotiation != null) result.webrtcNegotiation = webrtcNegotiation;
    if (sessionStatus != null) result.sessionStatus = sessionStatus;
    if (error != null) result.error = error;
    return result;
  }

  SignalingEnvelope._();

  factory SignalingEnvelope.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SignalingEnvelope.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, SignalingEnvelope_Payload>
      _SignalingEnvelope_PayloadByTag = {
    10: SignalingEnvelope_Payload.capabilityNegotiation,
    11: SignalingEnvelope_Payload.pairing,
    12: SignalingEnvelope_Payload.sessionAuthentication,
    13: SignalingEnvelope_Payload.webrtcNegotiation,
    14: SignalingEnvelope_Payload.sessionStatus,
    15: SignalingEnvelope_Payload.error,
    0: SignalingEnvelope_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SignalingEnvelope',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..oo(0, [10, 11, 12, 13, 14, 15])
    ..aOM<$0.ProtocolVersion>(1, _omitFieldNames ? '' : 'protocolVersion',
        subBuilder: $0.ProtocolVersion.create)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'senderDeviceId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'recipientDeviceId', $pb.PbFieldType.OY)
    ..aOS(4, _omitFieldNames ? '' : 'requestId')
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'sentAtUnixMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<$0.CapabilityNegotiation>(
        10, _omitFieldNames ? '' : 'capabilityNegotiation',
        subBuilder: $0.CapabilityNegotiation.create)
    ..aOM<$1.PairingMessage>(11, _omitFieldNames ? '' : 'pairing',
        subBuilder: $1.PairingMessage.create)
    ..aOM<$2.SessionAuthentication>(
        12, _omitFieldNames ? '' : 'sessionAuthentication',
        subBuilder: $2.SessionAuthentication.create)
    ..aOM<$3.WebRtcNegotiation>(13, _omitFieldNames ? '' : 'webrtcNegotiation',
        subBuilder: $3.WebRtcNegotiation.create)
    ..aOM<$4.SessionStatus>(14, _omitFieldNames ? '' : 'sessionStatus',
        subBuilder: $4.SessionStatus.create)
    ..aOM<$5.UnifiedError>(15, _omitFieldNames ? '' : 'error',
        subBuilder: $5.UnifiedError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SignalingEnvelope clone() => SignalingEnvelope()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SignalingEnvelope copyWith(void Function(SignalingEnvelope) updates) =>
      super.copyWith((message) => updates(message as SignalingEnvelope))
          as SignalingEnvelope;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SignalingEnvelope create() => SignalingEnvelope._();
  @$core.override
  SignalingEnvelope createEmptyInstance() => create();
  static $pb.PbList<SignalingEnvelope> createRepeated() =>
      $pb.PbList<SignalingEnvelope>();
  @$core.pragma('dart2js:noInline')
  static SignalingEnvelope getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SignalingEnvelope>(create);
  static SignalingEnvelope? _defaultInstance;

  SignalingEnvelope_Payload whichPayload() =>
      _SignalingEnvelope_PayloadByTag[$_whichOneof(0)]!;
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
  $core.List<$core.int> get senderDeviceId => $_getN(1);
  @$pb.TagNumber(2)
  set senderDeviceId($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSenderDeviceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSenderDeviceId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get recipientDeviceId => $_getN(2);
  @$pb.TagNumber(3)
  set recipientDeviceId($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRecipientDeviceId() => $_has(2);
  @$pb.TagNumber(3)
  void clearRecipientDeviceId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get requestId => $_getSZ(3);
  @$pb.TagNumber(4)
  set requestId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRequestId() => $_has(3);
  @$pb.TagNumber(4)
  void clearRequestId() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get sentAtUnixMs => $_getI64(4);
  @$pb.TagNumber(5)
  set sentAtUnixMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSentAtUnixMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearSentAtUnixMs() => $_clearField(5);

  @$pb.TagNumber(10)
  $0.CapabilityNegotiation get capabilityNegotiation => $_getN(5);
  @$pb.TagNumber(10)
  set capabilityNegotiation($0.CapabilityNegotiation value) =>
      $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasCapabilityNegotiation() => $_has(5);
  @$pb.TagNumber(10)
  void clearCapabilityNegotiation() => $_clearField(10);
  @$pb.TagNumber(10)
  $0.CapabilityNegotiation ensureCapabilityNegotiation() => $_ensure(5);

  @$pb.TagNumber(11)
  $1.PairingMessage get pairing => $_getN(6);
  @$pb.TagNumber(11)
  set pairing($1.PairingMessage value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasPairing() => $_has(6);
  @$pb.TagNumber(11)
  void clearPairing() => $_clearField(11);
  @$pb.TagNumber(11)
  $1.PairingMessage ensurePairing() => $_ensure(6);

  @$pb.TagNumber(12)
  $2.SessionAuthentication get sessionAuthentication => $_getN(7);
  @$pb.TagNumber(12)
  set sessionAuthentication($2.SessionAuthentication value) =>
      $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasSessionAuthentication() => $_has(7);
  @$pb.TagNumber(12)
  void clearSessionAuthentication() => $_clearField(12);
  @$pb.TagNumber(12)
  $2.SessionAuthentication ensureSessionAuthentication() => $_ensure(7);

  @$pb.TagNumber(13)
  $3.WebRtcNegotiation get webrtcNegotiation => $_getN(8);
  @$pb.TagNumber(13)
  set webrtcNegotiation($3.WebRtcNegotiation value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasWebrtcNegotiation() => $_has(8);
  @$pb.TagNumber(13)
  void clearWebrtcNegotiation() => $_clearField(13);
  @$pb.TagNumber(13)
  $3.WebRtcNegotiation ensureWebrtcNegotiation() => $_ensure(8);

  @$pb.TagNumber(14)
  $4.SessionStatus get sessionStatus => $_getN(9);
  @$pb.TagNumber(14)
  set sessionStatus($4.SessionStatus value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasSessionStatus() => $_has(9);
  @$pb.TagNumber(14)
  void clearSessionStatus() => $_clearField(14);
  @$pb.TagNumber(14)
  $4.SessionStatus ensureSessionStatus() => $_ensure(9);

  @$pb.TagNumber(15)
  $5.UnifiedError get error => $_getN(10);
  @$pb.TagNumber(15)
  set error($5.UnifiedError value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasError() => $_has(10);
  @$pb.TagNumber(15)
  void clearError() => $_clearField(15);
  @$pb.TagNumber(15)
  $5.UnifiedError ensureError() => $_ensure(10);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
