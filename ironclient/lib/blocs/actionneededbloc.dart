import 'dart:async';

import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/actionrequired.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/networkrequest.dart';
import 'package:ironcirclesapp/services/actionneeded_service.dart';
import 'package:ironcirclesapp/services/cache/table_actionrequired.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:rxdart/rxdart.dart';

class ActionNeededBloc {
  /*
  final UserCircleBloc userCircleBloc;  //= UserCircleBloc();


  ActionNeededBloc({required this.userCircleBloc});

   */

  final ActionNeededService _actionNeededService = ActionNeededService();

  final _actionRequired = PublishSubject<List<ActionRequired>>();
  Stream<List<ActionRequired>> get actionRequired => _actionRequired.stream;

  final _circleObjects = PublishSubject<List<CircleObject>>();
  Stream<List<CircleObject>> get circleObjects => _circleObjects.stream;

  final _newerCircleObjects = PublishSubject<List<CircleObject>>();
  Stream<List<CircleObject>> get newCircleObjects => _newerCircleObjects.stream;

  final _saveResults = PublishSubject<CircleObject>();
  Stream<CircleObject> get saveResults => _saveResults.stream;

  final _circleObjectDeleted = PublishSubject<CircleObject>();
  Stream<CircleObject> get circleObjectDeleted => _circleObjectDeleted.stream;

  final _circleObjectsDeleted = PublishSubject<List<CircleObject>>();
  Stream<List<CircleObject>> get circleObjectsDeleted =>
      _circleObjectsDeleted.stream;

  /// Initial load from a screen
  loadActionRequired(List<UserFurnace> userFurnaces) async {
    try {
      _sinkActionRequired(userFurnaces); //just hitting sqllite, async is fine

      //no need to hit server.  Action required objects are returned with UserCircles fetch.
      //intentionally not resinking the cache
      //_userCircleBloc.fetchUserCircles(userFurnaces, true);

      // _sinkActionRequired(userFurnaces);
    } catch (error, trace) {
      //debugPrint("ActionRequiredBloc.loadActionRequired: " + error.toString());
      LogBloc.insertError(error, trace);

      _circleObjects.sink.addError(error);
    }
  }

  /// Find action required to match network request
  void dismissNetworkNotification(
      List<UserFurnace> userFurnaces, NetworkRequest request) async {
    try {
      for (UserFurnace userFurnace in userFurnaces) {
        if (!userFurnace.connected!) continue;

        List<ActionRequired> actionRequireds =
            await TableActionRequiredCache.read(userFurnace);

        for (ActionRequired ar in actionRequireds) {
          if (ar.networkRequest != null) {
            if (ar.networkRequest!.id == request.id) {
              dismiss(ar);
            }
          }
        }
      }
    } catch (error, trace) {
      //debugPrint('ActionRequiredBloc._sinkActionRequired: $error');
      LogBloc.insertError(error, trace);
      rethrow;
    }
  }

  /// Sink all from cache
  void _sinkActionRequired(List<UserFurnace> userFurnaces) async {
    List<ActionRequired> retValue = [];

    try {
      //grab a list of locally cached ActionRequired for this user
      for (UserFurnace userFurnace in userFurnaces) {
        if (!userFurnace.connected!) continue;

        List<ActionRequired> actionRequireds =
            await TableActionRequiredCache.read(userFurnace);

        //add password help first
        List<ActionRequired> sorted = [];

        for (ActionRequired ar in actionRequireds) {
          if (ar.alertType == ActionRequiredAlertType.HELP_WITH_RESET) {
            sorted.add(ar);
          }
        }

        for (ActionRequired ar in actionRequireds) {
          if (ar.alertType != ActionRequiredAlertType.HELP_WITH_RESET) {
            sorted.add(ar);
          }
        }

        retValue.addAll(sorted);
      }
      _actionRequired.sink.add(retValue);
    } catch (error, trace) {
      //debugPrint('ActionRequiredBloc._sinkActionRequired: $error');
      LogBloc.insertError(error, trace);
      rethrow;
    }

    //return actionRequired;
  }

  removeChangeGenerated(List<ActionRequired> actionRequireds) async {
    try {
      for (ActionRequired actionRequired in actionRequireds) {
        if (actionRequired.alertType ==
            ActionRequiredAlertType.CHANGE_GENERATED) {
          await TableActionRequiredCache.delete(actionRequired.id!);
        }
      }
    } catch (error, trace) {
      //debugPrint('ActionRequiredBloc.removePasswordRequired: $error');
      LogBloc.insertError(error, trace);
      _actionRequired.sink.addError(error);
    }
  }

  /// Initial load from a screen
  loadCircleObjects(List<UserFurnace> userFurnaces) async {
    try {
      //List<CircleObject> circleObjects;
      //DateTime lastAccessed;

      //send the cached results first in case there is no internet
      _sinkCircleObjectsCache(userFurnaces);

      //NOTE: CONSUMING SCREEN SHOULD HAVE A LISTENER FOR CIRCLEOBJECTS AND CALL THIS AGAIN
    } catch (error, trace) {
      // debugPrint(
      // "CircleObjectCrosscircleBloc.loadCircleObjects: " + error.toString());
      LogBloc.insertError(error, trace);
      _circleObjects.sink.addError(error);
    }
  }

  dismiss(ActionRequired actionRequired) async {
    try {
      await ActionNeededService.dismiss(actionRequired);
    } catch (error, trace) {
      // debugPrint(
      // "CircleObjectCrosscircleBloc.loadCircleObjects: " + error.toString());
      LogBloc.insertError(error, trace);
      _circleObjects.sink.addError(error);
    }
  }

  /// Sink top 500 from cache
  void _sinkCircleObjectsCache(List<UserFurnace> userFurnaces) async {
    // DateTime retValue;

    try {
      List<UserCircleCache> userCircles = [];
      // List<CircleObjectCache> sinkList =[];

      List<String> circles = [];

      //List<CircleObject> allSinkValues = [];

      for (UserFurnace userFurnace in userFurnaces) {
        if (!userFurnace.connected!) continue;

        List<UserCircleCache> furnaceCircles =
            await TableUserCircleCache.readAllForUserFurnace(
                userFurnace.pk, userFurnace.userid);

        for (UserCircleCache userCircleCache in furnaceCircles) {
          //add the furnace hitchhiker
          userCircleCache.furnaceObject = userFurnace;
          circles.add(userCircleCache.circle!);
        }

        userCircles.addAll(furnaceCircles);
      }

      List<CircleObject> sinkValues = await _actionNeededService
          .fetchCircleObjectActionRequired(circles, userCircles);

      _circleObjects.sink.add(sinkValues);
    } catch (error, trace) {
      //debugPrint('ActionNeeded._sinkCircleObjectsCache: $error');
      LogBloc.insertError(error, trace);
      rethrow;
    }
  }

  dispose() async {
    await _circleObjects.drain();
    _circleObjects.close();

    await _newerCircleObjects.drain();
    _newerCircleObjects.close();

    await _saveResults.drain();
    _saveResults.close();

    await _circleObjectDeleted.drain();
    _circleObjectDeleted.close();

    await _circleObjectsDeleted.drain();
    _circleObjectsDeleted.close();

    await _actionRequired.drain();
    _actionRequired.close();
  }
}
