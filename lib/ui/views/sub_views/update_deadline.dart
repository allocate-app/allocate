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
import '../../../services/application_service.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/exceptions.dart';
import '../../blurred_dialog.dart';
import '../../widgets/dialogs/check_delete_dialog.dart';
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
  late ValueNotifier<bool> _updateLoading;
  late ValueNotifier<bool> _deleteLoading;
  late ValueNotifier<String?> _nameErrorText;

  late final Deadline _prev;

  late final DeadlineViewModel vm;
  late final DeadlineProvider deadlineProvider;
  late final EventProvider eventProvider;
  late final LayoutProvider layoutProvider;

  late ApplicationService applicationService;

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
    applicationService.removeListener(scrollToTop);
    mobileScrollController.dispose();
    desktopScrollController.dispose();
    nameEditingController.dispose();
    descriptionEditingController.dispose();
    super.dispose();
  }

  void initializeParameters() {
    _checkClose = ValueNotifier(false);
    _updateLoading = ValueNotifier(false);
    _deleteLoading = ValueNotifier(false);
    _nameErrorText = ValueNotifier(null);
    _checkRepeating = false;
    _prev = vm.toModel();
  }

  void initializeProviders() {
    vm = Provider.of<DeadlineViewModel>(context, listen: false);
    deadlineProvider = Provider.of<DeadlineProvider>(context, listen: false);

    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);
    eventProvider = Provider.of<EventProvider>(context, listen: false);

    applicationService = ApplicationService.instance;
    applicationService.addListener(scrollToTop);
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

    descriptionEditingController = TextEditingController(text: vm.description);
    descriptionEditingController.addListener(watchDescription);
  }

  void scrollToTop() {
    if (mobileScrollController.hasClients) {
      mobileScrollController.animateTo(
        0,
        duration: Constants.scrollDuration,
        curve: Constants.scrollCurve,
      );
    }
    if (desktopScrollController.hasClients) {
      desktopScrollController.animateTo(
        0,
        duration: Constants.scrollDuration,
        curve: Constants.scrollCurve,
      );
    }
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
      scrollToTop();
    }

    try {
      // Newly set warning dates should validate.
      if (!_prev.warnMe &&
          vm.warnMe &&
          !deadlineProvider.validateWarnDate(
              warnDate:
                  vm.mergeDateTime(date: vm.warnDate, time: vm.warnTime))) {
        valid = false;
        Tiles.displayError(
            e: InvalidDateException("Due date must be later than now."));
      }
    } on Exception catch (e) {
      Tiles.displayError(e: e);
      valid = false;
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
          .then((_) async {
        await eventProvider.updateEventModel(
          oldModel: _prev,
          newModel: newDeadline,
          notify: true,
        );
      }).catchError((e) async {
        await Tiles.displayError(e: e);
      }).whenComplete(() {
        vm.clear();
        _popScreen();
        return;
      });
    }
    await deadlineProvider
        .updateDeadline(deadline: newDeadline)
        .then((_) async {
      await eventProvider.updateEventModel(
        oldModel: _prev,
        newModel: newDeadline,
        notify: true,
      );
    }).catchError((e) async {
      await Tiles.displayError(e: e);
    }).whenComplete(() {
      vm.clear();
      _popScreen();
    });
  }

  Future<void> checkAndHandleDelete() async {
    bool checkDelete = deadlineProvider.userViewModel?.checkDelete ?? true;
    // If not checking delete -> proceed
    if (!checkDelete) {
      return await handleDelete();
    }

    return await blurredDismissible(
            context: context,
            dialog: CheckDeleteDialog(dontAsk: !checkDelete, type: "Deadline"))
        .then((results) async {
      if (null == results) {
        return;
      }

      deadlineProvider.userViewModel?.checkDelete = results[1];

      if (!results[0]) {
        return;
      }

      await handleDelete();
    });
  }

  Future<void> handleDelete() async {
    _deleteLoading.value = true;
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
          .then((_) async {
        newDeadline.toDelete = true;
        await eventProvider.updateEventModel(
          oldModel: _prev,
          newModel: newDeadline,
          notify: true,
        );
      }).catchError((e) async {
        await Tiles.displayError(e: e);
      }).whenComplete(() {
        vm.clear();
        _popScreen();
        return;
      });
    }

    await deadlineProvider
        .deleteDeadline(deadline: newDeadline)
        .then((_) async {
      newDeadline.toDelete = true;
      await eventProvider.updateEventModel(
        oldModel: _prev,
        newModel: newDeadline,
        notify: true,
      );
    }).catchError((e) async {
      await Tiles.displayError(e: e);
    }).whenComplete(() {
      vm.clear();
      _popScreen();
    });

    _deleteLoading.value = false;
  }

  Future<void> updateAndValidate() async {
    _updateLoading.value = true;
    if (validateData()) {
      await handleUpdate();
    }
    _updateLoading.value = false;
  }

  void _popScreen() {
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void handleClose({required bool willDiscard}) {
    if (willDiscard) {
      deadlineProvider.rebuild = true;
      vm.clear();
      return _popScreen();
    }
    _checkClose.value = false;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
        MediaQuery.viewPaddingOf(context);
        if (layoutProvider.largeScreen) {
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
    double insets = View.of(context).viewInsets.bottom;
    Widget innerList = ListView(
      padding: const EdgeInsets.only(
        top: Constants.halfPadding,
        left: Constants.padding,
        right: Constants.padding,
      ),
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
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: [
                      // Title
                      _buildNameTile(),

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
                    padding: const EdgeInsets.symmetric(
                        vertical: Constants.padding,
                        horizontal: Constants.halfPadding),
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: [
                      _buildDescriptionTile(
                        minLines: Constants.desktopMinLines,
                        maxLines: Constants.desktopMaxLinesBeforeScroll,
                      ),
                    ]),
              )
            ]),
        if (layoutProvider.isMobile)
          TweenAnimationBuilder<double>(
              duration:
                  const Duration(milliseconds: Constants.keyboardSlideOut),
              curve: Curves.fastLinearToSlowEaseIn,
              tween: Tween<double>(
                begin: insets > Constants.keyboardInsetOpenThreshold
                    ? Constants.keyboardInset
                    : 0,
                end: insets > Constants.keyboardInsetOpenThreshold
                    ? Constants.keyboardInset
                    : 0,
              ),
              builder: (BuildContext context, double value, Widget? child) {
                return SizedBox(height: value);
              }),
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
                _buildUpdateDeleteRow(),
              ]),
        ),
      ),
    );
  }

  Dialog _buildMobileDialog({
    required BuildContext context,
    bool smallScreen = false,
  }) {
    double insets = View.of(context).viewInsets.bottom;
    Widget innerList = ListView(
      padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
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
        if (layoutProvider.isMobile)
          TweenAnimationBuilder<double>(
              duration:
                  const Duration(milliseconds: Constants.keyboardSlideOut),
              curve: Curves.fastLinearToSlowEaseIn,
              tween: Tween<double>(
                begin: insets > Constants.keyboardInsetOpenThreshold
                    ? Constants.keyboardInset
                    : 0,
                end: insets > Constants.keyboardInsetOpenThreshold
                    ? Constants.keyboardInset
                    : 0,
              ),
              builder: (BuildContext context, double value, Widget? child) {
                return SizedBox(height: value);
              }),
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
                        controller: mobileScrollController, child: innerList)
                    : innerList,
              ),

              const PaddedDivider(padding: Constants.padding),
              _buildUpdateDeleteRow(),
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

  Widget _buildUpdateDeleteRow() => ValueListenableBuilder(
        valueListenable: _updateLoading,
        builder: (BuildContext context, bool updateLoading, Widget? child) =>
            ValueListenableBuilder(
          valueListenable: _deleteLoading,
          builder: (BuildContext context, bool deleteLoading, Widget? child) =>
              Tiles.updateAndDeleteButtons(
            updateLoading: updateLoading,
            deleteLoading: deleteLoading,
            handleDelete: checkAndHandleDelete,
            handleUpdate: updateAndValidate,
            updateButtonPadding:
                const EdgeInsets.symmetric(horizontal: Constants.padding),
            deleteButtonPadding:
                const EdgeInsets.symmetric(horizontal: Constants.padding),
          ),
        ),
      );
}
