import 'dart:async';
import 'package:flutter/foundation.dart';
import '../user/user.dart';
import "../user/userprefs.dart";
import '../util/numbers.dart';
class UserViewModel extends ChangeNotifier
{
  static const minBandwidth = 0;
  static const maxBandwidth = 150;

  User _user;
  UserPrefs _userPrefs;

  UserViewModel({required User user, required UserPrefs userPrefs}) : _user = user, _userPrefs = userPrefs;

  User get user => _user;
  // TODO: ASYNC user and userPrefs
  set user(User newUser)
  {
    _user = newUser;
    notifyListeners();
  }
  UserPrefs get userPrefs => _userPrefs;
  set userPrefs(UserPrefs newPref)
  {
    _userPrefs = newPref;
    notifyListeners();
  }
  // User model stuff > may need to be refactored out.
  String? get firstName => _user.firstName;
  String? get lastName => _user.lastName;
  String? get userName => _user.userName;
  int? get userId => _user.userID;
  DateTime? get birthday => _user.birthday;


  int get dayBandwidth => _user.dayBandwidth;
  int get bandwidth => _user.bandwidth;
  set bandwidth(int newBandwidth)
  {
    if(newBandwidth > maxBandwidth || newBandwidth < minBandwidth)
    {
      // TODO: implement.
      throw Error();
    }
    _user.dayBandwidth = remap(x: _user.dayBandwidth, inMin: 0, inMax: user.bandwidth, outMin: 0, outMax: newBandwidth).round();
    _user.bandwidth = newBandwidth;
    notifyListeners();
  }

  bool get inMeltdown => _user.inMeltdown;
  set inMeltDown(bool isInMeltdown)
  {
    _user.inMeltdown = isInMeltdown;
    notifyListeners();
  }

  // UserPrefs getset
  Theme get theme => _userPrefs.theme;
  set theme(Theme newTheme)
  {
    _userPrefs.theme = newTheme;
    notifyListeners();
  }

  bool get sync => _userPrefs.sync;
  set sync(bool toSync)
  {
    _userPrefs.sync = toSync;
    notifyListeners();
  }

  void spend(int cost)
  {
    if(cost > _user.dayBandwidth)
      {
        // TODO: handle properly, this should never happen.
        throw Error();
      }
    _user.dayBandwidth -= cost;
    notifyListeners();
    checkBreak();
  }
  void checkBreak()
  {
    if(_user.dayBandwidth % (_user.bandwidth~/4) == 0)
      {
        // This should fire a notification in the gui.
        // TODO: implement.
      }
  }


  void happyBirthday()
  {
    //TODO: Learn async programming and finish this.
    /// Intended behaviour:
    /// This should have some sort of listener that fires
    /// on the user's birthday. Nothing too flashy, just
    /// a notification & maybe a GUI thingy.
  }

}
