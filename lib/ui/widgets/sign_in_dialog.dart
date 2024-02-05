import 'package:allocate/ui/widgets/tiles.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../../providers/application/layout_provider.dart';
import '../../providers/model/user_provider.dart';
import '../../util/constants.dart';
import '../../util/exceptions.dart';

class SignInDialog extends StatefulWidget {
  const SignInDialog({super.key});

  @override
  State<SignInDialog> createState() => _SignInDialog();
}

class _SignInDialog extends State<SignInDialog> {
  late final TextEditingController _emailController;
  late final TextEditingController _tokenController;
  late final LayoutProvider layoutProvider;
  late final UserProvider userProvider;

  late final ValueNotifier<bool> validSignup;
  late final ValueNotifier<bool> validChallenge;
  late final ValueNotifier<bool> validToken;

  @override
  void initState() {
    super.initState();
    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);
    userProvider = Provider.of<UserProvider>(context, listen: false);
    validSignup = ValueNotifier<bool>(false);
    validChallenge = ValueNotifier<bool>(false);
    validToken = ValueNotifier<bool>(false);

    _emailController = TextEditingController();
    _tokenController = TextEditingController();
    _emailController.addListener(announceEmail);
    _tokenController.addListener(announceToken);
  }

  @override
  void dispose() {
    _emailController.removeListener(announceEmail);
    _tokenController.removeListener(announceToken);
    _emailController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  // This is just because of listener signatures
  void announceEmail() {
    announceText(_emailController);
  }

  void announceToken() {
    announceText(_tokenController);
  }

  void announceText(TextEditingController controller) {
    SemanticsService.announce(controller.text, Directionality.of(context));
    validSignup.value = _emailController.text.isNotEmpty;
    validToken.value = _tokenController.text.isNotEmpty;

    validChallenge.value = validSignup.value && validToken.value;
  }

  bool validateEmail() {
    bool valid = true;
    if (!_emailController.text.contains(RegExp(r"^.*@.*\..*$"))) {
      valid = false;
      Tiles.displayError(e: InvalidInputException("Invalid email format"));
    }

    return valid;
  }

  // 6-digit OTP
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
    if (!validateEmail()) {
      return;
    }

    await userProvider
        .verifyOTP(
      email: _emailController.text,
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
                              "Sign In",
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
                        children: [Expanded(child: _buildEmailTile())],
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
                      padding: const EdgeInsets.symmetric(
                          vertical: Constants.padding),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  right: Constants.padding),
                              child: _buildSignInButton(),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: Constants.padding),
                              child: _buildChallengeButton(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ),
      );

  Widget _buildEmailTile() => ValueListenableBuilder(
        valueListenable: validSignup,
        builder: (BuildContext context, bool value, Widget? child) =>
            Tiles.nameTile(
          context: context,
          controller: _emailController,
          hintText: "Email",
          labelText: "Email",
          errorText: null,
          handleClear: () {
            // This should still fire the listener.
            _emailController.clear();
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

  Widget _buildSignInButton() => ValueListenableBuilder(
      valueListenable: validSignup,
      builder: (BuildContext context, bool valid, Widget? child) {
        return FilledButton.icon(
          icon: const Icon(Icons.cloud_sync_rounded),
          onPressed: (valid)
              ? () async {
                  if (!validateEmail()) {
                    return;
                  }
                  await userProvider
                      .signInOTP(
                    email: _emailController.text,
                  )
                      .then((_) {
                    Tiles.displayAlert(message: "Check your email for an OTP");
                  }).catchError((e) async {
                    Tiles.displayError(e: e);
                  });
                }
              : null,
          label: const AutoSizeText("Get OTP",
              softWrap: true,
              overflow: TextOverflow.visible,
              maxLines: 2,
              minFontSize: Constants.large),
        );
      });

  Widget _buildChallengeButton() => ValueListenableBuilder(
      valueListenable: validChallenge,
      builder: (BuildContext context, bool valid, Widget? child) {
        return FilledButton.icon(
          icon: const Icon(Icons.login_rounded),
          onPressed: (valid) ? handleVerify : null,
          label: const AutoSizeText("Sign In",
              softWrap: false,
              overflow: TextOverflow.visible,
              maxLines: 1,
              minFontSize: Constants.large),
        );
      });
}
