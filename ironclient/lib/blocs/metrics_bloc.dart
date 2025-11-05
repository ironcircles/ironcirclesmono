import 'dart:async';

import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/metric.dart';
import 'package:ironcirclesapp/models/userfurnace.dart';
import 'package:ironcirclesapp/services/metrics_service.dart';
import 'package:rxdart/rxdart.dart';

class MetricsBloc {
  final MetricsService _service = MetricsService();

  final _metricsLoaded = PublishSubject<MetricsCollection>();
  Stream<MetricsCollection> get metricsLoaded => _metricsLoaded.stream;

  get(UserFurnace userFurnace) async {
    try {
      MetricsCollection metricsCollection  = await _service.get(userFurnace);

      metricsCollection.metrics.sort((a,b) => b.lastAccessed!.compareTo(a.lastAccessed!));

      for(int i = 0; i<metricsCollection.metrics.length; i++){
        metricsCollection.metrics[i].count = metricsCollection.metrics.length-i;
      }

      _metricsLoaded.sink.add(metricsCollection);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      //debugPrint('BacklogBloc.get + $error');
      _metricsLoaded.sink.addError(error);
    }
  }

  dispose() async {
    await _metricsLoaded.drain();
    _metricsLoaded.close();
  }
}
