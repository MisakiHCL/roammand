// SPDX-License-Identifier: MPL-2.0

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roammand/design_system/roammand_theme.dart';
import 'package:roammand/desktop/desktop_app_root.dart';
import 'package:roammand/l10n/app_locale_controller.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand/mobile/mobile_app_root.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isIOS) {
    await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
  if (Platform.isMacOS || Platform.isWindows) {
    await prepareDesktopWindow();
  }
  final localeController = await AppLocaleController.load();
  runApp(RoammandApp(localeController: localeController));
}

class RoammandApp extends StatefulWidget {
  const RoammandApp({
    super.key,
    this.desktopHostEnabled,
    this.mobileHome,
    this.localeController,
  });

  final bool? desktopHostEnabled;
  final Widget? mobileHome;
  final AppLocaleController? localeController;

  @override
  State<RoammandApp> createState() => _RoammandAppState();
}

final class _RoammandAppState extends State<RoammandApp> {
  late final AppLocaleController _localeController;
  late final bool _ownsLocaleController;

  @override
  void initState() {
    super.initState();
    _ownsLocaleController = widget.localeController == null;
    _localeController = widget.localeController ?? AppLocaleController();
    _localeController.addListener(_onLocaleChanged);
  }

  void _onLocaleChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final macosTypography = defaultTargetPlatform == TargetPlatform.macOS;
    final theme = RoammandTheme.dark(compactTypography: macosTypography);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: _localeController.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
      home: _home(),
    );
  }

  Widget _home() {
    if (widget.desktopHostEnabled ?? (Platform.isMacOS || Platform.isWindows)) {
      return DesktopAppRoot(
        localePreference: _localeController.preference,
        onLocalePreferenceChanged: _localeController.setPreference,
      );
    }
    if (widget.mobileHome case final home?) return home;
    if (Platform.isIOS) {
      return MobileAppRoot(
        platform: DevicePlatform.DEVICE_PLATFORM_IOS,
        localePreference: _localeController.preference,
        onLocalePreferenceChanged: _localeController.setPreference,
      );
    }
    if (Platform.isAndroid) {
      return MobileAppRoot(
        platform: DevicePlatform.DEVICE_PLATFORM_ANDROID,
        localePreference: _localeController.preference,
        onLocalePreferenceChanged: _localeController.setPreference,
      );
    }
    return const DevelopmentStatusPage();
  }

  @override
  void dispose() {
    _localeController.removeListener(_onLocaleChanged);
    if (_ownsLocaleController) {
      _localeController.dispose();
    }
    super.dispose();
  }
}

class DevelopmentStatusPage extends StatelessWidget {
  const DevelopmentStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.appTitle)),
      body: Center(child: Text(strings.developmentStatus)),
    );
  }
}
