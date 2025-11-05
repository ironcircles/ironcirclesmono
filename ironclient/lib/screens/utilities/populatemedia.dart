import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/circlealbum_bloc.dart';
import 'package:ironcirclesapp/blocs/circlefile_bloc.dart';
import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/circlerecipe_bloc.dart';
import 'package:ironcirclesapp/blocs/circlevideo_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/videocontroller_bloc.dart';
import 'package:ironcirclesapp/blocs/videocontroller_desktop_bloc.dart';
import 'package:ironcirclesapp/models/album_item.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/filecache_service.dart';
import 'package:ironcirclesapp/services/cache/table_circleobject.dart';
import 'package:ironcirclesapp/services/cache/videocache_service.dart';

class PopulateMedia {
  static void populateRecipeImageFile(
      CircleObject circleObject,
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      GlobalEventBloc globalEventBloc,
      CircleRecipeBloc circleRecipeBloc) {
    try {
      if (globalEventBloc.thumbnailExists(circleObject)) {
        return;
      }

      if (circleObject.recipe != null) {
        if (circleObject.recipe!.image != null) {
          circleRecipeBloc.notifyWhenThumbReady(
              userFurnace, userCircleCache, circleObject);
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('PopulateMedia.populateRecipeImageFile: $err');
    }
  }

  static void populateImageFile(
      CircleObject circleObject,
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      CircleImageBloc circleImageBloc,
      CircleObjectBloc circleObjectBloc) {
    try {
      circleImageBloc.notifyWhenThumbReady(
          userFurnace, userCircleCache, circleObject, circleObjectBloc);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('PopulateMedia.populateImageFile: $err');
    }
  }

  static void populateAlbum(
      CircleObject circleObject,
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      CircleAlbumBloc circleAlbumBloc,
      CircleObjectBloc circleObjectBloc) {
    try {
      circleAlbumBloc.notifyWhenAlbumReady(
        userFurnace, userCircleCache, circleObject, circleObjectBloc
      );
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('PopulateMedia.populateAlbum: $error');
    }
  }

  static void populateFile(
    CircleObject circleObject,
    UserFurnace? userFurnace,
    UserCircleCache userCircleCache,
    CircleFileBloc circleFileBloc,
  ) {
    if (circleObject.fullTransferState == BlobState.UPLOADING ||
        circleObject.fullTransferState == BlobState.DOWNLOADING) {
      //|| circleObject.video.videoState == VideoStateIC.VIDEO_READY
      return;
    }

    ///is the video cached?
    if (FileCacheService.isFileCached(
        circleObject, userCircleCache.circlePath!)) {
      circleObject.fullTransferState = BlobState.READY;
    } else {
      circleObject.fullTransferState = BlobState.NOT_DOWNLOADED;
    }

    return;
  }

  static void populateAlbumVideoFile(
      CircleObject circleObject,
      AlbumItem item,
      UserFurnace? userFurnace,
      UserCircleCache userCircleCache,
      CircleVideoBloc circleVideoBloc,
      VideoControllerBloc videoControllerBloc,
      {broadcastAutoPlay = false}) {
    if (item.video!.videoState == VideoStateIC.UPLOADING_VIDEO ||
      item.video!.videoState == VideoStateIC.DOWNLOADING_PREVIEW ||
      item.video!.videoState == VideoStateIC.DOWNLOADING_VIDEO) {
      return;
    }

    //is the video cached?
    if (VideoCacheService.isAlbumVideoCached(circleObject, userCircleCache.circlePath!, item)) {
      ///bandaid for lost state
      if (item.video!.videoState == null ||
        item.video!.videoState == 0) {
        item.video!.videoState = VideoStateIC.INITIALIZING_CHEWIE;
      }

      ///does it already have a chewie controller?
      if (videoControllerBloc.fetchAlbumController(item) == null) {
        item.video!.videoState = VideoStateIC.NEEDS_CHEWIE;
      } else {
        item.video!.videoState = VideoStateIC.VIDEO_READY;
      }

      item.video!.videoFile = File(VideoCacheService.returnExistingAlbumVideoPath(userCircleCache.circlePath!, circleObject, item.video!.video!));

      TableCircleObjectCache.updateCacheSingleObject('', circleObject);

      if (broadcastAutoPlay) circleVideoBloc.broadcastItemAutoplay(item);

    } else if (VideoCacheService.isAlbumPreviewCached(circleObject, userCircleCache.circlePath!, item)) {
      String path = VideoCacheService.returnExistingAlbumVideoPath(userCircleCache.circlePath!, circleObject, item.video!.preview!);

      if (item.video!.previewFile == null) {
        item.video!.videoState = VideoStateIC.PREVIEW_DOWNLOADED;
        TableCircleObjectCache.updateCacheSingleObject('', circleObject);
        item.video!.previewFile = File(path);
      } else if (item.video!.previewFile!.path != path) {
        item.video!.previewFile = File(path);
      }
    } else {
      item.video!.videoState = VideoStateIC.DOWNLOADING_PREVIEW;

      if (userFurnace != null) {
        circleVideoBloc.notifyWhenItemPreviewReady(userFurnace, userCircleCache, circleObject, item);
      }
      return;
    }
  }

  static void populateVideoFile(
      CircleObject circleObject,
      UserFurnace? userFurnace,
      UserCircleCache userCircleCache,
      CircleVideoBloc circleVideoBloc,
      VideoControllerBloc videoControllerBloc,
      VideoControllerDesktopBloc videoControllerDesktopBloc,
      {broadcastAutoPlay = false}) {
    if (circleObject.video!.videoState == VideoStateIC.UPLOADING_VIDEO ||
        circleObject.video!.videoState == VideoStateIC.DOWNLOADING_PREVIEW ||
        circleObject.video!.videoState ==
            VideoStateIC
                .DOWNLOADING_VIDEO) //|| circleObject.video.videoState == VideoStateIC.VIDEO_READY
      return;

    //is the video cached?
    if (VideoCacheService.isVideoCached(
        circleObject, userCircleCache.circlePath!)) {
      //if (circleObject.video!.videoState == VideoStateIC.VIDEO_READY) return;
      ///bandaid for lost state
      if (circleObject.video!.videoState == null ||
          circleObject.video!.videoState == 0)
        circleObject.video!.videoState = VideoStateIC.INITIALIZING_CHEWIE;

      ///does it already have a controller?
      if (globalState.isDesktop()) {
        if (videoControllerDesktopBloc.fetchController(circleObject) == null)
          circleObject.video!.videoState = VideoStateIC.NEEDS_CHEWIE;
        else
          circleObject.video!.videoState = VideoStateIC.VIDEO_READY;
      } else {
        if (videoControllerBloc.fetchController(circleObject) == null)
          circleObject.video!.videoState = VideoStateIC.NEEDS_CHEWIE;
        else
          circleObject.video!.videoState = VideoStateIC.VIDEO_READY;
      }

      circleObject.video!.videoFile = File(VideoCacheService.returnVideoPath(
          circleObject,
          userCircleCache.circlePath!,
          circleObject.video!.extension!));

      TableCircleObjectCache.updateCacheSingleObject('', circleObject);

      if (broadcastAutoPlay) circleVideoBloc.broadcastAutoplay(circleObject);

      //_videoControllerBloc.add(circleObject, _chewieInitialized); //a
    } else if (VideoCacheService.isPreviewCached(
        circleObject, userCircleCache.circlePath!)) {
      String path = VideoCacheService.returnPreviewPath(
          circleObject, userCircleCache.circlePath!);

      if (circleObject.video!.previewFile == null) {
        circleObject.video!.videoState = VideoStateIC.PREVIEW_DOWNLOADED;
        TableCircleObjectCache.updateCacheSingleObject('', circleObject);
        circleObject.video!.previewFile = File(path);
      } else if (circleObject.video!.previewFile!.path != path)
        circleObject.video!.previewFile = File(path);
    } else {
      // if (circleObject.video.videoState != VideoStateIC.DOWNLOADING_PREVIEW) {
      circleObject.video!.videoState = VideoStateIC.DOWNLOADING_PREVIEW;

      if (userFurnace != null)
        circleVideoBloc.notifyWhenPreviewReady(
            userFurnace, userCircleCache, circleObject);
      // }
    }

    return;
  }
}
