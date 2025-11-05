import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class FormattedDropdownObject extends StatelessWidget {
  final List<ListItem> list;
  final ListItem? selected;
  final String hintText;
  final Function onChanged;
  final String? errorText;
  final Color? underline;
  final Color? dropdownTextColor;
  final double fontSize;
  final bool expanded;
  // FormFieldState formFieldState;

  const FormattedDropdownObject(
      {Key? key,
      // @required this.child,
      required this.list,
      required this.selected,
      required this.onChanged,
      required this.hintText,
      this.errorText,
      this.underline,
      this.expanded = false,
      this.fontSize = 16,
      this.dropdownTextColor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<DropdownMenuItem<ListItem>> items = [];

    //List<DropdownMenuItem<ListItem>> _dropdownMenuItems;

    for (ListItem listItem in list) {
      items.add(DropdownMenuItem(
        value: listItem,
        child: MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(1),
          ),
          child: Text(
            listItem.name!,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: dropdownTextColor ?? globalState.theme.dropdownText,
              fontSize: (fontSize / globalState.mediaScaleFactor) *
                  globalState.dropdownScaleFactor,
            ),
          ),
        ),
      ));
    }

    return /*Theme(
        data: Theme.of(context).copyWith(splashColor: Colors.transparent),
        child:*/
        MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1),
            ),
            child: InputDecorator(
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(10),
                hintText: hintText.isEmpty ? null : hintText,
                labelText: hintText.isEmpty ? null : hintText,
                labelStyle: TextStyle(
                    color: globalState.theme.textFieldLabel,
                    fontSize: fontSize),
                hintStyle: TextStyle(
                  color: globalState.theme.textFieldLabel,
                  fontSize: fontSize,
                ),
                helperStyle: TextStyle(
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
                  fontSize: fontSize,
                ),
              ),
              isEmpty: selected!.name == '',
              child: DropdownButtonHideUnderline(
                child: Theme(
                  data: Theme.of(context).copyWith(
                      canvasColor: globalState.theme.dropdownBackground),
                  child: MediaQuery(
                      data: const MediaQueryData(
                        textScaler: TextScaler.linear(1),
                      ),
                      child: DropdownButton<ListItem>(
                        isDense: true,
                        style: TextStyle(
                            color: globalState.theme.textFieldLabel,
                            fontSize: fontSize),
                        value: selected,
                        onChanged: onChanged as void Function(ListItem?)?,
                        items: items,
                        isExpanded: expanded,
                      )),
                ),
              ),
            )) /*)*/;
  }
}

class ListItem {
  var object;
  String? name;

  ListItem({this.object, this.name});
}
