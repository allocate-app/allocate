abstract class ViewModel<T> {
  void fromModel({required T model});

  T toModel();

  void clear();
}
