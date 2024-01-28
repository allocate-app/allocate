import 'package:flutter/foundation.dart';

import '../../../../model/task/routine.dart';
import '../function/repository.dart';
import '../function/search.dart';

abstract interface class RoutineRepository extends ChangeNotifier
    implements Repository<Routine>, Search<Routine> {}
