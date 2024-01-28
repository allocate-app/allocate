import 'package:flutter/foundation.dart';
import 'package:schedulers/schedulers.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../util/constants.dart';

// Singleton class to notify daily resetting.
class DailyResetProvider extends ChangeNotifier {
  bool timezoneInitialized = false;
  static final DailyResetProvider _instance = DailyResetProvider._internal();

  static DailyResetProvider get instance => _instance;

  late TimeScheduler resetScheduler;

  void init() {
    initializeTimezone();
    if (!timezoneInitialized) {
      return;
    }
    resetScheduler = TimeScheduler();
    initTimeScheduler();
  }

  void initializeTimezone() {
    try {
      tz.initializeTimeZones();
      final String timeZoneName =
          Constants.timezoneNames[DateTime.now().timeZoneOffset.inMilliseconds];
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      timezoneInitialized = true;
    } on tz.TimeZoneInitException {
      timezoneInitialized = false;
    }
  }

  void initTimeScheduler() {
    if (!timezoneInitialized) {
      return;
    }
    resetScheduler.run(
        dailyReset,
        tz.TZDateTime.from(
            Constants.today.copyWith(day: Constants.today.day + 1), tz.local));
  }

  void resetTimeScheduler() {
    if (!timezoneInitialized) {
      return;
    }
    resetScheduler.dispose();
    resetScheduler = TimeScheduler();
    initTimeScheduler();
  }

  void dailyReset() {
    notifyListeners();
    resetTimeScheduler();
  }

  DailyResetProvider._internal();
}
