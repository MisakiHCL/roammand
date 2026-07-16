// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/pairing/trusted_host_store.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

void main() {
  test(
    'round trips a versioned checksummed snapshot through an atomic file',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'roammand-host-store-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/trusted-hosts.bin');
      final store = TrustedHostStore.atPath(file.path);
      final bindings = <TrustedHostBinding>[_binding(1), _binding(2)];

      await store.save(bindings);
      final encoded = await file.readAsBytes();
      final loaded = await store.load();

      expect(
        encoded.sublist(0, trustedHostEnvelopeMagic.length),
        trustedHostEnvelopeMagic,
      );
      expect(loaded, hasLength(2));
      expect(loaded[0].hostIdentity.displayName, 'Host 1');
      expect(loaded[1].signalingEndpoint, 'wss://signal.example.test/v1/ws');
      expect(
        loaded[0].hostIdentity.deviceId,
        deriveDeviceIdV1(loaded[0].hostIdentity.publicKey),
      );
    },
  );

  test(
    'rejects checksum, version, truncation, trailing bytes, and oversized files',
    () async {
      final backend = MemoryTrustedHostFileBackend();
      final store = TrustedHostStore(backend: backend);
      await store.save(<TrustedHostBinding>[_binding(1)]);
      final valid = Uint8List.fromList(backend.bytes!);

      final checksum = Uint8List.fromList(valid)
        ..[trustedHostEnvelopeHeaderBytes - 1] ^= 1;
      backend.bytes = checksum;
      await expectLater(
        store.load(),
        throwsA(isA<TrustedHostStoreException>()),
      );

      final version = Uint8List.fromList(valid)
        ..setRange(
          trustedHostEnvelopeMagic.length,
          trustedHostEnvelopeMagic.length + 4,
          <int>[0, 0, 0, 2],
        );
      backend.bytes = version;
      await expectLater(
        store.load(),
        throwsA(isA<TrustedHostStoreException>()),
      );

      backend.bytes = Uint8List.fromList(valid.sublist(0, valid.length - 1));
      await expectLater(
        store.load(),
        throwsA(isA<TrustedHostStoreException>()),
      );
      backend.bytes = Uint8List.fromList(<int>[...valid, 0]);
      await expectLater(
        store.load(),
        throwsA(isA<TrustedHostStoreException>()),
      );
      backend.bytes = Uint8List(maxTrustedHostFileBytes + 1);
      await expectLater(
        store.load(),
        throwsA(isA<TrustedHostStoreException>()),
      );
    },
  );

  test(
    'rejects duplicate, substituted, mobile, insecure, and excessive bindings',
    () async {
      final store = TrustedHostStore(backend: MemoryTrustedHostFileBackend());
      final duplicate = _binding(1);
      await expectLater(
        store.save(<TrustedHostBinding>[duplicate, duplicate.deepCopy()]),
        throwsA(isA<TrustedHostStoreException>()),
      );

      final substituted = _binding(1)..hostIdentity.publicKey[0] ^= 1;
      final mobile = _binding(2)
        ..hostIdentity.platform = DevicePlatform.DEVICE_PLATFORM_IOS;
      final insecure = _binding(3)..signalingEndpoint = 'ws://example.test/ws';
      for (final invalid in <TrustedHostBinding>[
        substituted,
        mobile,
        insecure,
      ]) {
        await expectLater(
          store.save(<TrustedHostBinding>[invalid]),
          throwsA(isA<TrustedHostStoreException>()),
        );
      }

      await expectLater(
        store.save(
          List<TrustedHostBinding>.generate(
            maxTrustedHostBindings + 1,
            (index) => _binding(index + 1),
          ),
        ),
        throwsA(isA<TrustedHostStoreException>()),
      );
    },
  );

  test(
    'failed atomic replacement preserves the prior readable snapshot',
    () async {
      final backend = MemoryTrustedHostFileBackend();
      final store = TrustedHostStore(backend: backend);
      await store.save(<TrustedHostBinding>[_binding(1)]);
      final previous = Uint8List.fromList(backend.bytes!);
      backend.failReplace = true;

      await expectLater(
        store.save(<TrustedHostBinding>[_binding(2)]),
        throwsA(isA<TrustedHostStoreException>()),
      );
      expect(backend.bytes, previous);
      backend.failReplace = false;
      expect((await store.load()).single.hostIdentity.displayName, 'Host 1');
    },
  );
}

final class MemoryTrustedHostFileBackend implements TrustedHostFileBackend {
  Uint8List? bytes;
  bool failReplace = false;

  @override
  Future<Uint8List?> read() async =>
      bytes == null ? null : Uint8List.fromList(bytes!);

  @override
  Future<void> replace(Uint8List replacement) async {
    if (failReplace) {
      throw FileSystemException('replace failed');
    }
    bytes = Uint8List.fromList(replacement);
  }
}

TrustedHostBinding _binding(int marker) {
  final publicKey = List<int>.generate(32, (index) => (marker + index) & 0xff);
  return TrustedHostBinding(
    hostIdentity: DeviceIdentity(
      deviceId: deriveDeviceIdV1(publicKey),
      publicKeyAlgorithm: PublicKeyAlgorithm.PUBLIC_KEY_ALGORITHM_ED25519,
      publicKey: publicKey,
      displayName: 'Host $marker',
      platform: marker.isEven
          ? DevicePlatform.DEVICE_PLATFORM_WINDOWS
          : DevicePlatform.DEVICE_PLATFORM_MACOS,
    ),
    signalingEndpoint: 'wss://signal.example.test/v1/ws',
    pairedAtUnixMs: Int64(1700000000000 + marker),
    displayOrder: marker - 1,
  );
}
