import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class CustomDragStartListener extends ReorderableDragStartListener {
  final Duration delay;

  const CustomDragStartListener(
      {super.key,
      this.delay = kLongPressTimeout,
      required super.child,
      required super.index,
      super.enabled});

  @override
  MultiDragGestureRecognizer createRecognizer() {
    return DelayedMultiDragGestureRecognizer(delay: delay, debugOwner: this);
  }
}
