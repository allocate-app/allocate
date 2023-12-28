import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../../providers/reminder_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/exceptions.dart';
import '../../widgets/flushbars.dart';
import '../../widgets/leading_widgets.dart';
import '../../widgets/padded_divider.dart';
import '../../widgets/tiles.dart';
import '../../widgets/title_bar.dart';

class CreateReminderScreen extends StatefulWidget {
  const CreateReminderScreen({super.key});

  @override
  State<CreateReminderScreen> createState() => _CreateReminderScreen();
}

class _CreateReminderScreen extends State<CreateReminderScreen> {
  late bool checkClose;

  late final ReminderProvider reminderProvider;

  // Name
  late String name;
  late final TextEditingController nameEditingController;
  String? nameErrorText;

  // Due date
  DateTime? dueDate;
  TimeOfDay? dueTime;

  // Repeat
  late Frequency frequency;

  late TextEditingController repeatSkipEditingController;
  late int repeatSkip;

  late Set<int> weekdayList;
  late List<bool> weekdays;

  // Scrolling
  late final ScrollController mainScrollController;
  late final ScrollPhysics scrollPhysics;

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeParameters();
    initializeControllers();
  }

  void initializeProviders() {
    reminderProvider = Provider.of<ReminderProvider>(context, listen: false);
  }

  void initializeParameters() {
    checkClose = false;
    name = "";
    repeatSkip = 1;
    frequency = Frequency.once;
    weekdays = List.generate(7, (_) => false);
    weekdayList = {};
  }

  void initializeControllers() {
    mainScrollController = ScrollController();
    scrollPhysics =
        const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());
    nameEditingController = TextEditingController();
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

    if (!reminderProvider.validateDueDate(dueDate: dueDate)) {
      valid = false;

      Flushbar? error;

      error = Flushbars.createError(
        message: "Due date must be later than now.",
        context: context,
        dismissCallback: () => error?.dismiss(),
      );

      error.show(context);
    }

    return valid;
  }

  // Validator should catch invalid datetimes; this is a fallback & to merge time.
  void mergeDateTimes() {
    dueDate = dueDate ?? DateTime.now();
    dueTime = dueTime ?? Constants.eod;

    dueDate = dueDate!.copyWith(hour: dueTime!.hour, minute: dueTime!.minute);
  }

  Future<void> handleCreate() async {
    for (int index in weekdayList) {
      weekdays[index] = true;
    }

    // in case the usr doesn't submit to the textfields
    name = nameEditingController.text;

    await reminderProvider
        .createReminder(
            name: name,
            dueDate: dueDate,
            repeatable: frequency != Frequency.once,
            frequency: frequency,
            repeatDays: weekdays,
            repeatSkip: repeatSkip)
        .whenComplete(() => Navigator.pop(context))
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
                e is FailureToCreateException || e is FailureToUploadException);
  }

  void handleClose({required bool willDiscard}) {
    if (willDiscard) {
      Navigator.pop(context);
    }

    if (mounted) {
      return setState(() => checkClose = false);
    }
  }

  void clearNameField() {
    if (mounted) {
      return setState(() {
        checkClose = true;
        nameEditingController.clear();
        name = "";
      });
    }
  }

  void updateName() {
    if (mounted) {
      setState(() {
        checkClose = true;
        name = nameEditingController.text;
      });
    }
  }

  void clearDue() {
    if (mounted) {
      return setState(() {
        checkClose = true;
        dueDate = null;
        dueTime = null;
      });
    }
  }

  void updateDue({bool? checkClose, DateTime? newDate, TimeOfDay? newTime}) {
    if (mounted) {
      return setState(() {
        this.checkClose = checkClose ?? this.checkClose;
        dueDate = newDate;
        dueTime = newTime;
      });
    }
  }

  void clearRepeatable() {
    if (mounted) {
      return setState(() {
        checkClose = true;
        frequency = Frequency.once;
        weekdayList.clear();
        repeatSkip = 1;
      });
    }
  }

  void updateRepeatable(
      {bool? checkClose,
      required Frequency newFreq,
      required Set<int> newWeekdays,
      required int newSkip}) {
    if (mounted) {
      return setState(() {
        this.checkClose = checkClose ?? this.checkClose;
        frequency = newFreq;
        weekdayList = newWeekdays;
        repeatSkip = newSkip;
      });
    }
  }

  Future<void> createAndValidate() async {
    mergeDateTimes();
    if (validateData()) {
      await handleCreate();
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool largeScreen = (width >= Constants.largeScreen);
    bool smallScreen = (width <= Constants.smallScreen);
    bool hugeScreen = (width >= Constants.hugeScreen);

    return Dialog(
        insetPadding: EdgeInsets.all((smallScreen)
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
                      title: "New Reminder",
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
                                      leading: LeadingWidgets.reminderIcon(
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
                                      outerPadding: const EdgeInsets.all(
                                        Constants.padding,
                                      ),
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
                                    date: dueDate,
                                    time: dueTime,
                                    useAlertIcon: false,
                                    showDate: true,
                                    unsetDateText: "Due Date",
                                    unsetTimeText: "Due Time",
                                    dialogHeader: "Select Due Date",
                                    handleClear: clearDue,
                                    handleUpdate: updateDue,
                                  ),

                                  (null != dueDate)
                                      ? const PaddedDivider(
                                          padding: Constants.padding)
                                      : const SizedBox.shrink(),

                                  // Repeatable Stuff -> Show status, on click, open a dialog.
                                  (null != dueDate)
                                      ? Tiles.repeatableTile(
                                          context: context,
                                          outerPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal:
                                                      Constants.padding),
                                          frequency: frequency,
                                          weekdays: weekdayList,
                                          repeatSkip: repeatSkip,
                                          startDate: dueDate,
                                          handleUpdate: updateRepeatable,
                                          handleClear: clearRepeatable,
                                        )
                                      : const SizedBox.shrink(),
                                ]))),
                    const PaddedDivider(padding: Constants.halfPadding),
                    Tiles.createButton(
                      outerPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      handleCreate: createAndValidate,
                    ),
                  ]),
            )));
  }
}
