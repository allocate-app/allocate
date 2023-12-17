import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../../../model/task/subtask.dart';
import '../../../providers/subtask_provider.dart';

class UpdateSubtaskScreen extends StatefulWidget {
  const UpdateSubtaskScreen({Key? key, this.initialSubtask}) : super(key: key);
  final Subtask? initialSubtask;

  @override
  State<UpdateSubtaskScreen> createState() => _UpdateSubtaskScreen();
}

class _UpdateSubtaskScreen extends State<UpdateSubtaskScreen> {
  late final SubtaskProvider subtaskProvider;
  late final TextEditingController nameController;

  Subtask get subtask => subtaskProvider.curSubtask!;

  @override
  void initState() {
    subtaskProvider = Provider.of<SubtaskProvider>(context, listen: false);
    if (null != widget.initialSubtask) {
      subtaskProvider.curSubtask = widget.initialSubtask;
    }

    nameController = TextEditingController();
    nameController.addListener(() {
      String newText = nameController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      if (mounted) {
        setState(() {
          subtask.name = newText;
          nameController.value = nameController.value.copyWith(text: newText);
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    nameController.dispose();

    super.dispose();
  }

  // Copy over basic formatting from model classes:
  // Title bar, (close button?)
  // Name + complete -> can use ToDo nametile.
  // Drain bar + slider.
  // update & delete buttons -> call subtaskProvider.
  // Name probably shouldn't be blank on exit.
  @override
  Widget build(context) {
    return const Dialog();
  }
}
