// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';

import 'roammand_colors.dart';

const roammandProgressIndicatorSize = 20.0;
const roammandCompactProgressIndicatorSize = 16.0;
const _progressStrokeWidth = 2.0;

/// A compact activity indicator that carries the Night Aurora gradient.
final class RoammandProgressIndicator extends StatelessWidget {
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
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ExcludeSemantics(
          child: CircularProgressIndicator(
            value: 1,
            strokeWidth: strokeWidth,
            color: RoammandColors.elevatedSurface,
          ),
        ),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              RoammandColors.auroraIndigo,
              RoammandColors.auroraSoft,
              RoammandColors.signalCyan,
            ],
          ).createShader(bounds),
          child: CircularProgressIndicator(
            value: value,
            strokeWidth: strokeWidth,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}
