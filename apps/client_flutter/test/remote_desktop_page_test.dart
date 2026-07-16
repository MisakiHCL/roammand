// SPDX-License-Identifier: MPL-2.0

import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' as gestures;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/diagnostics/diagnostics_collector.dart';
import 'package:roammand/diagnostics/diagnostics_model.dart';
import 'package:roammand/desktop/remote/input_sender.dart';
import 'package:roammand/desktop/remote/remote_desktop_controller.dart';
import 'package:roammand/desktop/remote/remote_desktop_page.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

void main() {
  test('reverses aspect-fit coordinates and rejects letterbox input', () {
    expect(
      mapRemotePointer(
        localPosition: const Offset(200, 200),
        viewportSize: const Size(400, 400),
        videoAspectRatio: 2,
      ),
      const RemotePointerPosition(5000, 5000),
    );
    expect(
      mapRemotePointer(
        localPosition: const Offset(200, 50),
        viewportSize: const Size(400, 400),
        videoAspectRatio: 2,
      ),
      isNull,
    );
  });

  testWidgets('shows status and maps mouse, scroll and keyboard input', (
    tester,
  ) async {
    final fixture = _PageFixture();
    await tester.pumpWidget(_app(fixture.page()));
    await tester.pump();
    fixture.controller.setState(RemoteDesktopState.connected);
    await tester.pump();

    expect(find.text('Connected'), findsOneWidget);
    final video = find.byKey(const Key('remote-video-interaction'));
    final center = tester.getCenter(video);
    final mouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      pointer: 1,
    );
    await mouse.addPointer(location: center);
    await mouse.moveTo(center + const Offset(8, 4));
    await tester.pump(pointerFrameInterval);
    await mouse.down(center + const Offset(8, 4));
    await mouse.up();
    tester.binding.handlePointerEvent(
      gestures.PointerScrollEvent(
        position: center,
        scrollDelta: const Offset(0, 12),
      ),
    );
    await tester.sendKeyDownEvent(
      LogicalKeyboardKey.keyA,
      physicalKey: PhysicalKeyboardKey.keyA,
    );
    await tester.sendKeyUpEvent(
      LogicalKeyboardKey.keyA,
      physicalKey: PhysicalKeyboardKey.keyA,
    );
    await tester.pump();

    expect(fixture.fast.sent, isNotEmpty);
    final fastEvents = fixture.fast.sent
        .map(decodeAndValidatePointerFastEnvelope)
        .toList();
    expect(fastEvents.any((event) => event.hasMove()), isTrue);
    expect(fastEvents.any((event) => event.hasScroll()), isTrue);
    final reliable = fixture.reliable.sent
        .map(decodeAndValidateReliableInputEnvelope)
        .toList();
    expect(reliable.any((event) => event.hasPointerButton()), isTrue);
    expect(
      reliable
          .where((event) => event.hasKeyboard())
          .map((event) => event.keyboard.usbHidUsage),
      contains(0x04),
    );
  });

  testWidgets('renders Chinese errors and a narrow control surface', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = _PageFixture();
    await tester.pumpWidget(_app(fixture.page(), locale: const Locale('zh')));
    fixture.controller
      ..errorCode = RemoteDesktopErrorCode.authentication
      ..setState(RemoteDesktopState.failed);
    await tester.pump();

    expect(find.text('主机身份验证失败。'), findsOneWidget);
    expect(find.text('关闭连接'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows reconnect progress, gates input, and retries in place', (
    tester,
  ) async {
    final fixture = _PageFixture();
    await tester.pumpWidget(_app(fixture.page()));
    await tester.pump();
    fixture.controller
      ..progress = const RemoteReconnectProgress(
        attempt: 2,
        maximumAttempts: 5,
        elapsed: Duration(seconds: 3),
        recoveryWindow: Duration(seconds: 30),
      )
      ..setState(RemoteDesktopState.reconnecting);
    await tester.pump();

    expect(
      find.text('Reconnecting… attempt 2 of 5. 27 seconds remaining.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsNothing);
    final video = find.byKey(const Key('remote-video-interaction'));
    final mouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      pointer: 2,
    );
    final center = tester.getCenter(video);
    await mouse.addPointer(location: center);
    await mouse.moveTo(center + const Offset(8, 4));
    await mouse.down(center);
    await mouse.up();
    await tester.pump(pointerFrameInterval);
    expect(fixture.fast.sent, isEmpty);
    expect(fixture.reliable.sent, isEmpty);

    fixture.controller
      ..retryAvailable = true
      ..setState(RemoteDesktopState.failed);
    await tester.pump();
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(fixture.controller.retryCount, 1);
    expect(find.byType(RemoteDesktopPage), findsOneWidget);
  });

  testWidgets('opens a privacy-safe diagnostics preview without saving', (
    tester,
  ) async {
    final fixture = _PageFixture();
    await tester.pumpWidget(_app(fixture.page()));
    await tester.pump();

    await tester.tap(find.byKey(const Key('remote-diagnostics-action')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Privacy-safe diagnostics'), findsOneWidget);
    expect(find.text('Included'), findsOneWidget);
    expect(find.text('Excluded'), findsOneWidget);
  });
}

final class _PageFixture {
  _PageFixture()
    : reliable = _CaptureChannel(),
      fast = _CaptureChannel(),
      controller = _FakeRemoteDesktopViewModel() {
    controller.sender = RemoteInputSender(
      sessionId: List<int>.filled(16, 0x71),
      reliable: reliable,
      fast: fast,
    );
  }

  final _CaptureChannel reliable;
  final _CaptureChannel fast;
  final _FakeRemoteDesktopViewModel controller;

  RemoteDesktopPage page() => RemoteDesktopPage(
    target: _target(),
    controller: controller,
    videoAspectRatio: 16 / 9,
    videoBuilder: (context, renderer) =>
        const ColoredBox(color: Colors.black, child: SizedBox.expand()),
  );
}

final class _CaptureChannel implements InputDataChannel {
  final List<Uint8List> sent = <Uint8List>[];

  @override
  int get bufferedAmount => 0;

  @override
  Future<void> send(Uint8List bytes) async {
    sent.add(Uint8List.fromList(bytes));
  }
}

final class _FakeRemoteDesktopViewModel extends ChangeNotifier
    implements RemoteDesktopViewModel {
  @override
  RemoteDesktopState state = RemoteDesktopState.connecting;

  @override
  RemoteDesktopErrorCode? errorCode;

  RemoteReconnectProgress? progress;
  bool retryAvailable = false;

  RemoteInputSender? sender;
  int connectCount = 0;
  int closeCount = 0;
  int retryCount = 0;

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
    closeCount += 1;
    await sender?.close();
    state = RemoteDesktopState.idle;
    notifyListeners();
  }

  @override
  Future<void> retry() async {
    retryCount += 1;
  }

  void setState(RemoteDesktopState value) {
    state = value;
    notifyListeners();
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
    osFamily: DiagnosticsOsFamily.macos,
  ),
  nowUnixMs: () => 1,
).snapshot();
