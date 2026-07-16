// SPDX-License-Identifier: Apache-2.0

// This is a generated file - do not edit.
//
// Generated from roammand/v1/session.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use sessionPermissionDescriptor instead')
const SessionPermission$json = {
  '1': 'SessionPermission',
  '2': [
    {'1': 'SESSION_PERMISSION_UNSPECIFIED', '2': 0},
    {'1': 'SESSION_PERMISSION_VIEW_SCREEN', '2': 1},
    {'1': 'SESSION_PERMISSION_CONTROL_INPUT', '2': 2},
  ],
};

/// Descriptor for `SessionPermission`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sessionPermissionDescriptor = $convert.base64Decode(
    'ChFTZXNzaW9uUGVybWlzc2lvbhIiCh5TRVNTSU9OX1BFUk1JU1NJT05fVU5TUEVDSUZJRUQQAB'
    'IiCh5TRVNTSU9OX1BFUk1JU1NJT05fVklFV19TQ1JFRU4QARIkCiBTRVNTSU9OX1BFUk1JU1NJ'
    'T05fQ09OVFJPTF9JTlBVVBAC');

@$core.Deprecated('Use sessionOfferAuthenticationDescriptor instead')
const SessionOfferAuthentication$json = {
  '1': 'SessionOfferAuthentication',
  '2': [
    {
      '1': 'controller_device_id',
      '3': 1,
      '4': 1,
      '5': 12,
      '10': 'controllerDeviceId'
    },
    {'1': 'host_device_id', '3': 2, '4': 1, '5': 12, '10': 'hostDeviceId'},
    {'1': 'session_id', '3': 3, '4': 1, '5': 12, '10': 'sessionId'},
    {'1': 'nonce', '3': 4, '4': 1, '5': 12, '10': 'nonce'},
    {'1': 'issued_at_unix_ms', '3': 5, '4': 1, '5': 4, '10': 'issuedAtUnixMs'},
    {
      '1': 'expires_at_unix_ms',
      '3': 6,
      '4': 1,
      '5': 4,
      '10': 'expiresAtUnixMs'
    },
    {
      '1': 'requested_permissions',
      '3': 7,
      '4': 3,
      '5': 14,
      '6': '.roammand.v1.SessionPermission',
      '10': 'requestedPermissions'
    },
    {'1': 'offer_sha256', '3': 8, '4': 1, '5': 12, '10': 'offerSha256'},
    {
      '1': 'controller_dtls_fingerprint_sha256',
      '3': 9,
      '4': 1,
      '5': 12,
      '10': 'controllerDtlsFingerprintSha256'
    },
    {'1': 'signature', '3': 10, '4': 1, '5': 12, '10': 'signature'},
  ],
};

/// Descriptor for `SessionOfferAuthentication`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionOfferAuthenticationDescriptor = $convert.base64Decode(
    'ChpTZXNzaW9uT2ZmZXJBdXRoZW50aWNhdGlvbhIwChRjb250cm9sbGVyX2RldmljZV9pZBgBIA'
    'EoDFISY29udHJvbGxlckRldmljZUlkEiQKDmhvc3RfZGV2aWNlX2lkGAIgASgMUgxob3N0RGV2'
    'aWNlSWQSHQoKc2Vzc2lvbl9pZBgDIAEoDFIJc2Vzc2lvbklkEhQKBW5vbmNlGAQgASgMUgVub2'
    '5jZRIpChFpc3N1ZWRfYXRfdW5peF9tcxgFIAEoBFIOaXNzdWVkQXRVbml4TXMSKwoSZXhwaXJl'
    'c19hdF91bml4X21zGAYgASgEUg9leHBpcmVzQXRVbml4TXMSUwoVcmVxdWVzdGVkX3Blcm1pc3'
    'Npb25zGAcgAygOMh4ucm9hbW1hbmQudjEuU2Vzc2lvblBlcm1pc3Npb25SFHJlcXVlc3RlZFBl'
    'cm1pc3Npb25zEiEKDG9mZmVyX3NoYTI1NhgIIAEoDFILb2ZmZXJTaGEyNTYSSwoiY29udHJvbG'
    'xlcl9kdGxzX2ZpbmdlcnByaW50X3NoYTI1NhgJIAEoDFIfY29udHJvbGxlckR0bHNGaW5nZXJw'
    'cmludFNoYTI1NhIcCglzaWduYXR1cmUYCiABKAxSCXNpZ25hdHVyZQ==');

