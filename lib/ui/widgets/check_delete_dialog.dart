import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/model/user_provider.dart';
import '../../util/constants.dart';
import '../../util/enums.dart';

class CheckDeleteDialog extends StatefulWidget {
  const CheckDeleteDialog(
      {super.key,
      this.dontAsk = false,
      this.type = "",
      this.headerOverride,
      this.deleteSchedule,
      this.showCheckbox = true});

  final bool dontAsk;
  final String type;
  final String? headerOverride;
  final bool showCheckbox;
  final DeleteSchedule? deleteSchedule;

  @override
  State<CheckDeleteDialog> createState() => _CheckDeleteDialog();
}

class _CheckDeleteDialog extends State<CheckDeleteDialog> {
  late bool dontAsk;
  late final String type;
  late final UserProvider userProvider;

  @override
  void initState() {
    dontAsk = widget.dontAsk;
    type = widget.type;
    userProvider = Provider.of<UserProvider>(context, listen: false);
    super.initState();
  }

  @override
  Widget build(context) {
    MediaQuery.sizeOf(context);
    return Dialog(
        insetPadding: EdgeInsets.all((userProvider.smallScreen)
            ? Constants.mobileDialogPadding
            : Constants.outerDialogPadding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
              maxHeight: Constants.smallLandscapeDialogHeight,
              maxWidth: Constants.smallLandscapeDialogWidth),
          child: Padding(
            padding: const EdgeInsets.all(Constants.doublePadding),
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
                            widget.headerOverride ?? "Delete $type?",
                            style: Constants.hugeHeaderStyle,
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            minFontSize: Constants.huge,
                          ),
                        )
                      ]),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: AutoSizeText(
                          (null != widget.deleteSchedule)
                              ? "Deleted items are recoverable for: ${Constants.deleteScheduleType(widget.deleteSchedule)}"
                              : "This cannot be undone.",
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
                        vertical: Constants.doublePadding),
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
                                    Navigator.pop(context, [false, false]);
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
                  if (widget.showCheckbox)
                    CheckboxListTile(
                        value: dontAsk,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                                Radius.circular(Constants.semiCircular))),
                        checkboxShape: const CircleBorder(),
                        title: const AutoSizeText(
                          "Delete without checking",
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
