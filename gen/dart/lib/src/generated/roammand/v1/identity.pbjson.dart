// SPDX-License-Identifier: Apache-2.0

// This is a generated file - do not edit.
//
// Generated from roammand/v1/identity.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use devicePlatformDescriptor instead')
const DevicePlatform$json = {
  '1': 'DevicePlatform',
  '2': [
    {'1': 'DEVICE_PLATFORM_UNSPECIFIED', '2': 0},
    {'1': 'DEVICE_PLATFORM_IOS', '2': 1},
    {'1': 'DEVICE_PLATFORM_ANDROID', '2': 2},
    {'1': 'DEVICE_PLATFORM_WINDOWS', '2': 3},
    {'1': 'DEVICE_PLATFORM_MACOS', '2': 4},
  ],
};

/// Descriptor for `DevicePlatform`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List devicePlatformDescriptor = $convert.base64Decode(
    'Cg5EZXZpY2VQbGF0Zm9ybRIfChtERVZJQ0VfUExBVEZPUk1fVU5TUEVDSUZJRUQQABIXChNERV'
    'ZJQ0VfUExBVEZPUk1fSU9TEAESGwoXREVWSUNFX1BMQVRGT1JNX0FORFJPSUQQAhIbChdERVZJ'
    'Q0VfUExBVEZPUk1fV0lORE9XUxADEhkKFURFVklDRV9QTEFURk9STV9NQUNPUxAE');

@$core.Deprecated('Use publicKeyAlgorithmDescriptor instead')
const PublicKeyAlgorithm$json = {
  '1': 'PublicKeyAlgorithm',
  '2': [
    {'1': 'PUBLIC_KEY_ALGORITHM_UNSPECIFIED', '2': 0},
    {'1': 'PUBLIC_KEY_ALGORITHM_ED25519', '2': 1},
  ],
};

/// Descriptor for `PublicKeyAlgorithm`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List publicKeyAlgorithmDescriptor = $convert.base64Decode(
    'ChJQdWJsaWNLZXlBbGdvcml0aG0SJAogUFVCTElDX0tFWV9BTEdPUklUSE1fVU5TUEVDSUZJRU'
    'QQABIgChxQVUJMSUNfS0VZX0FMR09SSVRITV9FRDI1NTE5EAE=');

@$core.Deprecated('Use deviceIdentityDescriptor instead')
const DeviceIdentity$json = {
  '1': 'DeviceIdentity',
  '2': [
    {'1': 'device_id', '3': 1, '4': 1, '5': 12, '10': 'deviceId'},
    {
      '1': 'public_key_algorithm',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.roammand.v1.PublicKeyAlgorithm',
      '10': 'publicKeyAlgorithm'
    },
    {'1': 'public_key', '3': 3, '4': 1, '5': 12, '10': 'publicKey'},
    {'1': 'display_name', '3': 4, '4': 1, '5': 9, '10': 'displayName'},
    {
      '1': 'platform',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.roammand.v1.DevicePlatform',
      '10': 'platform'
    },
  ],
};

/// Descriptor for `DeviceIdentity`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deviceIdentityDescriptor = $convert.base64Decode(
    'Cg5EZXZpY2VJZGVudGl0eRIbCglkZXZpY2VfaWQYASABKAxSCGRldmljZUlkElEKFHB1YmxpY1'
    '9rZXlfYWxnb3JpdGhtGAIgASgOMh8ucm9hbW1hbmQudjEuUHVibGljS2V5QWxnb3JpdGhtUhJw'
    'dWJsaWNLZXlBbGdvcml0aG0SHQoKcHVibGljX2tleRgDIAEoDFIJcHVibGljS2V5EiEKDGRpc3'
    'BsYXlfbmFtZRgEIAEoCVILZGlzcGxheU5hbWUSNwoIcGxhdGZvcm0YBSABKA4yGy5yb2FtbWFu'
    'ZC52MS5EZXZpY2VQbGF0Zm9ybVIIcGxhdGZvcm0=');
