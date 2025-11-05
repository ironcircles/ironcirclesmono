import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/avatarwidget.dart';

class HamburgerIcon extends StatefulWidget {
  final scaffoldKey;
  final GlobalKey? walkthroughKey;

  const HamburgerIcon({required this.scaffoldKey, this.walkthroughKey});

  @override
  State<StatefulWidget> createState() {
    return HamburgerIconState();
  }
}

class HamburgerIconState extends State<HamburgerIcon> {
  //final bool actionNeeded;
//  final UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();
  GlobalKey walkthroughKey = GlobalKey();

  @override
  void initState() {
    if (widget.walkthroughKey != null) walkthroughKey = widget.walkthroughKey!;

    /*_userFurnaceBloc.userfurnaces.listen((userFurnaces) {
      if (mounted) {
        setState(() {
          _userFurnaces = userFurnaces;
        });
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _userFurnaceBloc.request(globalState.user.id, true);

     */

    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return globalState.updateAvailable && !globalState.isDesktop()
            ? Material(
                    color: globalState.theme.background,
                    //required
                    elevation: 0.0,
                    shape: const CircleBorder(),
                    child: IconButton(
                      color: globalState.theme.background,
                      icon: const Icon(
                        Icons.system_update,
                        color: Colors.pink,
                        size: 30,
                      ),
                      // set your color here
                      onPressed: () {
                        widget.scaffoldKey.currentState.openDrawer();
                      },
                    ))
            : Padding(padding: const EdgeInsets.only(right:8), child: SizedBox(
                width: 42,
                height: 42.0,
                child: InkWell(
                  onTap: () {
                    widget.scaffoldKey.currentState.openDrawer();
                  },
                  child: AvatarWidget(
                      radius: 42,
                      isUser: true,
                      interactive: false,
                      user: globalState.user,
                      userFurnace: globalState.userFurnace!,
                      refresh: _doNothing),
                )))
        /*), IconButton(key: walkthroughKey,
            color: globalState.theme.background,
            icon: Icon(Icons.menu,
                color: globalState.theme.menuIcons), // set your color here
           // ImageIcon(
             // AssetImage("assets/images/small_black.png"),
             //   color: Colors.white),

            onPressed: () {
              widget.scaffoldKey.currentState.openDrawer();
            },
          )*/
        ;
  }

  _doNothing() {}
}
