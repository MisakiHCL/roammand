// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';

import 'roammand_colors.dart';

final class RoammandBrandMark extends StatelessWidget {
  const RoammandBrandMark({
    required this.size,
    this.semanticsLabel,
    this.monochrome = false,
    super.key,
  });

  final double size;
  final String? semanticsLabel;
  final bool monochrome;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _RoammandMarkPainter(monochrome: monochrome)),
    );
    final label = semanticsLabel;
    if (label == null) return mark;
    return Semantics(
      label: label,
      image: true,
      child: ExcludeSemantics(child: mark),
    );
  }
}

final class RoammandAppBarTitle extends StatelessWidget {
  const RoammandAppBarTitle({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      const RoammandBrandMark(size: 28),
      const SizedBox(width: 12),
      Text(title),
    ],
  );
}

final class _RoammandMarkPainter extends CustomPainter {
  const _RoammandMarkPainter({required this.monochrome});

  final bool monochrome;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 32;
    canvas.save();
    canvas.translate(0, size.height * 0.08);

    final workspace = Path()
      ..moveTo(17.95 * scale, 24 * scale)
      ..lineTo(7 * scale, 24 * scale)
      ..cubicTo(
        4 * scale,
        24 * scale,
        2 * scale,
        22 * scale,
        2 * scale,
        19 * scale,
      )
      ..lineTo(2 * scale, 9 * scale)
      ..cubicTo(
        2 * scale,
        6 * scale,
        4 * scale,
        4 * scale,
        7 * scale,
        4 * scale,
      )
      ..lineTo(20 * scale, 4 * scale)
      ..cubicTo(
        23 * scale,
        4 * scale,
        25 * scale,
        6 * scale,
        25 * scale,
        8.95 * scale,
      );
    final workspaceBounds = Rect.fromLTWH(
      2 * scale,
      4 * scale,
      23 * scale,
      20 * scale,
    );
    final workspacePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8 * scale
      ..strokeCap = StrokeCap.round
      ..shader = monochrome
          ? null
          : const LinearGradient(
              colors: <Color>[
                RoammandColors.signalCyan,
                RoammandColors.auroraIndigo,
                RoammandColors.auroraSoft,
              ],
            ).createShader(workspaceBounds)
      ..color = RoammandColors.inverseSurface;
    canvas.drawPath(workspace, workspacePaint);

    final connector = Path()
      ..moveTo(8.5 * scale, 15.8 * scale)
      ..cubicTo(
        12.5 * scale,
        15.8 * scale,
        14.2 * scale,
        13.4 * scale,
        19 * scale,
        13.4 * scale,
      );
    canvas.drawPath(
      connector,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * scale
        ..strokeCap = StrokeCap.round
        ..shader = monochrome
            ? null
            : const LinearGradient(
                colors: <Color>[
                  RoammandColors.signalCyan,
                  RoammandColors.auroraIndigo,
                ],
              ).createShader(
                Rect.fromLTRB(
                  8.5 * scale,
                  13.4 * scale,
                  19 * scale,
                  15.8 * scale,
                ),
              )
        ..color = RoammandColors.inverseSurface,
    );

    final controller = RRect.fromRectAndRadius(
      Rect.fromLTWH(19 * scale, 10 * scale, 11 * scale, 17 * scale),
      Radius.circular(3.6 * scale),
    );
    canvas.drawRRect(
      controller,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.1 * scale
        ..color = RoammandColors.inverseSurface,
    );

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1 * scale
      ..color = monochrome
          ? RoammandColors.inverseSurface
          : RoammandColors.auroraIndigo;
    canvas.drawCircle(
      Offset(24.5 * scale, 18.8 * scale),
      1.8 * scale,
      ringPaint,
    );
    canvas.drawCircle(
      Offset(24.5 * scale, 18.8 * scale),
      0.45 * scale,
      Paint()..color = RoammandColors.inverseSurface,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RoammandMarkPainter oldDelegate) =>
      oldDelegate.monochrome != monochrome;
}
