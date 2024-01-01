import "dart:io";
import "dart:math";

import "package:auto_size_text/auto_size_text.dart";
import "package:flex_color_picker/flex_color_picker.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";

import "../../../providers/theme_provider.dart";
import "../../../providers/user_provider.dart";
import "../../../util/constants.dart";
import "../../../util/enums.dart";
import "../../../util/numbers.dart";
import "../../widgets/expanded_listtile.dart";
import "../../widgets/settings_screen_widgets.dart";

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreen();
}

class _UserSettingsScreen extends State<UserSettingsScreen> {
  // For testing
  late bool _mockOnline;

  late final UserProvider userProvider;
  late final ThemeProvider themeProvider;

  late final ScrollController scrollController;
  late final ScrollPhysics scrollPhysics;

  late double _testWeight;

  late bool _toneMappingOpened;
  late bool _windowEffectOpened;

  late MenuController _scaffoldController;
  late MenuController _sidebarController;

  @override
  void initState() {
    userProvider = Provider.of<UserProvider>(context, listen: false);
    themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _testWeight = userProvider.curUser?.bandwidth.toDouble() ??
        Constants.maxBandwidthDouble;

    _mockOnline = true;
    _toneMappingOpened = false;
    _windowEffectOpened = false;

    _scaffoldController = MenuController();
    _sidebarController = MenuController();

    scrollController = ScrollController();
    ScrollPhysics scrollBehaviour = (Platform.isMacOS || Platform.isIOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
    scrollPhysics = AlwaysScrollableScrollPhysics(parent: scrollBehaviour);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void handleWeightChange(double? value) {
    if (null == value) {
      return;
    }
    if (mounted) {
      setState(() {
        userProvider.curUser?.bandwidth = value.toInt();
        _testWeight = value;
      });
    }
  }

  // This will need two layouts.
  // TODO: consume userProvider?
  @override
  Widget build(BuildContext context) {
    MediaQuery.sizeOf(context);
    return Padding(
        padding: const EdgeInsets.all(Constants.padding),
        // Mobile Layout.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(Constants.padding),
              leading: const Icon(Icons.settings_rounded),
              title: const AutoSizeText(
                "Settings",
                style: Constants.largeHeaderStyle,
                softWrap: false,
                maxLines: 1,
                overflow: TextOverflow.visible,
                minFontSize: Constants.huge,
              ),
              // TODO: factor this into a method.
              // As follows: connected => outlined online status, syncOnline => signIn button, none => signUp button
              trailing: (userProvider.curUser?.syncOnline ?? _mockOnline)
                  ? FilledButton(
                      onPressed: () {
                        if (mounted && kDebugMode) {
                          setState(() {
                            _mockOnline = !_mockOnline;
                          });
                        }
                      },
                      child: const AutoSizeText("Sign in"),
                    )
                  : FilledButton(
                      onPressed: () {
                        if (mounted && kDebugMode) {
                          setState(() {
                            _mockOnline = !_mockOnline;
                          });
                        }
                      },
                      child: const AutoSizeText("Sign up"),
                    ),
            ),
            Flexible(
              child: Scrollbar(
                controller: scrollController,
                thumbVisibility: true,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Constants.halfPadding),
                  shrinkWrap: true,
                  physics: scrollPhysics,
                  controller: scrollController,
                  children: [
                    SettingsScreenWidgets.energyTile(
                      weight: userProvider.curUser?.bandwidth.toDouble() ??
                          _testWeight,
                      batteryScale: remap(
                              x: userProvider.width.clamp(
                                  Constants.smallScreen, Constants.largeScreen),
                              inMin: Constants.smallScreen,
                              inMax: Constants.largeScreen,
                              outMin: 1,
                              outMax: 1.5)
                          .toDouble(),
                      handleWeightChange: handleWeightChange,
                    ),
                    SettingsScreenWidgets.userQuickInfo(
                        outerPadding: const EdgeInsets.only(
                            bottom: Constants.halfPadding),
                        user: userProvider.curUser),
                    // GENERAL SETTINGS
                    SettingsScreenWidgets.settingsSection(
                      context: context,
                      title: "General",
                      entries: [
                        (userProvider.curUser?.syncOnline ?? _mockOnline)
                            ? ListTile(
                                leading: const Icon(Icons.sync_rounded),
                                title: const AutoSizeText("Sync now",
                                    minFontSize: Constants.large,
                                    maxLines: 1,
                                    softWrap: true,
                                    overflow: TextOverflow.visible),
                                onTap: () {
                                  print("Sync now");
                                })
                            : ListTile(
                                leading: const Icon(Icons.cloud_sync_rounded),
                                title: const AutoSizeText("Cloud backup",
                                    minFontSize: Constants.large,
                                    maxLines: 1,
                                    softWrap: true,
                                    overflow: TextOverflow.visible),
                                onTap: () {
                                  print("Sign up");
                                }),
                        if (userProvider.curUser?.syncOnline ?? _mockOnline)
                          ListTile(
                              leading: const Icon(Icons.email_rounded),
                              title: const AutoSizeText("Change email",
                                  minFontSize: Constants.large,
                                  maxLines: 1,
                                  softWrap: true,
                                  overflow: TextOverflow.visible),
                              onTap: () {
                                print("Edit Email");
                              }),
                        if (userProvider.curUser?.syncOnline ?? _mockOnline)
                          ListTile(
                              leading: const Icon(Icons.lock_reset_rounded),
                              title: const AutoSizeText("Reset password",
                                  minFontSize: Constants.large,
                                  maxLines: 1,
                                  softWrap: true,
                                  overflow: TextOverflow.visible),
                              onTap: () {
                                print("Edit Password");
                              }),
                        ListTile(
                            leading: const Icon(Icons.account_circle_rounded),
                            title: const AutoSizeText("Add new account",
                                minFontSize: Constants.large,
                                maxLines: 1,
                                softWrap: true,
                                overflow: TextOverflow.visible),
                            onTap: () {
                              print("Edit Password");
                            }),
                      ],
                    ),

                    // THEME
                    SettingsScreenWidgets.settingsSection(
                        context: context,
                        title: "Theme",
                        entries: [
                          // ThemeType
                          DefaultTabController(
                            initialIndex: themeProvider.themeType.index,
                            length: ThemeType.values.length,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  bottom: Constants.padding),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(
                                          Constants.roundedCorners)),
                                  color:
                                      Theme.of(context).colorScheme.onSecondary,
                                ),
                                child: TabBar(
                                  onTap: (newIndex) {
                                    themeProvider.themeType =
                                        ThemeType.values[newIndex];
                                  },
                                  indicatorSize: TabBarIndicatorSize.tab,
                                  indicator: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(
                                              Constants.roundedCorners))),
                                  splashBorderRadius: const BorderRadius.all(
                                      Radius.circular(
                                          Constants.roundedCorners)),
                                  dividerColor: Colors.transparent,
                                  tabs: ThemeType.values
                                      .map((ThemeType type) => Tab(
                                            text: toBeginningOfSentenceCase(
                                                type.name),
                                          ))
                                      .toList(),
                                ),
                              ),
                            ),
                          ),

