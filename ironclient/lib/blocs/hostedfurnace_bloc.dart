import 'dart:async';
import 'dart:io';

import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/export_constants.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy.dart';
import 'package:ironcirclesapp/encryption/securerandomgenerator.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/hostedinvitation.dart';
import 'package:ironcirclesapp/models/networkrequest.dart';
import 'package:ironcirclesapp/models/ratchetkey.dart';
import 'package:ironcirclesapp/models/violation.dart';
import 'package:ironcirclesapp/services/cache/export_tables.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/table_userfurnace.dart';
import 'package:ironcirclesapp/services/hostedfurnace_service.dart';
import 'package:rxdart/rxdart.dart';

enum HostedFurnaceUpdatedType { text, discoverable, memberAutonomy }

class HostedFurnaceBloc {
  late HostedFurnaceService _hostedFurnaceService;
  late GlobalEventBloc _globalEventBloc;

  final _magicLink = PublishSubject<String>();
  Stream<String> get magicLink => _magicLink.stream;

  final _hostedInvitation = PublishSubject<HostedInvitation>();
  Stream<HostedInvitation> get hostedInvitation => _hostedInvitation.stream;

  final _alreadyConnected = PublishSubject<bool>();
  Stream<bool> get alreadyConnected => _alreadyConnected.stream;

  final _requestsBlinkStop = PublishSubject<bool>();
  Stream<bool> get requestsBlinkStop => _requestsBlinkStop.stream;

  final _notConnectedPublicNetworks = PublishSubject<List<HostedFurnace>>();
  Stream<List<HostedFurnace>> get notConnectedPublicNetworks =>
      _notConnectedPublicNetworks.stream;

  final _networkApprovedUpdated = PublishSubject<HostedFurnace>();
  Stream<HostedFurnace> get networkApprovedUpdated =>
      _networkApprovedUpdated.stream;

  final _networkOverrideUpdated = PublishSubject<HostedFurnace>();
  Stream<HostedFurnace> get networkOverrideUpdated =>
      _networkOverrideUpdated.stream;

  final _members = PublishSubject<List<User>>();
  Stream<List<User>> get members => _members.stream;

  final _networkRequests = PublishSubject<List<NetworkRequest>>();
  Stream<List<NetworkRequest>> get networkRequests => _networkRequests.stream;

  final _requests = PublishSubject<List<NetworkRequest>>();
  Stream<List<NetworkRequest>> get requests => _requests.stream;

  final _updatedFurnace = PublishSubject<UserFurnace>();
  Stream<UserFurnace> get updatedFurnace => _updatedFurnace.stream;

  final _discoverableNetworks = PublishSubject<List<HostedFurnace>>();
  Stream<List<HostedFurnace>> get discoverableNetworks =>
      _discoverableNetworks.stream;

  final _pendingDiscoverableNetworks = PublishSubject<List<HostedFurnace>>();
  Stream<List<HostedFurnace>> get pendingDiscoverableNetworks =>
      _pendingDiscoverableNetworks.stream;

  final _networkRetrieved = PublishSubject<HostedFurnace>();
  Stream<HostedFurnace> get networkRetrieved => _networkRetrieved.stream;

  final _imageChanged = PublishSubject<UserFurnace>();
  Stream<UserFurnace> get imageChanged => _imageChanged.stream;

  final _networkImage = PublishSubject<File>();
  Stream<File> get networkImage => _networkImage.stream;

  final _imageDownloaded = PublishSubject<UserFurnace>();
  Stream<UserFurnace> get imageDownloaded => _imageDownloaded.stream;

  final _publicImageDownloaded = PublishSubject<bool>();
  Stream<bool> get publicImageDownloaded => _publicImageDownloaded.stream;

  final _roleUpdated = PublishSubject<bool>();
  Stream<bool> get roleUpdated => _roleUpdated.stream;

  final _lockedOut = PublishSubject<User>();
  Stream<User> get lockedOut => _lockedOut.stream;

  final _nameAndAccessCodeChanged = PublishSubject<bool>();
  Stream<bool> get nameAndAccessCodeChanged => _nameAndAccessCodeChanged.stream;

