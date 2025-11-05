import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy.dart';
import 'package:ironcirclesapp/models/circlelastlocalupdate.dart';
import 'package:ironcirclesapp/models/circleobjectreaction.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/replyobject.dart';
import 'package:ironcirclesapp/models/replyobjectcache.dart';
import 'package:ironcirclesapp/models/violation.dart';
import 'package:ironcirclesapp/services/cache/table_circlelastlocalupdate.dart';
import 'package:ironcirclesapp/services/cache/table_circleobject.dart';
import 'package:ironcirclesapp/services/cache/table_replyobject.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/cache/table_userfurnace.dart';
import 'package:ironcirclesapp/services/replyobject_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

class SaveError {
  ReplyObject replyObject;
  String errorMessage;

  SaveError({required this.replyObject, required this.errorMessage});
}

class ReplyObjectBloc {

  final GlobalEventBloc globalEventBloc;
  final UserCircleBloc userCircleBloc;

  ReplyObjectBloc({ required this.globalEventBloc, required this.userCircleBloc });

  final _replyObjectService = ReplyObjectService();

  final _memCacheReplyObjects = PublishSubject<List<ReplyObject>>();
  Stream<List<ReplyObject>> get memCacheReplyObjects => _memCacheReplyObjects.stream;

  final _replyObjects = PublishSubject<List<ReplyObject>>();
  Stream<List<ReplyObject>> get replyObjects => _replyObjects.stream;

  final _olderReplyObjects = PublishSubject<List<ReplyObject>>();
  Stream<List<ReplyObject>> get olderReplyObjects => _olderReplyObjects.stream;

  final _newerReplyObjects = PublishSubject<List<ReplyObject>?>();
  Stream<List<ReplyObject>?> get newerReplyObjects => _newerReplyObjects.stream;

  final _replyObjectsDeleted = PublishSubject<List<ReplyObject>>();
  Stream<List<ReplyObject>> get replyObjectsDeleted => _replyObjectsDeleted.stream;

  final _saveResults = PublishSubject<ReplyObject>();
  Stream<ReplyObject> get saveResults => _saveResults.stream;

  final _saveFailed = PublishSubject<SaveError>();
  Stream<SaveError> get saveFailed => _saveFailed.stream;

  final _replyObjectDeleted = PublishSubject<String>();
  Stream<String> get replyObjectDeleted => _replyObjectDeleted.stream;

  sinkCircleObjectSaveError(SaveError error) {
    _saveFailed.sink.add(error);
  }

  sinkCircleObjectSave(ReplyObject sinkValue) {
    _saveResults.sink.add(sinkValue);
  }

  makeReplyObject(UserFurnace userFurnace, ReplyObject replyObject) async {

  }

  initialLoad(int amount, String userID) async {
    try {

      // List<Circle> cachedCircles = await TableCircleCache.readAll();
      // cachedCircles.removeWhere((element) => element.type != CircleType.WALL);

      List<Map> results = await TableReplyObjectCache.readAmountMostRecent(amount);

      if (results.isNotEmpty) {
        List<ReplyObject>? sinkValues =
        ReplyObjectService.convertFromCachePerformant(
            globalEventBloc, results, userID);

        debugPrint("returning replyObjects from sinkvalues from cache");
        //_replyObjects.sink.add(sinkValues);
        _memCacheReplyObjects.sink.add(sinkValues);

        //retValue = results.length;
      } else {
        debugPrint("returning empty replyObjects list from cache");
        //_replyObjects.sink.add([]);
        _memCacheReplyObjects.sink.add([]);
      }

    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("ReplyObjectBloc.initialLoad: $error");
      rethrow;
    }
  }

  Future<int> _sinkCache(String circleObjectID, String userID, {int amount = 50}) async {
    int retValue = 0;

    try {

      List<Map> results = await TableReplyObjectCache.readAmount(circleObjectID, amount);

      if (results.isNotEmpty) {
        List<ReplyObject>? sinkValues =
            ReplyObjectService.convertFromCachePerformant(
              globalEventBloc, results, userID);

        debugPrint("returning replyObjects from sinkvalues from cache");
        _replyObjects.sink.add(sinkValues);

        retValue = results.length;
      } else {
        debugPrint("returning empty replyObjects list from cache");
        _replyObjects.sink.add([]);
      }

    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('WallReplyBloc._sinkCache: $error');
      rethrow;
    }

    return retValue;
  }

