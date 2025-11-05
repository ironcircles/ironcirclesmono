import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/tutorial_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/tutorial.dart';
import 'package:ironcirclesapp/screens/leftnavigation/backlogscreen.dart';
import 'package:ironcirclesapp/screens/leftnavigation/helpsearch.dart';
import 'package:ironcirclesapp/screens/leftnavigation/tutorial_detail.dart';
import 'package:ironcirclesapp/screens/walkthroughs/insidecircle_walkthrough.dart';
import 'package:ironcirclesapp/screens/widgets/gradientbutton.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';

class HelpCenter extends StatefulWidget {
  const HelpCenter({
    Key? key,
  }) : super(key: key);

  @override
  _HelpCenterState createState() => _HelpCenterState();
}

/*class VideoUrl {
  String name = '';
  String url = '';
  String description = '';

  VideoUrl({required this.name, required this.url, required this.description});
}*/

class _HelpCenterState extends State<HelpCenter> {
  //ScrollController _scrollController = ScrollController();
  final TutorialBloc _tutorialBloc = TutorialBloc();

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late InsideCircleWalkthrough _insideCircleWalkthrough;

  bool _showSpinner = true;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  List<Topic> _topics = [];
  final ScrollController _scrollControllerTopics = ScrollController();
  final int _selectedIndex = 0;

  @override
  void initState() {
    _tutorialBloc.tutorialsLoaded.listen((tutorials) {
      if (mounted) {
        setState(() {
          _showSpinner = false;
          _topics = tutorials;
        });
      }
    }, onError: (err) {
      setState(() {
        _showSpinner = false;
      });
      debugPrint("error $err");
    }, cancelOnError: false);

    _tutorialBloc.get(globalState.userFurnace!);

    _insideCircleWalkthrough = InsideCircleWalkthrough(_finish);

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
    ListView showTutorials(int topicIndex) => ListView.builder(
        //reverse: isUser ? true : false,
        itemCount: _topics[topicIndex].tutorials.length,
        padding: const EdgeInsets.only(right: 0, left: 0, bottom: 0),
        //controller: _scrollControllerTutorials,
        //scrollDirection: Axis.vertical,
        physics: const ClampingScrollPhysics(),
        shrinkWrap: true,
        //gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        // crossAxisCount: 1,
        //  ),
        itemBuilder: (BuildContext context, int index) {
          Tutorial tutorial = _topics[topicIndex].tutorials[index];

          return Row(mainAxisSize: MainAxisSize.min, children: [
            Expanded(
                child: InkWell(
                    onTap: () {
                      open(_topics[_selectedIndex], tutorial);
                    },
                    child: Padding(
                        padding: EdgeInsets.only(
                            top: index == 0 ? 20 : 10, bottom: 10, left: 0),
                        child: ICText(
                          tutorial.title,
                          fontSize: 16,
                        )))),
          ]);
        });

    ListTile makeListTile(int index, Topic topic) => ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          leading: Container(
              padding: const EdgeInsets.only(right: 12.0),
              decoration: BoxDecoration(
                  border: Border(
                      right: BorderSide(
                          width: 1.0,
                          color: globalState.theme.trainingCardSeparator))),
              child: Text(
                (index + 1).toString(),
                textScaler: TextScaler.linear(globalState.cardScaleFactor),
                style: TextStyle(
                    fontSize: 16,
                    color: globalState.theme.trainingCardSeparator),
              ) //Icon(Icons.movie, color: globalState.theme.trainingCardLeadingIcon),
              ),
          title: Row(children: <Widget>[
            Expanded(
                child: Container(
              padding: const EdgeInsets.only(top: 10.0),
              child: Text(
                topic.topic,
                textScaler: TextScaler.linear(globalState.cardScaleFactor),
                //circleObject.userFurnace.alias,
                style: TextStyle(
                    fontSize: 20,
                    color: globalState.theme.trainingCardTitle,
                    fontWeight: FontWeight.bold),
              ),
            ))
          ]),
          subtitle: Column(children: <Widget>[
            showTutorials(index),
          ]),
        );

    Card makeTopicCard(int index, Topic topic) => Card(
          surfaceTintColor: Colors.transparent,
          color: globalState.theme.trainingCard,
          elevation: 8.0,
          margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          child: makeListTile(index, topic),
        );

    ListView showTopics() => ListView.builder(
        //reverse: isUser ? true : false,
        itemCount: _topics.length,
        padding: const EdgeInsets.only(right: 0, left: 0),
        controller: _scrollControllerTopics,
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        //gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        // crossAxisCount: 1,
        //  ),
        itemBuilder: (BuildContext context, int index) {
          return WrapperWidget(child: makeTopicCard(index, _topics[index]));
          // );
          //  return Text(_releases[index].version);
        });

