import 'dart:io';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../ui/views/route_views/trash.dart';
import '../ui/views/routes.dart';
import '../ui/views/sub_views.dart';
import 'enums.dart';
import 'numbers.dart';
import 'view_route.dart';

abstract class Constants {
  static Uuid uuid = const Uuid();

  static const String supabaseURL = String.fromEnvironment(
    "SUPABASE_URL",
    defaultValue: "",
  );

  static const String supabaseAnnonKey = String.fromEnvironment(
    "SUPABASE_ANNON_KEY",
    defaultValue: "",
  );

  static File appIcon = File("assets/placeholder.png");
  static File roadMap = File("ROADMAP.md");

  // TODO: change as appropriate.
  static const String licenseInfo =
      "Copyright © 2024 Jordan Clayton.\n Licensed under MIT.";

  // Windows notifications appID needs to be null in packaged mode.
  static String? get windowsApplicationID =>
      (const String.fromEnvironment("MSIX", defaultValue: "").toUpperCase() ==
              "Y")
          ? null
          : applicationName;
  static const String applicationName = "Allocate";
  static const String channelID = "1";
  static const String channelDescription =
      "To warn you of upcoming reminders and deadlines.";

  static int generateID() {
    int newID = fastHash(uuid.v4());
    while (newID == intMax) {
      newID = fastHash(uuid.v4());
    }
    return newID;
  }

  static int generate32ID() => fast32Hash(uuid.v4());

  // Task weight/duration params
  static const int lowerBound = 1;

  static const int upperBound = 5;

  static const int maxNumTasks = 10;

  static const Map<TaskType, int> numTasks = {
    TaskType.small: 0,
    TaskType.large: 5,
    TaskType.huge: maxNumTasks,
  };

  static const int maxTaskWeight = 5;

  static const double maxTaskWeightDouble = 5;

  static double get defaultSidebarOpacity {
    if (Platform.isIOS || Platform.isAndroid) {
      return 1.0;
    }
    if (Platform.isWindows || Platform.isMacOS) {
      return 0;
    }
    return 0.95;
  }

  static double get defaultScaffoldOpacity => 1.0;

  // static const int maxWeight = maxTaskWeight * maxNumTasks;

  static int get medianWeight => maxTaskWeight * numTasks[TaskType.large]!;

  static int get maxWeight => maxTaskWeight * numTasks[TaskType.huge]!;

  // Application Params

  // Views
  // Separate Screens.
  static const ViewRoute groupScreen = ViewRoute(
      destination: NavigationDrawerDestination(
        label: Text("All Groups", overflow: TextOverflow.ellipsis),
        icon: Icon(Icons.workspaces_outlined),
        selectedIcon: Icon(Icons.workspaces_rounded),
      ),
      view: GroupsListScreen(),
      name: "Groups",
      inMainNav: false);

