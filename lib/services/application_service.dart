import 'package:flutter/material.dart';

import '../ui/app_router.dart';

class ApplicationService {
  static final ApplicationService _instance = ApplicationService._internal();

  static ApplicationService get instance => _instance;

  static final AppRouter _appRouter = AppRouter();

  AppRouter get appRouter => _appRouter;

  // This is req'd for handling major errors, eg. multiple users existing, missing user, etc.
  GlobalKey<NavigatorState> get globalNavigatorKey => _appRouter.navigatorKey;

  ApplicationService._internal();
}
