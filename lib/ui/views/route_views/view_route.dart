import 'package:flutter/material.dart';

class ViewRoute {
  final String name;
  final NavigationDrawerDestination? destination;
  final Widget view;

  const ViewRoute({required this.name, this.destination, required this.view});
}
