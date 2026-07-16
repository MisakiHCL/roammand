// SPDX-License-Identifier: MPL-2.0

import 'dart:typed_data';

import 'package:roammand/controller/session/controller_session_identity.dart';
import 'package:roammand/mobile/identity/mobile_device_identity.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

final class MobileControllerSessionIdentity
    implements ControllerSessionIdentity {
  MobileControllerSessionIdentity(this._identity);

  final MobileDeviceIdentity _identity;
  bool _opened = false;
  bool _closed = false;

  @override
  Future<DeviceIdentity> open() async {
    if (_opened || _closed) {
      throw const ControllerSessionIdentityException();
    }
    _opened = true;
    return _identity.publicIdentity;
  }

  @override
  Future<Uint8List> signOffer(List<int> canonicalTranscript) async {
    if (!_opened || _closed) {
      throw const ControllerSessionIdentityException();
    }
    try {
      return await _identity.sign(canonicalTranscript);
    } catch (_) {
      throw const ControllerSessionIdentityException();
    }
  }

  @override
  Future<void> close() async {
    _closed = true;
  }
}
