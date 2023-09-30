import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:flutter/material.dart';

import '../../util/constants.dart';

// TODO: Move to Tiles Class -> No internal state.
class NameTile extends StatefulWidget {
  const NameTile({
    super.key,
    this.leading,
    this.hintText = "",
    this.errorText = "",
    this.controller,
    this.tilePadding = EdgeInsets.zero,
    this.textFieldPadding = EdgeInsets.zero,
    required this.clear,
  });

  final Widget? leading;
  final String? hintText;
  final String? errorText;
  final TextEditingController? controller;
  final EdgeInsetsGeometry tilePadding;
  final EdgeInsetsGeometry textFieldPadding;
  final void Function() clear;

  @override
  State<NameTile> createState() => _NameTile();
}

class _NameTile extends State<NameTile> {
  @override
  Widget build(context) {
    return Padding(
      padding: widget.tilePadding,
      child: Row(
        children: [
          widget.leading ?? const SizedBox.shrink(),
          Expanded(
            child: Padding(
              padding: widget.textFieldPadding,
              child: AutoSizeTextField(
                maxLines: 1,
                minFontSize: Constants.huge,
                decoration: InputDecoration(
                  suffixIcon: (widget.controller?.text.isNotEmpty ?? false)
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: widget.clear)
                      : null,
                  contentPadding: const EdgeInsets.all(Constants.innerPadding),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(
                          Radius.circular(Constants.roundedCorners)),
                      borderSide: BorderSide(
                        width: 2,
                        color: Theme.of(context).colorScheme.outlineVariant,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      )),
                  border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                          Radius.circular(Constants.roundedCorners)),
                      borderSide: BorderSide(
                        strokeAlign: BorderSide.strokeAlignOutside,
                      )),
                  hintText: widget.hintText,
                  errorText: widget.errorText,
                ),
                controller: widget.controller,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
