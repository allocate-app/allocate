import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../util/constants.dart';
import '../../util/interfaces/i_model.dart';
import 'tiles.dart';

class SearchRecentsBar<T extends IModel> extends StatefulWidget {
  const SearchRecentsBar(
      {Key? key,
      this.padding = EdgeInsets.zero,
      this.hintText = "",
      this.searchController,
      required this.handleHistorySelection,
      required this.mostRecent,
      required this.search,
      this.clearOnSelection = false,
      this.dispose = true,
      this.persistentEntry,
      required this.handleDataSelection})
      : super(key: key);

  final MapEntry<String, int>? persistentEntry;
  final String hintText;
  final EdgeInsetsGeometry padding;
  final SearchController? searchController;
  final bool clearOnSelection;
  final bool dispose;
  final void Function({required int id}) handleHistorySelection;
  final void Function({required int id}) handleDataSelection;
  final Future<List<T>> Function() mostRecent;
  final Future<List<T>> Function({required String searchString}) search;

  @override
  State<SearchRecentsBar<T>> createState() => _SearchRecents<T>();
}

class _SearchRecents<T extends IModel> extends State<SearchRecentsBar<T>> {
  late List<MapEntry<String, int>> searchHistory = List.empty(growable: true);

  late SearchController searchController;

  @override
  void initState() {
    super.initState();
    searchController = widget.searchController ?? SearchController();
    searchController.addListener(() {
      String newText = searchController.text;
      SemanticsService.announce(newText, Directionality.of(context));
    });
  }

  @override
  void dispose() {
    if (widget.dispose) {
      searchController.dispose();
    }
    super.dispose();
  }

  void updateHistory({required MapEntry<String, int> data}) {
    setState(() {
      if (searchHistory.length >= Constants.historyLength) {
        searchHistory.removeLast();
      }
      // Refactor this to accommodate a persistent one.
      searchHistory.insert(0, data);
    });
  }

  @override
  Widget build(context) {
    return Padding(
      padding: widget.padding,
      child: SearchAnchor.bar(
          isFullScreen: false,
          barSide: MaterialStatePropertyAll(BorderSide(
              width: 2,
              strokeAlign: BorderSide.strokeAlignOutside,
              color: Theme.of(context).colorScheme.outlineVariant)),
          barBackgroundColor:
              const MaterialStatePropertyAll(Colors.transparent),
          barElevation: const MaterialStatePropertyAll(0),
          viewConstraints: const BoxConstraints(
              maxHeight: Constants.maxSearchSideBeforeScroll),
          barHintText: widget.hintText,
          searchController: searchController,
          suggestionsBuilder:
              (BuildContext context, SearchController controller) {
            if (controller.text.isEmpty) {
              if (searchHistory.isNotEmpty) {
                return searchHistory
                    .map((MapEntry<String, int> data) => Tiles.historyTile(
                          title: data.key,
                          onTap: () {
                            controller.closeView(
                                (widget.clearOnSelection) ? "" : data.key);
                            widget.handleHistorySelection(id: data.value);
                          },
                        ))
                    .toList();
                // Consider appending the map entry here?
              }
              final searchFuture = widget.mostRecent();
              return [
                buildFutureList(
                    searchFuture: searchFuture, controller: controller)
              ];
            }
            // Search query iterable.
            final searchFuture = widget.search(searchString: controller.text);
            return [
              buildFutureList(
                  searchFuture: searchFuture, controller: controller)
            ];
          }),
    );
  }

  FutureBuilder<List<T>> buildFutureList(
      {required Future<List<T>> searchFuture,
      required SearchController controller}) {
    return FutureBuilder(
        future: searchFuture,
        builder: (BuildContext context, AsyncSnapshot<List<T>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final List<T>? data = snapshot.data;
            if (null != data && data.isNotEmpty) {
              return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Tiles.searchTile(
                        title: data[index].name,
                        onTap: () {
                          controller.closeView((widget.clearOnSelection)
                              ? ""
                              : data[index].name);
                          updateHistory(
                              data: MapEntry(data[index].name, data[index].id));
                          widget.handleDataSelection(id: data[index].id);
                        });
                  });
            }
            // Render peristent entry on an empty query
            return (null != widget.persistentEntry)
                ? Tiles.searchTile(
                    leading: const Icon(Icons.manage_history_rounded),
                    title: widget.persistentEntry!.key,
                    onTap: () {
                      controller.closeView((widget.clearOnSelection)
                          ? ""
                          : widget.persistentEntry!.key);
                      updateHistory(data: widget.persistentEntry!);
                      widget.handleDataSelection(
                          id: widget.persistentEntry!.value);
                    })
                : const SizedBox.shrink();
          }
          return const SizedBox.shrink();
        });
  }
}
