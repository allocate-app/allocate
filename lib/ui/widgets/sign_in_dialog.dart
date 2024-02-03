import 'package:allocate/ui/widgets/tiles.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../../providers/application/layout_provider.dart';
import '../../providers/model/user_provider.dart';
import '../../util/constants.dart';

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

  @override
  void initState() {
    super.initState();
    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);
    userProvider = Provider.of<UserProvider>(context, listen: false);
    validSignup = ValueNotifier<bool>(false);
    validChallenge = ValueNotifier<bool>(false);

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
    validChallenge.value =
        _emailController.text.isNotEmpty && _tokenController.text.isNotEmpty;
  }

  bool validateEmail() {
    bool valid = true;
    if (!_emailController.text.contains(RegExp(r".*@.*\..*"), 1)) {
      valid = false;
      Tiles.displayError(
          context: context, e: Exception("Invalid email format"));
    }

    return valid;
  }

  bool validateToken() {
    bool valid = true;
    if (_tokenController.text.isEmpty) {
      valid = false;

      Tiles.displayError(context: context, e: Exception("Invalid token"));
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

  Widget _buildEmailTile() => Tiles.nameTile(
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
      );

  Widget _buildTokenTile() => Tiles.nameTile(
        context: context,
        controller: _tokenController,
        hintText: "One-Time-Password",
        labelText: "One-Time-Password",
        errorText: null,
        handleClear: () {
          _tokenController.clear();
        },
        onEditingComplete: () {
          // TODO: factor out function to verifyOTP
        },
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
                    Navigator.pop(context, true);
                  }).catchError((e) async {
                    Tiles.displayError(context: context, e: e);
                  });
                }
              : null,
          label: const AutoSizeText("Sign up",
              softWrap: false,
              overflow: TextOverflow.visible,
              maxLines: 1,
              minFontSize: Constants.large),
        );
      });

  Widget _buildChallengeButton() => ValueListenableBuilder(
      valueListenable: validChallenge,
      builder: (BuildContext context, bool valid, Widget? child) {
        return FilledButton.icon(
          icon: const Icon(Icons.login_rounded),
          onPressed: (valid)
              ? () async {
                  if (!validateEmail()) {
                    return;
                  }
                  await userProvider
                      .verifyOTP(
                    email: _emailController.text,
                    token: _tokenController.text,
                  )
                      .then((_) {
                    Navigator.pop(context, true);
                  }).catchError((e) async {
                    Tiles.displayError(context: context, e: e);
                  });
                }
              : null,
          label: const AutoSizeText("Sign In",
              softWrap: false,
              overflow: TextOverflow.visible,
              maxLines: 1,
              minFontSize: Constants.large),
        );
      });
}
