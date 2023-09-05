import 'package:another_flushbar/flushbar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../providers/todo_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/sorting/todo_sorter.dart';
import '../../widgets/debug_placeholder.dart';
import '../../widgets/flushbars.dart';

class ToDosListScreen extends StatefulWidget {
  const ToDosListScreen({Key? key}) : super(key: key);

  @override
  State<ToDosListScreen> createState() => _ToDosListScreen();
}

class _ToDosListScreen extends State<ToDosListScreen> {
  late bool checkDelete;
  late bool allData;
  late bool loading;
  late int offset;

  late final ToDoProvider toDoProvider;

  // For linked todos.
  late final ScrollController mainScrollController;
  late final ScrollPhysics scrollPhysics;

  // For Task search.
  late final SearchController searchController;
  late List<MapEntry<String, int>> searchHistory;

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeParameters();
    initializeControllers();

    if (toDoProvider.rebuild) {
      toDoProvider.toDos = [];
      fetchData();
      toDoProvider.rebuild = false;
    }
  }

  void initializeProviders() {
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);
  }

  void initializeParameters() {
    loading = toDoProvider.toDos.isEmpty && toDoProvider.rebuild;
    allData = false;
    checkDelete = true;
    offset = toDoProvider.toDos.length;
    searchHistory = List.empty(growable: true);
  }

  void initializeControllers() {
    searchController = SearchController();
    mainScrollController = ScrollController();

    mainScrollController.addListener(() async {
      // Bottom: Run the query.
      if (mainScrollController.offset >=
              mainScrollController.position.maxScrollExtent &&
          !allData) {
        if (!loading) {
          setState(() => loading = true);
          await fetchData();
        }
      }
    });

    scrollPhysics =
        const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());
  }

  Widget getArrowDirection({required SortMethod method}) {
    if (toDoProvider.sortMethod == SortMethod.none) {
      return const SizedBox.shrink();
    }

    if (toDoProvider.sortMethod == method && !toDoProvider.descending) {
      return const Icon(Icons.arrow_downward_rounded);
    }

    return const Icon(Icons.arrow_upward_rounded);
  }

  Future<void> fetchData() async {
    setState(() => loading = true);
    return Future.delayed(
        const Duration(seconds: 1),
        () async => await toDoProvider
                .getToDosBy(limit: Constants.limitPerQuery, offset: offset)
                .then((newToDos) {
              offset += newToDos.length;

              toDoProvider.toDos.addAll(newToDos);
              setState(() {
                loading = false;
                allData = newToDos.length < Constants.limitPerQuery;
              });
            }).catchError(
              (e) {
                Flushbar? error;

                error = Flushbars.createError(
                  message: e.cause ?? "Error with retrieval",
                  context: context,
                  dismissCallback: () => error?.dismiss(),
                );

                error.show(context);
              },
            ));
  }

  Future<void> resetPagination() async {
    setState(() {
      offset = 0;
      toDoProvider.toDos.clear();
    });
    return await fetchData();
  }

  // Grab search from todos scrn.

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool largeScreen =
        (MediaQuery.of(context).size.width >= Constants.largeScreen);
    bool smallScreen =
        (MediaQuery.of(context).size.width <= Constants.smallScreen);

    return Padding(
      padding: const EdgeInsets.all(Constants.innerPadding),
      child: Column(children: [
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Expanded(
                child: AutoSizeText("Tasks",
                    style: Constants.largeHeaderStyle,
                    softWrap: false,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    minFontSize: Constants.large),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<SortMethod>(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Constants.padding),
                    value: toDoProvider.sortMethod,
                    icon: (toDoProvider.sortMethod != SortMethod.none)
                        ? (toDoProvider.descending)
                            ? const Icon(Icons.arrow_downward_rounded)
                            : const Icon(Icons.arrow_upward_rounded)
                        : null,
                    borderRadius: const BorderRadius.all(
                        Radius.circular(Constants.roundedCorners)),
                    onChanged: (method) {
                      if (null != method) {
                        // TODO: When user, add in.
                        // ALSO: CHANGE PROXY PROVIDER.
                        // SHOULD JUST BE AT START && SAVE ACCORDINGLY.
                        setState(() {
                          toDoProvider.sortMethod = method;
                          resetPagination();
                        });
                      }
                    },
                    items: ToDoSorter.sortMethods
                        .map<DropdownMenuItem<SortMethod>>(
                            (method) => DropdownMenuItem<SortMethod>(
                                  value: method,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.all(Constants.padding),
                                    child: Text(
                                      toBeginningOfSentenceCase(
                                          method.name.replaceAll("_", " "))!,
                                    ),
                                  ),
                                ))
                        .toList(growable: false)),
              ),
            ]),
        Flexible(
          child: (loading)
              ? const CircularProgressIndicator()
              : const DebugPlaceholder(debugName: "PAGINATION_TEST"),
        ),
      ]),
    );
  }
}
