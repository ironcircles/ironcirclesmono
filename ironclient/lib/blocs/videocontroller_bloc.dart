import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/circlevideo_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/encryption/encryptblob.dart';
import 'package:ironcirclesapp/models/album_item.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/videocache_service.dart';
import 'package:video_player/video_player.dart';

class VideoControllerBloc {
  List<_VideoController> videoControllers = [];

  Future<int> addPreview(File preview) async {
    _VideoController videoController = _VideoController();

    await videoController.initPreview(preview);

    videoControllers.add(videoController);

    return videoControllers.length - 1;
  }

  add(CircleObject circleObject) async {
    if (circleObject.video!.videoFile != null ||
        circleObject.video!.streamable!) {
      _VideoController videoController = _VideoController();

      await videoController.init(circleObject);

      videoControllers.add(videoController);
      debugPrint(
          'add: ${videoControllers.length}   *****************************************************');

      // callback(circleObject);

      return;
    }
  }

  addItem(AlbumItem item) async {
    if (item.video!.videoFile != null || item.video!.streamable!) {
      _VideoController videoController = _VideoController();

      await videoController.initItem(item);

      videoControllers.add(videoController);
      debugPrint(
          'add: ${videoControllers.length}   *****************************************************');

      return;
    }
  }

  disposeLast() {
    debugPrint(
        'disposeLast: ${videoControllers.length}   *****************************************************');

    if (videoControllers.isNotEmpty) {
      videoControllers[videoControllers.length - 1].dispose();
    }
  }

  predispose(CircleObject? circleObject) {
    debugPrint(
        'predispose: ${videoControllers.length}   *****************************************************');

    if (circleObject != null) {
      if (videoControllers.isNotEmpty) {
        if (videoControllers[videoControllers.length - 1].seed ==
            circleObject.seed) {
          videoControllers[videoControllers.length - 1].oldSeed =
              circleObject.seed!;
          videoControllers[videoControllers.length - 1].seed = "disposed";
          videoControllers[videoControllers.length - 1].pause();
        }
      }
    }
  }

  predisposeItem(AlbumItem? item) {
    debugPrint(
        'predispose: ${videoControllers.length}   *****************************************************');

    if (item != null) {
      if (videoControllers.isNotEmpty) {
        if (videoControllers[videoControllers.length - 1].seed == item.id) {
          videoControllers[videoControllers.length - 1].oldSeed = item.id!;
          videoControllers[videoControllers.length - 1].seed = "disposed";
          videoControllers[videoControllers.length - 1].pause();
        }
      }
    }
  }

  disposeObject(CircleObject? circleObject) {
    if (circleObject != null) {
      if (videoControllers.isNotEmpty) {
        if (videoControllers[videoControllers.length - 1].seed ==
                circleObject.seed ||
            videoControllers[videoControllers.length - 1].oldSeed ==
                circleObject.seed!) {
          debugPrint(
              'disposeObject: ${videoControllers.length}   *****************************************************');

          videoControllers[videoControllers.length - 1].dispose();
        }
      }
    }
  }

  disposeItem(AlbumItem? item) {
    if (item != null) {
      if (videoControllers.isNotEmpty) {
        if (videoControllers[videoControllers.length - 1].seed == item.id ||
            videoControllers[videoControllers.length - 1].oldSeed == item.id!) {
          debugPrint(
              'disposeObject: ${videoControllers.length}   *****************************************************');

          videoControllers[videoControllers.length - 1].dispose();
        }
      }
    }
  }

  pauseLast() {
    if (videoControllers.isNotEmpty) {
      videoControllers[videoControllers.length - 1].pause();
    }
  }

  ChewieController? fetchAlbumController(AlbumItem item) {
    if (videoControllers.isNotEmpty) {
      if (videoControllers[videoControllers.length - 1].seed == item.id!) {
        if (!videoControllers[videoControllers.length - 1].disposed) {
          return videoControllers[videoControllers.length - 1].chewieController;
        }
      }
    }

    return null;
  }

  //is there a controller initialized for this video?
  ChewieController? fetchController(CircleObject circleObject) {
    if (videoControllers.isNotEmpty) {
      if (videoControllers[videoControllers.length - 1].seed ==
          circleObject.seed!) {
        if (!videoControllers[videoControllers.length - 1].disposed)
          return videoControllers[videoControllers.length - 1].chewieController;
      }
    }

    return null;
  }

