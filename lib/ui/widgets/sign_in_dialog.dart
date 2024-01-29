import 'package:allocate/ui/widgets/tiles.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../../providers/application/layout_provider.dart';
import '../../providers/model/user_provider.dart';
import '../../util/constants.dart';

// This needs to do both sign-up and sign-in
class SignInDialog extends StatefulWidget {
  const SignInDialog({super.key, this.signUp = false});

  final bool signUp;

  @override
  State<StatefulWidget> createState() => _SignInDialog();
}

class _SignInDialog extends State<SignInDialog> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final LayoutProvider layoutProvider;
  late final UserProvider userProvider;

  late final ValueNotifier<bool> validSubmit;

  @override
  void initState() {
    super.initState();
    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);
    userProvider = Provider.of<UserProvider>(context, listen: false);
    validSubmit = ValueNotifier<bool>(false);

    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _emailController.addListener(announceEmail);
    _passwordController.addListener(announcePassword);
  }

  @override
  void dispose() {
    _emailController.removeListener(announceEmail);
    _passwordController.removeListener(announcePassword);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // This is just because of listener signatures
  void announceEmail() {
    announceText(_emailController);
  }

  void announcePassword() {
    announceText(_passwordController);
  }

  void announceText(TextEditingController controller) {
    SemanticsService.announce(controller.text, Directionality.of(context));

    validSubmit.value =
        _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty;
  }

  bool validateEmailPassword() {
    bool valid = true;
    // This is probably faster than a regular expression
    // given the minimal amount of validation happening here.
    if (!_emailController.text.contains(RegExp(r".*@.*\..*"), 1)) {
      valid = false;
      Tiles.displayError(
          context: context, e: Exception("Invalid email format"));
    }

    // This should never happen
    if (_passwordController.text.isEmpty) {
      valid = false;

      Tiles.displayError(context: context, e: Exception("Invalid password"));
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
                    Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AutoSizeText(
                              widget.signUp ? "Sign Up" : "Sign In",
                              softWrap: false,
                              maxLines: 1,
                              minFontSize: Constants.huge,
                              overflow: TextOverflow.visible,
                              style: Constants.largeHeaderStyle,
                            ),
                          )
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
                        children: [Expanded(child: _buildPasswordTile())],
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

  Widget _buildPasswordTile() => Tiles.nameTile(
        context: context,
        controller: _passwordController,
        hintText: "Password",
        labelText: "Password",
        errorText: null,
        handleClear: () {
          _passwordController.clear();
        },
        onEditingComplete: () {},
      );

  Widget _buildSignInButton() => ValueListenableBuilder(
      valueListenable: validSubmit,
      builder: (BuildContext context, bool valid, Widget? child) {
        if (widget.signUp) {
          return FilledButton.icon(
            icon: const Icon(Icons.cloud_sync_rounded),
            onPressed: (valid)
                ? () async {
                    if (!validateEmailPassword()) {
                      return;
                    }
                    await userProvider
                        .signUp(
                            email: _emailController.text,
                            password: _passwordController.text)
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
        }
        return FilledButton.icon(
          icon: const Icon(Icons.login_rounded),
          onPressed: (valid)
              ? () async {
                  if (!validateEmailPassword()) {
                    return;
                  }
                  await userProvider
                      .signIn(
                          email: _emailController.text,
                          password: _passwordController.text)
                      .then((_) => Navigator.pop(context, true))
                      .catchError((e) async {
                    Tiles.displayError(context: context, e: e);
                  });
                }
              : null,
          label: const AutoSizeText("Sign in",
              softWrap: false,
              overflow: TextOverflow.visible,
              maxLines: 1,
              minFontSize: Constants.large),
        );
      });
}
