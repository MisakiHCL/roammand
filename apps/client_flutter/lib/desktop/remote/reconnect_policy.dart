// SPDX-License-Identifier: MPL-2.0

import 'dart:async';

const _reconnectAttemptDelays = <Duration>[
  Duration(seconds: 1),
  Duration(seconds: 2),
  Duration(seconds: 4),
  Duration(seconds: 8),
  Duration(seconds: 8),
];

const _reconnectRecoveryWindow = Duration(seconds: 30);

abstract interface class ReconnectTimer {
  void cancel();
}

abstract interface class ReconnectScheduler {
  ReconnectTimer schedule(Duration delay, void Function() callback);
}

final class TimerReconnectScheduler implements ReconnectScheduler {
  const TimerReconnectScheduler();

  @override
  ReconnectTimer schedule(Duration delay, void Function() callback) =>
      _TimerReconnectTimer(Timer(delay, callback));
}

final class _TimerReconnectTimer implements ReconnectTimer {
  const _TimerReconnectTimer(this._timer);

  final Timer _timer;

  @override
  void cancel() => _timer.cancel();
}

final class ReconnectPolicy {
  const ReconnectPolicy();

  List<Duration> get attemptDelays => _reconnectAttemptDelays;

  Duration get recoveryWindow => _reconnectRecoveryWindow;

  ReconnectAttemptSequence start() => ReconnectAttemptSequence._(this);
}

final class ReconnectAttemptTicket {
  const ReconnectAttemptTicket._(
    this._generation, {
    required this.attempt,
    required this.delay,
    required this.elapsed,
  });

  final int attempt;
  final Duration delay;
  final Duration elapsed;
  final int _generation;
}

final class ReconnectAttemptSequence {
  ReconnectAttemptSequence._(this._policy);

  final ReconnectPolicy _policy;
  var _generation = 1;
  var _nextIndex = 0;
  var _elapsed = Duration.zero;
  var _active = true;
  var _exhausted = false;
  ReconnectAttemptTicket? _pending;
  ReconnectAttemptTicket? _inFlight;

  bool get active => _active;

  bool get exhausted => _exhausted;

  bool get allAttemptsCompleted =>
      _active &&
      _pending == null &&
      _inFlight == null &&
      _nextIndex >= _policy.attemptDelays.length;

  Duration get remainingRecoveryWindow {
    final remaining = _policy.recoveryWindow - _elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  ReconnectAttemptTicket? scheduleNext() {
    if (!_active ||
        _pending != null ||
        _inFlight != null ||
        _nextIndex >= _policy.attemptDelays.length) {
      return null;
    }
    final delay = _policy.attemptDelays[_nextIndex];
    _elapsed += delay;
    final ticket = ReconnectAttemptTicket._(
      _generation,
      attempt: _nextIndex + 1,
      delay: delay,
      elapsed: _elapsed,
    );
    _nextIndex += 1;
    _pending = ticket;
    return ticket;
  }

  bool begin(ReconnectAttemptTicket ticket) {
    if (!_isCurrent(ticket) || !identical(_pending, ticket)) {
      return false;
    }
    _pending = null;
    _inFlight = ticket;
    return true;
  }

  bool complete(ReconnectAttemptTicket ticket) {
    if (!_isCurrent(ticket) || !identical(_inFlight, ticket)) {
      return false;
    }
    _inFlight = null;
    return true;
  }

  bool expire() {
    if (!allAttemptsCompleted) {
      return false;
    }
    _active = false;
    _exhausted = true;
    return true;
  }

  void recovered() => _invalidate();

  void cancel() => _invalidate();

  bool _isCurrent(ReconnectAttemptTicket ticket) =>
      _active && ticket._generation == _generation;

  void _invalidate() {
    if (!_active) {
      return;
    }
    _generation += 1;
    _active = false;
    _pending = null;
    _inFlight = null;
  }
}
