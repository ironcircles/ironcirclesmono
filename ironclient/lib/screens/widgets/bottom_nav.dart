import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class ICBottomNavigation extends StatefulWidget {
  final Function onIndexChanged;
  final int invitationCount;

  ICBottomNavigation(
      {required this.onIndexChanged, required this.invitationCount});

  @override
  State<StatefulWidget> createState() {
    return _BottomNavigationState();
  }
}

class _BottomNavigationState extends State<ICBottomNavigation> {
  final UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();
  //final ActionNeededBloc _actionNeededBloc = ActionNeededBloc();

  late List<UserFurnace> _userFurnaces;
  int _actionCount = 0;
  int _actionCountLowPriority = 0;
  int index = 0;

  @override
  void initState() {
    _userFurnaces = [];

    _userFurnaceBloc.userfurnaces.listen((userFurnaces) {
      if (mounted) {
        setState(() {
          _userFurnaces = userFurnaces!;
          //_actionNeededBloc.(_userFurnaces);

          //_invyCount = 0;
          _actionCount = 0;
          _actionCountLowPriority = 0;

          for (UserFurnace userFurnace in _userFurnaces) {
            if (userFurnace.connected!) {
              if (userFurnace.invitations != null) {
                //_invyCount += userFurnace.invitations!;
              }
              if (userFurnace.actionsRequired != null) {
                _actionCount = _actionCount + userFurnace.actionsRequired!;
              }
              if (userFurnace.actionsRequiredLowPriority != null) {
                _actionCountLowPriority = _actionCountLowPriority +
                    userFurnace.actionsRequiredLowPriority!;
              }
            }
          }
        });
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _userFurnaceBloc.request(globalState.user.id);

    super.initState();
  }

  Widget build(BuildContext context) {
    return BottomNavigationBar(
      onTap: (index) {
        widget.onIndexChanged(index);
      },
      currentIndex: globalState.selectedHomeIndex,
      type: BottomNavigationBarType.fixed,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.photo_library),
          label: 'Library',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.pending_actions),
          label: 'Actions',
        ),
        BottomNavigationBarItem(
          backgroundColor: widget.invitationCount == 0
              ? globalState.theme.background
              : Colors.amber,
          icon: const Icon(Icons.person_add),
          label: widget.invitationCount == 0
              ? 'Invitations'
              : 'Invitations (${widget.invitationCount})',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.public),
          label: 'Browser',
        ),
      ],
    );
  }
}
