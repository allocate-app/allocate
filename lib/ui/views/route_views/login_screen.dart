import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "../../../providers/model/deadline_provider.dart";
import "../../../providers/model/group_provider.dart";
import "../../../providers/model/reminder_provider.dart";
import "../../../providers/model/routine_provider.dart";
import "../../../providers/model/subtask_provider.dart";
import "../../../providers/model/todo_provider.dart";
import "../../../providers/model/user_provider.dart";
import "../../../services/daily_reset_service.dart";
import "../../../services/isar_service.dart";
import "../../../services/notification_service.dart";
import "../../../services/supabase_service.dart";
import "../../../util/constants.dart";
import "../../app_router.dart";
import "../../widgets/tiles.dart";
import "loading_screen.dart";

// This should just play the loading animation
// set the home-page-index to settings screen, and pop open the dialog.
@RoutePage()
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreen();
}

class _LoginScreen extends State<LoginScreen> {
  final DailyResetService dailyResetProvider = DailyResetService.instance;

  @override
  void initState() {
    super.initState();
    dailyResetProvider.addListener(dayReset);
    // This is in-case the usr needs to log in again.
    init().whenComplete(() {
      AutoRouter.of(context).navigate(HomeRoute(
          index: Constants.viewRoutes.indexOf(Constants.settingsScreen)));
    });
  }

  @override
  void dispose() {
    dailyResetProvider.removeListener(dayReset);
    super.dispose();
  }

  Future<void> init() async {
    UserProvider up = Provider.of<UserProvider>(context, listen: false);
    // This implies the app is already running. -> NOPE, doesn't work.
    if (up.initialized) {
      User? user = SupabaseService.instance.supabaseClient.auth.currentUser;
      // Get the new user id -> should be overwritten by a sync routine anyway.
      up.viewModel?.uuid = user?.id;
      return;
    }

    // If for some reason these have already been initialized, they will
    // just skip the routines.

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
    }).whenComplete((){
      // Set the uuid accordingly - should be overwritten on next sync routine.
      User? user = SupabaseService.instance.supabaseClient.auth.currentUser;
      up.viewModel?.uuid = user?.id;
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
