import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/circlealbum_bloc.dart';
import 'package:ironcirclesapp/blocs/circlefile_bloc.dart';
import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/circlerecipe_bloc.dart';
import 'package:ironcirclesapp/blocs/circlevideo_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/videocontroller_bloc.dart';
import 'package:ironcirclesapp/blocs/videocontroller_desktop_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/localsearch.dart';
import 'package:ironcirclesapp/screens/utilities/populatemedia.dart';
import 'package:ironcirclesapp/screens/utilities/sharecircleobject.dart';
import 'package:ironcirclesapp/screens/walkthroughs/insidecircle_walkthrough.dart';
import 'package:ironcirclesapp/screens/widgets/backwithdoticon.dart';
import 'package:ironcirclesapp/screens/widgets/centralcalendar.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class CalendarHolder extends StatefulWidget {
  final UserFurnace userFurnace;
  final List<CircleObject> circleObjects;
  final GlobalEventBloc globalEventBloc;
  final UserCircleCache userCircleCache;
  final CircleObjectBloc circleObjectBloc;
  final CircleFileBloc circleFileBloc;
  final Function unpinObject;
  final CircleRecipeBloc circleRecipeBloc;
  final CircleImageBloc circleImageBloc;
  final CircleVideoBloc circleVideoBloc;
  final CircleAlbumBloc circleAlbumBloc;
  final VideoControllerBloc videoControllerBloc;
  final VideoControllerDesktopBloc videoControllerDesktopBloc;

  const CalendarHolder({
    Key? key,
    required this.userFurnace,
    required this.circleObjects,
    required this.globalEventBloc,
    required this.userCircleCache,
    required this.circleObjectBloc,
    required this.unpinObject,
    required this.circleRecipeBloc,
    required this.circleFileBloc,
    required this.circleImageBloc,
    required this.circleAlbumBloc,
    required this.circleVideoBloc,
    required this.videoControllerBloc,
    required this.videoControllerDesktopBloc,
  }) : super(key: key);

  @override
  CalendarHolderState createState() => CalendarHolderState();
}

class CalendarHolderState extends State<CalendarHolder> {
  final double _floatingActionSize = 55;
  final double _iconSize = 31;
  late InsideCircleWalkthrough _insideCircleWalkthrough;
  bool _toggleIcons = false;
  CircleObject? _selected;
  final double _iconPadding = 12;

  @override
  void initState() {
    super.initState();
    _insideCircleWalkthrough = InsideCircleWalkthrough(_finish);
  }

  @override
  Widget build(BuildContext context) {
    _openLocalSearch() async {
      CircleObject? circleObject = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => LocalSearch(
                  type: "Events",
                  //mode: widget.displayType,
                  userCircleCache: widget.userCircleCache,
                  userFurnace: widget.userFurnace,
                  circleObjectBloc: widget.circleObjectBloc,
                  userMessageColors: [widget.userFurnace.user], //members
                  circle: widget.userCircleCache.cachedCircle!, //_circle
                  videoControllerBloc: widget.videoControllerBloc,
                  videoControllerDesktopBloc:  widget.videoControllerDesktopBloc,
                  globalEventBloc: widget.globalEventBloc,
                  circleVideoBloc: widget.circleVideoBloc,
                  circleImageBloc: widget.circleImageBloc,
                  circleRecipeBloc: widget.circleRecipeBloc,
                  circleFileBloc: widget.circleFileBloc,
                  circleAlbumBloc: widget.circleAlbumBloc,
                  unpinObject: widget.unpinObject,
                  populateFile: PopulateMedia.populateFile,
                  populateImageFile: PopulateMedia.populateImageFile,
                  populateVideoFile: PopulateMedia.populateVideoFile,
                  populateAlbum: PopulateMedia.populateAlbum,
                  populateRecipeImageFile:
                      PopulateMedia.populateRecipeImageFile,
                  searchText: "test")));

