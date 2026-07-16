// SPDX-License-Identifier: MPL-2.0

import 'dart:collection';

import 'diagnostics_model.dart';

final class DiagnosticsCollector {
  DiagnosticsCollector({
    required this.metadata,
    required int Function() nowUnixMs,
  }) : _nowUnixMs = nowUnixMs,
       _startedAtUnixMs = nowUnixMs();

  final DiagnosticsMetadata metadata;
  final int Function() _nowUnixMs;
  final int _startedAtUnixMs;
  final Queue<DiagnosticsEvent> _events = Queue<DiagnosticsEvent>();
  final _WebRtcAccumulator _webRtc = _WebRtcAccumulator();
  int _eventTotal = 0;
  bool _truncated = false;

  void recordState(DiagnosticsSessionState state) {
    _add(DiagnosticsStateEvent(_elapsedMs, state));
  }

  void recordError(
    DiagnosticsErrorCategory category,
    DiagnosticsErrorCode code,
  ) {
    _add(DiagnosticsErrorEvent(_elapsedMs, category, code));
  }

  void recordReconnect({
    required int attempt,
    required Duration delay,
    required DiagnosticsReconnectOutcome outcome,
    required Duration totalElapsed,
  }) {
    _add(
      DiagnosticsReconnectEvent(
        _elapsedMs,
        attempt: attempt,
        delayMs: delay.inMilliseconds,
        outcome: outcome,
        totalElapsedMs: totalElapsed.inMilliseconds,
      ),
    );
  }

  void recordStats(PeerAggregateStats stats) => _webRtc.add(stats);

  DiagnosticsReport snapshot() => DiagnosticsReport(
    metadata: metadata,
    eventTotal: _eventTotal,
    truncated: _truncated,
    events: _events,
    webRtc: _webRtc.snapshot(),
  );

  int get _elapsedMs => _nowUnixMs().saturatingSubtract(_startedAtUnixMs);

  void _add(DiagnosticsEvent event) {
    _eventTotal += 1;
    if (_events.length == maximumDiagnosticEvents) {
      _events.removeFirst();
      _truncated = true;
    }
    _events.addLast(event);
  }
}

final class PeerStatsRecord {
  PeerStatsRecord({
    required this.id,
    required this.type,
    required this.timestampMs,
    required Map<Object?, Object?> values,
  }) : values = Map<Object?, Object?>.unmodifiable(values);

  final String id;
  final String type;
  final double timestampMs;
  final Map<Object?, Object?> values;
}

final class PeerStatsParser {
  int? _previousBytesReceived;
  double? _previousTimestampMs;

  PeerAggregateStats? parse(Iterable<PeerStatsRecord> reports) {
    final byId = <String, PeerStatsRecord>{
      for (final report in reports) report.id: report,
    };
    PeerStatsRecord? inbound;
    for (final report in byId.values) {
      if (report.type == 'inbound-rtp' &&
          (report.values['kind'] == 'video' ||
              report.values['mediaType'] == 'video')) {
        inbound = report;
        break;
      }
    }
    if (inbound == null) {
      return null;
    }

    final bytesReceived = _nonNegativeInt(inbound.values['bytesReceived']);
    final timestampMs = inbound.timestampMs;
    var bitrate = 0;
    final previousBytes = _previousBytesReceived;
    final previousTimestamp = _previousTimestampMs;
    if (previousBytes != null &&
        previousTimestamp != null &&
        bytesReceived >= previousBytes &&
        timestampMs > previousTimestamp) {
      bitrate =
          (((bytesReceived - previousBytes) * 8000) /
                  (timestampMs - previousTimestamp))
              .round();
    }
    _previousBytesReceived = bytesReceived;
    _previousTimestampMs = timestampMs;

    final selectedPair = _selectedCandidatePair(byId);
    final rttSeconds = _nonNegativeDouble(
      selectedPair?.values['currentRoundTripTime'],
    );
    final codecId = inbound.values['codecId'];
    final codec = codecId is String
        ? _normalizeCodec(byId[codecId]?.values['mimeType'])
        : DiagnosticsVideoCodec.unknown;
    return PeerAggregateStats(
      roundTripTimeMs: (rttSeconds * 1000).round(),
      packetsLost: _nonNegativeInt(inbound.values['packetsLost']),
      packetsReceived: _nonNegativeInt(inbound.values['packetsReceived']),
      bitrateBitsPerSecond: bitrate,
      framesPerSecond: _nonNegativeDouble(
        inbound.values['framesPerSecond'],
      ).round(),
      codec: codec,
      route: _connectionRoute(selectedPair, byId),
    );
  }
}

