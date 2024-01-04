import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:provider/provider.dart';

import '../../model/task/deadline.dart';
import '../../model/task/todo.dart';
import '../../providers/group_provider.dart';
import '../../providers/todo_provider.dart';
import '../../util/constants.dart';
import '../../util/enums.dart';
import '../../util/exceptions.dart';
import '../../util/interfaces/i_repeatable.dart';

abstract class Subtitles {
  static Widget toDoSubtitle(
          {required BuildContext context,
          int? id,
          required void Function() onError,
          DateTime? dueDate,
          bool smallScreen = false,
          required Priority priority}) =>
      Wrap(
          spacing: (smallScreen) ? Constants.halfPadding : Constants.padding,
          runSpacing: (smallScreen) ? Constants.halfPadding : Constants.padding,
          children: [
            // Group Name - Fix Accordingly
            (null != id)
                ? groupNameIcon(
                    id: id,
                    context: context,
                    onError: onError,
                  )
                : const SizedBox.shrink(),

            // Due Date - Fix accordingly
            (null != dueDate)
                ? Wrap(spacing: Constants.halfPadding, children: [
                    Icon(Icons.event_rounded,
                        size: (smallScreen)
                            ? Constants.minIconSize
                            : Constants.smIconSize),
                    AutoSizeText(
                      Jiffy.parseFromDateTime(dueDate)
                          .toLocal()
                          .format(pattern: "MMM d y"),
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      maxLines: 2,
                      maxFontSize: Constants.large,
                      minFontSize: Constants.medium,
                    )
                  ])
                : const SizedBox.shrink(),

            // Priority Icon.
            (!smallScreen || null == id)
                ? switch (priority) {
                    Priority.low => const Tooltip(
                        message: "Low",
                        child: Icon(Icons.low_priority_rounded,
                            size: Constants.smIconSize)),
                    Priority.medium => const Tooltip(
                        message: "Medium",
                        child: Icon(Icons.outlined_flag_rounded,
                            size: Constants.smIconSize)),
                    Priority.high => const Tooltip(
                        message: "High",
                        child: Icon(Icons.priority_high_rounded,
                            size: Constants.smIconSize)),
                  }
                : const SizedBox.shrink(),
          ]);

  static Widget deadlineSubtitle(
          {required BuildContext context,
          DateTime? dueDate,
          bool smallScreen = false,
          DateTime? warnDate,
          required Priority priority}) =>
      Wrap(
          spacing: Constants.halfPadding,
          runSpacing: Constants.halfPadding,
          children: [
            // Due-Date
            (null != dueDate)
                ? Wrap(spacing: Constants.halfPadding, children: [
                    Icon(Icons.event_rounded,
                        size: (smallScreen)
                            ? Constants.minIconSize
                            : Constants.smIconSize),
                    AutoSizeText(
                      Jiffy.parseFromDateTime(dueDate)
                          .toLocal()
                          .format(pattern: "MMM d y"),
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      maxLines: 2,
                      maxFontSize: Constants.large,
                      minFontSize: Constants.medium,
                    )
                  ])
                : const SizedBox.shrink(),

            (null != warnDate)
                ? Wrap(spacing: Constants.halfPadding, children: [
                    const Icon(Icons.notifications_on_rounded,
                        size: Constants.minIconSize),
                    AutoSizeText(
                      Jiffy.parseFromDateTime(warnDate)
                          .toLocal()
                          .format(pattern: "MMM d y"),
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      maxLines: 2,
                      maxFontSize: Constants.large,
                      minFontSize: Constants.medium,
                    )
                  ])
                : const SizedBox.shrink(),
            // Priority Icon.
            (!smallScreen || null == warnDate)
                ? switch (priority) {
                    Priority.low => const Tooltip(
                        message: "Low",
                        child: Icon(Icons.low_priority_rounded,
                            size: Constants.smIconSize)),
                    Priority.medium => const Tooltip(
                        message: "Medium",
                        child: Icon(Icons.outlined_flag_rounded,
                            size: Constants.smIconSize)),
                    Priority.high => const Tooltip(
                        message: "High",
                        child: Icon(Icons.priority_high_rounded,
                            size: Constants.smIconSize)),
                  }
                : const SizedBox.shrink(),
          ]);

