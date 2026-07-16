// SPDX-License-Identifier: Apache-2.0

// This is a generated file - do not edit.
//
// Generated from roammand/v1/authorization.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use grantRevocationReasonDescriptor instead')
const GrantRevocationReason$json = {
  '1': 'GrantRevocationReason',
  '2': [
    {'1': 'GRANT_REVOCATION_REASON_UNSPECIFIED', '2': 0},
    {'1': 'GRANT_REVOCATION_REASON_USER_REQUESTED', '2': 1},
    {'1': 'GRANT_REVOCATION_REASON_IDENTITY_RESET', '2': 2},
    {'1': 'GRANT_REVOCATION_REASON_SECURITY_RESPONSE', '2': 3},
  ],
};

/// Descriptor for `GrantRevocationReason`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List grantRevocationReasonDescriptor = $convert.base64Decode(
    'ChVHcmFudFJldm9jYXRpb25SZWFzb24SJwojR1JBTlRfUkVWT0NBVElPTl9SRUFTT05fVU5TUE'
    'VDSUZJRUQQABIqCiZHUkFOVF9SRVZPQ0FUSU9OX1JFQVNPTl9VU0VSX1JFUVVFU1RFRBABEioK'
    'JkdSQU5UX1JFVk9DQVRJT05fUkVBU09OX0lERU5USVRZX1JFU0VUEAISLQopR1JBTlRfUkVWT0'
    'NBVElPTl9SRUFTT05fU0VDVVJJVFlfUkVTUE9OU0UQAw==');

@$core.Deprecated('Use controllerGrantDescriptor instead')
const ControllerGrant$json = {
  '1': 'ControllerGrant',
  '2': [
    {'1': 'grant_id', '3': 1, '4': 1, '5': 12, '10': 'grantId'},
    {'1': 'host_device_id', '3': 2, '4': 1, '5': 12, '10': 'hostDeviceId'},
    {
      '1': 'controller',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.DeviceIdentity',
      '10': 'controller'
    },
    {
      '1': 'created_at_unix_ms',
      '3': 4,
      '4': 1,
      '5': 4,
      '10': 'createdAtUnixMs'
    },
    {
      '1': 'permissions',
      '3': 5,
      '4': 3,
      '5': 14,
      '6': '.roammand.v1.SessionPermission',
      '10': 'permissions'
    },
  ],
};

/// Descriptor for `ControllerGrant`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List controllerGrantDescriptor = $convert.base64Decode(
    'Cg9Db250cm9sbGVyR3JhbnQSGQoIZ3JhbnRfaWQYASABKAxSB2dyYW50SWQSJAoOaG9zdF9kZX'
    'ZpY2VfaWQYAiABKAxSDGhvc3REZXZpY2VJZBI7Cgpjb250cm9sbGVyGAMgASgLMhsucm9hbW1h'
    'bmQudjEuRGV2aWNlSWRlbnRpdHlSCmNvbnRyb2xsZXISKwoSY3JlYXRlZF9hdF91bml4X21zGA'
    'QgASgEUg9jcmVhdGVkQXRVbml4TXMSQAoLcGVybWlzc2lvbnMYBSADKA4yHi5yb2FtbWFuZC52'
    'MS5TZXNzaW9uUGVybWlzc2lvblILcGVybWlzc2lvbnM=');

@$core.Deprecated('Use grantRevocationDescriptor instead')
const GrantRevocation$json = {
  '1': 'GrantRevocation',
  '2': [
    {'1': 'grant_id', '3': 1, '4': 1, '5': 12, '10': 'grantId'},
    {
      '1': 'revoked_at_unix_ms',
      '3': 2,
      '4': 1,
      '5': 4,
      '10': 'revokedAtUnixMs'
    },
    {
      '1': 'reason',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.roammand.v1.GrantRevocationReason',
      '10': 'reason'
    },
  ],
};

/// Descriptor for `GrantRevocation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List grantRevocationDescriptor = $convert.base64Decode(
    'Cg9HcmFudFJldm9jYXRpb24SGQoIZ3JhbnRfaWQYASABKAxSB2dyYW50SWQSKwoScmV2b2tlZF'
    '9hdF91bml4X21zGAIgASgEUg9yZXZva2VkQXRVbml4TXMSOgoGcmVhc29uGAMgASgOMiIucm9h'
    'bW1hbmQudjEuR3JhbnRSZXZvY2F0aW9uUmVhc29uUgZyZWFzb24=');
