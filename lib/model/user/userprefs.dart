enum Theme{light, dark}

class UserPrefs
{
  Theme theme;
  bool sync;
  UserPrefs({this.theme = Theme.dark, this.sync = false});


}
