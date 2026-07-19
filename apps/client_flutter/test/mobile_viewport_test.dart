// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/desktop/remote/input_sender.dart';
import 'package:roammand/mobile/remote/mobile_viewport.dart';

void main() {
  test('contains video in portrait and landscape and rejects black bars', () {
    final portrait = MobileViewport.initial(
      viewportSize: const Size(400, 800),
      videoAspectRatio: 16 / 9,
    );
    expect(portrait.videoRect.left, closeTo(0, 0.001));
    expect(portrait.videoRect.top, closeTo(287.5, 0.001));
    expect(portrait.videoRect.width, closeTo(400, 0.001));
    expect(portrait.videoRect.height, closeTo(225, 0.001));
    expect(portrait.mapLocalToRemote(const Offset(200, 200)), isNull);
    expect(
      portrait.mapLocalToRemote(portrait.videoRect.center),
      const MobileRemotePosition(5000, 5000),
    );

    final landscape = portrait.withLayout(
      viewportSize: const Size(800, 400),
      videoAspectRatio: 16 / 9,
    );
    expect(landscape.videoRect.left, closeTo(44.444, 0.001));
    expect(landscape.videoRect.top, closeTo(0, 0.001));
    expect(landscape.mapLocalToRemote(const Offset(10, 200)), isNull);
  });

  test(
    'maps inclusive video endpoints to the shared Host coordinate range',
    () {
      final viewport = MobileViewport.initial(
        viewportSize: const Size(320, 180),
        videoAspectRatio: 16 / 9,
      );

      expect(
        viewport.mapLocalToRemote(viewport.videoRect.topLeft),
        const MobileRemotePosition(0, 0),
      );
      expect(
        viewport.mapLocalToRemote(viewport.videoRect.bottomRight),
        const MobileRemotePosition(
          remoteInputCoordinateMaximum,
          remoteInputCoordinateMaximum,
        ),
      );
    },
  );

  test('pinch zoom clamps scale and preserves the focal remote point', () {
    final viewport = MobileViewport.initial(
      viewportSize: const Size(400, 800),
      videoAspectRatio: 16 / 9,
    );
    const focal = Offset(100, 400);
    final anchor = viewport.mapLocalToRemote(focal)!;

    final zoomed = viewport.zoomTo(scale: 2, focalPoint: focal);
    expect(zoomed.scale, 2);
    expect(zoomed.mapLocalToRemote(focal), anchor);
    expect(zoomed.zoomTo(scale: 99, focalPoint: focal).scale, 4);
    expect(zoomed.zoomTo(scale: 0, focalPoint: focal).scale, 0.8);
  });

  test('supports an 80 percent overview and a safe initial fit', () {
    final overview = MobileViewport.initial(
      viewportSize: const Size(844, 390),
      videoAspectRatio: 16 / 9,
      initialScale: mobileViewportMinimumScale,
    );

    expect(overview.scale, 0.8);
    expect(overview.videoRect.top, closeTo(39, 0.001));
    expect(overview.videoRect.bottom, closeTo(351, 0.001));
    expect(
      mobileViewportSafeFitScale(
        viewportSize: const Size(844, 390),
        videoAspectRatio: 16 / 9,
        obscuredInsets: const EdgeInsets.fromLTRB(0, 48, 0, 40),
      ),
      0.8,
    );
    expect(
      mobileViewportSafeFitScale(
        viewportSize: const Size(800, 400),
        videoAspectRatio: 2,
        obscuredInsets: const EdgeInsets.symmetric(vertical: 20),
      ),
      0.9,
    );
  });

  test('rotation and keyboard resize preserve the visible remote center', () {
    final initial = MobileViewport.initial(
      viewportSize: const Size(400, 800),
      videoAspectRatio: 16 / 9,
    );
    final zoomed = initial.zoomFromAnchor(
      scale: 3,
      focalPoint: const Offset(300, 450),
      anchor: initial.mapLocalToRemote(const Offset(300, 450))!,
    );
    final oldCenter = zoomed.mapLocalToRemote(const Offset(200, 400))!;

    final rotated = zoomed.withLayout(
      viewportSize: const Size(800, 400),
      videoAspectRatio: 16 / 9,
    );
    expect(
      rotated.mapLocalToRemote(const Offset(400, 200)),
      _closePosition(oldCenter),
    );

    final keyboard = rotated.withLayout(
      viewportSize: const Size(800, 240),
      videoAspectRatio: 16 / 9,
    );
    expect(
      keyboard.mapLocalToRemote(const Offset(400, 120)),
      _closePosition(oldCenter),
    );
  });

  test(
    'every representative transform emits only finite bounded positions',
    () {
      for (final size in const <Size>[
        Size(320, 640),
        Size(640, 320),
        Size(1024, 768),
      ]) {
        for (final aspect in const <double>[4 / 3, 16 / 10, 16 / 9]) {
          for (final scale in const <double>[0.8, 1, 1.5, 2.5, 4]) {
            var viewport = MobileViewport.initial(
              viewportSize: size,
              videoAspectRatio: aspect,
            );
            viewport = viewport.zoomTo(
              scale: scale,
              focalPoint: viewport.videoRect.center,
            );
            for (final point in <Offset>[
              viewport.videoRect.topLeft,
              viewport.videoRect.center,
              viewport.videoRect.bottomRight,
            ]) {
              final remote = viewport.mapLocalToRemote(point)!;
              expect(
                remote.x,
                inInclusiveRange(0, remoteInputCoordinateMaximum),
              );
              expect(
                remote.y,
                inInclusiveRange(0, remoteInputCoordinateMaximum),
              );
            }
          }
        }
      }
    },
  );

  test('rejects invalid viewport dimensions and aspect ratios', () {
    for (final size in const <Size>[
      Size.zero,
      Size(-1, 10),
      Size(double.infinity, 10),
    ]) {
      expect(
        () => MobileViewport.initial(
          viewportSize: size,
          videoAspectRatio: 16 / 9,
        ),
        throwsArgumentError,
      );
    }
    for (final aspect in <double>[0, -1, double.infinity, double.nan]) {
      expect(
        () => MobileViewport.initial(
          viewportSize: const Size(100, 100),
          videoAspectRatio: aspect,
        ),
        throwsArgumentError,
      );
    }
    expect(
      () => MobileViewport.initial(
        viewportSize: const Size(100, 100),
        videoAspectRatio: 1,
        initialScale: double.nan,
      ),
      throwsArgumentError,
    );
    expect(
      () => mobileViewportSafeFitScale(
        viewportSize: const Size(100, 100),
        videoAspectRatio: 1,
        obscuredInsets: const EdgeInsets.only(top: -1),
      ),
      throwsArgumentError,
    );
  });
}

Matcher _closePosition(MobileRemotePosition expected) =>
    isA<MobileRemotePosition>()
        .having((value) => value.x, 'x', closeTo(expected.x, 1))
        .having((value) => value.y, 'y', closeTo(expected.y, 1));
