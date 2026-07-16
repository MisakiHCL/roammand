// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

const appLocalePreferenceStorageKey = 'app_locale_preference_v1';

enum AppLocalePreference {
  system(storageValue: 'system', locale: null),
  english(storageValue: 'en', locale: Locale('en')),
  simplifiedChinese(storageValue: 'zh-Hans', locale: Locale('zh'));

  const AppLocalePreference({required this.storageValue, required this.locale});

  final String storageValue;
  final Locale? locale;

  static AppLocalePreference fromStorageValue(String? value) {
    for (final preference in values) {
      if (preference.storageValue == value) {
        return preference;
      }
    }
    return system;
  }
}

abstract interface class AppLocalePreferenceStore {
  Future<AppLocalePreference> load();

  Future<void> save(AppLocalePreference preference);
}

final class SharedPreferencesAppLocaleStore
    implements AppLocalePreferenceStore {
  SharedPreferencesAppLocaleStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<AppLocalePreference> load() async =>
      AppLocalePreference.fromStorageValue(
        await _preferences.getString(appLocalePreferenceStorageKey),
      );

  @override
  Future<void> save(AppLocalePreference preference) => _preferences.setString(
    appLocalePreferenceStorageKey,
    preference.storageValue,
  );
}

final class AppLocaleController extends ChangeNotifier {
  AppLocaleController({
    AppLocalePreferenceStore? store,
    AppLocalePreference initialPreference = AppLocalePreference.system,
  }) : _store = store ?? const _TransientAppLocaleStore(),
       _preference = initialPreference;

  final AppLocalePreferenceStore _store;
  AppLocalePreference _preference;
  Future<void> _pendingSave = Future<void>.value();

  AppLocalePreference get preference => _preference;

  Locale? get locale => _preference.locale;

  static Future<AppLocaleController> load({
    AppLocalePreferenceStore? store,
  }) async {
    final resolvedStore = store ?? SharedPreferencesAppLocaleStore();
    var initialPreference = AppLocalePreference.system;
    try {
      initialPreference = await resolvedStore.load();
    } catch (_) {
      // Language preference is non-critical; fall back to the system locale.
    }
    return AppLocaleController(
      store: resolvedStore,
      initialPreference: initialPreference,
    );
  }

  Future<void> setPreference(AppLocalePreference preference) {
    if (_preference == preference) {
      return _pendingSave;
    }
    _preference = preference;
    notifyListeners();
    _pendingSave = _pendingSave.then((_) async {
      try {
        await _store.save(preference);
      } catch (_) {
        // Keep the in-memory choice for this session if persistence is down.
      }
    });
    return _pendingSave;
  }
}

final class _TransientAppLocaleStore implements AppLocalePreferenceStore {
  const _TransientAppLocaleStore();

  @override
  Future<AppLocalePreference> load() async => AppLocalePreference.system;

  @override
  Future<void> save(AppLocalePreference preference) async {}
}
