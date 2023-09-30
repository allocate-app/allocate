import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../../util/constants.dart';
import 'drain_bar.dart';

class WeightTile extends StatefulWidget {
  const WeightTile({
    super.key,
    this.tilePadding = EdgeInsets.zero,
    this.batteryPadding = EdgeInsets.zero,
    this.weight = 0,
    this.max = 0,
    this.slider,
    this.constraints = const BoxConstraints(),
  });

  final EdgeInsetsGeometry tilePadding;
  final EdgeInsetsGeometry batteryPadding;
  final double weight;
  final double max;
  final Widget? slider;
  final BoxConstraints constraints;

  @override
  State<WeightTile> createState() => _WeightTile();
}

class _WeightTile extends State<WeightTile> {
  @override
  Widget build(context) {
    return Column(children: [
      Padding(
        padding: widget.tilePadding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Flexible(
              child: AutoSizeText("Energy Drain: ",
                  minFontSize: Constants.medium,
                  maxLines: 1,
                  softWrap: true,
                  style: Constants.hugeHeaderStyle),
            ),
            Flexible(
              child: Padding(
                padding: widget.batteryPadding,
                child: DrainBar(
                  weight: widget.weight,
                  max: widget.max,
                  constraints: widget.constraints,
                ),
              ),
            ),
          ],
        ),
      ),
      widget.slider ?? const SizedBox.shrink(),
    ]);
  }
}
