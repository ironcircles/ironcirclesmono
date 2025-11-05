import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/circles/circle_new_wizard_invitations.dart';
import 'package:ironcirclesapp/screens/circles/circle_new_wizard_name.dart';
import 'package:ironcirclesapp/screens/themes/mastertheme.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';

class CircleNewWizardSettings extends StatefulWidget {
  final UserFurnace userFurnace;
  final WizardVariables wizardVariables;
  final List<String> timerValues;

  const CircleNewWizardSettings({
    required this.userFurnace,
    required this.wizardVariables,
    required this.timerValues,
  });

  @override
  _CircleNewWizardSettingsState createState() =>
      _CircleNewWizardSettingsState();
}

class _CircleNewWizardSettingsState extends State<CircleNewWizardSettings> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  TextEditingController securityTokenExpirationDays = TextEditingController();
  TextEditingController securityLoginAttempts = TextEditingController();
  TextEditingController securityMinPassword = TextEditingController();
  TextEditingController securityDaysPasswordValid = TextEditingController();
  List<bool>? securityVotingModel;
  List<bool>? privacyVotingModel;
  List<bool>? security2FA;
  List<bool>? privacyShareImage;
  List<bool>? privacyShareGif;
  List<bool>? privacyShareURL;
  List<bool>? privacyCopyText;
  List<bool>? toggleEntryVote;
  List<bool>? toggleMemberPosting;
  List<bool>? toggleMemberReacting;
  bool temporary = false;
  DateTime? endDate;
  DateTime? minimumDate;

  String? _disappearingTimer;
  List<String> _timerValues = [];

  _setupDisappearingTimer() {
    if (_timerValues.isEmpty) {
      _disappearingTimer = AppLocalizations.of(context)!.off;

      _timerValues.add(AppLocalizations.of(context)!.off);
      _timerValues.add(AppLocalizations.of(context)!.hours4);
      _timerValues.add(AppLocalizations.of(context)!.hours8);
      _timerValues.add(AppLocalizations.of(context)!.day1);
      _timerValues.add(AppLocalizations.of(context)!.week1);
      _timerValues.add(AppLocalizations.of(context)!.days30);
      _timerValues.add(AppLocalizations.of(context)!.days90);
      _timerValues.add(AppLocalizations.of(context)!.months6);
      _timerValues.add(AppLocalizations.of(context)!.year1);
    }
  }

  bool _screenLoaded = false;

  @override
  void initState() {
    super.initState();

    _disappearingTimer = widget.timerValues[0];

    if (widget.wizardVariables.circle.type == CircleType.TEMPORARY) {
      temporary = true;
      DateTime now = DateTime.now();
      endDate = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour + 1,
        now.minute,
      );
      widget.wizardVariables.circle.expiration = endDate.toString();
      minimumDate = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour + 1,
        now.minute,
      );
    }

    _initUI();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupDisappearingTimer();

      if (widget.wizardVariables.circle.privacyDisappearingTimer != null && _screenLoaded == false) {
        _screenLoaded = true;
        _disappearingTimer = getStringFromTimer(
            widget.wizardVariables.circle.privacyDisappearingTimer!);

        setState(() {

        });
      }

    });

    final end = Padding(
        padding: const EdgeInsets.only(
          left: 14,
          top: 15,
          bottom: 15,
        ), //4
        child: Row(children: [
          Text(
            '${AppLocalizations.of(context)!.circleExpiration}\t\t\t\t',
            textScaler: const TextScaler.linear(1.0),
            style: TextStyle(
              color: globalState.theme.labelText,
            ),
          ),
          InkWell(
              onTap: _getDateTimeEnd,
              child: Row(children: [
                Text(
                  widget.wizardVariables.circle.endDateString,
                  textScaler: const TextScaler.linear(1.0),
                  textAlign: TextAlign.start,
                  style: TextStyle(color: globalState.theme.textField),
                ),
                Text(
                  " @ ",
                  textScaler: const TextScaler.linear(1.0),
                  textAlign: TextAlign.start,
                  style: TextStyle(color: globalState.theme.toggleAlignRight),
                ),
                Text(
                  widget.wizardVariables.circle.endTimeString,
                  textScaler: const TextScaler.linear(1.0),
                  textAlign: TextAlign.start,
                  style: TextStyle(color: globalState.theme.textField),
                )
              ]))
        ]));

    final makeBottom = SizedBox(
        height: 55.0,
        child: Padding(
            padding: const EdgeInsets.only(top: 0, bottom: 2, right: 10),
            child: Row(children: <Widget>[
              const Spacer(),
              GradientButtonDynamic(
                  text: AppLocalizations.of(context)!.next,
                  onPressed: _toInvitations)
            ])));

    final makeBody = Container(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 20),
        child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
                constraints: const BoxConstraints(),
                child: WrapperWidget(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                      widget.wizardVariables.circle.type == CircleType.OWNER
                          ? Container()
                          : _toggleButton(
                              AppLocalizations.of(context)!.privacyVotingModel,
                              AppLocalizations.of(context)!.majority,
                              AppLocalizations.of(context)!.unanimous,
                              privacyVotingModel!,
                              alignLeft: false,
                              callback: null),
                      temporary == true ? end : Container(),
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 11, top: 10, bottom: 0),
                        child: Row(children: <Widget>[
                          Expanded(
                              flex: 1,
                              child: Padding(
                                  padding: const EdgeInsets.only(left: 2),
                                  child: Text(
                                      AppLocalizations.of(context)!
                                          .disappearingMessages, //'Disappearing messages:',
                                      textScaler: const TextScaler.linear(1.0),
                                      style: TextStyle(
                                          color: globalState
                                              .theme.toggleAlignRight)))),
                          Expanded(
                            flex: 1,
                            child: FormField(
                              builder: (FormFieldState<String> state) {
                                return FormattedDropdown(
                                  // hintText: 'off',
                                  expanded: true,
                                  list: widget.timerValues,
                                  dropdownTextColor:
                                      globalState.theme.textFieldText,
                                  selected: _disappearingTimer,
                                  errorText:
                                      state.hasError ? state.errorText : null,
                                  onChanged: (String? value) {
                                    setState(() {
                                      _disappearingTimer = _timerValues[
                                          widget.timerValues.indexOf(value!)];
                                      if (value!.isEmpty) value = null;
                                      state.didChange(value);
                                    });
                                  },
                                );
                              },
                              validator: (dynamic value) {
                                return _disappearingTimer == null
                                    ? 'off'
                                    : null;
                              },
                            ),
                          )
                        ]),
                      ),
                      const Padding(
                          padding: EdgeInsets.only(top: 10, right: 0)),
                      widget.wizardVariables.circle.type == CircleType.OWNER
                          ? Container()
                          : _toggleButton(
                              AppLocalizations.of(context)!
                                  .voteRequiredToAddMembers,
                              AppLocalizations.of(context)!.yesLowercase,
                              AppLocalizations.of(context)!.noLowercase,
                              toggleEntryVote!),
                      _toggleButton(
                          AppLocalizations.of(context)!.shareImagesVideos,
                          AppLocalizations.of(context)!.on,
                          AppLocalizations.of(context)!.off,
                          privacyShareImage!),
                      _toggleButton(
                          AppLocalizations.of(context)!.shareUrls,
                          AppLocalizations.of(context)!.on,
                          AppLocalizations.of(context)!.off,
                          privacyShareURL!),
                      _toggleButton(
                          AppLocalizations.of(context)!.copyMessageText,
                          AppLocalizations.of(context)!.on,
                          AppLocalizations.of(context)!.off,
                          privacyCopyText!),
                      _toggleButton(
                          AppLocalizations.of(context)!.shareGifs,
                          AppLocalizations.of(context)!.on,
                          AppLocalizations.of(context)!.off,
                          privacyShareGif!),
                      widget.wizardVariables.circle.type == CircleType.OWNER ||
                              widget.wizardVariables.circle.type ==
                                  CircleType.WALL
                          ? _toggleButton(
                              AppLocalizations.of(context)!.memberPosting,
                              AppLocalizations.of(context)!.on,
                              AppLocalizations.of(context)!.off,
                              toggleMemberPosting!)
                          : Container(),
                      widget.wizardVariables.circle.type == CircleType.OWNER ||
                              widget.wizardVariables.circle.type ==
                                  CircleType.WALL
                          ? _toggleButton(
                              AppLocalizations.of(context)!.memberReacting,
                              AppLocalizations.of(context)!.on,
                              AppLocalizations.of(context)!.off,
                              toggleMemberReacting!)
                          : Container(),
                      makeBottom,
                    ])))));

    return Form(
        key: _formKey,
        child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: globalState.theme.background,
            appBar: ICAppBar(
              title: AppLocalizations.of(context)!.configurePrivacySettings,
              pop: _backPressed,
            ),
            body: SafeArea(
                left: false,
                top: false,
                right: false,
                bottom: true,
                child: Stack(children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Expanded(
                          child: makeBody,
                        ),
                      ]),
                  _showSpinner ? Center(child: spinkit) : Container(),
                ]))));
  }

  _toggleButton(String label, String a, String b, List<bool> list,
      {bool alignLeft = false, Function? callback}) {
    return Row(children: <Widget>[
      Expanded(
          child: Padding(
              padding: const EdgeInsets.only(left: 15, right: 5),
              child: Text(
                label,
                textScaler: const TextScaler.linear(1.0),
                textAlign: alignLeft ? TextAlign.end : TextAlign.start,
                style: TextStyle(
                    color: alignLeft
                        ? globalState.theme.toggleAlignLeft
                        : globalState.theme.toggleAlignRight),
              ))),
      ToggleButtons(
        selectedBorderColor: globalState.theme.dialogTransparentBackground,
        borderColor: globalState.theme.dialogTransparentBackground,
        fillColor: Colors.lightBlueAccent.withOpacity(.1),
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
        //highlightColor: Colors.yellow,
        children: <Widget>[
          SizedBox(
              width: 80,
              child: Center(
                  child: Text(
                a,
                textScaler: const TextScaler.linear(1.0),
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
                textScaler: const TextScaler.linear(1.0),
                style: TextStyle(
                    color: list[1]
                        ? globalState.theme.buttonIcon
                        : globalState.theme.labelTextSubtle),
              ))),
        ],
      )
    ]);
  }

  _backPressed() {
    widget.wizardVariables.circle.privacyVotingModel =
        getVoteModelString(privacyVotingModel!);
    widget.wizardVariables.circle.privacyDisappearingTimer = getTimerInHours();
    widget.wizardVariables.circle.privacyShareImage =
        getSettingBool(privacyShareImage!);
    widget.wizardVariables.circle.privacyShareURL =
        getSettingBool(privacyShareURL!);
    widget.wizardVariables.circle.privacyCopyText =
        getSettingBool(privacyCopyText!);
    widget.wizardVariables.circle.privacyShareGif =
        getSettingBool(privacyShareGif!);
    widget.wizardVariables.circle.toggleEntryVote =
        getSettingBool(toggleEntryVote!);
    widget.wizardVariables.circle.toggleMemberPosting =
        getSettingBool(toggleMemberPosting!);
    widget.wizardVariables.circle.toggleMemberReacting =
        getSettingBool(toggleMemberReacting!);

    Navigator.pop(context, widget.wizardVariables);
  }

  _toInvitations() async {
    try {
      if (_formKey.currentState!.validate()) {
        widget.wizardVariables.circle.privacyVotingModel =
            getVoteModelString(privacyVotingModel!);
        widget.wizardVariables.circle.privacyDisappearingTimer =
            getTimerInHours();
        widget.wizardVariables.circle.privacyShareImage =
            getSettingBool(privacyShareImage!);
        widget.wizardVariables.circle.privacyShareURL =
            getSettingBool(privacyShareURL!);
        widget.wizardVariables.circle.privacyCopyText =
            getSettingBool(privacyCopyText!);
        widget.wizardVariables.circle.privacyShareGif =
            getSettingBool(privacyShareGif!);
        widget.wizardVariables.circle.toggleEntryVote =
            getSettingBool(toggleEntryVote!);
        widget.wizardVariables.circle.toggleMemberPosting =
            getSettingBool(toggleMemberPosting!);
        widget.wizardVariables.circle.toggleMemberReacting =
            getSettingBool(toggleMemberReacting!);

        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CircleNewWizardInvitations(
                      userFurnace: widget.userFurnace,
                      wizardVariables: widget.wizardVariables,
                    )));
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('NewCircleSettings._createCircle: $err');
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
    }
  }

  String getVoteModelString(List<bool> setting) {
    if (setting[0])
      return CircleVoteModel.MAJORITY;
    else
      return CircleVoteModel.UNANIMOUS;
  }

  bool getSettingBool(List<bool> setting) {
    if (setting[0])
      return true;
    else
      return false;
  }

  int getTimerInHours() {
    int retValue = 0;

    if (_disappearingTimer == AppLocalizations.of(context)!.off)
      retValue = CircleDisappearingTimer.OFF;
    else if (_disappearingTimer == AppLocalizations.of(context)!.hours4)
      retValue = CircleDisappearingTimer.FOUR_HOURS;
    else if (_disappearingTimer == AppLocalizations.of(context)!.hours8)
      retValue = CircleDisappearingTimer.EIGHT_HOURS;
    else if (_disappearingTimer == AppLocalizations.of(context)!.day1)
      retValue = CircleDisappearingTimer.ONE_DAY;
    else if (_disappearingTimer == AppLocalizations.of(context)!.week1)
      retValue = CircleDisappearingTimer.ONE_WEEK;
    else if (_disappearingTimer == AppLocalizations.of(context)!.days30)
      retValue = CircleDisappearingTimer.THIRTY_DAYS;
    else if (_disappearingTimer == AppLocalizations.of(context)!.days90)
      retValue = CircleDisappearingTimer.NINETY_DAYS;
    else if (_disappearingTimer == AppLocalizations.of(context)!.months6)
      retValue = CircleDisappearingTimer.SIX_MONTHS;
    else if (_disappearingTimer == AppLocalizations.of(context)!.year1)
      retValue = CircleDisappearingTimer.ONE_YEAR;

    return retValue;
  }

  String getStringFromTimer(int timer) {
    String retValue = AppLocalizations.of(context)!.off;

    if (timer == CircleDisappearingTimer.OFF)
      retValue = AppLocalizations.of(context)!.off;
    else if (timer == CircleDisappearingTimer.FOUR_HOURS)
      retValue = AppLocalizations.of(context)!.hours4;
    else if (timer == CircleDisappearingTimer.EIGHT_HOURS)
      retValue = AppLocalizations.of(context)!.hours8;
    else if (timer == CircleDisappearingTimer.ONE_DAY)
      retValue = AppLocalizations.of(context)!.day1;
    else if (timer == CircleDisappearingTimer.ONE_WEEK)
      retValue = AppLocalizations.of(context)!.week1;
    else if (timer == CircleDisappearingTimer.THIRTY_DAYS)
      retValue = AppLocalizations.of(context)!.days30;
    else if (timer == CircleDisappearingTimer.NINETY_DAYS)
      retValue = AppLocalizations.of(context)!.days90;
    else if (timer == CircleDisappearingTimer.SIX_MONTHS)
      retValue = AppLocalizations.of(context)!.months6;
    else if (timer == CircleDisappearingTimer.ONE_YEAR)
      retValue = AppLocalizations.of(context)!.year1;

    return retValue;
  }

  void _initUI() {
    // if (widget.wizardVariables.circle.privacyDisappearingTimer != null)
    //   _disappearingTimer = getStringFromTimer(
    //       widget.wizardVariables.circle.privacyDisappearingTimer!);

    widget.wizardVariables.circle.privacyVotingModel == CircleVoteModel.MAJORITY
        ? privacyVotingModel = [true, false]
        : privacyVotingModel = [false, true];

    widget.wizardVariables.circle.securityVotingModel ==
            CircleVoteModel.MAJORITY
        ? securityVotingModel = [true, false]
        : securityVotingModel = [false, true];

    widget.wizardVariables.circle.privacyShareImage == true
        ? privacyShareImage = [true, false]
        : privacyShareImage = [false, true];

    widget.wizardVariables.circle.privacyShareGif == true
        ? privacyShareGif = [true, false]
        : privacyShareGif = [false, true];

    widget.wizardVariables.circle.privacyShareURL == true
        ? privacyShareURL = [true, false]
        : privacyShareURL = [false, true];

    widget.wizardVariables.circle.privacyCopyText == true
        ? privacyCopyText = [true, false]
        : privacyCopyText = [false, true];

    widget.wizardVariables.circle.toggleEntryVote == true
        ? toggleEntryVote = [true, false]
        : toggleEntryVote = [false, true];

    widget.wizardVariables.circle.toggleMemberPosting == true
        ? toggleMemberPosting = [true, false]
        : toggleMemberPosting = [false, true];

    widget.wizardVariables.circle.toggleMemberReacting == true
        ? toggleMemberReacting = [true, false]
        : toggleMemberPosting = [false, true];

    securityTokenExpirationDays.text =
        widget.wizardVariables.circle.securityTokenExpirationDays.toString();

    securityMinPassword.text =
        widget.wizardVariables.circle.securityMinPassword.toString();

    securityLoginAttempts.text =
        widget.wizardVariables.circle.securityLoginAttempts.toString();

    securityDaysPasswordValid.text =
        widget.wizardVariables.circle.securityDaysPasswordValid.toString();
  }

  _getDateTimeEnd() async {
    DateTime now = DateTime.now();
    DateTime last = DateTime(now.year + 1, now.month, now.day);

    DateTime? date = await showDatePicker(
      context: context,
      firstDate: minimumDate!,
      lastDate: last,
      initialDate: DateTime.parse(widget.wizardVariables.circle.expiration!),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1),
            ),
            child: globalState.theme.themeMode == ICThemeMode.dark
                ? Theme(
                    data: ThemeData.dark().copyWith(
                      primaryColor: globalState.theme.button,
                      colorScheme:
                          ColorScheme.dark(primary: globalState.theme.button),
                      buttonTheme: const ButtonThemeData(
                          textTheme: ButtonTextTheme.primary),
                    ),
                    child: child!,
                  )
                : Theme(
                    data: ThemeData.light().copyWith(
                      primaryColor: globalState.theme.button,
                      colorScheme:
                          ColorScheme.light(primary: globalState.theme.button),
                      buttonTheme: const ButtonThemeData(
                          textTheme: ButtonTextTheme.primary),
                    ),
                    child: child!,
                  ));
      },
    );

    if (date != null) {
      TimeOfDay? time = await showTimePicker(
          initialTime: TimeOfDay.fromDateTime(DateTime.parse(
              widget.wizardVariables.circle.expiration!)), //TimeOfDay.now(),
          context: context,
          builder: (BuildContext context, Widget? child) {
            return MediaQuery(
                data: const MediaQueryData(
                  textScaler: TextScaler.linear(1),
                ),
                child: globalState.theme.themeMode == ICThemeMode.dark
                    ? Theme(
                        data: ThemeData.dark().copyWith(
                          primaryColor: globalState.theme.button,
                          colorScheme: ColorScheme.dark(
                              primary: globalState.theme.button),
                          buttonTheme: const ButtonThemeData(
                              textTheme: ButtonTextTheme.primary),
                        ),
                        child: child!,
                      )
                    : Theme(
                        data: ThemeData.light().copyWith(
                          primaryColor: globalState.theme.button,
                          colorScheme: ColorScheme.light(
                              primary: globalState.theme.button),
                          buttonTheme: const ButtonThemeData(
                              textTheme: ButtonTextTheme.primary),
                        ),
                        child: child!,
                      ));
          });

      if (time != null) {
        setState(() {
          DateTime temp =
              DateTime(date.year, date.month, date.day, time.hour, time.minute);
          DateTime now = DateTime.now();
          DateTime minimum =
              DateTime(now.year, now.month, now.day, now.hour + 1, now.minute);
          if (temp.isBefore(minimum)) {
            DialogNotice.showNotice(
                context,
                AppLocalizations.of(context)!.invalidTime,
                AppLocalizations.of(context)!
                    .circleMustExpireAtLeastAnHourFromNow,
                "",
                "",
                "",
                false);
          } else {
            widget.wizardVariables.circle.expiration = temp.toString();
          }
        });
      }
    }
  }
}