  /*final _discoverableChanged = PublishSubject<bool>();
  Stream<bool> get discoverableChanged => _discoverableChanged.stream;
   */

  final _ageRestrictedChanged = PublishSubject<bool>();
  Stream<bool> get ageRestrictedChanged => _ageRestrictedChanged.stream;

  final _storageSet = PublishSubject<bool>();
  Stream<bool> get storageSet => _storageSet.stream;

  final _storageLoaded = PublishSubject<HostedFurnaceStorage>();
  Stream<HostedFurnaceStorage> get storageLoaded => _storageLoaded.stream;

  final _updated = PublishSubject<HostedFurnaceUpdatedType>();
  Stream<HostedFurnaceUpdatedType> get updated => _updated.stream;

  final _requestsError = PublishSubject<bool>();
  Stream<bool> get requestsError => _requestsError.stream;

  final _wallEnabledChanged = PublishSubject<bool>();
  Stream<bool> get wallEnabledChanged => _wallEnabledChanged.stream;

  final _memberAutonomyChanged = PublishSubject<bool>();
  Stream<bool> get memberAutonomyChanged => _memberAutonomyChanged.stream;

  HostedFurnaceBloc(GlobalEventBloc globalEventBloc) {
    _globalEventBloc = globalEventBloc;
    _hostedFurnaceService = HostedFurnaceService(globalEventBloc);
  }

  broadcastNetworkRequests(List<NetworkRequest> networkRequests) {
    _networkRequests.sink.add(networkRequests);
  }

  Future<void> setStorage(
      UserFurnace userFurnace,
      String location,
      String accessKey,
      String secretKey,
      String region,
      String mediaBucket) async {
    try {
      await _hostedFurnaceService.setStorage(
          userFurnace, location, accessKey, secretKey, region, mediaBucket);
      _storageSet.sink.add(true);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      _storageSet.sink.addError(error);
    }
  }

  Future<void> getStorage(UserFurnace userFurnace) async {
    try {
      HostedFurnaceStorage hostedFurnaceStorage =
          await _hostedFurnaceService.getStorage(userFurnace);

      _storageLoaded.sink.add(hostedFurnaceStorage);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      _storageLoaded.sink.addError(error);
    }
  }

  Future<void> getMembers(UserFurnace userFurnace) async {
    try {
      if (userFurnace.connected == false) return;

      List<User> members = await _hostedFurnaceService.getMembers(userFurnace);
      _members.sink.add(members);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      _members.sink.addError(error);
    }
  }

  Future<void> setRole(UserFurnace userFurnace, User user, int role) async {
    try {
      await _hostedFurnaceService.setRole(userFurnace, user, role);

      _roleUpdated.sink.add(true);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      _roleUpdated.sink.addError(error);
    }
  }

  Future<void> reportAvatar(
      UserFurnace userFurnace, Violation violation) async {
    try {
      await _hostedFurnaceService.reportAvatar(userFurnace, violation);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      _roleUpdated.sink.addError(error);
    }
  }

