import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class ExpandingLineText extends StatelessWidget {
  //final Widget child;
  final Function? onChanged;
  final void Function(String)? onFieldSubmitted;
  //final Function? onSubmitted;
  final TextEditingController? controller;
  final FormFieldValidator? validator;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final FocusNode? nextNode;
  final String? labelText;
  final int? maxLines;
  final int? maxLength;
  final double fontSize;
  final String? hintText;
  final double hintSize;
  final String? counterText;
  final Color? underline;
  final bool expands;
  final Color? labelColor;
  final Color? textColor;
  final bool readOnly;
  final bool numbersOnly;
  final bool enableInteractiveSelection;
  final bool autoFocus;
  final bool obscureText;

  const ExpandingLineText({
    Key? key,
    // @required this.child,
    this.labelColor,
    this.textColor,
    this.controller,
    this.validator,
    this.textInputAction,
    this.focusNode,
    this.nextNode,
    this.labelText,
    this.hintText,
    this.onChanged,
    this.maxLines = 5,
    this.maxLength,
    this.fontSize = 16,
    this.hintSize = 16,
    this.underline,
    this.counterText,
    this.expands = false,
    this.readOnly = false,
    this.numbersOnly = false,
    this.onFieldSubmitted,
    this.autoFocus = false,
    //this.onSubmitted,
    this.enableInteractiveSelection = true,
    this.obscureText = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(splashColor: Colors.transparent),
      child: LayoutBuilder(
        builder: (context, size) {
          TextSpan text = TextSpan(
            text: labelText,
            //style: yourTextStyle,
          );

          TextPainter tp = TextPainter(
            text: text,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
          );
          tp.layout(maxWidth: size.maxWidth);

          int lines = (tp.size.height / tp.preferredLineHeight).ceil();

          return MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1)),
            child: TextFormField(
              autofocus: autoFocus,
              textCapitalization: TextCapitalization.sentences,
              enableInteractiveSelection: enableInteractiveSelection,
              textAlign: TextAlign.start,
              controller: controller,
              validator: validator,
              focusNode: focusNode,
              textInputAction: textInputAction,
              onChanged: onChanged as void Function(String)?,
              keyboardType: numbersOnly ? TextInputType.number : null,
              keyboardAppearance: Brightness.dark,
              onFieldSubmitted: onFieldSubmitted,
              inputFormatters:
                  numbersOnly
                      ? <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                      ]
                      : null,
              readOnly: readOnly,
              obscureText: obscureText,
              cursorColor: globalState.theme.textField,
              //minLines: 1,
              maxLength: maxLength,
              maxLines:
                  maxLines == null
                      ? null
                      : (lines < maxLines! ? null : maxLines),
              expands: expands,
              style: TextStyle(
                fontSize: fontSize,
                color: textColor ?? globalState.theme.textFieldText,
              ),
              decoration: InputDecoration(
                //filled: true,
                //fillColor: globalState.theme.textField,
                labelText: labelText,
                hintText: hintText,
                counterText: counterText,
                counterStyle:
                    counterText == null
                        ? null
                        : TextStyle(color: globalState.theme.labelTextSubtle),

                ///uncomment this to show a visible counter
                //counterStyle: TextStyle(height: double.minPositive,),
                errorStyle: TextStyle(color: Colors.red, fontSize: hintSize),
                labelStyle: TextStyle(
                  color: labelColor ?? globalState.theme.textFieldLabel,
                  fontSize: hintSize,
                ),
                //hintStyle: TextStyle(color: Colors.blue),
                contentPadding: const EdgeInsets.all(10),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: globalState.theme.textField),
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: globalState.theme.buttonDisabled,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                // onChanged: onChanged,
              ),
            ),
          );
        },
      ),
    );
  }
}
