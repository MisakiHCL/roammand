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

class DevicePlatform extends $pb.ProtobufEnum {
  static const DevicePlatform DEVICE_PLATFORM_UNSPECIFIED =
      DevicePlatform._(0, _omitEnumNames ? '' : 'DEVICE_PLATFORM_UNSPECIFIED');
  static const DevicePlatform DEVICE_PLATFORM_IOS =
      DevicePlatform._(1, _omitEnumNames ? '' : 'DEVICE_PLATFORM_IOS');
  static const DevicePlatform DEVICE_PLATFORM_ANDROID =
      DevicePlatform._(2, _omitEnumNames ? '' : 'DEVICE_PLATFORM_ANDROID');
  static const DevicePlatform DEVICE_PLATFORM_WINDOWS =
      DevicePlatform._(3, _omitEnumNames ? '' : 'DEVICE_PLATFORM_WINDOWS');
  static const DevicePlatform DEVICE_PLATFORM_MACOS =
      DevicePlatform._(4, _omitEnumNames ? '' : 'DEVICE_PLATFORM_MACOS');

  static const $core.List<DevicePlatform> values = <DevicePlatform>[
    DEVICE_PLATFORM_UNSPECIFIED,
    DEVICE_PLATFORM_IOS,
    DEVICE_PLATFORM_ANDROID,
    DEVICE_PLATFORM_WINDOWS,
    DEVICE_PLATFORM_MACOS,
  ];

  static final $core.List<DevicePlatform?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static DevicePlatform? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const DevicePlatform._(super.value, super.name);
}

class PublicKeyAlgorithm extends $pb.ProtobufEnum {
  static const PublicKeyAlgorithm PUBLIC_KEY_ALGORITHM_UNSPECIFIED =
      PublicKeyAlgorithm._(
          0, _omitEnumNames ? '' : 'PUBLIC_KEY_ALGORITHM_UNSPECIFIED');
  static const PublicKeyAlgorithm PUBLIC_KEY_ALGORITHM_ED25519 =
      PublicKeyAlgorithm._(
          1, _omitEnumNames ? '' : 'PUBLIC_KEY_ALGORITHM_ED25519');

  static const $core.List<PublicKeyAlgorithm> values = <PublicKeyAlgorithm>[
    PUBLIC_KEY_ALGORITHM_UNSPECIFIED,
    PUBLIC_KEY_ALGORITHM_ED25519,
  ];

  static final $core.List<PublicKeyAlgorithm?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static PublicKeyAlgorithm? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PublicKeyAlgorithm._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
