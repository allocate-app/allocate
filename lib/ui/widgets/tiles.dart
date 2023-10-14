import 'package:allocate/ui/widgets/handle_repeatable_modal.dart';
import 'package:allocate/ui/widgets/subtitles.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:provider/provider.dart';

import '../../model/task/subtask.dart';
import '../../model/task/todo.dart';
import '../../providers/todo_provider.dart';
import '../../providers/user_provider.dart';
import '../../ui/widgets/time_dialog.dart';
import '../../util/constants.dart';
import '../../util/enums.dart';
import '../../util/exceptions.dart';
import '../../util/numbers.dart';
import '../views/sub_views/update_todo.dart';
import 'check_delete_dialog.dart';
import 'date_range_dialog.dart';
import 'date_time_dialog.dart';
import 'drain_bar.dart';
import 'duration_dialog.dart';
import 'energy_modal.dart';
import 'flushbars.dart';
import 'frequency_dialog.dart';
import 'leading_widgets.dart';

class Tiles {
  /// ListView Tiles

  static toDoListTile({required BuildContext context,
    required int index,
    required ToDo toDo,
    bool showHandle = false,
    bool checkDelete = false}) =>
      ListTile(
          contentPadding:
          const EdgeInsets.symmetric(horizontal: Constants.padding),
          key: ValueKey(index),
          shape: const RoundedRectangleBorder(
              borderRadius:
              BorderRadius.all(Radius.circular(Constants.roundedCorners))),
          leading: LeadingWidgets.toDoCheckbox(
              scale: 1.1,
              completed: toDo.completed,
              onChanged: (bool? value) async {
                toDo.completed = value!;

                await Provider.of<ToDoProvider>(context, listen: false)
                    .updateToDo(toDo: toDo);
              }),
          title: AutoSizeText(toDo.name,
              overflow: TextOverflow.ellipsis,
              minFontSize: Constants.large,
              softWrap: false,
              maxLines: 2),
          subtitle: Subtitles.toDoSubTitle(
              context: context,
              id: toDo.groupID,
              dueDate: toDo.dueDate,
              priority: toDo.priority,
              onError: () async {
                toDo.groupID = null;
                await Provider.of<ToDoProvider>(context, listen: false)
                    .updateToDo(toDo: toDo);
              }),
          onTap: () async {
            await showDialog(
                barrierDismissible: false,
                useRootNavigator: false,
                context: context,
                builder: (BuildContext context) =>
                    UpdateToDoScreen(initialToDo: toDo));
          },
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
                  icon: const Icon(Icons.delete_forever_rounded),
                  onPressed: () async {
                    if (!checkDelete) {
                      return await deleteToDo(toDo: toDo, context: context);
                    }
                    return await showDialog<List<bool>?>(
                        barrierDismissible: true,
                        context: context,
                        builder: (BuildContext context) {
                          return CheckDeleteDialog(
                              dontAsk: !checkDelete, type: "Task");
                          // Dialog function.
                        }).then((results) async {
                      if (null == results) {
                        return;
                      }
                      Provider
                          .of<UserProvider>(context, listen: false)
                          .curUser
                          ?.checkDelete = results[1];
                      if (!results[0]) {
                        return;
                      }
                      await deleteToDo(toDo: toDo, context: context);
                    });
                  },
                )),
            (showHandle)
                ? ReorderableDragStartListener(
                index: index, child: const Icon(Icons.drag_handle_rounded))
                : const SizedBox.shrink(),
          ]));

  // Helper function to delete ToDos ->
  static Future<void> deleteToDo({
    required ToDo toDo,
    required BuildContext context,
  }) async {
    ToDoProvider toDoProvider =
    Provider.of<ToDoProvider>(context, listen: false);
    // For repeating ToDos.
    if (toDo.frequency != Frequency.once) {
      await showModalBottomSheet<bool?>(
          showDragHandle: true,
          context: context,
          builder: (BuildContext context) {
            return const HandleRepeatableModal(action: "Delete");
          }).then((deleteSingle) async {
        if (null == deleteSingle) {
          return;
        }

        // If delete all.
        if (!deleteSingle) {
          return await toDoProvider.deleteFutures(toDo: toDo).catchError((e) {
            Flushbar? error;

            error = Flushbars.createError(
              message: e.cause,
              context: context,
              dismissCallback: () => error?.dismiss(),
            );

            error.show(context);
          }, test: (e) => e is FailureToDeleteException);
        }

        // If delete one.
        await toDoProvider.nextRepeat(toDo: toDo).catchError((e) {
          Flushbar? error;

          error = Flushbars.createError(
            message: e.cause,
            context: context,
            dismissCallback: () => error?.dismiss(),
          );

          error.show(context);
        },
            test: (e) =>
            e is FailureToCreateException || e is FailureToUploadException);
      });
    }

    return await toDoProvider.deleteToDo(toDo: toDo).catchError((e) {
      Flushbar? error;

      error = Flushbars.createError(
        message: e.cause,
        context: context,
        dismissCallback: () => error?.dismiss(),
      );

      error.show(context);
    },
        test: (e) =>
        e is FailureToCreateException || e is FailureToUploadException);
  }

  /// Checkboxes
  static checkboxListTile({
    Key? key,
    EdgeInsetsGeometry contentPadding = EdgeInsets.zero,
    Widget? title,
    required void Function(bool? value) onChanged,
    bool value = false,
    Widget? trailing,
  }) =>
      ListTile(
          leading: LeadingWidgets.toDoCheckbox(
            completed: value,
            onChanged: onChanged,
          ),
          contentPadding: contentPadding,
          key: key,
          shape: const RoundedRectangleBorder(
              borderRadius:
              BorderRadius.all(Radius.circular(Constants.roundedCorners))),
          title: title,
          trailing: trailing);

  static Widget subtaskCheckboxTile({required BuildContext context,
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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.adaptivePlatformDensity,
                icon: Constants.batteryIcons[subTask.weight]!,
                selectedIcon: Constants.selectedBatteryIcons[subTask.weight]!,
                onPressed: () async {
                  await showModalBottomSheet<int?>(
                      useSafeArea: true,
                      showDragHandle: true,
                      context: context,
                      builder: (BuildContext context) {
                        return EnergyModal(initialWeight: subTask.weight);
                      }).then((newWeight) {
                    subTask.weight = newWeight ?? subTask.weight;
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
  // NAME
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

  // WEIGHT
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

  // WEIGHT SLIDER
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

  // DESCRIPTION
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

  // DURATION
  static Widget durationTile({int expectedDuration = 0,
    int realDuration = 0,
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
            builder: (BuildContext context) =>
                DurationDialog(duration: expectedDuration)).then(handleUpdate),
      ),
    );
  }

  // START-DUE DATES
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

  // TIME
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

  // SINGLE DATETIME TILE
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
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                    Radius.circular(Constants.roundedCorners))),
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

  // REPEATABLE
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

  // PRIORITY
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

  /// SEARCH

  static Widget historyTile({
    Widget? trailing,
    String title = "",
    void Function()? onTap,
  }) =>
      ListTile(
          leading: const Icon(Icons.history_rounded),
          shape: const RoundedRectangleBorder(
              borderRadius:
              BorderRadius.all(Radius.circular(Constants.roundedCorners))),
          title: AutoSizeText(
            title,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
          ),
          onTap: onTap,
          trailing: trailing);

  // I am unsure about a leading widget atm.
  static Widget searchTile({
    Widget? leading,
    Widget? trailing,
    String title = "",
    void Function()? onTap,
  }) =>
      ListTile(
        leading: leading,
        shape: const RoundedRectangleBorder(
            borderRadius:
            BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        title: AutoSizeText(
          title,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
        ),
        onTap: onTap,
      );

  /// BOILERPLATE.

  // BASIC CREATE LISTTILE
  static Widget createNew({
    required void Function() onTap,
    required BuildContext context,
  }) =>
      ListTile(
        leading: CircleAvatar(
          child: Icon(Icons.add_rounded,
              color: Theme
                  .of(context)
                  .colorScheme
                  .onSurfaceVariant),
        ),
        title: const AutoSizeText(
          "Create New",
          overflow: TextOverflow.visible,
          softWrap: false,
          maxLines: 1,
          minFontSize: Constants.medium,
        ),
        contentPadding: const EdgeInsets.all(Constants.padding),
        shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.all(Radius.circular(Constants.roundedCorners)),
        ),
        onTap: onTap,
      );

  // BASIC ADD BUTTON
  static Widget addTile({
    required void Function() onTap,
    required String title,
  }) =>
      ListTile(
        shape: const RoundedRectangleBorder(
            borderRadius:
            BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        leading: const Icon(Icons.add_rounded),
        title: AutoSizeText(title,
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            minFontSize: Constants.large),
        onTap: onTap,
      );

  // FETCH
  static Widget fetchTile({
    required void Function() onTap,
  }) =>
      ListTile(
          shape: const RoundedRectangleBorder(
              borderRadius:
              BorderRadius.all(Radius.circular(Constants.roundedCorners))),
          leading: const Icon(Icons.redo_rounded),
          title: const AutoSizeText(
            "Load more",
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            minFontSize: Constants.large,
          ),
          onTap: onTap);

  // CREATE/UPDATE
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

// DELETE
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

// COMBINATION UPDATE & DELETE
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
