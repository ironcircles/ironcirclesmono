import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/voice_input_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/dialogdisappearing.dart';
import 'package:ironcirclesapp/screens/themes/mastertheme.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/voice_button_widget.dart';
import 'package:ironcirclesapp/screens/widgets/voice_memo_sheet.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/screens/insidecircle/dialogvoiceoptions.dart';

enum ParentType { circle, vault, feed }

//version of thumbnail widget but for library links instead of library gallery
class InsideCirclePostWidget extends StatefulWidget {
  final TextEditingController message;
  final Function clear;
  final FocusNode focusNode;
  final CircleObject? replyObject;
  final ParentType parentType;
  final bool editing;
  final CircleObject? editingObject;
  final String clickedMember;
  final List<Member> members;
  final List<User> taggedUsers;
  final String typingTag;
  final Function setTypingTag;
  final Function setSendEnabled;
  final bool sendEnabled;
  final bool membersList;
  final Function setMembersList;
  final int whereTag;
  final Function setWhereTag;
  final Function setTimer;
  final Function setScheduled;
  final Function showSlidingPanel;
  final bool wall;
  final int timer;
  final Key timerKey;
  final Function passMediaCollection;
  final Function passMembersFiltered;
  final Function send;

  const InsideCirclePostWidget(
      {required this.message,
      required this.clear,
      required this.focusNode,
      required this.replyObject,
      required this.parentType,
      required this.sendEnabled,
      required this.timerKey,
      required this.editing,
      required this.timer,
      required this.editingObject,
      required this.taggedUsers,
      required this.setSendEnabled,
      required this.members,
      required this.membersList,
      required this.setMembersList,
      required this.typingTag,
      required this.setTypingTag,
      required this.wall,
      required this.whereTag,
      required this.setTimer,
      required this.setScheduled,
      required this.showSlidingPanel,
      required this.setWhereTag,
      required this.clickedMember,
      required this.passMembersFiltered,
      required this.passMediaCollection,
      required this.send});

  @override
  _InsideCircleTextFieldState createState() => _InsideCircleTextFieldState();
}

class _InsideCircleTextFieldState extends State<InsideCirclePostWidget> {
  /// get current cursor position
  int currentIndex = 0;

  DateTime? _scheduledDate;

  /// get text from start to cursor
  String textChunk = "";
  String tagChunk = "";

  // Voice button state
  VoiceButtonState _voiceButtonState = VoiceButtonState.idle;
  double _voiceSoundLevel = 0.0;
  VoiceInputBloc? _voiceInputBloc;
  StreamSubscription<VoiceInputState>? _voiceSub;

  final spinner = SpinKitThreeBounce(
    size: 20,
    color: globalState.theme.threeBounce,
  );

  @override
  void initState() {
    super.initState();
    _voiceInputBloc = VoiceInputBloc();
    _voiceSub = _voiceInputBloc!.stream.listen(_handleVoiceInputState);
  }

  @override
  void dispose() {
    _voiceSub?.cancel();
    _voiceInputBloc?.dispose();
    super.dispose();
  }

  IconButton buildButtonColumn(
      IconData icon, Color? color, Function onClick, Key key,
      {double iconSize = 37}) {
    // Color color = Theme.of(context).primaryColor;

    return IconButton(
      key: key,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      iconSize: iconSize - globalState.scaleDownIcons,
      icon: Icon(
        icon,
        size: iconSize - globalState.scaleDownIcons,
      ),
      onPressed: onClick as void Function()?,

      color: color,
      //size: iconSize,
    );
  }

