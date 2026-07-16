// SPDX-License-Identifier: MPL-2.0

import 'dart:typed_data';

import 'package:roammand_protocol/roammand_protocol.dart';

const _lengthPrefixBytes = 4;

final class LocalIpcFramer {
  final Uint8List _header = Uint8List(_lengthPrefixBytes);
  int _headerLength = 0;
  Uint8List? _payload;
  int _payloadLength = 0;
  bool _closed = false;
  bool _failed = false;

  int get bufferedBytes => _headerLength + _payloadLength;

  List<Uint8List> add(Uint8List chunk) {
    if (_closed || _failed) {
      throw StateError('local IPC framer is not accepting input');
    }
    try {
      return _addValid(chunk);
    } on FormatException {
      _failed = true;
      rethrow;
    }
  }

  void close() {
    if (_closed) {
      return;
    }
    _closed = true;
    if (_failed || _headerLength != 0 || _payload != null) {
      throw const FormatException(
        'local IPC stream ended with a partial frame',
      );
    }
  }

  static Uint8List encodePayload(List<int> payload) {
    _validatePayloadLength(payload.length, argument: true);
    final encoded = Uint8List(_lengthPrefixBytes + payload.length);
    final data = ByteData.sublistView(encoded);
    data.setUint32(0, payload.length, Endian.big);
    encoded.setRange(_lengthPrefixBytes, encoded.length, payload);
    return encoded;
  }

  List<Uint8List> _addValid(Uint8List chunk) {
    final frames = <Uint8List>[];
    var offset = 0;
    while (offset < chunk.length) {
      final payload = _payload;
      if (payload != null) {
        final copied = (payload.length - _payloadLength).clamp(
          0,
          chunk.length - offset,
        );
        payload.setRange(
          _payloadLength,
          _payloadLength + copied,
          chunk,
          offset,
        );
        _payloadLength += copied;
        offset += copied;
        if (_payloadLength == payload.length) {
          frames.add(payload);
          _payload = null;
          _payloadLength = 0;
        }
        continue;
      }

      final copied = (_lengthPrefixBytes - _headerLength).clamp(
        0,
        chunk.length - offset,
      );
      _header.setRange(_headerLength, _headerLength + copied, chunk, offset);
      _headerLength += copied;
      offset += copied;
      if (_headerLength == _lengthPrefixBytes) {
        final length = ByteData.sublistView(_header).getUint32(0, Endian.big);
        _validatePayloadLength(length, argument: false);
        _headerLength = 0;
        _payload = Uint8List(length);
      }
    }
    return frames;
  }

  static void _validatePayloadLength(int length, {required bool argument}) {
    if (length > 0 && length <= maxLocalIpcFrameBytes) {
      return;
    }
    if (argument) {
      throw ArgumentError.value(length, 'payload.length', 'out of range');
    }
    throw const FormatException('local IPC frame length is out of range');
  }
}