    return Scaffold(
      backgroundColor: globalState.theme.background,
      key: _scaffoldKey,
      appBar: ICAppBar(
          title: AppLocalizations.of(context)!.helpCenter,
          actions: <Widget>[
            Padding(
                padding: const EdgeInsets.only(right: 20),
                child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 27 - globalState.scaleDownIcons,
                    key: _insideCircleWalkthrough.keyButton7,
                    icon:
                        Icon(Icons.search, color: globalState.theme.menuIcons),
                    onPressed: _openHelpSearch))
          ]),
      //drawer: NavigationDrawer(),
      body: SafeArea(
          left: false,
          top: false,
          right: false,
          bottom: true,
          child: Stack(
            children: [
              Padding(
                  padding:
                      const EdgeInsets.only(left: 10, right: 10, bottom: 5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                          height: 10,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            //mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              const Expanded(
                                  flex: 1,
                                  child: Padding(
                                      padding:
                                          EdgeInsets.only(top: 0, left: 10),
                                      child: Text('',
                                          style: TextStyle(fontSize: 21)))),
                              Expanded(
                                  flex: 3,
                                  child: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 10, left: 35),
                                      child: Text(
                                        '',
                                        style: TextStyle(
                                            fontSize: 17,
                                            color: globalState.theme.labelText),
                                      ))),
                            ],
                          )),
                      _topics.isNotEmpty
                          ? Expanded(
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  //mainAxisSize: MainAxisSize.max,
                                  children: <Widget>[
                                  Expanded(flex: 1, child: showTopics())
                                ]))
                          : const Spacer(),
                      globalState.user.role == Role.IC_ADMIN || kDebugMode
                          ? Center(
                              child: SizedBox(
                                  width: ScreenSizes.getMaxButtonWidth(
                                      MediaQuery.of(context).size.width, true),
                                  child: GradientButton(
                                      onPressed: () {
                                        _tutorialBloc.generateContent(
                                            globalState.userFurnace!);
                                      },
                                      // fontSize: 20, height: 45,
                                      text: AppLocalizations.of(context)!
                                          .generateContent)))
                          : Container(),
                      const Padding(
                          padding: EdgeInsets.only(
                              left: 0, right: 0, top: 10, bottom: 0)),
                      Center(
                          child: SizedBox(
                              width: ScreenSizes.getMaxButtonWidth(
                                  MediaQuery.of(context).size.width, true),
                              child: GradientButton(
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ReportIssue(),
                                        ));
                                  },
                                  // fontSize: 20, height: 45,
                                  text: AppLocalizations.of(context)!
                                      .issuesAndRequests))),
                      /*Padding(
                          padding: const EdgeInsets.only(
                              left: 0, right: 0, top: 5, bottom: 0),
                          child: Container(
                              margin: EdgeInsets.symmetric(
                                  horizontal: ButtonType.getWidth(
                                      MediaQuery.of(context).size.width)),
                              child: GradientButton(
                                  onPressed: () {

                                      FormattedSnackBar.showSnackbarWithContext(context, 'Coming later this month', '', 3);
                                  },
                                  // fontSize: 20, height: 45,
                                  text: 'CHAT WITH SUPPORT'))),*/

                      /*Expanded(
                          child: _tutorials.length > 0
                              ? ListView.separated(
                                  separatorBuilder: (context, index) {
                                    return Divider(
                                      height: 10,
                                      color: globalState.theme.background,
                                    );
                                  },
                                  itemCount: _tutorials.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    var row = _tutorials[index];

                                    try {
                                      return makeCard(
                                        index,
                                        row,
                                      );
                                    } catch (err, trace) {
                                      LogBloc.insertError(err, trace);
                                      return Expanded(child: spinner);
                                    }
                                  })
                              : Container()),

                       */
                    ],
                  )),
              _showSpinner ? Center(child: spinkit) : Container(),
            ],
          )),
    );
  }

  void open(Topic topic, Tutorial tutorial) async {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => TutorialDetail(
                  topic: topic,
                  tutorial: tutorial,
                )));

    /*
    if (tutorial.video == null) {
      FormattedSnackBar.showSnackbarWithContext(context, 'coming soon!', '', 3);

      return;
    }

    await Navigator.of(context).push(MaterialPageRoute(
      builder: (BuildContext context) => FullScreenVideo(
        url: tutorial.video!,
        title: tutorial.title,
        description: tutorial.description,
        fullScreenByDefault: true,
      ),
    ));

    setState(() {});
  }

     */
  }

  void _finish() {}

  _openHelpSearch() async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => HelpSearch(
                  topics: _topics,
                )));
  }
}
