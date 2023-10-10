import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../../util/constants.dart';
import '../../util/interfaces/i_model.dart';

class SearchRecents<T extends IModel> extends StatefulWidget {
  const SearchRecents({super.key,
    this.padding = EdgeInsets.zero,
    this.hintText = "",
    required this.searchController,
    required this.handleHistorySelection,
    required this.mostRecent,
    required this.search,
    this.clearOnSelection = false,
    this.persistentEntry,
    required this.handleDataSelection});

  final MapEntry<String, int>? persistentEntry;
  final String hintText;
  final EdgeInsetsGeometry padding;
  final SearchController searchController;
  final bool clearOnSelection;
  final void Function({required MapEntry<String, int> data})
  handleHistorySelection;
  final void Function({required int id}) handleDataSelection;
  final Future<List<T>> Function() mostRecent;
  final Future<List<T>> Function({required String searchString}) search;

  @override
  State<SearchRecents<T>> createState() => _SearchRecents<T>();
}

class _SearchRecents<T extends IModel> extends State<SearchRecents<T>> {
  // TODO: Add a persistent item if it's here.
  late List<MapEntry<String, int>> searchHistory = List.empty(growable: true);

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
              color: Theme
                  .of(context)
                  .colorScheme
                  .outlineVariant)),
          barBackgroundColor:
          const MaterialStatePropertyAll(Colors.transparent),
          barElevation: const MaterialStatePropertyAll(0),
          viewConstraints: const BoxConstraints(
              maxHeight: Constants.maxSearchHeightBeforeScroll),
          barHintText: widget.hintText,
          searchController: widget.searchController,
          suggestionsBuilder: (context, SearchController controller) {
            if (controller.text.isEmpty) {
              if (searchHistory.isNotEmpty) {
                return searchHistory
                    .map((MapEntry<String, int> data) =>
                    ListTile(
                      leading: const Icon(Icons.history_rounded),
                      title: AutoSizeText(
                        data.key,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                      ),
                      onTap: () {
                        controller.closeView(data.key);
                        widget.handleHistorySelection(data: data);
                        if (widget.clearOnSelection) {
                          controller.value =
                              controller.value.copyWith(text: "");
                        }
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

  FutureBuilder<List<T>> buildFutureList({required Future<List<T>> searchFuture,
    required SearchController controller}) {
    return FutureBuilder(
        future: searchFuture,
        builder: (BuildContext context, AsyncSnapshot<List<T>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final List<T>? data = snapshot.data;
            // TODO: Refactor this to accommodate a persistent search item.
            // ie. an object that -hasn't- been created yet.
            if (null != data && data.isNotEmpty) {
              return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                                Radius.circular(Constants.roundedCorners))),
                        title: AutoSizeText(data[index].name),
                        onTap: () {
                          controller.closeView((widget.clearOnSelection)
                              ? ""
                              : data[index].name);
                          updateHistory(
                              data: MapEntry(
                                  data[index].name, data[index].localID!));
                          widget.handleDataSelection(id: data[index].localID!);
                          if (widget.clearOnSelection) {
                            controller.value =
                                controller.value.copyWith(text: "");
                          }
                        });
                  });
            }
            // This is what to render if no data. -- PERSISTENT entry here -> Consider making a separate widget.
            return (null != widget.persistentEntry)
                ? ListTile(
                leading: const Icon(Icons.manage_history_rounded),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                        Radius.circular(Constants.roundedCorners))),
                title: AutoSizeText(widget.persistentEntry!.key),
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


          // This is too jarring. Things load too quickly.
          //   const Padding(
          //   padding: EdgeInsets.all(Constants.padding),
          //   child: CircularProgressIndicator(),
          // );
        });
  }
}
