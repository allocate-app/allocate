import 'package:allocate/ui/widgets/tiles.dart';
import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../../providers/model/subtask_provider.dart';
import '../../providers/viewmodels/subtask_viewmodel.dart';
import '../../util/constants.dart';

class SubtaskQuickEntry extends StatefulWidget {
  const SubtaskQuickEntry({
    super.key,
    required this.taskID,
    this.taskIndex,
    this.weight = 0.0,
    this.innerPadding = EdgeInsets.zero,
    this.outerPadding = EdgeInsets.zero,
    this.menuController,
    this.onOpen,
    this.onClose,
    this.hintText = "",
  });

  final MenuController? menuController;
  final EdgeInsetsGeometry outerPadding;
  final EdgeInsetsGeometry innerPadding;
  final int taskID;
  final int? taskIndex;
  final String hintText;
  final double weight;

  final void Function()? onOpen;
  final void Function()? onClose;

  @override
  State<SubtaskQuickEntry> createState() => _SubtaskQuickEntry();
}

class _SubtaskQuickEntry extends State<SubtaskQuickEntry> {
  late TextEditingController nameEditingController;
  late MenuController menuController;

  late final SubtaskProvider subtaskProvider;
  late final SubtaskViewModel vm;

  @override
  void initState() {
    super.initState();
    vm = Provider.of<SubtaskViewModel>(context, listen: false);
    resetVM();
    // vm.weight = widget.weight.toInt();
    // vm.taskID = widget.taskID;
    // vm.customViewIndex = widget.taskIndex ?? vm.customViewIndex;
    subtaskProvider = Provider.of<SubtaskProvider>(context, listen: false);
    nameEditingController = TextEditingController();
    nameEditingController.addListener(watchName);

    menuController = widget.menuController ?? MenuController();
  }

  @override
  void dispose() {
    nameEditingController.removeListener(watchName);
    nameEditingController.dispose();
    super.dispose();
  }

  void watchName() {
    String newText = nameEditingController.text;
    SemanticsService.announce(newText, Directionality.of(context));
    vm.name = newText;
  }

  void resetVM() {
    vm.initWith(
        weight: widget.weight.toInt(),
        taskID: widget.taskID,
        customViewIndex: widget.taskIndex);
  }

  @override
  Widget build(context) {
    return Padding(
      padding: widget.outerPadding,
      child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Selector<SubtaskViewModel, String>(
              selector: (BuildContext context, SubtaskViewModel vm) => vm.name,
              builder: (BuildContext context, String value, Widget? child) {
                return Expanded(
                  child: AutoSizeTextField(
                      controller: nameEditingController,
                      minFontSize: Constants.large,
                      decoration: InputDecoration(
                          contentPadding: widget.innerPadding,
                          hintText: widget.hintText,
                          enabledBorder: OutlineInputBorder(
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(Constants.semiCircular)),
                              borderSide: BorderSide(
                                width: 2,
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                                strokeAlign: BorderSide.strokeAlignOutside,
                              )),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                                Radius.circular(Constants.semiCircular)),
                            borderSide: BorderSide(
                              strokeAlign: BorderSide.strokeAlignOutside,
                            ),
                          )),
                      onEditingComplete: () {
                        vm.name = nameEditingController.text;
                      }),
                );
              },
            ),
            Selector<SubtaskViewModel, int>(
                selector: (BuildContext context, SubtaskViewModel vm) =>
                    vm.weight,
                builder: (BuildContext context, int value, Widget? child) {
                  return Tiles.weightAnchor(
                      controller: menuController,
                      weight: vm.weight.toDouble(),
                      max: Constants.maxSubtaskWeightDouble,
                      divisions: Constants.maxSubtaskWeight,
                      onOpen: widget.onOpen,
                      onClose: widget.onClose,
                      onChangeEnd: (value) {
                        menuController.close();
                      },
                      handleWeightChange: (value) {
                        if (null == value) {
                          return;
                        }
                        vm.weight = value.toInt();
                      });
                }),
            Selector<SubtaskViewModel, String>(
                selector: (BuildContext context, SubtaskViewModel vm) =>
                    vm.name,
                builder: (BuildContext context, String value, Widget? child) {
                  return IconButton.filled(
                      icon: const Icon(Icons.add_rounded),
                      onPressed: (vm.name.isNotEmpty)
                          ? () async {
                              await subtaskProvider
                                  .createSubtask(vm.toModel())
                                  .catchError((e) {
                                Tiles.displayError(e: e);
                              }).whenComplete(() {
                                resetVM();
                                nameEditingController.clear();
                              });
                            }
                          : null);
                }),
          ]),
    );
  }
}
