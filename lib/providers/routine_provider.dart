import 'dart:developer';

import 'package:flutter/foundation.dart';
import '../services/routine_service.dart';
/// NOTE CHANGE DIRECTORY.
import "../model/task/routine.dart";
import "../util/exceptions.dart";

class RoutineProvider extends ChangeNotifier{
  final RoutineService _routineService = RoutineService.instance;

  late Routine curRoutine;

  // ref.watch(RoutineProvider).

  Future<void> createRoutine(Routine r) async
  {
    // Possibly create the routine => here.
    // Accept args from text val.
    try{
      _routineService.createRoutine(r);
    }
    on FailureToCreateException catch (e)
    {
      // Some sort of error widget.
      log(e.cause);
    }
    on FailureToUploadException catch (e)
    {
      log(e.cause);
    }

    // Some sort of success widget & move to edit view mb?
    notifyListeners();
  }

  Future<List<Routine>> getRoutines() async => _routineService.getRoutines();


}