import '../../../model/task/deadline.dart';
import 'repository.dart';

abstract interface class DeadlineRepository implements Repository<Deadline> {
  Future<List<Deadline>> getOverdues();
}
