import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart' show toBeginningOfSentenceCase;
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/hostedfurnace_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/dropdownpair.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/utilities/stringhelper.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class NetworkInvite extends StatefulWidget {
  final List<UserFurnace> userFurnaces;
  final UserFurnace? userFurnace;
  const NetworkInvite({Key? key, required this.userFurnaces, this.userFurnace})
      : super(key: key);

  @override
  _FriendsState createState() => _FriendsState();
}

class _FriendsState extends State<NetworkInvite> {
  bool _dm = false;
  bool _inside = true;

  late GlobalEventBloc _globalEventBloc;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool changed = false;
  List<UserCircleCache> userCircleCaches = [];
  final List<DropDownPair> _furnaceList = [];
  late DropDownPair _selected;
  late HostedFurnaceBloc _hostedFurnaceBloc;

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _hostedFurnaceBloc = HostedFurnaceBloc(_globalEventBloc);

    _selected = DropDownPair.blank();

    if (widget.userFurnace == null) {
      for (UserFurnace userFurnace in widget.userFurnaces) {
        if (userFurnace.connected!) {
          _furnaceList.add(DropDownPair(
              id: userFurnace.pk!.toString(),
              value: StringHelper.truncate(userFurnace.alias!, 40))); // ));
        }
      }

      _selected = _furnaceList[0];
    }

    _hostedFurnaceBloc.magicLink.listen((magicLink) async {
      if (mounted) {
        setState(() {
          _showSpinner = false;
        });

        globalState.lastCreatedMagicLink = magicLink;
        _shareLink(context, magicLink, _inside);

        //DialogShareMagicLink.shareToPopup(context, _shareHandler);
      }
    }, onError: (err) {
      debugPrint("error $err");
    });

    super.initState();
  }

  _shareLink(BuildContext context, String magicLink, bool inside) {
    if (inside)
      _globalEventBloc.broadcastPopToHomeAndOpenShare(
          SharedMediaHolder(message: magicLink));
    else {
      Share.share(magicLink);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dm = Padding(
      padding: const EdgeInsets.only(left: 10, right: 0, top: 0, bottom: 0),
      child: Row(children: <Widget>[
        const Spacer(),
        Checkbox(
          side: BorderSide(color: globalState.theme.buttonDisabled, width: 2.0),
          activeColor: globalState.theme.buttonIcon,
          checkColor: globalState.theme.checkBoxCheck,
          value: _dm,
          onChanged: (newValue) {
            setState(() {
              _dm = newValue!;
              //_scrollBottom();
            });
          },
        ),
        ICText(
          AppLocalizations.of(context)!
              .autoAddRecipientsToADM, // 'Auto add recipients to a DM?',
          fontSize: 14,
          textScaleFactor: 1,
        ),
      ]),
    );

    final makeBody = SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ConstrainedBox(
            constraints: const BoxConstraints(),
            child: Container(
              // color: Colors.black,
              padding:
                  const EdgeInsets.only(left: 5, right: 5, top: 0, bottom: 5),
              child: WrapperWidget(
                child:Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    widget.userFurnace != null
                        ? Padding(
                            padding: const EdgeInsets.only(left: 30),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  Row(children: [
                                    ICText(AppLocalizations.of(context)!
                                        .sendNetworkInviteTo), //'Send network invite to: '),
                                    Expanded(
                                        child: ICText(
                                      '${widget.userFurnace!.alias}',
                                      color: globalState.theme.button,
                                    ))
                                  ]),
                                ]))
                        : Row(children: [
                            const Padding(
                              padding:
                                  EdgeInsets.only(left: 30, top: 25, bottom: 0),
                            ),
                            Expanded(
                                child: ICText(toBeginningOfSentenceCase(
                                    AppLocalizations.of(context)!
                                        .selectANetwork)!)), //'Send an invite for which network?')),
                          ]),
                    widget.userFurnace != null
                        ? Container()
                        : Padding(
                            padding: const EdgeInsets.only(
                                left: 31, right: 20, top: 0, bottom: 0),
                            child: Row(children: <Widget>[
                              Expanded(
                                flex: 20,
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context)!
                                        .selectANetwork, // 'select a network',
                                    hintStyle: TextStyle(
                                        color:
                                            globalState.theme.textFieldLabel),
                                  ),
                                  //isEmpty: _furnace == 'first match',
                                  child: DropdownButtonHideUnderline(
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                          canvasColor: globalState
                                              .theme.dropdownBackground),
                                      child: DropdownButton<DropDownPair>(
                                        value: _selected,
                                        onChanged: (DropDownPair? newValue) {
                                          setState(() {
                                            _selected = newValue!;
                                          });
                                        },
                                        items: _furnaceList.map<
                                                DropdownMenuItem<DropDownPair>>(
                                            (DropDownPair value) {
                                          return DropdownMenuItem<DropDownPair>(
                                            value: value,
                                            child: Container(
                                              padding: const EdgeInsets.only(
                                                  left: 16),
                                              child: Text(
                                                value.value,
                                                textScaler: TextScaler.linear(
                                                    globalState
                                                        .dropdownScaleFactor),
                                                style: ICTextStyle
                                                    .getDropdownStyle(
                                                        context: context,
                                                        color: globalState.theme
                                                            .dropdownText),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                          ),
                    dm,
                    Row(children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 30, top: 40, bottom: 0),
                      ),
                      Expanded(
                          child: ICText(AppLocalizations.of(context)!
                              .whereWouldYouLikeToSendTheMagicLink)), //'Where would you like to send the magic link?')),
                    ]),

                    //_row('To a Circle/DM', Icons.share, true),
                    //_row('Outside IronCircles', Icons.share_outlined, false),

                    Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 10),
                        child: Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: ButtonType.getWidth(
                                    MediaQuery.of(context).size.width)),
                            child: GradientButton(
                                onPressed: () {
                                  _shareMagicCode(true);
                                },
                                text: AppLocalizations.of(context)!
                                    .tOACIRCLEDM))), // 'TO A CIRCLE/DM'))),
                    Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 10),
                        child: Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: ButtonType.getWidth(
                                    MediaQuery.of(context).size.width)),
                            child: GradientButton(
                                onPressed: () {
                                  _shareMagicCode(false);
                                },
                                text: AppLocalizations.of(context)!
                                    .outsideIronCircles))), //'OUTSIDE IRONCIRCLES'))),
                  ]),
            ))));

    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: globalState.theme.background,
        appBar: ICAppBar(
            title: AppLocalizations.of(context)!
                .sendAMmagicNetworkLink), //'Invite Friends'),
        body: SafeArea(
            top: true,
            bottom: true,
            child:  Stack(children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: makeBody,
                  ),
                ],
              ),
              _showSpinner ? Center(child: spinkit) : Container(),
            ])));
    //  bottomNavigationBar: makeBottom,
  }

  _shareMagicCode(bool inside) {
    try {
      _inside = inside;

      setState(() {
        _showSpinner = true;

        if (widget.userFurnace != null) {
          _hostedFurnaceBloc.getFirebaseDynamicLink(widget.userFurnace!, _dm);
        } else {
          _hostedFurnaceBloc.getFirebaseDynamicLink(
              widget.userFurnaces.firstWhere(
                  (element) => element.pk!.toString() == _selected.id),
              true);
        }
      });
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('MembersInvitations._getMagicLink: $err');

      setState(() {
        _showSpinner = false;
      });
    }
  }
}
