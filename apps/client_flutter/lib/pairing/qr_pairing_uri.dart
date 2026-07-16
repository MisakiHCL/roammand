// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';

import 'package:roammand/desktop/remote/signaling_client.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

import 'device_identity_validator.dart';
import 'pairing_limits.dart';

const _scheme = 'roammand';
const _legacyScheme = 'prd';
const _host = 'pair';
const _pathVersion = 'v1';
const _payloadPattern = r'^[A-Za-z0-9_-]+$';

final class QrPairingUriException implements Exception {
  const QrPairingUriException();

  @override
  String toString() => 'QrPairingUriException';
}

String encodeQrPairingUri(HostPairingInvitation invitation) {
  return _encodeQrPairingUri(invitation, scheme: _scheme);
}

String _encodeQrPairingUri(
  HostPairingInvitation invitation, {
  required String scheme,
}) {
  try {
    _validateInvitation(invitation, nowUnixMs: null);
    _rejectUnknownFields(invitation);
    final payload = base64UrlEncode(
      invitation.writeToBuffer(),
    ).replaceAll('=', '');
    final encoded = Uri(
      scheme: scheme,
      host: _host,
      pathSegments: <String>[_pathVersion, payload],
    ).toString();
    if (utf8.encode(encoded).length > maxQrPairingUriBytes) {
      throw const QrPairingUriException();
    }
    return encoded;
  } on QrPairingUriException {
    rethrow;
  } catch (_) {
    throw const QrPairingUriException();
  }
}

HostPairingInvitation parseQrPairingUri(
  String encoded, {
  required int nowUnixMs,
}) {
  if (encoded.isEmpty || utf8.encode(encoded).length > maxQrPairingUriBytes) {
    throw const QrPairingUriException();
  }
  try {
    final uri = Uri.parse(encoded);
    if ((uri.scheme != _scheme && uri.scheme != _legacyScheme) ||
        uri.host != _host ||
        !uri.hasAuthority ||
        uri.hasPort ||
        uri.userInfo.isNotEmpty ||
        uri.query.isNotEmpty ||
        uri.fragment.isNotEmpty ||
        uri.pathSegments.length != 2 ||
        uri.pathSegments.first != _pathVersion ||
        uri.pathSegments.last.isEmpty ||
        uri.toString() != encoded) {
      throw const QrPairingUriException();
    }
    final payload = uri.pathSegments.last;
    if (!RegExp(_payloadPattern).hasMatch(payload) || payload.contains('=')) {
      throw const QrPairingUriException();
    }
    final bytes = base64Url.decode(base64Url.normalize(payload));
    if (bytes.isEmpty || bytes.length > maxQrPairingPayloadBytes) {
      throw const QrPairingUriException();
    }
    final invitation = HostPairingInvitation.fromBuffer(bytes);
    _rejectUnknownFields(invitation);
    if (!_bytesEqual(invitation.writeToBuffer(), bytes)) {
      throw const QrPairingUriException();
    }
    _validateInvitation(invitation, nowUnixMs: nowUnixMs);
    if (_encodeQrPairingUri(invitation, scheme: uri.scheme) != encoded) {
      throw const QrPairingUriException();
    }
    return invitation.deepCopy();
  } on QrPairingUriException {
    rethrow;
  } catch (_) {
    throw const QrPairingUriException();
  }
}

void _validateInvitation(
  HostPairingInvitation invitation, {
  required int? nowUnixMs,
}) {
  if (!invitation.hasProtocolVersion() ||
      invitation.protocolVersion.major != protocolMajorVersion ||
      invitation.protocolVersion.minor < minimumProtocolMinorVersion ||
      invitation.kind != PairingInvitationKind.PAIRING_INVITATION_KIND_QR ||
      invitation.rendezvousId.length != rendezvousIdBytes ||
      !invitation.hasHostIdentity() ||
      invitation.hostEphemeralPublicKey.length != publicKeyBytes ||
      invitation.pairingCode.isNotEmpty ||
      invitation.signalingEndpoint.isEmpty) {
    throw const QrPairingUriException();
  }
  validateDesktopHostIdentity(invitation.hostIdentity);
  validateHostFingerprint(
    invitation.hostIdentity,
    invitation.hostPublicKeyFingerprintSha256,
  );
  final endpoint = Uri.parse(invitation.signalingEndpoint);
  validateSignalingEndpoint(endpoint);
  final issuedAt = invitation.issuedAtUnixMs.toInt();
  final expiresAt = invitation.expiresAtUnixMs.toInt();
  if (issuedAt <= 0 ||
      expiresAt < issuedAt ||
      expiresAt - issuedAt > pairingRendezvousLifetimeMs ||
      (nowUnixMs != null && nowUnixMs > expiresAt)) {
    throw const QrPairingUriException();
  }
}

void _rejectUnknownFields(HostPairingInvitation invitation) {
  if (invitation.unknownFields.isNotEmpty ||
      (invitation.hasProtocolVersion() &&
          invitation.protocolVersion.unknownFields.isNotEmpty) ||
      (invitation.hasHostIdentity() &&
          invitation.hostIdentity.unknownFields.isNotEmpty)) {
    throw const QrPairingUriException();
  }
}

bool _bytesEqual(List<int> left, List<int> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