  //Need container to hold link, which can change appearance when selected
  @override
  Widget build(BuildContext context) {
    return widget.wall
        ? Stack(
            alignment: Alignment.center,
            children: [
              Align(
                  alignment: Alignment.center,
                  child: IconButton(
                    icon: Icon(Icons.add,
                        color: globalState.theme.buttonDisabled),
                    iconSize: 24,
                    onPressed: () {
                      widget.showSlidingPanel();
                    },
                  )),
            ],

            //}),
          )
        : Stack(
            alignment: Alignment.center,
            children: [
              ConstrainedBox(
                  constraints:  BoxConstraints(
                      maxHeight:
                          globalState.isDesktop() ? 250 : 125 //put here the max height to which you need to resize the textbox
                      ),
                  child: MediaQuery(
                      data: const MediaQueryData(
                        textScaler: TextScaler.linear(1),
                      ),
                      child: TextField(
                          cursorColor: globalState.theme.textField,
                          contentInsertionConfiguration:
                              ContentInsertionConfiguration(onContentInserted:
                                  (KeyboardInsertedContent data) {
                            if (data.mimeType == "image/png") {
                              _getKeyboardMedia(data);
                            } else if (data.mimeType == "image/gif") {
                              _getKeyboardMedia(data);
                            }
                          }),
                          onSubmitted: (text) {
                            if (globalState.isDesktop()){
                              widget.send();
                            }
                          },
                          textInputAction: globalState.isDesktop() ? TextInputAction.done : TextInputAction.newline,
                          controller: widget.message,
                          focusNode: widget.focusNode,
                          autofocus: globalState.isDesktop() ? true: false,
                          maxLines: null,
                          maxLength: TextLength.Largest,
                          //lines < maxLines ? null : maxLines,
                          textCapitalization: TextCapitalization.sentences,
                          style: TextStyle(
                            color: globalState.theme.userObjectText,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: globalState.theme.slideUpPanelBackground,
                            hintText: widget.replyObject != null
                                ? AppLocalizations.of(context)!
                                    .replyToIronCladMessage
                                : widget.parentType == ParentType.vault
                                    ? AppLocalizations.of(context)!.stashInVault
                                    : widget.parentType == ParentType.feed
                                        ? AppLocalizations.of(context)!
                                            .postToEntireNetwork
                                        : AppLocalizations.of(context)!
                                            .sendIronCladMessage,
                            hintStyle: TextStyle(
                                color: globalState.theme.messageTextHint,
                                fontSize: 16),
                            contentPadding: EdgeInsets.only(
                                left: 50,
                                bottom: 10,
                                top: 10,
                                right: widget.sendEnabled ? 50 : 0),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: globalState.theme.messageBackground),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: globalState.theme.messageBackground),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),

                          onChanged: (text) {
                            bool localSendEnable = true;

                            String text = widget.message.text;

                            debugPrint("HERE IS THE TEXT FIELD: $text AND HERE IS THE TEXT: $text");

                            if (text.isEmpty) {
                              widget.taggedUsers.clear();
                              widget.setMembersList(false);
                              if (widget.editing) {
                                if (widget.editingObject != null) {
                                  if (widget.editingObject!.type ==
                                      CircleObjectType.CIRCLEMESSAGE) {
                                    localSendEnable = false;
                                  }
                                }
                              } else
                                localSendEnable = false;
                            } else {
                              localSendEnable = true;

                              if (text.contains("@")) {
                                for (Member m in widget.members) {
                                  User user = User(
                                      id: m.memberID, username: m.username);
                                  bool taggedAlready = widget.taggedUsers
                                      .where((element) =>
                                          element.username == m.username)
                                      .isNotEmpty;
                                  if (text.contains(m.username) &&
                                      taggedAlready == false) {
                                    widget.taggedUsers.add(user);
                                  }
                                }

                                /// set username list to all members
                                List<Member> membersFiltered = widget.members;

                                /// filter out members already tagged, KEEP IN MIND THE CHANGE HERE
                                membersFiltered = membersFiltered
                                    .where((element) =>
                                        !text.contains("${element.username} "))
                                    .toList();

                                /// filter out user
                                membersFiltered = membersFiltered
                                    .where((element) =>
                                        element.memberID != element.userID)
                                    .toList();

                                if (membersFiltered.isNotEmpty) {
                                  /// get current cursor position
                                  currentIndex =
                                      widget.message.selection.base.offset;

                                  /// get text from start to cursor
                                  textChunk = text.substring(0, currentIndex);

                                  /// trim to text from @ to cursor
                                  tagChunk;
                                  widget
                                      .setWhereTag(textChunk.lastIndexOf("@"));
                                  if ((widget.whereTag + 1) <= currentIndex) {
                                    tagChunk = textChunk.substring(
                                        widget.whereTag + 1, currentIndex);
                                    widget.setTypingTag(tagChunk);
                                  }

                                  ///get letter to the left
                                  String leftLetter = text.substring(
                                      currentIndex - 1, currentIndex);

                                  if (leftLetter == "@") {
                                    ///if that letter is @ symbol, show username menu
                                    widget.setMembersList(true);
                                    widget.passMembersFiltered(membersFiltered);
                                  } else if (leftLetter == " ") {
                                    ///if user is done tagging member
                                    widget.setMembersList(false);
                                  } else if (widget.membersList == true ||
                                      !widget.typingTag.contains(" ")) {
                                    /// if user types letter of tag
                                    /// filter by typed tag so far
                                    membersFiltered = membersFiltered
                                        .where((element) =>
                                            element.username
                                                .toLowerCase()
                                                .contains(
                                                    tagChunk.toLowerCase()) ||
                                            element.alias
                                                .toLowerCase()
                                                .contains(
                                                    tagChunk.toLowerCase()))
                                        //.startsWith(widget.typingTag.toLowerCase()))
                                        .toList();
                                    widget.passMembersFiltered(membersFiltered);
                                    widget.setMembersList(true);
                                  }
                                }
                              } else {
                                ///added this line to improve performance when typing fast
                                if (widget.membersList == true) {
                                  widget.taggedUsers.clear();
                                  widget.setMembersList(false);
                                }
                              }
                            }

                            if (localSendEnable != widget.sendEnabled) {
                              widget.setSendEnabled(localSendEnable);
                            }
                          }))),
              Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.add,
                        color: globalState.theme.buttonDisabled),
                    iconSize: 24,
                    onPressed: () {
                      widget.showSlidingPanel();
                    },
                  )),

              widget.wall == false
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                          // Timer/disappearing messages icon
                          widget.timer == UserDisappearingTimer.OFF &&
                                  _scheduledDate == null
                              ? IconButton(
                                  icon: Icon(Icons.timer,
                                      color: globalState.theme.buttonDisabled),
                                  iconSize: 24,
                                  onPressed: () {
                                    _showTimer();
                                  },
                                )
                              : Padding(
                                  padding: const EdgeInsets.only(top: 5, right: 0),
                                  child: _scheduledDate != null
                                      ? buildButtonColumn(
                                          Icons.timer,
                                          globalState.theme.bottomHighlightIcon,
                                          _showTimer,
                                          widget.timerKey,
                                          iconSize: 24)
                                      : InkWell(
                                          onTap: _showTimer,
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.timer,
                                                  color: globalState
                                                      .theme.bottomHighlightIcon,
                                                  size: 24 -
                                                      globalState.scaleDownIcons,
                                                ),
                                                Text(
                                                  _getShortTimerString(),
                                                  textScaler:
                                                      const TextScaler.linear(1.0),
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: globalState.theme
                                                          .bottomHighlightIcon),
                                                )
                                              ]))),
                          // Voice button (voice memo / voice-to-text)
                          Transform.translate(
                            offset: const Offset(-8, 0),
                            child: VoiceButtonWidget(
                              onOptionSelected: _handleVoiceOption,
                              buttonState: _voiceButtonState,
                              onStopVoiceMemo: null,
                              onStopVoiceToText: _stopVoiceToText,
                              soundLevel: _voiceSoundLevel,
                            ),
                          ),
                        ],
                      )))
                  : Container(),

              // widget.sendEnabled && widget.editing
              //     ? IconButton(
              //         icon: Icon(Icons.cancel_rounded,
              //             color: globalState.theme.buttonDisabled),
              //         iconSize: 22,
              //         onPressed: () {
              //           DialogYesNo.askYesNo(
              //               context,
              //               'Cancel post?',
              //               'Are you sure you want to cancel this post?',
              //               _confirmCancel,
              //               null,
              //               false);
              //         },
              //       )
              //     : Container(),
            ],

            //}),
          );
  }

  _getKeyboardMedia(KeyboardInsertedContent data) async {
    String tempDir = await FileSystemService.returnTempPath();
    int index = data.uri.lastIndexOf('/');
    String name = data.uri.substring(index);
    File file = await File('$tempDir/$name').create();
    file.writeAsBytesSync(data.data!.toList());
    Media media = Media(mediaType: MediaType.image, path: file.path);
    widget.setSendEnabled(true);
    setState(() {
      widget.passMediaCollection(media);
    });
  }

  _showTimer() {
    _closeKeyboard();
    DialogDisappearing.setTimer(context, widget.setTimer, _getDateTimeSchedule);
  }

  void _handleVoiceOption(VoiceOption option) async {
    final bloc = _voiceInputBloc;
    if (bloc == null) return;

    if (option == VoiceOption.voiceMemo) {
      await _showVoiceMemoSheet(bloc);
    } else {
      try {
        final started = await bloc.startVoiceToText();
        if (started) {
          setState(() {
            _voiceButtonState = VoiceButtonState.voiceToText;
          });
        }
      } catch (err) {
        debugPrint('Failed to start voice to text: $err');
      }
    }
  }

  Future<void> _showVoiceMemoSheet(VoiceInputBloc bloc) async {
    _closeKeyboard();
    final encrypted = await VoiceMemoSheet.show(context: context, bloc: bloc);
    if (encrypted != null) {
      final mediaExtension = Platform.isIOS ? 'm4a' : 'wav';
      final media = Media(
        path: encrypted.encryptedFile.path,
        mediaType: MediaType.file,
        name: 'voice_memo_${DateTime.now().millisecondsSinceEpoch}.$mediaExtension',
        attachment: encrypted,
      );
      widget.passMediaCollection(media);
      widget.setSendEnabled(true);
    }
  }

  void _handleVoiceInputState(VoiceInputState state) {
    VoiceButtonState? newButtonState;
    double? newSoundLevel;

    if (state.voiceToTextActive) {
      if (_voiceButtonState != VoiceButtonState.voiceToText) {
        newButtonState = VoiceButtonState.voiceToText;
      }
    } else {
      if (_voiceButtonState == VoiceButtonState.voiceToText) {
        if (state.partialText.isNotEmpty) {
          _insertVoiceText(state.partialText);
          _voiceInputBloc?.clearPartial();
        }
        newButtonState = VoiceButtonState.idle;
      }
    }

    if ((state.soundLevel - _voiceSoundLevel).abs() > 0.01) {
      newSoundLevel = state.soundLevel;
    }

    if (newButtonState != null || newSoundLevel != null) {
      setState(() {
        if (newButtonState != null) {
          _voiceButtonState = newButtonState;
        }
        if (newSoundLevel != null) {
          _voiceSoundLevel = newSoundLevel;
        }
      });
    }
  }

  void _insertVoiceText(String text) {
    final controller = widget.message;
    final selection = controller.selection;
    final insertPosition = selection.baseOffset >= 0 ? selection.baseOffset : controller.text.length;
    final newText = controller.text.replaceRange(insertPosition, insertPosition, '$text ');
    controller.text = newText;
    controller.selection = TextSelection.collapsed(offset: insertPosition + text.length + 1);
    widget.setSendEnabled(true);
  }

  Future<void> _stopVoiceToText() async {
    final bloc = _voiceInputBloc;
    if (bloc == null) return;
    await bloc.stopVoiceToText();
    setState(() => _voiceButtonState = VoiceButtonState.idle);
  }

  String _getShortTimerString() {
    if (widget.timer == UserDisappearingTimer.ONE_TIME_VIEW) return 'OTV';
    if (widget.timer == UserDisappearingTimer.TEN_SECONDS) return '10s';
    if (widget.timer == UserDisappearingTimer.THIRTY_SECONDS) return '30s';
    if (widget.timer == UserDisappearingTimer.ONE_MINUTE) return '1m';
    if (widget.timer == UserDisappearingTimer.FIVE_MINUTES) return '5m';
    if (widget.timer == UserDisappearingTimer.ONE_HOUR) return '1h';
    if (widget.timer == UserDisappearingTimer.EIGHT_HOURS) return '8h';
    if (widget.timer == UserDisappearingTimer.ONE_DAY) return '24h';

    return '';
  }

  _closeKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  _getDateTimeSchedule() async {
    DateTime? date = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate:
          DateTime(DateTime.now().year + 5), //should maximum be less than that?
      initialDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1),
            ),
            child: globalState.theme.themeMode == ICThemeMode.dark
                ? Theme(
                    data: ThemeData.dark().copyWith(
                      primaryColor: globalState.theme.button,
                      //accentColor:  globalState.theme.button,
                      colorScheme:
                          ColorScheme.dark(primary: globalState.theme.button),
                      buttonTheme: const ButtonThemeData(
                          textTheme: ButtonTextTheme.primary),
                    ),
                    child: child!,
                  )
                : Theme(
                    data: ThemeData.light().copyWith(
                      primaryColor: globalState.theme.button,
                      //accentColor:  globalState.theme.button,
                      colorScheme:
                          ColorScheme.light(primary: globalState.theme.button),
                      buttonTheme: const ButtonThemeData(
                          textTheme: ButtonTextTheme.primary),
                    ),
                    child: child!,
                  ));
      },
    );

    if (date != null) {
      TimeOfDay? time = await showTimePicker(
          initialTime: TimeOfDay.now(),
          context: context,
          builder: (BuildContext context, Widget? child) {
            return MediaQuery(
                data: const MediaQueryData(
                  textScaler: TextScaler.linear(1),
                ),
                child: globalState.theme.themeMode == ICThemeMode.dark
                    ? Theme(
                        data: ThemeData.dark().copyWith(
                          primaryColor: globalState.theme.button,
                          //accentColor:  globalState.theme.button,
                          colorScheme: ColorScheme.dark(
                              primary: globalState.theme.button),
                          buttonTheme: const ButtonThemeData(
                              textTheme: ButtonTextTheme.primary),
                        ),
                        child: child!,
                      )
                    : Theme(
                        data: ThemeData.light().copyWith(
                          primaryColor: globalState.theme.button,
                          //accentColor:  globalState.theme.button,
                          colorScheme: ColorScheme.light(
                              primary: globalState.theme.button),
                          buttonTheme: const ButtonThemeData(
                              textTheme: ButtonTextTheme.primary),
                        ),
                        child: child!,
                      ));
          });

      if (time != null) {
        setState(() {
          _scheduledDate =
              DateTime(date.year, date.month, date.day, time.hour, time.minute);
          if (_scheduledDate!.isBefore(DateTime.now())) {
            _scheduledDate = null;
            DialogNotice.showNotice(
                context,
                AppLocalizations.of(context)!.invalidTime,
                AppLocalizations.of(context)!.selectATimePastNow,
                "",
                "",
                "",
                false);
          } else {
            widget.setScheduled(_scheduledDate);
          }
        });
      }
    }
  }
}
