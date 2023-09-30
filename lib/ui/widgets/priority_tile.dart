import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../util/constants.dart';
import '../../util/enums.dart';

class PriorityTile extends StatefulWidget {
  const PriorityTile(
      {super.key,
      this.padding = EdgeInsets.zero,
      this.priority = Priority.low,
      required this.onSelectionChanged});

  final EdgeInsetsGeometry padding;
  final Priority priority;
  final void Function(Set<Priority> newSelection) onSelectionChanged;

  @override
  State<PriorityTile> createState() => _PriorityTile();
}

class _PriorityTile extends State<PriorityTile> {
  @override
  Widget build(context) {
    return Padding(
      padding: widget.padding,
      child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(children: [
              Expanded(
                  child: AutoSizeText("Priority",
                      style: Constants.headerStyle,
                      maxLines: 1,
                      softWrap: true,
                      textAlign: TextAlign.center,
                      minFontSize: Constants.medium))
            ]),
            SegmentedButton<Priority>(
                selectedIcon: const Icon(Icons.flag_circle_rounded),
                style: ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.adaptivePlatformDensity,
                  side: MaterialStatePropertyAll<BorderSide>(BorderSide(
                    width: 2,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  )),
                ),
                segments: Priority.values
                    .map((Priority type) => ButtonSegment<Priority>(
                        icon: Constants.priorityIcon[type],
                        value: type,
                        label: Text(
                          "${toBeginningOfSentenceCase(type.name)}",
                          softWrap: false,
                          overflow: TextOverflow.fade,
                        )))
                    .toList(growable: false),
                selected: <Priority>{widget.priority},
                onSelectionChanged: widget.onSelectionChanged)
          ]),
    );
  }
}
