import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circlevote_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circlevote_radio_closed.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';

class CircleVoteScreen extends StatefulWidget {
  final UserCircleCache? userCircleCache;
  final UserFurnace? userFurnace;
  //final List<UserFurnace> userFurnaces;
  final CircleObject? circleObject;
  final int screenMode;
  final Function? setNetworks;

  const CircleVoteScreen(
      {Key? key,
      this.circleObject,
      this.userCircleCache,
      this.userFurnace,
      this.setNetworks,
      //@required this.userFurnaces,
      required this.screenMode})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CircleVoteScreenState();
  }
}

class _CircleVoteScreenState extends State<CircleVoteScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  int? _radioValue = -1;
  List<UserFurnace> _selectedNetworks = [];

  final CircleVoteBloc _circleVoteBloc = CircleVoteBloc();
  CircleVote? _circleVote = CircleVote();

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    super.initState();

    if (widget.screenMode == ScreenMode.ADD) {
      //_circleVote.init();
    } else {
      _circleVote = CircleVote.deepCopy(widget.circleObject!.vote!);
    }

    _circleVoteBloc.submitVoteResults.listen((circleObject) {
      _showSpinner = false;
      //setState(() {
      //_showSpinner = false;
      Navigator.of(context).pop(circleObject);
      //});
    }, onError: (err) {
      setState(() {
        _showSpinner = false;
      });
      debugPrint("CircleVoteScreen.initState.submitVoteResults: $err");
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 1, true);
    }, cancelOnError: false);
  }

  @override
  void dispose() {
    //_circleRecipe.disposeUIControls();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_radioValue == -1)
      _radioValue = CircleVote.getUserVotedForIndex(
          widget.circleObject!.vote!, widget.userFurnace!.userid);

    final width = MediaQuery.of(context).size.width;

    final header =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      /*!widget.circleObject.vote.open
          ? Text('Vote is Closed',
              style:
                  TextStyle(color: globalState.theme.userTitleBody, fontSize: 18))
          : Text("Vote is Open",
              style: TextStyle(
                  color: globalState.theme.userTitleBody, fontSize: 18)),*/
      Center(
          child: Text(
        widget.circleObject!.vote!.getQuestion(context),
        textScaler: TextScaler.linear(globalState.messageScaleFactor),
        style: TextStyle(color: globalState.theme.userObjectText, fontSize: 18),
      )),
      widget.circleObject!.vote!.description != null
          ? Padding(
              padding: const EdgeInsets.only(left: 45, top: 20, bottom: 10),
              child: Text(
                widget.circleObject!.vote!.getDescription(context),
                textScaler: TextScaler.linear(globalState.messageScaleFactor),
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: globalState.theme.labelText,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ))
          : Container(),
    ]);

    final bottom = widget.circleObject!.vote!.open!
        ? SizedBox(
            height: 65.0,
            //width: 250,
            child: Padding(
              padding: const EdgeInsets.only(top: 0, bottom: 0),
              child: Column(
                  //crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Row(children: <Widget>[
                      Expanded(
                          flex: 1,
                          child: Center(
                              child: Container(
                                  constraints: BoxConstraints(
                                      maxWidth: ScreenSizes.getMaxButtonWidth(
                                          width, true)),
                                  child: GradientButton(
                                    text: CircleVote.didUserVote(
                                            widget.circleObject!.vote!,
                                            widget.userFurnace!.userid)
                                        ? AppLocalizations.of(context)!
                                            .changeVote
                                            .toUpperCase()
                                        : AppLocalizations.of(context)!
                                            .vote
                                            .toUpperCase(),
                                    onPressed: () {
                                      _submitVote(
                                          widget.circleObject,
                                          widget.circleObject!.vote!
                                              .options![_radioValue!]);
                                    },
                                  )))),
                    ]),
                  ]),
            ),
          )
        : Container();

    final body = Container(
        padding:
            const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
        child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
                constraints: const BoxConstraints(),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      ListView.builder(
                          //scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          itemCount: _circleVote!.options!.length,
                          itemBuilder: (BuildContext context, int index) {
                            CircleVoteOption row =
                                widget.circleObject!.vote!.options![index];

                            //return Container();
                            return widget.circleObject!.vote!.open!
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: <Widget>[
                                            const Padding(
                                              padding:
                                                  EdgeInsets.only(left: 15),
                                            ),
                                            SizedBox(
                                                height: 23,
                                                width: 23,
                                                child: Theme(
                                                    data: ThemeData(
                                                      //here change to your color
                                                      unselectedWidgetColor:
                                                          globalState.theme
                                                              .unselectedLabel,
                                                    ),
                                                    child: Radio(
                                                      fillColor:
                                                          MaterialStateProperty
                                                              .resolveWith(
                                                                  globalState
                                                                      .getRadioColor),
                                                      activeColor: globalState
                                                          .theme.button,
                                                      value: index,
                                                      groupValue: _radioValue,
                                                      onChanged:
                                                          _handleRadioValueChange,
                                                    ))),
                                            const Padding(
                                                padding:
                                                    EdgeInsets.only(right: 10)),
                                            Expanded(
                                                child: InkWell(
                                                    onTap: () {
                                                      _handleRadioValueChange(
                                                          index);
                                                    },
                                                    child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                top: 5,
                                                                bottom: 5),
                                                        child: Text(
                                                          _buildRowText(row),
                                                          textScaler: TextScaler
                                                              .linear(globalState
                                                                  .messageScaleFactor),
                                                          style: TextStyle(
                                                              fontSize: 17,
                                                              color: globalState
                                                                  .theme
                                                                  .objectTitle),
                                                        )))),
                                          ]),
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: <Widget>[
                                            const Padding(
                                              padding:
                                                  EdgeInsets.only(left: 40),
                                            ),
                                            Flexible(
                                                flex: 1,
                                                child: Text(
                                                  row.voteTally != null
                                                      ? _userList(row)
                                                      : "",
                                                  textScaler: TextScaler.linear(
                                                      globalState
                                                          .messageScaleFactor),
                                                  style: TextStyle(
                                                      fontSize: 17,
                                                      color: globalState
                                                          .theme.username),
                                                  textAlign: TextAlign.start,
                                                )),
                                          ]),
                                      const Padding(
                                        padding: EdgeInsets.only(
                                            bottom: 12, left: 0),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                        Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: <Widget>[
                                              const Padding(
                                                padding: EdgeInsets.only(
                                                    bottom: 0, left: 15),
                                              ),
                                              CircleVoteRadioClosed(
                                                  widget.circleObject!.vote,
                                                  row,
                                                  index,
                                                  _radioValue),
                                              Flexible(
                                                  flex: 2,
                                                  child: Text(
                                                    _buildRowText(row),
                                                    style: TextStyle(
                                                        fontSize: 17,
                                                        color: globalState.theme
                                                            .labelVoteOption),
                                                  )),
                                            ]),
                                        Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: <Widget>[
                                              const Padding(
                                                padding: EdgeInsets.only(
                                                    bottom: 0, left: 40),
                                              ),
                                              Flexible(
                                                  flex: 1,
                                                  child: Text(
                                                    row.voteTally != null
                                                        ? _userList(row)
                                                        : "",
                                                    style: TextStyle(
                                                        fontSize: 17,
                                                        color: globalState.theme
                                                            .urgentAction),
                                                    textAlign: TextAlign.start,
                                                  )),
                                            ]),
                                        const Padding(
                                          padding: EdgeInsets.only(
                                              bottom: 12, left: 0),
                                        ),
                                      ]);
                          }),
                      globalState.isDesktop() ? bottom : Container(),
                    ]))));

    /* final topAppBar = AppBar(
      elevation: 0.1,
      backgroundColor: globalState.theme.background,
      iconTheme: IconThemeData(
        color: globalState.theme.menuIcons, //change your color here
      ),
      title: widget.screenMode == ScreenMode.ADD
          ? Text("New Vote",
              style: ICTextStyle.getStyle(context: context,
                  color: globalState.theme.textTitle,
                  fontSize: ICTextStyle.appBarFontSize))
          : widget.circleObject!.vote!.open!
              ? CircleVote.didUserVote(
                      widget.circleObject!.vote!, widget.userFurnace!.userid)
                  ? Text("Change Vote?",
                      style: ICTextStyle.getStyle(context: context,
                          color: globalState.theme.textTitle,
                          fontSize: ICTextStyle.appBarFontSize))
                  : Text('Submit Vote',
                      style: ICTextStyle.getStyle(context: context,
                          color: globalState.theme.textTitle,
                          fontSize: ICTextStyle.appBarFontSize))
              : Text(CircleVote.getTitle(widget.circleObject!.vote!),
                  style: ICTextStyle.getStyle(context: context,
                      color: globalState.theme.textTitle,
                      fontSize: ICTextStyle.appBarFontSize)),
      actions: <Widget>[],
    );

    */

    return Form(
      key: _formKey,
      child: Scaffold(
          backgroundColor: globalState.theme.background,
          key: _scaffoldKey,
          appBar: ICAppBar(
              title: widget.screenMode == ScreenMode.ADD
                  ? AppLocalizations.of(context)!.newVote
                  : widget.circleObject!.vote!.open!
                      ? CircleVote.didUserVote(widget.circleObject!.vote!,
                              widget.userFurnace!.userid)
                          ? AppLocalizations.of(context)!.changeVoteQuestion
                          : AppLocalizations.of(context)!.submitVote
                      : widget.circleObject!.vote!.getTitle(
                          context,
                        )),
          body: SafeArea(
            left: false,
            top: false,
            right: false,
            bottom: true,
            child: Stack(children: [
              Padding(
                  padding:
                      const EdgeInsets.only(left: 10, right: 10, bottom: 0),
                  child: WrapperWidget(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      header,
                      const Padding(
                        padding: EdgeInsets.only(top: 15),
                      ),
                      Expanded(child: body),
                      globalState.isDesktop() ? Container() : bottom,
                    ],
                  ))),
              _showSpinner ? Center(child: spinkit) : Container(),
            ]),
          )),
    );
  }

  _handleRadioValueChange(int? value) {
    setState(() {
      _radioValue = value;
    });
  }

  String _buildRowText(CircleVoteOption row) {
    String retValue = row.getOption(context, widget.circleObject!.vote!.type!);
    retValue += " (${row.usersVotedFor!.length})";

    return retValue;
  }

  _submitVote(
      CircleObject? circleObject, CircleVoteOption selectedOption) async {
    setState(() {
      _showSpinner = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    //FormattedSnackBar.showSnackbarWithContext(context, selectedOption.option, "", 2);
    if (_radioValue! > -1) {
      if (CircleVote.didUserVote(
          circleObject!.vote!, widget.userFurnace!.userid)) {
        if (CircleVote.didUserVotedForOption(
            selectedOption, widget.userFurnace!.userid)) {
          if (mounted) {
            FormattedSnackBar.showSnackbarWithContext(context,
                AppLocalizations.of(context)!.voteHasNotChanged, "", 2, false);
          }

          return;
        }
      }

      _circleVoteBloc.submitVote(widget.userCircleCache!, circleObject,
          selectedOption, widget.userFurnace!);
    }
  }

  String _userList(CircleVoteOption circleVoteOption) {
    String retValue = '';

    circleVoteOption.usersVotedFor!.sort((a, b) {
      return a.username!.compareTo(b.username!);
    });

    for (User user in circleVoteOption.usersVotedFor!) {
      if (retValue.isEmpty)
        retValue = user.getUsernameAndAlias(globalState);
      else
        retValue += ', ${user.getUsernameAndAlias(globalState)}';
    }

    //if (retValue.isNotEmpty) retValue += ')';

    return retValue;
  }
}
