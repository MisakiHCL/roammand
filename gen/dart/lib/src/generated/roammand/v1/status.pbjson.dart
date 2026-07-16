// SPDX-License-Identifier: Apache-2.0

// This is a generated file - do not edit.
//
// Generated from roammand/v1/status.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use sessionStateDescriptor instead')
const SessionState$json = {
  '1': 'SessionState',
  '2': [
    {'1': 'SESSION_STATE_UNSPECIFIED', '2': 0},
    {'1': 'SESSION_STATE_IDLE', '2': 1},
    {'1': 'SESSION_STATE_SIGNALING', '2': 2},
    {'1': 'SESSION_STATE_AUTHENTICATING', '2': 3},
    {'1': 'SESSION_STATE_CONNECTING', '2': 4},
    {'1': 'SESSION_STATE_CONNECTED', '2': 5},
    {'1': 'SESSION_STATE_RECONNECTING', '2': 6},
    {'1': 'SESSION_STATE_FAILED', '2': 7},
    {'1': 'SESSION_STATE_CLOSING', '2': 8},
  ],
};

/// Descriptor for `SessionState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sessionStateDescriptor = $convert.base64Decode(
    'CgxTZXNzaW9uU3RhdGUSHQoZU0VTU0lPTl9TVEFURV9VTlNQRUNJRklFRBAAEhYKElNFU1NJT0'
    '5fU1RBVEVfSURMRRABEhsKF1NFU1NJT05fU1RBVEVfU0lHTkFMSU5HEAISIAocU0VTU0lPTl9T'
    'VEFURV9BVVRIRU5USUNBVElORxADEhwKGFNFU1NJT05fU1RBVEVfQ09OTkVDVElORxAEEhsKF1'
    'NFU1NJT05fU1RBVEVfQ09OTkVDVEVEEAUSHgoaU0VTU0lPTl9TVEFURV9SRUNPTk5FQ1RJTkcQ'
    'BhIYChRTRVNTSU9OX1NUQVRFX0ZBSUxFRBAHEhkKFVNFU1NJT05fU1RBVEVfQ0xPU0lORxAI');

@$core.Deprecated('Use sessionStatusDescriptor instead')
const SessionStatus$json = {
  '1': 'SessionStatus',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 12, '10': 'sessionId'},
    {
      '1': 'state',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.roammand.v1.SessionState',
      '10': 'state'
    },
    {
      '1': 'error',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.roammand.v1.UnifiedError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `SessionStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionStatusDescriptor = $convert.base64Decode(
    'Cg1TZXNzaW9uU3RhdHVzEh0KCnNlc3Npb25faWQYASABKAxSCXNlc3Npb25JZBIvCgVzdGF0ZR'
    'gCIAEoDjIZLnJvYW1tYW5kLnYxLlNlc3Npb25TdGF0ZVIFc3RhdGUSLwoFZXJyb3IYAyABKAsy'
    'GS5yb2FtbWFuZC52MS5VbmlmaWVkRXJyb3JSBWVycm9y');
