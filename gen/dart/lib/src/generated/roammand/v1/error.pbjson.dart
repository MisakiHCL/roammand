// SPDX-License-Identifier: Apache-2.0

// This is a generated file - do not edit.
//
// Generated from roammand/v1/error.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use errorCodeDescriptor instead')
const ErrorCode$json = {
  '1': 'ErrorCode',
  '2': [
    {'1': 'ERROR_CODE_UNSPECIFIED', '2': 0},
    {'1': 'ERROR_CODE_PAIRING_CODE_EXPIRED', '2': 1},
    {'1': 'ERROR_CODE_PAIRING_RATE_LIMITED', '2': 2},
    {'1': 'ERROR_CODE_PAIRING_REJECTED', '2': 3},
    {'1': 'ERROR_CODE_DEVICE_OFFLINE', '2': 4},
    {'1': 'ERROR_CODE_DEVICE_BUSY', '2': 5},
    {'1': 'ERROR_CODE_AUTH_INVALID', '2': 6},
    {'1': 'ERROR_CODE_AUTH_REVOKED', '2': 7},
    {'1': 'ERROR_CODE_SESSION_REPLAYED', '2': 8},
    {'1': 'ERROR_CODE_ICE_FAILED', '2': 9},
    {'1': 'ERROR_CODE_TURN_UNAVAILABLE', '2': 10},
    {'1': 'ERROR_CODE_CODEC_NEGOTIATION_FAILED', '2': 11},
    {'1': 'ERROR_CODE_CAPTURE_PERMISSION_REQUIRED', '2': 12},
    {'1': 'ERROR_CODE_INPUT_PERMISSION_REQUIRED', '2': 13},
    {'1': 'ERROR_CODE_CAPTURE_FAILED', '2': 14},
    {'1': 'ERROR_CODE_INPUT_INJECTION_FAILED', '2': 15},
    {'1': 'ERROR_CODE_APP_MOVED_TO_BACKGROUND', '2': 16},
    {'1': 'ERROR_CODE_INVALID_REQUEST', '2': 17},
    {'1': 'ERROR_CODE_PROTOCOL_UNSUPPORTED', '2': 18},
    {'1': 'ERROR_CODE_MESSAGE_TOO_LARGE', '2': 19},
    {'1': 'ERROR_CODE_SERVER_UNAVAILABLE', '2': 20},
    {'1': 'ERROR_CODE_PRIVILEGED_BRIDGE_UNAVAILABLE', '2': 21},
    {'1': 'ERROR_CODE_PRIVILEGED_CLIENT_UNTRUSTED', '2': 22},
    {'1': 'ERROR_CODE_PRIVILEGED_LEASE_EXPIRED', '2': 23},
    {'1': 'ERROR_CODE_SECURE_ATTENTION_UNAVAILABLE', '2': 24},
    {'1': 'ERROR_CODE_LOCAL_EMERGENCY_STOP', '2': 25},
  ],
};

/// Descriptor for `ErrorCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List errorCodeDescriptor = $convert.base64Decode(
    'CglFcnJvckNvZGUSGgoWRVJST1JfQ09ERV9VTlNQRUNJRklFRBAAEiMKH0VSUk9SX0NPREVfUE'
    'FJUklOR19DT0RFX0VYUElSRUQQARIjCh9FUlJPUl9DT0RFX1BBSVJJTkdfUkFURV9MSU1JVEVE'
    'EAISHwobRVJST1JfQ09ERV9QQUlSSU5HX1JFSkVDVEVEEAMSHQoZRVJST1JfQ09ERV9ERVZJQ0'
    'VfT0ZGTElORRAEEhoKFkVSUk9SX0NPREVfREVWSUNFX0JVU1kQBRIbChdFUlJPUl9DT0RFX0FV'
    'VEhfSU5WQUxJRBAGEhsKF0VSUk9SX0NPREVfQVVUSF9SRVZPS0VEEAcSHwobRVJST1JfQ09ERV'
    '9TRVNTSU9OX1JFUExBWUVEEAgSGQoVRVJST1JfQ09ERV9JQ0VfRkFJTEVEEAkSHwobRVJST1Jf'
    'Q09ERV9UVVJOX1VOQVZBSUxBQkxFEAoSJwojRVJST1JfQ09ERV9DT0RFQ19ORUdPVElBVElPTl'
    '9GQUlMRUQQCxIqCiZFUlJPUl9DT0RFX0NBUFRVUkVfUEVSTUlTU0lPTl9SRVFVSVJFRBAMEigK'
    'JEVSUk9SX0NPREVfSU5QVVRfUEVSTUlTU0lPTl9SRVFVSVJFRBANEh0KGUVSUk9SX0NPREVfQ0'
    'FQVFVSRV9GQUlMRUQQDhIlCiFFUlJPUl9DT0RFX0lOUFVUX0lOSkVDVElPTl9GQUlMRUQQDxIm'
    'CiJFUlJPUl9DT0RFX0FQUF9NT1ZFRF9UT19CQUNLR1JPVU5EEBASHgoaRVJST1JfQ09ERV9JTl'
    'ZBTElEX1JFUVVFU1QQERIjCh9FUlJPUl9DT0RFX1BST1RPQ09MX1VOU1VQUE9SVEVEEBISIAoc'
    'RVJST1JfQ09ERV9NRVNTQUdFX1RPT19MQVJHRRATEiEKHUVSUk9SX0NPREVfU0VSVkVSX1VOQV'
    'ZBSUxBQkxFEBQSLAooRVJST1JfQ09ERV9QUklWSUxFR0VEX0JSSURHRV9VTkFWQUlMQUJMRRAV'
    'EioKJkVSUk9SX0NPREVfUFJJVklMRUdFRF9DTElFTlRfVU5UUlVTVEVEEBYSJwojRVJST1JfQ0'
    '9ERV9QUklWSUxFR0VEX0xFQVNFX0VYUElSRUQQFxIrCidFUlJPUl9DT0RFX1NFQ1VSRV9BVFRF'
    'TlRJT05fVU5BVkFJTEFCTEUQGBIjCh9FUlJPUl9DT0RFX0xPQ0FMX0VNRVJHRU5DWV9TVE9QEB'
    'k=');

