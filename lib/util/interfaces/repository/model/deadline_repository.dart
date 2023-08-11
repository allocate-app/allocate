import '../../../../model/task/deadline.dart';
import '../function/overdue.dart';
import '../function/repeatable.dart';
import '../function/repository.dart';
import '../function/search.dart';

abstract interface class DeadlineRepository
    implements Repository<Deadline>, Repeatable<Deadline>, Overdue<Deadline>, Search<Deadline> {}
