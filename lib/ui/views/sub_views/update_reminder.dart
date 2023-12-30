import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../../model/task/reminder.dart';
import '../../../providers/reminder_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/exceptions.dart';
import '../../widgets/flushbars.dart';
import '../../widgets/handle_repeatable_modal.dart';
import '../../widgets/listtile_widgets.dart';
import '../../widgets/padded_divider.dart';
import '../../widgets/tiles.dart';
import '../../widgets/title_bar.dart';

class UpdateReminderScreen extends StatefulWidget {
  const UpdateReminderScreen({super.key, this.initialReminder});

  final Reminder? initialReminder;

  @override
  State<UpdateReminderScreen> createState() => _UpdateReminderScreen();
}

class _UpdateReminderScreen extends State<UpdateReminderScreen> {
  late bool checkClose;
  late bool showTime;

  late final ReminderProvider reminderProvider;
  late final UserProvider userProvider;
  late final Reminder prevReminder;

  // Name
  late final TextEditingController nameEditingController;
  String? nameErrorText;

  Reminder get reminder => reminderProvider.curReminder!;

  // Scrolling
  late final ScrollController mainScrollController;
  late final ScrollPhysics scrollPhysics;

  @override
  void initState() {
    initializeProviders();
    initializeParameters();
    initializeControllers();
    super.initState();
  }

  void initializeProviders() {
    reminderProvider = Provider.of<ReminderProvider>(context, listen: false);
    if (null != widget.initialReminder) {
      reminderProvider.curReminder = widget.initialReminder;
    }
    userProvider = Provider.of<UserProvider>(context, listen: false);
  }

  void initializeParameters() {
    checkClose = false;
    showTime = null != reminder.dueDate;
    prevReminder = reminder.copy();
  }

