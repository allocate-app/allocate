import "dart:io";

import "package:allocate/ui/widgets/check_delete_dialog.dart";
import "package:auto_size_text/auto_size_text.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";

import "../../../providers/theme_provider.dart";
import "../../../providers/user_provider.dart";
import "../../../util/constants.dart";
import "../../../util/enums.dart";
import "../../../util/numbers.dart";
import "../../widgets/settings_screen_widgets.dart";

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreen();
}

class _UserSettingsScreen extends State<UserSettingsScreen> {
  // For testing
  late bool _mockOnline;
  late bool _checkClose;
  late bool _checkDelete;
  late DeleteSchedule _deleteSchedule;

  late final UserProvider userProvider;
  late final ThemeProvider themeProvider;

  late final ScrollController mobileScrollController;
  late final ScrollController desktopScrollController;
  late final ScrollPhysics scrollPhysics;

  late double _testWeight;

  late bool _toneMappingOpened;
  late bool _windowEffectOpened;
  late bool _deleteScheduleOpened;

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
    _deleteScheduleOpened = false;
    _checkClose = true;
    _checkDelete = true;
    _deleteSchedule = DeleteSchedule.never;

    _scaffoldController = MenuController();
    _sidebarController = MenuController();

    mobileScrollController = ScrollController();
    desktopScrollController = ScrollController();
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

  // TODO: REMOVE THIS ONCE USER FINISHED.
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

  void anchorWatchScroll() {
    _scaffoldController.close();
    _sidebarController.close();
  }

  // TODO: refactor consumer to use AppProvider once written
  @override
  Widget build(BuildContext context) {
    MediaQuery.sizeOf(context);

    return Consumer<UserProvider>(
        builder: (BuildContext context, UserProvider value, Widget? child) {
      return (userProvider.wideView)
          ? buildWide(context: context)
          : buildRegular(context: context);
    });
  }

