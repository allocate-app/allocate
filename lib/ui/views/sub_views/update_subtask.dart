import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../../../providers/application/layout_provider.dart';
import '../../../providers/model/subtask_provider.dart';
import '../../../providers/viewmodels/subtask_viewmodel.dart';
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
  late final SubtaskProvider subtaskProvider;
  late final SubtaskViewModel vm;
  late final LayoutProvider layoutProvider;
  late final TextEditingController nameEditingController;

  @override
  void initState() {
    subtaskProvider = Provider.of<SubtaskProvider>(context, listen: false);

    vm = Provider.of<SubtaskViewModel>(context, listen: false);

    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);

    nameEditingController = TextEditingController(text: vm.name);
    nameEditingController.addListener(watchName);
    _checkClose = ValueNotifier(false);
    _nameErrorText = ValueNotifier(null);
    super.initState();
  }

  @override
  void dispose() {
    nameEditingController.removeListener(watchName);
    nameEditingController.dispose();

    super.dispose();
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

  @override
  Widget build(context) {
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
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    _buildTitleBar(),
                    const PaddedDivider(padding: Constants.halfPadding),
                    _buildNameTile(),
                    _buildWeightTile(),
                    const PaddedDivider(padding: Constants.halfPadding),
                    Tiles.updateAndDeleteButtons(
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
                            Navigator.pop(context);
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
                              Navigator.pop(context);
                            });
                          }
                        }),
                  ])),
            )));
  }

  Widget _buildTitleBar() => ValueListenableBuilder<bool>(
        valueListenable: _checkClose,
        builder: (BuildContext context, bool check, Widget? child) => TitleBar(
          context: context,
          title: "Edit Task",
          handleClose: ({required bool willDiscard}) async {
            if (willDiscard) {
              subtaskProvider.rebuild = true;
              vm.clear();
              return Navigator.pop(context);
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
            max: Constants.maxTaskWeightDouble,
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
