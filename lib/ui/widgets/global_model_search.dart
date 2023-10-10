import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';

import '../../util/constants.dart';
import '../../util/enums.dart';
import '../../util/interfaces/i_model.dart';

class GlobalModelSearch extends StatefulWidget {
  const GlobalModelSearch(
      {super.key,
      required this.handleHistorySelection,
      required this.mostRecent,
      required this.search,
      required this.handleDataSelection});

  // This may actually be best handled within this widget. -- see TODO;
  final void Function({required int id, required ModelType modelType})
      handleHistorySelection;

  final void Function({required int id, required ModelType modelType})
      handleDataSelection;
  final Future<List<IModel>> Function() mostRecent;
  final Future<List<IModel>> Function({required String searchString}) search;

  @override
  State<GlobalModelSearch> createState() => _GlobalModelSearch();
}

class _GlobalModelSearch extends State<GlobalModelSearch> {
  final SearchController searchController = SearchController();
  late List<MapEntry<String, MapEntry<int, ModelType>>> searchHistory =
      List.empty(growable: true);

  // TODO: Implement an "on selected" method.

  void updateHistory(
      {required MapEntry<String, MapEntry<int, ModelType>> data}) {
    setState(() {
      if (searchHistory.length >= Constants.historyLength) {
        searchHistory.removeLast();
      }
      searchHistory.insert(0, data);
    });
  }

  @override
  initState() {
    super.initState();
    searchController.addListener(() {
      String newText = searchController.text;
      SemanticsService.announce(newText, Directionality.of(context));
    });
  }

  @override
  dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(context) {
    return SearchAnchor(
      isFullScreen: false,
      searchController: searchController,
      builder: (BuildContext context, SearchController controller) {
        return IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => controller.openView());
      },
      suggestionsBuilder: (BuildContext context, SearchController controller) {
        if (controller.text.isEmpty) {
          if (searchHistory.isNotEmpty) {
            // TODO: Refactor to use HistoryTile
            return searchHistory
                .map((MapEntry<String, MapEntry<int, ModelType>> data) =>
                    ListTile(
                        leading: const Icon(Icons.history_rounded),
                        title: AutoSizeText(
                          data.key,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                        ),
                        onTap: () {
                          controller.closeView("");
                        },
                        trailing: DecoratedBox(
                          decoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(Constants.roundedCorners)),
                              border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                                  strokeAlign: BorderSide.strokeAlignOutside)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: Constants.padding),
                            child: AutoSizeText(
                              toBeginningOfSentenceCase(
                                  data.value.value.toString())!,
                              minFontSize: Constants.large,
                              overflow: TextOverflow.visible,
                              softWrap: false,
                              maxLines: 1,
                            ),
                          ),
                        )))
                .toList();
          }
          final searchFuture = widget.mostRecent();
          return [
            buildFutureList(searchFuture: searchFuture, controller: controller)
          ];
        }
        final searchFuture = widget.search(searchString: controller.text);
        return [
          buildFutureList(searchFuture: searchFuture, controller: controller)
        ];
      },
    );
  }

  FutureBuilder<List<IModel>> buildFutureList(
      {required Future<List<IModel>> searchFuture,
      required SearchController controller}) {
    return FutureBuilder(
      future: searchFuture,
      builder: (BuildContext context, AsyncSnapshot<List<IModel>> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final List<IModel>? data = snapshot.data;
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
                        //TODO: implement
                        controller.closeView("");
                      });
                });
          }
        }
        return const SizedBox.shrink();
      },
    );
  }
}