@$core.Deprecated('Use retryAfterDetailsDescriptor instead')
const RetryAfterDetails$json = {
  '1': 'RetryAfterDetails',
  '2': [
    {'1': 'retry_after_ms', '3': 1, '4': 1, '5': 4, '10': 'retryAfterMs'},
  ],
};

/// Descriptor for `RetryAfterDetails`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List retryAfterDetailsDescriptor = $convert.base64Decode(
    'ChFSZXRyeUFmdGVyRGV0YWlscxIkCg5yZXRyeV9hZnRlcl9tcxgBIAEoBFIMcmV0cnlBZnRlck'
    '1z');

@$core.Deprecated('Use permissionDetailsDescriptor instead')
const PermissionDetails$json = {
  '1': 'PermissionDetails',
  '2': [
    {'1': 'permission', '3': 1, '4': 1, '5': 9, '10': 'permission'},
  ],
};

/// Descriptor for `PermissionDetails`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List permissionDetailsDescriptor = $convert.base64Decode(
    'ChFQZXJtaXNzaW9uRGV0YWlscxIeCgpwZXJtaXNzaW9uGAEgASgJUgpwZXJtaXNzaW9u');

@$core.Deprecated('Use codecDetailsDescriptor instead')
const CodecDetails$json = {
  '1': 'CodecDetails',
  '2': [
    {'1': 'supported_codecs', '3': 1, '4': 3, '5': 9, '10': 'supportedCodecs'},
  ],
};

/// Descriptor for `CodecDetails`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List codecDetailsDescriptor = $convert.base64Decode(
    'CgxDb2RlY0RldGFpbHMSKQoQc3VwcG9ydGVkX2NvZGVjcxgBIAMoCVIPc3VwcG9ydGVkQ29kZW'
    'Nz');

@$core.Deprecated('Use transportDetailsDescriptor instead')
const TransportDetails$json = {
  '1': 'TransportDetails',
  '2': [
    {'1': 'transport', '3': 1, '4': 1, '5': 9, '10': 'transport'},
  ],
};

/// Descriptor for `TransportDetails`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transportDetailsDescriptor = $convert.base64Decode(
    'ChBUcmFuc3BvcnREZXRhaWxzEhwKCXRyYW5zcG9ydBgBIAEoCVIJdHJhbnNwb3J0');

@$core.Deprecated('Use unifiedErrorDescriptor instead')
const UnifiedError$json = {
  '1': 'UnifiedError',
  '2': [
    {
      '1': 'code',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.roammand.v1.ErrorCode',
      '10': 'code'
    },
    {'1': 'message_key', '3': 2, '4': 1, '5': 9, '10': 'messageKey'},
    {'1': 'retryable', '3': 3, '4': 1, '5': 8, '10': 'retryable'},
    {'1': 'request_id', '3': 4, '4': 1, '5': 9, '10': 'requestId'},
    {
      '1': 'retry_after',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.RetryAfterDetails',
      '9': 0,
      '10': 'retryAfter'
    },
    {
      '1': 'permission',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.PermissionDetails',
      '9': 0,
      '10': 'permission'
    },
    {
      '1': 'codec',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.CodecDetails',
      '9': 0,
      '10': 'codec'
    },
    {
      '1': 'transport',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.TransportDetails',
      '9': 0,
      '10': 'transport'
    },
  ],
  '8': [
    {'1': 'details'},
  ],
};

/// Descriptor for `UnifiedError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List unifiedErrorDescriptor = $convert.base64Decode(
    'CgxVbmlmaWVkRXJyb3ISKgoEY29kZRgBIAEoDjIWLnJvYW1tYW5kLnYxLkVycm9yQ29kZVIEY2'
    '9kZRIfCgttZXNzYWdlX2tleRgCIAEoCVIKbWVzc2FnZUtleRIcCglyZXRyeWFibGUYAyABKAhS'
    'CXJldHJ5YWJsZRIdCgpyZXF1ZXN0X2lkGAQgASgJUglyZXF1ZXN0SWQSQQoLcmV0cnlfYWZ0ZX'
    'IYCiABKAsyHi5yb2FtbWFuZC52MS5SZXRyeUFmdGVyRGV0YWlsc0gAUgpyZXRyeUFmdGVyEkAK'
    'CnBlcm1pc3Npb24YCyABKAsyHi5yb2FtbWFuZC52MS5QZXJtaXNzaW9uRGV0YWlsc0gAUgpwZX'
    'JtaXNzaW9uEjEKBWNvZGVjGAwgASgLMhkucm9hbW1hbmQudjEuQ29kZWNEZXRhaWxzSABSBWNv'
    'ZGVjEj0KCXRyYW5zcG9ydBgNIAEoCzIdLnJvYW1tYW5kLnYxLlRyYW5zcG9ydERldGFpbHNIAF'
    'IJdHJhbnNwb3J0QgkKB2RldGFpbHM=');
