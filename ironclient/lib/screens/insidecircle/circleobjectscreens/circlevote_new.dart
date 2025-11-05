import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circlevote_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/dialogselectnetwork.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/selectnetworkstextbutton.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';

class NewVote extends StatefulWidget {
  final UserCircleCache? userCircleCache;
  final UserFurnace? userFurnace;
  final CircleVoteBloc circleVoteBloc;
  final int? timer;
  final DateTime? scheduledFor;
  final Circle circle;
  final int? increment;
  final List<UserFurnace> userFurnaces;
  final Function? setNetworks;
  final bool wall;

  const NewVote(
      {Key? key,
      this.userCircleCache,
      this.userFurnace,
      required this.timer,
      required this.circleVoteBloc,
      required this.scheduledFor,
      this.increment,
      required this.userFurnaces,
      this.setNetworks,
      this.wall = false,
      required this.circle})
      : super(key: key);

  @override
  NewVoteState createState() => NewVoteState();
}

class NewVoteState extends State<NewVote> {
  final ScrollController _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  //final CircleVoteBloc _circleVoteBloc = CircleVoteBloc();

  final _answers = <TextEditingController>[];
  final TextEditingController _question = TextEditingController();
  List<UserFurnace> _selectedNetworks = [];
  List<String> _voteTypes = [];
  String _voteType = "";

