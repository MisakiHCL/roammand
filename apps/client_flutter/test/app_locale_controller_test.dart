// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/l10n/app_locale_controller.dart';

void main() {
  test('maps persisted values and falls back to the system locale', () {
    expect(
      AppLocalePreference.fromStorageValue('en'),
      AppLocalePreference.english,
    );
    expect(
      AppLocalePreference.fromStorageValue('zh-Hans'),
      AppLocalePreference.simplifiedChinese,
    );
    expect(
      AppLocalePreference.fromStorageValue('unsupported'),
      AppLocalePreference.system,
    );
    expect(
      AppLocalePreference.fromStorageValue(null),
      AppLocalePreference.system,
    );
  });

  test('loads and serializes language preference changes', () async {
    final store = _MemoryLocaleStore(
      loadedPreference: AppLocalePreference.simplifiedChinese,
    );
    final controller = await AppLocaleController.load(store: store);
    addTearDown(controller.dispose);

    expect(controller.preference, AppLocalePreference.simplifiedChinese);
    expect(controller.locale?.languageCode, 'zh');

    await controller.setPreference(AppLocalePreference.english);
    await controller.setPreference(AppLocalePreference.system);

    expect(store.savedPreferences, <AppLocalePreference>[
      AppLocalePreference.english,
      AppLocalePreference.system,
    ]);
    expect(controller.locale, isNull);

    final reloaded = await AppLocaleController.load(store: store);
    addTearDown(reloaded.dispose);
    expect(reloaded.preference, AppLocalePreference.system);
  });

  test('uses the system locale when preference loading fails', () async {
    final store = _MemoryLocaleStore(
      loadedPreference: AppLocalePreference.english,
      failLoad: true,
    );
    final controller = await AppLocaleController.load(store: store);
    addTearDown(controller.dispose);

    expect(controller.preference, AppLocalePreference.system);
    expect(controller.locale, isNull);
  });
}

final class _MemoryLocaleStore implements AppLocalePreferenceStore {
  _MemoryLocaleStore({required this.loadedPreference, this.failLoad = false});

  AppLocalePreference loadedPreference;
  final bool failLoad;
  final List<AppLocalePreference> savedPreferences = <AppLocalePreference>[];

  @override
  Future<AppLocalePreference> load() async {
    if (failLoad) {
      throw StateError('load failed');
    }
    return loadedPreference;
  }

  @override
  Future<void> save(AppLocalePreference preference) async {
    loadedPreference = preference;
    savedPreferences.add(preference);
  }
}
