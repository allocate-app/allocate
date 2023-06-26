enum Theme{light, dark}

// TODO: refactor back into user class?
class UserPrefs
{
  Theme theme;
  bool sync;
  UserPrefs({this.theme = Theme.dark, this.sync = false});


}
