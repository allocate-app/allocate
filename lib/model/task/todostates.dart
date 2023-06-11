import "package:event/event.dart";

class StateChange<T> extends EventArgs {
  T self;
  StateChange(this.self);

}
mixin ModelState<T>
{
  var onChanged = Event<StateChange<T>>();
  void raiseChange();
}