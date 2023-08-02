import '../../../model/task/deadline.dart';
import 'repository.dart';

abstract interface class DeadlineRepository implements Repository<Deadline> {
  Future<List<Deadline>> getRepeatables({required DateTime now});
  Future<List<Deadline>> getOverdues();
  Future<void> deleteFutures({required Deadline deadline});
}
