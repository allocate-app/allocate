import '../model/task/routine.dart';
import '../util/interfaces/datacache.dart';

class RoutineDataCache implements DataCache<Routine>
{
  static final RoutineDataCache _instance = RoutineDataCache._internal();
  static RoutineDataCache get instance => _instance;

  @override
  late Routine current;
  @override
  List<Routine> currents = List.empty(growable: true);
  @override
  final List<Routine> cache = List.empty(growable: true);

  RoutineDataCache._internal();

}