final class _WebRtcAccumulator {
  var _sampleCount = 0;
  var _rttTotal = 0;
  var _bitrateTotal = 0;
  var _latest = const PeerAggregateStats(
    roundTripTimeMs: 0,
    packetsLost: 0,
    packetsReceived: 0,
    bitrateBitsPerSecond: 0,
    framesPerSecond: 0,
    codec: DiagnosticsVideoCodec.unknown,
    route: DiagnosticsConnectionRoute.unknown,
  );

  void add(PeerAggregateStats stats) {
    _sampleCount += 1;
    _rttTotal += stats.roundTripTimeMs;
    _bitrateTotal += stats.bitrateBitsPerSecond;
    _latest = stats;
  }

  DiagnosticsWebRtcSummary snapshot() {
    final packetTotal = _latest.packetsLost + _latest.packetsReceived;
    final lossRatio = packetTotal == 0
        ? 0.0
        : _latest.packetsLost / packetTotal;
    return DiagnosticsWebRtcSummary(
      sampleCount: _sampleCount,
      currentRttMs: _latest.roundTripTimeMs,
      averageRttMs: _sampleCount == 0 ? 0 : (_rttTotal / _sampleCount).round(),
      packetsLost: _latest.packetsLost,
      packetsReceived: _latest.packetsReceived,
      lossRatio: lossRatio,
      currentBitrateBitsPerSecond: _latest.bitrateBitsPerSecond,
      averageBitrateBitsPerSecond: _sampleCount == 0
          ? 0
          : (_bitrateTotal / _sampleCount).round(),
      framesPerSecond: _latest.framesPerSecond,
      codec: _latest.codec,
      route: _latest.route,
    );
  }
}

PeerStatsRecord? _selectedCandidatePair(Map<String, PeerStatsRecord> byId) {
  for (final report in byId.values) {
    if (report.type != 'transport') continue;
    final pairId = report.values['selectedCandidatePairId'];
    if (pairId is String && byId[pairId]?.type == 'candidate-pair') {
      return byId[pairId];
    }
  }
  for (final report in byId.values) {
    if (report.type == 'candidate-pair' &&
        (report.values['nominated'] == true ||
            report.values['selected'] == true)) {
      return report;
    }
  }
  return null;
}

DiagnosticsConnectionRoute _connectionRoute(
  PeerStatsRecord? pair,
  Map<String, PeerStatsRecord> byId,
) {
  if (pair == null) return DiagnosticsConnectionRoute.unknown;
  final localId = pair.values['localCandidateId'];
  final remoteId = pair.values['remoteCandidateId'];
  final localType = localId is String
      ? byId[localId]?.values['candidateType']
      : null;
  final remoteType = remoteId is String
      ? byId[remoteId]?.values['candidateType']
      : null;
  if (localType == 'relay' || remoteType == 'relay') {
    return DiagnosticsConnectionRoute.relay;
  }
  if (localType is String || remoteType is String) {
    return DiagnosticsConnectionRoute.direct;
  }
  return DiagnosticsConnectionRoute.unknown;
}

DiagnosticsVideoCodec _normalizeCodec(Object? value) {
  final mimeType = value is String ? value.toLowerCase() : '';
  return switch (mimeType) {
    'video/h264' => DiagnosticsVideoCodec.h264,
    'video/vp8' => DiagnosticsVideoCodec.vp8,
    'video/av1' || 'video/av1x' => DiagnosticsVideoCodec.av1,
    _ => DiagnosticsVideoCodec.unknown,
  };
}

int _nonNegativeInt(Object? value) {
  if (value is num && value.isFinite && value >= 0) {
    return value.toInt();
  }
  return 0;
}

double _nonNegativeDouble(Object? value) {
  if (value is num && value.isFinite && value >= 0) {
    return value.toDouble();
  }
  return 0;
}

extension on int {
  int saturatingSubtract(int other) => this >= other ? this - other : 0;
}