  getHostedFurnace(
      GlobalEventBloc globalEventBloc, UserFurnace? userFurnace) async {
    try {
      if (userFurnace!.hostedName != null &&
          userFurnace.hostedAccessCode != null && userFurnace.connected == true) {
        HostedFurnace? network =
            await _hostedFurnaceService.getHostedFurnace(userFurnace);

        ///update table with new image id if its different
        if (network != null) {
          if (network.hostedFurnaceImage != null) {
            if (userFurnace.hostedFurnaceImageId !=
                    network.hostedFurnaceImage!.id ||
                !FileSystemService.furnaceImageExistsSync(
                    userFurnace.userid!, network.hostedFurnaceImage)) {
              userFurnace.hostedFurnaceImageId = network.hostedFurnaceImage!.id;
              //TableUserFurnace.upsert(userFurnace);

              downloadImage(globalEventBloc, userFurnace, network);
            }
          }

          _networkRetrieved.sink.add(network);
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      _networkRetrieved.sink.addError(error);
    }
    return;
  }

  Future<void> updateImage(UserFurnace? userFurnace, File? image) async {
    try {
      if (image != null) {
        bool updated =
            await _hostedFurnaceService.updateImage(userFurnace!, image);
        if (updated == true) {
          _imageChanged.sink.add(userFurnace);
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      //debugPrint('HostedFurnaceBloc.updateImage $err');
      _imageChanged.sink.addError(err);
    }
  }

  downloadImage(GlobalEventBloc globalEventBloc, UserFurnace userFurnace,
      HostedFurnace network) async {
    try {
      if (network.hostedFurnaceImage != null) {
        if (!globalEventBloc
            .genericObjectExists(userFurnace.hostedFurnaceImageId!)) {
          globalEventBloc.addGenericObject(userFurnace.hostedFurnaceImageId!);

          bool success =
              await _hostedFurnaceService.downloadImage(userFurnace, network);

          if (success) {
            await TableUserFurnace.upsert(userFurnace);

            _imageDownloaded.sink.add(userFurnace);
          }
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      _imageDownloaded.sink.addError(err);
    }
  }

  downloadDiscoverableImage(GlobalEventBloc globalEventBloc,
      UserFurnace? userFurnace, HostedFurnace network) async {
    try {
      if (network.hostedFurnaceImage!.retries >=
          RETRIES.MAX_IMAGE_DOWNLOAD_RETRIES) {
        if (network.hostedFurnaceImage != null) {
          if (FileSystemService.discoverableFurnaceImageExistsSync(
              network.hostedFurnaceImage)) {
            network.hostedFurnaceImage!.thumbnailTransferState =
                BlobState.READY;
          } else {
            return;
          }
        } else {
          return;
        }
      }

      ///ignore while transfer in progress
      if (network.hostedFurnaceImage!.thumbnailTransferState ==
              BlobState.ENCRYPTING ||
          network.hostedFurnaceImage!.thumbnailTransferState ==
              BlobState.DECRYPTING ||
          network.hostedFurnaceImage!.thumbnailTransferState ==
              BlobState.UPLOADING ||
          network.hostedFurnaceImage!.thumbnailTransferState ==
              BlobState.DOWNLOADING) {
        if (!_globalEventBloc.furnaceImageExists(network.hostedFurnaceImage!) &&
            network.hostedFurnaceImage!.retries != -1 &&
            network.hostedFurnaceImage!.thumbnailTransferState !=
                BlobState.READY) {
          network.hostedFurnaceImage!.retries =
              RETRIES.MAX_IMAGE_DOWNLOAD_RETRIES;
        }
        return;
      }

      ///make sure it's not already being downloaded
      if (_globalEventBloc.furnaceImageExists(network.hostedFurnaceImage!)) {
        debugPrint('already in GlobalEventBloc');
        return;
      }

      debugPrint('notifyWhenThumbReady');

      if (network.hostedFurnaceImage!.id == null) {
        debugPrint('this should not happen');
      }

      debugPrint(network.hostedFurnaceImage!.id);

      ///Is the thumbnail cached?
      if (FileSystemService.discoverableFurnaceImageExistsSync(
          network.hostedFurnaceImage)) {
        if (network.hostedFurnaceImage!.thumbnailTransferState !=
            BlobState.READY) {
          network.hostedFurnaceImage!.thumbnailTransferState = BlobState.READY;
        }
      } else {
        network.hostedFurnaceImage!.thumbnailTransferState =
            BlobState.DOWNLOADING;
        _globalEventBloc.furnaceImageObjects.add(network.hostedFurnaceImage!);

        ///make sure the image isn't being uploaded
        if (network.hostedFurnaceImage == null) return;

        if (userFurnace == null) {
          _hostedFurnaceService.downloadDiscoverableImageUnauthorized(
              network, processThumbnailDownloadFailed);
        } else {
          _hostedFurnaceService.downloadDiscoverableImage(
              userFurnace, network, processThumbnailDownloadFailed);
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      _globalEventBloc.removeImageOnError(network.hostedFurnaceImage!);
      //_publicImageDownloaded.sink.addError(err);
      debugPrint('HostedFurnaceBloc.downloadPublicImage: $err');
    }
  }

  Future<void> updateText(UserFurnace userFurnace,
      {String? description,
      String? name,
      String? accessCode,
      String? link}) async {
    try {
      ///use a map that only updates a specific field in case the user is moving quickly through the screen making changes
      Map<String, dynamic> map = {};

      if (link != null) {
        userFurnace.link = link;
        map[TableUserFurnace.link] = link;
      }
      if (name != null) {
        userFurnace.hostedName = name;
        userFurnace.alias = name;
        if (userFurnace.authServer! == true) {
          globalState.userFurnace!.alias = name;
        }

        map[TableUserFurnace.hostedName] = name;
        map[TableUserFurnace.alias] = name;
      }
      if (accessCode != null) {
        userFurnace.hostedAccessCode = accessCode;
        if (userFurnace.authServer! == true) {
          globalState.userFurnace!.hostedAccessCode = accessCode;
        }
        map[TableUserFurnace.hostedAccessCode] = accessCode;
      }

      if (description != null) {
        userFurnace.description = description;
        map[TableUserFurnace.description] = description;
      }

      await TableUserFurnace.upsertReducedFields(userFurnace, map);

      bool updated = await _hostedFurnaceService.updateParams(userFurnace,
          description: description,
          newName: name,
          accessCode: accessCode,
          link: link);

      if (updated == true) {
        _updatedFurnace.sink.add(userFurnace);
        _updated.sink.add(HostedFurnaceUpdatedType.text);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      _updated.sink.addError(error);
    }
  }

  Future<void> getNetworkRequests(UserFurnace userFurnace) async {
    try {
      List<NetworkRequest> requests =
          await _hostedFurnaceService.getNetworkRequests(userFurnace);

      _networkRequests.sink.add(requests);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      _networkRequests.sink.addError(error);
    }
  }

  Future<void> updateRequest(
      UserFurnace userFurnace, NetworkRequest networkRequest) async {
    try {
      await _hostedFurnaceService.updateRequest(
          userFurnace, networkRequest, this);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
    }
  }

  Future<void> requestsDone() async {
    try {
      _requestsBlinkStop.sink.add(true);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
    }
  }

  Future<void> makeRequest(
      UserFurnace userFurnace, NetworkRequest networkRequest) async {
    try {
      await _hostedFurnaceService.makeRequest(userFurnace, networkRequest);
      _requestsError.sink.add(true);
    } catch (error, trace) {
      _requestsError.sink.addError(error);
      LogBloc.insertError(error, trace);
    }
  }

  Future<void> getRequests(UserFurnace userFurnace, User user) async {
    try {
      List<NetworkRequest> requests =
          await _hostedFurnaceService.getRequests(userFurnace, user);
      _requests.sink.add(requests);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      _requests.sink.addError(error);
    }
  }

  Future<void> updateAgeRestricted(
      UserFurnace userFurnace, bool ageRestricted) async {
    try {
      Map<String, dynamic> map = {TableUserFurnace.adultOnly: ageRestricted ? 1 : 0};
      await TableUserFurnace.upsertReducedFields(userFurnace, map);

      bool done = await _hostedFurnaceService.updateParams(userFurnace,
          adultOnly: ageRestricted);
      if (done == true) {
        _ageRestrictedChanged.sink.add(ageRestricted);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      _ageRestrictedChanged.sink.addError(error);
    }
  }

  Future<void> updateDiscoverable(
      UserFurnace userFurnace, bool discoverable) async {
    try {
      await _hostedFurnaceService.updateParams(userFurnace,
          discoverable: discoverable);

      Map<String, dynamic> map = {TableUserFurnace.discoverable: discoverable ? 1 : 0};
      await TableUserFurnace.upsertReducedFields(userFurnace, map);
      _updated.sink.add(HostedFurnaceUpdatedType.discoverable);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      _updated.sink.addError(error);
    }
  }

  Future<void> updateMemberAutonomy(
      UserFurnace userFurnace, bool autonomy) async {
    try {
      Map<String, dynamic> map = {TableUserFurnace.memberAutonomy: autonomy ? 1 : 0};
      await TableUserFurnace.upsertReducedFields(userFurnace, map);
      bool updated = await _hostedFurnaceService.updateParams(userFurnace,
          autonomy: autonomy);
      if (updated == true) {
        _memberAutonomyChanged.sink.add(autonomy);
      }
      _updated.sink.add(HostedFurnaceUpdatedType.memberAutonomy);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      _updated.sink.addError(error);
    }
  }

  Future<void> updateEnableWall(
      UserFurnace userFurnace, bool enableWall) async {
    try {
      Map<String, dynamic> map = {
        TableUserFurnace.enableWall: enableWall ? 1 : 0
      };
      await TableUserFurnace.upsertReducedFields(userFurnace, map);

      bool updated = await _hostedFurnaceService.updateParams(userFurnace,
          enableWall: enableWall);
      // _discoverableChanged.sink.add(true);
      if (updated == true) {
        _wallEnabledChanged.sink.add(enableWall);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      // _discoverableChanged.sink.addError(error);
    }
  }

  Future<void> getAllDiscoverable() async {
    try {
      List<HostedFurnace> hostedFurnaces =
          await _hostedFurnaceService.getAllDiscoverable();
      _discoverableNetworks.sink.add(hostedFurnaces);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      _discoverableNetworks.sink.addError(error);
    }
  }

  Future<List<HostedFurnace>> getDiscoverable(
      UserFurnace userFurnace, bool ageRestrict) async {
    try {
      List<HostedFurnace> hostedFurnaces =
          await _hostedFurnaceService.getDiscoverable(userFurnace, ageRestrict);
      _discoverableNetworks.sink.add(hostedFurnaces);
      return hostedFurnaces;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      _discoverableNetworks.sink.addError(error);
    }
    return [];
  }

  Future<List<HostedFurnace>> getPendingDiscoverable(
      UserFurnace userFurnace) async {
    try {
      List<HostedFurnace> hostedFurnaces =
          await _hostedFurnaceService.getPendingDiscoverable(userFurnace);
      _pendingDiscoverableNetworks.sink.add(hostedFurnaces);
      return hostedFurnaces;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      _pendingDiscoverableNetworks.sink.addError(error);
    }
    return [];
  }

  Future<void> setNetworkApproved(
      UserFurnace userFurnace, HostedFurnace furn, bool value) async {
    try {
      HostedFurnace hostedFurnace = await _hostedFurnaceService
          .setNetworkApproved(userFurnace, furn, value);
      _networkApprovedUpdated.sink.add(hostedFurnace);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      _networkApprovedUpdated.sink.addError(error);
    }
  }

  Future<void> setNetworkOverride(
      UserFurnace userFurnace, HostedFurnace furn, bool value) async {
    try {
      HostedFurnace hostedFurnace = await _hostedFurnaceService
          .setNetworkOverride(userFurnace, furn, value);
      _networkOverrideUpdated.sink.add(hostedFurnace);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      _networkOverrideUpdated.sink.addError(error);
    }
  }

  Future<void> changeNameAndAccessCode(
      UserFurnace userFurnace, String newName, String accessCode) async {
    try {
      await _hostedFurnaceService.updateParams(userFurnace,
          accessCode: accessCode);

      _nameAndAccessCodeChanged.sink.add(true);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      _nameAndAccessCodeChanged.sink.addError(error);
    }
  }

  Future<void> lockout(
      UserFurnace userFurnace, User member, bool lockedOut) async {
    try {
      await _hostedFurnaceService.lockout(userFurnace, member, lockedOut);

      member.lockedOut = lockedOut;

      _lockedOut.sink.add(member);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      _lockedOut.sink.addError(error);
    }
  }

  Future<bool> checkName(String name, {String? networkUrl, String? networkApiKey}) async {
    try {
      return await _hostedFurnaceService.checkName(name, networkUrl: networkUrl, networkApiKey: networkApiKey);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);

      if (error.toString().toLowerCase().contains('no host') || error.toString().toLowerCase().contains('buffering timed')) {
        throw("Could not connect");
      }
    }

    return false;
  }

  Future<String> valid(
      UserFurnace userFurnace, String name, String key, bool fromPublic,
      {String networkUrl = ''}) async {
    try {
      return await _hostedFurnaceService
          .valid(userFurnace, name, key, fromPublic, networkUrl: networkUrl);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      rethrow;
    }
  }

  Future<bool> requestApproved(UserFurnace userFurnace, String name,
      {String networkUrl = ''}) async {
    try {
      return await _hostedFurnaceService.requestApproved(userFurnace, name,
          networkUrl: networkUrl);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      rethrow;
    }
  }

  processUnauthorizedThumbnailDownloadFailed(HostedFurnace network) async {
    try {
      debugPrint('processPreviewDownloadFailed');

      File thumbnail = File(
          FileSystemService.returnDiscoverableNetworkImagePath(
              network.hostedFurnaceImage!)!);

      network.hostedFurnaceImage!.retries += 1;

      await FileSystemService.safeDelete(thumbnail);

      if (network.hostedFurnaceImage!.retries <
          RETRIES.MAX_IMAGE_DOWNLOAD_RETRIES) {
        network.hostedFurnaceImage!.thumbnailTransferState =
            BlobState.DOWNLOADING;
        _globalEventBloc.furnaceImageObjects.add(network.hostedFurnaceImage!);

        _hostedFurnaceService.downloadDiscoverableImageUnauthorized(
            network, processUnauthorizedThumbnailDownloadFailed);
      } else {
        network.hostedFurnaceImage!.thumbnailTransferState =
            BlobState.BLOB_DOWNLOAD_FAILED;
        _globalEventBloc.broadcastProgressNetworkImageIndicator(
            network.hostedFurnaceImage!);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint(
          'HostedFurnaceBloc.progressUnauthorizedThumbnailDownloadFailed: $err');
      processUnauthorizedThumbnailDownloadFailed(network);
    }
  }

  processThumbnailDownloadFailed(
    UserFurnace userFurnace,
    HostedFurnace network,
  ) async {
    try {
      debugPrint('processPreviewDownloadFailed');

      File thumbnail = File(
          FileSystemService.returnDiscoverableNetworkImagePath(
              network.hostedFurnaceImage!)!);

      network.hostedFurnaceImage!.retries += 1;

      await FileSystemService.safeDelete(thumbnail);

      if (network.hostedFurnaceImage!.retries <
          RETRIES.MAX_IMAGE_DOWNLOAD_RETRIES) {
        network.hostedFurnaceImage!.thumbnailTransferState =
            BlobState.DOWNLOADING;
        _globalEventBloc.furnaceImageObjects.add(network.hostedFurnaceImage!);

        _hostedFurnaceService.downloadDiscoverableImage(
            userFurnace, network, processThumbnailDownloadFailed);
      } else {
        network.hostedFurnaceImage!.thumbnailTransferState =
            BlobState.BLOB_DOWNLOAD_FAILED;
        _globalEventBloc.broadcastProgressNetworkImageIndicator(
            network.hostedFurnaceImage!);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('HostedFurnaceBloc.progressThumbnailDownloadFailed: $err');
      processThumbnailDownloadFailed(userFurnace, network);
    }
  }

  Future<void> getFirebaseDynamicLink(UserFurnace userFurnace, bool dm) async {
    try {
      String random = SecureRandomGenerator.generateString(
          length: 25, charset: SecureRandomGenerator.alphaNum);
      String internalLink = "https://ironcircles.com/install?$random";

      final dynamicLinkParams = DynamicLinkParameters(
        link: Uri.parse(internalLink),
        uriPrefix: "https://ironcircles.page.link",
        androidParameters: const AndroidParameters(
          packageName: "com.ironcircles.ironcirclesapp",
        ),
        iosParameters: IOSParameters(
            bundleId: "com.ironcircles.ironclient",
            appStoreId: '1634856740',
            fallbackUrl: Uri.parse('https://apps.apple.com/app/id/1634856740')),
        //fallbackUrl: Uri.parse(
        //  'https://apps.apple.com/us/app/ironcircles/id1634856740')),

        //navigationInfoParameters:
        //  NavigationInfoParameters(forcedRedirectEnabled: true),
        socialMetaTagParameters: SocialMetaTagParameters(
          title: "Invitation to an IronCircles network",
          description:
              "${userFurnace.username} invited you to the ${userFurnace.alias} network!",
          imageUrl: Uri.parse(Urls.WEB_ICON),
        ),
      );

      final unguessableDynamicLink =
          await FirebaseDynamicLinks.instance.buildShortLink(
        dynamicLinkParams,
        shortLinkType: ShortDynamicLinkType.unguessable,
      );

      ///get a rachetIndex to use for Magic Links
      RatchetKey ratchetKey = await ForwardSecrecy.generateBlankKeyPair();
      await TableRatchetKeyReceiver.insert(ratchetKey);

      await _hostedFurnaceService.postMagicLinkToNetwork(
          userFurnace,
          internalLink,
          unguessableDynamicLink.shortUrl.toString(),
          dm,
          ratchetKey);

      _magicLink.sink.add(unguessableDynamicLink.shortUrl.toString());
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      _magicLink.addError(error);
    }
  }

  /*Future<void> getMagicLinkToCircle(
      UserFurnace userFurnace, String circleID) async {
    try {
      String magicLink = await _hostedFurnaceService.getMagicLinkToCircle(
          userFurnace, circleID);

      _magicLink.sink.add(magicLink);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      _magicLink.addError(error);
    }
  }*/

  Future<List<HostedFurnace>> checkIfAlreadyOnNetworks(
      List<HostedFurnace> networks) async {
    if (globalState.user.id != null && globalState.user.id!.isNotEmpty) {
      List<UserFurnace> userFurnaces =
          await TableUserFurnace.readAllForUser(globalState.user.id!);

      for (UserFurnace userFurnace in userFurnaces) {
        networks.removeWhere((network) =>
            network.name.toLowerCase() == userFurnace.alias!.toLowerCase() &&
            userFurnace.connected == true);
      }
    }
    _notConnectedPublicNetworks.sink.add(networks);

    return networks;
  }

  Future<bool> checkIfAlreadyOnNetwork(String networkName) async {
    bool retValue = false;

    if (globalState.user.id != null && globalState.user.id!.isNotEmpty) {
      List<UserFurnace> userFurnaces =
          await TableUserFurnace.readAllForUser(globalState.user.id!);

      for (UserFurnace userFurnace in userFurnaces) {
        if (userFurnace.alias!.toLowerCase() == networkName.toLowerCase() &&
            userFurnace.connected == true) {
          _alreadyConnected.sink.add(true);
          retValue = true;
        }
      }
    }

    return retValue;
  }

  Future<void> validateMagicLinkToNetwork(String link) async {
    try {
      HostedInvitation? hostedInvitation =
          await _hostedFurnaceService.validateHostedLinkToNetwork(link);

      if (hostedInvitation != null) {
        checkIfAlreadyOnNetwork(hostedInvitation.hostedFurnace.name);

        _hostedInvitation.sink.add(hostedInvitation);
      } else
        throw ('an issue has occurred');
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      _hostedInvitation.addError(error);
    }
  }

  dispose() async {
    await _magicLink.drain();
    _magicLink.close();

    await _hostedInvitation.drain();
    _hostedInvitation.close();

    await _members.drain();
    _members.close();

    await _lockedOut.drain();
    _lockedOut.close();

    await _roleUpdated.drain();
    _roleUpdated.close();

    await _nameAndAccessCodeChanged.drain();
    _nameAndAccessCodeChanged.close();

    await _storageSet.drain();
    _storageSet.close();

    await _storageLoaded.drain();
    _storageLoaded.close();

    await _alreadyConnected.drain();
    _alreadyConnected.close();

    await _notConnectedPublicNetworks.drain();
    _notConnectedPublicNetworks.close();

    await _requestsBlinkStop.drain();
    _requestsBlinkStop.close();

    await _networkApprovedUpdated.drain();
    _networkApprovedUpdated.close();

    await _networkOverrideUpdated.drain();
    _networkOverrideUpdated.close();

    await _pendingDiscoverableNetworks.drain();
    _pendingDiscoverableNetworks.close();
  }
}
