import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../../model/user/user.dart';
import '../../util/constants.dart';
import 'battery_meter.dart';
import 'padded_divider.dart';
import 'tiles.dart';

abstract class SettingsScreenWidgets {
  static Widget settingsSection({
    required BuildContext context,
    String title = "Section Name",
    EdgeInsetsGeometry namePadding = const EdgeInsets.all(Constants.padding),
    double dividerPadding = Constants.halfPadding,
    required List<Widget> entries,
    Color? backgroundColor,
    Color? dividerColor,
  }) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: namePadding,
            child: (title.isNotEmpty)
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: AutoSizeText(
                      title,
                      minFontSize: Constants.large,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      softWrap: false,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(
                  Radius.circular(Constants.curvedCorners)),
              color: backgroundColor ??
                  Theme.of(context).colorScheme.surfaceVariant,
            ),
            child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: entries.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    color: Colors.transparent,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                          Radius.circular(Constants.roundedCorners)),
                    ),
                    child: entries[index],
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return PaddedDivider(
                    padding: dividerPadding,
                    color:
                        dividerColor ?? Theme.of(context).colorScheme.outline,
                  );
                }),
          ),
        ],
      );

  // TODO: this will need to change to UserModel.
  static Widget userQuickInfo(
      {User? user, EdgeInsetsGeometry outerPadding = EdgeInsets.zero}) {
    return Padding(
      padding: outerPadding,
      child: InkWell(
        borderRadius:
            const BorderRadius.all(Radius.circular(Constants.circular)),
        onTap: () {
          // THIS SHOULD OPEN UP A DIALOG TO CHANGE USERNAME + email.
          print("Pressed tile");
        },
        child: Padding(
          padding: EdgeInsets.zero,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            InkWell(
              borderRadius:
                  const BorderRadius.all(Radius.circular(Constants.circular)),
              onTap: () {
                // THIS SHOULD SWITCH USER
                print("Pressed icon");
              },
              child: const SizedBox(
                height: Constants.circleAvatarSplashRadius,
                width: Constants.circleAvatarSplashRadius,
                child: Center(
                  child: Tooltip(
                    message: "Switch Users",
                    child: CircleAvatar(
                      radius: Constants.circleAvatarRadius,
                      child: Icon(Icons.switch_account_rounded),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Constants.padding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      // TODO: implement a hashing algorithm for the online UUID.
                      // and concatenate.
                      "${user?.username ?? ""}#1234",
                      style: Constants.xtraLargeBodyText,
                      overflow: TextOverflow.visible,
                      softWrap: false,
                      maxLines: 1,
                      minFontSize: Constants.large,
                    ),
                    const AutoSizeText(
                      "TODO: LOGIN EMAIL",
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  static Widget energyTile({
    double weight = Constants.maxBandwidthDouble,
    double batteryScale = 1,
    void Function(double?)? handleWeightChange,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(
                left: Constants.padding,
                right: Constants.padding,
                top: Constants.halfPadding,
                bottom: Constants.innerPadding),
            child: AutoSizeText("Energy Capacity",
                style: Constants.headerStyle,
                minFontSize: Constants.large,
                maxLines: 1,
                softWrap: true,
                overflow: TextOverflow.visible),
          ),
        ),
        BatteryMeter(
          weight: weight,
          forward: true,
          alertUser: false,
          constraints: const BoxConstraints(
            maxWidth: 150,
          ),
          scale: batteryScale,
        ),
        Padding(
          padding: const EdgeInsets.all(Constants.innerPadding),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Tiles.weightSlider(
                weight: weight,
                divisions: null,
                max: Constants.maxBandwidthDouble,
                handleWeightChange: handleWeightChange),
          ),
        ),
      ],
    );
  }
}
