import 'package:allocate/ui/widgets/tiles.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../../model/task/subtask.dart';
import '../../providers/subtask_provider.dart';
import '../../util/constants.dart';
import '../../util/exceptions.dart';
import 'flushbars.dart';

class SubtaskQuickEntry extends StatefulWidget {
  const SubtaskQuickEntry(
      {super.key,
      required this.taskID,
      this.taskIndex,
      this.weight = 0.0,
      this.innerPadding = EdgeInsets.zero,
      this.outerPadding = EdgeInsets.zero,
      this.menuController,
      this.onOpen,
      this.onClose,
      this.hintText = "",
      this.onSubmit});

  final MenuController? menuController;
  final EdgeInsetsGeometry outerPadding;
  final EdgeInsetsGeometry innerPadding;
  final int taskID;
  final int? taskIndex;
  final String hintText;
  final double weight;

  final void Function()? onOpen;
  final void Function()? onClose;
  final void Function({Subtask? subtask})? onSubmit;

  @override
  State<SubtaskQuickEntry> createState() => _SubtaskQuickEntry();
}

class _SubtaskQuickEntry extends State<SubtaskQuickEntry> {
  late String name;
  late double weight;
  late TextEditingController nameEditingController;
  late MenuController menuController;

  late final SubtaskProvider subtaskProvider;

  @override
  void initState() {
    super.initState();
    name = "";
    weight = widget.weight;
    subtaskProvider = Provider.of<SubtaskProvider>(context, listen: false);
    nameEditingController = TextEditingController();
    nameEditingController.addListener(() {
      String newText = nameEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      name = newText;
      if ((nameEditingController.text.isEmpty ^ name.isEmpty) && mounted) {
        setState(() {});
      }
    });

    menuController = widget.menuController ?? MenuController();
  }

  @override
  void dispose() {
    nameEditingController.dispose();
    super.dispose();
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
                  onEditingComplete: () {
                    name = nameEditingController.text;
                    if (mounted) {
                      setState(() {});
                    }
                  }),
            ),
            Tiles.weightAnchor(
                controller: menuController,
                weight: weight,
                onOpen: widget.onOpen,
                onClose: widget.onClose,
                onChangeEnd: (value) {
                  menuController.close();
                },
                handleWeightChange: (value) {
                  if (null == value) {
                    return;
                  }
                  if (mounted) {
                    setState(() => weight = value);
                  }
                }),
            IconButton.filled(
                icon: const Icon(Icons.add_rounded),
                onPressed: (name.isNotEmpty)
                    ? (null != widget.onSubmit)
                        ? () {
                            Subtask newSubtask = Subtask(
                              name: name,
                              weight: weight.toInt(),
                              taskID: widget.taskID,
                              lastUpdated: DateTime.now(),
                            );

                            return widget.onSubmit!(subtask: newSubtask);
                          }
                        : () async {
                            // in case the usr doesn't submit to the textfields
                            name = nameEditingController.text;

                            await subtaskProvider
                                .createSubtask(
                                    name: name,
                                    weight: weight.toInt(),
                                    taskID: widget.taskID,
                                    index: widget.taskIndex)
                                .whenComplete(() {
                              if (mounted) {
                                setState(() {
                                  name = "";
                                  weight = 0;
                                  nameEditingController.value =
                                      nameEditingController.value
                                          .copyWith(text: name);
                                });
                              }
                            }).catchError((e) {
                              Flushbar? error;
                              error = Flushbars.createError(
                                  message: e.cause,
                                  context: context,
                                  dismissCallback: () => error?.dismiss());
                            },
                                    test: (e) =>
                                        e is FailureToCreateException ||
                                        e is FailureToUploadException);
                          }
                    : null),
          ]),
    );
  }
}
