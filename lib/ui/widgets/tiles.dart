import 'package:allocate/ui/widgets/time_dialog.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:numberpicker/numberpicker.dart';

import '../../model/task/subtask.dart';
import '../../model/task/todo.dart';
import '../../util/constants.dart';
import '../../util/enums.dart';
import '../../util/numbers.dart';
import 'date_range_dialog.dart';
import 'date_time_dialog.dart';
import 'drain_bar.dart';
import 'frequency_dialog.dart';
import 'leading_widgets.dart';

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
          secondary: secondary);


  // TODO: Factor out statefulbuilder.
  static CheckboxListTile subtaskCheckboxTile({required BuildContext context,
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
                maxLines: 2,
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
                                                    "${cacheWeight
                                                        .toInt()} ${(cacheWeight >
                                                        (Constants
                                                            .maxTaskWeight / 2)
                                                            .floor())
                                                        ? Constants.lowBattery
                                                        : Constants
                                                        .fullBattery}",
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
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  onPressed: () => onRemoved(index: index)),
              (showHandle)
                  ? ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle_rounded))
                  : const SizedBox.shrink(),
            ],
          ));

  static Widget toDoCheckTile({
    required int index,
    required ToDo toDo,
    bool showHandle = false,
    required Future<void> Function({required int index, bool value}) onChanged,
    required Future<void> Function({required int index}) onTap,
    required void Function({required int index}) handleRemove,
  }) {
    return ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: Constants.innerPadding),
        key: ValueKey(index),
        shape: const RoundedRectangleBorder(
            borderRadius:
            BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        leading: LeadingWidgets.toDoCheckbox(
            completed: toDo.completed,
            onChanged: (bool? value) => onChanged(index: index, value: value!)),
        title: AutoSizeText(toDo.name,
            overflow: TextOverflow.ellipsis,
            minFontSize: Constants.large,
            softWrap: false,
            maxLines: 2),
        onTap: () async => await onTap(index: index),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Constants.batteryIcons[(toDo.taskType == TaskType.small)
                ? toDo.weight
                : remap(
                x: toDo.weight,
                inMin: 0,
                inMax: Constants.maxWeight,
                outMin: 0,
                outMax: 5)
                .toInt()]!,
            AutoSizeText(
              "${toDo.weight}",
              overflow: TextOverflow.visible,
              minFontSize: Constants.large,
              softWrap: false,
              maxLines: 1,
            ),
          ]),
          Padding(
              padding: EdgeInsets.zero,
              child: IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded),
                onPressed: () => handleRemove(index: index),
              )),
          (showHandle)
              ? ReorderableDragStartListener(
              index: index, child: const Icon(Icons.drag_handle_rounded))
              : const SizedBox.shrink(),
        ]));
  }

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
                          color: Theme
                              .of(context)
                              .colorScheme
                              .outlineVariant,
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
  static Widget weightSlider({required double weight,
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
                "$weight ${(weight > (Constants.maxTaskWeight / 2).floor())
                    ? Constants.lowBattery
                    : Constants.fullBattery}",
                divisions: Constants.maxTaskWeight,
                onChanged: handleWeightChange),
          ),
          const Icon(Icons.battery_1_bar),
        ],
      );

  // Description
  static Widget descriptionTile({TextEditingController? controller,
    EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
    String hintText = "Description",
    int? maxLines = Constants.mobileMaxLinesBeforeScroll,
    int minLines = Constants.mobileMinLines,
    double? minFontSize,
    bool isDense = false,
    required BuildContext context}) =>
      Padding(
        padding: outerPadding,
        child: AutoSizeTextField(
            controller: controller,
            maxLines: maxLines,
            minLines: minLines,
            minFontSize: minFontSize ?? Constants.large,
            decoration: InputDecoration(
              isDense: isDense,
              contentPadding: const EdgeInsets.all(Constants.innerPadding),
              hintText: hintText,
              enabledBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(
                      Radius.circular(Constants.roundedCorners)),
                  borderSide: BorderSide(
                    width: 2,
                    color: Theme
                        .of(context)
                        .colorScheme
                        .outlineVariant,
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
  // TODO: factor out stateful builder
  static Widget durationTile({int expectedDuration = 0,
    int realDuration = 0,
    int hours = 0,
    int minutes = 0,
    int seconds = 0,
    required BuildContext context,
    EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
    required void Function() handleClear,
    required void Function(int? value) handleUpdate}) {
    return Padding(
      padding: outerPadding,
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: Constants.innerPadding),
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
              padding:
              EdgeInsets.symmetric(horizontal: Constants.padding),
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
                    minFontSize: Constants.large,
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
        onTap: () async =>
        await showDialog<int>(
            context: context,
            builder: (BuildContext context) {
              return StatefulBuilder(
                builder: (BuildContext context,
                    void Function(void Function()) setState) =>
                    Dialog(
                        insetPadding:
                        const EdgeInsets.all(Constants.innerPadding),
                        child: Padding(
                            padding:
                            const EdgeInsets.all(Constants.innerPadding),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Flexible(
                                    child: Row(
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
                                              minFontSize: Constants.large,
                                            ),
                                          )
                                        ]),
                                  ),
                                  const Flexible(
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                                  size: Constants.medIconSize)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Flexible(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Expanded(
                                          child: NumberPicker(
                                            infiniteLoop: true,
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
                                            infiniteLoop: true,
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
                                            infiniteLoop: true,
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
                                                    Navigator.pop(
                                                        context, null),
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
          contentPadding: const EdgeInsets.only(left: Constants.innerPadding),
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
                  child: Tooltip(
                    message: "Start Date",
                    child: AutoSizeText(
                        Jiffy.parseFromDateTime(startDate)
                            .toLocal()
                            .format(
                          pattern: "MMM d",
                        ),
                        softWrap: false,
                        overflow: TextOverflow.visible,
                        maxLines: 1,
                        minFontSize: Constants.huge),
                  )),
              (null == dueDate)
                  ? const Flexible(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: Constants.padding),
                  child: Icon(Icons.today_rounded),
                ),
              )
                  : const Flexible(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: Constants.padding),
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
                child: Tooltip(
                  message: "Due Date",
                  child: AutoSizeText(
                      Jiffy.parseFromDateTime(dueDate)
                          .toLocal()
                          .format(pattern: "MMM d"),
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      maxLines: 1,
                      minFontSize: Constants.huge),
                ),
              )
            ],
          ),
          trailing: (startDate != null || dueDate != null)
              ? IconButton(
              icon: const Icon(Icons.clear), onPressed: handleClear)
              : null,
          onTap: () async {
            await showDialog<List<DateTime?>?>(
                context: context,
                builder: (BuildContext context) {
                  return DateRangeDialog(
                      startDate: startDate, dueDate: dueDate);
                }).then((newDates) {
              if (null == newDates) {
                return handleUpdate(newStart: startDate, newDue: dueDate);
              }
              return handleUpdate(
                  newStart: newDates[0], newDue: newDates[1], checkClose: true);
            });
          },
        ),
      );

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
            contentPadding: const EdgeInsets.only(left: Constants.innerPadding),
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
                    minFontSize: Constants.large,
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
                  child: Icon(Icons.history_toggle_off_rounded),
                ),
              )
                  : const Flexible(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: Constants.padding),
                    child: Icon(Icons.schedule_rounded),
                  )),
              (null == dueTime)
                  ? const Flexible(
                child: AutoSizeText(
                  "Due?",
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  maxLines: 1,
                  minFontSize: Constants.large,
                ),
              )
                  : Flexible(
                child: AutoSizeText(
                  dueTime.format(context).toString(),
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  maxLines: 1,
                  minFontSize: Constants.large,
                ),
              ),
            ]),
            onTap: () async {
              await showDialog<List<TimeOfDay?>?>(
                  context: context,
                  builder: (BuildContext context) {
                    return TimeDialog(startTime: startTime, dueTime: dueTime);
                  }).then((newTimes) {
                if (null == newTimes) {
                  return handleUpdate(newStart: startTime, newDue: dueTime);
                }
                return handleUpdate(
                    newStart: newTimes[0],
                    newDue: newTimes[1],
                    checkClose: true);
              });
            },
            trailing: (startTime != null || dueTime != null)
                ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: handleClear,
            )
                : null),
      );

  // SINGLE DATE TILE
  static Widget singleDateTimeTile({
    EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
    required BuildContext context,
    Widget? leading,
    DateTime? date,
    TimeOfDay? time,
    bool useAlertIcon = false,
    bool showDate = false,
    String unsetDateText = "",
    String unsetTimeText = "",
    String dialogHeader = "",
    required void Function() handleClear,
    required void Function(
        {bool? checkClose, DateTime? newDate, TimeOfDay? newTime})
    handleUpdate,
  }) =>
      Padding(
        padding: outerPadding,
        child: ListTile(
            contentPadding: const EdgeInsets.only(left: Constants.innerPadding),
            leading: (useAlertIcon)
                ? LeadingWidgets.alertIconButton(
                warn: showDate,
                onTap: () async {
                  await showDialog<Map<String, dynamic>?>(
                      context: context,
                      builder: (BuildContext context) {
                        return DateTimeDialog(
                          header: dialogHeader,
                          date: date,
                          time: time,
                        );
                      }).then((newDateTime) {
                    if (null == newDateTime) {
                      return handleUpdate(newDate: date, newTime: time);
                    }
                    return handleUpdate(
                        newDate: newDateTime["date"],
                        newTime: newDateTime["time"],
                        checkClose: true);
                  });
                })
                : leading,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                    Radius.circular(Constants.roundedCorners))),
            title: (showDate && null != date)
                ? Row(children: [
              Flexible(
                child: AutoSizeText(
                  Jiffy.parseFromDateTime(date).format(pattern: "MMM d"),
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  maxLines: 1,
                  minFontSize: Constants.huge,
                ),
              ),
              (null != time)
                  ? const Flexible(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: Constants.padding),
                  child: Icon(Icons.schedule_outlined),
                ),
              )
                  : const Flexible(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: Constants.padding),
                    child: Icon(Icons.history_toggle_off_outlined),
                  )),
              (null != time)
                  ? Flexible(
                child: AutoSizeText(
                  time.format(context).toString(),
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  maxLines: 1,
                  minFontSize: Constants.huge,
                ),
              )
                  : Flexible(
                child: AutoSizeText(
                  unsetTimeText,
                  overflow: TextOverflow.visible,
                  softWrap: false,
                  minFontSize: Constants.medium,
                  maxLines: 1,
                ),
              ),
            ])
                : AutoSizeText(
              unsetDateText,
              overflow: TextOverflow.visible,
              softWrap: true,
              minFontSize: Constants.medium,
              maxLines: 2,
            ),
            onTap: () async {
              await showDialog<Map<String, dynamic>?>(
                  context: context,
                  builder: (BuildContext context) {
                    return DateTimeDialog(
                      header: dialogHeader,
                      date: date,
                      time: time,
                    );
                  }).then((newDateTime) {
                if (null == newDateTime) {
                  return handleUpdate(newDate: date, newTime: time);
                }
                return handleUpdate(
                    newDate: newDateTime["date"],
                    newTime: newDateTime["time"],
                    checkClose: true);
              });
            },
            trailing: (showDate && null != date)
                ? IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: handleClear,
            )
                : null),
      );

  static Widget repeatableTile({
    required BuildContext context,
    EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
    required Frequency frequency,
    required Set<int> weekdays,
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
          contentPadding: const EdgeInsets.only(left: Constants.innerPadding),
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
          onTap: () async {
            await showDialog<Map<String, dynamic>?>(
                context: context,
                builder: (BuildContext context) {
                  return FrequencyDialog(
                    frequency: frequency,
                    weekdays: weekdays,
                    repeatSkip: repeatSkip,
                    startDate: startDate,
                  );
                }).then((newFrequency) {
              if (null == newFrequency) {
                return handleUpdate(
                  newFreq: frequency,
                  newWeekdays: weekdays,
                  newSkip: repeatSkip,
                );
              }
              return handleUpdate(
                newFreq: newFrequency["frequency"],
                newWeekdays: newFrequency["weekdays"],
                newSkip: newFrequency["repeatSkip"],
                checkClose: true,
              );
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
    bool mobile = false,
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
                      color: Theme
                          .of(context)
                          .colorScheme
                          .outlineVariant,
                    )),
                  ),
                  segments: Priority.values
                      .map((Priority type) =>
                      ButtonSegment<Priority>(
                          tooltip: toBeginningOfSentenceCase(type.name),
                          icon: Constants.priorityIcon[type],
                          value: type,
                          label: (!mobile)
                              ? Text(
                            "${toBeginningOfSentenceCase(type.name)}",
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                          )
                              : null))
                      .toList(growable: false),
                  selected: <Priority>{priority},
                  onSelectionChanged: onSelectionChanged)
            ]),
      );

  // MY DAY
  static Widget myDayTile({required bool myDay,
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
        shape: const RoundedRectangleBorder(
            borderRadius:
            BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        title: AutoSizeText(
          title,
          overflow: TextOverflow.visible,
          softWrap: true,
          minFontSize: Constants.medium,
          maxLines: 2,
        ),
        onTap: toggleMyDay);
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
            minFontSize: Constants.large),
        onTap: onTap,
      );

  static Widget fetchTile({
    required void Function() onTap,
  }) =>
      ListTile(
          leading: const Icon(Icons.redo_rounded),
          title: const AutoSizeText(
            "Load more",
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            minFontSize: Constants.large,
          ),
          onTap: onTap);

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
              label: Text(label, overflow: TextOverflow.ellipsis),
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
            label: const Text("Delete", overflow: TextOverflow.ellipsis),
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
