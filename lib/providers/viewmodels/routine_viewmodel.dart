import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../../model/task/routine.dart';
import '../../util/interfaces/view_model.dart';

class RoutineViewModel extends ChangeNotifier
    with EquatableMixin
    implements ViewModel<Routine> {
  @override
  void fromModel({required Routine model}) {
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
  Routine toModel() {
    // TODO: implement toModel
    throw UnimplementedError();
  }
}
