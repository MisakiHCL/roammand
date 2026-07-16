// SPDX-License-Identifier: MPL-2.0

import 'dart:typed_data';

import 'package:crypto/crypto.dart' as hashes;
import 'package:cryptography/cryptography.dart';
import 'package:roammand/controller/session/controller_session_identity.dart';
import 'package:roammand/desktop/host_agent/host_agent_models.dart';
import 'package:roammand/pairing/device_identity_validator.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

final class HostAgentControllerSessionIdentity
    implements ControllerSessionIdentity {
  HostAgentControllerSessionIdentity(this._port);

  final HostAgentSessionIdentityPort _port;
  DeviceIdentity? _identity;
  bool _closed = false;

  @override
  Future<DeviceIdentity> open() async {
    if (_closed || _identity != null) {
      throw const ControllerSessionIdentityException();
    }
    try {
      await _port.connect();
      final identity = (await _port.getHostStatus()).identity.deepCopy();
      validateDesktopHostIdentity(identity);
      _identity = identity;
      return identity.deepCopy();
    } catch (_) {
      await close();
      throw const ControllerSessionIdentityException();
    }
  }

  @override
  Future<Uint8List> signOffer(List<int> canonicalTranscript) async {
    final identity = _identity;
    if (_closed || identity == null) {
      throw const ControllerSessionIdentityException();
    }
    try {
      final signed = await _port.signSessionOffer(canonicalTranscript);
      if (!_constantTimeEquals(signed.controllerDeviceId, identity.deviceId) ||
          !_constantTimeEquals(
            signed.controllerPublicKey,
            identity.publicKey,
          ) ||
          !_constantTimeEquals(
            signed.transcriptSha256,
            hashes.sha256.convert(canonicalTranscript).bytes,
          ) ||
          signed.signature.length != signatureBytes) {
        throw const ControllerSessionIdentityException();
      }
      final valid = await Ed25519().verify(
        canonicalTranscript,
        signature: Signature(
          signed.signature,
          publicKey: SimplePublicKey(
            identity.publicKey,
            type: KeyPairType.ed25519,
          ),
        ),
      );
      if (!valid) {
        throw const ControllerSessionIdentityException();
      }
      return Uint8List.fromList(signed.signature);
    } on ControllerSessionIdentityException {
      rethrow;
    } catch (_) {
      throw const ControllerSessionIdentityException();
    }
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _identity = null;
    await _port.close();
  }
}

bool _constantTimeEquals(List<int> left, List<int> right) {
  if (left.length != right.length) {
    return false;
  }
  var difference = 0;
  for (var index = 0; index < left.length; index += 1) {
    difference |= left[index] ^ right[index];
  }
  return difference == 0;
}
