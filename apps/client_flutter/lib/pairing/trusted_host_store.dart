// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as paths;
import 'package:path_provider/path_provider.dart';
import 'package:roammand/desktop/remote/signaling_client.dart';
import 'package:roammand/identity/device_display_name.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

const trustedHostEnvelopeMagic = <int>[
  0x50,
  0x52,
  0x44,
  0x54,
  0x48,
  0x53,
  0x31,
  0x00,
];
const trustedHostEnvelopeHeaderBytes = 48;
const maxTrustedHostSnapshotBytes = 1024 * 1024;
const maxTrustedHostFileBytes =
    trustedHostEnvelopeHeaderBytes + maxTrustedHostSnapshotBytes;
const maxTrustedHostBindings = 256;
const _envelopeVersion = 1;
const _checksumBytes = 32;
const _trustedHostsFileName = 'trusted-hosts-v1.bin';

enum TrustedHostStoreError {
  corruptRecord,
  invalidBinding,
  tooManyBindings,
  unavailable,
}

final class TrustedHostStoreException implements Exception {
  const TrustedHostStoreException(this.code);

  final TrustedHostStoreError code;

  @override
  String toString() => 'TrustedHostStoreException(${code.name})';
}

abstract interface class TrustedHostPersistence {
  Future<List<TrustedHostBinding>> load();

  Future<void> save(Iterable<TrustedHostBinding> bindings);
}

abstract interface class TrustedHostFileBackend {
  Future<Uint8List?> read();

  Future<void> replace(Uint8List replacement);
}

final class IoTrustedHostFileBackend implements TrustedHostFileBackend {
  IoTrustedHostFileBackend(String path) : _file = File(path);

  final File _file;

  @override
  Future<Uint8List?> read() async {
    if (!await _file.exists()) {
      return null;
    }
    if (await _file.length() > maxTrustedHostFileBytes) {
      throw const TrustedHostStoreException(
        TrustedHostStoreError.corruptRecord,
      );
    }
    return _file.readAsBytes();
  }

  @override
  Future<void> replace(Uint8List replacement) async {
    await _file.parent.create(recursive: true);
    final temporary = File('${_file.path}.$pid.tmp');
    try {
      await temporary.writeAsBytes(replacement, flush: true);
      await temporary.rename(_file.path);
    } finally {
      if (await temporary.exists()) {
        await temporary.delete();
      }
    }
  }
}

final class TrustedHostStore implements TrustedHostPersistence {
  factory TrustedHostStore({required TrustedHostFileBackend backend}) =>
      TrustedHostStore._(backend);

  TrustedHostStore._(this._backend);

  factory TrustedHostStore.atPath(String path) =>
      TrustedHostStore(backend: IoTrustedHostFileBackend(path));

  final TrustedHostFileBackend _backend;

  static Future<TrustedHostStore> applicationSupport() async {
    final directory = await getApplicationSupportDirectory();
    return TrustedHostStore.atPath(
      paths.join(directory.path, _trustedHostsFileName),
    );
  }

  @override
  Future<List<TrustedHostBinding>> load() async {
    try {
      final encoded = await _backend.read();
      if (encoded == null) {
        return <TrustedHostBinding>[];
      }
      return _decodeEnvelope(encoded);
    } on TrustedHostStoreException {
      rethrow;
    } catch (_) {
      throw const TrustedHostStoreException(TrustedHostStoreError.unavailable);
    }
  }

  @override
  Future<void> save(Iterable<TrustedHostBinding> bindings) async {
    final snapshotBindings = bindings
        .map((binding) => binding.deepCopy())
        .toList(growable: false);
    validateTrustedHostBindings(snapshotBindings);
    final encoded = _encodeEnvelope(snapshotBindings);
    try {
      await _backend.replace(encoded);
    } on TrustedHostStoreException {
      rethrow;
    } catch (_) {
      throw const TrustedHostStoreException(TrustedHostStoreError.unavailable);
    }
  }
}

