import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import 'package:schedulers/schedulers.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:windows_notification/notification_message.dart';
import 'package:windows_notification/windows_notification.dart';

import '../util/constants.dart';

// Limitations: Linux build cannot currently handle notification clicks.
// Plugin may eventually use the new desktop standard. In the meantime looking into dbus.

// Future TODO: refactor this into an interface and use DI to handle platform specific code.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  // Linux/Windows only.
  late final Map<int, TimeScheduler> desktopLocalNotifications = {};

  // Windows only
  late final WindowsNotification winLocalNotificationPlugin;

  static NotificationService get instance => _instance;

  late final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

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

  static const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings("@mipmap/ic_launcher");

  static const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();

  static const LinuxInitializationSettings initializationSettingsLinux =
      LinuxInitializationSettings(defaultActionName: "Open notification");

  Future<void> init() async {
    // Timezones
    tz.initializeTimeZones();
    final String timeZoneName =
        Constants.timezoneNames[DateTime.now().timeZoneOffset.inMilliseconds];
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    if (Platform.isWindows) {
      return await initWindows();
    }

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();

    // LocalNotifierSettings
    const initSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin,
        linux: initializationSettingsLinux);

    // Include routing for when this is initialized.
    await flutterLocalNotificationsPlugin.initialize(initSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);

    return await handleAppLaunch();
  }

  Future<void> initWindows() async {
    // Windows
    winLocalNotificationPlugin =
        WindowsNotification(applicationId: Constants.windowsApplicationID);
    winLocalNotificationPlugin.initNotificationCallBack(
        (NotificationMessage data, EventType eventType, String? args) async {
      if (eventType == EventType.onActivate) {
        NotificationResponse response = NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: int.tryParse(data.id),
          payload: data.payload["payload"],
        );

        return await onDidReceiveNotificationResponse(response);
      }
      if (eventType == EventType.onDismissed) {
        winLocalNotificationPlugin.removeNotificationId(
            data.id, data.group ?? Constants.applicationName);
      }
    });
  }

  // NOTE: id should be the object's hashcode. Payload is TYPE\n notificationID.
  Future<void> scheduleNotification({
    required int id,
    required DateTime warnDate,
    required String message,
    required String payload,
  }) async {
    final scheduleDate = tz.TZDateTime.from(warnDate, tz.local);

    if (Platform.isIOS || Platform.isAndroid || Platform.isMacOS) {
      // Mobile/MacOS only.
      return await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        //Title
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

    if (Platform.isLinux) {
      return await scheduleLinux(
          id: id, warnDate: warnDate, message: message, payload: payload);
    }

    if (Platform.isWindows) {
      return await scheduleWindows(
          id: id, warnDate: warnDate, message: message, payload: payload);
    }
  }

  Future<void> scheduleLinux(
      {required int id,
      required DateTime warnDate,
      required String message,
      String? payload}) async {
    TimeScheduler timeScheduler = TimeScheduler();
    timeScheduler.run(() async {
      await showNotificationLinux(
          id: id, warnDate: warnDate, message: message, payload: payload);
      timeScheduler.dispose();
    }, tz.TZDateTime.from(warnDate, tz.local));

    desktopLocalNotifications.addAll({id: timeScheduler});
  }

  Future<void> scheduleWindows(
      {required int id,
      required DateTime warnDate,
      required String message,
      String? payload}) async {
    NotificationMessage notification = NotificationMessage.fromPluginTemplate(
        id.toString(), Constants.applicationName, message,
        payload: {"payload": payload}, group: Constants.applicationName);

    TimeScheduler timeScheduler = TimeScheduler();
    timeScheduler.run(() async {
      await winLocalNotificationPlugin
          .showNotificationPluginTemplate(notification);
      timeScheduler.dispose();
    }, tz.TZDateTime.from(warnDate, tz.local));

    desktopLocalNotifications.addAll({id: timeScheduler});
  }

  Future<void> showNotificationLinux(
      {required int id,
      required DateTime warnDate,
      required String message,
      String? payload}) async {
    await flutterLocalNotificationsPlugin.show(
        // Id
        id,
        // Header
        Constants.applicationName,
        // Message
        message,
        // Notification Details
        _notificationDetails,
        // Payload
        payload: payload);
  }

  Future<void> cancelNotification({required int id}) async {
    if (Platform.isWindows || Platform.isLinux) {
      desktopLocalNotifications[id]?.dispose();
      desktopLocalNotifications.remove(id);
      return;
    }

    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelFutures({required List<int> ids}) async {
    for (int id in ids) {
      await cancelNotification(id: id);
    }
  }

  Future<void> cancelAllNotifications() async {
    if (Platform.isWindows || Platform.isLinux) {
      desktopLocalNotifications.forEach((k, v) {
        v.dispose();
        desktopLocalNotifications.remove(k);
      });
      desktopLocalNotifications.clear();
    }
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  @pragma('vm: entry-point')
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
    // Eventual TODO: Send the payload as an arg to reminders screen -> Then, await show update dialog.

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
    return tz.TZDateTime.from(warnDate, tz.local)
        .isAfter(tz.TZDateTime.now(tz.local));
  }

  Future<void> handleAppLaunch() async {
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        (!kIsWeb && !Platform.isLinux)
            ? await flutterLocalNotificationsPlugin
                .getNotificationAppLaunchDetails()
            : null;
    return onDidReceiveNotificationResponse(
        notificationAppLaunchDetails?.notificationResponse);
  }

  NotificationService._internal();
}
