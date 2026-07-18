// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';

import 'package:roammand_protocol/roammand_protocol.dart';

String? normalizeDeviceDisplayName(String? value) {
  final normalized = value?.trim();
  if (normalized == null ||
      normalized.isEmpty ||
      utf8.encode(normalized).length > maxDeviceNameUtf8Bytes ||
      normalized.runes.any((rune) => rune < 0x20 || rune == 0x7f)) {
    return null;
  }
  return normalized;
}

String requireDeviceDisplayName(String value) {
  final normalized = normalizeDeviceDisplayName(value);
  if (normalized == null) {
    throw ArgumentError('Invalid device name', 'displayName');
  }
  return normalized;
}
