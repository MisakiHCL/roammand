// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

const mobileTapMaximumDuration = Duration(milliseconds: 250);
const mobileDoubleTapInterval = Duration(milliseconds: 300);
const mobileLongPressDelay = Duration(milliseconds: 500);
const mobileTwoFingerTapMaximumDuration = Duration(milliseconds: 300);
const mobileTwoFingerClassificationDelay = Duration(milliseconds: 32);
const mobileDoubleTapMaximumDistance = 24.0;
const mobileLongPressMovementTolerance = 12.0;
const mobileTwoFingerMovementTolerance = 16.0;
const mobilePinchScaleThreshold = 0.04;
const mobileScrollStartDistance = 8.0;
const mobileGestureClassificationMovement = 1.0;

abstract interface class MobileGestureTimer {
  void cancel();
}

abstract interface class MobileGestureScheduler {
  MobileGestureTimer schedule(Duration delay, void Function() callback);
}

final class TimerMobileGestureScheduler implements MobileGestureScheduler {
  const TimerMobileGestureScheduler();

  @override
  MobileGestureTimer schedule(Duration delay, void Function() callback) =>
      _TimerMobileGestureTimer(Timer(delay, callback));
}

final class _TimerMobileGestureTimer implements MobileGestureTimer {
  _TimerMobileGestureTimer(this._timer);

  Timer? _timer;

  @override
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}

sealed class MobileGestureAction {
  const MobileGestureAction();
}

enum MobileClickKind { leftClick, leftDoubleClick, rightClick }

final class MobileClickAction extends MobileGestureAction {
  const MobileClickAction({required this.kind, required this.position});

  final MobileClickKind kind;
  final Offset position;

  @override
  bool operator ==(Object other) =>
      other is MobileClickAction &&
      other.kind == kind &&
      other.position == position;

  @override
  int get hashCode => Object.hash(kind, position);
}

enum MobileDragPhase { down, move, up }

final class MobileDragAction extends MobileGestureAction {
  const MobileDragAction({required this.phase, required this.position});

  final MobileDragPhase phase;
  final Offset position;

  @override
  bool operator ==(Object other) =>
      other is MobileDragAction &&
      other.phase == phase &&
      other.position == position;

  @override
  int get hashCode => Object.hash(phase, position);
}

final class MobileScrollAction extends MobileGestureAction {
  const MobileScrollAction(this.delta);

  final Offset delta;

  @override
  bool operator ==(Object other) =>
      other is MobileScrollAction && other.delta == delta;

  @override
  int get hashCode => delta.hashCode;
}

enum MobileZoomPhase { start, update, end }

final class MobileZoomAction extends MobileGestureAction {
  const MobileZoomAction({
    required this.phase,
    required this.focalPoint,
    required this.scale,
  });

  final MobileZoomPhase phase;
  final Offset focalPoint;
  final double scale;

  @override
  bool operator ==(Object other) =>
      other is MobileZoomAction &&
      other.phase == phase &&
      other.focalPoint == focalPoint &&
      other.scale == scale;

  @override
  int get hashCode => Object.hash(phase, focalPoint, scale);
}

final class MobileReleaseAction extends MobileGestureAction {
  const MobileReleaseAction();

