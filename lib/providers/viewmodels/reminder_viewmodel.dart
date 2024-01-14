import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../model/task/reminder.dart';
import '../../util/interfaces/view_model.dart';

class ReminderViewModel extends ChangeNotifier
    with EquatableMixin
    implements ViewModel<Reminder> {
  @override
  void fromModel({required Reminder model}) {
    // TODO: implement fromModel
  }
  @override
  void clear() {
    // TODO: implement clear
  }

  @override
  // TODO: implement props
  List<Object?> get props => throw UnimplementedError();

  @override
  Reminder toModel() {
    // TODO: implement toModel
    throw UnimplementedError();
  }
}
