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
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class LocalSearch extends StatefulWidget {
  final UserCircleCache userCircleCache;
  final UserFurnace userFurnace;
  final String? type;

  ///The Furnace this Circle is connected to
  final CircleObjectBloc circleObjectBloc;

  ///The Furnace this Circle is connected to
  final Circle circle;

  ///Functions from calling widget
  final Function unpinObject;

  ///Objects/Functions that need to be passed through child widgets
  final List<User?> userMessageColors;
  final VideoControllerBloc videoControllerBloc;
  final VideoControllerDesktopBloc videoControllerDesktopBloc;
  final CircleVideoBloc circleVideoBloc;
  final GlobalEventBloc globalEventBloc;
  final CircleImageBloc circleImageBloc;
  final CircleRecipeBloc circleRecipeBloc;
  final CircleAlbumBloc circleAlbumBloc;
  final Function populateImageFile;
  final Function populateVideoFile;
  final Function populateRecipeImageFile;
  final Function populateAlbum;
  final String searchText;

  final CircleFileBloc circleFileBloc;
  final Function populateFile;

  const LocalSearch({
    Key? key,
    this.type,
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
    required this.circleAlbumBloc,
    required this.circleVideoBloc,
    required this.unpinObject,
    required this.populateImageFile,
    required this.populateVideoFile,
    required this.populateRecipeImageFile,
    required this.searchText,
    required this.circleFileBloc,
    required this.populateFile,
    required this.populateAlbum,
  }) : super(key: key);

  @override
  _LocalSearch createState() => _LocalSearch();
}

class _LocalSearch extends State<LocalSearch> {
  //ScrollController _scrollController = ScrollController();
  List<CircleObject> _circleObjects = [];
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  //ScrollController _scrollController = ScrollController();

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchtext = TextEditingController();

  ///spinner
  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  bool header = false;
  int counter = 1;

  @override
  void initState() {
    super.initState();

    ///subscribe to stream that listens for pinned objects to be pulled from SQLLite
    ///
    widget.circleObjectBloc.searchedObjects.listen((objects) {
      ///always make sure the screen is visible before calling setState
      if (mounted) {
        ///setState causes the screen to refresh
        setState(() {
          _circleObjects = objects.reversed.toList();
          _showSpinner = false;
        });
      }
    }, onError: (err, trace) {
      LogBloc.insertError(err, trace);
    }, cancelOnError: false);
  }

  @override
  void dispose() {
    super.dispose();
  }

  _searchAction(String searchText) async {
    widget.circleObjectBloc.search(widget.type, widget.userFurnace,
        widget.userCircleCache, _searchtext.text);
    setState(() {
      _showSpinner = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    double maxWidth =
        InsideConstants.getCircleObjectSize(MediaQuery.of(context).size.width);

    ///show an empty container until the results are loaded async
    final _searchResults = _showSpinner == true
      ? spinkit
      : _circleObjects.isNotEmpty
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
                  playVideo: _doNothing,
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
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
            child: Text(AppLocalizations.of(context)!.noResults,
                style: ICTextStyle.getStyle(context: context, 
                    color: globalState.theme.buttonDisabled, fontSize: 14)));

    final _makeBody = WrapperWidget(child: Column(children: [
      Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: Row(children: <Widget>[
          Expanded(
            flex: 20,
            child: FormattedText(
              // hintText: 'enter a username',
              labelText: AppLocalizations.of(context)!.whatDoYouWantToSearchFor, //'What do you want to search for?',
              controller: _searchtext,
            ),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Expanded(
            flex: globalState.isDesktop() ? 0 : 1,
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: ScreenSizes.getMaxButtonWidth(MediaQuery.of(context).size.width, true)),
                // margin: EdgeInsets.symmetric(
                //     horizontal:
                //         ButtonType.getWidth(MediaQuery.of(context).size.width)),
                child: GradientButton(
                  text: AppLocalizations.of(context)!.search2, //'Search',
                  onPressed: () {
                    _searchAction(_searchtext.text);
                  },
                )),
          ),
        ]),
      ),
      Expanded(child: _searchResults),
    ]));

    return Scaffold(
        backgroundColor: globalState.theme.background,
        key: _scaffoldKey,
        appBar: ICAppBar(title: AppLocalizations.of(context)!.search2), //'Search'),
        body: SafeArea(
            left: false,
            top: false,
            right: false,
            bottom: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(child: _makeBody),
              ],
            )));
  }

  _doNothing() {}

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
        null, false,
        circleObject);
  }

  _unpinObjectConfirmed(CircleObject circleObject) {
    _circleObjects.remove(circleObject);

    widget.unpinObject(circleObject);
    setState(() {});
  }


}
