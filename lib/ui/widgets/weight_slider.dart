import 'package:flutter/material.dart';

import '../../util/constants.dart';

class WeightSlider extends StatefulWidget {
  const WeightSlider({super.key, this.weight = 0, this.handleWeightChange});

  final double weight;
  final void Function(double value)? handleWeightChange;

  @override
  State<WeightSlider> createState() => _WeightSlider();
}

class _WeightSlider extends State<WeightSlider> {
  @override
  Widget build(context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const Icon(Icons.battery_full),
        Expanded(
          child: Slider(
              value: widget.weight,
              max: Constants.maxTaskWeight.toDouble(),
              label:
                  "${widget.weight} ${(widget.weight > (Constants.maxTaskWeight / 2).floor()) ? Constants.lowBattery : Constants.fullBattery}",
              divisions: Constants.maxTaskWeight,
              onChanged: widget.handleWeightChange),
        ),
        const Icon(Icons.battery_1_bar),
      ],
    );
  }
}
