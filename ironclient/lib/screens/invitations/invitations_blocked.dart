import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/invitations_bloc.dart';
import 'package:ironcirclesapp/blocs/member_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';

class InvitationBlocked extends StatefulWidget {
  final Function refreshCallback;
  final List<UserFurnace> userFurnaces;
  const InvitationBlocked(
      {Key? key, required this.refreshCallback, required this.userFurnaces})
      : super(key: key);

  @override
  InvitationBlockedState createState() => InvitationBlockedState();
}

class InvitationBlockedState extends State<InvitationBlocked> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  //List _invitations =[];

  List? _blockedUsers = [];

  final ScrollController _scrollController = ScrollController();

  final InvitationBloc _invitationBloc = InvitationBloc();

  final TextEditingController _circleName = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _password2 = TextEditingController();
  List<UserFurnace>? _userFurnaces;
  final UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();
  final MemberBloc _memberBloc = MemberBloc();
  bool _fetchedBlockedUsers = false;

  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    _userFurnaceBloc.userfurnaces.listen((furnaces) {
      if (mounted) {
        _userFurnaces = furnaces;
        _invitationBloc.fetchBlockedlist(_userFurnaces!);
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2,  true);
    }, cancelOnError: false);

    //Listen for the list of invitations
    _invitationBloc.invitations.listen((invitations) {
      if (mounted) {
        //widget.refreshCallback(invitations);
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _invitationBloc.removedFromBlockedlist.listen((user) {
      if (mounted) {
        setState(() {
          _blockedUsers!.removeWhere((element) => element.id == user.id);
        });

        for (Member m in globalState.members) {
          if (m.memberID == user.id) {
            _memberBloc.setBlocked(user.userFurnace!.userid!, m, false);
          }
        }

        //_invitationBloc.fetchInvitationsForUser(_userFurnaces!, force: true);
        FormattedSnackBar.showSnackbarWithContext(
            context, "${user.username!} ${AppLocalizations.of(context)!.removedFromList}", "", 2,  false);
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2,  true);
    }, cancelOnError: false);

    _invitationBloc.blockedList.listen((users) {
      if (mounted) {
        //_userFurnaces = furnaces;
        setState(() {
          _fetchedBlockedUsers = true;
          _blockedUsers = [];

          for (User user in users) {
            if (user.blockedEnabled!)
              _blockedUsers!.addAll(user.blockedList!);
            else
              //_blockedUsers = user.allowedList;
              _blockedUsers!.addAll(user.allowedList!);
          }
        });
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2,  true);
    }, cancelOnError: false);

    //_userFurnaceBloc.request(globalState.user.id, false);

    _userFurnaces = widget.userFurnaces;
    _invitationBloc.fetchBlockedlist(_userFurnaces!);
    super.initState();
  }

  @override
  void dispose() {
    _circleName.dispose();
    _password.dispose();
    _password2.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<String> _empty = [AppLocalizations.of(context)!.noUsersOnBlockedList]; //"No users on blocked list"];

    final makeEmpty = Container(
      //color: globalState.theme.body,
      // decoration: BoxDecoration(color: Color.fromRGBO(58, 66, 86, 1.0)),
      padding: const EdgeInsets.only(
        top: 20,
      ),
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        //shrinkWrap: true,
        itemCount: _empty.length,
        itemBuilder: (BuildContext context, int index) {
          return Center(
            child: ICText(_empty[0],
                textScaleFactor: globalState.labelScaleFactor,
                fontSize: 16,
                color: globalState.theme.labelText),
          );
        },
      ),
    );

    final makeBody = SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Container(
          color: globalState.theme.background,
          padding:
              const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 20),
          child: ListView.separated(
            separatorBuilder: (context, index) => Divider(
              color: globalState.theme.divider,
            ),
            scrollDirection: Axis.vertical,
            controller: _scrollController,
            shrinkWrap: true,
            itemCount: _blockedUsers!.length,
            itemBuilder: (BuildContext context, int index) {
              User row = _blockedUsers![index];
              return WrapperWidget(child: Padding(
                padding: const EdgeInsets.only(
                    left: 0.0, top: 0.0, bottom: 0.0, right: 0.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    AvatarWidget(
                        user: row,
                        userFurnace: row.userFurnace!,
                        //avatarid: row.avatar,
                        radius: 60 - (globalState.scaleDownIcons * 2),
                        showAvatar: true,
                        refresh: _refresh,
                        isUser: true),
                    const Padding(
                        padding: EdgeInsets.only(
                            left: 0.0, top: 0.0, bottom: 0.0, right: 10.0)),
                    Expanded(
                      child: ICText(
                          row.username!.length > 20
                              ? row
                                  .getUsernameAndAlias(globalState)
                                  .substring(0, 19)
                              : row.getUsernameAndAlias(globalState),
                          textScaleFactor: globalState.labelScaleFactor,
                          fontSize: 17,
                          color: globalState.theme.labelText),
                    ),
                    InkWell(
                      //onTap: () => _voteOut(context, row.username, row.id),
                      child: TextButton(
                        onPressed: () {
                          _remove(row);
                        },
                        child: ICText('remove',
                            textScaleFactor: globalState.labelScaleFactor,
                            color: globalState.theme.buttonIcon,
                            fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ));
            },
          )),
    );

    return Form(
        key: _formKey,
        child: Scaffold(
            appBar: const ICAppBar(title: 'Blocked Users'),
            key: _scaffoldKey,
            backgroundColor: globalState.theme.background,
            body: RefreshIndicator(
                key: _refreshIndicatorKey,
                onRefresh: _refresh,
                child: _blockedUsers!.isNotEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Expanded(
                            child: makeBody,
                          ),
                        ],
                      )
                    : _fetchedBlockedUsers
                        ? makeEmpty
                        : Center(
                            child: spinkit,
                          ))));
  }

  Future<void> _refresh() async {
    _userFurnaceBloc.request(globalState.user.id);

    return;
  }

  _remove(User user) {
    _invitationBloc.removeFromBlockedList(user);
  }
}
