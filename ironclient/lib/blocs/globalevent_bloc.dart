import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/constants/enums.dart';
import 'package:ironcirclesapp/models/album_item.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/hostedfurnaceimage.dart';
import 'package:ironcirclesapp/models/replyobject.dart';
import 'package:ironcirclesapp/screens/widgets/dialogpatterncapture.dart';
import 'package:ironcirclesapp/services/cache/table_circleobject.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';
import 'package:rxdart/rxdart.dart';

class GlobalEventBloc {
  List<AlbumItem> fullItems = [];
  List<AlbumItem> thumbnailItems = [];
  List<AlbumItem> retryItems = [];
  List<CircleObject> fullObjects = [];
  List<CircleObject> thumbnailObjects = [];
  List<CircleObject> albumObjects = [];
  List<HostedFurnaceImage> furnaceImageObjects = [];
  List<CircleObject> retryObjects = [];
  List<String> deletedSeeds = [];
  List<String> genericObjects = [];
  List<String> interactedMessages = [];

  final _taskComplete = PublishSubject<Map<String, dynamic>>();
  Stream<Map<String, dynamic>> get taskComplete => _taskComplete.stream;

  //large file transfer streams
  final _progressIndicator = PublishSubject<CircleObject>();
  Stream<CircleObject> get progressIndicator => _progressIndicator.stream;

  final _progressThumbnailIndicator = PublishSubject<CircleObject>();
  Stream<CircleObject> get progressThumbnailIndicator =>
      _progressThumbnailIndicator.stream;

  final progressFurnaceImageIndicator = PublishSubject<HostedFurnaceImage>();
  Stream<HostedFurnaceImage> get progressHostedFurnaceImageIndicator =>
      progressFurnaceImageIndicator.stream;

  final _itemProgressIndicator = PublishSubject<AlbumItem>();
  Stream<AlbumItem> get itemProgressIndicator => _itemProgressIndicator.stream;

  final _broadcastCircleObject = PublishSubject<CircleObject>();
  Stream<CircleObject> get circleObjectBroadcast =>
      _broadcastCircleObject.stream;

  final _broadcastReplyObject = PublishSubject<ReplyObject>();
  Stream<ReplyObject> get replyObjectBroadcast => _broadcastReplyObject.stream;

  final _circleObjectDeleted = PublishSubject<String>();
  Stream<String> get circleObjectDeleted => _circleObjectDeleted.stream;

  final _actionNeededRefresh = PublishSubject<bool>();
  Stream<bool> get actionNeededRefresh => _actionNeededRefresh.stream;

  final _invitationRefresh = PublishSubject<bool>();
  Stream<bool> get invitationRefresh => _invitationRefresh.stream;

  final _invitationReceived = PublishSubject<Invitation>();
  Stream<Invitation> get invitationReceived => _invitationReceived.stream;

  //deprecated
  final _previewDownloaded = PublishSubject<CircleObject>();
  Stream<CircleObject> get previewDownloaded => _previewDownloaded.stream;

  final _itemPreviewDownloaded = PublishSubject<AlbumItem>();
  Stream<AlbumItem> get itemPreviewDownloaded => _itemPreviewDownloaded.stream;

  final _objectDownloaded = PublishSubject<CircleObject>();
  Stream<CircleObject> get objectDownloaded => _objectDownloaded.stream;

  final _refreshHome = PublishSubject<bool>();
  Stream<bool> get refreshHome => _refreshHome.stream;

  final _wipePhone = PublishSubject<bool>();
  Stream<bool> get wipePhone => _wipePhone.stream;

  final _refreshMessageFeed = PublishSubject<bool>();
  Stream<bool> get refreshMessageFeed => _refreshMessageFeed.stream;

  // final _shareText = PublishSubject<String>();
  // Stream<String> get sharedText => _shareText.stream;
  //
  // // final _sharedMedia = PublishSubject<MediaCollection>();
  // // Stream<MediaCollection> get sharedMedia => _sharedMedia.stream;
  //
  // final _shareVideo = PublishSubject<File>();
  // Stream<File> get sharedVideo => _shareVideo.stream;

  final _closeHiddenCircles = PublishSubject<bool>();
  Stream<bool> get closeHiddenCircles => _closeHiddenCircles.stream;

  final _hideCircle = PublishSubject<String>();
  Stream<String> get hideCircle => _hideCircle.stream;

  final _unhideCircle = PublishSubject<String>();
  Stream<String> get unhideCircle => _unhideCircle.stream;

  final _notConnected = PublishSubject<bool>();
  Stream<bool> get notConnected => _notConnected.stream;

  final _recipeUpdated = PublishSubject<CircleObject>();
  Stream<CircleObject> get recipeUpdated => _recipeUpdated.stream;

  final _timerExpired = PublishSubject<String>();
  Stream<String> get timerExpired => _timerExpired.stream;

  final _showTOS = PublishSubject<bool>();
  Stream<bool> get showTOS => _showTOS.stream;

