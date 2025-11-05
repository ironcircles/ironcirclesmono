import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circlevideo_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';

class TransferManager extends StatefulWidget {
  final List<UserFurnace>? userFurnaces;
  final List<CircleObject>? circleObjects;

  const TransferManager({
    this.circleObjects,
    required this.userFurnaces,
    Key? key,
  }) : super(key: key);

  @override
  _TransferManagerState createState() => _TransferManagerState();
}

class _TransferManagerState extends State<TransferManager> {
  final ScrollController _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  GlobalEventBloc? _globalEventBloc;
  late CircleVideoBloc _circleVideoBloc;
  //UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();

  final List<CircleObject> _circleObjects = [];
  final List<CircleObject> _removedObjects = [];

  bool filter = false;

  @override
  void initState() {
    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);

    _circleVideoBloc = CircleVideoBloc(_globalEventBloc!);

    _globalEventBloc!.progressIndicator.listen((circleObject) {
      if (mounted) {
        try {
          if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
            int index = _circleObjects
                .indexWhere((param) => param.seed == circleObject.seed);

            if (index >= 0) {
              setState(() {
                debugPrint(circleObject.transferPercent.toString());
                if (circleObject.transferPercent == null ||
                    circleObject.transferPercent == 100) {
                  _removedObjects.add(_circleObjects[index]);
                  _circleObjects.removeAt(index);
                } else {
                  CircleObject old = _circleObjects[index];
                  circleObject.userCircleCache = old.userCircleCache;
                  circleObject.userFurnace = widget.userFurnaces!.firstWhere(
                      (element) =>
                          element.pk ==
                          circleObject.userCircleCache!.userFurnace);

                  _circleObjects[index] =
                      circleObject; //.video.transferPercent =
                }
              });
            } else {
              setState(() {
                if (!_removedObjects.contains(circleObject)) {
                  if (circleObject.userCircleCache != null &&
                      (circleObject.video!.videoState ==
                              VideoStateIC.UPLOADING_VIDEO ||
                          circleObject.video!.videoState ==
                              VideoStateIC.DOWNLOADING_VIDEO)) {
                    circleObject.userFurnace = widget.userFurnaces!.firstWhere(
                        (element) =>
                            element.pk ==
                            circleObject.userCircleCache!.userFurnace);
                    _circleObjects.add(circleObject);
                  }
                }
              });
            }
          }
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint(
              'TransferManager._globalEventBloc.progressIndicator.listen: $err');
        }
      }
    }, onError: (err) {
      debugPrint("TransferManager_InProgress.listen: $err");
    }, cancelOnError: false);

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  final spinkit = Padding(
      padding: const EdgeInsets.only(left: 150),
      child: SpinKitThreeBounce(
        size: 20,
        color: globalState.theme.threeBounce,
      ));

  ListTile makeListTile(int index, CircleObject circleObject) => ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        leading: Container(
          padding: const EdgeInsets.only(right: 12.0),
          decoration: BoxDecoration(
              border: Border(
                  right: BorderSide(
                      width: 1.0, color: globalState.theme.cardSeparator))),
          child: Icon(
              circleObject.video!.videoState == VideoStateIC.DOWNLOADING_VIDEO
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
              color: globalState.theme.cardLeadingIcon),
        ),
        title: Row(children: <Widget>[
          Expanded(
              child: Container(
            padding: const EdgeInsets.only(top: 0.0),
            child: Text(
              circleObject.body != null
                  ? circleObject.body!.isNotEmpty
                      ? circleObject.body!
                      : AppLocalizations.of(context)!.videoWord.toLowerCase()
                  : AppLocalizations.of(context)!.videoWord.toLowerCase(),
              textScaler: TextScaler.linear(globalState.cardScaleFactor),
              //circleObject.userFurnace.alias,
              style: TextStyle(
                color:
                    globalState.theme.cardTitle, /*fontWeight: FontWeight.bold*/
              ),
            ),
          )),
          Padding(
              padding: const EdgeInsets.only(right: 0),
              child: CircularPercentIndicator(
                radius: 30.0,
                lineWidth: 5.0,
                percent: (circleObject.transferPercent == null
                    ? 0
                    : circleObject.transferPercent! / 100),
                center: Text(
                    circleObject.transferPercent == null
                        ? '...'
                        : '${circleObject.transferPercent}%',
                    textScaler: const TextScaler.linear(1.0),
                    style: TextStyle(color: globalState.theme.progress)),
                progressColor: globalState.theme.progress,
              )),
        ]),
        subtitle: Column(children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                  flex: 0,
                  child: Padding(
                      padding:
                          const EdgeInsets.only(left: 5.0, bottom: 5, top: 10),
                      child: Text(
                        circleObject.userFurnace!.alias!,
                        textScaler: TextScaler.linear(globalState.cardScaleFactor),
                        style: TextStyle(color: globalState.theme.furnace),
                      ))),
              Expanded(
                  flex: 8,
                  child: Padding(
                      padding:
                          const EdgeInsets.only(left: 5.0, bottom: 5, top: 10),
                      child: Text(
                        circleObject.userCircleCache!.prefName!,
                        textScaler: TextScaler.linear(globalState.cardScaleFactor),
                        style: TextStyle(color: globalState.theme.cardSubTitle),
                      ))),
            ],
          ),
        ]),
        trailing: Icon(Icons.stop_circle_outlined,
            color: globalState.theme.menuIcons, size: 30.0),
        onTap: () {
          _cancelTransfer(circleObject);
        },
      );

  Card makeCard(
    int index,
    CircleObject circleObject,
  ) =>
      Card(
        surfaceTintColor: Colors.transparent,
        color: globalState.theme.card,
        elevation: 8.0,
        margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
        child: makeListTile(
          index,
          circleObject,
        ),
      );

  @override
  Widget build(BuildContext context) {
    /*
    Row makeRow(int index, CircleObject circleObject) =>
        Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
          circleObject.video!.videoState == VideoStateIC.UPLOADING_VIDEO ||
                  circleObject.video!.videoState == VideoStateIC.DOWNLOADING_VIDEO
              ? /*Expanded(
                  child: Row(
                  mainAxisSize: MainAxisSize.min,
                  //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  //crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                        child: Padding(
                            padding:
                                EdgeInsets.only(right: 0, bottom: 10, top: 0),
                            child: Text(
                              circleObject.userCircleCache == null
                                  ? ''
                                  : 'Circle: ' +
                                      circleObject.userCircleCache.prefName,
                              style: TextStyle(
                                  color: globalState.theme.buttonIcon),
                            ))),
                    Padding(
                        padding: EdgeInsets.only(right: 10, bottom: 10, top: 0),
                        child: Text(
                          circleObject.body == null ? '' : circleObject.body,
                          style: TextStyle(color: globalState.theme.buttonIcon),
                        )),
                    Padding(
                        padding: EdgeInsets.only(right: 0),
                        child: CircularPercentIndicator(
                          radius: 60.0,
                          lineWidth: 5.0,
                          percent: (circleObject.video.transferPercent == null
                              ? 0
                              : circleObject.video.transferPercent / 100),
                          center: Text(circleObject.video.transferPercent ==
                                  null
                              ? '...'
                              : circleObject.video.transferPercent.toString() +
                                  '%'),
                          progressColor: globalState.theme.progress,
                        )),
                    ClipOval(
                      child: Material(
                        color: globalState.theme.background, // button color
                        child: InkWell(
                          splashColor: globalState
                              .theme.buttonIconSplash, // inkwell color
                          child: SizedBox(
                              width: _iconSize,
                              height: _iconSize,
                              child: Icon(circleObject.video.videoState ==
                                      VideoStateIC.UPLOADING_VIDEO
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward)),
                          onTap: () {},
                        ),
                      ),
                    ),
                    ClipOval(
                      child: Material(
                        color: globalState.theme.background, // button color
                        child: InkWell(
                          splashColor: globalState
                              .theme.buttonIconSplash, // inkwell color
                          child: SizedBox(
                              width: _iconSize,
                              height: _iconSize,
                              child: Icon(Icons.remove_circle)),
                          onTap: () {
                            _cancelTransfer(circleObject);
                          },
                        ),
                      ),
                    ),
                  ],
                ))*/
              makeCard(index, circleObject)
              : ConstrainedBox(
                  constraints:
                      BoxConstraints(maxWidth: InsideConstants.MESSAGEBOXSIZE),
                  child: Padding(
                      padding: EdgeInsets.all(5.0),
                      child: Center(child: spinkit)
                      //  File(FileSystemServicewidget
                      //.circleObject.gif.giphy),
                      // ),
                      ),
                )
        ]);

     */

    final makeList = _circleObjects.isEmpty
        ? Expanded(
            flex: 0,
            child: Padding(
                padding: const EdgeInsets.only(
                  top: 20,
                  left: 10,
                  right: 10,
                ),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  ICText(AppLocalizations.of(context)!.noTransfers,
                      textScaleFactor: globalState.labelScaleFactor,
                      fontSize: 18,
                      color: globalState.theme.textTitle)
                ])))
        : Expanded(
            child: Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 5),
                child: Scrollbar(
                    controller: _scrollController,
                    //isAlwaysShown: true,
                    //scrollbarOrientation: ScrollbarOrientation.right,
                    child: ListView.separated(
                        // Let the ListView know how many items it needs to build
                        itemCount: _circleObjects.length,
                        //reverse: true,
                        //shrinkWrap: true,
                        //scrollDirection: Scro,
                        //controller: _scrollController,
                        //physics: const AlwaysScrollableScrollPhysics(),
                        //cacheExtent: 1500,
                        //addAutomaticKeepAlives: true,

                        separatorBuilder: (context, index) {
                          return Container(
                            color: globalState.theme.background,
                            height: 1,
                            width: double.maxFinite,
                          );
                        },
                        itemBuilder: (context, index) {
                          //debugPrint(index);
                          final CircleObject item = _circleObjects[index];

                          return makeCard(index, item);
                        }))));

    return Scaffold(
      backgroundColor: globalState.theme.background,
      key: _scaffoldKey,
      appBar: ICAppBar(
        title: AppLocalizations.of(context)!.transferManager,
      ),
      //drawer: NavigationDrawer(),
      body: Column(children: [makeList]),
    );
  }

  void _cancelTransfer(CircleObject circleObject) async {
    circleObject.video!.streamableCached = false;
    await _circleVideoBloc.cancelVideoTransfer(
        circleObject.userCircleCache!, circleObject);

    setState(() {
      _removedObjects.add(circleObject);
      _circleObjects.remove(circleObject);

      //debugPrint(_circleObjects.length);
    });
  }
/*
  void _showFullList(int index, CircleObject circleObject) async {
    CircleObject updatedObject = await Navigator.push(
        context,
        MaterialPageRoute(
          //builder: (context) => EditCircleList(
          builder: (context) => CircleListEdit(
            //imageProvider:
            //  const AssetImage("assets/large-image.jpg"),
            circleObject: circleObject,
            userCircleCache: circleObject.userCircleCache,
            userFurnace: circleObject.userFurnace,
            isNew: true,
          ),
        ));

    if (updatedObject != null) {
      setState(() {
        if (updatedObject.list.complete)
          _circleobjects.removeAt(index);
        else {
          updatedObject.userCircleCache = circleObject.userCircleCache;
          updatedObject.userFurnace = circleObject.userFurnace;
          _circleobjects[index] = updatedObject;
        }
      });
    }
  }

 */
}