  void populateVideoFile(
      CircleObject circleObject,
      UserCircleCache? userCircleCache,
      UserFurnace? userFurnace,
      CircleVideoBloc? circleVideoBloc) {
    if (circleObject.video == null) return;

    if (circleObject.video!.videoState == VideoStateIC.UPLOADING_VIDEO ||
        circleObject.video!.videoState == VideoStateIC.DOWNLOADING_PREVIEW ||
        circleObject.video!.videoState ==
            VideoStateIC
                .DOWNLOADING_VIDEO) //|| circleObject.video.videoState == VideoStateIC.VIDEO_READY
      return null;

    //is the video cached?
    if (VideoCacheService.isVideoCached(
        circleObject, userCircleCache!.circlePath)) {
      if (circleObject.video!.videoState == null)
        circleObject.video!.videoState = VideoStateIC.INITIALIZING_CHEWIE;

      //does it already have a chewie controller?
      if (fetchController(circleObject) == null)
        circleObject.video!.videoState = VideoStateIC.NEEDS_CHEWIE;
      else
        circleObject.video!.videoState = VideoStateIC.VIDEO_READY;

      circleObject.video!.videoFile = File(VideoCacheService.returnVideoPath(
          circleObject,
          userCircleCache.circlePath!,
          circleObject.video!.extension!));
    } else if (VideoCacheService.isPreviewCached(
        circleObject, userCircleCache.circlePath!)) {
      String path = VideoCacheService.returnPreviewPath(
          circleObject, userCircleCache.circlePath!);

      if (circleObject.video!.previewFile == null) {
        circleObject.video!.videoState = VideoStateIC.PREVIEW_DOWNLOADED;
        circleObject.video!.previewFile = File(path);
      } else if (circleObject.video!.previewFile!.path != path)
        circleObject.video!.previewFile = File(path);
    } else {
      // if (circleObject.video.videoState != VideoStateIC.DOWNLOADING_PREVIEW) {
      circleObject.video!.videoState = VideoStateIC.DOWNLOADING_PREVIEW;

      circleVideoBloc!
          .notifyWhenPreviewReady(userFurnace, userCircleCache, circleObject);
      // }
    }

    return null;
  }
  /*
  void populateVideoFile(
      CircleObject circleObject,
      UserCircleCache? userCircleCache,
      UserFurnace? userFurnace,
      CircleVideoBloc? circleVideoBloc) {
    if (circleObject.video!.videoState == VideoStateIC.UPLOADING_VIDEO ||
        circleObject.video!.videoState == VideoStateIC.DOWNLOADING_PREVIEW ||
        circleObject.video!.videoState ==
            VideoState
                .DOWNLOADING_VIDEO) //|| circleObject.video.videoState == VideoStateIC.VIDEO_READY
      return null;

    //is the video cached?
    if (VideoCacheService.isVideoCached(
        circleObject, userCircleCache!.circlePath)) {
      /*
      if (circleObject.video!.videoState == null)


        circleObject.video!.videoState = VideoStateIC.INITIALIZING_CHEWIE;

      int index = -1;
      //does it already have a chewie controller?
      if (videoControllers.isNotEmpty) {
        if (videoControllers[videoControllers.length - 1].seed ==
            circleObject.seed!) index = videoControllers.length - 1;
      }

      if (index == -1)
        circleObject.video!.videoState = VideoStateIC.NEEDS_CHEWIE;
      else
        circleObject.video!.videoState = VideoStateIC.VIDEO_READY;

      if (index != null) {
        /*circleObject.video.videoFile = File(VideoCacheService.returnVideoPath(
            widget.userCircleCache.circlePath,
            circleObject.seed,
            circleObject.video.extension));
        _videoControllerBloc.add(circleObject, _chewieInitialized); //async*/
      } else {}

         */
    } else if (VideoCacheService.isPreviewCached(
        circleObject, userCircleCache.circlePath!)) {
      String path = VideoCacheService.returnPreviewPath( circleObject,
          userCircleCache.circlePath!);

      if (circleObject.video!.previewFile == null) {
        circleObject.video!.videoState = VideoStateIC.PREVIEW_DOWNLOADED;
        circleObject.video!.previewFile = File(path);
      } else if (circleObject.video!.previewFile!.path != path)
        circleObject.video!.previewFile = File(path);
    } else {
      // if (circleObject.video.videoState != VideoStateIC.DOWNLOADING_PREVIEW) {
      circleObject.video!.videoState = VideoStateIC.DOWNLOADING_PREVIEW;

      circleVideoBloc!
          .notifyWhenPreviewReady(userFurnace, userCircleCache, circleObject);
      // }
    }

    return null;
  }

   */
}

