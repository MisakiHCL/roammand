// SPDX-License-Identifier: MPL-2.0

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

import '../../diagnostics/diagnostics_collector.dart';
import '../../diagnostics/diagnostics_model.dart';
import 'input_sender.dart';
import 'session_authenticator.dart';

const reliableInputChannelLabel = 'input.reliable';
const fastPointerChannelLabel = 'pointer.fast';
const _maximumIceServers = 8;
const _maximumIceUrlsPerServer = 8;
const _maximumIceUrlBytes = 2048;
const _maximumIceCredentialBytes = 1024;
const _videoMediaKind = 'video';
const _localMediaStreamOwnerTag = 'local';
const _receiveVideoOfferConstraints = <String, dynamic>{
  'mandatory': <String, dynamic>{
    'OfferToReceiveVideo': true,
    'OfferToReceiveAudio': false,
  },
  'optional': <Map<String, dynamic>>[],
};

enum DesktopIceTransportPolicy { all, relay }

final class DesktopIceServer {
  const DesktopIceServer({
    required this.urls,
    this.username = '',
    this.credential = '',
  });

  final List<String> urls;
  final String username;
  final String credential;

  void validate() {
    if (urls.isEmpty || urls.length > _maximumIceUrlsPerServer) {
      throw const PeerSessionException(PeerSessionErrorCode.configuration);
    }
    for (final value in urls) {
      final uri = Uri.tryParse(value);
      if (uri == null ||
          value.length > _maximumIceUrlBytes ||
          !const <String>{
            'stun',
            'stuns',
            'turn',
            'turns',
          }.contains(uri.scheme)) {
        throw const PeerSessionException(PeerSessionErrorCode.configuration);
      }
    }
    if (username.length > _maximumIceCredentialBytes ||
        credential.length > _maximumIceCredentialBytes) {
      throw const PeerSessionException(PeerSessionErrorCode.configuration);
    }
    final hasTurn = urls.any(
      (value) => value.startsWith('turn:') || value.startsWith('turns:'),
    );
    if (hasTurn && (username.isEmpty || credential.isEmpty)) {
      throw const PeerSessionException(PeerSessionErrorCode.configuration);
    }
  }
}

final class DesktopDataChannelConfiguration {
  const DesktopDataChannelConfiguration({
    required this.label,
    required this.ordered,
    this.maxRetransmits,
  });

  final String label;
  final bool ordered;
  final int? maxRetransmits;
}

final class ControllerPeerConfiguration {
  const ControllerPeerConfiguration({
    this.iceTransportPolicy = DesktopIceTransportPolicy.all,
    this.iceServers = const <DesktopIceServer>[],
    this.videoCodecPreference = const <String>['H264', 'VP8'],
    this.reliableChannel = const DesktopDataChannelConfiguration(
      label: reliableInputChannelLabel,
      ordered: true,
    ),
    this.fastChannel = const DesktopDataChannelConfiguration(
      label: fastPointerChannelLabel,
      ordered: false,
      maxRetransmits: 0,
    ),
  });

  final DesktopIceTransportPolicy iceTransportPolicy;
  final List<DesktopIceServer> iceServers;
  final List<String> videoCodecPreference;
  final DesktopDataChannelConfiguration reliableChannel;
  final DesktopDataChannelConfiguration fastChannel;

  void validate() {
    if (iceServers.length > _maximumIceServers ||
        videoCodecPreference.length != 2 ||
        videoCodecPreference[0].toUpperCase() != 'H264' ||
        videoCodecPreference[1].toUpperCase() != 'VP8' ||
        reliableChannel.label != reliableInputChannelLabel ||
        !reliableChannel.ordered ||
        reliableChannel.maxRetransmits != null ||
        fastChannel.label != fastPointerChannelLabel ||
        fastChannel.ordered ||
        fastChannel.maxRetransmits != 0) {
      throw const PeerSessionException(PeerSessionErrorCode.configuration);
    }
    for (final server in iceServers) {
      server.validate();
    }
    if (iceTransportPolicy == DesktopIceTransportPolicy.relay &&
        !iceServers.any(
          (server) => server.urls.any(
            (url) => url.startsWith('turn:') || url.startsWith('turns:'),
          ),
        )) {
      throw const PeerSessionException(PeerSessionErrorCode.configuration);
    }
  }
}

