import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/settings/logentryviewer.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';

class LogViewer extends StatefulWidget {
  @override
  _LogViewerState createState() => _LogViewerState();
}

class _LogViewerState extends State<LogViewer> {
  LogBloc _logBloc = LogBloc();
  List<Log> _logs = [];

  @override
  void initState() {
    super.initState();

    //Listen for deleted results arrive
    _logBloc.fetchLogs.listen((logs) {
      if (mounted) {
        setState(() {
          _logs = logs;
        });
      }
    }, onError: (err) {
      debugPrint("ViewUsers.initState: $err");
    }, cancelOnError: false);

    _logBloc.fetchRecent();
  }

  _showStackTrace(Log log) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LogEntryViewer(log: log),
        ));
  }

  TableRow _buildTableRow(Log log) {
    return TableRow(
        //key: ValueKey(item.pk),
        decoration: BoxDecoration(
            color: globalState.theme.tableBackground, border: Border.all()),
        children: [
          TableRowInkWell(
            onTap: () {
              _showStackTrace(log);
            },
            child: SizedBox(
              height: 50,
              //width: 5,
              child: Center(
                child: Text(log.type,
                    style: TextStyle(color: globalState.theme.tableText)),
              ),
            ),
          ),
          TableRowInkWell(
            onTap: () {
              _showStackTrace(log);
            },
            child: SizedBox(
              height: 50,
              child: Center(
                child: Text(
                    log.message.length > 40
                        ? log.message.substring(0, 40)
                        : log.message,
                    style: TextStyle(color: globalState.theme.tableText)),
              ),
            ),
          ),
          /*TableRowInkWell(
            onTap: () {
              _showStackTrace(log);
            },
            child: SizedBox(
              height: 50,
              child: Center(
                child: Text('stacktrace',
                    style:
                    TextStyle(color: globalState.theme.tableText)),
              ),
            ),
          ),

           */
          TableRowInkWell(
              onTap: () {
                _showStackTrace(log);
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: SizedBox(
                  height: 50,
                  child: Center(
                    child: Text(log.timeStamp.toLocal().toString(),
                        style: TextStyle(color: globalState.theme.tableText)),
                  ),
                ),
              )),
        ]); // Pass the);
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
        title: Text("Beta Defect Log",
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
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            scrollDirection: Axis.vertical,
            child: Table(
                children: _logs.map((item) => _buildTableRow(item)).toList())),
        // other arguments
      ),
      floatingActionButton: FloatingActionButton(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(30.0))
        ),
        child: const Icon(Icons.delete),
        onPressed: () {
          LogBloc.deleteAll();
          _logBloc.fetchRecent();

        },
      ),
    );
  }
}
