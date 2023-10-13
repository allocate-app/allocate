import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

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
    required void Function(bool? value) onChanged,
  }) =>
      Transform.scale(
          scale: scale,
          child: Checkbox(
            splashRadius: 15,
            value: completed,
            onChanged: onChanged,
            shape: const CircleBorder(),
          ));

  static Widget routineIcon({
    required BuildContext currentContext,
    double scale = 1,
    RoutineTime routineTime = RoutineTime.none,
    required void Function({required RoutineTime? newRoutineTime})
        handleRoutineTimeChange,
  }) {
    Icon? icon = switch (routineTime) {
      RoutineTime.morning => const Icon(Icons.wb_twilight_rounded),
      RoutineTime.afternoon => const Icon(Icons.lunch_dining_rounded),
      RoutineTime.evening => const Icon(Icons.bed_rounded),
      _ => const Icon(Icons.alarm_rounded),
    };

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
          await showDialog<RoutineTime>(
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
                              Flexible(
                                  child: AutoSizeText(
                                "Morning | Afternoon | Evening ",
                                style: Constants.largeHeaderStyle,
                                softWrap: true,
                                overflow: TextOverflow.visible,
                                maxLines: 1,
                                minFontSize: Constants.large,
                              )),
                              Flexible(
                                child: FittedBox(
                                    fit: BoxFit.fill,
                                    child: Icon(Icons.schedule_outlined,
                                        size: Constants.medIconSize)),
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
                                  child: (routineTime == RoutineTime.morning)
                                      ? IconButton.filledTonal(
                                          iconSize: Constants.lgIconSize,
                                          icon: const Icon(
                                              Icons.wb_twilight_rounded),
                                          onPressed: () => Navigator.pop(
                                              context, RoutineTime.morning))
                                      : IconButton.outlined(
                                          iconSize: Constants.lgIconSize,
                                          icon: const Icon(
                                              Icons.wb_twilight_rounded),
                                          onPressed: () => Navigator.pop(
                                              context, RoutineTime.morning)),
                                ),
                              )),
                              Flexible(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.all(Constants.padding),
                                  child: FittedBox(
                                    fit: BoxFit.fill,
                                    child: (routineTime ==
                                            RoutineTime.afternoon)
                                        ? IconButton.filledTonal(
                                            iconSize: Constants.lgIconSize,
                                            icon: const Icon(
                                                Icons.lunch_dining_rounded),
                                            onPressed: () => Navigator.pop(
                                                context, RoutineTime.afternoon))
                                        : IconButton.outlined(
                                            iconSize: Constants.lgIconSize,
                                            icon: const Icon(
                                                Icons.lunch_dining_rounded),
                                            onPressed: () => Navigator.pop(
                                                context,
                                                RoutineTime.afternoon)),
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.all(Constants.padding),
                                  child: FittedBox(
                                    fit: BoxFit.fill,
                                    child: (routineTime == RoutineTime.evening)
                                        ? IconButton.filledTonal(
                                            iconSize: Constants.lgIconSize,
                                            icon: const Icon(Icons.bed_rounded),
                                            onPressed: () => Navigator.pop(
                                                context, RoutineTime.evening))
                                        : IconButton.outlined(
                                            iconSize: Constants.lgIconSize,
                                            icon: const Icon(Icons.bed_rounded),
                                            onPressed: () => Navigator.pop(
                                                context, RoutineTime.evening)),
                                  ),
                                ),
                              )
                            ]),
                        Flexible(
                          child: Padding(
                              padding: const EdgeInsets.all(Constants.padding),
                              child: Tooltip(
                                message: "Remove.",
                                child: FittedBox(
                                  fit: BoxFit.fill,
                                  child: IconButton.outlined(
                                    iconSize: Constants.medIconSize,
                                    icon: const Icon(
                                        Icons.remove_circle_outline_rounded),
                                    onPressed: () => Navigator.pop(
                                        context, RoutineTime.none),
                                  ),
                                ),
                              )),
                        )
                      ]),
                ),
              ));
            },
          ).then((RoutineTime? time) =>
              handleRoutineTimeChange(newRoutineTime: time));
        },
        child: icon,
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
