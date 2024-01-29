import '../../../constants.dart';
import '../../i_model.dart';

abstract interface class LocalNotifications<T extends IModel> {
  Future<List<T>> getWarnMes(
      {DateTime? now, int limit = Constants.notificationLimit});
}