  @override
  bool operator ==(Object other) => other is MobileReleaseAction;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class MobileGestureMachine {
  factory MobileGestureMachine({
    required MobileGestureScheduler scheduler,
    required void Function(MobileGestureAction action) onAction,
  }) => MobileGestureMachine._(scheduler, onAction);

  MobileGestureMachine._(this._scheduler, this._onAction);

  final MobileGestureScheduler _scheduler;
  final void Function(MobileGestureAction action) _onAction;
  final Map<int, _Contact> _contacts = <int, _Contact>{};

  int? _singlePointer;
  Duration? _singleDownTime;
  Offset? _singleStart;
  Offset? _singleCurrent;
  MobileGestureTimer? _longPressTimer;
  MobileGestureTimer? _pendingTapTimer;
  MobileGestureTimer? _twoFingerClassificationTimer;
  _PendingTap? _pendingTap;
  _TwoFingerGesture? _twoFinger;
  bool _singleMoved = false;
  bool _dragging = false;
  bool _ignoreUntilClear = false;
  bool _releaseEmitted = false;
  bool _disposed = false;

  void pointerDown({
    required int pointer,
    required Offset position,
    required Duration timeStamp,
  }) {
    if (_disposed || _contacts.containsKey(pointer) || !_valid(position)) {
      return;
    }
    _releaseEmitted = false;
    _contacts[pointer] = _Contact(position, position);
    if (_ignoreUntilClear) {
      return;
    }
    if (_contacts.length == 1) {
      _beginSingle(pointer, position, timeStamp);
      return;
    }
    if (_contacts.length == 2) {
      _cancelLongPress();
      _cancelTwoFingerClassification();
      _singleMoved = true;
      _twoFinger = _TwoFingerGesture(contacts: _contacts, timeStamp: timeStamp);
      return;
    }
    final activeContacts = Map<int, _Contact>.of(_contacts);
    _cancelActiveState(emitRelease: true);
    _contacts.addAll(activeContacts);
    _ignoreUntilClear = true;
  }

  void pointerMove({
    required int pointer,
    required Offset position,
    required Duration timeStamp,
  }) {
    if (_disposed || !_valid(position)) {
      return;
    }
    final contact = _contacts[pointer];
    if (contact == null) {
      return;
    }
    contact.current = position;
    if (_ignoreUntilClear) {
      return;
    }
    final twoFinger = _twoFinger;
    if (twoFinger != null) {
      _updateTwoFinger(twoFinger);
      return;
    }
    if (pointer != _singlePointer) {
      return;
    }
    _singleCurrent = position;
    if (_dragging) {
      _onAction(
        MobileDragAction(phase: MobileDragPhase.move, position: position),
      );
      return;
    }
    if (_distance(position, _singleStart!) > mobileLongPressMovementTolerance) {
      _singleMoved = true;
      _cancelLongPress();
    }
  }

  void pointerUp({
    required int pointer,
    required Offset position,
    required Duration timeStamp,
  }) {
    if (_disposed) {
      return;
    }
    final contact = _contacts[pointer];
    if (contact == null) {
      return;
    }
    if (_valid(position)) {
      contact.current = position;
    }
    if (_ignoreUntilClear) {
      _contacts.remove(pointer);
      if (_contacts.isEmpty) {
        _ignoreUntilClear = false;
      }
      return;
    }
    final twoFinger = _twoFinger;
    if (twoFinger != null) {
      _cancelTwoFingerClassification();
      _finishTwoFinger(twoFinger, timeStamp);
      _twoFinger = null;
      _contacts.remove(pointer);
      _ignoreUntilClear = _contacts.isNotEmpty;
      _clearSingle();
      return;
    }
    if (pointer != _singlePointer) {
      _contacts.remove(pointer);
      return;
    }
    _cancelLongPress();
    final current = _valid(position) ? position : _singleCurrent!;
    if (_dragging) {
      _onAction(MobileDragAction(phase: MobileDragPhase.up, position: current));
    } else if (!_singleMoved &&
        timeStamp - _singleDownTime! <= mobileTapMaximumDuration) {
      _handleTap(current, timeStamp);
    }
    _contacts.remove(pointer);
    _clearSingle();
  }

  void pointerCancel(int pointer) {
    if (_contacts.containsKey(pointer)) {
      cancel();
    }
  }

  void cancel() {
    if (_disposed || _releaseEmitted) {
      return;
    }
    _cancelActiveState(emitRelease: true);
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _cancelActiveState(emitRelease: true);
    _disposed = true;
  }

  void _beginSingle(int pointer, Offset position, Duration timeStamp) {
    _singlePointer = pointer;
    _singleDownTime = timeStamp;
    _singleStart = position;
    _singleCurrent = position;
    _singleMoved = false;
    _dragging = false;
    _cancelLongPress();
    _longPressTimer = _scheduler.schedule(mobileLongPressDelay, () {
      if (_disposed ||
          _singlePointer != pointer ||
          _singleMoved ||
          _twoFinger != null ||
          _ignoreUntilClear) {
        return;
      }
      _dragging = true;
      _onAction(
        MobileDragAction(
          phase: MobileDragPhase.down,
          position: _singleCurrent!,
        ),
      );
    });
  }

  void _handleTap(Offset position, Duration timeStamp) {
    final pending = _pendingTap;
    if (pending != null &&
        timeStamp - pending.timeStamp <= mobileDoubleTapInterval &&
        _distance(position, pending.position) <=
            mobileDoubleTapMaximumDistance) {
      _pendingTapTimer?.cancel();
      _pendingTapTimer = null;
      _pendingTap = null;
      _onAction(
        MobileClickAction(
          kind: MobileClickKind.leftDoubleClick,
          position: position,
        ),
      );
      return;
    }
    if (pending != null) {
      _emitPendingTap();
    }
    _pendingTap = _PendingTap(position, timeStamp);
    _pendingTapTimer = _scheduler.schedule(
      mobileDoubleTapInterval,
      _emitPendingTap,
    );
  }

  void _emitPendingTap() {
    final pending = _pendingTap;
    _pendingTapTimer?.cancel();
    _pendingTapTimer = null;
    _pendingTap = null;
    if (pending != null && !_disposed) {
      _onAction(
        MobileClickAction(
          kind: MobileClickKind.leftClick,
          position: pending.position,
        ),
      );
    }
  }

  void _updateTwoFinger(_TwoFingerGesture gesture) {
    gesture.update(_contacts);
    if (gesture.mode == _TwoFingerMode.undecided) {
      if (!gesture.readyForClassification(_contacts)) {
        _scheduleTwoFingerClassification(gesture);
        return;
      }
      _cancelTwoFingerClassification();
    }
    _classifyAndEmitTwoFinger(gesture);
  }

  void _classifyAndEmitTwoFinger(_TwoFingerGesture gesture) {
    if (gesture.mode == _TwoFingerMode.undecided) {
      if ((gesture.scale - 1).abs() >= mobilePinchScaleThreshold) {
        gesture.mode = _TwoFingerMode.pinch;
        _onAction(
          MobileZoomAction(
            phase: MobileZoomPhase.start,
            focalPoint: gesture.startCentroid,
            scale: 1,
          ),
        );
      } else if (_distance(gesture.centroid, gesture.startCentroid) >=
          mobileScrollStartDistance) {
        gesture.mode = _TwoFingerMode.scroll;
      }
    }
    switch (gesture.mode) {
      case _TwoFingerMode.undecided:
        break;
      case _TwoFingerMode.pinch:
        _onAction(
          MobileZoomAction(
            phase: MobileZoomPhase.update,
            focalPoint: gesture.centroid,
            scale: gesture.scale,
          ),
        );
      case _TwoFingerMode.scroll:
        final delta = gesture.centroid - gesture.previousCentroid;
        if (delta != Offset.zero) {
          _onAction(MobileScrollAction(delta));
        }
    }
    gesture.previousCentroid = gesture.centroid;
  }

  void _scheduleTwoFingerClassification(_TwoFingerGesture gesture) {
    final thresholdReached =
        (gesture.scale - 1).abs() >= mobilePinchScaleThreshold ||
        _distance(gesture.centroid, gesture.startCentroid) >=
            mobileScrollStartDistance;
    if (_twoFingerClassificationTimer != null || !thresholdReached) {
      return;
    }
    _twoFingerClassificationTimer = _scheduler.schedule(
      mobileTwoFingerClassificationDelay,
      () {
        _twoFingerClassificationTimer = null;
        if (_disposed ||
            !identical(_twoFinger, gesture) ||
            _ignoreUntilClear ||
            _contacts.length != 2) {
          return;
        }
        _classifyAndEmitTwoFinger(gesture);
      },
    );
  }

  void _finishTwoFinger(_TwoFingerGesture gesture, Duration timeStamp) {
    switch (gesture.mode) {
      case _TwoFingerMode.undecided:
        if (timeStamp - gesture.timeStamp <=
                mobileTwoFingerTapMaximumDuration &&
            gesture.maximumMovement <= mobileTwoFingerMovementTolerance) {
          _onAction(
            MobileClickAction(
              kind: MobileClickKind.rightClick,
              position: gesture.startCentroid,
            ),
          );
        }
      case _TwoFingerMode.pinch:
        _onAction(
          MobileZoomAction(
            phase: MobileZoomPhase.end,
            focalPoint: gesture.centroid,
            scale: gesture.scale,
          ),
        );
      case _TwoFingerMode.scroll:
        break;
    }
  }

  void _cancelActiveState({required bool emitRelease}) {
    _cancelLongPress();
    _cancelTwoFingerClassification();
    _pendingTapTimer?.cancel();
    _pendingTapTimer = null;
    _pendingTap = null;
    _contacts.clear();
    _twoFinger = null;
    _ignoreUntilClear = false;
    _clearSingle();
    if (emitRelease && !_releaseEmitted) {
      _releaseEmitted = true;
      _onAction(const MobileReleaseAction());
    }
  }

  void _cancelLongPress() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
  }

