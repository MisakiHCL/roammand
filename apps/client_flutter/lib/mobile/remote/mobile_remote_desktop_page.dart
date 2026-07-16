// SPDX-License-Identifier: MPL-2.0

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:roammand/design_system/roammand_colors.dart';
import 'package:roammand/desktop/remote/input_sender.dart';
import 'package:roammand/desktop/remote/peer_session.dart';
import 'package:roammand/desktop/remote/remote_desktop_controller.dart';
import 'package:roammand/l10n/generated/app_localizations.dart';
import 'package:roammand/mobile/remote/mobile_gesture_surface.dart';
import 'package:roammand/mobile/remote/mobile_input_tray.dart';
import 'package:roammand/mobile/remote/mobile_keyboard_controller.dart';

import '../../diagnostics/diagnostics_dialog.dart';

const _statusMargin = 12.0;
const _statusHorizontalPadding = 16.0;
const _statusVerticalPadding = 8.0;
const _statusRadius = 20.0;
const _controlBarPadding = 8.0;
const _minimumInputTrayHeight = 160.0;
const _maximumInputTrayHeight = 240.0;
const _inputTrayScreenFraction = 0.42;
const _remoteOrientations = <DeviceOrientation>[
  DeviceOrientation.landscapeLeft,
  DeviceOrientation.landscapeRight,
];
const _systemManagedOrientations = <DeviceOrientation>[];

typedef MobileRemoteVideoBuilder =
    Widget Function(BuildContext context, Object renderer);

final class MobileRemoteDesktopPage extends StatefulWidget {
  const MobileRemoteDesktopPage({
    required this.target,
    required this.controller,
    this.videoBuilder,
    this.videoAspectRatio,
    super.key,
  });

  final RemoteDesktopTarget target;
  final RemoteDesktopViewModel controller;
  final MobileRemoteVideoBuilder? videoBuilder;
  final double? videoAspectRatio;

  @override
  State<MobileRemoteDesktopPage> createState() =>
      _MobileRemoteDesktopPageState();
}

