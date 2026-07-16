// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/mobile/identity/device_name_provider.dart';

void main() {
  test('uses and trims a best-effort system device name', () async {
    final provider = DeviceNameProvider(
      source: FakeDeviceNameSource('  Alice’s iPhone  '),
    );

    expect(
      await provider.suggest(localizedFallback: 'This phone'),
      'Alice’s iPhone',
    );
  });

  test(
    'uses the localized fallback for missing, invalid, or failed names',
    () async {
      for (final source in <DeviceNameSource>[
        FakeDeviceNameSource(null),
        FakeDeviceNameSource(' '),
        FakeDeviceNameSource(List<String>.filled(129, 'x').join()),
        FakeDeviceNameSource(null, fail: true),
      ]) {
        final provider = DeviceNameProvider(source: source);
        expect(
          await provider.suggest(localizedFallback: 'This phone'),
          'This phone',
        );
      }
    },
  );

  test('rejects an invalid localized fallback', () async {
    final provider = DeviceNameProvider(source: FakeDeviceNameSource(null));

    await expectLater(
      provider.suggest(localizedFallback: ' '),
      throwsArgumentError,
    );
  });
}

final class FakeDeviceNameSource implements DeviceNameSource {
  FakeDeviceNameSource(this.name, {this.fail = false});

  final String? name;
  final bool fail;

  @override
  Future<String?> readName() async {
    if (fail) {
      throw StateError('unavailable');
    }
    return name;
  }
}
