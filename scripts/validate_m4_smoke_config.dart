// SPDX-License-Identifier: Apache-2.0

import 'dart:convert';
import 'dart:io';

import 'package:roammand_protocol/roammand_protocol.dart';

const _realSignalingEndpoint = 'ROAMMAND_M4_SIGNALING_ENDPOINT';
const _realHostDescriptor = 'ROAMMAND_M4_HOST_DESCRIPTOR';
const _icePolicy = 'ROAMMAND_ICE_TRANSPORT_POLICY';
const _turnUrls = 'ROAMMAND_TURN_URLS';
const _turnUsername = 'ROAMMAND_TURN_USERNAME';
const _turnPassword = 'ROAMMAND_TURN_PASSWORD';
const _maximumDescriptorBytes = 8192;
const _maximumEndpointBytes = 2048;
const _maximumTurnUrls = 8;
const _maximumTurnValueBytes = 1024;
const _descriptorVersion = 1;

void main() {
  try {
    _validateRealMachine(Platform.environment);
    _validateTurn(Platform.environment);
  } on _ConfigurationFailure catch (error) {
    stderr.writeln('FAIL ${error.message}');
    exitCode = 2;
  }
}

void _validateRealMachine(Map<String, String> values) {
  final endpointValue = values[_realSignalingEndpoint]?.trim() ?? '';
  final descriptorValue = values[_realHostDescriptor]?.trim() ?? '';
  if (endpointValue.isEmpty && descriptorValue.isEmpty) {
    stdout.writeln('SKIP real-machine: configuration not supplied');
    return;
  }
  if (endpointValue.isEmpty || descriptorValue.isEmpty) {
    _fail('real-machine configuration is incomplete');
  }
  final endpoint = _signalingEndpoint(endpointValue);
  final descriptor = _decodeDescriptor(descriptorValue);
  if (descriptor.signalingEndpoint != endpoint) {
    _fail('real-machine signaling endpoints do not match');
  }
  stdout.writeln('READY real-machine: configuration valid');
}

void _validateTurn(Map<String, String> values) {
  final policy = values[_icePolicy]?.trim().toLowerCase() ?? '';
  final urlsValue = values[_turnUrls]?.trim() ?? '';
  final username = values[_turnUsername]?.trim() ?? '';
  final password = values[_turnPassword] ?? '';
  if (!const <String>{'', 'all', 'relay'}.contains(policy)) {
    _fail('ICE transport policy is invalid');
  }
  final anyTurnValue =
      urlsValue.isNotEmpty || username.isNotEmpty || password.isNotEmpty;
  if (!anyTurnValue && policy != 'relay') {
    stdout.writeln('SKIP TURN: configuration not supplied');
    return;
  }
  if (urlsValue.isEmpty || username.isEmpty || password.isEmpty) {
    _fail('TURN configuration is incomplete');
  }
  if (utf8.encode(username).length > _maximumTurnValueBytes ||
      utf8.encode(password).length > _maximumTurnValueBytes) {
    _fail('TURN credential exceeds the protocol limit');
  }
  final urls = urlsValue
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
  if (urls.isEmpty || urls.length > _maximumTurnUrls) {
    _fail('TURN URL count is invalid');
  }
  for (final value in urls) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        utf8.encode(value).length > _maximumEndpointBytes ||
        !const <String>{'turn', 'turns'}.contains(uri.scheme)) {
      _fail('TURN URL is invalid');
    }
  }
  stdout.writeln('READY TURN: relay configuration valid');
}

_HostDescriptor _decodeDescriptor(String encoded) {
  if (utf8.encode(encoded).length > _maximumDescriptorBytes) {
    _fail('Host descriptor exceeds the protocol limit');
  }
  try {
    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, dynamic>) {
      _fail('Host descriptor is not an object');
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
        !decoded.keys.toSet().containsAll(keys)) {
      _fail('Host descriptor fields are invalid');
    }
    if (decoded['version'] != _descriptorVersion ||
        decoded['signaling'] is! String ||
        decoded['deviceId'] is! String ||
        decoded['publicKey'] is! String ||
        decoded['displayName'] is! String ||
        decoded['platform'] is! String) {
      _fail('Host descriptor values are invalid');
    }
    final deviceId = base64Url.decode(
      base64Url.normalize(decoded['deviceId'] as String),
    );
    final publicKey = base64Url.decode(
      base64Url.normalize(decoded['publicKey'] as String),
    );
    final platform = switch (decoded['platform']) {
      'macos' => DevicePlatform.DEVICE_PLATFORM_MACOS,
      'windows' => DevicePlatform.DEVICE_PLATFORM_WINDOWS,
      _ => throw const FormatException(),
    };
    final identity = DeviceIdentity(
      deviceId: deviceId,
      publicKeyAlgorithm: PublicKeyAlgorithm.PUBLIC_KEY_ALGORITHM_ED25519,
      publicKey: publicKey,
      displayName: decoded['displayName'] as String,
      platform: platform,
    );
    validateDeviceIdentity(identity);
    if (!_bytesEqual(deviceId, deriveDeviceIdV1(publicKey))) {
      _fail('Host descriptor device ID is invalid');
    }
    return _HostDescriptor(
      signalingEndpoint: _signalingEndpoint(decoded['signaling'] as String),
    );
  } on _ConfigurationFailure {
    rethrow;
  } catch (_) {
    _fail('Host descriptor is invalid');
  }
}

Uri _signalingEndpoint(String value) {
  if (utf8.encode(value).length > _maximumEndpointBytes) {
    _fail('signaling endpoint exceeds the protocol limit');
  }
  final endpoint = Uri.tryParse(value);
  if (endpoint == null ||
      !endpoint.hasAuthority ||
      endpoint.host.isEmpty ||
      endpoint.userInfo.isNotEmpty) {
    _fail('signaling endpoint is invalid');
  }
  if (endpoint.scheme == 'wss') {
    return endpoint;
  }
  if (endpoint.scheme == 'ws' && _isLoopback(endpoint.host)) {
    return endpoint;
  }
  _fail('signaling endpoint is insecure');
}

bool _isLoopback(String host) {
  if (host.toLowerCase() == 'localhost') {
    return true;
  }
  return InternetAddress.tryParse(host)?.isLoopback ?? false;
}

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

Never _fail(String message) => throw _ConfigurationFailure(message);

final class _HostDescriptor {
  const _HostDescriptor({required this.signalingEndpoint});

  final Uri signalingEndpoint;
}

final class _ConfigurationFailure implements Exception {
  const _ConfigurationFailure(this.message);

  final String message;
}
