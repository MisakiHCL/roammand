// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/pairing/desktop_pairing_code.dart';

void main() {
  test('desktop pairing code normalizes raw and fixed 4-4 input', () {
    expect(normalizeDesktopPairingCode('abcd-efg2'), 'ABCDEFG2');
    expect(normalizeDesktopPairingCode('ABCDEFG2'), 'ABCDEFG2');
    expect(formatDesktopPairingCode('ABCDEFG2'), 'ABCD-EFG2');
  });

  test('desktop pairing code rejects ambiguous or non-canonical input', () {
    for (final value in <String>[
      '',
      'ABC',
      'ABCD-EFG',
      'ABCD-EFGH-IJKL',
      'ABC-DEFG2',
      'ABCD_EFG2',
      'ABCD EFG2',
      'ABCD-0FG2',
      'ABCD-1FG2',
      'ABCD-8FG2',
      'ABCD-9FG2',
      'ＡＢＣＤ-EFG2',
    ]) {
      expect(
        () => normalizeDesktopPairingCode(value),
        throwsA(isA<DesktopPairingCodeException>()),
        reason: value,
      );
    }
  });
}
