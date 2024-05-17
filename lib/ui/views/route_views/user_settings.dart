import "dart:io";

import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";

import "../../../providers/application/layout_provider.dart";
import '../../../providers/application/theme_provider.dart';
import "../../../providers/model/deadline_provider.dart";
import "../../../providers/model/group_provider.dart";
import "../../../providers/model/reminder_provider.dart";
import "../../../providers/model/routine_provider.dart";
import "../../../providers/model/subtask_provider.dart";
import "../../../providers/model/todo_provider.dart";
import '../../../providers/model/user_provider.dart';
import "../../../providers/viewmodels/user_viewmodel.dart";
import "../../../services/application_service.dart";
import "../../../util/constants.dart";
import "../../../util/enums.dart";
import "../../../util/exceptions.dart";
import "../../../util/numbers.dart";
import "../../blurred_dialog.dart";
import "../../widgets/dialogs/check_delete_dialog.dart";
import "../../widgets/dialogs/update_email_dialog.dart";
import "../../widgets/flushbars.dart";
import "../../widgets/screen_header.dart";
import "../../widgets/settings_screen_widgets.dart";
import "../../widgets/sign_in_dialog.dart";
import "../../widgets/tiles.dart";
import "loading_screen.dart";

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreen();
}

class _UserSettingsScreen extends State<UserSettingsScreen> {
  late final UserProvider userProvider;
  late final UserViewModel vm;
  late final ToDoProvider toDoProvider;
  late final RoutineProvider routineProvider;
  late final ReminderProvider reminderProvider;
  late final DeadlineProvider deadlineProvider;
  late final GroupProvider groupProvider;
  late final SubtaskProvider subtaskProvider;

  late final ThemeProvider themeProvider;
  late final LayoutProvider layoutProvider;

  late ApplicationService applicationService;

  late final ScrollController mobileScrollController;
  late final ScrollController desktopScrollController;
  late final ScrollController desktopSideController;
  late final ScrollPhysics scrollPhysics;

  late MenuController _scaffoldController;
  late MenuController _sidebarController;

  @override
  void initState() {
    initializeProviders();

    initializeControllers();
    super.initState();
  }

