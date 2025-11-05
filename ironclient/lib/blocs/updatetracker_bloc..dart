
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/models/updatetracker.dart';
import 'package:ironcirclesapp/services/updatetracker_service.dart';

class UpdateTrackerBloc {
  static UserFurnaceBloc userFurnaceBloc = UserFurnaceBloc();

  static get(UpdateTrackerType updateTrackerType) async {
    try {
      UpdateTracker retValue =
          await UpdateTrackerService.get(updateTrackerType);
      return retValue;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
    }
  }

  static put(UpdateTrackerType updateTrackerType, bool value) async {
    try {
      await UpdateTrackerService.put(updateTrackerType, value);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
    }
  }

  /*
  static checkForWallCircles() async {
    try {
      if (await get(UpdateTrackerType.wall).value == true) {
        return;
      }

      List<UserFurnace> furnaces =
          await userFurnaceBloc.requestConnected(globalState.user.id);

      List<UserFurnace> ownerAdmin = furnaces
          .where((furnace) =>
              furnace.role == Role.OWNER ||
              furnace.role == Role.ADMIN ||
              furnace.role == Role.IC_ADMIN)
          .toList();

      if (ownerAdmin.isEmpty) {
        await UpdateTrackerBloc.put(UpdateTrackerType.wall, true);
      } else {

          for (UserFurnace furnace in ownerAdmin) {



          }


          await UpdateTrackerBloc.put(UpdateTrackerType.wall, false);

      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
    }
  }

   */
}
