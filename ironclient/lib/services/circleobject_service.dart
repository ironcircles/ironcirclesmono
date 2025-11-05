import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/encryption/encryptapitraffic.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy.dart';
import 'package:ironcirclesapp/models/backgroundtask.dart';
import 'package:ironcirclesapp/models/circlelastlocalupdate.dart';
import 'package:ironcirclesapp/models/circleobjectreaction.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/violation.dart';
import 'package:ironcirclesapp/services/avatar_service.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/table_backgroundtask.dart';
import 'package:ironcirclesapp/services/cache/table_circlecache.dart';
import 'package:ironcirclesapp/services/cache/table_circleobject.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';
import 'package:ironcirclesapp/utils/network.dart';
import 'package:uuid/uuid.dart';

class CircleObjectService {
  bool turnOff = false;

  void _updateMemberAttributes(
      UserFurnace userFurnace, UserCircleCollection userCircles) {
    AvatarService avatarService = AvatarService();
    avatarService.validateCurrentAvatars(
        userFurnace, userCircles); //this is async on purpose
  }

  markDelivered(UserFurnace userFurnace, List<CircleObject> received) async {
    String url;

    try {
      url = userFurnace.url! + Urls.CIRCLEOBJECTSMARKDELIVERED;

      if (await Network.isConnected()) {
        debugPrint(url);

        Device device = await globalState.getDevice();

        ///don't pass the actual objects, ids are enough
        List<String> ids = [];

        for (var element in received) {
          ids.add(element.id!);
        }

        Map map = {
          'device': device.uuid,
          'circleObjects': ids,
        };

        int retries = 0;

        map = await EncryptAPITraffic.encrypt(map);

        while (retries <= RETRIES.MAX_MESSAGE_RETRIES) {
          try {
            final response = await http.post(Uri.parse(url),
                headers: {
                  'Authorization': userFurnace.token!,
                  'Content-Type': "application/json",
                },
                body: json.encode(map));

            if (response.statusCode == 200) {
              // Map<String, dynamic> jsonResponse =
              // await EncryptAPITraffic.decryptJson(response.body);

              return;
            } else if (response.statusCode == 401) {
              await navService.logout(userFurnace);
            } else {
              debugPrint("${response.statusCode}: ${response.body}");

              if (retries == RETRIES.MAX_MESSAGE_RETRIES)
                LogBloc.insertLog('${response.statusCode} : ${response.body}',
                    'CircleObjectService.markReceived');
            }
          } on SocketException catch (err, trace) {
            debugPrint('CircleObjectService.markReceived: ${err.toString()}');
            if (retries == RETRIES.MAX_MESSAGE_RETRIES)
              LogBloc.insertError(err, trace);
          } catch (err, trace) {
            debugPrint('CircleObjectService.markReceived: ${err.toString()}');
            if (retries == RETRIES.MAX_MESSAGE_RETRIES)
              LogBloc.insertError(err, trace);
          }

          if (retries == RETRIES.MAX_MESSAGE_RETRIES)
            throw Exception('failed to mark received');

          await Future.delayed(const Duration(milliseconds: RETRIES.TIMEOUT));
          retries++;
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectService: markReceived: $error");
    }
  }

  Future<List<List<CircleObject>>> getNewForUserCircles(
      UserFurnace userFurnace,
      List<String?>? openGuarded,
      List<CircleLastLocalUpdate> circleLastUpdates) async {
    String url;

    try {
      if (turnOff) return [[]];

      url = userFurnace.url! + Urls.CIRCLEOBJECTSALLUSERCIRCLES;

      openGuarded ??= [];

      if (await Network.isConnected()) {
        debugPrint(url);

        Device device = await globalState.getDevice();

        Map map = {
          'userid': userFurnace.userid!,
          'device': device.uuid,
        };

        if (openGuarded.isNotEmpty) {
          map["openguarded"] = openGuarded.toString();
        }

        if (circleLastUpdates.isNotEmpty) {
          map["circlelastupdates"] = circleLastUpdates;
        }

        int retries = 0;

        map = await EncryptAPITraffic.encrypt(map);

        while (retries <= RETRIES.MAX_FETCH_RETRY) {
          try {
            final response = await http.post(Uri.parse(url),
                headers: {
                  'Authorization': userFurnace.token!,
                  'Content-Type': "application/json",
                },
                body: json.encode(map));

            if (response.statusCode == 200) {
              Map<String, dynamic> jsonResponse =
                  await EncryptAPITraffic.decryptJson(response.body);

              List<List<CircleObject>> circleObjects = [];

              if (jsonResponse.containsKey("refreshNeededObjects")) {
                try {
                  CircleObjectCollection circleObjectCollection =
                      CircleObjectCollection.fromJSON(jsonResponse,
                          key: "refreshNeededObjects");

                  if (circleObjectCollection.circleObjects.isNotEmpty) {
                    for (CircleObject circleObject
                        in circleObjectCollection.circleObjects) {
                      circleObject.refreshNeeded = true;
                    }

                    circleObjects.add(circleObjectCollection.circleObjects);

                    //markReceived(
                    //  userFurnace, circleObjectCollection.circleObjects);
                  }
                } catch (err, trace) {
                  LogBloc.insertError(err, trace);
                }
              }

              if (jsonResponse.containsKey('circleobjects')) {
                for (var object in jsonResponse['circleobjects']) {
                  //debugPrint('asdfasdfasfd');

                  List<CircleObject> toAdd = [];

                  for (var individual in object) {
                    try {
                      if (individual.containsKey(
                          "ratchetIndexes") /*&& individual["type"] != 'deleted'*/) {
                        if (individual["type"] !=
                                CircleObjectType.SYSTEMMESSAGE &&
                            individual["type"] != CircleObjectType.CIRCLEVOTE) {
                          if (individual["ratchetIndexes"].length == 0)
                            continue;

                          if (individual["ratchetIndexes"][0] == null) continue;
                        }
                      }

                      toAdd.add(CircleObject.fromJson(individual));
                    } catch (err, trace) {
                      LogBloc.insertError(err, trace);
                      debugPrint('refresh crash');
                      //rethrow;
                    }
                  }

                  circleObjects.add(toAdd);

                  // circleObjects.addAll(CircleObjectCollection.fromJSON(object).circleObjects);
                }
              }
              return circleObjects;
            } else if (response.statusCode == 401) {
              await navService.logout(userFurnace);
              return [[]];
            } else {
              debugPrint("${response.statusCode}: ${response.body}");
              if (retries == RETRIES.MAX_FETCH_RETRY)
                LogBloc.insertLog('${response.statusCode} : ${response.body}',
                    'CircleObjectService.getNewForUserCircles');
            }
          } on SocketException catch (err, trace) {
            debugPrint(
                'CircleObjectService.getNewForUserCircles: ${err.toString()}');
            if (retries == RETRIES.MAX_FETCH_RETRY)
              LogBloc.insertError(err, trace);
          } catch (err, trace) {
            debugPrint(
                'CircleObjectService.getNewForUserCircles: ${err.toString()}');
            if (retries == RETRIES.MAX_FETCH_RETRY)
              LogBloc.insertError(err, trace);
          }

          if (retries == RETRIES.MAX_FETCH_RETRY)
            throw Exception('failed to get circle objects: $url');

          await Future.delayed(const Duration(milliseconds: RETRIES.TIMEOUT));
          retries++;
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectService: fetchCircleObjects: $error");
    }
    return [];
  }

  Future<CircleObject> getSingleObject(
    UserFurnace userFurnace,
    String circleObjectID,
    String circleID,
  ) async {
    String url;

    try {
      url = userFurnace.url! + Urls.CIRCLEOBJECTS_GET_SINGLE;

      if (await Network.isConnected()) {
        debugPrint(url);

        int retries = 0;

        Map map = {
          'circleObjectID': circleObjectID,
          'circleID': circleID,
        };

        map = await EncryptAPITraffic.encrypt(map);

        while (retries <= RETRIES.MAX_FETCH_RETRY) {
          try {
            final response = await http.post(Uri.parse(url),
                headers: {
                  'Authorization': userFurnace.token!,
                  'Content-Type': "application/json",
                },
                body: json.encode(map));

            if (response.statusCode == 200) {
              Map<String, dynamic> jsonResponse =
                  await EncryptAPITraffic.decryptJson(response.body);
              if (jsonResponse.containsKey('circleObject')) {
                CircleObject circleObject =
                    CircleObject.fromJson(jsonResponse["circleObject"]);

                return circleObject;
              }
            } else if (response.statusCode == 401) {
              await navService.logout(userFurnace);
              return CircleObject(ratchetIndexes: []);
            } else {
              debugPrint("${response.statusCode}: ${response.body}");
              if (retries == RETRIES.MAX_FETCH_RETRY)
                LogBloc.insertLog('${response.statusCode} : ${response.body}',
                    'CircleObjectService.fetchCircleObjects');
            }
          } on SocketException catch (err, trace) {
            debugPrint(
                'CircleObjectService.fetchCircleObjects: ${err.toString()}');
            if (retries == RETRIES.MAX_FETCH_RETRY)
              LogBloc.insertError(err, trace);
          } catch (err, trace) {
            debugPrint(
                'CircleObjectService.fetchCircleObjects: ${err.toString()}');
            if (retries == RETRIES.MAX_FETCH_RETRY)
              LogBloc.insertError(err, trace);
          }

          if (retries == RETRIES.MAX_FETCH_RETRY)
            throw Exception('failed to get circle objects');

          await Future.delayed(const Duration(milliseconds: RETRIES.TIMEOUT));
          retries++;
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectService: getSingleObject: $error");
    }

    return CircleObject(ratchetIndexes: []);
  }

  Future<List<CircleObject>> fetchCircleObjects(
      String circleID, UserFurnace userFurnace, int amount) async {
    String url;

    try {
      if (turnOff) return [];

      url = userFurnace.url! + Urls.CIRCLEOBJECTSBYCIRCLE;

      Map map = {
        'circleID': circleID,
        'amount': amount,
      };

      if (await Network.isConnected()) {
        debugPrint(url);

        int retries = 0;

        map = await EncryptAPITraffic.encrypt(map);

        while (retries <= RETRIES.MAX_FETCH_RETRY) {
          try {
            final response = await http.post(Uri.parse(url),
                headers: {
                  'Authorization': userFurnace.token!,
                  'Content-Type': "application/json",
                },
                body: json.encode(map));

            if (response.statusCode == 200) {
              Map<String, dynamic> jsonResponse =
                  await EncryptAPITraffic.decryptJson(response.body);

              if (jsonResponse.containsKey('usercircles')) {
                _updateMemberAttributes(userFurnace,
                    UserCircleCollection.fromJSON(jsonResponse, "usercircles"));
              }

              ///CO-REMOVE
              /*
              if (jsonResponse.containsKey("usercircle")) {
                UserCircle userCircle =
                    UserCircle.fromJson(jsonResponse['usercircle']);

               await TableUserCircleCache.updateAccessAndBadge(
                    circleID,
                    userFurnace.userid,
                    userCircle.showBadge,
                    userCircle.lastAccessed);


              }
               */

              if (jsonResponse.containsKey("circle")) {
                Circle circle = Circle.fromJson(jsonResponse['circle']);

                TableCircleCache.upsert(circle);
              }

              if (jsonResponse.containsKey('circleobjects')) {
                CircleObjectCollection circleObjectCollection =
                    CircleObjectCollection.fromJSON(jsonResponse);
                return circleObjectCollection.circleObjects;
              }
            } else if (response.statusCode == 401) {
              await navService.logout(userFurnace);
              return [];
            } else {
              debugPrint("${response.statusCode}: ${response.body}");
              if (retries == RETRIES.MAX_FETCH_RETRY)
                LogBloc.insertLog('${response.statusCode} : ${response.body}',
                    'CircleObjectService.fetchCircleObjects');
            }
          } on SocketException catch (err, trace) {
            debugPrint(
                'CircleObjectService.fetchCircleObjects: ${err.toString()}');
            if (retries == RETRIES.MAX_FETCH_RETRY)
              LogBloc.insertError(err, trace);
          } catch (err, trace) {
            debugPrint(
                'CircleObjectService.fetchCircleObjects: ${err.toString()}');
            if (retries == RETRIES.MAX_FETCH_RETRY)
              LogBloc.insertError(err, trace);
          }

          if (retries == RETRIES.MAX_FETCH_RETRY)
            throw Exception('failed to get circle objects');

          await Future.delayed(const Duration(milliseconds: RETRIES.TIMEOUT));
          retries++;
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectService: fetchCircleObjects: $error");
    }

    return [];
  }

  Future<List<CircleObject>> getPinnedPosts(
      GlobalEventBloc globalEventBloc, UserCircleCache userCircleCache) async {
    List<CircleObject> retValue = [];
    try {
      List<Map> results =
          await TableCircleObjectCache.readPinnedPosts(userCircleCache.circle!);

      if (results.isNotEmpty)
        retValue = CircleObjectService.convertFromCachePerformant(
            globalEventBloc, results, globalState.user.id!);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectService: fetchCircleObjects: $error");
    }

    return retValue;
  }

  Future<List<CircleObject>> search(GlobalEventBloc globalEventBloc,
      UserCircleCache userCircleCache, String searchText) async {
    List<CircleObject> retValue = [];
    try {
      searchText = searchText.toLowerCase().replaceAll(' ', '');
      if (searchText.isEmpty) {
        return retValue;
      } else {
        List<Map> results = await TableCircleObjectCache.search(
            userCircleCache.circle!, searchText);

        List<CircleObject> preFilter =
            CircleObjectService.convertFromCachePerformant(
                globalEventBloc, results, globalState.user.id!);

        debugPrint('break');

        if (searchText == "credential") {
          /// researching the database as credential is actually stored as the subtype LOGIN_INFO
          results = await TableCircleObjectCache.search(
              userCircleCache.circle!, "\"subType\":0");
          List<CircleObject> preFilter =
              CircleObjectService.convertFromCachePerformant(
                  globalEventBloc, results, globalState.user.id!);
          retValue.addAll(preFilter);
        } else if (searchText == "link") {
          retValue.addAll(preFilter.where(
              (element) => (element.type == CircleObjectType.CIRCLELINK)));
        } else if (searchText == "event") {
          retValue.addAll(preFilter.where(
              (element) => (element.type == CircleObjectType.CIRCLEEVENT)));
        } else if (searchText == "list") {
          retValue.addAll(preFilter.where(
              (element) => (element.type == CircleObjectType.CIRCLELIST)));
        } else if (searchText == "recipe") {
          retValue.addAll(preFilter.where(
              (element) => (element.type == CircleObjectType.CIRCLERECIPE)));
        }

        ///add matching body
        retValue.addAll(preFilter.where(
            (element) => element.body!.toLowerCase().contains(searchText)));

        ///add matching url
        retValue.addAll(preFilter.where((element) =>
            (element.type == CircleObjectType.CIRCLELINK &&
                element.link!.url!.toLowerCase().contains(searchText))));

        ///add matching events
        retValue.addAll(preFilter.where((element) =>
            (element.type == CircleObjectType.CIRCLEEVENT &&
                ((element.event!.title.toLowerCase().contains(searchText)) ||
                    (element.event!.description
                        .toLowerCase()
                        .contains(searchText)) ||
                    (element.event!.location
                        .toLowerCase()
                        .contains(searchText))))));

        ///add matching credentials
        retValue.addAll(preFilter.where((element) => (element.subType != null &&
                (element.subString1 != null &&
                    element.subString1!.toLowerCase().contains(searchText)) ||
            (element.subString2 != null &&
                element.subString2!.toLowerCase().contains(searchText)) ||
            (element.subString3 != null &&
                element.subString3!.toLowerCase().contains(searchText)) ||
            (element.subString4 != null &&
                element.subString4!.toLowerCase().contains(searchText)))));

        ///add matching lists
        retValue.addAll(preFilter.where((element) =>
            element.type == CircleObjectType.CIRCLELIST &&
            ((element.list!.name!.toLowerCase().contains(searchText)) ||
                (element.list!.tasks!
                    .where((element) =>
                        element.name!.toLowerCase().contains(searchText))
                    .isNotEmpty))));

        ///add matching recipes
        retValue.addAll(preFilter.where((element) =>
            element.type == CircleObjectType.CIRCLERECIPE &&
            ((element.recipe!.name!.toLowerCase().contains(searchText)) ||
                (element.recipe!.notes!.toLowerCase().contains(searchText)) ||
                (element.recipe!.ingredients!
                    .where((element) =>
                        element.name!.toLowerCase().contains(searchText))
                    .isNotEmpty) ||
                (element.recipe!.instructions!
                    .where((element) =>
                        element.name!.toLowerCase().contains(searchText))
                    .isNotEmpty))));

        ///sort the assembled list
        retValue.sort((a, b) => a.lastUpdate!.compareTo(b.lastUpdate!));

        ///remove duplicates
        final ids = <dynamic>{};
        retValue.retainWhere((x) => ids.add(x.seed));
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectService: fetchCircleObjects: $error");
    }

    return retValue;
  }

  Future<List<CircleObject>> vaultObjectSearch(GlobalEventBloc globalEventBloc,
      String type, UserCircleCache userCircleCache, String searchText) async {
    List<CircleObject> retValue = [];
    try {
      searchText = searchText.toLowerCase().replaceAll(' ', '');
      if (searchText.isEmpty) {
        return retValue;
      } else {
        List<Map> results = await TableCircleObjectCache.search(
            userCircleCache.circle!, searchText);

        List<CircleObject> preFilter =
            CircleObjectService.convertFromCachePerformant(
                globalEventBloc, results, globalState.user.id!);

        debugPrint('break');

        if (type == "Credentials") {
          /// researching the database as credential is actually stored as the subtype LOGIN_INFO
          results = await TableCircleObjectCache.search(
              userCircleCache.circle!, "\"subType\":0");
          List<CircleObject> preFilter =
              CircleObjectService.convertFromCachePerformant(
                  globalEventBloc, results, globalState.user.id!);
          //retValue.addAll(preFilter);
          ///add matching credentials
          retValue.addAll(preFilter.where((element) => (element.subType !=
                      null &&
                  (element.subString1 != null &&
                      element.subString1!.toLowerCase().contains(searchText)) ||
              (element.subString2 != null &&
                  element.subString2!.toLowerCase().contains(searchText)) ||
              (element.subString3 != null &&
                  element.subString3!.toLowerCase().contains(searchText)) ||
              (element.subString4 != null &&
                  element.subString4!.toLowerCase().contains(searchText)))));
        } else if (type == "Links") {
          ///add matching url and matching body
          retValue.addAll(preFilter.where((element) =>
              (element.type == CircleObjectType.CIRCLELINK &&
                      element.link!.url!.toLowerCase().contains(searchText) ||
                  element.link!.title!.contains(searchText) ||
                  element.link!.description!.contains(searchText) ||
                  element.type == CircleObjectType.CIRCLELINK &&
                      element.body!.toLowerCase().contains(searchText))));
          // retValue.addAll(preFilter.where((element) =>
          // (element.type == CircleObjectType.CIRCLELINK)));
        } else if (type == "Events") {
          ///add matching events
          retValue.addAll(preFilter.where((element) =>
              (element.type == CircleObjectType.CIRCLEEVENT &&
                  ((element.event!.title.toLowerCase().contains(searchText)) ||
                      (element.event!.description
                          .toLowerCase()
                          .contains(searchText)) ||
                      (element.event!.location
                          .toLowerCase()
                          .contains(searchText))))));
          // retValue.addAll(preFilter.where((element) =>
          // (element.type == CircleObjectType.CIRCLEEVENT)));
        } else if (type == "Lists") {
          ///add matching lists
          retValue.addAll(preFilter.where((element) =>
              element.type == CircleObjectType.CIRCLELIST &&
              ((element.list!.name!.toLowerCase().contains(searchText)) ||
                  (element.list!.tasks!
                      .where((element) =>
                          element.name!.toLowerCase().contains(searchText))
                      .isNotEmpty))));
          // retValue.addAll(preFilter.where((element) =>
          // (element.type == CircleObjectType.CIRCLELIST)));
        } else if (type == "Recipes") {
          ///add matching recipes
          retValue.addAll(preFilter.where((element) =>
              element.type == CircleObjectType.CIRCLERECIPE &&
              ((element.recipe!.name!.toLowerCase().contains(searchText)) ||
                  (element.recipe!.notes!.toLowerCase().contains(searchText)) ||
                  (element.recipe!.ingredients!
                      .where((element) =>
                          element.name!.toLowerCase().contains(searchText))
                      .isNotEmpty) ||
                  (element.recipe!.instructions!
                      .where((element) =>
                          element.name!.toLowerCase().contains(searchText))
                      .isNotEmpty))));
          // retValue.addAll(preFilter.where((element) =>
          // (element.type == CircleObjectType.CIRCLERECIPE)));
        } else if (type == "Notes") {
          ///add matching body
          retValue.addAll(preFilter.where(
              (element) => element.body!.toLowerCase().contains(searchText)));
        }

        ///sort the assembled list
        retValue.sort((a, b) => a.lastUpdate!.compareTo(b.lastUpdate!));

        ///remove duplicates
        final ids = Set();
        retValue.retainWhere((x) => ids.add(x.seed));
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectService: fetchCircleObjects: $error");
    }

    return retValue;
  }

  /*Future<List<CircleObject>> getMessageFeed(List<UserFurnace> userFurnaces,
      List<UserCircleCache> userCircleCaches) async {
    List<CircleObject> retValue = [];
    try {
      List<String> circleIDs = [];
      for (UserCircleCache userCircleCache in userCircleCaches) {
        circleIDs.add(userCircleCache.circle!);
      }

      List<Map> results =
          await TableCircleObjectCache.getMessageFeed(circleIDs, 800);

      if (results.isNotEmpty)
        retValue =
            CircleObjectService.convertFromCachePerformantWithHitchhikers(
                results, userFurnaces, userCircleCaches);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectService.getMessageFeed: " + error.toString());
    }

    return retValue;
  }

   */

  Future<List<CircleObject>> getMessageFeed(
      GlobalEventBloc globalEventBloc,
      List<UserFurnace> userFurnaces,
      List<UserCircleCache> userCircleCaches,
      bool onlyBadged) async {
    List<CircleObject> retValue = [];
    try {
      List<Map> results = [];

      for (UserCircleCache userCircleCache in userCircleCaches) {
        if (onlyBadged) {
          if (userCircleCache.showBadge == false) continue;

          ///skip
        }

        ///don't add results for guarded circles (hidden circles are only included if they are open)
        if (!userCircleCache.guarded!)
          results.addAll(await TableCircleObjectCache.getMessageFeedByCircle(
              userCircleCache, 500));
      }

      //List<Map> results = await TableCircleObjectCache.getMessageFeed(circleIDS, 500);

      if (results.isNotEmpty)
        retValue =
            CircleObjectService.convertFromCachePerformantWithHitchhikers(
                globalEventBloc, results, userFurnaces, userCircleCaches);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectService.getMessageFeed: $error");
    }

    return retValue;
  }

  Future<List<CircleObject>> fetchNewerThan(String circleID,
      UserFurnace userFurnace, DateTime lastUpdate, bool updateBadge) async {
    String url;

    try {
      if (turnOff) return [];

      List<CircleObject> retValue = [];

      // url =
      //     "${userFurnace.url!}${Urls.CIRCLEOBJECTSBYCIRCLENEW}$circleID&${lastUpdate.toUtc()}&$updateBadge";
      url = userFurnace.url! + Urls.CIRCLEOBJECTSBYCIRCLENEW;

      Map map = {
        'circleID': circleID,
        'lastUpdate': lastUpdate.toUtc().toString(),
        'updateBadge': updateBadge,
      };

      map = await EncryptAPITraffic.encrypt(map);

      Device device = await globalState.getDevice();

      if (userFurnace.token == null || device.uuid == null) {
        LogBloc.insertLog(
            'userFurnace.token: ${userFurnace.token}, device.uuid:${device.uuid}',
            'CircleObjectService fetchNewerThan');
        return [];
      }

      if (await Network.isConnected()) {
        debugPrint("$url ${DateTime.now().toLocal()}");

        int retries = 0;

        while (retries <= RETRIES.MAX_FETCH_RETRY) {
          try {
            final response = await http.post(Uri.parse(url),
                headers: {
                  'Authorization': userFurnace.token!,
                  //'device': device.uuid!,
                  'Content-Type': "application/json",
                },
                body: json.encode(map));

            if (response.statusCode == 200) {
              Map<String, dynamic> jsonResponse =
                  await EncryptAPITraffic.decryptJson(response.body);

              if (jsonResponse.containsKey('usercircles')) {
                _updateMemberAttributes(userFurnace,
                    UserCircleCollection.fromJSON(jsonResponse, "usercircles"));
              }

              ///CO-REMOVE
              /*if (jsonResponse.containsKey("usercircle")) {
                UserCircle userCircle =
                    UserCircle.fromJson(jsonResponse['usercircle']);
                TableUserCircleCache.updateAccessAndBadge(
                    circleID,
                    userFurnace.userid,
                    userCircle.showBadge,
                    userCircle.lastAccessed);
              }

               */

              if (jsonResponse.containsKey("circle")) {
                Circle circle = Circle.fromJson(jsonResponse['circle']);

                TableCircleCache.upsert(circle);
              }

              if (jsonResponse.containsKey("refreshNeededObjects")) {
                CircleObjectCollection circleObjectCollection =
                    CircleObjectCollection.fromJSON(jsonResponse,
                        key: "refreshNeededObjects");

                for (CircleObject circleObject
                    in circleObjectCollection.circleObjects) {
                  circleObject.refreshNeeded = true;
                }

                retValue.addAll(circleObjectCollection.circleObjects);
              }

              if (jsonResponse.containsKey("circleobjects")) {
                CircleObjectCollection circleObjectCollection =
                    CircleObjectCollection.fromJSON(jsonResponse);

                retValue.addAll(circleObjectCollection.circleObjects);
              }

              return retValue;
            } else if (response.statusCode == 401) {
              await navService.logout(userFurnace);
              return retValue;
            } else {
              debugPrint("${response.statusCode}: ${response.body}");

              if (retries == RETRIES.MAX_FETCH_RETRY)
                LogBloc.insertLog('${response.statusCode} : ${response.body}',
                    'CircleObjectService.fetchNewerThan');
            }
          } on SocketException catch (err, trace) {
            debugPrint('CircleObjectService.fetchNewerThan: ${err.toString()}');
            if (retries == RETRIES.MAX_FETCH_RETRY)
              LogBloc.insertError(err, trace);
          } catch (err, trace) {
            debugPrint('CircleObjectService.fetchNewerThan: ${err.toString()}');
            if (retries == RETRIES.MAX_FETCH_RETRY)
              LogBloc.insertError(err, trace);
          }

          if (retries == RETRIES.MAX_FETCH_RETRY)
            throw Exception('failed to get circle objects');

          await Future.delayed(const Duration(milliseconds: RETRIES.TIMEOUT));
          retries++;
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectService.fetchNewerThan: $error");
    }

    return [];
  }

  Future<List<CircleObject>> fetchOlderThan(
      String circleID, UserFurnace userFurnace, DateTime created) async {
    List<CircleObject> retValue = [];

    try {
      if (turnOff) return [];

      // String url =
      //     "${userFurnace.url!}${Urls.CIRCLEOBJECTSBYCIRCLEOLDER}$circleID&${created.toUtc()}";
      String url = userFurnace.url! + Urls.CIRCLEOBJECTSBYCIRCLEOLDER;

      if (await Network.isConnected()) {
        Map map = {
          'circleID': circleID,
          'created': created.toUtc().toString(),
        };

        map = await EncryptAPITraffic.encrypt(map);

        debugPrint("$url ${DateTime.now().toLocal()}");

        int retries = 0;

        while (retries <= RETRIES.MAX_FETCH_RETRY) {
          try {
            final response = await http.post(Uri.parse(url),
                headers: {
                  'Authorization': userFurnace.token!,
                  'Content-Type': "application/json",
                },
                body: json.encode(map));

            if (response.statusCode == 200) {
              Map<String, dynamic> jsonResponse =
                  await EncryptAPITraffic.decryptJson(response.body);

              if (jsonResponse.containsKey("circleobjects")) {
                CircleObjectCollection circleObjectCollection =
                    CircleObjectCollection.fromJSON(jsonResponse);

                retValue = circleObjectCollection.circleObjects;
              }
              return retValue;
            } else if (response.statusCode == 401) {
              await navService.logout(userFurnace);
              return retValue;
            } else {
              debugPrint("${response.statusCode}: ${response.body}");
              if (retries == RETRIES.MAX_FETCH_RETRY)
                LogBloc.insertLog('${response.statusCode} : ${response.body}',
                    'CircleObjectService.fetchOlderThan');
            }
          } on SocketException catch (err, trace) {
            debugPrint('CircleObjectService.fetchOlderThan: ${err.toString()}');
            if (retries == RETRIES.MAX_FETCH_RETRY)
              LogBloc.insertError(err, trace);
          } catch (err, trace) {
            debugPrint('CircleObjectService.fetchOlderThan: ${err.toString()}');
            if (retries == RETRIES.MAX_FETCH_RETRY)
              LogBloc.insertError(err, trace);
          }

          if (retries == RETRIES.MAX_FETCH_RETRY)
            throw Exception('failed to get circle objects');

          await Future.delayed(const Duration(milliseconds: RETRIES.TIMEOUT));
          retries++;
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectService.fetchOlderThan: $error");

      rethrow;
    }

    return retValue;
  }

  Future<List<CircleObject>> fetchJumpTo(String circleID,
      UserFurnace userFurnace, DateTime cacheDate, DateTime jumpTo) async {
    List<CircleObject> retValue = [];

    try {
      // String url =
      //     "${userFurnace.url!}${Urls.CIRCLEOBJECTSBYCIRCLEJUMPTDATE}$circleID&${cacheDate.toUtc()}&${jumpTo.toUtc()}";

      String url = userFurnace.url! + Urls.CIRCLEOBJECTSBYCIRCLEJUMPTDATE;

      if (await Network.isConnected()) {
        Map map = {
          'circleID': circleID,
          'cacheDate': cacheDate.toUtc().toString(),
          'jumpTo': jumpTo.toUtc().toString(),
        };

        map = await EncryptAPITraffic.encrypt(map);

        debugPrint("$url ${DateTime.now().toLocal()}");

        int retries = 0;

        while (retries <= RETRIES.MAX_FETCH_RETRY) {
          try {
            final response = await http.post(Uri.parse(url),
                headers: {
                  'Authorization': userFurnace.token!,
                  'Content-Type': "application/json",
                },
                body: json.encode(map));

            if (response.statusCode == 200) {
              Map<String, dynamic> jsonResponse =
                  await EncryptAPITraffic.decryptJson(response.body);

              if (jsonResponse.containsKey("circleobjects")) {
                CircleObjectCollection circleObjectCollection =
                    CircleObjectCollection.fromJSON(jsonResponse);

                return circleObjectCollection.circleObjects;
              } else
                return [];
            } else if (response.statusCode == 401) {
              await navService.logout(userFurnace);
              return retValue;
            } else {
              debugPrint("${response.statusCode}: ${response.body}");
              if (retries == RETRIES.MAX_FETCH_RETRY)
                LogBloc.insertLog('${response.statusCode} : ${response.body}',
                    'CircleObjectService.fetchJumpTo');
            }
          } on SocketException catch (err, trace) {
            debugPrint('CircleObjectService.fetchJumpTo: ${err.toString()}');
            if (retries == RETRIES.MAX_FETCH_RETRY)
              LogBloc.insertError(err, trace);
          } catch (err, trace) {
            debugPrint('CircleObjectService.fetchJumpTo: ${err.toString()}');
            if (retries == RETRIES.MAX_FETCH_RETRY)
              LogBloc.insertError(err, trace);
          }

          if (retries == RETRIES.MAX_FETCH_RETRY)
            throw Exception('failed to get circle objects');

          await Future.delayed(const Duration(milliseconds: RETRIES.TIMEOUT));
          retries++;
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectService.fetchJumpTo: $error");
      rethrow;
    }

    return retValue;
  }

  Future<CircleObject> pinCircleObject(
      UserCircleCache userCircleCache,
      UserFurnace userFurnace,
      CircleObject circleObject,
      bool circleWide) async {
    try {
      String url =
          userFurnace.url! + Urls.CIRCLEOBJECT_PINOBJECT + circleObject.id!;

      Device device = await globalState.getDevice();

      Map map = {
        'circleid': userCircleCache.circle!,
        'circleWide': circleWide,
        'device': device.uuid!,
      };

      if (await Network.isConnected()) {
        map = await EncryptAPITraffic.encrypt(map);

        debugPrint(url);

        int retries = 0;

        while (retries <= RETRIES.MAX_MESSAGE_RETRIES) {
          try {
            final response = await http.post(Uri.parse(url),
                headers: {
                  'Authorization': userFurnace.token!,
                  'Content-Type': "application/json",
                },
                body: json.encode(map));

            if (response.statusCode == 200) {
              Map<String, dynamic> jsonResponse =
                  await EncryptAPITraffic.decryptJson(response.body);

              CircleObject temp =
                  CircleObject.fromJson(jsonResponse["circleObject"]);
              circleObject.pinned = true;
              circleObject.pinnedUsers = temp.pinnedUsers;

              await TableCircleObjectCache.updateCacheSingleObject(
                  userFurnace.userid!, circleObject);

              return circleObject;
            } else if (response.statusCode == 401) {
              await navService.logout(userFurnace);
              return circleObject;
            } else {
              debugPrint("${response.statusCode}: ${response.body}");
              if (retries == RETRIES.MAX_MESSAGE_RETRIES)
                LogBloc.insertLog('${response.statusCode} : ${response.body}',
                    'CircleObjectService.pinCircleObject');
            }
          } on SocketException catch (err, trace) {
            debugPrint(
                'CircleObjectService.pinCircleObject: ${err.toString()}');
            if (retries == RETRIES.MAX_MESSAGE_RETRIES)
              LogBloc.insertError(err, trace);
          } catch (err, trace) {
            debugPrint(
                'CircleObjectService.pinCircleObject: ${err.toString()}');
            if (retries == RETRIES.MAX_MESSAGE_RETRIES)
              LogBloc.insertError(err, trace);
          }

          if (retries == RETRIES.MAX_MESSAGE_RETRIES)
            throw Exception('failed to pin post');

          await Future.delayed(const Duration(milliseconds: RETRIES.TIMEOUT));
          retries++;
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleObjectService.deleteCircleObject: ${err.toString()}');
      rethrow;
    }

    return circleObject;
  }

  Future<CircleObject> unpinCircleObject(UserCircleCache userCircleCache,
      UserFurnace userFurnace, CircleObject circleObject) async {
    try {
      String url = userFurnace.url! + Urls.CIRCLEOBJECT_UNPINOBJECT;

      Device device = await globalState.getDevice();

      Map map = {
        'circleObjectID': circleObject.id!,
        'circleid': userCircleCache.circle!,
        'device': device.uuid,
      };

      if (await Network.isConnected()) {
        map = await EncryptAPITraffic.encrypt(map);

        debugPrint(url);

        int retries = 0;

        while (retries <= RETRIES.MAX_MESSAGE_RETRIES) {
          try {
            final response = await http.post(Uri.parse(url),
                headers: {
                  'Authorization': userFurnace.token!,
                  'Content-Type': "application/json",
                },
                body: json.encode(map));

            if (response.statusCode == 200) {
              // Map<String, dynamic> jsonResponse =
              // await EncryptAPITraffic.decryptJson(response.body);

              await TableCircleObjectCache.updateCacheSingleObject(
                  userFurnace.userid!, circleObject);

              return circleObject;
            } else if (response.statusCode == 401) {
              await navService.logout(userFurnace);
              return circleObject;
            } else {
              debugPrint("${response.statusCode}: ${response.body}");
              if (retries == RETRIES.MAX_MESSAGE_RETRIES)
                LogBloc.insertLog('${response.statusCode} : ${response.body}',
                    'CircleObjectService.unpinCircleObject');
            }
          } on SocketException catch (err, trace) {
            debugPrint(
                'CircleObjectService.unpinCircleObject: ${err.toString()}');
            if (retries == RETRIES.MAX_MESSAGE_RETRIES)
              LogBloc.insertError(err, trace);
          } catch (err, trace) {
            debugPrint(
                'CircleObjectService.unpinCircleObject: ${err.toString()}');
            if (retries == RETRIES.MAX_MESSAGE_RETRIES)
              LogBloc.insertError(err, trace);
          }

          if (retries == RETRIES.MAX_MESSAGE_RETRIES)
            throw Exception('failed to unpin post');

          await Future.delayed(const Duration(milliseconds: RETRIES.TIMEOUT));
          retries++;
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleObjectService.deleteCircleObject: ${err.toString()}');
      rethrow;
    }

    return circleObject;
  }

  Future<CircleObject> hideCircleObject(UserCircleCache userCircleCache,
      UserFurnace userFurnace, CircleObject circleObject) async {
    try {
      String url = userFurnace.url! + Urls.CIRCLEOBJECT_HIDE + 'undefined';

      var connectivityResult = await (Connectivity().checkConnectivity());

      Map map = {
        'circleObjectID': circleObject.id!,
        'circleid': userCircleCache.circle!,
      };

      if (await Network.isConnected()) {
        debugPrint(url);

        int retries = 0;

        map = await EncryptAPITraffic.encrypt(map);

        while (retries <= RETRIES.MAX_MESSAGE_RETRIES) {
          try {
            final response = await http.put(Uri.parse(url),
                headers: {
                  'Authorization': userFurnace.token!,
                  'Content-Type': "application/json",
                },
                body: json.encode(map));

            if (response.statusCode == 200) {
              Map<String, dynamic> jsonResponse =
                  await EncryptAPITraffic.decryptJson(response.body);

              await TableCircleObjectCache.delete(circleObject.id);

              if (jsonResponse.containsKey('lastCircleObject')) {
                CircleObject retValue =
                    CircleObject.fromJson(jsonResponse["lastCircleObject"]);

                TableUserCircleCache.updateLastItemUpdate(retValue.circle!.id,
                    userFurnace.userid, retValue.lastUpdate);
              }
              return circleObject;
            } else if (response.statusCode == 401) {
              await navService.logout(userFurnace);
              return circleObject;
            } else {
              debugPrint("${response.statusCode}: ${response.body}");

              if (retries == RETRIES.MAX_MESSAGE_RETRIES)
                LogBloc.insertLog('${response.statusCode} : ${response.body}',
                    'CircleObjectService.hideCircleObject');
            }
          } on SocketException catch (err, trace) {
            debugPrint(
                'CircleObjectService.hideCircleObject: ${err.toString()}');
            if (retries == RETRIES.MAX_MESSAGE_RETRIES)
              LogBloc.insertError(err, trace);
          } catch (err, trace) {
            debugPrint(
                'CircleObjectService.hideCircleObject: ${err.toString()}');
            if (retries == RETRIES.MAX_MESSAGE_RETRIES)
              LogBloc.insertError(err, trace);
          }

          if (retries == RETRIES.MAX_MESSAGE_RETRIES)
            throw Exception('failed to hide post');

          await Future.delayed(const Duration(milliseconds: RETRIES.TIMEOUT));
          retries++;
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleObjectService.hideCircleObject: ${err.toString()}');
      rethrow;
    }

    return circleObject;
  }

  Future<CircleObject> deleteCircleObject(UserCircleCache? userCircleCache,
      UserFurnace userFurnace, CircleObject circleObject) async {
    try {
      String url = userFurnace.url! + Urls.CIRCLEOBJECTS + circleObject.id!;

      // debugPrint(url + " " + DateTime.now().toLocal().toString());

      if (await Network.isConnected()) {
        debugPrint(url);

        int retries = 0;

        while (retries <= RETRIES.MAX_MESSAGE_RETRIES) {
          try {
            final response = await http.delete(
              Uri.parse(url),
              headers: {'Authorization': userFurnace.token!},
              //body: map,
            );

            if (response.statusCode == 200) {
              Map<String, dynamic> jsonResponse = json.decode(response.body);

              await TableCircleObjectCache.delete(circleObject.id);

              if (jsonResponse.containsKey('lastCircleObject') &&
                  jsonResponse["lastCircleObject"] != null) {
                CircleObject retValue =
                    CircleObject.fromJson(jsonResponse["lastCircleObject"]);

                TableUserCircleCache.updateLastItemUpdate(retValue.circle!.id,
                    userFurnace.userid, retValue.lastUpdate);
              }

              return circleObject;
            } else if (response.statusCode == 401) {
              await navService.logout(userFurnace);
              return circleObject;
            } else {
              if (response.body.toLowerCase().contains("access denied"))
                throw (response.body);

              debugPrint("${response.statusCode}: ${response.body}");
              if (retries == RETRIES.MAX_MESSAGE_RETRIES)
                LogBloc.insertLog('${response.statusCode} : ${response.body}',
                    'CircleObjectService.deleteCircleObject');
            }
          } on SocketException catch (err, trace) {
            debugPrint(
                'CircleObjectService.deleteCircleObject: ${err.toString()}');
            if (retries == RETRIES.MAX_MESSAGE_RETRIES)
              LogBloc.insertError(err, trace);
          } catch (err, trace) {
            if (err.toString().toLowerCase().contains("access denied")) rethrow;

            debugPrint(
                'CircleObjectService.deleteCircleObject: ${err.toString()}');
            if (retries == RETRIES.MAX_MESSAGE_RETRIES)
              LogBloc.insertError(err, trace);
          }

          if (retries == RETRIES.MAX_MESSAGE_RETRIES)
            throw Exception('failed to delete post');

          await Future.delayed(const Duration(milliseconds: RETRIES.TIMEOUT));
          retries++;
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleObjectService.deleteCircleObject: ${err.toString()}');
      rethrow;
    }

    return circleObject;
  }

  Future<CircleObject> postReaction(
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      CircleObject circleObject,
      CircleObjectReaction circleObjectReaction) async {
    try {
      String url = userFurnace.url! + Urls.CIRCLEOBJECT_REACTION;

      Device device = await globalState.getDevice();

      Map map = {
        'apikey': userFurnace.apikey,
        'circleID': circleObject.circle!.id,
        'circleobjectid': circleObject.id,
        'pushtoken': device.pushToken,
        'index': circleObjectReaction.index,
        'emoji': circleObjectReaction.emoji,
      };

      if (await Network.isConnected()) {
        debugPrint(url);

        int retries = 0;

        map = await EncryptAPITraffic.encrypt(map);

        while (retries <= RETRIES.MAX_MESSAGE_RETRIES) {
          try {
            final response = await http.post(Uri.parse(url),
                headers: {
                  'Authorization': userFurnace.token!,
                  'Content-Type': "application/json",
                },
                body: json.encode(map));

            if (response.statusCode == 200) {
              Map<String, dynamic> jsonResponse =
                  await EncryptAPITraffic.decryptJson(response.body);

              CircleObject retValue =
                  CircleObject.fromJson(jsonResponse["circleobject"]);

              circleObject.reactions = retValue.reactions;

              TableCircleObjectCache.updateCacheSingleObject(
                  userFurnace.userid!, circleObject);

              //TableUserCircleCache.updateLastItemUpdate(
              //   retValue.circle!.id, userFurnace.userid, retValue.lastUpdate, setLastAccessed: true);

              return retValue;
            } else if (response.statusCode == 401) {
              await navService.logout(userFurnace);
              return circleObject;
            } else {
              debugPrint("${response.statusCode}: ${response.body}");
              if (retries == RETRIES.MAX_MESSAGE_RETRIES)
                LogBloc.insertLog('${response.statusCode} : ${response.body}',
                    'CircleObjectService.postReaction');
            }
          } on SocketException catch (err, trace) {
            debugPrint('CircleObjectService.postReaction: ${err.toString()}');
            if (retries == RETRIES.MAX_MESSAGE_RETRIES)
              LogBloc.insertError(err, trace);
          } catch (err, trace) {
            debugPrint('CircleObjectService.postReaction: ${err.toString()}');
            if (retries == RETRIES.MAX_MESSAGE_RETRIES)
              LogBloc.insertError(err, trace);
          }

          if (retries == RETRIES.MAX_MESSAGE_RETRIES)
            throw Exception('failed to post reaction');

          await Future.delayed(const Duration(milliseconds: RETRIES.TIMEOUT));
          retries++;
        }
      } else {
        throw ('connection to internet not detected');
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleObjectService.postReaction: ${err.toString()}');
      rethrow;
    }

    return circleObject;
  }

  Future<CircleObject> deleteReaction(
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      CircleObject circleObject,
      CircleObjectReaction circleObjectReaction) async {
    try {
      if (circleObjectReaction.id == null) {
        throw ('reaction delete before save');
      }
      String url = userFurnace.url! +
          Urls.CIRCLEOBJECT_REACTION +
          circleObjectReaction.id!;

      var connectivityResult = await (Connectivity().checkConnectivity());
      Device device = await globalState.getDevice();
      Map map = {
        'apikey': userFurnace.apikey,
        'circleID': circleObject.circle!.id,
        'circleobjectid': circleObject.id,
        'pushtoken': device.pushToken,
        'index': circleObjectReaction.index,
        'emoji': circleObjectReaction.emoji,
      };

      if (await Network.isConnected()) {
        map = await EncryptAPITraffic.encrypt(map);

        debugPrint(url);

        int retries = 0;

        while (retries <= RETRIES.MAX_MESSAGE_RETRIES) {
          try {
            final response = await http.delete(Uri.parse(url),
                headers: {
                  'Authorization': userFurnace.token!,
                  'Content-Type': "application/json",
                },
                body: json.encode(map));

            if (response.statusCode == 200) {
              Map<String, dynamic> jsonResponse =
                  await EncryptAPITraffic.decryptJson(response.body);

              CircleObject retValue =
                  CircleObject.fromJson(jsonResponse["circleobject"]);

              return retValue;
            } else if (response.statusCode == 401) {
              await navService.logout(userFurnace);
              return circleObject;
            } else {
              debugPrint("${response.statusCode}: ${response.body}");
              if (retries == RETRIES.MAX_MESSAGE_RETRIES)
                LogBloc.insertLog('${response.statusCode} : ${response.body}',
                    'CircleObjectService.deleteReaction');
            }
          } on SocketException catch (err, trace) {
            debugPrint('CircleObjectService.deleteReaction: ${err.toString()}');
            if (retries == RETRIES.MAX_MESSAGE_RETRIES)
              LogBloc.insertError(err, trace);
          } catch (err, trace) {
            debugPrint('CircleObjectService.deleteReaction: ${err.toString()}');
            if (retries == RETRIES.MAX_MESSAGE_RETRIES)
              LogBloc.insertError(err, trace);
          }

          if (retries == RETRIES.MAX_MESSAGE_RETRIES)
            throw Exception('failed to remove reaction');

          await Future.delayed(const Duration(milliseconds: RETRIES.TIMEOUT));
          retries++;
        }
      } else {
        throw ('connection to internet not detected');
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleObjectService.deleteReaction: ${err.toString()}');
      rethrow;
    }

    return circleObject;
  }

  Future<CircleObject> updateCircleObject(
      CircleObject circleObject, UserFurnace userFurnace) async {
    try {
      String url;

      //update the local cache
      //await TableCircleObjectCache.updateCacheSingleObject(circleObject);

      if (circleObject.ratchetIndexes.isEmpty){

        CircleObjectCache circleObjectCache = await TableCircleObjectCache.readBySeed(circleObject.seed!);
        debugPrint('break');


      }

      CircleObject encryptedCopy =
          await ForwardSecrecy.encryptCircleObject(userFurnace, circleObject);

      Device device = await globalState.getDevice();

      Map map = {
        'circleObjectID': circleObject.id!,
        'apikey': userFurnace.apikey,
        'creator': circleObject.creator!.id,
        'circleID': circleObject.circle!.id,
        //'emojiOnly': circleObject.emojiOnly == true ? 'true' : 'false',
        'seed': circleObject.seed,
        'pushtoken': device.pushToken,
        'body': encryptedCopy.body,
        'type': circleObject.subType != null &&
                circleObject.subType == SubType.LOGIN_INFO
            ? CircleObjectType.CIRCLECREDENTIAL
            : circleObject.type,
        'crank': encryptedCopy.crank,
        'signature': encryptedCopy.signature,
        'verification': encryptedCopy.verification,
        //'objectRatchet': encryptedCopy.objectRatchet,
        'senderRatchetPublic': encryptedCopy.senderRatchetPublic,
        'ratchetIndexes': encryptedCopy.ratchetIndexes,
      };

      url = userFurnace.url! + Urls.CIRCLEOBJECTS + 'undefined';

      map = await EncryptAPITraffic.encrypt(map);

      if (await Network.isConnected()) {
        debugPrint(url);

        int retries = 0;

        while (retries <= RETRIES.MAX_MESSAGE_RETRIES) {
          try {
            final response = await http.put(Uri.parse(url),
                headers: {
                  'Authorization': userFurnace.token!,
                  'Content-Type': "application/json",
                },
                body: json.encode(map));

            if (response.statusCode == 200) {
              ///API returned, don't retry
              retries = RETRIES.MAX_MESSAGE_RETRIES;

              Map<String, dynamic> jsonResponse =
                  await EncryptAPITraffic.decryptJson(response.body);

              CircleObject retValue =
                  CircleObject.fromJson(jsonResponse["circleobject"]);

              retValue.revertEncryptedFields(circleObject);

              //cache the object
              await TableCircleObjectCache.updateCacheSingleObject(
                  userFurnace.userid!, retValue);

              TableUserCircleCache.updateLastItemUpdate(retValue.circle!.id,
                  retValue.creator!.id, retValue.lastUpdate);

              return retValue;
            } else if (response.statusCode == 401) {
              await navService.logout(userFurnace);
              return circleObject;
            } else {
              debugPrint("${response.statusCode}: ${response.body}");

              if (retries == RETRIES.MAX_MESSAGE_RETRIES)
                LogBloc.insertLog('${response.statusCode} : ${response.body}',
                    'CircleObjectService.hideCircleObject');
            }
          } on SocketException catch (err, trace) {
            debugPrint(
                'CircleObjectService.updateCircleObject: ${err.toString()}');
            if (retries == RETRIES.MAX_MESSAGE_RETRIES)
              LogBloc.insertError(err, trace);
          } catch (err, trace) {
            debugPrint(
                'CircleObjectService.updateCircleObject: ${err.toString()}');
            if (retries == RETRIES.MAX_MESSAGE_RETRIES)
              LogBloc.insertError(err, trace);
          }

          if (retries == RETRIES.MAX_MESSAGE_RETRIES)
            throw Exception('failed to update post');

          await Future.delayed(const Duration(milliseconds: RETRIES.TIMEOUT));
          retries++;
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleObjectService.updateCircleObject: ${err.toString()}');
      rethrow;
    }

    return circleObject;
  }

  Future<CircleObject> cacheCircleObject(CircleObject circleObject) async {
    //create a local id for caching in the event the network is down
    if (circleObject.seed == null) {
      var uuid = const Uuid();
      circleObject.seed = uuid.v4();
    }

    if (circleObject.storageID == null || circleObject.storageID!.isEmpty) {
      var uuid = const Uuid();
      circleObject.storageID = uuid.v4();
    }

    await TableCircleObjectCache.updateCacheSingleObject(
        circleObject.creator!.id!, circleObject);

    return circleObject;
  }

  Future<bool> post(
    UserFurnace userFurnace,
    UserCircleCache userCircleCache,
    CircleObject circleObject,
    GlobalEventBloc globalEventBloc,
  ) async {
    try {
      String url = userFurnace.url! + Urls.CIRCLEOBJECTS_FILE;

      //debugPrint('CircleObjectService: userid: ${userFurnace.userid!}, circle: ${circleObject.circle!.id}, ');

      CircleObject encryptedCopy =
          await ForwardSecrecy.encryptCircleObject(userFurnace, circleObject);

      encryptedCopy.initDates();

      Device device = await globalState.getDevice();

      // ///for testing, add a json object that is larger than 15kb
      // Map<String, dynamic> rbr = {
      //   "users": List.generate(500, (index) => {
      //     "id": index + 1,
      //     "name": "User_${index + 1}",
      //     "email": "user${index + 1}@example.com",
      //     "age": (index % 50) + 18,
      //     "address": {
      //       "street": "${index + 1} Main St",
      //       "city": "City_${index % 100}",
      //       "state": "State_${index % 50}",
      //       "zip": "${10000 + index}"
      //     }
      //   })
      // };

      Map<String, dynamic> map = {
        'apikey': userFurnace.apikey,
        //'creator': circleObject.creator!.id,
        'circle': circleObject.circle!.id,
        'seed': circleObject.seed,
        //'rbr': rbr,
        //'emojiOnly': circleObject.emojiOnly == true ? 'true' : 'false',
        //'pushtoken': device.pushToken,
        'device': device.uuid,
        'replyObjectID': circleObject.replyObjectID,
        'body': encryptedCopy.body,
        'build': globalState.build,
        'type': circleObject.type,
        'crank': encryptedCopy.crank,
        'signature': encryptedCopy.signature,
        'verification': encryptedCopy.verification,
        'senderRatchetPublic': encryptedCopy.senderRatchetPublic,
        'ratchetIndexes': encryptedCopy.ratchetIndexes,
        'taggedUsers': encryptedCopy.taggedUsers,
        //'waitingOn': 'c2d73bb4-0435-4a8b-893b-2b9a9bf17b8b'
      };

      String waitingOn = CircleObject.getWaitingOn(circleObject);

      if (waitingOn.isNotEmpty) {
        map["waitingOn"] = waitingOn;
      }

      if (circleObject.timer != null) {
        map["timer"] = circleObject.timer;
      }
      if (circleObject.scheduledFor != null &&
          circleObject.dateIncrement != null) {
        String scheduled =
            encryptedCopy.scheduledFor.toString().substring(0, 17);
        String time = circleObject.dateIncrement!.toString();
        String scheduledTime = scheduled + time;
        map["scheduledFor"] = scheduledTime;
      }

      map = await EncryptAPITraffic.encryptb(map);

      ///write the map out to a file
      DirectoryAndFile directoryAndFile =
          await FileSystemService.cacheJson(map);

      //String json = jsonEncode(map);
      // String howBigIsThis = json.length.toString();
      // debugPrint('CircleObjectService: $howBigIsThis');
      // debugPrint(json);

      if (await Network.isConnected()) {

        debugPrint(url);
        ///RBR
        ///wait 5 seconds
        //await Future.delayed(const Duration(seconds: 15));

        //String json = jsonEncode(map);

        BackgroundTask backgroundTask = BackgroundTask(
          //taskID: task.taskId,
          type: BackgroundTaskType.postCircleObject,
          status: BackgroundTaskStatus.pending,
          circleID: circleObject.circle!.id!,
          userCircleID: userCircleCache.usercircle!,
          userID: userFurnace.userid!,
          seed: circleObject.seed!,
          networkID: userFurnace.pk!,
          path: directoryAndFile.path);

        final task = UploadTask(
            url: url,
            directory: directoryAndFile.directory,
            filename: directoryAndFile.fileName,
            headers: {
              'Authorization': userFurnace.token!,
              //'Content-Type': "application/json",
            },
            // fields: {'datafield': 'value'},
            fileField: 'file',
            metaData: BackgroundTaskType.postCircleObject.index.toString(),
            updates: Updates.status // request status and progress updates
            );

        // final task = DataTask(
        //     url: url,
        //     metaData: BackgroundTaskType.postCircleObject.index.toString(),
        //     headers: {
        //       'Authorization': userFurnace.token!,
        //       'Content-Type': "application/json",
        //     },
        //     httpRequestMethod: 'POST',
        //     //contentType: "application/json",
        //     //json: json,
        //     post: json,
        //     retries: 10,
        //     updates: Updates.status // request status and progress updates
        //     );

        ///set the ID
        backgroundTask.taskID = task.taskId;

        ///cache the task
        await TableBackgroundTask.upsert(backgroundTask);

        ///add the task to the queue
        final successfullyEnqueued = await FileDownloader().enqueue(task);

        debugPrint('break');

        return successfullyEnqueued;

        /*
        int retries = 0;

        while (retries <= RETRIES.MAX_MESSAGE_RETRIES) {
          try {
            final response = await http.post(Uri.parse(url),
                headers: {
                  'Authorization': userFurnace.token!,
                  'Content-Type': "application/json",
                },
                body: json.encode(map));

            if (response.statusCode == 200) {
              Map<String, dynamic> jsonResponse =
              await EncryptAPITraffic.decryptJson(response.body);

              // if (jsonResponse.containsKey("clearedWaitingOn")) {
              //   if (jsonResponse["clearedWaitingOn"] == true) {
              //     ///pull it from globalState notDone
              //     //CircleObject.clearItems(circleObject.seed!);
              //   }
              // }

              CircleObject retValue =
              CircleObject.fromJson(jsonResponse["circleobject"]);

              retValue.revertEncryptedFields(circleObject);

              if (circleObject.created!.difference(retValue.created!) <
                  const Duration(seconds: 30)) {
                ///use the local date
                retValue.created = circleObject.created!;
              }

              retValue.circle ??= circle;

              ///Part of the transition away from subtypes. API is not aware of a circlecredential type, so convert it here
              if (retValue.subType != null &&
                  retValue.subType == SubType.LOGIN_INFO) {
                retValue.type = CircleObjectType.CIRCLECREDENTIAL;
              }

              //cache the object
              await TableCircleObjectCache.updateCacheSingleObject(
                  userFurnace.userid!, retValue);

              TableUserCircleCache.updateLastItemUpdate(retValue.circle!.id,
                  retValue.creator!.id, retValue.lastUpdate);

              return retValue;
            } else if (response.statusCode == 401) {
              await navService.logout(userFurnace);

              return circleObject;
            } else {
              debugPrint("${response.statusCode}: ${response.body}");

              if (response.body.contains(
                  'You cannot post when there is an active vote to remove you from the Circle')) {
                retries = RETRIES.MAX_MESSAGE_RETRIES;
                globalEventBloc.broadcastError(
                    'You cannot post when there is an active vote to remove you from the Circle');
              }

              if (retries == RETRIES.MAX_MESSAGE_RETRIES) {
                LogBloc.insertLog('${response.statusCode} : ${response.body}',
                    'CircleObjectService.saveCircleObject');
              }
            }
          } on SocketException catch (err, trace) {
            debugPrint(
                'CircleObjectService.saveCircleObject: ${err.toString()}');

            if (retries == RETRIES.MAX_MESSAGE_RETRIES)
              LogBloc.insertError(err, trace);
          } catch (err, trace) {
            debugPrint(
                'CircleObjectService.saveCircleObject: ${err.toString()}');

            if (retries == RETRIES.MAX_MESSAGE_RETRIES)
              LogBloc.insertError(err, trace);
          }

          if (retries == RETRIES.MAX_MESSAGE_RETRIES)
            throw Exception('failed to save post');

          await Future.delayed(const Duration(milliseconds: RETRIES.TIMEOUT));
          retries++;
        }

         */
      } else {
        globalEventBloc.removeGenericObject(circleObject.seed!);
      }
    } catch (err, trace) {
      ///remove it from globalState notDone
      globalState.forcedOrder
          .removeWhere((element) => element.seed == circleObject.seed);
      LogBloc.insertError(err, trace);
      debugPrint('CircleObjectService.saveCircleObject: ${err.toString()}');
      rethrow;
    }

    return false;
  }

  //
  //
  // Future<CircleObject> saveCircleObject(
  //   UserFurnace userFurnace,
  //   UserCircleCache userCircleCache,
  //   CircleObject circleObject,
  //   GlobalEventBloc globalEventBloc,
  // ) async {
  //   try {
  //     String? url;
  //
  //     //debugPrint('CircleObjectService: userid: ${userFurnace.userid!}, circle: ${circleObject.circle!.id}, ');
  //
  //     CircleObject encryptedCopy =
  //         await ForwardSecrecy.encryptCircleObject(userFurnace, circleObject);
  //
  //     encryptedCopy.initDates();
  //
  //     Device device = await globalState.getDevice();
  //
  //     Circle circle = circleObject.circle!;
  //
  //     Map map = {
  //       'apikey': userFurnace.apikey,
  //       'creator': circleObject.creator!.id,
  //       'circle': circleObject.circle!.id,
  //       'seed': circleObject.seed,
  //       //'emojiOnly': circleObject.emojiOnly == true ? 'true' : 'false',
  //       'pushtoken': device.pushToken,
  //       'device': device.uuid,
  //       'replyObjectID': circleObject.replyObjectID,
  //       'body': encryptedCopy.body,
  //       'type': circleObject.type,
  //       'crank': encryptedCopy.crank,
  //       'signature': encryptedCopy.signature,
  //       'verification': encryptedCopy.verification,
  //       'senderRatchetPublic': encryptedCopy.senderRatchetPublic,
  //       'ratchetIndexes': encryptedCopy.ratchetIndexes,
  //       'taggedUsers': encryptedCopy.taggedUsers,
  //       //'waitingOn': 'c2d73bb4-0435-4a8b-893b-2b9a9bf17b8b'
  //     };
  //
  //     String waitingOn = CircleObject.getWaitingOn(circleObject);
  //
  //     if (waitingOn.isNotEmpty) {
  //       map["waitingOn"] = waitingOn;
  //     }
  //
  //     if (circleObject.timer != null) {
  //       map["timer"] = circleObject.timer;
  //     }
  //     if (circleObject.scheduledFor != null &&
  //         circleObject.dateIncrement != null) {
  //       String scheduled =
  //           encryptedCopy.scheduledFor.toString().substring(0, 17);
  //       String time = circleObject.dateIncrement!.toString();
  //       String scheduledTime = scheduled + time;
  //       map["scheduledFor"] = scheduledTime;
  //     }
  //
  //     url = userFurnace.url! + Urls.CIRCLEOBJECTS;
  //
  //     if (await Network.isConnected()) {
  //       map = await EncryptAPITraffic.encrypt(map);
  //
  //       debugPrint(url);
  //
  //       int retries = 0;
  //
  //       while (retries <= RETRIES.MAX_MESSAGE_RETRIES) {
  //         try {
  //           final response = await http.post(Uri.parse(url),
  //               headers: {
  //                 'Authorization': userFurnace.token!,
  //                 'Content-Type': "application/json",
  //               },
  //               body: json.encode(map));
  //
  //           if (response.statusCode == 200) {
  //             Map<String, dynamic> jsonResponse =
  //                 await EncryptAPITraffic.decryptJson(response.body);
  //
  //             // if (jsonResponse.containsKey("clearedWaitingOn")) {
  //             //   if (jsonResponse["clearedWaitingOn"] == true) {
  //             //     ///pull it from globalState notDone
  //             //     //CircleObject.clearItems(circleObject.seed!);
  //             //   }
  //             // }
  //
  //             CircleObject retValue =
  //                 CircleObject.fromJson(jsonResponse["circleobject"]);
  //
  //             retValue.revertEncryptedFields(circleObject);
  //
  //             if (circleObject.created!.difference(retValue.created!) <
  //                 const Duration(seconds: 30)) {
  //               ///use the local date
  //               retValue.created = circleObject.created!;
  //             }
  //
  //             retValue.circle ??= circle;
  //
  //             ///Part of the transition away from subtypes. API is not aware of a circlecredential type, so convert it here
  //             if (retValue.subType != null &&
  //                 retValue.subType == SubType.LOGIN_INFO) {
  //               retValue.type = CircleObjectType.CIRCLECREDENTIAL;
  //             }
  //
  //             //cache the object
  //             await TableCircleObjectCache.updateCacheSingleObject(
  //                 userFurnace.userid!, retValue);
  //
  //             TableUserCircleCache.updateLastItemUpdate(retValue.circle!.id,
  //                 retValue.creator!.id, retValue.lastUpdate);
  //
  //             return retValue;
  //           } else if (response.statusCode == 401) {
  //             await navService.logout(userFurnace);
  //
  //             return circleObject;
  //           } else {
  //             debugPrint("${response.statusCode}: ${response.body}");
  //
  //             if (response.body.contains(
  //                 'You cannot post when there is an active vote to remove you from the Circle')) {
  //               retries = RETRIES.MAX_MESSAGE_RETRIES;
  //               globalEventBloc.broadcastError(
  //                   'You cannot post when there is an active vote to remove you from the Circle');
  //             }
  //
  //             if (retries == RETRIES.MAX_MESSAGE_RETRIES) {
  //               LogBloc.insertLog('${response.statusCode} : ${response.body}',
  //                   'CircleObjectService.saveCircleObject');
  //             }
  //           }
  //         } on SocketException catch (err, trace) {
  //           debugPrint(
  //               'CircleObjectService.saveCircleObject: ${err.toString()}');
  //
  //           if (retries == RETRIES.MAX_MESSAGE_RETRIES)
  //             LogBloc.insertError(err, trace);
  //         } catch (err, trace) {
  //           debugPrint(
  //               'CircleObjectService.saveCircleObject: ${err.toString()}');
  //
  //           if (retries == RETRIES.MAX_MESSAGE_RETRIES)
  //             LogBloc.insertError(err, trace);
  //         }
  //
  //         if (retries == RETRIES.MAX_MESSAGE_RETRIES)
  //           throw Exception('failed to save post');
  //
  //         await Future.delayed(const Duration(milliseconds: RETRIES.TIMEOUT));
  //         retries++;
  //       }
  //     }
  //   } catch (err, trace) {
  //     ///remove it from globalState notDone
  //     globalState.forcedOrder
  //         .removeWhere((element) => element.seed == circleObject.seed);
  //     LogBloc.insertError(err, trace);
  //     debugPrint('CircleObjectService.saveCircleObject: ${err.toString()}');
  //     rethrow;
  //   }
  //
  //   return circleObject;
  // }

  Future<void> reportViolation(UserFurnace userFurnace,
      CircleObject circleObject, Violation violation) async {
    String url = userFurnace.url! + Urls.REPORT_VIOLATION;
    debugPrint(url);

    Map map = {
      "violation": violation,
      'circleID': circleObject.circle!.id,
    };

    int retries = 0;

    map = await EncryptAPITraffic.encrypt(map);

    while (retries <= RETRIES.MAX_MESSAGE_RETRIES) {
      try {
        final response = await http.post(Uri.parse(url),
            headers: {
              'Authorization': userFurnace.token!,
              'Content-Type': "application/json",
            },
            body: json.encode(map));

        if (response.statusCode == 200) {
          // Map<String, dynamic> jsonResponse =
          // await EncryptAPITraffic.decryptJson(response.body);

          return;
        } else if (response.statusCode == 401) {
          await navService.logout(userFurnace);
          return;
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
          if (retries == RETRIES.MAX_MESSAGE_RETRIES)
            LogBloc.insertLog('${response.statusCode} : ${response.body}',
                'CircleObjectService.reportViolation');
        }
      } on SocketException catch (err, trace) {
        debugPrint('CircleObjectService.reportViolation: ${err.toString()}');
        if (retries == RETRIES.MAX_MESSAGE_RETRIES)
          LogBloc.insertError(err, trace);
      } catch (err, trace) {
        debugPrint('CircleObjectService.reportViolation: ${err.toString()}');
        if (retries == RETRIES.MAX_MESSAGE_RETRIES)
          LogBloc.insertError(err, trace);
      }

      if (retries == RETRIES.MAX_MESSAGE_RETRIES)
        throw Exception('failed to report post');

      await Future.delayed(const Duration(milliseconds: RETRIES.TIMEOUT));
      retries++;
    }

    return;
  }

  ///TODO this only tries once, add retries capability
  Future<bool> oneTimeView(
      UserFurnace userFurnace, CircleObject circleObject) async {
    bool retValue = false;

    try {
      String url =
          userFurnace.url! + Urls.CIRCLEOBJECTSONETIMEVIEW + 'undefined';

      Map map = {
        "circleObjectID": circleObject.id!,
        'circleID': circleObject.circle!.id,
      };

      if (await Network.isConnected()) {
        map = await EncryptAPITraffic.encrypt(map);

        debugPrint("$url ${DateTime.now().toLocal()}");

        final response = await http.post(Uri.parse(url),
            headers: {
              'Authorization': userFurnace.token!,
              'Content-Type': "application/json",
            },
            body: json.encode(map));

        if (response.statusCode == 200) {
          Map<String, dynamic> jsonResponse =
              await EncryptAPITraffic.decryptJson(response.body);

          if (jsonResponse.containsKey("allowed")) {
            retValue = jsonResponse["allowed"];
          }
        } else if (response.statusCode == 401) {
          await navService.logout(userFurnace);
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
          LogBloc.insertLog('${response.statusCode} : ${response.body}',
              'CircleObjectService.reportViolation');
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectService.fetchJumpTo: $error");
      rethrow;
    }

    return retValue;
  }

  static checkForBlockedReactions(
      CircleObject circleObject, Member m, CircleObjectReaction reaction) {
    List<User> remove = [];
    for (User u in reaction.users) {
      if (u.id == m.memberID) {
        remove.add(u);
      }
    }
    for (User u in remove) {
      reaction.users.remove(u);
    }
  }

  /// Convert a CircleObjectCache list to a CircleObject list
  static List<CircleObject> convertFromCachePerformant(
      GlobalEventBloc globalEventBloc, List<Map> results, String userID,
      {List<UserFurnace> userFurnaces = const [],
      List<UserCircleCache> userCircleCaches = const []}) {
    List<CircleObject> convertValue = [];

    List<Member> blockedMembers = globalState.members
        .where((element) => element.blocked == true)
        .toList();

    ///convert the cache to circleobjects
    for (var result in results) {
      //debugPrint('convert start: ${DateTime.now()}');

      Map<String, dynamic>? decode;

      try {
        decode = json.decode(result["circleObjectJson"]);

        CircleObject circleObject = CircleObject.fromJson(decode!);

        ///add hitchhikers
        if (userCircleCaches.isNotEmpty) {
          int userCircleCacheIndex = userCircleCaches.indexWhere(
              (element) => element.circle! == circleObject.circle!.id);

          if (userCircleCacheIndex != -1) {
            circleObject.userCircleCache =
                userCircleCaches[userCircleCacheIndex];

            int furnaceIndex = userFurnaces.indexWhere((element) =>
                element.pk == circleObject.userCircleCache!.userFurnace);
            if (furnaceIndex != -1) {
              circleObject.userFurnace = userFurnaces[furnaceIndex];
            }
          }
        }

        ///check Timer
        if (circleObject.timer != null) {
          if (circleObject.timerExpires != null) {
            if (circleObject.timerExpires!.compareTo(DateTime.now()) < 0) {
              //timer expired.  Don't add this object.  Delete

              TableCircleObjectCache.delete(circleObject.id!);
              globalEventBloc
                  .broadCastMemCacheCircleObjectsRemove([circleObject]);
              continue;
            }
          }
        }

        bool memberBlocked = false;

        if (circleObject.creator != null) {
          for (Member m in blockedMembers) {
            if (circleObject.type != CircleObjectType.CIRCLEVOTE) {
              if (circleObject.creator!.id == m.memberID) {
                memberBlocked = true;
                TableCircleObjectCache.delete(circleObject.id!);
                globalEventBloc
                    .broadCastMemCacheCircleObjectsRemove([circleObject]);
                continue;
              } else if (circleObject.reactions != null &&
                  circleObject.reactions != []) {
                for (CircleObjectReaction reaction in circleObject.reactions!) {
                  checkForBlockedReactions(circleObject, m, reaction);
                }
                circleObject.reactions!
                    .removeWhere((element) => element.users.isEmpty);
              }
            }
          }
        }

        if (!memberBlocked) {
          convertValue.add(circleObject);
        }
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
        debugPrint('$decode');
        debugPrint('CircleObjectBloc._convertFromCache: $err');
      }
    }

    //debugPrint('convert stop: ${DateTime.now()}');

    return convertValue;
  }

  /// Convert a CircleObjectCache list to a CircleObject list
  static List<CircleObject> convertFromCachePerformantWithHitchhikers(
      GlobalEventBloc globalEventBloc,
      List<Map> results,
      List<UserFurnace> userFurnaces,
      List<UserCircleCache> userCircles) {
    List<CircleObject> convertValue = [];

    //debugPrint('convert start: ${DateTime.now()}');

    //convert the cache to circleobjects
    for (var result in results) {
      Map<String, dynamic>? decode;

      try {
        decode = json.decode(result["circleObjectJson"]);

        CircleObject circleObject = CircleObject.fromJson(decode!);

        //check Timer
        if (circleObject.timer != null) {
          if (circleObject.timerExpires != null) {
            if (circleObject.timerExpires!.compareTo(DateTime.now()) < 0) {
              //timer expired.  Don't add this object.  Delete

              TableCircleObjectCache.delete(circleObject.id!);
              globalEventBloc
                  .broadCastMemCacheCircleObjectsRemove([circleObject]);
              continue;
            }
          }
        }

        ///add the hitchikers
        UserCircleCache userCircleCache = userCircles.firstWhere(
            (element) => element.circle == circleObject.circle!.id!);
        circleObject.userCircleCache = userCircleCache;

        debugPrint("userFurnace key: ${userCircleCache.userFurnace}");
        circleObject.userFurnace = userFurnaces
            .firstWhere((element) => element.pk == userCircleCache.userFurnace);

        convertValue.add(circleObject);
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
        debugPrint('$decode');
        debugPrint('CircleObjectBloc._convertFromCache: $err');
      }
    }

    //debugPrint('convert stop: ${DateTime.now()}');

    return convertValue;
  }
}
