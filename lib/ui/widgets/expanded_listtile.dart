import 'package:flutter/material.dart';

import '../../util/constants.dart';

class ExpandedListTile extends StatefulWidget {
  const ExpandedListTile(
      {Key? key,
      this.outerPadding = EdgeInsets.zero,
      this.children,
      this.expanded = false,
      required this.title,
      this.subtitle,
      this.leading,
      this.border,
      this.trailing})
      : super(key: key);

  final EdgeInsetsGeometry outerPadding;
  final List<Widget>? children;
  final bool expanded;
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final BorderSide? border;

  @override
  State<ExpandedListTile> createState() => _ExpandedListTile();
}

class _ExpandedListTile extends State<ExpandedListTile> {
  late bool expanded;

  @override
  void initState() {
    super.initState();
    expanded = widget.expanded;
  }

  @override
  Widget build(context) {
    return Padding(
      padding: widget.outerPadding,
      child: Card(
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
          initiallyExpanded: expanded,
          maintainState: true,
          leading: widget.leading,
          trailing: widget.trailing,
          onExpansionChanged: (value) => setState(() => expanded = value),
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
