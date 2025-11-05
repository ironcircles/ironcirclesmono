import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:ironcirclesapp/blocs/release_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/release.dart';
import 'package:ironcirclesapp/screens/widgets/appstorelink.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';

class Releases extends StatefulWidget {
  const Releases({
    Key? key,
  }) : super(key: key);

  @override
  _TutorialsState createState() => _TutorialsState();
}

class _TutorialsState extends State<Releases> {
  //ScrollController _scrollController = ScrollController();
  final ReleaseBloc _releaseBloc = ReleaseBloc();

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _showSpinner = true;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  final ScrollController _scrollControllerNotes = ScrollController();
  final ScrollController _scrollControllerReleases = ScrollController();

  List<Release> _releases = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    /*
    tutorials.add(VideoUrl(
        name: 'Test',
        description: 'intro video',
        url:
            'https://ic-tutorials.s3-us-west-2.amazonaws.com/VID-20200621-WA0042.mp4'));

    tutorials.add(VideoUrl(
        name: 'Swordplay',
        description: 'the art of swordplay',
        url:
        'https://ic-tutorials.s3-us-west-2.amazonaws.com/PXL_20201122_052734427.mp4'));

     */

    //_initControllers()

    _releaseBloc.releasesLoaded.listen((releases) {
      if (mounted) {
        setState(() {
          _showSpinner = false;
          //_selectedIndex = releases.length - 1;
          _releases = releases;
        });
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _releaseBloc.get(globalState.userFurnace!);

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
    Padding showNotes() => Padding(
        padding: const EdgeInsets.only(bottom: 0, top: 20, left: 35, right: 0),
        child: Scrollbar(
            controller: _scrollControllerNotes,
            //isAlwaysShown: true,
            //scrollbarOrientation: ScrollbarOrientation.right,
            child: ListView.builder(
                //reverse: isUser ? true : false,
                itemCount: _releases[_selectedIndex].notes.length,
                padding: const EdgeInsets.only(right: 0, left: 0, bottom: 0),
                controller: _scrollControllerNotes,
                scrollDirection: Axis.vertical,
                //shrinkWrap: true,
                //gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                // crossAxisCount: 1,
                //  ),
                itemBuilder: (BuildContext context, int index) {
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                            padding: const EdgeInsets.only(bottom: 25, right: 15),
                            child: Text(
                              '${index + 1})  ${_releases[_selectedIndex].notes[index]}',
                              textScaler: TextScaler.linear(globalState.labelScaleFactor),
                              style: TextStyle(
                                  color: globalState.theme.drawerItemText),
                            )),
                        index == _releases[_selectedIndex].notes.length - 1
                            ? Padding(
                                padding: const EdgeInsets.only(top: 25),
                                child: Text(
                                    "Released on: ${DateFormat.yMMMd().format(
                                            _releases[_selectedIndex]
                                                .released
                                                .toLocal())}",
                                    textScaler: TextScaler.linear(globalState.labelScaleFactor),
                                    style: TextStyle(
                                        color: globalState.theme.labelText)))
                            : Container(),
                      ]);
                })));

    Padding showReleases() => Padding(
        padding: const EdgeInsets.only(bottom: 0, top: 0, left: 0, right: 0),
        child: ListView.builder(
            //reverse: isUser ? true : false,
            itemCount: _releases.length,
            padding: const EdgeInsets.only(right: 0, left: 0),
            controller: _scrollControllerReleases,
            scrollDirection: Axis.vertical,
            //shrinkWrap: true,
            //gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            // crossAxisCount: 1,
            //  ),
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                tileColor: _selectedIndex == index
                    ? globalState.theme.drawerCanvas
                    : globalState.theme.background,
                contentPadding: const EdgeInsets.only(left: 15),
                title: Text(
                  _releases[index].version,
                  textScaler: TextScaler.linear(globalState.labelScaleFactor),
                  style: TextStyle(color: globalState.theme.drawerItemText),
                ),
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
              );
              //  return Text(_releases[index].version);
            }));

    return Scaffold(
      backgroundColor: globalState.theme.background,
      key: _scaffoldKey,
      appBar: const ICAppBar(
        title: "Release Notes",
      ),
      //drawer: NavigationDrawer(),
      floatingActionButton: AppStoreLink(),
      body: SafeArea(
          left: false,
          top: false,
          right: false,
          bottom: true,
          child: Stack(
            children: [
              Column(children: [
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
                                padding: EdgeInsets.only(top: 0, left: 10),
                                child:
                                    Text('', style: TextStyle(fontSize: 21)))),
                        Expanded(
                            flex: 3,
                            child: Padding(
                                padding: const EdgeInsets.only(top: 10, left: 35),
                                child: Text(
                                  '',
                                  style: TextStyle(
                                      fontSize: 17,
                                      color: globalState.theme.labelText),
                                ))),
                      ],
                    )),
                Expanded(
                    child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  //mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Expanded(
                        flex: 1,
                        child: _releases.isNotEmpty
                            ? showReleases()
                            : Container()),
                    Expanded(
                        flex: 3,
                        child: _releases.isNotEmpty
                            ? Container(
                                color: globalState.theme.drawerCanvas,
                                child: Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: showNotes()))
                            : Container()),
                  ],
                )),
                const Padding(
                    padding: EdgeInsets.only(
                  bottom: 75,
                )),
              ]),
              _showSpinner ? Center(child: spinkit) : Container(),
            ],
          )),
    );
  }
}
