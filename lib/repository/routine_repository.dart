import 'package:allocate/services/isar_service.dart';
import 'package:flutter/foundation.dart';
import '../main.dart';
import '../model/task/routine.dart';
import '../services/supabase_service.dart';
import '../util/interfaces/repository.dart';

// Repositories should be a singleton?
// Dependency Injection?
class RoutineRepository with ChangeNotifier implements Repository<Routine> {

  late List<Routine> _routines;

  // This should call a singleton.
  final IsarService _isarService = IsarService.instance;
  final SupabaseService _supabaseService = SupabaseService.instance;

  @override
  Future<void> create(Routine routine) async
  {
    routine.isSynced = isDeviceConnected.value;
    int? id = await _isarService.insertOneRoutine(routine);
    if(null == id)
    {
      throw FailureToCreateException("Failed to save Routine");
    }
    routine.id = id;
    // Add to list?
    // Should there really be a list?
    // Why not just grab from the database on each view?
    if(isDeviceConnected.value)
    {
      id = await _supabaseService.insertOneRoutine(routine.toEntity());
      if(null == id)
      {
        throw FailureToUploadException("Failed to Sync routine");
      }
    }
    notifyListeners();
  }

  @override
  Future<void> update(Routine routine) async
  {

  }



  @override
  Future<void> delete(Routine routine) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future<void> getRepoList({bool showLoading = true}) async {
    // This needs refactoring to work with a loading widget.
    // showLoading ? startLoading() : null;
    _routines = [];

    await Future.delayed(const Duration(seconds: 1)).then((value) async
    {
      if(isDeviceConnected.value)
        {
          _routines = await _supabaseService.getRoutines();
          IsarService.instance.insertFreshRoutines(_routines);
        }
      else
        {
          _routines = await IsarService.instance.getRoutines();
        }
    });

    //stopLoading();

    // This should have a callback that gets the repo list by sort.
    notifyListeners();
  }

  @override
  Future<void> getRepoListBy() {
    // TODO: implement getRepoListBy
    throw UnimplementedError();
  }

}

// These can be factored out into an exceptions class
class FailureToCreateException implements Exception {
  String cause;
  FailureToCreateException(this.cause);
}
class FailureToUploadException implements Exception{
  String cause;
  FailureToUploadException(this.cause);
}
