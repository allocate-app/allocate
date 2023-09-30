import "package:auto_size_text/auto_size_text.dart";
import "package:flutter/material.dart";

import "../../util/constants.dart";

class DrainBar extends StatefulWidget {
  const DrainBar({
    super.key,
    this.weight = 0,
    this.max = Constants.maxDoubleBandwidth,
    this.constraints = const BoxConstraints(),
  });

  final double weight;
  final double max;
  final BoxConstraints constraints;

  @override
  State<DrainBar> createState() => _DrainBar();
}

class _DrainBar extends State<DrainBar> {
  @override
  Widget build(context) {
    double offset = widget.weight / widget.max;
    return ConstrainedBox(
      constraints: widget.constraints,
      child: Stack(alignment: Alignment.center, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    width: 3,
                    strokeAlign: BorderSide.strokeAlignCenter),
                shape: BoxShape.rectangle,
                // TODO: This should probably move to constants class.
                borderRadius: const BorderRadius.all(Radius.circular(10))),
            child: Padding(
              padding: const EdgeInsets.all(Constants.halfPadding),
              child: LinearProgressIndicator(
                  color: (offset < 0.6) ? null : Colors.redAccent,
                  minHeight: 50,
                  value: 1 - offset,
                  // Possibly remove
                  borderRadius: const BorderRadius.all(Radius.circular(10))),
            ),
          ),
        ),
        Align(
            alignment: Alignment.centerRight,
            child: Container(
                height: 40,
                width: 8,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(2)),
                  color: Theme.of(context).colorScheme.outline,
                ))),
        AutoSizeText("${widget.weight.toInt()}",
            minFontSize: Constants.large,
            softWrap: false,
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: Constants.hugeHeaderStyle),
      ]),
    );
  }
}
