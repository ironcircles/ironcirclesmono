import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/encryption/encryptapitraffic.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy.dart';
import 'package:ironcirclesapp/models/circleobjectreaction.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/replyobject.dart';
import 'package:ironcirclesapp/models/violation.dart';
import 'package:ironcirclesapp/services/avatar_service.dart';
import 'package:ironcirclesapp/services/cache/table_replyobject.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';
import 'package:ironcirclesapp/utils/network.dart';
import 'package:uuid/uuid.dart';

class ReplyObjectService {
  bool turnOff = false;

  void _updateMemberAttributes(
      UserFurnace userFurnace, UserCircleCollection userCircles) {
    AvatarService avatarService = AvatarService();
    avatarService.validateCurrentAvatars(
        userFurnace, userCircles); //this is async on purpose
  }

  //late GlobalEventBloc _globalEventBloc;

  // WallReplyService(GlobalEventBloc globalEventBloc) {
  //   _globalEventBloc = globalEventBloc;
  // }

  ///post reply
  ///} else if (encryptedCopy.type == CircleObjectType.CIRCLEALBUM) {
  //       for (int i = 0; i < params.circleObject.album!.media.length; i++) {
  //         AlbumItem item = params.circleObject.album!.media[i];
  //         if (item.type == AlbumItemType.IMAGE) {
  //           String imageText = json.encode(item.image!.toJson());
  //
  //           CircleObjectLineItem circleObjectLineItem = CircleObjectLineItem(
  //               ratchetIndex: await EncryptString.encryptString(imageText,
  //                   params.userID, messageKey: params.secretKey));
  //
  //           encryptedCopy.album!.media[i].encryptedLineItem = circleObjectLineItem;
  //
  //         } else if (item.type == AlbumItemType.VIDEO) {
  //           String videoText = json.encode(item.video!.toJson());
  //
  //           CircleObjectLineItem circleObjectLineItem = CircleObjectLineItem(
  //               ratchetIndex: await EncryptString.encryptString(videoText,
  //                   params.userID, messageKey: params.secretKey));
  //
  //           encryptedCopy.album!.media[i].encryptedLineItem = circleObjectLineItem;
  //         } else if (item.type == AlbumItemType.GIF) {
  //           String gifText = json.encode(item.gif!.toJson());
  //
  //           CircleObjectLineItem circleObjectLineItem = CircleObjectLineItem(
  //               ratchetIndex: await EncryptString.encryptString(gifText,
  //                   params.userID, messageKey: params.secretKey));
  //
  //           encryptedCopy.album!.media[i].encryptedLineItem = circleObjectLineItem;
  //         }
  //         encryptedCopy.album!.media[i].gif = null;
  //         encryptedCopy.album!.media[i].video = null;
  //         encryptedCopy.album!.media[i].image = null;
  //       }
  //
  //     }
  //
  // Future<List<ReplyObject>> getReplies(
  //     UserFurnace userFurnace,
  //     CircleObject circleObject
  //     ) async {
  //   List<ReplyObject> replyObjects = [];
  //   try {
  //
  //     String url = "${userFurnace.url!}${Urls.WALLREPLY_GETREPLIES}${circleObject.id}&${circleObject.circle!.id}";
  //
  //     debugPrint(url);
  //
  //     //Device device = await globalState.getDevice();
  //
  //     final response = await http.get(
  //       Uri.parse(url),
  //       headers: {
  //         'Authorization': userFurnace.token!,
  //         'Content-Type': "application/json",
  //       },
  //     );
  //
  //     if (response.statusCode == 200) {
  //       Map<String, dynamic> jsonResponse = json.decode(response.body);
  //       ///replies are encrypted. decrypt
  //       //List<ReplyObject> retValue = ReplyObjects.fromJSON(jsonResponse, "replyObjects").objects;
  //
  //     // } else if (circleObject.type == CircleObjectType.CIRCLEALBUM) {
  //     //   for (int i = 0; i < circleObject.album!.media.length; i++) {
  //     //     AlbumItem item = circleObject.album!.media[i];
  //     //
  //     //     List<String> jsonString = await EncryptString.decryptStrings(
  //     //         SecretKey(circleObject.secretKey!), [item.encryptedLineItem!.ratchetIndex]);
  //     //
  //     //     var decode = json.decode(jsonString[0]);
  //     //
  //     //     if (item.type == AlbumItemType.IMAGE) {
  //     //       CircleImage img = CircleImage.fromJson(decode);
  //     //
  //     //       circleObject.album!.media[i].image = img;
  //     //
  //     //     } else if (item.type == AlbumItemType.VIDEO) {
  //     //       CircleVideo video = CircleVideo.fromJson(decode);
  //     //
  //     //       circleObject.album!.media[i].video = video;
  //     //
  //     //     } else if (item.type == AlbumItemType.GIF) {
  //     //       CircleGif gif = CircleGif.fromJson(decode);
  //     //
  //     //       circleObject.album!.media[i].gif = gif;
  //     //     }
  //     //
  //     //   }
  //     // }
  //
  //       return replyObjects;
  //     } else if (response.statusCode == 401) {
  //       await navService.logout(userFurnace);
  //     } else {
  //       debugPrint('WallReplyService.getReplies failed: ${response.statusCode}');
  //       debugPrint(response.body);
  //       throw ("WallReplyService.getReplies failed: ${response.statusCode}");
  //     }
  //
  //   } catch (error, trace) {
  //     LogBloc.insertError(error, trace);
  //     debugPrint("WallReplyService.getReplies: $error");
  //     rethrow;
  //   }
  //   return replyObjects;
  // }

