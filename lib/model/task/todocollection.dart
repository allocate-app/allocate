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
            sorted.sort((a, b) => b.deadline.startDate.compareTo(a.deadline.startDate));
          }
        else{
          sorted.sort((a, b) => a.deadline.startDate.compareTo(b.deadline.startDate));
        }
        break;
      case SortMethod.endDate:
        if(reverse)
          {
            sorted.sort((a, b) => b.deadline.endDate.compareTo(a.deadline.endDate));
          }
        else
          {
            sorted.sort((a, b) => a.deadline.endDate.compareTo(b.deadline.endDate));
          }
        break;
      default:
        break;
    }
    return sorted;

  }

  void add(T t) => todos.insert(0, t);
  void remove(T t) => todos.remove(t);

  // For custom ordering. User swaps tasks in the view.
  // Objects to be rearranged are swapped in the model.
  // On update, custom order is maintained.
  void reorder(T t1, T t2) {
    int prevIndex = todos.indexOf(t1);
    int newIndex = todos.indexOf(t2);
    todos[prevIndex] = t2;
    todos[newIndex] = t2;
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
  // Utility function to avoid task hogging.
  // Called when user is hitting hard limit of tasks, to be determined later.
  // ToDos are pushed to the front, older tasks will always be at the end of the list.
  void pruneToDo()
  {
    todos.removeLast();
  }
}
