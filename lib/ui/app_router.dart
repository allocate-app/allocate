import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";

import "views/routes.dart";

part "app_router.gr.dart";

// This app uses tabbed routing -> Only one routepage is required.
@AutoRouterConfig(replaceInRouteName: 'Page|Screen,Route')
class AppRouter extends _$AppRouter {
  @override
  RouteType get defaultRouteType => const RouteType.material();

  @override
  List<AutoRoute> get routes => [
        AutoRoute(path: "/", page: SplashRoute.page, initial: true),
        AutoRoute(path: "/home", page: HomeRoute.page, initial: false),
      ];
}
