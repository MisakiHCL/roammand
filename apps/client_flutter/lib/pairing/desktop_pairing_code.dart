// SPDX-License-Identifier: MPL-2.0

import 'pairing_limits.dart';

final class DesktopPairingCodeException implements Exception {
  const DesktopPairingCodeException();

  @override
  String toString() => 'DesktopPairingCodeException';
}

String normalizeDesktopPairingCode(String value) {
  if (value.length != desktopPairingCodeLength &&
      value.length != formattedDesktopPairingCodeLength) {
    throw const DesktopPairingCodeException();
  }
  final raw = value.length == formattedDesktopPairingCodeLength
      ? _removeFixedSeparator(value)
      : value;
  final normalized = raw.toUpperCase();
  if (!RegExp(r'^[A-Z2-7]{8}$').hasMatch(normalized)) {
    throw const DesktopPairingCodeException();
  }
  return normalized;
}

String formatDesktopPairingCode(String value) {
  final normalized = normalizeDesktopPairingCode(value);
  return '${normalized.substring(0, 4)}-${normalized.substring(4)}';
}

String _removeFixedSeparator(String value) {
  if (value[4] != '-') {
    throw const DesktopPairingCodeException();
  }
  return '${value.substring(0, 4)}${value.substring(5)}';
}
