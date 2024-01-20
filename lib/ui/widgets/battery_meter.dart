import "package:auto_size_text/auto_size_text.dart";
import "package:flutter/material.dart";

import "../../util/constants.dart";

class BatteryMeter extends StatefulWidget {
  const BatteryMeter({
    super.key,
    this.weight = 0,
    this.scale = 1.0,
    this.max = Constants.maxBandwidthDouble,
    this.showDifference = false,
    this.forward = false,
    this.alertUser = true,
    this.constraints = const BoxConstraints(),
  });

  final double scale;
  final double weight;
  final double max;
  final bool showDifference;
  final bool forward;
  final bool alertUser;
  final BoxConstraints constraints;

  @override
  State<BatteryMeter> createState() => _BatteryMeter();
}

class _BatteryMeter extends State<BatteryMeter> {
  @override
  Widget build(context) {
    double offset = widget.weight / widget.max;
    if (offset.isNaN || offset.isInfinite) {
      offset = 0;
    }
    return ConstrainedBox(
      constraints: widget.constraints,
      child: Transform.scale(
        scale: widget.scale,
        child: Stack(alignment: Alignment.center, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
            child: Container(
              decoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 3,
                      strokeAlign: BorderSide.strokeAlignCenter),
                  shape: BoxShape.rectangle,
                  borderRadius: const BorderRadius.all(
                      Radius.circular(Constants.roundedCorners))),
              child: Padding(
                padding: const EdgeInsets.all(Constants.halfPadding),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(
                      Radius.circular(Constants.curvedCorners)),
                  child: LinearProgressIndicator(
                    color: (((offset < 0.6) ^ (widget.forward)) ||
                            !widget.alertUser)
                        ? Theme.of(context).colorScheme.inversePrimary
                        : Theme.of(context).colorScheme.tertiary,
                    minHeight: 50,
                    value: (widget.forward) ? offset : 1 - offset,
                    // Possibly remove
                  ),
                ),
              ),
            ),
          ),
          Align(
              alignment: const Alignment(1.05, 0),
              child: Container(
                  height: 18,
                  width: 8,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(Constants.circular),
                        bottomRight: Radius.circular(Constants.circular)),
                    color: Theme.of(context).colorScheme.outline,
                  ))),
          AutoSizeText(
              "${((widget.showDifference) ? widget.max - widget.weight : widget.weight).toInt()}",
              minFontSize: Constants.large,
              softWrap: false,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: Constants.hugeHeaderStyle),
        ]),
      ),
    );
  }
}