  static Widget reminderSubtitle({
    required BuildContext context,
    DateTime? dueDate,
    bool smallScreen = false,
  }) =>
      Wrap(
          spacing: Constants.halfPadding,
          runSpacing: Constants.halfPadding,
          children: [
            // Due-Date
            (null != dueDate)
                ? Wrap(spacing: Constants.halfPadding, children: [
                    Icon(Icons.event_rounded,
                        size: (smallScreen)
                            ? Constants.minIconSize
                            : Constants.smIconSize),
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
                  ])
                : const SizedBox.shrink(),

            // Due-Time
            (null != dueDate)
                ? Wrap(spacing: Constants.halfPadding, children: [
                    Icon(Icons.access_time_rounded,
                        size: (smallScreen)
                            ? Constants.minIconSize
                            : Constants.smIconSize),
                    AutoSizeText(
                      Jiffy.parseFromDateTime(dueDate)
                          .toLocal()
                          .format(pattern: "hh:mm a"),
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      maxLines: 2,
                      maxFontSize: Constants.large,
                      minFontSize: Constants.medium,
                    )
                  ])
                : const SizedBox.shrink(),
          ]);

  static Widget groupNameIcon(
      {required int id,
      required BuildContext context,
      required void Function() onError}) {
    GroupProvider groupProvider =
        Provider.of<GroupProvider>(context, listen: false);
    return (groupProvider.groupNames.containsKey(id))
        ? DecoratedBox(
            decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: const BorderRadius.all(
                    Radius.circular(Constants.semiCircular)),
                border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    strokeAlign: BorderSide.strokeAlignOutside)),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: Constants.halfPadding),
              child: AutoSizeText(
                groupProvider.groupNames[id]!,
                maxFontSize: Constants.large,
                minFontSize: Constants.medium,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
          )
        : FutureBuilder<String>(
            future: groupProvider.getGroupName(id: id).catchError((e) {
              onError();
              return "";
            }, test: (e) => e is GroupNotFoundException),
            builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                String? name = snapshot.data;
                if (null != name) {
                  return DecoratedBox(
                    decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        borderRadius: const BorderRadius.all(
                            Radius.circular(Constants.semiCircular)),
                        border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            strokeAlign: BorderSide.strokeAlignOutside)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Constants.halfPadding),
                      child: AutoSizeText(
                        name,
                        maxFontSize: Constants.large,
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
                  borderRadius:
                      BorderRadius.all(Radius.circular(Constants.semiCircular)),
                ),
              );
            });
  }

  static Widget subtaskSubtitle({required ValueNotifier<int> subtaskCount}) {
    return ValueListenableBuilder<int>(
        valueListenable: subtaskCount,
        builder: (BuildContext context, int value, Widget? child) {
          return Row(mainAxisSize: MainAxisSize.min, children: [
            AutoSizeText(
              "$value Step${(value == 1) ? "" : "s"}",
              maxFontSize: Constants.large,
              minFontSize: Constants.medium,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              maxLines: 1,
            ),
          ]);
        });
  }

  static Widget groupSubtitle({required ValueNotifier<int> toDoCount}) {
    return ValueListenableBuilder<int>(
      valueListenable: toDoCount,
      builder: (BuildContext context, int value, Widget? child) {
        return Row(mainAxisSize: MainAxisSize.min, children: [
          AutoSizeText(
            "$value Task${(value == 1) ? "" : "s"}",
            maxFontSize: Constants.large,
            minFontSize: Constants.medium,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            maxLines: 1,
          ),
        ]);
      },
    );
  }

  static Widget eventSubtitle(
      {required BuildContext context,
      required IRepeatable model,
      bool smallScreen = false}) {
    switch (model.modelType) {
      case ModelType.task:
        return toDoSubtitle(
            context: context,
            id: (model as ToDo).groupID,
            dueDate: model.dueDate,
            priority: model.priority,
            smallScreen: smallScreen,
            onError: () async {
              ToDoProvider toDoProvider =
                  Provider.of<ToDoProvider>(context, listen: false);
              (model).groupID = null;
              await toDoProvider.updateToDo(toDo: model);
            });
      case ModelType.deadline:
        return deadlineSubtitle(
          context: context,
          dueDate: model.dueDate,
          priority: (model as Deadline).priority,
          smallScreen: smallScreen,
          warnDate: (model.warnMe) ? model.warnDate : null,
        );
      case ModelType.reminder:
        return reminderSubtitle(
            context: context, dueDate: model.dueDate, smallScreen: smallScreen);
      default:
        return const SizedBox.shrink();
    }
  }
}
