import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:numberpicker/numberpicker.dart';

import '../../util/constants.dart';
import '../../util/enums.dart';

class FrequencyDialog extends StatefulWidget {
  const FrequencyDialog(
      {Key? key,
      this.frequency = Frequency.once,
      this.startDate,
      this.repeatSkip = 1,
      this.weekdays})
      : super(key: key);

  final Frequency frequency;
  final DateTime? startDate;
  final Set<int>? weekdays;
  final int repeatSkip;

  @override
  State<FrequencyDialog> createState() => _FrequencyDialog();
}

class _FrequencyDialog extends State<FrequencyDialog> {
  late Frequency frequency;
  late final DateTime startDate;
  late final Set<int> weekdays;
  late int repeatSkip;

  late TextEditingController dropdownController;

  @override
  void initState() {
    super.initState();
    frequency = widget.frequency;
    startDate = widget.startDate ?? DateTime.now();
    repeatSkip = widget.repeatSkip;
    weekdays = Set.from(widget.weekdays ?? {});
    if (weekdays.isEmpty) {
      weekdays.add(max(startDate.weekday - 1, 0));
    }
    dropdownController = TextEditingController();
  }

  @override
  void dispose() {
    dropdownController.dispose();
    super.dispose();
  }

  @override
  Widget build(context) {
    // DropdownMenu expansion is coming in 3.14.
    double width = MediaQuery.of(context).size.width;
    double dropdownWidth = width * 0.7;

    return Dialog(
        insetPadding: const EdgeInsets.all(Constants.innerPadding),
        child: Padding(
            padding: const EdgeInsets.all(Constants.innerPadding),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AutoSizeText(
                            "Set Recurring",
                            softWrap: false,
                            maxLines: 1,
                            minFontSize: Constants.medium,
                            overflow: TextOverflow.visible,
                            style: Constants.headerStyle,
                          ),
                        )
                      ]),
                  const Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: AutoSizeText(
                          "Repeat:",
                          softWrap: false,
                          maxLines: 1,
                          minFontSize: Constants.medium,
                          overflow: TextOverflow.visible,
                          style: Constants.largeHeaderStyle,
                        ),
                      ),
                      Flexible(
                        child: FittedBox(
                            fit: BoxFit.fill,
                            child: Icon(Icons.repeat_rounded,
                                size: Constants.medIconSize)),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(Constants.innerPadding),
                    child: DropdownMenu<Frequency>(
                        textStyle: Constants.headerStyle,
                        inputDecorationTheme: Theme.of(context)
                            .inputDecorationTheme
                            .copyWith(
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(
                                            Constants.roundedCorners)),
                                    borderSide: BorderSide(
                                      width: 2,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant,
                                      strokeAlign:
                                          BorderSide.strokeAlignOutside,
                                    )),
                                border: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(
                                            Constants.roundedCorners)),
                                    borderSide: BorderSide(
                                      strokeAlign:
                                          BorderSide.strokeAlignOutside,
                                    ))),
                        width: dropdownWidth,
                        initialSelection: frequency,
                        label: const Text("Frequency"),
                        controller: dropdownController,
                        hintText: "Frequency",
                        dropdownMenuEntries: Frequency.values
                            .map((Frequency frequency) => DropdownMenuEntry(
                                value: frequency,
                                label:
                                    toBeginningOfSentenceCase(frequency.name)!))
                            .toList(),
                        onSelected: (Frequency? newFrequency) {
                          if (null != newFrequency) {
                            frequency = newFrequency;
                          }
                          dropdownController.value = dropdownController.value
                              .copyWith(
                                  text: toBeginningOfSentenceCase(
                                      frequency.name)!,
                                  selection: TextSelection.collapsed(
                                      offset: frequency.name.length));
                          if (mounted) {
                            setState(() {});
                          }
                        }),
                  ),

                  (frequency == Frequency.custom)
                      ? Column(
                          children: [
                            // Days of the week - Wrap in padding and a container
                            Padding(
                              padding: const EdgeInsets.all(Constants.padding),
                              child: Wrap(
                                  spacing: 5,
                                  runSpacing: 5,
                                  alignment: WrapAlignment.center,
                                  runAlignment: WrapAlignment.center,
                                  children: Constants.weekDays
                                      .map((weekDay) => InputChip(
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .surfaceVariant,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(
                                                    Constants.circular)),
                                            side: BorderSide(
                                              strokeAlign:
                                                  BorderSide.strokeAlignOutside,
                                            ),
                                          ),
                                          label: AutoSizeText(weekDay.key,
                                              minFontSize: Constants.small,
                                              maxLines: 1,
                                              softWrap: false,
                                              overflow: TextOverflow.visible),
                                          selected:
                                              weekdays.contains(weekDay.value),
                                          onSelected: (bool selected) {
                                            if (mounted) {
                                              setState(() {
                                                if (selected) {
                                                  weekdays.add(weekDay.value);
                                                } else {
                                                  weekdays
                                                      .remove(weekDay.value);
                                                  if (weekdays.isEmpty) {
                                                    weekdays.add(max(
                                                        startDate.weekday - 1,
                                                        0));
                                                  }
                                                }
                                              });
                                            }
                                          }))
                                      .toList()),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),

                  // Repeat Skip
                  (frequency != Frequency.once && frequency != Frequency.daily)
                      ? Padding(
                          padding: const EdgeInsets.all(Constants.padding),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Flexible(
                                  child: AutoSizeText(
                                "Every",
                                minFontSize: Constants.small,
                                style: Constants.headerStyle,
                                overflow: TextOverflow.visible,
                                softWrap: false,
                                maxLines: 1,
                              )),
                              Expanded(
                                  child: NumberPicker(
                                      itemCount: 1,
                                      textStyle:
                                          Constants.numberPickerSecondary(
                                              context: context),
                                      selectedTextStyle:
                                          Constants.numberPickerPrimary(
                                              context: context),
                                      minValue: 1,
                                      maxValue: 100,
                                      value: repeatSkip,
                                      haptics: true,
                                      onChanged: (value) {
                                        SemanticsService.announce(
                                            "Skip value: $value",
                                            Directionality.of(context));
                                        if (mounted) {
                                          setState(() => repeatSkip = value);
                                        }
                                      })),
                              Flexible(
                                child: AutoSizeText(
                                  (frequency == Frequency.custom)
                                      ? "week${(repeatSkip > 1) ? "s." : "."}"
                                      : frequency.name.replaceAll(
                                          "ly", (repeatSkip > 1) ? "s." : "."),
                                  minFontSize: Constants.small,
                                  style: Constants.headerStyle,
                                  overflow: TextOverflow.visible,
                                  softWrap: false,
                                  maxLines: 1,
                                  textAlign: TextAlign.end,
                                ),
                              )
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),

                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.only(right: Constants.padding),
                            child: FilledButton.tonalIcon(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
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
                                Navigator.pop(context, {
                                  "frequency": frequency,
                                  "weekdays": weekdays,
                                  "repeatSkip": repeatSkip,
                                });
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
