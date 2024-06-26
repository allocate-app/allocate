import 'dart:io';
import 'dart:ui';

import 'package:flex_seed_scheme/flex_seed_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../providers/application/event_provider.dart';
import '../providers/application/layout_provider.dart';
import '../providers/model/deadline_provider.dart';
import '../providers/model/group_provider.dart';
import '../providers/model/reminder_provider.dart';
import '../providers/model/subtask_provider.dart';
import '../providers/model/todo_provider.dart';
import '../providers/model/user_provider.dart';
import '../providers/viewmodels/deadline_viewmodel.dart';
import '../providers/viewmodels/reminder_viewmodel.dart';
import '../providers/viewmodels/todo_viewmodel.dart';
import '../services/application_service.dart';
import '../ui/widgets/tiles.dart';
import '../util/constants.dart';

// This may require providers. Right now, this is just so I can build GUI things without
// having to run the entire app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  // iPadOS (and hopefully some android tablets) should ignore this.
  if (Platform.isIOS || Platform.isAndroid) {
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  } else {
    await windowManager.ensureInitialized();
    await windowManager.setResizable(true);
    // TODO: implement windows transparent titlebar.
    WindowOptions windowOptions = const WindowOptions(
      minimumSize: Constants.testDesktopSize,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      // TODO: minimize to taskbar
      // await windowManager.setPreventClose(true);
    });
  }

  // TESTING WIDGETS
  // Widget testWidget = const LoadingScreen();
  // Widget testWidget = Scaffold(
  //   body: Builder(builder: (BuildContext context) {
  //     return Center(
  //         child: FilledButton(
  //             child: const Text("Email Dialog"),
  //             onPressed: () async {
  //               await showDialog(
  //                   context: context,
  //                   builder: (BuildContext context) {
  //                     return const UpdateEmailDialog();
  //                   });
  //             }));
  //   }),
  // );
  // Widget testWidget = Scaffold(
  //   body: Builder(builder: (BuildContext context) {
  //     return Center(
  //         child: FilledButton(
  //             child: const Text("Sign-In Dialog"),
  //             onPressed: () async {
  //               await showDialog(
  //                   context: context,
  //                   builder: (BuildContext context) {
  //                     return const SignInDialog();
  //                   });
  //             }));
  //   }),
  // );

  // Widget testWidget = Scaffold(
  //     body: const Center(child: Text("FAB TESTER")),
  //     floatingActionButtonLocation: ExpandableFab.location,
  //     floatingActionButton: const MainFloatingActionButton());

  ValueNotifier updateLoading = ValueNotifier(false);
  ValueNotifier deleteLoading = ValueNotifier(false);
  Widget testWidget = Scaffold(
    body: Center(
        child: ValueListenableBuilder(
      valueListenable: updateLoading,
      builder: (BuildContext context, updateLoading, Widget? child) =>
          ValueListenableBuilder(
        valueListenable: deleteLoading,
        builder: (BuildContext context, deleteLoading, Widget? child) =>
            Tiles.updateAndDeleteButtons(
                updateLoading: updateLoading,
                deleteLoading: deleteLoading,
                updateButtonPadding:
                    const EdgeInsets.symmetric(horizontal: Constants.padding),
                deleteButtonPadding:
                    const EdgeInsets.symmetric(horizontal: Constants.padding),
                // Simulate delete + update logique.
                handleDelete: () async {
                  print("Clicked");
                  deleteLoading.value = true;
                  await Future.delayed(const Duration(seconds: 2));
                  deleteLoading.value = false;
                  print("Done");
                },
                handleUpdate: () async {
                  print("Clicked");
                  updateLoading.value = true;
                  await Future.delayed(const Duration(seconds: 2));
                  updateLoading.value = false;
                  print("Done");
                }),
      ),
    )),
  );

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider<LayoutProvider>(create: (_) {
      LayoutProvider lp = LayoutProvider();
      lp.drawerOpened = false;
      lp.isMobile = Platform.isAndroid || Platform.isIOS;
      return lp;
    }),
    ChangeNotifierProvider<ToDoProvider>(create: (_) => ToDoProvider()),
    ChangeNotifierProvider<ToDoViewModel>(create: (_) => ToDoViewModel()),
    ChangeNotifierProvider<SubtaskProvider>(create: (_) => SubtaskProvider()),
    ChangeNotifierProvider<GroupProvider>(create: (_) => GroupProvider()),
    ChangeNotifierProvider<EventProvider>(create: (_) => EventProvider()),
    ChangeNotifierProvider<DeadlineProvider>(create: (_) => DeadlineProvider()),
    ChangeNotifierProvider<DeadlineViewModel>(
        create: (_) => DeadlineViewModel()),
    ChangeNotifierProvider<ReminderProvider>(create: (_) => ReminderProvider()),
    ChangeNotifierProvider<ReminderViewModel>(
        create: (_) => ReminderViewModel()),
    ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
  ], child: WidgetTester(testWidget: testWidget)));
}

class WidgetTester extends StatefulWidget {
  const WidgetTester({super.key, required this.testWidget});

  final Widget testWidget;

  @override
  State<WidgetTester> createState() => _WidgetTester();
}

class _WidgetTester extends State<WidgetTester> {
  late final LayoutProvider layoutProvider;

  @override
  void initState() {
    super.initState();
    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);
    // NOTE: this does throw an exception -> but it should be fine.
  }

  // Basic themes.
  ThemeData lightTheme = ThemeData(
    colorScheme: SeedColorScheme.fromSeeds(
      brightness: Brightness.light,
      primaryKey: const Color(Constants.defaultPrimaryColorSeed),
      tones: FlexTones.material(Brightness.light),
    ),
  );
  ThemeData darkTheme = ThemeData(
    colorScheme: SeedColorScheme.fromSeeds(
      brightness: Brightness.dark,
      primaryKey: const Color(Constants.defaultPrimaryColorSeed),
      tones: FlexTones.material(Brightness.dark),
    ),
  );

  @override
  Widget build(BuildContext context) {
    layoutProvider.size = MediaQuery.sizeOf(context);
    layoutProvider.isTablet = layoutProvider.isMobile &&
        (layoutProvider.size.shortestSide > Constants.smallScreen);
    // print(layoutProvider.smallScreen);
    return TitlebarSafeArea(
      child: MaterialApp(
        navigatorKey: ApplicationService.instance.globalNavigatorKey,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        home: widget.testWidget,
      ),
    );
  }
}
