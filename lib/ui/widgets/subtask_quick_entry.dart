import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../../providers/model/subtask_provider.dart';
import '../../providers/viewmodels/subtask_viewmodel.dart';
import '../../util/constants.dart';
import 'tiles.dart';

class SubtaskQuickEntry extends StatefulWidget {
  const SubtaskQuickEntry({
    super.key,
    required this.taskID,
    this.viewModel,
    this.innerPadding = EdgeInsets.zero,
    this.outerPadding = EdgeInsets.zero,
    this.menuController,
    this.onOpen,
    this.onClose,
    this.hintText = "",
  });

  final SubtaskViewModel? viewModel;
  final MenuController? menuController;
  final EdgeInsetsGeometry outerPadding;
  final EdgeInsetsGeometry innerPadding;
  final int taskID;
  final String hintText;

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
    vm = widget.viewModel ??
        Provider.of<SubtaskViewModel>(context, listen: false);

    vm.taskID = widget.taskID;

    vm.addListener(repaint);

    subtaskProvider = Provider.of<SubtaskProvider>(context, listen: false);
    nameEditingController = TextEditingController(text: vm.name);
    nameEditingController.addListener(watchName);

    menuController = widget.menuController ?? MenuController();
  }

  @override
  void dispose() {
    vm.removeListener(repaint);
    nameEditingController.removeListener(watchName);
    nameEditingController.dispose();
    super.dispose();
  }

  void repaint() {
    setState(() {});
  }

  void watchName() {
    String newText = nameEditingController.text;
    SemanticsService.announce(newText, Directionality.of(context));
    vm.name = newText;
  }

  @override
  Widget build(context) {
    return Padding(
      padding: widget.outerPadding,
      child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
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
                            color: Theme.of(context).colorScheme.outlineVariant,
                            strokeAlign: BorderSide.strokeAlignOutside,
                          )),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                            Radius.circular(Constants.semiCircular)),
                        borderSide: BorderSide(
                          strokeAlign: BorderSide.strokeAlignOutside,
                        ),
                      )),
                  onTap: () {
                    Scrollable.ensureVisible(context,
                        duration: Constants.scrollDuration,
                        curve: Constants.scrollCurve);
                  },
                  onChanged: (_) {
                    Scrollable.ensureVisible(context,
                        duration: Constants.scrollDuration,
                        curve: Constants.scrollCurve);
                  },
                  onEditingComplete: () {
                    vm.name = nameEditingController.text;
                    FocusScope.of(context).unfocus();
                  }),
            ),

            Tiles.weightAnchor(
                subtask: true,
                controller: menuController,
                weight: vm.weight.toDouble(),
                max: Constants.maxSubtaskWeightDouble,
                divisions: Constants.maxSubtaskWeight,
                onOpen: () {
                  Scrollable.ensureVisible(context,
                      duration: Constants.scrollDuration,
                      curve: Constants.scrollCurve);
                  widget.onOpen?.call();
                },
                onClose: widget.onClose,
                onChangeEnd: (value) {
                  menuController.close();
                },
                handleWeightChange: (value) {
                  if (null == value) {
                    return;
                  }
                  vm.weight = value.toInt();
                }),

            IconButton.filled(
                icon: const Icon(Icons.add_rounded),
                onPressed: (nameEditingController.text.isNotEmpty)
                    ? () async {
                        await subtaskProvider
                            .createSubtask(vm.toModel())
                            .catchError((e) {
                          Tiles.displayError(e: e);
                        }).whenComplete(() {
                          vm.clear();
                          vm.taskID = widget.taskID;
                          nameEditingController.clear();
                        });
                      }
                    : null),
            // Widget needs to be decoupled from VM because of multi-instance use on my_day_routines.

            // Selector<SubtaskViewModel, String>(
            //   selector: (BuildContext context, SubtaskViewModel vm) => vm.name,
            //   builder: (BuildContext context, String value, Widget? child) {
            //     return Expanded(
            //       child: AutoSizeTextField(
            //           controller: nameEditingController,
            //           minFontSize: Constants.large,
            //           decoration: InputDecoration(
            //               contentPadding: widget.innerPadding,
            //               hintText: widget.hintText,
            //               enabledBorder: OutlineInputBorder(
            //                   borderRadius: const BorderRadius.all(
            //                       Radius.circular(Constants.semiCircular)),
            //                   borderSide: BorderSide(
            //                     width: 2,
            //                     color: Theme.of(context)
            //                         .colorScheme
            //                         .outlineVariant,
            //                     strokeAlign: BorderSide.strokeAlignOutside,
            //                   )),
            //               border: const OutlineInputBorder(
            //                 borderRadius: BorderRadius.all(
            //                     Radius.circular(Constants.semiCircular)),
            //                 borderSide: BorderSide(
            //                   strokeAlign: BorderSide.strokeAlignOutside,
            //                 ),
            //               )),
            //           onTap: () {
            //             Scrollable.ensureVisible(context,
            //                 duration: Constants.scrollDuration,
            //                 curve: Constants.scrollCurve);
            //           },
            //           onEditingComplete: () {
            //             vm.name = nameEditingController.text;
            //             FocusScope.of(context).unfocus();
            //           }),
            //     );
            //   },
            // ),
            // Selector<SubtaskViewModel, int>(
            //     selector: (BuildContext context, SubtaskViewModel vm) =>
            //         vm.weight,
            //     builder: (BuildContext context, int value, Widget? child) {
            //       return Tiles.weightAnchor(
            //           subtask: true,
            //           controller: menuController,
            //           weight: vm.weight.toDouble(),
            //           max: Constants.maxSubtaskWeightDouble,
            //           divisions: Constants.maxSubtaskWeight,
            //           onOpen: () {
            //             Scrollable.ensureVisible(context,
            //                 duration: Constants.scrollDuration,
            //                 curve: Constants.scrollCurve);
            //             widget.onOpen?.call();
            //           },
            //           onClose: widget.onClose,
            //           onChangeEnd: (value) {
            //             menuController.close();
            //           },
            //           handleWeightChange: (value) {
            //             if (null == value) {
            //               return;
            //             }
            //             vm.weight = value.toInt();
            //           });
            //     }),

            // Selector<SubtaskViewModel, String>(
            //     selector: (BuildContext context, SubtaskViewModel vm) =>
            //         vm.name,
            //     builder: (BuildContext context, String value, Widget? child) {
            //       return IconButton.filled(
            //           icon: const Icon(Icons.add_rounded),
            //           onPressed: (nameEditingController.text.isNotEmpty)
            //               ? () async {
            //                   await subtaskProvider
            //                       .createSubtask(vm.toModel())
            //                       .catchError((e) {
            //                     Tiles.displayError(e: e);
            //                   }).whenComplete(() {
            //                     vm.clear();
            //                     nameEditingController.clear();
            //                   });
            //                 }
            //               : null);
            //     }),
          ]),
    );
  }
}