  Future<List<ReplyObject>> updateCacheFurnace(UserFurnace userFurnace, String circleObjectID, String circleID, bool upsert, bool initialSink, int amount) async {
    List<ReplyObject> replyObjects= [];
    List<ReplyObject> decryptedObjects = [];
    try {

      CircleLastLocalUpdate? circleLastLocalUpdate =
          await TableCircleLastLocalUpdate.read(circleID);


      if (initialSink ||
          circleLastLocalUpdate == null) {
        replyObjects = await _replyObjectService.fetchReplyObjects(circleID, userFurnace, circleObjectID, amount);

        if (replyObjects.isNotEmpty) {
              try {
                decryptedObjects = await updateCache(
                  userFurnace, circleObjectID, circleID, replyObjects, upsert
                );

                //remove deletedobjects
                List<ReplyObject> deletedObjects = decryptedObjects
                    .where((element) => element.type == 'deleted')
                    .toList();

                if (deletedObjects.isNotEmpty) {
                  TableReplyObjectCache.deleteList(globalEventBloc, deletedObjects);
                  _replyObjectsDeleted.sink.add(deletedObjects);
                }
              } catch (err, trace) {
                debugPrint('ReplyObjectBloc.updateCacheFurnace: $err');
                debugPrint('$trace');
              }
            }
        _newerReplyObjects.sink.add(decryptedObjects);
        globalEventBloc.broadcastMemCacheReplyObjectsAdd(decryptedObjects);
        //_replyObjects.sink.add(decryptedObjects);
      } else {
        ///CO-REMOVE, update badge
        await requestNewerThan(circleID, circleObjectID, userFurnace, circleLastLocalUpdate, initialSink);
       // await requestNewerThan(circleID, circleObjectID, userFurnace, circleLastLocalUpdate, initialSink);
        //   ///CO-REMOVE
        //   List<ReplyObject> replyObjects =
        //     await _replyObjectService.fetchNewerThan(circleObjectID,
        //       circleID, userFurnace, circleLastLocalUpdate.lastFetched!);
        //
        //   return replyObjects;
      }

      //return decryptedObjects;


      // CircleLastLocalUpdate? circleLastLocalUpdate =
      //     await TableCircleLastLocalUpdate.read(circleID);
      //
      // if (circleLastLocalUpdate == null) {
      //   debugPrint('_replyObjectService.fetchReplyObjects fetch objects: ${DateTime.now()}');
      //
      //   //replyObjects = await _replyObjectService.fetchReplyObjects(circleID, circleObjectID, userFurnace, amount);
      //
      //   //_replyObjectService.getReplies(userFurnace, circleObject)
      //
      //   debugPrint('_replyObjectService.fetchReplyObjects fetched: ${DateTime.now()}');
      //
      //   if (replyObjects.isNotEmpty) {
      //     try {
      //       decryptedObjects = await updateCache(
      //         userFurnace, circleObjectID, circleID, replyObjects, upsert
      //       );
      //     } catch (err, trace) {
      //       debugPrint('ReplyObjectBloc.updateCacheFurnace: $err');
      //       debugPrint('$trace');
      //     }
      //   }
      //
      //   if (decryptedObjects.isEmpty) {
      //     return [];
      //   } else {
      //     return decryptedObjects;
      //     // if (updateCircleLastAccessed) {
      //     //   circleLastLocalUpdate = CircleLastLocalUpdate(
      //     //       circleID: circleID,
      //     //       lastFetched: decryptedObjects[0].lastUpdate!);
      //     //   circleLastLocalUpdate.upsert();
      //     // }
      //   }
      // } else {
      //   //await requestNewerThan(circleID, circleObjectID, userFurnace, circleLastLocalUpdate, initialSink);
      //
      //   // if (initialSink) {
      //   //   sinkCacheNewerThan(circleObjectID, circleLastLocalUpdate.lastFetched!);
      //   // }
      //
      //   ///CO-REMOVE
      //   List<ReplyObject> replyObjects =
      //     await _replyObjectService.fetchNewerThan(circleObjectID,
      //       circleID, userFurnace, circleLastLocalUpdate.lastFetched!);
      //
      //   return replyObjects;
      // }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('ReplyObjectBloc.updateCacheFurnace: $error');
    }
    return decryptedObjects;
  }