  final _showPinNeeded = PublishSubject<bool>();
  Stream<bool> get showPinNeeded => _showPinNeeded.stream;

  final _showBackupKeyNeeded = PublishSubject<bool>();
  Stream<bool> get showBackupKeyNeeded => _showBackupKeyNeeded.stream;

  final _circleObjectsRefreshed = PublishSubject<bool>();
  Stream<bool> get circleObjectsRefreshed => _circleObjectsRefreshed.stream;

  final _userFurnaceUpdated = PublishSubject<UserFurnace>();
  Stream<UserFurnace> get userFurnaceUpdated => _userFurnaceUpdated.stream;

  final _magicLinkBroadcast = PublishSubject<String>();
  Stream<String> get magicLinkBroadcast => _magicLinkBroadcast.stream;

  final _errorMessage = PublishSubject<String>();
  Stream<String> get errorMessage => _errorMessage.stream;

  final _memberRefreshNeeded = PublishSubject<bool>();
  Stream<bool> get memberRefreshNeeded => _memberRefreshNeeded.stream;

  final _showMustUpdate = PublishSubject<bool>();
  Stream<bool> get showMustUpdate => _showMustUpdate.stream;

  final _progress = PublishSubject<double>();
  Stream<double> get progress => _progress.stream;

  final _clear = PublishSubject<bool>();
  Stream<bool> get clear => _clear.stream;

  final cacheDeleted = PublishSubject<CircleObject>();
  Stream<CircleObject> get cacheDeletedStream => cacheDeleted.stream;

  final _deletedObject = PublishSubject<CircleObject>();
  Stream<CircleObject> get deletedObject => _deletedObject.stream;

  final refreshWall = PublishSubject<bool>();
  Stream<bool> get refreshWallStream => refreshWall.stream;

  final _addToLibrary = PublishSubject<List<CircleObject>>();
  Stream<List<CircleObject>> get addToLibrary => _addToLibrary.stream;

  final _removeFromLibrary = PublishSubject<List<CircleObject>>();
  Stream<List<CircleObject>> get removeFromLibrary => _removeFromLibrary.stream;

  final _networkDetailChanged = PublishSubject<bool>();
  Stream<bool> get networkDetailChanged => _networkDetailChanged.stream;

  final _openSlidingPanel = PublishSubject<String>();
  Stream<String> get openSlidingPanel => _openSlidingPanel.stream;

  final _openSlidingPanelWithShareTo = PublishSubject<SharedMediaHolder>();
  Stream<SharedMediaHolder> get openSlidingPanelWithShareTo =>
      _openSlidingPanelWithShareTo.stream;

  final _closeSlidingPanel = PublishSubject<bool>();
  Stream<bool> get closeSlidingPanel => _closeSlidingPanel.stream;

  final _scrollLibraryToTop = PublishSubject<bool>();
  Stream<bool> get scrollLibraryToTop => _scrollLibraryToTop.stream;

  final _memCacheReplyObjectsAdd = PublishSubject<List<ReplyObject>>();
  Stream<List<ReplyObject>> get memCacheReplyObjectsAdd =>
      _memCacheReplyObjectsAdd.stream;

  final _memCacheReplyObjectsRemove = PublishSubject<List<ReplyObject>>();
  Stream<List<ReplyObject>> get memCacheReplyObjectsRemove =>
      _memCacheReplyObjectsRemove.stream;

  final _memCacheCircleObjectsAdd = PublishSubject<List<CircleObject>>();
  Stream<List<CircleObject>> get memCacheCircleObjectsAdd =>
      _memCacheCircleObjectsAdd.stream;

  final _memCacheCircleObjectsRemove = PublishSubject<List<CircleObject>>();
  Stream<List<CircleObject>> get memCacheCircleObjectsRemove =>
      _memCacheCircleObjectsRemove.stream;

  final _memCacheCircleObjectsRemoveCircle = PublishSubject<String>();
  Stream<String> get memCacheCircleObjectsRemoveCircle =>
      _memCacheCircleObjectsRemoveCircle.stream;

  final _memCacheCircleObjectsRemoveAllHidden = PublishSubject<bool>();
  Stream<bool> get memCacheCircleObjectsRemoveAllHidden =>
      _memCacheCircleObjectsRemoveAllHidden.stream;

  final _memCacheCircleObjectsRemoveExpired = PublishSubject<MemCacheExpired>();
  Stream<MemCacheExpired> get memCacheCircleObjectsRemoveExpired =>
      _memCacheCircleObjectsRemoveExpired.stream;

  final _memCacheCircleObjectsAddCircle = PublishSubject<String>();
  Stream<String> get memCacheCircleObjectsAddCircle =>
      _memCacheCircleObjectsAddCircle.stream;

  final _popToHomeEnterCircle = PublishSubject<UserCircleCacheAndShare>();
  Stream<UserCircleCacheAndShare> get popToHomeEnterCircle =>
      _popToHomeEnterCircle.stream;

