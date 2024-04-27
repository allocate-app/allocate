import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../../../providers/application/layout_provider.dart';
import '../../../providers/model/subtask_provider.dart';
import '../../../providers/viewmodels/subtask_viewmodel.dart';
import '../../../services/application_service.dart';
import '../../../util/constants.dart';
import '../../widgets/listtile_widgets.dart';
import '../../widgets/padded_divider.dart';
import '../../widgets/tiles.dart';
import '../../widgets/title_bar.dart';

class UpdateSubtaskScreen extends StatefulWidget {
  const UpdateSubtaskScreen({super.key});

  @override
  State<UpdateSubtaskScreen> createState() => _UpdateSubtaskScreen();
}

class _UpdateSubtaskScreen extends State<UpdateSubtaskScreen> {
  late ValueNotifier<bool> _checkClose;
  late ValueNotifier<String?> _nameErrorText;
  late ValueNotifier<bool> _updateLoading;
  late ValueNotifier<bool> _deleteLoading;
  late final SubtaskProvider subtaskProvider;
  late final SubtaskViewModel vm;
  late final LayoutProvider layoutProvider;

  late ApplicationService applicationService;

  late final TextEditingController nameEditingController;
  late final ScrollController mainScrollController;
  late final ScrollPhysics scrollPhysics;

  @override
  void initState() {
    subtaskProvider = Provider.of<SubtaskProvider>(context, listen: false);

    vm = Provider.of<SubtaskViewModel>(context, listen: false);

    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);

    applicationService = ApplicationService.instance;
    applicationService.addListener(scrollToTop);

    nameEditingController = TextEditingController(text: vm.name);
    nameEditingController.addListener(watchName);

    mainScrollController = ScrollController();
    ScrollPhysics parentPhysics = (Platform.isIOS || Platform.isMacOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
    scrollPhysics = AlwaysScrollableScrollPhysics(parent: parentPhysics);

    _checkClose = ValueNotifier(false);
    _updateLoading = ValueNotifier(false);
    _deleteLoading = ValueNotifier(false);
    _nameErrorText = ValueNotifier(null);
    super.initState();
  }

  @override
  void dispose() {
    applicationService.removeListener(scrollToTop);
    nameEditingController.removeListener(watchName);
    nameEditingController.dispose();
    mainScrollController.dispose();

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
    _checkClose.value = subtaskProvider.userViewModel?.checkClose ?? true;
    String newText = nameEditingController.text;
    SemanticsService.announce(newText, Directionality.of(context));
    vm.name = newText;
    if (null != _nameErrorText.value) {
      _nameErrorText.value = null;
    }
  }

  bool validateData() {
    if (nameEditingController.text.isEmpty) {
      _nameErrorText.value = "Enter Step Name";
      return false;
    }
    return true;
  }

