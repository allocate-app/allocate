import "package:event/event.dart";

// TODO: implement a model singleton or factor this into a component.
class StateChange<T> extends EventArgs {
  T self;
  StateChange(this.self);

}
mixin ModelState<T>
{
  var onChanged = Event<StateChange<T>>();
  void raiseChange();
}