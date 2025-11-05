import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/circlevideo_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/constants.dart';
import 'package:ironcirclesapp/encryption/encryptblob.dart';
import 'package:ironcirclesapp/models/circleobject.dart';
import 'package:ironcirclesapp/models/globalstate.dart';
import 'package:ironcirclesapp/models/usercirclecache.dart';
import 'package:ironcirclesapp/models/userfurnace.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/videocache_service.dart';
import 'package:media_kit/media_kit.dart' as mediakit;
import 'package:media_kit_video/media_kit_video.dart';

class VideoControllerDesktopBloc {
  List<_VideoController> videoControllers = [];

  // Future<int> addPreview(File preview) async {
  //   _VideoController videoController = _VideoController();
  //
  //   await videoController.initPreview(preview);
  //
  //   videoControllers.add(videoController);
  //
  //   return videoControllers.length - 1;
  // }

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

  pauseLast() {
    if (videoControllers.isNotEmpty) {
      videoControllers[videoControllers.length - 1].pause();
    }
  }

  //is there a controller initialized for this video?
  VideoController? fetchController(CircleObject circleObject) {
    if (videoControllers.isNotEmpty) {
      if (videoControllers[videoControllers.length - 1].seed ==
          circleObject.seed!) {
        if (!videoControllers[videoControllers.length - 1].disposed)
          return videoControllers[videoControllers.length - 1].videoController;
      }
    }

    return null;
  }

  mediakit.Player? fetchPlayer(CircleObject circleObject) {
    if (videoControllers.isNotEmpty) {
      if (videoControllers[videoControllers.length - 1].seed ==
          circleObject.seed!) {
        if (!videoControllers[videoControllers.length - 1].disposed)
          return videoControllers[videoControllers.length - 1].videoPlayer;
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

  Future<String> fetchVideoPath(CircleObject circleObject) async {
    if (videoControllers.isNotEmpty) {
      if (videoControllers[videoControllers.length - 1].seed ==
          circleObject.seed!) {
        if (!videoControllers[videoControllers.length - 1].disposed)
          return await videoControllers[videoControllers.length - 1]
              .fetchVideo(circleObject);
      }
    }

    return '';
  }
}

class _VideoController {
  late VideoController? videoController;
  late mediakit.Player videoPlayer;

  String? seed;
  String oldSeed = '';
  bool disposed = false;
  String destinationPath = "";

  Future<String> fetchVideo(CircleObject circleObject) async {
    if (circleObject.video!.streamable! &&
        circleObject.video!.streamableCached == false) {
      return circleObject.video!.streamingUrl;
    }
     else if (globalState.isDesktop() &&
         circleObject.video!.streamableCached == true) {
       return circleObject.video!.videoFile!.path;
     }
    else if (globalState.isDesktop() &&
        (circleObject.video!.streamable == false ||
            (circleObject.video!.streamable! &&
                circleObject.video!.streamableCached == true))) {
      if (circleObject.video!.videoBytes == null) {
        // destinationPath = await FileSystemService.returnTempPathAndFile(
        //     extension: circleObject.video!.extension!);

        circleObject.video!.videoBytes = await EncryptBlob.decryptBlobToMemory(
            DecryptArguments(
                encrypted: circleObject.video!.videoFile!,
                nonce: circleObject.video!.fullCrank!,
                mac: circleObject.video!.fullSignature!,
                key: circleObject.secretKey,
                destinationPath: destinationPath));

        globalState.globalEventBloc
            .broadcastMemCacheCircleObjectsAdd([circleObject]);
      }
    }
    return '';
  }

  init(CircleObject circleObject) async {
    videoPlayer = mediakit.Player();

    videoController = VideoController(videoPlayer);
    seed = circleObject.seed;
    circleObject.video!.videoState = VideoStateIC.VIDEO_READY;
  }

  // initPreview(File preview) async {
  //   videoPlayerController = VideoPlayerController.file(preview);
  //
  //   debugPrint('VideoPlayerController.file(preview)');
  //
  //   await videoPlayerController.initialize();
  //
  //   debugPrint('videoPlayerController.initialize();');
  //
  //   chewieController = ChewieController(
  //     allowFullScreen: true,
  //     allowedScreenSleep: false,
  //     videoPlayerController: videoPlayerController,
  //     autoPlay: true,
  //     looping: false,
  //     showControlsOnInitialize: false,
  //     allowPlaybackSpeedChanging: false,
  //   );
  // }

  pause() {
    try {
      if (!disposed) {
        try {
          videoPlayer.pause();
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
        videoPlayer.dispose();
        debugPrint(
            'chewie disposed   ****************************************************');
        //chewieController = null;
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
        debugPrint('VideoControllerBloc.VideoController.dispose: $err');
      }

      try {
        videoPlayer.dispose();
        debugPrint(
            'vc disposed   ****************************************************');
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
        debugPrint('VideoControllerBloc.VideoController.dispose: $err');
      }
    }
  }
}
