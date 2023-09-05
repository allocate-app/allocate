// This is a workaround for the lack of standard nav drawer in m3.
// Eventually this will be rendered unnecessary.
import 'package:flutter/material.dart';

class DesktopDrawerWrapper extends StatelessWidget {
  const DesktopDrawerWrapper({Key? key, required this.drawer})
      : super(key: key);
  final NavigationDrawer drawer;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        removeTop: true,
        removeLeft: true,
        removeRight: true,
        // T
        child: Theme(
            data: Theme.of(context).copyWith(
                drawerTheme: const DrawerThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(),
              endShape: RoundedRectangleBorder(),
            )),
            child: drawer));
  }
}
