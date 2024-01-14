import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../../util/constants.dart';

class ScreenHeader extends StatelessWidget {
  const ScreenHeader(
      {super.key,
      this.leadingIcon,
      this.subtitle,
      this.trailing,
      this.header = "",
      this.outerPadding = EdgeInsets.zero});

  final Widget? leadingIcon;
  final Widget? subtitle;
  final Widget? trailing;
  final String header;
  final EdgeInsetsGeometry outerPadding;

  @override
  Widget build(context) {
    return Padding(
      padding: outerPadding,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: leadingIcon,
        subtitle: subtitle,
        title: AutoSizeText(
          header,
          style: Constants.largeHeaderStyle,
          softWrap: false,
          maxLines: 1,
          overflow: TextOverflow.visible,
          minFontSize: Constants.huge,
        ),
        trailing: trailing,
      ),
    );
  }
}
