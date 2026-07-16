// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:collection';

import 'package:roammand/desktop/remote/input_sender.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

enum MobileModifierKey { control, shift, alt, command }

enum MobileSpecialKey { escape, tab, arrowLeft, arrowUp, arrowRight, arrowDown }

const _modifierUsages = <MobileModifierKey, int>{
  MobileModifierKey.control: 0xe0,
  MobileModifierKey.shift: 0xe1,
  MobileModifierKey.alt: 0xe2,
  MobileModifierKey.command: 0xe3,
};

const _modifierBits = <MobileModifierKey, int>{
  MobileModifierKey.control: 1 << 0,
  MobileModifierKey.shift: 1 << 1,
  MobileModifierKey.alt: 1 << 2,
  MobileModifierKey.command: 1 << 3,
};

const _specialUsages = <MobileSpecialKey, int>{
  MobileSpecialKey.escape: 0x29,
  MobileSpecialKey.tab: 0x2b,
  MobileSpecialKey.arrowRight: 0x4f,
  MobileSpecialKey.arrowLeft: 0x50,
  MobileSpecialKey.arrowDown: 0x51,
  MobileSpecialKey.arrowUp: 0x52,
};

final class MobileKeyboardController {
  MobileKeyboardController(this._sender);

  final RemoteInputSender _sender;
  final Set<MobileModifierKey> _activeModifiers = <MobileModifierKey>{};

  Future<void> _tail = Future<void>.value();
  bool _closed = false;

  Set<MobileModifierKey> get activeModifiers =>
      UnmodifiableSetView<MobileModifierKey>(_activeModifiers);

  bool isModifierActive(MobileModifierKey modifier) =>
      _activeModifiers.contains(modifier);

  Future<void> setModifier(MobileModifierKey modifier, bool active) {
    if (_closed) {
      return _closedFuture();
    }
    final changed = active
        ? _activeModifiers.add(modifier)
        : _activeModifiers.remove(modifier);
    if (!changed) {
      return _tail;
    }
    final usage = _modifierUsages[modifier]!;
    final bits = _currentModifierBits();
    return _enqueue(
      () => _sender.sendKeyboard(
        action: active
            ? KeyboardAction.KEYBOARD_ACTION_DOWN
            : KeyboardAction.KEYBOARD_ACTION_UP,
        usbHidUsage: usage,
        modifierBits: bits,
      ),
    );
  }

  Future<void> sendSpecial(MobileSpecialKey key) {
    if (_closed) {
      return _closedFuture();
    }
    final usage = _specialUsages[key]!;
    final bits = _currentModifierBits();
    return _enqueue(() async {
      await _sender.sendKeyboard(
        action: KeyboardAction.KEYBOARD_ACTION_DOWN,
        usbHidUsage: usage,
        modifierBits: bits,
      );
      await _sender.sendKeyboard(
        action: KeyboardAction.KEYBOARD_ACTION_UP,
        usbHidUsage: usage,
        modifierBits: bits,
      );
    });
  }

  Future<void> sendText(String text) {
    if (_closed) {
      return _closedFuture();
    }
    return _enqueue(() => _sender.sendText(text));
  }

  Future<void> releaseAll() {
    if (_closed) {
      return _tail;
    }
    _activeModifiers.clear();
    return _enqueue(_sender.releaseAll);
  }

  Future<void> close() {
    if (_closed) {
      return _tail;
    }
    _activeModifiers.clear();
    final closing = _enqueue(_sender.releaseAll);
    _closed = true;
    return closing;
  }

  int _currentModifierBits() => _activeModifiers.fold<int>(
    0,
    (bits, modifier) => bits | _modifierBits[modifier]!,
  );

  Future<void> _enqueue(Future<void> Function() operation) {
    final completer = Completer<void>();
    _tail = _tail.then((_) async {
      try {
        await operation();
        completer.complete();
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<void> _closedFuture() =>
      Future<void>.error(StateError('mobile keyboard controller is closed'));
}
