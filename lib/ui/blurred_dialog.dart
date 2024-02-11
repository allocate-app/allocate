import 'dart:ui';

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
      return SafeArea(child: GestureDetector(
          onTap:(){
            FocusScope.of(context).unfocus();
          },
          child: dialog));
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
      return SafeArea(child: GestureDetector(
          onTap: (){
            FocusScope.of(context).unfocus();
          },
          child: dialog));
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
