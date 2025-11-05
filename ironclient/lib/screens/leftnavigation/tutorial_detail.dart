import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/tutorial.dart';
import 'package:ironcirclesapp/screens/utilities/fullscreen_video.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';

class TutorialDetail extends StatefulWidget {
  final Topic topic;
  final Tutorial tutorial;

  const TutorialDetail({
    Key? key,
    required this.topic,
    required this.tutorial,
  }) : super(key: key);

  @override
  _TutorialDetailState createState() => _TutorialDetailState();
}

/*class VideoUrl {
  String name = '';
  String url = '';
  String description = '';

  VideoUrl({required this.name, required this.url, required this.description});
}*/

class _TutorialDetailState extends State<TutorialDetail> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ListView showTutorialLineItems() => ListView.builder(
        //reverse: isUser ? true : false,
        itemCount: widget.tutorial.lineItems.length,
        padding: const EdgeInsets.only(right: 0, left: 0, bottom: 0),
        //controller: _scrollControllerTutorials,
        //scrollDirection: Axis.vertical,
        physics: const ClampingScrollPhysics(),
        shrinkWrap: true,
        //gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        // crossAxisCount: 1,
        //  ),
        itemBuilder: (BuildContext context, int index) {
          TutorialLineItem tutorialLineItem = widget.tutorial.lineItems[index];

          return WrapperWidget(child: Row(mainAxisSize: MainAxisSize.min, children: [
            /*Expanded(
                child: Padding(
                    padding: EdgeInsets.only(left: 50),
                    child: Text(
                      (index + 1).toString() +
                          ')  ' +
                          _topics[_selectedIndex].tutorials[index].title,
                      textScaleFactor: globalState.labelScaleFactor,
                      style: TextStyle(color: globalState.theme.drawerItemText),
                    )))

             */

            Expanded(
                child: Padding(
                    padding:
                        const EdgeInsets.only(top: 10, bottom: 10, left: 0),
                    child: ICText(
                      tutorialLineItem.item,
                      fontSize: tutorialLineItem.subTitle ? 18 : 16,
                      fontWeight: tutorialLineItem.subTitle
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: tutorialLineItem.subTitle
                          ? globalState.theme.trainingCardTitle
                          : globalState.theme.labelText,
                    ))),
            tutorialLineItem.video == null
                ? Container()
                : IconButton(
                    onPressed: () {
                      play(tutorialLineItem);
                    },
                    icon: const Icon(Icons.play_circle))
          ]));
        });

    return Scaffold(
      backgroundColor: globalState.theme.background,
      key: _scaffoldKey,
      appBar: const ICAppBar(title: ''),
      //drawer: NavigationDrawer(),
      body: SafeArea(
          left: false,
          top: true,
          right: false,
          bottom: true,
          child: Stack(
            children: [
              Padding(
                  padding:
                      const EdgeInsets.only(left: 25, right: 15, bottom: 5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        //mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          Expanded(
                              //flex: 3,
                              child: ICText(widget.tutorial.title,
                                  fontSize: 20,
                                  color: globalState.theme.labelText)),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 0, right: 0, bottom: 10),
                      ),
                      widget.tutorial.lineItems.isNotEmpty
                          ? Expanded(
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  //mainAxisSize: MainAxisSize.max,
                                  children: <Widget>[
                                  Expanded(
                                      flex: 1, child: showTutorialLineItems())
                                ]))
                          : Container()

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
            ],
          )),
    );
  }

  void play(TutorialLineItem tutorialLineItem) async {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (BuildContext context) => FullScreenVideo(
        url: tutorialLineItem.video!,
        title: tutorialLineItem.item,
        description: '',
        fullScreenByDefault: true,
      ),
    ));
  }
}
