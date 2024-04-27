import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../../model/task/reminder.dart';
import '../../../providers/application/event_provider.dart';
import '../../../providers/application/layout_provider.dart';
import '../../../providers/model/reminder_provider.dart';
import '../../../providers/viewmodels/reminder_viewmodel.dart';
import '../../../services/application_service.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/exceptions.dart';
import '../../widgets/listtile_widgets.dart';
import '../../widgets/padded_divider.dart';
import '../../widgets/tiles.dart';
import '../../widgets/title_bar.dart';

class CreateReminderScreen extends StatefulWidget {
  const CreateReminderScreen({super.key});

  @override
  State<CreateReminderScreen> createState() => _CreateReminderScreen();
}

class _CreateReminderScreen extends State<CreateReminderScreen> {
  late ValueNotifier<bool> _checkClose;
  late ValueNotifier<bool> _createLoading;
  late ValueNotifier<String?> _nameErrorText;

  late final ReminderProvider reminderProvider;
  late final ReminderViewModel vm;
  late final EventProvider eventProvider;
  late final LayoutProvider layoutProvider;

  late ApplicationService applicationService;

  // Name
  late final TextEditingController nameEditingController;

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
    vm = Provider.of<ReminderViewModel>(context, listen: false);
    vm.clear();
    eventProvider = Provider.of<EventProvider>(context, listen: false);
    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);
    applicationService = ApplicationService.instance;
    applicationService.addListener(scrollToTop);
  }

  void initializeParameters() {
    _checkClose = ValueNotifier(false);
    _createLoading = ValueNotifier(false);
    _nameErrorText = ValueNotifier(null);
  }

  void initializeControllers() {
    mainScrollController = ScrollController();
    ScrollPhysics parentPhysics = (Platform.isIOS || Platform.isMacOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
    scrollPhysics = AlwaysScrollableScrollPhysics(parent: parentPhysics);
    nameEditingController = TextEditingController();
    nameEditingController.addListener(watchName);
  }

  @override
  void dispose() {
    applicationService.removeListener(scrollToTop);
    nameEditingController.removeListener(watchName);
    mainScrollController.dispose();
    nameEditingController.dispose();
    super.dispose();
  }

  void scrollToTop() {
    if (mainScrollController.hasClients) {
      mainScrollController.animateTo(
        0,
        duration: Constants.scrollDuration,
        curve: Constants.scrollCurve,
      );
    }
  }

  void watchName() {
    _checkClose.value = reminderProvider.userViewModel?.checkClose ?? true;
    String newText = nameEditingController.text;
    SemanticsService.announce(newText, Directionality.of(context));
    vm.name = newText;
    if (null != _nameErrorText.value) {
      _nameErrorText.value = null;
    }
  }

  bool validateData() {
    bool valid = true;
    if (nameEditingController.text.isEmpty) {
      valid = false;
      _nameErrorText.value = "Enter Reminder Name";
      scrollToTop();
    }

    try {
      if (!reminderProvider.validateDueDate(
          dueDate: vm.mergeDateTime(date: vm.dueDate, time: vm.dueTime))) {
        valid = false;

        Tiles.displayError(
            e: InvalidDateException("Due date must be later than now."));
      }
    } on Exception catch (e) {
      valid = false;
      Tiles.displayError(e: e);
    }

    if (vm.frequency == Frequency.custom) {
      if (vm.weekdayList.isEmpty) {
        vm.weekdayList.add(
            min(((vm.dueDate?.weekday ?? Constants.today.weekday) - 1), 0));
      }
    }

    return valid;
  }

  Future<void> handleCreate() async {
    vm.repeatable = Frequency.once != vm.frequency;
    Reminder newReminder = vm.toModel();
    await reminderProvider.createReminder(newReminder).then((_) async {
      await eventProvider.insertEventModel(model: newReminder, notify: true);
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
          Widget innerList = ListView(
              padding: const EdgeInsets.only(
                top: Constants.halfPadding,
                left: Constants.padding,
                right: Constants.padding,
              ),
              shrinkWrap: true,
              controller: mainScrollController,
              physics: scrollPhysics,
              children: [
                _buildNameTile(),

                const PaddedDivider(padding: Constants.halfPadding),

                _buildDueDateTile(),

                // Repeatable Stuff -> Show status, on click, open a dialog.
                _buildRepeatableTile(),
              ]);

          return Dialog(
              insetPadding: EdgeInsets.all((layoutProvider.smallScreen)
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
                          _buildTitleBar(),

                          const PaddedDivider(padding: Constants.halfPadding),

                          Flexible(
                              child: (layoutProvider.isMobile)
                                  ? Scrollbar(
                                      controller: mainScrollController,
                                      child: innerList,
                                    )
                                  : innerList),
                          const PaddedDivider(padding: Constants.halfPadding),
                          _buildCreateButton(),
                        ]),
                  )));
        },
      );

  Widget _buildTitleBar() => ValueListenableBuilder<bool>(
        valueListenable: _checkClose,
        builder: (BuildContext context, bool check, Widget? child) => TitleBar(
          context: context,
          title: "New Reminder",
          handleClose: handleClose,
          checkClose: check,
          padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
        ),
      );

  Widget _buildNameTile() => ValueListenableBuilder<String?>(
      valueListenable: _nameErrorText,
      builder: (BuildContext context, String? errorText, Widget? child) =>
          Selector<ReminderViewModel, String>(
            selector: (BuildContext context, ReminderViewModel vm) => vm.name,
            builder: (BuildContext context, String value, Widget? child) =>
                Tiles.nameTile(
                    context: context,
                    leading: ListTileWidgets.reminderIcon(
                      currentContext: context,
                      iconPadding: const EdgeInsets.all(Constants.padding),
                      outerPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.halfPadding),
                    ),
                    errorText: errorText,
                    hintText: "Reminder Name",
                    controller: nameEditingController,
                    outerPadding:
                        const EdgeInsets.symmetric(vertical: Constants.padding),
                    textFieldPadding:
                        const EdgeInsets.only(left: Constants.padding),
                    onEditingComplete: () {
                      _checkClose.value =
                          reminderProvider.userViewModel?.checkClose ?? true;
                      vm.name = nameEditingController.text;
                    },
                    handleClear: () {
                      _checkClose.value =
                          reminderProvider.userViewModel?.checkClose ?? true;
                      nameEditingController.clear();
                      vm.name = "";
                    }),
          ));

  Widget _buildDueDateTile() =>
      Selector<ReminderViewModel, (DateTime?, TimeOfDay?)>(
        selector: (BuildContext context, ReminderViewModel vm) =>
            (vm.dueDate, vm.dueTime),
        builder: (BuildContext context, (DateTime?, TimeOfDay?) value,
                Widget? child) =>
            Tiles.singleDateTimeTile(
                context: context,
                date: value.$1,
                time: value.$2,
                useAlertIcon: false,
                showDate: true,
                unsetDateText: "Due Date",
                unsetTimeText: "Due time",
                dialogHeader: "Select Due Date",
                handleClear: () {
                  _checkClose.value =
                      reminderProvider.userViewModel?.checkClose ?? true;
                  vm.clearDateTime();
                },
                handleUpdate: (
                    {bool? checkClose, DateTime? newDate, TimeOfDay? newTime}) {
                  checkClose = checkClose ?? _checkClose.value;
                  _checkClose.value = (checkClose)
                      ? reminderProvider.userViewModel?.checkClose ?? checkClose
                      : false;
                  vm.updateDateTime(newDate: newDate, newTime: newTime);
                }),
      );

  Widget _buildRepeatableTile() =>
      Selector<ReminderViewModel, (bool, UniqueKey)>(
        selector: (BuildContext context, ReminderViewModel vm) =>
            (null != vm.dueDate, vm.repeatableKey),
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
                          startDate: vm.dueDate,
                          handleUpdate: (
                              {bool? checkClose,
                              required Frequency newFreq,
                              required int newSkip,
                              required Set<int> newWeekdays}) {
                            checkClose = checkClose ?? _checkClose.value;
                            _checkClose.value = (checkClose)
                                ? reminderProvider.userViewModel?.checkClose ??
                                    checkClose
                                : false;
                            vm.updateRepeatable(
                                newFreq: newFreq,
                                newSkip: newSkip,
                                newWeekdays: newWeekdays);
                          },
                          handleClear: () {
                            _checkClose.value =
                                reminderProvider.userViewModel?.checkClose ??
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
