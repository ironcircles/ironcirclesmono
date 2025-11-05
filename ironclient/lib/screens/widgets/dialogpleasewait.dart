import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';

class DialogPleaseWait {
  static Future<void> showSpinner(
    BuildContext context,
    String title,
    String subTitle,
  ) async {
    // flutter defined function
    return showDialog<void>(
        barrierColor: Colors.black.withOpacity(.8),
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => _SystemPadding(
                child: AlertDialog(
              surfaceTintColor: Colors.transparent,
                  backgroundColor: globalState.theme.dialogTransparentBackground,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30.0))),
              title: Center(
                  child: Text(
                title,
                style: TextStyle(color: globalState.theme.bottomIcon),
              )),
              content: DialogWidget(subTitle),
            )));
  }
}

class DialogWidget extends StatefulWidget {
  final String subTitle;
  const DialogWidget(this.subTitle);

  @override
  _DialogWidgetState createState() => _DialogWidgetState();
}

class _DialogWidgetState extends State<DialogWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        //width: 200,
        height: 100,
        child: Column(children: [
          ICText(
            widget.subTitle,
            textScaleFactor: globalState.dialogScaleFactor,
            color: globalState.theme.labelText,
            fontSize: 16,
          ),
          const Padding(padding: EdgeInsets.only(top: 10)),
          Center(child: SpinKitDualRing(color: globalState.theme.spinner, size: 45)),
        ]));
    // child: SpinKitRing(
    //    color: globalState.theme.bottomIcon, lineWidth: 2, size: 30.0));
  }
}

class _SystemPadding extends StatelessWidget {
  final Widget? child;

  const _SystemPadding({Key? key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        //padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        duration: const Duration(milliseconds: 300),
        child: child);
  }
}
