import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class CustomDragStartListener extends ReorderableDragStartListener {
  final Duration delay;

  const CustomDragStartListener(
      {Key? key,
      this.delay = kLongPressTimeout,
      required Widget child,
      required int index,
      bool enabled = true})
      : super(key: key, child: child, index: index, enabled: enabled);

  @override
  MultiDragGestureRecognizer createRecognizer() {
    return DelayedMultiDragGestureRecognizer(delay: delay, debugOwner: this);
  }
}