final class ControllerPeerOffer {
  ControllerPeerOffer({
    required this.sdp,
    required List<int> dtlsFingerprintSha256,
  }) : dtlsFingerprintSha256 = Uint8List.fromList(dtlsFingerprintSha256);

  final String sdp;
  final Uint8List dtlsFingerprintSha256;
}

enum ControllerPeerEvent { connected, disconnected, failed }

final class ControllerPeerCallbacks {
  const ControllerPeerCallbacks({
    required this.onLocalCandidate,
    required this.onEvent,
  });

  final void Function(IceCandidate candidate) onLocalCandidate;
  final void Function(ControllerPeerEvent event) onEvent;
}

abstract interface class ControllerPeerAdapter {
  Object get renderer;

  int get fastBufferedAmount;

  Future<ControllerPeerOffer> initialize(
    ControllerPeerConfiguration configuration,
    ControllerPeerCallbacks callbacks,
  );

  Future<ControllerPeerOffer> restartIce();

  Future<void> setRemoteAnswer(String sdp);

  Future<void> addRemoteCandidate(IceCandidate candidate);

  Future<void> sendReliable(Uint8List bytes);

  Future<void> sendFast(Uint8List bytes);

  Future<void> close();
}

abstract interface class ControllerPeerStatsProvider {
  Future<PeerAggregateStats?> getAggregateStats();
}

enum ControllerPeerState {
  idle,
  starting,
  awaitingVerifiedAnswer,
  connecting,
  connected,
  reconnecting,
  failed,
  closed,
}

enum PeerSessionErrorCode { configuration, state, candidateLimit, peer, closed }

final class PeerSessionException implements Exception {
  const PeerSessionException(this.code);

  final PeerSessionErrorCode code;

  @override
  String toString() => 'PeerSessionException(${code.name})';
}

final class ControllerPeerSession {
  ControllerPeerSession({required this.adapter, required this.configuration});

  factory ControllerPeerSession.production({
    required ControllerPeerConfiguration configuration,
  }) => ControllerPeerSession(
    adapter: FlutterWebRtcPeerAdapter(),
    configuration: configuration,
  );

  final ControllerPeerAdapter adapter;
  final ControllerPeerConfiguration configuration;
  final PendingIceCandidates _pendingCandidates = PendingIceCandidates();
  final StreamController<ControllerPeerEvent> _events =
      StreamController<ControllerPeerEvent>.broadcast();
  ControllerPeerState _state = ControllerPeerState.idle;
  bool _answerApplied = false;
  bool _answerApplicationInFlight = false;
  bool _closed = false;

  ControllerPeerState get state => _state;
  Object get videoRenderer => adapter.renderer;
  Stream<ControllerPeerEvent> get events => _events.stream;
  InputDataChannel get reliableInput => _PeerInputChannel(adapter, true);
  InputDataChannel get fastInput => _PeerInputChannel(adapter, false);

  Future<PeerAggregateStats?> getAggregateStats() {
    if (adapter case final ControllerPeerStatsProvider provider) {
      return provider.getAggregateStats();
    }
    return Future<PeerAggregateStats?>.value();
  }

  Future<ControllerPeerOffer> start() async {
    if (_state != ControllerPeerState.idle) {
      throw const PeerSessionException(PeerSessionErrorCode.state);
    }
    configuration.validate();
    _state = ControllerPeerState.starting;
    try {
      final offer = await adapter.initialize(
        configuration,
        ControllerPeerCallbacks(
          onLocalCandidate: _onLocalCandidate,
          onEvent: _onPeerEvent,
        ),
      );
      if (_closed) {
        throw const PeerSessionException(PeerSessionErrorCode.closed);
      }
      if (offer.sdp.isEmpty || offer.dtlsFingerprintSha256.length != 32) {
        throw const PeerSessionException(PeerSessionErrorCode.peer);
      }
      _state = ControllerPeerState.awaitingVerifiedAnswer;
      return offer;
    } on PeerSessionException {
      await _failAndClose();
      rethrow;
    } catch (_) {
      await _failAndClose();
      throw const PeerSessionException(PeerSessionErrorCode.peer);
    }
  }

