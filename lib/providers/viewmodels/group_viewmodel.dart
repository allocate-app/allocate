import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../model/task/group.dart';
import '../../util/interfaces/view_model.dart';

class GroupViewModel extends ChangeNotifier
    with EquatableMixin
    implements ViewModel<Group> {
  @override
  void fromModel({required Group model}) {
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
  Group toModel() {
    // TODO: implement toModel
    throw UnimplementedError();
  }
}
