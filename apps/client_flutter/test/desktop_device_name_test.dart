// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/desktop/host_agent/desktop_device_name.dart';
import 'package:roammand/identity/device_display_name.dart';

void main() {
  test('uses a trimmed desktop computer name', () async {
    final provider = DesktopDeviceNameProvider(
      source: _DesktopNameSource('  Office Mac  '),
    );

    expect(await provider.read(), 'Office Mac');
  });

  test('ignores unavailable or invalid desktop names', () async {
    for (final source in <DesktopDeviceNameSource>[
      _DesktopNameSource(null),
      _DesktopNameSource(' '),
      _DesktopNameSource('Office\nMac'),
      _DesktopNameSource(null, fails: true),
    ]) {
      expect(await DesktopDeviceNameProvider(source: source).read(), isNull);
    }
  });

  test('invalid name errors do not echo the entered device name', () {
    const rejectedName = 'Private\nComputer';

    expect(
      () => requireDeviceDisplayName(rejectedName),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.toString(),
          'message',
          isNot(contains(rejectedName)),
        ),
      ),
    );
  });
}

final class _DesktopNameSource implements DesktopDeviceNameSource {
  _DesktopNameSource(this.name, {this.fails = false});

  final String? name;
  final bool fails;

  @override
  Future<String?> readName() async {
    if (fails) throw StateError('unavailable');
    return name;
  }
}
