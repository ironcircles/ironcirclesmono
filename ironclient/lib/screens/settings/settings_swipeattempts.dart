import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/models/globalstate.dart';
import 'package:ironcirclesapp/models/swipepatternattempt.dart';
import 'package:ironcirclesapp/models/user.dart';
import 'package:ironcirclesapp/models/userfurnace.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';
import 'package:provider/provider.dart';

class SwipeAttemptsList extends StatefulWidget {
  final User user;
  final UserFurnace userFurnace;

  const SwipeAttemptsList(
    {Key? key,
    required this.user,
    required this.userFurnace,
  }): super(key: key);

  @override
  SwipeAttemptsListState createState() => SwipeAttemptsListState();
}

class SwipeAttemptsListState extends State<SwipeAttemptsList> {
  List<SwipePatternAttempt> _swipeAttempts = [];
  final ScrollController _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late GlobalEventBloc _globalEventBloc;
  late UserCircleBloc _userCircleBloc;

  @override
  void initState() {
    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _userCircleBloc = UserCircleBloc(globalEventBloc: _globalEventBloc);
    super.initState();

    _userCircleBloc.swipePatternAttempts.listen((swipePatternList) {
      if (mounted) {
        setState(() {
          _swipeAttempts = swipePatternList;
        });
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _userCircleBloc.fetchPatternSwipeAttemptsList(widget.user, widget.userFurnace);
  }

  @override
  Widget build(BuildContext context) {
    final body = SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Container(
          // color: Colors.black,
          padding:
              const EdgeInsets.only(left: 0, right: 0, top: 10, bottom: 20),
          child: ListView.separated(
            separatorBuilder: (context, index) => Divider(
              color: globalState.theme.divider,
            ),
            scrollDirection: Axis.vertical,
            controller: _scrollController,
            shrinkWrap: true,
            itemCount: _swipeAttempts.length,
            itemBuilder: (BuildContext context, int index) {
              SwipePatternAttempt row = _swipeAttempts[index];

              return Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  ICText(DateFormat('MM-dd-yy hh:mm a').format(row.attemptDate.toLocal()),
                      fontSize: globalState.userSetting.fontSize,
                      color: globalState.theme.buttonIcon),
                  const Padding(padding: EdgeInsets.only(left: 10.0)),
                  ICText(row.guardedItemDisplayName!),
                  const Padding(
                      padding: EdgeInsets.only(
                          left: 0.0, top: 0.0, bottom: 0.0, right: 8.0)),
                ],
              );
            },
          )),
    );

    return Scaffold(
      appBar: ICAppBar(
        title: AppLocalizations.of(context)!.failedPatternAttempts,
      ),
      backgroundColor: globalState.theme.background,
      //drawer: NavigationDrawer(),
      body: Padding(
          padding:
          const EdgeInsets.only(left: 20, right: 10, bottom: 5, top: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(child: body),
              //makeBottom,
            ],
          )),
    );
  }
}