void validateTrustedHostBindings(List<TrustedHostBinding> bindings) {
  if (bindings.length > maxTrustedHostBindings) {
    throw const TrustedHostStoreException(
      TrustedHostStoreError.tooManyBindings,
    );
  }
  final deviceIds = <String>{};
  for (final binding in bindings) {
    try {
      if (!binding.hasHostIdentity()) {
        throw const FormatException();
      }
      final identity = binding.hostIdentity;
      validateDeviceIdentity(identity);
      if (!_constantTimeEquals(
            identity.deviceId,
            deriveDeviceIdV1(identity.publicKey),
          ) ||
          (identity.platform != DevicePlatform.DEVICE_PLATFORM_MACOS &&
              identity.platform != DevicePlatform.DEVICE_PLATFORM_WINDOWS) ||
          binding.pairedAtUnixMs <= 0 ||
          binding.lastSuccessfulConnectionAtUnixMs < 0 ||
          (binding.lastSuccessfulConnectionAtUnixMs != 0 &&
              binding.lastSuccessfulConnectionAtUnixMs <
                  binding.pairedAtUnixMs)) {
        throw const FormatException();
      }
      validateSignalingEndpoint(Uri.parse(binding.signalingEndpoint));
      if (binding.localAlias.isNotEmpty &&
          normalizeDeviceDisplayName(binding.localAlias) !=
              binding.localAlias) {
        throw const FormatException();
      }
      if (!deviceIds.add(base64UrlEncode(identity.deviceId))) {
        throw const TrustedHostStoreException(
          TrustedHostStoreError.invalidBinding,
        );
      }
    } on TrustedHostStoreException {
      rethrow;
    } catch (_) {
      throw const TrustedHostStoreException(
        TrustedHostStoreError.invalidBinding,
      );
    }
  }
}

Uint8List _encodeEnvelope(List<TrustedHostBinding> bindings) {
  final payload = TrustedHostSnapshot(
    protocolVersion: ProtocolVersion(
      major: protocolMajorVersion,
      minor: minimumProtocolMinorVersion,
    ),
    bindings: bindings,
  ).writeToBuffer();
  if (payload.length > maxTrustedHostSnapshotBytes) {
    throw const TrustedHostStoreException(
      TrustedHostStoreError.tooManyBindings,
    );
  }
  final encoded = Uint8List(trustedHostEnvelopeHeaderBytes + payload.length);
  encoded.setRange(
    0,
    trustedHostEnvelopeMagic.length,
    trustedHostEnvelopeMagic,
  );
  final header = ByteData.sublistView(encoded);
  header.setUint32(
    trustedHostEnvelopeMagic.length,
    _envelopeVersion,
    Endian.big,
  );
  header.setUint32(
    trustedHostEnvelopeMagic.length + 4,
    payload.length,
    Endian.big,
  );
  final digest = sha256.convert(payload).bytes;
  encoded.setRange(
    trustedHostEnvelopeMagic.length + 8,
    trustedHostEnvelopeMagic.length + 8 + _checksumBytes,
    digest,
  );
  encoded.setRange(trustedHostEnvelopeHeaderBytes, encoded.length, payload);
  return encoded;
}

List<TrustedHostBinding> _decodeEnvelope(Uint8List encoded) {
  try {
    if (encoded.length < trustedHostEnvelopeHeaderBytes ||
        encoded.length > maxTrustedHostFileBytes ||
        !_constantTimeEquals(
          encoded.sublist(0, trustedHostEnvelopeMagic.length),
          trustedHostEnvelopeMagic,
        )) {
      throw const FormatException();
    }
    final header = ByteData.sublistView(encoded);
    final version = header.getUint32(
      trustedHostEnvelopeMagic.length,
      Endian.big,
    );
    final payloadLength = header.getUint32(
      trustedHostEnvelopeMagic.length + 4,
      Endian.big,
    );
    if (version != _envelopeVersion ||
        payloadLength > maxTrustedHostSnapshotBytes ||
        trustedHostEnvelopeHeaderBytes + payloadLength != encoded.length) {
      throw const FormatException();
    }
    final expectedDigest = encoded.sublist(
      trustedHostEnvelopeMagic.length + 8,
      trustedHostEnvelopeHeaderBytes,
    );
    final payload = encoded.sublist(trustedHostEnvelopeHeaderBytes);
    if (!_constantTimeEquals(expectedDigest, sha256.convert(payload).bytes)) {
      throw const FormatException();
    }
    final snapshot = TrustedHostSnapshot.fromBuffer(payload);
    if (!snapshot.hasProtocolVersion() ||
        snapshot.protocolVersion.major != protocolMajorVersion ||
        snapshot.protocolVersion.minor != minimumProtocolMinorVersion) {
      throw const FormatException();
    }
    final bindings = snapshot.bindings
        .map((binding) => binding.deepCopy())
        .toList(growable: false);
    validateTrustedHostBindings(bindings);
    return bindings;
  } catch (_) {
    throw const TrustedHostStoreException(TrustedHostStoreError.corruptRecord);
  }
}

bool _constantTimeEquals(List<int> left, List<int> right) {
  if (left.length != right.length) {
    return false;
  }
  var difference = 0;
  for (var index = 0; index < left.length; index += 1) {
    difference |= left[index] ^ right[index];
  }
  return difference == 0;
}
