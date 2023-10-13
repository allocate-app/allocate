import 'package:flutter/material.dart';

import '../../util/constants.dart';

class EnergyModal extends StatefulWidget {
  const EnergyModal({Key? key, this.initialWeight = 0}) : super(key: key);

  final int initialWeight;

  @override
  State<EnergyModal> createState() => _EnergyModal();
}

class _EnergyModal extends State<EnergyModal> {
  late double weight;

  @override
  void initState() {
    weight = widget.initialWeight.toDouble();
    super.initState();
  }

  @override
  Widget build(context) {
    return Center(
        heightFactor: 1,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Step Drain", style: Constants.headerStyle),
              Padding(
                  padding: const EdgeInsets.all(Constants.padding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const Icon(Icons.battery_full_rounded),
                      Expanded(
                        child: Slider(
                          value: weight,
                          max: Constants.maxTaskWeight.toDouble(),
                          label:
                              "${weight.toInt()} ${(weight > (Constants.maxTaskWeight / 2).floor()) ? Constants.lowBattery : Constants.fullBattery}",
                          divisions: Constants.maxTaskWeight,
                          onChanged: (value) => setState(() {
                            weight = value;
                          }),
                          onChangeEnd: (value) {
                            Navigator.pop(context, value.toInt());
                          },
                        ),
                      ),
                      const Icon(Icons.battery_1_bar_rounded),
                    ],
                  )),
            ]));
  }
}
