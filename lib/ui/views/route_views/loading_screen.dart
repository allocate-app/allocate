import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../../util/constants.dart';
import '../../../util/numbers.dart';
import '../../widgets/battery_meter.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  // This should just play some sort of loading animation while things happen in the background.
  @override
  Widget build(BuildContext context) {
    double scale = computeScale(
        screenSize: MediaQuery.maybeSizeOf(context) ?? const Size(100, 100));
    return Scaffold(
      body: OverflowBox(
        minWidth: 100,
        minHeight: 100,
        child: loadingGraphic(
          context: context,
          scale: scale,
        ),
      ),
    );
  }

  double computeScale({required Size screenSize}) {
    // double halfDiagonalMagnitude =
    //     sqrt(pow(screenSize.height / 2, 2) + pow(screenSize.width / 2, 2));
    double halfSideMagnitude = sqrt(pow(screenSize.shortestSide, 2) / 2);

    double t = smoothstep(
            x: (halfSideMagnitude / (Constants.hugeScreen)), v0: 0, v1: 1)
        .toDouble();
    return lerpDouble(
        Constants.minLoadGraphicScale, Constants.maxLoadGraphicScale, t)!;
  }

  Widget loadingGraphic({required BuildContext context, double? scale}) =>
      Transform.scale(
        scale: scale ?? 1,
        child: Stack(alignment: AlignmentDirectional.center, children: [
          Align(
              alignment: Alignment.center,
              child: Transform.rotate(
                angle: pi / 3,
                child: LoadingAnimationWidget.twoRotatingArc(
                  color: Theme.of(context).colorScheme.tertiary,
                  size: Constants.loadingArcSize,
                ),
              )),
          Align(
            alignment: Alignment.center,
            child: Transform.rotate(
              angle: 2 * pi / 3,
              child: LoadingAnimationWidget.twoRotatingArc(
                color: Theme.of(context).colorScheme.secondary,
                size: Constants.loadingArcSize,
              ),
            ),
          ),
          Align(
              alignment: Alignment.center,
              child: LoadingAnimationWidget.twoRotatingArc(
                color: Theme.of(context).colorScheme.primary,
                size: Constants.loadingArcSize,
              )),
          const Align(
            alignment: Alignment.center,
            child: BatteryMeter(
              forward: true,
              scale: 1.1,
              showText: false,
              weight: 1,
              max: 1,
              // This is just to force a default ratio
              constraints: BoxConstraints(
                maxWidth: 130,
                maxHeight: 150,
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.02),
            child: Icon(
              Icons.check_rounded,
              size: Constants.loadingGraphicIconSize,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ]),
      );
}
