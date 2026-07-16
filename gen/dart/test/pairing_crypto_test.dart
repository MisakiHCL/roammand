// SPDX-License-Identifier: Apache-2.0

import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:roammand_protocol/roammand_protocol.dart';
import 'package:test/test.dart';

void main() {
  test('Pairing Crypto V1 maps the first 44 digest bits to four indexes', () {
    final digest = Uint8List.fromList(
      _hex('f89f31c4716edbcff1d8a4ad5fbe1161730b022cf28770146e481a06ef5981c6'),
    );

    expect(pairingSasIndexes(digest), <int>[1988, 1996, 904, 1814]);
  });

  test('Pairing Crypto V1 rejects invalid digest and sequence values', () {
    expect(
      () => pairingSasIndexes(Uint8List(31)),
      throwsA(isA<PairingCryptoException>()),
    );
    expect(
      () => pairingNonce(PairingCryptoDirection.controllerToHost, 0),
      throwsA(isA<PairingCryptoException>()),
    );
    expect(
      () => pairingNonce(
        PairingCryptoDirection.controllerToHost,
        0x8000000000000000,
      ),
      throwsA(isA<PairingCryptoException>()),
    );
  });

  test('Pairing Crypto V1 rejects an all-zero X25519 shared secret', () async {
    await expectLater(
      x25519SharedSecret(Uint8List(32), Uint8List(32)),
      throwsA(
        isA<PairingCryptoException>().having(
          (error) => error.code,
          'code',
          PairingCryptoErrorCode.invalidPublicKey,
        ),
      ),
    );
  });

  test('Pairing Crypto V1 matches the shared golden vector', () async {
    final vector =
        jsonDecode(
              File(
                '../../conformance/protocol_vectors/pairing_crypto_v1.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final wordBytes = File(
      '../../conformance/wordlists/bip39-english.txt',
    ).readAsBytesSync();
    final words = utf8.decode(wordBytes).trim().split('\n');
    final transcript = _bytes(vector, 'canonical_transcript_hex');
    final transcriptHash = CanonicalTranscriptV1.sha256(transcript);
    final controllerPrivate = _bytes(
      vector,
      'controller_x25519_private_key_hex',
    );
    final hostPrivate = _bytes(vector, 'host_x25519_private_key_hex');

    expect(
      _hexEncode(transcriptHash),
      vector['transcript_sha256_hex'] as String,
    );
    expect(
      _hexEncode(await x25519PublicKey(controllerPrivate)),
      vector['controller_x25519_public_key_hex'] as String,
    );
    expect(
      _hexEncode(await x25519PublicKey(hostPrivate)),
      vector['host_x25519_public_key_hex'] as String,
    );
    final shared = await x25519SharedSecret(
      controllerPrivate,
      _bytes(vector, 'host_x25519_public_key_hex'),
    );
    expect(_hexEncode(shared), vector['x25519_shared_secret_hex'] as String);
    expect(pairingSasIndexes(transcriptHash), vector['sas_indexes']);
    expect(pairingSasWords(transcriptHash, words), vector['sas_words']);
    expect(
      crypto.sha256.convert(wordBytes).toString(),
      vector['wordlist_sha256_hex'] as String,
    );

    final keys = await derivePairingKeys(shared, transcriptHash);
    expect(
      _hexEncode(keys.controllerToHost),
      vector['controller_to_host_key_hex'] as String,
    );
    expect(
      _hexEncode(keys.hostToController),
      vector['host_to_controller_key_hex'] as String,
    );
    final direction = PairingCryptoDirection.controllerToHost;
    final sequence = vector['sequence'] as int;
    final nonce = pairingNonce(direction, sequence);
    final aad = pairingAad(
      direction: direction,
      sequence: sequence,
      rendezvousId: _bytes(vector, 'rendezvous_id_hex'),
      controllerDeviceId: _bytes(vector, 'controller_device_id_hex'),
      hostDeviceId: _bytes(vector, 'host_device_id_hex'),
    );
    expect(_hexEncode(nonce), vector['nonce_hex'] as String);
    expect(_hexEncode(aad), vector['aad_hex'] as String);
    final sealed = await sealPairingPayload(
      key: keys.controllerToHost,
      direction: direction,
      sequence: sequence,
      aad: aad,
      plaintext: _bytes(vector, 'plaintext_hex'),
    );
    expect(_hexEncode(sealed), vector['ciphertext_and_tag_hex'] as String);
    expect(
      await openPairingPayload(
        key: keys.controllerToHost,
        direction: direction,
        sequence: sequence,
        aad: aad,
        ciphertextAndTag: sealed,
      ),
      _bytes(vector, 'plaintext_hex'),
    );
  });

  test('Pairing Crypto V1 rejects tampered authenticated data', () async {
    final key = Uint8List(32);
    final aad = Uint8List.fromList(<int>[1, 2, 3]);
    final sealed = await sealPairingPayload(
      key: key,
      direction: PairingCryptoDirection.hostToController,
      sequence: 1,
      aad: aad,
      plaintext: Uint8List.fromList(<int>[4, 5, 6]),
    );

    await expectLater(
      openPairingPayload(
        key: key,
        direction: PairingCryptoDirection.hostToController,
        sequence: 1,
        aad: Uint8List.fromList(<int>[1, 2, 4]),
        ciphertextAndTag: sealed,
      ),
      throwsA(
        isA<PairingCryptoException>().having(
          (error) => error.code,
          'code',
          PairingCryptoErrorCode.authenticationFailed,
        ),
      ),
    );

    for (var index = 0; index < sealed.length; index++) {
      final tampered = Uint8List.fromList(sealed);
      tampered[index] ^= 0x01;
      await expectLater(
        openPairingPayload(
          key: key,
          direction: PairingCryptoDirection.hostToController,
          sequence: 1,
          aad: aad,
          ciphertextAndTag: tampered,
        ),
        throwsA(isA<PairingCryptoException>()),
        reason: 'tampered ciphertext byte $index',
      );
    }
  });

  test('Pairing Crypto V1 rejects duplicate and skipped sequences', () {
    final validator = PairingSequenceValidator()..accept(1);

    expect(() => validator.accept(1), throwsA(isA<PairingCryptoException>()));
    expect(() => validator.accept(3), throwsA(isA<PairingCryptoException>()));
    expect(() => validator.accept(2), returnsNormally);
    expect(validator.next, 3);
  });

  test('Pairing Crypto V1 covers the fixed word list boundaries', () async {
    final words = File(
      '../../conformance/wordlists/bip39-english.txt',
    ).readAsStringSync().trim().split('\n');

    expect(pairingSasWords(Uint8List(32), words), <String>[
      'abandon',
      'abandon',
      'abandon',
      'abandon',
    ]);
    expect(
      pairingSasWords(Uint8List.fromList(List<int>.filled(32, 0xff)), words),
      <String>['zoo', 'zoo', 'zoo', 'zoo'],
    );
    await expectLater(
      sealPairingPayload(
        key: Uint8List(32),
        direction: PairingCryptoDirection.controllerToHost,
        sequence: 1,
        aad: Uint8List(0),
        plaintext: Uint8List(maxPairingCiphertextBytes),
      ),
      throwsA(isA<PairingCryptoException>()),
    );
  });
}

List<int> _hex(String value) => <int>[
  for (var offset = 0; offset < value.length; offset += 2)
    int.parse(value.substring(offset, offset + 2), radix: 16),
];

Uint8List _bytes(Map<String, dynamic> vector, String name) =>
    Uint8List.fromList(_hex(vector[name] as String));

String _hexEncode(List<int> value) =>
    value.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
