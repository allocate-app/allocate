import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../../providers/application/layout_provider.dart';
import '../../providers/viewmodels/user_viewmodel.dart';
import '../../util/constants.dart';
import 'tiles.dart';

class SimpleNameDialog extends StatefulWidget {
  const SimpleNameDialog({super.key});

  @override
  State<SimpleNameDialog> createState() => _SimpleNameDialog();
}

class _SimpleNameDialog extends State<SimpleNameDialog> {
  late final UserViewModel vm;
  late final LayoutProvider layoutProvider;
  late final TextEditingController _nameController;

  late final ValueNotifier<String> _newName;

  @override
  void initState() {
    super.initState();

    vm = Provider.of<UserViewModel>(context, listen: false);

    _newName = ValueNotifier<String>(vm.username);

    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);
    _nameController = TextEditingController(text: _newName.value);
    _nameController.addListener(watchName);
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void dispose() {
    _nameController.removeListener(watchName);
    _nameController.dispose();
    super.dispose();
  }

  void watchName() {
    String newText = _nameController.text;
    SemanticsService.announce(newText, Directionality.of(context));
    _newName.value = newText;
  }

  @override
  Widget build(context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) => PopScope(
          canPop: false,
          onPopInvoked: (bool didPop) {
            if (didPop) {
              return;
            }
            if (_newName.value.isNotEmpty) {
              vm.username = _newName.value;
            }
            Navigator.pop(context);
          },
          child: Dialog(
            insetPadding: (layoutProvider.smallScreen)
                ? const EdgeInsets.all(Constants.mobileDialogPadding)
                : const EdgeInsets.all(Constants.outerDialogPadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: Constants.smallLandscapeDialogHeight,
                maxWidth: Constants.usernameEditorMaxWidth,
              ),
              child: Padding(
                  padding: const EdgeInsets.all(Constants.doublePadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: _buildNameTile(),
                          ),
                        ],
                      ),
                    ],
                  )),
            ),
          ),
        ),
      );

  Widget _buildNameTile() => ValueListenableBuilder<String>(
        valueListenable: _newName,
        builder: (BuildContext context, String value, Widget? child) =>
            Tiles.nameTile(
                context: context,
                controller: _nameController,
                hintText: "Username",
                labelText: "Username",
                errorText: null,
                handleClear: () {
                  _nameController.clear();
                  _newName.value = "";
                },
                onEditingComplete: () {
                  _newName.value = _nameController.text;

                  if (_newName.value.isNotEmpty) {
                    vm.username = _newName.value;
                  }

                  Navigator.pop(context);
                }),
      );
}
