import 'package:flutter/material.dart';

class ApplicationService {
  static final ApplicationService _instance = ApplicationService._internal();
  static ApplicationService get instance => _instance;

  // This is req'd for handling major errors, eg. multiple users existing, missing user, etc.
  final GlobalKey<NavigatorState> globalNavigatorKey =
      GlobalKey<NavigatorState>();

  ApplicationService._internal();
}
