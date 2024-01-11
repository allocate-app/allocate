import 'dart:io';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../../../model/task/deadline.dart';
import '../../../providers/deadline_provider.dart';
import '../../../providers/event_provider.dart';
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

class UpdateDeadlineScreen extends StatefulWidget {
  final Deadline? initialDeadline;

  const UpdateDeadlineScreen({super.key, this.initialDeadline});

  @override
  State<UpdateDeadlineScreen> createState() => _UpdateDeadlineScreen();
}

class _UpdateDeadlineScreen extends State<UpdateDeadlineScreen> {
  late bool checkClose;
  late bool _checkRepeating;

  late Deadline prevDeadline;

  late final DeadlineProvider deadlineProvider;
  late final UserProvider userProvider;
  late final EventProvider eventProvider;

  // Scrolling
  late final ScrollController mobileScrollController;
  late final ScrollController desktopScrollController;
  late final ScrollPhysics scrollPhysics;

  // Name
  late final TextEditingController nameEditingController;
  String? nameErrorText;

  late final TextEditingController descriptionEditingController;

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
    super.dispose();
  }

  void initializeParameters() {
    checkClose = false;
    _checkRepeating = false;
    prevDeadline = deadline.copy();
    prevDeadline.id = deadline.id;

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
    eventProvider = Provider.of<EventProvider>(context, listen: false);
  }

  void initializeControllers() {
    mobileScrollController = ScrollController();
    desktopScrollController = ScrollController();
    ScrollPhysics parentPhysics = (Platform.isIOS || Platform.isMacOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
    scrollPhysics = AlwaysScrollableScrollPhysics(parent: parentPhysics);
    nameEditingController = TextEditingController(text: deadline.name);
    nameEditingController.addListener(() {
      _checkRepeating = true;
      String newText = nameEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      deadline.name = newText;
      if (null != nameErrorText && mounted) {
        setState(() {
          nameErrorText = null;
        });
      }
    });

    descriptionEditingController =
        TextEditingController(text: deadline.description);
    descriptionEditingController.addListener(() {
      _checkRepeating = true;
      String newText = descriptionEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      deadline.description = newText;
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
        _checkRepeating = true;
        nameEditingController.clear();
        deadline.name = "";
      });
    }
  }

  void updateName() {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        _checkRepeating = true;
        deadline.name = nameEditingController.text;
      });
    }
  }

  void updateDescription() {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        _checkRepeating = true;
        deadline.description = descriptionEditingController.text;
      });
    }
  }

  Future<void> handleUpdate() async {
    if (prevDeadline.frequency != Frequency.once &&
        _checkRepeating &&
        RepeatableState.delta != prevDeadline.repeatableState) {
      bool? updateSingle = await showModalBottomSheet<bool?>(
          showDragHandle: true,
          context: context,
          builder: (BuildContext context) {
            return const HandleRepeatableModal(action: "Update");
          });

      if (null == updateSingle) {
        return;
      }
      await deadlineProvider
          .handleRepeating(
              deadline: prevDeadline,
              delta: deadline,
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
            oldModel: prevDeadline,
            newModel: deadline,
            notify: true,
          )
          .whenComplete(() => Navigator.pop(context));
    }
    await deadlineProvider.updateDeadline(deadline: deadline).catchError(
        (e) => Tiles.displayError(context: context, e: e),
        test: (e) =>
            e is FailureToUpdateException || e is FailureToUploadException);

    return await eventProvider
        .updateEventModel(
          oldModel: prevDeadline,
          newModel: deadline,
          notify: true,
        )
        .whenComplete(() => Navigator.pop(context));
  }

  Future<void> handleDelete() async {
    if (prevDeadline.frequency != Frequency.once &&
        RepeatableState.delta != prevDeadline.repeatableState) {
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
      await deadlineProvider
          .handleRepeating(
              deadline: prevDeadline,
              delta: deadline,
              single: deleteSingle,
              delete: true)
          .catchError((e) => Tiles.displayError(context: context, e: e),
              test: (e) =>
                  e is InvalidRepeatingException ||
                  e is FailureToUpdateException ||
                  e is FailureToUploadException ||
                  e is FailureToDeleteException);

      deadline.toDelete = true;
      return await eventProvider
          .updateEventModel(
            oldModel: prevDeadline,
            newModel: deadline,
            notify: true,
          )
          .whenComplete(() => Navigator.pop(context));
    }

    await deadlineProvider.deleteDeadline(deadline: deadline).catchError(
        (e) => Tiles.displayError(context: context, e: e),
        test: (e) => e is FailureToDeleteException);

    deadline.toDelete = true;
    return await eventProvider
        .updateEventModel(
          oldModel: prevDeadline,
          newModel: deadline,
          notify: true,
        )
        .whenComplete(() => Navigator.pop(context));
  }

  Future<void> updateAndValidate() async {
    deadline.name = nameEditingController.text;
    deadline.description = descriptionEditingController.text;

    if (validateData()) {
      await handleUpdate();
    }
  }

  void handleClose({required bool willDiscard}) {
    if (willDiscard) {
      deadlineProvider.rebuild = true;
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
        _checkRepeating = true;
        deadline.priority = newSelection.first;
      });
    }
  }

  void clearWarnMe() {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        _checkRepeating = true;
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
        _checkRepeating = true;
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
        _checkRepeating = true;
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
        _checkRepeating = true;
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
        _checkRepeating = true;
        showStartTime = false;
        showDueTime = false;
      });
    }
  }

  void updateTimes({bool? checkClose, TimeOfDay? newStart, TimeOfDay? newDue}) {
    if (mounted) {
      setState(() {
        checkClose = checkClose ?? this.checkClose;
        _checkRepeating = true;
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
        _checkRepeating = true;
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
        _checkRepeating = true;
        this.checkClose = (checkClose!)
            ? userProvider.curUser?.checkClose ?? checkClose!
            : checkClose!;
        deadline.frequency = newFreq;
        deadline.repeatSkip = newSkip;

        deadline.repeatable = (Frequency.once != deadline.frequency &&
            prevDeadline.repeatable == false);

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
    MediaQuery.sizeOf(context);

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
                  child: Material(
                    color: Colors.transparent,
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
                                            leading:
                                                ListTileWidgets.deadlineIcon(
                                              currentContext: context,
                                              iconPadding: const EdgeInsets.all(
                                                  Constants.padding),
                                              outerPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: Constants
                                                          .halfPadding),
                                            ),
                                            context: context,
                                            hintText: "Deadline Name",
                                            errorText: nameErrorText,
                                            controller: nameEditingController,
                                            outerPadding:
                                                const EdgeInsets.symmetric(
                                                    vertical:
                                                        Constants.padding),
                                            textFieldPadding:
                                                const EdgeInsets.only(
                                              left: Constants.padding,
                                            ),
                                            handleClear: clearNameField,
                                            onEditingComplete: updateName),

                                        Tiles.priorityTile(
                                          context: context,
                                          outerPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: Constants.padding,
                                                  vertical:
                                                      Constants.doublePadding),
                                          priority: deadline.priority,
                                          onSelectionChanged: changePriority,
                                        ),

                                        const PaddedDivider(
                                            padding: Constants.padding),
                                        Tiles.singleDateTimeTile(
                                          outerPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal:
                                                      Constants.padding),
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
                                                  horizontal:
                                                      Constants.padding),
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
                                        if (showTimeTile) ...[
                                          const PaddedDivider(
                                              padding: Constants.padding),
                                          Tiles.timeTile(
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
                                          ),
                                        ],

                                        if (showRepeatTile) ...[
                                          const PaddedDivider(
                                              padding: Constants.padding),
                                          Tiles.repeatableTile(
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
                                        ],
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
                                          outerPadding: const EdgeInsets.all(
                                              Constants.padding),
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
                        leading: ListTileWidgets.deadlineIcon(
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
                            vertical: Constants.padding),
                        textFieldPadding: const EdgeInsets.only(
                          left: Constants.padding,
                        ),
                        handleClear: clearNameField,
                        onEditingComplete: updateName),

                    Tiles.priorityTile(
                      mobile: smallScreen,
                      context: context,
                      outerPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding,
                          vertical: Constants.doublePadding),
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

                    // Time
                    if (showTimeTile) ...[
                      const PaddedDivider(padding: Constants.padding),
                      Tiles.timeTile(
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
                      ),
                    ],
                    // Repeatable Stuff -> Show status, on click, open a dialog.
                    if (showRepeatTile) ...[
                      const PaddedDivider(padding: Constants.padding),
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
