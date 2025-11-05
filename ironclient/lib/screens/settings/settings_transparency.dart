import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/globalstate.dart';
import 'package:ironcirclesapp/screens/widgets/dialogpasswordauth.dart';


class TransparencySettings extends StatefulWidget {


  const TransparencySettings();

  @override
  TransparencySettingsState createState() => TransparencySettingsState();
}

class TransparencySettingsState extends State<TransparencySettings> {
  bool? _transparency = false;
  //UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();
  //bool _showPassword = false;

  @override
  void initState() {
    _transparency = globalState.userFurnace!.transparency;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding:
            const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20),
        child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
          constraints: const BoxConstraints(),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 0),
                  child: Row(children: <Widget>[
                    Text(
                      'Enable partner/parental transparency controls?',
                      style: TextStyle(
                          fontSize: 16, color: globalState.theme.textFieldLabel),
                    ),
                    //secondary: const Icon(Icons.remove_red_eye),
                  ]),
                ),

                // Spacer(flex: 1),

                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 0),
                  child: Row(children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: Container(
                        //color: globalState.theme.textField,
                        child: SwitchListTile(inactiveThumbColor: globalState.theme.inactiveThumbColor,
                          activeColor: globalState.theme.button,
                          inactiveTrackColor: globalState.theme.inactiveTrackColor,
                          trackOutlineColor: MaterialStateProperty.resolveWith(globalState.getSwitchColor),
                          title: Text(
                            _transparency! ? "Enabled" : "Disabled",
                            style: TextStyle(
                                fontSize: 18,
                                color: globalState.theme.textFieldLabel),
                          ),
                          value: _transparency!,
                          onChanged: (bool value) {
                            setState(() {
                              if (value)
                                DialogPasswordAuth.passwordPopup(
                                    context, globalState.userFurnace!, _success);
                            });
                          },
                          //secondary: const Icon(Icons.remove_red_eye),
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                  ]),
                ),
              ]),
        )));
  }

  void _success(){
    setState(() {
      _transparency = true;
      globalState.userFurnace!.transparency = true;
    });
  }


}
