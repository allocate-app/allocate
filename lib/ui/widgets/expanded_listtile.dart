import 'package:flutter/material.dart';

import '../../util/constants.dart';

class ExpandedListTile extends StatefulWidget {
  const ExpandedListTile(
      {super.key,
      this.outerPadding = EdgeInsets.zero,
      this.children,
      this.initiallyExpanded = false,
      this.onExpansionChanged,
      required this.title,
      this.subtitle,
      this.leading,
      this.border,
      this.controller,
      this.trailing});

  final EdgeInsetsGeometry outerPadding;
  final List<Widget>? children;
  final bool initiallyExpanded;
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final BorderSide? border;
  final ExpansionTileController? controller;
  final void Function({bool expanded})? onExpansionChanged;

  @override
  State<ExpandedListTile> createState() => _ExpandedListTile();
}

class _ExpandedListTile extends State<ExpandedListTile> {
  late bool expanded;

  @override
  void initState() {
    super.initState();
    expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(context) {
    return Padding(
      padding: widget.outerPadding,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
            side: widget.border ??
                BorderSide(
                    width: 2,
                    color: Theme.of(context).colorScheme.outlineVariant,
                    strokeAlign: BorderSide.strokeAlignInside),
            borderRadius: const BorderRadius.all(
                Radius.circular(Constants.semiCircular))),
        child: ExpansionTile(
          controller: widget.controller,
          initiallyExpanded: expanded,
          maintainState: true,
          leading: widget.leading,
          trailing: widget.trailing,
          onExpansionChanged: (value) {
            if (mounted) {
              setState(() => expanded = value);
            }
            if (null != widget.onExpansionChanged) {
              widget.onExpansionChanged!(expanded: value);
            }
          },
          title: widget.title,
          subtitle: widget.subtitle,
          collapsedShape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(Constants.semiCircular))),
          shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(Constants.semiCircular))),
          children: widget.children ?? [],
        ),
      ),
    );
  }
}
