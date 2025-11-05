import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circlealbum_bloc.dart';
import 'package:ironcirclesapp/blocs/circlefile_bloc.dart';
import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/circlerecipe_bloc.dart';
import 'package:ironcirclesapp/blocs/circlevideo_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/videocontroller_bloc.dart';
import 'package:ironcirclesapp/blocs/videocontroller_desktop_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_determine_widget.dart';
import 'package:ironcirclesapp/screens/widgets/dialogyesno.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

///Purpose: This screen shows the user pinned posts for the specific Circle.
///User can select one, which will be returned to the calling screen

///This is a stateful class, meaning in can listen for events and refresh
class PinnedPosts extends StatefulWidget {
  final UserCircleCache userCircleCache;

  ///User's instance of the current Circle
  final UserFurnace userFurnace;

  ///The Furnace this Circle is connected to
  final CircleObjectBloc circleObjectBloc;

  ///The Furnace this Circle is connected to
  final Circle circle;

  ///Functions from calling widget
  final Function unpinObject;

  ///Objects/Functions that need to be passed through child widgets
  final List<User> userMessageColors;
  final VideoControllerBloc videoControllerBloc;
  final VideoControllerDesktopBloc videoControllerDesktopBloc;
  final CircleVideoBloc circleVideoBloc;
  final GlobalEventBloc globalEventBloc;
  final CircleImageBloc circleImageBloc;
  final CircleRecipeBloc circleRecipeBloc;
  final CircleAlbumBloc circleAlbumBloc;
  final CircleFileBloc circleFileBloc;
  final Function populateImageFile;
  final Function populateVideoFile;
  final Function populateRecipeImageFile;
  final Function populateFile;
  final Function populateAlbum;

  ///As much as possible going forward, don't allow nulls
  const PinnedPosts(
      {Key? key,
      required this.userCircleCache,
      required this.userFurnace,
      required this.circleObjectBloc,
      required this.circle,
      required this.userMessageColors,
      required this.videoControllerBloc,
      required this.videoControllerDesktopBloc,
      required this.globalEventBloc,
      required this.circleRecipeBloc,
      required this.circleImageBloc,
      required this.circleVideoBloc,
      required this.circleFileBloc,
      required this.circleAlbumBloc,
      required this.unpinObject,
      required this.populateImageFile,
      required this.populateVideoFile,
      required this.populateRecipeImageFile,
      required this.populateFile,
      required this.populateAlbum,})
      : super(key: key);

  @override
  _PinnedPostsState createState() => _PinnedPostsState();
}

///The state class that does all the work
class _PinnedPostsState extends State<PinnedPosts> {
  List<CircleObject> _circleObjects = [];
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  ///spinner
  //bool _showSpinner = true;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  ///This function is called before the screen renders.
  ///It does not support await statements so the screen doesn't pause
  ///Instead, we subscribe to a stream, call getPinnedPost, and listen for the results.
  @override
  void initState() {
    ///make sure we call widget's own initState
    super.initState();

    ///subscribe to stream that listens for pinned objects to be pulled from SQLLite
    ///
    widget.circleObjectBloc.pinnedObjects.listen((objects) {
      ///always make sure the screen is visible before calling setState
      if (mounted) {
        ///setState causes the screen to refresh
        setState(() {
          _circleObjects = objects.toList();
        });
      }
    }, onError: (err, trace) {
      LogBloc.insertError(err, trace);
    }, cancelOnError: false);

    ///call the function that will stream the results back (to the listener above)
    widget.circleObjectBloc
        .getPinnedPosts(widget.userFurnace, widget.userCircleCache);
  }

  @override
  Widget build(BuildContext context) {
    double maxWidth =
        InsideConstants.getCircleObjectSize(MediaQuery.of(context).size.width);

    ///show an empty container until the results are loaded async
    final _body = _circleObjects.isNotEmpty
        ? ScrollablePositionedList.separated(
            itemScrollController: _itemScrollController,
            itemPositionsListener: _itemPositionsListener,
            separatorBuilder: (context, index) {
              return Divider(
                height: 10,
                color: globalState.theme.background,
              );
            },
            //reverse: true,
            //shrinkWrap: true,
            itemCount: _circleObjects.length,
            itemBuilder: (BuildContext context, int index) {
              //var row = _circleObjects[index];

              try {
                return InsideCircleDetermineWidget(
                  members: globalState.members,
                  interactive: false,
                  reverse: false,
                  userCircleCache: widget.userCircleCache,
                  userFurnace: widget.userFurnace,
                  circleObjects: _circleObjects,
                  index: index,
                  refresh: _doNothing,
                  circle: widget.circle,
                  tapHandler: _tapHandler,
                  shareObject: _doNothing,
                  unpinObject: _unpinObject,
                  openExternalBrowser: _doNothing,
                  leave: _doNothing,
                  export: _doNothing,
                  cancelTransfer: _doNothing,
                  longPressHandler: _doNothing,
                  longReaction: _doNothing,
                  shortReaction: _doNothing,
                  storePosition: _doNothing,
                  copyObject: _doNothing,
                  reactionAdded: _doNothing,
                  showReactions: _doNothing,
                  videoControllerBloc: widget.videoControllerBloc,
                  videoControllerDesktopBloc: widget.videoControllerDesktopBloc,
                  globalEventBloc: widget.globalEventBloc,
                  circleRecipeBloc: widget.circleRecipeBloc,
                  circleObjectBloc: widget.circleObjectBloc,
                  circleImageBloc: widget.circleImageBloc,
                  circleVideoBloc: widget.circleVideoBloc,
                  circleFileBloc: widget.circleFileBloc,
                  circleAlbumBloc: widget.circleAlbumBloc,
                  updateList: _doNothing,
                  submitVote: _doNothing,
                  displayReactionsRow: false,
                  deleteObject: _doNothing,
                  editObject: _doNothing,
                  streamVideo: _doNothing,
                  downloadVideo: _doNothing,
                  downloadFile: _doNothing,
                  retry: _doNothing,
                  predispose: _doNothing,
                  playVideo: _tapHandler,
                  removeCache: _doNothing,
                  populateFile: widget.populateFile,
                  populateVideoFile: widget.populateVideoFile,
                  populateRecipeImageFile: widget.populateRecipeImageFile,
                  populateImageFile: widget.populateImageFile,
                  populateAlbum: widget.populateAlbum,
                  maxWidth: maxWidth,
                );
              } catch (err, trace) {
                LogBloc.insertError(err, trace);
                return Expanded(child: spinkit);
              }
            })
        : Container();

    ///Structure of the screen. In this case, an appBar (with a back button) and a body section
    return Scaffold(
      appBar: ICAppBar(title: AppLocalizations.of(context)!.pinnedPosts),
      backgroundColor: globalState.theme.background,
      body: Padding(
          padding: const EdgeInsets.only(left: 10, right: 0, bottom: 5, top: 0),
          child: WrapperWidget(child:Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(child: _body),
            ],
          ))),
    );
  }

  _doNothing(CircleObject circleObject) {}

  _tapHandler(CircleObject circleObject) {
    Navigator.pop(context, circleObject);
  }

  _unpinObject(CircleObject circleObject) async {
    FocusScope.of(context).unfocus();
    await DialogYesNo.askYesNo(
        context,
        AppLocalizations.of(context)!.removePinTitle,
        AppLocalizations.of(context)!.removePinMessage,
        _unpinObjectConfirmed,
        null,
        false,
        circleObject);
  }

  _unpinObjectConfirmed(CircleObject circleObject) {
    _circleObjects.remove(circleObject);

    widget.unpinObject(circleObject);
    setState(() {});
  }
}