  Future<void> applyVerifiedAnswer(String sdp) async {
    if (_closed ||
        _state != ControllerPeerState.awaitingVerifiedAnswer ||
        _answerApplicationInFlight) {
      throw const PeerSessionException(PeerSessionErrorCode.state);
    }
    _answerApplicationInFlight = true;
    try {
      await adapter.setRemoteAnswer(sdp);
      _requireOpen();
      _answerApplied = true;
      for (final candidate in _pendingCandidates.drain()) {
        await adapter.addRemoteCandidate(candidate);
        _requireOpen();
      }
      _state = ControllerPeerState.connecting;
    } on PeerSessionException catch (error) {
      if (_closed || error.code == PeerSessionErrorCode.closed) {
        throw const PeerSessionException(PeerSessionErrorCode.closed);
      }
      await _handleAnswerFailure();
      throw const PeerSessionException(PeerSessionErrorCode.peer);
    } catch (_) {
      if (_closed) {
        throw const PeerSessionException(PeerSessionErrorCode.closed);
      }
      await _handleAnswerFailure();
      throw const PeerSessionException(PeerSessionErrorCode.peer);
    } finally {
      _answerApplicationInFlight = false;
    }
  }

  Future<void> _handleAnswerFailure() async {
    if (_restarting) {
      _pendingCandidates.drain();
      _answerApplied = false;
      _state = ControllerPeerState.reconnecting;
    } else {
      await _failAndClose();
    }
  }

  bool _restarting = false;

  Future<ControllerPeerOffer> restartIce() async {
    if (_closed ||
        _answerApplicationInFlight ||
        (_state != ControllerPeerState.connected &&
            _state != ControllerPeerState.connecting &&
            _state != ControllerPeerState.awaitingVerifiedAnswer &&
            _state != ControllerPeerState.reconnecting)) {
      throw const PeerSessionException(PeerSessionErrorCode.state);
    }
    _pendingCandidates.drain();
    _answerApplied = false;
    _state = ControllerPeerState.reconnecting;
    _restarting = true;
    try {
      final offer = await adapter.restartIce();
      _requireOpen();
      if (offer.sdp.isEmpty || offer.dtlsFingerprintSha256.length != 32) {
        throw const PeerSessionException(PeerSessionErrorCode.peer);
      }
      _state = ControllerPeerState.awaitingVerifiedAnswer;
      return offer;
    } on PeerSessionException catch (error) {
      if (_closed || error.code == PeerSessionErrorCode.closed) {
        throw const PeerSessionException(PeerSessionErrorCode.closed);
      }
      _state = ControllerPeerState.reconnecting;
      throw const PeerSessionException(PeerSessionErrorCode.peer);
    } catch (_) {
      if (_closed) {
        throw const PeerSessionException(PeerSessionErrorCode.closed);
      }
      _state = ControllerPeerState.reconnecting;
      throw const PeerSessionException(PeerSessionErrorCode.peer);
    }
  }

