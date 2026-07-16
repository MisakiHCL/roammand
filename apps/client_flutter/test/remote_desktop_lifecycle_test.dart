// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/desktop/remote/input_sender.dart';
import 'package:roammand/desktop/remote/remote_desktop_controller.dart';
import 'package:roammand/desktop/remote/remote_desktop_page.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

void main() {
  testWidgets('local exit shortcut is not forwarded and closes once', (
    tester,
  ) async {
    final fixture = _LifecycleFixture();
    await tester.pumpWidget(_app(fixture.page));
    fixture.controller.state = RemoteDesktopState.connected;
    fixture.controller.notifyListeners();
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyDownEvent(
      LogicalKeyboardKey.escape,
      physicalKey: PhysicalKeyboardKey.escape,
    );
    await tester.pumpAndSettle();

    expect(fixture.controller.closeCount, 1);
    final usages = fixture.reliable.sent
        .map(decodeAndValidateReliableInputEnvelope)
        .where((event) => event.hasKeyboard())
        .map((event) => event.keyboard.usbHidUsage);
    expect(usages, isNot(contains(0x29)));
  });

  testWidgets('pause and dispose release all input and close idempotently', (
    tester,
  ) async {
    final fixture = _LifecycleFixture();
    await tester.pumpWidget(_app(fixture.page));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(fixture.controller.closeCount, 1);
    final events = fixture.reliable.sent
        .map(decodeAndValidateReliableInputEnvelope)
        .toList();
    expect(events.where((event) => event.hasReleaseAllInput()), hasLength(1));
  });

  testWidgets('focus loss releases input without closing the session', (
    tester,
  ) async {
    final fixture = _LifecycleFixture();
    await tester.pumpWidget(_app(fixture.page));
    fixture.controller.state = RemoteDesktopState.connected;
    fixture.controller.notifyListeners();
    await tester.pump();

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    expect(fixture.controller.closeCount, 0);
    expect(
      fixture.reliable.sent
          .map(decodeAndValidateReliableInputEnvelope)
          .where((event) => event.hasReleaseAllInput()),
      hasLength(1),
    );
  });
}

final class _LifecycleFixture {
  _LifecycleFixture()
    : reliable = _LifecycleChannel(),
      fast = _LifecycleChannel(),
      controller = _LifecycleController() {
    controller.sender = RemoteInputSender(
      sessionId: List<int>.filled(16, 0x71),
      reliable: reliable,
      fast: fast,
    );
  }

  final _LifecycleChannel reliable;
  final _LifecycleChannel fast;
  final _LifecycleController controller;

  late final RemoteDesktopPage page = RemoteDesktopPage(
    target: _target(),
    controller: controller,
    videoAspectRatio: 16 / 9,
    videoBuilder: (context, renderer) => const SizedBox.expand(),
  );
}

final class _LifecycleChannel implements InputDataChannel {
  final List<Uint8List> sent = <Uint8List>[];

  @override
  int get bufferedAmount => 0;

  @override
  Future<void> send(Uint8List bytes) async {
    sent.add(Uint8List.fromList(bytes));
  }
}

final class _LifecycleController extends ChangeNotifier
    implements RemoteDesktopViewModel {
  @override
  RemoteDesktopState state = RemoteDesktopState.connecting;

  @override
  RemoteDesktopErrorCode? errorCode;

  @override
  bool get canRetry => false;

  @override
  DiagnosticsReport get diagnosticsReport => throw UnimplementedError();

  @override
  RemoteReconnectProgress? get reconnectProgress => null;

  RemoteInputSender? sender;
  int closeCount = 0;
  bool _closed = false;

  @override
  RemoteInputSender? get inputSender => sender;

  @override
  Object get videoRenderer => this;

  @override
  Future<void> connect(RemoteDesktopTarget target) async {}

  @override
  Future<void> retry() async {
    throw UnimplementedError();
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    closeCount += 1;
    await sender?.close();
    state = RemoteDesktopState.idle;
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
      displayName: 'Host',
      platform: DevicePlatform.DEVICE_PLATFORM_MACOS,
    ),
    signalingEndpoint: Uri.parse('wss://signal.example.test/v1/ws'),
  );
}

Widget _app(Widget home) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);
