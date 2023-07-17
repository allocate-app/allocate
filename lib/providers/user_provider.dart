import 'package:flutter/foundation.dart';

import '../model/user/user.dart';
import '../services/user_storage_service.dart';

class UserProvider extends ChangeNotifier {
  UserProvider();

  final _userStorageService = UserStorageService();

  late User curUser;
}