  Future<void> addRemoteCandidate(IceCandidate candidate) async {
    if (_closed ||
        (_state != ControllerPeerState.awaitingVerifiedAnswer &&
            _state != ControllerPeerState.connecting &&
            _state != ControllerPeerState.connected)) {
      throw const PeerSessionException(PeerSessionErrorCode.state);
    }
    if (!_answerApplied) {
      try {
        _pendingCandidates.add(candidate);
      } on PendingIceLimitException {
        throw const PeerSessionException(PeerSessionErrorCode.candidateLimit);
      }
      return;
    }
    try {
      await adapter.addRemoteCandidate(candidate);
    } catch (_) {
      await _failAndClose();
      throw const PeerSessionException(PeerSessionErrorCode.peer);
    }
  }

  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _answerApplicationInFlight = false;
    _restarting = false;
    _pendingCandidates.drain();
    try {
      await adapter.close();
    } catch (_) {
      // Closing event streams must not depend on a native cleanup succeeding.
    }
    _state = ControllerPeerState.closed;
    await _localCandidateController.close();
    await _events.close();
  }

  void _requireOpen() {
    if (_closed) {
      throw const PeerSessionException(PeerSessionErrorCode.closed);
    }
  }

  void _onLocalCandidate(IceCandidate candidate) {
    if (!_closed) {
      _localCandidateController.add(candidate.deepCopy());
    }
  }

  final StreamController<IceCandidate> _localCandidateController =
      StreamController<IceCandidate>.broadcast();

  Stream<IceCandidate> get localCandidates => _localCandidateController.stream;

  void _onPeerEvent(ControllerPeerEvent event) {
    if (_closed) {
      return;
    }
    switch (event) {
      case ControllerPeerEvent.connected:
        _state = ControllerPeerState.connected;
        _restarting = false;
      case ControllerPeerEvent.disconnected:
      case ControllerPeerEvent.failed:
        _state = ControllerPeerState.reconnecting;
    }
    _events.add(event);
  }

  Future<void> _failAndClose() async {
    if (_closed) {
      return;
    }
    _state = ControllerPeerState.failed;
    _closed = true;
    _pendingCandidates.drain();
    try {
      await adapter.close();
    } catch (_) {
      // Preserve the stable peer failure while still releasing Dart streams.
    }
    await _localCandidateController.close();
    await _events.close();
  }
}

final class _PeerInputChannel implements InputDataChannel {
  const _PeerInputChannel(this._adapter, this._reliable);

  final ControllerPeerAdapter _adapter;
  final bool _reliable;

  @override
  int get bufferedAmount => _reliable ? 0 : _adapter.fastBufferedAmount;

  @override
  Future<void> send(Uint8List bytes) =>
      _reliable ? _adapter.sendReliable(bytes) : _adapter.sendFast(bytes);
}

