import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
import 'package:ironcirclesapp/services/cache/table_circleobject.dart';
import 'package:ironcirclesapp/services/circleobject_service.dart';
import 'package:ironcirclesapp/services/circlerecipe_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

class CircleRecipeBloc {
  CircleRecipeBloc(GlobalEventBloc globalEventBloc) {
    _globalEventBloc = globalEventBloc;
    _circleRecipeService = CircleRecipeService(globalEventBloc);
  }

  late GlobalEventBloc _globalEventBloc;
  late CircleRecipeService _circleRecipeService;
  final CircleObjectService _circleObjectService = CircleObjectService();
  //final ImageCacheService _imageCacheService = ImageCacheService();

  final _created = PublishSubject<CircleObject>();
  Stream<CircleObject> get created => _created.stream;

  final _updated = PublishSubject<CircleObject>();
  Stream<CircleObject> get updated => _updated.stream;

  final _taskChangeSubmitted = PublishSubject<CircleObject>();
  Stream<CircleObject> get taskChangeSubmitted => _taskChangeSubmitted.stream;

  notifyWhenThumbReady(UserFurnace userFurnace, UserCircleCache userCircleCache,
      CircleObject circleObject) async {
    try {
      //ignore while transfer in progress
      if (circleObject.thumbnailTransferState == BlobState.ENCRYPTING ||
          circleObject.thumbnailTransferState == BlobState.DECRYPTING ||
          circleObject.thumbnailTransferState == BlobState.UPLOADING ||
          circleObject.thumbnailTransferState == BlobState.DOWNLOADING) return;

      //make sure it's not already being downloaded
      if (_globalEventBloc.thumbnailExists(circleObject)) return;

      if (circleObject.seed == null) {
        debugPrint('this should not happen');
        return;
      }

      if (circleObject.recipe!.image!.thumbnailSize == null) {
        return;
      }
      if (ImageCacheService.isRecipeImageCached(
          circleObject.recipe!.image!.thumbnailSize!,
          userCircleCache.circlePath!,
          circleObject.seed!)) {
        if (circleObject.recipe!.image!.thumbnailFile == null) {
          circleObject.recipe!.image!.thumbnailFile = File(
              ImageCacheService.returnThumbnailPath(
                  userCircleCache.circlePath!, circleObject));
        }
      } else {
        if (circleObject.crank.isNotEmpty &&
            circleObject.ratchetIndexes.isEmpty) {
          //throw ('ratchetIndexes not saved');
          debugPrint('ratchetIndexes not saved');
          return;
        }
        circleObject.thumbnailTransferState = BlobState.DOWNLOADING;

        //check one last time
        if (_globalEventBloc.thumbnailExists(circleObject)) return;

        _globalEventBloc.thumbnailObjects.add(circleObject);

        if (circleObject.ratchetIndexes.isNotEmpty) {
          circleObject.secretKey ??= await ForwardSecrecy.getSecretKey(
              userCircleCache.usercircle!, circleObject);

          if (circleObject.secretKey!.isEmpty) throw ('could not find key');
        }

        _getImage(
          userFurnace,
          userCircleCache,
          circleObject,
        );
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleImageBloc.notifyWhenThumbReady: $err');
      rethrow;
    }
  }

  failedCallback(
    UserFurnace userFurnace,
    UserCircleCache userCircleCache,
    CircleObject circleObject,
  ) {}

  Future<void> _getImage(UserFurnace userFurnace,
      UserCircleCache userCircleCache, CircleObject circleObject) async {
    try {
      //make sure the image isn't being uploaded
      if (circleObject.recipe == null) return;
      if (circleObject.recipe!.image == null) return;

      _circleRecipeService.getImage(
          userFurnace, userCircleCache, circleObject, failedCallback);

      return;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
      rethrow;
    }
  }

  create(
      UserCircleCache userCircleCache,
      CircleObject circleObject,
      UserFurnace userFurnace,
      bool saveTemplate,
      bool deleteOriginalImage) async {
    try {
      circleObject.recipe!.saveTemplate = saveTemplate;

      ///generate seeds
      for (CircleRecipeIngredient item in circleObject.recipe!.ingredients!) {
        item.seed = const Uuid().v4();
      }
      for (CircleRecipeInstruction item in circleObject.recipe!.instructions!) {
        item.seed = const Uuid().v4();
      }

      debugPrint(
          'UserFurnace: ${userFurnace.userid!}, UserCircle user: ${userCircleCache.user!}');
      circleObject = await _circleObjectService.cacheCircleObject(circleObject);
      debugPrint(
          'UserFurnace: ${userFurnace.userid!}, UserCircle user: ${userCircleCache.user!}, seed: ${circleObject.seed}');

      if (circleObject.recipe!.image != null) {
        //cache
        String thumbnailPath = ImageCacheService.returnThumbnailPath(
            userCircleCache.circlePath!, circleObject);

        await ImageCacheService().createThumbnail(circleObject, thumbnailPath,
            circleObject.recipe!.image!.thumbnailFile!, true);

        //remove the cached image from the image picker
        if (deleteOriginalImage) {
          await FileSystemService.safeDelete(
              circleObject.recipe!.image!.thumbnailFile!);
        }

        circleObject.recipe!.image!.thumbnailFile = File(thumbnailPath);

        circleObject.thumbnailTransferState = BlobState.ENCRYPTING;
        // _globalEventBloc.broadcastProgressThumbnailIndicator(circleObject);
      }

      _created.sink.add(circleObject);

      if (circleObject.timer != null) {
        _globalEventBloc.startTimer(circleObject.timer!, circleObject);
      }

      circleObject = await _circleRecipeService.create(
          userCircleCache,
          circleObject,
          userFurnace,
          processFailedPost,
          CircleObjectBloc(globalEventBloc: _globalEventBloc));

      if (circleObject.id != null) {
        _created.sink.add(circleObject);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleRecipeBloc.create: $err');
      _created.sink.addError(err);
    }
  }

  processFailedPost() {}

  update(UserCircleCache userCircleCache, CircleObject circleObject,
      UserFurnace userFurnace) async {
    try {
      for (CircleRecipeIngredient item in circleObject.recipe!.ingredients!) {
        item.seed ??= const Uuid().v4();
      }
      for (CircleRecipeInstruction item in circleObject.recipe!.instructions!) {
        item.seed ??= const Uuid().v4();
      }

      circleObject = await _circleObjectService.cacheCircleObject(circleObject);

      // if (circleObject != null) {
      //   _updated.sink.add(circleObject);
      //   }

      if (circleObject.recipe!.imageChanged == true) {
        //cache
        String thumbnailPath = ImageCacheService.returnThumbnailPath(
            userCircleCache.circlePath!, circleObject);

        File oldImage = File(thumbnailPath);

        if (oldImage.existsSync()) await oldImage.delete();

        await ImageCacheService().createThumbnail(circleObject, thumbnailPath,
            circleObject.recipe!.image!.thumbnailFile!, true);

        //circleObject.recipe!.image!.thumbnailFile!.copy(thumbnailPath);

        circleObject.recipe!.image!.thumbnailFile = File(thumbnailPath);

        circleObject.thumbnailTransferState = BlobState.ENCRYPTING;
        // _globalEventBloc.broadcastProgressThumbnailIndicator(circleObject);
      }

      //_updated.sink.add(circleObject);

      await _circleRecipeService.update(
          userCircleCache,
          circleObject,
          userFurnace,
          processFailedPost,
          CircleObjectBloc(globalEventBloc: _globalEventBloc));

      //_updated.sink.add(circleObject);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleRecipeBloc.update: $err');
      _updated.sink.addError(err);
    }
  }

  /*
  updateRecipe(UserCircleCache userCircleCache, CircleObject circleObject, CircleRecipe circleRecipe,
      bool saveRecipe, UserFurnace userFurnace) async {
    try {

      //update the order field
      debugPrint('Bloc a: ${circleRecipe.lastUpdate}');
      //update the object from the deepcopy
      circleObject.recipe.ingestDeepCopy(circleRecipe);

      circleObject = await _recipeService.updateRecipe(
          userCircleCache, circleObject, saveRecipe, userFurnace);

      await TableCircleObjectCache.updateCacheSingleObject(circleObject);
      debugPrint('Bloc b: ${circleObject.lastUpdate}');
      _updated.sink.add(circleObject);
    } catch (err, trace) { LogBloc.insertError(err, trace);
      debugPrint('CircleRecipeBloc.updateRecipe: $err');
      _created.sink.addError(err);
    }
  }

   */

  displayRecipe(List<CircleObject> circleObjects) {}

  removeFromDeviceCache(List<CircleObject> circleObjects) async {
    await FileSystemService.returnCirclesDirectory(
        globalState.user.id!, DeviceOnlyCircle.circleID);

    await TableCircleObjectCache.deleteList(_globalEventBloc, circleObjects);

    /* for (var circleObject in circleObjects) {
      ImageCacheService.deleteCircleObjectImage(circlePath, circleObject.seed!);
    }

    */
  }

  dispose() async {
    await _created.drain();
    _created.close();

    await _taskChangeSubmitted.drain();
    _taskChangeSubmitted.close();

    await _updated.drain();
    _updated.close();
  }
}
