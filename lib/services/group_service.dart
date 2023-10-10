import '../model/task/group.dart';
import '../repositories/group_repo.dart';
import '../util/interfaces/repository/model/group_repository.dart';
import '../util/interfaces/sortable.dart';

class GroupService {
  //Default repo for now, switch as needed for testing.
  GroupRepository _repository = GroupRepo();

  set repository(GroupRepository repo) => _repository = repo;

  Future<Group> createGroup({required Group group}) async =>
      await _repository.create(group);

  Future<List<Group>> searchGroups({required String searchString}) async =>
      await _repository.search(searchString: searchString);

  Future<List<Group>> getGroups({int limit = 50}) async =>
      await _repository.getRepoList(limit: limit);

  Future<List<Group>> getGroupsBy(
          {required SortableView<Group> sorter,
          int limit = 50,
          int offset = 0}) async =>
      await _repository.getRepoListBy(
          sorter: sorter, limit: limit, offset: offset);

  Future<Group?> getGroupByID({int? id}) async =>
      (null != id) ? await _repository.getByID(id: id) : null;

  Future<List<Group>> mostRecent({int limit = 5}) async =>
      await _repository.mostRecent(limit: limit);

  Future<Group> updateGroup({required Group group}) async =>
      await _repository.update(group);

  Future<void> updateBatch({required List<Group> groups}) async =>
      await _repository.updateBatch(groups);

  Future<void> deleteGroup({required Group group}) async =>
      await _repository.delete(group);

  Future<void> clearDeletesLocalRepo() async => await _repository.deleteLocal();

  Future<void> syncRepo() async => await _repository.syncRepo();

  Future<List<Group>> reorderGroups(
      {required List<Group> groups,
      required int oldIndex,
      required int newIndex}) async {
    if (oldIndex < newIndex) {
      newIndex--;
    }
    Group group = groups.removeAt(oldIndex);
    groups.insert(newIndex, group);
    for (int i = 0; i < groups.length; i++) {
      groups[i].customViewIndex = i;
    }
    await _repository.updateBatch(groups);
    return groups;
  }
}
