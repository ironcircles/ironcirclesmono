import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class FormattedDropdown extends StatelessWidget {
  final List<String?>? list;
  final String? selected;
  final String? hintText;
  final Function onChanged;
  final String? errorText;
  final Color? underline;
  final Color? dropdownTextColor;
  final double fontSize;
  final bool expanded;
  // FormFieldState formFieldState;

  const FormattedDropdown(
      {Key? key,
      // @required this.child,
      required this.list,
      required this.selected,
      required this.onChanged,
      this.hintText,
      this.errorText,
      this.expanded = false,
      this.underline,
      this.fontSize = 16,
      this.dropdownTextColor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
        data: Theme.of(context).copyWith(splashColor: Colors.transparent),
        child: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1),
            ),
            child: InputDecorator(
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(10),
                hintText: hintText,
                labelText: hintText,
                hintStyle: TextStyle(
                    color: globalState.theme.textFieldLabel,
                    fontSize: fontSize),
                labelStyle: TextStyle(
                    color: globalState.theme.textFieldLabel,
                    fontSize: fontSize),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: globalState.theme.button),
                  borderRadius: BorderRadius.circular(16),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: globalState.theme.labelTextSubtle),
                  borderRadius: BorderRadius.circular(12),
                ),
                errorText: errorText,
                errorStyle: TextStyle(
                    color: globalState.theme.textFieldLabel,
                    fontSize: fontSize),
              ),
              isEmpty: selected == '',
              child: DropdownButtonHideUnderline(
                child: Theme(
                  data: Theme.of(context).copyWith(
                      canvasColor: globalState.theme.dropdownBackground),
                  child: DropdownButton<String>(
                    isDense: true,
                    value: selected,
                    isExpanded: expanded,
                    onChanged: onChanged as void Function(String?)?,
                    items: list!.map<DropdownMenuItem<String>>((String? value) {
                      return DropdownMenuItem<String>(
                          value: value,
                          child: MediaQuery(
                            data: const MediaQueryData(
                              textScaler: TextScaler.linear(1),
                            ),
                            child: Text(
                              value!,
                              style: TextStyle(
                                color: dropdownTextColor ??
                                    globalState.theme.dropdownText,
                                fontSize: fontSize,
                              ),
                            ),
                          ));
                    }).toList(),
                  ),
                ),
              ),
            )));
  }
}
