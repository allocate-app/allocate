import "package:test/test.dart";
import "../user/user.dart";
import "package:fake_async/fake_async.dart";

void main()
{
  group("User Tests CLI", ()
  {
    test("Bandwidth Remap", ()
        {
          User user = User();
          user.eBandwidth = 150;
          expect(user.eBandwidth, user.dayBandwidth);

        });
    test("Bandwidth Remap with cost", ()
    {
      User user = User();
      // User has 100 units to spend.
      user.spend(20);
      user.eBandwidth ~/= 2;
      expect(user.dayBandwidth, 40);
    });
    test("Breaktime Remap", ()
    {
      User user = User();
      user.breakTime = 150;
      expect(user.breakTime, user.curBreak);
    });
    // Timer is not counting down.
    test("Breaktime CountDown", (){
      fakeAsync((async){
        User user = User();
        user.breakTime = 20;
        user.curBrainState = BrainState.breakTime;

        // countSeconds should be moved to a private function.
        user.countSeconds();
        // Break should start.
        async.elapse(const Duration(seconds: 5));
        expect(user.curBreak, 15);
      });
    });
    test("Breaktime CountDown with Remap", ()
    {
      fakeAsync((async) {
        User user = User();
        user.breakTime = 20;
        user.curBrainState = BrainState.breakTime;
        user.countSeconds();
        // Break should start.
        async.elapse(const Duration(seconds: 5));
        user.breakTime = 40;
        expect(user.curBreak, 30);

      });
    });
    test("Breaktime Countdown Full CD", ()
    {
      fakeAsync((async){
        User user = User();
        user.breakTime = 20;
        user.curBrainState = BrainState.breakTime;
        user.countSeconds();
        async.elapse(const Duration(seconds: 21));
        expect(user.curBrainState, BrainState.okay);
        expect(user.curBreak, 20);
      });
    });
    test("Breaktime Countdown Burnout Interupt", ()
    {
      fakeAsync((async){
        User user = User();
        user.breakTime = 20;
        user.curBrainState = BrainState.breakTime;
        user.countSeconds();
        async.elapse(const Duration(seconds: 15));
        user.curBrainState = BrainState.burnOut;
        async.elapse(const Duration(seconds: 1));
        expect(user.curBrainState, BrainState.burnOut);
        expect(user.curBreak, 20);
      });
    });
  }
  );
}