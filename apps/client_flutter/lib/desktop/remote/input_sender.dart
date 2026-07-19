// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

const pointerFrameInterval = Duration(microseconds: 16667);
const maxFastBufferedAmount = 256 * 1024;
const remoteInputCoordinateMaximum = 10000;
const maxRemoteTextInputBytes = 1024;
const maxRemoteScrollDelta = 10000;
const _minimumUsbHidUsage = 0x04;
const _maximumUsbHidUsage = 0xe7;
const _maximumModifierBits = 0xff;

abstract interface class InputDataChannel {
  int get bufferedAmount;

  Future<void> send(Uint8List bytes);
}

abstract interface class InputFrameScheduler {
  void schedule(Duration delay, Future<void> Function() callback);

  void cancel();
}

final class TimerInputFrameScheduler implements InputFrameScheduler {
  Timer? _timer;

  @override
  void schedule(Duration delay, Future<void> Function() callback) {
    _timer?.cancel();
    _timer = Timer(delay, () => unawaited(callback()));
  }

  @override
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}

enum InputSenderErrorCode {
  invalidSession,
  invalidCoordinate,
  invalidUsage,
  invalidEnum,
  invalidText,
  invalidScroll,
  suspended,
  closed,
  channel,
}

final class InputSenderException implements Exception {
  const InputSenderException(this.code);

  final InputSenderErrorCode code;

  @override
  String toString() => 'InputSenderException(${code.name})';
}

final class RemoteInputSender {
  factory RemoteInputSender({
    required List<int> sessionId,
    required InputDataChannel reliable,
    required InputDataChannel fast,
    InputFrameScheduler? frameScheduler,
  }) => RemoteInputSender._(
    Uint8List.fromList(sessionId),
    reliable,
    fast,
    frameScheduler ?? TimerInputFrameScheduler(),
  );

  RemoteInputSender._(
    this._sessionId,
    this._reliable,
    this._fast,
    this._frameScheduler,
  ) {
    if (_sessionId.length != sessionIdBytes) {
      throw const InputSenderException(InputSenderErrorCode.invalidSession);
    }
  }

  final Uint8List _sessionId;
  final InputDataChannel _reliable;
  final InputDataChannel _fast;
  final InputFrameScheduler _frameScheduler;

  int _reliableSequence = 0;
  int _fastSequence = 0;
  _PendingPointerMove? _pendingMove;
  bool _frameScheduled = false;
  bool _releaseSent = false;
  bool _suspended = false;
  bool _closed = false;
  bool _fastSendInFlight = false;
  int _droppedPointerMoves = 0;

  int get droppedPointerMoves => _droppedPointerMoves;

  Future<void> sendPointerButton({
    required PointerButton button,
    required ButtonAction action,
    required int x,
    required int y,
  }) {
    _ensureOpen();
    _releaseSent = false;
    _validateCoordinate(x, y);
    if (button == PointerButton.POINTER_BUTTON_UNSPECIFIED ||
        action == ButtonAction.BUTTON_ACTION_UNSPECIFIED) {
      throw const InputSenderException(InputSenderErrorCode.invalidEnum);
    }
    return _sendReliable(
      ReliableInputEnvelope(
        pointerButton: PointerButtonEvent(
          button: button,
          action: action,
          x: x,
          y: y,
        ),
      ),
    );
  }

  Future<void> sendPointerClick({
    required PointerButton button,
    required ButtonAction action,
    required int x,
    required int y,
  }) {
    if (action != ButtonAction.BUTTON_ACTION_CLICK &&
        action != ButtonAction.BUTTON_ACTION_DOUBLE_CLICK) {
      throw const InputSenderException(InputSenderErrorCode.invalidEnum);
    }
    return sendPointerButton(button: button, action: action, x: x, y: y);
  }

  Future<void> sendKeyboard({
    required KeyboardAction action,
    required int usbHidUsage,
    int modifierBits = 0,
  }) {
    _ensureOpen();
    _releaseSent = false;
    if (action == KeyboardAction.KEYBOARD_ACTION_UNSPECIFIED) {
      throw const InputSenderException(InputSenderErrorCode.invalidEnum);
    }
    if (usbHidUsage < _minimumUsbHidUsage ||
        usbHidUsage > _maximumUsbHidUsage ||
        modifierBits < 0 ||
        modifierBits > _maximumModifierBits) {
      throw const InputSenderException(InputSenderErrorCode.invalidUsage);
    }
    return _sendReliable(
      ReliableInputEnvelope(
        keyboard: KeyboardEvent(
          action: action,
          usbHidUsage: usbHidUsage,
          modifierBits: modifierBits,
        ),
      ),
    );
  }

  Future<void> sendText(String text) {
    _ensureOpen();
    final encoded = utf8.encode(text);
    if (encoded.isEmpty || encoded.length > maxRemoteTextInputBytes) {
      throw const InputSenderException(InputSenderErrorCode.invalidText);
    }
    _releaseSent = false;
    return _sendReliable(
      ReliableInputEnvelope(text: TextInputEvent(text: text)),
    );
  }

  Future<void> sendScroll({required int deltaX, required int deltaY}) async {
    _ensureOpen();
    if (deltaX.abs() > maxRemoteScrollDelta ||
        deltaY.abs() > maxRemoteScrollDelta) {
      throw const InputSenderException(InputSenderErrorCode.invalidScroll);
    }
    _releaseSent = false;
    await _sendFastBestEffort(
      PointerFastEnvelope(
        scroll: PointerScrollEvent(deltaX: deltaX, deltaY: deltaY),
      ),
    );
  }

