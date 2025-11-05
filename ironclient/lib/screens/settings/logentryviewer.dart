import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';

class LogEntryViewer extends StatefulWidget {
  final Log log;

  const LogEntryViewer({required this.log});

  @override
  _LogEntryViewerState createState() => _LogEntryViewerState();
}

class _LogEntryViewerState extends State<LogEntryViewer> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: globalState.theme.background,
        appBar: AppBar(
          backgroundColor: globalState.theme.appBar,
          iconTheme: IconThemeData(
            color: globalState.theme.menuIcons, //change your color here
          ),
          elevation: 0.1,
          title: Text("Stack Trace",
              style: ICTextStyle.getStyle(context: context, 
                  color: globalState.theme.textTitle,
                  fontSize: ICTextStyle.appBarFontSize)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        //drawer: NavigationDrawer(),
        body: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
                constraints: const BoxConstraints(),
                child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ICSelectableText('${widget.log.message}\n\n',
                              color: globalState.theme.tableText),
                          ICSelectableText(widget.log.stack,
                              color: globalState.theme.tableText)
                        ]))
                // other arguments
                )));
  }
}