  final _popToHomeOpenTab = PublishSubject<int>();
  Stream<int> get popToHomeOpenTab => _popToHomeOpenTab.stream;

  final _popToHomeOpenScreen = PublishSubject<HomeNavToScreen>();
  Stream<HomeNavToScreen> get popToHomeOpenScreen =>
      _popToHomeOpenScreen.stream;

  final _popToHomeAndOpenShare = PublishSubject<SharedMediaHolder>();
  Stream<SharedMediaHolder> get popToHomeAndOpenShare =>
      _popToHomeAndOpenShare.stream;

  final _refreshCircles = PublishSubject<bool>();
  Stream<bool> get refreshCircles => _refreshCircles.stream;

  final _openFeed = PublishSubject<bool>();
  Stream<bool> get openFeed => _openFeed.stream;

  final _applicationStateChanged = PublishSubject<AppLifecycleState>();
  Stream<AppLifecycleState> get applicationStateChanged =>
      _applicationStateChanged.stream;

  final _refreshCircleForDesktop = PublishSubject<String>();
  Stream<String> get refreshCircleForDesktop => _refreshCircleForDesktop.stream;

  List<CircleObject> timerExpiring = [];

  broadcastTaskComplete(Map<String, dynamic> map) {
    _taskComplete.sink.add(map);
  }



  broadcastRefreshCircle(String circleID) {
    _refreshCircleForDesktop.sink.add(circleID);
  }

  broadCastApplicationStateChanged(AppLifecycleState msg) {
    _applicationStateChanged.sink.add(msg);
  }

  broadcastCloseHiddenCircles() {
    _closeHiddenCircles.sink.add(true);
  }

  broadcastHideCircle(String userCircleID) {
    _hideCircle.sink.add(userCircleID);
  }

  broadcastUnhideCircle(String userCircleID) {
    _unhideCircle.sink.add(userCircleID);
  }

  broadcastRefreshCircles() {
    _refreshCircles.sink.add(true);
  }

  broadcastOpenFeed() {
    _openFeed.sink.add(true);
  }

  broadcastPopToHomeOpenScreen(HomeNavToScreen screen) {
    _popToHomeOpenScreen.sink.add(screen);
  }

  broadcastPopToHomeEnterCircle(
      UserCircleCacheAndShare userCircleCacheAndShare) {
    _popToHomeEnterCircle.sink.add(userCircleCacheAndShare);
  }

  broadcastPopToHomeAndOpenShare(SharedMediaHolder shareHolder) {
    _popToHomeAndOpenShare.sink.add(shareHolder);
  }

  broadcastPopToHomeOpenTab(int tab) {
    _popToHomeOpenTab.sink.add(tab);
  }

  broadcastMemCacheCircleObjectsAdd(List<CircleObject> circleObjects) {
    _memCacheCircleObjectsAdd.sink.add(circleObjects);
  }

  broadcastMemCacheCircleObjectsRemoveAllHidden() {
    _memCacheCircleObjectsRemoveAllHidden.sink.add(true);
  }

  broadcastMemCacheCircleObjectsRemoveExpired(MemCacheExpired expired) {
    _memCacheCircleObjectsRemoveExpired.sink.add(expired);
  }

  broadcastMemCacheCircleObjectsRemoveCircle(String circleID) {
    _memCacheCircleObjectsRemoveCircle.sink.add(circleID);
  }

  broadcastMemCacheCircleObjectsAddCircle(String circleID) {
    _memCacheCircleObjectsAddCircle.sink.add(circleID);
  }

  broadCastMemCacheCircleObjectsRemove(List<CircleObject> circleObjects) {
    _memCacheCircleObjectsRemove.sink.add(circleObjects);
  }

  broadcastOpenSlidingPanel(String message) {
    _openSlidingPanel.sink.add(message);
  }

  broadcastOpenSlidingPanelWithShareTo(SharedMediaHolder sharedMediaHolder) {
    _openSlidingPanelWithShareTo.sink.add(sharedMediaHolder);
  }

  broadcastCloseSlidingPanel(bool rebroadcast) {
    _closeSlidingPanel.sink.add(rebroadcast);
  }

  broadcastScrollLibraryToTop() {
    _scrollLibraryToTop.sink.add(true);
  }

  broadcastClear() {
    _clear.sink.add(true);
  }

  broadcastDelete(CircleObject deletedObject) {
    _deletedObject.sink.add(deletedObject);
  }

  broadcastRefreshWall() {
    refreshWall.sink.add(true);
  }

  broadcastAddToLibrary(List<CircleObject> addedObjects) {
    _addToLibrary.sink.add(addedObjects);
  }

  broadcastRemoveFromLibrary(List<CircleObject> deletedObjects) {
    _removeFromLibrary.sink.add(deletedObjects);
  }

  broadcastCircleObjectsRefreshed() {
    _circleObjectsRefreshed.sink.add(true);
  }

  broadcastProgress(double progress) {
    _progress.sink.add(progress);
  }

