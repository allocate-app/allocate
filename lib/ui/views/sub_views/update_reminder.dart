import 'dart:math';

import 'package:another_flushbar/flushbar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:provider/provider.dart';

import '../../../model/task/reminder.dart';
import '../../../providers/reminder_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/exceptions.dart';
import '../../widgets/flushbars.dart';
import '../../widgets/padded_divider.dart';

//TODO: Bring repeatable tile over.
class UpdateReminderScreen extends StatefulWidget {
  const UpdateReminderScreen({Key? key}) : super(key: key);

  @override
  State<UpdateReminderScreen> createState() => _UpdateReminderScreen();
}

class _UpdateReminderScreen extends State<UpdateReminderScreen> {
  late bool checkClose;

  late final ReminderProvider reminderProvider;
  late final Reminder prevReminder;

  // Name
  late final TextEditingController nameEditingController;
  String? nameErrorText;

  Reminder get reminder => reminderProvider.curReminder!;

  @override
  void initState() {
    initializeProviders();
    initializeParameters();
    initializeControllers();
    super.initState();
  }

  void initializeProviders() {
    reminderProvider = Provider.of<ReminderProvider>(context, listen: false);
  }

  void initializeParameters() {
    checkClose = false;
    prevReminder = reminder.copy();
  }

  void initializeControllers() {
    nameEditingController = TextEditingController(text: reminder.name);
    nameEditingController.addListener(() {
      nameErrorText = null;
      checkClose = true;
      String newText = nameEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      setState(() => reminder.name = newText);
    });
  }

  @override
  void dispose() {
    nameEditingController.dispose();
    super.dispose();
  }

