// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/desktop/remote/input_sender.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

final _sessionId = Uint8List.fromList(List<int>.filled(16, 0x71));

void main() {
  test(
    'maps reliable input to exact protobuf with increasing sequence',
    () async {
      final reliable = _FakeInputChannel();
      final fast = _FakeInputChannel();
      final sender = RemoteInputSender(
        sessionId: _sessionId,
        reliable: reliable,
        fast: fast,
        frameScheduler: _ManualFrameScheduler(),
      );

      await sender.sendPointerButton(
        button: PointerButton.POINTER_BUTTON_LEFT,
        action: ButtonAction.BUTTON_ACTION_DOWN,
        x: 7500,
        y: 2500,
      );
      await sender.sendKeyboard(
        action: KeyboardAction.KEYBOARD_ACTION_DOWN,
        usbHidUsage: 0x04,
        modifierBits: 0x02,
      );
      await sender.sendScroll(deltaX: -4, deltaY: 12);

      final button = decodeAndValidateReliableInputEnvelope(reliable.sent[0]);
      expect(button.sequence.toInt(), 1);
      expect(button.pointerButton.button, PointerButton.POINTER_BUTTON_LEFT);
      expect(button.pointerButton.x, 7500);
      expect(button.pointerButton.y, 2500);
      final keyboard = decodeAndValidateReliableInputEnvelope(reliable.sent[1]);
      expect(keyboard.sequence.toInt(), 2);
      expect(keyboard.keyboard.usbHidUsage, 0x04);
      expect(keyboard.keyboard.modifierBits, 0x02);
      final scroll = decodeAndValidatePointerFastEnvelope(fast.sent.single);
      expect(scroll.sequence.toInt(), 1);
      expect(scroll.scroll.deltaX, -4);
      expect(scroll.scroll.deltaY, 12);
    },
  );

  test(
    'coalesces pointer movement to the latest value at one 60Hz frame',
    () async {
      final scheduler = _ManualFrameScheduler();
      final fast = _FakeInputChannel();
      final sender = RemoteInputSender(
        sessionId: _sessionId,
        reliable: _FakeInputChannel(),
        fast: fast,
        frameScheduler: scheduler,
      );

      sender.queuePointerMove(x: 10, y: 20, pressedButtonBits: 1);
      sender.queuePointerMove(x: 30, y: 40, pressedButtonBits: 2);
      expect(scheduler.scheduledDelay, pointerFrameInterval);
      expect(fast.sent, isEmpty);

      await scheduler.flush();

      final move = decodeAndValidatePointerFastEnvelope(fast.sent.single);
      expect(move.move.x, 30);
      expect(move.move.y, 40);
      expect(move.move.pressedButtonBits, 2);
    },
  );

  test(
    'drops stale movement under backpressure without blocking reliable',
    () async {
      final scheduler = _ManualFrameScheduler();
      final reliable = _FakeInputChannel();
      final fast = _FakeInputChannel(bufferedAmount: maxFastBufferedAmount + 1);
      final sender = RemoteInputSender(
        sessionId: _sessionId,
        reliable: reliable,
        fast: fast,
        frameScheduler: scheduler,
      );

      sender.queuePointerMove(x: 10, y: 20, pressedButtonBits: 0);
      await scheduler.flush();
      await sender.sendKeyboard(
        action: KeyboardAction.KEYBOARD_ACTION_UP,
        usbHidUsage: 0x04,
      );

      expect(fast.sent, isEmpty);
      expect(reliable.sent, hasLength(1));
      expect(sender.droppedPointerMoves, 1);
    },
  );

  test('release-all is sent once and close cancels pending movement', () async {
    final scheduler = _ManualFrameScheduler();
    final reliable = _FakeInputChannel();
    final fast = _FakeInputChannel();
    final sender = RemoteInputSender(
      sessionId: _sessionId,
      reliable: reliable,
      fast: fast,
      frameScheduler: scheduler,
    );
    sender.queuePointerMove(x: 10, y: 20, pressedButtonBits: 1);

    await sender.releaseAll();
    await sender.releaseAll();
    await sender.close();
    await scheduler.flush();

    final events = reliable.sent
        .map(decodeAndValidateReliableInputEnvelope)
        .toList(growable: false);
    expect(events, hasLength(2));
    expect(events.first.hasReleaseAllInput(), isTrue);
    expect(
      events.last.sessionControl.action,
      SessionControlAction.SESSION_CONTROL_ACTION_CLOSE,
    );
    expect(events.last.sequence.toInt(), 2);
    expect(fast.sent, isEmpty);
    expect(scheduler.cancelCount, 1);
  });

  test('new input rearms release-all after a focus-loss release', () async {
    final reliable = _FakeInputChannel();
    final sender = RemoteInputSender(
      sessionId: _sessionId,
      reliable: reliable,
      fast: _FakeInputChannel(),
      frameScheduler: _ManualFrameScheduler(),
    );

    await sender.releaseAll();
    await sender.sendKeyboard(
      action: KeyboardAction.KEYBOARD_ACTION_DOWN,
      usbHidUsage: 0x04,
    );
    await sender.releaseAll();

    expect(
      reliable.sent
          .map(decodeAndValidateReliableInputEnvelope)
          .where((event) => event.hasReleaseAllInput()),
      hasLength(2),
    );
  });

  test('suspends input, clears fast movement and preserves sequence', () async {
    final scheduler = _ManualFrameScheduler();
    final reliable = _FakeInputChannel();
    final fast = _FakeInputChannel();
    final sender = RemoteInputSender(
      sessionId: _sessionId,
      reliable: reliable,
      fast: fast,
      frameScheduler: scheduler,
    );
    await sender.sendKeyboard(
      action: KeyboardAction.KEYBOARD_ACTION_DOWN,
      usbHidUsage: 0x04,
    );
    sender.queuePointerMove(x: 100, y: 200, pressedButtonBits: 1);

    await sender.suspend();
    await sender.suspend();

    expect(
      () => sender.sendText('blocked'),
      throwsA(
        isA<InputSenderException>().having(
          (error) => error.code,
          'code',
          InputSenderErrorCode.suspended,
        ),
      ),
    );
    await scheduler.flush();
    expect(fast.sent, isEmpty);
    expect(scheduler.cancelCount, 1);
    expect(
      reliable.sent
          .map(decodeAndValidateReliableInputEnvelope)
          .last
          .sequence
          .toInt(),
      2,
    );
    expect(
      decodeAndValidateReliableInputEnvelope(
        reliable.sent.last,
      ).hasReleaseAllInput(),
      isTrue,
    );

    sender.resume();
    await sender.sendKeyboard(
      action: KeyboardAction.KEYBOARD_ACTION_UP,
      usbHidUsage: 0x04,
    );
    expect(
      decodeAndValidateReliableInputEnvelope(
        reliable.sent.last,
      ).sequence.toInt(),
      3,
    );
  });

  test('sends click, double-click and bounded UTF-8 text', () async {
    final reliable = _FakeInputChannel();
    final sender = RemoteInputSender(
      sessionId: _sessionId,
      reliable: reliable,
      fast: _FakeInputChannel(),
      frameScheduler: _ManualFrameScheduler(),
    );

    await sender.sendPointerClick(
      button: PointerButton.POINTER_BUTTON_LEFT,
      action: ButtonAction.BUTTON_ACTION_CLICK,
      x: 0,
      y: remoteInputCoordinateMaximum,
    );
    await sender.sendPointerClick(
      button: PointerButton.POINTER_BUTTON_RIGHT,
      action: ButtonAction.BUTTON_ACTION_DOUBLE_CLICK,
      x: remoteInputCoordinateMaximum,
      y: 0,
    );
    final text = List<String>.filled(maxRemoteTextInputBytes, 'a').join();
    expect(utf8.encode(text), hasLength(maxRemoteTextInputBytes));
    await sender.sendText(text);

    final events = reliable.sent
        .map(decodeAndValidateReliableInputEnvelope)
        .toList(growable: false);
    expect(events[0].pointerButton.action, ButtonAction.BUTTON_ACTION_CLICK);
    expect(
      events[1].pointerButton.action,
      ButtonAction.BUTTON_ACTION_DOUBLE_CLICK,
    );
    expect(events[2].text.text, text);
  });

  test('rejects values outside the Host input contract before send', () {
    final reliable = _FakeInputChannel();
    final fast = _FakeInputChannel();
    final sender = RemoteInputSender(
      sessionId: _sessionId,
      reliable: reliable,
      fast: fast,
      frameScheduler: _ManualFrameScheduler(),
    );

    expect(
      () => sender.queuePointerMove(
        x: remoteInputCoordinateMaximum + 1,
        y: 0,
        pressedButtonBits: 0,
      ),
      throwsA(isA<InputSenderException>()),
    );
    expect(
      () => sender.sendPointerClick(
        button: PointerButton.POINTER_BUTTON_LEFT,
        action: ButtonAction.BUTTON_ACTION_DOWN,
        x: 0,
        y: 0,
      ),
      throwsA(isA<InputSenderException>()),
    );
    for (final text in <String>[
      '',
      List<String>.filled(maxRemoteTextInputBytes + 1, 'a').join(),
      List<String>.filled(513, 'é').join(),
    ]) {
      expect(() => sender.sendText(text), throwsA(isA<InputSenderException>()));
    }
    for (final usage in <int>[0x03, 0xe8]) {
      expect(
        () => sender.sendKeyboard(
          action: KeyboardAction.KEYBOARD_ACTION_DOWN,
          usbHidUsage: usage,
        ),
        throwsA(isA<InputSenderException>()),
      );
    }
    expect(
      () => sender.sendKeyboard(
        action: KeyboardAction.KEYBOARD_ACTION_DOWN,
        usbHidUsage: 0x04,
        modifierBits: 0x100,
      ),
      throwsA(isA<InputSenderException>()),
    );
    expect(
      () => sender.sendScroll(deltaX: 0, deltaY: 10001),
      throwsA(isA<InputSenderException>()),
    );
    expect(reliable.sent, isEmpty);
    expect(fast.sent, isEmpty);
  });
}

final class _FakeInputChannel implements InputDataChannel {
  _FakeInputChannel({this.bufferedAmount = 0});

  @override
  int bufferedAmount;

  final List<Uint8List> sent = <Uint8List>[];

  @override
  Future<void> send(Uint8List bytes) async {
    sent.add(Uint8List.fromList(bytes));
  }
}

final class _ManualFrameScheduler implements InputFrameScheduler {
  Future<void> Function()? _callback;
  Duration? scheduledDelay;
  int cancelCount = 0;

  @override
  void schedule(Duration delay, Future<void> Function() callback) {
    scheduledDelay = delay;
    _callback = callback;
  }

  @override
  void cancel() {
    cancelCount += 1;
    _callback = null;
  }

  Future<void> flush() async {
    final callback = _callback;
    _callback = null;
    if (callback != null) {
      await callback();
    }
  }
}