  void queuePointerMove({
    required int x,
    required int y,
    required int pressedButtonBits,
  }) {
    _ensureOpen();
    _releaseSent = false;
    _validateCoordinate(x, y);
    if (pressedButtonBits < 0 || pressedButtonBits > 0x07) {
      throw const InputSenderException(InputSenderErrorCode.invalidEnum);
    }
    _pendingMove = _PendingPointerMove(x, y, pressedButtonBits);
    _schedulePendingPointerMove();
  }

  Future<void> releaseAll() async {
    if (_closed || _releaseSent) {
      return;
    }
    _releaseSent = true;
    await _sendReliable(
      ReliableInputEnvelope(releaseAllInput: ReleaseAllInput()),
    );
  }

  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _pendingMove = null;
    if (_frameScheduled) {
      _frameScheduler.cancel();
      _frameScheduled = false;
    }
    if (!_releaseSent) {
      _releaseSent = true;
      await _sendReliable(
        ReliableInputEnvelope(releaseAllInput: ReleaseAllInput()),
      );
    }
    await _sendReliable(
      ReliableInputEnvelope(
        sessionControl: SessionControlEvent(
          action: SessionControlAction.SESSION_CONTROL_ACTION_CLOSE,
        ),
      ),
    );
  }

  Future<void> suspend() async {
    if (_closed || _suspended) {
      return;
    }
    _suspended = true;
    _pendingMove = null;
    if (_frameScheduled) {
      _frameScheduler.cancel();
      _frameScheduled = false;
    }
    await releaseAll();
  }

  void resume() {
    if (_closed) {
      throw const InputSenderException(InputSenderErrorCode.closed);
    }
    _suspended = false;
  }

  Future<void> _flushPointerMove() async {
    _frameScheduled = false;
    final move = _pendingMove;
    _pendingMove = null;
    if (_closed || _suspended || move == null) {
      return;
    }
    if (_fastSendInFlight) {
      _pendingMove ??= move;
      return;
    }
    if (_fast.bufferedAmount > maxFastBufferedAmount) {
      _droppedPointerMoves += 1;
      return;
    }
    final sent = await _sendFastBestEffort(
      PointerFastEnvelope(
        move: PointerMoveEvent(
          x: move.x,
          y: move.y,
          pressedButtonBits: move.pressedButtonBits,
        ),
      ),
    );
    if (!sent) {
      _droppedPointerMoves += 1;
    }
  }

  void _schedulePendingPointerMove() {
    if (_closed ||
        _suspended ||
        _pendingMove == null ||
        _frameScheduled ||
        _fastSendInFlight) {
      return;
    }
    _frameScheduled = true;
    _frameScheduler.schedule(pointerFrameInterval, _flushPointerMove);
  }

  Future<bool> _sendFastBestEffort(PointerFastEnvelope envelope) async {
    if (_fastSendInFlight || _fast.bufferedAmount > maxFastBufferedAmount) {
      return false;
    }
    _fastSendInFlight = true;
    try {
      await _sendFast(envelope);
      return true;
    } on InputSenderException catch (error) {
      if (error.code != InputSenderErrorCode.channel) {
        rethrow;
      }
      // Pointer movement and scrolling use the deliberately lossy channel.
      // A closed or temporarily unwritable fast channel must not terminate
      // the reliable input path or surface an unhandled frame-callback error.
      return false;
    } finally {
      _fastSendInFlight = false;
      _schedulePendingPointerMove();
    }
  }

  Future<void> _sendReliable(ReliableInputEnvelope envelope) async {
    envelope
      ..protocolVersion = _version()
      ..sessionId = _sessionId
      ..sequence = Int64(++_reliableSequence);
    final encoded = Uint8List.fromList(envelope.writeToBuffer());
    if (encoded.length > maxReliableInputEnvelopeBytes) {
      throw const InputSenderException(InputSenderErrorCode.channel);
    }
    try {
      await _reliable.send(encoded);
    } catch (_) {
      throw const InputSenderException(InputSenderErrorCode.channel);
    }
  }

  Future<void> _sendFast(PointerFastEnvelope envelope) async {
    envelope
      ..protocolVersion = _version()
      ..sessionId = _sessionId
      ..sequence = Int64(++_fastSequence);
    final encoded = Uint8List.fromList(envelope.writeToBuffer());
    if (encoded.length > maxPointerFastEnvelopeBytes) {
      throw const InputSenderException(InputSenderErrorCode.channel);
    }
    try {
      await _fast.send(encoded);
    } catch (_) {
      throw const InputSenderException(InputSenderErrorCode.channel);
    }
  }

  void _ensureOpen() {
    if (_closed) {
      throw const InputSenderException(InputSenderErrorCode.closed);
    }
    if (_suspended) {
      throw const InputSenderException(InputSenderErrorCode.suspended);
    }
  }
}

final class _PendingPointerMove {
  const _PendingPointerMove(this.x, this.y, this.pressedButtonBits);

  final int x;
  final int y;
  final int pressedButtonBits;
}

ProtocolVersion _version() => ProtocolVersion(
  major: protocolMajorVersion,
  minor: minimumProtocolMinorVersion,
);

void _validateCoordinate(int x, int y) {
  if (x < 0 ||
      x > remoteInputCoordinateMaximum ||
      y < 0 ||
      y > remoteInputCoordinateMaximum) {
    throw const InputSenderException(InputSenderErrorCode.invalidCoordinate);
  }
}
