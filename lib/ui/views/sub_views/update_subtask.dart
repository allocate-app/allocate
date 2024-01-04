import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../../../model/task/subtask.dart';
import '../../../providers/subtask_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../util/constants.dart';
import '../../../util/exceptions.dart';
import '../../widgets/flushbars.dart';
import '../../widgets/listtile_widgets.dart';
import '../../widgets/padded_divider.dart';
import '../../widgets/tiles.dart';
import '../../widgets/title_bar.dart';

class UpdateSubtaskScreen extends StatefulWidget {
  const UpdateSubtaskScreen({super.key, this.initialSubtask});

  final Subtask? initialSubtask;

  @override
  State<UpdateSubtaskScreen> createState() => _UpdateSubtaskScreen();
}

class _UpdateSubtaskScreen extends State<UpdateSubtaskScreen> {
  late bool checkClose;
  late final SubtaskProvider subtaskProvider;
  late final UserProvider userProvider;

  late final TextEditingController nameEditingController;

  String? nameErrorText;

  Subtask get subtask => subtaskProvider.curSubtask!;

  @override
  void initState() {
    subtaskProvider = Provider.of<SubtaskProvider>(context, listen: false);
    if (null != widget.initialSubtask) {
      subtaskProvider.curSubtask = widget.initialSubtask;
    }

    userProvider = Provider.of<UserProvider>(context, listen: false);

    nameEditingController = TextEditingController(text: subtask.name);
    nameEditingController.addListener(() {
      SemanticsService.announce(
          nameEditingController.text, Directionality.of(context));
      if (null != nameErrorText && mounted) {
        setState(() {
          nameErrorText = null;
        });
      }
    });
    checkClose = false;
    super.initState();
  }

  @override
  void dispose() {
    nameEditingController.dispose();

    super.dispose();
  }

  bool validateData() {
    if (nameEditingController.text.isEmpty) {
      if (mounted) {
        nameErrorText = "Enter Task Name";
      }
      return false;
    }
    return true;
  }

  @override
  Widget build(context) {
    MediaQuery.sizeOf(context);

    return Dialog(
        insetPadding: (userProvider.smallScreen)
            ? const EdgeInsets.all(Constants.mobileDialogPadding)
            : const EdgeInsets.all(Constants.outerDialogPadding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
              maxHeight: Constants.smallLandscapeDialogHeight,
              maxWidth: Constants.smallLandscapeDialogWidth),
          child: Padding(
              padding: const EdgeInsets.all(Constants.padding),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TitleBar(
                    currentContext: context,
                    title: "Edit Step",
                    checkClose: checkClose,
                    padding: const EdgeInsets.symmetric(
                        horizontal: Constants.padding),
                    handleClose: ({required bool willDiscard}) async {
                      if (willDiscard) {
                        subtaskProvider.rebuild = true;
                        return Navigator.pop(context);
                      }
                      if (mounted) {
                        setState(() => checkClose = false);
                      }
                    }),
                const PaddedDivider(padding: Constants.halfPadding),
                Tiles.nameTile(
                    context: context,
                    leading: ListTileWidgets.checkbox(
                      scale: Constants.largeCheckboxScale,
                      completed: subtask.completed,
                      onChanged: (value) {
                        if (mounted) {
                          setState(() {
                            checkClose =
                                userProvider.curUser?.checkClose ?? true;
                            subtask.completed = value!;
                          });
                        }
                      },
                    ),
                    hintText: "Step Name",
                    errorText: nameErrorText,
                    controller: nameEditingController,
                    outerPadding: const EdgeInsets.all(Constants.padding),
                    textFieldPadding:
                        const EdgeInsets.only(left: Constants.halfPadding),
                    handleClear: () {
                      if (mounted) {
                        setState(() {
                          checkClose = userProvider.curUser?.checkClose ?? true;
                          nameEditingController.clear();
                          subtask.name = "";
                        });
                      }
                    },
                    onEditingComplete: () {
                      if (mounted) {
                        setState(() {
                          checkClose = userProvider.curUser?.checkClose ?? true;
                          subtask.name = nameEditingController.text;
                        });
                      }
                    }),
                Tiles.weightTile(
                  outerPadding: const EdgeInsets.all(Constants.doublePadding),
                  batteryPadding:
                      const EdgeInsets.symmetric(horizontal: Constants.padding),
                  constraints: const BoxConstraints(maxWidth: 200),
                  weight: subtask.weight.toDouble(),
                  max: Constants.maxTaskWeight.toDouble(),
                  slider: Tiles.weightSlider(
                      weight: subtask.weight.toDouble(),
                      handleWeightChange: (value) {
                        if (null == value) {
                          return;
                        }
                        if (mounted) {
                          setState(() {
                            checkClose =
                                userProvider.curUser?.checkClose ?? true;
                            subtask.weight = value.toInt();
                          });
                        }
                      }),
                ),
                const PaddedDivider(padding: Constants.halfPadding),
                Tiles.updateAndDeleteButtons(handleDelete: () async {
                  await subtaskProvider
                      .deleteSubtask(subtask: subtask)
                      .whenComplete(() {
                    Navigator.pop(context);
                  }).catchError((e) {
                    Flushbar? error;
                    error = Flushbars.createError(
                      message: e.cause,
                      context: context,
                      dismissCallback: () => error?.dismiss(),
                    );
                    error.show(context);
                  }, test: (e) => e is FailureToDeleteException);
                }, handleUpdate: () async {
                  if (validateData()) {
                    // in case the usr doesn't submit to the textfields
                    subtask.name = nameEditingController.text;

                    await subtaskProvider
                        .updateSubtask(subtask: subtask)
                        .whenComplete(() {
                      Navigator.pop(context);
                    }).catchError((e) {
                      Flushbar? error;
                      error = Flushbars.createError(
                        message: e.cause,
                        context: context,
                        dismissCallback: () => error?.dismiss(),
                      );
                      error.show(context);
                    });
                  }
                }),
              ])),
        ));
  }
}
