import "package:event/event.dart";

// TODO: implement if needed, or remove.
class StateChange<T> extends EventArgs {
  T self;
  StateChange(this.self);

}
mixin ModelState<T>
{
  var onChanged = Event<StateChange<T>>();
  void raiseChange();
}