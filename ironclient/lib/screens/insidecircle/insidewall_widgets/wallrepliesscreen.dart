import 'dart:async';
import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/member_bloc.dart';
import 'package:ironcirclesapp/blocs/replyobject_bloc.dart';
import 'package:ironcirclesapp/models/circleobjectreaction.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/replyobject.dart';
import 'package:ironcirclesapp/models/violation.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/report_post.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidewall_widgets/repliestextfield_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidewall_widgets/wallreply_widget.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';
import 'package:ironcirclesapp/screens/widgets/reactions/dialogreactions.dart';
import 'package:ironcirclesapp/screens/widgets/reactions/long_press_menu.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:ironcirclesapp/utils/emojiutil.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class WallRepliesScreen extends StatefulWidget {
  CircleObject circleObject;
  ReplyObjectBloc replyObjectBloc;
  UserFurnace userFurnace;
  Function refresh;
  final double maxWidth;
  UserCircleCache userCircleCache;
  bool fromReply;
  GlobalEventBloc globalEventBloc;
  List<ReplyObject>? replyObjects;
  MemberBloc memberBloc;

  WallRepliesScreen({
    Key? key,
    required this.circleObject,
    required this.replyObjectBloc,
    required this.userFurnace,
    required this.refresh,
    required this.maxWidth,
    required this.userCircleCache,
    required this.fromReply,
    required this.globalEventBloc,
    required this.replyObjects,
    required this.memberBloc,
  }) : super(key: key);

  @override
  WallRepliesScreenState createState() => WallRepliesScreenState();
}

class WallRepliesScreenState extends State<WallRepliesScreen> {
  List<ReplyObject> _replyObjects = [];

  GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  final _message = TextEditingController();
  late FocusNode _focusNode;
  bool _sendEnabled = false;
  bool _editing = false;
  ReplyObject? _editingObject;

  bool backgroundLoadFinished = false;
  bool _scrollingDown = false;
  bool _thereAreNoOlderPosts = false;
  bool _popping = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  static const int _scrollDuration = 250;
  final List<ReplyObject> _waitingOnScroller = [];

  String? _replyingTo;
  List<ReplyObject> _displayObjects = [];
  String? _replyingToUser;
  Color _replyingToColor = globalState.theme.userObjectText;
  String? _replyingToBody = "";

  final ScrollController _scrollController = ScrollController();
  List<User> taggedUsers = [];
  String typingTag = "";
  int whereTag = 0;
  List<User> members = [];
  List<Member> _members = [];
  bool _membersList = false;
  String clickedMember = "";
  List<Member> membersFiltered = [];

  bool _showTextField = true;
  final _emojiController = TextEditingController();
  bool _emojiShowing = false;
  ReplyObject? _reactingTo;
  bool _postedEmoji = false;


  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  int _loadCount = 1;
  int _spinMax = 0;

  late double taggingWidth;

  StreamSubscription? replyObjectBroadcastStream;

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

