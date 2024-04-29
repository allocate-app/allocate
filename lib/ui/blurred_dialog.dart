import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';

import '../services/application_service.dart';
import '../util/constants.dart';
import 'widgets/windows_titlebar.dart';

final bool isMobile = Platform.isIOS || Platform.isAndroid;

Future<T?> blurredDismissible<T>({
  required BuildContext context,
  required Widget dialog,
  bool keyboardOverlap = true
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
        TitlebarSafeArea(
            child: SafeArea(
                maintainBottomViewPadding: keyboardOverlap,
                child: MediaQuery.removeViewInsets(context: context, removeBottom: keyboardOverlap,child: dialog))),
        if (Platform.isWindows) ...windowsTitlebar(),
        if (isMobile)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).padding.top,
            child: GestureDetector(
                onTap: () {
                  ApplicationService.instance.scrollToTop();
                },
                excludeFromSemantics: true,
                behavior: HitTestBehavior.translucent),
          ),
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
  bool keyboardOverlap = true,
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
        TitlebarSafeArea(
          child: SafeArea(
              maintainBottomViewPadding: keyboardOverlap,
              child: MediaQuery.removeViewInsets(
                context: context,
                removeBottom: keyboardOverlap,
                child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      FocusScope.of(context).unfocus();
                    },
                    // Soft keyboard smooshes the dialog.
                    child: dialog),
              )),
        ),
        if (Platform.isWindows) ...windowsTitlebar(),
        if (isMobile)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).padding.top,
            child: GestureDetector(
                onTap: () {
                  ApplicationService.instance.scrollToTop();
                },
                excludeFromSemantics: true,
                behavior: HitTestBehavior.translucent),
          ),
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
