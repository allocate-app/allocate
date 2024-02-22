import 'dart:io';

import 'package:allocate/ui/widgets/padded_divider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:provider/provider.dart';

import '../../model/user/allocate_user.dart';
import '../../providers/application/layout_provider.dart';
import '../../util/constants.dart';
import 'listtile_widgets.dart';

class MultipleUserDialog extends StatefulWidget {
  const MultipleUserDialog({super.key, required this.users});

  final List<AllocateUser?> users;

  @override
  State<StatefulWidget> createState() => _MultipleUserDialog();
}

class _MultipleUserDialog extends State<MultipleUserDialog> {
  late List<AllocateUser?> _users;
  late final LayoutProvider layoutProvider;
  AllocateUser? _desiredUser;

  late ScrollPhysics _scrollPhysics;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _users = widget.users;
    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);
    _scrollController = ScrollController();
    ScrollPhysics parentPhysics = (Platform.isIOS || Platform.isMacOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
    _scrollPhysics = AlwaysScrollableScrollPhysics(parent: parentPhysics);
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
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: AutoSizeText(
                              "Select User",
                              style: Constants.largeHeaderStyle,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              maxLines: 2,
                              minFontSize: Constants.huge,
                            ),
                          )
                        ]),
                    ListView.separated(
                      shrinkWrap: true,
                      controller: _scrollController,
                      physics: _scrollPhysics,
                      itemCount: _users.length,
                      itemBuilder: (BuildContext context, int index) {
                        if (null != _users[index]) {
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: Constants.padding),
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(Constants.semiCircular))),
                            title: AutoSizeText(
                              _users[index]!.username,
                              overflow: TextOverflow.ellipsis,
                              minFontSize: Constants.large,
                              softWrap: true,
                              maxLines: 2,
                            ),
                            leading: ListTileWidgets.checkbox(
                                outerPadding: const EdgeInsets.symmetric(
                                    horizontal: Constants.halfPadding),
                                scale: 1.1,
                                completed: _desiredUser == _users[index],
                                onChanged: (bool? value) {
                                  bool rebuild = false;
                                  if (value!) {
                                    rebuild = _users[index] != _desiredUser;
                                    _desiredUser = _users[index];
                                  }
                                  if (rebuild) {
                                    setState(() {});
                                  }
                                }),
                            trailing: AutoSizeText(
                              "Last Updated: ${Jiffy.parseFromDateTime(_users[index]!.lastUpdated).format(pattern: "MMM dd yy").toString()}",
                              overflow: TextOverflow.visible,
                              minFontSize: Constants.large,
                              softWrap: false,
                              maxLines: 1,
                            ),
                          );
                        }
                        return const ListTile(
                            title: AutoSizeText(
                          "Invalid User",
                          overflow: TextOverflow.visible,
                          minFontSize: Constants.large,
                          softWrap: false,
                          maxLines: 1,
                        ));
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return const PaddedDivider(padding: Constants.padding);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: Constants.padding),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    right: Constants.padding),
                                child: FilledButton.tonalIcon(
                                    icon: const Icon(Icons.lock_reset),
                                    onPressed: () {
                                      Navigator.pop(context, null);
                                    },
                                    label: const AutoSizeText("Reset User",
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
                                  onPressed: (null != _desiredUser)
                                      ? () {
                                          Navigator.pop(context, _desiredUser);
                                        }
                                      : null,
                                  label: const AutoSizeText("Done",
                                      softWrap: false,
                                      overflow: TextOverflow.visible,
                                      maxLines: 1,
                                      minFontSize: Constants.large),
                                ),
                              ),
                            )
                          ]),
                    ),
                  ]),
            ),
          )));
}
