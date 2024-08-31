import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../../providers/application/layout_provider.dart';
import '../../util/constants.dart';
import '../../util/interfaces/i_model.dart';
import 'tiles.dart';

class SearchRecentsBar<T extends IModel> extends StatefulWidget {
  const SearchRecentsBar(
      {super.key,
      this.padding = EdgeInsets.zero,
      this.hintText = "",
      this.searchController,
      required this.mostRecent,
      required this.search,
      this.clearOnSelection = false,
      this.dispose = true,
      this.persistentEntry,
      this.border,
      required this.handleDataSelection});

  final BorderSide? border;
  final MapEntry<String, int>? persistentEntry;
  final String hintText;
  final EdgeInsetsGeometry padding;
  final SearchController? searchController;
  final bool clearOnSelection;
  final bool dispose;
  final Future<void> Function({required int id}) handleDataSelection;
  final Future<List<T>> Function() mostRecent;
  final Future<List<T>> Function({required String searchString}) search;

  @override
  State<SearchRecentsBar<T>> createState() => _SearchRecents<T>();
}

class _SearchRecents<T extends IModel> extends State<SearchRecentsBar<T>> {
  late List<MapEntry<String, int>> searchHistory = List.empty(growable: true);

  late SearchController searchController;

  late final LayoutProvider layoutProvider;

  @override
  void initState() {
    super.initState();
    searchController = widget.searchController ?? SearchController();
    searchController.addListener(announceText);

    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);
  }

  void announceText() {
    if (mounted) {
      String newText = searchController.text;
      SemanticsService.announce(newText, Directionality.of(context));
    }
  }

  @override
  void dispose() {
    searchController.removeListener(announceText);

    if (widget.dispose) {
      disposeController();
    }
    super.dispose();
  }

  Future<void> disposeController() async {
    await Future.delayed(const Duration(seconds: 1));
    searchController.dispose();
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
      child: Focus(
        onFocusChange: (bool hasFocus) {
          if (hasFocus && !searchController.isOpen) {
            FocusScope.of(context).unfocus();
          }
        },
        child: SearchAnchor.bar(
            barSide: WidgetStatePropertyAll(widget.border ??
                BorderSide(
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignOutside,
                    color: Theme.of(context).colorScheme.outlineVariant)),
            barBackgroundColor:
                const WidgetStatePropertyAll(Colors.transparent),
            barElevation: const WidgetStatePropertyAll(0),
            viewConstraints: const BoxConstraints(
              maxHeight: Constants.maxSearchSideBeforeScroll,
            ),
            barHintText: widget.hintText,
            onSubmitted: (String text) {
              FocusScope.of(context).unfocus();
              searchController.closeView("");
            },
            searchController: searchController,
            suggestionsBuilder:
                (BuildContext context, SearchController controller) {
              if (controller.text.isEmpty) {
                if (searchHistory.isNotEmpty) {
                  List<Widget> widgets = searchHistory
                      .map((MapEntry<String, int> data) => Tiles.historyTile(
                            title: data.key,
                            onTap: () async {
                              FocusScope.of(context).unfocus();
                              await widget.handleDataSelection(id: data.value);
                              controller.closeView(
                                  (widget.clearOnSelection) ? "" : data.key);
                            },
                          ))
                      .toList();
                  // Consider appending the map entry here?
                  widgets.add(_tapToUnfocus());
                  return widgets;
                }
                final searchFuture = widget.mostRecent();
                return [
                  buildFutureList(
                      searchFuture: searchFuture, controller: controller),
                  _tapToUnfocus()
                ];
              }
              // Search query iterable.
              final searchFuture = widget.search(searchString: controller.text);
              return [
                buildFutureList(
                    searchFuture: searchFuture, controller: controller),
                _tapToUnfocus(),
              ];
            }),
      ),
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
                    return Tiles.searchItemTile(
                        title: data[index].name,
                        onTap: () async {
                          FocusScope.of(context).unfocus();
                          await widget.handleDataSelection(id: data[index].id);
                          updateHistory(
                              data: MapEntry(data[index].name, data[index].id));
                          controller.closeView((widget.clearOnSelection)
                              ? ""
                              : data[index].name);
                        });
                  });
            }
            // Render peristent entry on an empty query
            return (null != widget.persistentEntry)
                ? Tiles.searchItemTile(
                    leading: const Icon(Icons.manage_history_rounded),
                    title: widget.persistentEntry!.key,
                    onTap: () async {
                      FocusScope.of(context).unfocus();
                      updateHistory(data: widget.persistentEntry!);
                      await widget.handleDataSelection(
                          id: widget.persistentEntry!.value);
                      controller.closeView((widget.clearOnSelection)
                          ? ""
                          : widget.persistentEntry!.key);
                    })
                : const SizedBox.shrink();
          }
          return const SizedBox.shrink();
        });
  }

  Widget _tapToUnfocus() => ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: layoutProvider.height, maxWidth: layoutProvider.width),
        child: GestureDetector(onTap: () {
          FocusScope.of(context).unfocus();
          searchController.closeView("");
        }),
      );
}