  void initializeProviders() {
    userProvider = Provider.of<UserProvider>(context, listen: false);
    vm = Provider.of<UserViewModel>(context, listen: false);
    themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);

    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);
    routineProvider = Provider.of<RoutineProvider>(context, listen: false);
    reminderProvider = Provider.of<ReminderProvider>(context, listen: false);
    deadlineProvider = Provider.of<DeadlineProvider>(context, listen: false);
    groupProvider = Provider.of<GroupProvider>(context, listen: false);
    subtaskProvider = Provider.of<SubtaskProvider>(context, listen: false);

    applicationService = ApplicationService.instance;
    applicationService.addListener(scrollToTop);
  }

  void initializeControllers() {
    _scaffoldController = MenuController();
    _sidebarController = MenuController();

    mobileScrollController = ScrollController();
    desktopScrollController = ScrollController();
    desktopSideController = ScrollController();
    ScrollPhysics scrollBehaviour = (Platform.isMacOS || Platform.isIOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
    scrollPhysics = AlwaysScrollableScrollPhysics(parent: scrollBehaviour);
  }

  @override
  void dispose() {
    applicationService.removeListener(scrollToTop);
    mobileScrollController.dispose();
    desktopScrollController.dispose();
    desktopSideController.dispose();
    super.dispose();
  }

  void anchorWatchScroll() {
    _scaffoldController.close();
    _sidebarController.close();
  }

  void scrollToTop() {
    if (mobileScrollController.hasClients) {
      mobileScrollController.animateTo(
        0,
        duration: Constants.scrollDuration,
        curve: Constants.scrollCurve,
      );
    }

    if (desktopSideController.hasClients) {
      desktopSideController.animateTo(
        0,
        duration: Constants.scrollDuration,
        curve: Constants.scrollCurve,
      );
    }

    if (desktopScrollController.hasClients) {
      desktopScrollController.animateTo(
        0,
        duration: Constants.scrollDuration,
        curve: Constants.scrollCurve,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return (layoutProvider.wideView)
          ? buildWide(context: context)
          : buildRegular(context: context);
    });
  }

  Widget buildWide({required BuildContext context}) {
    Widget sideList = ListView(
      shrinkWrap: true,
      physics: scrollPhysics,
      controller: desktopSideController,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              top: Constants.quadPadding +
                  Constants.doublePadding +
                  Constants.padding),
          child: _buildEnergyTile(),
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: Constants.quadPadding,
            bottom: Constants.doublePadding,
          ),
          child: _buildQuickInfo(),
        ),
        const Padding(
          padding: EdgeInsets.all(Constants.halfPadding - 1),
          child: SizedBox.shrink(),
        ),
        _buildSignOut(),
        _buildDeleteAccount(),
      ],
    );
    Widget mainList = ListView(
      padding: const EdgeInsets.symmetric(horizontal: Constants.doublePadding),
      controller: desktopScrollController,
      physics: scrollPhysics,
      shrinkWrap: true,
      children: [
        _buildAccountSection(),
        _buildGeneralSection(),
        _buildAccessibilitySection(),
        _buildThemeSection(),
        _buildAboutSection(),
        const Padding(
          padding: EdgeInsets.all(Constants.padding),
          child: SizedBox.shrink(),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.all(Constants.padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header.
                      _buildHeader(),
                      Flexible(
                          child: (layoutProvider.isMobile)
                              ? Scrollbar(
                                  controller: desktopSideController,
                                  child: sideList)
                              : sideList),
                    ],
                  ),
                ),
                Flexible(
                  flex: 2,
                  child: (layoutProvider.isMobile)
                      ? Scrollbar(
                          controller: desktopScrollController,
                          child: mainList,
                        )
                      : mainList,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRegular({required BuildContext context}) {
    Widget innerList = ListView(
      padding: const EdgeInsets.symmetric(horizontal: Constants.halfPadding),
      shrinkWrap: true,
      physics: scrollPhysics,
      controller: mobileScrollController,
      children: [
        _buildEnergyTile(),
        _buildQuickInfo(),
        // ACCOUNT SETTNIGS
        _buildAccountSection(),
        // GENERAL SETTINGS
        _buildGeneralSection(),
        // ACCESSIBILITY
        _buildAccessibilitySection(),
        // THEME
        _buildThemeSection(),
        // ABOUT
        _buildAboutSection(),
        // SIGN OUT
        _buildSignOut(),

        // DELETE ACCOUNT
        _buildDeleteAccount(),
        const Padding(
          padding: EdgeInsets.all(Constants.padding),
          child: SizedBox.shrink(),
        ),
      ],
    );

    return Padding(
        padding: const EdgeInsets.all(Constants.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header.
            _buildHeader(),
            Flexible(
                child: (layoutProvider.isMobile)
                    ? Scrollbar(
                        controller: mobileScrollController,
                        child: innerList,
                      )
                    : innerList),
          ],
        ));
  }

  Widget _buildQuickInfo() {
    // TODO: implement a user switcher.
    // return Consumer<UserProvider>(
    //   builder: (BuildContext context, UserProvider value, Widget? child) {
    //     return Selector<UserViewModel, (String, String?, String?)>(
    //         selector: (BuildContext context, UserViewModel vm) =>
    //             (vm.username, vm.email, vm.uuid),
    //         builder: (BuildContext context,
    //             (String, String?, String?) watchInfo, Widget? child) {
    //           return SettingsScreenWidgets.userQuickInfo(
    //             context: context,
    //             // userProvider: value,
    //             viewModel: vm,
    //             outerPadding:
    //                 const EdgeInsets.only(bottom: Constants.halfPadding),
    //           );
    //         });
    //   },
    // );

    return ValueListenableBuilder(
        valueListenable: userProvider.isConnected,
        builder: (BuildContext context, bool online, Widget? child) =>
            Selector<UserViewModel, (String, String?)>(
                selector: (BuildContext context, UserViewModel vm) =>
                    (vm.username, vm.email),
                builder: (BuildContext context, (String, String?) watchInfo,
                    Widget? child) {
                  return SettingsScreenWidgets.userQuickInfo(
                    context: context,
                    viewModel: vm,
                    connected: online,
                    outerPadding:
                        const EdgeInsets.only(bottom: Constants.halfPadding),
                  );
                }));
  }

  Widget _buildEnergyTile({double maxScale = 1.5}) {
    return Selector<UserViewModel, int>(
        selector: (BuildContext context, UserViewModel vm) => vm.bandwidth,
        builder: (BuildContext context, int value, Widget? child) =>
            SettingsScreenWidgets.energyTile(
                weight: value.toDouble(),
                batteryScale: remap(
                        x: layoutProvider.width.clamp(
                            Constants.smallScreen, Constants.largeScreen),
                        inMin: Constants.smallScreen,
                        inMax: Constants.largeScreen,
                        outMin: 1,
                        outMax: maxScale)
                    .toDouble(),
                handleWeightChange: (newWeight) {
                  if (null == newWeight) {
                    return;
                  }
                  vm.bandwidth = newWeight.toInt();
                },
                onChangeEnd: (newWeight) {
                  if (null == newWeight) {
                    return;
                  }

                  // This needs to be explicitly set, otherwise the data will not update.
                  vm.pushUpdate = true;
                  vm.bandwidth = newWeight.toInt();
                }));
  }

  Widget _buildAccountSection() {
    return ValueListenableBuilder<bool>(
        valueListenable: userProvider.isConnected,
        builder: (BuildContext context, bool isConnected, Widget? child) {
          if (isConnected) {
            return SettingsScreenWidgets.settingsSection(
              context: context,
              title: "Account",
              entries: [
                SettingsScreenWidgets.tapTile(
                    leading: const Icon(Icons.sync_rounded),
                    title: "Sync now",
                    onTap: () async {
                      if (!userProvider.isConnected.value) {
                        Tiles.displayError(
                            e: ConnectionException(
                                "No online connection, try signing in."));
                        return;
                      }

                      await Future.wait([
                        toDoProvider.syncRepo(),
                        routineProvider.syncRepo(),
                        deadlineProvider.syncRepo(),
                        reminderProvider.syncRepo(),
                        groupProvider.syncRepo(),
                        userProvider.syncUser(),
                      ]);
                    }),
                SettingsScreenWidgets.tapTile(
                  leading: const Icon(Icons.email_rounded),
                  title: "Change email",
                  onTap: () async {
                    if (!userProvider.isConnected.value) {
                      await Tiles.displayError(
                          e: ConnectionException(
                              "No online connection, try signing in."));
                      return;
                    }
                    await blurredDismissible(
                            context: context,
                            keyboardOverlap: false,
                            dialog: const UpdateEmailDialog())
                        // await showDialog<bool?>(
                        //     useRootNavigator: false,
                        //     context: context,
                        //     builder: (BuildContext context) =>
                        //         const UpdateEmailDialog())
                        .then((success) {
                      if (null == success) {
                        return;
                      }

                      if (success) {
                        Flushbars.createAlert(
                          message: "Check new email to confirm change.",
                          context: context,
                        ).show(context);
                      }
                    });
                  },
                ),
              ],
            );
          }

          // This should both send OTP + Challenge.
          // When application is -OPEN- should just resume state? I unno. The deeplink builder is super busted.
          return SettingsScreenWidgets.settingsSection(
              context: context,
              title: "Account",
              entries: [
                SettingsScreenWidgets.tapTile(
                    leading: const Icon(Icons.cloud_sync_rounded),
                    title: "Sign in to cloud backup",
                    onTap: () async {
                      await blurredDismissible(
                          context: context,
                          keyboardOverlap: false,
                          dialog: const SignInDialog());
                      // await showDialog(
                      //   useRootNavigator: false,
                      //   context: context,
                      //   barrierDismissible: true,
                      //   builder: (BuildContext context) => const SignInDialog(),
                      // );
                    }),
              ]);
        });
  }

  Widget _buildGeneralSection() {
    return SettingsScreenWidgets.settingsSection(
      context: context,
      title: "General",
      entries: [
        //  Check close.
        Selector<UserViewModel, bool>(
          selector: (BuildContext context, UserViewModel vm) => vm.checkClose,
          builder: (BuildContext context, bool value, Widget? child) {
            return SettingsScreenWidgets.toggleTile(
                leading: const Icon(Icons.close_rounded),
                value: value,
                title: "Ask before closing",
                onChanged: (bool value) {
                  vm.checkClose = value;
                });
          },
        ),

        Selector<UserViewModel, bool>(
          selector: (BuildContext context, UserViewModel vm) => vm.checkDelete,
          builder: (BuildContext context, bool value, Widget? child) {
            return SettingsScreenWidgets.toggleTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: "Ask before deleting",
                value: value,
                onChanged: (bool value) {
                  vm.checkDelete = value;
                });
          },
        ),

        Selector<UserViewModel, DeleteSchedule>(
          selector: (BuildContext context, UserViewModel vm) =>
              vm.deleteSchedule,
          builder:
              (BuildContext context, DeleteSchedule value, Widget? child) =>
                  SettingsScreenWidgets.radioDropDown(
                      initiallyExpanded: false,
                      groupMember: value,
                      values: DeleteSchedule.values,
                      title: "Keep deleted items:",
                      getName: Constants.deleteScheduleType,
                      onChanged: (DeleteSchedule? newSchedule) {
                        if (null == newSchedule) {
                          return;
                        }
                        vm.deleteSchedule = newSchedule;
                      }),
        ),
      ],
    );
  }

  Widget _buildAccessibilitySection() {
    return SettingsScreenWidgets.settingsSection(
      context: context,
      title: "Accessibility",
      entries: [
        // Reduce motion.
        Selector<ThemeProvider, bool>(
          selector: (BuildContext context, ThemeProvider tp) => tp.reduceMotion,
          builder: (BuildContext context, bool value, Widget? child) =>
              SettingsScreenWidgets.toggleTile(
                  leading: const Icon(Icons.slow_motion_video_rounded),
                  title: "Reduce motion",
                  value: value,
                  onChanged: (bool reduceMotion) {
                    themeProvider.reduceMotion = reduceMotion;
                  }),
        ),
        // Use Ultra high Contrast.
        Selector<ThemeProvider, bool>(
          selector: (BuildContext context, ThemeProvider tp) =>
              tp.useUltraHighContrast,
          builder: (BuildContext context, bool value, Widget? child) =>
              SettingsScreenWidgets.toggleTile(
                  leading: const Icon(Icons.contrast_rounded),
                  title: "Ultra contrast",
                  value: value,
                  onChanged: (bool useHi) {
                    themeProvider.useUltraHighContrast = useHi;
                  }),
        ),
      ],
    );
  }

  Widget _buildThemeSection() {
    return SettingsScreenWidgets
        .settingsSection(context: context, title: "Theme", entries: [
      // ThemeType
      Selector<ThemeProvider, ThemeType>(
        selector: (BuildContext context, ThemeProvider tp) => tp.themeType,
        builder: (BuildContext context, ThemeType value, Widget? child) =>
            DefaultTabController(
          initialIndex: value.index,
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
      ),

      // Color seeds.
      Selector<ThemeProvider, Color>(
        selector: (BuildContext context, ThemeProvider tp) => tp.primarySeed,
        builder: (BuildContext context, Color value, Widget? child) =>
            SettingsScreenWidgets.colorSeedTile(
                context: context,
                recentColors: themeProvider.recentColors,
                color: value,
                onColorChanged: (Color newColor) {
                  themeProvider.primarySeed = newColor;
                },
                colorType: "Primary color",
                icon: const Icon(Icons.eject_rounded),
                showTrailing:
                    const Color(Constants.defaultPrimaryColorSeed) != value,
                restoreDefault: () {
                  Tooltip.dismissAllToolTips();
                  themeProvider.primarySeed =
                      const Color(Constants.defaultPrimaryColorSeed);
                }),
      ),
      Selector<ThemeProvider, Color?>(
        selector: (BuildContext context, ThemeProvider tp) => tp.secondarySeed,
        builder: (BuildContext context, Color? value, Widget? child) =>
            SettingsScreenWidgets.colorSeedTile(
                context: context,
                recentColors: themeProvider.recentColors,
                onColorChanged: (Color newColor) {
                  themeProvider.secondarySeed = newColor;
                },
                color: value,
                colorType: "Secondary color",
                showTrailing: null != value,
                restoreDefault: () {
                  Tooltip.dismissAllToolTips();
                  themeProvider.secondarySeed = null;
                }),
      ),
      Selector<ThemeProvider, Color?>(
        selector: (BuildContext context, ThemeProvider tp) => tp.tertiarySeed,
        builder: (BuildContext context, Color? value, Widget? child) =>
            SettingsScreenWidgets.colorSeedTile(
                context: context,
                recentColors: themeProvider.recentColors,
                onColorChanged: (Color newColor) {
                  themeProvider.tertiarySeed = newColor;
                },
                color: value,
                colorType: "Tertiary color",
                showTrailing: null != value,
                restoreDefault: () {
                  Tooltip.dismissAllToolTips();
                  themeProvider.tertiarySeed = null;
                }),
      ),

      // Tonemapping radiobutton
      Selector<ThemeProvider, ToneMapping>(
        selector: (BuildContext context, ThemeProvider tp) => tp.toneMapping,
        builder: (BuildContext context, ToneMapping value, Widget? child) =>
            SettingsScreenWidgets.radioDropDown(
                initiallyExpanded: false,
                leading: const Icon(Icons.colorize_rounded),
                title: "Tonemapping",
                groupMember: value,
                values: ToneMapping.values,
                onChanged: (ToneMapping? newMap) {
                  if (null == newMap) {
                    return;
                  }
                  themeProvider.toneMapping = newMap;
                }),
      ),

      // Window effects
      if (!layoutProvider.isMobile) ...[
        Selector<ThemeProvider, Effect>(
          selector: (BuildContext context, ThemeProvider tp) => tp.windowEffect,
          builder: (BuildContext context, Effect value, Widget? child) =>
              SettingsScreenWidgets.radioDropDown(
            initiallyExpanded: false,
            leading: const Icon(Icons.color_lens_outlined),
            title: "Window effect",
            children: getAvailableWindowEffects(),
            groupMember: value,
            values: Effect.values,
          ),
        ),
        // Transparency - use the dropdown slider.
        Selector<ThemeProvider, (double, bool)>(
          selector: (BuildContext context, ThemeProvider tp) =>
              (tp.sidebarOpacity, tp.useTransparency),
          builder:
              (BuildContext context, (double, bool) value, Widget? child) =>
                  SettingsScreenWidgets.sliderTile(
            title: "Sidebar opacity",
            leading: const Icon(Icons.gradient_rounded),
            label: "${(100 * value.$1).toInt()}",
            onOpen: () {
              desktopScrollController.addListener(anchorWatchScroll);
              mobileScrollController.addListener(anchorWatchScroll);
            },
            onClose: () {
              desktopScrollController.removeListener(anchorWatchScroll);
              mobileScrollController.removeListener(anchorWatchScroll);
            },
            onChanged: (value.$2)
                ? (double newOpacity) {
                    themeProvider.sidebarOpacity = newOpacity;
                  }
                : null,
            onChangeEnd: (double newOpacity) {
              themeProvider.sidebarOpacitySavePref = newOpacity;
              _sidebarController.close();
            },
            value: value.$1,
            controller: _sidebarController,
          ),
        ),

        Selector<ThemeProvider, (double, bool)>(
          selector: (BuildContext context, ThemeProvider tp) =>
              (tp.scaffoldOpacity, tp.useTransparency),
          builder:
              (BuildContext context, (double, bool) value, Widget? child) =>
                  SettingsScreenWidgets.sliderTile(
            title: "Window opacity",
            leading: const Icon(Icons.gradient_rounded),
            label: "${(100 * value.$1).toInt()}",
            onOpen: () {
              desktopScrollController.addListener(anchorWatchScroll);
              mobileScrollController.addListener(anchorWatchScroll);
            },
            onClose: () {
              desktopScrollController.removeListener(anchorWatchScroll);
              mobileScrollController.removeListener(anchorWatchScroll);
            },
            onChanged: (value.$2)
                ? (double newOpacity) {
                    themeProvider.scaffoldOpacity = newOpacity;
                  }
                : null,
            onChangeEnd: (double newOpacity) {
              themeProvider.scaffoldOpacitySavePref = newOpacity;
              _scaffoldController.close();
            },
            value: value.$1,
            controller: _scaffoldController,
          ),
        ),
      ],
    ]);
  }

  Widget _buildHeader() => Selector<UserViewModel, bool>(
        selector: (BuildContext context, UserViewModel vm) => vm.syncOnline,
        builder: (BuildContext context, bool value, Widget? child) =>
            const ScreenHeader(
          outerPadding: EdgeInsets.all(Constants.padding),
          leadingIcon: Icon(Icons.settings_rounded),
          header: "Settings",
        ),
      );

  Widget _buildAboutSection() {
    return SettingsScreenWidgets.settingsSection(
        context: context,
        title: "About",
        entries: [
          SettingsScreenWidgets.tapTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: "About",
              onTap: () async {
                await blurredDismissible(
                  context: context,
                  dialog: SettingsScreenWidgets.aboutDialog(
                      packageInfo: layoutProvider.packageInfo),
                );
                // await showDialog(
                //     context: context,
                //     useRootNavigator: false,
                //     builder: (BuildContext context) {
                //       return SettingsScreenWidgets.aboutDialog(
                //         packageInfo: layoutProvider.packageInfo,
                //       );
                //     });
              }),
          SettingsScreenWidgets.tapTile(
              leading: const Icon(Icons.medical_information_rounded),
              title: "Debug Information",
              onTap: () async {
                await blurredDismissible(
                    context: context,
                    dialog:
                        SettingsScreenWidgets.debugInfoDialog(viewModel: vm));
                // await showDialog(
                //     context: context,
                //     useRootNavigator: false,
                //     builder: (BuildContext context) {
                //       return SettingsScreenWidgets.debugInfoDialog(viewModel: vm);
                //     });
              }),
          SettingsScreenWidgets.tapTile(
              leading: const Icon(Icons.add_road_rounded),
              title: "Roadmap",
              onTap: () async {
                await blurredDismissible(
                    context: context,
                    dialog: SettingsScreenWidgets.roadmapDialog());
                // await showDialog(
                //     context: context,
                //     useRootNavigator: false,
                //     builder: (BuildContext context) {
                //       return SettingsScreenWidgets.roadmapDialog();
                //     });
              }),
          SettingsScreenWidgets.tapTile(
              leading: const Icon(Icons.sticky_note_2_rounded),
              title: "Licenses",
              onTap: () {
                showLicensePage(
                  context: context,
                  applicationName: Constants.applicationName,
                  applicationIcon: Image(image: Constants.appIcon),
                  applicationVersion:
                      "${layoutProvider.packageInfo.version}(${layoutProvider.packageInfo.buildNumber})",
                  useRootNavigator: false,
                );
              }),
        ]);
  }

  Widget _buildSignOut() {
    return ValueListenableBuilder(
        valueListenable: userProvider.isConnected,
        builder: (BuildContext context, bool value, Widget? child) {
          if (value) {
            return SettingsScreenWidgets.settingsSection(
              context: context,
              title: "",
              entries: [
                SettingsScreenWidgets.tapTile(
                    leading: Icon(Icons.highlight_off_rounded,
                        color: Theme.of(context).colorScheme.tertiary),
                    title: "Sign out",
                    onTap: () async {
                      // Future TODO: multi-user accounts.
                      await userProvider.signOut().catchError((e) async {
                        await Tiles.displayError(e: e);
                      });
                    }),
              ],
            );
          }
          return const SizedBox.shrink();
        });
  }

  // TODO: implement with user-account switching
  Widget _buildNewAccount() {
    return const SizedBox.shrink();
  }

  // This should probably select userProvider.
  Widget _buildDeleteAccount() {
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
              await blurredDismissible<List<bool>?>(
                  context: context,
                  dialog: const CheckDeleteDialog(
                    type: "Account",
                    showCheckbox: false,
                  )).then((deleteInfo) async {
                if (null == deleteInfo) {
                  return;
                }
                bool delete = deleteInfo[0];
                if (delete) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) =>
                            const LoadingScreen(),
                      ));
                  await Future.wait(
                    [
                      // This should notify -> resetting userVM, resets everything.
                      // Deleting an online user will cascade
                      userProvider.deleteUser(),

                      // Delete local after user, in case of error, escapes early.
                      toDoProvider.clearDatabase(),
                      routineProvider.clearDatabase(),
                      reminderProvider.clearDatabase(),
                      deadlineProvider.clearDatabase(),
                      groupProvider.clearDatabase(),
                      subtaskProvider.clearDatabase(),
                    ],
                  ).then((_) {
                    layoutProvider.selectedPageIndex = 0;
                  }).catchError((e) async {
                    await Tiles.displayError(e: e);
                  }).whenComplete(() {
                    Navigator.pop(context);
                  });
                }
              });
            }),
      ],
    );
  }

  List<Widget> getAvailableWindowEffects() {
    List<Widget> validEffects = List.empty(growable: true);

    bool filterWindows = (Platform.isWindows && !themeProvider.win11);
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
            }),
      );
    }
    return validEffects;
  }
}
