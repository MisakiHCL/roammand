// SPDX-License-Identifier: MPL-2.0

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/desktop/host_agent/local_ipc_framer.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

void main() {
  test('decodes every chunk boundary and multiple frames identically', () {
    final expected = <Uint8List>[
      Uint8List.fromList('first'.codeUnits),
      Uint8List(257)..fillRange(0, 257, 0x22),
      Uint8List.fromList('third'.codeUnits),
    ];
    final encoded = Uint8List.fromList(
      expected.expand(LocalIpcFramer.encodePayload).toList(growable: false),
    );

    for (var chunkSize = 1; chunkSize <= encoded.length; chunkSize += 1) {
      final framer = LocalIpcFramer();
      final decoded = <Uint8List>[];
      for (var offset = 0; offset < encoded.length; offset += chunkSize) {
        final end = (offset + chunkSize).clamp(0, encoded.length);
        decoded.addAll(framer.add(encoded.sublist(offset, end)));
        expect(framer.bufferedBytes, lessThanOrEqualTo(maxLocalIpcFrameBytes));
      }
      framer.close();
      expect(decoded, hasLength(expected.length));
      for (var index = 0; index < expected.length; index += 1) {
        expect(decoded[index], orderedEquals(expected[index]));
      }
    }
  });

  test('rejects zero, oversized, truncated, and post-close input', () {
    expect(
      () => LocalIpcFramer().add(Uint8List.fromList(<int>[0, 0, 0, 0])),
      throwsFormatException,
    );
    final oversized = maxLocalIpcFrameBytes + 1;
    expect(
      () => LocalIpcFramer().add(
        Uint8List.fromList(<int>[
          (oversized >> 24) & 0xff,
          (oversized >> 16) & 0xff,
          (oversized >> 8) & 0xff,
          oversized & 0xff,
        ]),
      ),
      throwsFormatException,
    );
    expect(() => LocalIpcFramer().add(Uint8List(0)), returnsNormally);

    final truncatedHeader = LocalIpcFramer()
      ..add(Uint8List.fromList(<int>[0, 0, 0]));
    expect(truncatedHeader.close, throwsFormatException);
    final truncatedPayload = LocalIpcFramer()
      ..add(Uint8List.fromList(<int>[0, 0, 0, 4, 1, 2]));
    expect(truncatedPayload.close, throwsFormatException);

    final closed = LocalIpcFramer()..close();
    expect(() => closed.add(Uint8List.fromList(<int>[1])), throwsStateError);
    expect(
      () => LocalIpcFramer.encodePayload(Uint8List(0)),
      throwsArgumentError,
    );
    expect(
      () => LocalIpcFramer.encodePayload(Uint8List(maxLocalIpcFrameBytes + 1)),
      throwsArgumentError,
    );
  });
}
