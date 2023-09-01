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

import '../../../providers/deadline_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/exceptions.dart';
import '../../widgets/flushbars.dart';
import '../../widgets/padded_divider.dart';

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
  late final ScrollController mainScrollController;
  late final ScrollController subScrollControllerLeft;
  late final ScrollController subScrollControllerRight;
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
  late CustomFrequency customFreq;

  late TextEditingController repeatSkipEditingController;
  late int repeatSkip;

  late Set<int> weekDayList;
  late List<bool> weekDays;

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
    name = "";
    priority = Priority.low;
    description = "";
    repeatSkip = 1;

    frequency = Frequency.once;
    customFreq = CustomFrequency.weekly;

    warnMe = false;

    weekDayList = {};
    weekDays = List.generate(7, (_) => false);
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
    nameEditingController = TextEditingController();
    nameEditingController.addListener(() {
      nameErrorText = null;
      checkClose = true;
      String newText = nameEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      setState(() => name = newText);
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
      setState(() => nameErrorText = "Enter Task Name");
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
      if (weekDayList.isEmpty) {
        weekDayList
            .add(min(((startDate?.weekday ?? DateTime.now().weekday) - 1), 0));
      }
    } else {
      customFreq = CustomFrequency.weekly;
    }

    return valid;
  }

  void handleWarnDate() {
    DateTime? tmpWarnDate = warnDate;
    TimeOfDay? tmpWarnTime = warnTime;
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
                                                            tmpWarnTime ??
                                                                Constants
                                                                    .midnight,
                                                      );
                                                      if (null != picked) {
                                                        setState(() =>
                                                            tmpWarnTime =
                                                                picked);
                                                      }
                                                    },
                                                    child: (null != tmpWarnTime)
                                                        ? AutoSizeText(
                                                            tmpWarnTime!
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
                                                            "Time",
                                                            softWrap: true,
                                                            overflow:
                                                                TextOverflow
                                                                    .visible,
                                                            maxLines: 1,
                                                            minFontSize:
                                                                Constants
                                                                    .small)),
                                              ),
                                              (null != tmpWarnTime)
                                                  ? IconButton(
                                                      icon: const Icon(
                                                          Icons.clear_outlined),
                                                      selectedIcon: const Icon(
                                                          Icons.clear),
                                                      onPressed: () =>
                                                          setState(() {
                                                        checkClose = true;
                                                        tmpWarnTime = null;
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
                                      value: [tmpWarnDate],
                                      onValueChanged: (dates) {
                                        setState(() {
                                          tmpWarnDate = dates.firstOrNull;
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
          warnDate = tmpWarnDate;
          warnTime = tmpWarnTime;
          warnMe = (null != warnDate);
        }
      });
    });
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

  Future<void> handleCreate({required BuildContext context}) async {
    for (int index in weekDayList) {
      weekDays[index] = true;
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
          customFreq: customFreq,
          repeatDays: weekDays,
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

  @override
  Widget build(BuildContext context) {
    bool largeScreen =
        (MediaQuery.of(context).size.width >= Constants.largeScreen);
    bool smallScreen =
        (MediaQuery.of(context).size.width <= Constants.smallScreen);

    bool showTimeTile = (null != startDate || null != dueDate);

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
                              "New Deadline",
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
                  child: buildCreateButton(context: context),
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
                          "New Deadline",
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
                child: buildCreateButton(context: context),
              )
            ]),
      ),
    );
  }

  Row buildCreateButton({required BuildContext context}) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      FilledButton.icon(
          label: const Text("Create"),
          icon: const Icon(Icons.add),
          onPressed: () async {
            // WarnMe needs to be merged before validation.
            mergeDateTimes();
            bool validData = validateData();
            if (validData) {
              await handleCreate(context: context);
            }
            // Then save.
          })
    ]);
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
        suffixIcon: (name != "")
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  checkClose = true;
                  nameEditingController.clear();
                  setState(() => name = "");
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
    return ListTile(
      title: (warnMe && null != warnDate)
          ? Row(children: [
              const Flexible(
                child: Icon(Icons.event_outlined),
              ),
              Flexible(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: Constants.padding),
                  child: AutoSizeText(
                      Jiffy.parseFromDateTime(warnDate!)
                          .format(pattern: "MMM d"),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      maxLines: 2,
                      minFontSize: Constants.small),
                ),
              ),
              (null != warnTime)
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
              (null != warnTime)
                  ? Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: Constants.padding),
                        child: AutoSizeText(
                          warnTime!.format(context).toString(),
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
      leading: (warnMe)
          ? IconButton.filledTonal(
              icon: const Icon(Icons.notifications),
              onPressed: () => handleWarnDate(),
            )
          : IconButton.outlined(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => handleWarnDate()),
      trailing: (warnMe)
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() {
                    checkClose = true;
                    warnDate = null;
                    warnTime = null;
                    warnMe = false;
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
        selected: <Priority>{priority},
        onSelectionChanged: (Set<Priority> newSelection) => setState(() {
              checkClose = true;
              priority = newSelection.first;
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
      title: (null == startDate && null == dueDate)
          ? const AutoSizeText(
              "Add Dates",
              softWrap: true,
              overflow: TextOverflow.visible,
              maxLines: 2,
              minFontSize: Constants.small,
            )
          : Row(
              children: [
                (null == startDate)
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
                            Jiffy.parseFromDateTime(startDate!).format(
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
                (null == dueDate)
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
                (null == dueDate)
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
                            Jiffy.parseFromDateTime(dueDate!)
                                .format(pattern: "MMM d"),
                            softWrap: true,
                            overflow: TextOverflow.visible,
                            maxLines: 2,
                            minFontSize: Constants.small),
                      )
              ],
            ),
      trailing: (startDate != null || dueDate != null)
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() {
                    checkClose = true;
                    startDate = null;
                    dueDate = null;
                  }))
          : null,
      onTap: () {
        showDialog<void>(
            context: context,
            builder: (BuildContext context) {
              DateTime? tmpStart = startDate;
              DateTime? tmpDue = dueDate;
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
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.clear_outlined),
                                                  selectedIcon:
                                                      const Icon(Icons.clear),
                                                  onPressed: () => setState(() {
                                                    checkClose = true;
                                                    showDates.remove(tmpStart);
                                                    tmpStart = null;
                                                  }),
                                                )
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
                                                          checkClose = true;
                                                          showDates
                                                              .remove(tmpDue);
                                                          tmpDue = null;
                                                        }),
                                                      )
                                                    : const SizedBox.shrink(),
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
                                              startDate = tmpStart;
                                              dueDate = tmpDue;

                                              if (null != startDate &&
                                                  null != dueDate &&
                                                  startDate!
                                                      .isAfter(dueDate!)) {
                                                startDate = dueDate;
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
    return ListTile(
        leading: const Icon(Icons.schedule_outlined),
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
                        "Start Time",
                        softWrap: true,
                        overflow: TextOverflow.visible,
                        maxLines: 2,
                        minFontSize: Constants.small,
                      ))
                    : Flexible(
                        child: AutoSizeText(
                        "Start @: ${startTime!.format(context).toString()}",
                        softWrap: true,
                        overflow: TextOverflow.visible,
                        maxLines: 2,
                        minFontSize: Constants.small,
                      )),
                (null == dueTime)
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
                (null == dueTime)
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
                          "Due @: ${dueTime!.format(context).toString()}",
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
                TimeOfDay? tmpStart = startTime;
                TimeOfDay? tmpDue = dueTime;
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
                                                        initialTime: tmpStart ??
                                                            Constants.midnight);
                                                if (null != picked) {
                                                  setState(
                                                      () => tmpStart = picked);
                                                }
                                              },
                                              child: (null != tmpStart)
                                                  ? AutoSizeText(
                                                      tmpStart!
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
                                                        initialTime: tmpDue ??
                                                            Constants.midnight);
                                                if (null != picked) {
                                                  setState(
                                                      () => tmpDue = picked);
                                                }
                                              },
                                              child: (null != tmpDue)
                                                  ? AutoSizeText(
                                                      tmpDue!
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
                                                startTime = tmpStart;
                                                dueTime = tmpDue;
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
        trailing: (null != startTime || null != dueTime)
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() {
                  checkClose = true;
                  startTime = null;
                  dueTime = null;
                }),
              )
            : null);
  }

  ListTile buildRepeatableTile(
      {required BuildContext context, bool smallScreen = false}) {
    return ListTile(
        leading: const Icon(Icons.event_repeat_outlined),
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
        onTap: () {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                Frequency cacheFreq = frequency;
                CustomFrequency cacheCustom = customFreq;
                Set<int> cacheWeekdays = Set.from(weekDayList);
                if (cacheWeekdays.isEmpty) {
                  int day = (null != startDate)
                      ? max(startDate!.weekday - 1, 0)
                      : max(DateTime.now().weekday - 1, 0);
                  cacheWeekdays.add(day);
                }

                int cacheSkip = repeatSkip;
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
                                                                      int day = (null !=
                                                                              startDate)
                                                                          ? max(
                                                                              startDate!.weekday -
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
                                                frequency = cacheFreq;
                                                customFreq = cacheCustom;
                                                weekDayList = cacheWeekdays;
                                                repeatSkip = cacheSkip;
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
        trailing: (frequency != Frequency.once)
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() {
                      checkClose = true;
                      frequency = Frequency.once;
                      customFreq = CustomFrequency.weekly;
                      weekDayList.clear();
                      repeatSkip = 1;
                    }))
            : null);
  }
}
