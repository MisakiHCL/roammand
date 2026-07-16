// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

void main() {
  test('client compiles against generated protocol types', () {
    final version = ProtocolVersion(major: 1, minor: 0);

    expect(version.major, 1);
    expect(version.minor, 0);
  });
}