                          // Color seeds.
                          ListTile(
                              leading: CircleAvatar(
                                  backgroundColor: themeProvider.primarySeed),
                              title: const AutoSizeText(
                                  "Use ultra high contrast",
                                  minFontSize: Constants.large,
                                  maxLines: 1,
                                  softWrap: true,
                                  overflow: TextOverflow.visible),
                              // Testing. I dunno what this is.
                              trailing: ColorIndicator(
                                  color: themeProvider.primarySeed)),
                          ListTile(
                              leading: CircleAvatar(
                                backgroundColor: themeProvider.secondarySeed ??
                                    Colors.transparent,
                              ),
                              title: const AutoSizeText("Secondary color seed",
                                  minFontSize: Constants.large,
                                  maxLines: 1,
                                  softWrap: true,
                                  overflow: TextOverflow.visible),
                              trailing: IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    themeProvider.secondarySeed = null;
                                  })),
                          ListTile(
                              leading: CircleAvatar(
                                backgroundColor: themeProvider.tertiarySeed ??
                                    Colors.transparent,
                              ),
                              title: const AutoSizeText("Tertiary color seed",
                                  minFontSize: Constants.large,
                                  maxLines: 1,
                                  softWrap: true,
                                  overflow: TextOverflow.visible),
                              trailing: IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    themeProvider.tertiarySeed = null;
                                  })),

                          // Use Ultra high Contrast.
                          ListTile(
                            leading: const Icon(Icons.contrast_rounded),
                            title: const AutoSizeText("Use ultra high contrast",
                                minFontSize: Constants.large,
                                maxLines: 1,
                                softWrap: true,
                                overflow: TextOverflow.visible),
                            trailing: Consumer<ThemeProvider>(builder:
                                (BuildContext context, ThemeProvider value,
                                    Widget? child) {
                              return Switch(
                                  value: themeProvider.useUltraHighContrast,
                                  onChanged: (bool? value) {
                                    if (null == value) {
                                      return;
                                    }

                                    themeProvider.useUltraHighContrast = value;
                                  });
                            }),
                          ),

                          // Reduce motion.
                          ListTile(
                            leading:
                                const Icon(Icons.slow_motion_video_rounded),
                            title: const AutoSizeText("Reduce motion",
                                minFontSize: Constants.large,
                                maxLines: 1,
                                softWrap: true,
                                overflow: TextOverflow.visible),
                            trailing: Consumer<ThemeProvider>(builder:
                                (BuildContext context, ThemeProvider value,
                                    Widget? child) {
                              return Switch(
                                  value: themeProvider.reduceMotion,
                                  onChanged: (bool? value) {
                                    if (null == value) {
                                      return;
                                    }
                                    themeProvider.reduceMotion = value;
                                  });
                            }),
                          ),

                          // Tonemapping radiobutton
                          ExpandedListTile(
                            leading: const Icon(Icons.colorize_rounded),
                            title: const AutoSizeText("Tonemapping",
                                minFontSize: Constants.large,
                                maxLines: 1,
                                softWrap: true,
                                overflow: TextOverflow.visible),
                            initiallyExpanded: _toneMappingOpened,
                            onExpansionChanged: ({bool expanded = false}) =>
                                _toneMappingOpened = expanded,
                            children: ToneMapping.values
                                .map((toneMap) => Radio<ToneMapping>(
                                    value: toneMap,
                                    groupValue: themeProvider.toneMapping,
                                    onChanged: (ToneMapping? newMap) {
                                      if (null == newMap) {
                                        return;
                                      }
                                      themeProvider.toneMapping = newMap;
                                      if (mounted) {
                                        setState(() {
                                          _toneMappingOpened = false;
                                        });
                                      }
                                    }))
                                .toList(),
                          ),

                          // Window effects
                          if (!userProvider.isMobile)
                            ExpandedListTile(
                                initiallyExpanded: _windowEffectOpened,
                                leading: const Icon(Icons.color_lens_outlined),
                                title: const AutoSizeText("Window effect",
                                    minFontSize: Constants.large,
                                    maxLines: 1,
                                    softWrap: true,
                                    overflow: TextOverflow.visible),
                                children: getAvailableWindowEffects()),

                          // Transparency - use the dropdown slider.
                          if (!userProvider.isMobile)
                            MenuAnchor(
                                onOpen: () {
                                  scrollController.addListener(() {
                                    _sidebarController.close();
                                  });
                                },
                                onClose: () {
                                  scrollController.removeListener(() {
                                    _sidebarController.close();
                                  });
                                },
                                style: const MenuStyle(
                                    padding: MaterialStatePropertyAll(
                                        EdgeInsets.all(Constants.padding)),
                                    shape: MaterialStatePropertyAll(
                                        RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(
                                                    Constants.semiCircular))))),
                                controller: _sidebarController,
                                menuChildren: [
                                  Consumer<ThemeProvider>(builder:
                                      (BuildContext context,
                                          ThemeProvider value, Widget? child) {
                                    return SizedBox(
                                      width:
                                          min(userProvider.width * 0.75, 300),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Expanded(
                                            child: Slider(
                                                min: 0,
                                                max: 1,
                                                value: themeProvider
                                                    .sidebarOpacity,
                                                onChangeEnd: (value) {
                                                  themeProvider
                                                          .sidebarOpacitySavePref =
                                                      value;
                                                  _sidebarController.close();
                                                },
                                                onChanged: (themeProvider
                                                        .useTransparency)
                                                    ? (value) {
                                                        themeProvider
                                                                .sidebarOpacity =
                                                            value;
                                                      }
                                                    : null),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: Constants.padding),
                                            child: Text(
                                                "${(100 * themeProvider.sidebarOpacity).toInt()}",
                                                maxLines: 1,
                                                softWrap: true,
                                                overflow: TextOverflow.visible),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                                builder: (BuildContext context,
                                    MenuController controller, Widget? child) {
                                  return ListTile(
                                      leading:
                                          const Icon(Icons.gradient_rounded),
                                      title: const AutoSizeText(
                                          "Sidebar opacity",
                                          minFontSize: Constants.large,
                                          maxLines: 1,
                                          softWrap: true,
                                          overflow: TextOverflow.visible),
                                      onTap: () {
                                        if (_sidebarController.isOpen) {
                                          return _sidebarController.close();
                                        }
                                        _sidebarController.open();
                                      });
                                }),

                          if (!userProvider.isMobile)
                            MenuAnchor(
                                onOpen: () {
                                  scrollController.addListener(() {
                                    _scaffoldController.close();
                                  });
                                },
                                onClose: () {
                                  scrollController.removeListener(() {
                                    _scaffoldController.close();
                                  });
                                },
                                style: const MenuStyle(
                                    padding: MaterialStatePropertyAll(
                                        EdgeInsets.all(Constants.padding)),
                                    shape: MaterialStatePropertyAll(
                                        RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(
                                                    Constants.circular))))),
                                controller: _scaffoldController,
                                menuChildren: [
                                  Consumer<ThemeProvider>(builder:
                                      (BuildContext context,
                                          ThemeProvider value, Widget? child) {
                                    return SizedBox(
                                      width:
                                          min(userProvider.width * 0.75, 300),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Expanded(
                                            child: Slider(
                                                min: 0,
                                                max: 1,
                                                value: themeProvider
                                                    .scaffoldOpacity,
                                                onChangeEnd: (value) {
                                                  themeProvider
                                                          .scaffoldOpacitySavePref =
                                                      value;
                                                  _scaffoldController.close();
                                                },
                                                onChanged: (themeProvider
                                                        .useTransparency)
                                                    ? (value) {
                                                        themeProvider
                                                                .scaffoldOpacity =
                                                            value;
                                                      }
                                                    : null),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: Constants.padding),
                                            child: Text(
                                                "${(100 * themeProvider.scaffoldOpacity).toInt()}",
                                                maxLines: 1,
                                                softWrap: true,
                                                overflow: TextOverflow.visible),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                                builder: (BuildContext context,
                                    MenuController controller, Widget? child) {
                                  return ListTile(
                                      leading:
                                          const Icon(Icons.gradient_rounded),
                                      title: const AutoSizeText(
                                          "Window opacity",
                                          minFontSize: Constants.large,
                                          maxLines: 1,
                                          softWrap: true,
                                          overflow: TextOverflow.visible),
                                      onTap: () {
                                        if (_scaffoldController.isOpen) {
                                          return _scaffoldController.close();
                                        }
                                        _scaffoldController.open();
                                      });
                                }),
                        ]),
                    SettingsScreenWidgets.settingsSection(
                        context: context,
                        title: "About",
                        entries: [
                          ListTile(
                              leading: const Icon(Icons.info_outline_rounded),
                              title: const AutoSizeText("About",
                                  minFontSize: Constants.large,
                                  maxLines: 1,
                                  softWrap: true,
                                  overflow: TextOverflow.visible),
                              onTap: () {
                                print("About the app");
                              }),
                          ListTile(
                              leading: const Icon(Icons.add_road_rounded),
                              title: const AutoSizeText("Roadmap",
                                  minFontSize: Constants.large,
                                  maxLines: 1,
                                  softWrap: true,
                                  overflow: TextOverflow.visible),
                              onTap: () {
                                print("Roadmap");
                              }),
                        ]),
                    SettingsScreenWidgets.settingsSection(
                      context: context,
                      title: "",
                      entries: [
                        ListTile(
                            leading: Icon(Icons.highlight_off_rounded,
                                color: Theme.of(context).colorScheme.tertiary),
                            title: AutoSizeText("Sign out",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                                minFontSize: Constants.large,
                                maxLines: 1,
                                softWrap: true,
                                overflow: TextOverflow.visible),
                            onTap: () {
                              print("Sign Out");
                            }),
                      ],
                    ),
                    SettingsScreenWidgets.settingsSection(
                      context: context,
                      title: "",
                      entries: [
                        ListTile(
                            leading: Icon(Icons.delete_forever_rounded,
                                color: Theme.of(context).colorScheme.error),
                            title: AutoSizeText("Delete account",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                minFontSize: Constants.large,
                                maxLines: 1,
                                softWrap: true,
                                overflow: TextOverflow.visible),
                            onTap: () {
                              print("Delete user");
                            }),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ));
  }

  List<Widget> getAvailableWindowEffects() {
    List<Radio> validEffects = List.empty(growable: true);

    bool filterWindows = (Platform.isWindows && !userProvider.win11);
    for (Effect effect in Effect.values) {
      switch (effect) {
        case Effect.mica:
          if (Platform.isLinux || filterWindows) {
            continue;
          }
          break;
        case Effect.acrylic:
          if (Platform.isLinux || filterWindows) {
            continue;
          }
          break;
        case Effect.aero:
          if (Platform.isLinux) {
            continue;
          }
          break;
        default:
          break;
      }

      validEffects.add(
        Radio<Effect>(
            value: effect,
            groupValue: themeProvider.windowEffect,
            onChanged: (Effect? newEffect) {
              if (null == newEffect) {
                return;
              }
              themeProvider.windowEffect = newEffect;
              if (mounted) {
                setState(() => _windowEffectOpened = false);
              }
            }),
      );
    }
    return validEffects;
  }
}