final class FlutterWebRtcPeerAdapter
    implements ControllerPeerAdapter, ControllerPeerStatsProvider {
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  final PeerStatsParser _statsParser = PeerStatsParser();
  RTCPeerConnection? _peer;
  RTCDataChannel? _reliable;
  RTCDataChannel? _fast;
  MediaStream? _ownedRemoteVideoStream;
  Future<void>? _rendererInitialization;
  Future<void>? _closeFuture;
  final Set<Future<void>> _videoBindingTasks = <Future<void>>{};
  bool _closed = false;
  bool _peerConnected = false;
  bool _reportedConnected = false;
  bool _transportFailureReported = false;

  @override
  Object get renderer => _renderer;

  @override
  int get fastBufferedAmount => _fast?.bufferedAmount ?? 0;

  @override
  Future<ControllerPeerOffer> initialize(
    ControllerPeerConfiguration configuration,
    ControllerPeerCallbacks callbacks,
  ) async {
    if (_peer != null || _closed) {
      throw const PeerSessionException(PeerSessionErrorCode.state);
    }
    configuration.validate();
    var operation = _PeerDebugOperation.initializeRenderer;
    try {
      final rendererInitialization = _renderer.initialize();
      _rendererInitialization = rendererInitialization;
      try {
        await rendererInitialization;
      } finally {
        if (identical(_rendererInitialization, rendererInitialization)) {
          _rendererInitialization = null;
        }
      }
      if (_closed) {
        throw const PeerSessionException(PeerSessionErrorCode.closed);
      }
      operation = _PeerDebugOperation.createPeerConnection;
      final peer = await createPeerConnection(
        <String, dynamic>{
          'sdpSemantics': 'unified-plan',
          'iceTransportPolicy': configuration.iceTransportPolicy.name,
          'iceServers': configuration.iceServers
              .map(
                (server) => <String, dynamic>{
                  'urls': server.urls,
                  if (server.username.isNotEmpty) 'username': server.username,
                  if (server.credential.isNotEmpty)
                    'credential': server.credential,
                },
              )
              .toList(growable: false),
        },
        const <String, dynamic>{
          'mandatory': <String, dynamic>{},
          'optional': <Map<String, dynamic>>[],
        },
      );
      if (_closed) {
        await _closeUnownedPeer(peer);
        throw const PeerSessionException(PeerSessionErrorCode.closed);
      }
      _peer = peer;
      peer.onIceCandidate = (candidate) {
        final value = candidate.candidate;
        if (!_closed && value != null && value.isNotEmpty) {
          callbacks.onLocalCandidate(
            IceCandidate(
              candidate: value,
              sdpMid: candidate.sdpMid ?? '',
              sdpMLineIndex: candidate.sdpMLineIndex ?? 0,
            ),
          );
        }
      };
      peer.onConnectionState = (state) {
        switch (state) {
          case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
            _peerConnected = true;
            _reportConnectedWhenReady(callbacks);
          case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
            _peerConnected = false;
            _reportTransportFailure(
              callbacks,
              ControllerPeerEvent.disconnected,
            );
          case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
            _peerConnected = false;
            _reportTransportFailure(callbacks, ControllerPeerEvent.failed);
          case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
            _peerConnected = false;
            _reportedConnected = false;
          case RTCPeerConnectionState.RTCPeerConnectionStateNew:
          case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
            break;
        }
      };
      peer.onTrack = (event) {
        if (!_closed && event.track.kind == _videoMediaKind) {
          _startRemoteVideoBinding(event);
        }
      };

      operation = _PeerDebugOperation.addVideoTransceiver;
      final video = await peer.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
      _throwIfClosed();
      operation = _PeerDebugOperation.readVideoCapabilities;
      final capabilities = await getRtpReceiverCapabilities('video');
      _throwIfClosed();
      final codecs = _preferCodecCapabilities(
        capabilities.codecs ?? const <RTCRtpCodecCapability>[],
        configuration.videoCodecPreference,
      );
      if (codecs.isNotEmpty) {
        operation = _PeerDebugOperation.setVideoCodecs;
        await video.setCodecPreferences(codecs);
        _throwIfClosed();
      }

      operation = _PeerDebugOperation.createReliableDataChannel;
      final reliable = await peer.createDataChannel(
        configuration.reliableChannel.label,
        _ExactDataChannelInit(
          ordered: configuration.reliableChannel.ordered,
          maxRetransmits: configuration.reliableChannel.maxRetransmits,
        ),
      );
      if (_closed) {
        await _closeUnownedChannel(reliable);
        throw const PeerSessionException(PeerSessionErrorCode.closed);
      }
      _reliable = reliable;
      operation = _PeerDebugOperation.createFastDataChannel;
      final fast = await peer.createDataChannel(
        configuration.fastChannel.label,
        _ExactDataChannelInit(
          ordered: configuration.fastChannel.ordered,
          maxRetransmits: configuration.fastChannel.maxRetransmits,
        ),
      );
      if (_closed) {
        await _closeUnownedChannel(fast);
        throw const PeerSessionException(PeerSessionErrorCode.closed);
      }
      _fast = fast;
      _observeInputChannel(_reliable!, callbacks);
      _observeInputChannel(_fast!, callbacks);
      operation = _PeerDebugOperation.createOffer;
      final created = await peer.createOffer(_receiveVideoOfferConstraints);
      _throwIfClosed();
      final preferredSdp = preferDesktopVideoCodecs(created.sdp ?? '');
      if (preferredSdp.isEmpty) {
        throw const PeerSessionException(PeerSessionErrorCode.peer);
      }
      operation = _PeerDebugOperation.setLocalDescription;
      await peer.setLocalDescription(
        RTCSessionDescription(preferredSdp, 'offer'),
      );
      _throwIfClosed();
      return ControllerPeerOffer(
        sdp: preferredSdp,
        dtlsFingerprintSha256: extractSha256DtlsFingerprint(preferredSdp),
      );
    } catch (error) {
      _debugPeerFailure(operation, error);
      await close();
      rethrow;
    }
  }

  @override
  Future<void> setRemoteAnswer(String sdp) async {
    final peer = _peer;
    if (_closed || peer == null) {
      throw const PeerSessionException(PeerSessionErrorCode.closed);
    }
    try {
      await peer.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
    } catch (error) {
      _debugPeerFailure(_PeerDebugOperation.setRemoteAnswer, error);
      rethrow;
    }
  }

  @override
  Future<ControllerPeerOffer> restartIce() async {
    final peer = _peer;
    if (_closed || peer == null) {
      throw const PeerSessionException(PeerSessionErrorCode.closed);
    }
    await peer.restartIce();
    final created = await peer.createOffer(_receiveVideoOfferConstraints);
    final preferredSdp = preferDesktopVideoCodecs(created.sdp ?? '');
    if (preferredSdp.isEmpty) {
      throw const PeerSessionException(PeerSessionErrorCode.peer);
    }
    await peer.setLocalDescription(
      RTCSessionDescription(preferredSdp, 'offer'),
    );
    return ControllerPeerOffer(
      sdp: preferredSdp,
      dtlsFingerprintSha256: extractSha256DtlsFingerprint(preferredSdp),
    );
  }

  @override
  Future<void> addRemoteCandidate(IceCandidate candidate) async {
    final peer = _peer;
    if (_closed || peer == null) {
      throw const PeerSessionException(PeerSessionErrorCode.closed);
    }
    try {
      await peer.addCandidate(
        RTCIceCandidate(
          candidate.candidate,
          candidate.sdpMid,
          candidate.sdpMLineIndex,
        ),
      );
    } catch (error) {
      _debugPeerFailure(_PeerDebugOperation.addRemoteCandidate, error);
      rethrow;
    }
  }

  @override
  Future<void> sendReliable(Uint8List bytes) => _send(_reliable, bytes);

  @override
  Future<void> sendFast(Uint8List bytes) => _send(_fast, bytes);

  @override
  Future<PeerAggregateStats?> getAggregateStats() async {
    final peer = _peer;
    if (_closed || peer == null) {
      return null;
    }
    final reports = await peer.getStats();
    return _statsParser.parse(
      reports.map(
        (report) => PeerStatsRecord(
          id: report.id,
          type: report.type,
          timestampMs: report.timestamp / 1000,
          values: Map<Object?, Object?>.from(report.values),
        ),
      ),
    );
  }

  Future<void> _bindRemoteVideoTrack(RTCTrackEvent event) async {
    final hasRemoteStream = event.streams.isNotEmpty;
    MediaStream? ownedStream;
    try {
      final MediaStream stream;
      if (hasRemoteStream) {
        stream = event.streams.first;
      } else {
        // Unified Plan permits onTrack without an associated MediaStream. The
        // native renderer still needs a stream container to attach the track.
        ownedStream = await createLocalMediaStream(_localMediaStreamOwnerTag);
        await ownedStream.addTrack(event.track);
        stream = ownedStream;
      }
      if (_closed) {
        await ownedStream?.dispose();
        return;
      }

      await _renderer.setSrcObject(stream: stream, trackId: event.track.id);
      if (_closed) {
        await _bestEffortPeerCleanup(
          () => _renderer.setSrcObject(stream: null),
        );
        await _bestEffortPeerCleanup(() async => ownedStream?.dispose());
        return;
      }
      final previousOwnedStream = _ownedRemoteVideoStream;
      _ownedRemoteVideoStream = ownedStream;
      if (previousOwnedStream != null && previousOwnedStream != ownedStream) {
        await previousOwnedStream.dispose();
      }
    } catch (error) {
      if (ownedStream != null && ownedStream != _ownedRemoteVideoStream) {
        try {
          await ownedStream.dispose();
        } catch (_) {}
      }
      _debugPeerFailure(_PeerDebugOperation.bindRemoteVideo, error);
    }
  }

  void _startRemoteVideoBinding(RTCTrackEvent event) {
    late final Future<void> task;
    task = _bindRemoteVideoTrack(event);
    _videoBindingTasks.add(task);
    unawaited(
      task.whenComplete(() {
        _videoBindingTasks.remove(task);
      }),
    );
  }

  Future<void> _send(RTCDataChannel? channel, Uint8List bytes) async {
    if (_closed ||
        channel == null ||
        channel.state != RTCDataChannelState.RTCDataChannelOpen) {
      throw const PeerSessionException(PeerSessionErrorCode.peer);
    }
    await channel.send(RTCDataChannelMessage.fromBinary(bytes));
  }

  void _observeInputChannel(
    RTCDataChannel channel,
    ControllerPeerCallbacks callbacks,
  ) {
    channel.onDataChannelState = (state) {
      if (_closed) return;
      switch (state) {
        case RTCDataChannelState.RTCDataChannelClosing:
        case RTCDataChannelState.RTCDataChannelClosed:
          _reportTransportFailure(callbacks, ControllerPeerEvent.disconnected);
        case RTCDataChannelState.RTCDataChannelConnecting:
        case RTCDataChannelState.RTCDataChannelOpen:
          _reportConnectedWhenReady(callbacks);
      }
    };
  }

  void _reportTransportFailure(
    ControllerPeerCallbacks callbacks,
    ControllerPeerEvent event,
  ) {
    _reportedConnected = false;
    if (_closed || _transportFailureReported) {
      return;
    }
    _transportFailureReported = true;
    callbacks.onEvent(event);
  }

  void _reportConnectedWhenReady(ControllerPeerCallbacks callbacks) {
    if (_closed ||
        _reportedConnected ||
        !_peerConnected ||
        !_inputChannelIsOpen(_reliable) ||
        !_inputChannelIsOpen(_fast)) {
      return;
    }
    _transportFailureReported = false;
    _reportedConnected = true;
    callbacks.onEvent(ControllerPeerEvent.connected);
  }

  @override
  Future<void> close() => _closeFuture ??= _close();

  Future<void> _close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    final reliable = _reliable;
    final fast = _fast;
    final peer = _peer;
    _reliable = null;
    _fast = null;
    _peer = null;
    _peerConnected = false;
    _reportedConnected = false;
    _transportFailureReported = false;
    if (reliable != null) reliable.onDataChannelState = null;
    if (fast != null) fast.onDataChannelState = null;
    if (peer != null) {
      peer.onIceCandidate = null;
      peer.onConnectionState = null;
      peer.onTrack = null;
    }
    await _bestEffortPeerCleanup(() async => reliable?.close());
    await _bestEffortPeerCleanup(() async => fast?.close());
    await _bestEffortPeerCleanup(() async => peer?.close());
    await _bestEffortPeerCleanup(() async => peer?.dispose());
    final rendererInitialization = _rendererInitialization;
    if (rendererInitialization != null) {
      await _bestEffortPeerCleanup(() => rendererInitialization);
    }
    if (_videoBindingTasks.isNotEmpty) {
      await Future.wait<void>(List<Future<void>>.of(_videoBindingTasks));
    }
    final ownedRemoteVideoStream = _ownedRemoteVideoStream;
    _ownedRemoteVideoStream = null;
    await _bestEffortPeerCleanup(() => _renderer.setSrcObject(stream: null));
    await _bestEffortPeerCleanup(_renderer.dispose);
    await _bestEffortPeerCleanup(() async => ownedRemoteVideoStream?.dispose());
  }

  void _throwIfClosed() {
    if (_closed) {
      throw const PeerSessionException(PeerSessionErrorCode.closed);
    }
  }
}

