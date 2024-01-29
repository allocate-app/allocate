import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import 'package:schedulers/schedulers.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:windows_notification/notification_message.dart';
import 'package:windows_notification/windows_notification.dart';

import '../util/constants.dart';
import '../util/exceptions.dart';
import 'daily_reset_service.dart';

// Limitations: Linux build cannot currently handle notification clicks.
// Plugin may eventually use the new desktop standard. In the meantime looking into dbus.

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  late bool canSchedule = true;

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

  // Timezone is already initialized in the reset scheduler.
  Future<void> init() async {
    canSchedule = DailyResetService.instance.timezoneInitialized;

    if (!canSchedule) {
      return;
    }

    if (Platform.isWindows) {
      return await initWindows();
    }

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

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
    winLocalNotificationPlugin
        .initNotificationCallBack((NotificationCallBackDetails details) async {
      if (details.eventType == EventType.onActivate) {
        NotificationResponse response = NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: int.tryParse(details.message.id),
          payload: details.message.payload["payload"],
        );

        return await onDidReceiveNotificationResponse(response);
      }
      if (details.eventType == EventType.onDismissedUserCanceled) {
        winLocalNotificationPlugin.removeNotificationId(details.message.id,
            details.message.group ?? Constants.applicationName);
      }
    });
  }

  Future<void> scheduleNotification({
    required int id,
    required DateTime warnDate,
    required String message,
    required String payload,
  }) async {
    if (!canSchedule) {
      throw FailureToScheduleException(
          "Unable to establish Timezone for Scheduling");
    }
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

  Future<void> cancelNotification({required int? id}) async {
    if (null == id) {
      return;
    }
    if (Platform.isWindows || Platform.isLinux) {
      desktopLocalNotifications[id]?.dispose();
      desktopLocalNotifications.remove(id);
      return;
    }

    return await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelMultiple({required List<int?> ids}) async {
    for (int? id in ids) {
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

  // TODO: refactor this to just route to the notifications scrn.
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

  bool validateNotificationDate({DateTime? notificationDate}) {
    return null != notificationDate &&
        tz.TZDateTime.from(notificationDate, tz.local)
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
