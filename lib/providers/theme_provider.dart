import 'dart:io';

import 'package:flex_seed_scheme/flex_seed_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';

import '../model/user/user.dart';
import '../util/constants.dart';
import '../util/enums.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData? _themeData;
  ThemeData? _lightTheme;
  ThemeData? _darkTheme;
  ThemeData? _hiLight;
  ThemeData? _hiDark;

  late Color _primarySeed;
  Color? _secondarySeed;
  Color? _tertiarySeed;

  late FlexTones Function(Brightness brightness) _flexTone;

  late ThemeType _themeType;
  late ToneMapping _toneMapping;
  late Effect? _windowEffect;

  User? user;

  ThemeData? get themeData => _themeData;

  set themeData(ThemeData? newTheme) {
    _themeData = newTheme;
    notifyListeners();
  }

  ThemeData? get lightTheme => _lightTheme;

  ThemeData? get darkTheme => _darkTheme;

  ThemeData? get highContrastLight => _hiLight;

  ThemeData? get highContrastDark => _hiDark;

  Color get primarySeed => _primarySeed;

  //Notifies.
  set primarySeed(Color newColor) {
    _primarySeed = newColor;
    user?.primarySeed = newColor.value;
    generateThemes();
    setTheme(theme: _themeType);
  }

  Color? get secondarySeed => _secondarySeed;

  //Notifies.
  set secondarySeed(Color? newColor) {
    _secondarySeed = newColor;
    user?.secondarySeed = newColor?.value;
    generateThemes();
    setTheme(theme: _themeType);
  }

  Color? get tertiarySeed => _tertiarySeed;

  //Notifies.
  set tertiarySeed(Color? newColor) {
    _tertiarySeed = newColor;
    user?.tertiarySeed = newColor?.value;
    generateThemes();
    setTheme(theme: _themeType);
  }

  ThemeType get themeType => _themeType;

  //Notifies.
  set themeType(ThemeType newThemeType) {
    _themeType = newThemeType;
    user?.themeType = newThemeType;
    setTheme(theme: _themeType);
  }

  ToneMapping get toneMapping => _toneMapping;

  //Notifies.
  set toneMapping(ToneMapping newToneMapping) {
    _toneMapping = newToneMapping;
    user?.toneMapping = newToneMapping;
    generateThemes();
    setTheme(theme: _themeType);
  }

  Effect get windowEffect => _windowEffect!;

  //Notifies.
  set windowEffect(Effect newEffect) {
    _windowEffect = newEffect;
    user?.windowEffect = newEffect;
    setWindowEffect(effect: _windowEffect);
  }

  void setUser({User? newUser}) {
    user = newUser;
    notifyListeners();
  }

  ThemeProvider({this.user, ThemeData? themeData}) : _themeData = themeData {
    init();
  }

  // Generate according to user params.
  void init() {
    // Get colors
    _primarySeed =
        Color(user?.primarySeed ?? Constants.defaultPrimaryColorSeed);
    _secondarySeed =
        (null != user?.secondarySeed) ? Color(user!.secondarySeed!) : null;
    _tertiarySeed =
        (null != user?.tertiarySeed) ? Color(user!.tertiarySeed!) : null;

    // Get tonemapping.
    setToneMapping(tone: user?.toneMapping);

    // Generate Themes.
    generateThemes();

    // Set the theme, fall back to system.
    _themeData = getTheme(theme: user?.themeType ?? ThemeType.system);

    // Set the window effect for desktop. Runs asynchronously, should be set by the time
    // the splash screen is done.
    if (!Platform.isIOS || !Platform.isAndroid) {
      setWindowEffect();
    }
  }

  // Doesn't notify.
  void generateThemes() {
    _lightTheme = ThemeData(
      colorScheme: SeedColorScheme.fromSeeds(
          brightness: Brightness.light,
          primaryKey: _primarySeed,
          secondaryKey: _secondarySeed,
          tertiaryKey: _tertiarySeed,
          tones: _flexTone(Brightness.light)),
      useMaterial3: true,
    );
    _darkTheme = ThemeData(
      colorScheme: SeedColorScheme.fromSeeds(
          brightness: Brightness.dark,
          primaryKey: _primarySeed,
          secondaryKey: _secondarySeed,
          tertiaryKey: _tertiarySeed,
          tones: _flexTone(Brightness.dark)),
      useMaterial3: true,
    );
    _hiDark = ThemeData(
      colorScheme: SeedColorScheme.fromSeeds(
          brightness: Brightness.dark,
          primaryKey: _primarySeed,
          secondaryKey: _secondarySeed,
          tertiaryKey: _tertiarySeed,
          tones: (user?.useUltraHighContrast ?? false)
              ? FlexTones.ultraContrast(Brightness.dark)
              : FlexTones.highContrast(Brightness.dark)),
      useMaterial3: true,
    );

    _hiLight = ThemeData(
      colorScheme: SeedColorScheme.fromSeeds(
          brightness: Brightness.light,
          primaryKey: _primarySeed,
          secondaryKey: _secondarySeed,
          tertiaryKey: _tertiarySeed,
          tones: (user?.useUltraHighContrast ?? false)
              ? FlexTones.ultraContrast(Brightness.light)
              : FlexTones.highContrast(Brightness.light)),
      useMaterial3: true,
    );
  }

  // Doesn't notify.
  ThemeData? getTheme({ThemeType? theme = ThemeType.system}) {
    theme = theme ?? ThemeType.system;
    return switch (theme) {
      ThemeType.system => null,
      ThemeType.light => _lightTheme,
      ThemeType.dark => _darkTheme,
      ThemeType.hi_contrast_light => _hiLight,
      ThemeType.hi_contrast_dark => _hiDark,
    };
  }

  // Notifies
  void setTheme({ThemeType? theme = ThemeType.system}) {
    themeData = getTheme(theme: theme);
  }

  // Doesn't notify.
  FlexTones Function(Brightness brightness) getToneMapping(
      {ToneMapping? tone = ToneMapping.system}) {
    tone = tone ?? ToneMapping.system;
    return switch (tone) {
      ToneMapping.system => FlexTones.material,
      ToneMapping.soft => FlexTones.soft,
      ToneMapping.vivid => FlexTones.vivid,
      ToneMapping.monochromatic => FlexTones.oneHue,
      ToneMapping.hi_contrast => FlexTones.highContrast,
      ToneMapping.ultra_hi_contrast => FlexTones.ultraContrast,
    };
  }

  // Doesn't notify.
  void setToneMapping({ToneMapping? tone = ToneMapping.system}) {
    _flexTone = getToneMapping(tone: tone);
  }

  Brightness getBrightness() {
    return switch (_themeType) {
      ThemeType.system =>
        WidgetsBinding.instance.platformDispatcher.platformBrightness,
      ThemeType.light || ThemeType.hi_contrast_light => Brightness.light,
      ThemeType.dark || ThemeType.hi_contrast_dark => Brightness.dark,
    };
  }

  Future<void> setWindowEffect({Effect? effect = Effect.disabled}) async {
    if (Platform.isIOS || Platform.isAndroid || Platform.isLinux) {
      return;
    }
    effect = effect ?? Effect.disabled;
    switch (effect) {
      case Effect.disabled:
        // if (Platform.isLinux) {
        //   break;
        // }
        await _setWinMacWindow(effect: WindowEffect.disabled);
        break;
      case Effect.transparent:
        // if (Platform.isLinux) {
        //   break;
        // }
        await _setWinMacWindow(effect: WindowEffect.transparent);
        break;
      case Effect.aero:
        // if (Platform.isLinux) {
        //   break;
        // }

        await _setWinMacWindow(effect: WindowEffect.aero);

        break;
      case Effect.acrylic:
        // if (Platform.isLinux) {
        //   break;
        // }
        await _setWinMacWindow(effect: WindowEffect.acrylic);
        break;
      case Effect.sidebar:
        if (!Platform.isMacOS) {
          break;
        }
        await _setWinMacWindow(effect: WindowEffect.sidebar);
        break;
    }
    notifyListeners();
  }

  Future<void> _setWinMacWindow({
    effect = WindowEffect.transparent,
  }) async {
    Brightness brightness = getBrightness();
    Color backgroundColor = (Platform.isMacOS)
        ? Colors.transparent
        : (brightness == Brightness.light)
            ? Constants.windowsDefaultLight
            : Constants.windowsDefaultDark;

    Window.setEffect(
      effect: effect,
      color: backgroundColor,
      dark: brightness == Brightness.dark,
    );

    if (Platform.isMacOS && _themeType != ThemeType.system) {
      await Window.overrideMacOSBrightness(
        dark: brightness == Brightness.dark,
      );
    }
  }
}
