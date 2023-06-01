import "dart:async";
// Add as needed. Extend in UI class to dynamically modulate widget themes.
// Move this enum where it is most appropriate.
enum Theme{light, dark}

// No tasks during burnout.
enum BrainState{okay, breakTime, burnOut}
class User
{
  // This may be better handled within UI.
  static const MIN_BANDWIDTH = 0;
  static const MAX_BANDWIDTH = 150;
  // These could probably go. Keeping for now.
  String? firstName;
  String? lastName;
  // Kinda cheesy, but this is for me.
  DateTime? birthday;

  String? userName;
  // PWD in main.
  int? userID;
  int _eBandwidth = 100;
  int _dayBandwidth = 100;

  // in seconds.
  int _breakTime = 600;
  int _curBreak = 600;

  Theme theme = Theme.dark;
  // Assume the user is okay when they first create a profile.
  BrainState curBrainState = BrainState.okay;

  User(this.firstName, this.lastName, this.userName, this.userID, this.birthday, this.theme, this.curBrainState);

  // Return to this
  set eBandwidth(int val)
  {
    int oldBandwidth = _eBandwidth;
    if(val > MAX_BANDWIDTH)
      {
        // Return to this and reconsider.
        throw Error();
      }
    _eBandwidth = val;
    _dayBandwidth = remap(_dayBandwidth, oldBandwidth, _eBandwidth);
  }
  // Sets current break to remap proportionally in case it is changed during break time.
  set breakTime(int val)
  {
    int oldBreak = _breakTime;
    _breakTime = val;
    _curBreak = remap(_curBreak, oldBreak, _breakTime);

  }
  // General remap (x, inMin, inMax, outMin, outMax) => x * (outMax-outMin) / (inMax - outMax) + outMin;
  // Using zeroes for min.
  int remap(int curVal, int inputMax, int outputMax)
  {
    // lol, slope * oldVal +
    num newBandwidth = (outputMax / inputMax) * curVal;
    return (0.5 + newBandwidth) as int;
  }
  void spend(int cost)
  {
    // This should never happen. Consider removing after handling UI.
    if(cost > _eBandwidth)
      {
        throw Error();
      }
    _eBandwidth -= cost;
    checkBreak();
  }

  // This should likely have some sort of notification.
  void happyBirthday()
  {
    // HAPPY BIRTHDAY! => Widget animation.
    // TODO: Refactor this into the program app;
    // This should be handled within a controller.
  }

  // Hook this into UI > notify user to take a break.
  void checkBreak()
  {
    if(_dayBandwidth % (_eBandwidth~/4) == 0)
      {
        curBrainState = BrainState.breakTime;
      }
  }

  // Slightly unfamiliar with async programming.
  // This should probably hook into the UI in some fashion.
  void countSeconds()
  {
    late Timer countDown = Timer.periodic(const Duration(seconds: 1), (timer)
    {
     _curBreak --;
     if(_curBreak <= 0 || curBrainState == BrainState.burnOut)
       {
         timer.cancel();
         curBrainState = (curBrainState == BrainState.burnOut) ? BrainState.burnOut : BrainState.okay;
         _curBreak = _breakTime;
       }
    }
    );
  }

}