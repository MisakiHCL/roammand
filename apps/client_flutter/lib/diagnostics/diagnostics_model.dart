// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';

const diagnosticsSchema = 'roammand-diagnostics/v1';
const maximumDiagnosticEvents = 128;
const maximumDiagnosticsFileBytes = 262144;

const diagnosticsIncludedFields = <String>[
  'app_protocol_and_os_versions',
  'session_state_and_stable_errors',
  'reconnect_attempts_and_timing',
  'aggregate_webrtc_metrics',
];

const diagnosticsExcludedFields = <String>[
  'device_identifiers',
  'device_names',
  'keys_and_signatures',
  'nonces_tokens_and_passwords',
  'sdp_and_ice_candidates',
  'ip_addresses_and_ports',
  'input_content_and_coordinates',
  'screen_content',
  'raw_signaling_and_data_channel_payloads',
  'raw_webrtc_stats',
];

enum DiagnosticsOsFamily { android, ios, linux, macos, windows, unknown }

enum DiagnosticsSessionState {
  idle,
  connecting,
  authenticating,
  negotiating,
  connected,
  reconnecting,
  closing,
  failed,
}

enum DiagnosticsErrorCategory {
  configuration,
  localIdentity,
  signaling,
  authentication,
  peer,
  remote,
}

enum DiagnosticsErrorCode {
  configuration,
  identityUnavailable,
  signalingUnavailable,
  authenticationFailed,
  iceFailed,
  remoteFailed,
}

enum DiagnosticsReconnectOutcome { scheduled, attempted, recovered, exhausted }

enum DiagnosticsVideoCodec { h264, vp8, av1, unknown }

enum DiagnosticsConnectionRoute { direct, relay, unknown }

final class DiagnosticsMetadata {
  const DiagnosticsMetadata({
    required this.appVersion,
    required this.protocolMajor,
    required this.protocolMinor,
    required this.osFamily,
  });

  final String appVersion;
  final int protocolMajor;
  final int protocolMinor;
  final DiagnosticsOsFamily osFamily;
}

final class PeerAggregateStats {
  const PeerAggregateStats({
    required this.roundTripTimeMs,
    required this.packetsLost,
    required this.packetsReceived,
    required this.bitrateBitsPerSecond,
    required this.framesPerSecond,
    required this.codec,
    required this.route,
  });

  final int roundTripTimeMs;
  final int packetsLost;
  final int packetsReceived;
  final int bitrateBitsPerSecond;
  final int framesPerSecond;
  final DiagnosticsVideoCodec codec;
  final DiagnosticsConnectionRoute route;
}

sealed class DiagnosticsEvent {
  const DiagnosticsEvent(this.elapsedMs);

  final int elapsedMs;

  Map<String, Object> toJson();
}

final class DiagnosticsStateEvent extends DiagnosticsEvent {
  const DiagnosticsStateEvent(super.elapsedMs, this.state);

  final DiagnosticsSessionState state;

  @override
  Map<String, Object> toJson() => <String, Object>{
    'type': 'state',
    'elapsed_ms': elapsedMs,
    'state': state.name,
  };
}

final class DiagnosticsErrorEvent extends DiagnosticsEvent {
  const DiagnosticsErrorEvent(super.elapsedMs, this.category, this.code);

  final DiagnosticsErrorCategory category;
  final DiagnosticsErrorCode code;

  @override
  Map<String, Object> toJson() => <String, Object>{
    'type': 'error',
    'elapsed_ms': elapsedMs,
    'category': category.name,
    'code': code.name,
  };
}

final class DiagnosticsReconnectEvent extends DiagnosticsEvent {
  const DiagnosticsReconnectEvent(
    super.elapsedMs, {
    required this.attempt,
    required this.delayMs,
    required this.outcome,
    required this.totalElapsedMs,
  });

  final int attempt;
  final int delayMs;
  final DiagnosticsReconnectOutcome outcome;
  final int totalElapsedMs;

  @override
  Map<String, Object> toJson() => <String, Object>{
    'type': 'reconnect',
    'elapsed_ms': elapsedMs,
    'attempt': attempt,
    'delay_ms': delayMs,
    'outcome': outcome.name,
    'total_elapsed_ms': totalElapsedMs,
  };
}

final class DiagnosticsWebRtcSummary {
  const DiagnosticsWebRtcSummary({
    required this.sampleCount,
    required this.currentRttMs,
    required this.averageRttMs,
    required this.packetsLost,
    required this.packetsReceived,
    required this.lossRatio,
    required this.currentBitrateBitsPerSecond,
    required this.averageBitrateBitsPerSecond,
    required this.framesPerSecond,
    required this.codec,
    required this.route,
  });

  final int sampleCount;
  final int currentRttMs;
  final int averageRttMs;
  final int packetsLost;
  final int packetsReceived;
  final double lossRatio;
  final int currentBitrateBitsPerSecond;
  final int averageBitrateBitsPerSecond;
  final int framesPerSecond;
  final DiagnosticsVideoCodec codec;
  final DiagnosticsConnectionRoute route;

  Map<String, Object> toJson() => <String, Object>{
    'sample_count': sampleCount,
    'current_rtt_ms': currentRttMs,
    'average_rtt_ms': averageRttMs,
    'packets_lost': packetsLost,
    'packets_received': packetsReceived,
    'loss_ratio': lossRatio,
    'current_bitrate_bps': currentBitrateBitsPerSecond,
    'average_bitrate_bps': averageBitrateBitsPerSecond,
    'frames_per_second': framesPerSecond,
    'codec': codec.name,
    'route': route.name,
  };
}

final class DiagnosticsReport {
  DiagnosticsReport({
    required this.metadata,
    required this.eventTotal,
    required this.truncated,
    required Iterable<DiagnosticsEvent> events,
    required this.webRtc,
  }) : events = List<DiagnosticsEvent>.unmodifiable(events);

  final DiagnosticsMetadata metadata;
  final int eventTotal;
  final bool truncated;
  final List<DiagnosticsEvent> events;
  final DiagnosticsWebRtcSummary webRtc;

  Map<String, Object> toJson() => <String, Object>{
    'schema': diagnosticsSchema,
    'app_version': metadata.appVersion,
    'protocol': <String, Object>{
      'major': metadata.protocolMajor,
      'minor': metadata.protocolMinor,
    },
    'os_family': metadata.osFamily.name,
    'capture': <String, Object>{
      'event_total': eventTotal,
      'event_count': events.length,
      'truncated': truncated,
    },
    'events': events.map((event) => event.toJson()).toList(growable: false),
    'webrtc': webRtc.toJson(),
    'included': diagnosticsIncludedFields,
    'excluded': diagnosticsExcludedFields,
  };

  String encodeJson() => jsonEncode(toJson());
}
