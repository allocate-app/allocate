import 'dart:math';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../../../providers/deadline_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/exceptions.dart';
import '../../widgets/flushbars.dart';
import '../../widgets/leading_widgets.dart';
import '../../widgets/padded_divider.dart';
import '../../widgets/tiles.dart';
import '../../widgets/title_bar.dart';

class CreateDeadlineScreen extends StatefulWidget {
  const CreateDeadlineScreen({Key? key}) : super(key: key);

  @override
  State<CreateDeadlineScreen> createState() => _CreateDeadlineScreen();
}

class _CreateDeadlineScreen extends State<CreateDeadlineScreen> {
  late bool checkClose;

  // Provider (Needs user values) -> Refactor to DI for testing. One day.
  late final DeadlineProvider deadlineProvider;

  // Scrolling
  late final ScrollController mobileScrollController;
  late final ScrollController desktopScrollController;
  late final ScrollPhysics scrollPhysics;

  // Name
  late String name;
  late final TextEditingController nameEditingController;
  String? nameErrorText;

  // Priority
  late Priority priority;

  // WarnMe & Warn date
  late bool warnMe;
  DateTime? warnDate;
  TimeOfDay? warnTime;

  // Description
  late String description;
  late final TextEditingController descriptionEditingController;

  // Start / Due Date
  DateTime? startDate;
  TimeOfDay? startTime;
  DateTime? dueDate;
  TimeOfDay? dueTime;

  // Repeatable
  late Frequency frequency;

  late TextEditingController repeatSkipEditingController;
  late int repeatSkip;

