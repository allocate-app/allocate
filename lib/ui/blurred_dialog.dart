import 'dart:io';
import 'dart:ui';

import 'package:allocate/ui/widgets/windows_titlebar.dart';
import 'package:flutter/material.dart';

import '../util/constants.dart';

Future<T?> blurredDismissible<T>({
  required BuildContext context,
  required Widget dialog,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: "",
    useRootNavigator: false,
    transitionDuration: const Duration(milliseconds: Constants.blurDuration),
    pageBuilder: (BuildContext context, Animation<double> animation,
        Animation<double> secondaryAnimation) {
      // There does not seem to be a way to skirt the barrier for the windows taskbar.

      return Stack(children: [
        SafeArea(child: dialog),
        if (Platform.isWindows) ...windowsTitlebar(),
      ]);
    },
    transitionBuilder: (BuildContext context, Animation<double> animation,
        Animation<double> secondaryAnimation, Widget? child) {
      return BackdropFilter(
          filter: ImageFilter.blur(
              sigmaX: Constants.overlayBlur * animation.value,
              sigmaY: Constants.overlayBlur * animation.value),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ));
    },
  );
}

Future<T?> blurredNonDismissible<T>({
  required BuildContext context,
  required Widget dialog,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: false,
    barrierLabel: "",
    useRootNavigator: false,
    transitionDuration: const Duration(milliseconds: Constants.blurDuration),
    pageBuilder: (BuildContext context, Animation<double> animation,
        Animation<double> secondaryAnimation) {
      return Stack(children: [
        SafeArea(
            child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: dialog)),
        if (Platform.isWindows) ...windowsTitlebar(),
      ]);
    },
    transitionBuilder: (BuildContext context, Animation<double> animation,
        Animation<double> secondaryAnimation, Widget? child) {
      return BackdropFilter(
          filter: ImageFilter.blur(
              sigmaX: Constants.overlayBlur * animation.value,
              sigmaY: Constants.overlayBlur * animation.value),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ));
    },
  );
}
