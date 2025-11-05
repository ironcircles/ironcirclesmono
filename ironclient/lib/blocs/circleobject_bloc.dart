import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/circlealbum_bloc.dart';
import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
import 'package:ironcirclesapp/blocs/circlelist_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/link_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/member_bloc.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy.dart';
import 'package:ironcirclesapp/models/backgroundtask.dart';
import 'package:ironcirclesapp/models/circlelastlocalupdate.dart';
import 'package:ironcirclesapp/models/circleobjectreaction.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/ratchetindex.dart';
import 'package:ironcirclesapp/models/violation.dart';
import 'package:ironcirclesapp/services/blob_service.dart';
import 'package:ironcirclesapp/services/cache/filecache_service.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
import 'package:ironcirclesapp/services/cache/table_backgroundtask.dart';
import 'package:ironcirclesapp/services/cache/table_circlelastlocalupdate.dart';
import 'package:ironcirclesapp/services/cache/table_circleobject.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/cache/table_userfurnace.dart';
import 'package:ironcirclesapp/services/cache/videocache_service.dart';
import 'package:ironcirclesapp/services/circleobject_service.dart';
import 'package:ironcirclesapp/services/tenor_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

class SaveError {
  CircleObject circleObject;
  String errorMessage;

  SaveError({required this.circleObject, required this.errorMessage});
}

class CircleObjectBloc {
  //}implements BlocBase {

  final GlobalEventBloc globalEventBloc;

  CircleObjectBloc({required this.globalEventBloc});

  final LinkBloc _linkBloc = LinkBloc();

  final _circleObjectService = CircleObjectService();
  //final _circleImageService = CircleImageService();
  //final _circleImageService2 = CircleImage2Service();
  //final _userFurnaceBloc = UserFurnaceBloc();
  //UserCircleBloc _userCircleBloc = UserCircleBloc();

  final _imageCarousel = PublishSubject<List<CircleObject>?>();
  Stream<List<CircleObject>?> get imageCarousel => _imageCarousel.stream;

  final _imageCarouselMore = PublishSubject<List<CircleObject>?>();
  Stream<List<CircleObject>?> get imageCarouselMore =>
      _imageCarouselMore.stream;

  final _circleObjects = PublishSubject<List<CircleObject>?>();
  Stream<List<CircleObject>?> get allCircleObjects => _circleObjects.stream;

  final _messageFeed = PublishSubject<List<CircleObject>?>();
  Stream<List<CircleObject>?> get messageFeed => _messageFeed.stream;

  final _pinnedObjects = PublishSubject<List<CircleObject>>();
  Stream<List<CircleObject>> get pinnedObjects => _pinnedObjects.stream;

  final _searchedObjects = PublishSubject<List<CircleObject>>();
  Stream<List<CircleObject>> get searchedObjects => _searchedObjects.stream;

  final _newerCircleObjects = PublishSubject<List<CircleObject>?>();
  Stream<List<CircleObject>?> get newCircleObjects =>
      _newerCircleObjects.stream;

  final _saveResults = PublishSubject<CircleObject>();
  Stream<CircleObject> get saveResults => _saveResults.stream;

  final _saveFailed = PublishSubject<SaveError>();
  Stream<SaveError> get saveFailed => _saveFailed.stream;

  final _imageSaved = PublishSubject<CircleObject>();
  Stream<CircleObject> get imageSaved => _imageSaved.stream;

  final _thumbnailLoaded = PublishSubject<String?>();
  Stream<String?> get thumbnailLoaded => _thumbnailLoaded.stream;

  final _fullimageLoaded = PublishSubject<String?>();
  Stream<String?> get fullimageLoaded => _fullimageLoaded.stream;

  final _circleObjectDeleted = PublishSubject<CircleObject>();
  Stream<CircleObject> get circleObjectDeleted => _circleObjectDeleted.stream;

  final _circleObjectsDeleted = PublishSubject<List<CircleObject>>();
  Stream<List<CircleObject>> get circleObjectsDeleted =>
      _circleObjectsDeleted.stream;

  final _olderCircleObjects = PublishSubject<List<CircleObject>>();
  Stream<List<CircleObject>> get olderCircleObjects =>
      _olderCircleObjects.stream;

  final _jumpToCircleObjects = PublishSubject<List<CircleObject>>();
  Stream<List<CircleObject>> get jumpToCircleObjects =>
      _jumpToCircleObjects.stream;

  final _downloadBlobs = PublishSubject<CircleObject>();
  Stream<CircleObject> get downloadBlobs => _downloadBlobs.stream;

  final _refreshVault = PublishSubject<bool>();
  Stream<bool> get refreshVault => _refreshVault.stream;

  //GlobalEventBloc? _globalEventBloc;

  static cleanupStuckObjects() async {
    try {
      await TableCircleObjectCache.cleanupStuckObjects();
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
    }
  }

  /// retry to download objects that failed to download
  Future<CircleObject> getSingleObject(
    UserFurnace userFurnace,
    String circleObjectID,
    UserCircleCache userCircleCache,
  ) async {
    CircleObject? circleObject;
    try {
      circleObject = await _circleObjectService.getSingleObject(
        userFurnace,
        circleObjectID,
        userCircleCache.circle!,
      );

      circleObject.refreshNeeded = true;

      if (circleObject.id != null) {
        //List<CircleObject>? decryptedObjects =
        //await updateCache(userFurnace, circleID, [circleObject], true, forceCache: true);

        List<CircleObject>? decryptedObjects =
            await ForwardSecrecy.decryptCircleObjects(
              userFurnace.userid!,
              userCircleCache.usercircle!,
              [circleObject],
            );
        await TableCircleObjectCache.upsertListofObjects(
          userFurnace.userid!,
          decryptedObjects,
          markRead: true,
        );

        _newerCircleObjects.sink.add(decryptedObjects);

        globalEventBloc.removeFromRetry(circleObject);
      }
    } catch (error, trace) {
      if (circleObject != null) globalEventBloc.removeFromRetry(circleObject);
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectBloc.getSingleObject: $error");
      _circleObjects.sink.addError(error);
    }
    return circleObject!;
  }

  /// Initial load from a screen
  initialLoadForWall(
    List<UserFurnace> userFurnaces,
    List<UserCircleCache> userCircleCaches,
  ) async {
    try {
      List<CircleObject> circleObjects = [];

      ///send the cached results first in case there is no internet
      await _sinkCacheDoubleWall(userFurnaces, userCircleCaches);

      for (UserFurnace userFurnace in userFurnaces) {
        for (UserCircleCache userCircleCache in userCircleCaches) {
          if (userCircleCache.userFurnace! == userFurnace.pk) {
            List<CircleObject> circleObjects = await updateCacheFurnace(
              userFurnace,
              userCircleCache,
              userCircleCache.circle!,
              true,
              true,
              true,
              true,
              false,
              50,
            );

            _newerCircleObjects.sink.add(circleObjects);
            break;
          }
        }
      }

      //

      //_newerCircleObjects.sink.add(circleObjects);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectBloc.initalLoad: $error");
      _circleObjects.sink.addError(error);
    }
  }

  /// Initial load for a circle or dm
  initialLoad(
    String? circleID,
    UserFurnace userFurnace,
    UserCircleCache userCircleCache,
    bool initialSync, {
    bool sinkTwice = true,
    bool downloadImages = true,
    bool isVault = false,
  }) async {
    try {
      List<CircleObject> circleObjects = [];

      bool upsert = true;

      ///send the cached results first in case there is no internet
      if (initialSync) {
        if (sinkTwice == false) {
          await _sinkCache(
            userFurnace,
            userCircleCache,
            circleID,
            userFurnace.userid,
          );
        } else
          await _sinkCacheDouble(
            userFurnace,
            userCircleCache,
            circleID,
            userFurnace.userid,
            isVault: isVault,
          );
        //await _sinkCache(circleID, userFurnace!.userid);
        //int count =

        //if (count == 0) upsert = false;
        upsert = true;
      }

      ///fetch items
      circleObjects = await updateCacheFurnace(
        userFurnace,
        userCircleCache,
        circleID!,
        true,
        true,
        upsert,
        downloadImages,
        false,
        50,
      );

      _newerCircleObjects.sink.add(circleObjects);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectBloc.initalLoad: $error");
      _circleObjects.sink.addError(error);
    }
  }

  /// Refresh Cache only
  /*refreshFromCache(DateTime lastObjectCreated, String? circleID) async {
    try {
      //await _sinkCache(circleID, null);

    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectBloc.initalLoad: $error");
      _circleObjects.sink.addError(error);
    }
  }

   */

