import '../model/task/group.dart';
import '../repositories/group_repo.dart';
import '../util/interfaces/repository/model/group_repository.dart';
import '../util/interfaces/sortable.dart';

class GroupService {
  //Default repo for now, switch as needed for testing.
  GroupRepository _repository = GroupRepo();

  set repository(GroupRepository repo) => _repository = repo;

  Future<void> createGroup({required Group group}) async => _repository.create(group);

  Future<List<Group>> searchGroups({required String searchString}) async =>
      _repository.search(searchString: searchString);

  Future<List<Group>> getGroups({int limit = 50}) async => _repository.getRepoList(limit: limit);
  Future<List<Group>> getGroupsBy(
          {required SortableView<Group> sorter, int limit = 50, int offset = 0}) async =>
      _repository.getRepoListBy(sorter: sorter, limit: limit, offset: offset);

  Future<Group?> getGroupByID({required int id}) => _repository.getByID(id: id);

  Future<List<Group>> mostRecent({int limit = 5}) async => _repository.mostRecent(limit: limit);

  Future<void> updateGroup({required Group group}) async => _repository.update(group);
  Future<void> updateBatch({required List<Group> groups}) async => _repository.updateBatch(groups);

  Future<void> deleteGroup({required Group group}) async => _repository.delete(group);

  Future<void> clearDeletesLocalRepo() async => _repository.deleteLocal();

  Future<void> syncRepo() async => _repository.syncRepo();

  Future<void> reorderGroups(
      {required List<Group> groups, required int oldIndex, required int newIndex}) async {
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
