// SPDX-License-Identifier: MPL-2.0

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/desktop/home/trusted_computers_controller.dart';
import 'package:roammand/pairing/trusted_host_repository.dart';
import 'package:roammand/pairing/trusted_host_store.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

void main() {
  test(
    'loads immutable trusted computers and builds a validated target',
    () async {
      final persistence = MemoryTrustedComputersPersistence()
        ..bindings = <TrustedHostBinding>[_binding(1)];
      final repository = TrustedHostRepository(persistence: persistence);
      final controller = TrustedComputersController(
        repositoryFactory: () async => repository,
      );
      final states = <TrustedComputersState>[];
      controller.addListener(() => states.add(controller.state));

      await controller.start();

      expect(controller.state, TrustedComputersState.ready);
      expect(controller.hosts, hasLength(1));
      expect(controller.hosts.single.displayName, 'Host 1');
      expect(() => controller.hosts.clear(), throwsUnsupportedError);
      final target = controller.targetFor(controller.hosts.single);
      expect(target.hostIdentity.displayName, 'Host 1');
      expect(target.signalingEndpoint.scheme, 'wss');
      expect(states, contains(TrustedComputersState.ready));
      controller.dispose();
    },
  );

  test('deletes locally and timestamps only a successful connection', () async {
    final persistence = MemoryTrustedComputersPersistence()
      ..bindings = <TrustedHostBinding>[_binding(1), _binding(2)];
    final repository = TrustedHostRepository(persistence: persistence);
    final controller = TrustedComputersController(
      repositoryFactory: () async => repository,
    );
    await controller.start();
    final firstId = controller.hosts.first.hostIdentity.deviceId;
    final second = controller.hosts.last;

    await controller.markSuccessfulConnection(
      second,
      nowUnixMs: second.pairedAtUnixMs + 100,
    );
    expect(
      controller.hosts.last.lastSuccessfulConnectionAtUnixMs,
      second.pairedAtUnixMs + 100,
    );
    await controller.deleteLocal(firstId);
    expect(controller.hosts, hasLength(1));
    expect(controller.hosts.single.displayName, 'Host 2');
    expect(await controller.deleteLocal(firstId), isFalse);
    controller.dispose();
  });

  test(
    'reports initialization failure without exposing partial hosts',
    () async {
      final controller = TrustedComputersController(
        repositoryFactory: () async => throw StateError('storage unavailable'),
      );

      await controller.start();

      expect(controller.state, TrustedComputersState.error);
      expect(controller.hosts, isEmpty);
      controller.dispose();
    },
  );
}

final class MemoryTrustedComputersPersistence
    implements TrustedHostPersistence {
  List<TrustedHostBinding> bindings = <TrustedHostBinding>[];

  @override
  Future<List<TrustedHostBinding>> load() async =>
      bindings.map((binding) => binding.deepCopy()).toList();

  @override
  Future<void> save(Iterable<TrustedHostBinding> bindings) async {
    this.bindings = bindings.map((binding) => binding.deepCopy()).toList();
  }
}

TrustedHostBinding _binding(int seed) {
  final publicKey = List<int>.generate(32, (index) => seed + index);
  return TrustedHostBinding(
    hostIdentity: DeviceIdentity(
      deviceId: deriveDeviceIdV1(publicKey),
      publicKeyAlgorithm: PublicKeyAlgorithm.PUBLIC_KEY_ALGORITHM_ED25519,
      publicKey: publicKey,
      displayName: 'Host $seed',
      platform: DevicePlatform.DEVICE_PLATFORM_MACOS,
    ),
    signalingEndpoint: 'wss://signal.example.test/v1/connect',
    pairedAtUnixMs: Int64(1000 + seed),
    displayOrder: seed - 1,
  );
}