  /// Called when a cache refresh is needed, from a push notification or user refresh
  /// Only refreshes the caches, does not sink
  Future<void> fetchHistory(
    UserFurnace userFurnace,
    List<UserCircle> userCircles,
  ) async {
    List<CircleObject> circleObjects = [];
    List<CircleObject> decryptedObjects = [];
    try {
      bool done = false;

      DateTime olderThan = DateTime.now();

      for (UserCircle userCircle in userCircles) {
        do {
          List<CircleObject> circleObjects = await requestOlderThan(
            userCircle.circle!.id!,
            userFurnace,
            olderThan,
            forcePull: true,
          );

          if (circleObjects.length < 500) {
            done = true;
          } else {
            olderThan = circleObjects.last.created!;
          }
        } while (!done);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleObjectBlock.updateCacheFurnace: $error');
    }
  }

  /// Called when a cache refresh is needed, from a push notification or user refresh
  /// Only refreshes the caches, does not sink
  Future<List<CircleObject>> updateCacheFurnace(
    UserFurnace userFurnace,
    UserCircleCache userCircleCache,
    String circleID,
    bool updateBadge,
    bool updateCircleLastAccessed,
    bool upsert,
    bool downloadImages,
    bool initialSink,
    int amount,
  ) async {
    List<CircleObject> circleObjects = [];
    List<CircleObject> decryptedObjects = [];
    try {
      ///CO-REMOVE
      //return [];

      //CircleLastUpdate circleLastUpdate =
      //  await CircleLastUpdate.retrieve(circleID);
      CircleLastLocalUpdate? circleLastLocalUpdate =
          await TableCircleLastLocalUpdate.read(circleID);

      if (circleLastLocalUpdate == null) {
        debugPrint(
          '_circleObjectService.fetchCircleObjects fetch objects:  ${DateTime.now()}',
        );

        circleObjects = await _circleObjectService.fetchCircleObjects(
          circleID,
          userFurnace,
          amount,
        );

        debugPrint(
          '_circleObjectService.fetchCircleObjects fetched:  ${DateTime.now()}',
        );

        if (circleObjects.isNotEmpty) {
          try {
            //update the cache
            // decryptedObjects =
            //   await _updateCache(args);

            //decryptedObjects = await compute(_updateCache, args);
            decryptedObjects = await updateCache(
              userFurnace,
              circleID,
              circleObjects,
              upsert,
              downloadImages: downloadImages,
            );

            //This is not needed as keys were just generated on login (new install or clearing of cache)
            //ECDH.ratchetReceiverKeyPair(userFurnace, circleID);
          } catch (err, trace) {
            //LogBloc.insertError(err, trace);
            debugPrint('CircleObjectBlock.updateCacheFurnace: $err');
            debugPrint('$trace');
            //await updateCache(userFurnace, circleID, circleObjects, true);
          }
        }

        if (decryptedObjects.isEmpty) {
          //debugPrint('break');
        } else {
          if (updateCircleLastAccessed) {
            //circleLastUpdate.circleID = circleID;
            //await circleLastUpdate.upsert(decryptedObjects[0]
            //  .created!); //only change the last fetch date if the user is viewing the screen so we don't miss messages
            circleLastLocalUpdate = CircleLastLocalUpdate(
              circleID: circleID,
              lastFetched: decryptedObjects[0].lastUpdate!,
            );
            circleLastLocalUpdate.upsert();
          }
        }
      } else {
        ///CO-REMOVE, update badge
        await requestNewerThan(
          circleID,
          userFurnace,
          userCircleCache,
          circleLastLocalUpdate,
          false,
          updateCircleLastAccessed,
          initialSink,
        );
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleObjectBlock.updateCacheFurnace: $error');
    }

    return decryptedObjects;
  }

  getNewForUserCircles(
    UserFurnace userFurnace,
    List<String?>? openGuarded,
    List<CircleLastLocalUpdate> circleLastUpdates,
    bool force,
  ) async {
    try {
      ///CO-REMOVE
      //return;

      ///TODO LastFetched
      /*if (globalState.circleObjectFetch != null && !force) {
        Duration duration =
            DateTime.now().difference(globalState.circleObjectFetch!);

        if (duration.inSeconds < 20) return;
      }

      globalState.circleObjectFetch = DateTime.now();

       */

      List<List<CircleObject>> circleObjects = await _circleObjectService
          .getNewForUserCircles(userFurnace, openGuarded, circleLastUpdates);
      await cacheObjects(userFurnace, circleObjects);

      ///send a global notification
      globalEventBloc.broadcastCircleObjectsRefreshed();
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectBloc.getNewForUserCircles: $error");
      _newerCircleObjects.sink.addError(error);
    }
  }

  getPinnedPosts(
    UserFurnace userFurnace,
    UserCircleCache userCircleCache,
  ) async {
    try {
      List<CircleObject> circleObjects = await _circleObjectService
          .getPinnedPosts(globalEventBloc, userCircleCache);

      _pinnedObjects.sink.add(circleObjects);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectBloc.getPinnedPosts: $error");
      _pinnedObjects.sink.addError(error);
    }
  }

  search(
    String? type,
    UserFurnace userFurnace,
    UserCircleCache userCircleCache,
    String searchText,
  ) async {
    try {
      if (type != null) {
        List<CircleObject> circleObjects = await _circleObjectService
            .vaultObjectSearch(
              globalEventBloc,
              type,
              userCircleCache,
              searchText,
            );
        _searchedObjects.sink.add(circleObjects);
      } else {
        List<CircleObject> circleObjects = await _circleObjectService.search(
          globalEventBloc,
          userCircleCache,
          searchText,
        );
        _searchedObjects.sink.add(circleObjects);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectBloc.search: $error");
      _searchedObjects.sink.addError(error);
    }
  }

  List<CircleObject> sortMessageFeed(
    List<UserCircleCache> userCircleCaches,
    List<CircleObject> circleObjects,
  ) {
    List<CircleObject> sorted = [];

    ///sort the userCircleCaches
    userCircleCaches.sort(
      (a, b) => a.lastItemUpdate!.compareTo(b.lastItemUpdate!),
    );

    for (UserCircleCache userCircleCache in userCircleCaches) {
      List<CircleObject> objects =
          circleObjects
              .where((element) => element.circle!.id == userCircleCache.circle!)
              .toList();

      objects.sort((a, b) => a.lastUpdate!.compareTo(b.lastUpdate!));

      sorted.addAll(objects);
    }

    return sorted;
  }

  getMessageFeed(
    List<UserFurnace> userFurnaces,
    List<UserCircleCache> userCircleCaches,
  ) async {
    try {
      List<CircleObject> circleObjects = [];

      ///For performance, only sink circles with a message badge
      circleObjects = await _circleObjectService.getMessageFeed(
        globalEventBloc,
        userFurnaces,
        userCircleCaches,
        true,
      );

      _messageFeed.sink.add(circleObjects);

      ///The, check them all in cause a real time event overlapped the badge setting
      circleObjects = await _circleObjectService.getMessageFeed(
        globalEventBloc,
        userFurnaces,
        userCircleCaches,
        false,
      );

      _messageFeed.sink.add(circleObjects);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectBloc.getMessageFeed: $error");
      _messageFeed.sink.addError(error);
    }
  }

  requestNew(
    String circleID,
    UserFurnace userFurnace,
    UserCircleCache userCircleCache,
    bool updateBadge,
    bool updateCircleLastAccessed,
    bool initialSink,
  ) async {
    try {
      // UserCircleCache userCircleCache =
      //     await TableUserCircleCache.readUserCircleCacheByCircleAndUser(
      //         circleID, userFurnace.userid!);

      CircleLastLocalUpdate? circleLastLocalUpdate =
          await CircleLastLocalUpdate.read(userCircleCache.circle!);

      if (circleLastLocalUpdate != null)
        await requestNewerThan(
          circleID,
          userFurnace,
          userCircleCache,
          circleLastLocalUpdate,
          updateBadge,
          updateCircleLastAccessed,
          initialSink,
        );
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectBloc.requestNew: $error");
      _newerCircleObjects.sink.addError(error);
    }
  }

  /// Pulls items
  requestNewerThan(
    String circleID,
    UserFurnace userFurnace,
    UserCircleCache userCircleCache,
    CircleLastLocalUpdate circleLastLocalUpdate,
    bool updateBadge,
    bool updateCircleLastAccessed,
    bool initialSink,
  ) async {
    try {
      //if (initialSink) _sinkCache(circleID, userFurnace.userid!);
      if (initialSink) {
        sinkCacheNewerThan(
          userFurnace,
          userCircleCache,
          circleID,
          circleLastLocalUpdate.lastFetched!,
        );
      }

      ///CO-REMOVE
      List<CircleObject> circleObjects = await _circleObjectService
          .fetchNewerThan(
            circleID,
            userFurnace,
            circleLastLocalUpdate.lastFetched!,
            updateBadge,
          );

      ///did we find anything?
      if (circleObjects.isNotEmpty) {
        DateTime lastUpdate = circleObjects[0].lastUpdate!;

        //update the cache
        List<CircleObject>? decryptedObjects = await updateCache(
          userFurnace,
          circleID,
          circleObjects,
          true,
        );

        if (decryptedObjects.isNotEmpty) {
          //update the last fetch datetime in Hive
          if (updateCircleLastAccessed)
            await circleLastLocalUpdate.upsertDate(lastUpdate);
          _newerCircleObjects.sink.add(decryptedObjects);
        }
      } else {
        _newerCircleObjects.sink.add([]);
      }

      //  debugPrint("sink complete " + DateTime.now().toLocal().toString());
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectBloc.requestNewerThan: $error");
      _newerCircleObjects.sink.addError(error);
    }
  }

  /// Pulls old items
  Future<List<CircleObject>> requestOlderThan(
    String circleID,
    UserFurnace userFurnace,
    DateTime created, {
    bool forcePull = false,
  }) async {
    try {
      List<Map> cachedObjects = [];

      if (forcePull == false) {
        ///Are there any more in the database?
        cachedObjects = await TableCircleObjectCache.readOlderThanMap(
          [circleID],
          200,
          created,
        );

        if (cachedObjects.isNotEmpty) {
          List<CircleObject>? sinkValues =
              CircleObjectService.convertFromCachePerformant(
                globalEventBloc,
                cachedObjects,
                userFurnace.userid!,
              );

          _olderCircleObjects.sink.add(sinkValues);
        }
      }

      if (cachedObjects.length < 200) {
        ///If there is less than 200, then we need to pull from the server
        List<CircleObject>? serverObjects = await _circleObjectService
            .fetchOlderThan(circleID, userFurnace, created);

        //did we find anything?
        if (serverObjects.isNotEmpty) {
          //update the cache
          serverObjects = await updateCache(
            userFurnace,
            circleID,
            serverObjects,
            true,
          );
        }

        ///sink even if empty to let the ui to know to not ask repeatedly
        _olderCircleObjects.sink.add(serverObjects);

        return serverObjects;
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectBloc.requestOlderThan: $error");
      _olderCircleObjects.sink.addError(error);
    }

    return [];
  }

  /// Pulls items between dates
  requestJumpTo(
    String circleID,
    UserFurnace userFurnace,
    DateTime cachedDate,
    DateTime jumpTo,
  ) async {
    try {
      List<CircleObject> circleObjects = await _circleObjectService.fetchJumpTo(
        circleID,
        userFurnace,
        cachedDate,
        jumpTo,
      );

      //did we find anything?
      if (circleObjects.isNotEmpty) {
        //update the cache
        circleObjects = await updateCache(
          userFurnace,
          circleID,
          circleObjects,
          true,
          markRead: true,
        );

        // _olderCircleObjects.sink.add(circleObjects);
      }

      //raise event even if empty
      _jumpToCircleObjects.sink.add(circleObjects);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectBloc.requestJumpTo: $error");
      _olderCircleObjects.sink.addError(error);
    }
  }

  /*updateAllCircleObjectsForFurnance(
      UserFurnace userFurnace, List<UserCircle> userCircles) async {
    for (UserCircle userCircle in userCircles) {
      if (userCircle.circle != null) {
        await updateCacheFurnace(
            userFurnace, userCircle.circle!.id!, false, true, true);
      }
    }
  }

   */

  Future downloadAllBlobs(
    UserFurnace userFurnace,
    UserCircleCache userCircleCache,
  ) async {
    /*List<CircleObject> circleObjects = await TableCircleObjectCache.

    CircleImageBloc circleImageBloc =
    CircleImageBloc(globalEventBloc);
    circleImageBloc.notifyWhenThumbReady(
        userFurnace, userCircleCache, circleObject, this);

     */
  }

  Future<void> sinkImageCarouselForFeed(
    List<UserFurnace> userFurnaces,
    List<UserCircleCache> userCircles,
    CircleObject circleObject,
  ) async {
    try {
      List<String> circleIDs = userCircles.map((e) => e.circle!).toList();

      List<CircleObjectCache> circleObjectCacheList =
          await TableCircleObjectCache.readMediaBeforeAndAfterForFeed(
            circleObject,
            circleIDs,
            circleObject.lastUpdate!,
            circleObject.lastUpdate!,
            amount: 500,
          );

      if (circleObjectCacheList.isNotEmpty) {
        List<CircleObject>? sinkValues = _convertFromCache(
          circleObjectCacheList,
        );

        for (CircleObject sinkObject in sinkValues) {
          sinkObject.userCircleCache = userCircles.firstWhere(
            (element) => element.circle == sinkObject.circle!.id!,
          );

          sinkObject.userFurnace = userFurnaces.firstWhere(
            (element) => element.userid == sinkObject.userCircleCache!.user!,
          );
        }

        _imageCarousel.sink.add(sinkValues);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleObjectBloc.sinkImageCarousel: $error');
    }

    return;
  }

  Future<void> sinkMoreForImageCarouselFeed(
    List<UserFurnace> userFurnaces,
    List<UserCircleCache> userCircles,
    CircleObject circleObject,
    DateTime before,
    DateTime after,
  ) async {
    try {
      List<String> circleIDs = userCircles.map((e) => e.circle!).toList();

      List<CircleObjectCache> circleObjectCacheList =
          await TableCircleObjectCache.readMediaBeforeAndAfterForFeed(
            circleObject,
            circleIDs,
            before,
            after,
            amount: 5000,
          );

      if (circleObjectCacheList.isNotEmpty) {
        List<CircleObject>? sinkValues = _convertFromCache(
          circleObjectCacheList,
        );

        for (CircleObject sinkObject in sinkValues) {
          sinkObject.userCircleCache = userCircles.firstWhere(
            (element) => element.circle == sinkObject.circle!.id!,
          );

          sinkObject.userFurnace = userFurnaces.firstWhere(
            (element) => element.userid == sinkObject.userCircleCache!.user!,
          );
        }

        _imageCarouselMore.sink.add(sinkValues);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleObjectBloc.sinkImageCarousel: $error');
    }

    return;
  }

  Future<void> sinkImageCarouselForCircle(CircleObject circleObject) async {
    try {
      List<CircleObjectCache> circleObjectCacheList =
          await TableCircleObjectCache.readMediaBeforeAndAfterForCircle(
            circleObject,
            circleObject.lastUpdate!,
            circleObject.lastUpdate!,
            amount: 500,
          );

      if (circleObjectCacheList.isNotEmpty) {
        List<CircleObject>? sinkValues = _convertFromCache(
          circleObjectCacheList,
        );

        for (CircleObject sinkObject in sinkValues) {
          sinkObject.userCircleCache = circleObject.userCircleCache;
          sinkObject.userFurnace = circleObject.userFurnace;
        }

        _imageCarousel.sink.add(sinkValues);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleObjectBloc.sinkImageCarousel: $error');
    }

    return;
  }

  Future<void> sinkMoreForImageCarousel(
    CircleObject circleObject,
    DateTime before,
    DateTime after,
  ) async {
    try {
      List<CircleObjectCache> circleObjectCacheList =
          await TableCircleObjectCache.readMediaBeforeAndAfterForCircle(
            circleObject,
            before,
            after,
            amount: 5000,
          );

      if (circleObjectCacheList.isNotEmpty) {
        List<CircleObject>? sinkValues = _convertFromCache(
          circleObjectCacheList,
        );

        for (CircleObject sinkObject in sinkValues) {
          sinkObject.userCircleCache = circleObject.userCircleCache;
          sinkObject.userFurnace = circleObject.userFurnace;
        }

        _imageCarouselMore.sink.add(sinkValues);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleObjectBloc.sinkImageCarousel: $error');
    }

    return;
  }

  /// Sink from cache
  Future<int> sinkCacheNewerThan(
    UserFurnace userFurnace,
    UserCircleCache userCircleCache,
    String circleID,
    DateTime lastCreated,
  ) async {
    //DateTime? retValue;

    int retValue = 0;

    try {
      //List<CircleObjectCache> circleObjectCacheList =
      List<Map> results = await TableCircleObjectCache.readNewerThanMap(
        circleID,
        lastCreated,
      );

      if (results.isNotEmpty) {
        List<CircleObject>? sinkValues =
            CircleObjectService.convertFromCachePerformant(
              globalEventBloc,
              results,
              globalState.user.id!,
            );

        _newerCircleObjects.sink.add(sinkValues);

        retValue = results.length;
      } else {
        _newerCircleObjects.sink.add([]);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleObjectBloc._sinkCacheNewerThan: $error');
      rethrow;
    }

    return retValue;
  }

  /// Sink from cache
  Future<int> _sinkCache(
    UserFurnace userFurnace,
    UserCircleCache userCircleCache,
    String? circleID,
    String? userID, {
    int amount = 50,
  }) async {
    //DateTime? retValue;

    int retValue = 0;

    try {
      //List<CircleObjectCache> circleObjectCacheList =
      List<Map> results = await TableCircleObjectCache.readAmount(
        circleID,
        amount,
      );

      if (results.isNotEmpty) {
        List<CircleObject>? sinkValues =
            CircleObjectService.convertFromCachePerformant(
              globalEventBloc,
              results,
              userID!,
              userCircleCaches: [userCircleCache],
              userFurnaces: [userFurnace],
            );

        _circleObjects.sink.add(sinkValues);

        retValue = results.length;
      } else {
        _circleObjects.sink.add([]);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleObjectBloc._sinkCache: $error');
      rethrow;
    }

    return retValue;
  }

  Future<int> _sinkCacheDouble(
    UserFurnace userFurnace,
    UserCircleCache userCircleCache,
    String? circleID,
    String? userID, {
    bool isVault = false,
  }) async {
    //DateTime? retValue;

    int retValue = 0;

    try {
      int firstAmount = 50;
      int secondAmount = 1000;

      if (isVault) {
        firstAmount = 3000;
      }

      List<Map> firstRead = await TableCircleObjectCache.readAmount(
        circleID,
        firstAmount,
      );

      if (firstRead.isNotEmpty) {
        List<CircleObject>? firstSink =
            CircleObjectService.convertFromCachePerformant(
              globalEventBloc,
              firstRead,
              userID!,
              userCircleCaches: [userCircleCache],
              userFurnaces: [userFurnace],
            );
        _circleObjects.sink.add(firstSink);

        await Future.delayed(const Duration(milliseconds: 450), () {});

        List<Map> secondRead = await TableCircleObjectCache.readAmount(
          circleID,
          secondAmount,
        );

        if (secondRead.length > firstRead.length) {
          List<Map> secondGroup = secondRead.sublist(
            firstRead.length,
            secondRead.length,
          );

          List<CircleObject>? secondSink =
              CircleObjectService.convertFromCachePerformant(
                globalEventBloc,
                secondGroup,
                userID,
                userCircleCaches: [userCircleCache],
                userFurnaces: [userFurnace],
              );

          _olderCircleObjects.sink.add(secondSink);

          retValue = secondRead.length;
        } else
          retValue = firstRead.length;
      } else {
        _circleObjects.sink.add([]);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleObjectBloc._sinkCache: $error');
      rethrow;
    }

    return retValue;
  }

  Future<int> _sinkCacheDoubleWall(
    List<UserFurnace> userFurnaces,
    List<UserCircleCache> userCircleCaches,
  ) async {
    //DateTime? retValue;

    int retValue = 0;

    try {
      int firstAmount = 50;
      int secondAmount = 1000;

      List<String> circleIDs = [];

      for (UserCircleCache userCircleCache in userCircleCaches) {
        circleIDs.add(userCircleCache.circle!);
      }

      List<Map> firstRead = await TableCircleObjectCache.readByCircles(
        circleIDs,
        firstAmount,
      );

      if (firstRead.isNotEmpty) {
        List<CircleObject>? firstSink =
            CircleObjectService.convertFromCachePerformant(
              globalEventBloc,
              firstRead,
              userFurnaces[0].userid!,
              userFurnaces: userFurnaces,
              userCircleCaches: userCircleCaches,
            );

        _circleObjects.sink.add(firstSink);

        await Future.delayed(const Duration(milliseconds: 450), () {});

        List<Map> secondRead = await TableCircleObjectCache.readByCircles(
          circleIDs,
          secondAmount,
        );

        if (secondRead.length > firstRead.length) {
          List<Map> secondGroup = secondRead.sublist(
            firstRead.length,
            secondRead.length,
          );

          List<CircleObject>? secondSink =
              CircleObjectService.convertFromCachePerformant(
                globalEventBloc,
                firstRead,
                userFurnaces[0].userid!,
                userFurnaces: userFurnaces,
                userCircleCaches: userCircleCaches,
              );

          _olderCircleObjects.sink.add(secondSink);

          retValue = secondRead.length;
        } else
          retValue = firstRead.length;
      } else {
        _circleObjects.sink.add([]);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleObjectBloc._sinkCache: $error');
      rethrow;
    }

    return retValue;
  }

  ///called when objects failed to decrypt
  _retryFailedObjects(
    UserFurnace userFurnace,
    UserCircleCache userCircleCache,
    List<CircleObject> failedCircleObjects,
  ) async {
    List<CircleObject> results = [];

    var failedToDecrypt =
        failedCircleObjects
            .where((element) => element.body == 'Chat history unavailable')
            .toList();

    int counter = 0;
    for (CircleObject circleObject in failedToDecrypt) {
      try {
        ///chaos engineering, more than 10 indicates a larger problem
        if (counter > 10) break;

        CircleObject result = await getSingleObject(
          userFurnace,
          circleObject.id!,
          userCircleCache,
        );
        results.add(result);
        counter++;
      } catch (e, trace) {
        LogBloc.insertError(e, trace);
      }
    }

    _newerCircleObjects.sink.add(results);
  }

  retryFailedInDatabase() async {
    List<CircleObjectCache> failedToDecrypt =
        await TableCircleObjectCache.readFailedToDecrypt();

    if (failedToDecrypt.isEmpty) return;

    List<UserFurnace> userFurnaces = await TableUserFurnace.readAllForUser(
      globalState.user.id,
    );

    for (UserFurnace userFurnace in userFurnaces) {
      List<UserCircleCache> userCircleCaches =
          await TableUserCircleCache.readAllForUserFurnace(
            userFurnace.pk,
            userFurnace.userid,
          );

      for (UserCircleCache userCircleCache in userCircleCaches) {
        Iterable<CircleObjectCache> byCircle = failedToDecrypt.where(
          (element) => element.circleid! == userCircleCache.circle,
        );

        for (CircleObjectCache circleObjectCache in byCircle) {
          try {
            await Future.delayed(const Duration(milliseconds: 250), () {});

            CircleObject updatedObject = await getSingleObject(
              userFurnace,
              circleObjectCache.circleObjectid!,
              userCircleCache,
            );

            if (updatedObject.type == CircleObjectType.UNABLETODECRYPT) {
              circleObjectCache.retryDecrypt++;
              await TableCircleObjectCache.upsert(circleObjectCache);
            }
          } catch (e, trace) {
            LogBloc.insertError(e, trace);
          }
        }
      }
    }
  }

  ///called after keys are imported
  retryDecryption() async {
    try {
      List<Map> results = await TableCircleObjectCache.readType(
        CircleObjectType.UNABLETODECRYPT,
      );

      List<CircleObject> circleObjects =
          CircleObjectService.convertFromCachePerformant(
            globalEventBloc,
            results,
            globalState.user.id!,
          );

      if (circleObjects.isEmpty) return;

      List<UserFurnace> userFurnaces = await TableUserFurnace.readAllForUser(
        globalState.user.id,
      );

      for (UserFurnace userFurnace in userFurnaces) {
        List<UserCircleCache> userCircleCaches =
            await TableUserCircleCache.readAllForUserFurnace(
              userFurnace.pk,
              userFurnace.userid,
            );

        for (UserCircleCache userCircleCache in userCircleCaches) {
          Iterable<CircleObject> byCircle = circleObjects.where(
            (element) => element.circle!.id! == userCircleCache.circle,
          );

          for (CircleObject circleObject in byCircle) {
            circleObject.body = circleObject.encryptedBody;
            circleObject.type = circleObject.typeOriginal;
          }
          List<CircleObject> decryptedObjects =
              await ForwardSecrecy.decryptCircleObjects(
                userFurnace.userid!,
                userCircleCache.usercircle!,
                byCircle.toList(),
              );

          for (CircleObject circleObject in decryptedObjects) {
            TableCircleObjectCache.updateCacheSingleObject(
              userFurnace.userid!,
              circleObject,
            );
          }
        }
      }

      //debugPrint('break');
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleObjectBloc._retryDecryption: $error');
      rethrow;
    }
  }

  cacheObjects(
    UserFurnace userFurnace,
    List<List<CircleObject>> circleObjects,
  ) async {
    try {
      //debugPrint('cacheObjects');
      //debugPrint('deviceid: ${globalState.deviceID}');

      if (circleObjects.isNotEmpty) {
        for (var objects in circleObjects) {
          if (objects.isEmpty) continue;
          DateTime lastUpdate = objects[0].lastUpdate!;

          String circleID = objects[0].circle!.id!;

          UserCircleCache userCircleCache =
              await TableUserCircleCache.readUserCircleCacheByCircleAndUser(
                circleID,
                userFurnace.userid!,
              );

          CircleLastLocalUpdate? circleLastLocalUpdate;

          if (userCircleCache.circle != null) {
            circleLastLocalUpdate = await CircleLastLocalUpdate.read(
              userCircleCache.circle!,
            );
          }

          //update the cache
          List<CircleObject>? decryptedObjects = await updateCache(
            userFurnace,
            circleID,
            objects,
            true,
          );

          if (decryptedObjects.isNotEmpty && circleLastLocalUpdate != null) {
            //update the last fetch datetime in Hive
            await circleLastLocalUpdate.upsertDate(lastUpdate);
            //_newerCircleObjects.sink.add(decryptedObjects);
          }
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectBloc.cacheObjects: $error");
      // _newerCircleObjects.sink.addError(error);
    }
  }

  /// Update cache from a collection of circleobjects (presumably from furnace)
  Future<List<CircleObject>> updateCache(
    UserFurnace userFurnace,
    String circleID,
    List<CircleObject> circleObjects,
    bool upsert, {
    bool markRead = false,
    bool forceCache = false,
    bool reactionOnly = false,
    bool downloadImages = true,
  }) async {
    //List<CircleObject> deletedObjects = [];
    List<CircleObject> decryptedObjects = [];
    List<CircleObjectCache> cache = [];
    //debugPrint(userFurnace.userid);
    //debugPrint(circleID);

    try {
      List<CircleObject> markDelivered = [];
      markDelivered.addAll(circleObjects);

      //TODO don't decrypt objects whose body hasn't changed; test the encrypted body size

      //debugPrint('1: start of update cache ${DateTime.now()}');

      if (circleObjects.isEmpty) return circleObjects;

      String userCircleID = await TableUserCircleCache.getUserCircleID(
        userFurnace.userid!,
        circleID,
      );

      if (userCircleID.isEmpty) {
        debugPrint('userCircleID borked');
      } else {
        UserCircleCache userCircleCache = await TableUserCircleCache.read(
          userCircleID,
        );

        if (forceCache == false) {
          ///don't add items already cached
          List<CircleObject> filteredObjects =
              circleObjects
                  .where(
                    (element) =>
                        (element.type !=
                            'deleted') /* && (element.creator != null)*/,
                  )
                  .toList();
          //.where((element) =>  (element.type != 'deleted'));

          if (filteredObjects.isNotEmpty) {
            DateTime start =
                filteredObjects
                    .elementAt(filteredObjects.length - 1)
                    .lastUpdate!;

            ///TODO this should include the Seeds and not a start date
            cache = await TableCircleObjectCache.readForward(circleID, start);

            if (cache.isNotEmpty) {
              //test to see if the lastUpdatedDate changed
              for (CircleObjectCache circleObjectCache in cache) {
                // alreadyCached.addAll(circleObjects.where((element) =>
                //   element.seed == circleObjectCache.seed &&
                //      element.lastUpdate == circleObjectCache.lastUpdate));

                circleObjects.removeWhere(
                  (element) =>
                      element.seed == circleObjectCache.seed &&
                      element.lastUpdate == circleObjectCache.lastUpdate &&
                      element.refreshNeeded == false &&
                      element.type == circleObjectCache.type,
                );
              }
            }
          }
        }

        //There is nothing so return
        if (circleObjects.isEmpty) {
          ///is this an emoji only change?

          //debugPrint('only already cached items');
          if (cache.isNotEmpty) {
            List<CircleObject> alreadyCached = _convertFromCache(cache);

            return alreadyCached;
          } else {
            return circleObjects;
          }
        }

        //debugPrint('3: start delete  ${DateTime.now()}');
        //remove deletedobjeects
        List<CircleObject> deletedObjects =
            circleObjects
                .where((element) => element.type == 'deleted')
                .toList();

        List<CircleObject> oneTimeViewed =
            circleObjects
                .where((element) => element.oneTimeView == true)
                .toList();

        for (CircleObject circleObject in oneTimeViewed) {
          if (circleObject.ratchetIndexes.isEmpty) {
            await deleteOneTimeView(userCircleCache, circleObject);

            circleObjects.remove(circleObject);
          }
        }

        if (oneTimeViewed.isNotEmpty) {
          _circleObjectsDeleted.sink.add(oneTimeViewed);
        }

        if (deletedObjects.isNotEmpty) {
          TableCircleObjectCache.deleteList(globalEventBloc, deletedObjects);
          _circleObjectsDeleted.sink.add(deletedObjects);
        }

        Iterable<CircleObject> notDeleted = circleObjects.where(
          (circleObject) => circleObject.type != 'deleted',
        );

        if (notDeleted.isNotEmpty) {
          ///decryption will use compute (isolate) function.  Not supported by sqllite
          /*decryptedObjects = await FSVersionControl.decryptCircleObjects(
            userFurnace.userid!,
            userCircleID,
            notDeleted.toList(),
          );*/

          ///Pop up notification for desktop
          if (Platform.isWindows || Platform.isLinux) {}

          decryptedObjects = await ForwardSecrecy.decryptCircleObjects(
            userFurnace.userid!,
            userCircleID,
            notDeleted.toList(),
          );

          _retryFailedObjects(userFurnace, userCircleCache, decryptedObjects);

          //debugPrint('5: start upsert  ${DateTime.now()}');

          //update the database
          if (upsert) {
            await TableCircleObjectCache.upsertListofObjects(
              userFurnace.userid!,
              decryptedObjects,
              markRead: markRead,
            );

            //add the deletes back

            //don't wait
            ForwardSecrecy.ratchetReceiverKey(
              userFurnace,
              circleID,
              userCircleID,
              circleObjects: circleObjects,
            );
          } else {
            try {
              await TableCircleObjectCache.insertListofObjects(
                userFurnace.userid!,
                decryptedObjects,
                markRead: markRead,
              );
            } catch (err) {
              debugPrint('$err');

              //insert failed, force an upsert.  If it failed, it's likely due to a duplicate seed
              await TableCircleObjectCache.upsertListofObjects(
                userFurnace.userid!,
                decryptedObjects,
              );
            }
          }
        }
        //

        debugPrint('end decryption.  start caching:  ${DateTime.now()}');

        bool refreshActionNeeded = false;

        CircleAlbumBloc circleAlbumBloc = CircleAlbumBloc(globalEventBloc);

        ///Add the user to globalState.members if it doesn't exist already
        for (CircleObject circleObject in decryptedObjects) {
          circleObject.userCircleCache ??= userCircleCache;
          circleObject.userFurnace ??= userFurnace;

          if (circleObject.creator != null) {
            if (!Member.memberExists(circleObject.creator!.id!)) {
              if (globalState.members.isEmpty) {
                await MemberBloc.populateGlobalStateWithAll();

                ///TODO remove this if not the cause of colors changing

                if (!Member.memberExists(circleObject.creator!.id!)) {
                  MemberBloc memberBloc = MemberBloc();
                  memberBloc.create(
                    globalState,
                    userFurnace,
                    circleObject.creator!,
                  );
                }
              } else {
                MemberBloc memberBloc = MemberBloc();
                memberBloc.create(
                  globalState,
                  userFurnace,
                  circleObject.creator!,
                );
              }
            }
          }

          try {
            if (circleObject.type == CircleObjectType.CIRCLEIMAGE) {
              if (downloadImages) {
                CircleImageBloc circleImageBloc = CircleImageBloc(
                  globalEventBloc,
                );
                circleImageBloc.notifyWhenThumbReady(
                  userFurnace,
                  userCircleCache,
                  circleObject,
                  this,
                );
              }
            } else if (circleObject.type == CircleObjectType.CIRCLEVOTE ||
                circleObject.type == CircleObjectType.CIRCLELIST) {
              //globalEventBloc.broadcastActionNeededRefresh();
              refreshActionNeeded = true;
            } else if (circleObject.type == CircleObjectType.CIRCLEALBUM) {
              if (downloadImages) {
                circleAlbumBloc.notifyWhenAlbumReady(
                  userFurnace,
                  userCircleCache,
                  circleObject,
                  this,
                );
              }
            }

            if (circleObject.timer != null) {
              if (circleObject.timerExpires != null) {
                final int seconds =
                    DateTime.now()
                        .difference(circleObject.timerExpires!)
                        .inSeconds;

                globalEventBloc.startTimer(seconds, circleObject);
              }
            }
            if (circleObject.reactions != null) {
              globalEventBloc.setReactions(circleObject);
            }

            /*if (circleObject.pinnedUsers != null &&
                circleObject.pinnedUsers!.isNotEmpty) {
              debugPrint('here');
            }

             */
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint('CircleObjectBloc._updateCache inner loop error: $err');
          }
        }

        if ((Platform.isWindows || Platform.isLinux || Platform.isMacOS) &&
            decryptedObjects.isNotEmpty) {
          ///there are no push notifications so raise a Circle event in case the user has the Circle open
          ///(the new message badge is set in home.dart)

          globalEventBloc.broadcastRefreshCircle(circleID);
        }

        if (refreshActionNeeded) globalEventBloc.broadcastActionNeededRefresh();
      }

      if (markDelivered.isNotEmpty) {
        _circleObjectService.markDelivered(userFurnace, markDelivered);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleObjectBloc._updateCache: $error');

      rethrow;
    }

    //read items already cached.  There could have been a race condition where a object is cached from
    // Home at the same time this is processing on InsideCircle, just refresh the UI

    if (cache.isNotEmpty) {
      List<CircleObject> alreadyCached = _convertFromCache(cache);
      decryptedObjects.addAll(alreadyCached);
    }

    return decryptedObjects;
  }

  /// Convert a CircleObjectCache list to a CircleObject list
  List<CircleObject> _convertFromCache(List<CircleObjectCache> results) {
    List<CircleObject> convertValue = [];

    //convert the cache to circleobjects
    for (var circleObjectCache in results) {
      Map<String, dynamic>? decode;

      try {
        decode = json.decode(circleObjectCache.circleObjectJson!);

        CircleObject circleObject = CircleObject.fromJson(decode!);

        //check Timer
        if (circleObject.timer != null) {
          if (circleObject.timerExpires != null) {
            if (circleObject.timerExpires!.compareTo(DateTime.now()) < 0) {
              //timer expired.  Don't add this object.  Delete

              TableCircleObjectCache.delete(circleObject.id!);
              globalEventBloc.broadCastMemCacheCircleObjectsRemove([
                circleObject,
              ]);
              continue;
            }
          }
        }

        convertValue.add(circleObject);
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
        debugPrint('CircleObjectBloc._convertFromCache: $err');
      }
    }

    return convertValue;
  }

  resendFailedCircleObjects(
    GlobalEventBloc globalEventBloc,
    List<UserFurnace> userFurnaces,
  ) async {
    //return;

    try {
      //_globalEventBloc = globalEventBloc;

      List<CircleObjectCache> failedToSave =
          await TableCircleObjectCache.readPrecached();

      List<CircleObject> circleObjects = _convertFromCache(failedToSave);

      //if (circleObjects == null) return;

      for (CircleObject circleObject in circleObjects) {
        try {
          if (circleObject.seed == null) {
            ///TODO consider deleting the object RBR
            continue;
          }

          if (globalEventBloc.genericObjectExists(circleObject.seed!)) {
            continue;
          }

          globalEventBloc.addGenericObject(circleObject.seed!);

          //TODO add additional types as seed built
          UserCircleCache userCircleCache =
              await TableUserCircleCache.readUserCircleCacheByCircleAndUser(
                circleObject.circle!.id!,
                circleObject.creator!.id!,
              );
          late UserFurnace userFurnace;
          //List<UserFurnace>? userFurnaces =
          //  await _userFurnaceBloc.request(globalState.user.id, false);

          if (userCircleCache.userFurnace != null) {
            bool foundFurnace = false;

            try {
              userFurnace = userFurnaces.firstWhere(
                (furnace) => furnace.pk == userCircleCache.userFurnace,
                orElse: () => UserFurnace(),
              );

              if (userFurnace.pk != null) foundFurnace = true;
            } catch (error, trace) {
              LogBloc.insertError(error, trace);
              debugPrint('CircleObjectBloc.resendFailedCircleObjects: $error');
            }

            if (foundFurnace) {
              if (circleObject.type == CircleObjectType.CIRCLEMESSAGE ||
                  circleObject.type == CircleObjectType.CIRCLELINK ||
                  circleObject.type == CircleObjectType.CIRCLEGIF) {
                await _saveCircleObject(
                  globalEventBloc,
                  userFurnace,
                  userCircleCache,
                  circleObject,
                  true,
                );
              } else if (circleObject.type == CircleObjectType.CIRCLEIMAGE) {
                //circleObject.retries =6;

                /* try {
                File image = File(ImageCacheService.returnFullImagePath(
                    userCircleCache.circlePath!, circleObject.seed!));
                if (await image.exists()) {
                  saveCircleImageFromFile(
                      userCircleCache, userFurnace, circleObject, image);
                }
              } catch (err, trace) { LogBloc.insertError(err, trace);
                debugPrint(
                    'CircleObjectBloc.resendFailedCircleObjects circleimage if block: $err');
              }
              */
              } else if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
                /* try {

                CircleObject? uploading;
                try {
                  uploading = globalEventBloc!.fullObjects.firstWhere(
                      (element) => element.seed == circleObject.seed);
                } catch (err, trace) { LogBloc.insertError(err, trace);
                  debugPrint('break');
                }
                if (uploading == null) {
                  //did the file get cached?
                  if (VideoCacheService.isVideoCached(
                      circleObject, userCircleCache.circlePath)) {}
                  //overwrite is enable by default from AWS
                  saveCircleVideoFromFile(
                      userCircleCache, userFurnace, circleObject);
                  debugPrint("break");
                }

              } catch (err, trace) {
                LogBloc.insertError(err, trace);
                debugPrint(
                    'CircleObjectBloc.resendFailedCircleObjects circlevideo if block: $err');
              }

               */
              } else if (circleObject.type == CircleObjectType.CIRCLELIST) {
                CircleListBloc circleListBloc = CircleListBloc();
                CircleObject sinkValue = await circleListBloc.createList(
                  userCircleCache,
                  circleObject,
                  true,
                  userFurnace,
                  globalEventBloc,
                );
                _saveResults.sink.add(sinkValue);
              }
            }
          } else {
            debugPrint(
              'ERROR: CircleObjectBloc.resendFailedCircleObjects could not find the right furnace',
            );
          }
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint(
            'CircleObjectBloc.resendFailedCircleObjects loop block: $err',
          );
        }
        globalEventBloc.removeGenericObject(circleObject.seed!);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleObjectBloc.resendFailedCircleObjects: $error');
    }
  }

  /// Save a CircleObject
  saveCircleObject(
    GlobalEventBloc globalEventBloc,
    UserFurnace userFurnace,
    UserCircleCache userCircleCache,
    CircleObject circleObject,
  ) async {
    try {
      await _saveCircleObject(
        globalEventBloc,
        userFurnace,
        userCircleCache,
        circleObject,
        false,
      );
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
    }
  }

  /// Save a CircleObject
  _saveCircleObject(
    GlobalEventBloc globalEventBloc,
    UserFurnace userFurnace,
    UserCircleCache userCircleCache,
    CircleObject circleObject,
    bool retry,
  ) async {
    //List<UserCircleCache> retValue = [];

    try {
      //Create the CircleObject
      CircleObject sinkValue;

      circleObject.emojiOnly ??= false;

      if (circleObject.id == null) {
        circleObject.seed ??= const Uuid().v4();

        debugPrint(
          'CircleObjectBloc before broadcast: seed: ${circleObject.seed!},  userid: ${userFurnace.userid!}, circle: ${circleObject.circle!.id},  ${DateTime.now()} ',
        );

        globalEventBloc.addGenericObject(circleObject.seed!);
        globalEventBloc.broadcastCircleObject(circleObject);

        sinkValue = await _circleObjectService.cacheCircleObject(circleObject);

        debugPrint(
          'CircleObjectBloc after cache: seed: ${circleObject.seed!},  userid: ${userFurnace.userid!}, circle: ${circleObject.circle!.id},   ${DateTime.now()}',
        );

        if (circleObject.timer != null) {
          globalEventBloc.startTimer(circleObject.timer!, circleObject);
        }

        TableUserCircleCache.updateLastItemUpdate(
          circleObject.circle!.id,
          circleObject.creator!.id,
          sinkValue.lastUpdate,
        );

        debugPrint(
          'CircleObjectBloc after lastItemUpdate: seed: ${circleObject.seed!},  userid: ${userFurnace.userid!}, circle: ${circleObject.circle!.id},   ${DateTime.now()}',
        );
      }

      if (circleObject.type == 'circlelink') {
        CircleObject? preview;
        preview = await _linkBloc.unfurlLink(circleObject);
        if (preview != null) {
          circleObject.link = preview.link;
        }
      }

      if (circleObject.body != null)
        circleObject.body = circleObject.body!.trim();

      debugPrint(
        'CircleObjectBloc before service call: seed: ${circleObject.seed!},  userid: ${userFurnace.userid!}, circle: ${circleObject.circle!.id},  ${DateTime.now()}',
      );

      await _circleObjectService.post(
        userFurnace,
        userCircleCache,
        circleObject,
        globalEventBloc,
      );

      // sinkValue = await _circleObjectService.saveCircleObject(
      //     userFurnace, userCircleCache, circleObject, globalEventBloc);
      //
      // globalEventBloc.broadcastAndRemoveCircleObject(
      //     sinkValue, sinkValue.seed!);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');

      if (circleObject.seed != null) {
        globalEventBloc.removeGenericObject(circleObject.seed!);
      }

      if (error.toString().contains(ErrorMessages.USER_BEING_VOTED_OUT)) {
        globalEventBloc.broadcastError(ErrorMessages.USER_BEING_VOTED_OUT);
      }
    }
  }

  static processPost(
    GlobalEventBloc globalEventBloc,
    UserFurnace userFurnace,
    Map<String, dynamic> map,
    BackgroundTask backgroundTask,
  ) async {
    //CircleObject circleObject = CircleObject.fromJson(map["circleobject"]);

    ///grab the unencrypted values to revert
    var results = await TableCircleObjectCache.readMapBySeed(map["seed"]);
    List<CircleObject> cachedObjects =
        CircleObjectService.convertFromCachePerformant(
          globalEventBloc,
          results,
          userFurnace.userid!,
        );
    if (cachedObjects.isEmpty) {
      return;
    } else if (cachedObjects.length > 1) {
      LogBloc.insertLog(
        "TableCircleObjectCache.readMapBySeed returned more than one record",
        "CircleObjectBloc.processPost",
      );
    }
    CircleObject circleObject = cachedObjects.first;

    ///set the values from the background process
    DateTime created = DateTime.parse(map["created"]).toLocal();
    DateTime lastUpdate = DateTime.parse(map["lastUpdate"]).toLocal();

    circleObject.id = map["_id"];
    circleObject.lastUpdate = lastUpdate;

    if (map.containsKey('ratchetIndexes')) {
      circleObject.ratchetIndexes =
          RatchetIndexCollection.fromJSON(map, "ratchetIndexes").ratchetIndexes;
    }

    if (map.containsKey('senderRatchetPublic')) {
      circleObject.senderRatchetPublic = map["senderRatchetPublic"];
    }

    if (circleObject.created!.difference(created) <
        const Duration(seconds: 30)) {
      ///use the local date
      circleObject.created = circleObject.created!;
    }

    ///Part of the transition away from subtypes. API is not aware of a circlecredential type, so convert it here
    if (circleObject.subType != null &&
        circleObject.subType == SubType.LOGIN_INFO) {
      circleObject.type = CircleObjectType.CIRCLECREDENTIAL;
    }

    ///cache the object
    await TableCircleObjectCache.updateCacheSingleObject(
      userFurnace.userid!,
      circleObject,
    );

    TableUserCircleCache.updateLastItemUpdate(
      circleObject.circle!.id,
      circleObject.creator!.id,
      circleObject.lastUpdate,
    );

    debugPrint(
      "saveCircleObject complete: ${circleObject.created},  ${DateTime.now()}",
    );

    backgroundTask.markComplete();

    globalEventBloc.broadcastAndRemoveCircleObject(
      circleObject,
      circleObject.seed!,
    );
  }

  /// update a CircleObject
  updateCircleObject(CircleObject circleObject, UserFurnace userFurnace) async {
    //List<UserCircleCache> retValue = [];
    try {
      if (circleObject.type == 'circlelink') {
        CircleObject? preview;
        preview = await _linkBloc.unfurlLink(circleObject);
        if (preview != null) {
          circleObject.link = preview.link;
        }
      }

      if (circleObject.body != null)
        circleObject.body = circleObject.body!.trim();

      CircleObject sinkValue = await _circleObjectService.updateCircleObject(
        circleObject,
        userFurnace,
      );

      _saveResults.sink.add(sinkValue);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
    }
  }

  /// Update CircleImage with no image change
  updateCircleImageNoImageChange(
    UserCircleCache? userCircleCache,
    UserFurnace userFurnace,
    CircleObject circleObject,
  ) async {
    try {
      CircleObject sinkValue;

      sinkValue = await _circleObjectService.updateCircleObject(
        circleObject,
        userFurnace,
      );

      _saveResults.sink.add(sinkValue);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectBloc.saveCircleImage: $error");
    }
  }

  /// Pin an object
  pinCircleObject(
    UserCircleCache userCircleCache,
    UserFurnace userFurnace,
    CircleObject circleObject,
    bool circleWide,
  ) async {
    try {
      circleObject.pinned = true;

      await _circleObjectService.pinCircleObject(
        userCircleCache,
        userFurnace,
        circleObject,
        circleWide,
      );

      _saveResults.sink.add(circleObject);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectBloc.pinCircleObject: $error");
    }
  }

  /// upin an object
  unpinCircleObject(
    UserCircleCache userCircleCache,
    UserFurnace userFurnace,
    CircleObject circleObject,
  ) async {
    try {
      circleObject.pinned = false;

      await _circleObjectService.unpinCircleObject(
        userCircleCache,
        userFurnace,
        circleObject,
      );

      _saveResults.sink.add(circleObject);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectBloc.unpinCircleObject: $error");
    }
  }

  /// hide a CircleObject
  hideCircleObject(
    UserCircleCache userCircleCache,
    UserFurnace userFurnace,
    CircleObject circleObject,
  ) async {
    try {
      await _circleObjectService.hideCircleObject(
        userCircleCache,
        userFurnace,
        circleObject,
      );

      globalEventBloc.broadCastMemCacheCircleObjectsRemove([circleObject]);

      //stop process
      globalEventBloc.deletedSeeds.add(circleObject.seed!);

      //await TableCircleObjectCache.deleteBySeed(circleObject.seed!);

      if (circleObject.type == CircleObjectType.CIRCLEIMAGE) {
        BlobService.safeCancelTokens(circleObject);

        ImageCacheService.deleteCircleObjectImage(
          circleObject,
          userCircleCache.circlePath!,
        );
      } else if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
        BlobService.safeCancelTokens(circleObject);

        await VideoCacheService.deleteVideo(
          userCircleCache.circlePath!,
          circleObject,
        );
      } else if (circleObject.type == 'circlealbum') {
        BlobService.safeCancelTokens(circleObject);

        await CircleAlbumBloc.unCacheMedia(
          circleObject,
          userCircleCache.circlePath!,
        );
      }

      //if (sinkValue != null) {
      _circleObjectDeleted.sink.add(circleObject);
      globalEventBloc.broadCastMemCacheCircleObjectsRemove([circleObject]);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectBloc.hideCircleObject: $error");
    }
  }

  deleteObjects(
    UserFurnace? userFurnace,
    UserCircleCache? userCircleCache,
    List<CircleObject> circleObjects,
  ) async {
    for (CircleObject circleObject in circleObjects) {
      deleteCircleObject(userCircleCache, userFurnace, circleObject);
    }
  }

  deleteLibraryObjects(List<CircleObject> circleObjects) async {
    for (CircleObject circleObject in circleObjects) {
      deleteCircleObject(
        circleObject.userCircleCache,
        circleObject.userFurnace,
        circleObject,
      );
    }
  }

  /// Delete a CircleObject
  deleteCircleObject(
    UserCircleCache? userCircleCache,
    UserFurnace? userFurnace,
    CircleObject circleObject,
  ) async {
    try {
      CircleObject sinkValue;

      ///stop process
      globalEventBloc.deletedSeeds.add(circleObject.seed!);

      if (circleObject.type == 'circleimage') {
        BlobService.safeCancelTokens(circleObject);
      } else if (circleObject.type == 'circlevideo') {
        BlobService.safeCancelTokens(circleObject);
      } else if (circleObject.type == CircleObjectType.CIRCLEALBUM) {
        BlobService.safeCancelTokens(circleObject);
      }

      if (circleObject.id != null) {
        //delete the CircleObject from the furnace
        sinkValue = await _circleObjectService.deleteCircleObject(
          userCircleCache,
          userFurnace!,
          circleObject,
        );

        globalEventBloc.broadCastMemCacheCircleObjectsRemove([circleObject]);
      } else {
        sinkValue = circleObject;
      }

      await TableCircleObjectCache.deleteBySeed(circleObject.seed!);
      globalEventBloc.broadCastMemCacheCircleObjectsRemove([circleObject]);

      deleteObjectBlobs(userCircleCache, circleObject);
      if (circleObject.type == 'circleimage') {
        ImageCacheService.deleteCircleObjectImage(
          circleObject,
          userCircleCache!.circlePath!,
        );
      } else if (circleObject.type == 'circlevideo') {
        await VideoCacheService.deleteVideo(
          userCircleCache!.circlePath!,
          circleObject,
        );
      } else if (circleObject.type == 'circlealbum') {
        await CircleAlbumBloc.unCacheMedia(
          circleObject,
          userCircleCache!.circlePath!,
        );
      }

      //if (sinkValue != null) {
      _circleObjectDeleted.sink.add(sinkValue);
      globalEventBloc.broadCastMemCacheCircleObjectsRemove([circleObject]);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectBloc.deleteCircleObject: $error");
    }
  }

  /// Delete a CircleObject
  deleteOneTimeView(
    UserCircleCache? userCircleCache,
    CircleObject circleObject,
  ) async {
    try {
      await TableCircleObjectCache.deleteBySeed(circleObject.seed!);
      globalEventBloc.broadCastMemCacheCircleObjectsRemove([circleObject]);

      deleteObjectBlobs(userCircleCache, circleObject);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectBloc.deleteCircleObject: $error");
    }
  }

  deleteObjectBlobs(
    UserCircleCache? userCircleCache,
    CircleObject circleObject,
  ) {
    if (circleObject.type == CircleObjectType.CIRCLEIMAGE) {
      BlobService.safeCancelTokens(circleObject);
      ImageCacheService.deleteCircleObjectImage(
        circleObject,
        userCircleCache!.circlePath!,
      );
    } else if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
      BlobService.safeCancelTokens(circleObject);
      VideoCacheService.deleteVideo(userCircleCache!.circlePath!, circleObject);
    } else if (circleObject.type == CircleObjectType.CIRCLEFILE) {
      BlobService.safeCancelTokens(circleObject);
      FileCacheService.deleteFile(userCircleCache!.circlePath!, circleObject);
    }
  }

  sinkCircleObjectSave(CircleObject sinkValue) {
    _saveResults.sink.add(sinkValue);
  }

  sinkCircleObjectSaveError(SaveError error) {
    _saveFailed.sink.add(error);
  }

  /// Update users reaction
  postReaction(
    UserFurnace userFurnace,
    UserCircleCache userCircleCache,
    CircleObject circleObject,
    CircleObjectReaction circleObjectReaction,
  ) async {
    try {
      await TableCircleObjectCache.updateCacheSingleObject(
        userFurnace.userid!,
        circleObject,
      );
      userCircleCache.lastItemUpdate = DateTime.now();
      await TableUserCircleCache.upsert(userCircleCache);

      CircleObject updated = await _circleObjectService.postReaction(
        userFurnace,
        userCircleCache,
        circleObject,
        circleObjectReaction,
      );

      await updateCache(userFurnace, userCircleCache.circle!, [updated], true);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectBloc.postReaction: $error");
    }
  }

  Future<CircleObject> saveDraft(
    UserFurnace userFurnace,
    UserCircleCache userCircleCache,
    String body,
    MediaCollection? mediaCollection,
    GiphyOption? giphyOption, {
    CircleObject? preppedObject,
  }) async {
    CircleObject circleObject =
        preppedObject ??= CircleObject.prepNewCircleObject(
          userCircleCache,
          userFurnace,
          body,
          0,
          null,
        );

    circleObject.seed = const Uuid().v4();

    if (mediaCollection != null) {
      circleObject.draftMediaCollection = [];

      ///save the objects to the draft folder
      for (Media media in mediaCollection.media) {
        if (media.path.isNotEmpty) {
          media.path = await (FileSystemService.copyToDrafts(File(media.path)));
        }

        if (media.thumbnail.isNotEmpty) {
          media.thumbnail = await (FileSystemService.copyToDrafts(
            File(media.thumbnail),
          ));
        }

        circleObject.draftMediaCollection!.add(media);
      }

      //circleObject.draftMediaCollection = mediaCollection.media;

      if (mediaCollection.media.first.mediaType == MediaType.image) {
        circleObject.type = CircleObjectType.CIRCLEIMAGE;
      } else {
        circleObject.type = CircleObjectType.CIRCLEVIDEO;
      }
    } else if (giphyOption != null) {
      circleObject.gif = CircleGif();
      circleObject.type = CircleObjectType.CIRCLEGIF;
      circleObject.gif!.giphy = giphyOption.url;
      circleObject.gif!.width = giphyOption.width;
      circleObject.gif!.height = giphyOption.height;
    } else if (circleObject.subType == SubType.LOGIN_INFO) {
      circleObject.type ??= CircleObjectType.CIRCLEMESSAGE;
    } else {
      circleObject.type ??= CircleObjectType.CIRCLEMESSAGE;
    }

    circleObject.draft = true;

    await TableCircleObjectCache.updateCacheSingleObject(
      userFurnace.userid!,
      circleObject,
    );

    _saveResults.sink.add(circleObject);

    return circleObject;
  }

  deleteDraft(CircleObject circleObject) async {
    await TableCircleObjectCache.deleteDraft(circleObject.seed!);
  }

  Future<CircleObject> processReactionNotification(
    CircleObject circleObject,
    reaction,
  ) async {
    bool removed = false;
    CircleObjectReaction? found;

    circleObject.reactions ??= [];

    if (reaction.index != 1 && reaction.index != null) {
      ///old emojis
      for (CircleObjectReaction r in circleObject.reactions!) {
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

      for (CircleObjectReaction r in circleObject.reactions!) {
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
      if (reaction.index != 1 && reaction.index != null) {
        found.users.removeWhere(
          (element) => element.id == reaction.users[0].id,
        );
        if (found.users.isEmpty) {
          circleObject.reactions!.removeWhere(
            (element) => element.index == reaction.index,
          );
        }
      } else {
        found.users.removeWhere(
          (element) => element.id == reaction.users[0].id,
        );
        if (found.users.isEmpty) {
          circleObject.reactions!.removeWhere(
            (element) => element.emoji == reaction.emoji,
          );
        }
      }
    } else if (removed == false && found != null) {
      ///reaction exists, add user
      found.users.add(reaction.users[0]);
    } else {
      ///add reaction
      circleObject.reactions!.add(reaction);
    }

    await TableCircleObjectCache.upsertListofObjects('', [circleObject]);

    return circleObject;
  }

  deleteReaction(
    UserFurnace userFurnace,
    UserCircleCache userCircleCache,
    CircleObject circleObject,
    CircleObjectReaction circleObjectReaction,
    CircleObject lastInList,
  ) async {
    try {
      if (circleObjectReaction.id == null) {
        debugPrint('could not remove reaction');
        return;
      }

      await TableCircleObjectCache.updateCacheSingleObject(
        userFurnace.userid!,
        circleObject,
      );
      userCircleCache.lastItemUpdate = lastInList.lastUpdate!;
      await TableUserCircleCache.upsert(userCircleCache);

      CircleObject updated = await _circleObjectService.deleteReaction(
        userFurnace,
        userCircleCache,
        circleObject,
        circleObjectReaction,
      );

      updateCache(userFurnace, userCircleCache.circle!, [updated], true);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectBloc.postReaction: $error");
    }
  }

  reportViolation(
    UserFurnace userFurnace,
    CircleObject circleObject,
    Violation violation,
  ) async {
    try {
      _circleObjectService.reportViolation(
        userFurnace,
        circleObject,
        violation,
      );
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleObjectBloc.reportViolation $err');
    }
  }

  Future<bool> oneTimeView(
    UserFurnace userFurnace,
    CircleObject circleObject,
  ) async {
    bool allowed = false;
    try {
      allowed = await _circleObjectService.oneTimeView(
        userFurnace,
        circleObject,
      );
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectBloc.oneTimeView: $error");
      //_olderCircleObjects.sink.addError(error);
    }

    return allowed;
  }

  Future<CircleObject> fetchObjectById(String circleObjectID) async {
    CircleObjectCache circleObjectCache = await TableCircleObjectCache.get(
      circleObjectID,
    );
    Map<String, dynamic>? decode = json.decode(
      circleObjectCache.circleObjectJson!,
    );
    CircleObject circleObject = CircleObject.fromJson(decode!);
    return circleObject;
  }

  markRead(String circleObjectID) {
    TableCircleObjectCache.markRead(circleObjectID);
  }

  markReadForCircle(String circle, DateTime lastObjectCreated) async {
    await TableCircleObjectCache.markReadForCircle(circle, lastObjectCreated);
  }

  markMultipleRead(List<CircleObject> circleObjects) {
    List<String> circleObjectIDs = [];

    for (CircleObject circleObject in circleObjects) {
      circleObjectIDs.add(circleObject.id!);
    }

    TableCircleObjectCache.markMultipleRead(circleObjectIDs);
  }

  sinkVaultRefresh() {
    _refreshVault.add(true);
  }

  cleanup(UserFurnace userFurnace) async {
    ///TODO fetch a list from the server of all deleted items, or flagged as needing cleanup
    int result = await TableCircleObjectCache.delete(
      '6508a883fbba642a8543f953',
    );
    LogBloc.postLog('cleanup $result record', 'cleanup');
    result = await TableCircleObjectCache.delete('6508a5d6fbba642a85436c28');
    LogBloc.postLog('cleanup $result record', 'cleanup');
    result = await TableCircleObjectCache.delete('6508a50ba8cd3a8c99697df2');
    LogBloc.postLog('cleanup $result record', 'cleanup');

    result = await TableCircleObjectCache.delete('650646734cbe673e333b5c79');
    LogBloc.postLog('cleanup $result record', 'cleanup');

    TableCircleObjectCache.dropAndCreateView();
  }

  dispose() async {
    await _circleObjects.drain();
    _circleObjects.close();

    await _newerCircleObjects.drain();
    _newerCircleObjects.close();

    await _saveResults.drain();
    _saveResults.close();

    await _fullimageLoaded.drain();
    _fullimageLoaded.close();

    await _thumbnailLoaded.drain();
    _thumbnailLoaded.close();

    await _circleObjectDeleted.drain();
    _circleObjectDeleted.close();

    await _imageCarousel.drain();
    _imageCarousel.close();

    await _imageSaved.drain();
    _imageSaved.close();

    await _circleObjectsDeleted.drain();
    _circleObjectsDeleted.close();

    await _olderCircleObjects.drain();
    _olderCircleObjects.close();

    await _jumpToCircleObjects.drain();
    _jumpToCircleObjects.close();

    await _downloadBlobs.drain();
    await _downloadBlobs.close();

    await _saveFailed.drain();
    await _saveFailed.close();

    await _pinnedObjects.drain();
    await _pinnedObjects.close();

    await _messageFeed.drain();
    await _messageFeed.close();

    await _searchedObjects.drain();
    await _searchedObjects.close();

    await _refreshVault.drain();
    await _refreshVault.close();
  }
}
