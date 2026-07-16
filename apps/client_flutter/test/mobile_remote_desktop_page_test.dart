// SPDX-License-Identifier: MPL-2.0

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/design_system/roammand_colors.dart';
import 'package:roammand/diagnostics/diagnostics_collector.dart';
import 'package:roammand/diagnostics/diagnostics_model.dart';
import 'package:roammand/desktop/remote/input_sender.dart';
import 'package:roammand/desktop/remote/remote_desktop_controller.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand/mobile/remote/mobile_remote_desktop_page.dart';
import 'package:roammand/mobile/widgets/mobile_page_header.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

void main() {
  testWidgets('locks the remote page to landscape and restores app rotation', (
    tester,
  ) async {
    final orientationArguments = <List<Object?>>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemChrome.setPreferredOrientations') {
          orientationArguments.add(List<Object?>.from(call.arguments as List));
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final fixture = _PageFixture();

    await tester.pumpWidget(_app(fixture.page()));
    await tester.pump();
    expect(orientationArguments.first, <String>[
      'DeviceOrientation.landscapeLeft',
      'DeviceOrientation.landscapeRight',
    ]);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(orientationArguments.last, isEmpty);
  });

  testWidgets('keeps the iOS app landscape after leaving a remote session', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final orientationArguments = <List<Object?>>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemChrome.setPreferredOrientations') {
          orientationArguments.add(List<Object?>.from(call.arguments as List));
        }
        return null;
      },
    );
    try {
      await tester.pumpWidget(_app(_PageFixture().page()));
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(orientationArguments, hasLength(2));
      expect(orientationArguments.last, <String>[
        'DeviceOrientation.landscapeLeft',
        'DeviceOrientation.landscapeRight',
      ]);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    }
  });

  testWidgets('connects once and maps a delayed tap after rotation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = _PageFixture();
    await tester.pumpWidget(_app(fixture.page()));
    await tester.pump();

    expect(fixture.controller.connectCount, 1);
    expect(find.byType(SafeArea), findsNothing);
    expect(find.text('Connected'), findsOneWidget);

    await tester.binding.setSurfaceSize(const Size(720, 360));
    await tester.pump();
    final surface = find.byKey(const Key('mobile-remote-gesture-surface'));
    await tester.tapAt(tester.getCenter(surface));
    await tester.pump(const Duration(milliseconds: 301));

    final clicks = fixture.reliable.decoded
        .where((event) => event.hasPointerButton())
        .toList(growable: false);
    expect(clicks, hasLength(1));
    expect(
      clicks.single.pointerButton.action,
      ButtonAction.BUTTON_ACTION_CLICK,
    );
    expect(clicks.single.pointerButton.x, 5000);
    expect(clicks.single.pointerButton.y, 5000);
  });

  testWidgets('keeps status above the video with one session exit action', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_PageFixture().page()));
    await tester.pump();

    final status = find.byKey(const Key('mobile-remote-status'));
    final surface = find.byKey(const Key('mobile-remote-gesture-surface'));
    expect(status, findsOneWidget);
    expect(surface, findsOneWidget);
    expect(find.ancestor(of: status, matching: surface), findsNothing);
    expect(find.byKey(const Key('mobile-remote-back-action')), findsOneWidget);
    expect(find.byType(MobilePageBackButton), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('fills horizontal safe areas with one continuous page surface', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    tester.view.padding = const FakeViewPadding(
      left: 132,
      right: 72,
      bottom: 60,
    );
    addTearDown(() {
      tester.view.padding = FakeViewPadding.zero;
      return tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(_app(_PageFixture().page()));
    await tester.pump();

    final header = find.byKey(const Key('mobile-remote-header'));
    final surface = find.byKey(const Key('mobile-remote-gesture-surface'));
    final controlBar = find.byKey(const Key('mobile-remote-control-bar'));
    expect(tester.getRect(header).left, 0);
    expect(tester.getRect(header).right, 844);
    expect(tester.getRect(surface).left, 0);
    expect(tester.getRect(surface).right, 844);
    expect(tester.getRect(controlBar).left, 0);
    expect(tester.getRect(controlBar).right, 844);
    expect(tester.getRect(controlBar).bottom, 390);
    expect(tester.getSize(controlBar).height, 40);
    expect(
      tester.getRect(find.byKey(const Key('mobile-remote-back-action'))).left,
      greaterThanOrEqualTo(44),
    );
    expect(
      tester
          .getRect(find.byKey(const Key('mobile-remote-diagnostics-action')))
          .right,
      lessThanOrEqualTo(820),
    );
    expect(tester.widget<Material>(header).color, RoammandColors.canvas);
    expect(tester.widget<Material>(controlBar).color, RoammandColors.canvas);
    expect(tester.takeException(), isNull);
  });

  testWidgets('avoids overflow when the iOS keyboard reduces landscape space', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() {
      tester.view.viewInsets = FakeViewPadding.zero;
      return tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(_app(_PageFixture().page()));
    await tester.pump();

    await tester.tap(find.byKey(const Key('mobile-keyboard-toggle')));
    await tester.pump();
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.pump();

    expect(find.byKey(const Key('mobile-text-input')), findsOneWidget);
    expect(find.byKey(const Key('mobile-remote-header')), findsOneWidget);
    expect(
      find.byKey(const Key('mobile-remote-gesture-surface')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('mobile-remote-control-bar')), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('mobile-input-tray'))).height,
      56,
    );
    expect(find.byKey(const Key('mobile-modifier-control')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'keeps the text field focused while the software keyboard opens',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(844, 390));
      addTearDown(() {
        tester.view.viewInsets = FakeViewPadding.zero;
        return tester.binding.setSurfaceSize(null);
      });
      final fixture = _PageFixture();
      await tester.pumpWidget(_app(fixture.page()));
      await tester.pump();

      await tester.tap(find.byKey(const Key('mobile-keyboard-toggle')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('mobile-text-input')));
      await tester.pump();
      final editableBefore = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );

      tester.view.viewInsets = const FakeViewPadding(bottom: 720);
      await tester.pump();

      final editableAfter = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      expect(identical(editableAfter, editableBefore), isTrue);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      expect(
        tester.getSize(find.byKey(const Key('mobile-input-tray'))).height,
        56,
      );
      expect(find.byKey(const Key('mobile-remote-header')), findsOneWidget);
      expect(
        find.byKey(const Key('mobile-remote-gesture-surface')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('mobile-modifier-control')), findsNothing);

      await tester.enterText(
        find.byKey(const Key('mobile-text-input')),
        'still focused',
      );
      await tester.tap(find.byKey(const Key('mobile-text-send')));
      await tester.pump();
      expect(
        fixture.reliable.decoded
            .where((event) => event.hasText())
            .single
            .text
            .text,
        'still focused',
      );

      final dismissOverlay = find.byKey(
        const Key('mobile-dismiss-keyboard-overlay'),
      );
      expect(dismissOverlay, findsOneWidget);
      await tester.tap(dismissOverlay);
      await tester.pump(const Duration(milliseconds: 301));
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isFalse,
      );
      expect(
        fixture.reliable.decoded.where((event) => event.hasPointerButton()),
        isEmpty,
      );

      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pump();
      expect(dismissOverlay, findsNothing);
      expect(
        find.byKey(const Key('mobile-remote-control-bar')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('mobile-modifier-control')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('sends text, modifiers and special keys from the mobile tray', (
    tester,
  ) async {
    final fixture = _PageFixture();
    await tester.pumpWidget(_app(fixture.page()));
    await tester.pump();

    await tester.tap(find.byKey(const Key('mobile-keyboard-toggle')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('mobile-text-input')),
      'hello 世界',
    );
    await tester.tap(find.byKey(const Key('mobile-text-send')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('mobile-modifier-control')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('mobile-special-tab')));
    await tester.pump();

    final events = fixture.reliable.decoded;
    expect(
      events.where((event) => event.hasText()).single.text.text,
      'hello 世界',
    );
    final keyboard = events
        .where((event) => event.hasKeyboard())
        .map((event) => event.keyboard)
        .toList(growable: false);
    expect(keyboard.first.usbHidUsage, 0xe0);
    expect(keyboard.first.modifierBits, 0x01);
    expect(keyboard.where((event) => event.usbHidUsage == 0x2b), hasLength(2));
    expect(keyboard.last.modifierBits, 0x01);
  });

  testWidgets('background releases input and pause closes without reconnect', (
    tester,
  ) async {
    final fixture = _PageFixture();
    await tester.pumpWidget(_app(fixture.page()));
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(
      fixture.reliable.decoded.where((event) => event.hasReleaseAllInput()),
      hasLength(1),
    );
    expect(fixture.controller.closeCount, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(fixture.controller.closeCount, 1);
    expect(fixture.controller.connectCount, 1);
  });

  testWidgets('renders localized failure and remains usable when narrow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = _PageFixture(
      state: RemoteDesktopState.failed,
      errorCode: RemoteDesktopErrorCode.authentication,
    );
    await tester.pumpWidget(_app(fixture.page(), locale: const Locale('zh')));
    await tester.pump();

    expect(find.text('主机身份验证失败。'), findsOneWidget);
    expect(find.byKey(const Key('mobile-keyboard-toggle')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('localizes reconnect progress and offers retry after failure', (
    tester,
  ) async {
    final fixture = _PageFixture(state: RemoteDesktopState.reconnecting);
    fixture.controller.progress = const RemoteReconnectProgress(
      attempt: 3,
      maximumAttempts: 5,
      elapsed: Duration(seconds: 7),
      recoveryWindow: Duration(seconds: 30),
    );
    await tester.pumpWidget(_app(fixture.page(), locale: const Locale('zh')));
    await tester.pump();

    expect(find.text('正在重连…第 3/5 次尝试，剩余 23 秒。'), findsOneWidget);
    expect(find.text('重试'), findsNothing);
    expect(fixture.controller.inputSender, isNotNull);

    fixture.controller
      ..retryAvailable = true
      ..state = RemoteDesktopState.failed
      ..notifyListeners();
    await tester.pump();
    await tester.tap(find.text('重试'));
    await tester.pump();
    expect(fixture.controller.retryCount, 1);
    expect(find.byType(MobileRemoteDesktopPage), findsOneWidget);
  });

  testWidgets('system back waits for session close before popping', (
    tester,
  ) async {
    final fixture = _PageFixture();
    final closeGate = Completer<void>();
    fixture.controller.closeGate = closeGate;
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: Text('home')),
      ),
    );
    unawaited(
      navigatorKey.currentState!.push<void>(
        MaterialPageRoute<void>(builder: (_) => fixture.page()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MobileRemoteDesktopPage), findsOneWidget);

    await navigatorKey.currentState!.maybePop();
    await tester.pumpAndSettle();
    expect(fixture.controller.closeCount, 1);
    expect(find.byType(MobileRemoteDesktopPage), findsOneWidget);

    closeGate.complete();
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
    expect(fixture.controller.closeCount, 1);
  });

  testWidgets('opens the localized diagnostics preview', (tester) async {
    final fixture = _PageFixture();
    await tester.pumpWidget(_app(fixture.page(), locale: const Locale('zh')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('mobile-remote-diagnostics-action')));
    await tester.pumpAndSettle();

    expect(find.text('隐私安全诊断'), findsOneWidget);
    expect(find.text('包含'), findsOneWidget);
    expect(find.text('排除'), findsOneWidget);
  });
}

final class _PageFixture {
  _PageFixture({
    RemoteDesktopState state = RemoteDesktopState.connected,
    RemoteDesktopErrorCode? errorCode,
  }) : reliable = _CaptureChannel(),
       fast = _CaptureChannel(),
       controller = _FakeMobileViewModel(state, errorCode) {
    controller.sender = RemoteInputSender(
      sessionId: List<int>.filled(16, 0x51),
      reliable: reliable,
      fast: fast,
    );
  }

  final _CaptureChannel reliable;
  final _CaptureChannel fast;
  final _FakeMobileViewModel controller;

  MobileRemoteDesktopPage page() => MobileRemoteDesktopPage(
    target: _target(),
    controller: controller,
    videoAspectRatio: 16 / 9,
    videoBuilder: (context, renderer) =>
        const ColoredBox(color: Colors.blue, child: SizedBox.expand()),
  );
}

final class _CaptureChannel implements InputDataChannel {
  final List<Uint8List> sent = <Uint8List>[];

  @override
  int get bufferedAmount => 0;

  List<ReliableInputEnvelope> get decoded =>
      sent.map(decodeAndValidateReliableInputEnvelope).toList(growable: false);

  @override
  Future<void> send(Uint8List bytes) async {
    sent.add(Uint8List.fromList(bytes));
  }
}

final class _FakeMobileViewModel extends ChangeNotifier
    implements RemoteDesktopViewModel {
  _FakeMobileViewModel(this.state, this.errorCode);

  @override
  RemoteDesktopState state;

  @override
  RemoteDesktopErrorCode? errorCode;

  RemoteReconnectProgress? progress;
  bool retryAvailable = false;

  RemoteInputSender? sender;
  int connectCount = 0;
  int closeCount = 0;
  int retryCount = 0;
  bool _closed = false;
  Completer<void>? closeGate;

  @override
  bool get canRetry => retryAvailable;

  @override
  DiagnosticsReport get diagnosticsReport => _diagnosticsReport();

  @override
  RemoteInputSender? get inputSender => sender;

  @override
  RemoteReconnectProgress? get reconnectProgress => progress;

  @override
  Object get videoRenderer => this;

  @override
  Future<void> connect(RemoteDesktopTarget target) async {
    connectCount += 1;
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    closeCount += 1;
    await closeGate?.future;
    await sender?.close();
    state = RemoteDesktopState.idle;
    notifyListeners();
  }

  @override
  Future<void> retry() async {
    retryCount += 1;
  }
}

RemoteDesktopTarget _target() {
  final publicKey = List<int>.generate(32, (index) => index + 1);
  return RemoteDesktopTarget(
    hostIdentity: DeviceIdentity(
      deviceId: deriveDeviceIdV1(publicKey),
      publicKeyAlgorithm: PublicKeyAlgorithm.PUBLIC_KEY_ALGORITHM_ED25519,
      publicKey: publicKey,
      displayName: 'Office Mac',
      platform: DevicePlatform.DEVICE_PLATFORM_MACOS,
    ),
    signalingEndpoint: Uri.parse('wss://signal.example.test/v1/ws'),
  );
}

Widget _app(Widget home, {Locale? locale}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

DiagnosticsReport _diagnosticsReport() => DiagnosticsCollector(
  metadata: const DiagnosticsMetadata(
    appVersion: 'test',
    protocolMajor: 1,
    protocolMinor: 0,
    osFamily: DiagnosticsOsFamily.android,
  ),
  nowUnixMs: () => 1,
).snapshot();