  getReplies(bool initialSync, UserFurnace userFurnace, CircleObject circleObject, UserCircleCache userCircleCache) async {
    try {
      ///send the cached results first in case there is no internet
      if (initialSync) {
        debugPrint("initial sink, sinking cache");
        await _sinkCache(circleObject.id!, userFurnace.userid!);
      }

      bool upsert = true;

      ///fetch replies from API
      //List<ReplyObject> replies = await _replyObjectService.getReplies(userFurnace, circleObject);
      //List<ReplyObject> replies =
      await updateCacheFurnace(userFurnace, circleObject.id!, circleObject.circle!.id!//userCircleCache.circle!
          , upsert, initialSync, 50);

      //_replyObjects.sink.add(replies);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectBloc.getReplyObjects: $error");
      _replyObjects.sink.addError(error);
    }
  }

  /// Pulls old items
  requestOlderThan(CircleObject circleObject,
      String circleID, UserFurnace userFurnace, DateTime created) async {
    try {
      ///Are there any more in the database?
      List<Map> cachedObjects = await TableReplyObjectCache.readOlderThanMap(
        [circleObject.id!], 200, created);

      if (cachedObjects.isNotEmpty) {
        List<ReplyObject>? sinkValues = ReplyObjectService.convertFromCachePerformant(globalEventBloc, cachedObjects, userFurnace.userid!);

        _olderReplyObjects.sink.add(sinkValues);
      }

      if (cachedObjects.length < 200) {
        ///If there is less than 200, then we need to pull from the server
        List<ReplyObject>? serverObjects = await _replyObjectService.fetchOlderThan(circleObject.id!, circleID, userFurnace, created);

        //did we find anything?
        if (serverObjects.isNotEmpty) {
          //update the cache
          serverObjects = await updateCache(userFurnace, circleObject.id!, circleID, serverObjects, true);
        }

        ///sink even if empty to let the ui to know to not to ask repeatedly
        _olderReplyObjects.sink.add(serverObjects);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("WallReplyBloc.requestOlderThan: $error");
      _olderReplyObjects.sink.addError(error);
    }
  }

  requestNew(String circleObjectID, String circleID, UserFurnace userFurnace,
      //bool updateCircleLastAccessed,
      //bool updateBadge,
      bool initialSink) async {
    try {
      UserCircleCache userCircleCache =
      await TableUserCircleCache.readUserCircleCacheByCircleAndUser(
          circleID, userFurnace.userid!);

      CircleLastLocalUpdate? circleLastLocalUpdate =
          await CircleLastLocalUpdate.read(userCircleCache.circle!);

      if (circleLastLocalUpdate != null)
        await requestNewerThan(circleID, circleObjectID, userFurnace, circleLastLocalUpdate, initialSink);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("WallRepliesBloc.requestNew: $error");
      _newerReplyObjects.sink.addError(error);
    }
  }

  /// Update cache from a collection of replyobjects
  Future<List<ReplyObject>> updateCache(UserFurnace userFurnace, String circleObjectID,
      String circleID, List<ReplyObject> replyObjects, bool upsert,
      ) async {
    List<ReplyObject> decryptedObjects = [];
    List<ReplyObjectCache> cache = [];

    try {

      List<ReplyObject> markDelivered = [];
      markDelivered.addAll(replyObjects);

      if (replyObjects.isEmpty) return replyObjects;

      String userCircleID = await TableUserCircleCache.getUserCircleID(
        userFurnace.userid!, circleID);

      if (userCircleID.isEmpty) {
        debugPrint('userCircleID borked');
      } else {
        UserCircleCache userCircleCache =
        await TableUserCircleCache.read(userCircleID);

        //if forcecache == false
        List<ReplyObject> filteredObjects = replyObjects.where((element) => (element.type != 'deleted')).toList();

        if (filteredObjects.isNotEmpty) {
          DateTime start = filteredObjects
              .elementAt(filteredObjects.length - 1)
              .lastUpdate!;

          cache = await TableReplyObjectCache.readForward(circleObjectID, start);

          if (cache.isNotEmpty) {
            for (ReplyObjectCache replyObjectCache in cache) {
              replyObjects.removeWhere((element) =>
              element.seed == replyObjectCache.seed &&
                  element.lastUpdate == replyObjectCache.lastUpdate &&
                  element.refreshNeeded == false);
            }
          }
        }

        //There is nothing so return
        if (replyObjects.isEmpty) {
          ///is this an emoji only change?

          if (cache.isNotEmpty) {
            List<ReplyObject> alreadyCached = _convertFromCache(cache);

            return alreadyCached;
          } else {
            return replyObjects;
          }
        }

        //remove deletedobjects
        List<ReplyObject> deletedObjects = replyObjects
            .where((element) => element.type == 'deleted')
            .toList();

        if (deletedObjects.isNotEmpty) {
          TableReplyObjectCache.deleteList(globalEventBloc, deletedObjects);
          _replyObjectsDeleted.sink.add(deletedObjects);
        }

        Iterable<ReplyObject> notDeleted = replyObjects.where((replyObject) => replyObject.type != 'deleted' );

        if (notDeleted.isNotEmpty) {
          decryptedObjects = await ForwardSecrecy.decryptReplyObjects(
            userFurnace.userid!,
            circleID,
            notDeleted.toList(),
          );

          _retryFailedObjects(userFurnace, userCircleCache, decryptedObjects);

          if (upsert) {
            await TableReplyObjectCache.upsertListofObjects(
              userFurnace.userid!, decryptedObjects, //markRead: markRead
            );
            ForwardSecrecy.ratchetReceiverKey(
              userFurnace, circleID, userCircleID,
              circleObjects: []);
          } else {
            try {
              await TableReplyObjectCache.insertListofObjects(
                userFurnace.userid!, decryptedObjects,
                //markRead: markRead
              );
            } catch (err) {
              debugPrint('$err');

              //insert failed, force an upsert.  If it failed, it's likely due to a duplicate seed
              await TableReplyObjectCache.upsertListofObjects(
                  userFurnace.userid!, decryptedObjects);
            }
          }
        }

        debugPrint('end decryption.  start caching:  ${DateTime.now()}');

        ///other function here about adding user to global state.members???
      }

      // if (markDelivered.isNotEmpty) {
      //   _circleObjectService.markDelivered(userFurnace, markDelivered);
      // }

    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('ReplyObjectBloc._updateCache: $error');

      rethrow;
    }

    return decryptedObjects;
  }

  requestNewerThan(
      String circleID,
      String circleObjectID,
      UserFurnace userFurnace,
      CircleLastLocalUpdate circleLastLocalUpdate,
      // bool updateBadge,
      // bool updateCic
      bool initialSink,
      ) async {
    try {

      if (initialSink) {
        sinkCacheNewerThan(circleObjectID, circleLastLocalUpdate.lastFetched!);
      }

      ///CO-REMOVE
      List<ReplyObject> replyObjects =
          await _replyObjectService.fetchNewerThan(circleObjectID,
            circleID, userFurnace, circleLastLocalUpdate.lastFetched!);

      if (replyObjects.isNotEmpty) {
        List<ReplyObject>? decryptedObjects = await updateCache(userFurnace, circleObjectID, circleID, replyObjects, true);

        if (decryptedObjects.isNotEmpty) {
          _newerReplyObjects.sink.add(decryptedObjects);
          globalEventBloc.broadcastMemCacheReplyObjectsAdd(decryptedObjects);
        }
      }

      // decryptedObjects = await updateCache(
      //     userFurnace, circleObjectID, circleID, replyObjects, upsert
      // );

      // _newerReplyObjects.sink.add(replyObjects);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("WallReplyBloc.requestNewerThan: $error");
      _newerReplyObjects.sink.addError(error);
    }
  }

  ///Convert a ReplyObjectCache list to a ReplyObject list
  List<ReplyObject> _convertFromCache(List<ReplyObjectCache> results) {
    List<ReplyObject> convertValue = [];

    //convert the cache to replyobjects
    for (var replyObjectCache in results) {
      Map<String, dynamic>? decode;

      try {
        decode = json.decode(replyObjectCache.replyObjectJson!);

        ReplyObject replyObject = ReplyObject.fromJson(decode!);

        convertValue.add(replyObject);
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
        debugPrint("WallReplyBloc._convertFromCache: $err");
      }
    }
    return convertValue;
  }

  /// Sink from cache
  Future<int> sinkCacheNewerThan(String circleObjectID, DateTime lastCreated) async {
    int retValue = 0;

    try {
      List<Map> results = await TableReplyObjectCache.readNewerThanMap(circleObjectID, lastCreated);

      if (results.isNotEmpty) {
        List<ReplyObject>? sinkValues =
        ReplyObjectService.convertFromCachePerformant(
              globalEventBloc, results, globalState.user.id!);

        _newerReplyObjects.sink.add(sinkValues);

        retValue = results.length;
      } else {
        _newerReplyObjects.sink.add([]);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("WallReplyBloc._sinkCacheNewerThan: $error");
      rethrow;
    }
    return retValue;
  }

  saveReplyObject(
      GlobalEventBloc globalEventBloc,
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      ReplyObject replyObject,
      ) async {
    try {
      await _saveReplyObject(globalEventBloc, userFurnace, userCircleCache, replyObject);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
    }
  }

  _saveReplyObject(
      GlobalEventBloc globalEventBloc,
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      ReplyObject replyObject,
      ) async {
    try {
      ReplyObject sinkValue;

      replyObject.emojiOnly ??= false;

      if (replyObject.seed == null) {
        replyObject.seed = const Uuid().v4();

        debugPrint(
            'WallReplyBloc before broadcast: seed: ${replyObject.seed!},  userid: ${userFurnace.userid!}, circleObject: ${replyObject.circleObjectID},  ${DateTime.now()} ');

        // globalEventBloc.addGenericObject(circleObject.seed!);
        globalEventBloc.broadcastReplyObject([replyObject]);

        sinkValue = await _replyObjectService.cacheReplyObject(replyObject);

        debugPrint(
            'WallReplyBloc after cache: seed: ${replyObject.seed!},  userid: ${userFurnace.userid!}, circle: ${replyObject.circleObjectID},   ${DateTime.now()}');


      }

      if (replyObject.body != null)
        replyObject.body = replyObject.body!.trim();

      debugPrint(
          'WallReplyBloc before service call: seed: ${replyObject.seed!},  userid: ${userFurnace.userid!}, circle: ${replyObject.circleObjectID},  ${DateTime.now()}');

      sinkValue = await _replyObjectService.saveReplyObject(
        userFurnace, userCircleCache, replyObject, globalEventBloc);

      debugPrint(
          "saveReplyObject complete: ${replyObject.created},  ${DateTime.now()}");

      if (sinkValue.id != null) {
        globalEventBloc.broadcastMemCacheReplyObjectsAdd([sinkValue]);
        _saveResults.sink.add(sinkValue);
      } else {
        throw ('could not save reply');
      }
      // globalEventBloc.broadcastAndRemoveCircleObject(
      //     sinkValue, sinkValue.seed!);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');

      // if (replyObject.seed != null) {
      //   globalEventBloc.removeGenericObject(replyObject.seed!);
      // }

      if (error.toString().contains(ErrorMessages.USER_BEING_VOTED_OUT)) {
        globalEventBloc.broadcastError(ErrorMessages.USER_BEING_VOTED_OUT);
      }
    }
  }

  /// Update a replyObject
  updateReplyObject(ReplyObject replyObject, UserFurnace userFurnace, UserCircleCache userCircleCache,) async {
    try  {
      if (replyObject.body != null)
        replyObject.body = replyObject.body!.trim();

      ReplyObject sinkValue = await _replyObjectService.updateReplyObject(
        replyObject, userFurnace, userCircleCache);

      // if (sinkValue.id != null) {
      //   globalEventBloc.broadcastMemCacheReplyObjectsAdd([replyObject]);
      //   _saveResults.sink.add(sinkValue);
      // } else {
      //   throw ('could not save reply');
      // }
       _saveResults.sink.add(sinkValue);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("$error");
    }
  }

  resendFailedReplyObjects(
      GlobalEventBloc globalEventBloc, UserFurnace userFurnace
      ) async {
    try {
      List<ReplyObjectCache> failedToSave = await TableReplyObjectCache.readPrecached();

      List<ReplyObject> replyObjects = _convertFromCache(failedToSave);

      for (ReplyObject replyObject in replyObjects) {
        try {
          if (replyObject.seed == null) {
            continue;
          }

          if (globalEventBloc.genericObjectExists(replyObject.seed!)) {
            continue;
          }

          globalEventBloc.addGenericObject(replyObject.seed!);

          UserCircleCache userCircleCache = await TableUserCircleCache.readUserCircleCacheByCircleAndUser(
            replyObject.circle!.id!, replyObject.creator!.id!);

          await _saveReplyObject(globalEventBloc, userFurnace, userCircleCache, replyObject);
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint("WallReplyBloc.resendFailedReplyObjects loop block: $err");
        }
        globalEventBloc.removeGenericObject(replyObject.seed!);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("ReplyObjectBloc.resendFailedReplyObjects: $error");
    }
  }

  /// hide a ReplyObject
  hideReplyObject(UserCircleCache userCircleCache, UserFurnace userFurnace, ReplyObject replyObject) async {
    try {
      await _replyObjectService.hideReplyObject(
        userCircleCache, userFurnace, replyObject);

      globalEventBloc.broadcastMemCacheReplyObjectsRemove([replyObject]);

      //stop process
      //globalEventBloc.deletedSeeds.add(replyObject.seed!);
      await TableReplyObjectCache.delete(replyObject.id!);
      _replyObjectDeleted.sink.add(replyObject.id!);
      globalEventBloc.broadcastMemCacheReplyObjectsRemove([replyObject]);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("WallReplyBloc.hideReplyObject: $error");
    }
  }

  Future<List<ReplyObject>> getReplyLength(String? circleObjectID, UserFurnace userFurnace) async {
    List<ReplyObject> sinkValues = [];
    try {
      if (circleObjectID != null) {
        List<Map> replies = await TableReplyObjectCache.getLength(circleObjectID);

        if (replies.isNotEmpty) {
          sinkValues = ReplyObjectService.convertFromCachePerformant(
              globalEventBloc, replies, userFurnace.userid!);
        }
      }

    return sinkValues;
    //_replyObjects.sink.add(sinkValues);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("WallReplyBloc.getReplyLength: $error");
      //_replyObjects.sink.addError(error);
    }
    return sinkValues;
  }

  ///called when objects failed to decrypt
  _retryFailedObjects(UserFurnace userFurnace, UserCircleCache userCircleCache, List<ReplyObject> failedReplyObjects) async {
    List<ReplyObject> results = [];

    var failedToDecrypt = failedReplyObjects.where((element) => element.body == 'Chat history unavailable').toList();

    int counter = 0;
    for (ReplyObject replyObject in failedToDecrypt) {
      try {
        ///chaos engineering, more than 10 indicates a larger problem
        if (counter > 10) break;

        ReplyObject result = await getSingleObject(
          userFurnace, replyObject.id!, userCircleCache);
        results.add(result);
        counter++;
      } catch (e, trace) {
        LogBloc.insertError(e, trace);
      }
    }
    debugPrint("adding new objects from retryfailedobjects");
    _newerReplyObjects.sink.add(results);
  }

  /// retry to download objects that failed to download
  Future<ReplyObject> getSingleObject(UserFurnace userFurnace, String replyObjectID, UserCircleCache userCircleCache) async {
    ReplyObject? replyObject;
    try {
      replyObject = await _replyObjectService.getSingleObject(
        userFurnace, replyObjectID, userCircleCache.circle!);

      replyObject.refreshNeeded = true;

      if (replyObject.id != null) {
        List<ReplyObject>? decryptedObjects = await ForwardSecrecy.decryptReplyObjects(
          userFurnace.userid!,
          userCircleCache.usercircle!,
          [replyObject],
        );
        await TableReplyObjectCache.upsertListofObjects(
          userFurnace.userid!, decryptedObjects,
          //markRead: true,
        );

        debugPrint("adding new objects from getsingleobject");
        _newerReplyObjects.sink.add(decryptedObjects);
        globalEventBloc.broadcastReplyObject(decryptedObjects);

        //globalEventBloc.removeFromRetry(replyObject);
      }
    } catch (error, trace) {
      //if (replyObject != null) globalEventBloc.removeFromRetry(replyObject);
      LogBloc.insertError(error, trace);
      debugPrint('ReplyObjectBloc.getSingleObject: $error');
      _replyObjects.sink.addError(error);
    }
    return replyObject!;
  }

  ///Delete a reply object
  deleteReplyObject(UserCircleCache userCircleCache, UserFurnace userFurnace, ReplyObject replyObject) async {
    try {
      ReplyObject sinkValue;

      //globalEventBloc.deletedSeeds.add(circleObject.seed!);

      if (replyObject.id != null) {
        sinkValue = await _replyObjectService.deleteReplyObject(
          userCircleCache, userFurnace, replyObject);
        globalEventBloc.broadcastMemCacheReplyObjectsRemove([replyObject]);
      } else {
        sinkValue = replyObject;
      }

      await TableReplyObjectCache.deleteBySeed(replyObject.seed!);
      globalEventBloc.broadcastMemCacheReplyObjectsRemove([replyObject]);

      _replyObjectDeleted.sink.add(replyObject.id!);
      globalEventBloc.broadcastMemCacheReplyObjectsRemove([replyObject]);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("ReplyObjectBoc.deleteReplyObject: $error");
    }
  }

  // processNotification(CircleObject circleObject) async {
  //   ///get new items for circle object replies!
  //   ///check if they arent being gotten already first?
  //
  //   CircleObjectCache circleObjectCache =
  //     await TableCircleObjectCache.readBySeed(circleObject.seed!);
  //
  //   UserCircleCache userCircleCache = await TableUserCircleCache.readUserCircleCacheByCircleAndUser(
  //     circleObject.circle!.id!, circleObjectCache.creator!,
  //   );
  //
  //   UserFurnace userFurnace = await TableUserFurnace.read(userCircleCache.userFurnace);
  //
  //   updateCacheFurnace(userFurnace, circleObject.id!, circleObject.circle!.id!, true, false, 50);
  // }

  reportViolation(UserFurnace userFurnace, ReplyObject replyObject, Violation violation, UserCircleCache userCircleCache) async {
    try {
      _replyObjectService.reportViolation(
        userFurnace, replyObject, violation, userCircleCache);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('ReplyObjectBloc.reportViolation $err');
    }
  }

  deleteFromPushNotification(String id) async {
    try {

      ReplyObjectCache replyObj = await TableReplyObjectCache.get(id);

      if (replyObj.replyObjectid != null) {
        await TableReplyObjectCache.delete(id);
        _replyObjectDeleted.sink.add(id);
      }

    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('ReplyObjectBloc.deleteFromPushNotification: $error');
    }
  }

  uploadFromPushNotification(String replyID, String objectSeed,) async {
    try {

      CircleObjectCache circleObjectCache = await TableCircleObjectCache.readBySeed(objectSeed);

      // UserCircleCache userCircleCache = await TableUserCircleCache.readUserCircleCacheByCircleAndUser(
      //   circleObjectCache.circleid!, circleObjectCache.creator!
      // ); ///this is returning nada

      UserCircleCache userCircleCache = await userCircleBloc.getUserCircleCacheFromCircle(circleObjectCache.circleid!);

      if (userCircleCache.userFurnace != null) {
        ///only refresh is app is open, because global state needed for userCircleCache
        UserFurnace userFurnace = await TableUserFurnace.read(userCircleCache.userFurnace);
        getSingleObject(userFurnace, replyID, userCircleCache);
      }

    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("ReplyObjectBloc.uploadFromPushNotification: $error");
    }
  }

  postReaction(
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      ReplyObject replyObject,
      CircleObjectReaction circleObjectReaction) async {
    try {
      await TableReplyObjectCache.updateCacheSingleObject(
        userFurnace.userid!, replyObject);
      // userCircleCache.lastItemUpdate = DateTime.now();
      // await TableUserCircleCache.upsert(userCircleCache);

      ReplyObject updated = await _replyObjectService.postReaction(
        userFurnace, userCircleCache, replyObject, circleObjectReaction);

      await updateCache(userFurnace, replyObject.circleObjectID!, userCircleCache.circle!, [updated], true);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("ReplyObjectBloc.postReaction: $error");
    }
  }

  deleteReaction(
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      ReplyObject replyObject,
      CircleObjectReaction circleObjectReaction,
      ReplyObject lastInList
      ) async {
    try {
      if (circleObjectReaction.id == null) {
        debugPrint('could not remove reaction');
        return;
      }

      await TableReplyObjectCache.updateCacheSingleObject(
        userFurnace.userid!, replyObject);
      // userCircleCache.lastItemUpdate = lastInList.lastUpdate!;
      // await TableUserCircleCache.upsert(userCircleCache);

      ReplyObject updated = await _replyObjectService.deleteReaction(
        userFurnace, userCircleCache, replyObject, circleObjectReaction);

      updateCache(userFurnace, replyObject.circleObjectID!, userCircleCache.circle!, [updated], true);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("ReplyObjectBloc.deleteReaction: $error");
    }
  }

  Future<ReplyObject> processReactionNotification(
      String replyObjectID, reaction) async {
    bool removed = false;
    CircleObjectReaction? found;

    ReplyObjectCache replyObjectCache = await TableReplyObjectCache.get(replyObjectID);
    List<ReplyObject> replyObjects = _convertFromCache([replyObjectCache]);
   ReplyObject replyObject = replyObjects[0];

    if (reaction.index != 1 && reaction.index != null) {
      ///old emojis
      for (CircleObjectReaction r in replyObject.reactions!) {
        if (r.index == reaction.index) {
          found = r;
          for (User user in r.users) {
            if (user.id == reaction.users[0].id) {
              ///reaction exists, remove
              removed = true;
            }
          }
        }
      }
    } else {
      ///new emojis from emoji keyboard
      for (CircleObjectReaction r in replyObject.reactions!) {
        if (r.emoji == reaction.emoji) {
          found = r;
          for (User user in r.users) {
            if (user.id == reaction.users[0].id) {
              ///reaction exists, remove
              removed = true;
            }
          }
        }
      }
    }
    if (removed == true && found != null) {
      if (reaction.index !=  1 && reaction.index != null) {
        found.users.removeWhere((element) => element.id == reaction.users[0].id);
        if (found.users.isEmpty) {
          replyObject.reactions!.removeWhere((element) => element.index == reaction.index);
        }
      } else {
        found.users.removeWhere((element) => element.id == reaction.users[0].id);
        if (found.users.isEmpty) {
          replyObject.reactions!.removeWhere((element) => element.emoji == reaction.emoji);
        }
      }
    } else if (removed == false && found != null) {
      ///reaction exists, add user
      found.users.add(reaction.users[0]);
    } else {
      ///add reaction
      replyObject.reactions!.add(reaction);
    }

    await TableReplyObjectCache.upsertListofObjects("", [replyObject]);
    //_newerReplyObjects.sink.add([replyObject]);
    globalEventBloc.broadcastReplyObject([replyObject]);
    return replyObject;
  }

  dispose() async {
    await _replyObjects.drain();
    _replyObjects.close();

    await _newerReplyObjects.drain();
    _newerReplyObjects.close();

    await _olderReplyObjects.drain();
    _olderReplyObjects.close();

    await _replyObjectsDeleted.drain();
    _replyObjectsDeleted.close();

    await _saveResults.drain();
    _saveResults.close();

    await _saveFailed.drain();
    await _saveFailed.close();
  }

}