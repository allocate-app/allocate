import '../model/task/group.dart';
import '../repositories/group_repo.dart';
import '../util/interfaces/repository/group_repository.dart';
import '../util/interfaces/sorting/sortable.dart';

class GroupService {
  //Default repo for now, switch as needed for testing.
  GroupRepository _repository = GroupRepo();

  set repository(GroupRepository repo) => _repository = repo;

  Future<void> createGroup({required Group group}) async =>
      _repository.create(group);

  Future<List<Group>> getGroups() async => _repository.getRepoList();
  Future<List<Group>> getGroupsBy(
          {required SortableView<Group> sorter}) async =>
      _repository.getRepoListBy(sorter: sorter);

  Future<void> updateGroup({required Group group}) async =>
      _repository.update(group);
  Future<void> updateBatch({required List<Group> groups}) async =>
      _repository.updateBatch(groups);

  Future<void> deleteGroup({required Group group}) async =>
      _repository.delete(group);

  Future<void> retry({required List<Group> groups}) async =>
      _repository.retry(groups);

  Future<void> syncRepo() async => _repository.syncRepo();

  Future<void> reorderGroups(
      {required List<Group> groups,
      required int oldIndex,
      required int newIndex}) async {
    if (oldIndex < newIndex) {
      newIndex--;
    }
    Group r = groups.removeAt(oldIndex);
    groups.insert(newIndex, r);
    for (int i = 0; i < groups.length; i++) {
      groups[i].customViewIndex = i;
    }
    _repository.updateBatch(groups);
  }
}
