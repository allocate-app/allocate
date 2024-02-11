import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../util/constants.dart';

List<Widget> windowsTitlebar() => [
      const Align(
        alignment: Alignment.topCenter,
        child: DragToMoveArea(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: SizedBox(
                  height: 30,
                  // child: DecoratedBox(
                  //   decoration: BoxDecoration(
                  //     border: Border.all(color: Colors.pink, width: 2),
                  //   ),
                  // ),
                ),
              )
            ],
          ),
        ),
      ),
      Align(
        alignment: Alignment.topRight,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.zero,
              onTap: () async {
                await windowManager.minimize();
              },
              child: const Padding(
                padding: EdgeInsets.all(Constants.padding),
                child: Icon(Icons.minimize, size: Constants.smIconSize),
              ),
            ),
          ),

          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.zero,
              onTap: () async {
                bool isMaximized = await windowManager.isMaximized();
                if (isMaximized) {
                  await windowManager.unmaximize();
                  return;
                }
                await windowManager.maximize();
              },
              child: const Padding(
                padding: EdgeInsets.all(Constants.padding),
                child: Icon(FluentIcons.maximize_16_regular,
                    size: Constants.smIconSize),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.zero,
              hoverColor: Colors.red,
              onTap: () async {
                await windowManager.close();
              },
              child: const Padding(
                padding: EdgeInsets.all(Constants.padding),
                child: Icon(Icons.close, size: Constants.smIconSize),
              ),
            ),
          ),
          // IconButton(
          //   splashRadius: 2,
          //     icon:
          //     Icon(Icons.close),
          //     onPressed:(){
          //
          //     }
          // ),
        ]),
      )
    ];
