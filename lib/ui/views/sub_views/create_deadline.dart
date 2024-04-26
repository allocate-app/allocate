import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../../../model/task/deadline.dart';
import '../../../providers/application/event_provider.dart';
import '../../../providers/application/layout_provider.dart';
import '../../../providers/model/deadline_provider.dart';
import '../../../providers/viewmodels/deadline_viewmodel.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/exceptions.dart';
import '../../widgets/listtile_widgets.dart';
import '../../widgets/padded_divider.dart';
import '../../widgets/tiles.dart';
import '../../widgets/title_bar.dart';

class CreateDeadlineScreen extends StatefulWidget {
  const CreateDeadlineScreen({super.key});

  @override
  State<CreateDeadlineScreen> createState() => _CreateDeadlineScreen();
}

class _CreateDeadlineScreen extends State<CreateDeadlineScreen> {
  late ValueNotifier<bool> _checkClose;
  late ValueNotifier<bool> _createLoading;
  late ValueNotifier<String?> _nameErrorText;

  late final DeadlineViewModel vm;
  late final DeadlineProvider deadlineProvider;
  late final EventProvider eventProvider;
  late final LayoutProvider layoutProvider;

  // Scrolling

  late final ScrollController mobileScrollController;
  late final ScrollController desktopScrollController;
  late final ScrollPhysics scrollPhysics;

  // Name
  late final TextEditingController nameEditingController;

