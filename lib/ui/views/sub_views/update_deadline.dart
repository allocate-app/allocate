import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../../../model/task/deadline.dart';
import '../../../providers/deadline_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/exceptions.dart';
import '../../widgets/flushbars.dart';
import '../../widgets/handle_repeatable_modal.dart';
import '../../widgets/leading_widgets.dart';
import '../../widgets/padded_divider.dart';
import '../../widgets/tiles.dart';
import '../../widgets/title_bar.dart';

class UpdateDeadlineScreen extends StatefulWidget {
  final Deadline? initialDeadline;

  const UpdateDeadlineScreen({super.key, this.initialDeadline});

  @override
  State<UpdateDeadlineScreen> createState() => _UpdateDeadlineScreen();
}

class _UpdateDeadlineScreen extends State<UpdateDeadlineScreen> {
  late bool checkClose;

  late Deadline prevDeadline;

  late final DeadlineProvider deadlineProvider;
  late final UserProvider userProvider;

  // Scrolling
  late final ScrollController mobileScrollController;
  late final ScrollController desktopScrollController;
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
    mobileScrollController.dispose();
    desktopScrollController.dispose();
    nameEditingController.dispose();
    descriptionEditingController.dispose();
    repeatSkipEditingController.dispose();
    super.dispose();
  }

  void initializeParameters() {
    checkClose = false;
    prevDeadline = deadline.copy();

    showStartTime = null != deadline.startDate;
    showDueTime = null != deadline.dueDate;
    showWarnTime = null != deadline.warnDate;
  }

  void initializeProviders() {
    deadlineProvider = Provider.of<DeadlineProvider>(context, listen: false);
    if (null != widget.initialDeadline) {
      deadlineProvider.curDeadline = widget.initialDeadline;
    }

    userProvider = Provider.of<UserProvider>(context, listen: false);
  }

  void initializeControllers() {
    mobileScrollController = ScrollController();
    desktopScrollController = ScrollController();
    scrollPhysics =
        const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());
    nameEditingController = TextEditingController(text: deadline.name);
    nameEditingController.addListener(() {
      if (null != nameErrorText && mounted) {
        setState(() {
          nameErrorText = null;
        });
      }
      SemanticsService.announce(
          nameEditingController.text, Directionality.of(context));
    });

    descriptionEditingController =
        TextEditingController(text: deadline.description);
    descriptionEditingController.addListener(() {
      String newText = descriptionEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
    });

    repeatSkipEditingController =
        TextEditingController(text: deadline.repeatSkip.toString());
    repeatSkipEditingController.addListener(() {
      String newText = descriptionEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      // deadline.repeatSkip = int.tryParse(newText) ?? deadline.repeatSkip;
      // deadline.repeatSkip = max(deadline.repeatSkip, 1);
    });
  }

  bool validateData() {
    bool valid = true;
    if (nameEditingController.text.isEmpty) {
      valid = false;
      if (mounted) {
        setState(() => nameErrorText = "Enter Deadline Name");
      }
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

    if (null == deadline.startDate || null == deadline.dueDate) {
      deadline.frequency = Frequency.once;
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
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        nameEditingController.clear();
        deadline.name = "";
      });
    }
  }

  void updateName() {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        deadline.name = nameEditingController.text;
      });
    }
  }

  void updateDescription() {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        deadline.description = descriptionEditingController.text;
      });
    }
  }

  Future<void> handleUpdate() async {
    // in case the usr doesn't submit to the textfields
    deadline.name = nameEditingController.text;
    deadline.description = descriptionEditingController.text;

    if (prevDeadline.frequency != Frequency.once && checkClose) {
      bool? updateSingle = await showModalBottomSheet<bool?>(
          showDragHandle: true,
          context: context,
          builder: (BuildContext context) {
            return const HandleRepeatableModal(
              action: "Update",
            );
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
      bool? deleteSingle = await showModalBottomSheet<bool?>(
          showDragHandle: true,
          context: context,
          builder: (BuildContext context) {
            return const HandleRepeatableModal(action: "Delete");
          });
      // If the modal is discarded.
      if (null == deleteSingle) {
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

      if (deleteSingle) {
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
      return Navigator.pop(context);
    }

    if (mounted) {
      setState(() => checkClose = false);
    }
  }

  void changePriority(Set<Priority> newSelection) {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        deadline.priority = newSelection.first;
      });
    }
  }

  void clearWarnMe() {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        deadline.warnDate = null;
        showWarnTime = false;
        deadline.warnMe = false;
      });
    }
  }

  void updateWarnMe({bool? checkClose, DateTime? newDate, TimeOfDay? newTime}) {
    if (mounted) {
      setState(() {
        checkClose = checkClose ?? this.checkClose;
        this.checkClose = (checkClose!)
            ? userProvider.curUser?.checkClose ?? checkClose!
            : checkClose!;
        deadline.warnDate =
            newDate?.copyWith(hour: newTime?.hour, minute: newTime?.minute);
        showWarnTime = null != newTime;
        deadline.warnMe = null != deadline.warnDate;
      });
    }
  }

  void clearDates() {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        deadline.startDate = null;
        deadline.dueDate = null;
        showStartTime = false;
        showDueTime = false;
      });
    }
  }

  void updateDates({bool? checkClose, DateTime? newStart, DateTime? newDue}) {
    if (mounted) {
      setState(() {
        checkClose = checkClose ?? this.checkClose;
        this.checkClose = (checkClose!)
            ? userProvider.curUser?.checkClose ?? checkClose!
            : checkClose!;
        deadline.startDate = newStart;
        deadline.dueDate = newDue;
        if (null != deadline.startDate &&
            null != deadline.dueDate &&
            deadline.startDate!.isAfter(deadline.dueDate!)) {
          deadline.startDate = deadline.dueDate;
        }
      });
    }
  }

  void clearTimes() {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        showStartTime = false;
        showDueTime = false;
      });
    }
  }

  void updateTimes({bool? checkClose, TimeOfDay? newStart, TimeOfDay? newDue}) {
    if (mounted) {
      setState(() {
        checkClose = checkClose ?? this.checkClose;
        this.checkClose = (checkClose!)
            ? userProvider.curUser?.checkClose ?? checkClose!
            : checkClose!;

        deadline.startDate = deadline.startDate
            ?.copyWith(hour: newStart?.hour, minute: newStart?.minute);
        deadline.dueDate = deadline.dueDate
            ?.copyWith(hour: newDue?.hour, minute: newDue?.minute);

        showStartTime = null != newStart;
        showDueTime = null != newDue;
      });
    }
  }

  void clearRepeatable() {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        deadline.frequency = Frequency.once;

        deadline.repeatDays.fillRange(0, deadline.repeatDays.length, false);
        deadline.repeatSkip = 1;
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
        deadline.frequency = newFreq;
        deadline.repeatSkip = newSkip;

        if (newWeekdays.isEmpty) {
          newWeekdays
              .add((deadline.startDate?.weekday ?? DateTime.now().weekday) - 1);
        }
        for (int i = 0; i < deadline.repeatDays.length; i++) {
          deadline.repeatDays[i] = newWeekdays.contains(i);
        }
      });
    }
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
    MediaQuery.of(context).size;

    bool showTimeTile = null != deadline.startDate || null != deadline.dueDate;
    bool showRepeatTile =
        null != deadline.startDate && null != deadline.dueDate;

    return (userProvider.largeScreen)
        ? buildDesktopDialog(
            context: context,
            showTimeTile: showTimeTile,
            showRepeatTile: showRepeatTile,
          )
        : buildMobileDialog(
            smallScreen: userProvider.smallScreen,
            context: context,
            showTimeTile: showTimeTile,
            showRepeatTile: showRepeatTile,
          );
  }

  Dialog buildDesktopDialog(
      {required BuildContext context,
      bool showTimeTile = false,
      bool showRepeatTile = false}) {
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
                const PaddedDivider(padding: Constants.halfPadding),
                Flexible(
                  child: Scrollbar(
                    thumbVisibility: true,
                    controller: desktopScrollController,
                    child: ListView(
                      physics: scrollPhysics,
                      shrinkWrap: true,
                      controller: desktopScrollController,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: ListView(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
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
                                          handleClear: clearNameField,
                                          onEditingComplete: updateName),

                                      Tiles.priorityTile(
                                        context: context,
                                        outerPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: Constants.padding,
                                                vertical:
                                                    Constants.innerPadding),
                                        priority: deadline.priority,
                                        onSelectionChanged: changePriority,
                                      ),

                                      const PaddedDivider(
                                          padding: Constants.padding),
                                      Tiles.singleDateTimeTile(
                                        outerPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: Constants.padding),
                                        context: context,
                                        date: deadline.warnDate,
                                        time: (null != deadline.warnDate &&
                                                showWarnTime)
                                            ? TimeOfDay.fromDateTime(
                                                deadline.warnDate!)
                                            : null,
                                        useAlertIcon: true,
                                        showDate: deadline.warnMe,
                                        unsetDateText: "Warn me?",
                                        unsetTimeText: "Warn Time",
                                        dialogHeader: "Warn Date",
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
                                        startDate: (Constants.nullDate !=
                                                deadline.startDate)
                                            ? deadline.startDate
                                            : null,
                                        dueDate: (Constants.nullDate !=
                                                deadline.dueDate)
                                            ? deadline.dueDate
                                            : null,
                                        handleClear: clearDates,
                                        handleUpdate: updateDates,
                                      ),
                                      (showTimeTile)
                                          ? const PaddedDivider(
                                              padding: Constants.padding)
                                          : const SizedBox.shrink(),

                                      (showTimeTile)
                                          ? Tiles.timeTile(
                                              outerPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal:
                                                          Constants.padding),
                                              startTime: (showStartTime)
                                                  ? TimeOfDay.fromDateTime(
                                                      deadline.startDate!)
                                                  : null,
                                              dueTime: (showDueTime)
                                                  ? TimeOfDay.fromDateTime(
                                                      deadline.dueDate!)
                                                  : null,
                                              context: context,
                                              handleClear: clearTimes,
                                              handleUpdate: updateTimes,
                                            )
                                          : const SizedBox.shrink(),
                                      (showRepeatTile)
                                          ? const PaddedDivider(
                                              padding: Constants.padding)
                                          : const SizedBox.shrink(),
                                      (showRepeatTile)
                                          ? Tiles.repeatableTile(
                                              context: context,
                                              outerPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal:
                                                          Constants.padding),
                                              frequency: deadline.frequency,
                                              weekdays: weekdayList,
                                              repeatSkip: deadline.repeatSkip,
                                              startDate: deadline.startDate,
                                              handleUpdate: updateRepeatable,
                                              handleClear: clearRepeatable,
                                            )
                                          : const SizedBox.shrink(),
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
                                        onEditingComplete: updateDescription,
                                      ),
                                    ]),
                              )
                            ]),
                      ],
                    ),
                  ),
                ),

                const PaddedDivider(padding: Constants.halfPadding),
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
      bool showTimeTile = false,
      bool showRepeatTile = false}) {
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
              const PaddedDivider(padding: Constants.halfPadding),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  controller: mobileScrollController,
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
                        handleClear: clearNameField,
                        onEditingComplete: updateName),

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
                      date: deadline.warnDate,
                      time: (null != deadline.warnDate && showWarnTime)
                          ? TimeOfDay.fromDateTime(deadline.warnDate!)
                          : null,
                      useAlertIcon: true,
                      showDate: deadline.warnMe,
                      unsetDateText: "Warn me?",
                      unsetTimeText: "Warn Time",
                      dialogHeader: "Warn Date",
                      handleClear: clearWarnMe,
                      handleUpdate: updateWarnMe,
                    ),
                    const PaddedDivider(padding: Constants.padding),

                    Tiles.descriptionTile(
                      controller: descriptionEditingController,
                      outerPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      context: context,
                      onEditingComplete: updateDescription,
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

                    (showTimeTile)
                        ? const PaddedDivider(padding: Constants.padding)
                        : const SizedBox.shrink(),
                    // Time
                    (showTimeTile)
                        ? Tiles.timeTile(
                            outerPadding: const EdgeInsets.symmetric(
                                horizontal: Constants.padding),
                            startTime: (showStartTime)
                                ? TimeOfDay.fromDateTime(deadline.startDate!)
                                : null,
                            dueTime: (showDueTime)
                                ? TimeOfDay.fromDateTime(deadline.dueDate!)
                                : null,
                            context: context,
                            handleClear: clearTimes,
                            handleUpdate: updateTimes,
                          )
                        : const SizedBox.shrink(),
                    (showRepeatTile)
                        ? const PaddedDivider(padding: Constants.padding)
                        : const SizedBox.shrink(),
                    // Repeatable Stuff -> Show status, on click, open a dialog.
                    (showRepeatTile)
                        ? Tiles.repeatableTile(
                            context: context,
                            outerPadding: const EdgeInsets.symmetric(
                                horizontal: Constants.padding),
                            frequency: deadline.frequency,
                            weekdays: weekdayList,
                            repeatSkip: deadline.repeatSkip,
                            startDate: deadline.startDate,
                            handleUpdate: updateRepeatable,
                            handleClear: clearRepeatable,
                          )
                        : const SizedBox.shrink(),
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
