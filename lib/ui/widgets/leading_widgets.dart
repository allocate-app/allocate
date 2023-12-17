import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../../model/task/routine.dart';
import '../../util/constants.dart';
import '../../util/enums.dart';

class LeadingWidgets {
  static Widget outlinedIcon(
          {required BuildContext currentContext,
          EdgeInsetsGeometry iconPadding = EdgeInsets.zero,
          EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
          required Widget icon}) =>
      Padding(
          padding: outerPadding,
          child: DecoratedBox(
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Theme.of(currentContext).colorScheme.outline,
                    strokeAlign: BorderSide.strokeAlignOutside)),
            child: Padding(
              padding: iconPadding,
              child: icon,
            ),
          ));

  // This might eventually require different definitions if reminder/deadline
  // buttons are implemented with functionality.
  static Widget eventIcon(
          {required RepeatableType type,
          required BuildContext currentContext,
          EdgeInsetsGeometry iconPadding = EdgeInsets.zero,
          EdgeInsetsGeometry outerPadding = EdgeInsets.zero}) =>
      switch (type) {
        RepeatableType.task => outlinedIcon(
            currentContext: currentContext,
            iconPadding: iconPadding,
            outerPadding: outerPadding,
            icon: const Icon(Icons.task_rounded)),
        RepeatableType.deadline => deadlineIcon(
            currentContext: currentContext,
            iconPadding: iconPadding,
            outerPadding: outerPadding),
        RepeatableType.reminder => reminderIcon(
            currentContext: currentContext,
            iconPadding: iconPadding,
            outerPadding: outerPadding),
      };

  // This has no functionality at the moment. If a feature is added,
  // this will become a button.
  static Widget deadlineIcon({
    required BuildContext currentContext,
    EdgeInsetsGeometry iconPadding = EdgeInsets.zero,
    EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
  }) =>
      outlinedIcon(
          currentContext: currentContext,
          iconPadding: iconPadding,
          outerPadding: outerPadding,
          icon: const Icon(Icons.announcement_rounded));

  static Widget deadlineWarnMeIcon({
    required BuildContext currentContext,
    EdgeInsetsGeometry iconPadding = EdgeInsets.zero,
    EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
  }) =>
      outlinedIcon(
        currentContext: currentContext,
        outerPadding: outerPadding,
        iconPadding: iconPadding,
        icon: const Icon(Icons.notifications_on_rounded),
      );

  // This has no functionality at the moment. If a feature is added,
  // this will become a button.
  static Widget reminderIcon({
    required BuildContext currentContext,
    EdgeInsetsGeometry iconPadding = EdgeInsets.zero,
    EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
  }) =>
      outlinedIcon(
          currentContext: currentContext,
          iconPadding: iconPadding,
          outerPadding: outerPadding,
          icon: const Icon(Icons.push_pin_rounded));

  // This also has no functionality at the moment.
  // If a feature is added, this will be revised.
  static Widget reminderRepeatingIcon({
    required BuildContext currentContext,
    EdgeInsetsGeometry iconPadding = EdgeInsets.zero,
    EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
  }) =>
      outlinedIcon(
        currentContext: currentContext,
        iconPadding: iconPadding,
        outerPadding: outerPadding,
        icon: const Icon(Icons.restart_alt_rounded),
      );

  // This has no functionality at the moment. If a feature is added,
  // this will become a button.
  static Widget groupIcon({
    required BuildContext currentContext,
    EdgeInsetsGeometry iconPadding = EdgeInsets.zero,
    EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
  }) =>
      outlinedIcon(
          currentContext: currentContext,
          iconPadding: iconPadding,
          icon: const Icon(Icons.table_view_rounded));

  static Widget toDoCheckbox({
    double scale = 1,
    bool completed = false,
    EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
    required void Function(bool? value) onChanged,
  }) =>
      Padding(
        padding: outerPadding,
        child: Transform.scale(
            scale: scale,
            child: Checkbox(
              splashRadius: 15,
              value: completed,
              onChanged: onChanged,
              shape: const CircleBorder(),
            )),
      );

  static Widget groupListViewIcon({
    required Future<void> Function() onPressed,
  }) =>
      IconButton.filledTonal(
        icon: const Icon(Icons.edit_rounded),
        onPressed: onPressed,
      );

  static Widget myDayRoutineIcon(
      {Routine? routine, int times = 0, required void Function() onPressed}) {
    if (null == routine) {
      return IconButton.outlined(
        icon: routineGlyph(times: times),
        onPressed: onPressed,
      );
    }
    return IconButton.filledTonal(
        icon: routineGlyph(times: times), onPressed: onPressed);
  }

  // Uses an octal bitmask for times:
  // 1 = morning
  // 2 = aft
  // 4 = eve
  static Icon routineGlyph({int times = 0}) {
    return switch (times) {
      0 => const Icon(null),
      1 => const Icon(Icons.wb_twilight_rounded),
      2 => const Icon(Icons.lunch_dining_rounded),
      4 => const Icon(Icons.bed_rounded),
      _ => const Icon(Icons.queue_outlined),
    };
  }

  // TODO: still bugged, fix pls.
  static Widget routineIcon({
    required BuildContext currentContext,
    double scale = 1,
    int times = 0,
    required void Function({required int newRoutineTimes})
        handleRoutineTimeChange,
  }) {
    return Transform.scale(
      scale: scale,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(Constants.innerPadding),
          shape: const CircleBorder(),
          side: BorderSide(
            color: Theme.of(currentContext).colorScheme.outlineVariant,
          ),
        ),
        onPressed: () async {
          await showDialog<void>(
            context: currentContext,
            builder: (BuildContext context) {
              return Dialog(
                  child: ConstrainedBox(
                constraints: const BoxConstraints(
                    maxWidth: Constants.smallLandscapeDialogWidth),
                child: Padding(
                  padding: const EdgeInsets.all(Constants.innerPadding),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                child: AutoSizeText(
                                  "Set Routine Time",
                                  style: Constants.headerStyle,
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                  maxLines: 2,
                                  minFontSize: Constants.medium,
                                ),
                              )
                            ]),
                        const Flexible(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                  flex: 4,
                                  child: AutoSizeText(
                                    "Morning | Afternoon | Evening ",
                                    style: Constants.largeHeaderStyle,
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                    maxLines: 1,
                                    minFontSize: Constants.medium,
                                  )),
                              Flexible(
                                child: FittedBox(
                                    fit: BoxFit.fill,
                                    child: Icon(Icons.schedule_outlined,
                                        size: Constants.lgIconSize)),
                              ),
                            ],
                          ),
                        ),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Flexible(
                                  child: Padding(
                                padding:
                                    const EdgeInsets.all(Constants.padding),
                                child: FittedBox(
                                    fit: BoxFit.fill,
                                    child: (times & 1 == 1)
                                        ? IconButton.filledTonal(
                                            iconSize: Constants.hugeIconSize,
                                            icon: const Icon(
                                                Icons.wb_twilight_rounded),
                                            onPressed: () {
                                              times ^= 1;
                                              Navigator.pop(context);
                                            })
                                        : IconButton.outlined(
                                            iconSize: Constants.hugeIconSize,
                                            icon: const Icon(
                                                Icons.wb_twilight_rounded),
                                            onPressed: () {
                                              times ^= 1;
                                              Navigator.pop(context);
                                            })),
                              )),
                              Flexible(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.all(Constants.padding),
                                  child: FittedBox(
                                      fit: BoxFit.fill,
                                      child: (times & 2 == 2)
                                          ? IconButton.filledTonal(
                                              iconSize: Constants.hugeIconSize,
                                              icon: const Icon(
                                                  Icons.lunch_dining_rounded),
                                              onPressed: () {
                                                times ^= 2;
                                                Navigator.pop(context);
                                              })
                                          : IconButton.outlined(
                                              iconSize: Constants.hugeIconSize,
                                              icon: const Icon(
                                                  Icons.lunch_dining_rounded),
                                              onPressed: () {
                                                times ^= 2;
                                                Navigator.pop(context);
                                              })),
                                ),
                              ),
                              Flexible(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.all(Constants.padding),
                                  child: FittedBox(
                                      fit: BoxFit.fill,
                                      child: (times & 4 == 4)
                                          ? IconButton.filledTonal(
                                              iconSize: Constants.hugeIconSize,
                                              icon:
                                                  const Icon(Icons.bed_rounded),
                                              onPressed: () {
                                                times ^= 4;
                                                Navigator.pop(context);
                                              })
                                          : IconButton.outlined(
                                              iconSize: Constants.hugeIconSize,
                                              icon:
                                                  const Icon(Icons.bed_rounded),
                                              onPressed: () {
                                                times ^= 4;
                                                Navigator.pop(context);
                                              })),
                                ),
                              )
                            ]),
                        Flexible(
                            child: Padding(
                          padding: const EdgeInsets.all(Constants.padding),
                          child: Tooltip(
                            message: "Clear all",
                            child: FittedBox(
                                fit: BoxFit.fill,
                                child: IconButton.outlined(
                                    iconSize: Constants.medIconSize,
                                    icon: const Icon(
                                        Icons.remove_circle_outline_rounded),
                                    onPressed: () {
                                      times = 0;
                                      Navigator.pop(context);
                                    })),
                          ),
                        )),
                      ]),
                ),
              ));
            },
          ).then((_) => handleRoutineTimeChange(newRoutineTimes: times));
        },
        child: routineGlyph(times: times),
      ),
    );
  }

  static Widget alertIconButton({bool warn = false, void Function()? onTap}) =>
      (warn)
          ? IconButton.filledTonal(
              icon: const Icon(Icons.notifications_on_rounded),
              onPressed: onTap,
            )
          : IconButton.outlined(
              icon: const Icon(Icons.notifications_outlined), onPressed: onTap);
}
