import "todo.dart";
enum SortMethod {name, weight, priority, startDate, endDate, custom}
mixin ToDoCollection<T extends ToDo>{

  final todos = <T>[];
  // For views.
  List<T> get complete =>
      [...todos.where((t) => t.progress == Progress.completed)];
  List<T> get unComplete =>
      [...todos.where((t) => t.progress != Progress.completed)];

  List<T> sorted({List<T>? list, SortMethod sortBy = SortMethod.name, bool reverse = false})
  {
    list = list ?? unComplete;
    switch(sortBy)
    {
      case SortMethod.name:
        if(reverse)
          {
            list.sort((a, b) => b.name.compareTo(a.name));
          }
        else
          {
            list.sort((a, b) => a.name.compareTo(b.name));
          }
        break;
      case SortMethod.weight:
        if(reverse)
          {
            list.sort((a, b) => b.weight.compareTo(a.weight));
          }
        else
          {
            list.sort((a, b) => a.weight.compareTo(b.weight));
          }
        break;
      case SortMethod.priority:
        if(reverse)
          {
            list.sort((a, b) => b.priority.index.compareTo(a.priority.index));
          }
        else
          {
            list.sort((a, b) => a.priority.index.compareTo(b.priority.index));
          }
        break;
      case SortMethod.startDate:

        if(reverse)
          {
            list.sort((a, b) => b.deadline.startDate.compareTo(a.deadline.startDate));
          }
        else{
          list.sort((a, b) => a.deadline.startDate.compareTo(b.deadline.startDate));
        }
        break;
      case SortMethod.endDate:
        if(reverse)
          {
            list.sort((a, b) => b.deadline.endDate.compareTo(a.deadline.endDate));
          }
        else
          {
            list.sort((a, b) => a.deadline.endDate.compareTo(b.deadline.endDate));
          }
        break;
      default:
        break;
    }
    return list;

  }

  void add(T t) => todos.insert(0, t);
  void remove(T t) => todos.remove(t);

  // For custom ordering. User swaps tasks in the view.
  // Objects to be rearranged are swapped in the model.
  // On update, custom order is maintained.
  void reorder(T t1, T t2, {List<T>? list}) {
    list = list?? todos;
    int prevIndex = list.indexOf(t1);
    int newIndex = list.indexOf(t2);
    list[prevIndex] = t2;
    list[newIndex] = t1;
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
