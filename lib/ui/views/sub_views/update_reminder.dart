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

class UpdateReminderScreen extends StatefulWidget {
  const UpdateReminderScreen({super.key});

  @override
  State<UpdateReminderScreen> createState() => _UpdateReminderScreen();
}

class _UpdateReminderScreen extends State<UpdateReminderScreen> {
  late ValueNotifier<bool> _checkClose;
  late ValueNotifier<bool> _updateLoading;
  late ValueNotifier<bool> _deleteLoading;
  late ValueNotifier<String?> _nameErrorText;
  late bool _checkRepeating;

  late final ReminderProvider reminderProvider;
  late final ReminderViewModel vm;
  late final EventProvider eventProvider;
  late final LayoutProvider layoutProvider;
  late final Reminder _prev;

  // Name
  late final TextEditingController nameEditingController;

  // Scrolling
  late final ScrollController mainScrollController;
  late final ScrollPhysics scrollPhysics;

  @override
  void initState() {
    initializeProviders();
    initializeParameters();
    initializeControllers();
    super.initState();
  }

  void initializeProviders() {
    reminderProvider = Provider.of<ReminderProvider>(context, listen: false);
    vm = Provider.of<ReminderViewModel>(context, listen: false);
    eventProvider = Provider.of<EventProvider>(context, listen: false);
    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);
  }

  void initializeParameters() {
    _prev = vm.toModel();
    _checkRepeating = false;
    _checkClose = ValueNotifier(false);
    _updateLoading = ValueNotifier(false);
    _deleteLoading = ValueNotifier(false);
    _nameErrorText = ValueNotifier(null);
  }

  void initializeControllers() {
    mainScrollController = ScrollController();
    ScrollPhysics parentPhysics = (Platform.isIOS || Platform.isMacOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
    scrollPhysics = AlwaysScrollableScrollPhysics(parent: parentPhysics);

    nameEditingController = TextEditingController(text: vm.name);
    nameEditingController.addListener(watchName);
  }

  @override
  void dispose() {
    nameEditingController.removeListener(watchName);
    mainScrollController.dispose();
    nameEditingController.dispose();
    super.dispose();
  }

  void watchName() {
    _checkClose.value = reminderProvider.userViewModel?.checkClose ?? true;
    _checkRepeating = true;
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
      if (mainScrollController.hasClients) {
        mainScrollController.jumpTo(0);
      }
    }

    if (null == vm.mergeDateTime(date: vm.dueDate, time: vm.dueTime)) {
      valid = false;

      Tiles.displayError(e: InvalidDateException("Due Date required"));
    }

    if (vm.frequency == Frequency.custom) {
      if (vm.weekdayList.isEmpty) {
        vm.weekdayList.add(
            min(((vm.dueDate?.weekday ?? Constants.today.weekday) - 1), 0));
      }
    }

    vm.repeatable = (Frequency.once != vm.frequency &&
        (_prev.repeatable ||
            !(vm.dueDate?.isBefore(Constants.today) ?? false)));

    return valid;
  }

  Future<void> handleUpdate() async {
    Reminder newReminder = vm.toModel();
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

      await reminderProvider
          .handleRepeating(
              reminder: _prev,
              delta: newReminder,
              single: updateSingle,
              delete: false)
          .then((_) async {
        await eventProvider.updateEventModel(
            oldModel: _prev, newModel: newReminder, notify: true);
      }).catchError((e) async {
        await Tiles.displayError(e: e);
      }).whenComplete(() {
        vm.clear();
        _popScreen();
      });
    }

    await reminderProvider
        .updateReminder(reminder: newReminder)
        .then((_) async {
      await eventProvider.updateEventModel(
          oldModel: _prev, newModel: newReminder, notify: true);
    }).catchError((e) async {
      await Tiles.displayError(e: e);
    }).whenComplete(() {
      vm.clear();
      _popScreen();
    });
  }

  Future<void> checkAndHandleDelete() async {
    bool checkDelete = reminderProvider.userViewModel?.checkDelete ?? true;
    // If not checking delete -> proceed
    if (!checkDelete) {
      return await handleDelete();
    }

    return await blurredDismissible(
            context: context,
            dialog: CheckDeleteDialog(dontAsk: !checkDelete, type: "Reminder"))
        .then((results) async {
      if (null == results) {
        return;
      }

      reminderProvider.userViewModel?.checkDelete = results[1];

      if (!results[0]) {
        return;
      }

      await handleDelete();
    });
  }

  Future<void> handleDelete() async {
    _deleteLoading.value = true;
    Reminder newReminder = vm.toModel();
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

      await reminderProvider
          .handleRepeating(
              reminder: _prev,
              delta: newReminder,
              single: deleteSingle,
              delete: true)
          .then((_) async {
        newReminder.toDelete = true;
        await eventProvider.updateEventModel(
            oldModel: _prev, newModel: newReminder, notify: true);
      }).catchError((e) async {
        await Tiles.displayError(e: e);
      }).whenComplete(() {
        vm.clear();
        _popScreen();
      });
    }

    await reminderProvider
        .deleteReminder(reminder: newReminder)
        .then((_) async {
      newReminder.toDelete = true;
      await eventProvider.updateEventModel(
        oldModel: _prev,
        newModel: newReminder,
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

  void _popScreen() {
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void handleClose({required bool willDiscard}) {
    if (willDiscard) {
      reminderProvider.rebuild = true;
      vm.clear();
      return _popScreen();
    }

    _checkClose.value = false;
  }

  Future<void> updateAndValidate() async {
    _updateLoading.value = true;
    if (validateData()) {
      await handleUpdate();
    }
    _updateLoading.value = false;
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
                        _buildUpdateDeleteRow(),
                      ]),
                )));
      });

  Widget _buildTitleBar() => ValueListenableBuilder<bool>(
        valueListenable: _checkClose,
        builder: (BuildContext context, bool check, Widget? child) => TitleBar(
          context: context,
          title: "Edit Reminder",
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
                      _checkRepeating = true;
                      _checkClose.value =
                          reminderProvider.userViewModel?.checkClose ?? true;
                      vm.name = nameEditingController.text;
                    },
                    handleClear: () {
                      _checkRepeating = true;
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
                  _checkRepeating = true;
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
        selector: (BuildContext context, ReminderViewModel vm) => (
          null != vm.dueDate && RepeatableState.delta != vm.repeatableState,
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
                          startDate: vm.dueDate,
                          handleUpdate: (
                              {bool? checkClose,
                              required Frequency newFreq,
                              required int newSkip,
                              required Set<int> newWeekdays}) {
                            checkClose = checkClose ?? _checkClose.value;
                            _checkRepeating = true;
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
                            _checkRepeating = true;
                            _checkClose.value =
                                reminderProvider.userViewModel?.checkClose ??
                                    true;
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
