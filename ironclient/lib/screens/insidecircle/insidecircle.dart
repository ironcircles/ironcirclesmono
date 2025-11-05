import 'dart:async';
import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
//import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' as intl;
import 'package:ironcirclesapp/blocs/circle_bloc.dart';
import 'package:ironcirclesapp/blocs/circlealbum_bloc.dart';
import 'package:ironcirclesapp/blocs/circleevent_bloc.dart';
import 'package:ironcirclesapp/blocs/circlefile_bloc.dart';
import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
import 'package:ironcirclesapp/blocs/circlelist_bloc.dart';
import 'package:ironcirclesapp/blocs/circlemedia_bloc.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/circlerecipe_bloc.dart';
import 'package:ironcirclesapp/blocs/circlevideo_bloc.dart';
import 'package:ironcirclesapp/blocs/circlevote_bloc.dart';
import 'package:ironcirclesapp/blocs/emojiusage_bloc.dart';
import 'package:ironcirclesapp/blocs/firebase_bloc.dart';
import 'package:ironcirclesapp/blocs/giphy_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/member_bloc.dart';
import 'package:ironcirclesapp/blocs/replyobject_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/blocs/videocontroller_bloc.dart';
import 'package:ironcirclesapp/blocs/videocontroller_desktop_bloc.dart';
import 'package:ironcirclesapp/encryption/encryptblob.dart';
import 'package:ironcirclesapp/models/album_item.dart';
import 'package:ironcirclesapp/models/backgroundtask.dart';
import 'package:ironcirclesapp/models/circleobjectreaction.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/replyobject.dart';
import 'package:ironcirclesapp/models/stablediffusionprompt.dart';
import 'package:ironcirclesapp/models/violation.dart';
import 'package:ironcirclesapp/screens/circles/home.dart';
import 'package:ironcirclesapp/screens/fullscreen/fullscreengalleryswiper.dart';
import 'package:ironcirclesapp/screens/fullscreen/fullscreenimage.dart';
import 'package:ironcirclesapp/screens/fullscreen/fullscreenmessage.dart';
import 'package:ironcirclesapp/screens/fullscreen/pdfviewer.dart';
import 'package:ironcirclesapp/screens/insidecircle/bottomsheet_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/capturemedia.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circlealbumscreen.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circleevent_detail.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circlelist_edit_tabs.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circlelist_new.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circlerecipescreen.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circlevote_new.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circlevotes_edit.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/imagepreviewer.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/report_post.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/select_thumbnail.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/selectgif.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/subtype_credential.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/subtype_creditcard.dart';
import 'package:ironcirclesapp/screens/insidecircle/circlesettings.dart';
import 'package:ironcirclesapp/screens/insidecircle/dialoghandlefile.dart';
import 'package:ironcirclesapp/screens/insidecircle/dialogpinpost.dart';
import 'package:ironcirclesapp/screens/insidecircle/dialogshareto.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_determine_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/giphypreviewsingle.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/imagespreviewscroller.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidevault_determine_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidevault_widgets/gallery_holder.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidevault_widgets/vault_object_display.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidewall_determine_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidewall_widgets/wallrepliesscreen.dart';
import 'package:ironcirclesapp/screens/insidecircle/localsearch.dart';
import 'package:ironcirclesapp/screens/insidecircle/members.dart';
import 'package:ironcirclesapp/screens/insidecircle/pinnedposts.dart';
import 'package:ironcirclesapp/screens/insidecircle/processcircleobjectevents.dart';
import 'package:ironcirclesapp/screens/invitations/network_invite.dart';
import 'package:ironcirclesapp/screens/payment/premiumfeaturecheck.dart';
import 'package:ironcirclesapp/screens/stablediffusion/stablediffusion_generate.dart';
import 'package:ironcirclesapp/screens/utilities/populatemedia.dart';
import 'package:ironcirclesapp/screens/utilities/setcirclebackground.dart';
import 'package:ironcirclesapp/screens/utilities/sharecircleobject.dart';
import 'package:ironcirclesapp/screens/walkthroughs/insidecircle_walkthrough.dart';
import 'package:ironcirclesapp/screens/widgets/InsideCirclePostWidget.dart';
import 'package:ironcirclesapp/screens/widgets/backwithdoticon.dart';
import 'package:ironcirclesapp/screens/widgets/dialogcaching.dart';
import 'package:ironcirclesapp/screens/widgets/dialogdownload.dart';
import 'package:ironcirclesapp/screens/widgets/dialogfirsttimeincircle.dart';
import 'package:ironcirclesapp/screens/widgets/dialogfirsttimeinfeed.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/dialogprivatevaultprompt.dart';
import 'package:ironcirclesapp/screens/widgets/dialogselectnetwork.dart';
import 'package:ironcirclesapp/screens/widgets/dialogsetfontsize.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';
import 'package:ironcirclesapp/screens/widgets/pickers.dart';
import 'package:ironcirclesapp/screens/widgets/reactions/dialogreactions.dart';
import 'package:ironcirclesapp/screens/widgets/reactions/long_press_menu.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/services/cache/filecache_service.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
import 'package:ironcirclesapp/services/cache/table_circlecache.dart';
import 'package:ironcirclesapp/services/cache/videocache_service.dart';
import 'package:ironcirclesapp/services/tenor_service.dart';
import 'package:ironcirclesapp/utils/emojiutil.dart';
import 'package:ironcirclesapp/utils/launchurls.dart';
import 'package:ironcirclesapp/utils/permissions.dart';
import 'package:mime/mime.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:ironcirclesapp/screens/insidecircle/agora.dart';

class InsideCircle extends StatefulWidget {
  final UserCircleCache userCircleCache;
  final List<UserCircleCache> wallUserCircleCaches;
  final UserFurnace userFurnace;
  final List<UserFurnace>? userFurnaces;
  final List<UserFurnace> wallFurnaces;
  final bool? hiddenOpen;
  // final MediaCollection? sharedMediaCollection;
  // final File? sharedVideo;
  // final String? sharedText;
  // final GiphyOption? sharedGif;
  final Function? refresh;
  final Function? markRead;
  final Function? dismissByCircle;
  final Member? dmMember;
  final Function? resetDesktopUI;
  final bool wall;
  final SharedMediaHolder? sharedMediaHolder;
  final List<CircleObject> memCacheObjects;
  final List<ReplyObject> replyObjects;

  const InsideCircle({
    Key? key,
    required this.userCircleCache,
    required this.userFurnace,
    this.hiddenOpen,
    this.userFurnaces,
    this.wallFurnaces = const [],
    required this.memCacheObjects,
    required this.replyObjects,
    this.sharedMediaHolder,
    this.resetDesktopUI,
    // this.sharedMediaCollection,
    // this.sharedVideo,
    // this.sharedText,
    this.refresh,
    this.markRead,
    this.dismissByCircle,
    this.wall = false,
    // this.sharedGif,
    this.wallUserCircleCaches = const [],
    this.dmMember,
  }) : super(key: key);

  @override
  InsideCircleState createState() => InsideCircleState();
}