  static checkForBlockedReactions(
      ReplyObject replyObject, Member m, CircleObjectReaction reaction) {
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

  /// Convert a ReplyObjectCache list to a ReplyObject list
  static List<ReplyObject> convertFromCachePerformant(GlobalEventBloc globalEventBloc,
      List<Map> results, String userID,
  {List<UserFurnace> userFurnaces = const [],
    List<UserCircleCache> userCircleCaches = const []}) {
    List<ReplyObject> convertValue = [];

    List<Member> blockedMembers = globalState.members.where((element) => element.blocked == true).toList();

    ///convert the cache to replyobjects
    for (var result in results) {
      Map<String, dynamic>? decode;

      try {
        decode = json.decode(result["replyObjectJson"]);

        ReplyObject replyObject = ReplyObject.fromJson(decode!);

        ///add hitchikers
        // if (userCircleCaches.isNotEmpty) {
        //   int userCircleCacheIndex = userCircleCaches.indexWhere(
        //           (element) => element.circle! == circleObject.circle!.id);
        //
        //   if (userCircleCacheIndex != -1) {
        //     circleObject.userCircleCache =
        //     userCircleCaches[userCircleCacheIndex];
        //
        //     int furnaceIndex = userFurnaces.indexWhere((element) =>
        //     element.pk == circleObject.userCircleCache!.userFurnace);
        //     if (furnaceIndex != -1) {
        //       circleObject.userFurnace = userFurnaces[furnaceIndex];
        //     }
        //   }
        // }

        bool memberBlocked = false;

        if (replyObject.creator != null) {
          for (Member m in blockedMembers) {
            //if (circleObject.type != CircleObjectType.CIRCLEVOTE) {
              if (replyObject.creator!.id == m.memberID) {
                memberBlocked = true;
                TableReplyObjectCache.delete(replyObject.id!);
               // globalEventBloc.broadcastMemCacheReplyObjectsRemove([replyObject]);
                //globalEventBloc.broadCastMemCacheCircleObjectsRemove([replyObject]);
                continue;
              } else if (replyObject.reactions != null &&
                  replyObject.reactions != []) {
                for (CircleObjectReaction reaction in replyObject.reactions!) {
                  checkForBlockedReactions(replyObject, m, reaction);
                }
                replyObject.reactions!
                    .removeWhere((element) => element.users.isEmpty);
              }
            //}
          }
        }

        if (!memberBlocked) {
          convertValue.add(replyObject);
        }

      } catch (err, trace) {
        LogBloc.insertError(err, trace);
        debugPrint('$decode');
        debugPrint('WallReplyService._convertFromCache: $err');
      }
    }

    return convertValue;
  }

  Future<List<ReplyObject>> fetchOlderThan(String circleObjectID,
      String circleID, UserFurnace userFurnace, DateTime created
      ) async {
    List<ReplyObject> retValue = [];

    try {
      if (turnOff) return [];

      String url =
          "${userFurnace.url!}${Urls.WALLREPLY_BYOLDER}$circleObjectID&$circleID&${created.toUtc()}";

      Device device = await globalState.getDevice();

      if (userFurnace.token == null || device.uuid == null){
        LogBloc.insertLog('userFurnace.token: ${userFurnace.token}, device.uuid:${device.uuid}', 'WallReplyService fetchNewerThan');
        return [];
      }

      if (await Network.isConnected()) {
        debugPrint("$url ${DateTime.now().toLocal()}");

        int retries = 0;

        while (retries <= RETRIES.MAX_FETCH_RETRY) {
          try {
            final response = await http.get(Uri.parse(url), headers: {
              'Authorization': userFurnace.token!,
              'device': device.uuid!,
            });

            if (response.statusCode == 200) {
              Map<String, dynamic> jsonResponse = json.decode(response.body);

              if (jsonResponse.containsKey("replyobjects")) {
                ReplyObjectCollection replyObjectCollection = ReplyObjectCollection.fromJSON(jsonResponse);

                retValue = replyObjectCollection.replyObjects;
              }
              return retValue;
            } else if (response.statusCode == 401) {
              await navService.logout(userFurnace);
              return retValue;
            } else {
              debugPrint("${response.statusCode}: ${response.body}");
              if (retries == RETRIES.MAX_FETCH_RETRY)
                LogBloc.insertLog('${response.statusCode} : ${response.body}',
                    'WallReplyService.fetchOlderThan');
            }
          } on SocketException catch (err, trace) {
            debugPrint('WallReplyService.fetchOlderThan: ${err.toString()}');
            if (retries == RETRIES.MAX_FETCH_RETRY)
              LogBloc.insertError(err, trace);
          }  catch (err, trace) {
            debugPrint('WallReplyService.fetchOlderThan: ${err.toString()}');
            if (retries == RETRIES.MAX_FETCH_RETRY)
              LogBloc.insertError(err, trace);
          }

          if (retries == RETRIES.MAX_FETCH_RETRY)
            throw Exception('failed to get reply objects');

          await Future.delayed(const Duration(milliseconds: RETRIES.TIMEOUT));
          retries++;
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('WallReplyService.fetchOlderThan: $error');

      rethrow;
    }
    return retValue;
  }

  Future<ReplyObject> cacheReplyObject(ReplyObject replyObject) async {
    //create a local id for caching in the event the network is down
    if (replyObject.seed == null) {
      var uuid = const Uuid();
      replyObject.seed = uuid.v4();
    }

    // if (replyObject.storageID == null || replyObject.storageID!.isEmpty) {
    //   var uuid = const Uuid();
    //   replyObject.storageID = uuid.v4(); ///???
    // }

    await TableReplyObjectCache.updateCacheSingleObject(
      replyObject.creator!.id!, replyObject);

    return replyObject;
  }

  Future<List<ReplyObject>> fetchNewerThan(String circleObjectID, String circleID,
      UserFurnace userFurnace, DateTime lastUpdate) async {
    String url;

    try {
      if (turnOff) return [];

      List<ReplyObject> retValue = [];

      //url = "${userFurnace.url!}${Urls.WALLREPLY_BYNEWER}$circleObjectID&$circleID&${lastUpdate.toUtc()}";

      url = "${userFurnace.url!}${Urls.WALLREPLY_BYNEWER}";

      Device device = await globalState.getDevice();

      Map map = {
        'circleID': circleID,
        'circleObjectID': circleObjectID,
        'lastUpdate': lastUpdate.toUtc().toString(),
        'device': device.uuid!,
      };

      if (userFurnace.token == null || device.uuid == null){
        LogBloc.insertLog('userFurnace.token: ${userFurnace.token}, device.uuid:${device.uuid}', 'WallReplyService fetchNewerThan');
        return [];
      }

      if (await Network.isConnected()) {
        debugPrint("$url ${DateTime.now().toLocal()}");

        int retries = 0;

        while (retries <= RETRIES.MAX_FETCH_RETRY) {
          try {

            final response = await http.post(Uri.parse(url), headers: {
              'Authorization': userFurnace.token!,
              'Content-Type': "application/json",
            }, body: json.encode(map));

            if (response.statusCode == 200) {
              Map<String, dynamic> jsonResponse =
              await EncryptAPITraffic.decryptJson(response.body);

              if (jsonResponse.containsKey('refreshNeededObjects')) {
                ReplyObjectCollection replyObjectCollection =
                    ReplyObjectCollection.fromJSON(jsonResponse,
                      key: "refreshNeededObjects");

                for (ReplyObject replyObject
                in replyObjectCollection.replyObjects) {
                  replyObject.refreshNeeded = true;
                }

                retValue.addAll(replyObjectCollection.replyObjects);
              }

              if (jsonResponse.containsKey('replyobjects')) {
                ReplyObjectCollection replyObjectCollection =
                    ReplyObjectCollection.fromJSON(jsonResponse);

                retValue.addAll(replyObjectCollection.replyObjects);
              }

              return retValue;
            } else if (response.statusCode == 401) {
              await navService.logout(userFurnace);
              return retValue;
            } else {
              debugPrint("${response.statusCode}: ${response.body}");

              if (retries == RETRIES.MAX_FETCH_RETRY)
                LogBloc.insertLog('${response.statusCode} : ${response.body}',
                    'ReplyObjectService.fetchNewerThan');
            }

          } on SocketException catch (err, trace) {
            debugPrint('ReplyObjectService.fetchNewerThan: ${err.toString()}');
            if (retries == RETRIES.MAX_FETCH_RETRY)
              LogBloc.insertError(err, trace);
          } catch (err, trace) {
            debugPrint('ReplyObjectService.fetchNewerThan: ${err.toString()}');
            if (retries == RETRIES.MAX_FETCH_RETRY)
              LogBloc.insertError(err, trace);
          }

          if (retries == RETRIES.MAX_FETCH_RETRY)
            throw Exception('failed to get reply objects');

          await Future.delayed(const Duration(milliseconds: RETRIES.TIMEOUT));
          retries++;
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("ReplyObjectService.fetchNewerThan: $error");
    }
    return [];
  }

  Future<ReplyObject> saveReplyObject(
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      ReplyObject replyObject,
      GlobalEventBloc globalEventBloc
      ) async {
    try {
      String? url;
      ReplyObject encryptedCopy = await ForwardSecrecy.encryptReplyObject(userFurnace, replyObject, userCircleCache);

      encryptedCopy.initDates();

      Device device = await globalState.getDevice();

      Circle circle = replyObject.circle!;

      Map map = {
        'apikey': userFurnace.apikey,
        'creator': replyObject.creator!.id,
        'circle': replyObject.circle!.id,
        'seed': replyObject.seed,
        'pushtoken': device.pushToken,
        'device': device.uuid,
        'circleObjectID': replyObject.circleObjectID,
        'replyToID': replyObject.replyToID,
        //'replyObjectID': replyObject.replyObjectID,
        'body': encryptedCopy.body,
        'type': replyObject.type,
        'crank': encryptedCopy.crank,
        'signature': encryptedCopy.signature,
        'verification': encryptedCopy.verification,
        'senderRatchetPublic': encryptedCopy.senderRatchetPublic,
        'ratchetIndexes': encryptedCopy.ratchetIndexes,
        'taggedUsers': encryptedCopy.taggedUsers,
      };

      url = userFurnace.url! + Urls.WALLREPLY; //_POSTREPLY;

      if (await Network.isConnected()) {
        debugPrint(url);

        int retries = 0;

        map = await EncryptAPITraffic.encrypt(map);

        while(retries <= RETRIES.MAX_MESSAGE_RETRIES) {
          debugPrint("retries: " + retries.toString());
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

              ReplyObject retValue = ReplyObject.fromJson(jsonResponse["replyobject"]);

              retValue.revertEncryptedFields(replyObject);

              //retValue.circle ??= circle;

              //await TableReplyObjectCache.updateCacheSingleObject(userFurnace.userid!, retValue);

              await TableReplyObjectCache.updateCacheSingleObject( ////id gets here
                  replyObject.creator!.id!, retValue);

              TableUserCircleCache.updateLastItemUpdate(circle!.id,
              retValue.creator!.id, retValue.lastUpdate);

              return retValue;
            } else if (response.statusCode == 401) {
              await navService.logout(userFurnace);

              return replyObject;
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
                    'ReplyObjectService.saveReplyObject');
              }
            }
          } on SocketException catch (err, trace) {
            debugPrint(
                'ReplyObjectService.saveReplyObject: ${err.toString()}');

            if (retries == RETRIES.MAX_MESSAGE_RETRIES)
              LogBloc.insertError(err, trace);
          } catch (err, trace) {
            debugPrint(
                'ReplyObjectService.saveReplyObject: ${err.toString()}');

            if (retries == RETRIES.MAX_MESSAGE_RETRIES)
              LogBloc.insertError(err, trace);
          }

          if (retries == RETRIES.MAX_MESSAGE_RETRIES)
            throw Exception('failed to save post');

          await Future.delayed(const Duration(milliseconds: RETRIES.TIMEOUT));
          retries++;
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('ReplyObjectService.saveReplyObject: ${err.toString()}');
      rethrow;
    }

    return replyObject;
  }

  Future<ReplyObject> updateReplyObject(
      ReplyObject replyObject, UserFurnace userFurnace, UserCircleCache userCircleCache) async {
    try {
      String url;

      ReplyObject encryptedCopy = await ForwardSecrecy.encryptReplyObject(userFurnace, replyObject, userCircleCache);

      Device device = await globalState.getDevice();

      Map map = {
        'apikey': userFurnace.apikey,
        'creator': replyObject.creator!.id,
        'circleID': userCircleCache.circle!,
        "circleObjectID": replyObject.circleObjectID,
        'seed': replyObject.seed,
        'pushtoken': device.pushToken,
        'body': encryptedCopy.body,
        'type': replyObject.type,
        'crank': encryptedCopy.crank,
        'signature': encryptedCopy.signature,
        'verification': encryptedCopy.verification,
        'senderRatchetPublic': encryptedCopy.senderRatchetPublic,
        'ratchetIndexes': encryptedCopy.ratchetIndexes,
        'replyObjectID': replyObject.id,
      };

      //url = userFurnace.url! + Urls.WALLREPLY + replyObject.id!;
      url = userFurnace.url! + Urls.WALLREPLY + 'undefined';

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
              retries = RETRIES.MAX_MESSAGE_RETRIES;

              Map<String, dynamic> jsonResponse =
              await EncryptAPITraffic.decryptJson(response.body);

              ReplyObject retValue = ReplyObject.fromJson(jsonResponse["replyObject"]);

              retValue.revertEncryptedFields(replyObject);

              await TableReplyObjectCache.updateCacheSingleObject(
                userFurnace.userid!, retValue);

              TableUserCircleCache.updateLastItemUpdate(userCircleCache.circle!,
                  retValue.creator!.id, retValue.lastUpdate);

              return retValue;
            } else if (response.statusCode == 401) {
              await navService.logout(userFurnace);
              return replyObject;
            } else {
              debugPrint("${response.statusCode}: ${response.body}");

              if (retries == RETRIES.MAX_MESSAGE_RETRIES)
                LogBloc.insertLog("${response.statusCode} : ${response.body}",
                  "ReplyObjectService.hideReplyObject");
            }
          } on SocketException catch (err, trace) {
            debugPrint(
                'ReplyObjectService.updateReplyObject: ${err.toString()}');
            if (retries == RETRIES.MAX_MESSAGE_RETRIES)
              LogBloc.insertError(err, trace);
          } catch (err, trace) {
            debugPrint(
                'ReplyObjectService.updateReplyObject: ${err.toString()}');
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
      debugPrint("ReplyObjectService.updateReplyObject: ${err.toString()}");
      rethrow;
    }

    return replyObject;
  }

  Future<ReplyObject> hideReplyObject(UserCircleCache userCircleCache,
      UserFurnace userFurnace, ReplyObject replyObject) async {
    try {
      String url = userFurnace.url! + Urls.WALLREPLY_HIDE + 'undefined';

      Map map = {
        'circleid': userCircleCache.circle!,
        'replyObjectID': replyObject.id,
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

              await TableReplyObjectCache.delete(replyObject.id);

              if (jsonResponse.containsKey('lastReplyObject')) {
                ReplyObject retValue =
                    ReplyObject.fromJson(jsonResponse['lastReplyObject']);

                TableUserCircleCache.updateLastItemUpdate(retValue.circle!.id, userFurnace.userid, retValue.lastUpdate);
              }
              return replyObject;
            } else if (response.statusCode == 401) {
              await navService.logout(userFurnace);
              return replyObject;
            } else {
              debugPrint("${response.statusCode}: ${response.body}");

              if (retries == RETRIES.MAX_MESSAGE_RETRIES)
                LogBloc.insertLog('${response.statusCode} : ${response.body}',
                    'ReplyObjectService.hideReplyObject');
            }
          } on SocketException catch (err, trace) {
            debugPrint(
                'ReplyObjectService.hideReplyObject: ${err.toString()}');
            if (retries == RETRIES.MAX_MESSAGE_RETRIES)
              LogBloc.insertError(err, trace);
          } catch (err, trace) {
            debugPrint(
                'ReplyObjectService.hideReplyObject: ${err.toString()}');
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
      debugPrint('ReplyObjectService.hideReplyObject: ${err.toString()}');
      rethrow;
    }
    return replyObject;
  }

  Future<ReplyObject> getSingleObject(
      UserFurnace userFurnace,
      String replyObjectID,
      String circleID,
      ) async {
    String url;

    try {
      url = userFurnace.url! + Urls.WALLREPLY_GETSINGLE;

      if (await Network.isConnected()) {
        debugPrint(url);

        int retries = 0;

        Map map = {
          'replyObjectID': replyObjectID,
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

              if (jsonResponse.containsKey("replyObject")) {
                ReplyObject replyObject = ReplyObject.fromJson(jsonResponse["replyObject"]);

                return replyObject;
              }
            } else if (response.statusCode == 401) {
              await navService.logout(userFurnace);
              return ReplyObject(ratchetIndexes: []);
            } else {
              debugPrint("${response.statusCode}: ${response.body}");
              if (retries == RETRIES.MAX_FETCH_RETRY)
                LogBloc.insertLog("${response.statusCode} : ${response.body}",
                  'ReplyObjectService.getSingleObject');
            }
          } on SocketException catch (err, trace) {
            debugPrint('ReplyObjectService.getSingleObject: ${err.toString()}');
            if (retries == RETRIES.MAX_FETCH_RETRY)
              LogBloc.insertError(err, trace);
          } catch (err, trace) {
            debugPrint("ReplyObjectService.getSingleObject: ${err.toString()}");
            if (retries == RETRIES.MAX_FETCH_RETRY)
              LogBloc.insertError(err, trace);
          }

          if (retries == RETRIES.MAX_FETCH_RETRY)
            throw Exception('failed to get reply objects');

          await Future.delayed(const Duration(milliseconds: RETRIES.TIMEOUT));
          retries++;
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("ReplyObjectService: getReplyObject: $error");
    }
    return ReplyObject(ratchetIndexes: []);
  }

  Future<List<ReplyObject>> fetchReplyObjects(
      String circleID,
    UserFurnace userFurnace,
      String circleObjectID,
      int amount
      ) async {
    String url;

    try {
      if (turnOff) return [];

      url = "${userFurnace.url!}${Urls.WALLREPLY_BYOBJECT}$circleObjectID&$circleID";

      Map map = {
        'circleID': circleID,
        'circleObjectID': circleObjectID,
      };

      if (await Network.isConnected()) {

        map = await EncryptAPITraffic.encrypt(map);

        debugPrint(url);

        int retries = 0;

        while (retries <= RETRIES.MAX_FETCH_RETRY) {
          try {
            final response = await http.post(Uri.parse(url), headers: {
              'Authorization': userFurnace.token!,
              'content-type': 'application/json',
            }, body: json.encode(map));

            if (response.statusCode == 200) {
              Map<String, dynamic> jsonResponse =
              await EncryptAPITraffic.decryptJson(response.body);

              if (jsonResponse.containsKey('usercircles')) {
                _updateMemberAttributes(userFurnace,
                    UserCircleCollection.fromJSON(jsonResponse, "usercircles"));
              }

              if (jsonResponse.containsKey('replyobjects')) {
                ReplyObjectCollection replyObjectCollection =
                    ReplyObjectCollection.fromJSON(jsonResponse);
                return replyObjectCollection.replyObjects;
              }
            } else if (response.statusCode == 401) {
              await navService.logout(userFurnace);
              return [];
            } else {
              debugPrint("${response.statusCode}: ${response.body}");
              if (retries == RETRIES.MAX_FETCH_RETRY)
                LogBloc.insertLog('${response.statusCode} : ${response.body}',
                  'ReplyObjectService.fetchReplyObjects');
            }
          } on SocketException catch (err, trace) {
            debugPrint(
                'ReplyObjectService.fetchReplyObjects: ${err.toString()}');
            if (retries == RETRIES.MAX_FETCH_RETRY)
              LogBloc.insertError(err, trace);
          } catch (err, trace) {
            debugPrint(
                'ReplyObjectService.fetchReplyObjects: ${err.toString()}');
            if (retries == RETRIES.MAX_FETCH_RETRY)
              LogBloc.insertError(err, trace);
          }

          if (retries == RETRIES.MAX_FETCH_RETRY)
            throw Exception('failed to get reply objects');

          await Future.delayed(const Duration(milliseconds: RETRIES.TIMEOUT));
          retries++;
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('ReplyObjectService: fetchReplyObjects: $error');
    }

    return [];
  }

  Future<ReplyObject> deleteReplyObject(UserCircleCache userCircleCache, UserFurnace userFurnace, ReplyObject replyObject) async {
    try {

     // String url = "${userFurnace.url!}${Urls.WALLREPLY}${replyObject.id!}&${replyObject.circleObjectID}&${userCircleCache.circle!}";
      String url = userFurnace.url! + Urls.WALLREPLY_DELETE;

      Map map = {
        'circleID': userCircleCache.circle!,
        'replyObjectID': replyObject.id,
        'circleObjectID': replyObject.circleObjectID,
      };

      if (await Network.isConnected()) {
        debugPrint(url);

        int retries = 0;

        map = await EncryptAPITraffic.encrypt(map);

        while (retries <= RETRIES.MAX_MESSAGE_RETRIES) {
          try {
            final response = await http.delete(
              Uri.parse(url),
              headers: {'Authorization': userFurnace.token!}
            );

            if (response.statusCode == 200) {
              // Map<String, dynamic> jsonResponse =
              // await EncryptAPITraffic.decryptJson(response.body);

              await TableReplyObjectCache.delete(replyObject.id);

              return replyObject;
             } else if (response.statusCode == 401) {
              await navService.logout(userFurnace);
              return replyObject;
            } else {
              if (response.body.toLowerCase().contains("access denied"))
                throw (response.body);

              debugPrint("${response.statusCode}: ${response.body}");
              if (retries == RETRIES.MAX_MESSAGE_RETRIES)
                LogBloc.insertLog('${response.statusCode} : ${response.body}',
                    'ReplyObjectService.deleteReplyObject');
            }
          } on SocketException catch (err, trace) {
            debugPrint('ReplyObjectService.deleteReplyObject: ${err.toString()}');
            if (retries == RETRIES.MAX_MESSAGE_RETRIES) {
              LogBloc.insertError(err, trace);
            }
          } catch (err, trace) {
            if (err.toString().toLowerCase().contains("access denied")) rethrow;

            debugPrint('ReplyObjectService.deleteReplyObject: ${err.toString()}');
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
      debugPrint("ReplyObjectService.deleteReplyObject: ${err.toString()}");
      rethrow;
    }

    return replyObject;
  }

  Future<void> reportViolation(UserFurnace userFurnace, ReplyObject replyObject, Violation violation, UserCircleCache userCircleCache) async {
    String url = userFurnace.url! + Urls.WALLREPLY_REPORT;
    debugPrint(url);

    Map map = {
      "violation": violation,
      "circleID": userCircleCache.circle!,
    };

    int retries = 0;

    map= await EncryptAPITraffic.encrypt(map);

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
                'ReplyObjectService.reportViolation');
        }
      } on SocketException catch (err, trace) {
        debugPrint('ReplyObjectService.reportViolation: ${err.toString()}');
        if (retries == RETRIES.MAX_MESSAGE_RETRIES)
          LogBloc.insertError(err, trace);
      } catch (err, trace) {
        debugPrint('ReplyObjectService.reportViolation: ${err.toString()}');
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

  Future<ReplyObject> deleteReaction(
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      ReplyObject replyObject,
      CircleObjectReaction circleObjectReaction) async {
    try {
      if (circleObjectReaction.id == null) {
        throw ('reaction delete before save');
      }
      String url = userFurnace.url! +
        Urls.WALLREPLY_REACTION +
        'undefined';

      Device device = await globalState.getDevice();
      Map map = {
        'apikey': userFurnace.apikey,
        'id': circleObjectReaction.id,
        'circle': userCircleCache.circle!,
        'replyObjectID': replyObject.id,
        'circleObjectID': replyObject.circleObjectID,
        'circleObjectReactionID': circleObjectReaction.id!,
        'replyobjectid': replyObject.id,
        'pushtoken': device.pushToken,
      };

      if (await Network.isConnected()) {
        debugPrint(url);

        int retries = 0;

        map = await EncryptAPITraffic.encrypt(map);

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

              ReplyObject retValue = ReplyObject.fromJson(jsonResponse["replyobject"]);

              return retValue;
            } else if (response.statusCode == 401) {
              await navService.logout(userFurnace);
              return replyObject;
            } else {
              debugPrint("${response.statusCode}: ${response.body}");
              if (retries == RETRIES.MAX_MESSAGE_RETRIES)
                LogBloc.insertLog('${response.statusCode} : ${response.body}',
                  'ReplyObjectService.deleteReaction');
            }
          } on SocketException catch (err, trace) {
            debugPrint("ReplyObjectService.deleteReaction: ${err.toString()}");
            if (retries == RETRIES.MAX_MESSAGE_RETRIES)
              LogBloc.insertError(err, trace);
          } catch (err, trace) {
            debugPrint("ReplyObjectService.deleteReaction: ${err.toString()}");
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
      debugPrint('ReplyObjectService.deleteReaction: ${err.toString()}');
      rethrow;
    }
    return replyObject;
  }

  Future<ReplyObject> postReaction(
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      ReplyObject replyObject,
      CircleObjectReaction circleObjectReaction
      ) async {
    try {
      String url = userFurnace.url! + Urls.WALLREPLY_REACTION;

      Device device = await globalState.getDevice();

      Map map = {
        'apikey': userFurnace.apikey,
        'circle': userCircleCache.circle!,
        'id': replyObject.id,
        'circleObjectID': replyObject.circleObjectID,
        'index': circleObjectReaction.index,
        'emoji': circleObjectReaction.emoji,
        'replyobjectid': replyObject.id,
        'pushtoken': device.pushToken,
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

              ReplyObject retValue = ReplyObject.fromJson(jsonResponse["replyobject"]);

              replyObject.reactions = retValue.reactions;

              TableReplyObjectCache.updateCacheSingleObject(
                userFurnace.userid!, replyObject);

              return retValue;
            } else if (response.statusCode == 401) {
              await navService.logout(userFurnace);
              return replyObject;
            } else {
              debugPrint("${response.statusCode}: ${response.body}");
              if (retries == RETRIES.MAX_MESSAGE_RETRIES)
                LogBloc.insertLog('${response.statusCode} : ${response.body}',
                    'ReplyObjectService.postReaction');
            }
          } on SocketException catch (err, trace) {
            debugPrint('ReplyObjectService.postReaction: ${err.toString()}');
            if (retries == RETRIES.MAX_MESSAGE_RETRIES)
              LogBloc.insertError(err, trace);
          } catch (err, trace) {
            debugPrint('ReplyObjectService.postReaction: ${err.toString()}');
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
      debugPrint("ReplyObjectService.postReaction: ${err.toString()}");
      rethrow;
    }
    return replyObject;
  }

}