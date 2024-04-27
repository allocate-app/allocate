import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../providers/application/event_provider.dart';
import '../../../providers/application/layout_provider.dart';
import '../../../services/application_service.dart';
import '../../../util/constants.dart';
import '../../widgets/listviews.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreen();
}

class _CalendarScreen extends State<CalendarScreen> {
  late ScrollController mainScrollController;
  late ScrollPhysics scrollPhysics;

  late final FocusNode _refreshFocusNode;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  late EventProvider eventProvider;

  late LayoutProvider layoutProvider;

  late ApplicationService applicationService;

  late bool _showRepeatingLimit;
  late bool _showEventLimit;

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeControllers();
    _showEventLimit = true;
    _showRepeatingLimit = true;
    _refreshFocusNode = FocusNode();
  }

  @override
  void dispose() {
    applicationService.removeListener(scrollToTop);
    mainScrollController.dispose();
    super.dispose();
  }

  void initializeProviders() {
    eventProvider = Provider.of<EventProvider>(context, listen: false);
    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);
    applicationService = ApplicationService.instance;
    applicationService.addListener(scrollToTop);
  }

  void initializeControllers() {
    mainScrollController = ScrollController();
    scrollPhysics = (Platform.isIOS || Platform.isMacOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
  }

  void scrollToTop() {
    if (mainScrollController.hasClients) {
      mainScrollController.animateTo(
        0,
        duration: Constants.scrollDuration,
        curve: Constants.scrollCurve,
      );
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: MouseRegion(
                onEnter: (PointerEvent details) {
                  _refreshFocusNode.requestFocus();
                },
                onExit: (PointerEvent details) {
                  _refreshFocusNode.unfocus();
                },
                child: CallbackShortcuts(
                  bindings: <ShortcutActivator, VoidCallback>{
                    const SingleActivator(LogicalKeyboardKey.keyR,
                        control: true, includeRepeats: false): () {
                      _refreshIndicatorKey.currentState?.show();
                    }
                  },
                  child: Focus(
                    autofocus: true,
                    focusNode: _refreshFocusNode,
                    descendantsAreFocusable: true,
                    child: RefreshIndicator(
                      key: _refreshIndicatorKey,
                      onRefresh: () async {
                        await eventProvider.resetCalendar();
                      },
                      child: Consumer<EventProvider>(builder:
                          (BuildContext context, EventProvider value,
                              Widget? child) {
                        return ListView(
                            shrinkWrap: true,
                            physics: AlwaysScrollableScrollPhysics(
                                parent: scrollPhysics),
                            controller: mainScrollController,
                            children: [
                              if (!eventProvider.belowEventCap &&
                                  _showEventLimit)
                                ListTile(
                                  leading:
                                      const Icon(Icons.error_outline_rounded),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: Constants.padding),
                                  title: const AutoSizeText(
                                    "Size limit for calendar events exceeded.",
                                    maxLines: 2,
                                    overflow: TextOverflow.visible,
                                    maxFontSize: Constants.large,
                                    minFontSize: Constants.medium,
                                    softWrap: false,
                                  ),
                                  trailing: IconButton(
                                      icon: const Icon(Icons.clear_rounded),
                                      onPressed: () {
                                        _showEventLimit = false;
                                        if (mounted) {
                                          setState(() {});
                                        }
                                      }),
                                ),
                              if (!eventProvider.belowRepeatCap &&
                                  _showRepeatingLimit)
                                ListTile(
                                    leading:
                                        const Icon(Icons.error_outline_rounded),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: Constants.padding),
                                    title: const AutoSizeText(
                                      "Size limit for repeating events exceeded.",
                                      maxLines: 2,
                                      overflow: TextOverflow.visible,
                                      maxFontSize: Constants.large,
                                      minFontSize: Constants.medium,
                                      softWrap: false,
                                    ),
                                    trailing: IconButton(
                                        icon: const Icon(Icons.clear_rounded),
                                        onPressed: () {
                                          _showRepeatingLimit = false;
                                          if (mounted) {
                                            setState(() {});
                                          }
                                        })),
                              TableCalendar(
                                  // January 1st, 5 years ago
                                  firstDay: DateTime(
                                      Constants.today.year -
                                          Constants.yearOffset,
                                      1,
                                      1),
                                  // January 31st, 5 years from now.
                                  lastDay: DateTime(
                                      Constants.today.year +
                                          Constants.yearOffset,
                                      2,
                                      0),
                                  focusedDay: value.focusedDay,
                                  headerStyle: Constants.calendarHeaderStyle,
                                  calendarStyle:
                                      Constants.calendarStyle(context),
                                  calendarFormat: CalendarFormat.month,
                                  pageJumpingEnabled: true,
                                  eventLoader: value.getEventsForDay,
                                  selectedDayPredicate: (day) {
                                    return isSameDay(value.selectedDay, day);
                                  },
                                  onDaySelected: value.handleDaySelected,
                                  onPageChanged: (focusedDay) {
                                    value.focusedDay = focusedDay;
                                  }),
                              ListViews.eventList(
                                  selectedEvents: value.selectedEvents,
                                  smallScreen: layoutProvider.smallScreen),
                            ]);
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