  broadcastMemberRefreshNeeded() {
    _memberRefreshNeeded.sink.add(true);
  }

  broadcastUserFurnaceUpdate(UserFurnace userFurnace) {
    _userFurnaceUpdated.sink.add(userFurnace);
  }

  broadcastError(String error) {
    _errorMessage.sink.add(error);
  }

  broadcastMustUpdate() {
    _showMustUpdate.sink.add(true);
  }

  bool deletedSeed(String seed) {
    if (deletedSeeds.contains(seed)) return true;
    return false;
  }

  startTimer(int seconds, CircleObject circleObject) {
    if (circleObject.seed != null) {
      int seconds = circleObject.timer!;

      Duration duration = Duration(seconds: seconds);
      Timer(duration, () => processTimerExpired(circleObject.seed!));
    }
  }

  CircleObject find(List<CircleObject> list, CircleObject circleObject) {
    return list.firstWhere((element) => element.seed == circleObject.seed!);
  }

  setReactions(CircleObject circleObject) {
    if (circleObject.seed != null && circleObject.reactions != null) {
      if (_objectExists(thumbnailObjects, circleObject)) {
        CircleObject exists = find(thumbnailObjects, circleObject);

        exists.reactions = circleObject.reactions;
      }

      if (_objectExists(fullObjects, circleObject)) {
        CircleObject exists = find(fullObjects, circleObject);

        exists.reactions = circleObject.reactions;
      }
    }
  }

  processTimerExpired(String seed) async {
    TableCircleObjectCache.deleteBySeed(seed);
    broadCastMemCacheCircleObjectsRemove(
        [CircleObject(ratchetIndexes: [], seed: seed)]);
    _timerExpired.sink.add(seed);
  }

  refreshCircle(UserFurnace userFurnace, UserCircleCache userCircleCache,
      String circleID) async {
    debugPrint('GlobalEventBloc.refreshCircle');

    UserCircleBloc userCircleBloc = UserCircleBloc(globalEventBloc: this);
    await userCircleBloc.fetchUserCircles([userFurnace], true, false);

    ///This intentionally is updating the cache directly from the CircleObject controller
    CircleObjectBloc circleObjectBloc = CircleObjectBloc(globalEventBloc: this);
    circleObjectBloc.updateCacheFurnace(userFurnace, userCircleCache, circleID,
        true, true, false, true, false, 200);
  }

  // shareText(String text) {
  //   _shareText.sink.add(text);
  // }
  //
  // shareMedia(MediaCollection mediaCollection) {
  //   _sharedMedia.sink.add(mediaCollection);
  // }
  //
  // shareVideo(File video) {
  //   _shareVideo.sink.add(video);
  // }

  broadcastActionNeededRefresh() {
    _actionNeededRefresh.sink.add(true);
  }

  broadcastCircleObjectDeleted(String seed) {
    _circleObjectDeleted.sink.add(seed);
  }

  broadcastNetworkDetailChanged() {
    _networkDetailChanged.sink.add(true);
  }

  broadcastInvitationReceived(Invitation invitation) {
    _invitationReceived.sink.add(invitation);
  }

  broadcastInvitationRefresh() {
    _invitationRefresh.sink.add(true);
  }

  broadcastMagicLink(String magicLink) {
    _magicLinkBroadcast.sink.add(magicLink);
  }

  removeOnError(CircleObject circleObject) {
    removeObject(fullObjects, circleObject);
    removeObject(thumbnailObjects, circleObject);
  }

  removeImageOnError(HostedFurnaceImage img) {
    removeFurnaceImage(furnaceImageObjects, img);
  }

  removeThumbOnError(CircleObject circleObject) {
    removeObject(thumbnailObjects, circleObject);
  }

  removeFullOnError(CircleObject circleObject) {
    removeObject(fullObjects, circleObject);
  }

  removeFurnaceImage(List<HostedFurnaceImage> list, HostedFurnaceImage img) {
    HostedFurnaceImage found = list.firstWhere(
        (element) => element.id == img.id,
        orElse: () => HostedFurnaceImage());

    if (found.id != null && found.id.isNotEmpty) {
      list.remove(found);
    } else {
      debugPrint('GlobalEventBloc.removeFurnaceImage: failed to find image');
    }
  }

  removeObject(List<CircleObject> list, CircleObject circleObject) {
    CircleObject found = list.firstWhere(
        (element) => element.seed == circleObject.seed,
        orElse: () => CircleObject(ratchetIndexes: []));

    if (found.seed != null)
      list.remove(found);
    else
      debugPrint('GlobalEventBloc.removeObject: failed to find object');
  }

  removeObjectsForCircle(String circle) {
    try {
      fullObjects.removeWhere((element) => element.circle!.id == circle);

      thumbnailObjects.removeWhere((element) => element.circle!.id == circle);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('GlobalEventBloc.removeObjectsForCircle: $err');
    }
  }

