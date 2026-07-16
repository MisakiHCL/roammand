// SPDX-License-Identifier: MPL-2.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:roammand/l10n/app_locale_controller.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';

final class AppLanguageMenu extends StatelessWidget {
  const AppLanguageMenu({
    required this.preference,
    required this.onPreferenceChanged,
    this.iconSize = 20,
    super.key,
  });

  final AppLocalePreference preference;
  final Future<void> Function(AppLocalePreference preference)
  onPreferenceChanged;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return PopupMenuButton<AppLocalePreference>(
      tooltip: strings.languageMenuTooltip,
      icon: Icon(Icons.language, size: iconSize),
      onSelected: (selected) => unawaited(onPreferenceChanged(selected)),
      itemBuilder: (context) => <PopupMenuEntry<AppLocalePreference>>[
        _item(AppLocalePreference.system, strings.languageSystemOption),
        _item(AppLocalePreference.english, strings.languageEnglishOption),
        _item(
          AppLocalePreference.simplifiedChinese,
          strings.languageSimplifiedChineseOption,
        ),
      ],
    );
  }

  PopupMenuItem<AppLocalePreference> _item(
    AppLocalePreference value,
    String label,
  ) => PopupMenuItem<AppLocalePreference>(
    value: value,
    child: Row(
      children: <Widget>[
        SizedBox(
          width: 20,
          child: value == preference ? const Icon(Icons.check, size: 16) : null,
        ),
        const SizedBox(width: 12),
        Text(label),
      ],
    ),
  );
}
