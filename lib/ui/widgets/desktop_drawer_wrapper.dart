// This is a workaround for the lack of standard nav drawer in m3.
// Eventually this will be rendered unnecessary.
import 'package:flutter/material.dart';

class DesktopDrawerWrapper extends StatelessWidget {
  const DesktopDrawerWrapper({super.key, required this.drawer});

  final NavigationDrawer drawer;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        removeTop: true,
        removeLeft: true,
        removeRight: true,
        child: Theme(
            data: Theme.of(context).copyWith(
                drawerTheme: const DrawerThemeData(
              elevation: 0,
              // These are for zero border radius
              shape: RoundedRectangleBorder(),
              endShape: RoundedRectangleBorder(),
            )),
            child: drawer));
  }
}
