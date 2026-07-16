// SPDX-License-Identifier: MPL-2.0

import 'dart:typed_data';

import 'package:roammand_protocol/roammand_protocol.dart';

abstract interface class ControllerSessionIdentity {
  Future<DeviceIdentity> open();

  Future<Uint8List> signOffer(List<int> canonicalTranscript);

  Future<void> close();
}

final class ControllerSessionIdentityException implements Exception {
  const ControllerSessionIdentityException();

  @override
  String toString() => 'ControllerSessionIdentityException';
}