  void _cancelTwoFingerClassification() {
    _twoFingerClassificationTimer?.cancel();
    _twoFingerClassificationTimer = null;
  }

  void _clearSingle() {
    _cancelLongPress();
    _singlePointer = null;
    _singleDownTime = null;
    _singleStart = null;
    _singleCurrent = null;
    _singleMoved = false;
    _dragging = false;
  }
}

final class _Contact {
  _Contact(this.start, this.current);

  final Offset start;
  Offset current;
}

final class _PendingTap {
  const _PendingTap(this.position, this.timeStamp);

  final Offset position;
  final Duration timeStamp;
}

enum _TwoFingerMode { undecided, pinch, scroll }

final class _TwoFingerGesture {
  _TwoFingerGesture({
    required Map<int, _Contact> contacts,
    required this.timeStamp,
  }) : initial = <int, Offset>{
         for (final entry in contacts.entries) entry.key: entry.value.current,
       },
       startCentroid = _centroid(contacts.values.map((value) => value.current)),
       centroid = _centroid(contacts.values.map((value) => value.current)),
       previousCentroid = _centroid(
         contacts.values.map((value) => value.current),
       ),
       startDistance = _contactDistance(contacts),
       currentDistance = _contactDistance(contacts);

  final Map<int, Offset> initial;
  final Duration timeStamp;
  final Offset startCentroid;
  final double startDistance;
  Offset centroid;
  Offset previousCentroid;
  double currentDistance;
  double maximumMovement = 0;
  _TwoFingerMode mode = _TwoFingerMode.undecided;

