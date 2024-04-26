import 'package:cron/cron.dart';
import 'package:flutter/foundation.dart';

// Singleton class to notify daily resetting.
class DailyResetService extends ChangeNotifier {
  static final DailyResetService _instance = DailyResetService._internal();

  static DailyResetService get instance => _instance;
  late final Cron cron;

  void init() {
    cron = Cron();
    initTimeScheduler();
  }

  void initTimeScheduler() {
    cron.schedule(Schedule.parse('0 0 * * *'), dailyReset);
  }

  void dailyReset() {
    notifyListeners();
  }

  DailyResetService._internal();
}
