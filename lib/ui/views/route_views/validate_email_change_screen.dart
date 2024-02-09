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

// Basically just push the loading screen, set the new email, load the settings-screen index and route to home screen.
// TODO: -> Refactor this out.
// Just deeplink with an initial starting index.
@RoutePage()
class ValidateEmailChangeScreen extends StatefulWidget {
  const ValidateEmailChangeScreen({super.key});

  @override
  State<ValidateEmailChangeScreen> createState() =>
      _ValidateEmailChangeScreen();
}

class _ValidateEmailChangeScreen extends State<ValidateEmailChangeScreen> {
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
    // This implies the app is already running.
    if (up.initialized) {
      User? user = SupabaseService.instance.supabaseClient.auth.currentUser;
      // Get the new email, if it's somehow null, get the old email (should be the new one).
      // Assuming supabase has properly deeplinked.
      up.viewModel?.email =
          user?.newEmail ?? user?.email ?? up.viewModel?.email;
      return;
    }

    // If for some reason these have already been initialized, they will
    // just skip the routines.
    await Future.wait([
      IsarService.instance.init(),
      SupabaseService.instance.init(
        supabaseUrl: Constants.supabaseURL,
        anonKey: Constants.supabaseAnnonKey,
      ),
      Provider.of<ToDoProvider>(context, listen: false).init(),
      Provider.of<RoutineProvider>(context, listen: false).init(),
      Provider.of<SubtaskProvider>(context, listen: false).init(),
      Provider.of<ReminderProvider>(context, listen: false).init(),
      Provider.of<DeadlineProvider>(context, listen: false).init(),
      Provider.of<GroupProvider>(context, listen: false).init(),
      // This will trigger a day reset if the user has opened the app across a day.
      Provider.of<UserProvider>(context, listen: false).init(),
      NotificationService.instance.init(),
    ]);

    // Set the email accordingly.
    User? user = SupabaseService.instance.supabaseClient.auth.currentUser;
    // Get the new email, if it's somehow null, get the old email (should be the new one).
    // Assuming supabase has properly deeplinked.
    up.viewModel?.email = user?.newEmail ?? user?.email ?? up.viewModel?.email;
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
    ]).catchError((e) {
      Tiles.displayError(e: e);
      return [];
    });
  }

  @override
  Widget build(BuildContext context) => const LoadingScreen();
}