  bool _saving = false;
  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );
  bool _popping = false;

  @override
  void initState() {
    super.initState();

    widget.circleVoteBloc.createdResponse.listen((circleObject) {
      if (mounted) {
        _exit(circleVote: circleObject.vote!);
      }
    }, onError: (err) {
      debugPrint("error $err");
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      _saving = false;
    }, cancelOnError: false);
  }

  @override
  void dispose() {
    for (var controller in _answers) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (_answers.isEmpty) {
      _answers.add(TextEditingController(
          text: AppLocalizations.of(context)!.yes.toLowerCase()));
      _answers.add(TextEditingController(
          text: AppLocalizations.of(context)!.no.toLowerCase()));
    }

    if (_voteType.isEmpty) {
      _voteType = AppLocalizations.of(context)!.poll.toLowerCase();
    }

    if (_voteTypes.isEmpty) {
      _voteTypes.add(AppLocalizations.of(context)!.poll.toLowerCase());
      _voteTypes.add(AppLocalizations.of(context)!.majority.toLowerCase());
      _voteTypes.add(AppLocalizations.of(context)!.unanimous.toLowerCase());
    }

    final makeBottom = SizedBox(
      height: 55.0,
      child: Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 0),
        child: Row(children: <Widget>[
          Expanded(
              child: Center(
                  child: Container(
            constraints: BoxConstraints(
                maxWidth: ScreenSizes.getMaxButtonWidth(width, true)),
            child: GradientButton(
                text: AppLocalizations.of(context)!.submit,
                onPressed: () {
                  _save();
                }),
          ))),
        ]),
      ),
    );

    final makeBody = Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ConstrainedBox(
          constraints: const BoxConstraints(),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 0),
                  child: Row(children: <Widget>[
                    Expanded(
                      flex: 20,
                      child: Text(
                        AppLocalizations.of(context)!.question,
                        textScaler:
                            TextScaler.linear(globalState.labelScaleFactor),
                        style: TextStyle(
                            fontSize: 18, color: globalState.theme.labelText),
                      ),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 0),
                  child: Row(children: <Widget>[
                    Expanded(
                      flex: 20,
                      child: ExpandingLineText(
                        maxLength: TextLength.Smaller,
                        labelText:
                            AppLocalizations.of(context)!.enterVotingQuestion,
                        maxLines: 4,
                        controller: _question,
                        validator: (value) {
                          if (value.toString().isEmpty) {
                            return AppLocalizations.of(context)!
                                .errorQuestionIsRequired;
                          }
                          return null;
                        },
                      ),
                    ),
                  ]),
                ),
                Padding(
                    padding: const EdgeInsets.only(top: 4, left: 0),
                    child: FormattedDropdown(
                      hintText: AppLocalizations.of(context)!.votingModel,
                      list: _voteTypes,
                      selected: _voteType,
                      // errorText: state.hasError ? state.errorText : null,
                      onChanged: (String? value) {
                        setState(() {
                          if (value != null) {
                            _voteType = value;
                          }
                        });
                      },
                    )),
                Padding(
                  padding: const EdgeInsets.only(top: 30, bottom: 0),
                  child: Row(children: <Widget>[
                    Expanded(
                      flex: 20,
                      child: Text(
                        AppLocalizations.of(context)!.answers,
                        textScaler:
                            TextScaler.linear(globalState.labelScaleFactor),
                        style: TextStyle(
                            fontSize: 18, color: globalState.theme.labelText),
                      ),
                    ),
                    // IconButton(icon: Icon(Icons.add), color: globalState.theme.buttonIcon,)
                    Container(
                      child: Ink(
                        decoration: ShapeDecoration(
                          color: globalState.theme.buttonIcon,
                          shape: const CircleBorder(),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add),
                          color: globalState.theme.buttonLineForeground,
                          onPressed: () {
                            setState(() {
                              _answers.add(
                                TextEditingController(text: ""),
                              );
                            });
                          },
                        ),
                      ),
                    ),
                  ]),
                ),
                ListView.separated(
                    separatorBuilder: (context, index) => Divider(
                          color: globalState.theme.divider,
                        ),
                    scrollDirection: Axis.vertical,
                    controller: _scrollController,
                    shrinkWrap: true,
                    itemCount: _answers.length,
                    itemBuilder: (BuildContext context, int index) {
                      TextEditingController row = _answers[index];

                      return Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 0),
                        child: Row(children: <Widget>[
                          Expanded(
                            // flex: 20,
                            child: ExpandingLineText(
                              maxLength: TextLength.Smaller,
                              validator: (value) {
                                if (value.toString().isEmpty) {
                                  return AppLocalizations.of(context)!
                                      .errorAnswerIsRequired;
                                }

                                return null;
                              },
                              controller: row,
                              labelText:
                                  "${AppLocalizations.of(context)!.answer} ${index + 1}",
                              maxLines: 4,
                            ),
                          ),
                          Container(
                            child: Ink(
                              decoration: ShapeDecoration(
                                color: globalState.theme.background,
                                shape: const CircleBorder(),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.remove_circle),
                                color: globalState.theme.buttonLineForeground,
                                onPressed: () {
                                  setState(() {
                                    _answers.removeAt(index);
                                  });
                                },
                              ),
                            ),
                          ),
                        ]),
                      );
                    }),

                ///select a furnace to post to
                widget.userFurnaces.length > 1 &&
                        widget.wall &&
                        widget.setNetworks != null
                    ? Row(children: <Widget>[
                        Expanded(
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  top: 10, left: 2, right: 2),
                              child: SelectNetworkTextButton(
                                userFurnaces: widget.userFurnaces,
                                selectedNetworks: _selectedNetworks,
                                callback: _setNetworks,
                              ),
                            ))
                      ])
                    : Container(),
                globalState.isDesktop() ? makeBottom : Container(),
              ]),
        ),
      ),
    );

    return Form(
      key: _formKey,
      child: Scaffold(
        backgroundColor: globalState.theme.background,
        key: _scaffoldKey,
        appBar: ICAppBar(title: AppLocalizations.of(context)!.newVote),
        body: SafeArea(
            left: false,
            top: false,
            right: false,
            bottom: true,
            child: Stack(children: [
              WrapperWidget(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: makeBody,
                  ),
                  globalState.isDesktop() ? Container() : makeBottom,
                ],
              )),
              _showSpinner ? Center(child: spinkit) : Container(),
            ])),
      ),
    );
  }

  _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _showSpinner = true;
      });

      if (widget.wall) {
        if (_selectedNetworks.isEmpty) {
          if (widget.userFurnaces.length == 1) {
            _setNetworksAndPost(widget.userFurnaces);
          } else {
            List<UserFurnace>? selectedNetworks =
                await DialogSelectNetworks.selectNetworks(
                    context: context,
                    networks: widget.userFurnaces,
                    callback: _setNetworksAndPost,
                    existingNetworksFilter: _selectedNetworks);

            if (selectedNetworks == null) {
              setState(() {
                _showSpinner = false;
              });
            }
          }
        } else {
          _saveCircleObject();
        }
      } else {
        _saveCircleObject();
      }
    }
  }

  String _getVoteType() {
    if (_voteType == AppLocalizations.of(context)!.poll.toLowerCase()) {
      return CircleVoteModel.POLL;
    } else if (_voteType == AppLocalizations.of(context)!.majority) {
      return CircleVoteModel.MAJORITY;
    } else if (_voteType == AppLocalizations.of(context)!.unanimous) {
      return CircleVoteModel.UNANIMOUS;
    }

    return '';
  }

  _saveCircleObject() {
    try {
      if (_formKey.currentState!.validate()) {
        if (_saving) return;

        _saving = true;
        //TODO build options list from textcontroller array

        List<CircleVoteOption> options = [];

        for (TextEditingController edit in _answers) {
          for (CircleVoteOption existing in options) {
            if (existing.option == edit.text.trim())
              throw ('votes cannot have duplicate values');
          }
          options.add(CircleVoteOption(option: edit.text.trim()));
        }

        CircleVote circleVote = CircleVote(
            question: _question.text, options: options, model: _getVoteType());

        if (widget.wall) {
          ///Don't save the object if it's a wall post. The User might have selected multiple networks
          //_pop(newObject);
          _exit(circleVote: circleVote);
        } else {
          widget.circleVoteBloc.createVote(
              widget.userCircleCache!,
              circleVote,
              widget.userFurnace!,
              widget.timer,
              widget.scheduledFor,
              widget.circle,
              widget.increment);
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      _saving = false;
    }
  }

  ///callback for the automatic popup
  _setNetworksAndPost(List<UserFurnace> newlySelectedNetworks) {
    if (widget.setNetworks != null) {
      widget.setNetworks!(newlySelectedNetworks);
      _selectedNetworks = newlySelectedNetworks;

      _saveCircleObject();
    }
  }

  ///callback for the ui control tap
  _setNetworks(List<UserFurnace> newlySelectedNetworks) {
    if (widget.setNetworks != null) {
      widget.setNetworks!(newlySelectedNetworks);
      _selectedNetworks = newlySelectedNetworks;
      setState(() {});
    }
  }

  _exit({CircleVote? circleVote}) {
    _closeKeyboard();
    if (circleVote != null) {
      if (_popping == false) {
        _popping = true;
        Navigator.of(context).pop(circleVote);
      }
    } else {
      if (_popping == false) {
        _popping = true;
        Navigator.pop(context);
      }
    }
  }

  _closeKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }
}
