// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/desktop/home/host_connection_descriptor.dart';
import 'package:roammand/desktop/host_agent/host_agent_models.dart';
import 'package:roammand/desktop/maintenance/host_maintenance.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

void main() {
  test('describe exports only the public local identity', () async {
    final agent = _FakeHostAgent(_identity('Controller Mac', 1));
    final output = <String>[];
    final errors = <String>[];
    final runner = HostMaintenanceRunner(
      clientFactory: () => agent,
      writeOutput: output.add,
      writeError: errors.add,
    );

    final result = await runner.run(<String>[
      'describe',
      'wss://signal.example.test/v1/ws',
    ]);

    expect(result, 0);
    expect(errors, isEmpty);
    expect(output, hasLength(1));
    final decoded = jsonDecode(output.single) as Map<String, dynamic>;
    expect(decoded.keys, isNot(contains('privateKey')));
    final descriptor = parsePublicHostConnectionDescriptor(output.single);
    expect(descriptor.identity.displayName, 'Controller Mac');
    expect(descriptor.signalingEndpoint.scheme, 'wss');
    expect(agent.closed, isTrue);
  });

  test(
    'authorize-controller creates a permanent view and control grant',
    () async {
      final hostAgent = _FakeHostAgent(_identity('Host Mac', 33));
      final controller = _identity('Controller Mac', 65);
      final descriptor = encodePublicHostConnectionDescriptor(
        PublicHostConnectionDescriptor(
          identity: controller,
          signalingEndpoint: Uri.parse('wss://signal.example.test/v1/ws'),
        ),
      );
      final output = <String>[];
      final runner = HostMaintenanceRunner(
        clientFactory: () => hostAgent,
        writeOutput: output.add,
        writeError: (_) {},
      );

      final result = await runner.run(<String>[
        'authorize-controller',
        descriptor,
      ]);

      expect(result, 0);
      expect(output, <String>['{"status":"authorized"}']);
      expect(hostAgent.authorizedController?.deviceId, controller.deviceId);
      expect(hostAgent.permissions, <SessionPermission>[
        SessionPermission.SESSION_PERMISSION_VIEW_SCREEN,
        SessionPermission.SESSION_PERMISSION_CONTROL_INPUT,
      ]);
      expect(hostAgent.closed, isTrue);
    },
  );

  test('invalid command fails before connecting to the Host Agent', () async {
    final agent = _FakeHostAgent(_identity('Host Mac', 97));
    final errors = <String>[];
    final runner = HostMaintenanceRunner(
      clientFactory: () => agent,
      writeOutput: (_) {},
      writeError: errors.add,
    );

    final result = await runner.run(<String>['authorize-controller']);

    expect(result, 2);
    expect(errors, <String>['{"error":"invalid_arguments"}']);
    expect(agent.connected, isFalse);
  });
}

DeviceIdentity _identity(String name, int firstByte) {
  final publicKey = List<int>.generate(32, (index) => firstByte + index);
  return DeviceIdentity(
    deviceId: deriveDeviceIdV1(publicKey),
    publicKeyAlgorithm: PublicKeyAlgorithm.PUBLIC_KEY_ALGORITHM_ED25519,
    publicKey: publicKey,
    displayName: name,
    platform: DevicePlatform.DEVICE_PLATFORM_MACOS,
  );
}

final class _FakeHostAgent implements HostAgentApi {
  _FakeHostAgent(this.identity);

  final DeviceIdentity identity;
  bool connected = false;
  bool closed = false;
  DeviceIdentity? authorizedController;
  List<SessionPermission> permissions = const <SessionPermission>[];

  @override
  Stream<SessionTerminatedEvent> get sessionTerminations =>
      const Stream<SessionTerminatedEvent>.empty();

  @override
  Stream<HostPairingStatusSnapshot> get hostPairingStates =>
      const Stream<HostPairingStatusSnapshot>.empty();

  @override
  Stream<PrivilegedBridgeStatusSnapshot> get privilegedBridgeStates =>
      const Stream<PrivilegedBridgeStatusSnapshot>.empty();

  @override
  Future<EmergencyStopRemoteSessionResult> emergencyStopRemoteSession() async =>
      EmergencyStopRemoteSessionResult();

  @override
  Future<void> connect() async {
    connected = true;
  }

  @override
  Future<HostStatus> getHostStatus() async => HostStatus(identity: identity);

  @override
  Future<ControllerGrantView> createControllerGrant(
    DeviceIdentity controller,
    Iterable<SessionPermission> permissions,
  ) async {
    authorizedController = controller.deepCopy();
    this.permissions = List<SessionPermission>.of(permissions);
    return ControllerGrantView();
  }

  @override
  Future<List<ControllerGrantView>> listControllerGrants() async =>
      const <ControllerGrantView>[];

  @override
  Future<ControllerGrantRevoked> revokeControllerGrant(List<int> grantId) =>
      throw UnimplementedError();

  @override
  Future<CanonicalTranscriptSignature> signCanonicalTranscript(
    List<int> canonicalTranscript,
  ) => throw UnimplementedError();

  @override
  Future<SessionOfferSignature> signSessionOffer(
    List<int> canonicalTranscript,
  ) => throw UnimplementedError();

  @override
  Future<PairingTranscriptSignature> signPairingTranscript(
    List<int> canonicalTranscript,
    PairingIdentityRole role,
  ) => throw UnimplementedError();

  @override
  Future<HostPairingStatusSnapshot> getHostPairingStatus() async =>
      HostPairingStatusSnapshot(
        state: HostPairingState.HOST_PAIRING_STATE_IDLE,
      );

  @override
  Future<HostPairingStatusSnapshot> startHostQrPairing(
    String signalingEndpoint,
  ) => throw UnimplementedError();

  @override
  Future<HostPairingStatusSnapshot> startHostDesktopCodePairing(
    String signalingEndpoint,
  ) => throw UnimplementedError();

  @override
  Future<HostPairingStatusSnapshot> cancelHostPairing(List<int> rendezvousId) =>
      throw UnimplementedError();

  @override
  Future<HostPairingStatusSnapshot> acceptHostPairing(
    List<int> rendezvousId,
    List<int> controllerDeviceId,
  ) => throw UnimplementedError();

  @override
  Future<HostPairingStatusSnapshot> rejectHostPairing(
    List<int> rendezvousId,
    List<int> controllerDeviceId,
  ) => throw UnimplementedError();

  @override
  Future<void> close() async {
    closed = true;
  }
}