@$core.Deprecated('Use sessionAnswerAuthenticationDescriptor instead')
const SessionAnswerAuthentication$json = {
  '1': 'SessionAnswerAuthentication',
  '2': [
    {
      '1': 'controller_device_id',
      '3': 1,
      '4': 1,
      '5': 12,
      '10': 'controllerDeviceId'
    },
    {'1': 'host_device_id', '3': 2, '4': 1, '5': 12, '10': 'hostDeviceId'},
    {'1': 'session_id', '3': 3, '4': 1, '5': 12, '10': 'sessionId'},
    {'1': 'nonce', '3': 4, '4': 1, '5': 12, '10': 'nonce'},
    {'1': 'issued_at_unix_ms', '3': 5, '4': 1, '5': 4, '10': 'issuedAtUnixMs'},
    {
      '1': 'expires_at_unix_ms',
      '3': 6,
      '4': 1,
      '5': 4,
      '10': 'expiresAtUnixMs'
    },
    {
      '1': 'requested_permissions',
      '3': 7,
      '4': 3,
      '5': 14,
      '6': '.roammand.v1.SessionPermission',
      '10': 'requestedPermissions'
    },
    {'1': 'offer_sha256', '3': 8, '4': 1, '5': 12, '10': 'offerSha256'},
    {
      '1': 'controller_dtls_fingerprint_sha256',
      '3': 9,
      '4': 1,
      '5': 12,
      '10': 'controllerDtlsFingerprintSha256'
    },
    {'1': 'answer_sha256', '3': 10, '4': 1, '5': 12, '10': 'answerSha256'},
    {
      '1': 'host_dtls_fingerprint_sha256',
      '3': 11,
      '4': 1,
      '5': 12,
      '10': 'hostDtlsFingerprintSha256'
    },
    {'1': 'signature', '3': 12, '4': 1, '5': 12, '10': 'signature'},
  ],
};

/// Descriptor for `SessionAnswerAuthentication`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionAnswerAuthenticationDescriptor = $convert.base64Decode(
    'ChtTZXNzaW9uQW5zd2VyQXV0aGVudGljYXRpb24SMAoUY29udHJvbGxlcl9kZXZpY2VfaWQYAS'
    'ABKAxSEmNvbnRyb2xsZXJEZXZpY2VJZBIkCg5ob3N0X2RldmljZV9pZBgCIAEoDFIMaG9zdERl'
    'dmljZUlkEh0KCnNlc3Npb25faWQYAyABKAxSCXNlc3Npb25JZBIUCgVub25jZRgEIAEoDFIFbm'
    '9uY2USKQoRaXNzdWVkX2F0X3VuaXhfbXMYBSABKARSDmlzc3VlZEF0VW5peE1zEisKEmV4cGly'
    'ZXNfYXRfdW5peF9tcxgGIAEoBFIPZXhwaXJlc0F0VW5peE1zElMKFXJlcXVlc3RlZF9wZXJtaX'
    'NzaW9ucxgHIAMoDjIeLnJvYW1tYW5kLnYxLlNlc3Npb25QZXJtaXNzaW9uUhRyZXF1ZXN0ZWRQ'
    'ZXJtaXNzaW9ucxIhCgxvZmZlcl9zaGEyNTYYCCABKAxSC29mZmVyU2hhMjU2EksKImNvbnRyb2'
    'xsZXJfZHRsc19maW5nZXJwcmludF9zaGEyNTYYCSABKAxSH2NvbnRyb2xsZXJEdGxzRmluZ2Vy'
    'cHJpbnRTaGEyNTYSIwoNYW5zd2VyX3NoYTI1NhgKIAEoDFIMYW5zd2VyU2hhMjU2Ej8KHGhvc3'
    'RfZHRsc19maW5nZXJwcmludF9zaGEyNTYYCyABKAxSGWhvc3REdGxzRmluZ2VycHJpbnRTaGEy'
    'NTYSHAoJc2lnbmF0dXJlGAwgASgMUglzaWduYXR1cmU=');

@$core.Deprecated('Use sessionReconnectAuthenticationDescriptor instead')
const SessionReconnectAuthentication$json = {
  '1': 'SessionReconnectAuthentication',
  '2': [
    {
      '1': 'controller_device_id',
      '3': 1,
      '4': 1,
      '5': 12,
      '10': 'controllerDeviceId'
    },
    {'1': 'host_device_id', '3': 2, '4': 1, '5': 12, '10': 'hostDeviceId'},
    {'1': 'session_id', '3': 3, '4': 1, '5': 12, '10': 'sessionId'},
    {'1': 'nonce', '3': 4, '4': 1, '5': 12, '10': 'nonce'},
    {'1': 'issued_at_unix_ms', '3': 5, '4': 1, '5': 4, '10': 'issuedAtUnixMs'},
    {
      '1': 'expires_at_unix_ms',
      '3': 6,
      '4': 1,
      '5': 4,
      '10': 'expiresAtUnixMs'
    },
    {
      '1': 'requested_permissions',
      '3': 7,
      '4': 3,
      '5': 14,
      '6': '.roammand.v1.SessionPermission',
      '10': 'requestedPermissions'
    },
    {'1': 'offer_sha256', '3': 8, '4': 1, '5': 12, '10': 'offerSha256'},
    {
      '1': 'controller_dtls_fingerprint_sha256',
      '3': 9,
      '4': 1,
      '5': 12,
      '10': 'controllerDtlsFingerprintSha256'
    },
    {'1': 'answer_sha256', '3': 10, '4': 1, '5': 12, '10': 'answerSha256'},
    {
      '1': 'host_dtls_fingerprint_sha256',
      '3': 11,
      '4': 1,
      '5': 12,
      '10': 'hostDtlsFingerprintSha256'
    },
    {
      '1': 'reconnect_generation',
      '3': 12,
      '4': 1,
      '5': 13,
      '10': 'reconnectGeneration'
    },
    {'1': 'signature', '3': 13, '4': 1, '5': 12, '10': 'signature'},
  ],
};

