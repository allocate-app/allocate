import '../model/task/deadline.dart';
import '../repositories/deadline_repo.dart';
import '../util/interfaces/repository/deadline_repository.dart';
import '../util/interfaces/sorting/sortable.dart';

class DeadlineService {
  // This is just default. Switch as needed.
  DeadlineRepository _repository = DeadlineRepo();

  set repository(DeadlineRepository repo) => _repository = repo;

  Future<void> createDeadline({required Deadline deadline}) async =>
      _repository.create(deadline);

  Future<List<Deadline>> getDeadlines() async => _repository.getRepoList();
  Future<List<Deadline>> getDeadlinesBy(
          {required SortableView<Deadline> sorter}) async =>
      _repository.getRepoListBy(sorter: sorter);
  Future<List<Deadline>> getOverdues() async => _repository.getOverdues();

  Future<void> updateDeadline({required Deadline deadline}) async =>
      _repository.update(deadline);
  Future<void> updateBatch({required List<Deadline> deadlines}) async =>
      _repository.updateBatch(deadlines);

  Future<void> deleteDeadline({required Deadline deadline}) async =>
      _repository.delete(deadline);
  // TODO: Not sure abt showLoading.
  Future<void> retry({required List<Deadline> deadlines}) async =>
      _repository.retry(deadlines);
  // TODO: Figure out how to call this on a timer.
  Future<void> syncRepo() async => _repository.syncRepo();

  Future<void> reorderDeadlines(
      {required List<Deadline> deadlines,
      required int oldIndex,
      required int newIndex}) async {
    if (oldIndex < newIndex) {
      newIndex--;
    }
    Deadline d = deadlines.removeAt(oldIndex);
    deadlines.insert(newIndex, d);
    for (int i = 0; i < deadlines.length; i++) {
      deadlines[i].customViewIndex = i;
    }
    _repository.updateBatch(deadlines);
  }
}
