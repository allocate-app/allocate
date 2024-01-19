import 'dart:io';

import 'package:allocate/providers/application/theme_provider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/application/layout_provider.dart';
import '../../util/constants.dart';

class ColorPickerDialog extends StatefulWidget {
  const ColorPickerDialog({super.key, this.oldColor, this.colorType = ""});

  final Color? oldColor;
  final String colorType;

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialog();
}

class _ColorPickerDialog extends State<ColorPickerDialog> {
  late final ThemeProvider themeProvider;
  late final LayoutProvider layoutProvider;
  late Color curColor;

  late final ScrollController _scrollController;
  late final ScrollPhysics scrollPhysics;

  @override
  void initState() {
    themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);
    curColor = widget.oldColor ?? Colors.transparent;
    _scrollController = ScrollController();
    ScrollPhysics parentPhysics = (Platform.isIOS || Platform.isMacOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
    scrollPhysics = AlwaysScrollableScrollPhysics(parent: parentPhysics);
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) => Dialog(
            insetPadding: EdgeInsets.all((layoutProvider.smallScreen)
                ? Constants.mobileDialogPadding
                : Constants.outerDialogPadding),
            child: ConstrainedBox(
                constraints: const BoxConstraints(
                    maxWidth: Constants.smallLandscapeDialogWidth),
                child: Padding(
                    padding: const EdgeInsets.all(Constants.doublePadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AutoSizeText(
                                "Select Color Seed",
                                style: Constants.largeHeaderStyle,
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ],
                        ),
                        Flexible(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Flexible(
                                child: AutoSizeText(
                                  widget.colorType,
                                  style: Constants.hugeHeaderStyle,
                                  softWrap: false,
                                  overflow: TextOverflow.visible,
                                  maxLines: 1,
                                  minFontSize: Constants.large,
                                ),
                              ),
                              const Flexible(
                                child: FittedBox(
                                    fit: BoxFit.fill,
                                    child: Icon(Icons.colorize_rounded)),
                              ),
                            ],
                          ),
                        ),

                        // Colorpicker here.
                        Flexible(
                          flex: 10,
                          child: Scrollbar(
                            controller: _scrollController,
                            thumbVisibility: true,
                            child: ListView(
                              controller: _scrollController,
                              shrinkWrap: true,
                              physics: scrollPhysics,
                              children: [
                                ColorPicker(
                                    enableTooltips: true,
                                    color: curColor,
                                    elevation: 5,
                                    onColorChanged: (Color color) {
                                      if (mounted) {
                                        setState(() => curColor = color);
                                      }
                                    },
                                    pickersEnabled: const <ColorPickerType,
                                        bool>{
                                      ColorPickerType.primary: true,
                                      ColorPickerType.accent: true,
                                      ColorPickerType.bw: true,
                                      ColorPickerType.wheel: true,
                                      ColorPickerType.custom: false,
                                    },
                                    pickerTypeLabels: const <ColorPickerType,
                                        String>{
                                      ColorPickerType.primary: "Primary",
                                      ColorPickerType.accent: "Accent",
                                      ColorPickerType.bw: "B&W",
                                      ColorPickerType.wheel: "Wheel",
                                    },
                                    selectedPickerTypeColor:
                                        Theme.of(context).primaryColor,
                                    enableTonalPalette: true,
                                    tonalColorSameSize: true,
                                    tonalSubheading: const Tooltip(
                                      message:
                                          "Deselect tone to update picker type.",
                                      child: Text(
                                        "Tonal palette",
                                        style: Constants.largeBodyText,
                                        maxLines: 1,
                                        softWrap: true,
                                        overflow: TextOverflow.visible,
                                      ),
                                    ),
                                    enableShadesSelection: true,
                                    heading: const Text(
                                      "Hue selection",
                                      style: Constants.largeBodyText,
                                      maxLines: 1,
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                    ),
                                    subheading: const Text(
                                      "Shade selection",
                                      style: Constants.largeBodyText,
                                      maxLines: 1,
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                    ),
                                    showRecentColors: true,
                                    recentColorsSubheading: const Text(
                                      "Recent colors",
                                      style: Constants.largeBodyText,
                                      maxLines: 1,
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                    ),
                                    includeIndex850: true,
                                    borderRadius: Constants.circular,
                                    wheelSquareBorderRadius:
                                        Constants.curvedCorners,
                                    wheelSquarePadding: Constants.padding,
                                    recentColors: themeProvider.recentColors,
                                    onRecentColorsChanged:
                                        (List<Color> recentColors) {
                                      themeProvider.recentColors = recentColors;
                                      // Might need to setstate.
                                    }),
                              ],
                            ),
                          ),
                        ),

                        Padding(
                            padding:
                                const EdgeInsets.only(top: Constants.padding),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        right: Constants.padding),
                                    child: FilledButton.tonalIcon(
                                        icon: const Icon(Icons.close_rounded),
                                        onPressed: () {
                                          Navigator.pop(
                                              context, widget.oldColor);
                                        },
                                        label: const AutoSizeText("Cancel",
                                            softWrap: false,
                                            overflow: TextOverflow.visible,
                                            maxLines: 1,
                                            minFontSize: Constants.large)),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: Constants.padding),
                                    child: FilledButton.icon(
                                      icon: const Icon(Icons.done_rounded),
                                      // This needs to change.
                                      onPressed: () {
                                        Navigator.pop(context, curColor);
                                      },
                                      label: const AutoSizeText("Done",
                                          softWrap: false,
                                          overflow: TextOverflow.visible,
                                          maxLines: 1,
                                          minFontSize: Constants.large),
                                    ),
                                  ),
                                )
                              ],
                            )),
                      ],
                    )))),
      );
}