  double get scale => startDistance <= 0 ? 1 : currentDistance / startDistance;

  bool readyForClassification(Map<int, _Contact> contacts) =>
      initial.entries.every((entry) {
        final contact = contacts[entry.key];
        return contact != null &&
            _distance(entry.value, contact.current) >=
                mobileGestureClassificationMovement;
      });

  void update(Map<int, _Contact> contacts) {
    centroid = _centroid(contacts.values.map((value) => value.current));
    currentDistance = _contactDistance(contacts);
    for (final entry in contacts.entries) {
      final start = initial[entry.key];
      if (start != null) {
        maximumMovement = math.max(
          maximumMovement,
          _distance(start, entry.value.current),
        );
      }
    }
  }
}

Offset _centroid(Iterable<Offset> values) {
  final points = values.take(2).toList(growable: false);
  return Offset(
    (points[0].dx + points[1].dx) / 2,
    (points[0].dy + points[1].dy) / 2,
  );
}

double _contactDistance(Map<int, _Contact> contacts) {
  final points = contacts.values
      .take(2)
      .map((value) => value.current)
      .toList(growable: false);
  return _distance(points[0], points[1]);
}

double _distance(Offset left, Offset right) => (left - right).distance;

bool _valid(Offset position) => position.dx.isFinite && position.dy.isFinite;
