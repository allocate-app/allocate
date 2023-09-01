import 'dart:math';

import 'package:another_flushbar/flushbar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:provider/provider.dart';

import '../../../model/task/deadline.dart';
import '../../../providers/deadline_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/exceptions.dart';
import '../../widgets/flushbars.dart';
import '../../widgets/padded_divider.dart';

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
    } else {
      deadline.customFreq = CustomFrequency.weekly;
    }

    return valid;
  }

  void handleWarnDate() {
    DateTime? tmpWarnDate =
        (Constants.nullDate != deadline.warnDate) ? deadline.warnDate : null;
    TimeOfDay tmpWarnTime = (Constants.nullDate != deadline.warnDate)
        ? TimeOfDay.fromDateTime(deadline.warnDate)
        : Constants.midnight;
    showDialog<bool?>(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (context, setState) => Dialog(
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
                                    "Select Warning Date",
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
                                          borderRadius: BorderRadius.circular(
                                              Constants.roundedCorners),
                                          border: Border.all(
                                              strokeAlign: BorderSide
                                                  .strokeAlignOutside),
                                        ),
                                        child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Expanded(
                                                child: TextButton(
                                                    onPressed: () {
                                                      // Consider moving this to shifting focus to calendar
                                                      // using focusNode.
                                                      if (null == tmpWarnDate) {
                                                        setState(() =>
                                                            tmpWarnDate =
                                                                DateTime.now());
                                                      }
                                                    },
                                                    child: (null != tmpWarnDate)
                                                        ? AutoSizeText(
                                                            Jiffy.parseFromDateTime(
                                                                    tmpWarnDate!)
                                                                .format(
                                                                    pattern:
                                                                        "yMMMMd"),
                                                            softWrap: false,
                                                            overflow:
                                                                TextOverflow
                                                                    .visible,
                                                            maxLines: 1,
                                                            minFontSize:
                                                                Constants.small,
                                                          )
                                                        : const AutoSizeText(
                                                            "Warn Date",
                                                            softWrap: true,
                                                            overflow:
                                                                TextOverflow
                                                                    .visible,
                                                            maxLines: 1,
                                                            minFontSize:
                                                                Constants
                                                                    .small)),
                                              ),
                                              (null != tmpWarnDate)
                                                  ? IconButton(
                                                      icon: const Icon(
                                                          Icons.clear_outlined),
                                                      selectedIcon: const Icon(
                                                          Icons.clear),
                                                      onPressed: () =>
                                                          setState(() {
                                                        checkClose = true;
                                                        tmpWarnDate = null;
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
                                            style: Constants.hugeHeaderStyle,
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
                                          borderRadius: BorderRadius.circular(
                                              Constants.roundedCorners),
                                          border: Border.all(
                                              strokeAlign: BorderSide
                                                  .strokeAlignOutside),
                                        ),
                                        child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Expanded(
                                                child: TextButton(
                                                    onPressed: () async {
                                                      final TimeOfDay? picked =
                                                          await showTimePicker(
                                                        context: context,
                                                        initialTime:
                                                            tmpWarnTime,
                                                      );
                                                      if (null != picked) {
                                                        setState(() {
                                                          tmpWarnTime = picked;
                                                        });
                                                      }
                                                    },
                                                    child: (Constants
                                                                .midnight !=
                                                            tmpWarnTime)
                                                        ? AutoSizeText(
                                                            tmpWarnTime
                                                                .format(context)
                                                                .toString(),
                                                            softWrap: false,
                                                            overflow:
                                                                TextOverflow
                                                                    .visible,
                                                            maxLines: 1,
                                                            minFontSize:
                                                                Constants.small,
                                                          )
                                                        : const AutoSizeText(
                                                            "Warn Time",
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
                                                      tmpWarnTime)
                                                  ? IconButton(
                                                      icon: const Icon(
                                                          Icons.clear_outlined),
                                                      selectedIcon: const Icon(
                                                          Icons.clear),
                                                      onPressed: () =>
                                                          setState(() {
                                                        checkClose = true;
                                                        tmpWarnTime =
                                                            Constants.midnight;
                                                      }),
                                                    )
                                                  : const SizedBox.shrink()
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
                                      value: [tmpWarnDate],
                                      onValueChanged: (dates) {
                                        setState(() {
                                          tmpWarnDate = dates.firstOrNull ??
                                              Constants.nullDate;
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
                                          icon:
                                              const Icon(Icons.close_outlined),
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          label: const AutoSizeText("Cancel",
                                              softWrap: false,
                                              overflow: TextOverflow.visible,
                                              maxLines: 1,
                                              minFontSize: Constants.small)),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          left: Constants.padding),
                                      child: FilledButton.icon(
                                        icon: const Icon(Icons.done_outlined),
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
          deadline.warnDate = tmpWarnDate ?? Constants.nullDate;
          deadline.warnMe = (Constants.nullDate != deadline.warnDate);
          if (Constants.nullDate != deadline.warnDate) {
            deadline.warnDate = deadline.warnDate
                .copyWith(hour: tmpWarnTime.hour, minute: tmpWarnTime.minute);
          }
        }
      });
    });
  }

  Future<void> handleUpdate({required BuildContext context}) async {
    if (prevDeadline.frequency != Frequency.once && checkClose) {
      bool? updateSingle = await showModalBottomSheet<bool?>(
          showDragHandle: true,
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
                builder: (context, setState) => Center(
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
                        ])));
          });
      // If the modal is discarded.
      if (null == updateSingle) {
        return;
      }

      await deadlineProvider.deleteFutures(deadline: prevDeadline).catchError(
          (e) {
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

  Future<void> handleDelete({required BuildContext context}) async {
    if (prevDeadline.frequency != Frequency.once) {
      bool? updateSingle = await showModalBottomSheet<bool?>(
          showDragHandle: true,
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
                builder: (context, setState) => Center(
                    heightFactor: 1,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(Constants.padding),
                            child: FilledButton.icon(
                                onPressed: () => Navigator.pop(context, true),
                                label: const Text("Delete This Event"),
                                icon: const Icon(Icons.arrow_upward_outlined)),
                          ),
                          Padding(
                              padding: const EdgeInsets.all(Constants.padding),
                              child: FilledButton.tonalIcon(
                                onPressed: () => Navigator.pop(context, false),
                                label: const Text("Delete All"),
                                icon: const Icon(Icons.repeat_outlined),
                              ))
                        ])));
          });
      // If the modal is discarded.
      if (null == updateSingle) {
        return;
      }

      await deadlineProvider.deleteFutures(deadline: prevDeadline).catchError(
          (e) {
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

  @override
  Widget build(BuildContext context) {
    bool largeScreen =
        (MediaQuery.of(context).size.width >= Constants.largeScreen);
    bool smallScreen =
        (MediaQuery.of(context).size.width <= Constants.smallScreen);

    bool showTimeTile = (Constants.nullDate != deadline.startDate ||
        Constants.nullDate != deadline.dueDate);

    return (largeScreen)
        ? buildDesktopDialog(
            context: context,
            showTimeTile: showTimeTile,
            smallScreen: smallScreen,
            largeScreen: largeScreen)
        : buildMobileDialog(
            context: context,
            showTimeTile: showTimeTile,
            smallScreen: smallScreen,
            largeScreen: largeScreen);
  }

  Dialog buildDesktopDialog(
      {required BuildContext context,
      bool smallScreen = false,
      bool largeScreen = false,
      showTimeTile = false}) {
    return Dialog(
      insetPadding: const EdgeInsets.all(Constants.outerDialogPadding),
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxHeight: Constants.maxLandscapeDialogHeight),
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
                              "Update Deadline",
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
                Expanded(
                  flex: 3,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // This may need to be a listview.
                        Expanded(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Title
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: Constants.padding),
                                  child:
                                      buildNameTile(smallScreen: smallScreen),
                                ),
                                const PaddedDivider(
                                    padding: Constants.innerPadding),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: Constants.innerPadding),
                                  child: buildPriorityTile(
                                      smallScreen: smallScreen),
                                ),

                                const PaddedDivider(
                                    padding: Constants.innerPadding),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: Constants.padding),
                                  child:
                                      buildWarnMeTile(smallScreen: smallScreen),
                                ),
                                const PaddedDivider(
                                    padding: Constants.innerPadding),
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: Constants.padding),
                                    child: buildDateTile(context: context)),
                                const PaddedDivider(
                                    padding: Constants.innerPadding),

                                (showTimeTile)
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: Constants.padding),
                                        child: buildTimeTile(),
                                      )
                                    : const SizedBox.shrink(),
                                (showTimeTile)
                                    ? const PaddedDivider(
                                        padding: Constants.innerPadding)
                                    : const SizedBox.shrink(),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: Constants.padding),
                                  child: buildRepeatableTile(
                                      context: context,
                                      smallScreen: smallScreen),
                                )
                              ]),
                        ),
                        Expanded(
                          child: Scrollbar(
                            thumbVisibility: true,
                            controller: subScrollControllerRight,
                            child: ListView(
                                controller: subScrollControllerRight,
                                physics: scrollPhysics,
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: Constants.padding),
                                children: [
                                  // RoutineTasks
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: Constants.innerPadding,
                                        vertical: Constants.padding),
                                    child: buildDescriptionTile(
                                        smallScreen: smallScreen,
                                        largeScreen: largeScreen),
                                  ),
                                ]),
                          ),
                        )
                      ]),
                ),

                const PaddedDivider(padding: Constants.padding),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: Constants.padding),
                  child: buildUpdateDeleteRow(context: context),
                )
              ]),
        ),
      ),
    );
  }

  Dialog buildMobileDialog(
      {required BuildContext context,
      bool smallScreen = false,
      bool largeScreen = false,
      showTimeTile = false}) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
          horizontal: Constants.outerDialogPadding,
          vertical: Constants.smallOuterDialogPadding),
      child: Padding(
        padding: const EdgeInsets.all(Constants.padding),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title && Close Button
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: Constants.padding),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: AutoSizeText(
                          "Update Deadline",
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
              const PaddedDivider(padding: Constants.padding),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  controller: mainScrollController,
                  physics: scrollPhysics,
                  children: [
                    // Title + status
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      child: buildNameTile(smallScreen: smallScreen),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Constants.innerPadding),
                      child: buildWarnMeTile(smallScreen: smallScreen),
                    ),

                    const PaddedDivider(padding: Constants.innerPadding),
                    // Priority
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Constants.innerPadding),
                      child: buildPriorityTile(smallScreen: smallScreen),
                    ),

                    const PaddedDivider(padding: Constants.innerPadding),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Constants.innerPadding),
                      child: buildDescriptionTile(
                          smallScreen: smallScreen, largeScreen: largeScreen),
                    ),
                    const PaddedDivider(padding: Constants.innerPadding),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Constants.innerPadding),
                      child: buildDateTile(context: context),
                    ),

                    const PaddedDivider(padding: Constants.innerPadding),
                    // Time
                    (showTimeTile)
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: Constants.innerPadding),
                            child: buildTimeTile(),
                          )
                        : const SizedBox.shrink(),

                    (showTimeTile)
                        ? const PaddedDivider(padding: Constants.innerPadding)
                        : const SizedBox.shrink(),
                    // Repeatable Stuff -> Show status, on click, open a dialog.
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Constants.innerPadding),
                      child: buildRepeatableTile(
                          context: context, smallScreen: smallScreen),
                    ),
                  ],
                ),
              ),

              const PaddedDivider(padding: Constants.padding),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: Constants.padding),
                child: buildUpdateDeleteRow(context: context),
              )
            ]),
      ),
    );
  }

  Row buildUpdateDeleteRow({required BuildContext context}) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      Flexible(
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
            child: buildDeleteButton(context: context)),
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
        label: const Text("Update"),
        icon: const Icon(Icons.add),
        onPressed: () async {
          bool validData = validateData();
          if (validData) {
            handleUpdate(context: context);
          }
          // Then save.
        });
  }

  Row buildNameTile({bool smallScreen = false}) {
    return Row(
      children: [
        Expanded(
            child: Padding(
          padding: const EdgeInsets.all(Constants.padding),
          child: buildDeadlineName(smallScreen: smallScreen),
        )),
      ],
    );
  }

  AutoSizeTextField buildDeadlineName({bool smallScreen = false}) {
    return AutoSizeTextField(
      maxLines: 1,
      minFontSize: Constants.medium,
      decoration: InputDecoration(
        isDense: smallScreen,
        suffixIcon: (deadline.name != "")
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  nameEditingController.clear();
                  setState(() => deadline.name = "");
                })
            : null,
        contentPadding: const EdgeInsets.all(Constants.innerPadding),
        border: const OutlineInputBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners)),
            borderSide: BorderSide(
              strokeAlign: BorderSide.strokeAlignOutside,
            )),
        hintText: "Deadline name",
        errorText: nameErrorText,
      ),
      controller: nameEditingController,
    );
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

  ListTile buildWarnMeTile({bool smallScreen = false}) {
    TimeOfDay warnTime = TimeOfDay.fromDateTime(deadline.warnDate);
    return ListTile(
      title: (deadline.warnMe && Constants.nullDate != deadline.warnDate)
          ? Row(children: [
              const Flexible(
                child: Icon(Icons.event_outlined),
              ),
              Flexible(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: Constants.padding),
                  child: AutoSizeText(
                      Jiffy.parseFromDateTime(deadline.warnDate)
                          .format(pattern: "MMM d"),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      maxLines: 2,
                      minFontSize: Constants.small),
                ),
              ),
              (Constants.midnight != warnTime)
                  ? const Flexible(
                      child: Padding(
                        padding: EdgeInsets.only(right: Constants.padding),
                        child: Flexible(child: Icon(Icons.schedule_outlined)),
                      ),
                    )
                  : const Flexible(
                      child: Padding(
                      padding: EdgeInsets.only(right: Constants.padding),
                      child: Icon(Icons.history_toggle_off_outlined),
                    )),
              (Constants.midnight != warnTime)
                  ? Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: Constants.padding),
                        child: AutoSizeText(
                          warnTime.format(context).toString(),
                          overflow: TextOverflow.visible,
                          softWrap: false,
                          minFontSize: Constants.medium,
                          maxLines: 1,
                        ),
                      ),
                    )
                  : const Flexible(
                      child: AutoSizeText(
                        "Warn Time",
                        overflow: TextOverflow.visible,
                        softWrap: false,
                        minFontSize: Constants.medium,
                        maxLines: 1,
                      ),
                    ),
            ])
          : const AutoSizeText(
              "Warn me?",
              overflow: TextOverflow.visible,
              softWrap: true,
              minFontSize: Constants.medium,
              maxLines: 2,
            ),
      leading: (deadline.warnMe)
          ? IconButton.filledTonal(
              icon: const Icon(Icons.notifications),
              onPressed: () => handleWarnDate(),
            )
          : IconButton.outlined(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => handleWarnDate()),
      trailing: (deadline.warnMe)
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() {
                    checkClose = false;
                    deadline.warnDate = Constants.nullDate.copyWith(
                        hour: Constants.midnight.hour,
                        minute: Constants.midnight.minute);
                    deadline.warnMe = false;
                  }))
          : null,
      onTap: () => handleWarnDate(),
    );
  }

  SegmentedButton<Priority> buildPriorityTile({bool smallScreen = false}) {
    return SegmentedButton<Priority>(
        selectedIcon: const Icon(Icons.flag_circle),
        style: ButtonStyle(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        segments: Priority.values
            .map((Priority type) => ButtonSegment<Priority>(
                icon: Constants.priorityIcon[type],
                value: type,
                label: Text("${toBeginningOfSentenceCase(type.name)}",
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: (smallScreen) ? Constants.minBodyText : null)))
            .toList(growable: false),
        selected: <Priority>{deadline.priority},
        onSelectionChanged: (Set<Priority> newSelection) => setState(() {
              checkClose = true;
              deadline.priority = newSelection.first;
            }));
  }

  AutoSizeTextField buildDescriptionTile(
      {bool smallScreen = false, bool largeScreen = false}) {
    return AutoSizeTextField(
        controller: descriptionEditingController,
        maxLines: (smallScreen) ? Constants.descripMaxLinesBeforeScroll : null,
        minLines: (smallScreen)
            ? Constants.descripMinLinesMobile
            : (largeScreen)
                ? Constants.descripMaxLinesBeforeScroll
                : Constants.descripMinLinesDesktop,
        minFontSize: Constants.medium,
        decoration: InputDecoration(
          isDense: smallScreen,
          contentPadding: const EdgeInsets.all(Constants.innerPadding),
          hintText: "Description",
          border: const OutlineInputBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(Constants.roundedCorners)),
              borderSide: BorderSide(
                strokeAlign: BorderSide.strokeAlignOutside,
              )),
        ));
  }

  ListTile buildDateTile({required BuildContext context}) {
    return ListTile(
      leading: const Icon(Icons.today_outlined),
      title: (Constants.nullDate == deadline.startDate &&
              Constants.nullDate == deadline.dueDate)
          ? const AutoSizeText(
              "Add Dates",
              softWrap: true,
              overflow: TextOverflow.visible,
              maxLines: 2,
              minFontSize: Constants.small,
            )
          : Row(
              children: [
                (Constants.nullDate == deadline.startDate)
                    ? const Flexible(
                        child: AutoSizeText(
                          "Start Date",
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          maxLines: 2,
                          minFontSize: Constants.small,
                        ),
                      )
                    : Flexible(
                        child: AutoSizeText(
                            Jiffy.parseFromDateTime(deadline.startDate).format(
                              pattern: "MMM d",
                            ),
                            softWrap: true,
                            overflow: TextOverflow.visible,
                            maxLines: 2,
                            minFontSize: Constants.small)),
                const Flexible(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: Constants.padding),
                    child: AutoSizeText(
                      "-",
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      maxLines: 1,
                      minFontSize: Constants.small,
                    ),
                  ),
                ),
                (Constants.nullDate == deadline.dueDate)
                    ? const Flexible(
                        child: Padding(
                          padding: EdgeInsets.only(right: Constants.padding),
                          child: Flexible(child: Icon(Icons.today_outlined)),
                        ),
                      )
                    : const Flexible(
                        child: Padding(
                        padding: EdgeInsets.only(right: Constants.padding),
                        child: Icon(Icons.event_outlined),
                      )),
                (Constants.nullDate == deadline.dueDate)
                    ? const Flexible(
                        child: AutoSizeText(
                          "Due Date",
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          maxLines: 2,
                          minFontSize: Constants.small,
                        ),
                      )
                    : Flexible(
                        child: AutoSizeText(
                            Jiffy.parseFromDateTime(deadline.dueDate)
                                .format(pattern: "MMM d"),
                            softWrap: true,
                            overflow: TextOverflow.visible,
                            maxLines: 2,
                            minFontSize: Constants.small),
                      )
              ],
            ),
      trailing: (Constants.nullDate != deadline.startDate ||
              Constants.nullDate != deadline.dueDate)
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() {
                    checkClose = true;
                    deadline.startDate = Constants.nullDate;
                    deadline.dueDate = Constants.nullDate;
                  }))
          : null,
      onTap: () {
        showDialog<void>(
            context: context,
            builder: (BuildContext context) {
              DateTime? tmpStart = (Constants.nullDate != deadline.startDate)
                  ? deadline.startDate
                  : null;
              DateTime? tmpDue = (Constants.nullDate != deadline.dueDate)
                  ? deadline.dueDate
                  : null;
              DateTime initDate = tmpStart ?? tmpDue ?? DateTime.now();
              bool setStart = false;
              final int numDays =
                  (tmpDue?.difference(initDate).inDays ?? 0) + 1;
              List<DateTime?> showDates = List.generate(
                  numDays, (i) => initDate.add(Duration(days: i)));

              // List ->
              return StatefulBuilder(
                  builder: (context, setState) => Dialog(
                          child: Padding(
                        padding: const EdgeInsets.all(Constants.innerPadding),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Expanded(
                                      child: AutoSizeText(
                                        "Select Dates",
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
                                    Flexible(
                                        child: AutoSizeText(
                                      "Start | Due ",
                                      style: Constants.largeHeaderStyle,
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                      maxLines: 1,
                                      minFontSize: Constants.large,
                                    )),
                                    Flexible(
                                      child: FittedBox(
                                          fit: BoxFit.fill,
                                          child: Icon(Icons.date_range_outlined,
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
                                        MainAxisAlignment.spaceEvenly,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Expanded(
                                        flex: 10,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
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
                                                      onPressed: () =>
                                                          setState(() {
                                                            setStart = true;
                                                            tmpStart =
                                                                tmpStart ??
                                                                    DateTime
                                                                        .now();
                                                          }),
                                                      child: (null != tmpStart)
                                                          ? AutoSizeText(
                                                              Jiffy.parseFromDateTime(
                                                                      tmpStart!)
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
                                                              "Start Date",
                                                              softWrap: true,
                                                              overflow:
                                                                  TextOverflow
                                                                      .visible,
                                                              maxLines: 1,
                                                              minFontSize:
                                                                  Constants
                                                                      .small)),
                                                ),
                                                (null != tmpStart)
                                                    ? IconButton(
                                                        icon: const Icon(Icons
                                                            .clear_outlined),
                                                        selectedIcon:
                                                            const Icon(
                                                                Icons.clear),
                                                        onPressed: () =>
                                                            setState(() {
                                                          checkClose = true;
                                                          showDates
                                                              .remove(tmpStart);
                                                          tmpStart = null;
                                                        }),
                                                      )
                                                    : const SizedBox.shrink(),
                                              ]),
                                        ),
                                      ),
                                      const Flexible(
                                        flex: 1,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  Constants.halfPadding),
                                          child: AutoSizeText("|",
                                              style: Constants.largeHeaderStyle,
                                              softWrap: false,
                                              overflow: TextOverflow.visible,
                                              maxLines: 1,
                                              minFontSize: Constants.small),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 10,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
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
                                                      onPressed: () =>
                                                          setState(() {
                                                            setStart = false;
                                                            tmpDue = tmpDue ??
                                                                DateTime.now();
                                                          }),
                                                      child: (null != tmpDue)
                                                          ? AutoSizeText(
                                                              Jiffy.parseFromDateTime(
                                                                      tmpDue!)
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
                                                              "Due Date",
                                                              softWrap: true,
                                                              overflow:
                                                                  TextOverflow
                                                                      .visible,
                                                              maxLines: 1,
                                                              minFontSize:
                                                                  Constants
                                                                      .small)),
                                                ),
                                                (null != tmpDue)
                                                    ? IconButton(
                                                        icon: const Icon(Icons
                                                            .clear_outlined),
                                                        selectedIcon:
                                                            const Icon(
                                                                Icons.clear),
                                                        onPressed: () =>
                                                            setState(() {
                                                          checkClose = false;
                                                          showDates
                                                              .remove(tmpDue);
                                                          tmpDue = null;
                                                        }),
                                                      )
                                                    : const SizedBox.shrink()
                                              ]),
                                        ),
                                      ),
                                    ]),
                              ),

                              // Calendar view.
                              Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CalendarDatePicker2(
                                        config: CalendarDatePicker2Config(
                                          calendarType:
                                              CalendarDatePicker2Type.range,
                                          firstDate: DateTime(1970),
                                          lastDate: DateTime(3000),
                                        ),
                                        value: showDates,
                                        onValueChanged: (dates) {
                                          setState(() {
                                            if (dates.length > 1) {
                                              tmpStart = dates.first;
                                              tmpDue = dates.last;
                                            } else {
                                              (setStart)
                                                  ? tmpStart = dates.first
                                                  : tmpDue = dates.first;
                                            }
                                            showDates = dates;
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
                                                Navigator.pop(context),
                                            label: const AutoSizeText("Cancel",
                                                softWrap: false,
                                                overflow: TextOverflow.visible,
                                                maxLines: 1,
                                                minFontSize: Constants.small)),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            left: Constants.padding),
                                        child: FilledButton.icon(
                                          icon: const Icon(Icons.done_outlined),
                                          onPressed: () {
                                            setState(() {
                                              checkClose = true;
                                              deadline.startDate = tmpStart ??
                                                  Constants.nullDate;
                                              deadline.dueDate =
                                                  tmpDue ?? Constants.nullDate;

                                              if (Constants.nullDate !=
                                                      deadline.startDate &&
                                                  Constants.nullDate !=
                                                      deadline.dueDate &&
                                                  deadline.startDate.isAfter(
                                                      deadline.dueDate)) {
                                                deadline.startDate =
                                                    deadline.dueDate;
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
                                  ]),
                            ]),
                      )));
              // This is to update the main context after updating.
            }).then((_) => setState(() {}));
      },
    );
  }

  ListTile buildTimeTile() {
    TimeOfDay? startTime = TimeOfDay.fromDateTime(deadline.startDate);
    TimeOfDay? dueTime = TimeOfDay.fromDateTime(deadline.dueDate);

    return ListTile(
        leading: const Icon(Icons.schedule_outlined),
        title: (Constants.midnight == startTime &&
                Constants.midnight == dueTime)
            ? const AutoSizeText(
                "Add Times",
                overflow: TextOverflow.visible,
                minFontSize: Constants.small,
                maxLines: 2,
                softWrap: true,
              )
            : Row(children: [
                (Constants.midnight == startTime)
                    ? const Flexible(
                        child: AutoSizeText(
                        "Start Time",
                        softWrap: true,
                        overflow: TextOverflow.visible,
                        maxLines: 2,
                        minFontSize: Constants.small,
                      ))
                    : Flexible(
                        child: AutoSizeText(
                        "Start @: ${startTime.format(context).toString()}",
                        softWrap: true,
                        overflow: TextOverflow.visible,
                        maxLines: 2,
                        minFontSize: Constants.small,
                      )),
                (Constants.midnight == dueTime)
                    ? const Flexible(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: Constants.padding),
                          child: FittedBox(
                              fit: BoxFit.fill,
                              child: Icon(Icons.history_toggle_off_outlined)),
                        ),
                      )
                    : const Flexible(
                        child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: Constants.padding),
                        child: FittedBox(
                            fit: BoxFit.fill,
                            child: Icon(Icons.schedule_outlined)),
                      )),
                (Constants.midnight == dueTime)
                    ? const Flexible(
                        child: AutoSizeText(
                          "Due Time",
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          maxLines: 2,
                          minFontSize: Constants.small,
                        ),
                      )
                    : Flexible(
                        child: AutoSizeText(
                          "Due @: ${dueTime.format(context).toString()}",
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          maxLines: 2,
                          minFontSize: Constants.small,
                        ),
                      ),
              ]),
        onTap: () {
          showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                return StatefulBuilder(
                    builder: (context, setState) => Dialog(
                            child: Padding(
                          padding: const EdgeInsets.all(Constants.innerPadding),
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Expanded(
                                        child: AutoSizeText(
                                          "Select Times",
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
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                          child: AutoSizeText(
                                        "Start | Due ",
                                        style: Constants.largeHeaderStyle,
                                        softWrap: true,
                                        overflow: TextOverflow.visible,
                                        maxLines: 1,
                                        minFontSize: Constants.large,
                                      )),
                                      Flexible(
                                        child: FittedBox(
                                            fit: BoxFit.fill,
                                            child: Icon(Icons.schedule_outlined,
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
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Expanded(
                                          flex: 10,
                                          child: OutlinedButton(
                                              onPressed: () async {
                                                final TimeOfDay? picked =
                                                    await showTimePicker(
                                                        context: context,
                                                        initialTime:
                                                            startTime ??
                                                                Constants
                                                                    .midnight);
                                                if (null != picked) {
                                                  setState(() {
                                                    showStartTime = true;
                                                    startTime = picked;
                                                  });
                                                }
                                              },
                                              child: (Constants.midnight !=
                                                      startTime)
                                                  ? AutoSizeText(
                                                      startTime!
                                                          .format(context)
                                                          .toString(),
                                                      softWrap: false,
                                                      overflow:
                                                          TextOverflow.visible,
                                                      maxLines: 1,
                                                      minFontSize:
                                                          Constants.small,
                                                    )
                                                  : const AutoSizeText(
                                                      "Start Time",
                                                      softWrap: true,
                                                      overflow:
                                                          TextOverflow.visible,
                                                      maxLines: 1,
                                                      minFontSize:
                                                          Constants.small)),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  Constants.halfPadding),
                                          child: Text("|",
                                              style: Constants.timeColon),
                                        ),
                                        Expanded(
                                          flex: 10,
                                          child: OutlinedButton(
                                              onPressed: () async {
                                                final TimeOfDay? picked =
                                                    await showTimePicker(
                                                        context: context,
                                                        initialTime: dueTime ??
                                                            Constants.midnight);
                                                if (null != picked) {
                                                  setState(() {
                                                    showDueTime = true;
                                                    dueTime = picked;
                                                  });
                                                }
                                              },
                                              child: (Constants.midnight !=
                                                      dueTime)
                                                  ? AutoSizeText(
                                                      dueTime!
                                                          .format(context)
                                                          .toString(),
                                                      softWrap: false,
                                                      overflow:
                                                          TextOverflow.visible,
                                                      maxLines: 1,
                                                      minFontSize:
                                                          Constants.small,
                                                    )
                                                  : const AutoSizeText(
                                                      "Due Time",
                                                      softWrap: true,
                                                      overflow:
                                                          TextOverflow.visible,
                                                      maxLines: 1,
                                                      minFontSize:
                                                          Constants.small)),
                                        ),
                                      ]),
                                ),
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
                                                startTime = startTime ??
                                                    Constants.midnight;
                                                dueTime = dueTime ??
                                                    Constants.midnight;
                                                deadline.startDate =
                                                    deadline.startDate.copyWith(
                                                        hour: startTime!.hour,
                                                        minute:
                                                            startTime!.minute);
                                                deadline.dueDate =
                                                    deadline.dueDate.copyWith(
                                                        hour: dueTime!.hour,
                                                        minute:
                                                            dueTime!.minute);
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
                                    ]),
                              ]),
                        )));
              }).then((_) => setState(() {}));
        },
        trailing:
            (Constants.midnight != startTime || Constants.midnight != dueTime)
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() {
                      checkClose = true;

                      deadline.startDate = deadline.startDate.copyWith(
                          hour: Constants.midnight.hour,
                          minute: Constants.midnight.minute);
                      deadline.dueDate = deadline.dueDate.copyWith(
                          hour: Constants.midnight.hour,
                          minute: Constants.midnight.minute);
                    }),
                  )
                : null);
  }

  ListTile buildRepeatableTile(
      {required BuildContext context, bool smallScreen = false}) {
    return ListTile(
        leading: const Icon(Icons.event_repeat_outlined),
        title: (deadline.frequency == Frequency.once)
            ? const AutoSizeText("Set Recurring?",
                overflow: TextOverflow.visible,
                minFontSize: Constants.small,
                maxLines: 2,
                softWrap: true)
            : AutoSizeText(toBeginningOfSentenceCase(deadline.frequency.name)!,
                overflow: TextOverflow.visible,
                minFontSize: Constants.small,
                maxLines: 1,
                softWrap: false),
        onTap: () {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                Frequency cacheFreq = deadline.frequency;
                CustomFrequency cacheCustom = deadline.customFreq;
                Set<int> cacheWeekdays = {};

                for (int i = 0; i < deadline.repeatDays.length; i++) {
                  if (deadline.repeatDays[i]) {
                    cacheWeekdays.add(i);
                  }
                }

                if (cacheWeekdays.isEmpty) {
                  int day = (Constants.nullDate != deadline.startDate)
                      ? max(deadline.startDate.weekday - 1, 0)
                      : max(DateTime.now().weekday - 1, 0);
                  cacheWeekdays.add(day);
                }

                int cacheSkip = deadline.repeatSkip;

                return StatefulBuilder(builder: (context, setState) {
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
                                            setState(() =>
                                                cacheFreq = value ?? cacheFreq),
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
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal:
                                                    Constants.innerPadding),
                                            child: InputDecorator(
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(
                                                    gapPadding: 0,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                Constants
                                                                    .circular)),
                                                    borderSide: BorderSide(
                                                        strokeAlign: BorderSide
                                                            .strokeAlignOutside)),
                                              ),
                                              child:
                                                  DropdownButtonHideUnderline(
                                                child: DropdownButton<
                                                    CustomFrequency>(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal:
                                                          Constants.padding),
                                                  isDense: true,
                                                  isExpanded: true,
                                                  dropdownColor:
                                                      Constants.dialogColor(
                                                          context: context),
                                                  borderRadius: const BorderRadius
                                                      .all(Radius.circular(
                                                          Constants
                                                              .roundedCorners)),
                                                  value: cacheCustom,
                                                  onChanged: (CustomFrequency?
                                                          value) =>
                                                      setState(() =>
                                                          cacheCustom = value ??
                                                              cacheCustom),
                                                  items: CustomFrequency.values
                                                      .map((CustomFrequency
                                                              customFreq) =>
                                                          DropdownMenuItem<
                                                              CustomFrequency>(
                                                            value: customFreq,
                                                            child: AutoSizeText(
                                                              "${toBeginningOfSentenceCase(customFreq.name)}",
                                                              softWrap: false,
                                                              maxLines: 1,
                                                              minFontSize:
                                                                  Constants
                                                                      .small,
                                                            ),
                                                          ))
                                                      .toList(),
                                                ),
                                              ),
                                            ),
                                          ),
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
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .surfaceVariant,
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
                                                                              deadline
                                                                                  .startDate)
                                                                          ? max(
                                                                              deadline.startDate.weekday -
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
                                                      setState(() =>
                                                          cacheSkip = value);
                                                    })),
                                            Flexible(
                                              child: AutoSizeText(
                                                (cacheFreq == Frequency.custom)
                                                    ? cacheCustom.name
                                                        .replaceAll(
                                                            "ly",
                                                            (cacheSkip > 1)
                                                                ? "s."
                                                                : ".")
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
                                                deadline.frequency = cacheFreq;
                                                deadline.customFreq =
                                                    cacheCustom;
                                                deadline.repeatSkip = cacheSkip;
                                                deadline.repeatSkip = cacheSkip;
                                                if (cacheWeekdays.isEmpty) {
                                                  cacheWeekdays.add(deadline
                                                          .startDate.weekday -
                                                      1);
                                                }
                                                for (int i = 0;
                                                    i <
                                                        deadline
                                                            .repeatDays.length;
                                                    i++) {
                                                  deadline.repeatDays[i] =
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
        trailing: (deadline.frequency != Frequency.once)
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() {
                      checkClose = true;
                      deadline.frequency = Frequency.once;
                      deadline.customFreq = CustomFrequency.weekly;
                      deadline.repeatDays
                          .fillRange(0, deadline.repeatDays.length, false);
                      deadline.repeatSkip = 1;
                    }))
            : null);
  }
}
