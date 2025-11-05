

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/constants/constants.dart';
import 'package:ironcirclesapp/models/globalstate.dart';
import 'package:ironcirclesapp/models/tutorial.dart';
import 'package:ironcirclesapp/screens/leftnavigation/tutorial_detail.dart';
import 'package:ironcirclesapp/screens/widgets/formattedtext.dart';
import 'package:ironcirclesapp/screens/widgets/gradientbutton.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class HelpSearch extends StatefulWidget {
  final List<Topic> topics;

  const HelpSearch({
    Key? key,
    required this.topics,
  }) : super(key: key);

  @override
  _HelpSearch createState() => _HelpSearch();
}

class _HelpSearch extends State<HelpSearch> {

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  //List<Tutorial> _results = [];
  List<Topic> _results = [];
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchtext = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// used to get results from topics and tutorial titles
  _searchAction(String searchText) async {
    _results = [];
    /// loop through topics
    for (int i = 0; i < widget.topics.length; i ++) {
      Topic topic = widget.topics[i];
      String titleTopic = topic.topic.toLowerCase();
      if (titleTopic.contains(searchText.toLowerCase())) {
        _results.add(topic);
      } else {
        ///loop through tutorials
        for (int j = 0; j < topic.tutorials.length; j++) {
          Tutorial tutorial = topic.tutorials[j];
          String title = tutorial.title.toLowerCase();
          if (title.contains(searchText.toLowerCase())) {
            if (_results.contains(topic) == false) {
              _results.add(topic);
            }
          }
        }
      }
    }
    setState(() {
    });
  }

  /// used to get results from tutorial titles and content
  // _searchAction(String searchText) async {
  //   _results = [];
  //   /// loop through topics
  //   for (int i = 0; i < widget.topics.length; i ++) {
  //     Topic topic = widget.topics[i];
  //     ///loop through tutorials
  //     for (int j = 0; j < topic.tutorials.length; j++) {
  //       Tutorial tutorial = topic.tutorials[j];
  //       String title = tutorial.title.toLowerCase();
  //       if (title.contains(searchText)) {
  //         _results.add(tutorial);
  //       } else {
  //         /// loop through tutorial contents
  //         for (int l = 0; l < tutorial.lineItems.length; l++) {
  //           TutorialLineItem lineItem = tutorial.lineItems[l];
  //           String row = lineItem.item.toLowerCase();
  //           if (row.contains(searchText)) {
  //             _results.add(tutorial);
  //           }
  //         }
  //       }
  //     }
  //   }
  //   setState(() {
  //
  //   });
  //   int caterpillar = 0;
  // }

  @override
  Widget build(BuildContext context) {

    final _searchResults = _results.isNotEmpty
        ? ScrollablePositionedList.separated(
        itemScrollController: _itemScrollController,
        itemPositionsListener: _itemPositionsListener,
        separatorBuilder: (context, index) {
          return Divider(
              height: 10,
              color: globalState.theme.background
          );
        },
        itemCount: _results.length,
        itemBuilder: (BuildContext context, int index) {
          Topic topic = _results[index];
          int topicIndex = widget.topics.indexOf(topic);
          return Card(
              surfaceTintColor: Colors.transparent,
              color: globalState.theme.trainingCard,
              elevation: 8.0,
              margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                  leading: Container(
                      padding: const EdgeInsets.only(right: 12.0),
                      decoration: BoxDecoration(
                          border: Border(
                              right: BorderSide(
                                  width: 1.0,
                                  color: globalState.theme.trainingCardSeparator))),
                      child: Text(
                        (topicIndex + 1).toString(),
                        textScaler: TextScaler.linear(globalState.cardScaleFactor),
                        style: TextStyle(
                            fontSize: 16,
                            color: globalState.theme.trainingCardSeparator),
                      )
                  ),
                  title: Row(children: <Widget>[
                    Expanded(
                        child: Container(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text(
                            topic.topic,
                            textScaler: TextScaler.linear(globalState.cardScaleFactor),
                            style: TextStyle(
                                fontSize: 20,
                                color: globalState.theme.trainingCardTitle,
                                fontWeight: FontWeight.bold),
                          ),
                        ))
                  ]),
                  subtitle: Column(children: <Widget>[
                    ListView.builder(
                        itemCount: _results[index].tutorials.length,
                        padding: const EdgeInsets.only(right: 0, left: 0, bottom: 0),
                        physics: const ClampingScrollPhysics(),
                        shrinkWrap: true,
                        itemBuilder: (BuildContext context, int ind) {
                          Tutorial tutorial = _results[index].tutorials[ind];
                          return Row(mainAxisSize: MainAxisSize.min, children: [
                            Expanded(
                                child: InkWell(
                                    onTap: () {
                                      open(tutorial);
                                    },
                                    child: Padding(
                                        padding: EdgeInsets.only(
                                            top: index == 0 ? 20 : 10, bottom: 10, left: 0),
                                        child: ICText(
                                          tutorial.title,
                                          fontSize: 16,
                                        )))),
                          ]
                          );
                        }
                    )
                  ])
              )
          );
        }
    )
        : Container();

