import 'dart:io';
import 'dart:ui';

import 'package:flex_seed_scheme/flex_seed_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:window_manager/window_manager.dart';

import '../ui/views/route_views/loading_screen.dart';
import '../util/constants.dart';

// This may require providers. Right now, this is just so I can build GUI things without
// having to run the entire app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  // iPadOS (and hopefully some android tablets) should ignore this.
  if (Platform.isIOS || Platform.isAndroid) {
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  } else {
    await windowManager.ensureInitialized();
    await windowManager.setResizable(true);
    // TODO: implement windows transparent titlebar.
    WindowOptions windowOptions = const WindowOptions(
      minimumSize: Constants.minDesktopSize,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      // TODO: minimize to taskbar
      // await windowManager.setPreventClose(true);
    });
  }

  // TESTING WIDGETS
  Widget testWidget = const LoadingScreen();

  runApp(WidgetTester(testWidget: testWidget));
}

class WidgetTester extends StatefulWidget {
  const WidgetTester({super.key, required this.testWidget});

  final Widget testWidget;

  @override
  State<WidgetTester> createState() => _WidgetTester();
}

class _WidgetTester extends State<WidgetTester> {
  // Basic themes.
  ThemeData lightTheme = ThemeData(
    colorScheme: SeedColorScheme.fromSeeds(
      brightness: Brightness.light,
      primaryKey: const Color(Constants.defaultPrimaryColorSeed),
      tones: FlexTones.material(Brightness.light),
    ),
  );
  ThemeData darkTheme = ThemeData(
    colorScheme: SeedColorScheme.fromSeeds(
      brightness: Brightness.dark,
      primaryKey: const Color(Constants.defaultPrimaryColorSeed),
      tones: FlexTones.material(Brightness.dark),
    ),
  );

  @override
  Widget build(BuildContext context) => TitlebarSafeArea(
        child: MaterialApp(
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.system,
          home: widget.testWidget,
        ),
      );
}
