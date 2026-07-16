// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/mobile/remote/mobile_gesture_machine.dart';

void main() {
  test('delays a single click until the double-tap window closes', () {
    final fixture = _GestureFixture();

    fixture.down(1, const Offset(40, 50), 0);
    fixture.up(1, const Offset(40, 50), 100);
    expect(fixture.actions, isEmpty);
    fixture.scheduler.elapse(const Duration(milliseconds: 299));
    expect(fixture.actions, isEmpty);
    fixture.scheduler.elapse(const Duration(milliseconds: 1));

    expect(fixture.actions, <MobileGestureAction>[
      const MobileClickAction(
        kind: MobileClickKind.leftClick,
        position: Offset(40, 50),
      ),
    ]);
  });

  test('emits one double-click without an earlier single click', () {
    final fixture = _GestureFixture();

    fixture.down(1, const Offset(40, 50), 0);
    fixture.up(1, const Offset(40, 50), 80);
    fixture.down(2, const Offset(48, 54), 180);
    fixture.up(2, const Offset(48, 54), 240);
    fixture.scheduler.elapse(const Duration(seconds: 1));

    expect(fixture.actions, <MobileGestureAction>[
      const MobileClickAction(
        kind: MobileClickKind.leftDoubleClick,
        position: Offset(48, 54),
      ),
    ]);
  });

  test('long press produces an exact drag down move and up sequence', () {
    final fixture = _GestureFixture();

    fixture.down(1, const Offset(60, 70), 0);
    fixture.scheduler.elapse(mobileLongPressDelay);
    fixture.move(1, const Offset(90, 110), 550);
    fixture.up(1, const Offset(100, 120), 600);

    expect(fixture.actions, <MobileGestureAction>[
      const MobileDragAction(
        phase: MobileDragPhase.down,
        position: Offset(60, 70),
      ),
      const MobileDragAction(
        phase: MobileDragPhase.move,
        position: Offset(90, 110),
      ),
      const MobileDragAction(
        phase: MobileDragPhase.up,
        position: Offset(100, 120),
      ),
    ]);
  });

  test('two-finger tap emits one right click at the centroid', () {
    final fixture = _GestureFixture();

    fixture.down(1, const Offset(40, 80), 0);
    fixture.down(2, const Offset(80, 100), 10);
    fixture.up(2, const Offset(80, 100), 120);
    fixture.up(1, const Offset(40, 80), 130);

    expect(fixture.actions, <MobileGestureAction>[
      const MobileClickAction(
        kind: MobileClickKind.rightClick,
        position: Offset(60, 90),
      ),
    ]);
  });

  test('two-finger movement emits scroll and never right-clicks', () {
    final fixture = _GestureFixture();

    fixture.down(1, const Offset(100, 100), 0);
    fixture.down(2, const Offset(200, 100), 10);
    fixture.move(1, const Offset(100, 120), 40);
    fixture.move(2, const Offset(200, 120), 50);
    fixture.up(2, const Offset(200, 120), 70);
    fixture.up(1, const Offset(100, 120), 80);

    expect(fixture.actions.whereType<MobileScrollAction>(), isNotEmpty);
    expect(fixture.actions.whereType<MobileClickAction>(), isEmpty);
    expect(fixture.actions.whereType<MobileZoomAction>(), isEmpty);
  });

  test('pinch emits zoom start updates and end without remote input', () {
    final fixture = _GestureFixture();

    fixture.down(1, const Offset(100, 100), 0);
    fixture.down(2, const Offset(200, 100), 10);
    fixture.move(1, const Offset(90, 100), 40);
    fixture.move(2, const Offset(210, 100), 50);
    fixture.up(2, const Offset(210, 100), 70);
    fixture.up(1, const Offset(90, 100), 80);

    final zoom = fixture.actions.whereType<MobileZoomAction>().toList();
    expect(zoom.first.phase, MobileZoomPhase.start);
    expect(zoom.first.focalPoint, const Offset(150, 100));
    expect(
      zoom.where((action) => action.phase == MobileZoomPhase.update),
      hasLength(1),
    );
    expect(zoom.last.phase, MobileZoomPhase.end);
    expect(fixture.actions.whereType<MobileClickAction>(), isEmpty);
    expect(fixture.actions.whereType<MobileScrollAction>(), isEmpty);
  });

  test('recognizes a pinch with one stationary anchor after a short delay', () {
    final fixture = _GestureFixture();

    fixture.down(1, const Offset(100, 100), 0);
    fixture.down(2, const Offset(200, 100), 10);
    fixture.move(1, const Offset(70, 100), 40);
    fixture.scheduler.elapse(
      mobileTwoFingerClassificationDelay - const Duration(milliseconds: 1),
    );
    expect(fixture.actions.whereType<MobileZoomAction>(), isEmpty);

    fixture.scheduler.elapse(const Duration(milliseconds: 1));
    fixture.up(1, const Offset(70, 100), 80);
    fixture.up(2, const Offset(200, 100), 90);

    final zoom = fixture.actions.whereType<MobileZoomAction>().toList();
    expect(zoom.first.phase, MobileZoomPhase.start);
    expect(
      zoom.any((action) => action.phase == MobileZoomPhase.update),
      isTrue,
    );
    expect(zoom.last.phase, MobileZoomPhase.end);
  });

  test('third contact cancels cleanly without swallowing the next tap', () {
    final fixture = _GestureFixture();

    fixture.down(1, const Offset(80, 100), 0);
    fixture.down(2, const Offset(120, 100), 10);
    fixture.down(3, const Offset(100, 140), 20);
    fixture.up(1, const Offset(80, 100), 30);
    fixture.up(2, const Offset(120, 100), 40);
    fixture.up(3, const Offset(100, 140), 50);
    fixture.down(4, const Offset(200, 220), 60);
    fixture.up(4, const Offset(200, 220), 100);
    fixture.scheduler.elapse(mobileDoubleTapInterval);

    expect(fixture.actions, <MobileGestureAction>[
      const MobileReleaseAction(),
      const MobileClickAction(
        kind: MobileClickKind.leftClick,
        position: Offset(200, 220),
      ),
    ]);
  });

  test('motion before long press cancels tap and drag', () {
    final fixture = _GestureFixture();

    fixture.down(1, Offset.zero, 0);
    fixture.move(1, const Offset(30, 0), 100);
    fixture.scheduler.elapse(const Duration(seconds: 1));
    fixture.up(1, const Offset(30, 0), 1100);

    expect(fixture.actions, isEmpty);
    expect(fixture.scheduler.activeCount, 0);
  });

  test('cancel clears timers and requests release exactly once', () {
    final fixture = _GestureFixture();
    fixture.down(1, const Offset(10, 20), 0);

    fixture.machine.cancel();
    fixture.machine.cancel();
    fixture.scheduler.elapse(const Duration(seconds: 2));

    expect(fixture.actions, <MobileGestureAction>[const MobileReleaseAction()]);
    expect(fixture.scheduler.activeCount, 0);
  });
}

