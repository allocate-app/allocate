import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:numberpicker/numberpicker.dart';

import '../../model/task/subtask.dart';
import '../../util/constants.dart';
import '../../util/enums.dart';
import 'drain_bar.dart';

class Tiles {
  /// ListView Tiles

  /// Checkboxes
  static checkboxListTile({
    Key? key,
    EdgeInsetsGeometry contentPadding = EdgeInsets.zero,
    Widget? title,
    required void Function(bool? value) onChanged,
    bool? value,
    Widget? secondary,
  }) =>
      CheckboxListTile(
          contentPadding: contentPadding,
          key: key,
          checkboxShape: const CircleBorder(),
          controlAffinity: ListTileControlAffinity.leading,
          shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(Constants.roundedCorners))),
          title: title,
          value: value,
          onChanged: onChanged,

          // Delete Subtask
          secondary: secondary);

  static CheckboxListTile subtaskCheckboxTile(
          {required BuildContext context,
          required int index,
          required SubTask subTask,
          required void Function() onChanged,
          required void Function() onSubtaskWeightChanged,
          required void Function({required int index}) onRemoved,
          required TextEditingController controller,
          bool showHandle = false}) =>
      Tiles.checkboxListTile(
          key: ValueKey(index),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: Constants.innerPadding),
          onChanged: (bool? value) {
            subTask.completed = value!;
            onChanged();
          },
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
            child: AutoSizeTextField(
                controller: controller,
                minLines: 1,
                maxLines: 3,
                minFontSize: Constants.large,
                decoration: const InputDecoration.collapsed(
                  hintText: "Step name",
                ),
                onChanged: (value) {
                  subTask.name = value;
                  controller.value = controller.value.copyWith(
                    text: value,
                    selection: TextSelection.collapsed(offset: value.length),
                  );
                  onChanged();
                }),
          ),
          value: subTask.completed,
          secondary: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.adaptivePlatformDensity,
                icon: Constants.batteryIcons[subTask.weight]!,
                selectedIcon: Constants.selectedBatteryIcons[subTask.weight]!,
                onPressed: () {
                  double cacheWeight = subTask.weight.toDouble();
                  showModalBottomSheet<void>(
                      showDragHandle: true,
                      context: context,
                      builder: (BuildContext context) {
                        return StatefulBuilder(
                          builder: (BuildContext context,
                                  void Function(void Function()) setState) =>
                              Center(
                                  heightFactor: 1,
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text("Step Drain",
                                            style: Constants.headerStyle),
                                        Padding(
                                            padding: const EdgeInsets.all(
                                                Constants.padding),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                const Icon(
                                                    Icons.battery_full_rounded),
                                                Expanded(
                                                  child: Slider(
                                                    value: cacheWeight,
                                                    max: Constants.maxTaskWeight
                                                        .toDouble(),
                                                    label:
                                                        "${cacheWeight.toInt()} ${(cacheWeight > (Constants.maxTaskWeight / 2).floor()) ? Constants.lowBattery : Constants.fullBattery}",
                                                    divisions:
                                                        Constants.maxTaskWeight,
                                                    onChanged: (value) =>
                                                        setState(() {
                                                      cacheWeight = value;
                                                    }),
                                                  ),
                                                ),
                                                const Icon(Icons
                                                    .battery_1_bar_rounded),
                                              ],
                                            )),
                                      ])),
                        );
                      }).whenComplete(() {
                    subTask.weight = cacheWeight.toInt();
                    onSubtaskWeightChanged();
                  });
                },
              ),
              IconButton(
                  visualDensity: VisualDensity.adaptivePlatformDensity,
                  icon: const Icon(Icons.delete_rounded),
                  onPressed: () => onRemoved(index: index)),
              (showHandle)
                  ? ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle_rounded))
                  : const SizedBox.shrink(),
            ],
          ));

  /// Model Parameter Tiles
  // Name
  static Widget nameTile({
    required BuildContext context,
    EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
    EdgeInsetsGeometry textFieldPadding = EdgeInsets.zero,
    Widget? leading,
    String? hintText = "",
    String? errorText = "",
    TextEditingController? controller,
    required void Function() handleClear,
  }) =>
      Padding(
        padding: outerPadding,
        child: Row(
          children: [
            leading ?? const SizedBox.shrink(),
            Expanded(
              child: Padding(
                padding: textFieldPadding,
                child: AutoSizeTextField(
                  maxLines: 1,
                  minFontSize: Constants.huge,
                  decoration: InputDecoration(
                    suffixIcon: (controller?.text.isNotEmpty ?? false)
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: handleClear)
                        : null,
                    contentPadding:
                        const EdgeInsets.all(Constants.innerPadding),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                            Radius.circular(Constants.roundedCorners)),
                        borderSide: BorderSide(
                          width: 2,
                          color: Theme.of(context).colorScheme.outlineVariant,
                          strokeAlign: BorderSide.strokeAlignOutside,
                        )),
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                            Radius.circular(Constants.roundedCorners)),
                        borderSide: BorderSide(
                          strokeAlign: BorderSide.strokeAlignOutside,
                        )),
                    hintText: hintText,
                    errorText: errorText,
                  ),
                  controller: controller,
                ),
              ),
            ),
          ],
        ),
      );

  // Weight
  static Widget weightTile({
    EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
    EdgeInsetsGeometry batteryPadding = EdgeInsets.zero,
    required double weight,
    required double max,
    Widget? slider,
    BoxConstraints constraints = const BoxConstraints(),
  }) =>
      Column(children: [
        Padding(
          padding: outerPadding,
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
                  padding: batteryPadding,
                  child: DrainBar(
                    weight: weight,
                    max: max,
                    constraints: constraints,
                  ),
                ),
              ),
            ],
          ),
        ),
        slider ?? const SizedBox.shrink(),
      ]);

  // Weight Slider
  static Widget weightSlider(
          {required double weight,
          required void Function(double value)? handleWeightChange}) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Icon(Icons.battery_full),
          Expanded(
            child: Slider(
                value: weight,
                max: Constants.maxTaskWeight.toDouble(),
                label:
                    "$weight ${(weight > (Constants.maxTaskWeight / 2).floor()) ? Constants.lowBattery : Constants.fullBattery}",
                divisions: Constants.maxTaskWeight,
                onChanged: handleWeightChange),
          ),
          const Icon(Icons.battery_1_bar),
        ],
      );

  // Description
  static Widget descriptionTile(
          {TextEditingController? controller,
          EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
          bool isDense = false,
          required BuildContext context}) =>
      Padding(
        padding: outerPadding,
        child: AutoSizeTextField(
            controller: controller,
            maxLines: Constants.descripMaxLinesBeforeScroll,
            minLines: Constants.descripMinLines,
            minFontSize: Constants.large,
            decoration: InputDecoration(
              isDense: isDense,
              contentPadding: const EdgeInsets.all(Constants.innerPadding),
              hintText: "Description",
              enabledBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(
                      Radius.circular(Constants.roundedCorners)),
                  borderSide: BorderSide(
                    width: 2,
                    color: Theme.of(context).colorScheme.outlineVariant,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  )),
              border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                      Radius.circular(Constants.roundedCorners)),
                  borderSide: BorderSide(
                    strokeAlign: BorderSide.strokeAlignOutside,
                  )),
            )),
      );

  // Duration
  static Widget durationTile(
      {int expectedDuration = 0,
      required BuildContext context,
      int realDuration = 0,
      EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
      required void Function() handleClear,
      required void Function(int? value) handleUpdate}) {
    return Padding(
      padding: outerPadding,
      child: ListTile(
        leading: const Icon(Icons.timer_outlined),
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        title: (expectedDuration > 0)
            ? Row(
                children: [
                  Flexible(
                    child: Tooltip(
                      message: "Expected",
                      child: AutoSizeText(
                          Duration(seconds: expectedDuration)
                              .toString()
                              .split(".")
                              .first,
                          overflow: TextOverflow.visible,
                          minFontSize: Constants.large,
                          maxLines: 1,
                          softWrap: false),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: Constants.innerPadding),
                    child: Icon(
                      Icons.timer_rounded,
                    ),
                  ),
                  Flexible(
                    child: Tooltip(
                      message: "Projected",
                      child: AutoSizeText(
                          Duration(seconds: realDuration)
                              .toString()
                              .split(".")
                              .first,
                          overflow: TextOverflow.visible,
                          minFontSize: Constants.small,
                          maxLines: 1,
                          softWrap: true),
                    ),
                  ),
                ],
              )
            : const AutoSizeText("Expected Duration: ",
                overflow: TextOverflow.visible,
                minFontSize: Constants.small,
                maxLines: 2,
                softWrap: true),
        trailing: (expectedDuration > 0)
            ? IconButton(
                icon: const Icon(Icons.clear_rounded), onPressed: handleClear)
            : const SizedBox.shrink(),
        onTap: () => showDialog<int>(
            context: context,
            builder: (BuildContext context) {
              int time = expectedDuration;
              int hours = time ~/ 3600;
              time %= 3600;
              int minutes = time ~/ 60;
              time %= 60;
              int seconds = time;

              return StatefulBuilder(
                builder: (BuildContext context,
                        void Function(void Function()) setState) =>
                    Dialog(
                        child: Padding(
                            padding:
                                const EdgeInsets.all(Constants.innerPadding),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Expanded(
                                          child: AutoSizeText(
                                            "Expected Duration",
                                            style: Constants.headerStyle,
                                            softWrap: true,
                                            overflow: TextOverflow.visible,
                                            maxLines: 2,
                                            minFontSize: Constants.medium,
                                          ),
                                        )
                                      ]),
                                  const Flexible(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Expanded(
                                            flex: 2,
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
                                                  size: Constants.medIconSize)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: NumberPicker(
                                          textStyle:
                                              Constants.numberPickerSecondary(
                                                  context: context),
                                          selectedTextStyle:
                                              Constants.numberPickerPrimary(
                                                  context: context),
                                          minValue: 0,
                                          maxValue: 100,
                                          value: hours,
                                          haptics: true,
                                          onChanged: (value) {
                                            SemanticsService.announce(
                                                "$value, hours",
                                                Directionality.of(context));
                                            setState(() => hours = value);
                                          },
                                        ),
                                      ),
                                      const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: Constants.padding),
                                          child: Text(":",
                                              style: Constants.timeColon)),
                                      Expanded(
                                        child: NumberPicker(
                                          textStyle:
                                              Constants.numberPickerSecondary(
                                                  context: context),
                                          selectedTextStyle:
                                              Constants.numberPickerPrimary(
                                                  context: context),
                                          minValue: 0,
                                          maxValue: 59,
                                          value: minutes,
                                          haptics: true,
                                          onChanged: (value) {
                                            SemanticsService.announce(
                                                "$value, minutes",
                                                Directionality.of(context));
                                            setState(() => minutes = value);
                                          },
                                        ),
                                      ),
                                      const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: Constants.padding),
                                          child: Text(":",
                                              style: Constants.timeColon)),
                                      Expanded(
                                        child: NumberPicker(
                                          textStyle:
                                              Constants.numberPickerSecondary(
                                                  context: context),
                                          selectedTextStyle:
                                              Constants.numberPickerPrimary(
                                                  context: context),
                                          minValue: 0,
                                          maxValue: 59,
                                          value: seconds,
                                          haptics: true,
                                          onChanged: (value) {
                                            SemanticsService.announce(
                                                "$value, seconds",
                                                Directionality.of(context));
                                            setState(() => seconds = value);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                right: Constants.padding),
                                            child: FilledButton.tonalIcon(
                                                icon: const Icon(
                                                    Icons.close_rounded),
                                                onPressed: () =>
                                                    Navigator.pop(context, 0),
                                                label: const AutoSizeText(
                                                    "Cancel",
                                                    softWrap: false,
                                                    overflow:
                                                        TextOverflow.visible,
                                                    maxLines: 1,
                                                    minFontSize:
                                                        Constants.small)),
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                left: Constants.padding),
                                            child: FilledButton.icon(
                                              icon: const Icon(
                                                  Icons.done_rounded),
                                              onPressed: () {
                                                Navigator.pop(
                                                    context,
                                                    (hours * 3600) +
                                                        (minutes * 60) +
                                                        seconds);
                                              },
                                              label: const AutoSizeText("Done",
                                                  softWrap: false,
                                                  overflow:
                                                      TextOverflow.visible,
                                                  maxLines: 1,
                                                  minFontSize: Constants.small),
                                            ),
                                          ),
                                        )
                                      ])
                                ]))),
              );
            }).then(handleUpdate),
      ),
    );
  }

  // DATE-RANGE TILE
  static Widget dateRangeTile({
    EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
    required BuildContext context,
    DateTime? startDate,
    DateTime? dueDate,
    required void Function() handleClear,
    required void Function(
            {bool? checkClose, DateTime? newStart, DateTime? newDue})
        handleUpdate,
  }) =>
      Padding(
        padding: outerPadding,
        child: ListTile(
          leading: const Icon(Icons.today_rounded),
          shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(Constants.roundedCorners))),
          title: (null == startDate && null == dueDate)
              ? const AutoSizeText(
                  "Add Dates",
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  maxLines: 2,
                  minFontSize: Constants.small,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    (null == startDate)
                        ? const Flexible(
                            child: AutoSizeText(
                              "Start?",
                              softWrap: true,
                              overflow: TextOverflow.visible,
                              maxLines: 2,
                              minFontSize: Constants.small,
                            ),
                          )
                        : Flexible(
                            child: AutoSizeText(
                                Jiffy.parseFromDateTime(startDate)
                                    .toLocal()
                                    .format(
                                      pattern: "MMM d",
                                    ),
                                softWrap: false,
                                overflow: TextOverflow.visible,
                                maxLines: 1,
                                minFontSize: Constants.huge)),
                    const Padding(
                      padding: EdgeInsets.all(Constants.padding),
                      child: Text(
                        "-",
                        softWrap: false,
                        overflow: TextOverflow.visible,
                        maxLines: 1,
                      ),
                    ),
                    (null == dueDate)
                        ? const Flexible(
                            child: Padding(
                              padding:
                                  EdgeInsets.only(right: Constants.padding),
                              child: Icon(Icons.today_rounded),
                            ),
                          )
                        : const Flexible(
                            child: Padding(
                            padding: EdgeInsets.only(right: Constants.padding),
                            child: Icon(Icons.event_rounded),
                          )),
                    (null == dueDate)
                        ? const Flexible(
                            child: AutoSizeText(
                              "Due?",
                              softWrap: true,
                              overflow: TextOverflow.visible,
                              maxLines: 2,
                              minFontSize: Constants.small,
                            ),
                          )
                        : Flexible(
                            child: AutoSizeText(
                                Jiffy.parseFromDateTime(dueDate)
                                    .toLocal()
                                    .format(pattern: "MMM d"),
                                softWrap: false,
                                overflow: TextOverflow.visible,
                                maxLines: 1,
                                minFontSize: Constants.huge),
                          )
                  ],
                ),
          trailing: (startDate != null || dueDate != null)
              ? IconButton(
                  icon: const Icon(Icons.clear), onPressed: handleClear)
              : null,
          onTap: () {
            showDialog<void>(
                context: context,
                builder: (BuildContext context) {
                  DateTime? tmpStart = startDate;
                  DateTime? tmpDue = dueDate;
                  DateTime initDate = tmpStart ?? tmpDue ?? DateTime.now();
                  bool setStart = false;
                  final int numDays =
                      (tmpDue?.difference(initDate).inDays ?? 0) + 1;
                  List<DateTime?> showDates = List.generate(
                      numDays, (i) => initDate.copyWith(day: initDate.day + 1));

                  // List ->
                  return StatefulBuilder(
                      builder: (BuildContext context,
                              void Function(void Function()) setState) =>
                          Dialog(
                              insetPadding:
                                  const EdgeInsets.all(Constants.innerPadding),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    Constants.innerPadding),
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Expanded(
                                              child: AutoSizeText(
                                                "Select Dates",
                                                style: Constants.headerStyle,
                                                softWrap: true,
                                                overflow: TextOverflow.visible,
                                                maxLines: 2,
                                                minFontSize: Constants.medium,
                                              ),
                                            )
                                          ]),
                                      const Flexible(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Flexible(
                                                child: AutoSizeText(
                                              "Start | Due ",
                                              style: Constants.largeHeaderStyle,
                                              softWrap: true,
                                              overflow: TextOverflow.visible,
                                              maxLines: 1,
                                              minFontSize: Constants.large,
                                            )),
                                            Flexible(
                                              child: FittedBox(
                                                  fit: BoxFit.fill,
                                                  child: Icon(
                                                      Icons.date_range_rounded,
                                                      size: Constants
                                                          .medIconSize)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: Constants.innerPadding),
                                        child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Expanded(
                                                flex: 10,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius
                                                        .circular(Constants
                                                            .roundedCorners),
                                                    border: Border.all(
                                                        width: 2,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .outlineVariant,
                                                        strokeAlign: BorderSide
                                                            .strokeAlignOutside),
                                                  ),
                                                  child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        Expanded(
                                                          child: TextButton(
                                                              onPressed: () =>
                                                                  setState(() {
                                                                    setStart =
                                                                        true;
                                                                    tmpStart = tmpStart ??
                                                                        DateTime
                                                                            .now();
                                                                  }),
                                                              child: (null !=
                                                                      tmpStart)
                                                                  ? AutoSizeText(
                                                                      Jiffy.parseFromDateTime(
                                                                              tmpStart!)
                                                                          .toLocal()
                                                                          .format(
                                                                              pattern: "MMM d, yyyy"),
                                                                      softWrap:
                                                                          false,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .visible,
                                                                      maxLines:
                                                                          1,
                                                                      minFontSize:
                                                                          Constants
                                                                              .small,
                                                                    )
                                                                  : const AutoSizeText(
                                                                      "Start Date",
                                                                      softWrap:
                                                                          true,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .visible,
                                                                      maxLines:
                                                                          1,
                                                                      minFontSize:
                                                                          Constants
                                                                              .small)),
                                                        ),
                                                        (tmpStart != null)
                                                            ? IconButton(
                                                                icon: const Icon(
                                                                    Icons
                                                                        .clear_rounded),
                                                                selectedIcon:
                                                                    const Icon(Icons
                                                                        .clear),
                                                                onPressed: () =>
                                                                    setState(
                                                                        () {
                                                                  showDates.remove(
                                                                      tmpStart);
                                                                  tmpStart =
                                                                      null;
                                                                }),
                                                              )
                                                            : const SizedBox
                                                                .shrink(),
                                                      ]),
                                                ),
                                              ),
                                              const Flexible(
                                                flex: 1,
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: Constants
                                                          .halfPadding),
                                                  child: AutoSizeText("|",
                                                      style: Constants
                                                          .largeHeaderStyle,
                                                      softWrap: false,
                                                      overflow:
                                                          TextOverflow.visible,
                                                      maxLines: 1,
                                                      minFontSize:
                                                          Constants.small),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 10,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius
                                                        .circular(Constants
                                                            .roundedCorners),
                                                    border: Border.all(
                                                        width: 2,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .outlineVariant,
                                                        strokeAlign: BorderSide
                                                            .strokeAlignOutside),
                                                  ),
                                                  child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        Expanded(
                                                          child: TextButton(
                                                              onPressed: () =>
                                                                  setState(() {
                                                                    setStart =
                                                                        false;
                                                                    tmpDue = tmpDue ??
                                                                        DateTime
                                                                            .now();
                                                                  }),
                                                              child: (null !=
                                                                      tmpDue)
                                                                  ? AutoSizeText(
                                                                      Jiffy.parseFromDateTime(
                                                                              tmpDue!)
                                                                          .toLocal()
                                                                          .format(
                                                                              pattern: "MMM d, yyyy"),
                                                                      softWrap:
                                                                          false,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .visible,
                                                                      maxLines:
                                                                          1,
                                                                      minFontSize:
                                                                          Constants
                                                                              .small,
                                                                    )
                                                                  : const AutoSizeText(
                                                                      "Due Date",
                                                                      softWrap:
                                                                          true,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .visible,
                                                                      maxLines:
                                                                          1,
                                                                      minFontSize:
                                                                          Constants
                                                                              .small)),
                                                        ),
                                                        (tmpDue != null)
                                                            ? IconButton(
                                                                icon: const Icon(
                                                                    Icons
                                                                        .clear_rounded),
                                                                selectedIcon:
                                                                    const Icon(Icons
                                                                        .clear),
                                                                onPressed: () =>
                                                                    setState(
                                                                        () {
                                                                  showDates
                                                                      .remove(
                                                                          tmpDue);
                                                                  tmpDue = null;
                                                                }),
                                                              )
                                                            : const SizedBox
                                                                .shrink(),
                                                      ]),
                                                ),
                                              ),
                                            ]),
                                      ),

                                      // Calendar view.
                                      Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CalendarDatePicker2(
                                                config:
                                                    CalendarDatePicker2Config(
                                                  calendarType:
                                                      CalendarDatePicker2Type
                                                          .range,
                                                  firstDate: DateTime(1970),
                                                  lastDate: DateTime(3000),
                                                ),
                                                value: showDates,
                                                onValueChanged: (dates) {
                                                  setState(() {
                                                    if (dates.length > 1) {
                                                      tmpStart = dates.first;
                                                      tmpDue = dates.last;
                                                    } else {
                                                      (setStart)
                                                          ? tmpStart =
                                                              dates.first
                                                          : tmpDue =
                                                              dates.first;
                                                    }
                                                    showDates = dates;
                                                  });
                                                }),
                                          ]),

                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    right: Constants.padding),
                                                child: FilledButton.tonalIcon(
                                                    icon: const Icon(
                                                        Icons.close_rounded),
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      handleUpdate(
                                                        newStart: startDate,
                                                        newDue: dueDate,
                                                      );
                                                    },
                                                    label: const AutoSizeText(
                                                        "Cancel",
                                                        softWrap: false,
                                                        overflow: TextOverflow
                                                            .visible,
                                                        maxLines: 1,
                                                        minFontSize:
                                                            Constants.small)),
                                              ),
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    left: Constants.padding),
                                                child: FilledButton.icon(
                                                  icon: const Icon(
                                                      Icons.done_rounded),
                                                  // This needs to change.
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    handleUpdate(
                                                        checkClose: true,
                                                        newStart: tmpStart,
                                                        newDue: tmpDue);
                                                  },
                                                  label: const AutoSizeText(
                                                      "Done",
                                                      softWrap: false,
                                                      overflow:
                                                          TextOverflow.visible,
                                                      maxLines: 1,
                                                      minFontSize:
                                                          Constants.small),
                                                ),
                                              ),
                                            )
                                          ]),
                                    ]),
                              )));
                  // This is to update the main context after updating.
                });
          },
        ),
      );

  // TIME-RANGE TILE
  static Widget timeTile({
    TimeOfDay? startTime,
    TimeOfDay? dueTime,
    EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
    required BuildContext context,
    required void Function() handleClear,
    required void Function(
            {bool checkClose, TimeOfDay? newStart, TimeOfDay? newDue})
        handleUpdate,
  }) =>
      Padding(
        padding: outerPadding,
        child: ListTile(
            leading: const Icon(Icons.schedule_rounded),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                    Radius.circular(Constants.roundedCorners))),
            title: (null == startTime && null == dueTime)
                ? const AutoSizeText(
                    "Add Times",
                    overflow: TextOverflow.visible,
                    minFontSize: Constants.small,
                    maxLines: 2,
                    softWrap: true,
                  )
                : Row(children: [
                    (null == startTime)
                        ? const Flexible(
                            child: AutoSizeText(
                            "Start?",
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            maxLines: 1,
                            minFontSize: Constants.small,
                          ))
                        : Flexible(
                            child: AutoSizeText(
                            startTime.format(context).toString(),
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            maxLines: 1,
                            minFontSize: Constants.large,
                          )),
                    (null == dueTime)
                        ? const Flexible(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: Constants.padding),
                              child: FittedBox(
                                  fit: BoxFit.fill,
                                  child:
                                      Icon(Icons.history_toggle_off_rounded)),
                            ),
                          )
                        : const Flexible(
                            child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: Constants.padding),
                            child: FittedBox(
                                fit: BoxFit.fill,
                                child: Icon(Icons.schedule_rounded)),
                          )),
                    (null == dueTime)
                        ? const Flexible(
                            child: AutoSizeText(
                              "Due?",
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              maxLines: 1,
                              minFontSize: Constants.small,
                            ),
                          )
                        : Flexible(
                            child: AutoSizeText(
                              dueTime.format(context).toString(),
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              maxLines: 1,
                              minFontSize: Constants.small,
                            ),
                          ),
                  ]),
            onTap: () {
              showDialog<void>(
                  context: context,
                  builder: (BuildContext context) {
                    TimeOfDay? tmpStart = startTime;
                    TimeOfDay? tmpDue = dueTime;
                    return StatefulBuilder(
                        builder: (BuildContext context,
                                void Function(void Function()) setState) =>
                            Dialog(
                                insetPadding: const EdgeInsets.all(
                                    Constants.innerPadding),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                      Constants.innerPadding),
                                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Expanded(
                                                child: AutoSizeText(
                                                  "Select Times",
                                                  style: Constants.headerStyle,
                                                  softWrap: true,
                                                  overflow:
                                                      TextOverflow.visible,
                                                  maxLines: 2,
                                                  minFontSize: Constants.medium,
                                                ),
                                              )
                                            ]),
                                        const Flexible(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Flexible(
                                                  child: AutoSizeText(
                                                "Start | Due ",
                                                style:
                                                    Constants.largeHeaderStyle,
                                                softWrap: true,
                                                overflow: TextOverflow.visible,
                                                maxLines: 1,
                                                minFontSize: Constants.large,
                                              )),
                                              Flexible(
                                                child: FittedBox(
                                                    fit: BoxFit.fill,
                                                    child: Icon(
                                                        Icons.schedule_rounded,
                                                        size: Constants
                                                            .medIconSize)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: Constants.innerPadding),
                                          child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Expanded(
                                                  flex: 10,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius
                                                          .circular(Constants
                                                              .roundedCorners),
                                                      border: Border.all(
                                                          width: 2,
                                                          color: Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .outlineVariant,
                                                          strokeAlign: BorderSide
                                                              .strokeAlignOutside),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        Expanded(
                                                          child: TextButton(
                                                              onPressed:
                                                                  () async {
                                                                final TimeOfDay?
                                                                    picked =
                                                                    await showTimePicker(
                                                                        context:
                                                                            context,
                                                                        initialTime:
                                                                            tmpStart ??
                                                                                Constants.midnight);
                                                                if (null !=
                                                                    picked) {
                                                                  setState(() =>
                                                                      tmpStart =
                                                                          picked);
                                                                }
                                                              },
                                                              child: (null !=
                                                                      tmpStart)
                                                                  ? AutoSizeText(
                                                                      tmpStart!
                                                                          .format(
                                                                              context)
                                                                          .toString(),
                                                                      softWrap:
                                                                          false,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .visible,
                                                                      maxLines:
                                                                          1,
                                                                      minFontSize:
                                                                          Constants
                                                                              .small,
                                                                    )
                                                                  : const AutoSizeText(
                                                                      "Start Time",
                                                                      softWrap:
                                                                          true,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .visible,
                                                                      maxLines:
                                                                          1,
                                                                      minFontSize:
                                                                          Constants
                                                                              .small)),
                                                        ),
                                                        (tmpStart != null)
                                                            ? IconButton(
                                                                icon: const Icon(
                                                                    Icons
                                                                        .clear_rounded),
                                                                selectedIcon:
                                                                    const Icon(Icons
                                                                        .clear),
                                                                onPressed: () =>
                                                                    setState(
                                                                        () {
                                                                  tmpStart =
                                                                      null;
                                                                }),
                                                              )
                                                            : const SizedBox
                                                                .shrink(),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: Constants
                                                          .halfPadding),
                                                  child: Text("|",
                                                      style:
                                                          Constants.timeColon),
                                                ),
                                                Expanded(
                                                  flex: 10,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius
                                                          .circular(Constants
                                                              .roundedCorners),
                                                      border: Border.all(
                                                          width: 2,
                                                          color: Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .outlineVariant,
                                                          strokeAlign: BorderSide
                                                              .strokeAlignOutside),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        Expanded(
                                                          child: TextButton(
                                                              onPressed:
                                                                  () async {
                                                                final TimeOfDay?
                                                                    picked =
                                                                    await showTimePicker(
                                                                        context:
                                                                            context,
                                                                        initialTime:
                                                                            tmpDue ??
                                                                                Constants.midnight);
                                                                if (null !=
                                                                    picked) {
                                                                  setState(() =>
                                                                      tmpDue =
                                                                          picked);
                                                                }
                                                              },
                                                              child: (null !=
                                                                      tmpDue)
                                                                  ? AutoSizeText(
                                                                      tmpDue!
                                                                          .format(
                                                                              context)
                                                                          .toString(),
                                                                      softWrap:
                                                                          false,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .visible,
                                                                      maxLines:
                                                                          1,
                                                                      minFontSize:
                                                                          Constants
                                                                              .small,
                                                                    )
                                                                  : const AutoSizeText(
                                                                      "Due Time",
                                                                      softWrap:
                                                                          true,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .visible,
                                                                      maxLines:
                                                                          1,
                                                                      minFontSize:
                                                                          Constants
                                                                              .small)),
                                                        ),
                                                        (tmpDue != null)
                                                            ? IconButton(
                                                                icon: const Icon(
                                                                    Icons
                                                                        .clear_rounded),
                                                                selectedIcon:
                                                                    const Icon(Icons
                                                                        .clear),
                                                                onPressed: () =>
                                                                    setState(
                                                                        () {
                                                                  tmpDue = null;
                                                                }),
                                                              )
                                                            : const SizedBox
                                                                .shrink(),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ]),
                                        ),
                                        Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Expanded(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: Constants
                                                              .padding),
                                                  child: FilledButton.tonalIcon(
                                                      icon: const Icon(
                                                          Icons.close_rounded),
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                        handleUpdate(
                                                            newStart: startTime,
                                                            newDue: dueTime);
                                                      },
                                                      label: const AutoSizeText(
                                                          "Cancel",
                                                          softWrap: false,
                                                          overflow: TextOverflow
                                                              .visible,
                                                          maxLines: 1,
                                                          minFontSize:
                                                              Constants.small)),
                                                ),
                                              ),
                                              Expanded(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: Constants
                                                              .padding),
                                                  child: FilledButton.icon(
                                                    icon: const Icon(
                                                        Icons.done_rounded),
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      handleUpdate(
                                                          checkClose: true,
                                                          newStart: tmpStart,
                                                          newDue: tmpDue);
                                                    },
                                                    label: const AutoSizeText(
                                                        "Done",
                                                        softWrap: false,
                                                        overflow: TextOverflow
                                                            .visible,
                                                        maxLines: 1,
                                                        minFontSize:
                                                            Constants.small),
                                                  ),
                                                ),
                                              )
                                            ]),
                                      ]),
                                )));
                  });
            },
            trailing: (startTime != null || dueTime != null)
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: handleClear,
                  )
                : null),
      );

  // SINGLE DATE TILE - TBD

  // REPEATABLE
  static Widget repeatableTile({
    required BuildContext context,
    EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
    required Frequency frequency,
    required Set<int> weekdayList,
    DateTime? startDate,
    required int repeatSkip,
    required void Function(
            {bool? checkClose,
            required Frequency newFreq,
            required Set<int> newWeekdays,
            required int newSkip})
        handleUpdate,
    required void Function() handleClear,
  }) {
    return Padding(
      padding: outerPadding,
      child: ListTile(
          leading: const Icon(Icons.event_repeat_rounded),
          shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(Constants.roundedCorners))),
          title: (frequency == Frequency.once)
              ? const AutoSizeText("Set Recurring?",
                  overflow: TextOverflow.visible,
                  minFontSize: Constants.small,
                  maxLines: 2,
                  softWrap: true)
              : AutoSizeText(toBeginningOfSentenceCase(frequency.name)!,
                  overflow: TextOverflow.visible,
                  minFontSize: Constants.small,
                  maxLines: 1,
                  softWrap: false),
          onTap: () {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  Frequency cacheFreq = frequency;
                  Set<int> cacheWeekdays = Set.from(weekdayList);
                  if (cacheWeekdays.isEmpty) {
                    int day = (null != startDate)
                        ? max(startDate.weekday - 1, 0)
                        : max(DateTime.now().weekday - 1, 0);
                    cacheWeekdays.add(day);
                  }

                  int cacheSkip = repeatSkip;
                  return StatefulBuilder(builder: (BuildContext context,
                      void Function(void Function()) setState) {
                    return Dialog(
                        child: Padding(
                            padding:
                                const EdgeInsets.all(Constants.innerPadding),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                  // This is a hacky override until m3 Has width-scaling for DropdownMenu
                                  Padding(
                                    padding: (cacheFreq != Frequency.once &&
                                            cacheFreq != Frequency.daily)
                                        ? const EdgeInsets.fromLTRB(
                                            Constants.innerPadding,
                                            Constants.innerPadding,
                                            Constants.innerPadding,
                                            Constants.halfPadding)
                                        : const EdgeInsets.all(
                                            Constants.innerPadding),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          width: 2,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outlineVariant,
                                          strokeAlign:
                                              BorderSide.strokeAlignOutside,
                                        ),
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(
                                                Constants.circular)),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(
                                            Constants.innerPadding),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<Frequency>(
                                            focusColor: Colors.transparent,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: Constants.padding),
                                            isDense: true,
                                            isExpanded: true,
                                            dropdownColor:
                                                Constants.dialogColor(
                                                    context: context),
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(Constants
                                                        .roundedCorners)),
                                            value: cacheFreq,
                                            onChanged: (Frequency? value) =>
                                                setState(() => cacheFreq =
                                                    value ?? cacheFreq),
                                            items: Frequency.values
                                                .map((Frequency frequency) =>
                                                    DropdownMenuItem<Frequency>(
                                                      value: frequency,
                                                      child: AutoSizeText(
                                                        "${toBeginningOfSentenceCase(frequency.name)}",
                                                        softWrap: false,
                                                        maxLines: 1,
                                                        minFontSize:
                                                            Constants.small,
                                                      ),
                                                    ))
                                                .toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  (cacheFreq == Frequency.custom)
                                      ? Column(
                                          children: [
                                            // Days of the week - Wrap in padding and a container
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      Constants.innerPadding,
                                                      Constants.innerPadding,
                                                      Constants.innerPadding,
                                                      0),
                                              child: Wrap(
                                                  spacing: 5,
                                                  runSpacing: 5,
                                                  alignment:
                                                      WrapAlignment.center,
                                                  runAlignment:
                                                      WrapAlignment.center,
                                                  children: Constants.weekDays
                                                      .map(
                                                          (weekDay) =>
                                                              InputChip(
                                                                  backgroundColor: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .surfaceVariant,
                                                                  shape:
                                                                      const RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.all(
                                                                            Radius.circular(Constants.circular)),
                                                                    side:
                                                                        BorderSide(
                                                                      strokeAlign:
                                                                          BorderSide
                                                                              .strokeAlignOutside,
                                                                    ),
                                                                  ),
                                                                  label: AutoSizeText(
                                                                      weekDay
                                                                          .key,
                                                                      minFontSize:
                                                                          Constants
                                                                              .small,
                                                                      maxLines:
                                                                          1,
                                                                      softWrap:
                                                                          false,
                                                                      overflow: TextOverflow
                                                                          .visible),
                                                                  selected: cacheWeekdays
                                                                      .contains(weekDay
                                                                          .value),
                                                                  onSelected:
                                                                      (bool selected) =>
                                                                          setState(
                                                                              () {
                                                                            if (selected) {
                                                                              cacheWeekdays.add(weekDay.value);
                                                                            } else {
                                                                              cacheWeekdays.remove(weekDay.value);
                                                                              if (cacheWeekdays.isEmpty) {
                                                                                int day = (null != startDate) ? max(startDate.weekday - 1, 0) : max(DateTime.now().weekday - 1, 0);
                                                                                cacheWeekdays.add(day);
                                                                              }
                                                                            }
                                                                          })))
                                                      .toList()),
                                            ),
                                          ],
                                        )
                                      : const SizedBox.shrink(),

                                  // Repeat Skip
                                  (cacheFreq != Frequency.once &&
                                          cacheFreq != Frequency.daily)
                                      ? Padding(
                                          padding: const EdgeInsets.all(
                                              Constants.innerPadding),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
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
                                                      textStyle: Constants
                                                          .numberPickerSecondary(
                                                              context: context),
                                                      selectedTextStyle: Constants
                                                          .numberPickerPrimary(
                                                              context: context),
                                                      minValue: 1,
                                                      maxValue: 100,
                                                      value: cacheSkip,
                                                      haptics: true,
                                                      onChanged: (value) {
                                                        SemanticsService.announce(
                                                            "Skip value: $value",
                                                            Directionality.of(
                                                                context));
                                                        setState(() =>
                                                            cacheSkip = value);
                                                      })),
                                              Flexible(
                                                child: AutoSizeText(
                                                  (cacheFreq ==
                                                          Frequency.custom)
                                                      ? "week${(cacheSkip > 1) ? "s." : "."}"
                                                      : cacheFreq.name
                                                          .replaceAll(
                                                              "ly",
                                                              (cacheSkip > 1)
                                                                  ? "s."
                                                                  : "."),
                                                  minFontSize: Constants.small,
                                                  style: Constants.headerStyle,
                                                  overflow:
                                                      TextOverflow.visible,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                right: Constants.padding),
                                            child: FilledButton.tonalIcon(
                                                icon: const Icon(
                                                    Icons.close_rounded),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  handleUpdate(
                                                      newFreq: frequency,
                                                      newWeekdays: weekdayList,
                                                      newSkip: repeatSkip);
                                                },
                                                label: const AutoSizeText(
                                                    "Cancel",
                                                    softWrap: false,
                                                    overflow:
                                                        TextOverflow.visible,
                                                    maxLines: 1,
                                                    minFontSize:
                                                        Constants.small)),
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                left: Constants.padding),
                                            child: FilledButton.icon(
                                              icon: const Icon(
                                                  Icons.done_rounded),
                                              onPressed: () {
                                                Navigator.pop(context);
                                                handleUpdate(
                                                    checkClose: true,
                                                    newFreq: cacheFreq,
                                                    newWeekdays: cacheWeekdays,
                                                    newSkip: cacheSkip);
                                              },
                                              label: const AutoSizeText("Done",
                                                  softWrap: false,
                                                  overflow:
                                                      TextOverflow.visible,
                                                  maxLines: 1,
                                                  minFontSize: Constants.small),
                                            ),
                                          ),
                                        )
                                      ])
                                ])));
                  });
                });
          },
          trailing: (frequency != Frequency.once)
              ? IconButton(
                  icon: const Icon(Icons.clear), onPressed: handleClear)
              : null),
    );
  }

  // Priority
  static Widget priorityTile({
    required BuildContext context,
    EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
    required Priority priority,
    required void Function(Set<Priority> newSelection) onSelectionChanged,
  }) =>
      Padding(
        padding: outerPadding,
        child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(children: [
                Expanded(
                    child: AutoSizeText("Priority",
                        style: Constants.headerStyle,
                        maxLines: 1,
                        softWrap: true,
                        textAlign: TextAlign.center,
                        minFontSize: Constants.medium))
              ]),
              SegmentedButton<Priority>(
                  selectedIcon: const Icon(Icons.flag_circle_rounded),
                  style: ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.adaptivePlatformDensity,
                    side: MaterialStatePropertyAll<BorderSide>(BorderSide(
                      width: 2,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    )),
                  ),
                  segments: Priority.values
                      .map((Priority type) => ButtonSegment<Priority>(
                          icon: Constants.priorityIcon[type],
                          value: type,
                          label: Text(
                            "${toBeginningOfSentenceCase(type.name)}",
                            softWrap: false,
                            overflow: TextOverflow.fade,
                          )))
                      .toList(growable: false),
                  selected: <Priority>{priority},
                  onSelectionChanged: onSelectionChanged)
            ]),
      );

  // MY DAY
  static Widget myDayTile(
      {required bool myDay,
      required bool canAdd,
      required void Function() toggleMyDay}) {
    String title = "";
    Widget leading;

    if (myDay) {
      title = "Added to my Day";
      leading = IconButton.filledTonal(
        icon: const Icon(Icons.wb_sunny_rounded),
        onPressed: toggleMyDay,
      );
    } else if (canAdd) {
      title = "Add to my Day?";
      leading = IconButton.outlined(
          icon: const Icon(Icons.wb_sunny_outlined), onPressed: toggleMyDay);
    } else {
      "Don't overload yourself, you deserve a rest.";
      leading = const Icon(Icons.block_rounded);
    }
    return ListTile(
        leading: leading,
        title: AutoSizeText(
          title,
          overflow: TextOverflow.visible,
          softWrap: true,
          minFontSize: Constants.medium,
          maxLines: 2,
        ));
  }

  /// Boilerplate.
  // Basic Add Button
  static Widget addTile({
    required void Function() onTap,
    required String title,
  }) =>
      ListTile(
        leading: const Icon(Icons.add_rounded),
        title: AutoSizeText(title,
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            minFontSize: Constants.small),
        onTap: onTap,
      );

  // Create Button
  static Widget createButton({
    String label = "Create",
    EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
    required Future<void> Function() handleCreate,
  }) =>
      Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: outerPadding,
          child: FilledButton.icon(
              label: Text(label),
              icon: const Icon(Icons.add_rounded),
              onPressed: handleCreate),
        ),
      );

// Delete Button

  static Widget deleteButton({
    EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
    required Future<void> Function() handleDelete,
  }) =>
      Padding(
        padding: outerPadding,
        child: FilledButton.tonalIcon(
            label: const Text("Delete"),
            icon: const Icon(Icons.delete_forever_rounded),
            onPressed: handleDelete),
      );

// Combination Create & delete
  static Widget updateAndDeleteButtons({
    EdgeInsetsGeometry updateButtonPadding = EdgeInsets.zero,
    EdgeInsetsGeometry deleteButtonPadding = EdgeInsets.zero,
    required Future<void> Function() handleUpdate,
    required Future<void> Function() handleDelete,
  }) =>
      Align(
        alignment: Alignment.centerRight,
        child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Tiles.deleteButton(
                  outerPadding: deleteButtonPadding,
                  handleDelete: handleDelete),
              Tiles.createButton(
                  label: "Update",
                  outerPadding: updateButtonPadding,
                  handleCreate: handleUpdate)
            ]),
      );
}
