import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';

import '../../util/constants.dart';
import '../../util/enums.dart';
import '../../util/interfaces/sortable.dart';

class ListViewHeader<T> extends StatefulWidget {
  const ListViewHeader(
      {Key? key,
      this.outerPadding = EdgeInsets.zero,
      this.header = "",
      this.sorter,
      this.onChanged})
      : super(key: key);

  final EdgeInsetsGeometry outerPadding;
  final String header;
  final SortableView<T>? sorter;
  final void Function(SortMethod? sortMethod)? onChanged;

  @override
  State<ListViewHeader<T>> createState() => _ListViewHeader();
}

class _ListViewHeader<T> extends State<ListViewHeader<T>> {
  late final String header;

  late final SortableView<T>? sorter;

  late final TextEditingController dropdownController;

  @override
  void initState() {
    super.initState();
    header = widget.header;
    sorter = widget.sorter;
    dropdownController = TextEditingController();
    dropdownController.addListener(() {
      String newText = dropdownController.text;
      SemanticsService.announce(newText, Directionality.of(context));
    });
  }

  @override
  Widget build(context) {
    return Padding(
        padding: widget.outerPadding,
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                  child: AutoSizeText(
                header,
                style: Constants.largeHeaderStyle,
                softWrap: false,
                maxLines: 1,
                overflow: TextOverflow.visible,
                minFontSize: Constants.huge,
              )),
              (null != sorter)
                  ? DropdownMenu<SortMethod>(
                      width: 150,
                      textStyle: Constants.minHeaderStyle,
                      leadingIcon: const Icon(Icons.swap_vert_rounded),
                      trailingIcon: getTrailingIcon(),
                      inputDecorationTheme: Theme.of(context)
                          .inputDecorationTheme
                          .copyWith(
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(
                                          Constants.roundedCorners)),
                                  borderSide: BorderSide(
                                    width: 2,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                                    strokeAlign: BorderSide.strokeAlignOutside,
                                  )),
                              border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(
                                          Constants.roundedCorners)),
                                  borderSide: BorderSide(
                                    strokeAlign: BorderSide.strokeAlignOutside,
                                  ))),
                      initialSelection: sorter!.sortMethod,
                      controller: dropdownController,
                      label: const Text("Sort"),
                      hintText: "Sort method",
                      dropdownMenuEntries: sorter!.sortMethods
                          .map((SortMethod method) => DropdownMenuEntry(
                              value: method,
                              label: toBeginningOfSentenceCase(
                                  method.name.replaceAll("_", " "))!))
                          .toList(),
                      onSelected: (SortMethod? sortMethod) {
                        if (null != sortMethod) {
                          sorter!.sortMethod = sortMethod;
                        }
                        dropdownController.value = dropdownController.value
                            .copyWith(
                                text: toBeginningOfSentenceCase(sorter!
                                    .sortMethod.name
                                    .replaceAll("_", " "))!,
                                selection: TextSelection.collapsed(
                                    offset: sorter!.sortMethod.name.length));

                        if (null != widget.onChanged) {
                          widget.onChanged!(sortMethod);
                        }
                      })
                  : const SizedBox.shrink(),
            ]));
  }

  Widget? getTrailingIcon() {
    if (null == sorter || sorter?.sortMethod == SortMethod.none) {
      return null;
    }

    if (sorter!.descending) {
      return const Icon(Icons.arrow_downward_rounded);
    }
    return const Icon(Icons.arrow_upward_rounded);
  }
}
