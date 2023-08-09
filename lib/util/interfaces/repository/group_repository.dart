import '../../../model/task/group.dart';
import 'repository.dart';

abstract class GroupRepository implements Repository<Group> {
  Future<List<Group>> searchGroups({required String searchString});
  Future<List<Group>> mostRecent({int limit = 5});
}
