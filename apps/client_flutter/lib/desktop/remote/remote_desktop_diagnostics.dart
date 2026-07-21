// SPDX-License-Identifier: MPL-2.0

part of 'remote_desktop_controller.dart';

enum _RemoteDebugOperation {
  openIdentity,
  connectSignaling,
  createPeerOffer,
  sendAuthenticatedOffer,
  decodeRoutedEnvelope,
  applyRemoteAnswer,
  addRemoteCandidate,
  relayLocalCandidate,
  relayClosingStatus,
  signalingStream,
  peerStream,
  candidateStream,
  cancelCandidateStream,
  cancelPeerStream,
  cancelSignalingStream,
  closePeer,
  closeSignaling,
  closeIdentity,
  remoteError,
  peerEvent,
  terminalFailure,
}

Future<void> _bestEffortRemoteCleanup(
  _RemoteDebugOperation operation,
  Future<void> Function() cleanup,
) async {
  try {
    await cleanup();
  } catch (error) {
    _debugRemoteFailure(operation, error);
  }
}

void _debugRemoteFailure(_RemoteDebugOperation operation, Object error) {
  if (!kDebugMode) return;
  final cause = switch (error) {
    RemoteDesktopException(:final code) => code.name,
    SignalingClientException(:final code) => code.name,
    SignalingRemoteException(:final code) => code.name,
    SessionAnswerAuthenticationException(:final code) => code.name,
    SessionReconnectAuthenticationException(:final code) => code.name,
    PeerSessionException(:final code) => code.name,
    ProtocolValidationException(:final code) => code.wireName,
    ControllerSessionIdentityException() => 'identityUnavailable',
    _ => error.runtimeType.toString(),
  };
  _debugRemoteReason(operation, cause);
}

void _debugRemoteReason(_RemoteDebugOperation operation, String cause) {
  if (!kDebugMode) return;
  debugPrint('[remote] operation=${operation.name} cause=$cause');
}

Uint8List _secureRandomBytes(int length) {
  final random = Random.secure();
  return Uint8List.fromList(
    List<int>.generate(length, (_) => random.nextInt(256), growable: false),
  );
}

int _systemNowUnixMs() => DateTime.now().millisecondsSinceEpoch;

DiagnosticsOsFamily _currentOsFamily() => switch (defaultTargetPlatform) {
  TargetPlatform.android => DiagnosticsOsFamily.android,
  TargetPlatform.iOS => DiagnosticsOsFamily.ios,
  TargetPlatform.linux => DiagnosticsOsFamily.linux,
  TargetPlatform.macOS => DiagnosticsOsFamily.macos,
  TargetPlatform.windows => DiagnosticsOsFamily.windows,
  TargetPlatform.fuchsia => DiagnosticsOsFamily.unknown,
};

DiagnosticsSessionState _diagnosticSessionState(RemoteDesktopState state) =>
    switch (state) {
      RemoteDesktopState.idle => DiagnosticsSessionState.idle,
      RemoteDesktopState.connecting => DiagnosticsSessionState.connecting,
      RemoteDesktopState.authenticating =>
        DiagnosticsSessionState.authenticating,
      RemoteDesktopState.negotiating => DiagnosticsSessionState.negotiating,
      RemoteDesktopState.connected => DiagnosticsSessionState.connected,
      RemoteDesktopState.reconnecting => DiagnosticsSessionState.reconnecting,
      RemoteDesktopState.closing => DiagnosticsSessionState.closing,
      RemoteDesktopState.failed => DiagnosticsSessionState.failed,
    };

DiagnosticsErrorCategory _diagnosticErrorCategory(
  RemoteDesktopErrorCode code,
) => switch (code) {
  RemoteDesktopErrorCode.configuration =>
    DiagnosticsErrorCategory.configuration,
  RemoteDesktopErrorCode.localIdentity =>
    DiagnosticsErrorCategory.localIdentity,
  RemoteDesktopErrorCode.signaling => DiagnosticsErrorCategory.signaling,
  RemoteDesktopErrorCode.authentication =>
    DiagnosticsErrorCategory.authentication,
  RemoteDesktopErrorCode.peer => DiagnosticsErrorCategory.peer,
  RemoteDesktopErrorCode.remote => DiagnosticsErrorCategory.remote,
};

DiagnosticsErrorCode _diagnosticErrorCode(
  RemoteDesktopErrorCode code,
) => switch (code) {
  RemoteDesktopErrorCode.configuration => DiagnosticsErrorCode.configuration,
  RemoteDesktopErrorCode.localIdentity =>
    DiagnosticsErrorCode.identityUnavailable,
  RemoteDesktopErrorCode.signaling => DiagnosticsErrorCode.signalingUnavailable,
  RemoteDesktopErrorCode.authentication =>
    DiagnosticsErrorCode.authenticationFailed,
  RemoteDesktopErrorCode.peer => DiagnosticsErrorCode.iceFailed,
  RemoteDesktopErrorCode.remote => DiagnosticsErrorCode.remoteFailed,
};

DiagnosticsErrorCode _diagnosticSignalingRemoteError(ErrorCode code) =>
    switch (code) {
      ErrorCode.ERROR_CODE_DEVICE_OFFLINE => DiagnosticsErrorCode.deviceOffline,
      ErrorCode.ERROR_CODE_DEVICE_BUSY => DiagnosticsErrorCode.deviceBusy,
      ErrorCode.ERROR_CODE_SERVER_UNAVAILABLE =>
        DiagnosticsErrorCode.serverUnavailable,
      _ => DiagnosticsErrorCode.signalingRejected,
    };

bool _bytesEqual(List<int> left, List<int> right) {
  if (left.length != right.length) {
    return false;
  }
  var difference = 0;
  for (var index = 0; index < left.length; index += 1) {
    difference |= left[index] ^ right[index];
  }
  return difference == 0;
}
