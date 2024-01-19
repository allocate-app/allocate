import 'dart:math';

import 'package:flutter/material.dart';

// This is a workaround extension because Flutter does not yet have a separated reorderableListview
// Thank you to Bstolinski and AppleDev879:
// https://github.com/flutter/flutter/issues/76706

// NOTE: Index correction is built into this widget.
class CustomReorderableListView extends ReorderableListView {
  CustomReorderableListView.separated({
    super.key,
    required IndexedWidgetBuilder itemBuilder,
    required IndexedWidgetBuilder separatorBuilder,
    required int itemCount,
    required ReorderCallback onReorder,
    void Function(int)? onReorderStarted,
    void Function(int)? onReorderEnded,
    super.itemExtent,
    super.prototypeItem,
    super.proxyDecorator,
    bool buildDefaultDragHandles = true,
    super.padding,
    super.header,
    super.scrollDirection,
    super.reverse,
    super.scrollController,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.anchor,
    super.cacheExtent,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
  }) : super.builder(
          itemCount: max(0, itemCount * 2 - 1),
          itemBuilder: (BuildContext context, int index) {
            final isSeparator = index.isOdd;
            final itemIndex = index ~/ 2;
            final Widget item;

            if (isSeparator) {
              // Separator
              item = separatorBuilder.call(context, itemIndex);
              // Ensure the separator has a unique key
              if (item.key == null) {
                return KeyedSubtree(
                  key: ValueKey('ReorderableSeparator${index}Key'),
                  child: IgnorePointer(child: item),
                );
              }
              // No drag handles for separators
              return item;
            } else {
              // Actual list item
              item = itemBuilder.call(context, itemIndex);
              // Wrap with ReorderableDragStartListener if drag handles are needed
              return buildDefaultDragHandles
                  ? KeyedSubtree(
                      key: ValueKey('ReorderableItem${index}Key'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(child: item),
                          buildDefaultDragHandles
                              ? ReorderableDragStartListener(
                                  index: index,
                                  child: const Padding(
                                    padding: EdgeInsets.only(right: 8.0),
                                    child: Icon(Icons.drag_handle),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ],
                      ))
                  : item;
            }
          },
          onReorderStart: (index) {
            // Find the Separator widgets and hide them
            // Call onReorderStarted callback when the reorder starts
            onReorderStarted?.call(index);
          },
          onReorder: (int oldIndex, int newIndex) {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }

            if (oldIndex % 2 == 1) {
              //separator - should never happen
              return;
            }

            if ((oldIndex - newIndex).abs() == 1) {
              //moved behind the top/bottom separator
              return;
            }

            newIndex = oldIndex > newIndex && newIndex % 2 == 1
                ? (newIndex + 1) ~/ 2
                : newIndex ~/ 2;
            oldIndex = oldIndex ~/ 2;
            onReorder.call(oldIndex, newIndex);
          },
          onReorderEnd: (index) {
            onReorderEnded?.call(index);
          },
          buildDefaultDragHandles: false,
        );
}