  Widget buildWide({required BuildContext context}) {
    return Padding(
      padding: const EdgeInsets.all(Constants.padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildHeader(),
          Flexible(
            child: Scrollbar(
              controller: desktopScrollController,
              thumbVisibility: true,
              child: ListView(
                padding: const EdgeInsets.only(
                    left: Constants.halfPadding,
                    right: Constants.doublePadding),
                shrinkWrap: true,
                controller: desktopScrollController,
                physics: scrollPhysics,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: Constants.quadPadding +
                                      Constants.doublePadding +
                                      Constants.padding),
                              child: buildEnergyTile(),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                top: Constants.quadPadding,
                                bottom: Constants.doublePadding,
                              ),
                              child: buildQuickInfo(),
                            ),
                            const Padding(
                              padding:
                                  EdgeInsets.all(Constants.halfPadding - 1),
                              child: SizedBox.shrink(),
                            ),
                            buildAccountSection(),
                            buildSignOut(),
                            buildDeleteAccount(),
                          ],
                        ),
                      ),
                      Flexible(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: Constants.doublePadding),
                          child: ListView(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            children: [
                              buildGeneralSection(),
                              buildAccessibilitySection(),
                              buildThemeSection(),
                              const Padding(
                                padding: EdgeInsets.all(Constants.padding),
                                child: SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRegular({required BuildContext context}) {
    return Padding(
        padding: const EdgeInsets.all(Constants.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header.
            buildHeader(),
            Flexible(
              child: Scrollbar(
                controller: mobileScrollController,
                thumbVisibility: true,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Constants.halfPadding),
                  shrinkWrap: true,
                  physics: scrollPhysics,
                  controller: mobileScrollController,
                  children: [
                    buildEnergyTile(),
                    buildQuickInfo(),
                    // ACCOUNT SETTNIGS
                    buildAccountSection(),
                    // GENERAL SETTINGS
                    buildGeneralSection(),
                    // ACCESSIBILITY
                    buildAccessibilitySection(),
                    // THEME
                    buildThemeSection(),
                    // ABOUT
                    buildAboutSection(),
                    // SIGN OUT
                    buildSignOut(),

                    // DELETE ACCOUNT
                    buildDeleteAccount(),
                    const Padding(
                      padding: EdgeInsets.all(Constants.padding),
                      child: SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ));
  }

  Widget buildQuickInfo() {
    return SettingsScreenWidgets.userQuickInfo(
        outerPadding: const EdgeInsets.only(bottom: Constants.halfPadding),
        user: userProvider.curUser);
  }

  Widget buildEnergyTile({double maxScale = 1.5}) {
    return SettingsScreenWidgets.energyTile(
      weight: userProvider.curUser?.bandwidth.toDouble() ?? _testWeight,
      batteryScale: remap(
              x: userProvider.width
                  .clamp(Constants.smallScreen, Constants.largeScreen),
              inMin: Constants.smallScreen,
              inMax: Constants.largeScreen,
              outMin: 1,
              outMax: maxScale)
          .toDouble(),
      handleWeightChange: handleWeightChange,
    );
  }

  Widget buildHeader() {
    return ListTile(
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
    );
  }

  Widget buildAccountSection() {
    return SettingsScreenWidgets.settingsSection(
      context: context,
      title: "Account",
      entries: [
        (userProvider.curUser?.syncOnline ?? _mockOnline)
            ? SettingsScreenWidgets.tapTile(
                leading: const Icon(Icons.sync_rounded),
                title: "Sync now",
                onTap: () async {
                  //
                  print("Sync now");
                })
            : SettingsScreenWidgets.tapTile(
                leading: const Icon(Icons.cloud_sync_rounded),
                title: "Cloud backup",
                onTap: () {
                  print("Sign up");
                }),
        if (userProvider.curUser?.syncOnline ?? _mockOnline)
          SettingsScreenWidgets.tapTile(
            leading: const Icon(Icons.email_rounded),
            title: "Change email",
            onTap: () {
              print("Edit Email");
            },
          ),
        if (userProvider.curUser?.syncOnline ?? _mockOnline)
          SettingsScreenWidgets.tapTile(
              leading: const Icon(Icons.lock_reset_rounded),
              title: "Reset password",
              onTap: () {
                print("Edit Password");
              }),
        SettingsScreenWidgets.tapTile(
            leading: const Icon(Icons.account_circle_rounded),
            title: "Add new account",
            onTap: () {
              print("New Account");
            }),
      ],
    );
  }

  Widget buildGeneralSection() {
    return SettingsScreenWidgets.settingsSection(
      context: context,
      title: "General",
      entries: [
        //  Check close.
        SettingsScreenWidgets.toggleTile(
            leading: const Icon(Icons.close_rounded),
            value: userProvider.curUser?.checkClose ?? _checkClose,
            title: "Ask before closing",
            onChanged: (bool value) {
              userProvider.curUser?.checkClose = value;
              if (mounted) {
                setState(() {
                  _checkClose = value;
                });
              }
            }),

        SettingsScreenWidgets.toggleTile(
            leading: const Icon(Icons.delete_outline_rounded),
            title: "Ask before deleting",
            value: userProvider.curUser?.checkDelete ?? _checkDelete,
            onChanged: (bool value) {
              userProvider.curUser?.checkDelete = value;
              if (mounted) {
                setState(() {
                  _checkDelete = value;
                });
              }
            }),
        SettingsScreenWidgets.radioDropDown(
            groupMember:
                userProvider.curUser?.deleteSchedule ?? _deleteSchedule,
            values: DeleteSchedule.values,
            title: "Keep deleted items:",
            getName: Constants.deleteScheduleType,
            initiallyExpanded: _deleteScheduleOpened,
            onExpansionChanged: ({bool expanded = false}) {
              if (mounted) {
                _deleteScheduleOpened = expanded;
              }
            },
            onChanged: (DeleteSchedule? newSchedule) {
              if (null == newSchedule) {
                return;
              }
              userProvider.curUser?.deleteSchedule = newSchedule;
              if (mounted) {
                setState(() {
                  _deleteSchedule = newSchedule;
                });
              }
            }),
      ],
    );
  }

  Widget buildAccessibilitySection() {
    return SettingsScreenWidgets.settingsSection(
      context: context,
      title: "Accessibility",
      entries: [
        // Reduce motion.
        SettingsScreenWidgets.toggleTile(
            leading: const Icon(Icons.slow_motion_video_rounded),
            title: "Reduce motion",
            value: themeProvider.reduceMotion,
            onChanged: (bool value) {
              themeProvider.reduceMotion = value;
              if (mounted) {
                setState(() {});
              }
            }),
        // Use Ultra high Contrast.
        SettingsScreenWidgets.toggleTile(
            leading: const Icon(Icons.contrast_rounded),
            title: "Ultra contrast",
            value: themeProvider.useUltraHighContrast,
            onChanged: (bool value) {
              themeProvider.useUltraHighContrast = value;
              if (mounted) {
                setState(() {});
              }
            }),
      ],
    );
  }

  Widget buildThemeHuge() {
    return Flexible(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SettingsScreenWidgets
                .settingsSection(title: "Theme", context: context, entries: [
              // ThemeType
              DefaultTabController(
                initialIndex: themeProvider.themeType.index,
                length: ThemeType.values.length,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: Constants.padding),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(
                          Radius.circular(Constants.roundedCorners)),
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                    child: TabBar(
                      onTap: (newIndex) {
                        themeProvider.themeType = ThemeType.values[newIndex];
                      },
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: const BorderRadius.all(
                              Radius.circular(Constants.roundedCorners))),
                      splashBorderRadius: const BorderRadius.all(
                          Radius.circular(Constants.roundedCorners)),
                      dividerColor: Colors.transparent,
                      tabs: ThemeType.values
                          .map((ThemeType type) => Tab(
                                text: toBeginningOfSentenceCase(type.name),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),

              // Color seeds.
              SettingsScreenWidgets.colorSeedTile(
                  context: context,
                  recentColors: themeProvider.recentColors,
                  color: themeProvider.primarySeed,
                  onColorChanged: (Color newColor) {
                    themeProvider.primarySeed = newColor;
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  colorType: "Primary color",
                  icon: const Icon(Icons.eject_rounded),
                  showTrailing: Constants.defaultPrimaryColorSeed !=
                      themeProvider.primarySeed.value,
                  restoreDefault: () {
                    themeProvider.primarySeed =
                        const Color(Constants.defaultPrimaryColorSeed);
                    if (mounted) {
                      setState(() {});
                    }
                  }),
              SettingsScreenWidgets.colorSeedTile(
                  context: context,
                  recentColors: themeProvider.recentColors,
                  onColorChanged: (Color newColor) {
                    themeProvider.secondarySeed = newColor;
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  color: themeProvider.secondarySeed,
                  colorType: "Secondary color",
                  showTrailing: null != themeProvider.secondarySeed,
                  restoreDefault: () {
                    themeProvider.secondarySeed = null;
                    if (mounted) {
                      setState(() {});
                    }
                  }),
              SettingsScreenWidgets.colorSeedTile(
                  context: context,
                  recentColors: themeProvider.recentColors,
                  onColorChanged: (Color newColor) {
                    themeProvider.tertiarySeed = newColor;
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  color: themeProvider.tertiarySeed,
                  colorType: "Tertiary color",
                  showTrailing: null != themeProvider.tertiarySeed,
                  restoreDefault: () {
                    themeProvider.tertiarySeed = null;
                    if (mounted) {
                      setState(() {});
                    }
                  }),
            ]),
          ),
          Flexible(
            child: SettingsScreenWidgets.settingsSection(
              title: " ",
              context: context,
              entries: [
                // Tonemapping radiobutton
                SettingsScreenWidgets.radioDropDown(
                    leading: const Icon(Icons.colorize_rounded),
                    title: "Tonemapping",
                    groupMember: themeProvider.toneMapping,
                    values: ToneMapping.values,
                    initiallyExpanded: _toneMappingOpened,
                    onExpansionChanged: ({bool expanded = false}) {
                      if (mounted) {
                        _toneMappingOpened = expanded;
                      }
                    },
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
                    }),

                // Window effects
                if (!userProvider.isMobile) ...[
                  SettingsScreenWidgets.radioDropDown(
                    initiallyExpanded: _windowEffectOpened,
                    leading: const Icon(Icons.color_lens_outlined),
                    title: "Window effect",
                    children: getAvailableWindowEffects(),
                    groupMember: themeProvider.windowEffect,
                    values: Effect.values,
                  ),
                  // Transparency - use the dropdown slider.
                  SettingsScreenWidgets.sliderTile(
                    title: "Sidebar opacity",
                    leading: const Icon(Icons.gradient_rounded),
                    label: "${(100 * themeProvider.sidebarOpacity).toInt()}",
                    onOpen: () {
                      mobileScrollController.addListener(anchorWatchScroll);
                    },
                    onClose: () {
                      mobileScrollController.removeListener(anchorWatchScroll);
                    },
                    onChanged: (themeProvider.useTransparency)
                        ? (double value) {
                            themeProvider.sidebarOpacity = value;
                            if (mounted) {
                              setState(() {});
                            }
                          }
                        : null,
                    onChangeEnd: (double value) {
                      themeProvider.sidebarOpacitySavePref = value;
                      _sidebarController.close();
                      if (mounted) {
                        setState(() {});
                      }
                    },
                    value: themeProvider.sidebarOpacity,
                    controller: _sidebarController,
                  ),

                  SettingsScreenWidgets.sliderTile(
                    title: "Window opacity",
                    leading: const Icon(Icons.gradient_rounded),
                    label: "${(100 * themeProvider.scaffoldOpacity).toInt()}",
                    onOpen: () {
                      mobileScrollController.addListener(anchorWatchScroll);
                    },
                    onClose: () {
                      mobileScrollController.removeListener(anchorWatchScroll);
                    },
                    onChanged: (themeProvider.useTransparency)
                        ? (double value) {
                            themeProvider.scaffoldOpacity = value;
                            if (mounted) {
                              setState(() {});
                            }
                          }
                        : null,
                    onChangeEnd: (double value) {
                      themeProvider.scaffoldOpacitySavePref = value;
                      _scaffoldController.close();
                      if (mounted) {
                        setState(() {});
                      }
                    },
                    value: themeProvider.scaffoldOpacity,
                    controller: _scaffoldController,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildThemeSection() {
    return SettingsScreenWidgets.settingsSection(
        context: context,
        title: "Theme",
        entries: [
          // ThemeType
          DefaultTabController(
            initialIndex: themeProvider.themeType.index,
            length: ThemeType.values.length,
            child: Padding(
              padding: const EdgeInsets.only(bottom: Constants.padding),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(
                      Radius.circular(Constants.roundedCorners)),
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
                child: TabBar(
                  onTap: (newIndex) {
                    themeProvider.themeType = ThemeType.values[newIndex];
                  },
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: const BorderRadius.all(
                          Radius.circular(Constants.roundedCorners))),
                  splashBorderRadius: const BorderRadius.all(
                      Radius.circular(Constants.roundedCorners)),
                  dividerColor: Colors.transparent,
                  tabs: ThemeType.values
                      .map((ThemeType type) => Tab(
                            text: toBeginningOfSentenceCase(type.name),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),

          // Color seeds.
          SettingsScreenWidgets.colorSeedTile(
              context: context,
              recentColors: themeProvider.recentColors,
              color: themeProvider.primarySeed,
              onColorChanged: (Color newColor) {
                themeProvider.primarySeed = newColor;
                if (mounted) {
                  setState(() {});
                }
              },
              colorType: "Primary color",
              icon: const Icon(Icons.eject_rounded),
              showTrailing: Constants.defaultPrimaryColorSeed !=
                  themeProvider.primarySeed.value,
              restoreDefault: () {
                themeProvider.primarySeed =
                    const Color(Constants.defaultPrimaryColorSeed);
                if (mounted) {
                  setState(() {});
                }
              }),
          SettingsScreenWidgets.colorSeedTile(
              context: context,
              recentColors: themeProvider.recentColors,
              onColorChanged: (Color newColor) {
                themeProvider.secondarySeed = newColor;
                if (mounted) {
                  setState(() {});
                }
              },
              color: themeProvider.secondarySeed,
              colorType: "Secondary color",
              showTrailing: null != themeProvider.secondarySeed,
              restoreDefault: () {
                themeProvider.secondarySeed = null;
                if (mounted) {
                  setState(() {});
                }
              }),
          SettingsScreenWidgets.colorSeedTile(
              context: context,
              recentColors: themeProvider.recentColors,
              onColorChanged: (Color newColor) {
                themeProvider.tertiarySeed = newColor;
                if (mounted) {
                  setState(() {});
                }
              },
              color: themeProvider.tertiarySeed,
              colorType: "Tertiary color",
              showTrailing: null != themeProvider.tertiarySeed,
              restoreDefault: () {
                themeProvider.tertiarySeed = null;
                if (mounted) {
                  setState(() {});
                }
              }),

          // Tonemapping radiobutton
          SettingsScreenWidgets.radioDropDown(
              leading: const Icon(Icons.colorize_rounded),
              title: "Tonemapping",
              groupMember: themeProvider.toneMapping,
              values: ToneMapping.values,
              initiallyExpanded: _toneMappingOpened,
              onExpansionChanged: ({bool expanded = false}) {
                if (mounted) {
                  _toneMappingOpened = expanded;
                }
              },
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
              }),

          // Window effects
          if (!userProvider.isMobile) ...[
            SettingsScreenWidgets.radioDropDown(
              initiallyExpanded: _windowEffectOpened,
              leading: const Icon(Icons.color_lens_outlined),
              title: "Window effect",
              children: getAvailableWindowEffects(),
              groupMember: themeProvider.windowEffect,
              values: Effect.values,
            ),
            // Transparency - use the dropdown slider.
            SettingsScreenWidgets.sliderTile(
              title: "Sidebar opacity",
              leading: const Icon(Icons.gradient_rounded),
              label: "${(100 * themeProvider.sidebarOpacity).toInt()}",
              onOpen: () {
                mobileScrollController.addListener(anchorWatchScroll);
              },
              onClose: () {
                mobileScrollController.removeListener(anchorWatchScroll);
              },
              onChanged: (themeProvider.useTransparency)
                  ? (double value) {
                      themeProvider.sidebarOpacity = value;
                      if (mounted) {
                        setState(() {});
                      }
                    }
                  : null,
              onChangeEnd: (double value) {
                themeProvider.sidebarOpacitySavePref = value;
                _sidebarController.close();
                if (mounted) {
                  setState(() {});
                }
              },
              value: themeProvider.sidebarOpacity,
              controller: _sidebarController,
            ),

            SettingsScreenWidgets.sliderTile(
              title: "Window opacity",
              leading: const Icon(Icons.gradient_rounded),
              label: "${(100 * themeProvider.scaffoldOpacity).toInt()}",
              onOpen: () {
                mobileScrollController.addListener(anchorWatchScroll);
              },
              onClose: () {
                mobileScrollController.removeListener(anchorWatchScroll);
              },
              onChanged: (themeProvider.useTransparency)
                  ? (double value) {
                      themeProvider.scaffoldOpacity = value;
                      if (mounted) {
                        setState(() {});
                      }
                    }
                  : null,
              onChangeEnd: (double value) {
                themeProvider.scaffoldOpacitySavePref = value;
                _scaffoldController.close();
                if (mounted) {
                  setState(() {});
                }
              },
              value: themeProvider.scaffoldOpacity,
              controller: _scaffoldController,
            ),
          ],
        ]);
  }

  Widget buildAboutSection() {
    return SettingsScreenWidgets.settingsSection(
        context: context,
        title: "About",
        entries: [
          SettingsScreenWidgets.tapTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: "About",
              onTap: () async {
                // Future TODO: Implement MacOS specific code for opening "about" window.
                await showDialog(
                    context: context,
                    useRootNavigator: false,
                    builder: (BuildContext context) {
                      return SettingsScreenWidgets.aboutDialog(
                        packageInfo: userProvider.packageInfo,
                      );
                    });
              }),
          SettingsScreenWidgets.tapTile(
              leading: const Icon(Icons.add_road_rounded),
              title: "Roadmap",
              onTap: () async {
                await showDialog(
                    context: context,
                    useRootNavigator: false,
                    builder: (BuildContext context) {
                      return SettingsScreenWidgets.roadmapDialog();
                    });
              }),
          // TODO: THIS MAY NEED AN EXTERNAL LICENSING SECTION.
        ]);
  }

  Widget buildSignOut() {
    return SettingsScreenWidgets.settingsSection(
      context: context,
      title: "",
      entries: [
        SettingsScreenWidgets.tapTile(
            leading: Icon(Icons.highlight_off_rounded,
                color: Theme.of(context).colorScheme.tertiary),
            title: "Sign out",
            onTap: () async {
              print("Sign out");
              // Sign out of supabase, then push to account switcher.
            }),
      ],
    );
  }

  buildDeleteAccount() {
    return SettingsScreenWidgets.settingsSection(
      context: context,
      title: "",
      entries: [
        SettingsScreenWidgets.tapTile(
            leading: Icon(Icons.delete_forever_rounded,
                color: Theme.of(context).colorScheme.error),
            textColor: Theme.of(context).colorScheme.error,
            title: "Delete account",
            onTap: () async {
              await showDialog<List<bool>?>(
                  context: context,
                  useRootNavigator: false,
                  builder: (BuildContext context) {
                    return const CheckDeleteDialog(
                      type: "Account",
                      showCheckbox: false,
                    );
                  }).then((deleteInfo) async {
                if (null == deleteInfo) {
                  return;
                }
                bool delete = deleteInfo[0];
                if (delete) {
                  print("Deleted Acount");
                  //await userProvider.deleteUser();
                  // Push to Login screen/user switcher.
                }
              });
            }),
      ],
    );
  }

  List<Widget> getAvailableWindowEffects() {
    List<Widget> validEffects = List.empty(growable: true);

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
        case Effect.sidebar:
          if (!Platform.isMacOS) {
            continue;
          }
          break;
        default:
          break;
      }

      validEffects.add(
        SettingsScreenWidgets.radioTile<Effect>(
            member: effect,
            groupValue: themeProvider.windowEffect,
            onChanged: (newEffect) {
              if (null == newEffect) {
                return;
              }

              themeProvider.windowEffect = newEffect;
              if (mounted) {
                setState(() {
                  _windowEffectOpened = false;
                });
              }
            }),
      );
    }
    return validEffects;
  }
}