  void handleDueDate() {
    DateTime? tmpDueDate =
        (Constants.nullDate != reminder.dueDate) ? reminder.dueDate : null;
    TimeOfDay tmpDueTime = (Constants.nullDate != reminder.dueDate)
        ? TimeOfDay.fromDateTime(reminder.dueDate)
        : Constants.midnight;
    showDialog<bool?>(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context,
                      void Function(void Function()) setState) =>
                  Dialog(
                      child: Padding(
                          padding: const EdgeInsets.all(Constants.innerPadding),
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Expanded(
                                      child: AutoSizeText(
                                        "Select Due Date",
                                        style: Constants.headerStyle,
                                        softWrap: true,
                                        overflow: TextOverflow.visible,
                                        maxLines: 2,
                                        minFontSize: Constants.medium,
                                      ),
                                    ),
                                  ],
                                ),
                                const Flexible(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Flexible(
                                          child: AutoSizeText(
                                        "Date | Time ",
                                        style: Constants.largeHeaderStyle,
                                        softWrap: true,
                                        overflow: TextOverflow.visible,
                                        maxLines: 1,
                                        minFontSize: Constants.large,
                                      )),
                                      Flexible(
                                        child: FittedBox(
                                            fit: BoxFit.fill,
                                            child: Icon(Icons.alarm_outlined,
                                                size: Constants.medIconSize)),
                                      ),
                                    ],
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: Constants.innerPadding),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      Constants.roundedCorners),
                                              border: Border.all(
                                                  strokeAlign: BorderSide
                                                      .strokeAlignOutside),
                                            ),
                                            child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Expanded(
                                                    child: TextButton(
                                                        onPressed: () {
                                                          // Consider moving this to shifting focus to calendar
                                                          // using focusNode.
                                                          if (null ==
                                                              tmpDueDate) {
                                                            setState(() =>
                                                                tmpDueDate =
                                                                    DateTime
                                                                        .now());
                                                          }
                                                        },
                                                        child: (null !=
                                                                tmpDueDate)
                                                            ? AutoSizeText(
                                                                Jiffy.parseFromDateTime(
                                                                        tmpDueDate!)
                                                                    .toLocal()
                                                                    .format(
                                                                        pattern:
                                                                            "yMMMMd"),
                                                                softWrap: false,
                                                                overflow:
                                                                    TextOverflow
                                                                        .visible,
                                                                maxLines: 1,
                                                                minFontSize:
                                                                    Constants
                                                                        .small,
                                                              )
                                                            : const AutoSizeText(
                                                                "Date",
                                                                softWrap: true,
                                                                overflow:
                                                                    TextOverflow
                                                                        .visible,
                                                                maxLines: 1,
                                                                minFontSize:
                                                                    Constants
                                                                        .small)),
                                                  ),
                                                  (null != tmpDueDate)
                                                      ? IconButton(
                                                          icon: const Icon(Icons
                                                              .clear_outlined),
                                                          selectedIcon:
                                                              const Icon(
                                                                  Icons.clear),
                                                          onPressed: () =>
                                                              setState(() {
                                                            checkClose = true;
                                                            tmpDueDate = null;
                                                          }),
                                                        )
                                                      : const SizedBox.shrink()
                                                ]),
                                          ),
                                        ),
                                        const Flexible(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: Constants.padding),
                                            child: AutoSizeText("@",
                                                style:
                                                    Constants.hugeHeaderStyle,
                                                softWrap: false,
                                                overflow: TextOverflow.visible,
                                                maxLines: 1,
                                                minFontSize: Constants.small),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      Constants.roundedCorners),
                                              border: Border.all(
                                                  strokeAlign: BorderSide
                                                      .strokeAlignOutside),
                                            ),
                                            child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Expanded(
                                                    child: TextButton(
                                                        onPressed: () async {
                                                          final TimeOfDay?
                                                              picked =
                                                              await showTimePicker(
                                                            context: context,
                                                            initialTime:
                                                                tmpDueTime,
                                                          );
                                                          if (null != picked) {
                                                            setState(() =>
                                                                tmpDueTime =
                                                                    picked);
                                                          }
                                                        },
                                                        child: (Constants
                                                                    .midnight !=
                                                                tmpDueTime)
                                                            ? AutoSizeText(
                                                                tmpDueTime
                                                                    .format(
                                                                        context)
                                                                    .toString(),
                                                                softWrap: false,
                                                                overflow:
                                                                    TextOverflow
                                                                        .visible,
                                                                maxLines: 1,
                                                                minFontSize:
                                                                    Constants
                                                                        .small,
                                                              )
                                                            : const AutoSizeText(
                                                                "Due Time",
                                                                softWrap: true,
                                                                overflow:
                                                                    TextOverflow
                                                                        .visible,
                                                                maxLines: 1,
                                                                minFontSize:
                                                                    Constants
                                                                        .small)),
                                                  ),
                                                  (Constants.midnight !=
                                                          tmpDueTime)
                                                      ? IconButton(
                                                          icon: const Icon(Icons
                                                              .clear_outlined),
                                                          selectedIcon:
                                                              const Icon(
                                                                  Icons.clear),
                                                          onPressed: () =>
                                                              setState(() {
                                                            checkClose = true;
                                                            tmpDueTime =
                                                                Constants
                                                                    .midnight;
                                                          }),
                                                        )
                                                      : const SizedBox.shrink(),
                                                ]),
                                          ),
                                        ),
                                      ]),
                                ),

                                // Calendar picker here.

                                Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CalendarDatePicker2(
                                          config: CalendarDatePicker2Config(
                                            calendarType:
                                                CalendarDatePicker2Type.single,
                                            firstDate: DateTime(1970),
                                            lastDate: DateTime(3000),
                                          ),
                                          value: [tmpDueDate],
                                          onValueChanged: (dates) {
                                            setState(() {
                                              tmpDueDate = dates.firstOrNull;
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
                                                  Icons.close_outlined),
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
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
                                            icon:
                                                const Icon(Icons.done_outlined),
                                            onPressed: () {
                                              Navigator.pop(context, true);
                                            },
                                            label: const AutoSizeText("Done",
                                                softWrap: false,
                                                overflow: TextOverflow.visible,
                                                maxLines: 1,
                                                minFontSize: Constants.small),
                                          ),
                                        ),
                                      )
                                    ]),
                              ]))));
        }).then((setFields) {
      setState(() {
        if (setFields ?? false) {
          reminder.dueDate = tmpDueDate ?? Constants.nullDate;
          if (Constants.nullDate != reminder.dueDate) {
            reminder.dueDate = reminder.dueDate
                .copyWith(hour: tmpDueTime.hour, minute: tmpDueTime.minute);
          }
        }
      });
    });
  }

  bool validateData() {
    bool valid = true;
    if (nameEditingController.text.isEmpty) {
      valid = false;
      setState(() => nameErrorText = "Enter Reminder Name");
    }

    if (Constants.nullDate == reminder.dueDate) {
      valid = false;

      Flushbar? error;

      error = Flushbars.createError(
        message: "Due Date required.",
        context: context,
        dismissCallback: () => error?.dismiss(),
      );

      error.show(context);
    }
    return valid;
  }

  Future<void> handleUpdate({required BuildContext context}) async {
    if (prevReminder.frequency != Frequency.once && checkClose) {
      bool? updateSingle = await showModalBottomSheet<bool?>(
          showDragHandle: true,
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
                builder: (BuildContext context,
                        void Function(void Function()) setState) =>
                    Center(
                        heightFactor: 1,
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.all(Constants.padding),
                                child: FilledButton.icon(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    label: const Text("This Event"),
                                    icon: const Icon(
                                        Icons.arrow_upward_outlined)),
                              ),
                              Padding(
                                  padding:
                                      const EdgeInsets.all(Constants.padding),
                                  child: FilledButton.tonalIcon(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    label: const Text("All Future Events"),
                                    icon: const Icon(Icons.repeat_outlined),
                                  ))
                            ])));
          });
      // If the modal is discarded.
      if (null == updateSingle) {
        return;
      }

      // TODO: Refactor error handling to something easier to read -- Like firing an event to watch in the main gui.
      // On updating a repeating event, clear all future events
      await reminderProvider
          .deleteAndCancelFutures(reminder: prevReminder)
          .catchError((e) {
        Flushbar? error;

        error = Flushbars.createError(
          message: e.cause,
          context: context,
          dismissCallback: () => error?.dismiss(),
        );

        error.show(context);
      },
              test: (e) =>
                  e is FailureToCreateException ||
                  e is FailureToUploadException);

      // Updating all future events relies on deleting all future events ->
      // They are assumed to be re-generated on the next calendar view or day passing.
      // If only updating the one event, generate the next one in the database.

      // TODO: Refactor the error handling to something easier to read.
      if (updateSingle) {
        prevReminder.repeatable = true;
        // Need to sever the connection to future repeating events.
        reminder.repeatID = reminder.hashCode;

        await reminderProvider.nextRepeat(reminder: prevReminder).catchError(
            (e) {
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
        reminder.repeatable = false;
        reminder.frequency = Frequency.once;
      } else {
        reminder.repeatable = (reminder.frequency != Frequency.once);
      }
    } else {
      reminder.repeatable = (reminder.frequency != Frequency.once);
    }

    return await reminderProvider.updateReminder().whenComplete(() {
      Navigator.pop(context);
    }).catchError((e) {
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

  Future<void> handleDelete({required BuildContext context}) async {
    if (prevReminder.frequency != Frequency.once) {
      bool? updateSingle = await showModalBottomSheet<bool?>(
          showDragHandle: true,
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
                builder: (BuildContext context,
                        void Function(void Function()) setState) =>
                    Center(
                        heightFactor: 1,
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.all(Constants.padding),
                                child: FilledButton.icon(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    label: const Text("Delete This Event"),
                                    icon: const Icon(
                                        Icons.arrow_upward_outlined)),
                              ),
                              Padding(
                                  padding:
                                      const EdgeInsets.all(Constants.padding),
                                  child: FilledButton.tonalIcon(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    label: const Text("Delete All"),
                                    icon: const Icon(Icons.repeat_outlined),
                                  ))
                            ])));
          });
      // If the modal is discarded.
      if (null == updateSingle) {
        return;
      }

      // TODO: Refactor error handling to something easier to read -- Like firing an event to watch in the main gui.
      // On updating a repeating event, clear all future events
      await reminderProvider
          .deleteAndCancelFutures(reminder: prevReminder)
          .catchError((e) {
        Flushbar? error;

        error = Flushbars.createError(
          message: e.cause,
          context: context,
          dismissCallback: () => error?.dismiss(),
        );

        error.show(context);
      }, test: (e) => e is FailureToDeleteException);

      // Updating all future events relies on deleting all future events ->
      // They are assumed to be re-generated on the next calendar view or day passing.
      // If only updating the one event, generate the next one in the database.

      // TODO: Refactor the error handling to something easier to read.
      if (updateSingle) {
        prevReminder.repeatable = true;
        // Need to sever the connection to future repeating events.
        reminder.repeatID = reminder.hashCode;

        await reminderProvider.nextRepeat(reminder: prevReminder).catchError(
            (e) {
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
    }

    return await reminderProvider.deleteReminder().whenComplete(() {
      Navigator.pop(context);
    }).catchError((e) {
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

  @override
  Widget build(BuildContext context) {
    bool smallScreen =
        (MediaQuery.of(context).size.width <= Constants.smallScreen);

    return Dialog(
        insetPadding: const EdgeInsets.all(Constants.smallOuterDialogPadding),
        child: ConstrainedBox(
            constraints: const BoxConstraints(
                maxHeight: Constants.smallLandscapeDialogHeight,
                maxWidth: Constants.smallLandscapeDialogWidth),
            child: Padding(
              padding: const EdgeInsets.all(Constants.padding),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title && Close Button
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: Constants.padding),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Flexible(
                                child: AutoSizeText(
                                  "Edit Reminder",
                                  overflow: TextOverflow.visible,
                                  style: Constants.headerStyle,
                                  minFontSize: Constants.medium,
                                  softWrap: true,
                                  maxLines: 1,
                                ),
                              ),
                              buildCloseButton(context: context),
                            ]),
                      ),
                    ),
                    const PaddedDivider(padding: Constants.padding),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      child: buildNameTile(smallScreen: smallScreen),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      child: buildDateTimeTile(smallScreen: smallScreen),
                    ),
                    // Repeatable Stuff -> Show status, on click, open a dialog.
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      child: buildRepeatableTile(
                          context: context, smallScreen: smallScreen),
                    ),
                    const PaddedDivider(padding: Constants.padding),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      child: buildUpdateDeleteRow(context: context),
                    )
                  ]),
            )));
  }

  IconButton buildCloseButton({required BuildContext context}) {
    return IconButton(
        onPressed: () {
          if (checkClose) {
            showModalBottomSheet<bool>(
                showDragHandle: true,
                context: context,
                builder: (BuildContext context) {
                  return Center(
                      heightFactor: 1,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // const Icon(Icons.drag_handle_rounded),
                            Padding(
                              padding: const EdgeInsets.all(Constants.padding),
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.pop(context, true);
                                },
                                label: const Text("Discard"),
                                icon: const Icon(Icons.delete_forever_outlined),
                              ),
                            ),
                            Padding(
                                padding:
                                    const EdgeInsets.all(Constants.padding),
                                child: FilledButton.tonalIcon(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  label: const Text("Continue Editing"),
                                  icon: const Icon(
                                    Icons.edit_note_outlined,
                                  ),
                                ))
                          ]));
                }).then((willDiscard) {
              if (willDiscard ?? false) {
                Navigator.pop(context);
              }
            });
            setState(() => checkClose = false);
          } else {
            Navigator.pop(context);
          }
        },
        icon: const Icon(Icons.close_outlined),
        selectedIcon: const Icon(Icons.close));
  }

  Row buildNameTile({bool smallScreen = false}) {
    return Row(
      children: [
        Expanded(
            child: Padding(
          padding: const EdgeInsets.all(Constants.padding),
          child: buildReminderName(smallScreen: smallScreen),
        )),
      ],
    );
  }

  AutoSizeTextField buildReminderName({bool smallScreen = false}) {
    return AutoSizeTextField(
      maxLines: 1,
      minFontSize: Constants.medium,
      decoration: InputDecoration(
        isDense: smallScreen,
        suffixIcon: (reminder.name != "")
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  checkClose = true;
                  nameEditingController.clear();
                  setState(() => reminder.name = "");
                })
            : null,
        contentPadding: const EdgeInsets.all(Constants.innerPadding),
        border: const OutlineInputBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners)),
            borderSide: BorderSide(
              strokeAlign: BorderSide.strokeAlignOutside,
            )),
        hintText: "Reminder name",
        errorText: nameErrorText,
      ),
      controller: nameEditingController,
    );
  }

  ListTile buildDateTimeTile({bool smallScreen = false}) {
    TimeOfDay dueTime = TimeOfDay.fromDateTime(reminder.dueDate);
    return ListTile(
      title: (Constants.nullDate != reminder.dueDate)
          ? Row(children: [
              Flexible(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: Constants.padding),
                  child: AutoSizeText(
                      Jiffy.parseFromDateTime(reminder.dueDate)
                          .toLocal()
                          .format(pattern: "MMM d"),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      maxLines: 2,
                      minFontSize: Constants.medium),
                ),
              ),
              (Constants.midnight != dueTime)
                  ? const Flexible(
                      child: Padding(
                        padding: EdgeInsets.only(right: Constants.padding),
                        child: Icon(Icons.schedule_outlined),
                      ),
                    )
                  : const Flexible(
                      child: Padding(
                      padding: EdgeInsets.only(right: Constants.padding),
                      child: Icon(Icons.history_toggle_off_outlined),
                    )),
              (Constants.midnight != dueTime)
                  ? Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: Constants.padding),
                        child: AutoSizeText(
                          dueTime.format(context).toString(),
                          overflow: TextOverflow.visible,
                          softWrap: false,
                          minFontSize: Constants.large,
                          maxLines: 1,
                        ),
                      ),
                    )
                  : const Flexible(
                      child: AutoSizeText(
                        "Due Time",
                        overflow: TextOverflow.visible,
                        softWrap: false,
                        minFontSize: Constants.medium,
                        maxLines: 2,
                      ),
                    ),
            ])
          : const AutoSizeText(
              "Due Date",
              overflow: TextOverflow.visible,
              softWrap: true,
              minFontSize: Constants.medium,
              maxLines: 2,
            ),
      leading: const Icon(Icons.today_outlined),
      trailing: (Constants.nullDate != reminder.dueDate)
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() {
                    checkClose = true;
                    reminder.dueDate = Constants.nullDate;
                  }))
          : null,
      onTap: () => handleDueDate(),
    );
  }

  ListTile buildRepeatableTile(
      {required BuildContext context, bool smallScreen = false}) {
    return ListTile(
        leading: const Icon(Icons.event_repeat_outlined),
        title: (reminder.frequency == Frequency.once)
            ? const AutoSizeText("Set Recurring?",
                overflow: TextOverflow.visible,
                minFontSize: Constants.small,
                maxLines: 2,
                softWrap: true)
            : AutoSizeText(toBeginningOfSentenceCase(reminder.frequency.name)!,
                overflow: TextOverflow.visible,
                minFontSize: Constants.small,
                maxLines: 1,
                softWrap: false),
        onTap: () {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                Frequency cacheFreq = reminder.frequency;
                Set<int> cacheWeekdays = {};
                for (int i = 0; i < reminder.repeatDays.length; i++) {
                  if (reminder.repeatDays[i]) {
                    cacheWeekdays.add(i);
                  }
                }

                if (cacheWeekdays.isEmpty) {
                  int day = (Constants.nullDate != reminder.dueDate)
                      ? max(reminder.dueDate.weekday - 1, 0)
                      : max(DateTime.now().weekday - 1, 0);
                  cacheWeekdays.add(day);
                }

                int cacheSkip = reminder.repeatSkip;

                return StatefulBuilder(builder: (BuildContext context,
                    void Function(void Function()) setState) {
                  return Dialog(
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
                                          child: Icon(Icons.repeat_outlined,
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
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(
                                          gapPadding: 1,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(
                                                  Constants.circular)),
                                          borderSide: BorderSide(
                                              strokeAlign: BorderSide
                                                  .strokeAlignOutside)),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<Frequency>(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: Constants.padding),
                                        isDense: true,
                                        isExpanded: true,
                                        dropdownColor: Constants.dialogColor(
                                            context: context),
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(
                                                Constants.roundedCorners)),
                                        value: cacheFreq,
                                        onChanged: (Frequency? value) =>
                                            setState(() {
                                          checkClose = true;
                                          cacheFreq = value ?? cacheFreq;
                                        }),
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

                                (cacheFreq == Frequency.custom)
                                    ? Column(
                                        children: [
                                          // Days of the week - Wrap in padding and a container
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                Constants.innerPadding,
                                                Constants.innerPadding,
                                                Constants.innerPadding,
                                                0),
                                            child: Wrap(
                                                spacing: 5,
                                                runSpacing: 5,
                                                alignment: WrapAlignment.center,
                                                runAlignment:
                                                    WrapAlignment.center,
                                                children: Constants.weekDays
                                                    .map((weekDay) => InputChip(
                                                        backgroundColor:
                                                            Constants.dialogColor(
                                                                context:
                                                                    context),
                                                        shape:
                                                            const RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                  Radius.circular(
                                                                      Constants
                                                                          .circular)),
                                                          side: BorderSide(
                                                            strokeAlign: BorderSide
                                                                .strokeAlignOutside,
                                                          ),
                                                        ),
                                                        label: AutoSizeText(
                                                            weekDay.key,
                                                            minFontSize:
                                                                Constants.small,
                                                            maxLines: 1,
                                                            softWrap: false,
                                                            overflow:
                                                                TextOverflow
                                                                    .visible),
                                                        selected: cacheWeekdays
                                                            .contains(
                                                                weekDay.value),
                                                        onSelected:
                                                            (bool selected) =>
                                                                setState(() {
                                                                  checkClose =
                                                                      true;
                                                                  if (selected) {
                                                                    cacheWeekdays
                                                                        .add(weekDay
                                                                            .value);
                                                                  } else {
                                                                    cacheWeekdays
                                                                        .remove(
                                                                            weekDay.value);
                                                                    if (cacheWeekdays
                                                                        .isEmpty) {
                                                                      int day = (Constants.nullDate !=
                                                                              reminder
                                                                                  .dueDate)
                                                                          ? max(
                                                                              reminder.dueDate.weekday -
                                                                                  1,
                                                                              0)
                                                                          : max(
                                                                              DateTime.now().weekday - 1,
                                                                              0);
                                                                      cacheWeekdays
                                                                          .add(
                                                                              day);
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
                                                      setState(() {
                                                        checkClose = true;
                                                        cacheSkip = value;
                                                      });
                                                    })),
                                            Flexible(
                                              child: AutoSizeText(
                                                (cacheFreq == Frequency.custom)
                                                    ? "Week${(cacheSkip > 1) ? "s" : "."}"
                                                    : cacheFreq.name.replaceAll(
                                                        "ly",
                                                        (cacheSkip > 1)
                                                            ? "s."
                                                            : "."),
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
                                                  Icons.close_outlined),
                                              onPressed: () =>
                                                  Navigator.pop(context),
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
                                            icon:
                                                const Icon(Icons.done_outlined),
                                            onPressed: () {
                                              setState(() {
                                                checkClose = true;
                                                reminder.frequency = cacheFreq;
                                                reminder.repeatSkip = cacheSkip;

                                                if (cacheWeekdays.isEmpty) {
                                                  cacheWeekdays.add(
                                                      reminder.dueDate.weekday -
                                                          1);
                                                }
                                                for (int i = 0;
                                                    i <
                                                        reminder
                                                            .repeatDays.length;
                                                    i++) {
                                                  reminder.repeatDays[i] =
                                                      cacheWeekdays.contains(i);
                                                }
                                              });
                                              Navigator.pop(context);
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
                });
              }).then((_) => setState(() {}));
        },
        trailing: (reminder.frequency != Frequency.once)
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() {
                      checkClose = true;
                      reminder.frequency = Frequency.once;

                      reminder.repeatDays
                          .fillRange(0, reminder.repeatDays.length, false);

                      reminder.repeatSkip = 1;
                    }))
            : null);
  }

  Row buildUpdateDeleteRow({required BuildContext context}) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      Flexible(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
          child: buildDeleteButton(context: context),
        ),
      ),
      Flexible(child: buildUpdateButton(context: context)),
    ]);
  }

  FilledButton buildDeleteButton({required BuildContext context}) {
    return FilledButton.tonalIcon(
      label: const Text("Delete"),
      icon: const Icon(Icons.delete_forever),
      onPressed: () async => await handleDelete(context: context),
    );
  }

  FilledButton buildUpdateButton({required BuildContext context}) {
    return FilledButton.icon(
        label: const Text("Update Reminder"),
        icon: const Icon(Icons.add),
        onPressed: () async {
          bool validData = validateData();
          if (validData) {
            await handleUpdate(context: context);
          }
          // Then save.
        });
  }
}
