import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class FormattedText extends StatelessWidget {
  //final Widget child;
  final Function? onPressed;
  final Function? onChanged;
  final TextEditingController? controller;
  final FormFieldValidator? validator;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final FocusNode? nextNode;
  final String labelText;
  final int maxLines;
  final double fontSize;
  final String? hintText;
  final bool obscureText;
  final bool capitals;
  final bool enableInteractiveSelection;
  final bool readOnly;
  final TextStyle? textStyle;
  final int? maxLength;
  final bool autoFocus;

  const FormattedText({
    Key? key,
    // @required this.child,

    this.controller,
    this.validator,
    this.textInputAction,
    this.focusNode,
    this.nextNode,
    required this.labelText,
    this.textStyle,
    this.hintText,
    this.onPressed,
    this.onChanged,
    this.maxLines = 1,
    this.maxLength,
    this.fontSize = 18,
    this.autoFocus = false,
    this.obscureText = false,
    this.capitals = false,
    this.enableInteractiveSelection = true,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(splashColor: Colors.transparent),
      child: MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(1),
          ),
          child: TextFormField(
            cursorColor: globalState.theme.textField,
            readOnly: readOnly,
            autofocus: autoFocus,
            enableInteractiveSelection: enableInteractiveSelection,
            onChanged: onChanged as void Function(String)?,
            controller: controller,
            validator: validator,
            textInputAction: textInputAction,
            maxLines: maxLines,
            textCapitalization: capitals
                ? TextCapitalization.sentences
                : TextCapitalization.none,
            obscureText: obscureText,
            maxLength: maxLength,
            /*onFieldSubmitted: (term) {
          focusNode!.unfocus();
          FocusScope.of(context).requestFocus(nextNode);
        },*/
            //onFieldSubmitted: (value) => onChanged!(value),
            style: textStyle ??
                TextStyle(
                    fontSize: fontSize, color: globalState.theme.textFieldText),
            decoration: InputDecoration(
              //filled: true,
              //fillColor: globalState.theme.textField,
              labelText: labelText,
              hintText: hintText,
              errorStyle: TextStyle(color: Colors.red, fontSize: fontSize),
              counterStyle: TextStyle(fontSize: fontSize),
              //hintStyle: TextStyle(color: globalState.theme.messageTextHint),
              labelStyle: TextStyle(color: globalState.theme.textFieldLabel),
              //hintStyle: TextStyle(color: Colors.blue),
              contentPadding: const EdgeInsets.all(10),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: globalState.theme.button),
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: globalState.theme.labelTextSubtle),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )),
    );
  }
}
