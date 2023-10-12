import 'dart:math';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../../../model/task/deadline.dart';
import '../../../providers/deadline_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/exceptions.dart';
import '../../widgets/flushbars.dart';
import '../../widgets/leading_widgets.dart';
import '../../widgets/padded_divider.dart';
import '../../widgets/tiles.dart';
import '../../widgets/title_bar.dart';

class UpdateDeadlineScreen extends StatefulWidget {
  const UpdateDeadlineScreen({Key? key}) : super(key: key);

  @override
  State<UpdateDeadlineScreen> createState() => _UpdateDeadlineScreen();
}

class _UpdateDeadlineScreen extends State<UpdateDeadlineScreen> {
  late bool checkClose;

  late Deadline prevDeadline;

  late final DeadlineProvider deadlineProvider;

  // Scrolling
  late final ScrollController mainScrollController;
  late final ScrollController subScrollControllerLeft;
  late final ScrollController subScrollControllerRight;
  late final ScrollPhysics scrollPhysics;

  // Name
  late final TextEditingController nameEditingController;
  String? nameErrorText;

  late final TextEditingController descriptionEditingController;

  late TextEditingController repeatSkipEditingController;

  Deadline get deadline => deadlineProvider.curDeadline!;

  late bool showStartTime;
  late bool showDueTime;
  late bool showWarnTime;

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeParameters();
    initializeControllers();
  }

  @override
  void dispose() {
    nameEditingController.dispose();
    descriptionEditingController.dispose();
    repeatSkipEditingController.dispose();
    super.dispose();
  }

  void initializeParameters() {
    checkClose = false;
    prevDeadline = deadline.copy();

    showStartTime =
        Constants.midnight != TimeOfDay.fromDateTime(deadline.startDate);
    showDueTime =
        Constants.midnight != TimeOfDay.fromDateTime(deadline.dueDate);
  }

  void initializeProviders() {
    deadlineProvider = Provider.of<DeadlineProvider>(context, listen: false);
  }

  void initializeControllers() {
    mainScrollController = ScrollController();
    subScrollControllerLeft = ScrollController();
    subScrollControllerRight = ScrollController();
    scrollPhysics =
        const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());
    nameEditingController = TextEditingController(text: deadline.name);
    nameEditingController.addListener(() {
      nameErrorText = null;
      checkClose = true;
      String newText = nameEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      setState(() => deadline.name = newText);
    });

    descriptionEditingController =
        TextEditingController(text: deadline.description);
    descriptionEditingController.addListener(() {
      checkClose = true;
      String newText = descriptionEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      deadline.description = newText;
    });

    repeatSkipEditingController =
        TextEditingController(text: deadline.repeatSkip.toString());
    repeatSkipEditingController.addListener(() {
      checkClose = true;
      String newText = descriptionEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      deadline.repeatSkip = int.tryParse(newText) ?? deadline.repeatSkip;
      deadline.repeatSkip = max(deadline.repeatSkip, 1);
    });
  }

  bool validateData() {
    bool valid = true;
    if (nameEditingController.text.isEmpty) {
      valid = false;
      setState(() => nameErrorText = "Enter Task Name");
    }

    // Newly set warnMe = validate
    // Editing previous warnMe = Ignore - is not relevant.
    // I am unsure as to how this should be handled.
    if (!prevDeadline.warnMe &&
        deadline.warnMe &&
        !deadlineProvider.validateWarnDate(warnDate: deadline.warnDate)) {
      valid = false;

      Flushbar? error;

      error = Flushbars.createError(
        message: "Warn date must be later than now.",
        context: context,
        dismissCallback: () => error?.dismiss(),
      );

      error.show(context);
    }

    if (deadline.frequency == Frequency.custom) {
      if (!deadline.repeatDays.contains(true)) {
        for (int i = 0; i < deadline.repeatDays.length; i++) {
          deadline.repeatDays[i] = prevDeadline.repeatDays[i];
        }
      }
    }

    return valid;
  }

  void clearNameField() {
    setState(() {
      checkClose = true;
      nameEditingController.clear();
      deadline.name = "";
    });
  }

  Future<void> handleUpdate() async {
    if (prevDeadline.frequency != Frequency.once && checkClose) {
      bool? updateSingle = await showModalBottomSheet<bool?>(
          showDragHandle: true,
          context: context,
          builder: (BuildContext context) {
            return Center(
                heightFactor: 1,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(Constants.padding),
                        child: FilledButton.icon(
                            onPressed: () => Navigator.pop(context, true),
                            label: const Text("This Event"),
                            icon: const Icon(Icons.arrow_upward_outlined)),
                      ),
                      Padding(
                          padding: const EdgeInsets.all(Constants.padding),
                          child: FilledButton.tonalIcon(
                            onPressed: () => Navigator.pop(context, false),
                            label: const Text("All Future Events"),
                            icon: const Icon(Icons.repeat_outlined),
                          ))
                    ]));
          });
      // If the modal is discarded.
      if (null == updateSingle) {
        return;
      }

      await deadlineProvider
          .deleteAndCancelFutures(deadline: prevDeadline)
          .catchError((e) {
        Flushbar? error;

        error = Flushbars.createError(
          message: e.cause,
          context: context,
          dismissCallback: () => error?.dismiss(),
        );

        error.show(context);
      }, test: (e) => e is FailureToDeleteException);

      if (updateSingle) {
        prevDeadline.repeatable = true;
        // Need to sever the connection to future repeating events.
        deadline.repeatID = deadline.hashCode;

        await deadlineProvider.nextRepeat(deadline: prevDeadline).catchError(
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
        deadline.repeatable = false;
        deadline.frequency = Frequency.once;
      } else {
        deadline.repeatable = (deadline.frequency != Frequency.once);
      }
    } else {
      deadline.repeatable = (deadline.frequency != Frequency.once);
    }

    return await deadlineProvider.updateDeadline().whenComplete(() {
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
    if (prevDeadline.frequency != Frequency.once) {
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

      await deadlineProvider
          .deleteAndCancelFutures(deadline: prevDeadline)
          .catchError((e) {
        Flushbar? error;

        error = Flushbars.createError(
          message: e.cause,
          context: context,
          dismissCallback: () => error?.dismiss(),
        );

        error.show(context);
      }, test: (e) => e is FailureToDeleteException);

      if (updateSingle) {
        prevDeadline.repeatable = true;
        // Need to sever the connection to future repeating events.
        deadline.repeatID = deadline.hashCode;

        await deadlineProvider.nextRepeat(deadline: prevDeadline).catchError(
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

    return await deadlineProvider.deleteDeadline().whenComplete(() {
      Navigator.pop(context);
    }).catchError((e) {
      Flushbar? error;

      error = Flushbars.createError(
        message: e.cause,
        context: context,
        dismissCallback: () => error?.dismiss(),
      );

      error.show(context);
    }, test: (e) => e is FailureToDeleteException);
  }

  Future<void> updateAndValidate() async {
    if (validateData()) {
      await handleUpdate();
    }
  }

  void handleClose({required bool willDiscard}) {
    if (willDiscard) {
      Navigator.pop(context, prevDeadline);
    }

    if (mounted) {
      setState(() => checkClose = false);
    }
  }

  void changePriority(Set<Priority> newSelection) {
    setState(() {
      checkClose = true;
      deadline.priority = newSelection.first;
    });
  }

  void clearWarnMe() {
    setState(() {
      checkClose = true;
      deadline.warnDate = Constants.nullDate.copyWith(
          hour: Constants.midnight.hour, minute: Constants.midnight.minute);
      deadline.warnMe = false;
    });
  }

  void updateWarnMe({bool? checkClose, DateTime? newDate, TimeOfDay? newTime}) {
    setState(() {
      this.checkClose = checkClose ?? this.checkClose;
      newDate = newDate ?? Constants.nullDate;
      newTime = newTime ?? Constants.midnight;
      deadline.warnDate = deadline.warnDate
          .copyWith(hour: newTime!.hour, minute: newTime!.minute);
      deadline.warnMe = (Constants.nullDate != deadline.warnDate);
    });
  }

  void clearDates() {
    setState(() {
      checkClose = true;
      deadline.startDate = Constants.nullDate;
      deadline.dueDate = Constants.nullDate;
    });
  }

  void updateDates({bool? checkClose, DateTime? newStart, DateTime? newDue}) {
    setState(() {
      this.checkClose = checkClose ?? this.checkClose;
      deadline.startDate = newStart ?? Constants.nullDate;
      deadline.dueDate = newDue ?? Constants.nullDate;

      if (Constants.nullDate != deadline.startDate &&
          Constants.nullDate != deadline.dueDate &&
          deadline.startDate.isAfter(deadline.dueDate)) {
        deadline.startDate = deadline.dueDate;
      }
    });
  }

  void clearTimes() {
    setState(() {
      checkClose = true;

      deadline.startDate = deadline.startDate.copyWith(
          hour: Constants.midnight.hour, minute: Constants.midnight.minute);
      deadline.dueDate = deadline.dueDate.copyWith(
          hour: Constants.midnight.hour, minute: Constants.midnight.minute);
    });
  }

  void updateTimes({bool? checkClose, TimeOfDay? newStart, TimeOfDay? newDue}) {
    setState(() {
      this.checkClose = checkClose ?? this.checkClose;
      newStart = newStart ?? Constants.midnight;
      newDue = newDue ?? Constants.midnight;
      deadline.startDate = deadline.startDate
          .copyWith(hour: newStart!.hour, minute: newStart!.minute);
      deadline.dueDate =
          deadline.dueDate.copyWith(hour: newDue!.hour, minute: newDue!.minute);
    });
  }

  void clearRepeatable() {
    setState(() {
      checkClose = true;
      deadline.frequency = Frequency.once;

      deadline.repeatDays.fillRange(0, deadline.repeatDays.length, false);
      deadline.repeatSkip = 1;
    });
  }

  void updateRepeatable(
      {bool? checkClose,
      required Frequency newFreq,
      required Set<int> newWeekdays,
      required int newSkip}) {
    setState(() {
      this.checkClose = checkClose ?? this.checkClose;
      deadline.frequency = newFreq;
      deadline.repeatSkip = newSkip;

      if (newWeekdays.isEmpty) {
        newWeekdays.add(deadline.startDate.weekday - 1);
      }
      for (int i = 0; i < deadline.repeatDays.length; i++) {
        deadline.repeatDays[i] = newWeekdays.contains(i);
      }
    });
  }

  Set<int> get weekdayList {
    Set<int> weekdays = {};
    for (int i = 0; i < deadline.repeatDays.length; i++) {
      if (deadline.repeatDays[i]) {
        weekdays.add(i);
      }
    }
    return weekdays;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool largeScreen = (width >= Constants.largeScreen);
    bool smallScreen = (width <= Constants.smallScreen);
    bool hugeScreen = (width >= Constants.hugeScreen);

    bool showTimeTile = (Constants.nullDate != deadline.startDate ||
        Constants.nullDate != deadline.dueDate);

    return (largeScreen)
        ? buildDesktopDialog(
            context: context,
            showTimeTile: showTimeTile,
          )
        : buildMobileDialog(
            smallScreen: smallScreen,
            context: context,
            showTimeTile: showTimeTile,
          );
  }

  Dialog buildDesktopDialog(
      {required BuildContext context, showTimeTile = false}) {
    return Dialog(
      insetPadding: const EdgeInsets.all(Constants.outerDialogPadding),
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxHeight: Constants.maxDesktopDialogSide),
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
                  title: "Edit Deadline",
                  checkClose: checkClose,
                  padding:
                      const EdgeInsets.symmetric(horizontal: Constants.padding),
                  handleClose: handleClose,
                ),
                const PaddedDivider(padding: Constants.padding),
                Flexible(
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: ListView(
                              shrinkWrap: true,
                              controller: subScrollControllerLeft,
                              children: [
                                // Title
                                Tiles.nameTile(
                                    leading: LeadingWidgets.deadlineIcon(
                                      currentContext: context,
                                      iconPadding: const EdgeInsets.all(
                                          Constants.padding),
                                      outerPadding: const EdgeInsets.symmetric(
                                          horizontal: Constants.halfPadding),
                                    ),
                                    context: context,
                                    hintText: "Deadline Name",
                                    errorText: nameErrorText,
                                    controller: nameEditingController,
                                    outerPadding: const EdgeInsets.symmetric(
                                        horizontal: Constants.padding),
                                    textFieldPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: Constants.halfPadding,
                                    ),
                                    handleClear: clearNameField),

                                Tiles.priorityTile(
                                  context: context,
                                  outerPadding: const EdgeInsets.symmetric(
                                      horizontal: Constants.padding,
                                      vertical: Constants.innerPadding),
                                  priority: deadline.priority,
                                  onSelectionChanged: changePriority,
                                ),

                                const PaddedDivider(padding: Constants.padding),
                                Tiles.singleDateTimeTile(
                                  outerPadding: const EdgeInsets.symmetric(
                                      horizontal: Constants.padding),
                                  context: context,
                                  date: deadline.warnDate,
                                  time: (Constants.midnight !=
                                          TimeOfDay.fromDateTime(
                                              deadline.startDate))
                                      ? TimeOfDay.fromDateTime(
                                          deadline.startDate)
                                      : null,
                                  useAlertIcon: true,
                                  showDate: deadline.warnMe,
                                  unsetDateText: "Warn me?",
                                  unsetTimeText: "Warn Time",
                                  dialogHeader: "Select Warning Date",
                                  handleClear: clearWarnMe,
                                  handleUpdate: updateWarnMe,
                                ),
                                const PaddedDivider(padding: Constants.padding),
                                Tiles.dateRangeTile(
                                  context: context,
                                  outerPadding: const EdgeInsets.symmetric(
                                      horizontal: Constants.padding),
                                  startDate:
                                      (Constants.nullDate != deadline.startDate)
                                          ? deadline.startDate
                                          : null,
                                  dueDate:
                                      (Constants.nullDate != deadline.dueDate)
                                          ? deadline.dueDate
                                          : null,
                                  handleClear: clearDates,
                                  handleUpdate: updateDates,
                                ),
                                const PaddedDivider(padding: Constants.padding),

                                (showTimeTile)
                                    ? Tiles.timeTile(
                                        outerPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: Constants.padding),
                                        startTime: (Constants.midnight !=
                                                TimeOfDay.fromDateTime(
                                                    deadline.startDate))
                                            ? TimeOfDay.fromDateTime(
                                                deadline.startDate)
                                            : null,
                                        dueTime: (Constants.midnight !=
                                                TimeOfDay.fromDateTime(
                                                    deadline.dueDate))
                                            ? TimeOfDay.fromDateTime(
                                                deadline.dueDate)
                                            : null,
                                        context: context,
                                        handleClear: clearTimes,
                                        handleUpdate: updateTimes,
                                      )
                                    : const SizedBox.shrink(),
                                (showTimeTile)
                                    ? const PaddedDivider(
                                        padding: Constants.padding)
                                    : const SizedBox.shrink(),
                                Tiles.repeatableTile(
                                  context: context,
                                  outerPadding: const EdgeInsets.symmetric(
                                      horizontal: Constants.padding),
                                  frequency: deadline.frequency,
                                  weekdays: weekdayList,
                                  repeatSkip: deadline.repeatSkip,
                                  startDate: deadline.startDate,
                                  handleUpdate: updateRepeatable,
                                  handleClear: clearRepeatable,
                                ),
                              ]),
                        ),
                        Flexible(
                          child: Scrollbar(
                            thumbVisibility: true,
                            controller: subScrollControllerRight,
                            child: ListView(
                                controller: subScrollControllerRight,
                                physics: scrollPhysics,
                                shrinkWrap: true,
                                children: [
                                  Tiles.descriptionTile(
                                    controller: descriptionEditingController,
                                    outerPadding: const EdgeInsets.symmetric(
                                        horizontal: Constants.padding),
                                    context: context,
                                  ),
                                ]),
                          ),
                        )
                      ]),
                ),

                const PaddedDivider(padding: Constants.padding),
                Tiles.updateAndDeleteButtons(
                  handleDelete: handleDelete,
                  handleUpdate: updateAndValidate,
                  updateButtonPadding:
                      const EdgeInsets.symmetric(horizontal: Constants.padding),
                  deleteButtonPadding:
                      const EdgeInsets.symmetric(horizontal: Constants.padding),
                ),
              ]),
        ),
      ),
    );
  }

  Dialog buildMobileDialog(
      {required BuildContext context,
      bool smallScreen = false,
      showTimeTile = false}) {
    return Dialog(
      insetPadding: EdgeInsets.all((smallScreen)
          ? Constants.mobileDialogPadding
          : Constants.outerDialogPadding),
      child: Padding(
        padding: const EdgeInsets.all(Constants.padding),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title && Close Button
              TitleBar(
                currentContext: context,
                title: "New Deadline",
                checkClose: checkClose,
                padding:
                    const EdgeInsets.symmetric(horizontal: Constants.padding),
                handleClose: handleClose,
              ),
              const PaddedDivider(padding: Constants.padding),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  controller: mainScrollController,
                  physics: scrollPhysics,
                  children: [
                    Tiles.nameTile(
                        leading: LeadingWidgets.deadlineIcon(
                          currentContext: context,
                          iconPadding: const EdgeInsets.all(Constants.padding),
                          outerPadding: const EdgeInsets.symmetric(
                              horizontal: Constants.halfPadding),
                        ),
                        context: context,
                        hintText: "Deadline Name",
                        errorText: nameErrorText,
                        controller: nameEditingController,
                        outerPadding: const EdgeInsets.symmetric(
                            horizontal: Constants.padding),
                        textFieldPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.halfPadding,
                        ),
                        handleClear: clearNameField),

                    Tiles.priorityTile(
                      mobile: smallScreen,
                      context: context,
                      outerPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding,
                          vertical: Constants.innerPadding),
                      priority: deadline.priority,
                      onSelectionChanged: changePriority,
                    ),

                    const PaddedDivider(padding: Constants.padding),
                    Tiles.singleDateTimeTile(
                      outerPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      context: context,
                      date: (Constants.nullDate != deadline.warnDate)
                          ? deadline.warnDate
                          : null,
                      time: (Constants.midnight !=
                              TimeOfDay.fromDateTime(deadline.warnDate))
                          ? TimeOfDay.fromDateTime(deadline.warnDate)
                          : null,
                      useAlertIcon: true,
                      showDate: deadline.warnMe,
                      unsetDateText: "Warn me?",
                      unsetTimeText: "Warn Time",
                      dialogHeader: "Select Warning Date",
                      handleClear: clearWarnMe,
                      handleUpdate: updateWarnMe,
                    ),
                    const PaddedDivider(padding: Constants.padding),

                    Tiles.descriptionTile(
                      controller: descriptionEditingController,
                      outerPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      context: context,
                    ),
                    const PaddedDivider(padding: Constants.padding),

                    Tiles.dateRangeTile(
                      context: context,
                      outerPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      startDate: (Constants.nullDate != deadline.startDate)
                          ? deadline.startDate
                          : null,
                      dueDate: (Constants.nullDate != deadline.dueDate)
                          ? deadline.dueDate
                          : null,
                      handleClear: clearDates,
                      handleUpdate: updateDates,
                    ),

                    const PaddedDivider(padding: Constants.padding),
                    // Time
                    (showTimeTile)
                        ? Tiles.timeTile(
                            outerPadding: const EdgeInsets.symmetric(
                                horizontal: Constants.padding),
                            startTime: (Constants.midnight !=
                                    TimeOfDay.fromDateTime(deadline.startDate))
                                ? TimeOfDay.fromDateTime(deadline.startDate)
                                : null,
                            dueTime: (Constants.midnight !=
                                    TimeOfDay.fromDateTime(deadline.dueDate))
                                ? TimeOfDay.fromDateTime(deadline.dueDate)
                                : null,
                            context: context,
                            handleClear: clearTimes,
                            handleUpdate: updateTimes,
                          )
                        : const SizedBox.shrink(),
                    (showTimeTile)
                        ? const PaddedDivider(padding: Constants.padding)
                        : const SizedBox.shrink(),
                    // Repeatable Stuff -> Show status, on click, open a dialog.
                    Tiles.repeatableTile(
                      context: context,
                      outerPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      frequency: deadline.frequency,
                      weekdays: weekdayList,
                      repeatSkip: deadline.repeatSkip,
                      startDate: deadline.startDate,
                      handleUpdate: updateRepeatable,
                      handleClear: clearRepeatable,
                    ),
                  ],
                ),
              ),

              const PaddedDivider(padding: Constants.padding),
              Tiles.updateAndDeleteButtons(
                handleDelete: handleDelete,
                handleUpdate: updateAndValidate,
                updateButtonPadding:
                    const EdgeInsets.symmetric(horizontal: Constants.padding),
                deleteButtonPadding:
                    const EdgeInsets.symmetric(horizontal: Constants.padding),
              ),
            ]),
      ),
    );
  }
}
