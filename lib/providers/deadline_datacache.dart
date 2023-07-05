import '../model/task/deadline.dart';
import '../util/interfaces/datacache.dart';

class DeadLineDataCache implements DataCache<DeadLine>
{
  static final DeadLineDataCache _instance = DeadLineDataCache._internal();
  static DeadLineDataCache get instance => _instance;

  @override
  late DeadLine current;

  @override
  List<DeadLine> currents = List.empty(growable:false);

  @override
  final List<DeadLine> cache = List.empty(growable: true);

  DeadLineDataCache._internal();

}