  void _popScreen() {
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(context) {
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
        _buildWeightTile(),
        const PaddedDivider(padding: Constants.halfPadding),
        // TODO: consider factoring this out into a ValueListenableBuilder2.
        ValueListenableBuilder(
            valueListenable: _updateLoading,
            builder:
                (BuildContext context, bool updateLoading, Widget? child) =>
                    ValueListenableBuilder(
                        valueListenable: _deleteLoading,
                        builder: (BuildContext context, bool deleteLoading,
                                Widget? child) =>
                            Tiles.updateAndDeleteButtons(
                                updateLoading: updateLoading,
                                deleteLoading: deleteLoading,
                                updateButtonPadding: const EdgeInsets.symmetric(
                                    horizontal: Constants.padding),
                                deleteButtonPadding: const EdgeInsets.symmetric(
                                    horizontal: Constants.padding),
                                handleDelete: () async {
                                  await subtaskProvider
                                      .deleteSubtask(subtask: vm.toModel())
                                      .catchError((e) async {
                                    await Tiles.displayError(e: e);
                                  }).whenComplete(() {
                                    vm.clear();
                                    _popScreen();
                                  });
                                },
                                handleUpdate: () async {
                                  if (validateData()) {
                                    await subtaskProvider
                                        .updateSubtask(subtask: vm.toModel())
                                        .catchError((e) async {
                                      await Tiles.displayError(e: e);
                                    }).whenComplete(() {
                                      vm.clear();
                                      _popScreen();
                                    });
                                  }
                                }))),
      ],
    );

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) => Dialog(
            insetPadding: (layoutProvider.smallScreen)
                ? const EdgeInsets.all(Constants.mobileDialogPadding)
                : const EdgeInsets.all(Constants.outerDialogPadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                  maxHeight: Constants.smallLandscapeDialogHeight,
                  maxWidth: Constants.smallLandscapeDialogWidth),
              child: Padding(
                  padding: const EdgeInsets.all(Constants.padding),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTitleBar(),
                        const PaddedDivider(padding: Constants.halfPadding),
                        Flexible(
                          child: (layoutProvider.isMobile)
                              ? Scrollbar(
                                  controller: mainScrollController,
                                  child: innerList,
                                )
                              : innerList,
                        ),
                      ])),
            )));
  }

  Widget _buildTitleBar() => ValueListenableBuilder<bool>(
        valueListenable: _checkClose,
        builder: (BuildContext context, bool check, Widget? child) => TitleBar(
          context: context,
          title: "Edit Subtask",
          handleClose: ({required bool willDiscard}) async {
            if (willDiscard) {
              subtaskProvider.rebuild = true;
              vm.clear();
              _popScreen();
            }
            _checkClose.value = false;
          },
          checkClose: check,
          padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
        ),
      );

  Widget _buildNameTile() => ValueListenableBuilder<String?>(
      valueListenable: _nameErrorText,
      builder: (BuildContext context, String? errorText, Widget? child) =>
          Selector<SubtaskViewModel, (String, bool)>(
            selector: (BuildContext context, SubtaskViewModel vm) =>
                (vm.name, vm.completed),
            builder: (BuildContext context, (String, bool) value,
                    Widget? child) =>
                Tiles.nameTile(
                    context: context,
                    leading: ListTileWidgets.checkbox(
                      scale: Constants.largeCheckboxScale,
                      completed: value.$2,
                      onChanged: (bool? completed) {
                        _checkClose.value =
                            subtaskProvider.userViewModel?.checkClose ?? true;
                        vm.completed = completed!;
                      },
                    ),
                    errorText: errorText,
                    hintText: "Step Name",
                    controller: nameEditingController,
                    outerPadding:
                        const EdgeInsets.symmetric(vertical: Constants.padding),
                    textFieldPadding:
                        const EdgeInsets.only(left: Constants.padding),
                    onEditingComplete: () {
                      _checkClose.value =
                          subtaskProvider.userViewModel?.checkClose ?? true;
                      vm.name = nameEditingController.text;
                    },
                    handleClear: () {
                      _checkClose.value =
                          subtaskProvider.userViewModel?.checkClose ?? true;
                      nameEditingController.clear();
                      vm.name = "";
                    }),
          ));

  Widget _buildWeightTile() => Selector<SubtaskViewModel, int>(
      selector: (BuildContext context, SubtaskViewModel vm) => vm.weight,
      builder: (BuildContext context, int value, Widget? child) =>
          Tiles.weightTile(
            outerPadding: const EdgeInsets.all(Constants.doublePadding),
            batteryPadding: const EdgeInsets.all(Constants.padding),
            constraints: const BoxConstraints(
              maxWidth: 200,
            ),
            weight: value.toDouble(),
            max: Constants.maxSubtaskWeightDouble,
            slider: Tiles.weightSlider(
                max: Constants.maxSubtaskWeightDouble,
                divisions: Constants.maxSubtaskWeight,
                weight: value.toDouble(),
                handleWeightChange: (double? newWeight) {
                  if (null == newWeight) {
                    return;
                  }
                  _checkClose.value =
                      subtaskProvider.userViewModel?.checkClose ?? true;
                  vm.weight = newWeight.toInt();
                }),
          ));
}