class InsideCircleState extends State<InsideCircle> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  final List<UserFurnace> _selectedNetworks = [];
  List<CircleObject> reactionObjects = [];
  List<UserCircleCache> wallCircles = [];
  bool _thereAreNoOlderPosts = false;

  String memberSearch = "";
  bool memberSearchBegin = false;
  List<Member> membersFiltered = [];
  String clickedMember = "";
  List<Member> messageMembers = [];

  /// get current cursor position
  int currentIndex = 0;

  /// get text from start to cursor
  String textChunk = "";

  /// trim to text from @ to cursor
  int whereTag = 0;
  String typingTag = "";
  List<Member> oldMembersFiltered = [];
  List<User> taggedUsers = [];

  final ImagePicker _picker = ImagePicker();
  int _previewIndex = -1;
  final VideoControllerBloc _videoControllerBloc = VideoControllerBloc();
  final VideoControllerDesktopBloc _videoControllerDesktopBloc =
      VideoControllerDesktopBloc();
  final VideoControllerBloc _previewControllerBloc = VideoControllerBloc();
  late FirebaseBloc _firebaseBloc;

  List<User> members = [];

  //List<String?> _emojiUsage =[];
  final EmojiUsageBloc _emojiUsageBloc = EmojiUsageBloc();
  int? _thumbnailFrame;

  late InsideCircleWalkthrough _insideCircleWalkthrough;

  //GIPHY
  final GiphyBloc _giphyBloc = GiphyBloc();

  //bool _giphyPreview = false;
  bool _showEmojiPicker = false;
  CircleObject? _editingObject;
  CircleObject? _lastSelected;
  CircleObject? _lastVideoPlayed;
  CircleObject? _replyObject;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final CircleBloc _circleBloc = CircleBloc();
  late CircleObjectBloc _circleObjectBloc;
  late CircleImageBloc _circleImageBloc;
  late CircleMediaBloc _circleMediaBloc;
  late UserCircleBloc _userCircleBloc;
  final CircleVoteBloc _voteBloc = CircleVoteBloc();
  final CircleListBloc _circleListBloc = CircleListBloc();
  final CircleEventBloc _circleEventBloc = CircleEventBloc();
  final MemberBloc _memberBloc = MemberBloc();
  late CircleAlbumBloc _circleAlbumBloc;
  late ReplyObjectBloc _replyObjectBloc;

  late CircleRecipeBloc _circleRecipeBloc;
  late GlobalEventBloc _globalEventBloc;
  late CircleVideoBloc _circleVideoBloc;
  late CircleFileBloc _circleFileBloc;

  //MemberBloc _memberBloc = MemberBloc();

  List<CircleObject> _circleObjects = [];
  List<Member> _members = [];
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  final _message = TextEditingController();
  bool _sendEnabled = false;
  bool _membersList = false;
  String? _currentCircle;
  late Circle _circle;

  File? _video;
  File? _photo;
  File? _image;
  MediaCollection? _mediaCollection;
  MediaCollection _keyboardMediaCollection = MediaCollection();
  bool _hiRes = false;
  bool _streamable = false;

  bool _photoPreview = false;
  bool _imagePreview = false;
  bool _videoPreview = false;
  bool _videoStreamOnly = false;
  bool _refreshEnabled = true;
  bool _forceRefresh = false;
  bool _popping = false;
  bool _editing = false;
  bool _orientationNeeded = false;

  List<bool>? _videoStreamable = [true, false];
  final List<bool> _album = [true, false];

  late FocusNode _focusNode; // = FocusNode();
  GiphyOption? _giphyOption;
  int _loadCount = 1;
  int _spinMax = 0;

  bool _showJumpToDateSpinner = false;
  DateTime? _jumpToDate;
  StreamSubscription<SuppressNotification>? _suppressNotifications;
  StreamSubscription<String?>? _circleEventStream;

  MediaCollection? _sharedMedia;
  MediaCollection? _alreadySharedMedia;
  File? _sharedVideo;
  String? _sharedText;
  GiphyOption? _sharedGif;

  DateTime? _scheduledDate;
  DateTime? _lastScheduled;
  int? _increment;

  bool _scrollingDown = false;
  int _lastIndex = 0;
  bool _showTextField = true;
  bool _firstTimeLoadComplete = false;

  final _emojiController = TextEditingController();
  bool _emojiShowing = false;
  CircleObject? _reactingTo;
  bool _postedEmoji = false;

  double _maxWidth = 0;

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(color: globalState.theme.spinner, size: 60);

  final separator = Container(
    color: globalState.theme.background,
    height: 1,
    width: double.maxFinite,
  );

  final List<CircleObject> _waitingOnScroller = [];
  final List<String> _choices = [];

  _setupMenu() {
    if (_choices.isEmpty) {
      if (_circle.type == CircleType.VAULT) {
        _choices.add(AppLocalizations.of(context)!.vaultSettings);
        _choices.add(AppLocalizations.of(context)!.fontSize);
        _choices.add(AppLocalizations.of(context)!.pinnedPosts);
        _choices.add(AppLocalizations.of(context)!.jumpToDate);
      } else if (_circle.dm) {
        _choices.add(AppLocalizations.of(context)!.dmSettings);
        _choices.add(AppLocalizations.of(context)!.pinnedPosts);
        _choices.add(AppLocalizations.of(context)!.jumpToDate);
        _choices.add(AppLocalizations.of(context)!.fontSize);
      } else {
        _choices.add(AppLocalizations.of(context)!.circleMembers);
        _choices.add(AppLocalizations.of(context)!.circleSettings);
        _choices.add(AppLocalizations.of(context)!.pinnedPosts);
        _choices.add(AppLocalizations.of(context)!.jumpToDate);
        _choices.add(AppLocalizations.of(context)!.fontSize);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    globalState.forcedOrder.clear();

    //print(widget.wallFurnaces.length);

    try {
      ///init variables for the calendar
      DateTime _today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );

      _setEventDateTime(
        DateTime(
          _today.year,
          _today.month,
          _today.day,
          DateTime.now().hour + 1,
        ),
        DateTime(
          _today.year,
          _today.month,
          _today.day,
          DateTime.now().hour + 2,
        ),
      );

      globalState.setAppPath();

      _emojiController.addListener(() {
        if (_emojiController.text.isNotEmpty) {
          debugPrint(_emojiController.text);
          _emojiReaction(_emojiController.text, _reactingTo);
          setState(() {
            _emojiController.text = '';
          });
        }
      });

      _insideCircleWalkthrough = InsideCircleWalkthrough(_finish);
      _focusNode = FocusNode(
        onKeyEvent: (node, event) {
          // Check if 'V' key is pressed
          bool isVKeyPressed = (event.physicalKey == PhysicalKeyboardKey.keyV);

          // Check if 'Ctrl' or 'Meta' key is pressed
          bool isCtrlOrMetaPressed = HardwareKeyboard
              .instance
              .physicalKeysPressed
              .any(
                (key) =>
                    key == PhysicalKeyboardKey.controlLeft ||
                    key == PhysicalKeyboardKey.controlRight ||
                    key == PhysicalKeyboardKey.metaLeft ||
                    key == PhysicalKeyboardKey.metaRight,
              );

          if (isVKeyPressed && isCtrlOrMetaPressed) {
            _pasteImage();
          }
          return KeyEventResult.ignored;
        },
      );

      if (widget.sharedMediaHolder != null) {
        _sharedGif = widget.sharedMediaHolder!.sharedGif;
        _sharedMedia = widget.sharedMediaHolder!.sharedMedia;
        _sharedText = widget.sharedMediaHolder!.sharedText;
        _sharedVideo = widget.sharedMediaHolder!.sharedVideo;
        widget.sharedMediaHolder!.clear();
      }

      _circle = widget.userCircleCache.cachedCircle!;
      _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
      _circleObjectBloc = CircleObjectBloc(globalEventBloc: _globalEventBloc);
      _userCircleBloc = UserCircleBloc(globalEventBloc: _globalEventBloc);
      _circleImageBloc = CircleImageBloc(_globalEventBloc);
      _circleVideoBloc = CircleVideoBloc(_globalEventBloc);
      _circleFileBloc = CircleFileBloc(_globalEventBloc);
      _circleRecipeBloc = CircleRecipeBloc(_globalEventBloc);
      _circleAlbumBloc = CircleAlbumBloc(_globalEventBloc);
      _replyObjectBloc = ReplyObjectBloc(
        globalEventBloc: _globalEventBloc,
        userCircleBloc: _userCircleBloc,
      );
      _circleMediaBloc = CircleMediaBloc(
        circleImageBloc: _circleImageBloc,
        circleVideoBloc: _circleVideoBloc,
        circleFileBloc: _circleFileBloc,
      );

      _currentCircle = widget.userCircleCache.circle;

      _circle.type == CircleType.OWNER
          ? widget.userFurnace.userid ==
                      widget.userCircleCache.cachedCircle!.owner ||
                  _circle.toggleMemberPosting == true
              ? _showTextField //textField
              : _showTextField =
                  false //Container()
          : _showTextField = true; //textField,

      listen(context);

      _itemPositionsListener.itemPositions.addListener(() {
        _calculateDirection();
      });

      _initialLoad();
    } catch (err, trace) {
      LogBloc.postLog(err.toString(), 'InsideCircle.initState');
    }
  }

  _initialLoad() {
    ///request items from blocs
    if (widget.wall) {
      _circleObjectBloc.initialLoadForWall(
        widget.wallFurnaces,
        widget.wallUserCircleCaches,
      );

      _memberBloc.getConnectedMembers(
        widget.wallFurnaces,
        widget.wallUserCircleCaches,
        removeDM: false,
        excludeOwnerCircles: false,
      );
    } else {
      _circleObjectBloc.initialLoad(
        _currentCircle,
        widget.userFurnace,
        widget.userCircleCache,
        true,
        sinkTwice: true,
        isVault: _circle.type == CircleType.VAULT,
      );

      _memberBloc.getConnectedMembers(
        [widget.userFurnace],
        [widget.userCircleCache],
        removeDM: false,
        excludeOwnerCircles: false,
      );
    }
  }

  void _disposeControllers(CircleObject circleObject) {
    _predispose(circleObject);

    _videoControllerBloc.pauseLast();

    _videoControllerBloc.predispose(circleObject);
    setState(() {
      _lastVideoPlayed!.video!.videoState = VideoStateIC.NEEDS_CHEWIE;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _videoControllerBloc.disposeObject(circleObject);
    });

    _lastVideoPlayed = null;
  }

  void _predispose(CircleObject circleObject) {
    if (circleObject.video!.videoState == VideoStateIC.VIDEO_READY) {
      _videoControllerBloc.predispose(circleObject);
      setState(() {
        circleObject.video!.videoState = VideoStateIC.NEEDS_CHEWIE;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _circleObjectBloc.dispose();
    _message.dispose();
    _giphyBloc.dispose();
    _emojiUsageBloc.dispose();
    _userCircleBloc.dispose();
    _voteBloc.dispose();
    _circleListBloc.dispose();

    applicationStateChangedStream?.cancel();
    _suppressNotifications?.cancel();
    _circleEventStream?.cancel();
    progressThumbnailIndicatorStream?.cancel();
    previewDownloadedStream?.cancel();
    circleObjectBroadcastStream?.cancel();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _videoControllerBloc.disposeLast();
      _previewControllerBloc.disposeLast();
    });

    super.dispose();
  }

  _clearSpinner() {
    _showSpinner = false;
    _loadCount = 1;
    _spinMax = 0;
  }

  _checkSpinner() {
    if (_loadCount < _spinMax)
      _loadCount++;
    else {
      _clearSpinner();
    }
  }

  double _height = 0;
  double _width = 0;

  @override
  Widget build(BuildContext context) {
    _setupMenu();

    _height = MediaQuery.of(context).size.height;
    _width = MediaQuery.of(context).size.width;

    double screenWidth = globalState.setScaler(
      _width - 10,
      mediaScaler: MediaQuery.textScalerOf(context),
    );

    double maxWidth = InsideConstants.getCircleObjectSize(screenWidth);
    _maxWidth = maxWidth;

    final postWidget = InsideCirclePostWidget(
      message: _message,
      send: _send,
      clear: _clear,
      wall: widget.wall,
      showSlidingPanel: _showPanelWithoutShare,
      timer: _timer,
      setTimer: _setTimer,
      setScheduled: _setScheduled,
      timerKey: _insideCircleWalkthrough.keyButton6,
      focusNode: _focusNode,
      replyObject: _replyObject,
      parentType: widget.wall ? ParentType.feed : ParentType.circle,
      sendEnabled: _sendEnabled,
      passMediaCollection: passMediaCollection,
      editing: _editing,
      editingObject: _editingObject,
      taggedUsers: taggedUsers,
      setSendEnabled: setSendEnabled,
      members: _members,
      membersList: _membersList,
      setMembersList: setMembersList,
      passMembersFiltered: filterMembersList,
      typingTag: typingTag,
      setTypingTag: setTypingTag,
      whereTag: whereTag,
      setWhereTag: setWhereTag,
      clickedMember: clickedMember,
    );

    // IconButton buildButtonColumn(
    //     IconData icon, Color? color, Function onClick, Key key,
    //     {double iconSize = 37}) {
    //   // Color color = Theme.of(context).primaryColor;
    //
    //   return IconButton(
    //     key: key,
    //     padding: EdgeInsets.zero,
    //     constraints: const BoxConstraints(),
    //     iconSize: iconSize - globalState.scaleDownIcons,
    //     icon: Icon(
    //       icon,
    //       size: iconSize - globalState.scaleDownIcons,
    //     ),
    //     onPressed: onClick as void Function()?,
    //
    //     color: color,
    //     //size: iconSize,
    //   );
    // }

    Stack makeChat = Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 0, left: 5.0, right: 5.0),
          child: RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: _refresh,
            color: globalState.theme.buttonIcon,
            child:
                _circleObjects.isEmpty
                    ? Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: globalState.theme.background,
                        ),
                        child: _showSpinner ? spinkit : Container(),
                      ),
                    )
                    : NotificationListener<ScrollEndNotification>(
                      onNotification: onNotification,
                      child: ScrollablePositionedList.separated(
                        /// Let the ListView know how many items it needs to build
                        itemCount: _circleObjects.length,
                        reverse: true,
                        itemScrollController: _itemScrollController,
                        itemPositionsListener: _itemPositionsListener,
                        physics: const AlwaysScrollableScrollPhysics(),

                        //physics: const NeverScrollableScrollPhysics(),
                        separatorBuilder: (context, index) {
                          return Container(
                            color: globalState.theme.background,
                            //height: 1,
                            width: double.maxFinite,
                          );
                        },
                        itemBuilder: (context, index) {
                          //debugPrint(index);

                          CircleObject item = _circleObjects[index];

                          if (globalState.isDesktop()) {
                            ///check the widget
                            if (item.type == CircleObjectType.CIRCLEIMAGE &&
                                item.image != null &&
                                item.image!.imageBytes == null) {
                              int index = widget.memCacheObjects.indexWhere(
                                (element) => element.seed == item.seed,
                              );

                              if (index != -1) {
                                item.image!.imageBytes =
                                    widget
                                        .memCacheObjects[index]
                                        .image!
                                        .imageBytes;
                              }
                            } else if (item.type ==
                                    CircleObjectType.CIRCLEVIDEO &&
                                item.video!.previewBytes == null) {
                              int index = widget.memCacheObjects.indexWhere(
                                (element) => element.seed == item.seed,
                              );

                              if (index != -1) {
                                item.video!.previewBytes =
                                    widget
                                        .memCacheObjects[index]
                                        .video!
                                        .previewBytes;
                              }
                            }

                            ///also check the reply widget
                            if (item.replyObjectID != null) {
                              ///get the reply object
                              int replyIndex = _circleObjects.indexWhere(
                                (element) => element.id == item.replyObjectID!,
                              );

                              if (replyIndex != -1) {
                                CircleObject replyItem =
                                    _circleObjects[replyIndex];

                                ///test to see if it is an image or video
                                if (replyItem.type ==
                                        CircleObjectType.CIRCLEVIDEO ||
                                    replyItem.type ==
                                        CircleObjectType.CIRCLEIMAGE) {
                                  int memCacheIndex = widget.memCacheObjects
                                      .indexWhere(
                                        (element) =>
                                            element.seed == replyItem.seed,
                                      );

                                  if (memCacheIndex != -1) {
                                    if (replyItem.type ==
                                            CircleObjectType.CIRCLEIMAGE &&
                                        replyItem.image!.imageBytes == null) {
                                      int index = widget.memCacheObjects
                                          .indexWhere(
                                            (element) =>
                                                element.seed == replyItem.seed,
                                          );

                                      if (index != -1) {
                                        replyItem.image!.imageBytes =
                                            widget
                                                .memCacheObjects[index]
                                                .image!
                                                .imageBytes;
                                      }
                                    } else if (replyItem.type ==
                                            CircleObjectType.CIRCLEVIDEO &&
                                        replyItem.video!.previewBytes == null) {
                                      int index = widget.memCacheObjects
                                          .indexWhere(
                                            (element) =>
                                                element.seed == replyItem.seed,
                                          );

                                      if (index != -1) {
                                        replyItem.video!.previewBytes =
                                            widget
                                                .memCacheObjects[index]
                                                .video!
                                                .previewBytes;
                                      }
                                    }
                                  }
                                }
                              } else {
                                ///TODO this is a whole thing, the reply was to an object that is far back enough it wasn't loaded
                                _fetchObjectById(item.replyObjectID!);
                              }
                            }
                          }
                          return InsideCircleDetermineWidget(
                            members: _members,
                            //members: globalState.members,
                            populateAlbum: PopulateMedia.populateAlbum,
                            circleAlbumBloc: _circleAlbumBloc,
                            reverse: true,
                            scrollToIndex: _scrollToIndex,
                            userCircleCache: widget.userCircleCache,
                            userFurnace: widget.userFurnace,
                            circleObjects: _circleObjects,
                            index: index,
                            refresh: _reload,
                            circle: widget.userCircleCache.cachedCircle!,
                            shareObject: _shareObject,
                            unpinObject: _unpinObject,
                            openExternalBrowser: _openExternalBrowser,
                            leave: _leave,
                            export: _export,
                            cancelTransfer: _cancelTransfer,
                            longPressHandler: _longPressHandler,
                            longReaction: _longReaction,
                            shortReaction: _shortReaction,
                            tapHandler: _shortPressHandler,
                            storePosition: _storePosition,
                            copyObject: _copyObject,
                            reactionAdded: _reactionAdded,
                            showReactions: _showReactions,
                            videoControllerBloc: _videoControllerBloc,
                            videoControllerDesktopBloc:
                                _videoControllerDesktopBloc,
                            globalEventBloc: _globalEventBloc,
                            circleVideoBloc: _circleVideoBloc,
                            circleImageBloc: _circleImageBloc,
                            circleObjectBloc: _circleObjectBloc,
                            circleRecipeBloc: _circleRecipeBloc,
                            circleFileBloc: _circleFileBloc,
                            updateList: _updateList,
                            submitVote: _submitVote,
                            deleteObject: _deleteObject,
                            editObject: _editObject,
                            streamVideo: _streamVideo,
                            downloadVideo: _downloadVideo,
                            downloadFile: _downloadFile,
                            retry: _retry,
                            predispose: _predispose,
                            playVideo: _playVideo,
                            removeCache: _removeCache,
                            populateFile: PopulateMedia.populateFile,
                            populateVideoFile: PopulateMedia.populateVideoFile,
                            populateRecipeImageFile:
                                PopulateMedia.populateRecipeImageFile,
                            populateImageFile: PopulateMedia.populateImageFile,
                            displayReactionsRow: true,
                            interactive: true,
                            maxWidth: maxWidth,
                          );
                        },
                      ),
                    ),
          ),
        ),
        _waitingOnScroller.isNotEmpty
            ? Align(
              alignment: Alignment.bottomCenter,
              child: InkWell(
                onTap: () {
                  _addNewAndScrollToBottom();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_circle_down_rounded,
                      size: 50,
                      color: globalState.theme.buttonIcon,
                    ),
                    ICText(
                      ' new messages',
                      color: globalState.theme.buttonIcon,
                    ),
                  ],
                ),
              ),
            )
            : _scrollingDown
            ? Align(
              alignment: Alignment.bottomCenter,
              child: InkWell(
                onTap: () {
                  _addNewAndScrollToBottom();
                },
                child: Icon(
                  Icons.arrow_circle_down_rounded,
                  size: 50,
                  color: globalState.theme.buttonIcon,
                ),
              ),
            )
            : Container(),
      ],
    );

    Stack makeFeed = Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(
            top: 0,
            left: 5.0,
            right: 5.0,
            bottom: 0,
          ),
          child: RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: _refresh,
            color: globalState.theme.buttonIcon,
            child:
                _circleObjects.isEmpty
                    ? Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: globalState.theme.background,
                        ),
                        child: _showSpinner ? spinkit : Container(),
                      ),
                    )
                    : NotificationListener<ScrollEndNotification>(
                      onNotification: onNotification,
                      child: ScrollablePositionedList.separated(
                        /// Let the ListView know how many items it needs to build
                        itemCount: _circleObjects.length,
                        reverse: false,
                        itemScrollController: _itemScrollController,
                        itemPositionsListener: _itemPositionsListener,
                        physics: const AlwaysScrollableScrollPhysics(),

                        //physics: const NeverScrollableScrollPhysics(),
                        separatorBuilder: (context, index) {
                          return Container(
                            color: globalState.theme.background,
                            //height: 1,
                            width: double.maxFinite,
                          );
                        },
                        itemBuilder: (context, index) {
                          //debugPrint(index);
                          CircleObject item = _circleObjects[index];

                          if (globalState.isDesktop()) {
                            if (item.type == CircleObjectType.CIRCLEIMAGE &&
                                item.image!.imageBytes == null) {
                              int index = widget.memCacheObjects.indexWhere(
                                (element) => element.seed == item.seed,
                              );

                              if (index != -1) {
                                item.image!.imageBytes =
                                    widget
                                        .memCacheObjects[index]
                                        .image!
                                        .imageBytes;
                              }
                            } else if (item.type ==
                                    CircleObjectType.CIRCLEVIDEO &&
                                item.video!.previewBytes == null) {
                              int index = widget.memCacheObjects.indexWhere(
                                (element) => element.seed == item.seed,
                              );

                              if (index != -1) {
                                item.video!.previewBytes =
                                    widget
                                        .memCacheObjects[index]
                                        .video!
                                        .previewBytes;
                              }
                            }
                          }

                          return InsideWallDetermineWidget(
                            key: GlobalKey(),
                            members: _members,
                            //members: globalState.members,
                            replyObjects: widget.replyObjects,
                            circleAlbumBloc: _circleAlbumBloc,
                            replyObjectBloc: _replyObjectBloc,
                            populateAlbum: PopulateMedia.populateAlbum,
                            reverse: false,
                            userCircleCache: item.userCircleCache!,
                            userFurnace: item.userFurnace!,
                            circleObjects: _circleObjects,
                            index: index,
                            refresh: _refresh,
                            circle:
                                widget.wall
                                    ? item.userCircleCache!.cachedCircle!
                                    : widget.userCircleCache.cachedCircle!,
                            tapHandler: _shortPressHandler,
                            shareObject: _shareObject,
                            unpinObject: _unpinObject,
                            openExternalBrowser: _openExternalBrowser,
                            leave: _leave,
                            export: _export,
                            cancelTransfer: _cancelTransfer,
                            longPressHandler: _longPressHandler,
                            longReaction: _longReaction,
                            shortReaction: _shortReaction,
                            storePosition: _storePosition,
                            copyObject: _copyObject,
                            reactionAdded: _reactionAdded,
                            showReactions: _showReactions,
                            videoControllerBloc: _videoControllerBloc,
                            videoControllerDesktopBloc:
                                _videoControllerDesktopBloc,
                            globalEventBloc: _globalEventBloc,
                            circleVideoBloc: _circleVideoBloc,
                            circleImageBloc: _circleImageBloc,
                            circleObjectBloc: _circleObjectBloc,
                            circleRecipeBloc: _circleRecipeBloc,
                            circleFileBloc: _circleFileBloc,
                            memberBloc: _memberBloc,
                            updateList: _updateList,
                            submitVote: _submitVote,
                            deleteObject: _deleteObject,
                            editObject: _editObject,
                            streamVideo: _streamVideo,
                            downloadVideo: _downloadVideo,
                            downloadFile: _downloadFile,
                            retry: _retry,
                            predispose: _predispose,
                            playVideo: _playVideo,
                            removeCache: _removeCache,
                            populateFile: PopulateMedia.populateFile,
                            populateVideoFile: PopulateMedia.populateVideoFile,
                            populateRecipeImageFile:
                                PopulateMedia.populateRecipeImageFile,
                            populateImageFile: PopulateMedia.populateImageFile,
                            displayReactionsRow: true,
                            interactive: true,
                            maxWidth: screenWidth,
                          );
                        },
                      ),
                    ),
          ),
        ),
        _waitingOnScroller.isNotEmpty
            ? Align(
              alignment: Alignment.bottomCenter,
              child: InkWell(
                onTap: () {
                  _addNewAndScrollToBottom();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      ///Feed scroll is in reverse so this is an up arrow
                      Icons.arrow_circle_up_rounded,
                      size: 50,
                      color: globalState.theme.buttonIcon,
                    ),
                    ICText(
                      ' new messages',
                      color: globalState.theme.buttonIcon,
                    ),
                  ],
                ),
              ),
            )
            : _scrollingDown
            ? Align(
              alignment: Alignment.bottomCenter,
              child: InkWell(
                onTap: () {
                  _addNewAndScrollToBottom();
                },
                child: Icon(
                  ///Feed scroll is in reverse so this is an up arrow
                  Icons.arrow_circle_up_rounded,
                  size: 50,
                  color: globalState.theme.buttonIcon,
                ),
              ),
            )
            : Container(),
      ],
    );

    final makeBottom = Padding(
      padding: EdgeInsets.only(
        left: globalState.isDesktop() && widget.wall ? _width / 4 - 50 : 0,
        right:
            globalState.isDesktop() && widget.wall
                ? _width / 4 - 50
                : globalState.isDesktop()
                ? 25
                : 0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: globalState.theme.background,
          borderRadius: const BorderRadius.only(
            // bottomLeft: Radius.circular(10.0),
            // bottomRight: Radius.circular(10.0),
            topLeft: Radius.circular(10.0),
            topRight: Radius.circular(10.0),
          ),
        ),
        padding: const EdgeInsets.all(8),
        //color: globalState.theme.slideUpPanelBackground,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(
                left: 0,
                right: 0,
                top: widget.wall ? 0 : 0,
                bottom: 0,
              ),
              child: Row(
                children: <Widget>[
                  _replyObject != null
                      ? Expanded(
                        child: Text(
                          "${_replyObject!.creator!.getUsernameAndAlias(globalState)}: ${_replyObject!.body!.length > 175 ? "${_replyObject!.body!.substring(0, 175)}...'" : _replyObject!.body!}",
                          textScaler: TextScaler.linear(
                            globalState.messageScaleFactor,
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                _replyObject!.creator!.id ==
                                        widget.userCircleCache.user!
                                    ? globalState.theme.userObjectText
                                    : Member.getMemberColor(
                                      widget.userFurnace,
                                      _replyObject!.creator,
                                    ),
                          ),
                        ),
                      )
                      : Container(),
                ],
              ),
            ),
            //Row(children: []),
            Padding(
              padding: EdgeInsets.only(
                //left: (Platform.isIOS ? 0 : 10), right: 0, top: 5, bottom: 0),
                left: 0,
                top: widget.wall ? 0 : 2,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    flex: 100,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                        color: globalState.theme.slideUpPanelBackground,
                      ),
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: [
                              _membersList
                                  ? SizedBox(
                                    height: 100,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Expanded(
                                          child: SingleChildScrollView(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    const BorderRadius.only(
                                                      bottomLeft:
                                                          Radius.circular(10),
                                                      bottomRight:
                                                          Radius.circular(10),
                                                      topLeft: Radius.circular(
                                                        10,
                                                      ),
                                                      topRight: Radius.circular(
                                                        10,
                                                      ),
                                                    ),
                                                color:
                                                    globalState
                                                        .theme
                                                        .slideUpPanelBackground,
                                              ),
                                              width: maxWidth + 20,
                                              height: 200,
                                              padding: const EdgeInsets.only(
                                                left: 0,
                                                right: 0,
                                                top: 0,
                                                bottom: 0,
                                              ),
                                              child: ListView.builder(
                                                scrollDirection: Axis.vertical,
                                                controller: _scrollController,
                                                shrinkWrap: true,
                                                itemCount:
                                                    membersFiltered.length,
                                                itemBuilder: (
                                                  BuildContext context,
                                                  int index,
                                                ) {
                                                  Member row =
                                                      membersFiltered[index];
                                                  User user = User(
                                                    id: row.memberID,
                                                    username: row.username,
                                                  );

                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          left: 10,
                                                          top: 15,
                                                          bottom: 10,
                                                          right: 10,
                                                        ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: <Widget>[
                                                        InkWell(
                                                          onTap: () {
                                                            setState(() {
                                                              if (!taggedUsers
                                                                  .contains(
                                                                    row.username,
                                                                  )) {
                                                                taggedUsers.add(
                                                                  user,
                                                                );
                                                              }

                                                              /// add tag to text
                                                              if (typingTag
                                                                  .contains(
                                                                    "@",
                                                                  )) {
                                                                _message.text =
                                                                    "${_message.text}${row.username} ";
                                                              } else if (typingTag
                                                                  .isEmpty) {
                                                                _message
                                                                    .text = _message
                                                                    .text
                                                                    .replaceFirst(
                                                                      "@",
                                                                      "@${row.username} ",
                                                                      whereTag,
                                                                    );
                                                              } else {
                                                                _message
                                                                    .text = _message
                                                                    .text
                                                                    .replaceFirst(
                                                                      typingTag,
                                                                      "${row.username} ",
                                                                      whereTag +
                                                                          1,
                                                                    );
                                                              }

                                                              /// move cursor to end of added tag
                                                              // _message.selection =
                                                              //     TextSelection.collapsed(offset: whereTag + row.username.length + 2);

                                                              /// close this menu
                                                              _membersList =
                                                                  false;
                                                            });
                                                          },
                                                          child: Row(
                                                            children: [
                                                              AvatarWidget(
                                                                user: user,
                                                                userFurnace:
                                                                    widget.wall
                                                                        ? widget.userFurnaces!.firstWhere(
                                                                          (
                                                                            element,
                                                                          ) =>
                                                                              element.pk ==
                                                                              row.furnaceKey,
                                                                        )
                                                                        : widget
                                                                            .userFurnace,
                                                                radius: 30,
                                                                refresh:
                                                                    _refresh,
                                                                showDM: true,
                                                                isUser:
                                                                    user.id ==
                                                                    widget
                                                                        .userFurnace
                                                                        .userid,
                                                              ),
                                                              const Padding(
                                                                padding:
                                                                    EdgeInsets.only(
                                                                      right: 10,
                                                                    ),
                                                              ),
                                                              Text(
                                                                row.username.length >
                                                                        20
                                                                    ? user
                                                                        .getUsernameAndAlias(
                                                                          globalState,
                                                                        )
                                                                        .substring(
                                                                          0,
                                                                          19,
                                                                        )
                                                                    : user.getUsernameAndAlias(
                                                                      globalState,
                                                                    ),
                                                                textScaler:
                                                                    TextScaler.linear(
                                                                      globalState
                                                                          .labelScaleFactor,
                                                                    ),
                                                                style: TextStyle(
                                                                  fontSize: 17,
                                                                  color: Member.returnColor(
                                                                    user.id!,
                                                                    globalState
                                                                        .members,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  : Container(),
                              Container(
                                child:
                                    _keyboardMediaCollection.isNotEmpty
                                        ? Padding(
                                          padding: const EdgeInsets.only(
                                            top: 5,
                                          ),
                                          child: ImagesPreviewScroller(
                                            mediaCollection:
                                                _keyboardMediaCollection,
                                            onDelete: _onDeletePress,
                                            onPress: _onPreviewPress,
                                          ),
                                        )
                                        : null,
                              ),
                            ],
                          ),
                          postWidget,
                        ],
                      ),
                    ),
                    //}),
                  ),
                  widget.wall
                      ? Container()
                      : const Padding(padding: EdgeInsets.only(left: 5)),
                  widget.wall
                      ? Container()
                      : Column(
                        children: <Widget>[
                          _editingObject == null
                              ? SizedBox(
                                height: 40,
                                //width:80,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.send_rounded,
                                    size: 27,
                                    color:
                                        _sendEnabled
                                            ? globalState
                                                .theme
                                                .bottomHighlightIcon
                                            : globalState.theme.buttonDisabled,
                                  ),
                                  onPressed: () {
                                    _send();
                                  },
                                ),
                              )
                              : SizedBox(
                                height: 40,
                                //width:80,
                                child: TextButton(
                                  child: Text(
                                    'EDIT',
                                    textScaler: const TextScaler.linear(1.0),
                                    style: TextStyle(
                                      fontSize: 18,
                                      color:
                                          _sendEnabled
                                              ? globalState
                                                  .theme
                                                  .bottomHighlightIcon
                                              : globalState
                                                  .theme
                                                  .buttonDisabled,
                                    ),
                                  ),
                                  onPressed: () {
                                    _send();
                                  },
                                ),
                              ),
                          const Padding(padding: EdgeInsets.only(bottom: 5)),
                        ],
                      ),
                ],
                // decoration: BoxDecoration(color: Colors.black),
              ),
            ),
            const Padding(padding: EdgeInsets.only(bottom: 0)),
          ],
        ),
      ),
    );

    void _choiceAction(String choice) async {
      if (choice == AppLocalizations.of(context)!.circleSettings ||
          choice == AppLocalizations.of(context)!.dmSettings ||
          choice == AppLocalizations.of(context)!.vaultSettings) {
        _refreshEnabled = false;

        _closeKeyboard();

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => CircleSettings(
                  userCircleCache: widget.userCircleCache,
                  userFurnace: widget.userFurnace,
                  circle: _circle,
                  firebaseBloc: _firebaseBloc,
                  userFurnaces: widget.userFurnaces!,
                  circleBloc: _circleBloc,
                ),
          ),
        );

        _refreshEnabled = true;

        if (result != null) {
          setState(() {
            widget.userCircleCache.cachedCircle = result.cachedCircle;
            _circle = result.cachedCircle;
            widget.userCircleCache.hidden = result.hidden;
            widget.userCircleCache.prefName = result.prefName;
            widget.userCircleCache.background = result.background;
            widget.userCircleCache.masterBackground = result.masterBackground;
          });

          _refresh();
        }
      } else if (choice == AppLocalizations.of(context)!.circleMembers) {
        _closeKeyboard();

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => Members(
                  userCircleCache: widget.userCircleCache,
                  userFurnace: widget.userFurnace,
                  userFurnaces: widget.userFurnaces!,
                ),
          ),
        );

        //if (result != null) _refresh();
        _refresh();
      } else if (choice == AppLocalizations.of(context)!.jumpToDate) {
        _getDateTime();
      } else if (choice == AppLocalizations.of(context)!.fontSize) {
        await DialogFontSize.selectFontSize(context);
        setState(() {});
      } else if (choice == AppLocalizations.of(context)!.pinnedPosts) {
        _closeKeyboard();

        CircleObject? result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PinnedPosts(
                  populateAlbum: PopulateMedia.populateAlbum,
                  circleAlbumBloc: _circleAlbumBloc,
                  userCircleCache: widget.userCircleCache,
                  userFurnace: widget.userFurnace,
                  circleObjectBloc: _circleObjectBloc,
                  userMessageColors: members,
                  circle: _circle,
                  videoControllerBloc: _videoControllerBloc,
                  videoControllerDesktopBloc: _videoControllerDesktopBloc,
                  globalEventBloc: _globalEventBloc,
                  circleVideoBloc: _circleVideoBloc,
                  circleImageBloc: _circleImageBloc,
                  circleRecipeBloc: _circleRecipeBloc,
                  circleFileBloc: _circleFileBloc,
                  unpinObject: _unpinObjectConfirmed,
                  populateImageFile: PopulateMedia.populateImageFile,
                  populateVideoFile: PopulateMedia.populateVideoFile,
                  populateRecipeImageFile:
                      PopulateMedia.populateRecipeImageFile,
                  populateFile: PopulateMedia.populateFile,
                ),
          ),
        );

        if (result != null) {
          int index = _circleObjects.indexWhere(
            (element) => element.seed == result.seed,
          );
          _scrollToIndex(index);
        }
      }
    }

    _closeHiddenCircles() async {
      // globalState.hiddenOpen = false;
      // widget.userCircleCache.hiddenOpen = false;
      // await UserCircleBloc.closeHiddenCircles(_firebaseBloc);
      // _backPressed(false);

      // Navigator.pushReplacementNamed(
      //   context,
      //   '/home',
      //   // arguments: user,
      // );

      if (globalState.isDesktop()) {
        widget.resetDesktopUI!();
      }
      _globalEventBloc.broadcastCloseHiddenCircles();
    }

    _openLocalSearch() async {
      _refreshEnabled = false;
      CircleObject? circleObject = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => LocalSearch(
                populateAlbum: PopulateMedia.populateAlbum,
                circleAlbumBloc: _circleAlbumBloc,
                userCircleCache: widget.userCircleCache,
                userFurnace: widget.userFurnace,
                circleObjectBloc: _circleObjectBloc,
                userMessageColors: members,
                circle: _circle,
                videoControllerBloc: _videoControllerBloc,
                videoControllerDesktopBloc: _videoControllerDesktopBloc,
                globalEventBloc: _globalEventBloc,
                circleVideoBloc: _circleVideoBloc,
                circleImageBloc: _circleImageBloc,
                circleRecipeBloc: _circleRecipeBloc,
                circleFileBloc: _circleFileBloc,
                unpinObject: _unpinObjectConfirmed,
                populateImageFile: PopulateMedia.populateImageFile,
                populateVideoFile: PopulateMedia.populateVideoFile,
                populateFile: PopulateMedia.populateFile,
                populateRecipeImageFile: PopulateMedia.populateRecipeImageFile,
                searchText: "test",
              ),
        ),
      );

      if (circleObject != null) {
        int index = _circleObjects.indexWhere(
          (element) => element.seed == circleObject.seed,
        );

        //await Future.delayed(const Duration(seconds:2));

        if (index >= 0) {
          _scrollToIndex(index);
        }
      }

      _refreshEnabled = true;
    }

    final topAppBar = AppBar(
      elevation: 0,
      toolbarHeight: 45,
      centerTitle: false,
      titleSpacing: 0.0,
      backgroundColor: globalState.theme.appBar,
      title: Text(
        widget.userCircleCache.prefName == null
            ? ''
            : widget.dmMember != null
            ? widget.dmMember!.returnUsernameAndAlias()
            : "${widget.userCircleCache.prefName!}  ",
        textScaler: const TextScaler.linear(1.0),
        overflow: TextOverflow.fade,
        style: ICTextStyle.getStyle(
          context: context,
          color: globalState.theme.textTitle,
          fontSize: ICTextStyle.appBarFontSize,
        ),
      ),
      iconTheme: IconThemeData(
        color: globalState.theme.menuIcons, //change your color here
      ),
      automaticallyImplyLeading: globalState.isDesktop() ? false : true,
      leading:
          globalState.isDesktop()
              ? null
              : BackWithDotIcon(
                userFurnaces: widget.userFurnaces!,
                goHome: () {
                  _goHome(true);
                },
                forceRefresh: _forceRefresh,
                circleID: widget.userCircleCache.circle!,
              ),
      actions: <Widget>[
        ///uncomment to add a button for testing that generates messages
        kDebugMode
            ? IconButton(
              icon: Icon(Icons.history, color: globalState.theme.menuIconsAlt),
              onPressed: _generateMessages,
            )
            : Container(),

        widget.hiddenOpen! || globalState.hiddenOpen
            ? IconButton(
              icon: Icon(
                Icons.lock_rounded,
                color: globalState.theme.menuIconsAlt,
              ),
              onPressed: _closeHiddenCircles,
            )
            //_goHome();
            : Container(),

        /* PopupMenuButton<String>(
          onSelected: _filter,
          icon: Icon(Icons.filter_list, color: _objectFilter == 'All' ? globalState.theme.menuIcons : globalState.theme.menuIconsAlt),
          itemBuilder: (BuildContext context) {
            return FilterMenu.choices.map((String choice) {
              return PopupMenuItem<String>(
                value: choice,
                child: Text(choice, style: TextStyle( color: (_objectFilter == choice) ? globalState.theme.menuIconsAlt :  globalState.theme.menuIcons),),
              );
            }).toList();
          },
        ),*/
        // IconButton(
        //   icon: Icon(Icons.phone, color: globalState.theme.menuIcons),
        //   tooltip: 'Start Video Call',
        //   onPressed: _openAngora,
        // ),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          iconSize: 27 - globalState.scaleDownIcons,
          key: _insideCircleWalkthrough.keyButton7,
          icon: Icon(Icons.search, color: globalState.theme.menuIcons),
          onPressed: _openLocalSearch,
        ),
        PopupMenuButton<String>(
          surfaceTintColor: Colors.transparent,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          iconSize: 27 - globalState.scaleDownIcons,
          key: _insideCircleWalkthrough.keyButton8,
          color: globalState.theme.menuBackground,
          onSelected: _choiceAction,
          icon: Icon(Icons.settings, color: globalState.theme.menuIcons),
          itemBuilder: (BuildContext context) {
            return _choices.map((String choice) {
              return PopupMenuItem<String>(
                value: choice,
                child: Text(
                  choice,
                  textScaler: TextScaler.linear(globalState.menuScaleFactor),
                  style: TextStyle(color: globalState.theme.menuText),
                ),
              );
            }).toList();
          },
        ),
      ],
    );
    // alternate to makeBody used for private vault
    Stack makeVaultScreen = Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 0, left: 5.0, right: 5.0),
          child: InsideVaultDetermineWidget(
            circleAlbumBloc: _circleAlbumBloc,
            memCacheObjects: widget.memCacheObjects,
            userCircleBloc: _userCircleBloc,
            circleListBloc: _circleListBloc,
            members: _members,
            reverse: true,
            userCircleCache: widget.userCircleCache,
            userFurnace: widget.userFurnace,
            circleObjects: _circleObjects,
            refresh: _refresh,
            searchGiphy: _selectGif,
            generateImage: _generate,
            onNotification: onNotification,
            circle: _circle,
            tapHandler: _shortPressHandler,
            shareObject: _shareObject,
            unpinObject: _unpinObject,
            openExternalBrowser: _openExternalBrowser,
            leave: _leave,
            export: _export,
            cancelTransfer: _cancelTransfer,
            longPressHandler: _longPressHandler,
            longReaction: _longReaction,
            shortReaction: _shortReaction,
            storePosition: _storePosition,
            copyObject: _copyObject,
            reactionAdded: _reactionAdded,
            showReactions: _showReactions,
            videoControllerBloc: _videoControllerBloc,
            videoControllerDesktopBloc: _videoControllerDesktopBloc,
            globalEventBloc: _globalEventBloc,
            circleVideoBloc: _circleVideoBloc,
            circleImageBloc: _circleImageBloc,
            circleObjectBloc: _circleObjectBloc,
            circleFileBloc: _circleFileBloc,
            circleRecipeBloc: _circleRecipeBloc,
            updateList: _updateList,
            submitVote: _submitVote,
            deleteObject: _deleteObject,
            editObject: _editObject,
            streamVideo: _streamVideo,
            downloadVideo: _downloadVideo,
            downloadFile: _downloadFile,
            retry: _retry,
            predispose: _predispose,
            playVideo: _playVideo,
            removeCache: _removeCache,
            populateVideoFile: PopulateMedia.populateVideoFile,
            populateRecipeImageFile: PopulateMedia.populateRecipeImageFile,
            populateImageFile: PopulateMedia.populateImageFile,
            displayReactionsRow: true,
            pickFiles: _pickFiles,
            send: _send,
            sendLink: _sendLink,
            captureMedia: _captureMedia,
            selectMedia: _pickImagesAndVideos,
            interactive: true,
            refreshObjects: _refreshCircleObjects,
          ),
        ),
      ],
    );

    Widget _mainWidget = DropTarget(
      onDragDone: (detail) {
        _previewDroppedImages(detail);
      },
      child: SafeArea(
        left: false,
        top: false,
        right: false,
        bottom: true,
        child: Scaffold(
          //this builds screen
          key: _scaffoldKey,
          backgroundColor: globalState.theme.background,
          appBar: widget.wall ? null : topAppBar,
          body: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Stack(
                      children: [
                        _circle.type == CircleType.VAULT
                            ? makeVaultScreen
                            : _circle.type == CircleType.WALL
                            ? makeFeed
                            : makeChat,
                        _showSpinner ? Center(child: spinkit) : Container(),
                        _showJumpToDateSpinner
                            ? Center(child: spinkit)
                            : Container(),
                      ],
                    ),
                  ),
                  _circle.type == CircleType.VAULT
                      ? Container()
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          /*Container(
                              padding: const EdgeInsets.all(0.0),
                              child: _editing ? Container() : bottomButtonBar,
                            ),*/
                          Container(
                            padding: const EdgeInsets.only(left: 15),
                            child:
                                _giphyOption != null
                                    ? GiphyPreviewSingle(
                                      giphyOption: _giphyOption,
                                      cancel: _clear,
                                    )
                                    : null,
                          ),
                          Container(
                            padding: const EdgeInsets.only(left: 0),
                            child:
                                _videoPreview
                                    ? _previewControllerBloc
                                            .videoControllers
                                            .isEmpty
                                        ? Container()
                                        : Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: (300),
                                                      height: (100),
                                                      child: AspectRatio(
                                                        aspectRatio:
                                                            _previewControllerBloc
                                                                .videoControllers[_previewIndex]
                                                                .chewieController!
                                                                .aspectRatio ??
                                                            _previewControllerBloc
                                                                .videoControllers[_previewIndex]
                                                                .chewieController!
                                                                .videoPlayerController
                                                                .value
                                                                .aspectRatio,
                                                        child: Chewie(
                                                          controller:
                                                              _previewControllerBloc
                                                                  .videoControllers[_previewIndex]
                                                                  .chewieController!,
                                                        ),
                                                      ),
                                                    ),
                                                    Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        IconButton(
                                                          icon: Icon(
                                                            Icons.image_rounded,
                                                            color:
                                                                globalState
                                                                    .theme
                                                                    .buttonIcon,
                                                          ),
                                                          iconSize: 25,
                                                          /*iconSize: 22,*/
                                                          //constraints: BoxConstraints(maxHeight: 20),
                                                          onPressed: () async {
                                                            Duration? position =
                                                                await _previewControllerBloc
                                                                    .videoControllers[_previewIndex]
                                                                    .videoPlayerController
                                                                    .position;

                                                            Duration duration =
                                                                _previewControllerBloc
                                                                    .videoControllers[_previewIndex]
                                                                    .videoPlayerController
                                                                    .value
                                                                    .duration;

                                                            //debugPrint(duration
                                                            //  .inMilliseconds);

                                                            int startFrame = 0;
                                                            int
                                                            durationInSeconds =
                                                                duration
                                                                    .inSeconds;

                                                            if (position !=
                                                                null)
                                                              startFrame =
                                                                  position
                                                                      .inSeconds;

                                                            if (mounted) {
                                                              int?
                                                              thumbnailFrame = await Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder:
                                                                      (
                                                                        context,
                                                                      ) => SelectThumbnail(
                                                                        video:
                                                                            _video!,
                                                                        startFrame:
                                                                            startFrame,
                                                                        duration:
                                                                            durationInSeconds,
                                                                      ),
                                                                ),
                                                              );

                                                              _thumbnailFrame =
                                                                  thumbnailFrame;
                                                            }
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    //Padding(padding: EdgeInsets.only(left:25),),
                                                    _videoStreamOnly
                                                        ? Text(
                                                          AppLocalizations.of(
                                                            context,
                                                          )!.videoSizeRequiresStreaming,
                                                        )
                                                        : ToggleButtons(
                                                          selectedBorderColor:
                                                              globalState
                                                                  .theme
                                                                  .dialogTransparentBackground,
                                                          borderColor:
                                                              globalState
                                                                  .theme
                                                                  .dialogTransparentBackground,
                                                          fillColor: Colors
                                                              .lightBlueAccent
                                                              .withOpacity(.1),
                                                          onPressed: (
                                                            int index,
                                                          ) {
                                                            setState(() {
                                                              if (index == 0) {
                                                                _videoStreamable =
                                                                    [
                                                                      true,
                                                                      false,
                                                                    ];
                                                              } else {
                                                                _videoStreamable =
                                                                    [
                                                                      false,
                                                                      true,
                                                                    ];
                                                              }
                                                            });
                                                          },
                                                          isSelected:
                                                              _videoStreamable!,
                                                          //highlightColor: Colors.yellow,
                                                          children: <Widget>[
                                                            SizedBox(
                                                              width: 120,
                                                              child: Center(
                                                                child: Text(
                                                                  AppLocalizations.of(
                                                                    context,
                                                                  )!.e2EEncrypted,
                                                                  style: TextStyle(
                                                                    color:
                                                                        _videoStreamable![0]
                                                                            ? globalState.theme.buttonIcon
                                                                            : globalState.theme.labelTextSubtle,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              width: 120,
                                                              child: Center(
                                                                child: Text(
                                                                  AppLocalizations.of(
                                                                    context,
                                                                  )!.streamable,
                                                                  style: TextStyle(
                                                                    color:
                                                                        _videoStreamable![1]
                                                                            ? globalState.theme.buttonIcon
                                                                            : globalState.theme.labelTextSubtle,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.help,
                                                      ),
                                                      iconSize: 25,
                                                      color:
                                                          globalState
                                                              .theme
                                                              .buttonDisabled,
                                                      onPressed: () {
                                                        setState(() {
                                                          DialogNotice.showNotice(
                                                            context,
                                                            'E2E versus Streamable?',
                                                            'E2E encryption protects your video.  If the video is otherwise publicly available, you may wish to choose Streaming instead.',
                                                            'Streaming allows circle members to watch the video without having to download (and decrypt).',
                                                            'Streamable videos are still encrypted in transit and at rest.',
                                                            null,
                                                            true,
                                                          );
                                                        });
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        )
                                    : Container(),
                          ),

                          _emojiShowing == true
                              ? EmojiPicker(
                                textEditingController: _emojiController,
                                onBackspacePressed: () {
                                  setState(() {
                                    _emojiShowing = false;
                                  });
                                },
                                config: Config(
                                  height: 256,
                                  //swapCategoryAndBottomBar: false,
                                  checkPlatformCompatibility: true,
                                  emojiViewConfig: EmojiViewConfig(
                                    backgroundColor:
                                        globalState.theme.userObjectBackground,
                                  ),
                                  emojiTextStyle: const TextStyle(),
                                  skinToneConfig: const SkinToneConfig(),
                                  categoryViewConfig: CategoryViewConfig(
                                    iconColor: globalState.theme.labelText,
                                    dividerColor: globalState.theme.labelText,
                                    backgroundColor:
                                        globalState.theme.userObjectBackground,
                                    indicatorColor:
                                        globalState.theme.userObjectText,
                                    iconColorSelected:
                                        globalState.theme.userObjectText,
                                  ),
                                  bottomActionBarConfig: BottomActionBarConfig(
                                    buttonColor:
                                        globalState.theme.userObjectBackground,
                                    backgroundColor:
                                        globalState.theme.userObjectBackground,
                                    buttonIconColor:
                                        globalState.theme.labelText,
                                  ),
                                  searchViewConfig: SearchViewConfig(
                                    buttonIconColor:
                                        globalState.theme.labelText,
                                    backgroundColor:
                                        globalState.theme.userObjectBackground,
                                  ),
                                ),
                              )
                              : Container(height: 0.0),
                          // MemberList(
                          // userCircleCache: userCircleCache,
                          // userFurnace: userFurnace,
                          // ),
                          _showTextField ? makeBottom : Container(),
                        ],
                      ),
                ],
              ),
              //_showSpinner ? Center(child: spinkit) : Container()
            ],
          ),
        ),
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (didPop) {
          return;
        }
        _backPressed(true);
      },
      child:
          Platform.isIOS
              ? GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.velocity.pixelsPerSecond.dx > 200) {
                    _backPressed(true);
                  }
                },
                child: _mainWidget,
              )
              : _mainWidget,
    );
  }

  bool _displayedWarning = false;

  StreamSubscription? applicationStateChangedStream;
  StreamSubscription? memCacheCircleObjectsRemoveAllHiddenStream;
  StreamSubscription? circleObjectsRefreshedStream;
  StreamSubscription? progressIndicatorStream;

  StreamSubscription? progressThumbnailIndicatorStream;
  StreamSubscription? previewDownloadedStream;
  StreamSubscription? circleObjectBroadcastStream;

  listen(BuildContext context) {
    // ///listen to background processing events
    // _globalEventBloc.taskComplete.listen((map) {
    //
    //   asdfsadfsadf
    //
    //
    // }, onError: (err) {
    //   debugPrint("error $err");
    // }, cancelOnError: false);

    applicationStateChangedStream = _globalEventBloc.applicationStateChanged
        .listen(
          (msg) {
            handleAppLifecycleState(msg);
          },
          onError: (error, trace) {
            LogBloc.insertError(error, trace);
          },
          cancelOnError: false,
        );

    if (widget.wall) {
      _globalEventBloc.openFeed.listen(
        (value) {
          if (widget.sharedMediaHolder != null &&
              !widget.sharedMediaHolder!.isCleared()) {
            ///this will occur if a share occurs and the feed isn't open
            debugPrint(
              "********************** widget.sharedMediaHolder != null && !widget.sharedMediaHolder!.isCleared()",
            );
            _sharedGif = widget.sharedMediaHolder!.sharedGif;
            _sharedMedia = widget.sharedMediaHolder!.sharedMedia;
            _sharedText = widget.sharedMediaHolder!.sharedText;
            _sharedVideo = widget.sharedMediaHolder!.sharedVideo;

            setState(() {});
            widget.sharedMediaHolder!.clear();
          } else if (globalState.enterCircle != null &&
              globalState.enterCircle!.sharedMediaHolder != null &&
              !globalState.enterCircle!.sharedMediaHolder!.isCleared()) {
            ///this will occur if a share occurs and the feed is already open
            debugPrint(
              "********************** globalState.enterCircle != null && globalState.enterCircle!.sharedMediaHolder != null",
            );
            _sharedGif = globalState.enterCircle!.sharedMediaHolder!.sharedGif;
            _sharedMedia =
                globalState.enterCircle!.sharedMediaHolder!.sharedMedia;
            _sharedText =
                globalState.enterCircle!.sharedMediaHolder!.sharedText;
            _sharedVideo =
                globalState.enterCircle!.sharedMediaHolder!.sharedVideo;

            globalState.enterCircle!.sharedMediaHolder!.clear();
          } else {
            debugPrint(
              "********************** widget.sharedMediaHolder is null",
            );
          }
          if (mounted) {
            setState(() {});
            debugPrint("********************** InsideCircle mounted");
          } else {
            debugPrint("********************** InsideCircle not mounted");
          }
        },
        onError: (err) {
          debugPrint("InsideCircle.listen.userFurnaceUpdated: $err");
        },
        cancelOnError: false,
      );
    }

    _circleObjectBloc!.refreshVault.listen(
      (refresh) async {
        if (mounted) {
          setState(() {
            debugPrint("refreshing insidecircle");
          });
        }
      },
      onError: (err) {
        debugPrint("CentralCalendar._firebaseBloc.calendarRefresh: $err");
      },
      cancelOnError: false,
    );

    memCacheCircleObjectsRemoveAllHiddenStream = _globalEventBloc
        .memCacheCircleObjectsRemoveAllHidden
        .listen(
          (success) async {
            widget.wallUserCircleCaches.removeWhere(
              (element) => element.hidden == true,
            );
            wallCircles.removeWhere((element) => element.hidden == true);

            widget.memCacheObjects.clear();
          },
          onError: (err) {
            debugPrint("error $err");
          },
          cancelOnError: false,
        );

    _globalEventBloc.clear.listen(
      (message) async {
        if (mounted) {
          try {
            if (_showTextField == false) {
              setState(() {
                _showTextField = true;
              });
            }
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint(
              'InsideCircle._globalEventBloc.timerExpired.listen: $err',
            );
          }
        }
      },
      onError: (err) {
        _clearSpinner();
        debugPrint("InsideCircle._globalEventBloc.timerExpired: $err");
      },
      cancelOnError: false,
    );

    _globalEventBloc.errorMessage.listen(
      (message) async {
        if (mounted) {
          try {
            if (_displayedWarning == false) {
              _displayedWarning = true;
              DialogNotice.showNoticeOptionalLines(
                context,
                'Sorry',
                message,
                true,
              );
            }

            if (_circleObjects[0].id == null) {
              _circleObjectBloc.deleteCircleObject(
                widget.userCircleCache,
                widget.userFurnace,
                _circleObjects[0],
              );
            }
            //}
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint(
              'InsideCircle._globalEventBloc.timerExpired.listen: $err',
            );
          }
        }
      },
      onError: (err) {
        _clearSpinner();
        debugPrint("InsideCircle._globalEventBloc.timerExpired: $err");
      },
      cancelOnError: false,
    );

    circleObjectsRefreshedStream = _globalEventBloc.circleObjectsRefreshed
        .listen(
          (success) {
            if (mounted) {
              _initialLoad();
              _globalEventBloc.broadcastRefreshWall();
            }
          },
          onError: (err) {
            debugPrint("error $err");
          },
          cancelOnError: false,
        );

    _memberBloc.loaded.listen(
      (members) {
        if (mounted) {
          setState(() {
            _members = members;
          });
        }
      },
      onError: (err) {
        debugPrint("error $err");
      },
      cancelOnError: false,
    );

    _circleBloc.settingsVoteCreated.listen(
      (vote) async {
        if (mounted) {
          try {
            _upsertCircleObject(vote);
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint(
              'InsideCircle._globalEventBloc.settingsVoteCreated.listen: $err',
            );
          }
        }
      },
      onError: (err) {
        _clearSpinner();
        debugPrint("InsideCircle._globalEventBloc.timerExpired: $err");
      },
      cancelOnError: false,
    );

    _globalEventBloc.timerExpired.listen(
      (seed) async {
        if (mounted) {
          try {
            int index = _circleObjects.indexWhere(
              (param) => param.seed == seed,
            );

            if (index >= 0) {
              setState(() {
                _circleObjects.removeAt(index);
              });
            }
            //}
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint(
              'InsideCircle._globalEventBloc.timerExpired.listen: $err',
            );
          }
        }
      },
      onError: (err) {
        _clearSpinner();
        debugPrint("InsideCircle._globalEventBloc.timerExpired: $err");
      },
      cancelOnError: false,
    );

    _circleVideoBloc.streamAvailable.listen(
      (circleObject) async {
        if (mounted) {
          try {
            int index = _circleObjects.indexWhere(
              (param) => param.seed == circleObject.seed,
            );

            if (index >= 0) {
              _circleObjects[index].video!.streamingUrl =
                  circleObject.video!.streamingUrl;

              if (_lastVideoPlayed != null) {
                _videoControllerBloc.pauseLast();

                _videoControllerBloc.predispose(_lastVideoPlayed);
                setState(() {
                  _lastVideoPlayed!.video!.videoState =
                      VideoStateIC.NEEDS_CHEWIE;
                });

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _videoControllerBloc.disposeObject(_lastVideoPlayed);
                });
              }

              await _videoControllerBloc.add(_circleObjects[index]);
              _lastVideoPlayed = circleObject;

              setState(() {
                //circleObject.video!.videoState = VideoStateIC.VIDEO_READY;
              });
            }
            //}
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint('InsideCircle.streamAvailable.listen: $err');
          }
        }
      },
      onError: (err) {
        _clearSpinner();
        debugPrint("InsideCircle.listen: $err");
      },
      cancelOnError: false,
    );

    _circleFileBloc.cacheDeleted.listen(
      (circleObject) {
        if (mounted) {
          try {
            int index = _circleObjects.indexWhere(
              (param) => param.seed == circleObject.seed,
            );

            if (index >= 0) {
              setState(() {
                _circleObjects[index].fullTransferState =
                    BlobState.NOT_DOWNLOADED;
              });
            }

            _globalEventBloc.broadcastRefreshWall();
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint('InsideCircle.cacheDeleted.listen: $err');
          }
        }
      },
      onError: (err) {
        _clearSpinner();
        debugPrint("InsideCircle.listen.cacheDeleted: $err");
      },
      cancelOnError: false,
    );

    _globalEventBloc.cacheDeletedStream.listen(
      (circleObject) {
        if (mounted) {
          try {
            int index = _circleObjects.indexWhere(
              (param) => param.seed == circleObject.seed,
            );

            if (index >= 0) {
              setState(() {
                _circleObjects[index].video!.videoState =
                    VideoStateIC.PREVIEW_DOWNLOADED;
                //_circleObjects[index].video!.videoState = circleObject.video!.videoState;
              });

              _globalEventBloc.broadcastRefreshWall();
            }
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint('InsideCircle.cacheDeleted.listen: $err');
          }
        }
      },
      onError: (err) {
        _clearSpinner();
        debugPrint("InsideCircle.listen.cacheDeleted: $err");
      },
      cancelOnError: false,
    );

    progressIndicatorStream = _globalEventBloc.progressIndicator.listen(
      (circleObject) {
        if (mounted) {
          try {
            setState(() {
              if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
                if (circleObject.oneTimeView == false) {
                  ProcessCircleObjectEvents.putCircleVideo(
                    _circleObjects,
                    circleObject,
                    _circleVideoBloc,
                  );

                  if (circleObject.transferPercent == 100) {
                    _circleObjectBloc.sinkVaultRefresh();
                    //_globalEventBloc.broadcastRefreshWall();
                  }
                } else if (circleObject.transferPercent == 100 &&
                    circleObject.oneTimeView) {
                  _processOTVVideoDownloaded(circleObject);
                  //_globalEventBloc.broadcastRefreshWall();
                }
              } else if (circleObject.type == CircleObjectType.CIRCLEFILE) {
                ProcessCircleObjectEvents.putCircleFile(
                  _circleObjects,
                  circleObject,
                  _circleFileBloc,
                );

                if (circleObject.transferPercent == 100) {
                  if (lastTapped != null &&
                      lastTapped!.seed == circleObject.seed) {
                    lastTapped = null;

                    if (circleObject.file!.extension! == 'pdf') {
                      if (circleObject.oneTimeView == true &&
                          circleObject.body != "") {
                        _openPDF(circleObject, false, replace: true);
                      } else {
                        _openPDF(circleObject, false);
                      }
                    } else {
                      _handleFile(circleObject);
                    }
                  }

                  //_globalEventBloc.broadcastRefreshWall();
                }

                _circleObjectBloc.sinkVaultRefresh();
              } else if (circleObject.type == CircleObjectType.CIRCLEIMAGE) {
                ProcessCircleObjectEvents.putCircleImage(
                  _circleObjects,
                  circleObject,
                  true,
                );

                if (circleObject.transferPercent == 100) {
                  //_globalEventBloc.broadcastRefreshWall();
                }
              } else if (circleObject.type == CircleObjectType.CIRCLEALBUM) {
                ProcessCircleObjectEvents.putCircleAlbum(
                  _circleObjects,
                  circleObject,
                  true,
                );

                if (circleObject.transferPercent == 100) {
                  //_globalEventBloc.broadcastRefreshWall();
                }
              }
            });
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint(
              'InsideCircle._globalEventBloc.progressIndicator.listen: $err',
            );
          }
        }
      },
      onError: (err) {
        _clearSpinner();
        debugPrint(
          "InsideCircle._globalEventBloc.progressIndicator.listen: $err",
        );
      },
      cancelOnError: false,
    );

    progressThumbnailIndicatorStream = _globalEventBloc
        .progressThumbnailIndicator
        .listen(
          (circleObject) {
            if (mounted) {
              try {
                setState(() {
                  if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
                    // ProcessCircleObjectEvents.putCircleVideo(
                    //_circleObjects, circleObject, _circleVideoBloc);
                  } else if (circleObject.type ==
                      CircleObjectType.CIRCLEIMAGE) {
                    ProcessCircleObjectEvents.putCircleImage(
                      _circleObjects,
                      circleObject,
                      false,
                    );
                  } else if (circleObject.type ==
                      CircleObjectType.CIRCLEALBUM) {
                    ProcessCircleObjectEvents.putCircleAlbum(
                      _circleObjects,
                      circleObject,
                      false,
                    );
                  } else if (circleObject.type ==
                      CircleObjectType.CIRCLERECIPE) {
                    ProcessCircleObjectEvents.putCircleRecipe(
                      _circleObjects,
                      circleObject,
                    );
                  }
                });
              } catch (err, trace) {
                LogBloc.insertError(err, trace);
                debugPrint(
                  'InsideCircle._globalEventBloc.progressThumbnailIndicator.listen: $err',
                );
              }
            }
          },
          onError: (err) {
            _clearSpinner();
            debugPrint(
              "InsideCircle._globalEventBloc.progressIndicator.listen: $err",
            );
          },
          cancelOnError: false,
        );

    ///DEPRECATED  TODO
    _globalEventBloc.objectDownloaded.listen(
      (object) {
        //find the circle object

        if (mounted) {
          try {
            CircleObject circleObject = _circleObjects.firstWhere(
              (element) => element.id == object.id,
              orElse: () => CircleObject(ratchetIndexes: []),
            );

            if (circleObject.seed != null) {
              setState(() {
                if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
                  /* circleObject.video!.previewFile = File(
                    VideoCacheService.returnPreviewPath(
                        widget.userCircleCache.circlePath!,
                        circleObject.seed!));

                */
                } else if (circleObject.type == CircleObjectType.CIRCLEIMAGE) {
                  if (circleObject.seed != null) {}
                }
              });
            }
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint(
              'insidecircle listen _globalEvenBloc.objectDownloaded: $err',
            );
          }
        }
      },
      onError: (err) {
        debugPrint("CircleImageMemberWidget.initState: $err");
      },
      cancelOnError: false,
    );

    previewDownloadedStream = _globalEventBloc.previewDownloaded.listen(
      (object) {
        //find the circle object

        if (mounted) {
          try {
            CircleObject circleObject = _circleObjects.firstWhere(
              (element) => element.id == object.id,
              orElse: () => CircleObject(ratchetIndexes: []),
            );

            if (circleObject.seed != null) {
              if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
                if (circleObject.oneTimeView) {
                  ///download the video
                  _circleVideoBloc.downloadVideo(
                    widget.userFurnace,
                    widget.userCircleCache,
                    circleObject,
                  );
                }

                setState(() {
                  circleObject.video!.videoState = object.video!.videoState!;
                });
              }
            }
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint(
              'insidecircle listen _globalEvenBloc.previewDownloaded: $err',
            );
          }
        }
      },
      onError: (err) {
        debugPrint("CircleImageMemberWidget.initState: $err");
      },
      cancelOnError: false,
    );

    // _firebaseBloc = BlocProvider.of<FirebaseBloc>(context);
    _firebaseBloc = Provider.of<FirebaseBloc>(context, listen: false);

    _circleEventStream = _firebaseBloc.circleEvent.listen(
      (circleID) {
        if (mounted && circleID != null && _validCircle(circleID)) {
          //is this the circle we are currently in?
          if (widget.wall) {
            ///verify the circle is part of the wall circles
            int index = widget.wallUserCircleCaches.indexWhere(
              (element) => element.circle! == circleID,
            );

            if (index == -1) return;
          }

          if (_circleObjects.isNotEmpty) {
            _firebaseBloc.removeNotification();

            if (_circleObjects.isNotEmpty) {
              _circleObjectBloc.markReadForCircle(
                _circle.id!,
                _circleObjects[0].created!,
              );
            }

            ///Let the server know we received the message, at the same time, see if anything else came in
            ///this will flip the server side showBadge flag
            _refreshCircleObjects();
          }
        }
      },
      onError: (err) {
        _clearSpinner();
        debugPrint("InsideCircle.listen: $err");
      },
      cancelOnError: false,
    );

    _globalEventBloc.refreshCircleForDesktop.listen(
      (circleID) {
        if (mounted && circleID != null && _validCircle(circleID)) {
          //is this the circle we are currently in?
          if (widget.wall) {
            ///verify the circle is part of the wall circles
            int index = widget.wallUserCircleCaches.indexWhere(
              (element) => element.circle! == circleID,
            );

            if (index == -1) return;
          }

          if (_circleObjects.isNotEmpty) {
            _firebaseBloc.removeNotification();

            if (_circleObjects.isNotEmpty) {
              _circleObjectBloc.markReadForCircle(
                _circle.id!,
                _circleObjects[0].created!,
              );
            }

            ///Let the server know we received the message, at the same time, see if anything else came in
            ///this will flip the server side showBadge flag
            _refreshCircleObjects();
          }
        }
      },
      onError: (err) {
        _clearSpinner();
        debugPrint("InsideCircle.listen: $err");
      },
      cancelOnError: false,
    );

    _suppressNotifications = _firebaseBloc.suppressNotification.listen(
      (suppressNotification) {
        if (mounted) {
          //is this the circle we are currently in?
          if (suppressNotification.circleID != _currentCircle) {
            _firebaseBloc.showNotification(
              suppressNotification.title,
              payload: suppressNotification.payload,
            );
          }
        }
      },
      onError: (err) {
        _clearSpinner();
        debugPrint("InsideCircle.listen: $err");
      },
      cancelOnError: false,
    );

    _circleBloc.fetchedResponse.listen(
      (circle) {
        if (mounted && _validCircle(circle.id!)) {
          setState(() {
            ///there could be a race condition where the api returns faster than the retrieving from cache
            if (circle.memberSessionKeys.isEmpty &&
                _circle.memberSessionKeys.isNotEmpty) {
              circle.memberSessionKeys.addAll(_circle.memberSessionKeys);
            }
            _circle = circle;
            widget.userCircleCache.cachedCircle = _circle;
          });
        }
      },
      onError: (err) {
        debugPrint(err.message.toString());

        if (err.message.toString() == "Exception: Could not find circle") {
          _goHome(true);
        } else
          _clearSpinner();
        debugPrint("InsideCircle.listen._cirlceBloc.fetchResponse: $err");
      },
      cancelOnError: false,
    );

    _firebaseBloc.circleRemoveNotification.listen(
      (circle) {
        if (mounted && _validCircle(circle)) {
          //is this the circle we are currently in?

          _firebaseBloc.removeNotification();

          if (_circleObjects.isNotEmpty) {
            _circleObjectBloc.markReadForCircle(
              _circle.id!,
              _circleObjects[0].created!,
            );
          }
        }
      },
      onError: (err) {
        //Navigator.pushReplacementNamed(context, '/login');
        _clearSpinner();
        debugPrint(
          "InsideCircle.listen._firebaseBloc.circleRemoveNotification: $err",
        );
      },
      cancelOnError: false,
    );

    ///Listen for the first CircleObject load
    _circleObjectBloc.allCircleObjects.listen(
      (allCircleObjects) {
        if (mounted) {
          //_userCircleBloc.turnOffBadge(widget.userCircleCache);

          _firstTimeLoadComplete = true;

          if (allCircleObjects!.isNotEmpty) {
            /*allCircleObjects.sort((a, b) {
            return b.created!.compareTo(a.created!);
          });
           */

            if (_circleObjects.isEmpty) {
              CircleObjectCollection.addWallHitchhikers(
                allCircleObjects,
                widget.wallFurnaces,
                widget.wallUserCircleCaches,
              );

              setState(() {
                //_circleObjects = CircleObjectCollection.sort(allCircleObjects);
                _circleObjects = allCircleObjects;
              });
            } else {
              ///Creating a new instance of the list caused a refresh issue with vault screens
              if (_circle.type == CircleType.VAULT) {
                ///scrolling update
                _addObjects(allCircleObjects, false);
                // CircleObjectCollection.addObjects(
                //     _circleObjects, allCircleObjects, _currentCircle!);

                // _circleObjects.clear();

                //_circleObjects
                //   .addAll(CircleObjectCollection.sort(allCircleObjects));
              } else {
                ///scrolling update
                //CircleObjectCollection.addObjects(
                //   _circleObjects, allCircleObjects, _currentCircle!);
                _addObjects(allCircleObjects, false);
              }
            }

            _firebaseBloc.removeNotification();

            //MemberColors.setMemberColors(
            //    _circleObjects, members, globalState.user.username!);

            //setState(() {});
          } else {
            setState(() {
              _circleObjects = allCircleObjects;
            }); //refresh the hamburger in case an invitation was received
          }

          ///don't update the server because we do so in _populateCircle -> getcircle
          _turnoffBadgeAndSetLastAccess(false);
          _populateCircle();
          _circleObjectBloc.resendFailedCircleObjects(
            _globalEventBloc,
            widget.userFurnaces!,
          );

          _showShare();

          _showFirstTimePrompts();

          if (_circleObjects.isNotEmpty) {
            _circleObjectBloc.markReadForCircle(
              _circle.id!,
              _circleObjects[0].created!,
            );
          }
        }
      },
      onError: (err) {
        _clearSpinner();
        debugPrint("InsideCircle.listen: $err");
      },
      cancelOnError: false,
    );

    ///Listen for any new CircleObjects that arrive
    _circleObjectBloc.olderCircleObjects.listen(
      (circleObjects) {
        if (mounted) {
          if (circleObjects.isEmpty) {
            _thereAreNoOlderPosts = true;
          } else {
            _thereAreNoOlderPosts = false;
            setState(() {
              _checkSpinner();

              ///These get added at the top, so just add them. Should make the scroller janky
              CircleObjectCollection.addObjects(
                _circleObjects,
                circleObjects,
                _currentCircle!,
                widget.wallFurnaces,
                widget.wallUserCircleCaches,
              );
            });

            debugPrint(
              'InsideCircle.listen.olderCircleObjects: ${circleObjects.length}, and new total ${_circleObjects.length}',
            );
          }
        }
      },
      onError: (err) {
        _clearSpinner();
        debugPrint("InsideCircle.listen.olderCircleObjects: $err");
      },
      cancelOnError: false,
    );

    ///Jump to circles
    _circleObjectBloc.jumpToCircleObjects.listen(
      (circleObjects) {
        if (mounted) {
          int index = -1;

          setState(() {
            _showJumpToDateSpinner = false;

            if (circleObjects.isEmpty) {
              index = _circleObjects.length - 1;
            } else {
              List<CircleObject> oldList = _circleObjects;

              CircleObjectCollection.addWallHitchhikers(
                circleObjects,
                widget.wallFurnaces,
                widget.wallUserCircleCaches,
              );

              _circleObjects = circleObjects;

              _scrollAfterWait(0);
              _addObjects(oldList, false);
              index = CircleObjectCollection.findIndexByDate(
                _circleObjects,
                _jumpToDate!,
              );
              // MemberColors.addMemberColors(
              //  _circleObjects, members, globalState.user.username!);
            }
          });

          _scrollAfterWait(index);
          //_scrollToIndex(index);
        }
      },
      onError: (err) {
        _showJumpToDateSpinner = false;
        debugPrint("InsideCircle.listen.jumpToCircleObjects: $err");
      },
      cancelOnError: false,
    );

    //Listen for any new CircleObjects that arrive
    _circleObjectBloc.newCircleObjects.listen(
      (newCircleObjects) {
        if (mounted) {
          //bool scroll = false;

          setState(() {
            _checkSpinner();

            if (newCircleObjects!.isNotEmpty) {
              _addObjects(newCircleObjects, false);

              _circleObjectBloc.markReadForCircle(
                _circle.id!,
                _circleObjects[0].created!,
              );
            } else {
              _showSpinner = false;
            }
          });
        }
      },
      onError: (err) {
        _clearSpinner();
        debugPrint("InsideCircle.listen.newCircleObjects: $err");
      },
      cancelOnError: false,
    );

    //Listen for saved results arrive
    _circleObjectBloc.saveResults.listen(
      (result) {
        result.scheduledFor = _scheduledDate;
        if (result.type == CircleObjectType.CIRCLEEVENT)
          _upsertCircleObject(result /*sort: true*/);
        else
          _upsertCircleObject(result);
      },
      onError: (err) {
        debugPrint("InsideCircle.listen: $err");
        setState(() {
          _showSpinner = false;
        });
      },
      cancelOnError: false,
    );

    //Listen for saved failed
    _circleObjectBloc.saveFailed.listen(
      (result) {
        int index = _circleObjects.indexWhere(
          (circleobject) => circleobject.seed == result.circleObject.seed,
        );

        if (index != -1) _circleObjects.removeAt(index);

        //debugPrint(result.errorMessage);

        DialogNotice.showNotice(
          context,
          'Something went wrong',
          result.errorMessage,
          null,
          null,
          null,
          true,
        );

        setState(() {
          _showSpinner = false;
        });
      },
      onError: (err) {
        debugPrint("InsideCircle.listen: $err");

        setState(() {
          _showSpinner = false;
        });
      },
      cancelOnError: false,
    );

    circleObjectBroadcastStream = _globalEventBloc.circleObjectBroadcast.listen(
      (result) async {
        debugPrint("...........START UPSERT TO SCREEN: ${DateTime.now()}");

        if (_validCircle(result.circle!.id!)) {
          // if (mounted) {
          //   if (widget.markRead != null) await widget.markRead!(result);
          // }

          ///always scroll for new objects
          bool scroll = false;
          if (result.id == null) scroll = true;
          _addObjects([result], scroll);

          if (result.id != null) {
            if (widget.markRead != null)
              await widget.markRead!(result);
            else
              _circleObjectBloc.markReadForCircle(_circle.id!, result.created!);
          }
          if (mounted) {
            setState(() {
              _showSpinner = false;
            });
          }
        }

        //debugPrint("...........FINISHED UPSERT TO SCRFEEN: ${DateTime.now()}");
      },
      onError: (err) {
        debugPrint("InsideCircle.listen: $err");
      },
      cancelOnError: false,
    );

    //Listen for saved results arrive
    _circleRecipeBloc.created.listen(
      (result) {
        _upsertCircleObject(result);
      },
      onError: (err) {
        debugPrint("InsideCircle.listen: $err");
      },
      cancelOnError: false,
    );

    //Listen for saved results arrive
    _circleListBloc.created.listen(
      (result) {
        _upsertCircleObject(result);
      },
      onError: (err) {
        debugPrint("InsideCircle.listen: $err");
      },
      cancelOnError: false,
    );

    //Listen for saved results arrive
    _voteBloc.createdResponse.listen(
      (result) {
        _upsertCircleObject(result);
      },
      onError: (err) {
        debugPrint("InsideCircle.listen: $err");
      },
      cancelOnError: false,
    );

    ///Listen for individual deletions
    _circleObjectBloc.circleObjectDeleted.listen(
      (result) {
        if (mounted) {
          int index = _circleObjects.indexWhere(
            (circleobject) => circleobject.seed == result.seed,
          );

          if (index != -1) {
            if (result.type == CircleObjectType.CIRCLEVIDEO) {
              if (result.video != null) {
                if (result.video!.videoState == VideoStateIC.VIDEO_READY) {
                  _disposeControllers(result);
                }
              }
            }
            setState(() {
              _circleObjects.removeAt(index);
            });
            _circleObjectBloc.sinkVaultRefresh();
            _globalEventBloc.broadcastDelete(result);
          }
        }
      },
      onError: (err) {
        debugPrint("InsideCircle.listen: $err");
      },
      cancelOnError: false,
    );

    ///Listen for multiple deletions
    _circleObjectBloc.circleObjectsDeleted.listen(
      (deletedItems) {
        if (mounted) {
          for (CircleObject circleObject in deletedItems) {
            int index = _circleObjects.indexWhere(
              (circleobject) => circleobject.seed == circleObject.seed,
            );

            if (index != -1) {
              setState(() {
                _circleObjects.removeAt(index);
              });
            }
          }
        }
      },
      onError: (err) {
        debugPrint("InsideCircle.listen: $err");
      },
      cancelOnError: false,
    );

    _voteBloc.submitVoteResults.listen(
      (circleObject) async {
        if (circleObject.vote == null) {
          _circleBloc.deleteCache(_globalEventBloc, widget.userCircleCache);
          await Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Home()),
            (Route<dynamic> route) => false,
          );
        } else {
          setState(() {
            _showSpinner = false;

            int index = _circleObjects.indexWhere(
              (circleobject) => circleobject.id == circleObject.id,
            );

            _circleObjects[index] = circleObject;

            /*if (!circleObject.vote!.open!) if (circleObject.vote!.type ==
                CircleVoteType.DELETECIRCLE &&
            circleObject.vote!.winner != null) {
          _goHome(true);
        }
         */

            // if (circleObject.vote == null) {
            //   ///circle was deleted
            //
            //   _goHome(true);
            // } else {
            _circle = circleObject.circle!;
            if (mounted) {
              setState(() {
                _showSpinner = false;
                _addObjects([circleObject], true);
              });
            }
            //}
          });
        }
        //_refresh();
      },
      onError: (err) {
        debugPrint("InsideCircle.listen: $err");

        setState(() {
          _showSpinner = false;
        });
      },
      cancelOnError: false,
    );

    _circleListBloc.updated.listen(
      (circleObject) {
        if (mounted) {
          setState(() {
            _showSpinner = false;
            _addObjects([circleObject], true);
          });
        }
      },
      onError: (err) {
        debugPrint("error $err");
        FormattedSnackBar.showSnackbarWithContext(
          context,
          err.toString(),
          "",
          2,
          true,
        );

        setState(() {
          //_showSpinner = false;
        });
      },
      cancelOnError: false,
    );

    _userCircleBloc.leaveCircleResponse.listen(
      (response) {
        if (mounted) {
          FormattedSnackBar.showSnackbarWithContext(
            context,
            "Left circle",
            "",
            1,
            false,
          );
          if (response!) _goHome(true);
        }
      },
      onError: (err) {
        FormattedSnackBar.showSnackbarWithContext(
          context,
          err.toString(),
          "",
          1,
          true,
        );
      },
      cancelOnError: false,
    );

    _firebaseBloc.removeNotification();
  }

  _backPressed(bool samePosition) {
    if (widget.wall || globalState.isDesktop()) return;

    if (_showEmojiPicker) {
      setState(() {
        _showEmojiPicker = !_showEmojiPicker;
      });
    } else {
      _goHome(samePosition);
    }
  }

  void _populateCircle() async {
    //_circle = (await TableCircleCache.read(widget.userCircleCache.circle!))!;
    _circleBloc.fetchCircle(
      widget.userFurnace,
      widget.userCircleCache.circle!,
      widget.userCircleCache.lastLocalAccess,
    );
  }

  void _fileCachedFromString(String path) async {
    _sharedMedia = MediaCollection();

    if (FileSystemService.isStringImage(path)) {
      _sharedMedia!.add(Media(path: path, mediaType: MediaType.image));

      _sharedText = null;
    } else if (FileSystemService.isStringVideo(path)) {
      Media media = Media(path: path, mediaType: MediaType.video);

      _sharedMedia!.add(media);

      _sharedText = null;

      // media.thumbnail =
      // (await VideoCacheService.cacheTempVideoPreview(media.path, 0)).path;
    }

    ///recursive call
    _showShare();
  }

  void _imageCachedFromString(String path) async {
    _sharedMedia = MediaCollection();
    _sharedMedia!.add(Media(path: path, mediaType: MediaType.image));

    _sharedText = null;

    ///recursive call
    _showShare();
  }

  void _openVaultObjectDisplay(
    DisplayType displayType, {
    String sharedText = '',
    CircleObject? scrollToObject,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => VaultObjectDisplay(
              circleAlbumBloc: _circleAlbumBloc,
              displayType: displayType,
              send: _send,
              circleListBloc: _circleListBloc,
              userCircleCache: widget.userCircleCache,
              circleRecipeBloc: _circleRecipeBloc,
              userCircleBloc: _userCircleBloc,
              userFurnace: widget.userFurnace,
              export: _export,
              deleteObject: _deleteObject,
              scrollToObject: scrollToObject,
              circleObjects: _circleObjects,
              refresh: _refresh,
              onNotification: onNotification,
              circleFileBloc: _circleFileBloc,
              circleObjectBloc: _circleObjectBloc,
              downloadFile: _downloadFile,
              pickFiles: _pickFiles,
              globalEventBloc: _globalEventBloc,
              videoControllerBloc: _videoControllerBloc,
              videoControllerDesktopBloc: _videoControllerDesktopBloc,
              circleVideoBloc: _circleVideoBloc,
              sharedText: sharedText,
              sendLink: _sendLink,
              circleImageBloc: _circleImageBloc,
              unpinObject: _unpinObject,
              shuffle: false,
              key: GlobalKey(),
            ),
      ),
    );
  }

  ///called when an object is shared to this Circle
  void _showShare() async {
    if (_sharedMedia != null) {
      if (_alreadySharedMedia != _sharedMedia) {
        ///image cropper makes this fire twice
        _alreadySharedMedia = _sharedMedia;

        if (_sharedMedia!.isEmpty) {
          return;
        }

        if (_circle.type == CircleType.VAULT) {
          _showVaultPreviewer();
        } else {
          _showPreviewer(_sharedMedia!);
        }
        //  _showPanelWithShare();
      }
    } else if (_sharedGif != null) {
      if (_circle.type == CircleType.VAULT) {
        _showVaultPreviewer();
      } else {
        MediaCollection mediaCollection = MediaCollection();
        mediaCollection.media.add(
          Media(
            mediaType: MediaType.gif,
            path: _sharedGif!.url,
            height: _sharedGif!.height!,
            width: _sharedGif!.width!,
          ),
        );
        _showPreviewer(mediaCollection);
      }
      // else {
      //   _previewGiphy(_sharedGif!);
      // }
    } else if (_sharedText != null) {
      ///check to see if this is a shared link to image/video

      if (FileSystemService.isFile(_sharedText!)) {
        DialogCaching.showCaching(
          context,
          'Please wait',
          _sharedText!,
          true,
          _fileCachedFromString,
        );
      } else if (FileSystemService.isStringImage(_sharedText!)) {
        DialogCaching.showCaching(
          context,
          'Please wait',
          _sharedText!,
          false,
          _imageCachedFromString,
        );
      } else {
        if (_circle.type == CircleType.VAULT) {
          if (_sharedText!.isNotEmpty) {
            if (isLink(_sharedText!)) {
              _openVaultObjectDisplay(
                DisplayType.Links,
                sharedText: _sharedText!,
              );
            } else {
              _openVaultObjectDisplay(
                DisplayType.Notes,
                sharedText: _sharedText!,
              );
            }
          }
        } else {
          setState(() {
            _message.text = _sharedText!;
            _sendEnabled = true;
            //_cancelEnabled = true;

            FocusScope.of(context).requestFocus(_focusNode);
          });
        }
      }
    } else if (_sharedVideo != null) {
      _setupVideoPreview(_sharedVideo!.path);
    }
  }

  void _showPreviewer(MediaCollection mediaCollection) async {
    _refreshEnabled = false;

    if (widget.wall == false || widget.wallFurnaces.length == 1) {
      _selectedNetworks.clear();
      if (widget.wallFurnaces.length == 1) {
        _selectedNetworks.add(widget.wallFurnaces[0]);
      } else {
        _selectedNetworks.add(widget.userFurnace);
      }
    }

    if (mounted) {
      SelectedMedia? selectedImages = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ImagePreviewer(
                hiRes: _hiRes,
                streamable: _streamable,
                timer: _timer,
                setTimer: _setTimer,
                showCaption: _circle.type == CircleType.VAULT ? false : true,
                setScheduled: _setScheduled,
                wall: widget.wall,
                caption: _message.text,
                setNetworks: _setSelectedNetworks,
                screenName:
                    widget.wall
                        ? widget.wallFurnaces.length == 1
                            ? widget.wallFurnaces[0].alias!
                            : "Network Feed"
                        : widget.userCircleCache.prefName ?? '',
                media: mediaCollection,
                userFurnaces:
                    widget.wallFurnaces.isEmpty
                        ? [widget.userFurnace]
                        : widget.wallFurnaces,
              ),
        ),
      );

      if (selectedImages != null) {
        _refreshEnabled = true;

        if (selectedImages.mediaCollection.isNotEmpty) {
          if (_circle.type == CircleType.VAULT) {
            _mediaCollection = selectedImages.mediaCollection;
            _send(overrideButton: true);
          } else if (widget.wall) {
            for (UserFurnace selectedNetwork in _selectedNetworks) {
              UserCircleCache userCircleCache = _getUserCircleCacheFromFurnace(
                selectedNetwork,
              );

              debugPrint(
                'InsideCircle._previewMedia: network userid: ${selectedNetwork.userid!}, userCircleCache: ${userCircleCache.usercircle!}, circle: ${userCircleCache.circle!}',
              );

              CircleObject newPost = _prepNewCircleObject(
                selectedNetwork,
                userCircleCache,
                caption: selectedImages.caption,
              );

              _send(
                vaultObject: newPost,
                mediaCollection: selectedImages.mediaCollection,
                overrideButton: true,
                album: selectedImages.album,
                message: selectedImages.caption,
                hiRes: selectedImages.hiRes,
                streamable: selectedImages.streamable,
              );
            }
          } else {
            _send(
              overrideButton: true,
              mediaCollection: selectedImages.mediaCollection,
              album: selectedImages.album,
              message: selectedImages.caption,
            );
          }
        }
      }

      setState(() {
        _showSpinner = false;
      });
    }
  }

  void _showVaultPreviewer() async {
    _refreshEnabled = false;

    if (_sharedGif != null) {
      _sharedMedia ??= MediaCollection();

      _sharedMedia!.add(Media(mediaType: MediaType.gif, path: _sharedGif!.url));

      _giphyOption = _sharedGif;
    }

    SelectedMedia? selectedImages = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ImagePreviewer(
              hiRes: _hiRes,
              streamable: _streamable,
              timer: _timer,
              showCaption: _circle.type == CircleType.VAULT ? false : true,
              setTimer: _setTimer,
              setScheduled: _setScheduled,
              screenName: widget.userCircleCache.prefName ?? '',
              userFurnaces:
                  widget.wallFurnaces.isEmpty
                      ? [widget.userFurnace]
                      : widget.wallFurnaces,
              media: _sharedMedia!,
            ),
      ),
    );

    if (selectedImages != null) {
      _refreshEnabled = true;

      if (_circle.type == CircleType.VAULT) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => GalleryHolder(
                  refresh: _refresh,
                  memCacheObjects: widget.memCacheObjects,
                  onNotification: onNotification,
                  searchGiphy: _selectGif,
                  generateImage: _generate,
                  userCircleCache: widget.userCircleCache,
                  userFurnace: widget.userFurnace,
                  circleObjects: _circleObjects,
                  globalEventBloc: _globalEventBloc,
                  captureMedia: _captureMedia,
                  selectMedia: _pickImagesAndVideos,
                  circleObjectBloc: _circleObjectBloc,
                ),
          ),
        );

        if (_sharedGif != null) {
          _setSelectedMediaVariables(selectedImages);
          _send(overrideButton: true);
        } else {
          _mediaCollection = selectedImages.mediaCollection;
          _send(overrideButton: true);
        }
      }
      // } else {
      //   if (selectedImages.mediaCollection.media.isNotEmpty) {
      //     _previewSelectedMedia(selectedImages);
      //   }
      // }
    }
  }

  void _downloadVideo(CircleObject circleObject) {
    setState(() {
      circleObject.retries = 0;
    });

    if (widget.wall) {
      _circleVideoBloc.downloadVideo(
        _getUserFurnace(circleObject),
        _getUserCircleCache(circleObject),
        circleObject,
      );
    } else {
      _circleVideoBloc.downloadVideo(
        widget.userFurnace,
        widget.userCircleCache,
        circleObject,
      );
    }
  }

  void _downloadFile(CircleObject circleObject) {
    setState(() {
      circleObject.retries = 0;
    });

    if (widget.wall) {
      _circleFileBloc.downloadFile(
        _getUserFurnace(circleObject),
        _getUserCircleCache(circleObject),
        circleObject,
      );
    } else {
      _circleFileBloc.downloadFile(
        widget.userFurnace,
        widget.userCircleCache,
        circleObject,
      );
    }
  }

  void _showReply(CircleObject circleObject) {
    if (widget.wall) {
      List<ReplyObject> replies =
          widget.replyObjects
              .where((element) => element.circleObjectID == circleObject.id)
              .toList();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => WallRepliesScreen(
                replyObjectBloc: _replyObjectBloc,
                circleObject: circleObject,
                userFurnace: circleObject.userFurnace!,
                refresh: _refresh,
                maxWidth: _maxWidth,
                userCircleCache: circleObject.userCircleCache!,
                fromReply: true,
                globalEventBloc: _globalEventBloc,
                replyObjects: replies,
                memberBloc: _memberBloc,
              ),
        ),
      );
    } else {
      setState(() {
        _clearPreviews();
        _sendEnabled = true;
        _replyObject = CircleObject(
          ratchetIndexes: [],
          creator: circleObject.creator,
          type: circleObject.type,
          body: circleObject.body,
        );

        if (_replyObject!.body == null) {
          _replyObject!.body = "";
        } else if (_replyObject!.body!.isNotEmpty) {
          _replyObject!.body = "'${circleObject.body!}'";
        }

        if (_replyObject!.type == CircleObjectType.CIRCLEMESSAGE) {
          if (circleObject.subType == SubType.LOGIN_INFO) {
            _replyObject!.body = "[credential] ${circleObject.subString1!}";
          }
        } else if (_replyObject!.type == CircleObjectType.CIRCLECREDENTIAL) {
          _replyObject!.body = "[credential] ${circleObject.subString1!}";
        } else if (_replyObject!.type == CircleObjectType.CIRCLEIMAGE) {
          _replyObject!.body = circleObject.body ?? '';
          if (circleObject.image != null)
            _replyObject!.id = circleObject.id!;
          else
            _replyObject!.body = '[image]';
        } else if (_replyObject!.type == CircleObjectType.CIRCLEVIDEO) {
          _replyObject!.body = circleObject.body ?? '';
          if (circleObject.video != null)
            _replyObject!.id = circleObject.id!;
          else
            _replyObject!.body = '[video]';
        } else if (_replyObject!.type == CircleObjectType.CIRCLEALBUM) {
          _replyObject!.body = circleObject.body ?? '';
          if (circleObject.album != null) {
            _replyObject!.id = circleObject.id!;
          } else {
            _replyObject!.body = '[album]';
          }
        } else if (_replyObject!.type == CircleObjectType.CIRCLELIST) {
          if (circleObject.list!.name!.isNotEmpty)
            _replyObject!.body = '[list] ${circleObject.list!.name!}';
          else
            _replyObject!.body = '[list]';
        } else if (_replyObject!.type == CircleObjectType.CIRCLEGIF) {
          _replyObject!.body = circleObject.body ?? '';
          if (circleObject.gif != null)
            _replyObject!.id = circleObject.id!;
          else
            _replyObject!.body = '[gif]';
        } else if (_replyObject!.type == CircleObjectType.CIRCLERECIPE) {
          if (circleObject.recipe!.name != null) {
            _replyObject!.body = '[recipe] ${circleObject.recipe!.name!}';
          } else
            _replyObject!.body = '[recipe]';
        } else if (_replyObject!.type == CircleObjectType.CIRCLELINK) {
          _replyObject!.body = '[link]';
          if (circleObject.link!.url != null) {
            _replyObject!.body = circleObject.link!.url;
            _replyObject!.id = circleObject.id!;
          }
        } else if (_replyObject!.type == CircleObjectType.CIRCLEVOTE) {
          if (circleObject.vote!.question != null) {
            _replyObject!.body = '[vote] ${circleObject.vote!.question!}';
          } else
            _replyObject!.body = '[vote]';
        } else if (_replyObject!.type == CircleObjectType.CIRCLEEVENT) {
          if (circleObject.event!.title != null) {
            _replyObject!.body = '[event] ${circleObject.event!.title}';
          } else
            _replyObject!.body = '[event]';
        } else if (_replyObject!.type == CircleObjectType.CIRCLEFILE) {
          if (circleObject.file!.name != null) {
            _replyObject!.body = '[file] ${circleObject.file!.name!}';
          } else
            _replyObject!.body = '[file]';
        }

        FocusScope.of(context).requestFocus(_focusNode);
        //_focusNode.requestFocus();
      });
    }
  }

  void _playVideo(CircleObject circleObject) async {
    setState(() {
      _clearPreviews();
    });

    _showFullScreenImage(circleObject);
  }

  void _streamVideo(CircleObject circleObject) {
    setState(() {
      _clearPreviews();
      // circleObject.video!.videoState = VideoStateIC.BUFFERING;
    });
    //_circleVideoBloc.getStreamingUrl(widget.userFurnace, circleObject);

    _showFullScreenImage(circleObject);
  }

  _getDateTime() async {
    DateTime? date = await Pickers.getDate(
      context,
      blankDate(_jumpToDate) ? DateTime.now() : _jumpToDate!,
    );

    // DateTime? date = await showDatePicker(
    //   context: context,
    //   firstDate: DateTime(2000),
    //   lastDate: DateTime(DateTime.now().year + 5),
    //   initialDate: blankDate(_jumpToDate) ? DateTime.now() : _jumpToDate!,
    // );

    if (date != null) {
      setState(() {
        _jumpToDate = DateTime(date.year, date.month, date.day);

        int index = CircleObjectCollection.findIndexByDate(
          _circleObjects,
          _jumpToDate!,
        );

        bool scroll = false;

        if (index == _circleObjects.length - 1) {
          String convertedDate = intl.DateFormat(
            "yyyy-MM-dd",
          ).format(_circleObjects[index].created!);
          String convertedJumpDate = intl.DateFormat(
            "yyyy-MM-dd",
          ).format(_jumpToDate!);

          if (convertedDate == convertedJumpDate)
            scroll = true;
          else {
            //fetch from last cache date to jumpDate
            _circleObjectBloc.requestJumpTo(
              _currentCircle!,
              widget.userFurnace,
              _circleObjects[_circleObjects.length - 1].created!,
              _jumpToDate!,
            );

            _showJumpToDateSpinner = true;
            FormattedSnackBar.showSnackbarWithContext(
              context,
              'this could take a sec...',
              "",
              3,
              false,
            );
          }
        } else {
          scroll = true;
        }

        if (scroll) {}
        //jump, weeeeeeee
        if (scroll)
          _itemScrollController.scrollTo(
            index: index,
            duration: const Duration(milliseconds: _scrollDuration),
            curve: Curves.easeInOutCubic,
          );
      });
    }
  }

  bool blankDate(DateTime? due) {
    if (due == null) return true;

    return (due.difference(DateTime(1)).inSeconds == 0);
  }

  _fetchOlderThan() {
    if (widget.wall) {
      for (UserCircleCache userCircleCache in widget.wallUserCircleCaches) {
        List<CircleObject> circleObjects =
            _circleObjects
                .where(
                  (element) =>
                      element.circle!.id == userCircleCache.cachedCircle!.id,
                )
                .toList();

        if (circleObjects.isNotEmpty) {
          CircleObject oldest = circleObjects[circleObjects.length - 1];

          var userFurnace = widget.wallFurnaces.firstWhere(
            (element) => element.pk == userCircleCache.userFurnace,
          );

          _circleObjectBloc.requestOlderThan(
            userCircleCache.cachedCircle!.id!,
            userFurnace,
            oldest.created!,
          );
        }
      }
    } else {
      CircleObject oldest = _circleObjects[_circleObjects.length - 1];

      _circleObjectBloc.requestOlderThan(
        _currentCircle!,
        widget.userFurnace,
        oldest.created!,
      );
    }
  }

  bool onNotification(ScrollEndNotification t) {
    try {
      if (t.metrics.pixels > 0 && t.metrics.atEdge) {
        _fetchOlderThan();

        if (_circleObjects.length > 40) {
          FormattedSnackBar.showSnackbarWithContext(
            context,
            'checking for additional posts...',
            "",
            2,
            false,
          );
        }
        return true;
      } else {
        //if there is only a few objects, there is no scroll option so just run the stuff
        if (_circleObjects.length < 10 && _thereAreNoOlderPosts == false) {
          _fetchOlderThan();
          return true;
        }
      }

      if (_circle.type != CircleType.VAULT /*&& widget.wall == false*/ ) {
        ///user scrolled to bottom of list. Add anything in the queue
        if (_itemPositionsListener.itemPositions.value.isNotEmpty &&
            _itemPositionsListener.itemPositions.value.first.index == 0) {
          _addObjects(_waitingOnScroller, true);
          _waitingOnScroller.clear();
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('InsideCircle.onNotification: $err');
    }

    return false;
  }

  bool isLink(String text) {
    String url = '';
    try {
      final exp = RegExp(
        r"((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?",
      );

      Iterable<RegExpMatch> matches = exp.allMatches(text);

      for (var match in matches) {
        url = text.substring(match.start, match.end);

        break;
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("InsideCircle._checkForLink: $err");
    }

    return url.isNotEmpty;
  }

  CircleLink? _checkReplyForLink(CircleObject obj) {
    CircleLink? circleLink;

    try {
      final exp = RegExp(
        r"((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?",
      );

      Iterable<RegExpMatch> matches = exp.allMatches(obj.reply!);

      for (var match in matches) {
        circleLink = CircleLink();
        circleLink.url = obj.reply!.substring(match.start, match.end);

        break;
      }

      if (circleLink != null) {
        if (circleLink.url != null) {
          //String temp = obj.reply!.replaceAll(circleLink.url!, '');

          //if (temp != '') circleLink.body = temp;

          if (obj.body != '') circleLink.body = obj.body;
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("InsideCircle._checkReplyForLink: $err");
    }

    return circleLink;
  }

  CircleLink? _checkForLink(String potential) {
    CircleLink? circleLink;

    try {
      final exp = RegExp(
        r"((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?",
      );

      Iterable<RegExpMatch> matches = exp.allMatches(potential);

      for (var match in matches) {
        circleLink = CircleLink();
        circleLink.url = potential.substring(match.start, match.end);

        ///Force a cert and let the broswer through an error if there isn't one
        circleLink.url!.replaceFirst('http://', 'https://');

        ///did they type a link and forget the https?
        if (circleLink.url!.contains('https://') == false) {
          ///tack it on the front
          circleLink.url = 'https://${circleLink.url!}';
        }

        break;
      }

      if (circleLink != null) {
        if (circleLink.url != null) {
          String temp = potential.replaceAll(circleLink.url!, '');

          //if (temp != null) {
          if (temp != '') circleLink.body = temp;
          //}
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("InsideCircle._checkForLink: $err");
    }

    return circleLink;
  }

  _getUserCircleCacheFromFurnace(UserFurnace userFurnace) {
    if (widget.wall) {
      int index = widget.wallUserCircleCaches.indexWhere(
        (element) => element.userFurnace! == userFurnace.pk,
      );

      return widget.wallUserCircleCaches[index];
    } else {
      return widget.userCircleCache;
    }
  }

  _selectNetworkCallback(List<UserFurnace> selectedNetworks) async {
    _sendEnabled = false;
    for (UserFurnace userFurnace in selectedNetworks) {
      CircleObject circleObject = _prepNewCircleObject(
        userFurnace,
        _getUserCircleCacheFromFurnace(userFurnace),
      );

      _send(
        overrideButton: true,
        vaultObject: circleObject,
        message: circleObject.body!,
      );
    }
  }

  _selectNetworks() async {
    await DialogSelectNetworks.selectNetworks(
      context: context,
      networks: widget.wallFurnaces,
      callback: _selectNetworkCallback,
      existingNetworksFilter: [],
    );
  }

  _send({
    overrideButton = false,
    CircleObject? vaultObject,
    MediaCollection? mediaCollection,
    String message = '',
    bool album = false,
    bool hiRes = false,
    bool streamable = false,
  }) async {
    debugPrint("...........START_send: ${DateTime.now()}");

    debugPrint('hiRes: $_hiRes');
    debugPrint('streamable: $_streamable');

    ///TODO this variable should be stored with each type individually
    _hiRes = hiRes;
    _streamable = streamable;

    if (_mediaCollection != null) {
      if (!PremiumFeatureCheck.checkFileSizeRestriction(
        context,
        _hiRes,
        _mediaCollection!,
      )) {
        return;
      }
    }

    String text = _message.text;

    if (_sendEnabled == false && overrideButton == false) {
      ///there is a voice to text Flutter issue on iOS, so also check the text field
      if (Platform.isIOS) {
        if (_message.text.isEmpty) {
          debugPrint("...........returning: ${DateTime.now()}");
          return;
        }
      } else {
        debugPrint("...........returning: ${DateTime.now()}");
        return;
      }
    }
    _sendEnabled = false;

    _firebaseBloc.removeNotification();

    CircleObject? circleObject;

    if (_editingObject != null) {
      circleObject = _editingObject;

      await _editAndClear(circleObject!);
    } else {
      if (vaultObject != null) {
        circleObject = vaultObject;
        //circleObject.body = message;
      } else if (widget.wall && vaultObject == null) {
        ///condition where users is in the Feed and posts a message (slide up panel not involved, so no network set)
        if (widget.wallFurnaces.length == 1) {
          ///just use the one network
          circleObject = _prepNewCircleObject(
            widget.wallFurnaces[0],
            widget.userCircleCache,
            caption: message,
          );
        } else {
          _selectNetworks();
          _sendEnabled = true;
          return;
        }
      } else
        circleObject = _prepNewCircleObject(
          widget.userFurnace,
          widget.userCircleCache,
          caption: message,
        );

      if (_timer != UserDisappearingTimer.OFF) {
        circleObject.timer = _timer;
      }

      if (_scheduledDate != null) {
        circleObject.scheduledFor = _scheduledDate;
        if (_scheduledDate == _lastScheduled) {
          _increment = _increment! + 1;
        } else {
          _increment = 0;
        }
        circleObject.dateIncrement = _increment!;
        _lastScheduled = _scheduledDate;
      }

      circleObject.emojiOnly = await EmojiUtil.checkForOnlyEmojis(
        _message.text,
      );

      CircleLink? circleLink;
      if (circleObject.link != null) {
        circleLink = circleObject.link;
      } else {
        circleLink = _checkForLink(circleObject.body!);
      }

      if (circleLink != null) {
        _sendLink(circleLink, circleObject);
      } else if (widget.wall &&
          circleObject.type == CircleObjectType.CIRCLELINK) {
        _sendAndClear(circleObject);
      } else if (_giphyOption != null) {
        CircleObject circleObject = _prepNewCircleObject(
          vaultObject != null ? vaultObject.userFurnace! : widget.userFurnace,
          vaultObject != null
              ? vaultObject.userCircleCache!
              : widget.userCircleCache,
        );
        if (_timer != UserDisappearingTimer.OFF) {
          circleObject.timer = _timer;
        }
        circleObject.gif = CircleGif();
        circleObject.type = CircleObjectType.CIRCLEGIF;
        circleObject.gif!.giphy = _giphyOption!.url;
        circleObject.gif!.width = _giphyOption!.width;
        circleObject.gif!.height = _giphyOption!.height;

        _sendAndClear(circleObject);
      } else if (_photo != null ||
          _mediaCollection != null ||
          _keyboardMediaCollection.isNotEmpty ||
          _image != null ||
          mediaCollection != null) {
        //_mediaCollection ??= mediaCollection;
        mediaCollection ??= _mediaCollection;

        if (mediaCollection != null) mediaCollection.album = album;

        if (_keyboardMediaCollection.isNotEmpty) {
          mediaCollection ??= MediaCollection();
          List<Media> list = _keyboardMediaCollection!.media;
          for (Media m in list) {
            mediaCollection.add(m);
          }
        }

        circleObject.type = _circleMediaBloc.getType(mediaCollection!.media[0]);
        //circleObject.hiRes = _hiRes;

        //debugPrint(circleObject.userCircleCache!.circlePath!);

        _sendAndClear(circleObject, mediaCollection: mediaCollection);

        //circleObject = _prepNewCircleObject(skipBody: true);
      } else if (_video != null) {
        circleObject.type = CircleObjectType.CIRCLEVIDEO;
        //_showSpinner = true;

        _sendAndClear(circleObject);

        circleObject = _prepNewCircleObject(
          vaultObject != null ? vaultObject.userFurnace! : widget.userFurnace,
          vaultObject != null
              ? vaultObject.userCircleCache!
              : widget.userCircleCache,
          skipBody: true,
        );
      } else {
        if (_message.text.trim().isNotEmpty || vaultObject != null) {
          circleObject.type = CircleObjectType.CIRCLEMESSAGE;

          CircleObjectCollection.addObjects(
            _circleObjects,
            [circleObject],
            _circle.id!,
            widget.wallFurnaces,
            widget.wallUserCircleCaches,
          );
          //_circleObjects.add(circleObject);

          _sendAndClear(circleObject);
        }
      }
    }
    //}
  }

  // Future<CircleObject> _prepNewCircleObject(
  //     String caption, UserCircleCache userCircleCache, UserFurnace userFurnace,
  //     {bool skipBody = false}) async {
  //   String messageText = '';
  //
  //   if (!skipBody) messageText = caption;
  //
  //   CircleObject newCircleObject = CircleObject.prepNewCircleObject(
  //       userCircleCache, userFurnace, messageText, 0, null);
  //
  //   newCircleObject.emojiOnly = await EmojiUtil.checkForOnlyEmojis(caption);
  //
  //   return newCircleObject;
  // }
  //
  CircleObject _prepNewCircleObject(
    UserFurnace userFurnace,
    UserCircleCache userCircleCache, {
    bool skipBody = false,
    String caption = '',
  }) {
    String messageText = '';

    if (!skipBody) {
      if (caption.isNotEmpty) {
        messageText = caption;
      } else {
        messageText = _message.text;
      }
    }

    CircleObject newCircleObject = CircleObject.prepNewCircleObject(
      userCircleCache,
      userFurnace,
      messageText,
      _circleObjects.length - 1,
      _replyObject,
    );

    newCircleObject.taggedUsers = taggedUsers;

    return newCircleObject;
  }

  _getUserFurnace(CircleObject circleObject) {
    late UserFurnace userFurnace;
    late UserCircleCache userCircleCache;

    if (widget.wall) {
      userFurnace = circleObject.userFurnace!;
    } else {
      userFurnace = widget.userFurnace;
    }

    return userFurnace;
  }

  _getUserCircleCache(CircleObject circleObject) {
    late UserCircleCache userCircleCache;

    if (widget.wall) {
      userCircleCache = circleObject.userCircleCache!;
    } else {
      userCircleCache = widget.userCircleCache;
    }

    return userCircleCache;
  }

  void _retry(CircleObject circleObject) async {
    UserFurnace userFurnace = _getUserFurnace(circleObject);
    UserCircleCache userCircleCache = _getUserCircleCache(circleObject);

    if (circleObject.type == CircleObjectType.CIRCLEIMAGE) {
      _globalEventBloc.addThumbandFull(circleObject);

      setState(() {
        circleObject.retries = 0;
      });

      ///wait 1 second
      await Future.delayed(const Duration(seconds: 1));

      //TODO figure out how to distinguish between an upload and a download using failed state
      if (circleObject.creator!.id! == userFurnace.userid!) {
        String thumbnail = ImageCacheService.returnThumbnailPath(
          userCircleCache.circlePath!,
          circleObject,
        );
        String full = ImageCacheService.returnFullImagePath(
          userCircleCache.circlePath!,
          circleObject,
        );

        _globalEventBloc.removeOnError(circleObject);

        _circleImageBloc.retryUpload(
          userCircleCache,
          userFurnace,
          circleObject,
          File(full),
          File(thumbnail),
          _circleObjectBloc,
        );
      } else {
        _circleImageBloc.retryDownload(
          userFurnace,
          userCircleCache,
          circleObject,
        );
      }
    } else if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
      setState(() {
        circleObject.retries = 0;
      });

      if (circleObject.id == null) {
        //upload
        String thumbnail = VideoCacheService.returnPreviewPath(
          circleObject,
          userCircleCache.circlePath!,
        );

        String full = VideoCacheService.returnVideoPath(
          circleObject,
          userCircleCache.circlePath!,
          circleObject.video!.extension!,
        );

        _circleVideoBloc.retryUpload(
          userCircleCache,
          userFurnace,
          circleObject,
          File(full),
          File(thumbnail),
          _circleObjectBloc,
        );
      } else {
        //download
        _circleVideoBloc.processDownloadFailed(
          userFurnace,
          userCircleCache,
          circleObject,
        );
      }
    }
  }

  _panelClosed() {
    _refreshEnabled = true;
    _panelOpen = false;
  }

  // _closePanel() {
  //   ///this will automatically call _panelClosed
  //   Navigator.pop(context);
  // }

  void _editObject(CircleObject circleObject) async {
    String? body;
    //bool ready = false;
    _clearPreviews();

    _setSessionKeys(circleObject);

    setState(() {
      _showTextField = true;
    });

    if (circleObject.type == CircleObjectType.CIRCLEMESSAGE) {
      body = circleObject.body;
    } else if (circleObject.type == CircleObjectType.CIRCLELINK) {
      if (circleObject.link != null) body = circleObject.link!.url;

      if (circleObject.body != null) body = '${circleObject.body!} ${body!}';
    } else if (circleObject.type == CircleObjectType.CIRCLEIMAGE) {
      body = circleObject.body;
      //
      // _image = File(ImageCacheService.returnFullImagePath(
      //     widget.userCircleCache.circlePath!,
      //     circleObject)); //circleObject.image.thumbnail;
      //
      // _imagePreview = true;
      //ready = true;
    } else if (circleObject.type == CircleObjectType.CIRCLEGIF) {
      body = circleObject.body;
    } else if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
      body = circleObject.body;
    }

    // if (body != null || ready) {
    setState(() {
      _editingObject = circleObject;

      if (body != null) _message.text = body;
      _sendEnabled = true;
      //_cancelEnabled = true;
      _editing = true;

      //FocusScope.of(context).requestFocus(_focusNode);
      _focusNode.requestFocus();
    });
    //}
  }

  _editAndClear(CircleObject circleObject) async {
    //_closePanel();

    bool ready = false;
    String body = _message.text;

    circleObject.emojiOnly = await EmojiUtil.checkForOnlyEmojis(_message.text);
    CircleLink? circleLink = _checkForLink(body);

    if (circleLink != null) {
      circleObject.body = '';
      if (circleLink.body != null) circleObject.body = circleLink.body;

      circleObject.link = circleLink;
      circleObject.type = CircleObjectType.CIRCLELINK;

      ready = true;
    } else if (_giphyOption != null) {
      //_giphyBloc.giffySearch(_message.text);
      //circleObject.type = CircleObjectType.CIRCLEGIF;
    } else if (_photo != null ||
        _image != null ||
        circleObject.type == CircleObjectType.CIRCLEIMAGE) {
      circleObject.type = CircleObjectType.CIRCLEIMAGE;
      circleObject.body = _message.text;

      if (_photo != null) {
      } else if (_image != null &&
          _image!.path !=
              ImageCacheService.returnFullImagePath(
                widget.wall
                    ? circleObject.userCircleCache!.circlePath!
                    : widget.userCircleCache.circlePath!,
                circleObject,
              )) {
        _circleImageBloc.put(
          widget.wall ? circleObject.userCircleCache! : widget.userCircleCache,
          widget.wall ? circleObject.userFurnace! : widget.userFurnace,
          circleObject,
          _circleObjectBloc,
          _image!,
        );
      } else {
        _circleObjectBloc.updateCircleImageNoImageChange(
          widget.wall ? circleObject.userCircleCache! : widget.userCircleCache,
          widget.wall ? circleObject.userFurnace! : widget.userFurnace,
          circleObject,
        );
      }

      _clear(false);
    } else {
      if (_message.text.isNotEmpty) {
        if (body.isNotEmpty) {
          circleObject.body = _message.text;
          //circleObject.type = CircleObjectType.CIRCLEMESSAGE;
          ready = true;
        }
      }
    }

    if (ready) {
      //update the object
      _circleObjectBloc.updateCircleObject(
        circleObject,
        widget.wall ? circleObject.userFurnace! : widget.userFurnace,
      );

      _clear(false);
    }
  }

  _uploadGifs(List<Media> gifs, CircleObject circleObject) {
    bool first = true;

    for (Media gif in gifs) {
      late CircleObject gifObject;
      if (widget.wall) {
        gifObject = _prepNewCircleObject(
          circleObject.userFurnace!,
          circleObject.userCircleCache!,
        );
        gifObject.userFurnace = circleObject.userFurnace;
        gifObject.userCircleCache = circleObject.userCircleCache;
      } else {
        gifObject = _prepNewCircleObject(
          widget.userFurnace,
          widget.userCircleCache,
        );
      }

      if (first) {
        gifObject.body = circleObject.body;
        first = false;
      }
      gifObject.gif = CircleGif();
      gifObject.type = CircleObjectType.CIRCLEGIF;
      gifObject.type = CircleObjectType.CIRCLEGIF;
      gifObject.gif!.giphy = gif.path;
      gifObject.gif!.width = gif.width;
      gifObject.gif!.height = gif.height;

      _sendAndClear(gifObject);
    }
  }

  _uploadImages(List<Media> images, CircleObject circleObject) {
    _circleImageBloc.uploadCircleImages(
      widget.wall ? circleObject.userCircleCache! : widget.userCircleCache,
      widget.wall ? circleObject.userFurnace! : widget.userFurnace,
      circleObject,
      _circleObjectBloc,
      images,
      //_mediaCollection!.getFiles(MediaType.image),
      _hiRes,
    );
  }

  _uploadVideos(List<Media> videos, CircleObject circleObject) {
    _circleVideoBloc.uploadVideos(
      widget.wall ? circleObject.userCircleCache! : widget.userCircleCache,
      widget.wall ? circleObject.userFurnace! : widget.userFurnace,
      circleObject,
      _circleObjectBloc,
      videos,
    );
  }

  _uploadFiles(List<Media> files, CircleObject circleObject) {
    _circleFileBloc.uploadFiles(
      widget.wall ? circleObject.userCircleCache! : widget.userCircleCache,
      widget.wall ? circleObject.userFurnace! : widget.userFurnace,
      circleObject,
      _circleObjectBloc,
      files,
    );
  }

  _sendAndClear(
    CircleObject circleObject, {
    bool lastObject = true,
    MediaCollection? mediaCollection,
  }) async {
    debugPrint("...........SEND AND CLEAR: ${DateTime.now()}");

    if (lastObject) {
      setState(() {
        try {
          if (_waitingOnScroller.isNotEmpty) {
            _addObjects(_waitingOnScroller, true);
            _waitingOnScroller.clear();
          } else if (_itemScrollController.isAttached &&
              _circleObjects.isNotEmpty &&
              _circle.type != CircleType.VAULT) {
            _itemScrollController.scrollTo(
              index: 0,
              duration: const Duration(milliseconds: 10),
              curve: Curves.easeInOutCubic,
            );
          }
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
        }
      });
    }

    if (_photo != null) {
      _circleImageBloc.post(
        widget.userCircleCache,
        widget.userFurnace,
        circleObject,
        _circleObjectBloc,
        _photo!,
        _hiRes,
      );
    } else if (_image != null) {
      _circleImageBloc.post(
        widget.userCircleCache,
        widget.userFurnace,
        circleObject,
        _circleObjectBloc,
        _image!,
        _hiRes,
      );
    } else if (mediaCollection != null) {
      setState(() {
        _showSpinner = true;
      });
      await Future.delayed(const Duration(milliseconds: 100));

      if (mediaCollection.album &&
          _timer != UserDisappearingTimer.ONE_TIME_VIEW) {
        ///album
        _circleAlbumBloc.makeAlbum(
          circleObject,
          widget.userCircleCache,
          widget.userFurnace,
          mediaCollection.media,
          _hiRes,
          _circleObjectBloc,
        );
        setState(() {
          _showSpinner = false;
        });
      } else {
        ///process all the objects at once to get the right order and then upload
        _circleMediaBloc.processAndUploadMedia(
          widget.wall ? circleObject.userCircleCache! : widget.userCircleCache,
          widget.wall ? circleObject.userFurnace! : widget.userFurnace,
          circleObject,
          mediaCollection.media,
          _circleObjectBloc,
          _hiRes,
          _sendAndClear,
        );
      }
    } else {
      ///save the object
      _circleObjectBloc.saveCircleObject(
        _globalEventBloc,
        widget.wall ? circleObject.userFurnace! : widget.userFurnace,
        widget.wall ? circleObject.userCircleCache! : widget.userCircleCache,
        circleObject,
      );

      debugPrint("...........SAVEOBJECT: ${DateTime.now()}");
    }

    if (lastObject) {
      setState(() {
        _clear(false);
      });
    }

    if (_circle.type == CircleType.VAULT) {
      _circleObjectBloc.sinkVaultRefresh();
    }
  }

  _clearPreviews() {
    if (_previewControllerBloc.videoControllers.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _previewControllerBloc.disposeLast();
      });
    }
    _giphyOption = null;
    _sharedText = null;
    _sharedMedia = null;
    _sharedGif = null;

    //_assetsPreview = false;
    _photoPreview = false;
    _imagePreview = false;
    //_linkPreview = false;
    _photo = null;
    _image = null;
    //_asset = null;
    _mediaCollection = null;
    _keyboardMediaCollection = MediaCollection();
    _hiRes = false;
    _streamable = false;
    _videoPreview = false;
    _video = null;
    _videoStreamOnly = false;
    _videoStreamable = [true, false];

    _membersList = false;

    _orientationNeeded = false;
  }

  _closeKeyboard() {
    if (mounted) {
      FocusScope.of(context).requestFocus(FocusNode());
    }
  }

  _clear(bool closeKeyboard) {
    setState(() {
      _message.text = '';
      _message.clear();
      _sendEnabled = false;
      _editingObject = null;
      //_cancelEnabled = false;
      _editing = false;
      taggedUsers = [];
      //_showEmojiPicker = false;
      if (_lastSelected != null) _lastSelected!.showOptionIcons = false;
      _replyObject = null;
      _clearPreviews();
    });

    if (closeKeyboard) _closeKeyboard();

    if (globalState.isDesktop()) {
      _focusNode.requestFocus();
    }
  }

  _panelCollapsed() {
    _refreshEnabled = true;

    setState(() {
      _showTextField = true;
      if (_message.text.isNotEmpty) {
        _sendEnabled = true;
      }
    });
  }

  _clearNow() {
    _clear(true);
  }

  _sendLink(CircleLink circleLink, CircleObject? circleObject) {
    circleObject ??= _prepNewCircleObject(
      widget.userFurnace,
      widget.userCircleCache,
    );
    circleObject.body = '';
    if (circleLink.body != null) circleObject.body = circleLink.body;

    circleObject.link = circleLink;
    circleObject.type = CircleObjectType.CIRCLELINK;

    CircleObjectCollection.addObjects(
      _circleObjects,
      [circleObject],
      _circle.id!,
      widget.wallFurnaces,
      widget.wallUserCircleCaches,
    );

    _sendAndClear(circleObject);
  }

  checkStayOrGo() {
    ///remove auto go home if on desktop
    if (globalState.isDesktop()) return;

    if ((widget.userCircleCache.hidden! || widget.userCircleCache.guarded!) &&
        _refreshEnabled) {
      _refreshEnabled = false;
      _goHome(true, forceScratchLoad: false);
    }
  }

  _setLastAccessed() {
    if (_circleObjects.isNotEmpty) {
      DateTime lastItemUpdate = _circleObjects[0].lastUpdate!;

      ///make sure this isn't after the userCache lastItemUpdate, for example in the case of a list edit or reaction
      if (_circleObjects[0].lastUpdate!.compareTo(
            widget.userCircleCache.lastItemUpdate!,
          ) <
          0) {
        lastItemUpdate = widget.userCircleCache.lastItemUpdate!;
      }

      widget.userCircleCache.showBadge = false;
      widget.userCircleCache.lastItemUpdate = lastItemUpdate;
      widget.userCircleCache.lastLocalAccess = lastItemUpdate;
    }
  }

  _turnoffBadgeAndSetLastAccess(bool updateServer) {
    if (_circleObjects.isNotEmpty) {
      _setLastAccessed();
      _userCircleBloc.setLastAccessed(
        widget.userFurnace,
        widget.userCircleCache,
        widget.userCircleCache.lastItemUpdate!,
        _circleObjectBloc,
        updateServer,
      );

      // debugPrint(
      //     'InsideCircle:goHome setLastAccessedLocalOnly passed ${DateTime.now()}');
    } else {
      // debugPrint(
      //     'InsideCircle:goHome turnOffBadge started ${DateTime.now()}');

      _userCircleBloc.turnOffBadge(
        widget.userCircleCache,
        DateTime.now(),
        _circleObjectBloc,
      );

      // debugPrint('InsideCircle:goHome turnOffBadge passed ${DateTime.now()}');
    }
  }

  _goHome(bool samePosition, {forceScratchLoad = false}) {
    if (_panelOpen) {
      _panelOpen = false;
      _refreshEnabled = true;
      Navigator.pop(context);
      return;
    }
    if (_popping) return;

    _popping = true;

    if (_message.text.isNotEmpty ||
        (_mediaCollection != null && _mediaCollection!.media.isNotEmpty) ||
        _giphyOption != null) {
      _circleObjectBloc.saveDraft(
        widget.userFurnace,
        widget.userCircleCache,
        _message.text,
        _mediaCollection,
        _giphyOption,
      );
    }

    // debugPrint('InsideCircle:goHome saveDraft passed ${DateTime.now()}');

    try {
      _firebaseBloc.removeNotification();
      _closeKeyboard();

      // debugPrint('InsideCircle:goHome _closeKeyboard passed ${DateTime.now()}');

      globalState.selectedHomeIndex = 0;

      if (!samePosition) {
        globalState.lastSelectedIndexDMs = null;
        globalState.lastSelectedIndexCircles = null;
        //globalState.userSetting.sortAlpha = null;
        globalState.lastSelectedFilter = null;
      }

      //await _userCircleBloc.turnOffBadge(widget.userCircleCache);

      _turnoffBadgeAndSetLastAccess(true);

      if (globalState.isDesktop()) {
        ///can't pop or the screen will be black
        ///need to tell circles.dart to reset
        if (widget.resetDesktopUI != null) widget.resetDesktopUI!();
      } else if (mounted &&
          (ModalRoute.of(context)!.isFirst || forceScratchLoad)) {
        debugPrint('***********POPPED****************');
        //came from push notification press or share to
        Navigator.pushReplacementNamed(
          context,
          '/home',
          // arguments: user,
        );
      } else {
        if (widget.dismissByCircle != null) {
          debugPrint(
            'InsideCircle:goHome dismissByCircle started ${DateTime.now()}',
          );
          widget.dismissByCircle!(widget.userCircleCache, widget.userFurnace);

          debugPrint(
            'InsideCircle:goHome dismissByCircle passed ${DateTime.now()}',
          );
        }

        debugPrint('***********POPPED****************');

        debugPrint('InsideCircle:goHome pop ${DateTime.now()}');
        Navigator.pop(context);

        if (widget.refresh != null) widget.refresh!();
      }

      debugPrint('InsideCircle:goHome stopped ${DateTime.now()}');
    } catch (err, trace) {
      _popping = false;
      LogBloc.insertError(err, trace);
      debugPrint('InsideCircle._goHome: $err');
    }
  }

  handleAppLifecycleState(AppLifecycleState msg) {
    switch (msg) {
      case AppLifecycleState.paused:
        if (!globalState.isDesktop()) {
          _previewControllerBloc.pauseLast();
          _videoControllerBloc.pauseLast();

          checkStayOrGo();
        }
        break;
      case AppLifecycleState.inactive:
        if (!globalState.isDesktop()) {
          _previewControllerBloc.pauseLast();
          _videoControllerBloc.pauseLast();
        }

        checkStayOrGo();
        break;
      case AppLifecycleState.resumed:
        if (_refreshEnabled) {
          // if (_circleObjects.isNotEmpty) {
          //
          //   _circleObjectBloc.sinkCacheNewerThan(
          //       widget.userCircleCache.circle!, _circleObjects[0].created!);
          // }

          if (mounted) {
            /*setState(() {
                _startSpinner(1);
              });

               */
          }

          _refreshCircleObjects();

          ///resend any failed to send items
          _circleObjectBloc.resendFailedCircleObjects(
            _globalEventBloc,
            widget.userFurnaces!,
          );

          debugPrint('InsideCircle.resumed');

          _userCircleBloc.fetchUserCircles(widget.userFurnaces!, true, true);

          if (mounted) {
            setState(() {
              _forceRefresh = true;
            });

            setState(() {
              _forceRefresh = false;
            });

            if (globalState.isDesktop()) {
              debugPrint("requesting focus");
              _focusNode.requestFocus();
            }
          }

          _firebaseBloc.removeNotification();
        }

        break;
      default:
        break;
    }
  }

  _displayMember(user, row) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 15, bottom: 10, right: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          InkWell(
            // replace with on tap add it to message
            // onTap: () {
            //   _showProfile(row);
            // },
            // onTap: () {
            //   _clickMember(row.username);
            // },
            child: Text(
              row.username!.length > 20
                  ? user.getUsernameAndAlias(globalState).substring(0, 19)
                  : user.getUsernameAndAlias(globalState),
              textScaler: TextScaler.linear(globalState.labelScaleFactor),
              style: TextStyle(
                fontSize: 17,
                color: Member.returnColor(user.id!, globalState.members),
                //color: //globalState.members.first.color

                // user.id! == widget.userFurnace.userid!
                //     ? globalState.theme.userObjectText
                //     : Member.returnColor(
                //     user.id!, globalState.members
              ),
            ),
          ),
        ],
      ),
    );
  }

  _createVote() async {
    _refreshEnabled = false;
    int dateInc = _increment != null ? _increment! + 1 : 0;

    UserFurnace stageFurnace = getStageFurnace();

    UserCircleCache userCircleCache = _getUserCircleCacheFromFurnace(
      stageFurnace,
    );

    CircleVote? circleVote = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => NewVote(
              userCircleCache: userCircleCache,
              userFurnaces: widget.wallFurnaces,
              userFurnace: stageFurnace,
              timer: CircleDisappearingTimer.OFF,
              circleVoteBloc: _voteBloc,
              scheduledFor: null,
              circle: userCircleCache.cachedCircle!,
              increment: dateInc,
              setNetworks: _setSelectedNetworks,
              wall: widget.wall,
            ),
      ),
    );

    if (circleVote != null) {
      if (widget.wall) {
        for (UserFurnace selectedNetwork in _selectedNetworks) {
          UserCircleCache userCircleCache = _getUserCircleCacheFromFurnace(
            selectedNetwork,
          );

          _voteBloc.createVote(
            userCircleCache,
            circleVote,
            selectedNetwork,
            null,
            null,
            userCircleCache.cachedCircle!,
            null,
          );
        }
      }
    }

    _clear(false);
    _refreshEnabled = true;
    _refreshCircleObjects();
  }

  _createRecipe() async {
    _refreshEnabled = false;
    int dateInc = _increment != null ? _increment! + 1 : 0;

    UserFurnace stageFurnace = getStageFurnace();

    UserCircleCache userCircleCache = _getUserCircleCacheFromFurnace(
      stageFurnace,
    );

    CircleObject? circleObject = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CircleRecipeScreen(
              userFurnaces:
                  widget.wall ? widget.wallFurnaces : [widget.userFurnace],
              userFurnace: stageFurnace,
              userCircleCache: userCircleCache,
              screenMode: ScreenMode.ADD,
              circleRecipeBloc: _circleRecipeBloc,
              globalEventBloc: _globalEventBloc,
              circleObjectBloc: _circleObjectBloc,
              timer: _timer,
              scheduledFor: _scheduledDate,
              increment: dateInc,
              replyObject: _replyObject,
              setNetworks: _setSelectedNetworks,
              wall: widget.wall,
            ),
      ),
    );

    if (circleObject != null) {
      ///scroll the library widget to the top
      _globalEventBloc.broadcastScrollLibraryToTop();

      if (widget.wall) {
        for (UserFurnace selectedNetwork in _selectedNetworks) {
          UserCircleCache userCircleCache = _getUserCircleCacheFromFurnace(
            selectedNetwork,
          );

          CircleObject newPost = _prepNewCircleObject(
            selectedNetwork,
            userCircleCache,
            caption: '',
          );
          newPost.type = CircleObjectType.CIRCLERECIPE;
          newPost.recipe = CircleRecipe();
          newPost.recipe!.ingestDeepCopy(circleObject.recipe!);
          newPost.body = newPost.recipe!.name!;

          _circleRecipeBloc.create(
            userCircleCache,
            newPost,
            selectedNetwork,
            false,
            false,
          );
        }
      }
    }

    _clear(false);
    _refreshEnabled = true;
  }

  // _createTextEditor() async {
  //   _refreshEnabled = false;
  //   await Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (context) => const TextArea()),
  //   );
  //   _clear(false);
  //   _refreshEnabled = true;
  // }

  _createCredential() async {
    _refreshEnabled = false;

    UserFurnace stageFurnace = getStageFurnace();

    UserCircleCache userCircleCache = _getUserCircleCacheFromFurnace(
      stageFurnace,
    );

    CircleObject? circleObject = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SubtypeCredential(
              //userFurnaces: widget.userFurnaces,
              globalEventBloc: _globalEventBloc,
              circleObjectBloc: _circleObjectBloc,
              userCircleCache: userCircleCache,
              setNetworks: _setSelectedNetworks,
              userFurnace: stageFurnace,
              userCircleBloc: _userCircleBloc,
              screenMode: ScreenMode.ADD,
              timer: CircleDisappearingTimer.OFF,
              scheduledFor: null,
              replyObject: null,
              wall: widget.wall,
              userFurnaces: widget.wallFurnaces,
              //circleRecipeBloc: _circleRecipeBloc,
            ),
      ),
    );

    if (circleObject != null) {
      if (widget.wall) {
        for (UserFurnace selectedNetwork in _selectedNetworks) {
          UserCircleCache userCircleCache = _getUserCircleCacheFromFurnace(
            selectedNetwork,
          );

          CircleObject newPost = _prepNewCircleObject(
            selectedNetwork,
            userCircleCache,
            skipBody: true,
          );

          newPost.userFurnace = selectedNetwork;
          newPost.userCircleCache = userCircleCache;

          newPost.type = CircleObjectType.CIRCLECREDENTIAL;
          newPost.subType = SubType.LOGIN_INFO;
          newPost.subString1 = circleObject.subString1;
          newPost.subString2 = circleObject.subString2;
          newPost.subString3 = circleObject.subString3;
          newPost.subString4 = circleObject.subString4;

          _circleObjectBloc.saveCircleObject(
            _globalEventBloc,
            selectedNetwork,
            userCircleCache,
            newPost,
          );
        }
      }
      //Navigator.pop(context);
    }

    _clear(false);

    _refreshEnabled = true;
  }

  _createSubtypeCreditCard() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SubtypeCreditCard(
              //userFurnaces: widget.userFurnaces,
              circleObjectBloc: _circleObjectBloc,
              userCircleCache: widget.userCircleCache,
              userFurnace: widget.userFurnace,
              userCircleBloc: _userCircleBloc,
              screenMode: ScreenMode.ADD,
              globalEventBloc: _globalEventBloc,
              replyObject: _replyObject,
              //circleRecipeBloc: _circleRecipeBloc,
            ),
      ),
    );

    _clear(false);
  }

  _getKeyboardSticker(KeyboardInsertedContent data) async {
    String tempDir = await FileSystemService.returnTempPath();
    int index = data.uri.lastIndexOf('/');
    String name = data.uri.substring(index);
    File file = await File('$tempDir/$name').create();
    file.writeAsBytesSync(data.data!.toList());
    Media media = Media(mediaType: MediaType.image, path: file.path);
    _mediaCollection ??= MediaCollection();
    setState(() {
      _mediaCollection!.add(media);
      _sendEnabled = true;
    });
  }

  _getKeyboardMedia(KeyboardInsertedContent data) async {
    String tempDir = await FileSystemService.returnTempPath();
    int index = data.uri.lastIndexOf('/');
    String name = data.uri.substring(index);
    File file = await File('$tempDir/$name').create();
    file.writeAsBytesSync(data.data!.toList());
    Media media = Media(mediaType: MediaType.image, path: file.path);
    _mediaCollection ??= MediaCollection();
    setState(() {
      _mediaCollection!.add(media);
      _sendEnabled = true;
    });
  }

  // _previewGiphy(GiphyOption giphyOption) {
  //   setState(() {
  //     _clearPreviews();
  //     _giphyOption = giphyOption;
  //
  //     _sendEnabled = true;
  //     //_cancelEnabled = true;
  //   });
  //
  //   _refreshCircleObjects();
  // }

  _selectGif() async {
    GiphyOption? giphyOption = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SelectGif(refresh: _refresh)),
    );

    if (giphyOption != null) {
      MediaCollection mediaCollection = MediaCollection();

      mediaCollection.populateFromGiphyOption(giphyOption);

      _showPreviewer(mediaCollection);
    }
  }

  _createList() async {
    try {
      _refreshEnabled = false;
      int dateInc = _increment != null ? _increment! + 1 : 0;
      UserFurnace stageFurnace = getStageFurnace();

      UserCircleCache userCircleCache = _getUserCircleCacheFromFurnace(
        stageFurnace,
      );

      CircleObject? circleObject = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => CircleListNew(
                circleListBloc: _circleListBloc,
                increment: dateInc,
                userFurnaces: widget.wallFurnaces,
                userFurnace: stageFurnace,
                userCircleCache: userCircleCache,
                setNetworks: _setSelectedNetworks,
                //globalEventBloc: widget.globalEventBloc,
                circleObjectBloc: _circleObjectBloc,
                timer: CircleDisappearingTimer.OFF,
                scheduledFor: null,
                replyObject: null,
                wall: widget.wall,
              ),
        ),
      );

      if (circleObject != null) {
        ///scroll the library widget to the top
        _globalEventBloc.broadcastScrollLibraryToTop();

        if (widget.wall) {
          for (UserFurnace selectedNetwork in _selectedNetworks) {
            UserCircleCache userCircleCache = _getUserCircleCacheFromFurnace(
              selectedNetwork,
            );

            CircleObject newPost = _prepNewCircleObject(
              selectedNetwork,
              userCircleCache,
            );
            newPost.type = CircleObjectType.CIRCLELIST;
            newPost.list = CircleList.deepCopy(circleObject.list!);

            _circleListBloc.createList(
              userCircleCache,
              newPost,
              true,
              selectedNetwork,
              _globalEventBloc,
            );
          }
        }
      }

      _clear(false);

      _refreshEnabled = true;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('InsideCircle._createList: $err');
    }
  }

  // _showMoreItemsToPost() {
  //   DialogSelectPostItems.selectPostItemsPopup(
  //       context, globalState.userFurnace!.username, _itemToPostSelected);
  // }

  // _itemToPostSelected(String type) {
  //   if (type == CircleObjectType.CIRCLELIST) {
  //     _createList();
  //   } else if (type == CircleObjectType.CIRCLEVOTE) {
  //     _createVote();
  //   } else if (type == CircleObjectType.CIRCLERECIPE) {
  //     _createRecipe();
  //   } else if (type == CircleObjectType.CIRCLEQUILLTEXT) {
  //     _createTextEditor();
  //   } else if (type == CircleObjectType.CIRCLECREDENTIAL) {
  //     _createSubtypeCredential();
  //   } else if (type == 'Credential') {
  //     _createSubtypeCredential();
  //   } else if (type == 'Credit Card') {
  //     _createSubtypeCreditCard();
  //   } else if (type == 'Bank Account') {
  //     _createSubtypeCreditCard();
  //   } else if (type == 'Markup') {
  //     _createMarkup(null, false);
  //   }
  // }

  late CircleEvent _circleEvent;

  _setEventDateTime(DateTime startDate, DateTime endDate) {
    _circleEvent = CircleEvent(
      respondents: [],
      encryptedLineItems: [],
      startDate: startDate,
      endDate: endDate,
    );
  }

  _createEvent() async {
    try {
      UserFurnace stageFurnace = getStageFurnace();

      UserCircleCache userCircleCache = _getUserCircleCacheFromFurnace(
        stageFurnace,
      );

      _refreshEnabled = false;
      _closeKeyboard();
      int dateInc = _increment != null ? _increment! + 1 : 0;

      _circleEvent = CircleEvent(
        respondents: [],
        encryptedLineItems: [],
        startDate: _circleEvent.startDate,
        endDate: _circleEvent.endDate,
      );

      var circleEvent = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => CircleEventDetail(
                circleObject: CircleObject(
                  ratchetIndexes: [],
                  event: _circleEvent,
                ),
                circleObjectBloc: _circleObjectBloc,
                userFurnaces:
                    widget.wall ? widget.wallFurnaces : [widget.userFurnace],
                userFurnace: stageFurnace,
                userCircleCache: userCircleCache,
                setNetworks: _setSelectedNetworks,
                replyObject: null,
                fromCentralCalendar: true,
                scheduledFor: null,
                wall: widget.wall,
                increment: dateInc,
              ),
        ),
      );

      _refreshEnabled = true;

      if (circleEvent != null) {
        if (widget.wall) {
          for (UserFurnace selectedNetwork in _selectedNetworks) {
            UserCircleCache userCircleCache = _getUserCircleCacheFromFurnace(
              selectedNetwork,
            );

            CircleEvent newEvent = CircleEvent.deepCopy(circleEvent);

            _circleEventBloc.createEvent(
              _circleObjectBloc,
              userCircleCache,
              newEvent,
              selectedNetwork,
              _globalEventBloc,
              null,
              null,
              null,
            );
          }
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('InsideCircle._scheduleEvent: $err');
    }
  }

  _captureMedia() async {
    _refreshEnabled = false;

    try {
      _closeKeyboard();

      CapturedMediaResults? results = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CaptureMedia()),
      );

      if (results != null) {
        for (Media media in results.mediaCollection.media) {
          if (media.mediaType == MediaType.video) {
            media.thumbnail =
                (await VideoCacheService.cacheTempVideoPreview(
                  media.path,
                  0,
                )).path;
          }
        }

        // if (results.isShrunk) {
        //   // _refreshEnabled = true;
        //   // SelectedMedia selectedImages = SelectedMedia(
        //   //     hiRes: true,
        //   //     streamable: false,
        //   //     mediaCollection: results.mediaCollection);
        //   // if (selectedImages.mediaCollection.media.isNotEmpty) {
        //   //   _previewSelectedMedia(selectedImages);
        //   // }
        // } else {
        _showPreviewer(results.mediaCollection);
        // }
      }

      _refreshEnabled = true;

      _refreshCircleObjects();
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('InsideCircle._captureMedia: $err');
    }

    _refreshEnabled = true;
  }

  void requestNewerThan() {
    _refreshCircleObjects();
  }

  //TODO Replacing a photo needs to be reimplemented after new preview screen
  _takePhoto() async {
    /*_refreshEnabled = false;

    try {
      _closeKeyboard();

      ImagePicker imagePicker = ImagePicker();

      var imageFile = await imagePicker.pickImage(
        source: ImageSource.camera,
      );

      if (imageFile != null) {
        // debugPrint (imageFile.path);

        SelectedImages? selectedImages = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImagePreviewer(
                  hiRes: hiRes,
                  userCircleCache: widget.userCircleCache,
                  circleImageBloc: _circleImageBloc,
                  media: [File(imageFile.path)]),
            ));
        _refreshEnabled = true;

        if (selectedImages != null) {
          _refreshEnabled = true;

          if (selectedImages.images.isNotEmpty) {
            _previewImages(selectedImages);
          }
        }
      }
      return;
    } catch (err, trace) {
      _refreshEnabled = true;
      LogBloc.insertError(err, trace);
      debugPrint('InsideCircle._takePhoto: $err');
    }

     */
  }

  _setupVideoPreview(String path, {bool orientationNeeded = false}) async {
    try {
      setState(() {
        _clearPreviews();
        _videoPreview = false;
      });

      _orientationNeeded = orientationNeeded;

      _video = File(path);

      try {
        if (_video!.lengthSync() >= EncryptBlob.maxForEncrypted) {
          _videoStreamOnly = true;

          _videoStreamable = [false, true];
        }
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
      }

      //dispose of old ones

      if (_lastVideoPlayed != null) _disposeControllers(_lastVideoPlayed!);

      if (_previewControllerBloc.videoControllers.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _previewControllerBloc
              .videoControllers[_previewControllerBloc.videoControllers.length -
                  1]
              .dispose();
        });
      }

      //debugPrint('break');

      _previewIndex = await _previewControllerBloc.addPreview(_video!);

      //debugPrint('break');
      if (mounted)
        setState(() {
          _sendEnabled = true;
          //_cancelEnabled = true;
          _videoPreview = true;
        });
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('InsideCircle._setupVideoPreview: $err');
    }
  }

  // _previewSharedMedia() async {
  //   // if (widget.wall == false || widget.wallFurnaces.length == 1) {
  //   //   _selectedNetworks.clear();
  //   //   _selectedNetworks.add(widget.userFurnace);
  //   // }
  //
  //   _refreshEnabled = false;
  //
  //   SelectedMedia? selectedImages = await Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => ImagePreviewer(
  //             caption: _message.text,
  //             hiRes: false,
  //             streamable: false,
  //             setScheduled: _setScheduled,
  //             timer: _timer,
  //             setTimer: _setTimer,
  //             media: _sharedMedia!,
  //             showCaption: _circle.type == CircleType.VAULT ? false : true,
  //             wall: widget.wall,
  //             userFurnaces:
  //                 widget.wall ? widget.wallFurnaces : [widget.userFurnace],
  //             //selectedNetworks: _selectedNetworks,
  //             setNetworks: _setSelectedNetworks,
  //             redo: _captureMedia,
  //             screenName:
  //                 widget.wall ? "Feed" : widget.userCircleCache.prefName!),
  //       ));
  //
  //   _refreshEnabled = true;
  //
  //   if (selectedImages != null) {
  //     if (selectedImages.mediaCollection.media.isNotEmpty) {
  //       _mediaCollection = selectedImages.mediaCollection;
  //       _send(overrideButton: true);
  //     }
  //   }
  // }

  _previewImageFile(File file) {
    setState(() {
      _clearPreviews();
      _image = file;
      _imagePreview = true;
      _sendEnabled = true;

      //_cancelEnabled = true;
    });
  }

  _setSelectedMediaVariables(SelectedMedia selectedImages) {
    if (selectedImages.mediaCollection.media.isNotEmpty) {
      _hiRes = selectedImages.hiRes;
      _streamable = selectedImages.streamable;
      selectedImages.mediaCollection.album == selectedImages.album;
    }
  }

  // _previewSelectedMedia(SelectedMedia selectedImages) {
  //   _clearPreviews();
  //
  //   _setSelectedMediaVariables(selectedImages);
  //
  //   _previewMediaCollection(selectedImages.mediaCollection,
  //       clearPreviews: false);
  // }

  // _previewMediaCollection(MediaCollection mediaCollection,
  //     {bool clearPreviews = true}) {
  //   setState(() {
  //     if (clearPreviews) _clearPreviews();
  //     _mediaCollection = mediaCollection;
  //
  //     if (mediaCollection.media.isNotEmpty) {
  //       _sendEnabled = true;
  //     }
  //   });
  // }

  _onPreviewPress(int index) async {
    try {
      if (_keyboardMediaCollection!.media[index].mediaType == MediaType.file)
        return;

      _refreshEnabled = false;
      _closeKeyboard();

      SelectedMedia? selectedImages = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ImagePreviewer(
                hiRes: _hiRes,
                streamable: _streamable,
                selectedIndex: index,
                timer: _timer,
                setTimer: _setTimer,
                showCaption: _circle.type == CircleType.VAULT ? false : true,
                setScheduled: _setScheduled,
                screenName: widget.userCircleCache.prefName ?? '',
                userFurnaces:
                    widget.wallFurnaces.isEmpty
                        ? [widget.userFurnace]
                        : widget.wallFurnaces,
                media: _keyboardMediaCollection,
                emojiDisplay: true,
              ),
        ),
      );

      if (selectedImages != null) {
        _refreshEnabled = true;

        if (selectedImages.mediaCollection.isNotEmpty) {
          setState(() {
            _keyboardMediaCollection = selectedImages.mediaCollection;
          });
        }
      } else {
        setState(() {
          _keyboardMediaCollection = MediaCollection();
        });
      }

      return;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('_onPreviewPress: $err');
    }
    _imagePreview = false;
    _sendEnabled = false;
    //_cancelEnabled = false;
    _image = null;

    _refreshEnabled = true;
  }

  Future<void> _leave() async {
    DialogYesNo.askYesNo(
      context,
      "Leave this Circle?",
      "Are you sure you want to leave this circle?",
      _leaveResult,
      null,
      false,
    );
  }

  _leaveResult() {
    _userCircleBloc.leaveCircle(widget.userFurnace, widget.userCircleCache);
  }

  _submitVote(CircleObject circleObject, CircleVoteOption selectedOption) {
    //FormattedSnackBar.showSnackbarWithContext(context, selectedOption.option, "", 2);

    setState(() {
      _showSpinner = true;
    });

    UserFurnace userFurnace = _getUserFurnace(circleObject);
    UserCircleCache userCircleCache = _getUserCircleCache(circleObject);
    _voteBloc.submitVote(
      userCircleCache,
      circleObject,
      selectedOption,
      userFurnace,
    );
  }

  Future _refresh() async {
    if (_showSpinner) return;

    _circleObjectBloc.resendFailedCircleObjects(
      _globalEventBloc,
      widget.userFurnaces!,
    );

    /*setState(() {
      _startSpinner(1);
    });

     */

    _refreshCircleObjects();

    if (_itemScrollController.isAttached)
      _itemScrollController.scrollTo(
        index: 0,
        duration: const Duration(milliseconds: _scrollDuration),
        curve: Curves.easeInOutCubic,
      );
  }

  void _reportPost(CircleObject circleObject) async {
    UserFurnace userFurnace = _getUserFurnace(circleObject);
    UserCircleCache userCircleCache = _getUserCircleCache(circleObject);

    Violation? violation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ReportPost(
              type: ReportType.POST,
              member: null,
              circleObjectBloc: _circleObjectBloc,
              circleObject: circleObject,
              userCircleCache: userCircleCache,
              userFurnace: userFurnace,
              network: null,
            ),
      ),
    );

    //debugPrint(violation.violatedTerms);

    if (violation != null) {
      _circleObjectBloc.reportViolation(userFurnace, circleObject, violation);

      FormattedSnackBar.showSnackbarWithContext(
        context,
        "potential violation reported",
        "",
        3,
        false,
      );
    }
  }

  void _showRecipeReadOnly(CircleObject circleObject) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CircleRecipeScreen(
              circleObject: circleObject,
              //_circleObjects[index],
              userCircleCache:
                  widget.wall
                      ? circleObject.userCircleCache!
                      : widget.userCircleCache,
              userFurnace:
                  widget.wall ? circleObject.userFurnace! : widget.userFurnace,
              screenMode: ScreenMode.READONLY,
              userFurnaces: widget.userFurnaces!,
              circleRecipeBloc: _circleRecipeBloc,
              circleObjectBloc: _circleObjectBloc,
              globalEventBloc: _globalEventBloc,
              timer: _timer,
              replyObject: _replyObject,
            ),
      ),
    );
  }

  void _showRecipeEdit(CircleObject circleObject) async {
    _refreshEnabled = false;

    _setSessionKeys(circleObject);

    var updatedObject = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CircleRecipeScreen(
              //imageProvider:
              //  const AssetImage("assets/large-image.jpg"),
              circleObject: circleObject,
              userCircleCache:
                  widget.wall
                      ? circleObject.userCircleCache!
                      : widget.userCircleCache,
              userFurnace:
                  widget.wall ? circleObject.userFurnace! : widget.userFurnace,
              screenMode: ScreenMode.EDIT,
              userFurnaces: widget.userFurnaces!,
              circleObjectBloc: _circleObjectBloc,
              circleRecipeBloc: _circleRecipeBloc,
              globalEventBloc: _globalEventBloc,
              timer: _timer,
              replyObject: _replyObject,
            ),
      ),
    );

    if (updatedObject != null) {
      //_circleObjects[index] = updatedObject;
      _addObjects([circleObject], true);
    }

    _refreshEnabled = true;
  }

  void _showFullVote(CircleObject circleObject) async {
    ///don't open a vote for someone getting voted out
    if (circleObject.vote!.type != CircleVoteType.REMOVEMEMBER) {
      if (circleObject.vote!.object != widget.userFurnace.userid!) {
        var updatedObject = await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => CircleVoteScreen(
                  //imageProvider:
                  //  const AssetImage("assets/large-image.jpg"),
                  circleObject: circleObject,
                  userCircleCache:
                      widget.wall
                          ? circleObject.userCircleCache!
                          : widget.userCircleCache,
                  userFurnace:
                      widget.wall
                          ? circleObject.userFurnace!
                          : widget.userFurnace,
                  screenMode: ScreenMode.EDIT,
                ),
          ),
        );

        if (updatedObject != null) {
          _addObjects([updatedObject], true);

          if (!updatedObject.vote.open)
            if (updatedObject.vote.type == CircleVoteType.DELETECIRCLE &&
                updatedObject.vote.winner != null) {
              _goHome(true);
            }
        }
      }
    }
  }

  void _showSubType(CircleObject circleObject, int screenMode) async {
    _setSessionKeys(circleObject);

    _refreshEnabled = false;
    if (circleObject.type == CircleObjectType.CIRCLECREDENTIAL ||
        circleObject.subType == SubType.LOGIN_INFO) {
      var updatedObject = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => SubtypeCredential(
                userCircleBloc: _userCircleBloc,
                circleObjectBloc: _circleObjectBloc,
                circleObject: circleObject,
                userCircleCache:
                    widget.wall
                        ? circleObject.userCircleCache!
                        : widget.userCircleCache,
                userFurnace:
                    widget.wall
                        ? circleObject.userFurnace!
                        : widget.userFurnace,
                userFurnaces: widget.userFurnaces!,
                screenMode: screenMode,
                globalEventBloc: _globalEventBloc,
                timer: _timer,
                replyObject: _replyObject,
              ),
        ),
      );

      if (updatedObject != null) {
        setState(() {
          _circleObjects[_findIndexCircleObject(circleObject)] = updatedObject;
        });
      }
    }

    _refreshEnabled = true;
  }

  int _findIndexCircleObject(CircleObject circleObject) {
    return _circleObjects.indexWhere(
      (element) => element.seed == circleObject.seed,
    );
  }

  void _showEvent(CircleObject circleObject) async {
    if (circleObject.id == null) return;

    _refreshEnabled = false;

    _setSessionKeys(circleObject);

    var updatedObject = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CircleEventDetail(
              userFurnaces: widget.userFurnaces!,
              //imageProvider:
              //  const AssetImage("assets/large-image.jpg"),
              circleObject: circleObject,
              circleObjectBloc: _circleObjectBloc,
              userCircleCache:
                  widget.wall
                      ? circleObject.userCircleCache!
                      : widget.userCircleCache,
              userFurnace:
                  widget.wall ? circleObject.userFurnace! : widget.userFurnace,
              fromCentralCalendar: false,
              //isNew: true, readOnly: readOnly,
            ),
      ),
    );

    _refreshEnabled = true;

    if (updatedObject != null) {
      _addObjects([circleObject], true);
    }
  }

  _setSessionKeys(CircleObject circleObject) {
    if (widget.wall == false) {
      circleObject.circle = _circle;
    }
  }

  void _showFullList(CircleObject circleObject, bool readOnly) async {
    if (circleObject.id == null) return;

    _setSessionKeys(circleObject);

    var updatedObject = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CircleListEditTabs(
              //imageProvider:
              //  const AssetImage("assets/large-image.jpg"),
              circleObject: circleObject,
              userCircleCache:
                  widget.wall
                      ? circleObject.userCircleCache!
                      : widget.userCircleCache,
              userFurnace:
                  widget.wall ? circleObject.userFurnace! : widget.userFurnace,
              isNew: true,
              readOnly: readOnly,
            ),
      ),
    );

    if (updatedObject != null) {
      _addObjects([updatedObject], true);
    }
  }

  void _showFullScreenImage(
    CircleObject circleObject, {
    bool? videoOneTimeView,
  }) async {
    if (widget.wall == false)
      circleObject.userCircleCache = widget.userCircleCache;

    _refreshEnabled = false;

    if (videoOneTimeView != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => FullScreenGallerySwiper(
                albumDownloadVideo: _albumDownloadVideo,
                globalEventBloc: _globalEventBloc,
                circleAlbumBloc: _circleAlbumBloc,
                circleImageBloc: _circleImageBloc,
                fullScreenSwiperCaller:
                    widget.wall
                        ? FullScreenSwiperCaller.feed
                        : FullScreenSwiperCaller.circle,
                libraryObjects: [circleObject],
                //imageProvider:
                //  const AssetImage("assets/large-image.jpg"),
                circleObject: circleObject,
                userFurnaces: widget.wallFurnaces,
                userCircleCaches: widget.wallUserCircleCaches,
                userFurnace:
                    widget.wall
                        ? circleObject.userFurnace!
                        : widget.userFurnace,
                circle:
                    widget.wall
                        ? circleObject.userCircleCache!.cachedCircle!
                        : _circle,
                delete: _swiperDelete,
                //oneView: videoOneTimeView != null ? true : false,
              ),
        ),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => FullScreenGallerySwiper(
                albumDownloadVideo: _albumDownloadVideo,
                globalEventBloc: _globalEventBloc,
                circleAlbumBloc: _circleAlbumBloc,
                circleImageBloc: _circleImageBloc,
                fullScreenSwiperCaller:
                    widget.wall
                        ? FullScreenSwiperCaller.feed
                        : FullScreenSwiperCaller.circle,
                userFurnaces: widget.wallFurnaces,
                userCircleCaches: widget.wallUserCircleCaches,
                circleObject: circleObject,
                userFurnace:
                    widget.wall
                        ? circleObject.userFurnace!
                        : widget.userFurnace,
                circle: widget.wall ? circleObject.circle! : _circle,
                delete: _swiperDelete,
              ),
        ),
      );
    }

    _refreshEnabled = true;
  }

  void _deleteObject(CircleObject circleObject) async {
    FocusScope.of(context).unfocus();
    await DialogYesNo.askYesNo(
      context,
      'Delete?',
      // 'Are you sure you want to ${(PremiumFeatureCheck.wipeFileOn() /*&& (circleObject.type == CircleObjectType.CIRCLEIMAGE || circleObject.type == CircleObjectType.CIRCLEVIDEO)*/) ? 'shred' : 'delete'} this post?',
      'Are you sure you want to delete this post?',
      _deleteObjectConfirmed,
      null,
      false,
      circleObject,
    );
  }

  void _deleteObjectConfirmed(CircleObject circleObject) async {
    _globalEventBloc.broadcastDelete(circleObject);

    _circleImageBloc.removeInProgressPost(circleObject);

    if (widget.wall)
      _circleObjectBloc.deleteCircleObject(
        circleObject.userCircleCache!,
        circleObject.userFurnace!,
        circleObject,
      );
    else
      _circleObjectBloc.deleteCircleObject(
        widget.userCircleCache,
        widget.userFurnace,
        circleObject,
      );
  }

  void _cancelTransfer(CircleObject circleObject) async {
    circleObject.video!.streamableCached = false;

    if (widget.wall)
      circleObject = await _circleVideoBloc.cancelVideoTransfer(
        circleObject.userCircleCache!,
        circleObject,
      );
    else
      circleObject = await _circleVideoBloc.cancelVideoTransfer(
        widget.userCircleCache,
        circleObject,
      );

    setState(() {
      circleObject.video!.videoState = VideoStateIC.PREVIEW_DOWNLOADED;
    });
  }

  void _removeCache(CircleObject circleObject) async {
    if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
      FocusScope.of(context).unfocus();
      await DialogYesNo.askYesNo(
        context,
        'Remove video(s) from cache?',
        'Remove this video from cache to free up space? You can download again later.',
        _removeCacheConfirmed,
        null,
        false,
        circleObject,
      );
    } else if (circleObject.type == CircleObjectType.CIRCLEFILE) {
      FocusScope.of(context).unfocus();
      await DialogYesNo.askYesNo(
        context,
        'Remove file(s) from cache?',
        'Remove this file from cache to free up space? You can download again later.',
        _removeCacheConfirmed,
        null,
        false,
        circleObject,
      );
    }
  }

  void _removeCacheConfirmed(CircleObject circleObject) async {
    if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
      circleObject.video!.streamableCached = false;

      if (circleObject.video!.videoState == VideoStateIC.VIDEO_READY) {
        _videoControllerBloc.pauseLast();
        _disposeControllers(circleObject);
      }

      if (widget.wall)
        _circleVideoBloc.deleteCache(
          circleObject.userFurnace!.userid!,
          circleObject.userCircleCache!.circlePath!,
          circleObject,
        );
      else
        _circleVideoBloc.deleteCache(
          widget.userFurnace.userid!,
          widget.userCircleCache.circlePath!,
          circleObject,
        );
    } else if (circleObject.type == CircleObjectType.CIRCLEFILE) {
      if (widget.wall)
        _circleFileBloc.deleteCache(
          circleObject.userFurnace!.userid!,
          circleObject.userCircleCache!.circlePath!,
          circleObject,
        );
      else
        _circleFileBloc.deleteCache(
          widget.userFurnace.userid!,
          widget.userCircleCache.circlePath!,
          circleObject,
        );
    }
  }

  void _cannotShare(String itemType, String line) async {
    if (itemType == CircleObjectType.CIRCLEIMAGE) {
      itemType = AppLocalizations.of(context)!.imageWord;
    } else if (itemType == CircleObjectType.CIRCLEVIDEO) {
      itemType = AppLocalizations.of(context)!.videoWord;
    } else if (itemType == CircleObjectType.CIRCLEFILE) {
      itemType = AppLocalizations.of(context)!.fileWord;
    } else if (itemType == CircleObjectType.CIRCLEGIF) {
      itemType = AppLocalizations.of(context)!.gifWord;
    } else if (itemType == CircleObjectType.CIRCLELINK) {
      itemType = AppLocalizations.of(context)!.linkWord;
    }
    DialogNotice.showNotice(
      context,
      "${AppLocalizations.of(context)!.cannotShareNoticeTitle} $itemType",
      AppLocalizations.of(context)!.cannotShareNoticeLine1,
      line,
      "",
      "",
      false,
    );
  }

  void _shareObject(CircleObject circleObject) async {
    late UserCircleCache userCircleCache;
    late UserFurnace userFurnace;

    debugPrint("*********************** made it to _shareObject");

    if (widget.wall) {
      userCircleCache = circleObject.userCircleCache!;
      userFurnace = circleObject.userFurnace!;
    } else {
      userCircleCache = widget.userCircleCache;
      userFurnace = widget.userFurnace;
    }

    if (globalState.isDesktop() ||
        circleObject.type == CircleObjectType.CIRCLEEVENT ||
        circleObject.type == CircleObjectType.CIRCLECREDENTIAL ||
        circleObject.subType == SubType.LOGIN_INFO ||
        circleObject.type == CircleObjectType.CIRCLELIST ||
        circleObject.type == CircleObjectType.CIRCLERECIPE) {
      ShareCircleObject.shareToDestination(
        context,
        userCircleCache,
        circleObject,
        true,
      );
      return;
    }

    ///these objects need prepped before sharing
    if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
      bool cached = VideoCacheService.isVideoCached(
        circleObject,
        userCircleCache.circlePath!,
      );

      if (!cached) {
        DialogNotice.showNotice(
          context,
          'Download video before sharing',
          'a video must be downloaded before it can be shared',
          'you can always remove the cache after the video is shared to free up storage',
          null,
          null,
          false,
        );

        return;
      }
    } else if (circleObject.type == CircleObjectType.CIRCLEFILE) {
      bool cached = FileCacheService.isFileCached(
        circleObject,
        userCircleCache.circlePath!,
      );

      if (!cached) {
        DialogNotice.showNotice(
          context,
          'Download file before sharing',
          'a file must be downloaded before it can be shared',
          'you can always remove the cache after the file is shared to free up storage',
          null,
          null,
          false,
        );

        return;
      }
    }

    ///prep is done, now share
    if (circleObject.type == CircleObjectType.CIRCLEGIF) {
      if (_circle.privacyShareGif != null) {
        if (_circle.privacyShareGif! ||
            circleObject.creator!.id == userFurnace.userid) {
          if (globalState.isDesktop()) {
            ShareCircleObject.shareToDestination(
              context,
              userCircleCache,
              circleObject,
              true,
            );
          } else {
            DialogShareTo.shareToPopup(
              context,
              userCircleCache,
              circleObject,
              ShareCircleObject.shareToDestination,
            );
          }
        } else {
          _cannotShare(
            circleObject.type!,
            AppLocalizations.of(context)!.cannotShareNoticeGif,
          );
        }
      }
    } else if (circleObject.type == CircleObjectType.CIRCLEIMAGE ||
        circleObject.type == CircleObjectType.CIRCLEVIDEO ||
        circleObject.type == CircleObjectType.CIRCLEFILE) {
      if (_circle.privacyShareImage != null) {
        if (_circle.privacyShareImage! ||
            circleObject.creator!.id == userFurnace.userid) {
          if (globalState.isDesktop()) {
            ShareCircleObject.shareToDestination(
              context,
              userCircleCache,
              circleObject,
              true,
            );
          } else {
            DialogShareTo.shareToPopup(
              context,
              userCircleCache,
              circleObject,
              ShareCircleObject.shareToDestination,
            );
          }
        } else {
          _cannotShare(
            circleObject.type!,
            AppLocalizations.of(context)!.cannotShareNoticeMedia,
          );
        }
      }
    } else if (circleObject.type == CircleObjectType.CIRCLELINK) {
      if (_circle.privacyShareURL != null) {
        if (_circle.privacyShareURL! ||
            circleObject.creator!.id == userFurnace.userid) {
          if (globalState.isDesktop()) {
            ShareCircleObject.shareToDestination(
              context,
              userCircleCache,
              circleObject,
              true,
            );
          } else {
            DialogShareTo.shareToPopup(
              context,
              userCircleCache,
              circleObject,
              ShareCircleObject.shareToDestination,
            );
          }
        } else {
          _cannotShare(
            circleObject.type!,
            AppLocalizations.of(context)!.cannotShareNoticeUrl,
          );
        }
      }
    }
  }

  void _setBackground(CircleObject circleObject) async {
    File image;

    late UserCircleCache userCircleCache;
    late UserFurnace userFurnace;

    if (widget.wall) {
      userCircleCache = circleObject.userCircleCache!;
      userFurnace = circleObject.userFurnace!;
    } else {
      userCircleCache = widget.userCircleCache;
      userFurnace = widget.userFurnace;
    }

    if (ImageCacheService.isFullImageCached(
      circleObject,
      userCircleCache.circlePath!,
      circleObject.seed!,
    )) {
      image = File(
        ImageCacheService.returnFullImagePath(
          userCircleCache.circlePath!,
          circleObject,
        ),
      );
    } else {
      image = File(
        ImageCacheService.returnThumbnailPath(
          userCircleCache.circlePath!,
          circleObject,
        ),
      );
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SetCircleBackground(
              userFurnace: userFurnace,
              userCircleCache: userCircleCache,
              image: image,
              buttonText: "SET BACKGROUND",
            ),
      ),
    );

    if (result != null) {
      FormattedSnackBar.showSnackbarWithContext(
        context,
        "background updated",
        "",
        2,
        false,
      );
    }
  }

  _updateList(CircleObject circleObject, CircleList copiedList) {
    setState(() {
      try {
        for (CircleListTask circleListTask in circleObject.list!.tasks!) {
          CircleListTask? updatedTask;

          try {
            int index = copiedList.tasks!.indexWhere(
              (element) => element.id == circleListTask.id,
            );

            if (index != -1) {
              updatedTask = copiedList.tasks![index];
            }

            if (updatedTask != null &&
                updatedTask.complete != circleListTask.complete) {
              circleListTask.complete = updatedTask.complete;

              if (updatedTask.complete!) {
                circleListTask.completedBy = globalState.user;
                circleListTask.completed = DateTime.now().toLocal();
              }
            }
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint('InsideCircle._updateList: $err');
          }
        }

        setState(() {
          _showSpinner = true;
        });

        _circleListBloc.updateList(
          widget.wall ? circleObject.userCircleCache! : widget.userCircleCache,
          circleObject,
          circleObject.list!,
          false,
          widget.wall ? circleObject.userFurnace! : widget.userFurnace,
        );
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
        debugPrint('InsideCircle._markComplete: $err');
      }
    });
  }

  void _copyObject(CircleObject circleObject) async {
    if (circleObject.type == 'circlemessage') {
      Clipboard.setData(ClipboardData(text: circleObject.body!));
      //match = true;
    } else if (circleObject.type == 'circlelink') {
      Clipboard.setData(ClipboardData(text: circleObject.link!.url!));
      //match = true;
    } else if (circleObject.type == 'circlegif') {
      Clipboard.setData(ClipboardData(text: circleObject.gif!.giphy!));
      // match = true;
    }
  }

  void _storePosition(TapDownDetails details) {
    //_tapPosition = details.globalPosition;
  }

  _upsertCircleObject(CircleObject circleObject) {
    try {
      int position = -1;
      if (_circleObjects.isNotEmpty &&
          _circle.type != CircleType.VAULT &&
          _itemPositionsListener.itemPositions.value.isNotEmpty) {
        position = _itemPositionsListener.itemPositions.value.first.index;
        debugPrint('InsideCircle._upsertCircleObject: position: $position');
      }
      CircleObjectCollection.addWallHitchhikers(
        [circleObject],
        widget.wallFurnaces,
        widget.wallUserCircleCaches,
      );

      if (globalState.isDesktop()) {
        _globalEventBloc.broadcastMemCacheCircleObjectsAdd([circleObject]);
      }

      CircleObjectCollection.upsertObject(
        _circleObjects,
        circleObject,
        _currentCircle!,
        widget.wallUserCircleCaches,
      );

      if (mounted) {
        setState(() {
          _clearSpinner();
        });
      }

      if (circleObject.scheduledFor != null) {
        _increment = _increment! + 1;

        ///just to be safe.
        ///circle object scheduled for already has increment so can't match
        _lastScheduled = _scheduledDate;
      }

      if (_circleObjects.isNotEmpty &&
          _circle.type != CircleType.VAULT &&
          _itemPositionsListener.itemPositions.value.isNotEmpty) {
        position = _itemPositionsListener.itemPositions.value.first.index;
        debugPrint('InsideCircle._upsertCircleObject: position: $position');
      }

      if (_circle.type == CircleType.VAULT)
        _circleObjectBloc.sinkVaultRefresh();
      //_globalEventBloc.broadcastRefreshWall();
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('InsideCircle._addCircleObject: $err');
      if (mounted)
        setState(() {
          _clearSpinner();
        });
    }
  }

  _addNewAndScrollToBottom() {
    if (_waitingOnScroller.isNotEmpty) {
      _addObjects(_waitingOnScroller, true);
      setState(() {
        _waitingOnScroller.clear();
      });
    } else if (_itemScrollController.isAttached &&
        _circleObjects.isNotEmpty &&
        _circle.type != CircleType.VAULT) {
      _itemScrollController.scrollTo(
        index: 0,
        duration: const Duration(milliseconds: _scrollDuration),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  _calculateDirection() {
    //debugPrint('uh');
    //debugPrint(_itemPositionsListener.itemPositions.value.first.index);

    if (_itemPositionsListener.itemPositions.value.isEmpty) return;

    if (_itemPositionsListener.itemPositions.value.first.index == 0) {
      if (_scrollingDown != false)
        setState(() {
          _scrollingDown = false;

          if (_waitingOnScroller.isNotEmpty) {
            _addObjects(_waitingOnScroller, true);
            _waitingOnScroller.clear();
          }
        });
    } else if (_itemPositionsListener.itemPositions.value.first.index <
        _lastIndex) {
      if (_scrollingDown != true) {
        setState(() {
          _scrollingDown = true;
        });

        Timer(const Duration(seconds: 3), () {
          if (mounted)
            setState(() {
              _scrollingDown = false;
            });
        });
      }
    } else if (_itemPositionsListener.itemPositions.value.first.index >
            _lastIndex &&
        _lastIndex == 0) {
      _closeKeyboard();
    }
    /*else if (_scrollingDown != false
      setState(() {
        _scrollingDown = false;
      });
      */

    _lastIndex = _itemPositionsListener.itemPositions.value.first.index;
  }

  _addAndScroll(List<CircleObject> objects) {
    debugPrint('addAndScroll called at ${DateTime.now()}');
    if (mounted)
      setState(() {
        CircleObjectCollection.addObjects(
          _circleObjects,
          objects,
          _currentCircle!,
          widget.wallFurnaces,
          widget.wallUserCircleCaches /*isWall: widget.wall*/,
        );
      });
    _circleObjectBloc.sinkVaultRefresh();
    //_globalEventBloc.broadcastRefreshWall();

    if (_itemScrollController.isAttached &&
        _circleObjects.isNotEmpty &&
        _circle.type != CircleType.VAULT) {
      _itemScrollController.scrollTo(
        index: 0,
        duration: const Duration(milliseconds: _scrollDuration),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  _addObjects(List<CircleObject> objects, bool scrollToBottom) {
    ///requester said jump to bottom
    if (scrollToBottom) {
      if (objects.isNotEmpty) {
        _addAndScroll(objects);
      }
    }
    ///figure out whether to scroll or not
    else if (objects.isNotEmpty) {
      ///only add ones that aren't already there
      List<CircleObject> alreadyThere = [];
      List<CircleObject> notAlreadyThere = [];

      for (CircleObject object in objects) {
        if (_circleObjects.indexWhere(
              (element) => element.seed == object.seed,
            ) >
            -1) {
          alreadyThere.add(object);
        } else {
          notAlreadyThere.add(object);
        }
      }

      ///add the ones that are just updates
      if (alreadyThere.isNotEmpty) {
        if (mounted)
          setState(() {
            CircleObjectCollection.addObjects(
              _circleObjects,
              alreadyThere,
              _currentCircle!,
              widget.wallFurnaces,
              widget.wallUserCircleCaches,
            );
          });
        _circleObjectBloc.sinkVaultRefresh();
        //_globalEventBloc.broadcastRefreshWall();
      }

      bool scroll = false;
      int position = -1;
      int difference = _circleObjects.length - objects.length;
      if (_circleObjects.isNotEmpty &&
          _circle.type != CircleType.VAULT &&
          difference != 0) {
        position = _itemPositionsListener.itemPositions.value.first.index;
        debugPrint('current position is $position');
        if (position == 0 && _circleObjects.isNotEmpty) scroll = true;
      }

      if (notAlreadyThere.isNotEmpty) {
        if (scroll) {
          _addAndScroll(notAlreadyThere);
        } else {
          ///On first load don't scroll or use _waitingScroller until background load is finished
          if (backgroundLoadFinished == false) {
            backgroundLoadFinished = true;
            if (mounted) {
              setState(() {
                CircleObjectCollection.addObjects(
                  _circleObjects,
                  notAlreadyThere,
                  _currentCircle!,
                  widget.wallFurnaces,
                  widget.wallUserCircleCaches,
                );
              });
              _circleObjectBloc
                  .sinkVaultRefresh(); //_globalEventBloc.broadcastRefreshWall();
            }
          } else {
            _waitingOnScroller.addAll(notAlreadyThere);
            if (mounted) setState(() {});
          }
        }
      }
    }

    if (mounted) {
      if (objects.length == 1) {
        if (objects[0].id != null) {
          ///don't process while the object is still uploading
          _turnoffBadgeAndSetLastAccess(true);
        }
      }
    }
  }

  bool backgroundLoadFinished = false;

  void _scrollToIndex(int index) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (_circle.type == CircleType.VAULT) {
      CircleObject circleObject = _circleObjects[index];
      DisplayType displayType = DisplayType.Notes;

      if (circleObject.type == CircleObjectType.CIRCLERECIPE) {
        displayType = DisplayType.Recipes;
      } else if (circleObject.type == CircleObjectType.CIRCLELIST) {
        displayType = DisplayType.Lists;
      } else if (circleObject.type == CircleObjectType.CIRCLECREDENTIAL) {
        displayType = DisplayType.Credentials;
      } else if (circleObject.type == CircleObjectType.CIRCLEMESSAGE &&
          circleObject.subType != null) {
        displayType = DisplayType.Credentials;
      } else if (circleObject.type == CircleObjectType.CIRCLELINK) {
        displayType = DisplayType.Links;
      }

      _openVaultObjectDisplay(displayType, scrollToObject: circleObject);
    } else {
      if (index != -1) {
        if (_circleObjects.length - index < 10) {
          _itemScrollController.jumpTo(index: index);
        } else {
          _itemScrollController.scrollTo(
            index: index,
            duration: const Duration(milliseconds: _scrollDuration),
            curve: Curves.easeInOutCubic,
          );
        }
      }
    }
  }

  static const int _scrollDuration = 250;

  void _scrollAfterWait(int index) async {
    await Future.delayed(const Duration(seconds: 1));

    if (index != -1) {
      ///if the index is near the top of the list we have to use jumpto instead of scrollto because the Flutter team sucks
      if (_circleObjects.length - index < 10) {
        _itemScrollController.jumpTo(index: index);
      } else {
        _itemScrollController.scrollTo(
          index: index,
          duration: const Duration(milliseconds: _scrollDuration),
          curve: Curves.easeInOutCubic,
        );
      }
    }
  }

  void _refreshCircleObjects() {
    try {
      debugPrint('hit _refreshCircleObjects');

      if (widget.wall) {
        for (UserCircleCache userCircleCache in widget.wallUserCircleCaches) {
          var userFurnace = widget.wallFurnaces.firstWhere(
            (element) => element.pk == userCircleCache.userFurnace,
          );

          _circleObjectBloc.requestNew(
            userCircleCache.cachedCircle!.id!,
            userFurnace,
            userCircleCache,
            true,
            true,
            true,
          );
        }
      } else {
        _circleObjectBloc.requestNew(
          _currentCircle!,
          widget.userFurnace,
          widget.userCircleCache,
          true,
          true,
          true,
        );
      }
    } catch (e, trace) {
      LogBloc.insertError(e, trace);
    }
  }
  //
  // Future _cropImage(File imageFile, bool isPhoto) async {
  //   _closeKeyboard();
  //
  //   _refreshEnabled = false;
  //
  //   ImageCropper imageCropper = ImageCropper();
  //
  //   CroppedFile? croppedFile = await imageCropper.cropImage(
  //       sourcePath: imageFile.path,
  //       aspectRatioPresets: Platform.isAndroid
  //           ? [
  //               CropAspectRatioPreset.square,
  //               CropAspectRatioPreset.ratio3x2,
  //               CropAspectRatioPreset.original,
  //               CropAspectRatioPreset.ratio4x3,
  //               CropAspectRatioPreset.ratio16x9
  //             ]
  //           : [
  //               CropAspectRatioPreset.original,
  //               CropAspectRatioPreset.square,
  //               CropAspectRatioPreset.ratio3x2,
  //               CropAspectRatioPreset.ratio4x3,
  //               CropAspectRatioPreset.ratio5x3,
  //               CropAspectRatioPreset.ratio5x4,
  //               CropAspectRatioPreset.ratio7x5,
  //               CropAspectRatioPreset.ratio16x9
  //             ],
  //       uiSettings: [
  //         AndroidUiSettings(
  //             toolbarTitle: 'Adjust image',
  //             backgroundColor: globalState.theme.background,
  //             activeControlsWidgetColor: Colors.blueGrey[600],
  //             toolbarColor: globalState.theme.background,
  //             statusBarColor: globalState.theme.background,
  //             toolbarWidgetColor: globalState.theme.menuIcons,
  //             initAspectRatio: CropAspectRatioPreset.original,
  //             lockAspectRatio: false),
  //         IOSUiSettings(
  //           title: 'Adjust image',
  //         )
  //       ]);
  //   if (croppedFile != null) {
  //     imageFile = File(croppedFile.path);
  //     if (isPhoto) {
  //       setState(() {
  //         _photo = File(croppedFile.path);
  //         //state = AppState.cropped;
  //       });
  //     } else {
  //       setState(() {
  //         _image = File(croppedFile.path);
  //         //state = AppState.cropped;
  //       });
  //     }
  //   }
  //
  //   _refreshEnabled = true;
  // }

  // _createMarkup(File? imageFile, bool isPhoto) async {
  //   _closeKeyboard();
  //
  //   File? result = await Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //           builder: (context) => Markup(
  //                 source: imageFile,
  //               )));
  //
  //   if (result != null) {
  //     //imageFile = result;
  //     if (isPhoto) {
  //       setState(() {
  //         _photo = result;
  //         //state = AppState.cropped;
  //       });
  //     } else {
  //       if (imageFile == null) {
  //         //_previewImageFile(result);
  //         MediaCollection mediaCollection = MediaCollection();
  //         mediaCollection
  //             .add(Media(path: result.path, mediaType: MediaType.image));
  //
  //         _previewSelectedMedia(SelectedMedia(
  //             hiRes: false,
  //             streamable: false,
  //             mediaCollection: mediaCollection));
  //       } else {
  //         setState(() {
  //           _image = result;
  //           //state = AppState.cropped;
  //         });
  //       }
  //     }
  //   }
  // }

  ///emoji picker opening
  _openEmojiPicker(CircleObject pCircleObject) {
    setState(() {
      _postedEmoji = false;
      _emojiController.text = '';
      _reactingTo = pCircleObject;
      _emojiShowing = true;
    });
  }

  ///emoji picker emoji chosen
  _emojiReaction(String emoji, CircleObject? pressedCircleObject) {
    //find the latest
    CircleObject circleObject;
    if (pressedCircleObject == null) {
      circleObject = _circleObjects.firstWhere(
        (element) => element.seed == _reactingTo!.seed,
      );
    } else {
      circleObject = pressedCircleObject;
    }
    CircleObjectReaction? found;
    bool remove = false;
    circleObject.reactions ??= [];

    UserFurnace userFurnace = _getUserFurnace(circleObject);
    UserCircleCache userCircleCache = _getUserCircleCache(circleObject);

    for (CircleObjectReaction reaction in circleObject.reactions!) {
      if (reaction.emoji == emoji) {
        found = reaction;
        for (User user in reaction.users) {
          if (user.id == userFurnace.userid) {
            remove = true;
            break;
          }
        }
      }
    }
    if (remove) {
      found!.users.removeWhere((element) => element.id == userFurnace.userid);
      if (found.users.isEmpty) {
        circleObject.reactions!.removeWhere(
          (element) => element.emoji == found!.emoji,
        );
      }
      _circleObjectBloc.deleteReaction(
        userFurnace,
        userCircleCache,
        circleObject,
        found,
        _circleObjects[0],
      );
    } else if (found != null) {
      found.users.add(
        User(username: userFurnace.username, id: userFurnace.userid),
      );
      _circleObjectBloc.postReaction(
        userFurnace,
        userCircleCache,
        circleObject,
        found,
      );
      _postedEmoji = true;
    } else {
      CircleObjectReaction reaction = CircleObjectReaction(
        index: null,
        emoji: emoji,
        users: [User(username: userFurnace.username, id: userFurnace.userid)],
      );
      circleObject.reactions!.add(reaction);
      _circleObjectBloc.postReaction(
        userFurnace,
        userCircleCache,
        circleObject,
        reaction,
      );
      _postedEmoji = true;
    }
    setState(() {
      circleObject.showOptionIcons = false;
      if (_postedEmoji == true) {
        _emojiShowing = false;
      }
    });
  }

  _reactionAdded(CircleObject pCircleObject, index) {
    if (index == -1) {
      //_closeReactions();
      return;
    }

    if (index == -2) {
      _openEmojiPicker(pCircleObject);
      return;
    }

    //find the latest
    CircleObject circleObject = _circleObjects.firstWhere(
      (element) => element.seed == pCircleObject.seed,
    );

    CircleObjectReaction? found;
    bool remove = false;

    circleObject.reactions ??= [];

    UserFurnace userFurnace = _getUserFurnace(circleObject);
    UserCircleCache userCircleCache = _getUserCircleCache(circleObject);

    for (CircleObjectReaction reaction in circleObject.reactions!) {
      if (reaction.index == index) {
        found = reaction;
        for (User user in reaction.users) {
          if (user.id == userFurnace.userid) {
            remove = true;
          }
        }
      }
    }

    if (remove) {
      found!.users.removeWhere((element) => element.id == userFurnace.userid);

      if (found.users.isEmpty)
        circleObject.reactions!.removeWhere(
          (element) => element.index == found!.index,
        );

      _circleObjectBloc.deleteReaction(
        userFurnace,
        userCircleCache,
        circleObject,
        found,
        _circleObjects[0],
      );
    } else if (found != null) {
      found.users.add(
        User(username: userFurnace.username, id: userFurnace.userid),
      );

      _circleObjectBloc.postReaction(
        widget.wall ? circleObject.userFurnace! : userFurnace,
        widget.wall ? circleObject.userCircleCache! : userCircleCache,
        circleObject,
        found,
      );
    } else {
      CircleObjectReaction reaction = CircleObjectReaction(
        index: index,
        emoji: null,
        users: [User(username: userFurnace.username, id: userFurnace.userid)],
      );

      circleObject.reactions!.add(reaction);

      _circleObjectBloc.postReaction(
        widget.wall ? circleObject.userFurnace! : userFurnace,
        widget.wall ? circleObject.userCircleCache! : userCircleCache,
        circleObject,
        reaction,
      );
    }

    setState(() {
      circleObject.showOptionIcons = false;
    });
  }

  void _showReactions(CircleObject circleObject) {
    bool isUser = false;

    UserFurnace userFurnace = _getUserFurnace(circleObject);
    //UserCircleCache userCircleCache = _getUserCircleCache(circleObject);

    if (circleObject.creator!.id == userFurnace.userid) isUser = true;

    _longPressHandler(circleObject, circleObject.showDate, isUser);
  }

  void _longReaction(CircleObject circleObject, index) {
    DialogReactions.showReactions(context, 'Reactions', circleObject);
  }

  void _shortReaction(CircleObject circleObject, index, String? emoji) {
    if (emoji!.isNotEmpty) {
      _emojiReaction(emoji, circleObject);
    } else {
      _reactionAdded(circleObject, index);
    }
    //circleObject.reactions!.sort((a, b) => a.emoji.compareTo(b.emoji));
    //_reactionAdded(circleObject, index);
  }

  int _timer = UserDisappearingTimer.OFF;

  _setTimer(int timer) {
    setState(() {
      _timer = timer;
      if (timer == UserDisappearingTimer.OFF) {
        _scheduledDate = null;
      }
    });
  }

  _setScheduled(DateTime? scheduled) {
    setState(() {
      _scheduledDate = scheduled;
    });
  }

  // _showTimer() {
  //   _closeKeyboard();
  //   DialogDisappearing.setTimer(context, _setTimer, _getDateTimeSchedule);
  // }
  //
  // String _getShortTimerString() {
  //   if (_timer == UserDisappearingTimer.ONE_TIME_VIEW) return 'OTV';
  //   if (_timer == UserDisappearingTimer.TEN_SECONDS) return '10s';
  //   if (_timer == UserDisappearingTimer.THIRTY_SECONDS) return '30s';
  //   if (_timer == UserDisappearingTimer.ONE_MINUTE) return '1m';
  //   if (_timer == UserDisappearingTimer.FIVE_MINUTES) return '5m';
  //   if (_timer == UserDisappearingTimer.ONE_HOUR) return '1h';
  //   if (_timer == UserDisappearingTimer.EIGHT_HOURS) return '8h';
  //   if (_timer == UserDisappearingTimer.ONE_DAY) return '24h';
  //
  //   return '';
  // }

  List<CircleObject> otv = [];

  CircleObject? lastTapped;

  void _shortPressHandler(CircleObject circleObject) async {
    lastTapped = circleObject;

    late UserCircleCache userCircleCache;
    late UserFurnace userFurnace;
    late Circle circle;

    if (widget.wall) {
      userCircleCache = circleObject.userCircleCache!;
      userFurnace = circleObject.userFurnace!;
      circle = userCircleCache.cachedCircle!;
    } else {
      userCircleCache = widget.userCircleCache;
      userFurnace = widget.userFurnace;
      circle = _circle;
    }

    if (circleObject.draft) {
      _clear(false);

      _circleObjects.remove(circleObject);
      _circleObjectBloc.deleteDraft(circleObject);

      if (circleObject.type == CircleObjectType.CIRCLERECIPE) {
        _refreshEnabled = false;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => CircleRecipeScreen(
                  circleObject: circleObject,
                  wall: widget.wall,
                  //_circleObjects[index],
                  setNetworks: _setSelectedNetworks,
                  userCircleCache: userCircleCache,
                  userFurnace: userFurnace,
                  screenMode: ScreenMode.ADD,
                  userFurnaces:
                      widget.wall ? widget.wallFurnaces : widget.userFurnaces!,
                  circleRecipeBloc: _circleRecipeBloc,
                  circleObjectBloc: _circleObjectBloc,
                  globalEventBloc: _globalEventBloc,
                  timer: _timer,
                  replyObject: _replyObject,
                ),
          ),
        );
        _refreshEnabled = true;
      } else if (circleObject.type == CircleObjectType.CIRCLELIST) {
        _refreshEnabled = false;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => CircleListNew(
                  userFurnace: userFurnace,
                  userCircleCache: userCircleCache,
                  circleObject: circleObject,
                  circleObjectBloc: _circleObjectBloc,
                  userFurnaces: widget.userFurnaces!,
                  circleListBloc: _circleListBloc,
                  timer: 0,
                  replyObject: _replyObject,
                ),
          ),
        );
        _refreshEnabled = true;
      } else if (circleObject.type == CircleObjectType.CIRCLECREDENTIAL ||
          (circleObject.subType != null &&
              circleObject.subType == SubType.LOGIN_INFO)) {
        _refreshEnabled = false;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => SubtypeCredential(
                  //userFurnaces: widget.userFurnaces,
                  circleObject: circleObject,
                  circleObjectBloc: _circleObjectBloc,
                  userCircleCache: userCircleCache,
                  userFurnace: userFurnace,
                  userFurnaces: widget.userFurnaces!,
                  userCircleBloc: _userCircleBloc,
                  screenMode: ScreenMode.ADD,
                  globalEventBloc: _globalEventBloc,
                  timer: _timer,
                  replyObject: _replyObject,
                  //circleRecipeBloc: _circleRecipeBloc,
                ),
          ),
        );
        _refreshEnabled = true;
      } else {
        _sendEnabled = true;

        if (circleObject.body != null) _message.text = circleObject.body!;

        if (circleObject.draftMediaCollection != null) {
          _mediaCollection = _mediaCollection ?? MediaCollection();
          _mediaCollection!.media = circleObject.draftMediaCollection!;

          _circleObjects.remove(circleObject);
          _circleObjectBloc.deleteDraft(circleObject);
        } else if (circleObject.gif != null) {
          _giphyOption = GiphyOption(
            preview: circleObject.gif!.giphy!,
            url: circleObject.gif!.giphy!,
            width: circleObject.gif!.width,
            height: circleObject.gif!.height,
          );

          _circleObjects.remove(circleObject);
          _circleObjectBloc.deleteDraft(circleObject);
        }
      }

      if (mounted) setState(() {});

      return;
    }

    _closeKeyboard();

    if (circleObject.oneTimeView == true) {
      if (otv.contains(circleObject)) {
        return;
      }

      otv.add(circleObject);

      bool allowed = false;

      allowed = await _circleObjectBloc.oneTimeView(userFurnace, circleObject);

      Color messageColor = Member.getMemberColor(
        userFurnace,
        circleObject.creator,
      );

      if (widget.wall == false)
        circleObject.userCircleCache = widget.userCircleCache;

      if (allowed) {
        if (circleObject.type == CircleObjectType.CIRCLEIMAGE ||
            circleObject.type == CircleObjectType.CIRCLEGIF) {
          circleObject.userCircleCache ?? userCircleCache;

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => FullScreenImage(
                    globalEventBloc: _globalEventBloc,
                    circleImageBloc: _circleImageBloc,
                    //imageProvider:
                    //  const AssetImage("assets/large-image.jpg"),
                    circleObject: circleObject,
                    //userCircleCache: widget.userCircleCache,
                    userFurnace: userFurnace,
                    circle: circle,
                    messageColor: messageColor,
                  ),
            ),
          );
        } else if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
          DialogDownload.showDialogOnly(context, 'Downloading..');

          ///download the preview
          _circleVideoBloc.notifyWhenPreviewReady(
            userFurnace,
            userCircleCache,
            circleObject,
          );

          ///return while preview is downloading. Don't want to delete the object until it's viewed
          return;
        } else if (circleObject.type == CircleObjectType.CIRCLEEVENT) {
          _showEvent(
            circleObject,
          ); //async should be ok, doesn't load from cache
        } else if (circleObject.type == CircleObjectType.CIRCLELIST) {
          _showFullList(
            circleObject,
            true,
          ); //async should be ok, doesn't load from cache
        } else if (circleObject.type == CircleObjectType.CIRCLERECIPE) {
          _showRecipeReadOnly(circleObject);
        } else if (circleObject.type == CircleObjectType.CIRCLEFILE) {
          if (circleObject.body != "") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => CircleMessageFullScreen(
                      body: circleObject.body!,
                      messageColor: messageColor,
                      fileHandler: _fileHandler,
                      object: circleObject,
                    ),
              ),
            );
          } else if (circleObject.file!.extension! == 'pdf') {
            _openPDF(circleObject, true);
          } else {
            _handleFile(circleObject);
          }
          // OpenFile.open(FileCacheService.returnFilePath(
          //  widget.userCircleCache.circlePath!, circleObject.file!.name!));
        } else if (circleObject.type == CircleObjectType.CIRCLEVOTE) {
          _showFullVote(circleObject);
        } else if (circleObject.type == CircleObjectType.CIRCLECREDENTIAL) {
          int screenMode = ScreenMode.READONLY;
          if (circleObject.subType == SubType.LOGIN_INFO ||
              circleObject.subType == SubType.CREDIT_CARD) {
            _showSubType(circleObject, screenMode);
          }
        } else if (circleObject.type == CircleObjectType.CIRCLELINK) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CircleMessageFullScreen(
                    body: circleObject.body!,
                    messageColor: messageColor,
                    object: circleObject,
                  ),
            ),
          );
        } else if (circleObject.type == CircleObjectType.CIRCLEMESSAGE) {
          if (circleObject.subType != null && circleObject.id != null) {
            int screenMode = ScreenMode.READONLY;

            //if (circleObject.creator!.id! != widget.userFurnace.username!)
            //int screenMode = ScreenMode.READONLY;

            if (circleObject.subType == SubType.LOGIN_INFO ||
                circleObject.subType == SubType.CREDIT_CARD) {
              _showSubType(circleObject, screenMode);
            }
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => CircleMessageFullScreen(
                      body: circleObject.body!,
                      messageColor: messageColor,
                    ),
              ),
            );
          }
        }
      }

      await _circleObjectBloc.deleteOneTimeView(userCircleCache, circleObject);

      setState(() {
        _circleObjects.remove(circleObject);
      });
    } else if (circleObject.type == CircleObjectType.CIRCLEEVENT) {
      _showEvent(circleObject);
    } else if (circleObject.type == CircleObjectType.CIRCLEALBUM) {
      _openAlbum(circleObject);
    } else if (circleObject.type == CircleObjectType.CIRCLEIMAGE) {
      _showFullScreenImage(circleObject);
    } else if (circleObject.type == CircleObjectType.CIRCLEGIF) {
      _showFullScreenImage(circleObject);
    } else if (circleObject.type == CircleObjectType.CIRCLELIST) {
      _showFullList(circleObject, false);
    } else if (circleObject.type == CircleObjectType.CIRCLEFILE) {
      //OpenResult result = await OpenFile.open(FileCacheService.returnFilePath(
      //widget.userCircleCache.circlePath!, '${circleObject.seed!}.${circleObject.file!.extension!}'));
      if (circleObject.file!.extension! == 'pdf') {
        _openPDF(circleObject, true);
      } else {
        _handleFile(circleObject);
      }

      //debugPrint(result.message);
    } else if (circleObject.type == CircleObjectType.CIRCLERECIPE) {
      if (circleObject.creator!.id == userCircleCache.user) {
        _showRecipeEdit(circleObject);
      } else {
        _showRecipeReadOnly(circleObject);
      }
    } else if (circleObject.type == CircleObjectType.CIRCLEVOTE) {
      _showFullVote(circleObject);
    } else if (circleObject.type == CircleObjectType.CIRCLEMESSAGE) {
      if (circleObject.subType != null && circleObject.id != null) {
        int screenMode = ScreenMode.EDIT;

        // if (circleObject.creator!.id! != widget.userFurnace.username!) {
        //int screenMode = ScreenMode.READONLY;

        if (circleObject.subType == SubType.LOGIN_INFO ||
            circleObject.subType == SubType.CREDIT_CARD) {
          _showSubType(circleObject, screenMode);
        }
        // }
      } else if (circleObject.reply != null) {
        if (circleObject.replyObjectID != null) {
          CircleObject obj = _circleObjects.firstWhere(
            (element) => element.id == circleObject.replyObjectID,
          );
          _scrollToIndex(_circleObjects.indexOf(obj));
        }
      }
    } else if (circleObject.type == CircleObjectType.CIRCLECREDENTIAL) {
      if (circleObject.subType != null && circleObject.id != null) {
        int screenMode = ScreenMode.EDIT;

        // if (circleObject.creator!.id! !=
        //     userFurnace.username!)
        if (circleObject.subType == SubType.LOGIN_INFO ||
            circleObject.subType == SubType.CREDIT_CARD) {
          _showSubType(circleObject, screenMode);
        }
      }
    }
  }

  _openPDF(CircleObject circleObject, bool download, {bool? replace}) async {
    String extension = circleObject.file!.extension!;

    if (globalState.isDesktop()) {
      extension = "enc";

      ///desktop files are encrypted
    }

    File internal = File(
      FileCacheService.returnFilePath(
        widget.wall
            ? circleObject.userCircleCache!.circlePath!
            : widget.userCircleCache.circlePath!,
        '${circleObject.seed!}.$extension',
      ),
    );

    if (!internal.existsSync()) {
      if (download) {
        ///download the file
        _circleFileBloc.downloadFile(
          widget.wall ? circleObject.userFurnace! : widget.userFurnace,
          widget.wall ? circleObject.userCircleCache! : widget.userCircleCache,
          circleObject,
        );
      }

      return;
    }

    File external = File(
      FileCacheService.returnFilePath(
        widget.wall
            ? circleObject.userCircleCache!.circlePath!
            : widget.userCircleCache.circlePath!,
        circleObject.file!.name!,
      ),
    );

    if (external.existsSync()) {
      external.deleteSync();
    }

    if (globalState.isDesktop()) {
      ///decrypt the file

      await EncryptBlob.decryptBlob(
        DecryptArguments(
          encrypted: internal,
          nonce: circleObject.file!.fileCrank!,
          mac: circleObject.file!.fileSignature!,
          key: circleObject.secretKey,
          destinationPath: external.path,
        ),
        deleteEncryptedSource: false,
      );
    } else {
      ///copy the file
      internal.copySync(external.path);
    }

    if (replace == true) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => PDFViewer(
                  circleObject: circleObject,
                  userCircleCache:
                      widget.wall
                          ? circleObject.userCircleCache!
                          : widget.userCircleCache,
                  name: circleObject.file!.name!,
                  path: external.path,
                ),
          ),
        );
      }
    } else {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PDFViewer(
                  circleObject: circleObject,
                  userCircleCache:
                      widget.wall
                          ? circleObject.userCircleCache!
                          : widget.userCircleCache,
                  name: circleObject.file!.name!,
                  path: external.path,
                ),
          ),
        );
      }
    }
    if (circleObject.oneTimeView == true) {
      await _circleObjectBloc.deleteOneTimeView(
        widget.wall ? circleObject.userCircleCache! : widget.userCircleCache,
        circleObject,
      );

      setState(() {
        _circleObjects.remove(circleObject);
      });
    }
  }

  _handleFileResult(
    BuildContext context,
    CircleObject circleObject,
    HandleFile handleFile,
  ) async {
    if (mounted) {
      if (handleFile == HandleFile.download) {
        _export(circleObject);
      } else if (handleFile == HandleFile.inside) {
        ShareCircleObject.shareToDestination(
          context,
          widget.userCircleCache,
          circleObject,
          true,
        );
      } else if (handleFile == HandleFile.outside) {
        ShareCircleObject.shareToDestination(
          context,
          widget.userCircleCache,
          circleObject,
          false,
        );
      }
    }
  }

  _handleFile(CircleObject circleObject) async {
    File internal = File(
      FileCacheService.returnFilePath(
        widget.userCircleCache.circlePath!,
        '${circleObject.seed!}.${circleObject.file!.extension!}',
      ),
    );

    if (!internal.existsSync()) {
      _downloadFile(circleObject);
      return;
    }

    if (mounted) {
      DialogHandleFile.handleFilePopup(
        context,
        circleObject,
        _handleFileResult,
      );
    }
  }

  _export(CircleObject circleObject) async {
    circleObject.userCircleCache = widget.userCircleCache;

    await DialogDownload.showAndDownloadCircleObjects(
      context,
      'Downloading file',
      [circleObject],
    );
    if (mounted) {
      DialogNotice.showNoticeOptionalLines(
        context,
        'Download Complete',
        'File download complete',
        false,
      );
    }
  }

  void _longPressHandler(
    CircleObject circleObject,
    bool showDate,
    bool isUser, {
    Function? copy,
    Function? share,
    Function? edit,
    Function? cancel,
    Function? export,
    Function? download,
    Function? deleteCache,
    Function? openExternalBrowser,
  }) async {
    if (circleObject.type == CircleObjectType.SYSTEMMESSAGE ||
        circleObject.type == CircleObjectType.UNABLETODECRYPT)
      return;

    double keyboard = (MediaQuery.of(context).viewInsets.bottom);

    _closeKeyboard();

    setState(() {
      circleObject.showOptionIcons = true;
    });

    int result = await Navigator.of(context).push(
      PageRouteBuilder(
        //barrierDismissible: true,
        opaque: false,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder:
            (_, __, ___) => LongPressMenu(
              keyboardSize: keyboard,
              circle:
                  widget.wall
                      ? circleObject.userCircleCache!.cachedCircle!
                      : _circle,
              wall: widget.wall,
              selected: _reactionAdded,
              circleObject: circleObject,
              globalKey: circleObject.globalKey,
              showDate: showDate,
              isUser: isUser,
              copy: copy,
              download: download,
              edit: edit,
              export: export,
              cancel: cancel,
              deleteCache: deleteCache,
              openExternalBrowser: openExternalBrowser,
              share: share,
              enableReacting: _circle.toggleMemberReacting,
              enablePosting: _circle.toggleMemberPosting,
            ),
      ),
    );

    setState(() {
      circleObject.showOptionIcons = false;
    });

    if (result == LongPressFunction.DELETE)
      _deleteObject(circleObject);
    else if (result == LongPressFunction.EDIT)
      _editObject(circleObject);
    else if (result == LongPressFunction.COPY)
      _copyObject(circleObject);
    else if (result == LongPressFunction.SHARE)
      _shareObject(circleObject);
    else if (result == LongPressFunction.CANCEL)
      _cancelTransfer(circleObject);
    else if (result == LongPressFunction.DELETE_CACHE)
      _removeCache(circleObject);
    else if (result == LongPressFunction.REPORT_POST)
      _reportPost(circleObject);
    else if (result == LongPressFunction.OPEN_EXTERNAL_BROWSER)
      _openExternalBrowser(circleObject);
    else if (result == LongPressFunction.SET_BACKGROUND)
      _setBackground(circleObject);
    else if (result == LongPressFunction.EXPORT)
      _export(circleObject);
    else if (result == LongPressFunction.DOWNLOAD) {
      if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
        _downloadVideo(circleObject);
      } else if (circleObject.type == CircleObjectType.CIRCLEFILE) {
        _downloadFile(circleObject);
      }
    } else if (result == LongPressFunction.REPLY)
      _showReply(circleObject);
    else if (result == LongPressFunction.HIDE)
      _hideObject(circleObject);
    else if (result == LongPressFunction.PIN)
      _pinObject(circleObject);
    return;
  }

  _pinObject(CircleObject circleObject) async {
    FocusScope.of(context).unfocus();

    bool pinForAll = true;
    if (_circle.type == CircleType.OWNER &&
        widget.userFurnace.role == Role.MEMBER) {
      pinForAll = false;
    }

    DialogPinPost.pinPost(
      context,
      circleObject,
      _pinObjectSelection,
      pinForAll,
    );
  }

  _pinObjectSelection(CircleObject circleObject, int selection) async {
    _circleObjectBloc.pinCircleObject(
      widget.userCircleCache,
      widget.userFurnace,
      circleObject,
      selection == 0 ? false : true,
    );
  }

  _unpinObject(CircleObject circleObject) async {
    FocusScope.of(context).unfocus();
    await DialogYesNo.askYesNo(
      context,
      'Remove pin?',
      'Do you want to remove this pin?',
      _unpinObjectConfirmed,
      null,
      false,
      circleObject,
    );
  }

  _unpinObjectConfirmed(CircleObject circleObject) {
    _circleObjectBloc.unpinCircleObject(
      widget.userCircleCache,
      widget.userFurnace,
      circleObject,
    );
  }

  _hideObject(CircleObject circleObject) async {
    FocusScope.of(context).unfocus();
    await DialogYesNo.askYesNo(
      context,
      'Delete for you?',
      'Are you sure you want to delete this post? This will not impact other members.',
      _hideObjectConfirmed,
      null,
      false,
      circleObject,
    );
  }

  _hideObjectConfirmed(CircleObject circleObject) {
    setState(() {
      _circleObjects.remove(circleObject);
    });

    _circleObjectBloc.hideCircleObject(
      widget.userCircleCache,
      widget.userFurnace,
      circleObject,
    );
  }

  _openExternalBrowser(CircleObject circleObject) {
    LaunchURLs.openExternalBrowser(context, circleObject);
  }

  _reload() {
    setState(() {
      _circleObjects = [];
      _members = globalState.members;
    });

    _initialLoad();
  }

  void _showFirstTimePrompts({bool override = false}) {
    if (globalState.userSetting.askedToGuardVault == false &&
            _circle.type == CircleType.VAULT ||
        override) {
      globalState.userSetting.setAskedToGuardVault(true);

      globalState.showPrivateVaultPrompt = false;
      DialogPrivateVaultPrompt.showShortcuts(
        context,
        widget.userCircleCache,
        widget.userFurnaces!,
        widget.userFurnace,
        _userCircleBloc,
        _firebaseBloc,
        _finish,
      );
    } else if (globalState.userSetting.firstTimeInCircle == false &&
        _circle.type == CircleType.STANDARD &&
        _circle.dm == false) {
      globalState.userSetting.setFirstTimeInCircle(true);

      //globalState.firstLoadComplete = false;
      DialogFirstTimeInCircle.showShortcuts(
        context,
        widget.userCircleCache,
        widget.userFurnaces!,
        widget.userFurnace,
        _userCircleBloc,
        _firebaseBloc,
        _finishFirstTimeInCircle,
      );
    } else if (globalState.userSetting.firstTimeInFeed == false &&
        widget.wall &&
        globalState.isDesktop() == false) {
      //debugPrint('first time feed isDesktop: ' + globalState.isDesktop().toString());
      globalState.userSetting.setFirstTimeInFeed(true);

      DialogFirstTimeInFeed.show(context);
    }
  }

  void _finishFirstTimeInCircle(
    DialogFirstTimeInCircleResponse dialogFirstTimeInCircleResponse,
  ) {
    if (dialogFirstTimeInCircleResponse ==
        DialogFirstTimeInCircleResponse.members) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => Members(
                userCircleCache: widget.userCircleCache,
                userFurnace: widget.userFurnace,
                userFurnaces: widget.userFurnaces!,
              ),
        ),
      );
    } else if (dialogFirstTimeInCircleResponse ==
        DialogFirstTimeInCircleResponse.magicLink) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => NetworkInvite(
                userFurnaces: widget.userFurnaces!,
                userFurnace: widget.userFurnace,
              ),
        ),
      );
    }
  }

  void _finish() {
    //_goHome(true, forceScratchLoad: true);

    //_circlesWalkthrough.tutorialCoachMark.show(context: context);
  }

  void _pickFiles() async {
    try {
      _closeKeyboard();
      _refreshEnabled = false;
      //if (await Permissions.imagesGranted(context)) {

      if (_editing) {
        final XFile? pickedFile = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );

        setState(() {
          if (pickedFile != null) {
            _previewImageFile(File(pickedFile.path));
          }
        });
      } else {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.custom,
          allowedExtensions: ALLOWED_FILE_TYPES,
        );

        if (result != null && result.files.isNotEmpty) {
          MediaCollection mediaCollection = MediaCollection();
          await mediaCollection.populateFromFilePicker(
            result.files,
            MediaType.file,
          );

          if (mediaCollection.isNotEmpty) {
            if (_circle.type == CircleType.VAULT) {
              _mediaCollection = mediaCollection;
              _send(overrideButton: true);
            } else {
              _showPreviewer(mediaCollection);
            }
          }
        }
      }

      _refreshEnabled = true;
      return;
    } catch (err, trace) {
      if (err.toString().contains('photo_access_denied')) {
        Permissions.askOpenSettings(context);
      } else {
        LogBloc.insertError(err, trace);
        debugPrint('_selectImage: $err');

        _imagePreview = false;
        _sendEnabled = false;
        //_cancelEnabled = false;
        _image = null;
        _refreshEnabled = true;
      }
    }
  }
  //
  // void _generateImage() async {
  //   try {
  //     _closeKeyboard();
  //     _refreshEnabled = false;
  //     //if (await Permissions.imagesGranted(context)) {
  //
  //     if (_editing) {
  //     } else {
  //       setState(() {
  //         _showSpinner = true;
  //       });
  //
  //       SelectedMedia? selectedImages = await Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => StableDiffusionWidget(
  //             userFurnace: widget.userFurnace,
  //             imageGenType: ImageType.image,
  //             //previewScreenName: widget.user,
  //           ),
  //         ),
  //       );
  //
  //       if (selectedImages != null) {
  //         _refreshEnabled = true;
  //
  //         if (selectedImages.mediaCollection.isNotEmpty) {
  //           if (_circle.type == CircleType.VAULT) {
  //             _mediaCollection = selectedImages.mediaCollection;
  //             _send(overrideButton: true);
  //           } else if (widget.wall) {
  //             _send(
  //                 overrideButton: true,
  //                 mediaCollection: selectedImages.mediaCollection);
  //           } else {
  //             _previewSelectedMedia(selectedImages);
  //           }
  //         }
  //       }
  //       // }
  //     }
  //
  //     setState(() {
  //       _showSpinner = false;
  //     });
  //
  //     _refreshEnabled = true;
  //     return;
  //   } catch (err, trace) {
  //     setState(() {
  //       _showSpinner = false;
  //     });
  //
  //     if (err.toString().contains('photo_access_denied')) {
  //       Permissions.askOpenSettings(context);
  //     } else {
  //       LogBloc.insertError(err, trace);
  //       debugPrint('_selectImage: $err');
  //
  //       _imagePreview = false;
  //       _sendEnabled = false;
  //       //_cancelEnabled = false;
  //       _image = null;
  //       _refreshEnabled = true;
  //     }
  //   }
  // }

  void _pickImagesAndVideos() async {
    try {
      _closeKeyboard();
      _refreshEnabled = false;
      //if (await Permissions.imagesGranted(context)) {

      if (_editing) {
        final XFile? pickedFile = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );

        setState(() {
          if (pickedFile != null) {
            _previewImageFile(File(pickedFile.path));
          }
        });
      } else {
        setState(() {
          _showSpinner = true;
        });

        FilePickerResult? result;

        if (Platform.isWindows) {
          ///File picker separated video and images for some reason on Windows
          result = await FilePicker.platform.pickFiles(
            allowMultiple: true,
            type: FileType.custom,
            allowedExtensions: ALLOWED_MEDIA_TYPES,
          );
        } else {
          result = await FilePicker.platform.pickFiles(
            allowMultiple: true,
            type: FileType.media,
          );
        }

        if (result != null && result.files.isNotEmpty) {
          MediaCollection mediaCollection = MediaCollection();
          await mediaCollection.populateFromFilePicker(
            result.files,
            MediaType.image,
          );

          _showPreviewer(mediaCollection);
        } else {
          _refreshEnabled = true;
          setState(() {
            _showSpinner = false;
          });
        }
      }

      return;
    } catch (err, trace) {
      _showSpinner = false;

      if (mounted) {
        setState(() {});
      }

      if (err.toString().contains('photo_access_denied')) {
        Permissions.askOpenSettings(context);
      } else {
        LogBloc.insertError(err, trace);
        debugPrint('_selectImage: $err');

        _imagePreview = false;
        _sendEnabled = false;
        //_cancelEnabled = false;
        _image = null;
        _refreshEnabled = true;
      }
    }
  }

  _fileHandler(CircleObject circleObject) {
    if (circleObject.file!.extension! == 'pdf') {
      _openPDF(circleObject, true);
    } else {
      _handleFile(circleObject);
    }
  }

  bool viewingOTV = false;

  _processOTVVideoDownloaded(CircleObject circleObject) async {
    if (viewingOTV) {
      return;
    }

    viewingOTV = true;
    Navigator.pop(context);

    var result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FullScreenGallerySwiper(
              albumDownloadVideo: _albumDownloadVideo,
              globalEventBloc: _globalEventBloc,
              circleImageBloc: _circleImageBloc,
              circleAlbumBloc: _circleAlbumBloc,
              libraryObjects: [circleObject],
              fullScreenSwiperCaller:
                  widget.wall
                      ? FullScreenSwiperCaller.feed
                      : FullScreenSwiperCaller.circle,
              userFurnaces: widget.wallFurnaces,
              userCircleCaches: widget.wallUserCircleCaches,
              circleObject: circleObject,
              //userCircleCache: widget.userCircleCache,
              userFurnace:
                  widget.wall ? circleObject.userFurnace! : widget.userFurnace,
              circle:
                  widget.wall
                      ? circleObject.userCircleCache!.cachedCircle!
                      : _circle,
              delete: _swiperDelete,
              //oneView: videoOneTimeView != null ? true : false,
            ),
      ),
    );

    await _circleObjectBloc.deleteOneTimeView(
      widget.userCircleCache,
      circleObject,
    );

    setState(() {
      _circleObjects.remove(circleObject);
    });

    viewingOTV = false;
  }

  void _swiperDelete(CircleObject circleObject) async {
    FocusScope.of(context).unfocus();

    String title = "Delete for you?";
    String description =
        'Are you sure you want to delete this post? This will not impact other members.';

    if (circleObject.circle!.id == DeviceOnlyCircle.circleID) {
      description = "Are you sure you want to delete this cached media?";
    } else if (widget.wall &&
        circleObject.creator?.id == circleObject.userFurnace!.userid) {
      title = "Delete for everyone?";
      description = "Are you sure you want to delete this?";
    } else if (circleObject.creator?.id == widget.userFurnace.userid) {
      title = "Delete for everyone?";
      description = "Are you sure you want to delete this?";
    }

    await DialogYesNo.askYesNo(
      context,
      title,
      description,
      _swiperDeleteConfirmed,
      null,
      false,
      circleObject,
    );
  }

  _swiperDeleteConfirmed(CircleObject circleObject) async {
    List<CircleObject> isUserObject = [];
    List<CircleObject> isDeviceObject = [];

    setState(() {
      if (circleObject.circle!.id == DeviceOnlyCircle.circleID) {
        isDeviceObject.add(circleObject);
      } else if (circleObject.creator?.id == widget.userFurnace.userid) {
        isUserObject.add(circleObject);
      } else {
        _circleObjectBloc.hideCircleObject(
          widget.userCircleCache,
          widget.userFurnace,
          circleObject,
        );
        _globalEventBloc.broadcastDelete(circleObject);
      }
    });

    ///for device only objects
    if (isDeviceObject.isNotEmpty) {
      await _circleImageBloc.removeFromDeviceCache(isDeviceObject);
      _globalEventBloc.broadcastDelete(isDeviceObject.single);
    }

    ///for user's objects
    if (isUserObject.isNotEmpty) {
      await _circleObjectBloc.deleteObjects(
        widget.userFurnace,
        widget.userCircleCache,
        isUserObject,
      );
      _globalEventBloc.broadcastDelete(isUserObject.single);
    }
  }

  setSendEnabled(bool enabled) {
    setState(() {
      _sendEnabled = enabled;
    });
  }

  passMediaCollection(Media media) {
    ///used to pass emojis from keyboard
    _keyboardMediaCollection ??= MediaCollection();
    setState(() {
      _keyboardMediaCollection!.add(media);
    });
  }

  setMembersList(bool membersList) {
    setState(() {
      _membersList = membersList;
    });
  }

  filterMembersList(List<Member> passedMembersFiltered) {
    setState(() {
      membersFiltered = passedMembersFiltered;
    });
  }

  setTypingTag(String typingTag) {
    setState(() {
      this.typingTag = typingTag;
    });
  }

  setWhereTag(int whereTag) {
    setState(() {
      this.whereTag = whereTag;
    });
  }

  bool _panelOpen = false;
  //
  // showModalBottomSheet<T>({
  //   required BuildContext context,
  //   required WidgetBuilder builder,
  //   Color? backgroundColor,
  //   String? barrierLabel,
  //   double? elevation,
  //   ShapeBorder? shape,
  //   Clip? clipBehavior,
  //   BoxConstraints? constraints,
  //   Color? barrierColor,
  //   bool isScrollControlled = false,
  //   double scrollControlDisabledMaxHeightRatio =
  //       50,
  //   bool useRootNavigator = false,
  //   bool isDismissible = true,
  //   bool enableDrag = true,
  //   bool? showDragHandle,
  //   bool useSafeArea = false,
  //   RouteSettings? routeSettings,
  //   AnimationController? transitionAnimationController,
  //   Offset? anchorPoint,
  //   AnimationStyle? sheetAnimationStyle,
  // }) {
  //   assert(debugCheckHasMediaQuery(context));
  //   assert(debugCheckHasMaterialLocalizations(context));
  //
  //   final NavigatorState navigator =
  //       Navigator.of(context, rootNavigator: useRootNavigator);
  //   final MaterialLocalizations localizations =
  //       MaterialLocalizations.of(context);
  //   return navigator.push(ModalBottomSheetRoute<T>(
  //     builder: builder,
  //     capturedThemes:
  //         InheritedTheme.capture(from: context, to: navigator.context),
  //     isScrollControlled: isScrollControlled,
  //     scrollControlDisabledMaxHeightRatio: scrollControlDisabledMaxHeightRatio,
  //     barrierLabel: barrierLabel ?? localizations.scrimLabel,
  //     barrierOnTapHint:
  //         localizations.scrimOnTapHint(localizations.bottomSheetLabel),
  //     backgroundColor: backgroundColor,
  //     elevation: elevation,
  //     shape: shape,
  //     clipBehavior: clipBehavior,
  //     constraints: constraints,
  //     isDismissible: isDismissible,
  //     modalBarrierColor:
  //         barrierColor ?? Theme.of(context).bottomSheetTheme.modalBarrierColor,
  //     enableDrag: enableDrag,
  //     showDragHandle: showDragHandle,
  //     settings: routeSettings,
  //     transitionAnimationController: transitionAnimationController,
  //     anchorPoint: anchorPoint,
  //     useSafeArea: useSafeArea,
  //     //sheetAnimationStyle: sheetAnimationStyle,
  //   ));
  // }

  _showPanel(SharedMediaHolder? sharedMediaHolder) async {
    _closeKeyboard();
    _refreshEnabled = false;
    _panelOpen = true;

    if (globalState.isDesktop()) {
      showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          return BottomSheetWidget(
            message: _message.text,
            selectGif: _selectGif,
            generate: _generate,
            createRecipe: _createRecipe,
            createList: _createList,
            createEvent: _createEvent,
            createVote: _createVote,
            createCredential: _createCredential,
            height: _height,
            width: _width,
            itemPositionsListener: _itemPositionsListener,
            sharedMediaHolder: sharedMediaHolder,
            itemScrollController: _itemScrollController,
            scrollingDown: _scrollingDown,
            feed: widget.wall,
            firstTimeLoadComplete: _firstTimeLoadComplete,
            circleVoteBloc: _voteBloc,
            reload: _reload,
            timer: _timer,
            panelClosed: _panelClosed,
            setTimer: _setTimer,
            setScheduled: _setScheduled,
            maxWidth: _width,
            clear: _clearNow,
            crossObjects: widget.memCacheObjects,
            collapse: _panelCollapsed,
            scrollToIndex: _scrollToIndex,
            addObjects: _addObjects,
            userCircleBloc: _userCircleBloc,
            circleListBloc: _circleListBloc,
            members: _members,
            wall: widget.wall,
            //userCircleCache: widget.userCircleCache,
            userFurnace: widget.userFurnace,
            wallFurnaces: widget.wallFurnaces,
            allFurnaces: widget.userFurnaces!,
            userCircleCaches:
                widget.wallUserCircleCaches.isEmpty
                    ? [widget.userCircleCache]
                    : widget.wallUserCircleCaches,
            circleObjects: _circleObjects,
            objectsLength: _circleObjects.length,
            refresh: _refresh,
            tabBackgroundColor: globalState.theme.slideUpPanelBackground,
            onNotification: onNotification,
            //circle: _circle,
            tapHandler: _shortPressHandler,
            shareObject: _shareObject,
            unpinObject: _unpinObject,
            openExternalBrowser: _openExternalBrowser,
            leave: _leave,
            export: _export,
            cancelTransfer: _cancelTransfer,
            longPressHandler: _longPressHandler,
            longReaction: _longReaction,
            shortReaction: _shortReaction,
            storePosition: _storePosition,
            pickImagesAndVideos: _pickImagesAndVideos,
            copyObject: _copyObject,
            reactionAdded: _reactionAdded,
            showReactions: _showReactions,
            videoControllerBloc: _videoControllerBloc,
            globalEventBloc: _globalEventBloc,
            circleVideoBloc: _circleVideoBloc,
            circleImageBloc: _circleImageBloc,
            circleObjectBloc: _circleObjectBloc,
            circleFileBloc: _circleFileBloc,
            circleRecipeBloc: _circleRecipeBloc,
            updateList: _updateList,
            submitVote: _submitVote,
            deleteObject: _deleteObject,
            editObject: _editObject,
            streamVideo: _streamVideo,
            downloadVideo: _downloadVideo,
            downloadFile: _downloadFile,
            retry: _retry,
            predispose: _predispose,
            playVideo: _playVideo,
            removeCache: _removeCache,
            populateVideoFile: PopulateMedia.populateVideoFile,
            populateRecipeImageFile: PopulateMedia.populateRecipeImageFile,
            populateImageFile: PopulateMedia.populateImageFile,
            displayReactionsRow: true,
            pickFiles: _pickFiles,
            send: _send,
            sendLink: _sendLink,
            captureMedia: _captureMedia,
            selectMedia: _pickImagesAndVideos,
            interactive: true,
            refreshObjects: _refreshCircleObjects,
          );
        },
        enableDrag: Platform.isIOS ? false : true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        constraints: BoxConstraints(
          maxWidth: _width * .7,
          maxHeight: _height * .8,
        ),
        isScrollControlled: false,
        scrollControlDisabledMaxHeightRatio: 100,
        barrierColor: globalState.theme.dialogTransparentBackground,
        backgroundColor: globalState.theme.dialogTransparentBackground,
      );
    } else {
      Scaffold.of(context).showBottomSheet(
        (BuildContext context) {
          // showModalBottomSheet<void>(
          //   context: context,
          //   builder: (BuildContext context) {
          return BottomSheetWidget(
            message: _message.text,
            selectGif: _selectGif,
            generate: _generate,
            createRecipe: _createRecipe,
            createList: _createList,
            createEvent: _createEvent,
            createVote: _createVote,
            createCredential: _createCredential,
            height: _height,
            width: _width,
            itemPositionsListener: _itemPositionsListener,
            sharedMediaHolder: sharedMediaHolder,
            itemScrollController: _itemScrollController,
            scrollingDown: _scrollingDown,
            feed: widget.wall,
            firstTimeLoadComplete: _firstTimeLoadComplete,
            circleVoteBloc: _voteBloc,
            reload: _reload,
            timer: _timer,
            panelClosed: _panelClosed,
            setTimer: _setTimer,
            setScheduled: _setScheduled,
            maxWidth: _width,
            clear: _clearNow,
            crossObjects: widget.memCacheObjects,
            collapse: _panelCollapsed,
            scrollToIndex: _scrollToIndex,
            addObjects: _addObjects,
            userCircleBloc: _userCircleBloc,
            circleListBloc: _circleListBloc,
            members: _members,
            wall: widget.wall,
            //userCircleCache: widget.userCircleCache,
            userFurnace: widget.userFurnace,
            wallFurnaces: widget.wallFurnaces,
            allFurnaces: widget.userFurnaces!,
            userCircleCaches:
                widget.wallUserCircleCaches.isEmpty
                    ? [widget.userCircleCache]
                    : widget.wallUserCircleCaches,
            circleObjects: _circleObjects,
            objectsLength: _circleObjects.length,
            refresh: _refresh,
            tabBackgroundColor: globalState.theme.slideUpPanelBackground,
            onNotification: onNotification,
            //circle: _circle,
            tapHandler: _shortPressHandler,
            shareObject: _shareObject,
            unpinObject: _unpinObject,
            openExternalBrowser: _openExternalBrowser,
            leave: _leave,
            export: _export,
            cancelTransfer: _cancelTransfer,
            longPressHandler: _longPressHandler,
            longReaction: _longReaction,
            shortReaction: _shortReaction,
            storePosition: _storePosition,
            pickImagesAndVideos: _pickImagesAndVideos,
            copyObject: _copyObject,
            reactionAdded: _reactionAdded,
            showReactions: _showReactions,
            videoControllerBloc: _videoControllerBloc,
            globalEventBloc: _globalEventBloc,
            circleVideoBloc: _circleVideoBloc,
            circleImageBloc: _circleImageBloc,
            circleObjectBloc: _circleObjectBloc,
            circleFileBloc: _circleFileBloc,
            circleRecipeBloc: _circleRecipeBloc,
            updateList: _updateList,
            submitVote: _submitVote,
            deleteObject: _deleteObject,
            editObject: _editObject,
            streamVideo: _streamVideo,
            downloadVideo: _downloadVideo,
            downloadFile: _downloadFile,
            retry: _retry,
            predispose: _predispose,
            playVideo: _playVideo,
            removeCache: _removeCache,
            populateVideoFile: PopulateMedia.populateVideoFile,
            populateRecipeImageFile: PopulateMedia.populateRecipeImageFile,
            populateImageFile: PopulateMedia.populateImageFile,
            displayReactionsRow: true,
            pickFiles: _pickFiles,
            send: _send,
            sendLink: _sendLink,
            captureMedia: _captureMedia,
            selectMedia: _pickImagesAndVideos,
            interactive: true,
            refreshObjects: _refreshCircleObjects,
          );
        },
        enableDrag: Platform.isIOS ? false : true,
        // shape: const RoundedRectangleBorder(
        //   borderRadius: BorderRadius.only(
        //     topLeft: Radius.circular(10),
        //     topRight: Radius.circular(10),
        //   ),
        // ),
        //
        // constraints: BoxConstraints(
        //   maxWidth: globalState.isDesktop() ? _width * .7 : _width,
        //   maxHeight: globalState.isDesktop() ? _height * .8 : _height,
        // ),
        // isScrollControlled: false,
        //backgroundColor: globalState.theme.dialogTransparentBackground,
      );
    }

    _sharedGif = null;
    _sharedMedia = null;
    _sharedText = null;
    _sharedVideo = null;

    _globalEventBloc.broadcastRefreshWall();
  }

  _showPanelWithoutShare() async {
    _showPanel(null);
  }

  _showPanelWithShare() {
    if (_editing == false) {
      SharedMediaHolder sharedMediaHolder = SharedMediaHolder(
        message: _sharedText ?? '',
        sharedMedia: _sharedMedia,
        sharedGif: _sharedGif,
        sharedVideo: _sharedVideo,
      );

      _showPanel(sharedMediaHolder);
    }
  }

  bool _validCircle(String circleID) {
    if (circleID == _currentCircle || widget.wall) {
      //is this the circle we are currently in?
      if (widget.wall) {
        ///verify the circle is part of the wall circles
        int index = widget.wallUserCircleCaches.indexWhere(
          (element) => element.circle! == circleID,
        );

        if (index == -1) return false;
      }
    } else {
      return false;
    }
    return true;
  }

  _setSelectedNetworks(List<UserFurnace> newlySelectedNetworks) {
    _selectedNetworks.clear();
    _selectedNetworks.addAll(newlySelectedNetworks);
  }

  _generate() async {
    if (widget.wall == false || widget.wallFurnaces.length == 1) {
      _selectedNetworks.clear();
      _selectedNetworks.add(widget.userFurnace);
    }

    SelectedMedia? selectedImages = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => StableDiffusionWidget(
              userFurnace: widget.userFurnace,
              previewScreenName:
                  widget.wall
                      ? "Network Feed"
                      : widget.userCircleCache.prefName ?? '',
              wall: widget.wall,
              userFurnaces:
                  widget.wall ? widget.wallFurnaces : [widget.userFurnace],
              //selectedNetworks: _selectedNetworks,
              setNetworks: _setSelectedNetworks,
              //redo: widget.redo,
              imageGenType: ImageType.image,
            ),
      ),
    );

    if (selectedImages != null) {
      if (selectedImages.mediaCollection.isNotEmpty) {
        if (_circle.type == CircleType.VAULT) {
          _mediaCollection = selectedImages.mediaCollection;
          _send(overrideButton: true);
        } else if (widget.wall) {
          for (UserFurnace selectedNetwork in _selectedNetworks) {
            UserCircleCache userCircleCache = _getUserCircleCacheFromFurnace(
              selectedNetwork,
            );

            debugPrint(
              'InsideCircle._previewMedia: network userid: ${selectedNetwork.userid!}, userCircleCache: ${userCircleCache.usercircle!}, circle: ${userCircleCache.circle!}',
            );

            CircleObject newPost = _prepNewCircleObject(
              selectedNetwork,
              userCircleCache,
              caption: selectedImages.caption,
            );

            _send(
              vaultObject: newPost,
              mediaCollection: selectedImages.mediaCollection,
              overrideButton: true,
              message: selectedImages.caption,
              hiRes: selectedImages.hiRes,
              streamable: selectedImages.streamable,
            );
          }
        } else {
          _send(
            overrideButton: true,
            mediaCollection: selectedImages.mediaCollection,
          );
        }
      }
    }
  }

  UserFurnace getStageFurnace() {
    late UserFurnace furnace;

    if (widget.wall == false) {
      furnace = widget.userFurnace;
    } else if (_selectedNetworks.isNotEmpty) {
      ///default to the auth furnace if it is wall enabled
      int index = _selectedNetworks.indexWhere(
        (element) => element.authServer == true,
      );

      if (index != -1) {
        furnace = _selectedNetworks[index];
      } else {
        furnace = _selectedNetworks[0];
      }
    } else {
      furnace = widget.userFurnace;
    }

    return furnace;
  }

  void _albumDownloadVideo(AlbumItem item, CircleObject object) {
    setState(() {
      object.retries = 0;
      item.retries = 0;
    });
    _circleVideoBloc.downloadAlbumVideo(
      widget.userFurnace,
      widget.userCircleCache,
      object,
      item,
    );
  }

  _onDeletePress(int index) async {
    setState(() {
      _keyboardMediaCollection!.media.removeAt(index);
    });
  }

  void _openAlbum(CircleObject circleObject) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CircleAlbumScreen(
              deviceOnly: false,
              circleObject: circleObject,
              userCircleCache:
                  widget.wall
                      ? circleObject.userCircleCache!
                      : widget.userCircleCache,
              userFurnace:
                  widget.wall ? circleObject.userFurnace! : widget.userFurnace,
              circleAlbumBloc: _circleAlbumBloc,
              circleObjectBloc: _circleObjectBloc,
              globalEventBloc: _globalEventBloc,
              fullScreenSwiperCaller: FullScreenSwiperCaller.circle,
              circleVideoBloc: _circleVideoBloc,
              circleImageBloc: _circleImageBloc,
              interactive: true,
              downloadVideo: _albumDownloadVideo,
            ),
      ),
    );
  }

  List<String> alreadyFetching = [];

  _fetchObjectById(String id) async {
    try {
      if (alreadyFetching.contains(id)) return;
      alreadyFetching.add(id);

      CircleObject circleObject = await _circleObjectBloc.fetchObjectById(id);

      circleObject.userCircleCache = widget.userCircleCache;
      circleObject.userFurnace = widget.userFurnace;

      ///populate the image or video thumbnail bytes
      try {
        if (circleObject.type == CircleObjectType.CIRCLEIMAGE) {
          Uint8List? imageBytes = await EncryptBlob.decryptBlobToMemory(
            DecryptArguments(
              encrypted: File(
                ImageCacheService.returnThumbnailPath(
                  widget.userCircleCache!.circlePath!,
                  circleObject,
                ),
              ),
              nonce: circleObject.image!.thumbCrank!,
              mac: circleObject.image!.thumbSignature!,
              key: circleObject.secretKey,
            ),
          );

          if (imageBytes != null) {
            circleObject.image!.imageBytes = imageBytes;
          }
        } else if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
          Uint8List? _imageBytes = await EncryptBlob.decryptBlobToMemory(
            DecryptArguments(
              encrypted: File(
                VideoCacheService.returnPreviewPath(
                  circleObject,
                  widget.userCircleCache.circlePath!,
                ),
              ),
              nonce: circleObject.video!.thumbCrank!,
              mac: circleObject.video!.thumbSignature!,
              key: circleObject.secretKey,
            ),
          );

          if (_imageBytes != null) {
            circleObject.video!.previewBytes = _imageBytes;
          }
        }
      } catch (error, trace) {
        LogBloc.insertError(error, trace);
      }

      _globalEventBloc.broadcastMemCacheCircleObjectsAdd([circleObject]);
      CircleObjectCollection.addObjects(
        _circleObjects,
        [circleObject],
        _circle.id!,
        [],
        [],
      );

      setState(() {});
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
    }
  }

  _pasteImage() async {
    try {
      final imageBytes = await Pasteboard.image;

      if (imageBytes != null) {
        File temp = await FileSystemService.getNewTempImageFile();
        await temp.writeAsBytes(imageBytes);

        MediaCollection mediaCollection = MediaCollection();
        mediaCollection.media.add(
          Media(mediaType: MediaType.image, path: temp.path),
        );

        _showPreviewer(mediaCollection);
      }
    } catch (err) {
      debugPrint(err.toString());
    }

    return;
  }

  _previewDroppedImages(DropDoneDetails detail) async {
    MediaCollection mediaCollection = MediaCollection();

    for (XFile file in detail.files) {
      String? mime = lookupMimeType(file.path);

      if (mime != null) {
        if (mime.contains('image'))
          mediaCollection.add(
            Media(path: file.path, mediaType: MediaType.image),
          );
        else if (mime.contains('video')) {
          Media video = Media(path: file.path, mediaType: MediaType.video);

          video.thumbnail =
              (await VideoCacheService.cacheTempVideoPreview(
                video.path,
                0,
              )).path;

          mediaCollection.add(video);
        } else {
          mediaCollection.add(
            Media(path: file.path, mediaType: MediaType.file),
          );
        }
      }
    }
    _showPreviewer(mediaCollection);
  }

  _doNothing() {}

  _generateMessages() async {
    for (int i = 0; i < 5000; i++) {
      _message.text = 'Message $i';
      _send(overrideButton: true);
      await Future.delayed(Duration(milliseconds: 250));
    }
  }

  // _openAngora() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (context) => Agora(circleID: _circle.id ?? '', userFurnace: widget.userFurnace)),
  //   );
  // }

}
