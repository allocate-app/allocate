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
  BrainState curBrainState;
  late Timer curTimer;

  User({this.firstName, this.lastName, this.userName, this.userID, this.birthday, this.theme = Theme.dark, this.curBrainState = BrainState.okay});

  int get eBandwidth => _eBandwidth;
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
  int get dayBandwidth => _dayBandwidth;

  // Sets current break to remap proportionally in case it is changed during break time.
  int get breakTime => _breakTime;
  set breakTime(int val)
  {
    int oldBreak = _breakTime;
    _breakTime = val;
    _curBreak = remap(_curBreak, oldBreak, _breakTime);

  }
  int get curBreak => _curBreak;

  // General remap (x, inMin, inMax, outMin, outMax) => x * (outMax-outMin) / (inMax - inMin) + outMin;
  // Using zeroes for min.
  int remap(int curVal, int inputMax, int outputMax)
  {
    // lol, slope * oldVal +
    num newBandwidth = (outputMax / inputMax) * curVal;
    return newBandwidth.round();
  }
  void spend(int cost)
  {
    // This should never happen. Consider removing after handling UI.
    if(cost > _dayBandwidth)
      {
        throw Error();
      }
    _dayBandwidth -= cost;
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
  // This should likely be an event.
  void checkBreak()
  {
    if(_dayBandwidth % (_eBandwidth~/4) == 0)
      {
        curBrainState = BrainState.breakTime;
        // It would also be good if I called the function.
        countSeconds();
      }
  }

  // Slightly unfamiliar with async programming.
  // This should probably hook into the UI in some fashion.
  void countSeconds()
  {
    curTimer = Timer.periodic(const Duration(seconds: 1), (timer)
    {
     _curBreak --;
     if(_curBreak <= 0 || curBrainState == BrainState.burnOut)
       {
         curBrainState = (curBrainState == BrainState.burnOut) ? BrainState.burnOut : BrainState.okay;
         _curBreak = _breakTime;
         timer.cancel();
       }
     // TODO: When UI, update here.
    }
    );
  }

}