// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';

import 'package:roammand_protocol/roammand_protocol.dart';

import '../remote/signaling_client.dart';

const _maximumDescriptorBytes = 8192;
const _descriptorVersion = 1;

final class HostConnectionDescriptorException implements Exception {
  const HostConnectionDescriptorException();

  @override
  String toString() => 'HostConnectionDescriptorException';
}

final class PublicHostConnectionDescriptor {
  PublicHostConnectionDescriptor({
    required DeviceIdentity identity,
    required this.signalingEndpoint,
  }) : identity = identity.deepCopy();

  final DeviceIdentity identity;
  final Uri signalingEndpoint;

  void validate() {
    try {
      validateDeviceIdentity(identity);
      validateSignalingEndpoint(signalingEndpoint);
      if (!_bytesEqual(
        identity.deviceId,
        deriveDeviceIdV1(identity.publicKey),
      )) {
        throw const HostConnectionDescriptorException();
      }
      _platformName(identity.platform);
    } catch (_) {
      throw const HostConnectionDescriptorException();
    }
  }
}

String encodePublicHostConnectionDescriptor(
  PublicHostConnectionDescriptor descriptor,
) {
  descriptor.validate();
  return jsonEncode(<String, Object>{
    'version': _descriptorVersion,
    'signaling': descriptor.signalingEndpoint.toString(),
    'deviceId': base64UrlEncode(descriptor.identity.deviceId),
    'publicKey': base64UrlEncode(descriptor.identity.publicKey),
    'displayName': descriptor.identity.displayName,
    'platform': _platformName(descriptor.identity.platform),
  });
}

PublicHostConnectionDescriptor parsePublicHostConnectionDescriptor(
  String encoded,
) {
  if (encoded.isEmpty ||
      utf8.encode(encoded).length > _maximumDescriptorBytes) {
    throw const HostConnectionDescriptorException();
  }
  try {
    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, dynamic>) {
      throw const HostConnectionDescriptorException();
    }
    const keys = <String>{
      'version',
      'signaling',
      'deviceId',
      'publicKey',
      'displayName',
      'platform',
    };
    if (decoded.length != keys.length ||
        !decoded.keys.toSet().containsAll(keys) ||
        decoded['version'] != _descriptorVersion ||
        decoded['signaling'] is! String ||
        decoded['deviceId'] is! String ||
        decoded['publicKey'] is! String ||
        decoded['displayName'] is! String ||
        decoded['platform'] is! String) {
      throw const HostConnectionDescriptorException();
    }
    final descriptor = PublicHostConnectionDescriptor(
      identity: DeviceIdentity(
        deviceId: base64Url.decode(
          base64Url.normalize(decoded['deviceId'] as String),
        ),
        publicKeyAlgorithm: PublicKeyAlgorithm.PUBLIC_KEY_ALGORITHM_ED25519,
        publicKey: base64Url.decode(
          base64Url.normalize(decoded['publicKey'] as String),
        ),
        displayName: decoded['displayName'] as String,
        platform: _parsePlatform(decoded['platform'] as String),
      ),
      signalingEndpoint: Uri.parse(decoded['signaling'] as String),
    );
    descriptor.validate();
    return descriptor;
  } on HostConnectionDescriptorException {
    rethrow;
  } catch (_) {
    throw const HostConnectionDescriptorException();
  }
}

String _platformName(DevicePlatform platform) => switch (platform) {
  DevicePlatform.DEVICE_PLATFORM_MACOS => 'macos',
  DevicePlatform.DEVICE_PLATFORM_WINDOWS => 'windows',
  _ => throw const HostConnectionDescriptorException(),
};

DevicePlatform _parsePlatform(String value) => switch (value) {
  'macos' => DevicePlatform.DEVICE_PLATFORM_MACOS,
  'windows' => DevicePlatform.DEVICE_PLATFORM_WINDOWS,
  _ => throw const HostConnectionDescriptorException(),
};

bool _bytesEqual(List<int> left, List<int> right) {
  if (left.length != right.length) {
    return false;
  }
  var difference = 0;
  for (var index = 0; index < left.length; index += 1) {
    difference |= left[index] ^ right[index];
  }
  return difference == 0;
}
