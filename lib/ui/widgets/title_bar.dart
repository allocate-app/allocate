import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../../util/constants.dart';

class TitleBar extends StatefulWidget {
  const TitleBar(
      {super.key,
      required this.currentContext,
      this.title = "",
      this.centerWidget,
      this.checkClose = false,
      this.padding = EdgeInsets.zero,
      required this.handleClose});

  final BuildContext currentContext;
  final String title;
  final Widget? centerWidget;
  final bool checkClose;
  final EdgeInsetsGeometry padding;
  final void Function({required bool willDiscard}) handleClose;

  @override
  State<TitleBar> createState() => _TitleBar();

  static Widget durationCenterWidget(
          {required int expectedDuration, required int realDuration}) =>
      Flexible(
        flex: 2,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Tooltip(
                message: "Expected",
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: Constants.padding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Flexible(
                        child: FittedBox(
                          fit: BoxFit.fill,
                          child: Icon(
                            Icons.timer_outlined,
                          ),
                        ),
                      ),
                      Flexible(
                        child: AutoSizeText(
                            Duration(seconds: expectedDuration)
                                .toString()
                                .split(".")
                                .first,
                            minFontSize: Constants.medium,
                            overflow: TextOverflow.visible,
                            softWrap: false,
                            maxLines: 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Flexible(
              child: Tooltip(
                message: "Projected",
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: Constants.padding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Flexible(
                        child: FittedBox(
                          fit: BoxFit.fill,
                          child: Icon(
                            Icons.timer_rounded,
                          ),
                        ),
                      ),
                      Flexible(
                        child: AutoSizeText(
                            Duration(seconds: realDuration)
                                .toString()
                                .split(".")
                                .first,
                            minFontSize: Constants.medium,
                            overflow: TextOverflow.visible,
                            softWrap: false,
                            maxLines: 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _TitleBar extends State<TitleBar> {
  @override
  Widget build(context) {
    return Padding(
        padding: widget.padding,
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(
              child: AutoSizeText(
            widget.title,
            overflow: TextOverflow.visible,
            style: Constants.headerStyle,
            minFontSize: Constants.large,
            softWrap: true,
            maxLines: 2,
          )),
          widget.centerWidget ?? const SizedBox.shrink(),
          IconButton(
              onPressed: () async {
                await handleClose();
              },
              icon: const Icon(Icons.close_rounded),
              selectedIcon: const Icon(Icons.close_rounded))
        ]));
  }

  Future<void> handleClose() async {
    bool? willDiscard;
    if (widget.checkClose) {
      willDiscard = await showModalBottomSheet<bool?>(
          showDragHandle: true,
          context: context,
          builder: (BuildContext context) {
            return Center(
                heightFactor: 1,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(Constants.padding),
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context, true);
                          },
                          label: const Text("Discard"),
                          icon: const Icon(Icons.delete_forever_outlined),
                        ),
                      ),
                      Padding(
                          padding: const EdgeInsets.all(Constants.padding),
                          child: FilledButton.tonalIcon(
                            onPressed: () => Navigator.pop(context, false),
                            label: const Text("Continue Editing"),
                            icon: const Icon(
                              Icons.edit_note_rounded,
                            ),
                          ))
                    ]));
          });
    } else {
      willDiscard = true;
    }
    willDiscard = willDiscard ?? false;
    return widget.handleClose(willDiscard: willDiscard);
  }
}
