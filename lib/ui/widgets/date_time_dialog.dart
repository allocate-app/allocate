import 'package:auto_size_text/auto_size_text.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import '../../util/constants.dart';

class DateTimeDialog extends StatefulWidget {
  const DateTimeDialog({super.key, this.header = "", this.date, this.time});

  final String header;
  final DateTime? date;
  final TimeOfDay? time;

  @override
  State<DateTimeDialog> createState() => _DateTimeDialog();
}

class _DateTimeDialog extends State<DateTimeDialog> {
  DateTime? date;
  TimeOfDay? time;

  late final UserProvider userProvider;

  @override
  void initState() {
    date = widget.date;
    time = widget.time;
    userProvider = Provider.of<UserProvider>(context, listen: false);
    super.initState();
  }

  @override
  Widget build(context) {
    MediaQuery.sizeOf(context);
    return Dialog(
        insetPadding: (userProvider.smallScreen)
            ? const EdgeInsets.all(Constants.mobileDialogPadding)
            : const EdgeInsets.all(Constants.outerDialogPadding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
              maxWidth: Constants.smallLandscapeDialogWidth),
          child: Padding(
              padding: const EdgeInsets.all(Constants.innerPadding),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: AutoSizeText(
                            widget.header,
                            style: Constants.largeHeaderStyle,
                            softWrap: true,
                            overflow: TextOverflow.visible,
                            maxLines: 2,
                            minFontSize: Constants.huge,
                          ),
                        ),
                      ],
                    ),
                    const Flexible(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Flexible(
                              child: AutoSizeText(
                            "Date | Time ",
                            style: Constants.hugeHeaderStyle,
                            softWrap: true,
                            overflow: TextOverflow.visible,
                            maxLines: 1,
                            minFontSize: Constants.huge,
                          )),
                          Flexible(
                            child: FittedBox(
                                fit: BoxFit.fill,
                                child: Icon(Icons.alarm_outlined,
                                    size: Constants.lgIconSize)),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: Constants.innerPadding),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                              onPressed: () {
                                                // Consider moving this to shifting focus to calendar
                                                // using focusNode.
                                                if (null == date) {
                                                  setState(() =>
                                                      date = DateTime.now());
                                                }
                                              },
                                              child: (null != date)
                                                  ? AutoSizeText(
                                                      Jiffy.parseFromDateTime(
                                                              date!)
                                                          .toLocal()
                                                          .format(
                                                              pattern:
                                                                  "MMMM dd, yyyy"),
                                                      softWrap: false,
                                                      overflowReplacement:
                                                          AutoSizeText(
                                                        Jiffy.parseFromDateTime(
                                                                date!)
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
                                                  : const AutoSizeText("Date",
                                                      softWrap: true,
                                                      overflow:
                                                          TextOverflow.visible,
                                                      maxLines: 1,
                                                      minFontSize:
                                                          Constants.huge)),
                                        ),
                                        (null != date)
                                            ? IconButton(
                                                icon: const Icon(
                                                    Icons.clear_rounded),
                                                onPressed: () => setState(() {
                                                  date = null;
                                                }),
                                              )
                                            : const SizedBox.shrink()
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
                                        strokeAlign:
                                            BorderSide.strokeAlignOutside),
                                  ),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Expanded(
                                          child: TextButton(
                                              onPressed: () async {
                                                final TimeOfDay? picked =
                                                    await showTimePicker(
                                                  context: context,
                                                  initialTime: time ??
                                                      Constants.midnight,
                                                );
                                                if (null != picked) {
                                                  setState(() => time = picked);
                                                }
                                              },
                                              child: (null != time)
                                                  ? AutoSizeText(
                                                      time!
                                                          .format(context)
                                                          .toString(),
                                                      softWrap: false,
                                                      overflow:
                                                          TextOverflow.visible,
                                                      maxLines: 1,
                                                      minFontSize:
                                                          Constants.huge,
                                                    )
                                                  : const AutoSizeText("Time",
                                                      softWrap: true,
                                                      overflow:
                                                          TextOverflow.visible,
                                                      maxLines: 1,
                                                      minFontSize:
                                                          Constants.huge)),
                                        ),
                                        (null != time)
                                            ? IconButton(
                                                icon: const Icon(
                                                    Icons.clear_rounded),
                                                onPressed: () => setState(() {
                                                  time = null;
                                                }),
                                              )
                                            : const SizedBox.shrink(),
                                      ]),
                                ),
                              ),
                            ),
                          ]),
                    ),

                    // Calendar view.
                    Flexible(
                      flex: (userProvider.smallScreen) ? 1 : 2,
                      child: CalendarDatePicker2(
                          config: CalendarDatePicker2Config(
                            centerAlignModePicker: true,
                            calendarType: CalendarDatePicker2Type.single,
                            firstDate: DateTime(1970),
                            lastDate: DateTime(3000),
                          ),
                          value: [date],
                          onValueChanged: (dates) {
                            setState(() {
                              date = dates.firstOrNull;
                            });
                          }),
                    ),

                    Row(
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
                                onPressed: () {
                                  Navigator.pop(context, {
                                    "date": date,
                                    "time": time,
                                  });
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
                  ])),
        ));
  }
}