  late Set<int> weekdayList;
  late List<bool> weekdays;

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeParameters();
    initializeControllers();
  }

  @override
  void dispose() {
    mobileScrollController.dispose();
    desktopScrollController.dispose();
    nameEditingController.dispose();
    descriptionEditingController.dispose();
    repeatSkipEditingController.dispose();
    super.dispose();
  }

  void initializeParameters() {
    checkClose = false;
    name = "";
    priority = Priority.low;
    description = "";
    repeatSkip = 1;

    frequency = Frequency.once;

    warnMe = false;

    weekdayList = {};
    weekdays = List.generate(7, (_) => false);
  }

  void initializeProviders() {
    deadlineProvider = Provider.of<DeadlineProvider>(context, listen: false);
  }

  void initializeControllers() {
    mobileScrollController = ScrollController();
    desktopScrollController = ScrollController();
    scrollPhysics =
        const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());
    nameEditingController = TextEditingController();
    nameEditingController.addListener(() {
      nameErrorText = null;
      checkClose = true;
      String newText = nameEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      if (mounted) {
        return setState(() => name = newText);
      }
    });

    descriptionEditingController = TextEditingController();
    descriptionEditingController.addListener(() {
      checkClose = true;
      String newText = descriptionEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      description = newText;
    });

    repeatSkipEditingController = TextEditingController();
    repeatSkipEditingController.addListener(() {
      checkClose = true;
      String newText = descriptionEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      repeatSkip = int.tryParse(newText) ?? repeatSkip;
      repeatSkip = max(repeatSkip, 1);
    });
  }

  bool validateData() {
    bool valid = true;
    if (nameEditingController.text.isEmpty) {
      valid = false;
      if (mounted) {
        setState(() => nameErrorText = "Enter Task Name");
      }
    }

    if (warnMe && !deadlineProvider.validateWarnDate(warnDate: warnDate)) {
      valid = false;

      Flushbar? error;

      error = Flushbars.createError(
        message: "Warn date must be later than now.",
        context: context,
        dismissCallback: () => error?.dismiss(),
      );

      error.show(context);
    }

    if (frequency == Frequency.custom) {
      if (weekdayList.isEmpty) {
        weekdayList
            .add(min(((startDate?.weekday ?? DateTime.now().weekday) - 1), 0));
      }
    }

    return valid;
  }

  void mergeDateTimes() {
    startDate = startDate ?? DateTime.now();
    startTime = startTime ?? Constants.midnight;

    startDate =
        startDate!.copyWith(hour: startTime!.hour, minute: startTime!.minute);

    dueDate = dueDate ?? DateTime.now();
    dueTime = dueTime ?? Constants.midnight;

    dueDate = dueDate!.copyWith(hour: dueTime!.hour, minute: dueTime!.minute);

    warnDate = warnDate ?? DateTime.now();
    warnTime = warnTime ?? Constants.eod;
    warnDate =
        warnDate!.copyWith(hour: warnTime!.hour, minute: warnTime!.minute);
  }

  Future<void> handleCreate() async {
    for (int index in weekdayList) {
      weekdays[index] = true;
    }

    await deadlineProvider
        .createDeadline(
          name: name,
          description: description,
          startDate: startDate,
          dueDate: dueDate,
          warnDate: warnDate,
          warnMe: warnMe,
          priority: priority,
          repeatable: frequency != Frequency.once,
          frequency: frequency,
          repeatDays: weekdays,
          repeatSkip: repeatSkip,
        )
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

  void changePriority(Set<Priority> newSelection) {
    if (mounted) {
      return setState(() {
        checkClose = true;
        priority = newSelection.first;
      });
    }
  }

  void clearDates() {
    if (mounted) {
      return setState(() {
        checkClose = true;
        startDate = null;
        dueDate = null;
      });
    }
  }

  void clearWarnMe() {
    if (mounted) {
      return setState(() {
        checkClose = true;
        warnDate = null;
        warnTime = null;
        warnMe = false;
      });
    }
  }

  void updateWarnMe({bool? checkClose, DateTime? newDate, TimeOfDay? newTime}) {
    if (mounted) {
      return setState(() {
        this.checkClose = checkClose ?? this.checkClose;
        warnDate = newDate;
        warnTime = newTime;
        warnMe = (null != warnDate);
      });
    }
  }

  void updateDates({bool? checkClose, DateTime? newStart, DateTime? newDue}) {
    if (mounted) {
      return setState(() {
        this.checkClose = checkClose ?? this.checkClose;
        startDate = newStart;
        dueDate = newDue;

        if (null != startDate &&
            null != dueDate &&
            startDate!.isAfter(dueDate!)) {
          startDate = dueDate;
        }
      });
    }
  }

  void clearTimes() {
    if (mounted) {
      return setState(() {
        checkClose = true;
        startTime = null;
        dueTime = null;
      });
    }
  }

  void updateTimes({bool? checkClose, TimeOfDay? newStart, TimeOfDay? newDue}) {
    if (mounted) {
      return setState(() {
        this.checkClose = checkClose ?? this.checkClose;
        startTime = newStart;
        dueTime = newDue;
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

    bool showTimeTile = (null != startDate || null != dueDate);

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
                  title: "New Deadline",
                  checkClose: checkClose,
                  padding:
                      const EdgeInsets.symmetric(horizontal: Constants.padding),
                  handleClose: handleClose,
                ),
                const PaddedDivider(padding: Constants.padding),
                Flexible(
                  child: Scrollbar(
                    thumbVisibility: true,
                    controller: desktopScrollController,
                    child: ListView(
                      shrinkWrap: true,
                      physics: scrollPhysics,
                      controller: desktopScrollController,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: ListView(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    children: [
                                      // Title
                                      Tiles.nameTile(
                                          leading: LeadingWidgets.deadlineIcon(
                                            currentContext: context,
                                            iconPadding: const EdgeInsets.all(
                                                Constants.padding),
                                            outerPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal:
                                                        Constants.halfPadding),
                                          ),
                                          context: context,
                                          hintText: "Deadline Name",
                                          errorText: nameErrorText,
                                          controller: nameEditingController,
                                          outerPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal:
                                                      Constants.padding),
                                          textFieldPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: Constants.halfPadding,
                                          ),
                                          handleClear: clearNameField),

                                      Tiles.priorityTile(
                                        context: context,
                                        outerPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: Constants.padding,
                                                vertical:
                                                    Constants.innerPadding),
                                        priority: priority,
                                        onSelectionChanged: changePriority,
                                      ),

                                      const PaddedDivider(
                                          padding: Constants.padding),
                                      Tiles.singleDateTimeTile(
                                        outerPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: Constants.padding),
                                        context: context,
                                        date: warnDate,
                                        time: warnTime,
                                        useAlertIcon: true,
                                        showDate: warnMe,
                                        unsetDateText: "Warn me?",
                                        unsetTimeText: "Warn Time",
                                        dialogHeader: "Select Warning Date",
                                        handleClear: clearWarnMe,
                                        handleUpdate: updateWarnMe,
                                      ),
                                      const PaddedDivider(
                                          padding: Constants.padding),
                                      Tiles.dateRangeTile(
                                        context: context,
                                        outerPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: Constants.padding),
                                        startDate: startDate,
                                        dueDate: dueDate,
                                        handleClear: clearDates,
                                        handleUpdate: updateDates,
                                      ),
                                      const PaddedDivider(
                                          padding: Constants.padding),

                                      (showTimeTile)
                                          ? Tiles.timeTile(
                                              outerPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal:
                                                          Constants.padding),
                                              startTime: startTime,
                                              dueTime: dueTime,
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
                                        outerPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: Constants.padding),
                                        frequency: frequency,
                                        weekdays: weekdayList,
                                        repeatSkip: repeatSkip,
                                        startDate: startDate,
                                        handleUpdate: updateRepeatable,
                                        handleClear: clearRepeatable,
                                      ),
                                    ]),
                              ),
                              Flexible(
                                child: ListView(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    children: [
                                      Tiles.descriptionTile(
                                        minLines: Constants.desktopMinLines,
                                        maxLines: Constants
                                            .desktopMaxLinesBeforeScroll,
                                        controller:
                                            descriptionEditingController,
                                        outerPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: Constants.padding),
                                        context: context,
                                      ),
                                    ]),
                              )
                            ]),
                      ],
                    ),
                  ),
                ),

                const PaddedDivider(padding: Constants.padding),
                Tiles.createButton(
                  outerPadding:
                      const EdgeInsets.symmetric(horizontal: Constants.padding),
                  handleCreate: createAndValidate,
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
                  controller: mobileScrollController,
                  physics: scrollPhysics,
                  children: [
                    // Title + status
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
                      priority: priority,
                      onSelectionChanged: changePriority,
                    ),

                    const PaddedDivider(padding: Constants.padding),
                    Tiles.singleDateTimeTile(
                      outerPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      context: context,
                      date: warnDate,
                      time: warnTime,
                      useAlertIcon: true,
                      showDate: warnMe,
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
                      startDate: startDate,
                      dueDate: dueDate,
                      handleClear: clearDates,
                      handleUpdate: updateDates,
                    ),

                    const PaddedDivider(padding: Constants.padding),
                    // Time
                    (showTimeTile)
                        ? Tiles.timeTile(
                            outerPadding: const EdgeInsets.symmetric(
                                horizontal: Constants.padding),
                            startTime: startTime,
                            dueTime: dueTime,
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
                      frequency: frequency,
                      weekdays: weekdayList,
                      repeatSkip: repeatSkip,
                      startDate: startDate,
                      handleUpdate: updateRepeatable,
                      handleClear: clearRepeatable,
                    ),
                  ],
                ),
              ),

              const PaddedDivider(padding: Constants.padding),
              Tiles.createButton(
                outerPadding:
                    const EdgeInsets.symmetric(horizontal: Constants.padding),
                handleCreate: createAndValidate,
              ),
            ]),
      ),
    );
  }
}
