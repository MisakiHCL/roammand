// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/diagnostics/diagnostics_collector.dart';
import 'package:roammand/diagnostics/diagnostics_model.dart';

const _secretKey = 'private_key_SENTINEL_9247';
const _secretValue = 'candidate_or_typed_text_SENTINEL_4813';

void main() {
  test('keeps a typed 128-event ring and emits only schema fields', () {
    var now = 1000;
    final collector = DiagnosticsCollector(
      metadata: const DiagnosticsMetadata(
        appVersion: '7.0.0-test',
        protocolMajor: 1,
        protocolMinor: 0,
        osFamily: DiagnosticsOsFamily.macos,
      ),
      nowUnixMs: () => now,
    );

    for (var index = 0; index < 130; index += 1) {
      now += 10;
      collector.recordState(DiagnosticsSessionState.reconnecting);
    }
    collector.recordError(
      DiagnosticsErrorCategory.peer,
      DiagnosticsErrorCode.iceFailed,
    );
    collector.recordReconnect(
      attempt: 5,
      delay: const Duration(seconds: 15),
      outcome: DiagnosticsReconnectOutcome.exhausted,
      totalElapsed: const Duration(seconds: 30),
    );
    collector.recordStats(
      const PeerAggregateStats(
        roundTripTimeMs: 48,
        packetsLost: 2,
        packetsReceived: 198,
        bitrateBitsPerSecond: 800000,
        framesPerSecond: 30,
        codec: DiagnosticsVideoCodec.h264,
        route: DiagnosticsConnectionRoute.relay,
      ),
    );
    collector.recordStats(
      const PeerAggregateStats(
        roundTripTimeMs: 52,
        packetsLost: 3,
        packetsReceived: 297,
        bitrateBitsPerSecond: 1000000,
        framesPerSecond: 28,
        codec: DiagnosticsVideoCodec.h264,
        route: DiagnosticsConnectionRoute.relay,
      ),
    );

    final encoded = collector.snapshot().encodeJson();
    final decoded = jsonDecode(encoded) as Map<String, dynamic>;
    expect(decoded.keys.toSet(), <String>{
      'schema',
      'app_version',
      'protocol',
      'os_family',
      'capture',
      'events',
      'webrtc',
      'included',
      'excluded',
    });
    expect(decoded['schema'], 'roammand-diagnostics/v1');
    expect(decoded['app_version'], '7.0.0-test');
    expect(decoded['protocol'], <String, dynamic>{'major': 1, 'minor': 0});
    expect(decoded['os_family'], 'macos');
    expect(decoded['capture'], <String, dynamic>{
      'event_total': 132,
      'event_count': 128,
      'truncated': true,
    });
    expect((decoded['events'] as List<dynamic>), hasLength(128));
    expect(decoded['webrtc'], <String, dynamic>{
      'sample_count': 2,
      'current_rtt_ms': 52,
      'average_rtt_ms': 50,
      'packets_lost': 3,
      'packets_received': 297,
      'loss_ratio': 0.01,
      'current_bitrate_bps': 1000000,
      'average_bitrate_bps': 900000,
      'frames_per_second': 28,
      'codec': 'h264',
      'route': 'relay',
    });
    expect(decoded['included'], contains('aggregate_webrtc_metrics'));
    expect(decoded['excluded'], contains('input_content_and_coordinates'));
  });

  test('raw stats parser drops unknown keys, IDs, addresses and values', () {
    final parser = PeerStatsParser();
    parser.parse(<PeerStatsRecord>[
      PeerStatsRecord(
        id: '$_secretValue-inbound',
        type: 'inbound-rtp',
        timestampMs: 1000,
        values: <Object?, Object?>{
          'kind': 'video',
          'bytesReceived': 1000,
          'packetsLost': 1,
          'packetsReceived': 99,
          'framesPerSecond': 30,
          'codecId': '$_secretValue-codec',
          _secretKey: _secretValue,
        },
      ),
      PeerStatsRecord(
        id: '$_secretValue-codec',
        type: 'codec',
        timestampMs: 1000,
        values: <Object?, Object?>{'mimeType': 'video/H264'},
      ),
    ]);
    final sample = parser.parse(<PeerStatsRecord>[
      PeerStatsRecord(
        id: '$_secretValue-inbound',
        type: 'inbound-rtp',
        timestampMs: 2000,
        values: <Object?, Object?>{
          'kind': 'video',
          'bytesReceived': 101000,
          'packetsLost': 2,
          'packetsReceived': 198,
          'framesPerSecond': 29,
          'codecId': '$_secretValue-codec',
          _secretKey: _secretValue,
        },
      ),
      PeerStatsRecord(
        id: '$_secretValue-codec',
        type: 'codec',
        timestampMs: 2000,
        values: <Object?, Object?>{'mimeType': 'video/H264'},
      ),
      PeerStatsRecord(
        id: '$_secretValue-transport',
        type: 'transport',
        timestampMs: 2000,
        values: <Object?, Object?>{
          'selectedCandidatePairId': '$_secretValue-pair',
        },
      ),
      PeerStatsRecord(
        id: '$_secretValue-pair',
        type: 'candidate-pair',
        timestampMs: 2000,
        values: <Object?, Object?>{
          'currentRoundTripTime': 0.05,
          'localCandidateId': '$_secretValue-local',
          'remoteCandidateId': '$_secretValue-remote',
          'remoteAddress': _secretValue,
        },
      ),
      PeerStatsRecord(
        id: '$_secretValue-local',
        type: 'local-candidate',
        timestampMs: 2000,
        values: <Object?, Object?>{
          'candidateType': 'relay',
          'address': _secretValue,
        },
      ),
    ]);

    expect(sample, isNotNull);
    expect(sample!.bitrateBitsPerSecond, 800000);
    expect(sample.roundTripTimeMs, 50);
    expect(sample.codec, DiagnosticsVideoCodec.h264);
    expect(sample.route, DiagnosticsConnectionRoute.relay);

    final collector = DiagnosticsCollector(
      metadata: const DiagnosticsMetadata(
        appVersion: 'test',
        protocolMajor: 1,
        protocolMinor: 0,
        osFamily: DiagnosticsOsFamily.android,
      ),
      nowUnixMs: () => 2000,
    )..recordStats(sample);
    final encoded = collector.snapshot().encodeJson();
    expect(encoded, isNot(contains(_secretKey)));
    expect(encoded, isNot(contains(_secretValue)));
    expect(encoded, isNot(contains('remoteAddress')));
    expect(encoded, isNot(contains('candidate-pair')));
  });
}
