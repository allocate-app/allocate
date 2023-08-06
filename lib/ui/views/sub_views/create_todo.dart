import "dart:io";

import "package:allocate/util/constants.dart";
import "package:allocate/util/interfaces/crossbuild.dart";
import "package:flutter/material.dart";

import "../../../model/task/subtask.dart";

class CreateToDoScreen extends StatefulWidget {
  const CreateToDoScreen({Key? key}) : super(key: key);

  @override
  State<CreateToDoScreen> createState() => _CreateToDoScreen();
}

class _CreateToDoScreen extends State<CreateToDoScreen> implements CrossBuild {
  static const double padding = 8.0;
  bool checkClose = false;

  // Param fields.
  final List<SubTask> subTasks = List.filled(Constants.maxNumTasks, SubTask());

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      return buildMobile(context: context);
    }
    return buildDesktop(context: context);
  }

  @override
  Widget buildDesktop({required BuildContext context}) {
    // TODO: implement buildDesktop
    throw UnimplementedError();
  }

  @override
  Widget buildMobile({required BuildContext context}) {
    return Dialog(
      child: Padding(
          padding: const EdgeInsets.all(padding),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close Button
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  IconButton(
                      onPressed: () {
                        bool discard = true;
                        if (checkClose) {
                          showModalBottomSheet<void>(
                              context: context,
                              builder: (BuildContext context) {
                                return Center(
                                    heightFactor: 1,
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.drag_handle_rounded),
                                          Padding(
                                            padding:
                                                const EdgeInsets.all(padding),
                                            child: FilledButton.icon(
                                              onPressed: () {
                                                discard = true;
                                                Navigator.pop(context);
                                              },
                                              label: const Text("Discard"),
                                              icon: const Icon(Icons
                                                  .delete_forever_outlined),
                                            ),
                                          ),
                                          Padding(
                                              padding:
                                                  const EdgeInsets.all(padding),
                                              child: FilledButton.tonalIcon(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                label: const Text(
                                                    "Continue Editing"),
                                                icon: const Icon(
                                                  Icons.edit_note_outlined,
                                                ),
                                              ))
                                        ]));
                              });
                        }
                        if (discard) {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.close_outlined),
                      selectedIcon: const Icon(Icons.close))
                ]),
                // ToDo Name On value changed, set the name param.
                // This ALL needs to be wrapped within a scrollable listview.
                const TextField(),

                //TaskType -> Segmented Button
                // On value Changed, checkClose = true,
                // Set the task type

                //Group selector -> Dropdown: list is immutable list view of groups.
                // On value Changed, set the group id to the group's id. && Checkclose.

                // Divider

                // TextField: Description.

                // Divider

                // Add Dates listview element -> On tapped: Calendar Dialog.

                // Divider

                // Recurring -> On tapped: Recurring dialog

                // Divider
                // Etc.
              ])),
    );
  }
}
