import 'package:flutter/material.dart';

class ViewRoute {
  final String name;
  final NavigationDrawerDestination destination;
  final Widget view;
  final bool inMainNav;

  const ViewRoute(
      {required this.name,
      required this.destination,
      required this.view,
      required this.inMainNav});
}
