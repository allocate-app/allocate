import 'package:flutter/foundation.dart';
import 'package:schedulers/schedulers.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../util/constants.dart';

class DailyResetProvider extends ChangeNotifier {
  TimeScheduler resetScheduler;

  DailyResetProvider() : resetScheduler = TimeScheduler() {
    init();
  }

  void init() {
    // This is already initialized in the notification service.

    // tz.initializeTimeZones();
    // final String timeZoneName =
    //     Constants.timezoneNames[DateTime.now().timeZoneOffset.inMilliseconds];
    // tz.setLocalLocation(tz.getLocation(timeZoneName));

    initTimeScheduler();
  }

  void initTimeScheduler() {
    resetScheduler.run(
        dailyReset,
        tz.TZDateTime.from(
            Constants.today.copyWith(day: Constants.today.day + 1), tz.local));
  }

  void resetTimeScheduler() {
    resetScheduler.dispose();
    resetScheduler = TimeScheduler();
    initTimeScheduler();
  }

  void dailyReset() {
    notifyListeners();
    resetTimeScheduler();
  }
}
