import 'package:flutter/material.dart';

import '../../util/constants.dart';

class HandleRepeatableModal extends StatelessWidget {
  const HandleRepeatableModal({super.key, this.action = ""});

  final String action;

  @override
  Widget build(BuildContext context) {
    return Center(
        heightFactor: 1,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(Constants.padding),
                child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    label: Text("$action This Event"),
                    icon: const Icon(Icons.arrow_upward_rounded)),
              ),
              Padding(
                  padding: const EdgeInsets.all(Constants.padding),
                  child: FilledButton.tonalIcon(
                    onPressed: () => Navigator.pop(context, false),
                    label: Text("$action All"),
                    icon: const Icon(Icons.repeat_rounded),
                  )),
              const Padding(
                padding: EdgeInsets.only(bottom: Constants.padding),
                child: SizedBox.shrink(),
              ),
            ]));
  }
}