Future<void> _closeUnownedPeer(RTCPeerConnection peer) async {
  await _bestEffortPeerCleanup(peer.close);
  await _bestEffortPeerCleanup(peer.dispose);
}

Future<void> _closeUnownedChannel(RTCDataChannel channel) =>
    _bestEffortPeerCleanup(channel.close);

Future<void> _bestEffortPeerCleanup(Future<void> Function() cleanup) async {
  try {
    await cleanup();
  } catch (_) {
    // Every native resource is released independently during teardown.
  }
}

enum _PeerDebugOperation {
  initializeRenderer,
  createPeerConnection,
  addVideoTransceiver,
  readVideoCapabilities,
  setVideoCodecs,
  createReliableDataChannel,
  createFastDataChannel,
  createOffer,
  setLocalDescription,
  setRemoteAnswer,
  addRemoteCandidate,
  bindRemoteVideo,
}

bool _inputChannelIsOpen(RTCDataChannel? channel) =>
    channel?.state == RTCDataChannelState.RTCDataChannelOpen;

void _debugPeerFailure(_PeerDebugOperation operation, Object error) {
  if (!kDebugMode) return;
  final cause = switch (error) {
    PeerSessionException(:final code) => code.name,
    _ => error.runtimeType.toString(),
  };
  debugPrint('[remote] peer_operation=${operation.name} cause=$cause');
}

