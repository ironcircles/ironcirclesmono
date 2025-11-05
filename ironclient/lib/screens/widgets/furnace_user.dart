import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class FurnaceUser extends StatelessWidget {
  final UserFurnace userFurnace;

  const FurnaceUser({Key? key, required this.userFurnace}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: <Widget>[
            Expanded(
                child: Row(children: <Widget>[
              Text(
                "Furnace alias : ",
                style: TextStyle(color: globalState.theme.textFieldLabel),
              ),
              Text(
                "${userFurnace.alias}",
                style: TextStyle(color: globalState.theme.textFieldText),
              )
            ])),
            Expanded(
                child: Row(children: <Widget>[
              Text(
                "username : ",
                style: TextStyle(color: globalState.theme.textFieldLabel),
              ),
              Text(
                "${userFurnace.username}",
                style: TextStyle(color: globalState.theme.textFieldText),
              )
            ])),
          ],
        ));
  }
}