  bool _furnaceImageExists(
      List<HostedFurnaceImage> list, HostedFurnaceImage img) {
    bool retValue = false;

    HostedFurnaceImage found = list.firstWhere(
        (element) => element.id == img.id,
        orElse: () => HostedFurnaceImage());

    if (found.id != null && found.id.isNotEmpty) retValue = true;

    return retValue;
  }

  bool furnaceImageExists(HostedFurnaceImage img) {
    return _furnaceImageExists(furnaceImageObjects, img);
  }

  removeItem(List<AlbumItem> list, AlbumItem item) {
    AlbumItem found = list.firstWhere((element) => element.id == item.id,
        orElse: () => AlbumItem(type: AlbumItemType.IMAGE, index: 0));

    if (found.id != null)
      list.remove(found);
    else
      debugPrint('GlobalEventBloc.removeItem: failed to find item');
  }

  removeItemThumbOnError(AlbumItem item) {
    removeItem(thumbnailItems, item);
  }

  removeItemFullOnError(AlbumItem item) {
    removeItem(fullItems, item);
  }

  bool _itemExists(List<AlbumItem> list, AlbumItem item) {
    bool retValue = false;

    AlbumItem found = list.firstWhere((element) => element.id == item.id,
        orElse: () => AlbumItem(type: AlbumItemType.IMAGE, index: 0));

    if (found.id != null) retValue = true;

    return retValue;
  }

  bool albumThumbnailExists(AlbumItem albumItem) {
    return _itemExists(thumbnailItems, albumItem);
  }

  bool albumFullExists(AlbumItem albumItem) {
    return _itemExists(fullItems, albumItem);
  }

  bool itemRetryExists(AlbumItem item) {
    return _itemExists(retryItems, item);
  }

  addItemRetry(AlbumItem item) {
    if (!_itemExists(retryItems, item)) {
      retryItems.add(item);
    }
  }

  removeItemFromRetry(AlbumItem item) {
    try {
      retryItems.removeWhere((element) => element.id == item.id);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('GlobalEventBloc.removeItemFromRetry: $err');
    }
  }

  bool _objectExists(List<CircleObject> list, CircleObject circleObject) {
    bool retValue = false;

    CircleObject found = list.firstWhere(
        (element) => element.seed == circleObject.seed,
        orElse: () => CircleObject(ratchetIndexes: []));

    if (found.seed != null) retValue = true;

    return retValue;
  }

  bool albumExists(CircleObject circleObject) {
    return _objectExists(albumObjects, circleObject);
  }

  bool thumbnailExists(CircleObject circleObject) {
    return _objectExists(thumbnailObjects, circleObject);
  }

  bool fullExists(CircleObject circleObject) {
    return _objectExists(fullObjects, circleObject);
  }

  bool retryExists(CircleObject circleObject) {
    return _objectExists(retryObjects, circleObject);
  }

  removeFromRetry(CircleObject circleObject) {
    try {
      retryObjects.removeWhere((element) => element.id == circleObject.id);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('GlobalEventBloc.removeObjectsForCircle: $err');
    }
  }

  addAlbumObject(CircleObject circleObject) {
    if (!_objectExists(albumObjects, circleObject)) {
      albumObjects.add(circleObject);
    }
  }

  broadcastAlbumDownloaded(CircleObject circleObject) {
    removeObject(albumObjects, circleObject);
  }

  broadcastItemPreviewDownloaded(AlbumItem item) {
    removeItem(thumbnailItems, item);
    _itemPreviewDownloaded.add(item);
  }

  broadcastPreviewDownloaded(CircleObject circleObject) {
    removeObject(thumbnailObjects, circleObject);
    _previewDownloaded.sink.add(circleObject);
  }

  addThumbandFull(CircleObject circleObject) {
    if (!_objectExists(fullObjects, circleObject)) {
      fullObjects.add(circleObject);
    }

    if (!_objectExists(thumbnailObjects, circleObject)) {
      thumbnailObjects.add(circleObject);
    }
  }

  addFull(CircleObject circleObject) {
    if (!_objectExists(fullObjects, circleObject)) {
      fullObjects.add(circleObject);
    }
  }

  addRetry(CircleObject circleObject) {
    if (!_objectExists(retryObjects, circleObject)) {
      retryObjects.add(circleObject);
    }
  }

  broadcastAlbumItemIndicator(AlbumItem item) {
    _itemProgressIndicator.sink.add(item);
  }

  broadcastProgressIndicator(CircleObject circleObject) {
    if (!_objectExists(fullObjects, circleObject)) {
      fullObjects.add(circleObject);
    } else {
      CircleObject exists = find(fullObjects, circleObject);
      circleObject.reactions = exists.reactions;
    }
    _progressIndicator.sink.add(circleObject);

    if (circleObject.transferPercent == 100)
      removeObject(fullObjects, circleObject);
  }

