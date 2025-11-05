import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class ExpandingText extends StatelessWidget {
  //final Widget child;
  final Function? onPressed;
  final Function? onChanged;
  final TextEditingController? controller;
  final FormFieldValidator? validator;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final FocusNode? nextNode;
  final String labelText;
  final double height;
  final int? fontSize;
  final String? hintText;
  final bool obscureText;
  final bool capitals;
  final bool enableInteractiveSelection;
  final bool readOnly;
  final int maxLength;
  final TextInputType? textInputType;

  const ExpandingText({
    Key? key,
    // @required this.child,
    this.controller,
    this.validator,
    this.textInputAction,
    this.textInputType,
    this.focusNode,
    this.nextNode,
    required this.labelText,

    this.hintText,
    this.onPressed,
    this.onChanged,
    this.height = 100,
    this.fontSize,
    this.obscureText = false,
    this.capitals = false,
    this.enableInteractiveSelection = true,
    this.readOnly = false,
    this.maxLength = 1000,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(splashColor: Colors.transparent),
      child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight:
                  height //put here the max height to which you need to resize the textbox
              ),
          child: MediaQuery(
                  data: const MediaQueryData(
    textScaler: TextScaler.linear(1),
    ),
    child:  TextFormField(
            cursorColor: globalState.theme.textField,
            readOnly: readOnly,
            enableInteractiveSelection: enableInteractiveSelection,
            onChanged: onChanged as void Function(String)?,
            controller: controller,
            validator: validator,
            textInputAction: textInputAction,
            keyboardType: textInputType,
            maxLines: null,
            maxLength: maxLength,
            textCapitalization: capitals
                ? TextCapitalization.sentences
                : TextCapitalization.none,
            obscureText: obscureText,
            /*onFieldSubmitted: (term) {
          focusNode!.unfocus();
          FocusScope.of(context).requestFocus(nextNode);
        },*/
            //onFieldSubmitted: (value) => onChanged!(value),
            style: TextStyle(
                fontSize: fontSize == null
                    ? 18
                    : fontSize!.toDouble(),
                color: globalState.theme.textFieldText),
            decoration: InputDecoration(
              //filled: true,
              //fillColor: globalState.theme.textField,

              labelText: labelText,
              hintText: hintText,
              //hintStyle: TextStyle(color: globalState.theme.messageTextHint),
              labelStyle: TextStyle(color: globalState.theme.textFieldLabel),
              //hintStyle: TextStyle(color: Colors.blue),
              contentPadding:
                  const EdgeInsets.all(10),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: globalState.theme.button),
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: globalState.theme.buttonDisabled),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ))),
    );
  }
}
