// SPDX-License-Identifier: MPL-2.0

import 'dart:typed_data';

import 'package:roammand_protocol/roammand_protocol.dart';

abstract interface class ControllerPairingIdentity {
  DeviceIdentity get publicIdentity;

  Future<Uint8List> sign(List<int> canonicalTranscript);
}
