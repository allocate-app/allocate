import 'package:auto_size_text/auto_size_text.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:provider/provider.dart';

import '../../providers/application/layout_provider.dart';
import '../../util/constants.dart';

class DateRangeDialog extends StatefulWidget {
  const DateRangeDialog({super.key, this.startDate, this.dueDate});

  final DateTime? startDate;
  final DateTime? dueDate;

  @override
  State<DateRangeDialog> createState() => _DateRangeDialog();
}

class _DateRangeDialog extends State<DateRangeDialog> {
  late DateTime? startDate;
  late DateTime? dueDate;
  late DateTime initDate;

  late int numDays;

  late bool setStart = false;
  late List<DateTime?> showDates;
  late LayoutProvider layoutProvider;

  @override
  void initState() {
    startDate = widget.startDate;
    dueDate = widget.dueDate;
    initDate = startDate ?? dueDate ?? DateTime.now();
    numDays = (dueDate?.difference(initDate).inDays ?? 0) + 1;
    showDates =
        List.generate(numDays, (i) => initDate.copyWith(day: initDate.day + i));
    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);
    super.initState();
  }

  @override
  Widget build(context) => LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) => Dialog(
          insetPadding: EdgeInsets.all((layoutProvider.smallScreen)
              ? Constants.mobileDialogPadding
              : Constants.outerDialogPadding),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
                maxWidth: Constants.smallLandscapeDialogWidth),
            child: Padding(
              padding: const EdgeInsets.all(Constants.doublePadding),
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
                              "Select Dates",
                              style: Constants.largeHeaderStyle,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              maxLines: 2,
                              minFontSize: Constants.huge,
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
                            "Start | Due ",
                            style: Constants.hugeHeaderStyle,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            maxLines: 1,
                            minFontSize: Constants.huge,
                          )),
                          Flexible(
                            child: FittedBox(
                                fit: BoxFit.fill,
                                child: Icon(Icons.date_range_rounded,
                                    size: Constants.lgIconSize)),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: Constants.doublePadding),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    right: Constants.padding),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        Constants.roundedCorners),
                                    border: Border.all(
                                        width: 2,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outlineVariant,
                                        strokeAlign:
                                            BorderSide.strokeAlignOutside),
                                  ),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Expanded(
                                          child: TextButton(
                                              onPressed: () => setState(() {
                                                    setStart = true;
                                                    startDate = startDate ??
                                                        DateTime.now();
                                                  }),
                                              child: (null != startDate)
                                                  ? AutoSizeText(
                                                      Jiffy.parseFromDateTime(
                                                              startDate!)
                                                          .toLocal()
                                                          .format(
                                                              pattern:
                                                                  "MMMM dd, yyyy"),
                                                      softWrap: false,
                                                      overflowReplacement:
                                                          AutoSizeText(
                                                        Jiffy.parseFromDateTime(
                                                                startDate!)
                                                            .toLocal()
                                                            .format(
                                                                pattern:
                                                                    "MMM d, yy"),
                                                        softWrap: false,
                                                        overflow: TextOverflow
                                                            .visible,
                                                        maxLines: 1,
                                                        minFontSize:
                                                            Constants.huge,
                                                      ),
                                                      maxLines: 1,
                                                      minFontSize:
                                                          Constants.huge,
                                                    )
                                                  : const AutoSizeText(
                                                      "Start Date",
                                                      softWrap: false,
                                                      overflow:
                                                          TextOverflow.visible,
                                                      maxLines: 1,
                                                      minFontSize:
                                                          Constants.huge)),
                                        ),
                                        if (startDate != null)
                                          IconButton(
                                            icon:
                                                const Icon(Icons.clear_rounded),
                                            onPressed: () => setState(() {
                                              showDates.remove(startDate);
                                              startDate = null;
                                            }),
                                          )
                                      ]),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: Constants.padding),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        Constants.roundedCorners),
                                    border: Border.all(
                                        width: 2,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outlineVariant,
                                        strokeAlign:
                                            BorderSide.strokeAlignOutside),
                                  ),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Expanded(
                                          child: TextButton(
                                              onPressed: () => setState(() {
                                                    setStart = false;
                                                    dueDate = dueDate ??
                                                        DateTime.now();
                                                  }),
                                              child: (null != dueDate)
                                                  ? AutoSizeText(
                                                      Jiffy.parseFromDateTime(
                                                              dueDate!)
                                                          .toLocal()
                                                          .format(
                                                              pattern:
                                                                  "MMMM dd, yyyy"),
                                                      softWrap: false,
                                                      overflowReplacement:
                                                          AutoSizeText(
                                                        Jiffy.parseFromDateTime(
                                                                dueDate!)
                                                            .toLocal()
                                                            .format(
                                                                pattern:
                                                                    "MMM d, yy"),
                                                        softWrap: false,
                                                        overflow: TextOverflow
                                                            .visible,
                                                        maxLines: 1,
                                                        minFontSize:
                                                            Constants.huge,
                                                      ),
                                                      maxLines: 1,
                                                      minFontSize:
                                                          Constants.huge,
                                                    )
                                                  : const AutoSizeText(
                                                      "Due Date",
                                                      softWrap: false,
                                                      overflow:
                                                          TextOverflow.visible,
                                                      maxLines: 1,
                                                      minFontSize:
                                                          Constants.huge)),
                                        ),
                                        if (dueDate != null)
                                          IconButton(
                                            icon:
                                                const Icon(Icons.clear_rounded),
                                            onPressed: () => setState(() {
                                              showDates.remove(dueDate);
                                              dueDate = null;
                                            }),
                                          )
                                      ]),
                                ),
                              ),
                            ),
                          ]),
                    ),

                    // Calendar view.
                    Flexible(
                      flex: (layoutProvider.smallScreen) ? 1 : 2,
                      child: CalendarDatePicker2(
                          config: CalendarDatePicker2Config(
                            centerAlignModePicker: true,
                            calendarType: CalendarDatePicker2Type.range,
                            firstDate: Constants.firstDay,
                            lastDate: Constants.lastDay,
                          ),
                          value: showDates,
                          onValueChanged: (dates) {
                            setState(() {
                              if (dates.length > 1) {
                                startDate = dates.first;
                                dueDate = dates.last;
                              } else {
                                (setStart)
                                    ? startDate = dates.first
                                    : dueDate = dates.first;
                              }
                              showDates = dates;
                            });
                          }),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(top: Constants.padding),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    right: Constants.padding),
                                child: FilledButton.tonalIcon(
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () {
                                      Navigator.pop(context);
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
                                  icon: const Icon(Icons.done_rounded),
                                  // This needs to change.
                                  onPressed: () {
                                    Navigator.pop(
                                        context, [startDate, dueDate]);
                                  },
                                  label: const AutoSizeText("Done",
                                      softWrap: false,
                                      overflow: TextOverflow.visible,
                                      maxLines: 1,
                                      minFontSize: Constants.large),
                                ),
                              ),
                            )
                          ]),
                    ),
                  ]),
            ),
          )));
}
