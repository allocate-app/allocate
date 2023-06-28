import 'package:flutter/foundation.dart';

import '../model/task/deadline.dart';
import '../repository/deadline_repository.dart';

class DeadLineService extends ChangeNotifier{

  /// TODO: Unimplemented Crud
  final DeadlineRepository _repository;
  DeadLineService(this._repository);

  Future<void> saveDeadline(DeadLine d) async => _repository.create(d);
}