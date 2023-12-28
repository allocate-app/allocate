import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../../util/constants.dart';

class CheckDeleteDialog extends StatefulWidget {
  const CheckDeleteDialog({super.key, this.dontAsk = false, this.type = ""});

  final bool dontAsk;
  final String type;

  @override
  State<CheckDeleteDialog> createState() => _CheckDeleteDialog();
}

class _CheckDeleteDialog extends State<CheckDeleteDialog> {
  late bool dontAsk;
  late final String type;

  @override
  void initState() {
    dontAsk = widget.dontAsk;
    type = widget.type;
    super.initState();
  }

  @override
  Widget build(context) {
    return Dialog(
        insetPadding: const EdgeInsets.all(Constants.mobileDialogPadding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
              maxHeight: Constants.smallLandscapeDialogHeight,
              maxWidth: Constants.smallLandscapeDialogWidth),
          child: Padding(
            padding: const EdgeInsets.all(Constants.innerPadding),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AutoSizeText(
                            "Delete $type?",
                            style: Constants.hugeHeaderStyle,
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            minFontSize: Constants.huge,
                          ),
                        )
                      ]),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: AutoSizeText(
                          "This cannot be undone.",
                          style: Constants.largeHeaderStyle,
                          overflow: TextOverflow.visible,
                          maxLines: 1,
                          minFontSize: Constants.huge,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: Constants.innerPadding),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  right: Constants.padding),
                              child: FilledButton.tonalIcon(
                                  icon: const Icon(Icons.close_outlined),
                                  onPressed: () {
                                    Navigator.pop(context, [false, !dontAsk]);
                                  },
                                  label: const AutoSizeText("Cancel",
                                      softWrap: false,
                                      overflow: TextOverflow.visible,
                                      maxLines: 1,
                                      minFontSize: Constants.large)),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: Constants.padding),
                              child: FilledButton.icon(
                                icon: const Icon(Icons.delete_forever_rounded),
                                onPressed: () {
                                  Navigator.pop(context, [true, !dontAsk]);
                                },
                                label: const AutoSizeText("Delete",
                                    softWrap: false,
                                    overflow: TextOverflow.visible,
                                    maxLines: 1,
                                    minFontSize: Constants.large),
                              ),
                            ),
                          )
                        ]),
                  ),
                  CheckboxListTile(
                      value: dontAsk,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(
                              Radius.circular(Constants.semiCircular))),
                      checkboxShape: const CircleBorder(),
                      title: const AutoSizeText(
                        "Don't ask me again",
                        overflow: TextOverflow.visible,
                        softWrap: false,
                        maxLines: 1,
                        minFontSize: Constants.large,
                      ),
                      onChanged: (value) {
                        setState(() {
                          dontAsk = value!;
                        });
                      })
                ]),
          ),
        ));
  }
}
