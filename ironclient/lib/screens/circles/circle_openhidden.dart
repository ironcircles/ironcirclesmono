import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:provider/provider.dart';

class CircleOpenHidden extends StatefulWidget {
  // final Flutterbug flutterbug;

  // FlutterManager({Key key, this.title}) : super(key: key);
  // FlutterDetail({Key key, this.flutterbug}) : super(key: key);
  // final String title;

  @override
  _CircleOpenHiddenState createState() => _CircleOpenHiddenState();
}

class _CircleOpenHiddenState extends State<CircleOpenHidden> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _circleName = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _password2 = TextEditingController();
  //bool _hidden = false;
  bool _showPassword = false;

  String? _furnace;
  String? _allFurnace;
  //String _ownershipModel = '';
  final List<String?> _furnaceList = [];
  late UserCircleBloc _userCircleBloc; // = UserCircleBloc();
  //late CircleObjectBloc _circleObjectBloc; // = CircleObjectBloc();
  late GlobalEventBloc _globalEventBloc;
  final UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();
  List<UserFurnace>? _userFurnaces;

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _allFurnace = AppLocalizations.of(context)!.all;
      _furnace = AppLocalizations.of(context)!.all;
      _furnaceList.add(_furnace);
    });

    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _userCircleBloc = UserCircleBloc(globalEventBloc: _globalEventBloc);

    _userFurnaceBloc.userfurnaces.listen((furnaces) {
      if (mounted) {
        setState(() {
          _userFurnaces = furnaces;

          for (UserFurnace userFurnace in _userFurnaces!) {
            if (userFurnace.connected!) {
              if (!_furnaceList.contains(userFurnace.alias))
                _furnaceList.add(userFurnace.alias);
            }
          }

          _showSpinner = false;
        });
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
    }, cancelOnError: false);

    _userCircleBloc.returnHiddenCircles.listen((userCircleCaches) {
      if (mounted) {
        _globalEventBloc.broadcastRefreshHome();
        Navigator.pop(context, true);
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);

      if (mounted) {
        setState(() {
          _showSpinner = false;
        });
      }
    }, cancelOnError: false);

    _userFurnaceBloc.request(globalState.user.id);

    _showSpinner = true;
  }

  @override
  void dispose() {
    _circleName.dispose();
    _password.dispose();
    _password2.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final makeBody = Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 11, top: 0, bottom: 0),
                child: Row(children: <Widget>[
                  Expanded(
                    flex: 20,
                    child: ICText(
                      AppLocalizations.of(context)!
                          .enterPassphraseToOpenCirclesOrDMs,
                      textScaleFactor: globalState.labelScaleFactor,
                      fontSize: 16,
                      color: globalState.theme.labelText,
                    ),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 11, top: 4, bottom: 0, right: 49),
                child: Row(children: <Widget>[
                  Expanded(
                    flex: 20,
                    child: MediaQuery(
                        data: const MediaQueryData(
                          textScaler: TextScaler.linear(1),
                        ),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(10),
                            //  icon: const Icon(Icons.color_lens),
                            hintText:
                                AppLocalizations.of(context)!.selectANetwork,
                            hintStyle: TextStyle(
                                color: globalState.theme.textFieldLabel,
                                fontSize: 16),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: globalState.theme.button),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: globalState.theme.labelTextSubtle),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                  canvasColor:
                                      globalState.theme.dropdownBackground),
                              child: DropdownButton<String>(
                                isDense: true,
                                value: _furnace,
                                itemHeight: null,
                                isExpanded: true,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _furnace = newValue;
                                  });
                                },
                                items: _furnaceList
                                    .map<DropdownMenuItem<String>>(
                                        (String? value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Container(
                                      padding: const EdgeInsets.only(left: 16),
                                      child: ICText(
                                        value!,
                                        textScaleFactor:
                                            globalState.dropdownScaleFactor,
                                        color: globalState.theme.button,
                                        fontSize: 18,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        )),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 0, left: 12),
                child: Row(children: <Widget>[
                  Expanded(
                    flex: 20,
                    child: FormattedText(
                      labelText: AppLocalizations.of(context)!.passphrase,
                      controller: _password,
                      obscureText: !_showPassword,
                      maxLines: 1,
                      validator: (value) {
                        if (value.isEmpty) {
                          return AppLocalizations.of(context)!
                              .passphraseIsRequired;
                        }

                        return null;
                      },
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: _showPassword
                          ? IconButton(
                              icon: Icon(Icons.visibility,
                                  color: globalState.theme.buttonIcon),
                              onPressed: () {
                                setState(() {
                                  _showPassword = false;
                                });
                              })
                          : IconButton(
                              icon: Icon(Icons.visibility,
                                  color: globalState.theme.buttonDisabled),
                              onPressed: () {
                                setState(() {
                                  _showPassword = true;
                                });
                              }))
                  //new Spacer(flex: 1),
                ]),
              ),
            ]),
        // ),
      ),
    );

    final makeBottom = Padding(
      padding: const EdgeInsets.only(left: 0, right: 0, top: 30, bottom: 0),
      child: Row(children: <Widget>[
        Expanded(
          child: GradientButton(
              text: AppLocalizations.of(context)!.open, //'OPEN',
              onPressed: () {
                _validateHiddenPassword();
              }),
        ),
      ]),
    );

    return Form(
        key: _formKey,
        child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: globalState.theme.background,
            appBar: ICAppBar(
              title: AppLocalizations.of(context)!.openCircleOrDM,
            ),
            body: SafeArea(
                left: false,
                top: false,
                right: false,
                bottom: true,
                child: WrapperWidget(
                    child: Stack(children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      _furnaceList.isEmpty ? Container() : makeBody,
                      makeBottom,
                    ],
                  ),
                  _showSpinner ? spinkit : Container()
                ])))));
  }

  _validateHiddenPassword() async {
    if (_formKey.currentState!.validate() && _showSpinner == false) {
      /*FormattedSnackBar.showSnackbarWithContext(
          context, "validating passphrase", "", 2);

       */

      setState(() {
        _showSpinner = true;
      });

      late UserFurnace userFurnace;

      if (_furnace != _allFurnace) {
        for (UserFurnace testFurnace in _userFurnaces!) {
          if (testFurnace.alias == _furnace) {
            userFurnace = testFurnace;
            break;
          }
        }

        _userCircleBloc.validateHiddenPassphraseFurnace(
            _password.text, userFurnace);
      } else {
        _userCircleBloc.validateHiddenPassphrase(
            _password.text, _userFurnaces!);
      }
    }
  }

  /*_goInside(UserCircleCache userCircleCache) {
    globalState.hiddenOpen = true;

    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => InsideCircle(
                  userCircleCache: userCircleCache,
                  userFurnace: userCircleCache.furnaceObject!,
                  hiddenOpen: true,
                )),
        ModalRoute.withName("/home"));
  }

   */
}