      if (circleObject != null) {
        int index = widget.circleObjects
            .indexWhere((element) => element.seed == circleObject.seed);

        //if (index >= 0) _scrollToIndex(index);
      }
    }

    return Scaffold(
        appBar: AppBar(
            elevation: 0,
            toolbarHeight: 45,
            centerTitle: false,
            titleSpacing: 0.0,
            backgroundColor: globalState.theme.background,
            title: Text("Calendar",
                style: ICTextStyle.getStyle(context: context, 
                    color: globalState.theme.textTitle,
                    fontSize: ICTextStyle.appBarFontSize)),
            leading: BackWithDotIcon(
              userFurnaces: [widget.userFurnace],
              goHome: () {
                _goHome(true);
              },
              forceRefresh: false,
              circleID: widget.userCircleCache.circle!,
            ),
            actions: <Widget>[
              IconButton(
                  key: _insideCircleWalkthrough.keyButton7,
                  icon: Icon(Icons.search, color: globalState.theme.menuIcons),
                  onPressed: _openLocalSearch),
            ]),
        backgroundColor: globalState.theme.background,
        body: Padding(
            padding: const EdgeInsets.only(left: 5, right: 5, bottom: 5),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  _toggleIcons
                      ? Row(
                          children: [
                            IconButton(
                              color: globalState.theme.background,
                              onPressed: () {
                                setState(() {
                                  _selected = null;
                                  _toggleIcons = false;
                                });
                              },
                              icon: Icon(
                                Icons.cancel,
                                color: globalState.theme.buttonIcon,
                              ),
                            ),
                            const Spacer(),
                            Padding(
                                padding: EdgeInsets.only(left: _iconPadding),
                                child: InkWell(
                                    onTap: () {
                                      _askToDelete(_selected!);
                                    },
                                    child: Icon(Icons.delete,
                                        color: globalState.theme.buttonIcon))),
                            Padding(
                                padding: EdgeInsets.only(left: _iconPadding),
                                child: InkWell(
                                    onTap: () {
                                      ShareCircleObject.shareToDestination(
                                          context,
                                          widget.userCircleCache,
                                          _selected!,
                                          true);
                                    },
                                    child: Icon(Icons.share,
                                        size: _iconSize,
                                        color: globalState.theme.buttonIcon))),
                          ],
                        )
                      : Container(),
                  Expanded(
                      child: CentralCalendar(
                    calendarType: "vault",
                    screenMode: CalendarMode.create,
                    userCircleCache: widget.userCircleCache,
                    circleObjectBloc: widget.circleObjectBloc,
                    userFurnace: widget.userFurnace,
                    userFurnaces: [widget.userFurnace],
                    longPress: _longPress,
                    replyObject: null,
                    selected: _selected,
                  )),
                ])));
  }

  _shortPress(CircleObject circleObject, Circle? circle) {
    if (_toggleIcons) {
      if (circleObject == _selected) {
        setState(() {
          _selected = null;
          _toggleIcons = false;
        });
      } else if (circleObject != _selected) {
        setState(() {
          _selected = circleObject;
        });
      }
    }
    // else if (_toggleIcons == false) {
    //   LaunchURLs.openExternalBrowser(context, circleObject);
    // }
  }

  _longPress(CircleObject circleObject) {
    setState(() {
      if (_toggleIcons) {
        _selected = null;
        _toggleIcons = false;
      } else {
        _selected = circleObject;
        _toggleIcons = !_toggleIcons;
      }
    });
  }

  void delete(CircleObject object) {
    widget.circleObjectBloc
        .deleteCircleObject(widget.userCircleCache, widget.userFurnace, object);
    setState(() {
      //_circleObjects.remove(circleObject);
      widget.circleObjects.remove(object);
      _toggleIcons = false;
      _selected = null;
    });
  }

  void _askToDelete(CircleObject object) async {
    DialogYesNo.askYesNo(
        context,
        AppLocalizations.of(context)!.confirmDeleteTitle,
        AppLocalizations.of(context)!.confirmDeleteMessage,
        delete,
        null, false,
        object);
  }

  void _finish() {
    //_circlesWalkthrough.tutorialCoachMark.show(context: context);
  }

  _goHome(bool samePosition) async {
    debugPrint('***********POPPED****************');
    Navigator.pop(context);
    //widget.refresh();
  }

}
