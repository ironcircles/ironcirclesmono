/*import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class DialogCaptureMethod2 {
  //static AuthenticationBloc _authBloc = AuthenticationBloc();
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  static selectCaptureMethodPopup(
    BuildContext context,
    String? username,
    Function success,
  ) async {
    //bool _validPassword = false;
    //TextEditingController _password = TextEditingController();

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) => Theme(
      data: ThemeData(
          dialogBackgroundColor: globalState.theme.dialogBackground),
      child:_SystemPadding(
        child: AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0))),
          title: Text(
            "What would you like to post?", textScaleFactor: globalState.menuScaleFactor,
            style: TextStyle(fontSize: 16, color: globalState.theme.textTitle),
          ),
          contentPadding: const EdgeInsets.all(10.0),
          content: ItemsToPost(scaffoldKey, success),
          actions: <Widget>[
            /*new FlatButton(
                child: const Text('CANCEL'),
                onPressed: () {
                  Navigator.pop(context);
                }),*/

          ],
        ),
      )),
    );
  }
}

class _SystemPadding extends StatelessWidget {
  final Widget? child;

  _SystemPadding({Key? key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        //padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        duration: const Duration(milliseconds: 300),
        child: child);
  }
}

class ItemsToPost extends StatefulWidget {
  final scaffoldKey;
  final Function success;
  //final TextEditingController controller;

  ItemsToPost(
    this.scaffoldKey,
    this.success,
    //this.controller,
    /* this.circleObject,
      this.showAvatar,
      this.showDate,
      this.showTime,
      this.messageColor,
      this.userFurnace,
      this.copy,
      this.share,*/
  );

  ItemsToPostState createState() => ItemsToPostState();
}

class ItemsToPostState extends State<ItemsToPost> {
  //bool _showPassword = false;

  @override
  void initState() {
    super.initState();
  }

  Widget _row(String text, IconData iconData, String selection) {
    return InkWell(
        onTap: () {
          Navigator.pop(context);
          widget.success(selection);
        },
        child: Padding(
            padding: EdgeInsets.only(right: 0, top: 10, bottom: 5, left: 25),
            child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    iconData,
                    color: globalState.theme.bottomIcon,
                    size: 35,
                  ),
                  Padding(
                      padding: EdgeInsets.only(
                          right: 10,)),
                  Text(
                    text, textScaleFactor: globalState.menuScaleFactor,
                    style:
                        TextStyle(color: globalState.theme.bottomIcon, fontSize: 16),
                  ),
                ])));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        //width: 200,
        height: 100,
        child: Scaffold(
          backgroundColor: globalState.theme.dialogBackground,
          key: widget.scaffoldKey,
          resizeToAvoidBottomInset: true,
          body: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _row('Photo', Icons.camera,
                    CircleObjectType.CIRCLEIMAGE),
                _row('Record video', Icons.videocam,
                    CircleObjectType.CIRCLEVIDEO),
              ]),
        ));
  }


}

 */
