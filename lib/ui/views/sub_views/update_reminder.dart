import 'dart:io';
import 'dart:math';

import 'package:another_flushbar/flushbar.dart';
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
import '../../widgets/flushbars.dart';
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
      _nameErrorText.value = "Enter Task Name";
      if (mainScrollController.hasClients) {
        mainScrollController.jumpTo(0);
      }
    }

    if (null == vm.mergeDateTime(date: vm.dueDate, time: vm.dueTime)) {
      valid = false;

      Flushbar? error;

      error = Flushbars.createError(
        message: "Due Date required.",
        context: context,
        dismissCallback: () => error?.dismiss(),
      );

      error.show(context);
    }

    // if (null == vm.dueDate) {
    //   vm.frequency = Frequency.once;
    // }

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
          .catchError((e) => Tiles.displayError(context: context, e: e),
              test: (e) =>
                  e is FailureToUpdateException ||
                  e is FailureToUploadException ||
                  e is InvalidRepeatingException ||
                  e is FailureToDeleteException);

      return await eventProvider
          .updateEventModel(
              oldModel: _prev, newModel: newReminder, notify: true)
          .whenComplete(() {
        vm.clear();
        Navigator.pop(context);
      });
    }

    await reminderProvider.updateReminder(reminder: newReminder).catchError(
        (e) => Tiles.displayError(context: context, e: e),
        test: (e) =>
            e is FailureToCreateException || e is FailureToUploadException);

    return await eventProvider
        .updateEventModel(oldModel: _prev, newModel: newReminder, notify: true)
        .whenComplete(() {
      vm.clear();
      Navigator.pop(context);
    });
  }

  Future<void> handleDelete() async {
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
          .catchError((e) => Tiles.displayError(context: context, e: e),
              test: (e) =>
                  e is FailureToUpdateException ||
                  e is FailureToUploadException ||
                  e is InvalidRepeatingException ||
                  e is FailureToDeleteException);

      newReminder.toDelete = true;
      return await eventProvider
          .updateEventModel(
              oldModel: _prev, newModel: newReminder, notify: true)
          .whenComplete(() {
        vm.clear();
        Navigator.pop(context);
      });
    }

    await reminderProvider.deleteReminder().catchError(
        (e) => Tiles.displayError(context: context, e: e),
        test: (e) =>
            e is FailureToCreateException || e is FailureToUploadException);

    newReminder.toDelete = true;
    return await eventProvider
        .updateEventModel(
      oldModel: _prev,
      newModel: newReminder,
      notify: true,
    )
        .whenComplete(() {
      vm.clear();
      Navigator.pop(context);
    });
  }

  void handleClose({required bool willDiscard}) {
    if (willDiscard) {
      reminderProvider.rebuild = true;
      vm.clear();
      return Navigator.pop(context);
    }

    _checkClose.value = false;
  }

  Future<void> updateAndValidate() async {
    if (validateData()) {
      await handleUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
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
                          child: Scrollbar(
                              thumbVisibility: true,
                              controller: mainScrollController,
                              child: ListView(
                                  shrinkWrap: true,
                                  controller: mainScrollController,
                                  physics: scrollPhysics,
                                  children: [
                                    _buildNameTile(),

                                    const PaddedDivider(
                                        padding: Constants.halfPadding),

                                    _buildDueDateTile(),

                                    // Repeatable Stuff -> Show status, on click, open a dialog.
                                    _buildRepeatableTile(),
                                  ]))),
                      const PaddedDivider(padding: Constants.halfPadding),
                      Tiles.updateAndDeleteButtons(
                        handleDelete: handleDelete,
                        handleUpdate: updateAndValidate,
                        updateButtonPadding: const EdgeInsets.symmetric(
                            horizontal: Constants.padding),
                        deleteButtonPadding: const EdgeInsets.symmetric(
                            horizontal: Constants.padding),
                      ),
                    ]),
              )));
    });
  }

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
}
