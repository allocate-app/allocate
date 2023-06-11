import "todo.dart";

enum SortMethod {name, weight, priority, startDate, endDate, custom}
mixin ToDoCollection<T extends ToDo> on ToDo {

  final todos = <T>[];
  // For views.
  List<T> get complete =>
      [...todos.where((t) => t.progress == Progress.completed)];
  List<T> get unComplete =>
      [...todos.where((t) => t.progress != Progress.completed)];

  List<T> sorted({SortMethod sortBy = SortMethod.name, bool reverse = false})
  {
    // This should be a copy of the user sorted list.
    var sorted = [...unComplete];
    switch(sortBy)
    {
      case SortMethod.name:
        if(reverse)
          {
            sorted.sort((a, b) => b.name.compareTo(a.name));
          }
        else
          {
            sorted.sort((a, b) => a.name.compareTo(b.name));
          }
        break;
      case SortMethod.weight:
        if(reverse)
          {
            sorted.sort((a, b) => b.weight.compareTo(a.weight));
          }
        else
          {
            sorted.sort((a, b) => a.weight.compareTo(b.weight));
          }
        break;
      case SortMethod.priority:
        if(reverse)
          {
            sorted.sort((a, b) => b.priority.index.compareTo(a.priority.index));
          }
        else
          {
            sorted.sort((a, b) => a.priority.index.compareTo(b.priority.index));
          }
        break;
      case SortMethod.startDate:

        if(reverse)
          {
            sorted.sort((a, b) => b.startDate.compareTo(a.startDate));
          }
        else{
          sorted.sort((a, b) => a.startDate.compareTo(b.startDate));
        }
        break;
      case SortMethod.endDate:
        if(reverse)
          {
            sorted.sort((a, b) => b.endDate.compareTo(a.endDate));
          }
        else
          {
            sorted.sort((a, b) => a.endDate.compareTo(b.endDate));
          }
        break;
      default:
        break;
    }
    return sorted;

  }

  // push new to front of list.
  void add(T t) => todos.insert(0, t);
  void remove(T t) => todos.remove(t);

  // TODO: Move to day view.
  void reorder(T t, int i) {
    //
    int prevIndex = todos.indexOf(t);
    todos[prevIndex] = todos[i];
    todos[i] = t;
  }

  int calculateWeight() => unComplete.fold(0, (p, c) => p + c.weight);
  Duration calculateDuration() =>
      unComplete.fold(Duration.zero, (p, c) => p + c.expectedDuration);

  void removeAllCompletes() {
    for(T t in complete)
      {
        todos.remove(t);
      }
  }
}