  broadcastProgressNetworkImageIndicator(HostedFurnaceImage img) {
    if (img.thumbnailTransferState != BlobState.BLOB_DOWNLOAD_FAILED &&
        !_furnaceImageExists(furnaceImageObjects, img)) {
      furnaceImageObjects.add(img);
    }
    progressFurnaceImageIndicator.sink.add(img);

    if (img.thumbnailTransferState == BlobState.READY) {
      removeFurnaceImage(furnaceImageObjects, img);
    }
  }

  broadcastProgressThumbnailIndicator(
    CircleObject circleObject,
  ) {
    //if (circleObject.thumbnailTransferState == BlobState.READY)
    //removeObject(thumbnailObjects, circleObject);
    if (circleObject.thumbnailTransferState != BlobState.BLOB_DOWNLOAD_FAILED &&
        !_objectExists(thumbnailObjects, circleObject)) {
      thumbnailObjects.add(circleObject);
    }

    _progressThumbnailIndicator.sink.add(circleObject);

    if (circleObject.thumbnailTransferState == BlobState.READY)
      removeObject(thumbnailObjects, circleObject);
  }

  updateProgressThumbnailIndicator(CircleObject circleObject) {
    if (!_objectExists(thumbnailObjects, circleObject)) {
      thumbnailObjects.add(circleObject);
    }
    //_progressThumbnailIndicator.sink.add(circleObject);

    if (circleObject.transferPercent == 100)
      removeObject(thumbnailObjects, circleObject);
  }

  broadcastObjectDownloaded(CircleObject circleObject) {
    _objectDownloaded.sink.add(circleObject);

    removeObject(fullObjects, circleObject);
  }

  broadcastRecipeUpdated(CircleObject circleObject) {
    _recipeUpdated.sink.add(circleObject);
  }

  bool genericObjectExists(String key) {
    bool retValue = false;

    String found = genericObjects.firstWhere((element) => element == key,
        orElse: () => '');

    if (found.isNotEmpty) retValue = true;

    return retValue;
  }

  addGenericObject(String key) {
    if (!genericObjectExists(key)) {
      genericObjects.add(key);
    }
  }

  broadcastCircleObject(CircleObject circleObject) {
    _broadcastCircleObject.sink.add(circleObject);
  }

  broadcastReplyObject(List<ReplyObject> replyObjects) {
    _broadcastReplyObject.sink.add(replyObjects[0]);
  }

  broadcastMemCacheReplyObjectsAdd(List<ReplyObject> replyObjects) {
    _memCacheReplyObjectsAdd.sink.add(replyObjects);
  }

  broadcastMemCacheReplyObjectsRemove(List<ReplyObject> replyObjects) {
    _memCacheReplyObjectsRemove.sink.add(replyObjects);
  }

  broadcastAndRemoveCircleObject(CircleObject circleObject, String key) {
    _broadcastCircleObject.sink.add(circleObject);
    removeGenericObject(key);
  }

  broadcastTOSReviewNeeded() {
    _showTOS.sink.add(true);
  }

  broadcastPinNeeded() {
    _showPinNeeded.sink.add(true);
  }

  broadcastRefreshHome() {
    _refreshHome.sink.add(true);
  }

  broadcastWipePhone() {
    _wipePhone.sink.add(true);
  }

  broadcastRefreshMessageFeed() {
    _refreshMessageFeed.sink.add(true);
  }

  broadcastBackupKeyNeeded() {
    _showBackupKeyNeeded.sink.add(true);
  }

  removeGenericObject(String key) {
    String found = genericObjects.firstWhere((element) => element == key,
        orElse: () => '');

    if (found.isNotEmpty) genericObjects.remove(found);
  }

  UserCircleCache? _clickedUserCircleCache;
  BuildContext? buildContext;

