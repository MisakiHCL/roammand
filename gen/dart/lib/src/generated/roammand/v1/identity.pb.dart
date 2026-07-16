// SPDX-License-Identifier: Apache-2.0

// This is a generated file - do not edit.
//
// Generated from roammand/v1/identity.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'identity.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'identity.pbenum.dart';

class DeviceIdentity extends $pb.GeneratedMessage {
  factory DeviceIdentity({
    $core.List<$core.int>? deviceId,
    PublicKeyAlgorithm? publicKeyAlgorithm,
    $core.List<$core.int>? publicKey,
    $core.String? displayName,
    DevicePlatform? platform,
  }) {
    final result = create();
    if (deviceId != null) result.deviceId = deviceId;
    if (publicKeyAlgorithm != null)
      result.publicKeyAlgorithm = publicKeyAlgorithm;
    if (publicKey != null) result.publicKey = publicKey;
    if (displayName != null) result.displayName = displayName;
    if (platform != null) result.platform = platform;
    return result;
  }

  DeviceIdentity._();

  factory DeviceIdentity.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeviceIdentity.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeviceIdentity',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'deviceId', $pb.PbFieldType.OY)
    ..e<PublicKeyAlgorithm>(
        2, _omitFieldNames ? '' : 'publicKeyAlgorithm', $pb.PbFieldType.OE,
        defaultOrMaker: PublicKeyAlgorithm.PUBLIC_KEY_ALGORITHM_UNSPECIFIED,
        valueOf: PublicKeyAlgorithm.valueOf,
        enumValues: PublicKeyAlgorithm.values)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'publicKey', $pb.PbFieldType.OY)
    ..aOS(4, _omitFieldNames ? '' : 'displayName')
    ..e<DevicePlatform>(
        5, _omitFieldNames ? '' : 'platform', $pb.PbFieldType.OE,
        defaultOrMaker: DevicePlatform.DEVICE_PLATFORM_UNSPECIFIED,
        valueOf: DevicePlatform.valueOf,
        enumValues: DevicePlatform.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceIdentity clone() => DeviceIdentity()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceIdentity copyWith(void Function(DeviceIdentity) updates) =>
      super.copyWith((message) => updates(message as DeviceIdentity))
          as DeviceIdentity;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeviceIdentity create() => DeviceIdentity._();
  @$core.override
  DeviceIdentity createEmptyInstance() => create();
  static $pb.PbList<DeviceIdentity> createRepeated() =>
      $pb.PbList<DeviceIdentity>();
  @$core.pragma('dart2js:noInline')
  static DeviceIdentity getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeviceIdentity>(create);
  static DeviceIdentity? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get deviceId => $_getN(0);
  @$pb.TagNumber(1)
  set deviceId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => $_clearField(1);

  @$pb.TagNumber(2)
  PublicKeyAlgorithm get publicKeyAlgorithm => $_getN(1);
  @$pb.TagNumber(2)
  set publicKeyAlgorithm(PublicKeyAlgorithm value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPublicKeyAlgorithm() => $_has(1);
  @$pb.TagNumber(2)
  void clearPublicKeyAlgorithm() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get publicKey => $_getN(2);
  @$pb.TagNumber(3)
  set publicKey($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPublicKey() => $_has(2);
  @$pb.TagNumber(3)
  void clearPublicKey() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get displayName => $_getSZ(3);
  @$pb.TagNumber(4)
  set displayName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDisplayName() => $_has(3);
  @$pb.TagNumber(4)
  void clearDisplayName() => $_clearField(4);

  @$pb.TagNumber(5)
  DevicePlatform get platform => $_getN(4);
  @$pb.TagNumber(5)
  set platform(DevicePlatform value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasPlatform() => $_has(4);
  @$pb.TagNumber(5)
  void clearPlatform() => $_clearField(5);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
