import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/model/deadline_provider.dart';
import '../../../providers/model/group_provider.dart';
import '../../../providers/model/reminder_provider.dart';
import '../../../providers/model/routine_provider.dart';
import '../../../providers/model/subtask_provider.dart';
import '../../../providers/model/todo_provider.dart';
import '../../../providers/model/user_provider.dart';
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

  @override
  void initState() {
    super.initState();

    init().whenComplete(() {
      // This implies that NavigationService opened a payload.
      if (AutoRouter.of(context).isRouteActive("home")) {
        return;
      }

      // ROUTE TO HOME PAGE, send the initial index.
      AutoRouter.of(context).navigate(HomeRoute(index: 0));
    });
  }

  @override
  void dispose() {
    dailyResetProvider.removeListener(dayReset);
    super.dispose();
  }

  Future<void> init() async {
    // Initialize Isar.
    // Initialize Supabase.
    // Initialize Providers.
    dailyResetProvider.addListener(dayReset);

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
        // This will trigger a day reset if the user has opened the app across a day.
        Provider.of<UserProvider>(context, listen: false).init(),
        // It might be smarter to return an index instead.
        NotificationService.instance.init(),
      ]);
    });
  }

  Future<void> dayReset() async {
    Future.wait([
      Provider.of<ToDoProvider>(context, listen: false).dayReset(),
      Provider.of<RoutineProvider>(context, listen: false).dayReset(),
      Provider.of<SubtaskProvider>(context, listen: false).dayReset(),
      Provider.of<ReminderProvider>(context, listen: false).dayReset(),
      Provider.of<DeadlineProvider>(context, listen: false).dayReset(),
      Provider.of<GroupProvider>(context, listen: false).dayReset(),
      Provider.of<UserProvider>(context, listen: false).dayReset(),
    ]).catchError((e) => Tiles.displayError(context: context, e: e));
  }

  @override
  Widget build(BuildContext context) => const LoadingScreen();
}
