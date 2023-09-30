import 'package:auto_size_text/auto_size_text.dart';
import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:numberpicker/numberpicker.dart';

import '../../model/task/subtask.dart';
import '../../util/constants.dart';

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

  // Description
  static Widget descriptionTile({TextEditingController? controller,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    bool isDense = false,
    required BuildContext context}) =>
      Padding(
        padding: padding,
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
  static Widget durationTile({int expectedDuration = 0,
    required BuildContext context,
    int realDuration = 0,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    required void Function() handleClear,
    required void Function(int? value) handleUpdate}) {
    return Padding(
      padding: padding,
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
        onTap: () =>
            showDialog<int>(
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
                                                  style: Constants
                                                      .largeHeaderStyle,
                                                  softWrap: true,
                                                  overflow: TextOverflow
                                                      .visible,
                                                  maxLines: 1,
                                                  minFontSize: Constants.large,
                                                )),
                                            Flexible(
                                              child: FittedBox(
                                                  fit: BoxFit.fill,
                                                  child: Icon(
                                                      Icons.timer_outlined,
                                                      size: Constants
                                                          .medIconSize)),
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
                                                  horizontal: Constants
                                                      .padding),
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
                                                  horizontal: Constants
                                                      .padding),
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
                                                        Navigator.pop(
                                                            context, 0),
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
                                                  label: const AutoSizeText(
                                                      "Done",
                                                      softWrap: false,
                                                      overflow:
                                                      TextOverflow.visible,
                                                      maxLines: 1,
                                                      minFontSize: Constants
                                                          .small),
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

  // SINGLE DATE TILE - TBA

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

// Update & Delete buttons.
}
