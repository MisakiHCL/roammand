// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/design_system/roammand_surfaces.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand/mobile/identity/device_name_provider.dart';
import 'package:roammand/mobile/identity/mobile_device_identity.dart';
import 'package:roammand/mobile/identity/mobile_identity_onboarding.dart';
import 'package:roammand/mobile/identity/mobile_identity_store.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

void main() {
  testWidgets('requires confirmation before creating the protected identity', (
    tester,
  ) async {
    final storage = _MemoryIdentityStore();
    final store = MobileIdentityStore(
      secureStore: storage,
      platform: DevicePlatform.DEVICE_PLATFORM_ANDROID,
      randomBytes: (_) => List<int>.generate(mobileIdentitySeedBytes, (i) => i),
    );
    MobileDeviceIdentity? confirmed;

    await tester.pumpWidget(
      _app(
        MobileIdentityOnboarding(
          store: store,
          nameProvider: DeviceNameProvider(source: _NameSource('Pixel 9')),
          onReady: (identity) => confirmed = identity,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pixel 9'), findsOneWidget);
    expect(storage.writes, 0);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(confirmed?.publicIdentity.displayName, 'Pixel 9');
    expect(storage.writes, 1);
  });

  testWidgets('fits the first-run form in a compact landscape viewport', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(844, 390);
    tester.view.padding = const FakeViewPadding(left: 44, right: 24);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetPadding);

    await tester.pumpWidget(
      _app(
        MobileIdentityOnboarding(
          store: MobileIdentityStore(
            secureStore: _MemoryIdentityStore(),
            platform: DevicePlatform.DEVICE_PLATFORM_IOS,
            randomBytes: (_) => List<int>.filled(mobileIdentitySeedBytes, 7),
          ),
          nameProvider: DeviceNameProvider(source: _NameSource('iPhone')),
          onReady: (_) {},
        ),
        locale: const Locale('zh'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('mobile-identity-landscape-layout')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    final backdropRect = tester.getRect(find.byType(RoammandBackdrop));
    final cardRect = tester.getRect(
      find.byKey(const Key('mobile-identity-card')),
    );
    expect(backdropRect, const Rect.fromLTWH(0, 0, 844, 390));
    expect(cardRect.center.dy, closeTo(backdropRect.center.dy, 1));
    expect(cardRect.bottom, lessThanOrEqualTo(390));
  });
}

Widget _app(Widget home, {Locale? locale}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

final class _NameSource implements DeviceNameSource {
  _NameSource(this.name);
  final String name;
  @override
  Future<String?> readName() async => name;
}

final class _MemoryIdentityStore implements MobileIdentitySecureStore {
  String? value;
  int writes = 0;
  @override
  Future<String?> read(String key) async => value;
  @override
  Future<void> write(String key, String value) async {
    writes += 1;
    this.value = value;
  }
}