  void initializeControllers() {
    mainScrollController = ScrollController();
    scrollPhysics =
        const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());
    nameEditingController = TextEditingController(text: reminder.name);
    nameEditingController.addListener(() {
      if (null != nameErrorText && mounted) {
        setState(() {
          nameErrorText = null;
        });
      }
      SemanticsService.announce(
          nameEditingController.text, Directionality.of(context));
    });
  }

  @override
  void dispose() {
    mainScrollController.dispose();
    nameEditingController.dispose();
    super.dispose();
  }

  bool validateData() {
    bool valid = true;
    if (nameEditingController.text.isEmpty) {
      valid = false;
      if (mounted) {
        setState(() => nameErrorText = "Enter Reminder Name");
      }
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

  Future<void> handleUpdate() async {
    // in case the usr doesn't submit to the textfields
    reminder.name = nameEditingController.text;

    if (prevReminder.frequency != Frequency.once && checkClose) {
      bool? updateSingle = await showModalBottomSheet<bool?>(
          showDragHandle: true,
          context: context,
          builder: (BuildContext context) {
            return const HandleRepeatableModal(action: "Update");
          });

      // If the modal is discarded.
      if (null == updateSingle) {
        return;
      }

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

      if (updateSingle) {
        prevReminder.repeatable = true;
        // To prevent getting deleted by editing another repeating event.
        reminder.repeatID = Constants.generateID();

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

  Future<void> handleDelete() async {
    if (prevReminder.frequency != Frequency.once) {
      bool? deleteSingle = await showModalBottomSheet<bool?>(
          showDragHandle: true,
          context: context,
          builder: (BuildContext context) {
            return const HandleRepeatableModal(
              action: "Delete",
            );
          });
      // If the modal is discarded.
      if (null == deleteSingle) {
        return;
      }

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

      if (deleteSingle) {
        prevReminder.repeatable = true;

        // To prevent getting deleted by editing another repeating event.
        reminder.repeatID = Constants.generateID();

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

  void handleClose({required bool willDiscard}) {
    if (willDiscard) {
      reminderProvider.rebuild = true;
      return Navigator.pop(context);
    }

    if (mounted) {
      setState(() => checkClose = false);
    }
  }

  void clearNameField() {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        nameEditingController.clear();
        reminder.name = "";
      });
    }
  }

  void updateName() {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        reminder.name = nameEditingController.text;
      });
    }
  }

  void clearDue() {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        reminder.dueDate = null;
        showTime = false;
      });
    }
  }

  void updateDue({bool? checkClose, DateTime? newDate, TimeOfDay? newTime}) {
    if (mounted) {
      setState(() {
        checkClose = checkClose ?? this.checkClose;
        this.checkClose = (checkClose!)
            ? userProvider.curUser?.checkClose ?? checkClose!
            : checkClose!;
        reminder.dueDate =
            newDate?.copyWith(hour: newTime?.hour, minute: newTime?.minute);
        showTime = null != newTime;
      });
    }
  }

  void clearRepeatable() {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        reminder.frequency = Frequency.once;
        reminder.repeatDays.fillRange(0, reminder.repeatDays.length, false);
        reminder.repeatSkip = 1;
      });
    }
  }

  void updateRepeatable(
      {bool? checkClose,
      required Frequency newFreq,
      required Set<int> newWeekdays,
      required int newSkip}) {
    if (mounted) {
      setState(() {
        checkClose = checkClose ?? this.checkClose;
        this.checkClose = (checkClose!)
            ? userProvider.curUser?.checkClose ?? checkClose!
            : checkClose!;
        reminder.frequency = newFreq;
        reminder.repeatSkip = newSkip;

        if (newWeekdays.isEmpty) {
          newWeekdays
              .add((reminder.dueDate?.weekday ?? DateTime.now().weekday) - 1);
        }

        for (int i = 0; i < reminder.repeatDays.length; i++) {
          reminder.repeatDays[i] = newWeekdays.contains(i);
        }
      });
    }
  }

  Set<int> get weekdayList {
    Set<int> weekdays = {};
    for (int i = 0; i < reminder.repeatDays.length; i++) {
      if (reminder.repeatDays[i]) {
        weekdays.add(i);
      }
    }
    return weekdays;
  }

  Future<void> updateAndValidate() async {
    if (validateData()) {
      await handleUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.of(context).size;
    return Dialog(
        insetPadding: EdgeInsets.all((userProvider.smallScreen)
            ? Constants.mobileDialogPadding
            : Constants.outerDialogPadding),
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
                    TitleBar(
                      currentContext: context,
                      title: "Edit Reminder",
                      checkClose: checkClose,
                      padding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      handleClose: handleClose,
                    ),

                    const PaddedDivider(padding: Constants.halfPadding),
                    Flexible(
                        child: Scrollbar(
                            thumbVisibility: true,
                            controller: mainScrollController,
                            child: ListView(
                                shrinkWrap: true,
                                controller: mainScrollController,
                                physics: scrollPhysics,
                                children: [
                                  Tiles.nameTile(
                                      leading: ListTileWidgets.reminderIcon(
                                        currentContext: context,
                                        iconPadding: const EdgeInsets.all(
                                            Constants.padding),
                                        outerPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal:
                                                    Constants.halfPadding),
                                      ),
                                      context: context,
                                      hintText: "Reminder Name",
                                      errorText: nameErrorText,
                                      controller: nameEditingController,
                                      outerPadding: const EdgeInsets.only(
                                          left: Constants.innerPadding,
                                          right: Constants.innerPadding,
                                          bottom: Constants.innerPadding),
                                      textFieldPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: Constants.halfPadding,
                                      ),
                                      handleClear: clearNameField,
                                      onEditingComplete: updateName),
                                  const PaddedDivider(
                                      padding: Constants.padding),
                                  Tiles.singleDateTimeTile(
                                    leading: const Icon(Icons.today_outlined),
                                    outerPadding: const EdgeInsets.symmetric(
                                        horizontal: Constants.padding),
                                    context: context,
                                    date: reminder.dueDate,
                                    time: (null != reminder.dueDate && showTime)
                                        ? TimeOfDay.fromDateTime(
                                            reminder.dueDate!)
                                        : null,
                                    useAlertIcon: false,
                                    showDate: true,
                                    unsetDateText: "Due Date",
                                    unsetTimeText: "Due Time",
                                    dialogHeader: "Select Due Date",
                                    handleClear: clearDue,
                                    handleUpdate: updateDue,
                                  ),

                                  (null != reminder.dueDate)
                                      ? const PaddedDivider(
                                          padding: Constants.padding)
                                      : const SizedBox.shrink(),

                                  // Repeatable Stuff -> Show status, on click, open a dialog.
                                  (null != reminder.dueDate)
                                      ? Tiles.repeatableTile(
                                          context: context,
                                          outerPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal:
                                                      Constants.padding),
                                          frequency: reminder.frequency,
                                          weekdays: weekdayList,
                                          repeatSkip: reminder.repeatSkip,
                                          startDate: reminder.dueDate,
                                          handleUpdate: updateRepeatable,
                                          handleClear: clearRepeatable,
                                        )
                                      : const SizedBox.shrink(),
                                ]))),
                    const PaddedDivider(padding: Constants.halfPadding),
                    Tiles.updateAndDeleteButtons(
                      handleDelete: handleDelete,
                      handleUpdate: updateAndValidate,
                      updateButtonPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      deleteButtonPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                    ),
                  ]),
            )));
  }
}
