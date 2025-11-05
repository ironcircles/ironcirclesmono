
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/updatetracker.dart';
import 'package:ironcirclesapp/services/cache/table_updatetracker.dart';


class UpdateTrackerService {
  static get(UpdateTrackerType updateTrackerType) async {
    try {

      return await TableUpdateTracker.read(updateTrackerType);

    } catch (error, trace) {
      LogBloc.insertError(error, trace);
    }
  }

  static put(UpdateTrackerType updateTrackerType, bool value) async {
    try {

      await TableUpdateTracker.upsert(updateTrackerType, value);

    } catch (error, trace) {
      LogBloc.insertError(error, trace);
    }
  }
}
