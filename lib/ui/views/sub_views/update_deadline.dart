import 'dart:io';
import 'dart:math';

import 'package:another_flushbar/flushbar.dart';
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
import '../../widgets/flushbars.dart';
import '../../widgets/handle_repeatable_modal.dart';
import '../../widgets/listtile_widgets.dart';
import '../../widgets/padded_divider.dart';
import '../../widgets/tiles.dart';
import '../../widgets/title_bar.dart';

class UpdateDeadlineScreen extends StatefulWidget {
  const UpdateDeadlineScreen({
    super.key,
  });

  @override
  State<UpdateDeadlineScreen> createState() => _UpdateDeadlineScreen();
}

class _UpdateDeadlineScreen extends State<UpdateDeadlineScreen> {
  late bool _checkRepeating;
  late ValueNotifier<bool> _checkClose;
  late ValueNotifier<String?> _nameErrorText;

  late final Deadline _prev;

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
    nameEditingController.dispose();
    descriptionEditingController.dispose();
    super.dispose();
  }

  void initializeParameters() {
    _checkClose = ValueNotifier(false);
    _nameErrorText = ValueNotifier(null);
    _checkRepeating = false;
    _prev = vm.toModel();
  }

  void initializeProviders() {
    vm = Provider.of<DeadlineViewModel>(context, listen: false);
    deadlineProvider = Provider.of<DeadlineProvider>(context, listen: false);

    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);
    eventProvider = Provider.of<EventProvider>(context, listen: false);
  }

  void initializeControllers() {
    mobileScrollController = ScrollController();
    desktopScrollController = ScrollController();
    ScrollPhysics parentPhysics = (Platform.isIOS || Platform.isMacOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
    scrollPhysics = AlwaysScrollableScrollPhysics(parent: parentPhysics);

    nameEditingController = TextEditingController(text: vm.name);
    nameEditingController.addListener(watchName);

    descriptionEditingController = TextEditingController();
    descriptionEditingController.addListener(watchDescription);
  }

  void watchName() {
    _checkClose.value = deadlineProvider.userViewModel?.checkClose ?? true;
    _checkRepeating = true;
    String newText = nameEditingController.text;
    SemanticsService.announce(newText, Directionality.of(context));
    vm.name = newText;
    if (null != _nameErrorText.value) {
      _nameErrorText.value = null;
    }
  }

  void watchDescription() {
    _checkClose.value = deadlineProvider.userViewModel?.checkClose ?? true;
    _checkRepeating = true;
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

    // Newly set warning dates should validate.
    if (!_prev.warnMe &&
        vm.warnMe &&
        !deadlineProvider.validateWarnDate(
            warnDate: vm.mergeDateTime(date: vm.warnDate, time: vm.warnTime))) {
      valid = false;

      Flushbar? error;

      error = Flushbars.createError(
        message: "Warn date must be later than now.",
        context: context,
        dismissCallback: () => error?.dismiss(),
      );

      error.show(context);
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

    vm.repeatable = (Frequency.once != vm.frequency &&
        (_prev.repeatable ||
            !(vm.startDate?.isBefore(Constants.today) ?? false)));

    return valid;
  }

  // The error snackbar is causing an issue with popping the context..
  Future<void> handleUpdate() async {
    Deadline newDeadline = vm.toModel();
    if (_prev.frequency != Frequency.once &&
        _checkRepeating &&
        RepeatableState.delta != _prev.repeatableState) {
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
              deadline: _prev,
              delta: newDeadline,
              single: updateSingle,
              delete: false)
          .catchError((e) {
            Tiles.displayError(e: e);
            vm.clear();
            Navigator.pop(context);
            return;
          }, test: (e) => e is FailureToUpdateException)
          .catchError((e) => Tiles.displayError(e: e))
          .whenComplete(() async {
            return await eventProvider
                .updateEventModel(
              oldModel: _prev,
              newModel: newDeadline,
              notify: true,
            )
                .whenComplete(() {
              vm.clear();
              Navigator.pop(context);
            });
          });
    }
    await deadlineProvider
        .updateDeadline(deadline: newDeadline)
        .catchError((e) async {
      Tiles.displayError(e: e);
      // await Future.delayed(const Duration(seconds: 20));
    }).whenComplete(() async {
      return await eventProvider
          .updateEventModel(
        oldModel: _prev,
        newModel: newDeadline,
        notify: true,
      )
          .whenComplete(() {
        vm.clear();
        Navigator.pop(context);
      });
    });
  }

  Future<void> handleDelete() async {
    Deadline newDeadline = vm.toModel();
    if (_prev.frequency != Frequency.once &&
        RepeatableState.delta != _prev.repeatableState) {
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
              deadline: _prev,
              delta: newDeadline,
              single: deleteSingle,
              delete: true)
          .catchError((e) => Tiles.displayError(e: e));

      newDeadline.toDelete = true;
      return await eventProvider
          .updateEventModel(
        oldModel: _prev,
        newModel: newDeadline,
        notify: true,
      )
          .whenComplete(() {
        vm.clear();
        Navigator.pop(context);
      });
    }

    await deadlineProvider
        .deleteDeadline(deadline: newDeadline)
        .catchError((e) => Tiles.displayError(e: e));

    newDeadline.toDelete = true;
    return await eventProvider
        .updateEventModel(
      oldModel: _prev,
      newModel: newDeadline,
      notify: true,
    )
        .whenComplete(() {
      vm.clear();
      Navigator.pop(context);
    });
  }

  Future<void> updateAndValidate() async {
    if (validateData()) {
      await handleUpdate();
    }
  }

  void handleClose({required bool willDiscard}) {
    if (willDiscard) {
      deadlineProvider.rebuild = true;
      vm.clear();
      return Navigator.pop(context);
    }
    _checkClose.value = false;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth > Constants.largeScreen) {
          return _buildDesktopDialog(context: context);
        }
        return _buildMobileDialog(
          context: context,
          smallScreen: layoutProvider.smallScreen,
        );
      });

  Dialog _buildDesktopDialog({
    required BuildContext context,
  }) {
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
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: Constants.halfPadding),
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      children: [
                                        // Title
                                        _buildNameTile(),

                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: Constants.padding),
                                          child: _buildPriorityTile(),
                                        ),

                                        const PaddedDivider(
                                            padding: Constants.padding),
                                        _buildWarnMeTile(),

                                        const PaddedDivider(
                                            padding: Constants.padding),
                                        _buildDateRangeTile(),

                                        _buildTimeTile(),

                                        _buildRepeatableTile(),
                                      ]),
                                ),
                                Flexible(
                                  child: ListView(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: Constants.halfPadding),
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      children: [
                                        _buildDescriptionTile(
                                          minLines: Constants.desktopMinLines,
                                          maxLines: Constants
                                              .desktopMaxLinesBeforeScroll,
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

  Dialog _buildMobileDialog({
    required BuildContext context,
    bool smallScreen = false,
  }) {
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
                child: ListView(
                  shrinkWrap: true,
                  controller: mobileScrollController,
                  physics: scrollPhysics,
                  children: [
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
                    // Time
                    _buildTimeTile(),
                    // Repeatable Stuff -> Show status, on click, open a dialog.
                    _buildRepeatableTile(),
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

  Widget _buildTitleBar() => ValueListenableBuilder<bool>(
        valueListenable: _checkClose,
        builder: (BuildContext context, bool check, Widget? child) => TitleBar(
          context: context,
          title: "Edit Deadline",
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
                      _checkRepeating = true;
                      vm.name = nameEditingController.text;
                    },
                    handleClear: () {
                      _checkClose.value =
                          deadlineProvider.userViewModel?.checkClose ?? true;
                      _checkRepeating = true;
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
                  _checkRepeating = true;
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
                  _checkRepeating = true;
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
                  _checkRepeating = true;
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
                  _checkRepeating = true;
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
                            _checkRepeating = true;
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
                            _checkRepeating = true;
                            vm.updateTimes(newStart: newStart, newDue: newDue);
                          }),
                    ],
                  )
                : const SizedBox.shrink(),
      );

  Widget _buildRepeatableTile() =>
      Selector<DeadlineViewModel, (bool, UniqueKey)>(
        selector: (BuildContext context, DeadlineViewModel vm) => (
          null != vm.startDate &&
              null != vm.dueDate &&
              RepeatableState.delta != vm.repeatableState,
          vm.repeatableKey
        ),
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
                            _checkRepeating = true;
                            vm.updateRepeatable(
                                newFreq: newFreq,
                                newSkip: newSkip,
                                newWeekdays: newWeekdays);
                          },
                          handleClear: () {
                            _checkClose.value =
                                deadlineProvider.userViewModel?.checkClose ??
                                    true;
                            _checkRepeating = true;
                            vm.clearRepeatable();
                          }),
                    ],
                  )
                : const SizedBox.shrink(),
      );
}
