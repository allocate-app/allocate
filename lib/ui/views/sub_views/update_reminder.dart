import 'dart:io';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../../model/task/reminder.dart';
import '../../../providers/event_provider.dart';
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
  late bool _checkRepeating;
  late bool showTime;

  late final ReminderProvider reminderProvider;
  late final UserProvider userProvider;
  late final EventProvider eventProvider;
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
    eventProvider = Provider.of<EventProvider>(context, listen: false);
  }

  void initializeParameters() {
    checkClose = false;
    _checkRepeating = false;
    showTime = null != reminder.dueDate;
    prevReminder = reminder.copy();
  }

  void initializeControllers() {
    mainScrollController = ScrollController();
    ScrollPhysics parentPhysics = (Platform.isIOS || Platform.isMacOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
    scrollPhysics = AlwaysScrollableScrollPhysics(parent: parentPhysics);
    nameEditingController = TextEditingController(text: reminder.name);
    nameEditingController.addListener(() {
      _checkRepeating = true;
      String newText = nameEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      reminder.name = newText;
      if (null != nameErrorText && mounted) {
        setState(() {
          nameErrorText = null;
        });
      }
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
    if (prevReminder.frequency != Frequency.once &&
        _checkRepeating &&
        RepeatableState.delta != prevReminder.repeatableState) {
      bool? updateSingle = await showModalBottomSheet<bool?>(
          showDragHandle: true,
          context: context,
          builder: (BuildContext context) {
            return const HandleRepeatableModal(action: "Update");
          });

      if (null == updateSingle) {
        return;
      }

      await reminderProvider
          .handleRepeating(
              reminder: prevReminder,
              delta: reminder,
              single: updateSingle,
              delete: false)
          .catchError((e) => Tiles.displayError(context: context, e: e),
              test: (e) =>
                  e is FailureToUpdateException ||
                  e is FailureToUploadException ||
                  e is InvalidRepeatingException ||
                  e is FailureToDeleteException);

      return await eventProvider
          .updateEventModel(
              oldModel: prevReminder, newModel: reminder, notify: true)
          .whenComplete(() => Navigator.pop(context));
    }

    await reminderProvider.updateReminder().catchError(
        (e) => Tiles.displayError(context: context, e: e),
        test: (e) =>
            e is FailureToCreateException || e is FailureToUploadException);

    return await eventProvider
        .updateEventModel(
            oldModel: prevReminder, newModel: reminder, notify: true)
        .whenComplete(() => Navigator.pop(context));
  }

  Future<void> handleDelete() async {
    if (prevReminder.frequency != Frequency.once &&
        RepeatableState.delta != prevReminder.repeatableState) {
      bool? deleteSingle = await showModalBottomSheet<bool?>(
          showDragHandle: true,
          context: context,
          builder: (BuildContext context) {
            return const HandleRepeatableModal(
              action: "Delete",
            );
          });

      if (null == deleteSingle) {
        return;
      }
      await reminderProvider
          .handleRepeating(
              reminder: prevReminder,
              delta: reminder,
              single: deleteSingle,
              delete: true)
          .catchError((e) => Tiles.displayError(context: context, e: e),
              test: (e) =>
                  e is FailureToUpdateException ||
                  e is FailureToUploadException ||
                  e is InvalidRepeatingException ||
                  e is FailureToDeleteException);

      reminder.toDelete = true;
      return await eventProvider
          .updateEventModel(
              oldModel: prevReminder, newModel: reminder, notify: true)
          .whenComplete(() => Navigator.pop(context));
    }

    await reminderProvider.deleteReminder().catchError(
        (e) => Tiles.displayError(context: context, e: e),
        test: (e) =>
            e is FailureToCreateException || e is FailureToUploadException);

    reminder.toDelete = true;
    return await eventProvider
        .updateEventModel(
          oldModel: prevReminder,
          newModel: reminder,
          notify: true,
        )
        .whenComplete(() => Navigator.pop(context));
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
        _checkRepeating = true;
        nameEditingController.clear();
        reminder.name = "";
      });
    }
  }

  void updateName() {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        _checkRepeating = true;
        reminder.name = nameEditingController.text;
      });
    }
  }

  void clearDue() {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        _checkRepeating = true;
        reminder.dueDate = null;
        showTime = false;
      });
    }
  }

  void updateDue({bool? checkClose, DateTime? newDate, TimeOfDay? newTime}) {
    if (mounted) {
      setState(() {
        checkClose = checkClose ?? this.checkClose;
        _checkRepeating = true;
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
        _checkRepeating = true;
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
        _checkRepeating = true;
        checkClose = checkClose ?? this.checkClose;
        this.checkClose = (checkClose!)
            ? userProvider.curUser?.checkClose ?? checkClose!
            : checkClose!;
        reminder.frequency = newFreq;
        reminder.repeatSkip = newSkip;
        reminder.repeatable = (Frequency.once != reminder.frequency &&
            prevReminder.repeatable == false);

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
    MediaQuery.sizeOf(context);
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
                                      outerPadding: const EdgeInsets.symmetric(
                                          vertical: Constants.padding),
                                      textFieldPadding: const EdgeInsets.only(
                                        left: Constants.padding,
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

                                  // Repeatable Stuff -> Show status, on click, open a dialog.
                                  if (null != reminder.dueDate) ...[
                                    const PaddedDivider(
                                        padding: Constants.padding),
                                    Tiles.repeatableTile(
                                      context: context,
                                      outerPadding: const EdgeInsets.symmetric(
                                          horizontal: Constants.padding),
                                      frequency: reminder.frequency,
                                      weekdays: weekdayList,
                                      repeatSkip: reminder.repeatSkip,
                                      startDate: reminder.dueDate,
                                      handleUpdate: updateRepeatable,
                                      handleClear: clearRepeatable,
                                    ),
                                  ],
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
