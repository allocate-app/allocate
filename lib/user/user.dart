import "dart:async";
import "../util/numbers.dart";
// Add as needed. Extend in UI class to dynamically modulate widget themes.
// TODO: Move this enum where it is most appropriate.

// TODO: refactor User class behaviour to a UserViewModel.
enum Theme{light, dark}

// No tasks during burnout.
enum BrainState{okay, breakTime, burnOut}
class User
{

  // These could probably go. Keeping for now.
  String? firstName;
  String? lastName;
  // Kinda cheesy, but this is for me.
  DateTime? birthday;

  String? userName;
  // PWD in main.
  int? userID;
  int eBandwidth = 100;

  // in seconds.
  int breakTime = 600;

  Theme theme = Theme.dark;
  // Assume the user is okay when they first create a profile.
  BrainState curBrainState;
  late Timer curTimer;

  User({this.firstName, this.lastName, this.userName, this.userID, this.birthday, this.theme = Theme.dark, this.curBrainState = BrainState.okay});

  // TODO: move to viewmodel.
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