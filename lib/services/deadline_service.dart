import '../model/task/deadline.dart';
import '../util/interfaces/deadline_repository.dart';

class DeadLineService {

  static final DeadLineService _instance = DeadLineService._internal();

  late DeadLineRepository _repository;

  set repository(DeadLineRepository repo) => _repository = repo;

  Future<void> createDeadLine(DeadLine d) async => _repository.create(d);
  Future<void> updateDeadLine(DeadLine d) async => _repository.update(d);
  Future<void> updateBatch(List<DeadLine> deadlines) async => _repository.updateBatch(deadlines);
  Future<void> retry(List<DeadLine> deadlines) async => _repository.retry(deadlines);
  Future<void> deleteDeadLine(DeadLine d) async => _repository.delete(d);
  // TODO: Not sure abt showLoading.
  Future<void> syncRepo() async => _repository.syncRepo(showLoading: false);

  Future<List<DeadLine>> getDeadlines() async => _repository.getRepoList();
  // TODO: this may need a covariant override.
  Future<List<DeadLine>> getDeadLinesBy(Sorter<DeadLine> sorter) async => _repository.getRepoListBy(sorter: sorter);

  Future<void> reorderDeadLines(List<DeadLine> deadlines, int oldIndex, int newIndex) async {
    if(oldIndex < newIndex)
      {
        newIndex--;
      }
    DeadLine d = deadlines.removeAt(oldIndex);
    deadlines.insert(newIndex, d);
    for(int i = 0; i < deadlines.length; i++)
      {
        deadlines[i].customViewIndex = i;
      }
    _repository.updateBatch(deadlines);
  }

  DeadLineService._internal();

}