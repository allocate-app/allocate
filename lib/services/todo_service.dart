import 'package:flutter/foundation.dart';
import '../model/task/todo.dart';
import '../util/numbers.dart';

class ToDoService with ChangeNotifier
{
  // This may actually be able to stay.
  Duration realDuration(ToDo t) {
    num factor = smoothstep(x: t.weight, v0: 1, v1: 10);
    return Duration(seconds: (t.expectedDuration * factor) as int);
  }
}