/// Descriptor for `SessionReconnectAuthentication`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionReconnectAuthenticationDescriptor = $convert.base64Decode(
    'Ch5TZXNzaW9uUmVjb25uZWN0QXV0aGVudGljYXRpb24SMAoUY29udHJvbGxlcl9kZXZpY2VfaW'
    'QYASABKAxSEmNvbnRyb2xsZXJEZXZpY2VJZBIkCg5ob3N0X2RldmljZV9pZBgCIAEoDFIMaG9z'
    'dERldmljZUlkEh0KCnNlc3Npb25faWQYAyABKAxSCXNlc3Npb25JZBIUCgVub25jZRgEIAEoDF'
    'IFbm9uY2USKQoRaXNzdWVkX2F0X3VuaXhfbXMYBSABKARSDmlzc3VlZEF0VW5peE1zEisKEmV4'
    'cGlyZXNfYXRfdW5peF9tcxgGIAEoBFIPZXhwaXJlc0F0VW5peE1zElMKFXJlcXVlc3RlZF9wZX'
    'JtaXNzaW9ucxgHIAMoDjIeLnJvYW1tYW5kLnYxLlNlc3Npb25QZXJtaXNzaW9uUhRyZXF1ZXN0'
    'ZWRQZXJtaXNzaW9ucxIhCgxvZmZlcl9zaGEyNTYYCCABKAxSC29mZmVyU2hhMjU2EksKImNvbn'
    'Ryb2xsZXJfZHRsc19maW5nZXJwcmludF9zaGEyNTYYCSABKAxSH2NvbnRyb2xsZXJEdGxzRmlu'
    'Z2VycHJpbnRTaGEyNTYSIwoNYW5zd2VyX3NoYTI1NhgKIAEoDFIMYW5zd2VyU2hhMjU2Ej8KHG'
    'hvc3RfZHRsc19maW5nZXJwcmludF9zaGEyNTYYCyABKAxSGWhvc3REdGxzRmluZ2VycHJpbnRT'
    'aGEyNTYSMQoUcmVjb25uZWN0X2dlbmVyYXRpb24YDCABKA1SE3JlY29ubmVjdEdlbmVyYXRpb2'
    '4SHAoJc2lnbmF0dXJlGA0gASgMUglzaWduYXR1cmU=');

@$core.Deprecated('Use sessionAuthenticationDescriptor instead')
const SessionAuthentication$json = {
  '1': 'SessionAuthentication',
  '2': [
    {
      '1': 'offer',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.SessionOfferAuthentication',
      '9': 0,
      '10': 'offer'
    },
    {
      '1': 'answer',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.SessionAnswerAuthentication',
      '9': 0,
      '10': 'answer'
    },
    {
      '1': 'reconnect',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.SessionReconnectAuthentication',
      '9': 0,
      '10': 'reconnect'
    },
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `SessionAuthentication`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionAuthenticationDescriptor = $convert.base64Decode(
    'ChVTZXNzaW9uQXV0aGVudGljYXRpb24SPwoFb2ZmZXIYASABKAsyJy5yb2FtbWFuZC52MS5TZX'
    'NzaW9uT2ZmZXJBdXRoZW50aWNhdGlvbkgAUgVvZmZlchJCCgZhbnN3ZXIYAiABKAsyKC5yb2Ft'
    'bWFuZC52MS5TZXNzaW9uQW5zd2VyQXV0aGVudGljYXRpb25IAFIGYW5zd2VyEksKCXJlY29ubm'
    'VjdBgDIAEoCzIrLnJvYW1tYW5kLnYxLlNlc3Npb25SZWNvbm5lY3RBdXRoZW50aWNhdGlvbkgA'
    'UglyZWNvbm5lY3RCCQoHcGF5bG9hZA==');