  @override
  void initState() {
    super.initState();

    _emojiController.addListener(() {
      if (_emojiController.text.isNotEmpty) {
        debugPrint(_emojiController.text);
        _emojiReaction(_emojiController.text, _reactingTo);
        setState(() {
          _emojiController.text = '';
        });
      }
    });

    taggingWidth = InsideConstants.getCircleObjectSize(widget.maxWidth);

    _focusNode = FocusNode();

    widget.memberBloc.loaded.listen((members) {
      if (mounted) {
        setState(() {
          _members = members;
        });
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    widget.memberBloc.getConnectedMembers(
        [widget.userFurnace], [widget.userCircleCache],
        removeDM: true, excludeOwnerCircles: false);

    replyObjectBroadcastStream = widget.globalEventBloc.replyObjectBroadcast.listen((result) async {
      debugPrint("...........START UPSERT TO SCREEN: ${DateTime.now()}");

      if (result.id == null) {
        _addObjects([result], true);
        setState(() {
          _showSpinner = false;
        });
      } else {
        ReplyObjectCollection.addObjects(
          _replyObjects,
          [result],
          result.circleObjectID!,
          widget.userFurnace,
        );
        _addObjects([result], true);
        reloadObjects();
      }

    }, onError: (err) {
      debugPrint("WallRepliesScreen replyObjectBroadcast.listen: $err");
    }, cancelOnError: false);

    ///Listen for any new CircleObjects that arrive
    widget.replyObjectBloc.olderReplyObjects.listen((replyObjects) {
      if (mounted) {
        if (replyObjects.isEmpty) {
          _thereAreNoOlderPosts = true;
        } else {
          _thereAreNoOlderPosts = false;
          setState(() {
            _checkSpinner();

            ///These get added at the top, so just add them. Should make the scroller janky
            ReplyObjectCollection.addObjects(
                _replyObjects,
                replyObjects,
                widget.circleObject.id!,
                widget.userFurnace);
            reloadObjects();
            //_refreshIndicatorKey = GlobalKey<RefreshIndicatorState>(); forces scroll to bottom, avoid
          });

          debugPrint(
              'WallRepliesScreen.listen.olderReplyObjects: ${replyObjects.length}, and new total ${_replyObjects.length}');
        }
      }
    }, onError: (err) {
      _clearSpinner();
      debugPrint("WallRepliesScreen.listen.olderReplyObjects: $err");
    }, cancelOnError: false);

    ///Listen for any new replyobjects that arrive
    widget.replyObjectBloc.newerReplyObjects.listen((newReplyObjects) {
      if (mounted) {
        setState(() {
          _checkSpinner();

          if (newReplyObjects!.isNotEmpty) {
            _addObjects(newReplyObjects, false);

            //widget.wallReplyBloc.markReadForCircle
          } else {
            _showSpinner = false;
          }
        });
      }
    }, onError: (err) {
      _clearSpinner();
      debugPrint("WallRepliesScreen.listen.newReplyObjects: $err");
    }, cancelOnError: false);

    widget.replyObjectBloc.saveResults.listen((result) {
      _upsertReplyObject(result);
      reloadObjects();
    }, onError: (err) {
      debugPrint('WallRepliesScreen.listen: $err');
      setState(() {
        _showSpinner = false;
      });
    }, cancelOnError: false);

    widget.replyObjectBloc.saveFailed.listen((result) {
      int index = _replyObjects.indexWhere(
          (replyObject) => replyObject.seed == result.replyObject.seed);

      if (index != -1) _replyObjects.removeAt(index);
      reloadObjects();
    }, onError: (err) {
      debugPrint("WallRepliesScreen.listen: $err");
      setState(() {
        _showSpinner = false;
      });
    }, cancelOnError: false);

    // circleObjectBroadcastStream =
    //     _globalEventBloc.circleObjectBroadcast.listen((result) async {
    //       debugPrint("...........START UPSERT TO SCREEN: ${DateTime.now()}");
    //
    //       if (_validCircle(result.circle!.id!)) {
    //         // if (mounted) {
    //         //   if (widget.markRead != null) await widget.markRead!(result);
    //         // }
    //
    //         ///always scroll for new objects
    //         bool scroll = false;
    //         if (result.id == null) scroll = true;
    //         _addObjects([result], scroll);
    //
    //         if (result.id != null) {
    //           if (widget.markRead != null)
    //             await widget.markRead!(result);
    //           else
    //             _circleObjectBloc.markReadForCircle(_circle.id!, result.created!);
    //         }
    //         if (mounted) {
    //           setState(() {
    //             _showSpinner = false;
    //           });
    //         }
    //       }
    //
    //       //debugPrint("...........FINISHED UPSERT TO SCRFEEN: ${DateTime.now()}");
    //     }, onError: (err) {
    //       debugPrint("InsideCircle.listen: $err");
    //     }, cancelOnError: false);

    ///Listen for individual deletions
    widget.replyObjectBloc.replyObjectDeleted.listen((result) {
      if (mounted) {
        int index = _replyObjects
            .indexWhere((replyObject) => replyObject.id == result);

        if (index != -1) {
          setState(() {
            _replyObjects.removeAt(index);
            reloadObjects();
          });
          //widget.wallReplyBloc.sinkVaultRefresh();
          // widget.globalEventBloc.broadcastDelete(result);
        }
      }
    }, onError: (err) {
      debugPrint("WallRepliesScreen.listen: $err");
    }, cancelOnError: false);

    ///Listen for multiple deletions
    widget.replyObjectBloc.replyObjectsDeleted.listen((deletedItems) {
      if (mounted) {
        for (ReplyObject replyObject in deletedItems) {
          int index = _replyObjects.indexWhere(
              (replyobject) => replyobject.seed == replyObject.seed);

          if (index != -1) {
            setState(() {
              _replyObjects.removeAt(index);
              reloadObjects();
            });
          }
        }
      }
    }, onError: (err) {
      debugPrint("WallRepliesScreen.listen: $err");
    }, cancelOnError: false);

    widget.replyObjectBloc.replyObjects.listen((repliesList) {
      if (mounted) {
        setState(() {
          debugPrint("reply objects:" + repliesList.length.toString());
          _replyObjects = repliesList;
          reloadObjects();
        });
        // _replyList = repliesList;
        // if (_replyList.isEmpty) {
        //   //widget.replyHolder.repliesLength = 0;
        // }
      }
    }, onError: (err) {
      debugPrint("WallRepliesWidget.wallReplyBloc.replies: $err");
    }, cancelOnError: false);

    widget.replyObjectBloc.getReplies(
        false, widget.userFurnace, widget.circleObject, widget.userCircleCache);

    if (widget.replyObjects != null) {
      setState(() {
        _replyObjects = widget.replyObjects!;
        reloadObjects();
      });
    }

    if (widget.fromReply == true) {
      //_replyTo();
    }
  }

  reloadObjects() {
    _replyObjects.sort((a, b) => a.created!.compareTo(b.created!));
    _displayObjects = _replyObjects.where((element) => element.replyToID == null).toList();
    _displayObjects = _displayObjects.reversed.toList();
  }

  @override
  void dispose() {
    _message.dispose();
    _focusNode.dispose();
    replyObjectBroadcastStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textField = RepliesTextField(
        message: _message,
        clear: _clear,
        focusNode: _focusNode,
        replyToObject: widget.circleObject,
        sendEnabled: _sendEnabled,
        editing: _editing,
        editingObject: _editingObject,
        replyingObjectID: _replyingTo ?? '',
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
        clickedMember: clickedMember);

    Stack makeReplies = Stack(children: [
      Container(
          margin: const EdgeInsets.only(top: 0, left: 5.0, right: 5.0),
          child: RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _refresh,
              color: globalState.theme.buttonIcon,
              child: _replyObjects.isEmpty
                  ? Center(
                      child: Container(
                          decoration: BoxDecoration(
                            color: globalState.theme.background,
                          ),
                          child: _showSpinner ? spinkit : Container()))
                  : NotificationListener<ScrollEndNotification>(
                      onNotification: onNotification,
                      child: ScrollablePositionedList.separated(
                          itemCount: _displayObjects.length,
                          reverse: true,
                          itemScrollController: _itemScrollController,
                          itemPositionsListener: _itemPositionsListener,
                          physics: const AlwaysScrollableScrollPhysics(),
                          separatorBuilder: (context, index) {
                            return Container(
                              color: globalState.theme.background,
                              width: double.maxFinite,
                            );
                          },
                          itemBuilder: (context, index) {
                            ReplyObject reply = _displayObjects[index];

                            List<ReplyObject> theseReplies = _replyObjects.where((element) => element.replyToID != null && element.replyToID == reply.id).toList();
                            if (theseReplies.isNotEmpty) {
                               theseReplies.sort((a, b) => a.created!.compareTo(b.created!));
                            }

                            Color messageColor;
                            if (reply.creator != null &&
                                reply.creator!.id !=
                                    widget.userFurnace.userid) {
                              messageColor = Member.getMemberColor(
                                  widget.userFurnace, reply.creator);
                            } else {
                              messageColor = globalState.theme.userObjectText;
                            }

                            bool isUser = reply.creator != null
                                 ? widget.userFurnace.userid == reply.creator!.id
                                 : false;

                            //Color replyMessageColor = Member.getReplyMemberColor(reply, widget.userCircleCache.user!, widget.userFurnace);

                            return WrapperWidget(child: Padding(
                                padding: EdgeInsets.only(top: 0),
                                child: Column(children: <Widget>[
                                  ///DateWidget replacement
                                  Container(
                                      padding: const EdgeInsets.only(
                                          top:
                                              0, //InsideConstants.DATEPADDINGTOP,
                                          bottom:
                                              0), //InsideConstants.DATEPADDINGBOTTOM),
                                      child: Center(
                                          child: Text(
                                              reply
                                                  .lastUpdatedDate!, //: reply.date!,
                                              textScaler: TextScaler.linear(
                                                  globalState
                                                      .messageHeaderScaleFactor),
                                              style: TextStyle(
                                                  fontSize: globalState
                                                      .userSetting.fontSize,
                                                  color: globalState
                                                      .theme.date)))),
                                  Column(
                                    children: [

                                      WallReplyWidget(
                                        key: GlobalKey(),
                                        reply: reply,
                                        replyResponses: theseReplies,
                                        userFurnace: widget.userFurnace,
                                        userCircleCache: widget.userCircleCache,
                                        isUser: isUser,
                                        tapHandler: _tapHandler,
                                        longPressHandler: _longPressHandler,
                                        messageColor: messageColor,
                                        replyMessageColor: messageColor,
                                        refresh: widget.refresh,
                                        maxWidth: widget.maxWidth,
                                        longReaction: _longReaction,
                                        shortReaction: _shortReaction,
                                        reactionAdded: _reactionAdded,
                                        showReactions: _showReactions,
                                      ),

                                      ListView.builder(
                                          shrinkWrap:true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: theseReplies.length,
                                          itemBuilder: (context, index) {
                                            ReplyObject response = theseReplies[index];

                                            Color messageColorResponse;
                                            if (response.creator != null &&
                                                response.creator!.id !=
                                                    widget.userFurnace.userid) {
                                              messageColorResponse = Member.getMemberColor(
                                                  widget.userFurnace, response.creator);
                                            } else {
                                              messageColorResponse = globalState.theme.userObjectText;
                                            }

                                            bool isUserResponse = response.creator != null
                                                ? widget.userFurnace.userid == response.creator!.id
                                                : false;

                                            return Padding(
                                              padding: const EdgeInsets.only(left: 50, top: 10, bottom: 10),
                                              child: WallReplyWidget(
                                                key: GlobalKey(),
                                                reply: response,
                                                replyResponses: theseReplies,
                                                userFurnace: widget.userFurnace,
                                                userCircleCache: widget.userCircleCache,
                                                isUser: isUserResponse,
                                                tapHandler: _tapHandler,
                                                longPressHandler: _longPressHandler,
                                                messageColor: messageColorResponse,
                                                replyMessageColor: messageColorResponse,
                                                refresh: widget.refresh,
                                                maxWidth: widget.maxWidth,
                                                longReaction: _longReaction,
                                                shortReaction: _shortReaction,
                                                reactionAdded: _reactionAdded,
                                                showReactions: _showReactions,
                                              )
                                            );

                                          }),
                                    ]
                                  )
                                ])));
                          })))),
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
                          AppLocalizations.of(context)!.newMessages,
                          color: globalState.theme.buttonIcon,
                        )
                      ])))
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
                      )))
              : Container()
    ]);

    final makeBottom = WrapperWidget(child:Padding(
        padding: const EdgeInsets.only(top: 5, bottom: 5, left: 5),
        child: Column(
            children: <Widget>[
              Row(
                  children: <Widget>[
                    _replyingToUser != null
                        ? Expanded(
                        child: Text(
                          "${_replyingToUser}: ${_replyingToBody!.length > 175 ? '${_replyingToBody?.substring(0,175)}...' : _replyingToBody}",
                          textScaler:
                          TextScaler.linear(globalState.messageScaleFactor),
                          style: TextStyle(
                              fontSize: 16,
                              color: _replyingToColor),
                        )
                    )
                        : Container(),
                  ]
              ),

              Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(
                        flex: 100,
                        child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(10)),
                              color: globalState
                                  .theme.slideUpPanelBackground,
                            ),
                            child: Column(children: <Widget>[
                              Row(children: [
                                _membersList
                                    ? SizedBox(
                                    height: 100,
                                    child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: <Widget>[
                                          Expanded(
                                              child:
                                              SingleChildScrollView(
                                                child: Container(
                                                    decoration: BoxDecoration(
                                                        borderRadius: const BorderRadius.only(
                                                            bottomLeft: Radius.circular(
                                                                10),
                                                            bottomRight: Radius.circular(
                                                                10),
                                                            topLeft: Radius.circular(
                                                                10),
                                                            topRight: Radius.circular(
                                                                10)),
                                                        color: globalState
                                                            .theme
                                                            .slideUpPanelBackground),
                                                    width: taggingWidth, //widget.maxWidth,//widget.maxWidth + 20,
                                                    height: 200,
                                                    padding: const EdgeInsets.only(
                                                        left: 0,
                                                        right: 0,
                                                        top: 0,
                                                        bottom: 0),
                                                    child: ListView
                                                        .builder(
                                                        scrollDirection: Axis
                                                            .vertical,
                                                        controller:
                                                        _scrollController,
                                                        shrinkWrap:
                                                        true,
                                                        itemCount:
                                                        membersFiltered
                                                            .length,
                                                        itemBuilder:
                                                            (BuildContext context, int index) {
                                                          Member
                                                          row =
                                                          membersFiltered[index];
                                                          User user = User(
                                                              id: row.memberID,
                                                              username: row.username);

                                                          return Container(
                                                              child: Padding(
                                                                  padding: const EdgeInsets.only(left: 10, top: 15, bottom: 10, right: 10),
                                                                  child: Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
                                                                    InkWell(
                                                                        onTap: () {
                                                                          setState(() {
                                                                            if (!taggedUsers.contains(row.username)) {
                                                                              taggedUsers.add(user);
                                                                            }

                                                                            /// add tag to text
                                                                            if (typingTag.contains("@")) {
                                                                              _message.text = "${_message.text}${row.username} ";
                                                                            } else if (typingTag.isEmpty) {
                                                                              _message.text = _message.text.replaceFirst("@", "@${row.username} ", whereTag);
                                                                            } else {
                                                                              _message.text = _message.text.replaceFirst(typingTag, "${row.username} ", whereTag + 1);
                                                                            }

                                                                            /// move cursor to end of added tag
                                                                            // _message.selection =
                                                                            //     TextSelection.collapsed(offset: whereTag + row.username.length + 2);

                                                                            /// close this menu
                                                                            _membersList = false;
                                                                          });
                                                                        },
                                                                        child: Row(children: [
                                                                          AvatarWidget(
                                                                              user: user,
                                                                              userFurnace: //widget.wall ? widget.userFurnaces!.firstWhere((element) => element.pk == row.furnaceKey) :
                                                                              widget.userFurnace,
                                                                              radius: 30,
                                                                              refresh: _refresh,
                                                                              showDM: true,
                                                                              isUser: user.id == widget.userFurnace.userid),
                                                                          const Padding(
                                                                            padding: EdgeInsets.only(right: 10),
                                                                          ),
                                                                          Text(
                                                                            row.username.length > 20 ? user.getUsernameAndAlias(globalState).substring(0, 19) : user.getUsernameAndAlias(globalState),
                                                                            textScaler: TextScaler.linear(globalState.labelScaleFactor),
                                                                            style: TextStyle(fontSize: 17, color: Member.returnColor(user.id!, globalState.members)),
                                                                          )
                                                                        ])),
                                                                  ])));
                                                        })),
                                              ))
                                        ]))
                                    : Container(),
                              ]),
                              textField,
                            ]))
                    ),
                    const Padding(padding: EdgeInsets.only(left: 5)),
                    Column(children: <Widget>[
                      _editingObject == null
                          ? SizedBox(
                          height: 40,
                          //width:80,
                          child: IconButton(
                            icon: Icon(
                              Icons.send_rounded,
                              size: 27,
                              color: _sendEnabled
                                  ? globalState
                                  .theme.bottomHighlightIcon
                                  : globalState
                                  .theme.buttonDisabled,
                            ),
                            onPressed: () {
                              _send();
                            },
                          ))
                          : SizedBox(
                          height: 40,
                          //width:80,
                          child: TextButton(
                            child: Text(
                              AppLocalizations.of(context)!.edit,
                              textScaler:
                              const TextScaler.linear(1.0),
                              style: TextStyle(
                                  fontSize: 18,
                                  color: _sendEnabled
                                      ? globalState.theme
                                      .bottomHighlightIcon
                                      : globalState
                                      .theme.buttonDisabled),
                            ),
                            onPressed: () {
                              _send();
                            },
                          )),
                      const Padding(
                          padding: EdgeInsets.only(
                            bottom: 5,
                          )),
                    ])
                  ])
            ])));

    AppBar topAppBar = AppBar(
      backgroundColor: globalState.theme.appBar,
      iconTheme: IconThemeData(
        color: globalState.theme.menuIcons,
      ),
      elevation: 0.1,
      title: Text(AppLocalizations.of(context)!.repliesTitle,
          style: ICTextStyle.getStyle(
              context: context,
              color: globalState.theme.textTitle,
              fontSize: ICTextStyle.appBarFontSize)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
    );

    Widget _mainWidget = SafeArea(
        left: false,
        top: false,
        right: false,
        bottom: true,
        child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: globalState.theme.background,
            appBar: topAppBar,
            body: Stack(children: [
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                        child: Stack(children: [
                      makeReplies,
                      _showSpinner ? Center(child: spinkit) : Container(),
                    ])),

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
                          backgroundColor: globalState.theme.userObjectBackground,
                        ),
                        emojiTextStyle: const TextStyle(),
                        skinToneConfig: const SkinToneConfig(),
                        categoryViewConfig: CategoryViewConfig(
                          iconColor: globalState.theme.labelText,
                          dividerColor: globalState.theme.labelText,
                          backgroundColor: globalState.theme.userObjectBackground,
                          indicatorColor: globalState.theme.userObjectText,
                          iconColorSelected: globalState.theme.userObjectText,
                        ),
                        bottomActionBarConfig: BottomActionBarConfig(
                          buttonColor: globalState.theme.userObjectBackground,
                          backgroundColor: globalState.theme.userObjectBackground,
                          buttonIconColor: globalState.theme.labelText,
                        ),
                        searchViewConfig: SearchViewConfig(
                          buttonIconColor: globalState.theme.labelText,
                          backgroundColor: globalState.theme.userObjectBackground,
                        )
                      )
                    )
                    : Container(
                      height: 0.0,
                    ),

                    _showTextField ? makeBottom : Container(),
                  ])
            ])));

    return PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) {
          if (didPop) {
            return;
          }
          _backPressed(true);
        },
        child: Platform.isIOS
            ? GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.velocity.pixelsPerSecond.dx > 200) {
                    _backPressed(true);
                  }
                },
                child: _mainWidget)
            : _mainWidget);
  }

  _backPressed(bool samePosition) {
    // if (widget.wall) return;
    //
    // if (_showEmojiPicker) {
    //   setState(() {
    //     _showEmojiPicker = !_showEmojiPicker;
    //   });
    // } else {
    _goHome(samePosition);
    //}
  }

  _goHome(bool samePosition, {forceScratchLoad = false}) {
    // if (_panelOpen) {
    //   _panelOpen = false;
    //   _refreshEnabled = true;
    //   Navigator.pop(context);
    //   return;
    // }
    if (_popping) return;

    _popping = true;

    // if (_message.text.isNotEmpty ||
    //     (_mediaCollection != null && _mediaCollection!.media.isNotEmpty) ||
    //     _giphyOption != null) {
    //   _circleObjectBloc.saveDraft(widget.userFurnace, widget.userCircleCache,
    //       _message.text, _mediaCollection, _giphyOption);
    // }

    try {
      //_firebaseBloc.removeNotification();
      _closeKeyboard();

      //globalState.selectedHomeIndex = 0;

      // if (!samePosition) {
      //   globalState.lastSelectedIndexDMs = null;
      //   globalState.lastSelectedIndexCircles = null;
      //   globalState.sortAlpha = null;
      //   globalState.lastSelectedFilter = null;
      // }

      //_turnoffBadgeAndSetLastAccess();

      if (mounted && ModalRoute.of(context)!.isFirst || forceScratchLoad) {
        debugPrint('***********POPPED****************');
        //came from push notification press or share to
        // Navigator.pushReplacementNamed(
        //   context,
        //   '/home',
        //   // arguments: user,
        // );
      } else {
        // if (widget.dismissByCircle != null) {
        //   debugPrint(
        //       'InsideCircle:goHome dismissByCircle started ${DateTime.now()}');
        //   widget.dismissByCircle!(widget.userCircleCache, widget.userFurnace);
        //
        //   debugPrint(
        //       'InsideCircle:goHome dismissByCircle passed ${DateTime.now()}');
        // }

        debugPrint('***********POPPED****************');

        debugPrint('WallRepliesScreen:goHome pop ${DateTime.now()}');
        Navigator.pop(context);

        if (widget.refresh != null) widget.refresh!();
      }

      debugPrint('WallRepliesScreen:goHome stopped ${DateTime.now()}');
    } catch (err, trace) {
      _popping = false;
      LogBloc.insertError(err, trace);
      debugPrint('WallRepliesScreen._goHome: $err');
    }
  }

  // _replyTo() {
  //
  // }

  _replyToReply() {}

  _reply() {}

  _closeKeyboard() {
    if (mounted) {
      FocusScope.of(context).requestFocus(FocusNode());
    }
  }

  setSendEnabled(bool enabled) {
    setState(() {
      _sendEnabled = enabled;
    });
  }

  _clear(bool closeKeyboard) {
    setState(() {
      _message.text = '';
      _message.clear();
      _sendEnabled = false;
      _editingObject = null;
      _editing = false;
      _replyingTo = null;
      _replyingToUser = null;
      _replyingToColor = globalState.theme.userObjectText;
      _replyingToBody = "";
      _membersList = false;
      taggedUsers = [];
      //   if (_lastSelected != null) _lastSelected!.showOptionIcons = false;
      //   _replyObject = null;
      //   _clearPreviews();
    });

    if (closeKeyboard) _closeKeyboard();
  }

  _send() async {
    debugPrint("...........START_send: ${DateTime.now()}");

    if (_sendEnabled == false //&& overrideButton == false
        ) {
      debugPrint("...........returning: ${DateTime.now()}");
      return;
    }
    _sendEnabled = false;

    ReplyObject? replyObject;

    if (_editingObject != null) {
      replyObject = _editingObject;

      await _editAndClear(replyObject!);
    } else {
      replyObject = _prepNewReplyObject(
          widget.userFurnace, //widget.wallFurnaces[0],
          widget.userCircleCache,
          _replyObjects.length); //length - 1

      replyObject.emojiOnly = await EmojiUtil.checkForOnlyEmojis(_message.text);

      if (_message.text.trim().isNotEmpty) {
        _replyObjects.add(replyObject);

        _sendAndClear(replyObject);
      }
    }
  }

  _editAndClear(ReplyObject replyObject) async {
    bool ready = false;
    String body = _message.text;

    replyObject.emojiOnly = await EmojiUtil.checkForOnlyEmojis(_message.text);

    if (_message.text.isNotEmpty) {
      if (body.isNotEmpty) {
        replyObject.body = _message.text;
        ready = true;
      }
    }

    if (ready) {
      widget.replyObjectBloc.updateReplyObject(
        replyObject,
        widget.userFurnace,
        widget.userCircleCache,
      );

      setState(() {
        _clear(false);
      });
    }
  }

  ReplyObject _prepNewReplyObject(
    UserFurnace userFurnace,
    UserCircleCache userCircleCache,
    int index,
  ) {
    String messageText = _message.text;

    ReplyObject newReplyObject = ReplyObject(
      creator: User(
        username: userFurnace.username,
        id: userFurnace.userid,
        accountType: userFurnace.accountType,
      ),
      body: messageText,
      circle: userCircleCache.cachedCircle,
      created: DateTime.now(),
      sortIndex: index,
      ratchetIndexes: [],
      circleObject: widget.circleObject,
      circleObjectID: widget.circleObject.id,
      type: CircleObjectType.CIRCLEMESSAGE,
      replyToID: _replyingTo,
    );

    newReplyObject.taggedUsers = taggedUsers;

    newReplyObject.initDates();

    return newReplyObject;
  }

  _sendAndClear(ReplyObject replyObject, {bool lastObject = true}) async {
    debugPrint("...........SEND AND CLEAR: ${DateTime.now()}");

    setState(() {
      try {
        if (_waitingOnScroller.isNotEmpty) {
          _addObjects(_waitingOnScroller, true);
          _waitingOnScroller.clear();
        } else if (_itemScrollController.isAttached &&
            _replyObjects.isNotEmpty) {
          _itemScrollController.scrollTo(
              index: 0,
              duration: const Duration(milliseconds: 10),
              curve: Curves.easeInOutCubic);
        }
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
      }
    });

    widget.replyObjectBloc.saveReplyObject(
      widget.globalEventBloc,
      widget.userFurnace,
      widget.userCircleCache,
      replyObject,
    );

    debugPrint("...........SAVEOBJECT: ${DateTime.now()}");

    if (lastObject) {
      setState(() {
        _clear(false);
      });
    }
  }

  Future _refresh() async {
    if (_showSpinner) return;

    widget.replyObjectBloc
        .resendFailedReplyObjects(widget.globalEventBloc, widget.userFurnace);

    _refreshReplyObjects();

    if (_itemScrollController.isAttached)
      _itemScrollController.scrollTo(
          index: 0,
          duration: const Duration(milliseconds: _scrollDuration),
          curve: Curves.easeInOutCubic);
  }

  bool onNotification(ScrollEndNotification t) {
    try {
      if (t.metrics.pixels > 0 && t.metrics.atEdge) {
        _fetchOlderThan();

        if (_replyObjects.length > 40) {
          FormattedSnackBar.showSnackbarWithContext(
              context, AppLocalizations.of(context)!.checkingForAdditionalPosts, "", 2, false);
        }
        return true;
      } else {
        if (_replyObjects.length < 10 && _thereAreNoOlderPosts == false) {
          _fetchOlderThan();
          return true;
        }
      }

      if (_itemPositionsListener.itemPositions.value.isNotEmpty &&
          _itemPositionsListener.itemPositions.value.first.index == 0) {
        _addObjects(_waitingOnScroller, true);
        _waitingOnScroller.clear();
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('WallRepliesScreen.onNotification: $err');
    }
    return false;
  }

  _addObjects(List<ReplyObject> objects, bool scrollToBottom) {
    ///requester said jump to bottom
    if (scrollToBottom) {
      if (objects.isNotEmpty) {
        _addAndScroll(objects);
      }
    }

    ///figure out whether to scroll or not
    else if (objects.isNotEmpty) {
      ///only add ones that aren't already there
      List<ReplyObject> alreadyThere = [];
      List<ReplyObject> notAlreadyThere = [];

      for (ReplyObject object in objects) {
        if (_replyObjects.indexWhere((element) => element.seed == object.seed) >
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
            ReplyObjectCollection.addObjects(
                _replyObjects,
                alreadyThere,
                widget.circleObject.id!,
                //_currentCircle!,
                widget.userFurnace);
          });
        reloadObjects();
        _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
        //widget.wallReplyBloc.sinkVaultRefresh();
        //_globalEventBloc.broadcastRefreshWall();
      }

      bool scroll = false;
      int position = -1;
      int difference = _replyObjects.length - objects.length;
      if (_replyObjects.isNotEmpty && difference != 0) {
        position = _itemPositionsListener.itemPositions.value.first.index;
        debugPrint('current position is $position');
        if (position == 0 && _replyObjects.isNotEmpty) scroll = true;
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
                ReplyObjectCollection.addObjects(
                    _replyObjects,
                    notAlreadyThere,
                    widget.circleObject.id!,
                    widget.userFurnace);
              });
              reloadObjects();
              _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
              // widget.wallReplyBloc.sinkVaultRefresh(); //_globalEventBloc.broadcastRefreshWall();
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
          //_turnoffBadgeAndSetLastAccess();
        }
      }
    }
  }

  void _refreshReplyObjects() {
    try {
      debugPrint('hit _refreshReplyObjects');

      widget.replyObjectBloc.requestNew(widget.circleObject.id!,
          widget.circleObject.circle!.id!, widget.userFurnace, false);
    } catch (e, trace) {
      LogBloc.insertError(e, trace);
    }
  }

  _addAndScroll(List<ReplyObject> objects) {
    debugPrint('addAndScroll called at ${DateTime.now()}');
    if (mounted) {
      setState(() {
        ReplyObjectCollection.addObjects(
          _replyObjects,
          objects,
          widget.circleObject.id!,
          widget.userFurnace);
      });
      //widget.wallReplyBloc.sinkVaultRefresh();

      if (_itemScrollController.isAttached && _replyObjects.isNotEmpty) {
        _itemScrollController.scrollTo(
            index: 0,
            duration: const Duration(milliseconds: _scrollDuration),
            curve: Curves.easeInOutCubic);
      }
    }
    reloadObjects();
    _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  }

  _fetchOlderThan() {
    ReplyObject oldest = _replyObjects[_replyObjects.length - 1];

    widget.replyObjectBloc.requestOlderThan(widget.circleObject,
        widget.userCircleCache.circle!, widget.userFurnace, oldest.created!);
  }

  _addNewAndScrollToBottom() {
    if (_waitingOnScroller.isNotEmpty) {
      _addObjects(_waitingOnScroller, true);
      setState(() {
        _waitingOnScroller.clear();
      });
    } else if (_itemScrollController.isAttached && _replyObjects.isNotEmpty) {
      _itemScrollController.scrollTo(
          index: 0,
          duration: const Duration(milliseconds: _scrollDuration),
          curve: Curves.easeInOutCubic);
    }
  }

  _upsertReplyObject(ReplyObject replyObject) {
    try {
      int position = -1;
      if (_replyObjects.isNotEmpty &&
          _itemPositionsListener.itemPositions.value.isNotEmpty) {
        position = _itemPositionsListener.itemPositions.value.first.index;
        debugPrint("WallRepliesScreen._upsertReplyObject: position: $position");
      }

      ReplyObjectCollection.upsertObject(_replyObjects, replyObject,
          widget.circleObject.id!, widget.userCircleCache);

      if (mounted) {
        setState(() {
          _clearSpinner();
        });
      }

      if (_replyObjects.isNotEmpty &&
          _itemPositionsListener.itemPositions.value.isNotEmpty) {
        position = _itemPositionsListener.itemPositions.value.first.index;
        debugPrint("WallRepliesScreen._upsertReplyObject: position: $position");
      }
      reloadObjects();
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("WallRepliesScreen._upsertReplyObject: $err");
      if (mounted) {
        setState(() {
          _clearSpinner();
        });
      }
    }
  }

  void _editObject(ReplyObject replyObject) async {
    String? body;
    setState(() {
      _showTextField = true;
    });

    body = replyObject.body;

    setState(() {
      _editingObject = replyObject;
      if (body != null) _message.text = body;
      _sendEnabled = true;
      _editing = true;
      _focusNode.requestFocus();
    });
  }

  void _deleteObject(ReplyObject replyObject) async {
    FocusScope.of(context).unfocus();
    await DialogYesNo.askYesNo(
      context,
      AppLocalizations.of(context)!.confirmDeleteTitle,
      AppLocalizations.of(context)!.confirmDeleteMessage,
      _deleteObjectConfirmed,
      null,
      false,
      replyObject);
  }

  void _deleteObjectConfirmed(ReplyObject replyObject) async {
    //_globalEventBloc.broadcastDelete(replyObject);

    widget.replyObjectBloc.deleteReplyObject(
      widget.userCircleCache, widget.userFurnace, replyObject
    );
  }

  _hideObject(ReplyObject replyObject) async {
    FocusScope.of(context).unfocus();
    await DialogYesNo.askYesNo(
      context,
      AppLocalizations.of(context)!.deleteForYouTitle,
      AppLocalizations.of(context)!.deleteForYouQuestion,
      _hideObjectConfirmed,
      null,
      false,
      replyObject
    );
  }

  _hideObjectConfirmed(ReplyObject replyObject) {
    setState(() {
      _replyObjects.remove(replyObject);
    });

    widget.replyObjectBloc.hideReplyObject(
      widget.userCircleCache, widget.userFurnace, replyObject);
  }

  void _reportPost(ReplyObject replyObject) async {

    Violation? violation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportPost(
         type: ReportType.POST,
         member: null,
         circleObject: null,
         replyObject: replyObject,
         userCircleCache: widget.userCircleCache,
         userFurnace: widget.userFurnace,
         network: null,
         circleObjectBloc: null,
        )
      )
    );

    if (violation != null) {
      widget.replyObjectBloc.reportViolation(widget.userFurnace, replyObject, violation, widget.userCircleCache);

      FormattedSnackBar.showSnackbarWithContext(
        context, AppLocalizations.of(context)!.potentialViolationReported, "", 3, false);
    }
  }

  _reactionAdded(ReplyObject pReplyObject, index) {
    if (index == -1) {
      return;
    }

    ///add reaction logic later
    if (index == -2) {
      _openEmojiPicker(pReplyObject);
      return;
    }

    //find the latest
    ReplyObject replyObject = _replyObjects.firstWhere((element) => element.seed == pReplyObject.seed);
    CircleObjectReaction? found;
    bool remove = false;

    replyObject.reactions ??= [];

    // UserFurnace userFurnace = _getUserFurnace(replyObject);
    // UserCircleCache userCircleCache

    for (CircleObjectReaction reaction in replyObject.reactions!) {
      if (reaction.index == index) {
        found = reaction;
        for (User user in reaction.users) {
          if (user.id == widget.userFurnace.userid) {
            remove = true;
          }
        }
      }
    }

    if (remove) {
      found!.users.removeWhere((element) => element.id == widget.userFurnace.userid);

      if (found.users.isEmpty)
        replyObject.reactions!.removeWhere((element) => element.index == found!.index);

    widget.replyObjectBloc.deleteReaction(
      widget.userFurnace, widget.userCircleCache, replyObject, found, _replyObjects[0]);
    } else if (found != null) {
      found.users.add(User(
        username: widget.userFurnace.username,
        id: widget.userFurnace.userid,
      ));

      widget.replyObjectBloc.postReaction(
        widget.userFurnace,
        widget.userCircleCache,
        replyObject,
        found
      );
    } else {
      CircleObjectReaction reaction = CircleObjectReaction(
        index: index,
        emoji: null,
        users: [
          User(
            username: widget.userFurnace.username,
            id: widget.userFurnace.userid,
          )
        ],
      );

      replyObject.reactions!.add(reaction);

      widget.replyObjectBloc.postReaction(
        widget.userFurnace, widget.userCircleCache,
        replyObject, reaction);
    }

    setState(() {
      replyObject.showOptionIcons = false;
    });
  }

  _openEmojiPicker(ReplyObject pReplyObject) {
    setState(() {
      _postedEmoji = false;
      _emojiController.text = "";
      _reactingTo = pReplyObject;
      _emojiShowing = true;
    });
  }

  void _longReaction(ReplyObject replyObject, index) {
    DialogReactions.showReplyReactions(context, 'Reactions', replyObject);
  }

  void _shortReaction(ReplyObject replyObject, index, String? emoji) {
    if (emoji!.isNotEmpty) {
      _emojiReaction(emoji, replyObject);
    } else {
      _reactionAdded(replyObject, index);
    }
  }

  ///emoji picker emoji chosen
  _emojiReaction(String emoji, ReplyObject? pressedReplyObject) {
    //find the latest
    ReplyObject replyObject;
    if (pressedReplyObject == null) {
      replyObject = _replyObjects.firstWhere((element) => element.seed == _reactingTo!.seed);
    } else {
      replyObject = pressedReplyObject;
    }
    CircleObjectReaction? found;
    bool remove = false;
    replyObject.reactions ??= [];

    for (CircleObjectReaction reaction in replyObject.reactions!) {
      if (reaction.emoji == emoji) {
        found = reaction;
        for (User user in reaction.users) {
          if (user.id == widget.userFurnace.userid) {
            remove = true;
            break;
          }
        }
      }
    }
    if (remove) {
      found!.users.removeWhere((element) => element.id == widget.userFurnace.userid);
      if (found.users.isEmpty) {
        replyObject.reactions!.removeWhere((element) => element.emoji == found!.emoji);
      }
      widget.replyObjectBloc.deleteReaction(
        widget.userFurnace, widget.userCircleCache, replyObject, found, _replyObjects[0]);
    } else if (found != null) {
      found.users.add(User(username: widget.userFurnace.username, id: widget.userFurnace.userid));
      widget.replyObjectBloc.postReaction(
        widget.userFurnace, widget.userCircleCache, replyObject, found);
      _postedEmoji = true;
    } else {
      CircleObjectReaction reaction = CircleObjectReaction(
        index: null,
        emoji: emoji,
        users: [
          User(
            username: widget.userFurnace.username,
            id: widget.userFurnace.userid,
          )
        ]
      );
      replyObject.reactions!.add(reaction);
      widget.replyObjectBloc.postReaction(
        widget.userFurnace, widget.userCircleCache, replyObject, reaction);
      _postedEmoji = true;
    }
    setState(() {
      replyObject.showOptionIcons = false;
      if (_postedEmoji == true) {
        _emojiShowing = false;
      }
    });
  }

  void _showReactions(ReplyObject replyObject) {
    bool isUser = false;

    //UserFurnace userFurnace = _getUserFurnace(circleObject);
    //UserCircleCache userCircleCache = _getUserCircleCache(circleObject);

    if (replyObject.creator!.id == widget.userFurnace.userid) isUser = true;

    _longPressHandler(replyObject, isUser);
  }

  void _longPressHandler(ReplyObject replyObject, bool isUser) async {

    double keyboard = (MediaQuery.of(context).viewInsets.bottom);
    _closeKeyboard();

    setState(() {
      replyObject.showOptionIcons = true;
    });

    int result = await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, __, ___) => LongPressMenu(
          circle: widget.circleObject.userCircleCache!.cachedCircle!,
          circleObject: null,
          keyboardSize: keyboard,
          wall: true, ///prevents pinning && settingbackground
          selected: _reactionAdded,
          replyObject: replyObject,
          globalKey: replyObject.globalKey,
          showDate: true,
          isUser: isUser,
          edit: _editObject,
          copy: null,
          share: null,
          enableReacting: true,
          enablePosting: true,
        ),
      ),
    );

    setState(() {
      replyObject.showOptionIcons = false;
    });

    if (result == LongPressFunction.DELETE) {
      _deleteObject(replyObject); ///when user is owner of reply
    } else if (result == LongPressFunction.EDIT) {
      _editObject(replyObject);
    } else if (result == LongPressFunction.COPY) {
      _doNothing(replyObject);
    } else if (result == LongPressFunction.SHARE) {
      _doNothing(replyObject);
    } else if (result == LongPressFunction.CANCEL) {
      _doNothing(replyObject);
    } else if (result == LongPressFunction.DELETE_CACHE) {
      _doNothing(replyObject);
    } else if (result == LongPressFunction.REPORT_POST) {
      _reportPost(replyObject);
    } else if (result == LongPressFunction.OPEN_EXTERNAL_BROWSER) {
      _doNothing(replyObject);
    } else if (result == LongPressFunction.SET_BACKGROUND) {
      _doNothing(replyObject);
    } else if (result == LongPressFunction.EXPORT) {
      _doNothing(replyObject);
    } else if (result == LongPressFunction.DOWNLOAD) {
      _doNothing(replyObject);
    } else if (result == LongPressFunction.REPLY) {
      setState(() {
        replyObject.replyToID == null
        ? _replyingTo = replyObject.id
        : _replyingTo = replyObject.replyToID;

        _replyingToUser = replyObject.creator!.getUsernameAndAlias(globalState);
        replyObject.creator!.id == widget.userCircleCache.user!
          ? _replyingToColor = globalState.theme.userObjectText
          : _replyingToColor = Member.getMemberColor(
            widget.userFurnace, replyObject.creator);

        if (replyObject.body == null) {
          _replyingToBody = "";
        } else if (replyObject.body!.isNotEmpty) {
          _replyingToBody = replyObject.body;
        }

        // if (replyObject.type == CircleObjectType.CIRCLEMESSAGE) {
        //
        // }

        _focusNode.requestFocus();
      });
    } else if (result == LongPressFunction.HIDE) {
      ///when user is not owner of reply
      _hideObject(replyObject);
    } else if (result == LongPressFunction.PIN) {
      ///do
    }
    return;
  }

  _doNothing(ReplyObject replyObject) {

  }

  void _tapHandler(ReplyObject replyObject) async {
    ///do
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

  _panelCollapsed() {
    //_refreshEnabled = true;

    setState(() {
      _showTextField = true;
      if (_message.text.isNotEmpty) {
        _sendEnabled = true;
      }
    });
  }

}
