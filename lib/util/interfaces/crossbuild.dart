import 'package:flutter/material.dart';

abstract interface class CrossBuild {
  Widget buildMobile({required BuildContext context});

  Widget buildDesktop({required BuildContext context});
}
