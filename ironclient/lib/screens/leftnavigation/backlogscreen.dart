import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/backlog_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/backlog.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/leftnavigation/backlogitemscreen.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';



class ReportIssue extends StatefulWidget {
  const ReportIssue({
    Key? key,
  }) : super(key: key);

  @override
  _ReportIssueState createState() => _ReportIssueState();
}

/*class VideoUrl {
  String name = '';
  String url = '';
  String description = '';

  VideoUrl({required this.name, required this.url, required this.description});
}*/

class _ReportIssueState extends State<ReportIssue> {
  //ScrollController _scrollController = ScrollController();
  final BacklogBloc _backlogBloc = BacklogBloc();

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  bool _showSpinner = true;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  List<Backlog> _backlog = [];
  List<TableRow> _rows = [];

  @override
  void initState() {
    _backlogBloc.backlogLoaded.listen((backlogs) {
      if (mounted) {
        setState(() {
          _showSpinner = false;

          _rows = [];

          _rows.add(const TableRow(children: [
            Text(''),
            Text('SUMMARY'),
            Text('STATUS'),
          ]));

          for (Backlog backlog in backlogs) {
            _rows.add(TableRow(children: [
              Text(backlog.type),
              Text(backlog.summary),
              Text(backlog.status == null ? '' : backlog.status!),
              //Text(backlog.version == null ? '' : backlog.version!.toString())
            ]));
          }
          _backlog = backlogs;
        });
      }
    }, onError: (err) {
      debugPrint("error $err");
      FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2, true);
    }, cancelOnError: false);

    _backlogBloc.get(globalState.userFurnace!);

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  final spinner = SpinKitThreeBounce(
    size: 20,
    color: globalState.theme.threeBounce,
  );

