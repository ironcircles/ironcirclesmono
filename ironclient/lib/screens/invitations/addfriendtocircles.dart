import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/invitations_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/circles/messagefeed_usercircle.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:provider/provider.dart';
///Called from the InsideCircle and when the app receives an external share

class AddFriendToCircles extends StatefulWidget {
  final User member;
  final UserFurnace userFurnace;

  const AddFriendToCircles({
    Key? key,
    required this.userFurnace,
    required this.member,
  }) : super(key: key);
  // FlutterDetail({Key key, this.flutterbug}) : super(key: key);
  // final String title;

  @override
  _AddFriendToCirclesState createState() => _AddFriendToCirclesState();
}

class _AddFriendToCirclesState extends State<AddFriendToCircles> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  late UserCircleBloc _userCircleBloc;
  late GlobalEventBloc _globalEventBloc;
  final InvitationBloc _invitationBloc = InvitationBloc();

  List<UserCircleCache> _userCircles = [];

  bool _loaded = false;

  @override
  void initState() {
    super.initState();

    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _userCircleBloc = UserCircleBloc(globalEventBloc: _globalEventBloc);

    _invitationBloc.sendMultipleInvitationsResponse.listen((success) async {
      if (mounted) {
        setState(() {
          _userCircles.removeWhere((element) => element.selected == true);
        });

        FormattedSnackBar.showSnackbarWithContext(context,
            AppLocalizations.of(context)!.invitationsSent, '', 3, false);
      }
    }, onError: (err) {
      //Navigator.pushReplacementNamed(context, '/login');
      debugPrint("error $err");
    }, cancelOnError: false);

    _userCircleBloc.refreshedUserCircles.listen(
        (refreshedUserCircleCaches) async {
      if (mounted) {
        setState(() {
          _userCircles = refreshedUserCircleCaches;

          _userCircles.removeWhere((element) => (element.dm == true));
          _userCircles.removeWhere(
              (element) => (element.cachedCircle!.type == CircleType.VAULT));

          _loaded = true;
        });
      }
    }, onError: (err) {
      //Navigator.pushReplacementNamed(context, '/login');
      debugPrint("error $err");
    }, cancelOnError: false);

    _userCircleBloc.sinkCacheWithoutMember([widget.userFurnace], widget.member);
  }

  @override
  void dispose() {
    //_circleName.dispose();
    //_password.dispose();
    //_password2.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final makeList = SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ConstrainedBox(
            constraints: const BoxConstraints(),
            child: Container(
                // color: Colors.black,
                padding: const EdgeInsets.only(
                    left: 20, right: 20, top: 0, bottom: 10),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        // color: Colors.black,
                        padding: const EdgeInsets.only(
                            left: 10, right: 10, top: 0, bottom: 20),
                        child: (_loaded && _userCircles.isEmpty)
                            ?  Padding(
                                padding: const EdgeInsets.only(top: 30),
                                child:
                                    Center(child: ICText(AppLocalizations.of(context)!.noCirclesFound)))
                            : ListView.builder(
                                scrollDirection: Axis.vertical,
                                controller: _scrollController,
                                shrinkWrap: true,
                                itemCount: _userCircles.length,
                                itemBuilder: (BuildContext context, int index) {
                                  var item = _userCircles[index];

                                  return WrapperWidget(child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          item.selected = !item.selected;
                                        });
                                      },
                                      child: Row(children: [
                                        MessageFeedUserCircleWidget(
                                          index,
                                          item.furnaceObject!,
                                          _userCircleBloc,
                                          item,
                                          _doNothing,
                                          radius: 180 -
                                              (globalState.scaleDownIcons * 2),
                                        ),
                                        const Spacer(),
                                        Checkbox(
                                            activeColor:
                                            globalState.theme.buttonIcon,
                                            checkColor:
                                            globalState.theme.checkBoxCheck,
                                            side: BorderSide(color: globalState.theme.buttonDisabled, width: 2.0),
                                            //title: Text(' '),
                                            value: item.selected,
                                            onChanged: (newValue) {
                                              setState(() {
                                                item.selected = newValue!;
                                              });
                                            })
                                      ])));
                                }),
                      )
                    ]))));

    final makeBottom = WrapperWidget(child: SizedBox(
      height: 55.0,
      child: Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 0),
        child: Row(children: <Widget>[
          Expanded(
            child: GradientButton(
                text: AppLocalizations.of(context)!.sendInvitations.toUpperCase(),
                onPressed: () {
                  if (_userCircles
                          .indexWhere((element) => element.selected == true) ==
                      -1)
                    FormattedSnackBar.showSnackbarWithContext(
                        context,
                        AppLocalizations.of(context)!.nothingSelected,
                        '',
                        3,
                        false);
                  else
                    _invitationBloc.sendInvitationsToMember(
                        widget.member,
                        _userCircles
                            .where((element) => element.selected == true));
                }),
          ),
        ]),
      ),
    ))  ;

    return Scaffold(
        backgroundColor: globalState.theme.background,
        key: _scaffoldKey,
        appBar:  ICAppBar(title: AppLocalizations.of(context)!.addToCircles),
        body: SafeArea(
            left: false,
            top: false,
            right: false,
            bottom: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                //makeTitle,
                Expanded(
                  child: makeList,
                ),
                const Padding(padding: EdgeInsets.only(bottom: 20)),
                Container(
                  padding: const EdgeInsets.all(0.0),
                  child: makeBottom,
                ),
              ],
            )));
  }

  _doNothing(UserCircleCache userCircleCache) {}
}