class _VideoController {
  ChewieController? chewieController;
  late VideoPlayerController videoPlayerController;
  String? seed;
  String oldSeed = '';
  bool disposed = false;
  String destinationPath = "";

  init(CircleObject circleObject) async {
    //File file = VideoCacheService.returnVideoPath(, fileName);

    if (circleObject.video!.streamable! &&
        !circleObject.video!.streamableCached) {
      videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(circleObject.video!.streamingUrl));
    } else if (globalState.isDesktop() &&
        (circleObject.video!.streamable == false ||
            (circleObject.video!.streamable! &&
                circleObject.video!.streamableCached == false))) {
      if (destinationPath.isEmpty) {
        destinationPath = await FileSystemService.returnTempPathAndFile(
            extension: circleObject.video!.extension!);

        await EncryptBlob.decryptBlob(
            DecryptArguments(
                encrypted: circleObject.video!.videoFile!,
                nonce: circleObject.video!.fullCrank!,
                mac: circleObject.video!.fullSignature!,
                key: circleObject.secretKey,
                destinationPath: destinationPath),
            deleteEncryptedSource: false);
      }

      videoPlayerController = VideoPlayerController.file(File(destinationPath));
    } else {
      videoPlayerController =
          VideoPlayerController.file(circleObject.video!.videoFile!);
    }

    //await videoPlayerController.initialize();
    await Future.wait([videoPlayerController.initialize()]);

    ///trouble shooting for bizcimen

    chewieController = ChewieController(
      allowedScreenSleep: false,
      allowFullScreen: true,
      //fullScreenByDefault: true,
      videoPlayerController: videoPlayerController,
      autoPlay: true,
      looping: true,
      showControlsOnInitialize: false,
      allowPlaybackSpeedChanging: true,
    );

    // Buffering state listener removed - spinner no longer shown

    seed = circleObject.seed;

    circleObject.video!.videoState = VideoStateIC.VIDEO_READY;
  }

  initItem(AlbumItem item) async {
    if (item.video!.streamable! && !item.video!.streamableCached) {
      videoPlayerController =
          VideoPlayerController.networkUrl(Uri.parse(item.video!.streamingUrl));
    } else {
      videoPlayerController =
          VideoPlayerController.file(item.video!.videoFile!);
    }

    await Future.wait([videoPlayerController.initialize()]);

    chewieController = ChewieController(
      allowedScreenSleep: false,
      allowFullScreen: true,
      //fullScreenByDefault: true,
      videoPlayerController: videoPlayerController,
      autoPlay: true,
      looping: true,
      showControlsOnInitialize: false,
      allowPlaybackSpeedChanging: true,
    );

    // Buffering state listener removed - spinner no longer shown

    seed = item.id;

    item.video!.videoState = VideoStateIC.VIDEO_READY;
  }

  initPreview(File preview) async {
    videoPlayerController = VideoPlayerController.file(preview);

    debugPrint('VideoPlayerController.file(preview)');

    await videoPlayerController.initialize();

    debugPrint('videoPlayerController.initialize();');

    chewieController = ChewieController(
      allowFullScreen: true,
      allowedScreenSleep: false,
      videoPlayerController: videoPlayerController,
      autoPlay: true,
      looping: true,
      showControlsOnInitialize: false,
      allowPlaybackSpeedChanging: false,
    );

    // Add listener to handle buffering state changes
    videoPlayerController.addListener(() {
      if (videoPlayerController.value.isBuffering) {
        // For preview videos, we don't need to update video state
        // as they don't have a circleObject associated
      } else if (videoPlayerController.value.isInitialized && 
                 !videoPlayerController.value.isBuffering) {
        // Video is ready
      }
    });
  }

  pause() {
    try {
      if (!disposed) {
        try {
          videoPlayerController.pause();
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint('VideoControllerBloc.pause: $err');
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('VideoControllerBloc.VideoController.pause: $err');
    }
  }

  dispose() {
    if (!disposed) {
      disposed = true;
      seed = 'disposed';

      if (destinationPath.isNotEmpty) {
        FileSystemService.safeDelete(File(destinationPath));
        destinationPath = "";
      }

      try {
        chewieController!.dispose();
        debugPrint(
            'chewie disposed   ****************************************************');
        //chewieController = null;
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
        debugPrint('VideoControllerBloc.VideoController.dispose: $err');
      }

      try {
        videoPlayerController.dispose();
        debugPrint(
            'vc disposed   ****************************************************');
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
        debugPrint('VideoControllerBloc.VideoController.dispose: $err');
      }
    }
  }
}
