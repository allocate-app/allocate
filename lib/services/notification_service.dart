import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:windows_notification/notification_message.dart';
import 'package:windows_notification/windows_notification.dart';

import '../ui/app_router.dart';
import '../util/constants.dart';
import '../util/exceptions.dart';
import 'application_service.dart';

// Limitations: Linux build cannot currently handle notification clicks.
// Plugin may eventually use the new desktop standard. In the meantime looking into dbus.
// Local notifications for Linux/Windows cannot be scheduled; they will not fire at the right time
// due to process suspension.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  late bool _canSchedule = false;
  late bool _initialized = false;

  // Linux/Windows only.
  late final Map<int, Timer> desktopLocalNotifications = {};

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
    urgency: LinuxNotificationUrgency.critical,
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

  static final LinuxInitializationSettings initializationSettingsLinux =
      LinuxInitializationSettings(
          defaultActionName: "Open notification",
          defaultIcon: AssetsLinuxIcon("assets/allocateaboutlogo.png"));

  Future<void> init() async {
    if (_initialized || _canSchedule) {
      return;
    }

    try {
      final String timeZoneName =
          Constants.timezoneNames[DateTime.now().timeZoneOffset.inMilliseconds];
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      _canSchedule = true;
    } on tz.TimeZoneInitException {
      _canSchedule = false;
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
    final initSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin,
        linux: initializationSettingsLinux);

    // Include routing for when this is initialized.
    await flutterLocalNotificationsPlugin.initialize(initSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);

    _initialized = true;
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

    _initialized = true;
  }

  Future<void> scheduleNotification({
    required int id,
    required DateTime warnDate,
    required String message,
    required String payload,
  }) async {
    if (!_canSchedule) {
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
    Timer timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (DateTime.now().isAfter(warnDate)) {
        await showNotificationLinux(
          id: id,
          message: message,
          payload: payload,
        );
        timer.cancel();
      }
    });

    // Cancel an existing notification if it's being re-scheduled.
    desktopLocalNotifications[id]?.cancel();
    desktopLocalNotifications[id] = timer;
  }

  Future<void> scheduleWindows(
      {required int id,
      required DateTime warnDate,
      required String message,
      String? payload}) async {
    NotificationMessage notification = NotificationMessage.fromPluginTemplate(
        id.toString(), Constants.applicationName, message,
        payload: {"payload": payload}, group: Constants.applicationName);

    Timer timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (DateTime.now().isAfter(warnDate)) {
        await winLocalNotificationPlugin
            .showNotificationPluginTemplate(notification);
        timer.cancel();
      }
    });

    // Cancel an existing notification if it's being re-scheduled.
    desktopLocalNotifications[id]?.cancel();
    desktopLocalNotifications[id] = timer;
  }

  Future<void> showNotificationWindows(
      {required int id, required String message, String? payload}) async {
    NotificationMessage notification = NotificationMessage.fromPluginTemplate(
        id.toString(), Constants.applicationName, message,
        payload: {"payload": payload}, group: Constants.applicationName);
    await winLocalNotificationPlugin
        .showNotificationPluginTemplate(notification);
  }

  Future<void> showNotificationLinux(
      {required int id, required String message, String? payload}) async {
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
      Timer? timer = desktopLocalNotifications[id];
      timer?.cancel();
      desktopLocalNotifications.remove(id);
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
      for (Timer timer in desktopLocalNotifications.values) {
        timer.cancel();
      }
      desktopLocalNotifications.clear();
      return;
    }
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  @pragma('vm: entry-point')
  Future<void> onDidReceiveNotificationResponse(
      NotificationResponse? notificationResponse) async {
    final String? payload = notificationResponse?.payload;

    if (null == payload) {
      return;
    }

    ApplicationService as = ApplicationService.instance;

    // Set the routing to Notifications.
    as.initialPageIndex = 1;

    // If the app is already open, push to home
    if (as.appRouter.isRouteActive("/home")) {
      as.appRouter.navigate(HomeRoute(index: 1));
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
