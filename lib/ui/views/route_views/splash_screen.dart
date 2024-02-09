import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../providers/application/layout_provider.dart';
import '../../../providers/model/deadline_provider.dart';
import '../../../providers/model/group_provider.dart';
import '../../../providers/model/reminder_provider.dart';
import '../../../providers/model/routine_provider.dart';
import '../../../providers/model/subtask_provider.dart';
import '../../../providers/model/todo_provider.dart';
import '../../../providers/model/user_provider.dart';
import '../../../services/application_service.dart';
import '../../../services/daily_reset_service.dart';
import '../../../services/isar_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/supabase_service.dart';
import '../../../util/constants.dart';
import '../../../util/exceptions.dart';
import '../../app_router.dart';
import '../../widgets/tiles.dart';
import 'loading_screen.dart';

// Open on app launch -> gives enough time for stuff to be initialized.
@RoutePage()
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<SplashScreen> createState() => _SplashScreen();
}

class _SplashScreen extends State<SplashScreen> {
  final DailyResetService dailyResetProvider = DailyResetService.instance;
  late final LayoutProvider layoutProvider;

  @override
  void initState() {
    super.initState();
    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);

    init().whenComplete(() {
      // ROUTE TO HOME PAGE, send the initial index.
      // Unless it has been set by NavigatorService
      AutoRouter.of(context).navigate(HomeRoute(
          index: ApplicationService.instance.initialPageIndex ??
              widget.initialIndex));
    });
  }

  @override
  void dispose() {
    dailyResetProvider.removeListener(dayReset);
    super.dispose();
  }

  Future<void> init() async {
    // Check to see if supabase => the app is already opened.
    try {
      SupabaseClient testClient = SupabaseService.instance.supabaseClient;
      return;
    } finally {
      // Initialize Isar.
      // Initialize Supabase.
      // Initialize Providers.
      dailyResetProvider.addListener(dayReset);
      layoutProvider.isMobile = Platform.isIOS || Platform.isAndroid;

      if (Constants.supabaseURL.isEmpty || Constants.supabaseAnnonKey.isEmpty) {
        throw BuildFailureException("App has not been configured");
      }

      // DBs need to be initialized before providers.

      await Future.wait(
        [
          IsarService.instance.init(),
          SupabaseService.instance.init(
            supabaseUrl: Constants.supabaseURL,
            anonKey: Constants.supabaseAnnonKey,
          ),
        ],
      ).then((_) async {
        await Future.wait([
          Provider.of<ToDoProvider>(context, listen: false).init(),
          Provider.of<RoutineProvider>(context, listen: false).init(),
          Provider.of<SubtaskProvider>(context, listen: false).init(),
          Provider.of<ReminderProvider>(context, listen: false).init(),
          Provider.of<DeadlineProvider>(context, listen: false).init(),
          Provider.of<GroupProvider>(context, listen: false).init(),
          Provider.of<UserProvider>(context, listen: false).init(),
          NotificationService.instance.init(),
        ]);

        // The splash screen is going too fast.
        await Future.delayed(const Duration(seconds: 1));
      });
    }
  }

  Future<void> dayReset() async {
    await Future.wait([
      Provider.of<ToDoProvider>(context, listen: false).dayReset(),
      Provider.of<RoutineProvider>(context, listen: false).dayReset(),
      Provider.of<SubtaskProvider>(context, listen: false).dayReset(),
      Provider.of<ReminderProvider>(context, listen: false).dayReset(),
      Provider.of<DeadlineProvider>(context, listen: false).dayReset(),
      Provider.of<GroupProvider>(context, listen: false).dayReset(),
      Provider.of<UserProvider>(context, listen: false).dayReset(),
    ]).catchError((e) async {
      await Tiles.displayError(e: e);
      return [];
    });
  }

  @override
  Widget build(BuildContext context) {
    layoutProvider.size = MediaQuery.sizeOf(context);
    layoutProvider.isTablet = layoutProvider.isMobile &&
        (layoutProvider.size.shortestSide > Constants.smallScreen);
    return const LoadingScreen();
  }
}
