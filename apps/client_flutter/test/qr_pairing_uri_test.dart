// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/pairing/device_identity_validator.dart';
import 'package:roammand/pairing/pairing_limits.dart';
import 'package:roammand/pairing/qr_pairing_uri.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

void main() {
  test('QR pairing URI round trips one canonical invitation', () {
    final invitation = _invitation();
    final encoded = encodeQrPairingUri(invitation);
    final decoded = parseQrPairingUri(encoded, nowUnixMs: 60_000);

    expect(encoded, startsWith('roammand://pair/v1/'));
    expect(encoded, isNot(contains('=')));
    expect(decoded, invitation);
  });

  test('QR pairing URI rejects non-canonical URI structure', () {
    final valid = encodeQrPairingUri(_invitation());
    final payload = Uri.parse(valid).pathSegments.last;
    for (final value in <String>[
      valid.replaceFirst('roammand:', 'https:'),
      valid.replaceFirst('//pair/', '//other/'),
      valid.replaceFirst('/v1/', '/v2/'),
      valid.replaceFirst('/v1/', '/v1/extra/'),
      'roammand://user@pair/v1/$payload',
      '$valid?debug=1',
      '$valid#fragment',
      '$valid=',
      'roammand://pair/v1/',
      'roammand://pair/v1/${List<String>.filled(maxQrPairingUriBytes + 1, 'A').join()}',
    ]) {
      expect(
        () => parseQrPairingUri(value, nowUnixMs: 60_000),
        throwsA(isA<QrPairingUriException>()),
        reason: value.substring(0, value.length > 80 ? 80 : value.length),
      );
    }
  });

  test('QR pairing URI rejects duplicate, unknown and reordered fields', () {
    final invitation = _invitation();
    final canonical = invitation.writeToBuffer();
    final mutations = <List<int>>[
      <int>[...canonical, 0x10, 0x01],
      <int>[...canonical, 0xf8, 0x07, 0x01],
      <int>[...canonical.sublist(2), ...canonical.sublist(0, 2)],
    ];

    for (final mutation in mutations) {
      final payload = base64UrlEncode(mutation).replaceAll('=', '');
      expect(
        () =>
            parseQrPairingUri('roammand://pair/v1/$payload', nowUnixMs: 60_000),
        throwsA(isA<QrPairingUriException>()),
      );
    }
  });

  test(
    'QR pairing URI rejects expired, oversized lifetime and substitutions',
    () {
      final valid = _invitation();
      final fingerprint = valid.hostPublicKeyFingerprintSha256;
      final cases = <HostPairingInvitation>[
        valid.deepCopy()..expiresAtUnixMs = Int64(59_999),
        valid.deepCopy()..expiresAtUnixMs = Int64(121_001),
        valid.deepCopy()
          ..kind = PairingInvitationKind.PAIRING_INVITATION_KIND_DESKTOP_CODE
          ..pairingCode = 'ABCDEFG2',
        valid.deepCopy()..hostIdentity.deviceId[0] ^= 1,
        valid.deepCopy()
          ..hostIdentity.platform = DevicePlatform.DEVICE_PLATFORM_IOS,
        valid.deepCopy()
          ..hostPublicKeyFingerprintSha256 = List<int>.from(fingerprint)
          ..hostPublicKeyFingerprintSha256[0] ^= 1,
        valid.deepCopy()..hostEphemeralPublicKey.removeLast(),
        valid.deepCopy()
          ..signalingEndpoint = 'ws://signal.example.test/v1/connect',
      ];

      for (final invitation in cases) {
        expect(
          () => parseQrPairingUri(
            _uncheckedUri(invitation.writeToBuffer()),
            nowUnixMs: 60_000,
          ),
          throwsA(isA<QrPairingUriException>()),
        );
      }
    },
  );

  test('QR pairing permits plaintext signaling only on loopback', () {
    final invitation = _invitation()
      ..signalingEndpoint = 'ws://127.0.0.1:8080/v1/connect';

    expect(
      parseQrPairingUri(
        encodeQrPairingUri(invitation),
        nowUnixMs: 60_000,
      ).signalingEndpoint,
      invitation.signalingEndpoint,
    );
  });

  test('QR pairing still accepts a canonical pre-brand URI', () {
    final current = encodeQrPairingUri(_invitation());
    final legacy = current.replaceFirst('roammand:', 'prd:');

    expect(parseQrPairingUri(legacy, nowUnixMs: 60_000), _invitation());
  });
}

HostPairingInvitation _invitation() {
  final publicKey = List<int>.generate(32, (index) => index + 1);
  final identity = DeviceIdentity(
    deviceId: deriveDeviceIdV1(publicKey),
    publicKeyAlgorithm: PublicKeyAlgorithm.PUBLIC_KEY_ALGORITHM_ED25519,
    publicKey: publicKey,
    displayName: 'Living room Mac',
    platform: DevicePlatform.DEVICE_PLATFORM_MACOS,
  );
  return HostPairingInvitation(
    protocolVersion: ProtocolVersion(major: 1, minor: 0),
    kind: PairingInvitationKind.PAIRING_INVITATION_KIND_QR,
    rendezvousId: List<int>.generate(16, (index) => index + 0x40),
    hostIdentity: identity,
    hostPublicKeyFingerprintSha256: devicePublicKeyFingerprintSha256(identity),
    hostEphemeralPublicKey: List<int>.generate(32, (index) => index + 0x60),
    signalingEndpoint: 'wss://signal.example.test/v1/connect',
    issuedAtUnixMs: Int64(1_000),
    expiresAtUnixMs: Int64(121_000),
  );
}

String _uncheckedUri(List<int> bytes) =>
    'roammand://pair/v1/${base64UrlEncode(bytes).replaceAll('=', '')}';
