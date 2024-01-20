import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../util/constants.dart';

class LayoutProvider extends ChangeNotifier {
  int _myDayIndex = 0;
  int _selectedPageIndex = 0;
  int navGroupsLength = 0;

  Size _size = const Size(0, 0);

  bool _largeScreen = false;
  bool _hugeScreen = false;
  bool _smallScreen = false;

  bool _win11 = false;
  bool isTablet = false;

  // not sure if this is needed yet
  bool isMobile = false;

  bool _drawerOpened = true;
  double _navDrawerWidth = Constants.navigationDrawerMaxWidth;
  bool _dragging = false;

  bool _footerTween = false;

  bool _navGroupsExpanded = false;

  PackageInfo _packageInfo = PackageInfo(
    appName: "",
    packageName: "",
    version: "",
    buildNumber: "",
    buildSignature: "",
    installerStore: "",
  );

  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  late WindowsDeviceInfo _windowsDeviceInfo;

  int get myDayIndex => _myDayIndex;

  set myDayIndex(int index) {
    _myDayIndex = index;
    notifyListeners();
  }

  int get selectedPageIndex => _selectedPageIndex;

  set selectedPageIndex(int newIndex) {
    _selectedPageIndex = newIndex;
    notifyListeners();
  }

  set initPageIndex(int newIndex) {
    _selectedPageIndex = newIndex;
  }

  Size get size => _size;

  set size(Size newSize) {
    _size = newSize;
    _smallScreen = width <= Constants.smallScreen;
    _largeScreen = width >= Constants.largeScreen;
    _hugeScreen = width >= Constants.hugeScreen;
    if (_myDayIndex == Constants.tabs.length - 1 && wideView) {
      _myDayIndex = 0;
    }
  }

  double get height => size.height;

  double get width => size.width;

  bool get dragging => _dragging;

  set dragging(bool drag) {
    _dragging = drag;
    notifyListeners();
  }

  bool get drawerOpened => _drawerOpened;

  set drawerOpened(bool opened) {
    _drawerOpened = opened;
    if (_myDayIndex == Constants.tabs.length - 1 && wideView) {
      _myDayIndex = 0;
    }
    notifyListeners();
  }

  double get navDrawerWidth => _navDrawerWidth;

  set navDrawerWidth(double navDrawerWidth) {
    _navDrawerWidth = navDrawerWidth;

    if (_myDayIndex == Constants.tabs.length - 1 && wideView) {
      _myDayIndex = 0;
    }

    notifyListeners();
  }

  bool get navGroupsExpanded => _navGroupsExpanded;

  set navGroupsExpanded(bool expanded) {
    bool notify = expanded ^ _navGroupsExpanded;
    _navGroupsExpanded = expanded;
    if (notify) {
      notifyListeners();
    }
  }

  bool get footerTween => _footerTween;

  set footerTween(bool tween) {
    bool notify = tween ^ _footerTween;
    _footerTween = tween;
    if (notify) {
      notifyListeners();
    }
  }

  // This is a hacky, hacky way of creating a footer.
  // ie. number of tiles + user tile + room for 1 extra tile *
  // approx tile height in lp.

  double get tileSpace =>
      (Constants.viewRoutes.length + 2) * Constants.navDestinationHeight +
      2.5 * Constants.doublePadding;

  double get tileSpaceOpened =>
      (Constants.viewRoutes.length + 4 + navGroupsLength) *
          Constants.navDestinationHeight +
      3 * Constants.padding;

  double get footerOffset => max(size.height - tileSpace, 0);

  double get footerOffsetOpened => max(size.height - tileSpaceOpened, 0);

  bool get smallScreen => _smallScreen;

  bool get largeScreen => _largeScreen;

  bool get hugeScreen => _hugeScreen;

  bool get wideView =>
      _hugeScreen ||
      (_largeScreen &&
          (!_drawerOpened ||
              // This is because of dragging
              _navDrawerWidth < Constants.navigationDrawerMinThreshold));

  // TODO: this is possibly best to put in themeprovider.
  bool get win11 => _win11;

  PackageInfo get packageInfo => _packageInfo;

  // set win11(bool isWin11) {
  //   _win11 = isWin11;
  //   notifyListeners();
  // }

  // CONSTRUCTOR
  LayoutProvider() {
    init().whenComplete(() {
      notifyListeners();
    });
  }

  // Right now, all that's needed is windows.
  // io handles most other cases.
  // Notifies.
  Future<void> init() async {
    _packageInfo = await PackageInfo.fromPlatform();
    if (Platform.isWindows) {
      _windowsDeviceInfo = await _deviceInfoPlugin.windowsInfo;
      _win11 = (_windowsDeviceInfo.buildNumber >= 22000);
    }
  }
}