  // Description
  late final TextEditingController descriptionEditingController;

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
    nameEditingController.removeListener(watchName);
    nameEditingController.dispose();
    descriptionEditingController.removeListener(watchDescription);
    descriptionEditingController.dispose();
    super.dispose();
  }

  void initializeParameters() {
    _checkClose = ValueNotifier(false);
    _createLoading = ValueNotifier(false);
    _nameErrorText = ValueNotifier(null);
  }

  void initializeProviders() {
    vm = Provider.of<DeadlineViewModel>(context, listen: false);
    vm.clear();
    deadlineProvider = Provider.of<DeadlineProvider>(context, listen: false);
    eventProvider = Provider.of<EventProvider>(context, listen: false);
    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);
  }

  void initializeControllers() {
    mobileScrollController = ScrollController();
    desktopScrollController = ScrollController();
    ScrollPhysics parentPhysics = (Platform.isIOS || Platform.isMacOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
    scrollPhysics = AlwaysScrollableScrollPhysics(parent: parentPhysics);

    nameEditingController = TextEditingController();
    nameEditingController.addListener(watchName);

    descriptionEditingController = TextEditingController();
    descriptionEditingController.addListener(watchDescription);
  }

  void watchName() {
    _checkClose.value = deadlineProvider.userViewModel?.checkClose ?? true;
    String newText = nameEditingController.text;
    SemanticsService.announce(newText, Directionality.of(context));
    vm.name = newText;
    if (null != _nameErrorText.value) {
      _nameErrorText.value = null;
    }
  }

  void watchDescription() {
    _checkClose.value = deadlineProvider.userViewModel?.checkClose ?? true;
    String newText = descriptionEditingController.text;
    SemanticsService.announce(newText, Directionality.of(context));
    vm.description = newText;
  }

  bool validateData() {
    bool valid = true;
    if (nameEditingController.text.isEmpty) {
      valid = false;
      _nameErrorText.value = "Enter Deadline Name";
      if (desktopScrollController.hasClients) {
        desktopScrollController.jumpTo(0);
      }
      if (mobileScrollController.hasClients) {
        mobileScrollController.jumpTo(0);
      }
    }

    try {
      if (vm.warnMe &&
          !deadlineProvider.validateWarnDate(
              warnDate:
                  vm.mergeDateTime(date: vm.warnDate, time: vm.warnTime))) {
        valid = false;

        Tiles.displayError(
            e: InvalidDateException("Warn date must be later than now."));
      }
    } on Exception catch (e) {
      valid = false;
      Tiles.displayError(e: e);
    }

    if (null == vm.startDate || null == vm.dueDate) {
      vm.frequency = Frequency.once;
    }

    if (vm.frequency == Frequency.custom) {
      if (vm.weekdayList.isEmpty) {
        vm.weekdayList.add(
            min(((vm.startDate?.weekday ?? Constants.today.weekday) - 1), 0));
      }
    }

    return valid;
  }

  // This should still run even if the online throws.
  // If local create fails, something is very wrong => pop context and escape
  Future<void> handleCreate() async {
    vm.repeatable = Frequency.once != vm.frequency;
    Deadline newDeadline = vm.toModel();

    await deadlineProvider.createDeadline(newDeadline).then((_) async {
      await eventProvider.insertEventModel(
          model: deadlineProvider.curDeadline!, notify: true);
    }).catchError((e) async {
      await Tiles.displayError(e: e);
    }).whenComplete(() {
      vm.clear();
      _popScreen();
    });
  }

  void _popScreen() {
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void handleClose({required bool willDiscard}) {
    if (willDiscard) {
      vm.clear();
      _popScreen();
    }

    _checkClose.value = false;
  }

  Future<void> createAndValidate() async {
    _createLoading.value = true;
    if (validateData()) {
      await handleCreate();
    }
    _createLoading.value = false;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
        if (layoutProvider.largeScreen) {
          return _buildDesktopDialog(context: context);
        }
        return _buildMobileDialog(
          context: context,
          smallScreen: layoutProvider.smallScreen,
        );
      });

  Dialog _buildDesktopDialog({required BuildContext context}) {
    Widget innerList = ListView(
      padding: const EdgeInsets.only(
        top: Constants.halfPadding,
        left: Constants.padding,
        right: Constants.padding,
      ),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: Constants.halfPadding),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // Title
                      _buildNameTile(),
                      // Priority
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: Constants.padding),
                        child: _buildPriorityTile(),
                      ),

                      const PaddedDivider(padding: Constants.padding),

                      _buildWarnMeTile(),
                      const PaddedDivider(padding: Constants.padding),

                      _buildDateRangeTile(),

                      _buildTimeTile(),

                      _buildRepeatableTile(),
                    ]),
              ),
              Flexible(
                child: ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                        vertical: Constants.padding,
                        horizontal: Constants.halfPadding),
                    children: [
                      _buildDescriptionTile(
                        minLines: Constants.desktopMinLines,
                        maxLines: Constants.desktopMaxLinesBeforeScroll,
                      ),
                    ]),
              )
            ]),
      ],
    );

    return Dialog(
      insetPadding: const EdgeInsets.all(Constants.outerDialogPadding),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
            maxHeight: Constants.maxDesktopDialogHeight,
            maxWidth: Constants.maxDesktopDialogWidth),
        child: Padding(
          padding: const EdgeInsets.all(Constants.padding),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title && Close Button
                _buildTitleBar(),
                const PaddedDivider(padding: Constants.halfPadding),
                Flexible(
                  child: Material(
                    color: Colors.transparent,
                    child: (layoutProvider.isMobile)
                        ? Scrollbar(
                            controller: desktopScrollController,
                            child: innerList,
                          )
                        : innerList,
                  ),
                ),

                const PaddedDivider(padding: Constants.halfPadding),
                _buildCreateButton(),
              ]),
        ),
      ),
    );
  }

  Dialog _buildMobileDialog({
    required BuildContext context,
    bool smallScreen = false,
  }) {
    Widget innerList = ListView(
      padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
      shrinkWrap: true,
      controller: mobileScrollController,
      physics: scrollPhysics,
      children: [
        // Title + status
        _buildNameTile(),

        Padding(
          padding: const EdgeInsets.only(bottom: Constants.padding),
          child: _buildPriorityTile(mobile: smallScreen),
        ),

        const PaddedDivider(padding: Constants.padding),

        _buildWarnMeTile(),

        const PaddedDivider(padding: Constants.padding),

        _buildDescriptionTile(),

        const PaddedDivider(padding: Constants.padding),

        _buildDateRangeTile(),

        _buildTimeTile(),

        _buildRepeatableTile(),
      ],
    );

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
              _buildTitleBar(),
              const PaddedDivider(padding: Constants.halfPadding),
              Flexible(
                child: (layoutProvider.isMobile)
                    ? Scrollbar(
                        controller: mobileScrollController,
                        child: innerList,
                      )
                    : innerList,
              ),

              const PaddedDivider(padding: Constants.halfPadding),
              _buildCreateButton(),
            ]),
      ),
    );
  }

  Widget _buildTitleBar() => ValueListenableBuilder<bool>(
        valueListenable: _checkClose,
        builder: (BuildContext context, bool check, Widget? child) => TitleBar(
          context: context,
          title: "New Deadline",
          handleClose: handleClose,
          checkClose: check,
          padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
        ),
      );

  Widget _buildNameTile() => ValueListenableBuilder<String?>(
      valueListenable: _nameErrorText,
      builder: (BuildContext context, String? errorText, Widget? child) =>
          Selector<DeadlineViewModel, String>(
            selector: (BuildContext context, DeadlineViewModel vm) => vm.name,
            builder: (BuildContext context, String value, Widget? child) =>
                Tiles.nameTile(
                    context: context,
                    leading: ListTileWidgets.deadlineIcon(
                      context: context,
                      iconPadding: const EdgeInsets.all(Constants.padding),
                      outerPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.halfPadding),
                    ),
                    errorText: errorText,
                    hintText: "Deadline Name",
                    controller: nameEditingController,
                    outerPadding:
                        const EdgeInsets.symmetric(vertical: Constants.padding),
                    textFieldPadding:
                        const EdgeInsets.only(left: Constants.padding),
                    onEditingComplete: () {
                      _checkClose.value =
                          deadlineProvider.userViewModel?.checkClose ?? true;
                      vm.name = nameEditingController.text;
                    },
                    handleClear: () {
                      _checkClose.value =
                          deadlineProvider.userViewModel?.checkClose ?? true;
                      nameEditingController.clear();
                      vm.name = "";
                    }),
          ));

  Widget _buildPriorityTile({bool mobile = false}) =>
      Selector<DeadlineViewModel, Priority>(
        selector: (BuildContext context, DeadlineViewModel vm) => vm.priority,
        builder: (BuildContext context, Priority value, Widget? child) =>
            Tiles.priorityTile(
                context: context,
                priority: value,
                mobile: mobile,
                onSelectionChanged: (Set<Priority> newPriority) {
                  _checkClose.value =
                      deadlineProvider.userViewModel?.checkClose ?? true;
                  vm.priority = newPriority.first;
                }),
      );

  Widget _buildWarnMeTile() =>
      Selector<DeadlineViewModel, (DateTime?, TimeOfDay?, bool)>(
        selector: (BuildContext context, DeadlineViewModel vm) =>
            (vm.warnDate, vm.warnTime, vm.warnMe),
        builder: (BuildContext context, (DateTime?, TimeOfDay?, bool) value,
                Widget? child) =>
            Tiles.singleDateTimeTile(
                context: context,
                date: value.$1,
                time: value.$2,
                useAlertIcon: true,
                showDate: value.$3,
                unsetDateText: "Warn me?",
                unsetTimeText: "Warn time",
                dialogHeader: "Warn Date",
                handleClear: () {
                  _checkClose.value =
                      deadlineProvider.userViewModel?.checkClose ?? true;
                  vm.clearWarnMe();
                },
                handleUpdate: (
                    {bool? checkClose, DateTime? newDate, TimeOfDay? newTime}) {
                  checkClose = checkClose ?? _checkClose.value;
                  _checkClose.value = (checkClose)
                      ? deadlineProvider.userViewModel?.checkClose ?? checkClose
                      : false;
                  vm.updateWarnMe(newDate: newDate, newTime: newTime);
                }),
      );

  Widget _buildDescriptionTile({
    int minLines = Constants.mobileMinLines,
    int maxLines = Constants.mobileMaxLinesBeforeScroll,
    bool mobile = false,
  }) =>
      Selector<DeadlineViewModel, String>(
        selector: (BuildContext context, DeadlineViewModel vm) =>
            vm.description,
        builder: (BuildContext context, String value, Widget? child) =>
            Tiles.descriptionTile(
                context: context,
                isDense: mobile,
                hintText: "Notes",
                minLines: minLines,
                maxLines: maxLines,
                controller: descriptionEditingController,
                onEditingComplete: () {
                  _checkClose.value =
                      deadlineProvider.userViewModel?.checkClose ?? true;
                  vm.description = descriptionEditingController.text;
                }),
      );

  Widget _buildDateRangeTile() =>
      Selector<DeadlineViewModel, (DateTime?, DateTime?)>(
        selector: (BuildContext context, DeadlineViewModel vm) =>
            (vm.startDate, vm.dueDate),
        builder: (BuildContext context, (DateTime?, DateTime?) value,
                Widget? child) =>
            Tiles.dateRangeTile(
                context: context,
                startDate: value.$1,
                dueDate: value.$2,
                handleClear: () {
                  _checkClose.value =
                      deadlineProvider.userViewModel?.checkClose ?? true;
                  vm.clearDates();
                },
                handleUpdate: (
                    {bool? checkClose, DateTime? newDue, DateTime? newStart}) {
                  checkClose = checkClose ?? _checkClose.value;
                  _checkClose.value = (checkClose)
                      ? deadlineProvider.userViewModel?.checkClose ?? checkClose
                      : false;
                  vm.updateDates(newStart: newStart, newDue: newDue);
                }),
      );

  Widget _buildTimeTile() =>
      Selector<DeadlineViewModel, (bool, TimeOfDay?, TimeOfDay?)>(
        selector: (BuildContext context, DeadlineViewModel vm) => (
          null != vm.startDate && null != vm.dueDate,
          vm.startTime,
          vm.dueTime
        ),
        builder: (BuildContext context, (bool, TimeOfDay?, TimeOfDay?) value,
                Widget? child) =>
            (value.$1)
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PaddedDivider(padding: Constants.padding),
                      Tiles.timeTile(
                          context: context,
                          startTime: value.$2,
                          dueTime: value.$3,
                          handleClear: () {
                            _checkClose.value =
                                deadlineProvider.userViewModel?.checkClose ??
                                    true;
                            vm.clearTimes();
                          },
                          handleUpdate: (
                              {bool? checkClose,
                              TimeOfDay? newStart,
                              TimeOfDay? newDue}) {
                            checkClose = checkClose ?? _checkClose.value;
                            _checkClose.value = (checkClose)
                                ? deadlineProvider.userViewModel?.checkClose ??
                                    checkClose
                                : false;
                            vm.updateTimes(newStart: newStart, newDue: newDue);
                          }),
                    ],
                  )
                : const SizedBox.shrink(),
      );

  Widget _buildRepeatableTile() =>
      Selector<DeadlineViewModel, (bool, UniqueKey)>(
        selector: (BuildContext context, DeadlineViewModel vm) =>
            (null != vm.startDate && null != vm.dueDate, vm.repeatableKey),
        builder: (BuildContext context, (bool, UniqueKey) value,
                Widget? child) =>
            (value.$1)
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PaddedDivider(padding: Constants.padding),
                      Tiles.repeatableTile(
                          context: context,
                          frequency: vm.frequency,
                          weekdays: vm.weekdayList,
                          repeatSkip: vm.repeatSkip,
                          startDate: vm.startDate,
                          handleUpdate: (
                              {bool? checkClose,
                              required Frequency newFreq,
                              required int newSkip,
                              required Set<int> newWeekdays}) {
                            checkClose = checkClose ?? _checkClose.value;
                            _checkClose.value = (checkClose)
                                ? deadlineProvider.userViewModel?.checkClose ??
                                    checkClose
                                : false;
                            vm.updateRepeatable(
                                newFreq: newFreq,
                                newSkip: newSkip,
                                newWeekdays: newWeekdays);
                          },
                          handleClear: () {
                            _checkClose.value =
                                deadlineProvider.userViewModel?.checkClose ??
                                    true;
                            vm.clearRepeatable();
                          }),
                    ],
                  )
                : const SizedBox.shrink(),
      );

  Widget _buildCreateButton() => ValueListenableBuilder(
        valueListenable: _createLoading,
        builder: (BuildContext context, bool createLoading, Widget? child) =>
            Tiles.createButton(
          loading: createLoading,
          outerPadding:
              const EdgeInsets.symmetric(horizontal: Constants.padding),
          handleCreate: createAndValidate,
        ),
      );
}
