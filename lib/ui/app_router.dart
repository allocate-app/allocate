import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";

import "views/routes.dart";

part "app_router.gr.dart";

@AutoRouterConfig(replaceInRouteName: 'Page|Screen,Route')
class AppRouter extends _$AppRouter {
  @override
  RouteType get defaultRouteType => const RouteType.material();

  // TODO: Screens! Also, switch to customRoute for transitions.
  @override
  List<AutoRoute> get routes => [
        AutoRoute(path: "/", page: SplashRoute.page, initial: true),
        AutoRoute(path: "/home", page: HomeRoute.page, initial: false),
        // These should be deep-links.
        AutoRoute(path: "/login", page: LoginRoute.page, initial: false),
        AutoRoute(
            path: "/validate-email",
            page: ValidateEmailChangeRoute.page,
            initial: false),
      ];
}
