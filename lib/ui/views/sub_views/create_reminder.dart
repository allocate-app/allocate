import 'package:flutter/material.dart';
import 'package:test/expect.dart';

import '../../../util/constants.dart';

class CreateReminderScreen extends StatefulWidget{
  const CreateReminderScreen({Key? key}): super(key: key);

  @override
  State<CreateReminderScreen> createState() => _CreateReminderScreen();

}

class _CreateReminderScreen extends State<CreateReminderScreen> {


  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final Color errorColor = Theme
        .of(context)
        .colorScheme
        .error;

    bool largeScreen = (MediaQuery
        .of(context)
        .size
        .width >= Constants.largeScreen);
    bool smallScreen = (MediaQuery
        .of(context)
        .size
        .width <= Constants.smallScreen);
    return (largeScreen)
        ? buildDesktopDialog(context, smallScreen, errorColor)
        : buildMobileDialog(context, smallScreen, errorColor);
  }

  Dialog buildDesktopDialog(BuildContext context, bool smallScreen,
      Color errorColor) {
    throw UnimplementedError();
  }

  Dialog buildMobileDialog(BuildContext context, bool smallScreen,
      Color errorColor) {
    throw UnimplementedError();
  }
}
