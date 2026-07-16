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

abstract interface class QrScannerSession {
  Stream<QrScannerEvent> get events;

  Widget buildPreview();
  Future<void> start();
  Future<void> stop();
  Future<void> pause();
  Future<void> resume();
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
          );

  final MobileScannerController _controller;
  final StreamController<QrScannerEvent> _events =
      StreamController<QrScannerEvent>.broadcast(sync: true);
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
    onDetectError: (_, _) => _addFailure(QrScannerFailure.initialization),
    errorBuilder: (_, error) {
      _addFailure(_mapFailure(error));
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Icon(Icons.camera_alt_outlined, color: Colors.white, size: 48),
        ),
      );
    },
  );

  @override
  Future<void> start() => _run(_controller.start);

  @override
  Future<void> stop() => _run(_controller.stop);

  @override
  Future<void> pause() => _run(_controller.pause);

  @override
  Future<void> resume() => start();

  Future<void> _run(Future<void> Function() operation) async {
    if (_closed) return;
    try {
      await operation();
    } on MobileScannerException catch (error) {
      _addFailure(_mapFailure(error));
    } catch (_) {
      _addFailure(QrScannerFailure.initialization);
    }
  }

  void _addFailure(QrScannerFailure failure) {
    if (!_closed && !_events.isClosed) {
      scheduleMicrotask(() {
        if (!_closed && !_events.isClosed) {
          _events.add(QrScannerFailed(failure));
        }
      });
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _controller.dispose();
    await _events.close();
  }
}

QrScannerFailure _mapFailure(MobileScannerException error) =>
    switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        QrScannerFailure.permissionDenied,
      MobileScannerErrorCode.unsupported => QrScannerFailure.noCamera,
      _ => QrScannerFailure.initialization,
    };