    // final _searchResults = _results.isNotEmpty
    //   ? ScrollablePositionedList.separated(
    //     itemScrollController: _itemScrollController,
    //     itemPositionsListener: _itemPositionsListener,
    //     separatorBuilder: (context, index) {
    //       return Divider(
    //         height: 10,
    //         color: globalState.theme.background
    //       );
    //     },
    //   itemCount: _results.length,
    //   itemBuilder: (BuildContext context, int index) {
    //       Tutorial tutorial = _results[index];
    //       return Row(
    //         mainAxisSize: MainAxisSize.min,
    //         children: [
    //           Expanded(
    //             child: Container(
    //               color: globalState.theme.trainingCard,
    //               child: InkWell(
    //                   onTap: () {
    //                     open(tutorial);
    //                   },
    //                   child: Padding(
    //                       padding: EdgeInsets.only( top: 10, left: 15, bottom: 10, right: 15),
    //                           //top: index == 0 ? 20 : 10, bottom: 10, left: 0),
    //                       child: ICText(
    //                         tutorial.title,
    //                         fontSize: 20, //16
    //                       )
    //                   )
    //               )
    //             )
    //           )
    //         ]
    //       );
    //   }
    // )
    // : Container();

    final _makeBody = Column(children: [
      Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Row(
              children: <Widget>[
                Expanded(
                    flex: 20,
                    child: FormattedText(
                      labelText: 'What do you want to search for?',
                      controller: _searchtext,
                    )
                )
              ]
          )
      ),
      Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Row(children: <Widget>[
            Expanded(
                flex: 20,
                child: Container(
                    margin: EdgeInsets.symmetric(
                        horizontal: ButtonType.getWidth(MediaQuery.of(context).size.width)),
                    child: GradientButton(
                        text: 'Search',
                        onPressed: () {
                          _searchAction(_searchtext.text);
                        }
                    ))
            )
          ])
      ),
      Expanded(child: _searchResults),
    ]);

    return Scaffold(
        backgroundColor: globalState.theme.background,
        key: _scaffoldKey,
        appBar: const ICAppBar(title: 'Search'),
        body: SafeArea(
            left: false,
            top: false,
            right: false,
            bottom: true,
            child: Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 5),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Expanded(child: _makeBody),
                    ]
                )
            )
        )
    );
  }

  Topic searchForTutorial(Tutorial tutorial) {
    for (int i = 0; i < widget.topics.length; i++) {
      Topic topic = widget.topics[i];
      for (int j = 0; j < topic.tutorials.length; j++) {
        Tutorial t = topic.tutorials[j];
        if (t == tutorial) {
          return topic;
        }
      }
    }
    ///this should never fire
    return widget.topics.first;
  }

  void open(Tutorial tutorial) async {
    Topic topic = searchForTutorial(tutorial);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => TutorialDetail(
              topic: topic,
              tutorial: tutorial,
            )));
  }


}