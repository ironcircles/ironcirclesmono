import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/circle_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/themes/mastertheme.dart';
import 'package:ironcirclesapp/screens/widgets/dialogcirclesettings.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:provider/provider.dart';

class CircleWideSettings extends StatefulWidget {
  final UserCircleCache userCircleCache;
  final UserFurnace userFurnace;
  final Circle circle;
  final CircleBloc circleBloc;

  const CircleWideSettings(
      {Key? key,
      required this.userCircleCache,
      required this.userFurnace,
      required this.circle,
      required this.circleBloc})
      : super(key: key);

  @override
  CircleWideSettingsState createState() => CircleWideSettingsState();
}

class CircleWideSettingsState extends State<CircleWideSettings> {
  late GlobalEventBloc _globalEventBloc;
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
  List<bool>? toggleEntryVote;
  List<bool>? toggleMemberPosting;
  List<bool>? toggleMemberReacting;
  DateTime? minimumDate;

  //List<bool> votingModelSharePhotos;
  //List<bool> settingSharePhotos;

  String? _disappearingTimer; // = "off";
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

    circle.toggleEntryVote == true
        ? toggleEntryVote = [true, false]
        : toggleEntryVote = [false, true];

    circle.toggleMemberPosting == true
        ? toggleMemberPosting = [true, false]
        : toggleMemberPosting = [false, true];

