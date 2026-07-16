// SPDX-License-Identifier: MPL-2.0

import 'dart:typed_data';

import 'package:crypto/crypto.dart' as hashes;
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/desktop/pairing/desktop_controller_pairing_identity.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

void main() {
  test(
    'uses the local Agent only for a role-bound pairing signature',
    () async {
      final algorithm = Ed25519();
      final keyPair = await algorithm.newKeyPairFromSeed(
        List<int>.generate(32, (index) => index),
      );
      final publicKey = await keyPair.extractPublicKey();
      final identity = DeviceIdentity(
        deviceId: deriveDeviceIdV1(publicKey.bytes),
        publicKeyAlgorithm: PublicKeyAlgorithm.PUBLIC_KEY_ALGORITHM_ED25519,
        publicKey: publicKey.bytes,
        displayName: 'Controller Mac',
        platform: DevicePlatform.DEVICE_PLATFORM_MACOS,
      );
      final transcript = CanonicalTranscriptV1.encode(
        TranscriptPurpose.pairingSas,
        <TranscriptField>[
          TranscriptField(1, identity.deviceId),
          TranscriptField(2, List<int>.filled(32, 0x22)),
          TranscriptField(3, List<int>.filled(16, 0x33)),
          TranscriptField(4, identity.publicKey),
          TranscriptField(5, List<int>.filled(32, 0x55)),
          TranscriptField(6, List<int>.filled(32, 0x66)),
          TranscriptField(7, List<int>.filled(32, 0x77)),
        ],
      );
      var requests = 0;
      final adapter = DesktopControllerPairingIdentity(
        identity: identity,
        signTranscript: (bytes, role) async {
          requests += 1;
          expect(role, PairingIdentityRole.PAIRING_IDENTITY_ROLE_CONTROLLER);
          final signature = await algorithm.sign(bytes, keyPair: keyPair);
          return PairingTranscriptSignature(
            role: role,
            signerDeviceId: identity.deviceId,
            signerPublicKey: identity.publicKey,
            signature: signature.bytes,
            transcriptSha256: hashes.sha256.convert(bytes).bytes,
          );
        },
      );

      final signature = await adapter.sign(transcript);

      expect(signature, hasLength(64));
      expect(requests, 1);
      expect(adapter.publicIdentity, identity);
    },
  );

  test('rejects substituted Agent signature metadata', () async {
    final publicKey = List<int>.generate(32, (index) => index + 1);
    final identity = DeviceIdentity(
      deviceId: deriveDeviceIdV1(publicKey),
      publicKeyAlgorithm: PublicKeyAlgorithm.PUBLIC_KEY_ALGORITHM_ED25519,
      publicKey: publicKey,
      displayName: 'Controller PC',
      platform: DevicePlatform.DEVICE_PLATFORM_WINDOWS,
    );
    final adapter = DesktopControllerPairingIdentity(
      identity: identity,
      signTranscript: (bytes, role) async => PairingTranscriptSignature(
        role: role,
        signerDeviceId: List<int>.filled(32, 0x99),
        signerPublicKey: identity.publicKey,
        signature: List<int>.filled(64, 0x44),
        transcriptSha256: hashes.sha256.convert(bytes).bytes,
      ),
    );

    expect(
      () => adapter.sign(Uint8List.fromList(<int>[1, 2, 3])),
      throwsA(isA<DesktopControllerPairingIdentityException>()),
    );
  });
}