final class _GestureFixture {
  _GestureFixture()
    : scheduler = _FakeGestureScheduler(),
      actions = <MobileGestureAction>[] {
    machine = MobileGestureMachine(scheduler: scheduler, onAction: actions.add);
  }

  final _FakeGestureScheduler scheduler;
  final List<MobileGestureAction> actions;
  late final MobileGestureMachine machine;

  void down(int pointer, Offset position, int milliseconds) =>
      machine.pointerDown(
        pointer: pointer,
        position: position,
        timeStamp: Duration(milliseconds: milliseconds),
      );

  void move(int pointer, Offset position, int milliseconds) =>
      machine.pointerMove(
        pointer: pointer,
        position: position,
        timeStamp: Duration(milliseconds: milliseconds),
      );

  void up(int pointer, Offset position, int milliseconds) => machine.pointerUp(
    pointer: pointer,
    position: position,
    timeStamp: Duration(milliseconds: milliseconds),
  );
}

final class _FakeGestureScheduler implements MobileGestureScheduler {
  final List<_FakeGestureTimer> _timers = <_FakeGestureTimer>[];
  Duration _elapsed = Duration.zero;

  int get activeCount => _timers.where((timer) => timer.active).length;

  @override
  MobileGestureTimer schedule(Duration delay, void Function() callback) {
    final timer = _FakeGestureTimer(_elapsed + delay, callback);
    _timers.add(timer);
    return timer;
  }

  void elapse(Duration duration) {
    _elapsed += duration;
    final due =
        _timers.where((timer) => timer.active && timer.due <= _elapsed).toList()
          ..sort((left, right) => left.due.compareTo(right.due));
    for (final timer in due) {
      timer.fire();
    }
  }
}

final class _FakeGestureTimer implements MobileGestureTimer {
  _FakeGestureTimer(this.due, this.callback);

  final Duration due;
  final void Function() callback;
  bool active = true;

  @override
  void cancel() {
    active = false;
  }

  void fire() {
    if (!active) return;
    active = false;
    callback();
  }
}