    circle.toggleMemberReacting == true
        ? toggleMemberReacting = [true, false]
        : toggleMemberReacting = [false, true];
  }

  @override
  void initState() {
    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);

    //circleBloc
    widget.circleBloc.settingsUpdatedMessage.listen((msg) {
      if (mounted) {
        FormattedSnackBar.showSnackbarWithContext(context, msg, "", 1, false);
      }
    }, onError: (err) {
      //Navigator.pushReplacementNamed(context, '/login');

      debugPrint("error $err");
    }, cancelOnError: false);

    //circleBloc
    widget.circleBloc.settingsUpdated.listen((circle) {
      if (mounted) {
        setState(() {
          if (_circle != null) _initUI(circle);

          widget.userCircleCache.cachedCircle = circle;

          setState(() {
            _circle = circle;
          });
        });
      }
    }, onError: (err) {
      //Navigator.pushReplacementNamed(context, '/login');
      if (mounted)
        FormattedSnackBar.showSnackbarWithContext(
            context, err.toString(), "", 2, true);
      debugPrint("error $err");
    }, cancelOnError: false);

    //Listen circle activity
    widget.circleBloc.fetchedResponse.listen((circle) {
      if (mounted) {
        changed = true;

        _initUI(circle);

        setState(() {
          _circle = circle;
        });
      }
    }, onError: (err) {
      debugPrint("CircleSettingsWide.initState.fetchedResponse: $err");
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
    }, cancelOnError: false);

    //Listen deleted response
    widget.circleBloc.deleteResponse.listen((response) {
      if (mounted) {
        if (response!.toLowerCase() == CircleBloc.CIRCLE_DELETED ||
            response.toLowerCase() == CircleBloc.DM_DELETED) {
          if (mounted)
            FormattedSnackBar.showSnackbarWithContext(
                context,
                "${widget.circle.getChatTypeLocalizedString(context)} ${AppLocalizations.of(context)!.deleted.toLowerCase()}",
                "",
                1,
                false);

          _goHome();
        } else if (response.contains(CircleBloc.CIRCLE_DELETE_VOTE_CREATED)) {
          FormattedSnackBar.showSnackbarWithContext(
              context,
              "${AppLocalizations.of(context)!.voteToDelete} ${widget.circle.getChatTypeLocalizedString(context)} ${AppLocalizations.of(context)!.wasCreated}",
              "",
              1,
              false);
        } else {
          if (mounted)
            FormattedSnackBar.showSnackbarWithContext(
                context, response, "", 1, true);
        }
      }
    }, onError: (err) {
      debugPrint("error $err");
      if (mounted)
        FormattedSnackBar.showSnackbarWithContext(
            context, err.toString(), "", 2, true);
    }, cancelOnError: false);

    widget.circleBloc
        .fetchCircle(widget.userFurnace, widget.userCircleCache.circle!, null);

    super.initState();
  }

  _goHome() async {
    _globalEventBloc.broadcastPopToHomeOpenTab(0);
    // await Navigator.pushAndRemoveUntil(
    //     context,
    //     MaterialPageRoute(builder: (context) => Home()),
    //     (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    _setupDisappearingTimer();

    final end = Padding(
        padding: const EdgeInsets.only(
          left: 14,
          top: 10,
          bottom: 15,
        ),
        child: Row(children: [
          Text(
            '${AppLocalizations.of(context)!.circleExpiration}\t\t\t\t',
            textScaler: const TextScaler.linear(1.0),
            style: TextStyle(
              color: globalState.theme.labelText,
            ),
          ),
          InkWell(
              onTap: widget.userFurnace.userid == widget.circle.owner
                  ? _getDateTimeEnd
                  : null,
              child: Row(children: [
                Text(
                  _circle != null ? _circle!.endDateString : "",
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
                  _circle != null ? _circle!.endTimeString : "",
                  textScaler: const TextScaler.linear(1.0),
                  textAlign: TextAlign.start,
                  style: TextStyle(color: globalState.theme.textField),
                )
              ]))
        ]));

    final deleteButton = Container(
        margin: EdgeInsets.symmetric(
            horizontal: ButtonType.getWidth(MediaQuery.of(context).size.width)),
        child: GradientButton(
          text:
              '${AppLocalizations.of(context)!.dELETE} ${widget.circle.getChatTypeLocalizedString(context).toUpperCase()}',
          onPressed: () => _delete(context),
        ));

    final divider = Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: Divider(
          color: globalState.theme.divider,
          height: 20,
          thickness: 5,
          indent: 0,
          endIndent: 0,
        ));

    final makeBody = _circle == null
        ? Container()
        : Container(
            padding:
                const EdgeInsets.only(left: 10, right: 10, top: 20, bottom: 20),
            child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: WrapperWidget(child:Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    widget.circle.type == CircleType.OWNER &&
                            widget.circle.owner != widget.userFurnace.userid
                        ? Padding(
                            padding: const EdgeInsets.only(
                                top: 0, bottom: 10, right: 10, left: 10),
                            child: Row(
                              children: [
                                Icon(Icons.priority_high,
                                    color: globalState.theme.labelTextSubtle),
                                Expanded(
                                    child: Text(
                                  AppLocalizations.of(context)!
                                      .onlyOwnerCanChangeSettings,
                                  textScaler: TextScaler.linear(
                                      globalState.labelScaleFactor),
                                  overflow: TextOverflow.visible,
                                  style: TextStyle(
                                      color: globalState.theme.labelTextSubtle,
                                      fontSize: 16),
                                ))
                              ],
                            ))
                        : Container(),
                    Text(
                      AppLocalizations.of(context)!.privacysettings,
                      textScaler:
                          TextScaler.linear(globalState.labelScaleFactor),
                      style: TextStyle(
                          fontSize: 18, color: globalState.theme.buttonIcon),
                    ),
                    widget.circle.type == CircleType.OWNER
                        ? Container()
                        : _toggleButton(
                            AppLocalizations.of(context)!.privacyVotingModel,
                            AppLocalizations.of(context)!.majority,
                            AppLocalizations.of(context)!.unanimous,
                            privacyVotingModel!,
                            alignLeft: true,
                            callback: showPrivacyModelChangeDialog),
                    widget.circle.type == CircleType.OWNER
                        ? Container()
                        : Padding(
                            padding: const EdgeInsets.only(
                                left: 55, top: 0, bottom: 0),
                            child: divider,
                          ),
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
                    widget.circle.type == CircleType.TEMPORARY
                        ? end
                        : Container(),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 11, top: 0, bottom: 0),
                      child: Row(children: <Widget>[
                        Expanded(
                            flex: 1,
                            child: Padding(
                                padding: const EdgeInsets.only(left: 2),
                                child: Text(
                                    AppLocalizations.of(context)!
                                        .disappearingMessages,
                                    textScaler: TextScaler.linear(
                                        globalState.labelScaleFactor),
                                    style: TextStyle(
                                        color: globalState
                                            .theme.toggleAlignRight)))),
                        Expanded(
                          flex: 1,
                          child: Padding(
                              padding: const EdgeInsets.only(left: 0),
                              child: FormField(
                                builder: (FormFieldState<String> state) {
                                  return FormattedDropdown(
                                    list: _timerValues,
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
                                  return _disappearingTimer == null
                                      ? AppLocalizations.of(context)!.off
                                      : null;
                                },
                              )),
                        )
                      ]),
                    ),
                    const Padding(padding: EdgeInsets.only(top: 10, right: 0)),
                    widget.circle.dm || widget.circle.type == CircleType.OWNER
                        ? Container()
                        : _toggleButton(
                            AppLocalizations.of(context)!
                                .voteRequiredToAddMembers,
                            AppLocalizations.of(context)!.on.toLowerCase(),
                            AppLocalizations.of(context)!.off.toLowerCase(),
                            toggleEntryVote!),
                    _toggleButton(
                        AppLocalizations.of(context)!.shareImagesVideos,
                        AppLocalizations.of(context)!.on.toLowerCase(),
                        AppLocalizations.of(context)!.off.toLowerCase(),
                        privacyShareImage!),
                    /*_toggleButton("Voting Model:", "majority", "unanimous",
                    settingShareImageModel,
                    alignLeft: true),*/

                    //thinDivider,
                    //Padding(padding: EdgeInsets.only(top: 10, right: 0)),
                    _toggleButton(
                        AppLocalizations.of(context)!.shareUrls,
                        AppLocalizations.of(context)!.on.toLowerCase(),
                        AppLocalizations.of(context)!.off.toLowerCase(),
                        privacyShareURL!),
                    /* _toggleButton("Voting Model:", "majority", "unanimous",
                    settingShareURLModel,
                    alignLeft: true),*/
                    //thinDivider,
                    _toggleButton(
                        AppLocalizations.of(context)!.copyMessageText,
                        AppLocalizations.of(context)!.on.toLowerCase(),
                        AppLocalizations.of(context)!.off.toLowerCase(),
                        privacyCopyText!),
                    /*_toggleButton("Voting Model:", "majority", "unanimous",
                    settingCopyTextModel,
                    alignLeft: true),*/
                    //thinDivider,
                    _toggleButton(
                        AppLocalizations.of(context)!.shareGifs,
                        AppLocalizations.of(context)!.on.toLowerCase(),
                        AppLocalizations.of(context)!.off.toLowerCase(),
                        privacyShareGif!),
                    widget.circle.type == CircleType.OWNER ||
                            widget.circle.type == CircleType.WALL
                        ? _toggleButton(
                            AppLocalizations.of(context)!.memberPosting,
                            AppLocalizations.of(context)!.on.toLowerCase(),
                            AppLocalizations.of(context)!.off.toLowerCase(),
                            toggleMemberPosting!)
                        : Container(),
                    widget.circle.type == CircleType.OWNER ||
                            widget.circle.type == CircleType.WALL
                        ? _toggleButton(
                            AppLocalizations.of(context)!.memberReacting,
                            AppLocalizations.of(context)!.on.toLowerCase(),
                            AppLocalizations.of(context)!.off.toLowerCase(),
                            toggleMemberReacting!)
                        : Container(),
                    /* _toggleButton("Voting Model:", "majority", "unanimous",
                    settingShareGifModel,
                    alignLeft: true),*/
                    widget.circle.type == CircleType.OWNER &&
                            widget.circle.owner != widget.userFurnace.userid
                        ? Container()
                        : Row(children: [
                            const Spacer(),
                            Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                    padding: const EdgeInsets.only(
                                        top: 7, bottom: 0),
                                    child: GradientButtonDynamic(
                                        //width: 250,
                                        //height: 45,
                                        text:
                                            AppLocalizations.of(context)!.aPPLY,
                                        onPressed: () {
                                          SettingsChanges messages =
                                              _getPrivacyChangesDisplayValue();

                                          if (messages.localizedMessage.isEmpty)
                                            FormattedSnackBar
                                                .showSnackbarWithContext(
                                                    context,
                                                    AppLocalizations.of(
                                                            context)!
                                                        .nothingChanged,
                                                    "",
                                                    1,
                                                    false);
                                          else
                                            DialogCircleSettings.confirmChange(
                                              context,
                                              CircleSettingChangeType.PRIVACY,
                                              _circle,
                                              messages.localizedMessage, messages.apiMessage,
                                              _setPrivacy,
                                            );
                                        } //_setImage(),
                                        )))
                          ]),
                    divider,
                    /*Text(
                  "Security settings:",
                  style: TextStyle(
                      fontSize: 18, color: globalState.theme.buttonIcon),
                ),

                _toggleButton("Security Voting Model:", "majority", "unanimous",
                    securityVotingModel!,
                    alignLeft: true, callback: showSecurityModelChangeDialog),
                Padding(
                  padding: const EdgeInsets.only(left: 55, top: 0, bottom: 0),
                  child: divider,
                ),

                Padding(padding: EdgeInsets.only(top: 0, right: 0)),
                _textField('Password attempts before lock:',
                    securityLoginAttempts, null,
                    numbersOnly: true, maxLength: 2),
                Padding(padding: EdgeInsets.only(top: 0, right: 0)),
                _textField(
                    'Minimum password length:', securityMinPassword, null,
                    numbersOnly: true, maxLength: 2),
                /*_toggleButton(
                  "Voting Model:",
                  "majority",
                  "unanimous",
                  securityMinPasswordModel,
                  alignLeft: true,
                ),*/
                _textField(
                    "Password change (days):", securityDaysPasswordValid, null,
                    numbersOnly: true, maxLength: 4),
                /* _toggleButton("Voting Model:", "majority", "unanimous",
                    securityDaysPasswordValidModel,
                    alignLeft: true),*/
                _textField(
                    "Stay logged in (days):", securityTokenExpirationDays, null,
                    numbersOnly: true, maxLength: 4),
                /* _toggleButton("Voting Model:", "majority", "unanimous",
                    securityTokenExpirationDaysModel,
                    alignLeft: true),*/

                Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                        padding: const EdgeInsets.only(top: 7, bottom: 0),
                        child: GradientButton(
                          width: 250,
                          height: 45,
                          text: 'APPLY SECURITY SETTING',
                          onPressed: () {
                            String message = _getSecurityChangesDisplayValue();

                            if (message.isEmpty)
                              FormattedSnackBar.showSnackbar(
                                  _scaffoldKey, 'nothing changed', "", 1);
                            else
                              DialogCircleSettings.confirmChange(
                                context,
                                CircleSettingChangeType.SECURITY,
                                _circle,
                                message,
                                _setSecurity,
                              );
                          }, //_setImage(),
                        ))),
                divider,

                 */
                    _circle!.ownershipModel != CircleOwnership.OWNER
                        ? deleteButton
                        : _circle!.owner != widget.userFurnace.userid
                            ? Container()
                            : deleteButton,
                  ],
                )),
          ));

    final getForm = Form(
        key: _formKey,
        child: Scaffold(
          backgroundColor: globalState.theme.background,
          key: _scaffoldKey,
          //backgroundColor: globalState.theme.scaffoldBackgroundColor,
          //appBar: topAppBar,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: makeBody,
              ),
            ],
          ),
        ));

    return PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) {
          if (didPop) {
            return;
          }
          FocusScope.of(context).requestFocus(FocusNode());

          if (changed)
            Navigator.pop(context, widget.userCircleCache);
          else
            Navigator.pop(
              context,
            );
        },
        child: Platform.isIOS
            ? GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.velocity.pixelsPerSecond.dx > 2000) {
                    FocusScope.of(context).requestFocus(FocusNode());

                    if (changed) {
                      Navigator.pop(context, widget.userCircleCache);
                    } else {
                      Navigator.pop(
                        context,
                      );
                    }
                  } else if (details.velocity.pixelsPerSecond.dx > 200) {
                    DefaultTabController.of(context).animateTo(0);
                  }
                },
                child: getForm)
            : getForm);
  }

  /*
  _textField(
      String label, TextEditingController controller, Function? validator,
      {bool alignLeft = false, bool numbersOnly = false, int? maxLength}) {
    return Row(children: <Widget>[
      Expanded(
          flex: 2,
          child: Padding(
              padding: EdgeInsets.only(left: 15, right: 5, top: 10),
              child: Text(
                label,
                textAlign: alignLeft ? TextAlign.end : TextAlign.start,
                style: TextStyle(color: globalState.theme.labelText),
              ))),
      Expanded(
          child: Padding(
              padding: EdgeInsets.only(bottom: 7),
              child: ExpandingLineText(
                numbersOnly: numbersOnly,
                labelText: '',
                maxLength: maxLength,
                maxLines: 1,
                controller: controller,
              )))
    ]);
  }

   */

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
            if (_circle!.ownershipModel == CircleOwnership.OWNER) if (_circle!
                    .owner !=
                widget.userFurnace.userid) return;

            //return;
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

  // showSecurityModelChangeDialog(String a, String b) {
  //   DialogCircleSettings.confirmChange(
  //       context,
  //       CircleSettingChangeType.SECURITY,
  //       _circle,
  //       '${AppLocalizations.of(context)!.changeVotingModelFrom} $a ${AppLocalizations.of(context)!.to.toLowerCase()} $b?',
  //       _setSecurityVotingModel,
  //       fail: _unsetSecurityVotingModel);
  // }

  showPrivacyModelChangeDialog(String a, String b) {
    DialogCircleSettings.confirmChange(
        context,
        CircleSettingChangeType.PRIVACY,
        _circle,
        '${AppLocalizations.of(context)!.changeVotingModelFrom} $a ${AppLocalizations.of(context)!.to.toLowerCase()} $b?',
        'Change voting model from $a to $b?',
        _setPrivacyVotingModel,
        fail: _unsetPrivacyVotingModel);
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

  SettingsChanges _getPrivacyChangesDisplayValue() {
    List<CircleSettingValue> list = _privacyValuesThatChanged();

    String localizedMessage = "";
    String apiMessage = "";

    ///not localized

    for (CircleSettingValue circleSettingValue in list) {
      if (localizedMessage.isNotEmpty) {
        localizedMessage = '$localizedMessage\n\n';
        apiMessage = '$apiMessage\n\n';
      }

      if (circleSettingValue.setting ==
          CircleSetting.privacyDisappearingTimer) {
        String originalTimer =
            getStringFromTimer(circleSettingValue.priorNumberSetting);
        String newTimer = getStringFromTimer(circleSettingValue.numericSetting);
        localizedMessage =
            '$localizedMessage${AppLocalizations.of(context)!.privacyDisappearingTimer} - $originalTimer ${AppLocalizations.of(context)!.to.toLowerCase()} $newTimer';

        apiMessage =
            '$apiMessage${circleSettingValue.setting} - ${circleSettingValue.priorNumberSetting} to ${circleSettingValue.numericSetting}';
      } else {

        apiMessage =
        '$apiMessage${circleSettingValue.setting} - ${circleSettingValue.priorBoolSetting} to ${circleSettingValue.boolSetting}';
        
        if (circleSettingValue.setting == CircleSetting.toggleEntryVote) {
          localizedMessage =
              '$localizedMessage${AppLocalizations.of(context)!.toggleEntryVote} - ${circleSettingValue.priorBoolSetting ? AppLocalizations.of(context)!.on : AppLocalizations.of(context)!.off} ${AppLocalizations.of(context)!.to.toLowerCase()} ${circleSettingValue.boolSetting ? AppLocalizations.of(context)!.on : AppLocalizations.of(context)!.off}';
        } else if (circleSettingValue.setting ==
            CircleSetting.toggleMemberPosting) {
          localizedMessage =
              '$localizedMessage${AppLocalizations.of(context)!.toggleMemberPosting} - ${circleSettingValue.priorBoolSetting ? AppLocalizations.of(context)!.on : AppLocalizations.of(context)!.off} ${AppLocalizations.of(context)!.to.toLowerCase()} ${circleSettingValue.boolSetting ? AppLocalizations.of(context)!.on : AppLocalizations.of(context)!.off}';
        } else if (circleSettingValue.setting ==
            CircleSetting.toggleMemberReacting) {
          localizedMessage =
              '$localizedMessage${AppLocalizations.of(context)!.toggleMemberReacting} - ${circleSettingValue.priorBoolSetting ? AppLocalizations.of(context)!.on : AppLocalizations.of(context)!.off} ${AppLocalizations.of(context)!.to.toLowerCase()} ${circleSettingValue.boolSetting ? AppLocalizations.of(context)!.on : AppLocalizations.of(context)!.off}';
        } else if (circleSettingValue.setting ==
            CircleSetting.privacyShareImage) {
          localizedMessage =
              '$localizedMessage${AppLocalizations.of(context)!.privacyShareImage} - ${circleSettingValue.priorBoolSetting ? AppLocalizations.of(context)!.on : AppLocalizations.of(context)!.off} ${AppLocalizations.of(context)!.to.toLowerCase()} ${circleSettingValue.boolSetting ? AppLocalizations.of(context)!.on : AppLocalizations.of(context)!.off}';
        } else if (circleSettingValue.setting ==
            CircleSetting.privacyVotingModel) {
          localizedMessage =
              '$localizedMessage${AppLocalizations.of(context)!.privacyVotingModel} - ${circleSettingValue.priorBoolSetting ? AppLocalizations.of(context)!.on : AppLocalizations.of(context)!.off} ${AppLocalizations.of(context)!.to.toLowerCase()} ${circleSettingValue.boolSetting ? AppLocalizations.of(context)!.on : AppLocalizations.of(context)!.off}';
        } else if (circleSettingValue.setting ==
            CircleSetting.privacyShareURL) {
          localizedMessage =
              '$localizedMessage${AppLocalizations.of(context)!.privacyShareURL} - ${circleSettingValue.priorBoolSetting ? AppLocalizations.of(context)!.on : AppLocalizations.of(context)!.off} ${AppLocalizations.of(context)!.to.toLowerCase()} ${circleSettingValue.boolSetting ? AppLocalizations.of(context)!.on : AppLocalizations.of(context)!.off}';
        } else if (circleSettingValue.setting ==
            CircleSetting.privacyShareGif) {
          localizedMessage =
              '$localizedMessage${AppLocalizations.of(context)!.privacyShareGif} - ${circleSettingValue.priorBoolSetting ? AppLocalizations.of(context)!.on : AppLocalizations.of(context)!.off} ${AppLocalizations.of(context)!.to.toLowerCase()} ${circleSettingValue.boolSetting ? AppLocalizations.of(context)!.on : AppLocalizations.of(context)!.off}';
        } else if (circleSettingValue.setting ==
            CircleSetting.privacyCopyText) {
          localizedMessage =
              '$localizedMessage${AppLocalizations.of(context)!.privacyCopyText} - ${circleSettingValue.priorBoolSetting ? AppLocalizations.of(context)!.on : AppLocalizations.of(context)!.off} ${AppLocalizations.of(context)!.to.toLowerCase()} ${circleSettingValue.boolSetting ? AppLocalizations.of(context)!.on : AppLocalizations.of(context)!.off}';
        }
      }

      // if (retValue.isEmpty) {
      //   retValue =
      //   '${circleSettingValue.displayValue} - ${circleSettingValue
      //       .originalValue} to ${circleSettingValue.settingValue}';
      // } else {
      //   retValue =
      //   '$retValue\n\n${circleSettingValue.displayValue} - ${circleSettingValue
      //       .originalValue} to ${circleSettingValue.settingValue}';
      // }
    }

    return SettingsChanges(localizedMessage: localizedMessage, apiMessage: apiMessage);
  }

  _setPrivacy(String message) {
    List<CircleSettingValue> list = _privacyValuesThatChanged(boolString: true);

    if (list.isNotEmpty) {
      widget.circleBloc.updateSetting(widget.userFurnace, _circle!.id!, list,
          message, CircleSettingChangeType.PRIVACY);

      FormattedSnackBar.showSnackbarWithContext(context,
          AppLocalizations.of(context)!.requestingPrivacyChanges, "", 1, false);
    } else {
      FormattedSnackBar.showSnackbarWithContext(
          context, AppLocalizations.of(context)!.nothingChanged, "", 1, false);
    }
  }

  _setSecurityVotingModel(String message) {
    String requestedChange = getVoteModelString(securityVotingModel!);

    widget.circleBloc.updateVotingModel(widget.userFurnace, _circle!.id!,
        requestedChange, message, CircleSettingChangeType.SECURITY);

    FormattedSnackBar.showSnackbarWithContext(context,
        AppLocalizations.of(context)!.requestingSecurityChanges, "", 1, false);
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

  _setPrivacyVotingModel(String message) {
    String requestedChange = getVoteModelString(privacyVotingModel!);

    widget.circleBloc.updateVotingModel(widget.userFurnace, _circle!.id!,
        requestedChange, message, CircleSettingChangeType.PRIVACY);

    FormattedSnackBar.showSnackbarWithContext(context,
        AppLocalizations.of(context)!.requestingPrivacyChanges, "", 1, false);
  }

  Future<void> _delete(BuildContext context) async {
    DialogYesNo.askYesNo(
        context,
        widget.circle.dm
            ? AppLocalizations.of(context)!.confirmDeleteDMTitle
            : AppLocalizations.of(context)!.confirmDeleteCircleTitle,
        widget.circle.dm
            ? AppLocalizations.of(context)!.confirmDeleteDMMessage
            : AppLocalizations.of(context)!.confirmDeleteCircleMessage,

        /// TODO add this back when owner circles are restored ->  \n\nIf you are the owner or only member of this circle, this will happen immediately. Otherwise a vote will be kicked off.',
        _deleteResult,
        null,
        false);
  }

  _deleteResult() {
    widget.circleBloc
        .delete(_globalEventBloc, widget.userFurnace, widget.userCircleCache);
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

  // String getSettingString(List<bool> setting) {
  //   if (setting[0] == true)
  //     return 'yes';
  //   else
  //     return 'no';
  // }

  // String getBoolSettingString(bool? setting) {
  //   if (setting == true)
  //     return 'yes';
  //   else
  //     return 'no';
  // }

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

  // String getAPIStringFromTimer(int timer) {
  //   String retValue = AppLocalizations.of(context)!.off;
  //
  //   if (timer == CircleDisappearingTimer.OFF)
  //     retValue = CircleDisappearingTimerAPIStrings.OFF;
  //   else if (timer == CircleDisappearingTimer.FOUR_HOURS)
  //     retValue = CircleDisappearingTimerAPIStrings.FOUR_HOURS;
  //   else if (timer == CircleDisappearingTimer.EIGHT_HOURS)
  //     retValue = CircleDisappearingTimerAPIStrings.EIGHT_HOURS;
  //   else if (timer == CircleDisappearingTimer.ONE_DAY)
  //     retValue = CircleDisappearingTimerAPIStrings.ONE_DAY;
  //   else if (timer == CircleDisappearingTimer.ONE_WEEK)
  //     retValue = CircleDisappearingTimerAPIStrings.ONE_WEEK;
  //   else if (timer == CircleDisappearingTimer.THIRTY_DAYS)
  //     retValue = CircleDisappearingTimerAPIStrings.THIRTY_DAYS;
  //   else if (timer == CircleDisappearingTimer.NINETY_DAYS)
  //     retValue = CircleDisappearingTimerAPIStrings.NINETY_DAYS;
  //   else if (timer == CircleDisappearingTimer.SIX_MONTHS)
  //     retValue = CircleDisappearingTimerAPIStrings.SIX_MONTHS;
  //   else if (timer == CircleDisappearingTimer.ONE_YEAR)
  //     retValue = CircleDisappearingTimerAPIStrings.ONE_YEAR;
  //
  //   return retValue;
  // }

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
        _disappearingTimer != AppLocalizations.of(context)!.off)
      setTimer = true;
    else if (_circle!.privacyDisappearingTimer != null &&
        requestedTimer != _circle!.privacyDisappearingTimer) {
      setTimer = true;
    }

    if (setTimer)
      list.add(CircleSettingValue(
          priorNumberSetting: _circle!.privacyDisappearingTimer!,
          setting: CircleSetting.privacyDisappearingTimer,
          numericSetting: requestedTimer));

    if (_circle!.privacyShareImage !=
        getSecurityBool(
          privacyShareImage!,
        )) {
      list.add(CircleSettingValue(
          priorBoolSetting: _circle!.privacyShareImage!,
          setting: CircleSetting.privacyShareImage,
          boolSetting: getSecurityBool(
            privacyShareImage!,
          )));
    }

    if (_circle!.privacyShareGif != getSecurityBool(privacyShareGif!))
      list.add(CircleSettingValue(
          priorBoolSetting: _circle!.privacyShareGif!,
          setting: CircleSetting.privacyShareGif,
          boolSetting: getSecurityBool(privacyShareGif!)));

    if (_circle!.privacyShareURL != getSecurityBool(privacyShareURL!))
      list.add(CircleSettingValue(
          priorBoolSetting: _circle!.privacyShareURL!,
          setting: CircleSetting.privacyShareURL,
          boolSetting: getSecurityBool(privacyShareURL!)));

    if (_circle!.privacyCopyText != getSecurityBool(privacyCopyText!))
      list.add(CircleSettingValue(
          priorBoolSetting: _circle!.privacyCopyText!,
          setting: CircleSetting.privacyCopyText,
          boolSetting: getSecurityBool(privacyCopyText!)));

    if (_circle!.toggleEntryVote != getSecurityBool(toggleEntryVote!))
      list.add(CircleSettingValue(
          priorBoolSetting: _circle!.toggleEntryVote!,
          setting: CircleSetting.toggleEntryVote,
          boolSetting: getSecurityBool(toggleEntryVote!)));

    if (_circle!.toggleMemberPosting != getSecurityBool(toggleMemberPosting!))
      list.add(CircleSettingValue(
          priorBoolSetting: _circle!.toggleMemberPosting,
          setting: CircleSetting.toggleMemberPosting,
          boolSetting: getSecurityBool(toggleMemberPosting!)));

    if (_circle!.toggleMemberReacting != getSecurityBool(toggleMemberReacting!))
      list.add(CircleSettingValue(
          priorBoolSetting: _circle!.toggleMemberReacting,
          setting: CircleSetting.toggleMemberReacting,
          boolSetting: getSecurityBool(toggleMemberReacting!)));

    return list;
  }

  _getDateTimeEnd() async {
    DateTime now = DateTime.now();
    DateTime last = DateTime(now.year + 1, now.month, now.day);

    DateTime? date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: last,
      initialDate: DateTime.parse(widget.circle.expiration!),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1),
            ),
            child: globalState.theme.themeMode == ICThemeMode.dark
                ? Theme(
                    data: ThemeData.dark().copyWith(
                      primaryColor: globalState.theme.button,
                      //accentColor:  globalState.theme.button,
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
                      //accentColor:  globalState.theme.button,
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
          initialTime: TimeOfDay.now(),
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
                          //accentColor:  globalState.theme.button,
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
                          //accentColor:  globalState.theme.button,
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
            widget.circle.expiration = temp.toString();
            widget.circleBloc.updateTemporaryExpiration(
                widget.userFurnace, _circle!.id!, temp.toString());
          }
        });
      }
    }
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

class SettingsChanges {
  String localizedMessage;
  String apiMessage;

  SettingsChanges({required this.localizedMessage, required this.apiMessage});
}
