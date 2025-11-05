import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ironcirclesapp/blocs/metrics_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/metric.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';

class MetricsScreen extends StatefulWidget {
  @override
  _MetricsScreenState createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> {
  final MetricsBloc _bloc = MetricsBloc();
  List<Metric> _metrics = [];

  int _currentSortColumn = 2;
  bool _isSortAsc = false;
  int _subscriberCount = 0;
  int _accountsDeleted = 0;
  int _activeInLastFourteen = 0;
  int _counter = 0;

  @override
  void initState() {
    super.initState();

    ///Listen for metrics to arrive arrive
    _bloc.metricsLoaded.listen((metricsCollection) {
      if (mounted) {
        setState(() {
          _metrics = metricsCollection.metrics;
          _subscriberCount = metricsCollection.subscribedCount;
          _accountsDeleted = metricsCollection.accountsDeleted;
          _activeInLastFourteen = metricsCollection.activeInLastFourteen;
        });
      }
    }, onError: (err) {
      debugPrint("ViewUsers.initState: $err");
    }, cancelOnError: false);

    _bloc.get(globalState.userFurnace!);
  }

  DataRow _buildTableRow(Metric metric) {
    return DataRow(
        //key: ValueKey(item.pk),
        //decoration: BoxDecoration(
        // color: globalState.theme.tableBackground, border: Border.all()),
        cells: [
          DataCell(
            Text(metric.count.toString(),
                style: TextStyle(color: globalState.theme.tableText)),
          ),
          DataCell(Text(
            metric.user == null
                ? ''
                : _counter > 3
                    ? '${metric.user!.username!}\n(${metric.hostedFurnaceName})'
                    : '${metric.user!.id!}\n(${metric.hostedFurnaceId})',
            /*metric.user!.username!.length > 20
                    ? metric.user!.username!.substring(0, 19)
                    : metric.user!.username!,*/
            style: TextStyle(color: globalState.theme.tableText),
          )),
          DataCell(
            Text(
                metric.lastAccessed == null
                    ? ''
                    : '${DateFormat.yMMMd().format(metric.lastAccessed!)} @ ${DateFormat('HH:mm').format(metric.lastAccessed!)}',
                style: TextStyle(color: globalState.theme.tableText)),
          ),
          DataCell(
            Padding(
                padding: const EdgeInsets.only(left: 5),
                child: Text(
                    metric.user == null
                        ? ''
                        : '${DateFormat.yMMMd().format(DateTime.parse(metric.user!.created!).toLocal())} @ ${DateFormat('HH:mm').format(DateTime.parse(metric.user!.created!).toLocal())}',
                    style: TextStyle(color: globalState.theme.tableText))),
          ),
          DataCell(
            Text(
              metric.recentMessageCount!
                  .toString(), //log.timeStamp.toLocal().toString(),
              style: TextStyle(color: globalState.theme.tableText),
            ),
          ),
          DataCell(
            Text(
              metric.models!.length > 50
                  ? metric.models!.substring(0, 49)
                  : metric.models!, //log.timeStamp.toLocal().toString(),
              style: TextStyle(color: globalState.theme.tableText),
            ),
          ),
          DataCell(
            Text(
              metric.mostRecentBuild!
                  .toString(), //log.timeStamp.toLocal().toString(),
              style: TextStyle(color: globalState.theme.tableText),
            ),
          ),
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
          title: Text("Metrics",
              style: ICTextStyle.getStyle(context: context, 
                  color: globalState.theme.textTitle,
                  fontSize: ICTextStyle.appBarFontSize)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        //drawer: NavigationDrawer(),
        body: /*SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            scrollDirection: Axis.vertical,
            child:SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              scrollDirection: Axis.vertical,
              child: Padding(
                  padding: EdgeInsets.only(left: 10, right: 10),
                  child:*/
            Column(children: [
          InkWell(                                        highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              onTap: () {
                setState(() {
                  _counter = _counter + 1;
                });
              },
              child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: ICText(
                    "Subscription count: $_subscriberCount",
                  ))),
          _counter >= 5
              ? Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: ICText(
                    "Active last 2 weeks: $_activeInLastFourteen",
                  ))
              : Container(),
          Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: ICText(
                "Accounts deleted: $_accountsDeleted",
              )),
          Expanded(
              child: InteractiveViewer(
                  constrained: false,
                  child: DataTable(
                    columns: [
                      DataColumn(
                        label: const Text('#',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        onSort: (columnIndex, _) {
                          setState(() {
                            _currentSortColumn = columnIndex;
                            if (_isSortAsc) {
                              _metrics
                                  .sort((a, b) => b.count!.compareTo(a.count!));
                            } else {
                              _metrics
                                  .sort((a, b) => a.count!.compareTo(b.count!));
                            }
                            order();

                            _isSortAsc = !_isSortAsc;
                          });
                        },
                      ),
                      DataColumn(
                        label: const Text('user',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        onSort: (columnIndex, _) {
                          setState(() {
                            _currentSortColumn = columnIndex;
                            if (_isSortAsc) {
                              _metrics.sort((a, b) => b.user!.username!
                                  .compareTo(a.user!.username!));
                            } else {
                              _metrics.sort((a, b) => a.user!.username!
                                  .compareTo(b.user!.username!));
                            }
                            order();

                            _isSortAsc = !_isSortAsc;
                          });
                        },
                      ),
                      DataColumn(
                        label: const Text('accessed',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        onSort: (columnIndex, _) {
                          setState(() {
                            _currentSortColumn = columnIndex;
                            if (_isSortAsc) {
                              _metrics.sort((a, b) =>
                                  b.lastAccessed!.compareTo(a.lastAccessed!));
                            } else {
                              _metrics.sort((a, b) =>
                                  a.lastAccessed!.compareTo(b.lastAccessed!));
                            }
                            order();

                            _isSortAsc = !_isSortAsc;
                          });
                        },
                      ),
                      DataColumn(
                        label: const Text('created',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        onSort: (columnIndex, _) {
                          setState(() {
                            _currentSortColumn = columnIndex;
                            if (_isSortAsc) {
                              _metrics.sort(
                                  (a, b) => b.created!.compareTo(a.created!));
                            } else {
                              _metrics.sort(
                                  (a, b) => a.created!.compareTo(b.created!));
                            }
                            order();

                            _isSortAsc = !_isSortAsc;
                          });
                        },
                      ),
                      DataColumn(
                        label: const Text('posts',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        onSort: (columnIndex, _) {
                          setState(() {
                            _currentSortColumn = columnIndex;
                            if (_isSortAsc) {
                              _metrics.sort((a, b) => b.recentMessageCount!
                                  .compareTo(a.recentMessageCount!));
                            } else {
                              _metrics.sort((a, b) => a.recentMessageCount!
                                  .compareTo(b.recentMessageCount!));
                            }

                            order();

                            _isSortAsc = !_isSortAsc;
                          });
                        },
                      ),
                      DataColumn(
                        label: const Text('models',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        onSort: (columnIndex, _) {
                          setState(() {
                            _currentSortColumn = columnIndex;
                            if (_isSortAsc) {
                              _metrics.sort(
                                  (a, b) => b.models!.compareTo(a.models!));
                            } else {
                              _metrics.sort(
                                  (a, b) => a.models!.compareTo(b.models!));
                            }

                            order();

                            _isSortAsc = !_isSortAsc;
                          });
                        },
                      ),
                      DataColumn(
                        label: const Text('latest build',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        onSort: (columnIndex, _) {
                          setState(() {
                            _currentSortColumn = columnIndex;
                            if (_isSortAsc) {
                              _metrics.sort((a, b) => b.mostRecentBuild!
                                  .compareTo(a.mostRecentBuild!));
                            } else {
                              _metrics.sort((a, b) => a.mostRecentBuild!
                                  .compareTo(b.mostRecentBuild!));
                            }

                            order();

                            _isSortAsc = !_isSortAsc;
                          });
                        },
                      ),
                    ],
                    /*columnWidths: {
                        0: FlexColumnWidth(1),
                        1: FlexColumnWidth(4),
                        2: FlexColumnWidth(4),
                        3: FlexColumnWidth(2),
                      },

                       */
                    rows: _metrics.map((item) => _buildTableRow(item)).toList(),
                    columnSpacing: 5,
                    sortColumnIndex: _currentSortColumn,
                    sortAscending: _isSortAsc,
                  ))),

          // other arguments
        ])); //));
  }

  order() {
    for (int i = 0; i < _metrics.length; i++) {
      _metrics[i].count = _metrics.length - i;
    }
  }
}
