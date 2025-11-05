import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:ironcirclesapp/blocs/backlog_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/backlog.dart';
import 'package:ironcirclesapp/models/backlogreply.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/expandingtext.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';

class BacklogItemScreen extends StatefulWidget {
  final Backlog? backlog;

  const BacklogItemScreen({
    Key? key,
    this.backlog,
  }) : super(key: key);
  // final String title;

  @override
  _IssuesReportedNewState createState() => _IssuesReportedNewState();
}

class _IssuesReportedNewState extends State<BacklogItemScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final BacklogBloc _backlogBloc = BacklogBloc();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  late FocusNode _focusNode;
  final TextEditingController _summary = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _reply = TextEditingController();
  bool _sendEnabled = false;
  final ScrollController _scrollController = ScrollController();
  bool _clicked = false;
  String _type = 'defect';
  String _typeLocalized = '';
  final List<String> _typeList = <String>['defect', 'feature'];
  late List<String> _typeListLocalized = [''];
  String title = 'Submit a Defect';
  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  Backlog? backlog;

  @override
  void initState() {
    _focusNode = FocusNode();

    backlog = widget.backlog;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _typeListLocalized = <String>[
          AppLocalizations.of(context)!.defect,
          AppLocalizations.of(context)!.feature,
        ];
        _typeLocalized = _typeListLocalized[0];
        if (backlog != null) {
          if (backlog!.type == 'defect') {
            title = AppLocalizations.of(context)!.reportedDefect;
          } else {
            title = AppLocalizations.of(context)!.featureRequest;
          }
        } else {
          title = AppLocalizations.of(context)!.submitADefect;
        }
      });
    });

    if (backlog != null) {
      backlog!.replies = widget.backlog!.replies.reversed.toList();

      _type = backlog!.type;

      _summary.text = backlog!.summary;
      _description.text = backlog!.description;
    }

    _backlogBloc.backlogAdded.listen((backlog) {
      Navigator.pop(context, backlog);
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);

      _clicked = false;
      debugPrint("error $err");
    }, cancelOnError: false);

    _backlogBloc.backlogLoaded.listen((backlogs) async {
      if (mounted) {
        if (backlog != null) {
          backlog = backlogs.firstWhere((element) => element.id == backlog!.id);

          backlog!.replies = backlog!.replies.reversed.toList();
          setState(() {});
        }
      }
    }, onError: (err) {
      debugPrint("error $err");
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 3, true);
    }, cancelOnError: false);

    _backlogBloc.backlogReply.listen((reply) {
      if (mounted) {
        //backlog!.replies.add(reply);
        backlog!.replies.insert(0, reply);
        setState(() {
          _showSpinner = false;
        });
      }
    }, onError: (err) {
      debugPrint("error $err");
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 3, true);
    }, cancelOnError: false);

    _backlogBloc.get(globalState.userFurnace!);

    super.initState();
  }

  @override
  void dispose() {
    _backlogBloc.dispose();
    _focusNode.dispose();
    _summary.dispose();
    _description.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submit = SizedBox(
      height: 55.0,
      child: Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 2),
        child: Row(children: <Widget>[
          Expanded(
            child: GradientButton(
                text: AppLocalizations.of(context)!.submit,
                onPressed: () {
                  _submit();
                  //_connectToExisting();
                }),
          ),
        ]),
      ),
    );

    final makeReplies = backlog == null
        ? Container()
        : backlog!.replies.isNotEmpty
            ? Expanded(
                flex: 2,
                child: Scrollbar(
                    controller: _scrollController,
                    child: ListView.separated(
                        controller: _scrollController,
                        reverse: true,
                        separatorBuilder: (context, index) {
                          return Divider(
                            height: 10,
                            color: globalState.theme.background,
                          );
                        },
                        itemCount: backlog!.replies.length,
                        itemBuilder: (BuildContext context, int index) {
                          var row = backlog!.replies[index];

                          try {
                            return WrapperWidget(child: Padding(
                                padding:
                                    const EdgeInsets.only(left: 15, right: 15),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                                child: Image.asset(row
                                                            .user.role ==
                                                        Role.IC_ADMIN
                                                    ? 'assets/images/ios_icon.png'
                                                    : 'assets/images/avatar.jpg')),
                                            const Padding(
                                              padding: EdgeInsets.only(
                                                left: 10,
                                              ),
                                            ),
                                            Expanded(
                                                child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                  ICText(
                                                    row.created == null
                                                        ? ""
                                                        : '${DateFormat.yMMMd().format(row.created!)} ${DateFormat.jm().format(row.created!)}',
                                                    fontSize: 12,
                                                  ),
                                                  Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: [
                                                        Expanded(
                                                            child: ICText(
                                                                row.reply,
                                                                fontSize: 16,
                                                                color: row.user
                                                                            .role ==
                                                                        Role
                                                                            .IC_ADMIN
                                                                    ? globalState
                                                                            .theme
                                                                            .messageColorOptions![
                                                                        2]
                                                                    : globalState
                                                                        .theme
                                                                        .userObjectText))
                                                      ])
                                                ])),
                                          ]),
                                    ])));
                          } catch (err, trace) {
                            LogBloc.insertError(err, trace);
                          }
                        })))
            : Container();

    final makeBody = Container(
        // decoration: BoxDecoration(color: Color.fromRGBO(58, 66, 86, 1.0)),
        padding: const EdgeInsets.only(left: 8, right: 10, top: 0, bottom: 0),
        child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
                constraints: const BoxConstraints(),
                child: WrapperWidget(child:Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      backlog != null
                          ? Container()
                          : Padding(
                              padding: const EdgeInsets.only(
                                  left: 5, top: 5, bottom: 0),
                              child: Row(children: <Widget>[
                                Expanded(
                                  flex: 1,
                                  child: FormField(
                                    builder: (FormFieldState<String> state) {
                                      return FormattedDropdown(
                                        hintText: AppLocalizations.of(context)!.featureOrDefect.toLowerCase(),
                                        list: _typeListLocalized,
                                        selected: _typeLocalized,
                                        errorText: state.hasError
                                            ? state.errorText
                                            : null,
                                        onChanged: (String? value) {
                                          setState(() {
                                            _type = _typeList[_typeListLocalized.indexOf(value!)];

                                            if (_type == 'defect') {
                                              title = AppLocalizations.of(context)!.reportedDefect;
                                            } else {
                                              title = AppLocalizations.of(context)!.featureRequest;
                                            }
                                            _typeLocalized = value!;
                                            if (value!.isEmpty) value = null;
                                            state.didChange(value);
                                          });
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ]),
                            ),
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 5, top: 12, bottom: 12),
                        child: ExpandingText(
                          capitals: true,
                          height: 100 * globalState.textFieldScaleFactor,
                          readOnly: backlog == null ? false : true,
                          labelText: AppLocalizations.of(context)!.summary.toLowerCase(),
                          controller: _summary,
                          validator: (value) {
                            if (value.isEmpty) {
                              return AppLocalizations.of(context)!.errorFieldRequired;
                            }

                            return null;
                          },
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 5, top: 4, bottom: 4),
                        child: ExpandingText(
                          capitals: true,
                          height: 100 * globalState.textFieldScaleFactor,
                          readOnly: backlog == null ? false : true,
                          labelText: AppLocalizations.of(context)!.description.toLowerCase(),
                          controller: _description,
                          /*validator: (value) {
                          if (value.isEmpty) {
                            return 'field is required';
                          }
                        },

                         */
                        ),
                      ),
                    ])))));

    return Form(
        key: _formKey,
        child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: globalState.theme.background,
            appBar: ICAppBar(
              title: title,
              actions: [
                backlog == null
                    ? Container()
                    : IconButton(
                        //padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.refresh,
                            color: globalState.theme.menuIcons),
                        onPressed: () {
                          _refresh();
                        })
              ],
            ),
            body: SafeArea(
              left: false,
              top: false,
              right: false,
              bottom: true,
              child: Stack(children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(child: makeBody),
                    backlog == null
                        ? Container()
                        : backlog!.hideReplies == false
                            ? makeReplies
                            : backlog!.creator!.id == globalState.user.id
                                ? makeReplies
                                : globalState.user.role == Role.IC_ADMIN
                                    ? makeReplies
                                    : Container(),
                    backlog == null
                        ? Padding(
                            padding: const EdgeInsets.only(
                                top: 5, left: 20, right: 20, bottom: 0),
                            child: submit,
                          )
                        : Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 0, right: 10),
                                child: backlog!.voteLabel.isEmpty
                                    ? Container()
                                    : GradientButtonDynamic(
                                        text: backlog!.voteLabel,
                                        onPressed: () {
                                          _vote(backlog!);
                                        },
                                      ))),
                    backlog == null
                        ? Container()
                        : backlog!.creator!.id == globalState.user.id ||
                                globalState.user.role == Role.IC_ADMIN
                            ? Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Row(children: [
                                  Expanded(
                                    flex: 1,
                                    child: Stack(
                                        alignment: Alignment.topRight,
                                        children: [
                                          ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                  maxHeight:
                                                      125 //put here the max height to which you need to resize the textbox
                                                  ),
                                              child: TextField(
                                                  cursorColor: globalState.theme.textField,
                                                  controller: _reply,
                                                  focusNode: _focusNode,
                                                  maxLines: null,
                                                  maxLength: TextLength.Largest,
                                                  //lines < maxLines ? null : maxLines,
                                                  textCapitalization:
                                                      TextCapitalization
                                                          .sentences,
                                                  style: TextStyle(
                                                      fontSize: (globalState
                                                                  .userSetting
                                                                  .fontSize /
                                                              globalState
                                                                  .mediaScaleFactor) *
                                                          globalState
                                                              .textFieldScaleFactor, //18,
                                                      color: globalState.theme
                                                          .userObjectText),
                                                  decoration: InputDecoration(
                                                    counterText: '',
                                                    filled: true,
                                                    fillColor: globalState.theme
                                                        .messageBackground,
                                                    hintText: AppLocalizations.of(context)!.enterNewReply,
                                                    hintStyle: TextStyle(
                                                      color: globalState.theme
                                                          .messageTextHint,
                                                      fontSize: ((globalState
                                                                      .userSetting
                                                                      .fontSize -
                                                                  globalState
                                                                      .scaleDownTextFont) /
                                                              globalState
                                                                  .mediaScaleFactor) *
                                                          globalState
                                                              .textFieldScaleFactor,
                                                    ),
                                                    contentPadding:
                                                        EdgeInsets.only(
                                                            left: 14,
                                                            bottom: 10,
                                                            top: 10,
                                                            right: _sendEnabled
                                                                ? 42
                                                                : 0),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                          color: globalState
                                                              .theme
                                                              .messageBackground),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                          color: globalState
                                                              .theme
                                                              .messageBackground),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                  ),
                                                  onChanged: (text) {
                                                    setState(() {
                                                      if (_reply
                                                          .text.isNotEmpty)
                                                        _sendEnabled = true;
                                                      else
                                                        _sendEnabled = false;
                                                    });
                                                  })),
                                          _sendEnabled
                                              ? IconButton(
                                                  icon: Icon(
                                                      Icons.cancel_rounded,
                                                      color: globalState.theme
                                                          .buttonDisabled),
                                                  iconSize: 22,
                                                  onPressed: () {
                                                    _reply.text = '';
                                                    _sendEnabled = false;
                                                  },
                                                )
                                              : Container(),
                                        ]),
                                    //}),
                                  ),
                                  SizedBox(
                                      height: 40,
                                      //width:80,
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.send_rounded,
                                          size: 30,
                                          color: _sendEnabled
                                              ? globalState
                                                  .theme.bottomHighlightIcon
                                              : globalState
                                                  .theme.buttonDisabled,
                                        ),
                                        onPressed: () {
                                          _replyToBacklog();
                                        },
                                      ))
                                ]))
                            : Container(),
                  ],
                ),
                _showSpinner ? spinkit : Container()
              ]),
            )));
  }

  Future<void> _refresh() async {
    _backlogBloc.get(globalState.userFurnace!);
  }

  _vote(Backlog backlog) {
    try {
      _backlogBloc.vote(globalState.userFurnace!, backlog);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('BacklogScreen._vote: $err');
    }
  }

  _submit() {
    try {
      if (_formKey.currentState!.validate()) {
        setState(() {
          _showSpinner = true;
        });

        if (_clicked == false) {
          _clicked = true;

          Backlog backlog = Backlog(
            summary: _summary.text,
            description: _description.text,
            type: _type,
            replies: [],
          );

          _backlogBloc.post(globalState.userFurnace!, backlog);
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('BacklogAddsCreen.submit: $err');
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      _clicked = false;
    }
  }

  _replyToBacklog() {
    _showSpinner = true;

    FocusScope.of(context).requestFocus(FocusNode());

    //backlog!.replies.add(BacklogReply(
    //    user: globalState.user, reply: _reply.text, created: DateTime.now()));
    _backlogBloc.reply(
        globalState.userFurnace!,
        backlog!,
        BacklogReply(
            user: globalState.user,
            reply: _reply.text,
            created: DateTime.now()));

    _sendEnabled = false;
    _reply.text = '';
    //FocusScope.of(context).requestFocus(_focusNode);

    setState(() {});

    if (_scrollController.hasClients)
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
  }

/*
  void _connected(UserFurnace userFurnace) {
    //localFurnace = userFurnace;
    _refresh(userFurnace);

    /*
    setState(() {
      _showChangePassword = true;
      localFurnace = userFurnace;
    });

    FormattedSnackBar.showSnackbarWithContext(context, 'Furnace Connected', "", 2);

     */
  }*/
}
