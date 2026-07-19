// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'roammand_colors.dart';

const roammandProgressIndicatorSize = 20.0;
const roammandCompactProgressIndicatorSize = 16.0;
const _progressStrokeWidth = 2.0;
const _progressDuration = Duration(milliseconds: 960);
const _progressSweepAngle = math.pi * 1.45;
const _progressBoundsInset = 1.0;

/// A compact activity indicator that carries the Night Aurora gradient.
final class RoammandProgressIndicator extends StatefulWidget {
  const RoammandProgressIndicator({
    this.size = roammandProgressIndicatorSize,
    this.strokeWidth = _progressStrokeWidth,
    this.value,
    super.key,
  });

  final double size;
  final double strokeWidth;
  final double? value;

  @override
  State<RoammandProgressIndicator> createState() =>
      _RoammandProgressIndicatorState();
}

final class _RoammandProgressIndicatorState
    extends State<RoammandProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotation;

  @override
  void initState() {
    super.initState();
    _rotation = AnimationController(vsync: this, duration: _progressDuration);
    _updateAnimation();
  }

  @override
  void didUpdateWidget(RoammandProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.value == null) != (widget.value == null)) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (widget.value == null) {
      _rotation.repeat();
    } else {
      _rotation.stop();
      _rotation.value = 0;
    }
  }

  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: widget.size,
    child: CustomPaint(
      painter: _RoammandProgressPainter(
        rotation: _rotation,
        value: widget.value,
        strokeWidth: widget.strokeWidth,
      ),
    ),
  );
}

final class _RoammandProgressPainter extends CustomPainter {
  _RoammandProgressPainter({
    required this.rotation,
    required this.value,
    required this.strokeWidth,
  }) : super(repaint: rotation);

  final Animation<double> rotation;
  final double? value;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.max(
      0.0,
      (math.min(size.width, size.height) / 2) -
          (strokeWidth / 2) -
          _progressBoundsInset,
    );
    if (radius <= 0) return;

    final arcBounds = Rect.fromCircle(center: center, radius: radius);
    final trackPaint = Paint()
      ..color = RoammandColors.outline.withValues(alpha: 0.56)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius, trackPaint);

    final progress = value?.clamp(0.0, 1.0);
    final sweepAngle = progress == null
        ? _progressSweepAngle
        : math.pi * 2 * progress;
    if (sweepAngle <= 0) return;

    const startAngle = -math.pi / 2;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(progress == null ? rotation.value * math.pi * 2 : 0);
    canvas.translate(-center.dx, -center.dy);
    final progressPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + _progressSweepAngle,
        colors: <Color>[RoammandColors.auroraIndigo, RoammandColors.signalCyan],
      ).createShader(arcBounds)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;
    canvas.drawArc(arcBounds, startAngle, sweepAngle, false, progressPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RoammandProgressPainter oldDelegate) =>
      oldDelegate.rotation != rotation ||
      oldDelegate.value != value ||
      oldDelegate.strokeWidth != strokeWidth;
}
