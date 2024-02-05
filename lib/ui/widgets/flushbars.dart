import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

import '../../util/constants.dart';

abstract class Flushbars {
  static Flushbar createError({
    required String message,
    required BuildContext context,
    Color? errorColor,
    Color? textColor,
    double? maxWidth,
    double? leftMarginOffset,
    Color? backgroundColor,
    Duration duration =
        const Duration(milliseconds: Constants.snackbarDuration),
    void Function()? dismissCallback,
  }) =>
      Flushbar(
          maxWidth: maxWidth,
          forwardAnimationCurve: Curves.fastEaseInToSlowEaseOut,
          reverseAnimationCurve: Curves.fastEaseInToSlowEaseOut,
          animationDuration:
              const Duration(milliseconds: Constants.snackbarEaseInDuration),
          shouldIconPulse: true,
          message: message,
          flushbarPosition: FlushbarPosition.BOTTOM,
          margin: EdgeInsets.only(
              right: Constants.padding * 1.5,
              left: Constants.padding * 1.5 + (leftMarginOffset ?? 0),
              top: Constants.doublePadding * 1.5,
              bottom: Constants.doublePadding * 1.5),
          padding: const EdgeInsets.all(Constants.padding),
          borderRadius:
              const BorderRadius.all(Radius.circular(Constants.semiCircular)),
          duration: duration,
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          messageColor:
              textColor ?? Theme.of(context).colorScheme.onSecondaryContainer,
          isDismissible: true,
          icon: Icon(
            Icons.error_outline,
            size: 28,
            color: errorColor ?? Constants.errorColor(context: context),
          ),
          mainButton: TextButton(
            onPressed: dismissCallback ??
                () {
                  Navigator.pop(context);
                },
            child: const Text("Dismiss"),
          ));

  static Flushbar createAlert({
    required String message,
    required BuildContext context,
    Color? alertColor,
    Color? textColor,
    double? maxWidth,
    double? leftMarginOffset,
    Color? backgroundColor,
    Duration duration =
        const Duration(milliseconds: Constants.snackbarDuration),
    void Function()? dismissCallback,
  }) =>
      Flushbar(
          maxWidth: maxWidth,
          forwardAnimationCurve: Curves.fastEaseInToSlowEaseOut,
          reverseAnimationCurve: Curves.fastEaseInToSlowEaseOut,
          animationDuration:
              const Duration(milliseconds: Constants.snackbarEaseInDuration),
          shouldIconPulse: true,
          message: message,
          flushbarPosition: FlushbarPosition.BOTTOM,
          margin: EdgeInsets.only(
              right: Constants.padding * 1.5,
              left: Constants.padding * 1.5 + (leftMarginOffset ?? 0),
              top: Constants.doublePadding * 1.5,
              bottom: Constants.doublePadding * 1.5),
          padding: const EdgeInsets.all(Constants.padding),
          borderRadius:
              const BorderRadius.all(Radius.circular(Constants.semiCircular)),
          duration: duration,
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          messageColor:
              textColor ?? Theme.of(context).colorScheme.onSecondaryContainer,
          isDismissible: true,
          icon: Icon(
            Icons.error_outline,
            size: 28,
            color: alertColor ?? Theme.of(context).colorScheme.primary,
          ),
          mainButton: TextButton(
            onPressed: dismissCallback ??
                () {
                  Navigator.pop(context);
                },
            child: const Text("Dismiss"),
          ));
}