final class _ExactDataChannelInit extends RTCDataChannelInit {
  _ExactDataChannelInit({required bool ordered, required int? maxRetransmits}) {
    this.ordered = ordered;
    this.maxRetransmits = maxRetransmits ?? -1;
    binaryType = 'binary';
  }

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{
    'ordered': ordered,
    if (maxRetransmits >= 0) 'maxRetransmits': maxRetransmits,
    'protocol': protocol,
    'negotiated': negotiated,
    'id': id,
  };
}

List<RTCRtpCodecCapability> _preferCodecCapabilities(
  List<RTCRtpCodecCapability> codecs,
  List<String> preference,
) {
  final ordered = <RTCRtpCodecCapability>[];
  final seen = <RTCRtpCodecCapability>{};
  for (final name in preference) {
    for (final codec in codecs) {
      if (codec.mimeType.toUpperCase() == 'VIDEO/${name.toUpperCase()}') {
        ordered.add(codec);
        seen.add(codec);
      }
    }
  }
  ordered.addAll(codecs.where((codec) => !seen.contains(codec)));
  return ordered;
}

String preferDesktopVideoCodecs(String sdp) {
  final lines = sdp.split('\r\n');
  final payloadCodec = <String, String>{};
  final rtpMap = RegExp(r'^a=rtpmap:(\d+)\s+([^/\s]+)', caseSensitive: false);
  for (final line in lines) {
    final match = rtpMap.firstMatch(line);
    if (match != null) {
      payloadCodec[match.group(1)!] = match.group(2)!.toUpperCase();
    }
  }
  for (var index = 0; index < lines.length; index += 1) {
    if (!lines[index].startsWith('m=video ')) {
      continue;
    }
    final parts = lines[index].split(' ');
    if (parts.length <= 3) {
      continue;
    }
    final payloads = parts.sublist(3);
    final preferred = <String>[];
    for (final codec in const <String>['H264', 'VP8']) {
      preferred.addAll(
        payloads.where((payload) => payloadCodec[payload] == codec),
      );
    }
    preferred.addAll(payloads.where((payload) => !preferred.contains(payload)));
    lines[index] = <String>[...parts.take(3), ...preferred].join(' ');
    break;
  }
  return lines.join('\r\n');
}

Uint8List extractSha256DtlsFingerprint(String sdp) {
  final match = RegExp(
    r'^a=fingerprint:sha-256\s+([0-9A-Fa-f:]+)\s*$',
    multiLine: true,
  ).firstMatch(sdp.replaceAll('\r\n', '\n'));
  if (match == null) {
    throw const PeerSessionException(PeerSessionErrorCode.peer);
  }
  final values = match.group(1)!.split(':');
  if (values.length != 32) {
    throw const PeerSessionException(PeerSessionErrorCode.peer);
  }
  try {
    return Uint8List.fromList(
      values
          .map((value) {
            if (value.length != 2) {
              throw const FormatException();
            }
            return int.parse(value, radix: 16);
          })
          .toList(growable: false),
    );
  } on FormatException {
    throw const PeerSessionException(PeerSessionErrorCode.peer);
  }
}
