import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
//import 'package:http_retry/http_retry.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/encryption/encryptapitraffic.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/ratchetkey.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';
import 'package:ironcirclesapp/utils/network.dart';

class RatchetPublicKeyService {
  Future<bool> ratchetPublicKey(
      UserFurnace userFurnace, RatchetKey ratchetKey, String circleID,
      {List<CircleObject>? circleObjects}) async {
    try {
      String url = userFurnace.url! + Urls.RATCHETPUBLICKEY + 'undefined';

      Device device = await globalState.getDevice();

      Map map = {
        'device': device.uuid,
        'ratchetPublicKey': ratchetKey.removePrivateKey(),
        'circleID': circleID,
        //'circleobjects': circleObjects,
      };

      if (circleObjects != null) {
        if (circleObjects.length < 100) {
          //user might have just cleared the cache
          map["circleobjects"] = circleObjects;
        }
      }

      map = await EncryptAPITraffic.encrypt(map);

      if (await Network.isConnected()) {
        debugPrint(url);

        int retries = 0;

        while (retries <= RETRIES.RATCHET_RETRIES) {
          try {
            final response = await http.put(Uri.parse(url),
                headers: {
                  'Authorization': userFurnace.token!,
                  'Content-Type': "application/json",
                },
                body: json.encode(map));

            if (response.statusCode == 200) {
              // Map<String, dynamic> jsonResponse =
              // await EncryptAPITraffic.decryptJson(response.body);

              return true;
            } else if (response.statusCode == 401) {
              await navService.logout(userFurnace);
            } else {
              debugPrint("${response.statusCode}: ${response.body}");
              if (retries == RETRIES.MAX_MESSAGE_RETRIES) {
                throw Exception(
                    'RatchetPublicKeyService.ratchetPublicKey: failed to ratchetKey');
              }
            }
          } catch (error) {
            debugPrint('RatchetPublicKeyService.ratchetPublicKey: $error');

            if (retries == RETRIES.MAX_MESSAGE_RETRIES) {
              //will be logged below
              throw Exception(error);
            }
          }

          await Future.delayed(const Duration(milliseconds: 100));
          retries++;
        }

        return false;
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('RatchetPublicKeyService.ratchetPublicKey: $error');
      throw Exception(error);
    }

    return false;
  }

  Future<bool> updateUserKey(
    UserFurnace userFurnace,
    RatchetKey userKey,
  ) async {
    try {
      String url = userFurnace.url! + Urls.SET_REMOTE_PUBLIC;

      Map map = {
        'ratchetPublicKey': userKey.removePrivateKey(),
      };

      if (await Network.isConnected()) {
        map = await EncryptAPITraffic.encrypt(map);

        debugPrint(url);

        final response = await http.post(Uri.parse(url),
            headers: {
              'Authorization': userFurnace.token!,
              'Content-Type': "application/json",
            },
            body: json.encode(map));

        if (response.statusCode == 200) {
          //Map<String, dynamic> jsonResponse = json.decode(response.body);

          /*
          List<RatchetKey> ratchetKeys =
          RatchetKeyCollection.fromJSON(jsonResponse, "ratchetPublicKeys").ratchetKeys;
*/

          return true;
        } else if (response.statusCode == 401) {
          await navService.logout(userFurnace);
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
          throw Exception(response.body);
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('RatchetPublicKeyService.updateRatchetPublicKeys: $error');
      throw Exception(error);
    }

    return false;
  }

  Future<bool> updateRatchetPublicKeys(UserFurnace userFurnace,
      List<RatchetKey> ratchetKeys, bool newUser) async {
    try {
      String url = userFurnace.url! + Urls.RATCHETPUBLICKEY;

      Map map = {
        'ratchetPublicKeys':
            RatchetKeyCollection.removePrivateKeys(ratchetKeys),
        'newUser': newUser,
      };

      map = await EncryptAPITraffic.encrypt(map);

      if (await Network.isConnected()) {
        debugPrint(url);

        final response = await http.post(Uri.parse(url),
            headers: {
              'Authorization': userFurnace.token!,
              'Content-Type': "application/json",
            },
            body: json.encode(map));

        if (response.statusCode == 200) {
          // Map<String, dynamic> jsonResponse =
          // await EncryptAPITraffic.decryptJson(response.body);

          /*
          List<RatchetKey> ratchetKeys =
          RatchetKeyCollection.fromJSON(jsonResponse, "ratchetPublicKeys").ratchetKeys;
*/

          return true;
        } else if (response.statusCode == 401) {
          await navService.logout(userFurnace);
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
          throw Exception(response.body);
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('RatchetPublicKeyService.updateRatchetPublicKeys: $error');
      throw Exception(error);
    }

    return false;
  }

  static Future<List<RatchetKey>> fetchMemberPublicKeys(
      UserFurnace userFurnace, String circleID) async {
    List<RatchetKey> retValue = [];
    try {
      String url = userFurnace.url! + Urls.RATCHETPUBLICKEY_GETPUBLIC;

      //throw ('chaos');

      if (await Network.isConnected()) {
        debugPrint(url);

        var client = RetryClient(http.Client(), retries: RETRIES.HTTP_RETRY);

        int retries = 0;

        Map map = {
          'circleID': circleID,
        };

        map = await EncryptAPITraffic.encrypt(map);

        while (retries <= RETRIES.MAX_MESSAGE_RETRIES) {
          try {
            final response = await client.post(
              Uri.parse(url),
              headers: {
                'Authorization': userFurnace.token!,
                'Content-Type': "application/json"
              },
              body: json.encode(map),
            );

            if (response.statusCode == 200) {
              Map<String, dynamic> jsonResponse =
                  await EncryptAPITraffic.decryptJson(response.body);

              if (jsonResponse.containsKey('ratchetPublicKeys')) {
                retValue = RatchetKeyCollection.fromJSON(
                        jsonResponse, "ratchetPublicKeys")
                    .ratchetKeys;

                return retValue;
              } else
                throw ('could not fetch public keys');
            } else if (response.statusCode == 401) {
              await navService.logout(userFurnace);
              throw ('could not fetch public keys');
            } else {
              debugPrint("${response.statusCode}: ${response.body}");
              //throw ('could not fetch public keys');
              if (response.body.contains(ErrorMessages.USER_BEING_VOTED_OUT)) {
                retries = RETRIES.MAX_MESSAGE_RETRIES;
                throw (ErrorMessages.USER_BEING_VOTED_OUT);
              }
            }
          } on SocketException catch (err, trace) {
            debugPrint(
                'RatchetPublicKeyService.fetchMemberPublicKeys: ${err.toString()}');

            if (retries == RETRIES.MAX_MESSAGE_RETRIES) {
              LogBloc.insertError(err, trace);
              throw ('could not fetch public keys');
            }
          } catch (err, trace) {
            debugPrint(
                'RatchetPublicKeyService.fetchMemberPublicKeys: ${err.toString()}');
            if (err.toString().contains(ErrorMessages.USER_BEING_VOTED_OUT)) {
              rethrow;
            } else if (retries == RETRIES.MAX_MESSAGE_RETRIES) {
              LogBloc.insertError(err, trace);
              throw ('could not fetch public keys');
            }
          }

          retries++;
        }

        //if we made it here, something went wrong
        throw ('could not fetch public keys');
      } else
        throw ('internet not detected');
    } on SocketException catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint(
          'RatchetPublicKeyService.fetchMemberPublicKeys: ${err.toString()}');
      throw ('could not fetch public keys');
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint(
          'RatchetPublicKeyService.fetchMemberPublicKeys: ${err.toString()}');
      if (err.toString().contains(ErrorMessages.USER_BEING_VOTED_OUT)) {
        rethrow;
      } else
        throw ('could not fetch public keys');
    }
  }

  static Future<RatchetKey> fetchMemberPublicKey(
      UserFurnace userFurnace, String userID) async {
    try {
      String url = userFurnace.url! + Urls.PUBLICMEMBERKEY;

      Map map = {
        "userID": userID,
      };

      map = await EncryptAPITraffic.encrypt(map);

      if (await Network.isConnected()) {
        debugPrint(url);

        var client = RetryClient(http.Client(), retries: 3);

        final response = await client.post(
          Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json"
          },
          body: json.encode(map),
        );

        if (response.statusCode == 200) {
          Map<String, dynamic> jsonResponse =
          await EncryptAPITraffic.decryptJson(response.body);

          if (jsonResponse.containsKey('publicKey')) {
            RatchetKey retValue =
                RatchetKey.fromJson(jsonResponse["publicKey"]);

            return retValue;
          } else
            throw ('could not fetch public key');
        } else if (response.statusCode == 401) {
          await navService.logout(userFurnace);
          throw ('could not fetch public keys');
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
          throw ('could not fetch public keys');
        }
      } else
        throw ('could not fetch public keys');
    } on SocketException catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint(
          'RatchetPublicKeyService.fetchMemberPublicKey: ${err.toString()}');
      throw ('could not fetch public keys');
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint(
          'RatchetPublicKeyService.fetchMemberPublicKey: ${err.toString()}');
      throw Exception(err);
    }
  }

  static Future<List<RatchetKey>> fetchMemberUserPublicKeys(
      UserFurnace userFurnace, List<User> passwordHelpers) async {
    List<RatchetKey> retValue = [];
    try {
      String url = userFurnace.url! + Urls.PUBLICMEMBERKEYS;

      if (await Network.isConnected()) {
        debugPrint(url);

        var client = RetryClient(http.Client(), retries: 3);

        Map map = {
          "passwordHelpers": passwordHelpers,
        };

        map = await EncryptAPITraffic.encrypt(map);

        final response = await client.post(Uri.parse(url),
            headers: {
              'Authorization': userFurnace.token!,
              'Content-Type': "application/json",
            },
            body: json.encode(map));

        if (response.statusCode == 200) {
          Map<String, dynamic> jsonResponse =
          await EncryptAPITraffic.decryptJson(response.body);

          if (jsonResponse.containsKey('ratchetPublicKeys')) {
            retValue =
                RatchetKeyCollection.fromJSON(jsonResponse, "ratchetPublicKeys")
                    .ratchetKeys;

            return retValue;
          } else
            throw ('could not fetch public keys');
        } else if (response.statusCode == 401) {
          await navService.logout(userFurnace);
          throw ('could not fetch public keys');
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
          throw ('could not fetch public keys');
        }
      } else
        throw ('could not fetch public keys');
    } on SocketException catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint(
          'RatchetPublicKeyService.fetchMemberPublicKeys: ${err.toString()}');
      throw ('could not fetch public keys');
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint(
          'RatchetPublicKeyService.fetchMemberPublicKeys: ${err.toString()}');
      throw Exception(err);
    }
  }
}
