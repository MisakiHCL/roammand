// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:roammand/desktop/remote/input_sender.dart';

const mobileViewportMinimumScale = 1.0;
const mobileViewportMaximumScale = 4.0;

final class MobileRemotePosition {
  const MobileRemotePosition(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is MobileRemotePosition && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

final class MobileViewport {
  const MobileViewport._({
    required this.viewportSize,
    required this.videoAspectRatio,
    required this.scale,
    required this.pan,
  });

  factory MobileViewport.initial({
    required Size viewportSize,
    required double videoAspectRatio,
  }) {
    _validateLayout(viewportSize, videoAspectRatio);
    return MobileViewport._(
      viewportSize: viewportSize,
      videoAspectRatio: videoAspectRatio,
      scale: mobileViewportMinimumScale,
      pan: Offset.zero,
    );
  }

  final Size viewportSize;
  final double videoAspectRatio;
  final double scale;
  final Offset pan;

  Rect get videoRect {
    final base = _containedVideoRect(viewportSize, videoAspectRatio);
    return Rect.fromCenter(
      center: viewportSize.center(Offset.zero) + pan,
      width: base.width * scale,
      height: base.height * scale,
    );
  }

  MobileRemotePosition? mapLocalToRemote(Offset localPosition) {
    if (!localPosition.dx.isFinite || !localPosition.dy.isFinite) {
      return null;
    }
    final rect = videoRect;
    if (localPosition.dx < rect.left ||
        localPosition.dx > rect.right ||
        localPosition.dy < rect.top ||
        localPosition.dy > rect.bottom) {
      return null;
    }
    final normalizedX = ((localPosition.dx - rect.left) / rect.width).clamp(
      0.0,
      1.0,
    );
    final normalizedY = ((localPosition.dy - rect.top) / rect.height).clamp(
      0.0,
      1.0,
    );
    return MobileRemotePosition(
      (normalizedX * remoteInputCoordinateMaximum).round(),
      (normalizedY * remoteInputCoordinateMaximum).round(),
    );
  }

  MobileViewport withLayout({
    required Size viewportSize,
    required double videoAspectRatio,
  }) {
    _validateLayout(viewportSize, videoAspectRatio);
    if (viewportSize == this.viewportSize &&
        videoAspectRatio == this.videoAspectRatio) {
      return this;
    }
    final oldCenter =
        mapLocalToRemote(this.viewportSize.center(Offset.zero)) ??
        const MobileRemotePosition(
          remoteInputCoordinateMaximum ~/ 2,
          remoteInputCoordinateMaximum ~/ 2,
        );
    final resized = MobileViewport._(
      viewportSize: viewportSize,
      videoAspectRatio: videoAspectRatio,
      scale: scale,
      pan: Offset.zero,
    );
    return resized.zoomFromAnchor(
      scale: scale,
      focalPoint: viewportSize.center(Offset.zero),
      anchor: oldCenter,
    );
  }

  MobileViewport zoomTo({required double scale, required Offset focalPoint}) {
    final anchor = mapLocalToRemote(focalPoint);
    if (anchor == null) {
      return _withScaleAndPan(scale, Offset.zero);
    }
    return zoomFromAnchor(scale: scale, focalPoint: focalPoint, anchor: anchor);
  }

  MobileViewport zoomFromAnchor({
    required double scale,
    required Offset focalPoint,
    required MobileRemotePosition anchor,
  }) {
    if (!scale.isFinite ||
        !focalPoint.dx.isFinite ||
        !focalPoint.dy.isFinite ||
        anchor.x < 0 ||
        anchor.x > remoteInputCoordinateMaximum ||
        anchor.y < 0 ||
        anchor.y > remoteInputCoordinateMaximum) {
      throw ArgumentError('Invalid mobile viewport zoom');
    }
    final nextScale = scale.clamp(
      mobileViewportMinimumScale,
      mobileViewportMaximumScale,
    );
    final base = _containedVideoRect(viewportSize, videoAspectRatio);
    final contentSize = Size(base.width * nextScale, base.height * nextScale);
    final xFraction = anchor.x / remoteInputCoordinateMaximum;
    final yFraction = anchor.y / remoteInputCoordinateMaximum;
    final desiredCenter = Offset(
      focalPoint.dx - (xFraction - 0.5) * contentSize.width,
      focalPoint.dy - (yFraction - 0.5) * contentSize.height,
    );
    final desiredPan = desiredCenter - viewportSize.center(Offset.zero);
    return _withScaleAndPan(nextScale, desiredPan);
  }

  MobileViewport _withScaleAndPan(double scale, Offset requestedPan) {
    if (!scale.isFinite) {
      throw ArgumentError.value(scale, 'scale');
    }
    final nextScale = scale.clamp(
      mobileViewportMinimumScale,
      mobileViewportMaximumScale,
    );
    final base = _containedVideoRect(viewportSize, videoAspectRatio);
    final contentWidth = base.width * nextScale;
    final contentHeight = base.height * nextScale;
    final maxPanX = math.max(0.0, (contentWidth - viewportSize.width) / 2);
    final maxPanY = math.max(0.0, (contentHeight - viewportSize.height) / 2);
    final clampedPan = Offset(
      requestedPan.dx.clamp(-maxPanX, maxPanX),
      requestedPan.dy.clamp(-maxPanY, maxPanY),
    );
    return MobileViewport._(
      viewportSize: viewportSize,
      videoAspectRatio: videoAspectRatio,
      scale: nextScale,
      pan: clampedPan,
    );
  }
}

Rect _containedVideoRect(Size viewportSize, double videoAspectRatio) {
  final viewportAspectRatio = viewportSize.width / viewportSize.height;
  if (viewportAspectRatio > videoAspectRatio) {
    final width = viewportSize.height * videoAspectRatio;
    return Rect.fromLTWH(
      (viewportSize.width - width) / 2,
      0,
      width,
      viewportSize.height,
    );
  }
  final height = viewportSize.width / videoAspectRatio;
  return Rect.fromLTWH(
    0,
    (viewportSize.height - height) / 2,
    viewportSize.width,
    height,
  );
}

void _validateLayout(Size viewportSize, double videoAspectRatio) {
  if (!viewportSize.width.isFinite ||
      !viewportSize.height.isFinite ||
      viewportSize.width <= 0 ||
      viewportSize.height <= 0 ||
      !videoAspectRatio.isFinite ||
      videoAspectRatio <= 0) {
    throw ArgumentError('Invalid mobile viewport layout');
  }
}
