import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class DialogUpload {
  static Future<void> showUploadingBlob(
    BuildContext context,
    String title,
    GlobalEventBloc globalEventBloc,
  ) async {
    // flutter defined function
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          surfaceTintColor: Colors.transparent,
          backgroundColor: globalState.theme.dialogTransparentBackground,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30.0))),
          title: Center(
              child: Text(
            title,
            style: TextStyle(color: globalState.theme.bottomIcon),
          )),
          content: DialogUploadWidget(0, globalEventBloc),
        );
      },
    );
  }
}

class DialogUploadWidget extends StatefulWidget {
  final double percent;
  final GlobalEventBloc globalEventBloc;

  const DialogUploadWidget(
    this.percent,
    this.globalEventBloc,
  );

  @override
  _DialogUploadWidgetState createState() => _DialogUploadWidgetState();
}

class _DialogUploadWidgetState extends State<DialogUploadWidget> {
  double _percent = 0;

  @override
  void initState() {
    super.initState();

    widget.globalEventBloc.progress.listen((percent) {
      _percent = percent;

      if (mounted) {
        setState(() {});

        if (percent == 100) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CircularPercentIndicator(
      radius: 30.0,
      lineWidth: 5.0,
      percent: (_percent / 100),
      center: Text('$_percent%',
          textScaler: const TextScaler.linear(1.0),
          style: TextStyle(color: globalState.theme.progress)),
      progressColor: globalState.theme.progress,
    );
  }
}
