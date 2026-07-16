// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/desktop/remote/reconnect_policy.dart';

void main() {
  test('uses the exact bounded reconnect schedule', () {
    const policy = ReconnectPolicy();

    expect(policy.attemptDelays, const <Duration>[
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 8),
      Duration(seconds: 15),
    ]);
    expect(policy.recoveryWindow, const Duration(seconds: 30));
    expect(
      policy.attemptDelays.fold<Duration>(
        Duration.zero,
        (elapsed, delay) => elapsed + delay,
      ),
      policy.recoveryWindow,
    );
  });

  test('permits one timer and one attempt at a time', () {
    final sequence = const ReconnectPolicy().start();

    final first = sequence.scheduleNext();
    expect(first?.attempt, 1);
    expect(first?.delay, const Duration(seconds: 1));
    expect(first?.elapsed, const Duration(seconds: 1));
    expect(sequence.scheduleNext(), isNull);

    expect(sequence.begin(first!), isTrue);
    expect(sequence.begin(first), isFalse);
    expect(sequence.scheduleNext(), isNull);
    expect(sequence.complete(first), isTrue);

    final second = sequence.scheduleNext();
    expect(second?.attempt, 2);
    expect(second?.delay, const Duration(seconds: 2));
    expect(second?.elapsed, const Duration(seconds: 3));
  });

  test('stops after the fifth failed attempt at thirty seconds', () {
    final sequence = const ReconnectPolicy().start();
    ReconnectAttemptTicket? last;

    for (var attempt = 1; attempt <= 5; attempt += 1) {
      final ticket = sequence.scheduleNext();
      expect(ticket, isNotNull);
      expect(ticket?.attempt, attempt);
      expect(sequence.begin(ticket!), isTrue);
      expect(sequence.complete(ticket), isTrue);
      last = ticket;
    }

    expect(last?.elapsed, const Duration(seconds: 30));
    expect(sequence.exhausted, isTrue);
    expect(sequence.scheduleNext(), isNull);
  });

  test('recovery cancels pending work and invalidates stale callbacks', () {
    final sequence = const ReconnectPolicy().start();
    final pending = sequence.scheduleNext()!;

    sequence.recovered();

    expect(sequence.active, isFalse);
    expect(sequence.exhausted, isFalse);
    expect(sequence.begin(pending), isFalse);
    expect(sequence.complete(pending), isFalse);
    expect(sequence.scheduleNext(), isNull);
  });

  test('cancellation invalidates an in-flight completion', () {
    final sequence = const ReconnectPolicy().start();
    final inFlight = sequence.scheduleNext()!;
    expect(sequence.begin(inFlight), isTrue);

    sequence.cancel();

    expect(sequence.complete(inFlight), isFalse);
    expect(sequence.scheduleNext(), isNull);
  });
}
