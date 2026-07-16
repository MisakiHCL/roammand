// SPDX-License-Identifier: MPL-2.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

enum QrScannerFailure {
  permissionDenied,
  permanentlyDenied,
  restricted,
  noCamera,
  initialization,
}

sealed class QrScannerEvent {
  const QrScannerEvent();
}

final class QrScannerCode extends QrScannerEvent {
  const QrScannerCode(this.value);
  final String value;
}

final class QrScannerFailed extends QrScannerEvent {
  const QrScannerFailed(this.failure);
  final QrScannerFailure failure;
}

final class QrScannerReady extends QrScannerEvent {
  const QrScannerReady();
}

abstract interface class QrScannerSession {
  Stream<QrScannerEvent> get events;

  Widget buildPreview();
  Future<void> start();
  Future<void> stop();
  Future<void> pause();
  Future<void> resume();
  Future<void> toggleTorch();
  Future<void> switchCamera();
  Future<void> close();
}

final class MobileQrScannerSession implements QrScannerSession {
  MobileQrScannerSession({MobileScannerController? controller})
    : _controller =
          controller ??
          MobileScannerController(
            autoStart: false,
            facing: CameraFacing.back,
            formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
            detectionSpeed: DetectionSpeed.noDuplicates,
            returnImage: false,
          ) {
    _controller.addListener(_onControllerChanged);
  }

  final MobileScannerController _controller;
  final StreamController<QrScannerEvent> _events =
      StreamController<QrScannerEvent>.broadcast(sync: true);
  Future<void>? _pendingStart;
  QrScannerFailure? _lastFailure;
  bool _ready = false;
  bool _closed = false;

  @override
  Stream<QrScannerEvent> get events => _events.stream;

  @override
  Widget buildPreview() => MobileScanner(
    controller: _controller,
    useAppLifecycleState: false,
    onDetect: (capture) {
      if (_closed) return;
      for (final barcode in capture.barcodes) {
        final value = barcode.rawValue;
        if (barcode.format == BarcodeFormat.qrCode &&
            value != null &&
            value.isNotEmpty) {
          _events.add(QrScannerCode(value));
          return;
        }
      }
    },
    // Barcode stream errors do not mean the camera failed to initialize.
    onDetectError: (_, _) {},
    errorBuilder: (_, _) => const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Icon(Icons.camera_alt_outlined, color: Colors.white, size: 48),
      ),
    ),
  );

  @override
  Future<void> start() async {
    final pending = _pendingStart;
    if (pending != null) return pending;
    final operation = _run(_controller.start);
    _pendingStart = operation;
    try {
      await operation;
    } finally {
      if (identical(_pendingStart, operation)) {
        _pendingStart = null;
      }
    }
  }

  @override
  Future<void> stop() => _run(_controller.stop);

  @override
  Future<void> pause() => _run(_controller.pause);

  @override
  Future<void> resume() => start();

  @override
  Future<void> toggleTorch() => _run(_controller.toggleTorch);

  @override
  Future<void> switchCamera() => _run(_controller.switchCamera);

  Future<void> _run(Future<void> Function() operation) async {
    if (_closed) return;
    try {
      await operation();
    } on MobileScannerException catch (error) {
      final failure = _mapFailure(error);
      if (failure != null) _publishFailure(failure);
    } catch (_) {
      _publishFailure(QrScannerFailure.initialization);
    }
  }

  void _onControllerChanged() {
    if (_closed) return;
    final state = _controller.value;
    if (state.isRunning && state.error == null) {
      _lastFailure = null;
      if (!_ready) {
        _ready = true;
        _events.add(const QrScannerReady());
      }
      return;
    }
    _ready = false;
    final error = state.error;
    if (error == null || state.isStarting) return;
    final failure = _mapFailure(error);
    if (failure != null) _publishFailure(failure);
  }

  void _publishFailure(QrScannerFailure failure) {
    if (_lastFailure == failure) return;
    _lastFailure = failure;
    _addFailure(failure);
  }

  void _addFailure(QrScannerFailure failure) {
    if (!_closed && !_events.isClosed) {
      scheduleMicrotask(() {
        if (!_closed && !_events.isClosed && _lastFailure == failure) {
          _events.add(QrScannerFailed(failure));
        }
      });
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _controller.removeListener(_onControllerChanged);
    await _controller.dispose();
    await _events.close();
  }
}

QrScannerFailure? _mapFailure(MobileScannerException error) =>
    switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        QrScannerFailure.permissionDenied,
      MobileScannerErrorCode.unsupported => QrScannerFailure.noCamera,
      MobileScannerErrorCode.controllerAlreadyInitialized ||
      MobileScannerErrorCode.controllerInitializing => null,
      _ => QrScannerFailure.initialization,
    };