  @override
  Widget build(BuildContext context) {
    ListTile makeListTile(int index, Backlog backlog) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          leading: Container(
            padding: const EdgeInsets.only(right: 12.0),
            decoration: BoxDecoration(
                border: Border(
                    right: BorderSide(
                        width: 1.0,
                        color: globalState.theme.backlogCardSeparator))),
            child: Icon(
                backlog.type == 'defect'
                    ? Icons.bug_report
                    : Icons.add_circle_outlined,
                color: backlog.type == 'defect'
                    ? globalState.theme.backlogCardLeadingDefectIcon
                    : globalState.theme.backlogCardLeadingFeatureIcon),
          ),
          title: Row(children: <Widget>[
            Expanded(
                child: Container(
              padding: const EdgeInsets.only(top: 10.0),
              child: Text(
                backlog.summary.length > 150
                    ? '${backlog.summary.substring(0, 149)}...'
                    : backlog.summary,
                textScaler: TextScaler.linear(globalState.cardScaleFactor),
                //circleObject.userFurnace.alias,
                style: TextStyle(
                    color: globalState.theme.backlogCardTitle,
                    fontWeight: FontWeight.normal),
              ),
            ))
          ]),
          subtitle: Column(children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  'status: ',
                  textScaler: const TextScaler.linear(1.0),
                  style:
                      TextStyle(color: globalState.theme.backlogCardSubTitle),
                ),
                Text(
                  backlog.status!,
                  textScaler: const TextScaler.linear(1.0),
                  style:
                      TextStyle(color: globalState.theme.backlogCardSubTitle),
                ),
                const Spacer(),
                Text(
                  'votes: ',
                  textScaler: const TextScaler.linear(1.0),
                  style:
                      TextStyle(color: globalState.theme.backlogCardSubTitle),
                ),
                Text(
                  backlog.upVotes!.length.toString(),
                  textScaler: const TextScaler.linear(1.0),
                  style:
                      TextStyle(color: globalState.theme.backlogCardSubTitle),
                ),
                /*Expanded(
                    //flex: 0,
                    child: Padding(
                        padding: EdgeInsets.only(left: 5.0, bottom: 5, top: 10),
                        child: Text(
                          backlog.description,
                          style: TextStyle(
                              color: globalState.theme.backlogCardSubTitle),
                        ))),*/
              ],
            ),
          ]),
          trailing: Icon(Icons.keyboard_arrow_right,
              color: globalState.theme.backlogCardTrailingIcon, size: 30.0),
          onTap: () {
            open(context, backlog);
          },
        );

    Card makeCard(int index, Backlog backlog) => Card(
          surfaceTintColor: Colors.transparent,
          color: globalState.theme.backlogCard,
          elevation: 8.0,
          margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          child: makeListTile(index, backlog),
        );

    return Scaffold(
      backgroundColor: globalState.theme.background,
      key: _scaffoldKey,
      appBar:  ICAppBar(
        title: AppLocalizations.of(context)!.openIssueAndRequests ,
      ),
      //drawer: NavigationDrawer(),
      body: SafeArea(
          left: false,
          top: false,
          right: false,
          bottom: true,
          child: RefreshIndicator(
              color: globalState.theme.buttonIcon,
              key: _refreshIndicatorKey,
              onRefresh: _refresh,
              child: Stack(
                children: [
                  Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        //mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          Expanded(
                              child: _backlog.isNotEmpty
                                  ? ListView.separated(
                                      separatorBuilder: (context, index) {
                                        return Divider(
                                          height: 10,
                                          color: globalState.theme.background,
                                        );
                                      },
                                      itemCount: _backlog.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        var row = _backlog[index];

                                        try {
                                        return   WrapperWidget(child:Padding(
                                              padding: EdgeInsets.only(
                                                  bottom: index ==
                                                          _backlog.length - 1
                                                      ? 0
                                                      : 0),
                                              child: Stack(
                                                  alignment:
                                                      Alignment.bottomRight,
                                                  children: [
                                                    Padding(
                                                        padding: EdgeInsets.only(
                                                            bottom: row
                                                                    .voteLabel
                                                                    .isEmpty
                                                                ? 0
                                                                : 30),
                                                        child: makeCard(
                                                          index,
                                                          row,
                                                        )),
                                                    Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                                right: 10),
                                                        child: row.voteLabel
                                                                .isEmpty
                                                            ? Container()
                                                            : TextButton(
                                                                style: TextButton.styleFrom(
                                                                    backgroundColor:
                                                                        globalState
                                                                            .theme
                                                                            .backlogVoteButton),
                                                                onPressed: () {
                                                                  _vote(row);
                                                                },
                                                                child: Text(
                                                                    row
                                                                        .voteLabel,
                                                                    textScaler: TextScaler.linear(globalState.cardScaleFactor),
                                                                    style: TextStyle(
                                                                        color: globalState
                                                                            .theme
                                                                            .backlogVoteButtonText)))),
                                                  ])));
                                        } catch (err, trace) {
                                          LogBloc.insertError(err, trace);
                                          return Expanded(child: spinner);
                                        }
                                      })
                                  : Container()),
                          const SizedBox(
                            height: 75,
                          )
                        ],
                      )),
                  _showSpinner ? Center(child: spinkit) : Container(),
                ],
              ))),
      floatingActionButton: FloatingActionButton(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(30.0))
        ),
        backgroundColor: globalState.theme.buttonIcon,
        foregroundColor: globalState.theme.backlogVoteButtonText,
        onPressed: () {
          _add();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _refresh() async {
    _backlogBloc.get(globalState.userFurnace!);

    return;
  }

  void open(BuildContext context, Backlog backlog) async {
    //Navigator.pop(context);

    await Navigator.of(context).push(MaterialPageRoute(
      builder: (BuildContext context) => BacklogItemScreen(
        backlog: backlog,
      ),
    ));

    // setState(() {});

    _backlogBloc.get(globalState.userFurnace!);
  }

  _vote(Backlog backlog) {
    try {
      _backlogBloc.vote(globalState.userFurnace!, backlog);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('BacklogScreen._vote: $err');
    }
  }

  _add() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (BuildContext context) => const BacklogItemScreen(),
    ));

    _backlogBloc.get(globalState.userFurnace!);
  }
}
