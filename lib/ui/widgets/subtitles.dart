import 'package:another_flushbar/flushbar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:provider/provider.dart';

import '../../providers/group_provider.dart';
import '../../util/constants.dart';
import '../../util/enums.dart';
import '../../util/exceptions.dart';
import 'flushbars.dart';

class Subtitles {
  static Widget toDoSubTitle(
          {required BuildContext context,
          int? id,
          required void Function() onError,
          required DateTime dueDate,
          required Priority priority}) =>
      Wrap(
          spacing: Constants.halfPadding,
          runSpacing: Constants.halfPadding,
          children: [
            // Group Name - Fix Accordingly
            (null != id)
                ? FutureBuilder<String>(
                    future: Provider.of<GroupProvider>(context, listen: false)
                        .getGroupName(id: id)
                        .catchError((e) {
                      Flushbar? error;

                      error = Flushbars.createError(
                        message: e.cause ?? "Error with retrieval",
                        context: context,
                        dismissCallback: () => error?.dismiss(),
                      );

                      error.show(context);
                      onError();
                      return "Error";
                    }, test: (e) => e is GroupNotFoundException),
                    builder: (BuildContext context,
                        AsyncSnapshot<String?> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        String? name = snapshot.data;
                        if (null != name) {
                          return DecoratedBox(
                            decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(Constants.roundedCorners)),
                                border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                                    strokeAlign:
                                        BorderSide.strokeAlignOutside)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: Constants.padding),
                              child: AutoSizeText(
                                name,
                                minFontSize: Constants.medium,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                maxLines: 1,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
                      }
                      return ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 50),
                        child: const LinearProgressIndicator(
                          minHeight: Constants.minIconSize,
                          borderRadius: BorderRadius.all(
                              Radius.circular(Constants.roundedCorners)),
                        ),
                      );
                    })
                : const SizedBox.shrink(),

            // Due Date - Fix accordingly
            Wrap(spacing: Constants.halfPadding, children: [
              const Icon(Icons.event_rounded, size: Constants.minIconSize),
              AutoSizeText(
                Jiffy.parseFromDateTime(dueDate)
                    .toLocal()
                    .format(pattern: "MMM d"),
                softWrap: false,
                overflow: TextOverflow.visible,
                maxLines: 2,
                maxFontSize: Constants.large,
                minFontSize: Constants.medium,
              )
            ]),

            // Priority Icon.
            switch (priority) {
              Priority.low => const Tooltip(
                  message: "Low", child: Icon(Icons.low_priority_rounded)),
              Priority.medium => const Tooltip(
                  message: "Medium", child: Icon(Icons.outlined_flag_rounded)),
              Priority.high => const Tooltip(
                  message: "High", child: Icon(Icons.priority_high_rounded)),
            }
          ]);
}
