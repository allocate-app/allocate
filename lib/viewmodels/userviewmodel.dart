import 'package:flutter/foundation.dart';
import '../user/user.dart';
import '../util/numbers.dart';
class UserViewModel extends ChangeNotifier
{
  static const minBandwidth = 0;
  static const maxBandwidth = 150;

  User _user;
  int _dayBandwidth = 100;
  int _curBreak = 600;
  UserViewModel({required User user}) : _user = user, _dayBandwidth = user.eBandwidth, _curBreak = user.breakTime;

  User get user => _user;
  // ASYNC.
  set user(User newUser)
  {
    _user = newUser;
    notifyListeners();
  }

  int get dayBandwidth => _dayBandwidth;
  int get bandwidth => _user.eBandwidth;
  set bandwidth(int newBandwidth)
  {
    if(newBandwidth > maxBandwidth || newBandwidth < minBandwidth)
    {
      // TODO: implement.
      throw Error();
    }
    _dayBandwidth = remap(x: _dayBandwidth, inMin: 0, inMax: user.eBandwidth, outMin: 0, outMax: newBandwidth).round();
    _user.eBandwidth = newBandwidth;
    notifyListeners();
  }


  int get breakTime => _user.breakTime;
  set breakTime(int newBreak)
  {
    _curBreak = remap(x:_curBreak, inMin: 0, inMax: user.breakTime, outMin: 0, outMax: newBreak).round();
    _user.breakTime = newBreak;
    notifyListeners();
  }
}