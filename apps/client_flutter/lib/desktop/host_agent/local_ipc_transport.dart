// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_ipc/dart_ipc.dart' as ipc;
import 'package:path/path.dart' as path;
import 'package:roammand_protocol/roammand_protocol.dart';

const _runtimeDirectoryEnvironment = 'ROAMMAND_RUNTIME_DIR';
// Keep this pre-brand per-user directory stable so upgrades find the same Agent.
const _legacyProductDataDirectory = 'Roammand';
const _discoveryFileName = 'ipc-endpoint.txt';
const _tokenFileName = 'ipc-token.bin';
const _maximumDiscoveryBytes = 4096;
const _maximumEndpointCharacters = 2048;
const _supportedDiscoveryVersion = '1';
const _unixTransport = 'unix';
const _namedPipeTransport = 'named-pipe';

abstract interface class LocalIpcTransport {
  Stream<List<int>> get incoming;

  Future<void> write(Uint8List bytes);

  Future<void> close();
}

final class LocalIpcConnection {
  LocalIpcConnection(this.transport, this.token, {this.expectedInstanceId});

  final LocalIpcTransport transport;
  final Uint8List token;
  final Uint8List? expectedInstanceId;
}

abstract interface class HostAgentConnector {
  Future<LocalIpcConnection> connect();
}

final class DefaultHostAgentConnector implements HostAgentConnector {
  const DefaultHostAgentConnector({this.runtimeDirectory});

  final String? runtimeDirectory;

  @override
  Future<LocalIpcConnection> connect() async {
    final runtime = runtimeDirectory ?? _defaultRuntimeDirectory();
    final discoveryBytes = await _readBoundedRegularFile(
      path.join(runtime, _discoveryFileName),
      _maximumDiscoveryBytes,
    );
    final discovery = _parseDiscovery(discoveryBytes);
    final tokenBytes = await _readBoundedRegularFile(
      path.join(runtime, _tokenFileName),
      localIpcTokenBytes,
    );
    if (tokenBytes.length != localIpcTokenBytes) {
      tokenBytes.fillRange(0, tokenBytes.length, 0);
      throw const LocalIpcTransportException('Host Agent token is invalid');
    }

    try {
      final socket = await ipc.connect(discovery.endpoint);
      return LocalIpcConnection(
        _SocketLocalIpcTransport(socket),
        tokenBytes,
        expectedInstanceId: discovery.instanceId,
      );
    } catch (_) {
      tokenBytes.fillRange(0, tokenBytes.length, 0);
      throw const LocalIpcTransportException('Host Agent is unavailable');
    }
  }
}

final class LocalIpcTransportException implements Exception {
  const LocalIpcTransportException(this.message);

  final String message;

  @override
  String toString() => 'LocalIpcTransportException: $message';
}

final class _SocketLocalIpcTransport implements LocalIpcTransport {
  _SocketLocalIpcTransport(this._socket);

  final Socket _socket;
  bool _closed = false;

  @override
  Stream<List<int>> get incoming => _socket;

  @override
  Future<void> write(Uint8List bytes) async {
    if (_closed) {
      throw const LocalIpcTransportException('Host Agent connection is closed');
    }
    _socket.add(bytes);
    await _socket.flush();
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await _socket.close();
  }
}

final class _Discovery {
  const _Discovery(this.endpoint, this.instanceId);

  final String endpoint;
  final Uint8List instanceId;
}

Future<Uint8List> _readBoundedRegularFile(String filePath, int limit) async {
  final type = await FileSystemEntity.type(filePath, followLinks: false);
  if (type != FileSystemEntityType.file) {
    throw const LocalIpcTransportException(
      'Host Agent discovery is unavailable',
    );
  }
  final file = File(filePath);
  final length = await file.length();
  if (length <= 0 || length > limit) {
    throw const LocalIpcTransportException('Host Agent discovery is invalid');
  }
  final bytes = await file.readAsBytes();
  if (bytes.length != length || bytes.length > limit) {
    throw const LocalIpcTransportException(
      'Host Agent discovery changed while reading',
    );
  }
  return bytes;
}

_Discovery _parseDiscovery(Uint8List bytes) {
  late final String text;
  try {
    text = utf8.decode(bytes, allowMalformed: false);
  } on FormatException {
    throw const LocalIpcTransportException('Host Agent discovery is invalid');
  }
  final values = <String, String>{};
  for (final line in text.split('\n')) {
    if (line.isEmpty) {
      continue;
    }
    final separator = line.indexOf('=');
    if (separator <= 0 || separator == line.length - 1) {
      throw const LocalIpcTransportException('Host Agent discovery is invalid');
    }
    final key = line.substring(0, separator);
    if (values.containsKey(key)) {
      throw const LocalIpcTransportException(
        'Host Agent discovery is ambiguous',
      );
    }
    values[key] = line.substring(separator + 1);
  }
  final endpoint = values['endpoint'];
  final instanceHex = values['instance_id'];
  if (values.length != 4 ||
      values['version'] != _supportedDiscoveryVersion ||
      endpoint == null ||
      endpoint.length > _maximumEndpointCharacters ||
      instanceHex == null ||
      instanceHex.length != agentInstanceIdBytes * 2 ||
      !_transportMatchesPlatform(values['transport'])) {
    throw const LocalIpcTransportException('Host Agent discovery is invalid');
  }
  return _Discovery(endpoint, _decodeHex(instanceHex));
}

bool _transportMatchesPlatform(String? transport) {
  if (Platform.isWindows) {
    return transport == _namedPipeTransport;
  }
  if (Platform.isMacOS) {
    return transport == _unixTransport;
  }
  return false;
}

Uint8List _decodeHex(String value) {
  final bytes = Uint8List(value.length ~/ 2);
  for (var index = 0; index < bytes.length; index += 1) {
    final byte = int.tryParse(
      value.substring(index * 2, index * 2 + 2),
      radix: 16,
    );
    if (byte == null) {
      throw const LocalIpcTransportException('Host Agent discovery is invalid');
    }
    bytes[index] = byte;
  }
  return bytes;
}

String _defaultRuntimeDirectory() {
  final override = Platform.environment[_runtimeDirectoryEnvironment];
  if (override != null && override.isNotEmpty) {
    return override;
  }
  if (Platform.isMacOS) {
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      throw const LocalIpcTransportException(
        'Current-user home is unavailable',
      );
    }
    return path.join(
      home,
      'Library',
      'Caches',
      _legacyProductDataDirectory,
      'runtime',
    );
  }
  if (Platform.isWindows) {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData == null || localAppData.isEmpty) {
      throw const LocalIpcTransportException(
        'Current-user data is unavailable',
      );
    }
    return path.join(localAppData, _legacyProductDataDirectory, 'runtime');
  }
  throw const LocalIpcTransportException(
    'Host Agent is unsupported on this platform',
  );
}
