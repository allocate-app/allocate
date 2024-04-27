import 'package:flutter/material.dart';

import '../ui/app_router.dart';
import '../util/constants.dart';

class ApplicationService extends ChangeNotifier {
  static final ApplicationService _instance = ApplicationService._internal();

  static ApplicationService get instance => _instance;

  static final AppRouter _appRouter = AppRouter();

  AppRouter get appRouter => _appRouter;

  static int? _initialStartingIndex;

  void scrollToTop() => notifyListeners();

  // This can be null
  set initialPageIndex(int? index) {
    if (null != index &&
        (index > Constants.viewRoutes.length - 1 || index < 0)) {
      return;
    }
    _initialStartingIndex = index;
  }

  int? get initialPageIndex => _initialStartingIndex;

  // This is req'd for handling major errors, eg. multiple users existing, missing user, etc.
  GlobalKey<NavigatorState> get globalNavigatorKey => _appRouter.navigatorKey;

  ApplicationService._internal();
}
