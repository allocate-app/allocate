import 'package:allocate/ui/widgets/tiles.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../providers/application/layout_provider.dart';
import '../../providers/model/user_provider.dart';
import '../../util/constants.dart';
import '../../util/exceptions.dart';

class UpdateEmailDialog extends StatefulWidget {
  const UpdateEmailDialog({super.key});

  @override
  State<UpdateEmailDialog> createState() => _UpdateEmailDialog();
}

class _UpdateEmailDialog extends State<UpdateEmailDialog> {
  late final TextEditingController _oldEmailController;
  late final TextEditingController _newEmailController;
  late final TextEditingController _tokenController;
  late final LayoutProvider layoutProvider;
  late final UserProvider userProvider;

  late final ValueNotifier<bool> validRequest;
  late final ValueNotifier<bool> validChallenge;
  late final ValueNotifier<bool> validNew;
  late final ValueNotifier<bool> validOld;
  late final ValueNotifier<bool> validToken;

  @override
  void initState() {
    super.initState();
    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);
    userProvider = Provider.of<UserProvider>(context, listen: false);
    validRequest = ValueNotifier<bool>(false);
    validChallenge = ValueNotifier<bool>(false);
    validNew = ValueNotifier<bool>(false);
    validOld = ValueNotifier<bool>(false);
    validToken = ValueNotifier<bool>(false);
    _oldEmailController = TextEditingController();
    _newEmailController = TextEditingController();
    _tokenController = TextEditingController();
    _oldEmailController.addListener(announceOld);
    _newEmailController.addListener(announceNew);
    _tokenController.addListener(announceToken);
  }

  @override
  void dispose() {
    _oldEmailController.removeListener(announceOld);
    _newEmailController.removeListener(announceNew);
    _oldEmailController.dispose();
    _newEmailController.dispose();
    super.dispose();
  }

  // This is just because of listener signatures
  void announceOld() {
    announceText(_oldEmailController);
  }

  void announceNew() {
    announceText(_newEmailController);
  }

  void announceToken() {
    announceText(_tokenController);
  }

  void announceText(TextEditingController controller) {
    SemanticsService.announce(controller.text, Directionality.of(context));

    validNew.value = _newEmailController.text.isNotEmpty;
    validOld.value = _oldEmailController.text.isNotEmpty;
    validToken.value = _tokenController.text.isNotEmpty;

    validRequest.value = validNew.value && validOld.value;
    validChallenge.value = validNew.value && validToken.value;
  }

  bool validateEmails() {
    if (!validateOldEmail()) {
      return false;
    }
    return validateNewEmail();
  }

  bool validateOldEmail() {
    if (!_oldEmailController.text.contains(RegExp(r"^.*@.*\..*$"))) {
      Tiles.displayError(
          e: InvalidInputException("Old Email: Invalid email format"));
      return false;
    }
    return true;
  }

  bool validateNewEmail() {
    if (!_newEmailController.text.contains(RegExp(r".*@.*\..*$"))) {
      Tiles.displayError(
          e: InvalidInputException("New Email: Invalid email format"));
      return false;
    }

    if (_oldEmailController.text == _newEmailController.text) {
      Tiles.displayError(
          e: InvalidInputException("New email matches previous email."));
      return false;
    }
    return true;
  }

  bool validateToken() {
    bool valid = true;
    if (_tokenController.text.isEmpty ||
        !_tokenController.text.contains(RegExp(r"^[0-9]{6}$"))) {
      valid = false;

      Tiles.displayError(e: InvalidInputException("Invalid 6-digit token"));
    }
    return valid;
  }

  Future<void> handleVerify() async {
    if (!validateToken()) {
      return;
    }
    if (!validateNewEmail()) {
      return;
    }

    await userProvider
        .verifiyEmailChange(
      newEmail: _newEmailController.text,
      token: _tokenController.text,
    )
        .then((_) {
      Navigator.pop(context);
    }).catchError((e) async {
      Tiles.displayError(e: e);
    });
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
                            flex: 3,
                            child: AutoSizeText(
                              "Update Email",
                              softWrap: false,
                              maxLines: 1,
                              minFontSize: Constants.huge,
                              overflow: TextOverflow.visible,
                              style: Constants.largeHeaderStyle,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.fill,
                            child: Icon(Icons.send_rounded,
                                size: Constants.lgIconSize),
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
                      padding: const EdgeInsets.symmetric(
                          vertical: Constants.padding),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [Expanded(child: _buildTokenTile())],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: Constants.padding),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // TODO: factor this out. -> token challenge instead.
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    right: Constants.padding),
                                child: _buildEmailUpdateButton(),
                              ),
                            ),

                            Expanded(
                                child: Padding(
                              padding: const EdgeInsets.only(
                                  left: Constants.padding),
                              child: _buildChallengeButton(),
                            )),
                          ]),
                    ),
                  ],
                ),
              )),
        ),
      );

  Widget _buildOldTile() => ValueListenableBuilder(
        valueListenable: validOld,
        builder: (BuildContext context, bool value, Widget? child) =>
            Tiles.nameTile(
          context: context,
          controller: _oldEmailController,
          hintText: "Old Email",
          labelText: "Old Email",
          errorText: null,
          handleClear: () {
            // This should still fire the listener.
            _oldEmailController.clear();
          },
          onEditingComplete: () {},
        ),
      );

  Widget _buildNewTile() => ValueListenableBuilder(
        valueListenable: validNew,
        builder: (BuildContext context, bool value, Widget? child) =>
            Tiles.nameTile(
          context: context,
          controller: _newEmailController,
          hintText: "New Email",
          labelText: "New Email",
          errorText: null,
          handleClear: () {
            _newEmailController.clear();
          },
          onEditingComplete: () {},
        ),
      );

  Widget _buildTokenTile() => ValueListenableBuilder(
        valueListenable: validToken,
        builder: (BuildContext context, bool value, Widget? child) =>
            Tiles.nameTile(
          context: context,
          controller: _tokenController,
          hintText: "One-Time-Password",
          labelText: "One-Time-Password",
          errorText: null,
          handleClear: () {
            _tokenController.clear();
          },
          onEditingComplete: (validChallenge.value) ? handleVerify : () {},
        ),
      );

  Widget _buildChallengeButton() => ValueListenableBuilder(
      valueListenable: validChallenge,
      builder: (BuildContext context, bool valid, Widget? child) {
        return FilledButton.icon(
          icon: const Icon(Icons.mark_email_read_rounded),
          onPressed: (valid) ? handleVerify : null,
          label: const AutoSizeText(
            "Confirm (OTP)",
          ),
        );
      });

  Widget _buildEmailUpdateButton() => ValueListenableBuilder(
      valueListenable: validRequest,
      builder: (BuildContext context, bool valid, Widget? child) {
        return FilledButton.icon(
          icon: const Icon(Icons.email_rounded),
          onPressed: (valid)
              ? () async {
                  if (!validateEmails()) {
                    return;
                  }
                  await userProvider
                      .updateEmail(
                    newEmail: _newEmailController.text,
                  )
                      .then((_) {
                    Tiles.displayAlert(
                        message: "Check your new email for an OTP to confirm");
                  }).catchError((e) async {
                    Tiles.displayError(e: e);
                  });
                }
              : null,
          label: const AutoSizeText("Request Update",
              softWrap: true,
              overflow: TextOverflow.visible,
              maxLines: 2,
              minFontSize: Constants.large),
        );
      });
}
