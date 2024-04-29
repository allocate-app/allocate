import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../../providers/application/layout_provider.dart';
import '../../services/application_service.dart';
import '../../util/constants.dart';

List<PlatformMenuItem> finderBar({required BuildContext context}) {
  ApplicationService as = ApplicationService.instance;
  return [
      // Main - label doesn't show anyway.
      PlatformMenu(
        label: Constants.applicationName,
        menus: [
          // About
          const PlatformMenuItemGroup(members: [
            PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.about,
            ),
          ]),

          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: "Preferences...",
                shortcut:
                    const SingleActivator(LogicalKeyboardKey.comma,includeRepeats: false, meta: true),
                onSelected: () {
                  Provider.of<LayoutProvider>(context, listen: false)
                          .selectedPageIndex =
                      Constants.viewRoutes.indexOf(Constants.settingsScreen);
                },
              ),
              PlatformMenuItem(
                  label: "Notifications",
                  onSelected: () {
                    Provider.of<LayoutProvider>(context, listen: false)
                        .selectedPageIndex = 1;
                  }),
            ],
          ),

          // Services
          const PlatformMenuItemGroup(members: [
            PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.servicesSubmenu),
          ]),

          const PlatformMenuItemGroup(members: [
            PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.hide),
            PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.hideOtherApplications),
            PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.showAllApplications),
          ]),

          // Could implement this by hand.
          const PlatformMenuItemGroup(members: [
            PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.quit),
          ]),
        ],
      ),

      PlatformMenu(
        label: "File",
        menus: [
          PlatformMenuItem(
              label: 'Close',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyW,
                includeRepeats: false,
                meta: true,
              ),
              onSelected: (as.hidden.value) ? null : () async {
                as.hidden.value = true;
                FocusScope.of(context).unfocus();
                await windowManager.close();
              }),
        ],
      ),

      // Edit --> Would need to rebuild by hand via PlatformMenu delegate.
      //
      const PlatformMenu(
        label: "Edit",
        menus: [
          PlatformMenuItemGroup(members: [
            PlatformMenuItem(
              label: "Undo",
              shortcut: SingleActivator(LogicalKeyboardKey.keyZ,includeRepeats: false, meta: true),
              onSelectedIntent: UndoTextIntent(SelectionChangedCause.keyboard),
            ),
            PlatformMenuItem(
              label: "Redo",
              shortcut: SingleActivator(LogicalKeyboardKey.keyZ, includeRepeats: false,
                  shift: true, meta: true),
              onSelectedIntent: RedoTextIntent(SelectionChangedCause.keyboard),
            ),
          ]),
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: "Cut",
                shortcut: SingleActivator(LogicalKeyboardKey.keyX,includeRepeats: false, meta: true),
                onSelectedIntent:
                    CopySelectionTextIntent.cut(SelectionChangedCause.keyboard),
              ),
              PlatformMenuItem(
                  label: "Copy",
                  shortcut:
                      SingleActivator(LogicalKeyboardKey.keyC,includeRepeats: false, meta: true),
                  onSelectedIntent: CopySelectionTextIntent.copy),
              PlatformMenuItem(
                  label: "Paste",
                  shortcut:
                      SingleActivator(LogicalKeyboardKey.keyV,includeRepeats: false, meta: true),
                  onSelectedIntent:
                      PasteTextIntent(SelectionChangedCause.keyboard)),
              PlatformMenuItem(
                label: "Delete",
                onSelectedIntent: DeleteCharacterIntent(forward: false),
              ),
              PlatformMenuItem(
                label: "Select All",
                shortcut: SingleActivator(LogicalKeyboardKey.keyA,includeRepeats: false, meta: true),
                onSelectedIntent:
                    SelectAllTextIntent(SelectionChangedCause.keyboard),
              ),
            ],
          ),

          // // Find/Spelling Grammar -> no spellcheck spt for flutter - hard to interop with MacOS.
          // Needs native code, stretch goal.
          // PlatformMenuItemGroup(
          //   members: [
          //   ],
          // ),
          // Dictation + Emoji
          PlatformMenuItemGroup(
            members: [
              PlatformMenu(label: "Speech", menus: [
                PlatformProvidedMenuItem(
                    type: PlatformProvidedMenuItemType.startSpeaking),
                PlatformProvidedMenuItem(
                    type: PlatformProvidedMenuItemType.stopSpeaking),
              ]),
              // Emoji -> Not implemented w/o native code. Future stretch goal.
            ],
          ),
        ],
      ),
      // View
      const PlatformMenu(label: "View", menus: [
        PlatformProvidedMenuItem(
          type: PlatformProvidedMenuItemType.toggleFullScreen,
        ),
      ]),
      // Window
      PlatformMenu(
        label: "Window",
        menus: [
          const PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.minimizeWindow),
          const PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.zoomWindow),
          const PlatformMenuItemGroup(members: [
            PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.arrangeWindowsInFront),
          ]),

          // Single instanced for now, this is literally just the main window.
          PlatformMenuItem(
              label: Constants.applicationName,
              onSelected: () async {
                await windowManager.show();
                await windowManager.focus();
              }),
        ],
      ),
      // Help --> This is currently in triage for flutter desktop.
      // PlatformMenu(
      //   label:
      // ),
    ];
}