  static const ViewRoute settingsScreen = ViewRoute(
    destination: NavigationDrawerDestination(
      label: Text("Settings", overflow: TextOverflow.ellipsis),
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings_rounded),
    ),
    view: UserSettingsScreen(),
    name: "Settings",
    inMainNav: false,
  );

  static const ViewRoute trashScreen = ViewRoute(
      destination: NavigationDrawerDestination(
        label: Text("Trash", overflow: TextOverflow.ellipsis),
        icon: Icon(Icons.restore_from_trash_outlined),
        selectedIcon: Icon(Icons.restore_from_trash_rounded),
      ),
      view: TrashScreen(),
      name: "Trash",
      inMainNav: false);

  static const List<ViewRoute> viewRoutes = [
    ViewRoute(
      destination: NavigationDrawerDestination(
        icon: Icon(Icons.wb_sunny_outlined),
        label: Text("My Day", overflow: TextOverflow.ellipsis),
        selectedIcon: Icon(Icons.wb_sunny_rounded),
      ),
      view: MyDayScreen(),
      name: "My Day",
      inMainNav: true,
    ),

    ViewRoute(
      destination: NavigationDrawerDestination(
        icon: Icon(Icons.notifications_outlined),
        label: Text("Notifications"),
        selectedIcon: Icon(Icons.notifications_rounded),
      ),
      view: NotificationsScreen(),
      name: "Notifications",
      inMainNav: true,
    ),

    ViewRoute(
      destination: NavigationDrawerDestination(
          icon: Icon(Icons.push_pin_outlined),
          selectedIcon: Icon(Icons.push_pin_rounded),
          label: Text("Reminders")),
      view: RemindersListScreen(),
      name: "Reminders",
      inMainNav: true,
    ),

    ViewRoute(
      destination: NavigationDrawerDestination(
        icon: Icon(Icons.announcement_outlined),
        label: Text("Deadlines"),
        selectedIcon: Icon(Icons.announcement_rounded),
      ),
      view: DeadlinesListScreen(),
      name: "Deadlines",
      inMainNav: true,
    ),

    ViewRoute(
      destination: NavigationDrawerDestination(
        icon: Icon(Icons.task_outlined),
        label: Text("Tasks"),
        selectedIcon: Icon(Icons.task_rounded),
      ),
      view: ToDosListScreen(),
      name: "Tasks",
      inMainNav: true,
    ),

    // Completed
    ViewRoute(
      destination: NavigationDrawerDestination(
        icon: Icon(Icons.check_circle_outline_rounded),
        label: Text("Completed"),
        selectedIcon: Icon(Icons.check_circle_rounded),
      ),
      view: CompletedListScreen(),
      name: "Completed",
      inMainNav: true,
    ),
    // Routines
    ViewRoute(
      destination: NavigationDrawerDestination(
        icon: Icon(Icons.repeat_rounded),
        label: Text("Routines"),
        selectedIcon: Icon(Icons.repeat_on_rounded),
      ),
      view: RoutinesListScreen(),
      name: "Routines",
      inMainNav: true,
    ),
    settingsScreen,
    trashScreen,
    // THIS MUST ALWAYS BE LAST
    groupScreen,
  ];

  static const List<Tab> tabs = [
    Tab(text: "Tasks"),
    Tab(text: "Routines"),
    Tab(text: "Calendar")
  ];

  static const List<Widget> views = [
    MyDayToDos(),
    MyDayRoutines(),
    CalendarScreen(),
  ];

  // Test these.
  static const minBandwidth = 0;
  static const maxBandwidth = 200;
  static const double maxBandwidthDouble = 200;

  // Date Constants
  static DateTime get nullDate => DateTime.utc(-271820, 12, 31);
  static const TimeOfDay midnight = TimeOfDay(hour: 0, minute: 0);
  static const TimeOfDay eod = TimeOfDay(hour: 23, minute: 59);

  static DateTime get yesterday => DateTime.now()
      .copyWith(hour: 0, minute: 0)
      .subtract(const Duration(days: 1));

  static DateTime get today => DateTime.now().copyWith(hour: 0, minute: 0);
  static int yearOffset = 5;

  // GUI constants.
  static const Duration dragDelayTime = Duration(milliseconds: 225);

  static final offsetIn =
      Tween(begin: const Offset(1, 0), end: const Offset(0, 0));

  static const int animationDelay = 200;
  static const int hitDelay = 150;
  static const int fadeInTime = 1000;
  static const int drawerSlideTime = 500;
  static const int slideInTime = 300;
  static const int footerTime = 600;
  static const int footerDelay = 100;
  static const int fadeOutTime = 250;

  // Pagination:
  static const int minLimitPerQuery = 50;

  // This is approximately 2Million elements;
  // change accordingly
  static const int maxLimitPerQuery = 2 << 19;
  static const double loadOffset = 50;

  // Placeholder int value, "MAX INT"
  static const int intMax = -1 >>> 1;

  // In LP
  static const Size minDesktopSize = Size(500, 500);

  // This is just for testing mobile formats.
  // On my main machine, this works out to 320 x 320 logical pixels.
  static const Size testDesktopSize = Size(432, 700);

  // Color
  static double tabBarOpacity = 0.5;

  static Color dialogColor({required BuildContext context}) =>
      Theme.of(context).colorScheme.surfaceVariant;

  static Color errorColor({required BuildContext context}) =>
      Theme.of(context).colorScheme.error;

  static const int defaultPrimaryColorSeed = 0xFF6750A4;

  static const Color windowsDefaultLight = Color(0x22DDDDDD);
  static const Color windowsDefaultDark = Color(0xCC222222);

  // Minimum Text sizes
  static const double small = 8;
  static const double medium = 10;
  static const double large = 12;
  static const double xtraLarge = 14;
  static const double huge = 16;
  static const double maximumFontSize = 40;

  static const double minIconSize = 16;
  static const double smIconSize = 20;
  static const double medIconSize = 35;
  static const double lgIconSize = 50;
  static const double hugeIconSize = 100;
  static const double appIconSize = 400;

  // Text styles
  static TextStyle numberPickerSecondary({required BuildContext context}) =>
      TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.secondary);

  static TextStyle numberPickerPrimary({required BuildContext context}) =>
      TextStyle(fontSize: 36, color: Theme.of(context).colorScheme.secondary);

  static const TextStyle timeColon =
      TextStyle(fontWeight: FontWeight.bold, fontSize: 32);

  static const TextStyle minBodyText = TextStyle(fontSize: 11);
  static const TextStyle medBodyText = TextStyle(fontSize: 12);
  static const TextStyle largeBodyText = TextStyle(fontSize: 14);
  static const TextStyle xtraLargeBodyText = TextStyle(fontSize: 16);
  static const TextStyle hugeBodyText = TextStyle(fontSize: 18);
  static const TextStyle maxBodyText = TextStyle(fontSize: 24);

  static const TextStyle dropdownStyle =
      TextStyle(fontSize: 18, fontWeight: FontWeight.w500);

  static const TextStyle smDropdownStyle =
      TextStyle(fontSize: 12, fontWeight: FontWeight.w500);

  static const TextStyle minHeaderStyle =
      TextStyle(fontWeight: FontWeight.bold, fontSize: 12);

  static const TextStyle smallHeaderStyle =
      TextStyle(fontWeight: FontWeight.bold, fontSize: 14);
  static const TextStyle headerStyle =
      TextStyle(fontWeight: FontWeight.bold, fontSize: 16);
  static const TextStyle largeHeaderStyle =
      TextStyle(fontWeight: FontWeight.bold, fontSize: 24);
  static const TextStyle hugeHeaderStyle =
      TextStyle(fontWeight: FontWeight.bold, fontSize: 36);

  // Tweak as necessary
  static const double maxSearchSideBeforeScroll = 300;
  static const double maxListHeightBeforeScroll = 500;
  static const double maxDesktopDialogSide = 700;
  static const double smallLandscapeDialogHeight = 500;
  static const double smallLandscapeDialogWidth = 700;
  static const double roadmapWidth = 500;

  // This is using _kWidth from Drawer. Atm it's 304, should be 360 according to M3.
  // I don't know if I wanna change it
  // static const double navigationDrawerMinWidth = 100;
  static const double navigationDrawerMaxWidth = 304;
  static const double navigationDrawerMinThreshold = 100;

  static const double verticalDividerThickness = 3;

  // This is approximate
  static const int navDestinationHeight = 56;

  // KEEP THESE AS IS.
  static const double hugeScreen = 1000;
  static const double largeScreen = 700;

  static const double smallScreen = 450;

  // For determining tablet
  static const double phoneSize = 550;

  static const double largeCheckboxScale = 1.5;
  static const double largeCheckboxMinScale = 1.2;
  static const double batteryScale = 5;
  static const double batterySmallScale = 2.5;

  static const double halfPadding = padding / 2;
  static const double quarterPadding = padding / 4;
  static const double padding = 8;
  static const double doublePadding = padding * 2;
  static const double triplePadding = padding * 3;
  static const double quadPadding = padding * 4;
  static const double outerDialogPadding = 30;
  static const double mobileDialogPadding = 10;

  static const int historyLength = 5;
  static const double circular = 50;
  static const double curvedCorners = 15;
  static const double roundedCorners = 20;
  static const double semiCircular = 30;
  static const int mobileMinLines = 8;
  static const int desktopMinLines = 15;
  static const int mobileMaxLinesBeforeScroll = 10;
  static const int desktopMaxLinesBeforeScroll = 25;

  static const double circleAvatarRadius = 25;
  static const double circleAvatarSplashOffset = 16;
  static const double circleAvatarSplashRadius =
      2 * circleAvatarRadius + circleAvatarSplashOffset;

  static const String lowBattery = "🪫";
  static const String fullBattery = "🔋";

  static const Map<int, Icon> batteryIcons = {
    0: Icon(Icons.battery_full_rounded),
    1: Icon(Icons.battery_5_bar_rounded),
    2: Icon(Icons.battery_4_bar_rounded),
    3: Icon(Icons.battery_3_bar_rounded),
    4: Icon(Icons.battery_2_bar_rounded),
    5: Icon(Icons.battery_1_bar_rounded),
  };

  static const Map<int, Icon> selectedBatteryIcons = {
    0: Icon(Icons.battery_full_rounded),
    1: Icon(Icons.battery_5_bar_rounded),
    2: Icon(Icons.battery_4_bar_rounded),
    3: Icon(Icons.battery_3_bar_rounded),
    4: Icon(Icons.battery_2_bar_rounded),
    5: Icon(Icons.battery_1_bar_rounded),
  };
  static const Map<Priority, Icon> priorityIcon = {
    Priority.low: Icon(Icons.low_priority_rounded),
    Priority.medium: Icon(Icons.flag_rounded),
    Priority.high: Icon(Icons.priority_high_rounded),
  };

  static const List<MapEntry<String, int>> weekdays = [
    MapEntry("Sun", 6),
    MapEntry("Mon", 0),
    MapEntry("Tues", 1),
    MapEntry("Wed", 2),
    MapEntry("Thur", 3),
    MapEntry("Fri", 4),
    MapEntry("Sat", 5)
  ];

  static String deleteScheduleType(DeleteSchedule? schedule) =>
      switch (schedule) {
        DeleteSchedule.day => "15 days",
        DeleteSchedule.month => "30 days",
        DeleteSchedule.year => "1 year",
        _ => "Forever"
      };

  // This is for timezones.
  static const Map timezoneNames = {
    0: 'UTC',
    10800000: 'Indian/Mayotte',
    3600000: 'Europe/London',
    7200000: 'Europe/Zurich',
    -32400000: 'Pacific/Gambier',
    -28800000: 'US/Alaska',
    -14400000: 'US/Eastern',
    -10800000: 'Canada/Atlantic',
    -18000000: 'US/Central',
    -21600000: 'US/Mountain',
    -25200000: 'US/Pacific',
    -7200000: 'Atlantic/South_Georgia',
    -9000000: 'Canada/Newfoundland',
    39600000: 'Pacific/Pohnpei',
    25200000: 'Indian/Christmas',
    36000000: 'Pacific/Saipan',
    18000000: 'Indian/Maldives',
    46800000: 'Pacific/Tongatapu',
    21600000: 'Indian/Chagos',
    43200000: 'Pacific/Wallis',
    14400000: 'Indian/Reunion',
    28800000: 'Australia/Perth',
    32400000: 'Pacific/Palau',
    19800000: 'Asia/Kolkata',
    16200000: 'Asia/Kabul',
    20700000: 'Asia/Kathmandu',
    23400000: 'Indian/Cocos',
    12600000: 'Asia/Tehran',
    -3600000: 'Atlantic/Cape_Verde',
    37800000: 'Australia/Broken_Hill',
    34200000: 'Australia/Darwin',
    31500000: 'Australia/Eucla',
    49500000: 'Pacific/Chatham',
    -36000000: 'US/Hawaii',
    50400000: 'Pacific/Kiritimati',
    -34200000: 'Pacific/Marquesas',
    -39600000: 'Pacific/Pago_Pago'
  };
}
