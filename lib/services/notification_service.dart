import 'dart:convert';
import 'dart:io';

import "package:flutter_local_notifications/flutter_local_notifications.dart";
import 'package:schedulers/schedulers.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../util/constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  // Linux/Windows only.
  // REFACTOR: get rid of scheduler.
  // Make a dictionary of streams? Needs implementation
  //
  late final TimeScheduler scheduler;

  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationDetails _androidNotificationDetails =
      AndroidNotificationDetails(
    Constants.channelID,
    Constants.applicationName,
    channelDescription: Constants.channelDescription,
    playSound: true,
    priority: Priority.high,
    importance: Importance.high,
  );

  static const DarwinNotificationDetails _darwinNotificationDetails =
      DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    threadIdentifier: Constants.channelID,
  );

  static const LinuxNotificationDetails _linuxNotificationDetails =
      LinuxNotificationDetails(
    urgency: LinuxNotificationUrgency.normal,
  );

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: _androidNotificationDetails,
    iOS: _darwinNotificationDetails,
    macOS: _darwinNotificationDetails,
    linux: _linuxNotificationDetails,
  );

  Future<void> init() async {

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings("@mipmap/ic_launcher");

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: "Open notification");

    const initSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin,
        linux: initializationSettingsLinux);

    if(Platform.isWindows || Platform.isLinux)
      {
        scheduler = TimeScheduler();
      }

    tz.initializeTimeZones();

    // TODO: NEEDS TO HAVE TIMEZONES ACTUALLY SET.

    // Include routing for when this is initialized.
    await flutterLocalNotificationsPlugin.initialize(initSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
  }

  // NOTE: id should be the object's hashcode. Payload is TYPE\n notificationID.
  Future<void> scheduleNotification({
    required int id,
    required DateTime warnDate,
    required String message,
    required String payload,
  }) async {
    final scheduleDate = tz.TZDateTime.from(warnDate, tz.local);

    // Mobile/MacOS only.
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      Constants.applicationName,
      message,
      scheduleDate,
      _notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelNotification({required int id}) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelFutures({required List<int> ids}) async {
    for (int id in ids) {
      await flutterLocalNotificationsPlugin.cancel(id);
    }
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  // NEEDS ROUTING.
  Future<void> onDidReceiveNotificationResponse(
      NotificationResponse? notificationResponse) async {
    final String? payload = notificationResponse?.payload;
    if (null == payload) {
      // Go through regular routing routine.
      return;
    }
    LineSplitter lineSplitter = const LineSplitter();
    List<String> entities = lineSplitter.convert(payload);

    // TODO: Remove payload. Just route to "Notifications Pg"
    // In the payload, log the index value to send as an arg.

    if (entities.isEmpty || entities.length > 2) {
      // Go through regular routing routine.
      return;
    }
    // TODO: re-implement this. Go straight to the notifications screen.
    // Remove payloads.

    // First string is the type, second is the id.
    switch (entities[0]) {
      case "DEADLINE":
        // Route to deadline screen, get by notification ID.
        // Design UI to take multiple args for initstate.
        break;
      case "REMINDER":
        // Route to reminder screen, get by notification id.
        break;
      default:
        // Regular routing.
        break;
    }
  }

  bool validateWarnDate({required DateTime warnDate}) {
    return tz.TZDateTime.from(warnDate, tz.local).isAfter(tz.TZDateTime.now(tz.local));
  }

  Future<void> handleAppLaunch() async {
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    return onDidReceiveNotificationResponse(
        notificationAppLaunchDetails?.notificationResponse);
  }

  NotificationService._internal();
}
