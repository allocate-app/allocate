import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

import '../../util/constants.dart';

class Flushbars {
  static Flushbar createError({
    required String message,
    required BuildContext context,
    Color? errorColor,
    Color? textColor,
    // Return to this later.
    // Color? actionColor,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    void Function()? dismissCallback,
  }) =>
      Flushbar(
        // TODO: Abstract to constants class.
        animationDuration: const Duration(milliseconds: 300),
          message: message,
          flushbarPosition: FlushbarPosition.TOP,
          // TODO: Add margins to constants class.
          margin: const EdgeInsets.all(Constants.padding),
          padding: const EdgeInsets.all(Constants.padding),
          borderRadius:
              const BorderRadius.all(Radius.circular(Constants.roundedCorners)),
          duration: duration,
          backgroundColor: backgroundColor ??
              Theme.of(context).snackBarTheme.backgroundColor ??
              const Color(0xFF323232),
          messageColor: textColor,
          isDismissible: true,
          icon: Icon(
            Icons.error_outline,
            // TODO: possibly move to constants class.
            size: 28,
            color: errorColor ?? Constants.errorColor(context: context),
          ),
          mainButton: TextButton(
            onPressed: dismissCallback,
            child: const Text("Dismiss"),
          ));
}