  pinCaptured(List<int> pin) async {
    try {
      //String pinString = UserCircleCache.pinToString(pin);
      //debugPrint(pinString);

      //debugPrint(UserCircleCache.stringToPin(pinString));

      if (_clickedUserCircleCache != null) {
        if (_clickedUserCircleCache!.checkPin(pin)) {
          goInside(_clickedUserCircleCache!, guardPinAccepted: true);
        } else {
          DialogPatternCapture.capture(
              NavigationService.navigationKey.currentContext!,
              pinCaptured,
              'Swipe pattern to enter',
              dismissible: false,
              cancel: cancel);
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('Home._pinCaptured: $err');
    }
  }

  cancel() {
    NavigationService navigationService = NavigationService();
    navigationService.pushReplacementNamed(
      '/home',
    );
  }

  gotoInvitations() {
    broadcastPopToHomeOpenScreen(HomeNavToScreen.invitations);

    return;
  }

  gotoActionRequired() {
    // NavigationService navigationService = NavigationService();
    //
    // navigationService.pushAndRemoveUntil(
    //   MaterialPageRoute(
    //       builder: (context) => const Home(
    //             tab: BottomNavigationOptions.ACTIONS,
    //           )),
    //   keepPreviousPages: false,
    // );
    // return;

    broadcastPopToHomeOpenTab(2);
  }

  // gotoHome() {
  //   NavigationService navigationService = NavigationService();
  //
  //   navigationService.pushAndRemoveUntil(
  //     MaterialPageRoute(builder: (context) => const Home()),
  //     keepPreviousPages: false,
  //   );
  //   return;
  // }

  gotoBacklog() {
    // NavigationService navigationService = NavigationService();
    //
    // navigationService.pushAndRemoveUntil(
    //   MaterialPageRoute(
    //       builder: (context) => const Home(
    //             openScreen: HomeNavToScreen.backlog,
    //             //tab: BottomNavigationOptions.ACTIONS,
    //           )),
    //   keepPreviousPages: false,
    // );

    broadcastPopToHomeOpenScreen(HomeNavToScreen.backlog);

    return;
  }

  gotoIronCoinWallet() {
    broadcastPopToHomeOpenScreen(HomeNavToScreen.giftedIronCoin);

    return;
  }

  Future<void> goInside(UserCircleCache userCircleCache,
      {bool guardPinAccepted = false}) async {
    // if (userCircleCache.guarded! && !guardPinAccepted) {
    //   _clickedUserCircleCache = userCircleCache;
    //
    //   await DialogPatternCapture.capture(
    //       NavigationService.navigationKey.currentContext!,
    //       pinCaptured,
    //       'Swipe pattern to enter',
    //       cancel: cancel,
    //       dismissible: false);
    //
    //   return;
    // }

    if (userCircleCache.hidden == true && userCircleCache.hiddenOpen == false) {
      // navigationService.pushReplacementNamed(
      //   '/home',
      // );
      broadcastPopToHomeOpenTab(0);
      return;
    }

    broadcastPopToHomeEnterCircle(
        UserCircleCacheAndShare(userCircleCache: userCircleCache));
    return;
  }

  _initGlobalState(UserCircleCache userCircleCache) {
    if (userCircleCache.cachedCircle!.type == CircleType.WALL) {
      globalState.selectedCircleTabIndex = 0;
      globalState.selectedHomeIndex = BottomNavigationOptions.CIRCLES;
      //LogBloc.insertLog("globalState.selectedCirclesIndex ${globalState.selectedCircleIndex}", "_initGlobalState");
    } else {
      globalState.enterCircle =
          UserCircleCacheAndShare(userCircleCache: userCircleCache);
      //LogBloc.insertLog("did not set index", "_initGlobalState");
    }
  }

  Future<int?> processInteractedMessage(
      RemoteMessage remoteMessage, bool fromAutoLogin,
      {bool guardPinAccepted = false}) async {
    //LogBloc.insertLog('initialMessage is not null', 'processInteractedMessage');
    //LogBloc.insertLog('fromAutoLogin: $fromAutoLogin', 'processInteractedMessage');

    UserCircleBloc userCircleBloc = UserCircleBloc(globalEventBloc: this);
    CircleObjectBloc _circleObjectBloc =
        CircleObjectBloc(globalEventBloc: this);

    var data = remoteMessage.data;

    ///don't process messages twice
    if (data["id"] != null) {
      if (interactedMessages.contains(data["id"])) {
        return null; //already processing
      } else {
        interactedMessages.add(data["id"]);
      }
    }

    debugPrint(data["strippedObject"]);

    String? body;

    int notificationType = data["notificationType"] == null
        ? -1
        : int.parse(data["notificationType"]);
    debugPrint('Notification Type: $notificationType');

    if (remoteMessage.notification != null) {
      body = remoteMessage.notification!.body;
    } else {
      //LogBloc.insertLog('remoteMessage.notification == null',
      //    'globalEventBloc.processInteractedMessage');
    }

    if (body == 'New activity in IronCircles' ||
        body == 'New ironclad message' ||
        body == 'Member reacted to your ironclad message' ||
        body == 'Member updated ironclad message' ||
        body == 'Message removed by IronCircles' ||
        notificationType == NotificationType.MESSAGE ||
        notificationType == NotificationType.EVENT) {
      if (data.containsKey("object")) {
        var decode = json.decode(data["object"]!);
        debugPrint('INTERACTED message handler id: ${data["id"]}');

        //LogBloc.insertLog('INTERACTED message handler id: ${data["id"]}',
        //    'globalEventBloc.processInteractedMessage');

        try {
          CircleObject circleObject = CircleObject.fromJson(decode!);

          //update the circle cache
          UserCircleCache userCircleCache = await userCircleBloc
              .refreshFromPushNotification(circleObject, false, false);

          if (!fromAutoLogin) {
            //LogBloc.insertLog('Go inside',
            //   'globalEventBloc.processInteractedMessage');
            goInside(userCircleCache);
          } else {
            //LogBloc.insertLog('Go to _initGlobalState',
            //   'globalEventBloc.processInteractedMessage');
            _initGlobalState(userCircleCache);
          }
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint(err.toString());
        }
      } else if (data.containsKey("objectID")) {
        ///tapped reaction notification
        notificationType = NotificationType.REACTION;
        String id = data["objectID"];

        try {
          CircleObject circleObject =
              await _circleObjectBloc.fetchObjectById(id);

          UserCircleCache userCircleCache = await userCircleBloc
              .getUserCircleCacheFromCircle(circleObject.circle!.id!);

          // globalState.enterCircle =
          //     UserCircleCacheAndShare(userCircleCache: userCircleCache);

          if (!fromAutoLogin) {
            goInside(userCircleCache);
          } else {
            _initGlobalState(userCircleCache);
          }
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint(err.toString());
        }
      } else {
        //late List<UserCircle> userCircles;
        String circleID = data["object2"]; //["data"]["object"];

        try {
          UserCircleCache userCircleCache =
              await userCircleBloc.getUserCircleCacheFromCircle(circleID);

          if (!fromAutoLogin) {
            goInside(userCircleCache);
          } else {
            _initGlobalState(userCircleCache);
          }
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint(err.toString());
        }
      }
    } else if (body == 'New invitation in IronCircles' ||
        notificationType == NotificationType.INVITATION) {
      if (!fromAutoLogin) {
        gotoInvitations();
      }
    } else if (body == 'Action needed in IronCircles' ||
        notificationType == NotificationType.ACTION_NEEDED) {
      if (!fromAutoLogin) {
        gotoActionRequired();
      }
    } else if (notificationType == NotificationType.BACKLOG_ITEM ||
        notificationType == NotificationType.BACKLOG_REPLY) {
      if (!fromAutoLogin) {
        gotoBacklog();
      }
    } else if (notificationType == NotificationType.GIFTED_IRONCOIN) {
      if (!fromAutoLogin) {
        //globalState.globalEventBloc.broadcastPopToHomeOpenTab(0);
        broadcastPopToHomeOpenScreen(HomeNavToScreen.backlog);
      }
    } else if (data["object2"] != null) {
      try {
        UserCircleCache userCircleCache =
            await userCircleBloc.getUserCircleCacheFromCircle(data["object2"]);

        if (!fromAutoLogin) {
          goInside(userCircleCache);
        } else {
          notificationType = NotificationType.MESSAGE;
          _initGlobalState(userCircleCache);
        }
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
        debugPrint(err.toString());
      }
    }

    return notificationType;
  }

  dispose() async {
    await _progressIndicator.drain();
    _progressIndicator.close();

    await _progressThumbnailIndicator.drain();
    _progressThumbnailIndicator.close();

    await _objectDownloaded.drain();
    _objectDownloaded.close();

    await _previewDownloaded.drain();
    _previewDownloaded.close();

    await _broadcastCircleObject.drain();
    _broadcastCircleObject.close();

    await _actionNeededRefresh.drain();
    _actionNeededRefresh.close();

    await _invitationRefresh.drain();
    _invitationRefresh.close();

    await _closeHiddenCircles.drain();
    await _closeHiddenCircles.close();

    await _notConnected.drain();
    await _notConnected.close();

    await _recipeUpdated.drain();
    await _recipeUpdated.close();

    await _timerExpired.drain();
    await _timerExpired.close();

    await _showTOS.drain();
    await _showTOS.close();

    await _showPinNeeded.drain();
    await _showPinNeeded.close();

    await _showBackupKeyNeeded.drain();
    await _showBackupKeyNeeded.close();

    await _refreshHome.drain();
    await _refreshHome.close();

    await _circleObjectsRefreshed.drain();
    await _circleObjectsRefreshed.close();

    await _refreshMessageFeed.drain();
    await _refreshMessageFeed.close();

    await _circleObjectDeleted.drain();
    await _circleObjectDeleted.close();

    await _wipePhone.drain();
    await _wipePhone.close();

    await _userFurnaceUpdated.drain();
    await _userFurnaceUpdated.close();

    await _magicLinkBroadcast.drain();
    await _magicLinkBroadcast.close();

    await _showMustUpdate.drain();
    await _showMustUpdate.close();
    await _progress.drain();
    await _progress.close();

    await _networkDetailChanged.drain();
    await _networkDetailChanged.close();

    await _broadcastReplyObject.drain();
    await _broadcastReplyObject.close();
  }

  static Locale returnLocale(BuildContext context) {
    Locale locale_ = Locale('en_us');
    ;
    String language_ = AppLocalizations.of(context)!.language.toString();

    //locale_ = (AppLocalizations.of(context)!.language).toString() == Language.TURKISH.toString()? Locale('tr'): Locale('en_us');

    if (language_ == Language.TURKISH.toString()) locale_ = const Locale('tr');

    return locale_;
  }
}

class MemCacheExpired {
  String circleID;
  int privacyDisappearingTimer;

  MemCacheExpired(
      {required this.circleID, required this.privacyDisappearingTimer});
}

class UserCircleCacheAndShare {
  UserCircleCache userCircleCache;
  SharedMediaHolder? sharedMediaHolder;

  UserCircleCacheAndShare(
      {required this.userCircleCache, this.sharedMediaHolder});
}
