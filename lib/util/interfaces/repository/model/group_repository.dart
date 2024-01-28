import 'package:flutter/foundation.dart';

import '../../../../model/task/group.dart';
import '../function/repository.dart';
import '../function/search.dart';

abstract class GroupRepository extends ChangeNotifier
    implements Repository<Group>, Search<Group> {}
