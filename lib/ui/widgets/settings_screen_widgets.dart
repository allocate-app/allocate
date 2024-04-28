import 'package:auto_size_text/auto_size_text.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../providers/viewmodels/user_viewmodel.dart';
import '../../services/isar_service.dart';
import '../../services/supabase_service.dart';
import '../../util/constants.dart';
import '../blurred_dialog.dart';
import 'battery_meter.dart';
import 'dialogs/color_picker_dialog.dart';
import 'dialogs/simple_name_dialog.dart';
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
                Color? newColor = await blurredDismissible(
                    context: context,
                    dialog: ColorPickerDialog(
                      oldColor: color,
                      colorType: colorType,
                    ));
                // await showDialog<Color?>(
                //     useRootNavigator: false,
                //     context: context,
                //     builder: (BuildContext context) {
                //       return ColorPickerDialog(
                //         oldColor: color,
                //         colorType: colorType,
                //       );
                //     });
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
          Color? newColor = await blurredDismissible(
              context: context,
              dialog: ColorPickerDialog(
                oldColor: color,
                colorType: colorType,
              ));

          // await showDialog<Color?>(
          //     useRootNavigator: false,
          //     context: context,
          //     builder: (BuildContext context) {
          //       return ColorPickerDialog(
          //         oldColor: color,
          //         colorType: colorType,
          //       );
          //     });

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

  static Widget userQuickInfo(
          {required BuildContext context,
          // Userprovider for user switcher.
          // required UserProvider userProvider,
          required UserViewModel viewModel,
          bool connected = false,
          EdgeInsetsGeometry outerPadding = EdgeInsets.zero}) =>
      Padding(
        padding: outerPadding,
        child: Tooltip(
          message: "Edit user",
          child: Card(
            elevation: 1,
            shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(Constants.circular)),
            ),
            child: InkWell(
              borderRadius:
                  const BorderRadius.all(Radius.circular(Constants.circular)),
              onTap: () async {
                await blurredDismissible(
                    context: context, dialog: const SimpleNameDialog());
                // showDialog(
                //     useRootNavigator: false,
                //     context: context,
                //     builder: (BuildContext context) =>
                //         const SimpleNameDialog());
              },
              child: Padding(
                padding: EdgeInsets.zero,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  InkWell(
                    borderRadius: const BorderRadius.all(
                        Radius.circular(Constants.circular)),
                    onTap: () async {
                      // FUTURE TODO: finish USER SWITCHER
                      // THIS SHOULD SWITCH USER

                      Tiles.displayError(
                          e: Exception("Feature not implemented."));
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
                            // This tag doesn't serve any purpose.
                            // "${viewModel.username} #${(null != viewModel.uuid) ? Constants.generateTag(viewModel.uuid!).toString().padLeft(Constants.tagDigits, "0") : Constants.generateTag(Constants.generateUuid()).toString().padLeft(Constants.tagDigits, "0")}",
                            viewModel.username,
                            style: Constants.xtraLargeBodyText,
                            overflow: TextOverflow.visible,
                            softWrap: false,
                            maxLines: 1,
                            minFontSize: Constants.huge,
                          ),
                          AutoSizeText(
                            (connected)
                                ? "Email: ${viewModel.email}"
                                : "Offline Only",
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            maxLines: 1,
                            minFontSize: Constants.large,
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );

  static Widget energyTile({
    double weight = Constants.maxBandwidthDouble,
    double batteryScale = 1,
    void Function(double?)? handleWeightChange,
    void Function(double?)? onChangeEnd,
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
                  handleWeightChange: handleWeightChange,
                  onChangeEnd: onChangeEnd),
            ),
          ),
        ],
      );

  /// RADIOBUTTON - Enum.
  static Widget radioTile<T extends Enum>(
      {required T member,
      String? name,
      required T groupValue,
      void Function(T?)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
      child: ListTile(
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.circular))),
        leading: Radio<T>(
            value: member, groupValue: groupValue, onChanged: onChanged),
        onTap: (null != onChanged) ? () => onChanged(member) : null,
        title: AutoSizeText(
          name ?? toBeginningOfSentenceCase(member.name.replaceAll("_", " "))!,
          softWrap: false,
          maxLines: 1,
          overflow: TextOverflow.visible,
          minFontSize: Constants.large,
          style: Constants.largeBodyText,
        ),
      ),
    );
  }

  static Widget radioDropDown<T extends Enum>({
    required T groupMember,
    required List<T> values,
    List<Widget>? children,
    String? title,
    Widget? leading,
    bool initiallyExpanded = false,
    String Function(T member)? getName,
    ExpansionTileController? controller,
    void Function({bool expanded})? onExpansionChanged,
    void Function(T? newSelection)? onChanged,
  }) =>
      ExpandedListTile(
        controller: controller,
        border: BorderSide.none,
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
                    child: Image(image: Constants.appIcon, fit: BoxFit.fill),
                  ),
                ),
                const AutoSizeText(
                  Constants.applicationName,
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
    return FutureBuilder<String>(
        future: Constants.roadMap,
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData && null != snapshot.data) {
            String body = snapshot.data!;
            return Dialog(
              insetPadding: const EdgeInsets.all(Constants.outerDialogPadding),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: Constants.roadmapWidth),
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
                              styleSheetTheme:
                                  MarkdownStyleSheetBaseTheme.material,
                              shrinkWrap: true,
                            )),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        });
  }

  static Widget debugInfoDialog({required UserViewModel viewModel}) {
    bool connected =
        null != SupabaseService.instance.supabaseClient.auth.currentSession;

    double dbBytes = IsarService.instance.dbSize.value.toDouble();
    int onlinePercent = (dbBytes / Constants.supabaseLimit.toDouble()).round();
    int offlinePercent = (dbBytes / Constants.isarLimit.toDouble()).round();

    return Dialog(
      insetPadding: const EdgeInsets.all(Constants.mobileDialogPadding),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
            maxWidth: Constants.smallLandscapeDialogHeight),
        child: Padding(
          padding: const EdgeInsets.all(Constants.doublePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AutoSizeText(
                "Debug Info:",
                style: Constants.largeHeaderStyle,
                minFontSize: Constants.huge,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: Constants.padding),
                child: Stack(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: AutoSizeText(
                        "Local User ID:",
                        minFontSize: Constants.large,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: AutoSizeText(
                        "${viewModel.id}",
                        minFontSize: Constants.large,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: AutoSizeText(
                      "Online Sync Enabled:",
                      minFontSize: Constants.large,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AutoSizeText(
                      "${viewModel.syncOnline}",
                      minFontSize: Constants.large,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
              Stack(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: AutoSizeText(
                      "Online User ID:",
                      minFontSize: Constants.large,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AutoSizeText(
                      (null == viewModel.uuid)
                          ? "N/A"
                          : "${viewModel.uuid!.substring(0, viewModel.uuid!.length ~/ 2)}\n${viewModel.uuid!.substring(viewModel.uuid!.length ~/ 2)}",
                      minFontSize: Constants.large,
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
              Stack(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: AutoSizeText(
                      "Connection Status:",
                      minFontSize: Constants.large,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AutoSizeText(
                      connected ? "Online" : "Offline",
                      minFontSize: Constants.large,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
              Stack(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: AutoSizeText(
                      "Local Storage:",
                      minFontSize: Constants.large,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AutoSizeText(
                      "${dbBytes / 1000000} MB",
                      minFontSize: Constants.large,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
              Stack(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: AutoSizeText(
                      "Local Space Remaining:",
                      minFontSize: Constants.large,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AutoSizeText(
                      "${100 - offlinePercent}%",
                      minFontSize: Constants.large,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
              Stack(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: AutoSizeText(
                      "Online Space Remaining:",
                      minFontSize: Constants.large,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AutoSizeText(
                      "${100 - onlinePercent}%",
                      minFontSize: Constants.large,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
