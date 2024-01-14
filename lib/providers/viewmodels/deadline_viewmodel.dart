import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../model/task/deadline.dart';
import '../../util/interfaces/view_model.dart';

class DeadlineViewModel extends ChangeNotifier
    with EquatableMixin
    implements ViewModel<Deadline> {
  @override
  void fromModel({required Deadline model}) {
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
  Deadline toModel() {
    // TODO: implement toModel
    throw UnimplementedError();
  }
}
