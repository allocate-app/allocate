import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:numberpicker/numberpicker.dart';

import '../../util/constants.dart';

class DurationDialog extends StatefulWidget {
  const DurationDialog({Key? key, this.duration = 0}) : super(key: key);
  final int duration;

  @override
  State<DurationDialog> createState() => _DurationDialog();
}

class _DurationDialog extends State<DurationDialog> {
  late int hours;
  late int minutes;
  late int seconds;

  @override
  void initState() {
    super.initState();
    setTimeValues(time: widget.duration);
  }

  void setTimeValues({int time = 0}) {
    hours = time ~/ 3600;
    time %= 3600;
    minutes = time ~/ 60;
    time %= 60;
    seconds = time;
  }

  @override
  Widget build(context) {
    return Dialog(
        insetPadding: const EdgeInsets.all(Constants.innerPadding),
        child: Padding(
            padding: const EdgeInsets.all(Constants.innerPadding),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Flexible(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: AutoSizeText(
                              "Expected Duration",
                              style: Constants.headerStyle,
                              softWrap: true,
                              overflow: TextOverflow.visible,
                              maxLines: 2,
                              minFontSize: Constants.large,
                            ),
                          )
                        ]),
                  ),
                  const Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                            flex: 3,
                            child: AutoSizeText(
                              "Hours | Minutes | Seconds ",
                              style: Constants.largeHeaderStyle,
                              softWrap: true,
                              overflow: TextOverflow.visible,
                              maxLines: 1,
                              minFontSize: Constants.large,
                            )),
                        Flexible(
                          child: FittedBox(
                              fit: BoxFit.fill,
                              child: Icon(Icons.timer_outlined,
                                  size: Constants.lgIconSize)),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: NumberPicker(
                            infiniteLoop: true,
                            textStyle: Constants.numberPickerSecondary(
                                context: context),
                            selectedTextStyle:
                            Constants.numberPickerPrimary(context: context),
                            minValue: 0,
                            maxValue: 100,
                            value: hours,
                            haptics: true,
                            onChanged: (value) {
                              SemanticsService.announce(
                                  "$value, hours", Directionality.of(context));
                              setState(() => hours = value);
                            },
                          ),
                        ),
                        const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: Constants.padding),
                            child: Text(":", style: Constants.timeColon)),
                        Expanded(
                          child: NumberPicker(
                            infiniteLoop: true,
                            textStyle: Constants.numberPickerSecondary(
                                context: context),
                            selectedTextStyle:
                            Constants.numberPickerPrimary(context: context),
                            minValue: 0,
                            maxValue: 59,
                            value: minutes,
                            haptics: true,
                            onChanged: (value) {
                              SemanticsService.announce("$value, minutes",
                                  Directionality.of(context));
                              setState(() => minutes = value);
                            },
                          ),
                        ),
                        const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: Constants.padding),
                            child: Text(":", style: Constants.timeColon)),
                        Expanded(
                          child: NumberPicker(
                            infiniteLoop: true,
                            textStyle: Constants.numberPickerSecondary(
                                context: context),
                            selectedTextStyle:
                            Constants.numberPickerPrimary(context: context),
                            minValue: 0,
                            maxValue: 59,
                            value: seconds,
                            haptics: true,
                            onChanged: (value) {
                              SemanticsService.announce("$value, seconds",
                                  Directionality.of(context));
                              setState(() => seconds = value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Padding(
                            padding:
                            const EdgeInsets.only(right: Constants.padding),
                            child: FilledButton.tonalIcon(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () => Navigator.pop(context, null),
                                label: const AutoSizeText("Cancel",
                                    softWrap: false,
                                    overflow: TextOverflow.visible,
                                    maxLines: 1,
                                    minFontSize: Constants.small)),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding:
                            const EdgeInsets.only(left: Constants.padding),
                            child: FilledButton.icon(
                              icon: const Icon(Icons.done_rounded),
                              onPressed: () {
                                Navigator.pop(context,
                                    (hours * 3600) + (minutes * 60) + seconds);
                              },
                              label: const AutoSizeText("Done",
                                  softWrap: false,
                                  overflow: TextOverflow.visible,
                                  maxLines: 1,
                                  minFontSize: Constants.small),
                            ),
                          ),
                        )
                      ])
                ])));
  }
}