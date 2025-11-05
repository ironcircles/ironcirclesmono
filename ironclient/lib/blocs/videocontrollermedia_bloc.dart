import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:video_player/video_player.dart';

class VideoControllerMediaBloc {
  List<_VideoController> videoControllers = [];

  Future<int> addPreview(File preview) async {
    _VideoController videoController = _VideoController();

    await videoController.initPreview(preview);

    videoControllers.add(videoController);

    return videoControllers.length - 1;
  }

  add(Media video, bool autoPlay) async {
    if (fetchController(video) == null) {
      _VideoController videoController = _VideoController();

      await videoController.init(video, autoPlay);

      videoControllers.add(videoController);
      debugPrint(
          'add: ${videoControllers.length}   *****************************************************');

      // callback(circleObject);

    }

    return;
  }

  disposeLast() {
    debugPrint(
        'disposeLast: ${videoControllers.length}   *****************************************************');

    if (videoControllers.isNotEmpty) {
      videoControllers[videoControllers.length - 1].dispose();
    }
  }

  predispose(Media? media) {
    debugPrint(
        'predispose: ${videoControllers.length}   *****************************************************');

    if (media != null) {
      if (videoControllers.isNotEmpty) {
        if (videoControllers[videoControllers.length - 1].seed == media.seed) {
          videoControllers[videoControllers.length - 1].oldSeed = media.seed;
          videoControllers[videoControllers.length - 1].seed = "disposed";
          videoControllers[videoControllers.length - 1].pause();
        }
      }
    }
  }

  disposeObject(Media? media) {
    if (media != null) {
      if (videoControllers.isNotEmpty) {
        if (videoControllers[videoControllers.length - 1].seed == media.seed ||
            videoControllers[videoControllers.length - 1].oldSeed ==
                media.seed) {
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
  ChewieController? fetchController(Media media) {
    if (videoControllers.isNotEmpty) {
      if (videoControllers[videoControllers.length - 1].seed == media.seed) {
        if (!videoControllers[videoControllers.length - 1].disposed)
          return videoControllers[videoControllers.length - 1].chewieController;
      }
    }

    return null;
  }
}

class _VideoController {
  ChewieController? chewieController;
  late VideoPlayerController videoPlayerController;
  String? seed;
  String oldSeed = '';
  bool disposed = false;

  init(Media video, bool autoPlay) async {
    videoPlayerController = VideoPlayerController.file(video.file);

    await videoPlayerController.initialize();

    chewieController = ChewieController(
      allowFullScreen: true,
      allowedScreenSleep: false,
      //fullScreenByDefault: true,
      videoPlayerController: videoPlayerController,
      autoPlay: autoPlay,
      looping: true,
      showControlsOnInitialize: false,
      allowPlaybackSpeedChanging: false,
      progressIndicatorDelay: const Duration(days: 2),
    );

    // Buffering state listener removed - spinner no longer shown

    seed = video.seed;

    video.videoState = VideoStateIC.VIDEO_READY;
  }

  initPreview(File preview) async {
    videoPlayerController = VideoPlayerController.file(preview);

    debugPrint('VideoPlayerController.file(preview)');

    await videoPlayerController.initialize();

    debugPrint('videoPlayerController.initialize();');

    chewieController = ChewieController(
      allowFullScreen: true,
      videoPlayerController: videoPlayerController,
      autoPlay: true,
      looping: true,
      showControlsOnInitialize: false,
      allowPlaybackSpeedChanging: false,
      progressIndicatorDelay: const Duration(days: 2),
    );

    // Add listener to handle buffering state changes
    videoPlayerController.addListener(() {
      if (videoPlayerController.value.isBuffering) {
        // For preview videos, we don't need to update video state
        // as they don't have a video object associated
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
