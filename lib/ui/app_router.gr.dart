// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

abstract class _$AppRouter extends RootStackRouter {
  // ignore: unused_element
  _$AppRouter({super.navigatorKey});

  @override
  final Map<String, PageFactory> pagesMap = {
    CreateUserRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const CreateUserScreen(),
      );
    },
    HomeRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const HomeScreen(),
      );
    },
    InitUserRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const InitUserScreen(),
      );
    },
    LoginRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const LoginScreen(),
      );
    },
    SignUpRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const SignUpScreen(),
      );
    },
    SplashRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const SplashScreen(),
      );
    },
    UpdateEmailRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const UpdateEmailScreen(),
      );
    },
    UpdatePasswordRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const UpdatePasswordScreen(),
      );
    },
  };
}

/// generated route for
/// [CreateUserScreen]
class CreateUserRoute extends PageRouteInfo<void> {
  const CreateUserRoute({List<PageRouteInfo>? children})
      : super(
          CreateUserRoute.name,
          initialChildren: children,
        );

  static const String name = 'CreateUserRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [HomeScreen]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [InitUserScreen]
class InitUserRoute extends PageRouteInfo<void> {
  const InitUserRoute({List<PageRouteInfo>? children})
      : super(
          InitUserRoute.name,
          initialChildren: children,
        );

  static const String name = 'InitUserRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [LoginScreen]
class LoginRoute extends PageRouteInfo<void> {
  const LoginRoute({List<PageRouteInfo>? children})
      : super(
          LoginRoute.name,
          initialChildren: children,
        );

  static const String name = 'LoginRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [SignUpScreen]
class SignUpRoute extends PageRouteInfo<void> {
  const SignUpRoute({List<PageRouteInfo>? children})
      : super(
          SignUpRoute.name,
          initialChildren: children,
        );

  static const String name = 'SignUpRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [SplashScreen]
class SplashRoute extends PageRouteInfo<void> {
  const SplashRoute({List<PageRouteInfo>? children})
      : super(
          SplashRoute.name,
          initialChildren: children,
        );

  static const String name = 'SplashRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [UpdateEmailScreen]
class UpdateEmailRoute extends PageRouteInfo<void> {
  const UpdateEmailRoute({List<PageRouteInfo>? children})
      : super(
          UpdateEmailRoute.name,
          initialChildren: children,
        );

  static const String name = 'UpdateEmailRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [UpdatePasswordScreen]
class UpdatePasswordRoute extends PageRouteInfo<void> {
  const UpdatePasswordRoute({List<PageRouteInfo>? children})
      : super(
          UpdatePasswordRoute.name,
          initialChildren: children,
        );

  static const String name = 'UpdatePasswordRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}
