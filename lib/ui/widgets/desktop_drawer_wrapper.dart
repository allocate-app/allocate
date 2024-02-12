// This is a workaround for the lack of standard nav drawer in m3.
// Eventually this will be rendered unnecessary.
import 'dart:io';

import 'package:flutter/material.dart';

class DesktopDrawerWrapper extends StatelessWidget {
  const DesktopDrawerWrapper(
      {super.key, required this.drawer, this.elevation = 0});

  final Widget drawer;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        removeTop: (!(Platform.isIOS || Platform.isAndroid)),
        removeLeft: true,
        removeRight: true,
        child: Theme(
            data: Theme.of(context).copyWith(
                drawerTheme: DrawerThemeData(
              // These are for zero border radius
              elevation: elevation,
              shape: const RoundedRectangleBorder(),
              endShape: const RoundedRectangleBorder(),
            )),
            child: drawer));
  }
}
