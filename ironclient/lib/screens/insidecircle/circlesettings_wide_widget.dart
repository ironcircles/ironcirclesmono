/*import 'package:flutter/material.dart';

import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class CircleSettingsWideWidget extends StatefulWidget {
  final Circle circle;
  final bool showLabel;

  CircleSettingsWideWidget({
    Key? key,
    required this.circle,
    this.showLabel = true,
  }) : super(key: key);

  @override
  CircleWideSettingsState createState() => CircleWideSettingsState();
}

class CircleWideSettingsState extends State<CircleSettingsWideWidget> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  //File? _image;
  //CircleBloc _circleBloc = CircleBloc();
  //UserCircleBloc _userCircleBloc = UserCircleBloc();

  List<bool>? privacyVotingModel;
  List<bool>? securityVotingModel;

  TextEditingController securityTokenExpirationDays = TextEditingController();
  TextEditingController securityLoginAttempts = TextEditingController();
  TextEditingController securityMinPassword = TextEditingController();
  TextEditingController securityDaysPasswordValid = TextEditingController();
  List<bool>? security2FA;
  List<bool>? privacyShareImage;
  List<bool>? privacyShareGif;
  List<bool>? privacyShareURL;
  List<bool>? privacyCopyText;

  //List<bool> votingModelSharePhotos;
  //List<bool> settingSharePhotos;

  String? _disappearingTimer = "off";
  List<String> timerValues = [
    "off",
    "4 hours",
    "8 hours",
    "1 day",
    "1 week",
    "30 days",
    "90 days",
    "6 months",
    "1 year"
  ];

  //String? _dataRetention = "pass through";

  Circle? _circle;

  bool changed = false;

  void _initUI(Circle circle) {
    if (circle.privacyDisappearingTimer != null)
      _disappearingTimer = getStringFromTimer(circle.privacyDisappearingTimer!);

    circle.privacyVotingModel == CircleVoteModel.MAJORITY
        ? privacyVotingModel = [true, false]
        : privacyVotingModel = [false, true];

    circle.securityVotingModel == CircleVoteModel.MAJORITY
        ? securityVotingModel = [true, false]
        : securityVotingModel = [false, true];

    //circle.security2FA == true
    //? security2FA = [true, false]
    // : security2FA = [false, true];

    securityTokenExpirationDays.text =
        circle.securityTokenExpirationDays.toString();

    securityMinPassword.text = circle.securityMinPassword.toString();

    securityLoginAttempts.text = circle.securityLoginAttempts.toString();

    securityDaysPasswordValid.text =
        circle.securityDaysPasswordValid.toString();

    circle.privacyShareImage == true
        ? privacyShareImage = [true, false]
        : privacyShareImage = [false, true];

    circle.privacyShareGif == true
        ? privacyShareGif = [true, false]
        : privacyShareGif = [false, true];

    circle.privacyShareURL == true
        ? privacyShareURL = [true, false]
        : privacyShareURL = [false, true];

    circle.privacyCopyText == true
        ? privacyCopyText = [true, false]
        : privacyCopyText = [false, true];
  }

  @override
  void initState() {
    _initUI(widget.circle);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final divider = Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: Divider(
          color: globalState.theme.divider,
          height: 20,
          thickness: 5,
          indent: 0,
          endIndent: 0,
        ));

    final makeBody = Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 20),
      child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              widget.showLabel
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        "Privacy settings:",
                        textScaleFactor: globalState.labelScaleFactor,
                        style: TextStyle(
                            fontSize: 18, color: globalState.theme.buttonIcon),
                      ))
                  : Container(),
              _toggleButton("Privacy Voting Model:", "majority", "unanimous",
                  privacyVotingModel!,
                  alignLeft: widget.showLabel ? true : false, callback: null),
              widget.showLabel
                  ? Padding(
                      padding:
                          const EdgeInsets.only(left: 55, top: 0, bottom: 0),
                      child: divider,
                    )
                  : Container(),
              /*Padding(
                  padding: const EdgeInsets.only(left: 11, top: 4, bottom: 0),
                  child: Row(children: <Widget>[
                    Expanded(
                        flex: 1,
                        child: Padding(
                            padding: EdgeInsets.only(left: 2),
                            child: Text('Data Retention:',
                                style: TextStyle(
                                    color:
                                        globalState.theme.toggleAlignRight)))),
                    Expanded(
                        flex: 1,
                        child: Padding(
                          padding: EdgeInsets.only(top: 0, left: 10),
                          child: TextButton(
                              style: TextButton.styleFrom(
                                primary: globalState.theme.textField,
                                backgroundColor:
                                    globalState.theme.tabBackground,
                              ),
                              onPressed: () {
                                //_forgeBoost();
                              },
                              child: Text(_circle!.retention! == 0
                                  ? 'device only'
                                  : _circle!.retention! < 1000
                                      ? _circle!.retention!.toString() + ' GB'
                                      : (_circle!.retention! / 1000)
                                              .toString() +
                                          ' TB')),
                        ))
                  ]),
                ),

                 */
              Padding(
                padding: const EdgeInsets.only(left: 11, top: 0, bottom: 0),
                child: Row(children: <Widget>[
                  Expanded(
                      flex: 1,
                      child: Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Text('Disappearing messages:',
                              textScaleFactor: globalState.labelScaleFactor,
                              style: TextStyle(
                                  color: globalState.theme.toggleAlignRight)))),
                  Expanded(
                    flex: 1,
                    child: Padding(
                        padding: const EdgeInsets.only(left: 0),
                        child: FormField(
                          builder: (FormFieldState<String> state) {
                            return FormattedDropdown(
                              // hintText: 'off',
                              list: timerValues,
                              dropdownTextColor:
                                  globalState.theme.textFieldText,
                              selected: _disappearingTimer,
                              errorText:
                                  state.hasError ? state.errorText : null,
                              onChanged: (String? value) {
                                setState(() {
                                  _disappearingTimer = value;
                                  if (value!.isEmpty) value = null;
                                  state.didChange(value);
                                });
                              },
                            );
                          },
                          validator: (dynamic value) {
                            return _disappearingTimer == null ? 'off' : null;
                          },
                        )),
                  )
                ]),
              ),
              const Padding(padding: EdgeInsets.only(top: 10, right: 0)),
              _toggleButton("Sharing images/videos:", "allowed", "disallowed",
                  privacyShareImage!),
              /*_toggleButton("Voting Model:", "majority", "unanimous",
                    settingShareImageModel,
                    alignLeft: true),*/

              //thinDivider,
              //Padding(padding: EdgeInsets.only(top: 10, right: 0)),
              _toggleButton(
                  "Sharing urls:", "allowed", "disallowed", privacyShareURL!),
              /* _toggleButton("Voting Model:", "majority", "unanimous",
                    settingShareURLModel,
                    alignLeft: true),*/
              //thinDivider,
              _toggleButton("Copying message text:", "allowed", "disallowed",
                  privacyCopyText!),
              /*_toggleButton("Voting Model:", "majority", "unanimous",
                    settingCopyTextModel,
                    alignLeft: true),*/
              //thinDivider,
              _toggleButton(
                  "Sharing gifs:", "allowed", "disallowed", privacyShareGif!),
              /* _toggleButton("Voting Model:", "majority", "unanimous",
                    settingShareGifModel,
                    alignLeft: true),*/
              //divider,
            ],
          )),
    );

    return makeBody;
  }

  _toggleButton(String label, String a, String b, List<bool> list,
      {bool alignLeft = false, Function? callback}) {
    return Row(children: <Widget>[
      Expanded(
          child: Padding(
              padding: const EdgeInsets.only(left: 15, right: 5),
              child: Text(
                label,
                textScaleFactor: 1.0,
                textAlign: alignLeft ? TextAlign.end : TextAlign.start,
                style: TextStyle(
                    color: alignLeft
                        ? globalState.theme.toggleAlignLeft
                        : globalState.theme.toggleAlignRight),
              ))),
      ToggleButtons(
        selectedColor: globalState.theme.button,
        //highlightColor: Colors.yellow,
        children: <Widget>[
          SizedBox(
              width: 80,
              child: Center(
                  child: Text(
                a,
                textScaleFactor: 1.0,
                style: TextStyle(
                    color: list[0]
                        ? globalState.theme.buttonIcon
                        : globalState.theme.labelTextSubtle),
              ))),
          SizedBox(
              width: 85,
              child: Center(
                  child: Text(
                b,
                textScaleFactor: 1.0,
                style: TextStyle(
                    color: list[1]
                        ? globalState.theme.buttonIcon
                        : globalState.theme.labelTextSubtle),
              ))),
        ],
        onPressed: (int index) {
          setState(() {
            for (int buttonIndex = 0;
                buttonIndex < list.length;
                buttonIndex++) {
              if (buttonIndex == index) {
                list[buttonIndex] = true;
              } else {
                list[buttonIndex] = false;
              }
            }

            if (callback != null) {
              if (list[0] == true)
                callback(b, a);
              else
                callback(a, b);
            }
          });
        },
        isSelected: list,
      )
    ]);
  }

  /*String _getSecurityChangesDisplayValue() {
    List<CircleSettingValue> list = _securityValuesThatChanged();

    String retValue = "";

    for (CircleSettingValue circleSettingValue in list) {
      if (retValue.isEmpty)
        retValue =
            '${circleSettingValue.displayValue} from ${circleSettingValue.originalValue} to ${circleSettingValue.settingValue}';
      else
        retValue = retValue +
            '\n\n${circleSettingValue.displayValue} from ${circleSettingValue.originalValue} to ${circleSettingValue.settingValue}';
    }

    return retValue;
  }

  _setSecurity(String message) {
    List<CircleSettingValue> list = _securityValuesThatChanged();

    if (list.length > 0) {
      _circleBloc.updateSetting(widget.userFurnace, _circle!.id!, list, message,
          CircleSettingChangeType.SECURITY);

      FormattedSnackBar.showSnackbar(
          _scaffoldKey, "requesting security changes, please wait...", "", 1);
    } else {
      FormattedSnackBar.showSnackbarWithContext(context, "nothing changed", "", 1);
    }
  }

   */

  String _getPrivacyChangesDisplayValue() {
    List<CircleSettingValue> list = _privacyValuesThatChanged();

    String retValue = "";

    for (CircleSettingValue circleSettingValue in list) {
      if (retValue.isEmpty)
        retValue =
            '${circleSettingValue.displayValue} - ${circleSettingValue.originalValue} to ${circleSettingValue.settingValue}';
      else
        retValue = retValue +
            '\n\n${circleSettingValue.displayValue} - ${circleSettingValue.originalValue} to ${circleSettingValue.settingValue}';
    }

    return retValue;
  }

  _unsetSecurityVotingModel() {
    setState(() {
      _circle!.securityVotingModel == CircleVoteModel.MAJORITY
          ? securityVotingModel = [true, false]
          : securityVotingModel = [false, true];
    });
  }

  _unsetPrivacyVotingModel() {
    setState(() {
      _circle!.privacyVotingModel == CircleVoteModel.MAJORITY
          ? privacyVotingModel = [true, false]
          : privacyVotingModel = [false, true];
    });
  }

  String getVoteModelString(List<bool> setting) {
    if (setting[0])
      return CircleVoteModel.MAJORITY;
    else
      return CircleVoteModel.UNANIMOUS;
  }

  bool getSecurityBool(List<bool> setting) {
    if (setting[0])
      return true;
    else
      return false;
  }

  String getSettingString(List<bool> setting) {
    if (setting[0] == true)
      return 'allowed';
    else
      return 'disallowed';
  }

  String getBoolSettingString(bool? setting) {
    if (setting == true)
      return 'allowed';
    else
      return 'disallowed';
  }

  int getTimerInHours() {
    int retValue = 0;

    if (_disappearingTimer == CircleDisappearingTimerStrings.OFF)
      retValue = CircleDisappearingTimer.OFF;
    else if (_disappearingTimer == CircleDisappearingTimerStrings.FOUR_HOURS)
      retValue = CircleDisappearingTimer.FOUR_HOURS;
    else if (_disappearingTimer == CircleDisappearingTimerStrings.EIGHT_HOURS)
      retValue = CircleDisappearingTimer.EIGHT_HOURS;
    else if (_disappearingTimer == CircleDisappearingTimerStrings.ONE_DAY)
      retValue = CircleDisappearingTimer.ONE_DAY;
    else if (_disappearingTimer == CircleDisappearingTimerStrings.ONE_WEEK)
      retValue = CircleDisappearingTimer.ONE_WEEK;
    else if (_disappearingTimer == CircleDisappearingTimerStrings.THIRTY_DAYS)
      retValue = CircleDisappearingTimer.THIRTY_DAYS;
    else if (_disappearingTimer == CircleDisappearingTimerStrings.NINETY_DAYS)
      retValue = CircleDisappearingTimer.NINETY_DAYS;
    else if (_disappearingTimer == CircleDisappearingTimerStrings.SIX_MONTHS)
      retValue = CircleDisappearingTimer.SIX_MONTHS;
    else if (_disappearingTimer == CircleDisappearingTimerStrings.ONE_YEAR)
      retValue = CircleDisappearingTimer.ONE_YEAR;

    return retValue;
  }

  String getStringFromTimer(int timer) {
    String retValue = 'off';

    if (timer == CircleDisappearingTimer.OFF)
      retValue = CircleDisappearingTimerStrings.OFF;
    else if (timer == CircleDisappearingTimer.FOUR_HOURS)
      retValue = CircleDisappearingTimerStrings.FOUR_HOURS;
    else if (timer == CircleDisappearingTimer.EIGHT_HOURS)
      retValue = CircleDisappearingTimerStrings.EIGHT_HOURS;
    else if (timer == CircleDisappearingTimer.ONE_DAY)
      retValue = CircleDisappearingTimerStrings.ONE_DAY;
    else if (timer == CircleDisappearingTimer.ONE_WEEK)
      retValue = CircleDisappearingTimerStrings.ONE_WEEK;
    else if (timer == CircleDisappearingTimer.THIRTY_DAYS)
      retValue = CircleDisappearingTimerStrings.THIRTY_DAYS;
    else if (timer == CircleDisappearingTimer.NINETY_DAYS)
      retValue = CircleDisappearingTimerStrings.NINETY_DAYS;
    else if (timer == CircleDisappearingTimer.SIX_MONTHS)
      retValue = CircleDisappearingTimerStrings.SIX_MONTHS;
    else if (timer == CircleDisappearingTimer.ONE_YEAR)
      retValue = CircleDisappearingTimerStrings.ONE_YEAR;

    return retValue;
  }

  /*
  List<CircleSettingValue> _securityValuesThatChanged() {
    List<CircleSettingValue> list = [];

    /*
    //check votes first
    if (_circle.securityVotingModel != getVoteModelString(securityVotingModel))
      list.add(CircleSettingValue(
          setting: CircleSetting.SECURITY_VOTING_MODEL,
          settingValue: getVoteModelString(securityVotingModel)));*/

    //Now the text fields
    if (_circle!.securityMinPassword != int.parse(securityMinPassword.text))
      list.add(CircleSettingValue(
          originalValue: _circle!.securityMinPassword.toString(),
          displayValue: 'Minimum password length',
          setting: CircleSetting.SECURITY_MINPASSWORD,
          settingValue: securityMinPassword.text));

    if (_circle!.securityDaysPasswordValid !=
        int.parse(securityDaysPasswordValid.text))
      list.add(CircleSettingValue(
          originalValue: _circle!.securityDaysPasswordValid.toString(),
          displayValue: 'Password change (days)',
          setting: CircleSetting.SECURITY_DAYSPASSWORDVALID,
          settingValue: securityDaysPasswordValid.text));

    if (_circle!.securityTokenExpirationDays !=
        int.parse(securityTokenExpirationDays.text))
      list.add(CircleSettingValue(
          originalValue: _circle!.securityTokenExpirationDays.toString(),
          displayValue: 'Stay logged in (days)',
          setting: CircleSetting.SECURITY_TOKENEXPIRATIONDAYS,
          settingValue: securityTokenExpirationDays.text));

    if (_circle!.securityLoginAttempts != int.parse(securityLoginAttempts.text))
      list.add(CircleSettingValue(
          originalValue: _circle!.securityLoginAttempts.toString(),
          displayValue: 'Password attempts',
          setting: CircleSetting.SECURITY_LOGINATTEMPTS,
          settingValue: securityLoginAttempts.text));

    return list;
  }

   */

  List<CircleSettingValue> _privacyValuesThatChanged(
      {bool boolString = false}) {
    List<CircleSettingValue> list = [];

    //check votes first
    /*if (_circle.privacyVotingModel !=
        getVoteModelString(privacyVotingModel))
      list.add(CircleSettingValue(
          setting: CircleSetting.PRIVACY_VOTING_MODEL,
          settingValue: getVoteModelString(privacyVotingModel)));
*/

    bool setTimer = false;
    int requestedTimer = getTimerInHours();

    if (_circle!.privacyDisappearingTimer == null &&
        _disappearingTimer != "off")
      setTimer = true;
    else if (_circle!.privacyDisappearingTimer != null &&
        requestedTimer != _circle!.privacyDisappearingTimer) {
      setTimer = true;
    }

    if (setTimer)
      list.add(CircleSettingValue(
          originalValue: _circle!.privacyDisappearingTimer == null
              ? CircleDisappearingTimerStrings.OFF
              : getStringFromTimer(_circle!.privacyDisappearingTimer!),
          displayValue: 'Disappearing message timer',
          setting: CircleSetting.PRIVACY_DISAPPEARING_TIMER,
          settingValue: _disappearingTimer));

    if (_circle!.privacyShareImage !=
        getSecurityBool(
          privacyShareImage!,
        ))
      list.add(CircleSettingValue(
          originalValue: getBoolSettingString(_circle!.privacyShareImage),
          displayValue: 'Sharing images',
          setting: CircleSetting.PRIVACY_SHAREIMAGE,
          settingValue: boolString
              ? getSecurityBool(privacyShareImage!).toString()
              : getSettingString(privacyShareImage!).toString()));

    if (_circle!.privacyShareGif != getSecurityBool(privacyShareGif!))
      list.add(CircleSettingValue(
          originalValue: getBoolSettingString(_circle!.privacyShareGif),
          displayValue: 'Sharing gifs',
          setting: CircleSetting.PRIVACY_SHAREGIF,
          settingValue: boolString
              ? getSecurityBool(privacyShareGif!).toString()
              : getSettingString(privacyShareGif!).toString()));

    if (_circle!.privacyShareURL != getSecurityBool(privacyShareURL!))
      list.add(CircleSettingValue(
          originalValue: getBoolSettingString(_circle!.privacyShareURL),
          displayValue: 'Sharing urls',
          setting: CircleSetting.PRIVACY_SHAREURL,
          settingValue: boolString
              ? getSecurityBool(privacyShareURL!).toString()
              : getSettingString(privacyShareURL!).toString()));

    if (_circle!.privacyCopyText != getSecurityBool(privacyCopyText!))
      list.add(CircleSettingValue(
          originalValue: getBoolSettingString(_circle!.privacyCopyText),
          displayValue: 'Copying message text',
          setting: CircleSetting.PRIVACY_COPYTEXT,
          settingValue: boolString
              ? getSecurityBool(privacyCopyText!).toString()
              : getSettingString(privacyCopyText!).toString()));

    return list;
  }

  /*void _forgeBoost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ForgeBoost(
                userCircleCache: widget.userCircleCache,
                userFurnace: widget.userFurnace,
                circle: _circle!,
              )),
    );

    if (result != null) {
      setState(() {});
    }
  }

   */
}

 */
