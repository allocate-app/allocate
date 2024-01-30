import 'package:allocate/ui/widgets/tiles.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../providers/application/layout_provider.dart';
import '../../providers/model/user_provider.dart';
import '../../util/constants.dart';

class UpdateEmailDialog extends StatefulWidget {
  const UpdateEmailDialog({super.key});

  @override
  State<UpdateEmailDialog> createState() => _UpdateEmailDialog();
}

class _UpdateEmailDialog extends State<UpdateEmailDialog> {
  late final TextEditingController _oldController;
  late final TextEditingController _newController;
  late final LayoutProvider layoutProvider;
  late final UserProvider userProvider;

  late final ValueNotifier<bool> validSubmit;
  late final ValueNotifier<String?> _errorText;

  @override
  void initState() {
    super.initState();
    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);
    userProvider = Provider.of<UserProvider>(context, listen: false);
    validSubmit = ValueNotifier<bool>(false);
    _errorText = ValueNotifier<String?>(null);
    _oldController = TextEditingController();
    _newController = TextEditingController();
    _oldController.addListener(announceOld);
    _newController.addListener(announceNew);
  }

  @override
  void dispose() {
    _oldController.removeListener(announceOld);
    _newController.removeListener(announceNew);
    _oldController.dispose();
    _newController.dispose();
    super.dispose();
  }

  // This is just because of listener signatures
  void announceOld() {
    announceText(_oldController);
  }

  void announceNew() {
    announceText(_newController);
  }

  void announceText(TextEditingController controller) {
    _errorText.value = null;
    SemanticsService.announce(controller.text, Directionality.of(context));

    validSubmit.value =
        _oldController.text.isNotEmpty && _newController.text.isNotEmpty;
  }

  bool validateEmailPassword() {
    bool valid = true;

    if (_oldController.text != userProvider.viewModel?.email) {
      Tiles.displayError(
          context: context, e: Exception("Previous email incorrect"));
      valid = false;
    }
    if (_oldController.text == _newController.text) {
      Tiles.displayError(
          context: context, e: Exception("New email matches previous email."));
      valid = false;
    }

    return valid;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) => Dialog(
          insetPadding: EdgeInsets.all((layoutProvider.smallScreen)
              ? Constants.mobileDialogPadding
              : Constants.outerDialogPadding),
          child: ConstrainedBox(
              constraints: const BoxConstraints(
                  // Needs a smaller width -> using height.
                  maxWidth: Constants.smallLandscapeDialogHeight),
              child: Padding(
                padding: const EdgeInsets.all(Constants.doublePadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AutoSizeText(
                              "Update Email",
                              softWrap: false,
                              maxLines: 1,
                              minFontSize: Constants.huge,
                              overflow: TextOverflow.visible,
                              style: Constants.largeHeaderStyle,
                            ),
                          ),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.fill,
                              child: Icon(Icons.send_rounded,
                                  size: Constants.lgIconSize),
                            ),
                          ),
                        ]),
                    Padding(
                      padding: const EdgeInsets.only(
                          top: Constants.doublePadding,
                          bottom: Constants.padding),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [Expanded(child: _buildOldTile())],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: Constants.padding),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [Expanded(child: _buildNewTile())],
                      ),
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
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () {
                                      Navigator.pop(context, false);
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
                                child: _buildSignInButton(),
                              ),
                            )
                          ]),
                    ),
                  ],
                ),
              )),
        ),
      );

  Widget _buildOldTile() => Tiles.nameTile(
        context: context,
        controller: _oldController,
        hintText: "Old Email",
        labelText: "Old Email",
        errorText: null,
        handleClear: () {
          // This should still fire the listener.
          _oldController.clear();
        },
        onEditingComplete: () {},
      );

  Widget _buildNewTile() => ValueListenableBuilder(
        valueListenable: _errorText,
        builder: (BuildContext context, String? value, Widget? child) =>
            Tiles.nameTile(
          context: context,
          controller: _newController,
          hintText: "New Email",
          labelText: "New Email",
          errorText: value,
          handleClear: () {
            _newController.clear();
          },
          onEditingComplete: () {},
        ),
      );

  Widget _buildSignInButton() => ValueListenableBuilder(
      valueListenable: validSubmit,
      builder: (BuildContext context, bool valid, Widget? child) {
        return FilledButton.icon(
          icon: const Icon(Icons.email_rounded),
          onPressed: (valid)
              ? () async {
                  if (!validateEmailPassword()) {
                    return;
                  }
                  await userProvider
                      .updateEmail(
                        newEmail: _newController.text,
                      )
                      .then((_) => Navigator.pop(context, true))
                      .catchError((e) async {
                    Tiles.displayError(context: context, e: e);
                  });
                }
              : null,
          label: const AutoSizeText("Update Email",
              softWrap: false,
              overflow: TextOverflow.visible,
              maxLines: 1,
              minFontSize: Constants.large),
        );
      });
}
