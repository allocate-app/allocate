import '../model/task/deadline.dart';
import '../services/isar_service.dart';
import '../services/supabase_service.dart';
import '../util/interfaces/repository.dart';

class DeadlineRepository implements Repository<DeadLine>
{

  late List<DeadLine> _deadlines;
  final IsarService _isarService = IsarService.instance;
  final SupabaseService _supabaseService = SupabaseService.instance;



  @override
  Future<void> create(DeadLine d) {
    // TODO: implement create
    throw UnimplementedError();
  }

  @override
  Future<void> update(DeadLine d) {
    // TODO: implement update
    throw UnimplementedError();
  }

  @override
  Future<void> delete(DeadLine t) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future<void> getRepoList({bool showLoading = true}) {
    // TODO: implement getRepoList
    throw UnimplementedError();
  }

  @override
  Future<void> getRepoListBy() {
    // TODO: implement getRepoListBy
    throw UnimplementedError();
  }
}

