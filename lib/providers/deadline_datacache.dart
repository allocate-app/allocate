import '../model/task/deadline.dart';
import '../util/interfaces/datacache.dart';

class DeadLineDataCache implements DataCache<Deadline>
{
  static final DeadLineDataCache _instance = DeadLineDataCache._internal();
  static DeadLineDataCache get instance => _instance;

  @override
  late Deadline current;

  @override
  List<Deadline> currents = List.empty(growable:false);

  @override
  final List<Deadline> cache = List.empty(growable: true);

  DeadLineDataCache._internal();

}