final class _MobileRemoteDesktopPageState extends State<MobileRemoteDesktopPage>
    with WidgetsBindingObserver {
  final MobileGestureSurfaceController _gestureController =
      MobileGestureSurfaceController();

  RemoteInputSender? _keyboardSender;
  MobileKeyboardController? _keyboardController;
  Future<void>? _closeFuture;
  bool _keyboardVisible = false;
  bool _closing = false;
  bool _popRequested = false;
  bool _allowPop = false;
  late final Future<void> _orientationLock;

  @override
  void initState() {
    super.initState();
    _orientationLock = _setPreferredOrientations(_remoteOrientations);
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_onControllerChanged);
    _syncKeyboardController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_closing) {
        unawaited(widget.controller.connect(widget.target));
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _releaseInput();
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _releaseInput();
        unawaited(_closeSession(pop: false));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_onControllerChanged);
    unawaited(_keyboardController?.close() ?? Future<void>.value());
    final closing = _closeController();
    unawaited(closing.whenComplete(widget.controller.dispose));
    unawaited(
      _orientationLock.whenComplete(
        () => _setPreferredOrientations(_systemManagedOrientations),
      ),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final inputTrayHeight =
        (MediaQuery.sizeOf(context).height * _inputTrayScreenFraction).clamp(
          _minimumInputTrayHeight,
          _maximumInputTrayHeight,
        );
    return PopScope<void>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          unawaited(_closeSession(pop: true));
        }
      },
      child: Scaffold(
        backgroundColor: RoammandColors.canvas,
        appBar: AppBar(
          title: Text(
            strings.remoteDesktopTitle(widget.target.hostIdentity.displayName),
          ),
          actions: <Widget>[
            IconButton(
              key: const Key('mobile-remote-diagnostics-action'),
              onPressed: _closing
                  ? null
                  : () => unawaited(
                      showDiagnosticsDialog(
                        context,
                        report: widget.controller.diagnosticsReport,
                      ),
                    ),
              tooltip: strings.diagnosticsAction,
              icon: const Icon(Icons.monitor_heart_outlined, size: 24),
            ),
            IconButton(
              onPressed: _closing ? null : () => _closeSession(pop: true),
              tooltip: strings.closeSessionAction,
              icon: const Icon(Icons.close, size: 24),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(child: _buildRemoteArea(context, strings)),
              _buildControlBar(context, strings),
              if (_keyboardVisible)
                SizedBox(
                  height: inputTrayHeight,
                  child: MobileInputTray(
                    controller: _keyboardController,
                    enabled: _inputEnabled,
                    onInputFailure: _handleInputFailure,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRemoteArea(BuildContext context, AppLocalizations strings) {
    final renderer = widget.controller.videoRenderer;
    if (renderer is RTCVideoRenderer && widget.videoAspectRatio == null) {
      return ListenableBuilder(
        listenable: renderer,
        builder: (context, _) => _remoteStack(
          context,
          strings,
          _rendererAspectRatio(renderer),
          _buildVideo(context, renderer),
        ),
      );
    }
    return _remoteStack(
      context,
      strings,
      _configuredAspectRatio,
      _buildVideo(context, renderer),
    );
  }

  Widget _remoteStack(
    BuildContext context,
    AppLocalizations strings,
    double aspectRatio,
    Widget video,
  ) => Stack(
    fit: StackFit.expand,
    children: <Widget>[
      MobileGestureSurface(
        video: video,
        videoAspectRatio: aspectRatio,
        sender: _connectedSender,
        controller: _gestureController,
        onInputFailure: _handleInputFailure,
      ),
      Positioned(
        top: _statusMargin,
        left: _statusMargin,
        right: _statusMargin,
        child: Center(child: _buildStatus(context, strings)),
      ),
    ],
  );

  Widget _buildVideo(BuildContext context, Object renderer) {
    final builder = widget.videoBuilder;
    if (builder != null) {
      return builder(context, renderer);
    }
    if (renderer is! RTCVideoRenderer) {
      return const ColoredBox(color: Colors.black);
    }
    return RTCVideoView(
      renderer,
      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
    );
  }

  Widget _buildStatus(BuildContext context, AppLocalizations strings) {
    final failed = widget.controller.state == RemoteDesktopState.failed;
    final connected = widget.controller.state == RemoteDesktopState.connected;
    final colors = Theme.of(context).colorScheme;
    final accent = failed
        ? RoammandColors.emergency
        : connected
        ? RoammandColors.online
        : RoammandColors.auroraSoft;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: failed
            ? colors.errorContainer
            : connected
            ? RoammandColors.online.withValues(alpha: 0.14)
            : colors.surfaceContainerHighest.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(_statusRadius),
        border: Border.all(color: accent.withValues(alpha: 0.48)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _statusHorizontalPadding,
          vertical: _statusVerticalPadding,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (connected) ...<Widget>[
              const Icon(Icons.circle, size: 8, color: RoammandColors.online),
              const SizedBox(width: 8),
            ],
            if (_isProgressState(widget.controller.state)) ...<Widget>[
              const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(child: Text(_statusText(strings))),
            if (failed && widget.controller.canRetry) ...<Widget>[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => unawaited(_retrySession()),
                child: Text(strings.retryRemoteAction),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControlBar(BuildContext context, AppLocalizations strings) =>
      Material(
        color: RoammandColors.deepSurface,
        shape: const Border(top: BorderSide(color: RoammandColors.outline)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _controlBarPadding),
          child: Row(
            children: <Widget>[
              const Icon(Icons.touch_app_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.mobileGestureHint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                key: const Key('mobile-keyboard-toggle'),
                onPressed: () {
                  setState(() => _keyboardVisible = !_keyboardVisible);
                },
                tooltip: _keyboardVisible
                    ? strings.mobileHideKeyboardAction
                    : strings.mobileKeyboardAction,
                icon: Icon(
                  _keyboardVisible
                      ? Icons.keyboard_hide_outlined
                      : Icons.keyboard_outlined,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      );

  String _statusText(AppLocalizations strings) {
    if (widget.controller.state == RemoteDesktopState.failed) {
      return switch (widget.controller.errorCode) {
        RemoteDesktopErrorCode.authentication =>
          strings.remoteAuthenticationFailed,
        RemoteDesktopErrorCode.localIdentity =>
          strings.remoteLocalIdentityFailed,
        RemoteDesktopErrorCode.signaling => strings.remoteSignalingFailed,
        RemoteDesktopErrorCode.configuration =>
          strings.remoteConfigurationFailed,
        RemoteDesktopErrorCode.peer ||
        RemoteDesktopErrorCode.remote ||
        null => strings.remoteConnectionFailed,
      };
    }
    return switch (widget.controller.state) {
      RemoteDesktopState.idle => strings.remoteIdle,
      RemoteDesktopState.connecting => strings.remoteConnecting,
      RemoteDesktopState.reconnecting => _reconnectText(strings),
      RemoteDesktopState.authenticating => strings.remoteAuthenticating,
      RemoteDesktopState.negotiating => strings.remoteNegotiating,
      RemoteDesktopState.connected => strings.remoteConnected,
      RemoteDesktopState.closing => strings.remoteClosing,
      RemoteDesktopState.failed => strings.remoteConnectionFailed,
    };
  }

  String _reconnectText(AppLocalizations strings) {
    final progress = widget.controller.reconnectProgress;
    if (progress == null) {
      return strings.remoteReconnectingPending;
    }
    return strings.remoteReconnecting(
      progress.attempt,
      progress.maximumAttempts,
      progress.remaining.inSeconds,
    );
  }

  double get _configuredAspectRatio {
    final ratio = widget.videoAspectRatio;
    return ratio != null && ratio.isFinite && ratio > 0 ? ratio : 16 / 9;
  }

  double _rendererAspectRatio(RTCVideoRenderer renderer) =>
      renderer.videoWidth > 0 && renderer.videoHeight > 0
      ? renderer.videoWidth / renderer.videoHeight
      : 16 / 9;

  bool get _inputEnabled =>
      widget.controller.state == RemoteDesktopState.connected &&
      _keyboardController != null;

  RemoteInputSender? get _connectedSender =>
      widget.controller.state == RemoteDesktopState.connected
      ? widget.controller.inputSender
      : null;

  void _onControllerChanged() {
    _syncKeyboardController();
    if (mounted) setState(() {});
  }

  void _syncKeyboardController() {
    final sender = _connectedSender;
    if (identical(sender, _keyboardSender)) return;
    final previous = _keyboardController;
    _keyboardSender = sender;
    _keyboardController = sender == null
        ? null
        : MobileKeyboardController(sender);
    if (previous != null) {
      unawaited(previous.close());
    }
  }

  void _releaseInput() {
    _gestureController.cancel();
    unawaited(_keyboardController?.releaseAll() ?? Future<void>.value());
  }

  void _handleInputFailure(Object error) {
    if (kDebugMode) {
      final cause = switch (error) {
        InputSenderException(:final code) => code.name,
        PeerSessionException(:final code) => code.name,
        _ => error.runtimeType.toString(),
      };
      debugPrint('[remote] input_operation=send cause=$cause');
    }
    if (!_closing) {
      unawaited(_closeSession(pop: false));
    }
  }

  Future<void> _closeSession({required bool pop}) async {
    _popRequested = _popRequested || pop;
    if (!_closing) {
      _closing = true;
      if (mounted) setState(() {});
      _releaseInput();
    }
    await _closeController();
    if (_popRequested && mounted && !_allowPop) {
      setState(() => _allowPop = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) {
        await Navigator.of(context).maybePop();
      }
    }
  }

  Future<void> _closeController() => _closeFuture ??= widget.controller.close();

  Future<void> _retrySession() async {
    if (_closing || !widget.controller.canRetry) {
      return;
    }
    try {
      await widget.controller.retry();
    } catch (_) {}
  }
}

Future<void> _setPreferredOrientations(
  List<DeviceOrientation> orientations,
) async {
  try {
    await SystemChrome.setPreferredOrientations(orientations);
  } catch (error) {
    if (kDebugMode) {
      debugPrint(
        '[remote] operation=setPreferredOrientations '
        'cause=${error.runtimeType}',
      );
    }
  }
}

bool _isProgressState(RemoteDesktopState state) => switch (state) {
  RemoteDesktopState.connecting ||
  RemoteDesktopState.authenticating ||
  RemoteDesktopState.negotiating ||
  RemoteDesktopState.reconnecting ||
  RemoteDesktopState.closing => true,
  RemoteDesktopState.idle ||
  RemoteDesktopState.connected ||
  RemoteDesktopState.failed => false,
};
