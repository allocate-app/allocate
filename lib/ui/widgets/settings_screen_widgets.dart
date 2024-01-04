import 'package:auto_size_text/auto_size_text.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../model/user/user.dart';
import '../../util/constants.dart';
import 'battery_meter.dart';
import 'color_picker_dialog.dart';
import 'expanded_listtile.dart';
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

  static Widget tapTile(
          {Widget? leading,
          String title = "",
          void Function()? onTap,
          Widget? trailing,
          Color? textColor}) =>
      ListTile(
        leading: leading,
        title: AutoSizeText(title,
            style: TextStyle(
              color: textColor,
            ),
            minFontSize: Constants.large,
            maxLines: 1,
            softWrap: true,
            overflow: TextOverflow.visible),
        onTap: onTap,
        trailing: trailing,
      );

  static Widget toggleTile({
    Widget? leading,
    String title = "",
    void Function(bool value)? onChanged,
    bool value = false,
  }) =>
      tapTile(
        leading: leading,
        title: title,
        onTap: null,
        trailing: Switch(
          value: value,
          onChanged: onChanged,
        ),
      );

  static Widget colorSeedTile({
    Color? color,
    List<Color>? recentColors,
    String colorType = "",
    Icon icon = const Icon(Icons.close_rounded),
    void Function()? restoreDefault,
    void Function(Color color)? onColorChanged,
    bool showTrailing = false,
    required BuildContext context,
  }) =>
      tapTile(
        leading: DecoratedBox(
          decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.all(Radius.circular(Constants.circular)),
              border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignOutside)),
          child: ColorIndicator(
              color: color ?? Colors.transparent,
              hasBorder: false,
              borderRadius: Constants.circular,
              onSelectFocus: false,
              onSelect: () async {
                Color? newColor = await showDialog<Color?>(
                    useRootNavigator: false,
                    context: context,
                    builder: (BuildContext context) {
                      return ColorPickerDialog(
                        oldColor: color,
                        colorType: colorType,
                      );
                    });
                if (Colors.transparent == newColor ||
                    null == newColor ||
                    newColor == color ||
                    null == onColorChanged) {
                  return;
                }
                onColorChanged(newColor);
              }),
        ),
        onTap: () async {
          Color? newColor = await showDialog<Color?>(
              useRootNavigator: false,
              context: context,
              builder: (BuildContext context) {
                return ColorPickerDialog(
                  oldColor: color,
                  colorType: colorType,
                );
              });

          if (Colors.transparent == newColor ||
              null == newColor ||
              newColor == color ||
              null == onColorChanged) {
            return;
          }
          onColorChanged(newColor);
        },
        title: colorType,
        trailing: (showTrailing)
            ? IconButton(
                icon: icon,
                onPressed: restoreDefault,
                tooltip: "Restore default")
            : null,
      );

  // TODO: this will need to change to UserModel.
  static Widget userQuickInfo(
          {User? user, EdgeInsetsGeometry outerPadding = EdgeInsets.zero}) =>
      Padding(
        padding: outerPadding,
        child: Card(
          elevation: 1,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(Constants.circular)),
          ),
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
                  borderRadius: const BorderRadius.all(
                      Radius.circular(Constants.circular)),
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
        ),
      );

  static Widget energyTile({
    double weight = Constants.maxBandwidthDouble,
    double batteryScale = 1,
    void Function(double?)? handleWeightChange,
  }) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(
                  left: Constants.padding,
                  right: Constants.padding,
                  bottom: Constants.doublePadding,
                  top: Constants.padding),
              child: AutoSizeText("Energy Capacity",
                  style: Constants.headerStyle,
                  minFontSize: Constants.large,
                  maxLines: 1,
                  softWrap: true,
                  overflow: TextOverflow.visible),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Constants.doublePadding),
            child: BatteryMeter(
              weight: weight,
              forward: true,
              alertUser: false,
              constraints: const BoxConstraints(
                maxWidth: 150,
              ),
              scale: batteryScale,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Constants.doublePadding),
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

  /// RADIOBUTTON - Enum.
  static Widget radioTile<T extends Enum>(
          {required T member,
          String? name,
          required T groupValue,
          void Function(T?)? onChanged}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
        child: ListTile(
          shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(Constants.circular))),
          leading: Radio<T>(
              value: member, groupValue: groupValue, onChanged: onChanged),
          onTap: (null != onChanged) ? () => onChanged(member) : null,
          title: AutoSizeText(
            name ??
                toBeginningOfSentenceCase(member.name.replaceAll("_", " "))!,
            softWrap: false,
            maxLines: 1,
            overflow: TextOverflow.visible,
            minFontSize: Constants.large,
            style: Constants.largeBodyText,
          ),
        ),
      );

  static Widget radioDropDown<T extends Enum>({
    required T groupMember,
    required List<T> values,
    List<Widget>? children,
    String? title,
    Widget? leading,
    bool initiallyExpanded = false,
    String Function(T member)? getName,
    void Function({bool expanded})? onExpansionChanged,
    void Function(T? newSelection)? onChanged,
  }) =>
      ExpandedListTile(
        leading: leading,
        title: AutoSizeText(
          title ?? toBeginningOfSentenceCase(T.runtimeType.toString())!,
          minFontSize: Constants.large,
          maxLines: 1,
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
        trailing: AutoSizeText(
          (null != getName)
              ? getName(groupMember)
              : toBeginningOfSentenceCase(groupMember.name)!,
          maxLines: 1,
          softWrap: true,
          minFontSize: Constants.xtraLarge,
          overflow: TextOverflow.visible,
        ),
        initiallyExpanded: initiallyExpanded,
        children: children ??
            values
                .map((member) => radioTile<T>(
                      name: (null != getName) ? getName(member) : null,
                      member: member,
                      groupValue: groupMember,
                      onChanged: onChanged,
                    ))
                .toList(),
      );

  ///Slider ANCHOR
  static Widget sliderTile({
    void Function()? onOpen,
    void Function()? onClose,
    void Function(double value)? onChanged,
    void Function(double value)? onChangeEnd,
    String title = "Slider title",
    double? width,
    Widget? leading,
    double value = 0,
    double min = 0,
    double max = 1,
    label = "",
    EdgeInsetsGeometry labelPadding =
        const EdgeInsets.only(right: Constants.padding),
    MenuController? controller,
    EdgeInsetsGeometry padding = const EdgeInsets.all(Constants.padding),
  }) =>
      MenuAnchor(
          onOpen: onOpen,
          onClose: onClose,
          style: MenuStyle(
            padding: MaterialStatePropertyAll(padding),
            shape: const MaterialStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.all(Radius.circular(Constants.semiCircular)),
              ),
            ),
          ),
          controller: controller,
          menuChildren: [
            SizedBox(
                width: width,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Slider(
                        min: 0,
                        max: 1,
                        value: value,
                        onChangeEnd: onChangeEnd,
                        onChanged: onChanged,
                      ),
                    ),
                    Padding(
                      padding: padding,
                      child: Text(
                        label,
                        maxLines: 1,
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                )),
          ],
          builder:
              (BuildContext context, MenuController controller, Widget? child) {
            return tapTile(
                leading: leading,
                title: title,
                onTap: () {
                  if (controller.isOpen) {
                    return controller.close();
                  }
                  controller.open();
                });
          });

  /// ABOUT DIALOG
  static Widget aboutDialog({required PackageInfo packageInfo}) => Dialog(
        insetPadding: const EdgeInsets.all(Constants.outerDialogPadding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
              maxWidth: Constants.smallLandscapeDialogWidth),
          child: Padding(
            padding: const EdgeInsets.all(Constants.doublePadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: Constants.appIconSize,
                      maxHeight: Constants.appIconSize,
                    ),
                    child: Image.file(Constants.appIcon, fit: BoxFit.fill),
                  ),
                ),
                AutoSizeText(
                  packageInfo.appName,
                  style: Constants.largeHeaderStyle,
                  minFontSize: Constants.huge,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                ),
                AutoSizeText(
                  "${packageInfo.version} (${packageInfo.buildNumber})",
                  minFontSize: Constants.huge,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                ),
                const AutoSizeText(
                  Constants.licenseInfo,
                  minFontSize: Constants.large,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          ),
        ),
      );

  static Widget roadmapDialog() {
    // This is unlikely to be very large - so sync for now.
    // Stream will require a stateful widget.
    String body = Constants.roadMap.readAsStringSync();
    return Dialog(
      insetPadding: const EdgeInsets.all(Constants.outerDialogPadding),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Constants.roadmapWidth),
        child: Padding(
          padding: const EdgeInsets.all(Constants.doublePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: Constants.smallLandscapeDialogHeight,
                    ),
                    child: Markdown(
                      data: body,
                      styleSheet: MarkdownStyleSheet(
                        h1: Constants.hugeHeaderStyle,
                        h2: Constants.largeHeaderStyle,
                        h3: Constants.headerStyle,
                      ),
                      styleSheetTheme: MarkdownStyleSheetBaseTheme.material,
                      shrinkWrap: true,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
