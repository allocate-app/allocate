import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";

import "views/routes.dart";

/// Remaining views:
/// Calendar: -> For Side view.
/// ToDos: Create/Update/FullList/Completed
/// StretchGoal: Trash! Needs a modification to the timer -> Delete Method moves to trash. EdgeFunc/Store in user to determine whether to nuke after like 30 days?
/// INTERIM: -> Use a boolean(Alert Deletes): Add to user schema.
///
/// SubTasks?? Maybe.
///
/// Routines: Create/Update/TOD Select/FullList
/// Deadlines: Create/Update/FullList
/// Reminders: Create/Update/FullList
/// User: Recover/Create/Update
/// Auth: Sign In/Sign Up/Delete Account

part "app_router.gr.dart";

// This needs to be fully refactored and is likely unnecessary.
@AutoRouterConfig(replaceInRouteName: 'Page|Screen,Route')
class AppRouter extends _$AppRouter {
  @override
  RouteType get defaultRouteType => const RouteType.material();

  // TODO: Screens! Also, switch to customRoute for transitions.
  @override
  List<AutoRoute> get routes => [
        // AutoRoute(path: "/", page: SplashRoute.page, initial: true),
        AutoRoute(path: "/sign-up", page: SignUpRoute.page),
        AutoRoute(path: "/login", page: LoginRoute.page),
        AutoRoute(path: "/home", page: HomeRoute.page),
        AutoRoute(path: "/init-user", page: InitUserRoute.page),
        AutoRoute(path: "/create-user", page: CreateUserRoute.page),
        // AutoRoute(path: "/update-user", page: HomeRoute.page),
        // Send this with an arg to prompt the dialog.
        AutoRoute(path: "/update-password", page: UpdatePasswordRoute.page),
        AutoRoute(path: "/update-email", page: UpdateEmailRoute.page),
      ];
}
