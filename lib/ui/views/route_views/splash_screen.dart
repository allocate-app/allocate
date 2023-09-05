// TODO: Rebuild this once home screen finished.
// import "dart:developer";
// import "dart:io";
//
// import "package:auto_route/auto_route.dart";
// import "package:flutter/material.dart";
// import "package:provider/provider.dart";
// import "package:supabase_flutter/supabase_flutter.dart" hide Provider, User;
//
// import '../../../model/user/user.dart';
// import '../../../providers/user_provider.dart';
// import '../../../util/exceptions.dart';
// import '../../../util/interfaces/crossbuild.dart';
// import '../../app_router.dart';
//
// @RoutePage()
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({Key? key}) : super(key: key);
//
//   @override
//   State<SplashScreen> createState() => _SplashScreen();
// }
//
// class _SplashScreen extends State<SplashScreen> implements CrossBuild {
//   @override
//   void initState() {
//     super.initState();
//
//     final UserProvider userProvider =
//         Provider.of<UserProvider>(context, listen: false);
//
//     // Load Session
//     Future.wait([
//       SupabaseAuth.instance.initialSession,
//       userProvider.loadedUser,
//       Future.delayed(const Duration(milliseconds: 2000)),
//     ]).then((responseList) {
//       final Session? session = responseList.first;
//
//       // Grab user.
//       User? user = userProvider.curUser ?? responseList[1];
//
//       if (null == user) {
//         return context.router.replace(const InitUserRoute());
//       }
//
//       return context.router.replace((null == session && user.syncOnline)
//           ? LoginRoute()
//           : HomeRoute());
//     }).catchError((e) {
//       UserException userException = e as UserException;
//       log(userException.cause);
//       return context.router.replace((null == userProvider.curUser)
//           ?  InitUserRoute()
//           :  HomeRoute());
//     }, test: (e) => e is UserException).catchError((e) {
//       log(e.toString());
//       return context.router.replace( HomeRoute());
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (Platform.isAndroid || Platform.isIOS) {
//       return buildMobile(context: context);
//     } else {
//       return buildDesktop(context: context);
//     }
//   }
//
//   @override
//   Widget buildMobile({required BuildContext context}) {
//     // HAVE TO IMPLEMENT
//     return Scaffold();
//   }
//
//   @override
//   Widget buildDesktop({required BuildContext context}) {
//     // HAVE TO IMPLEMENT
//     return Scaffold();
//   }
// }
