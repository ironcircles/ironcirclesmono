import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/constants.dart';
import 'package:ironcirclesapp/models/mediatype.dart' as mediaType;
import 'package:media_kit/media_kit.dart' as mediakit;
import 'package:media_kit_video/media_kit_video.dart';

class VideoControllerMediaDesktopBloc {
  List<_VideoController> videoControllers = [];

  Future<int> addPreview(File preview) async {
    _VideoController videoController = _VideoController();

    await videoController.initPreview(preview);

    videoControllers.add(videoController);

    return videoControllers.length - 1;
  }

  add(mediaType.Media video, bool autoPlay, Function callback) async {
    if (fetchController(video.seed) == null) {
      _VideoController videoController = _VideoController();
      videoControllers.add(videoController);

      await videoController.init(video, autoPlay, callback);

      debugPrint(
          'add: ${videoControllers.length}   *****************************************************');
    } else {
      callback(video);
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

  disposeAll() {
    for (var i = 0; i < videoControllers.length; i++) {
      //predispose
      videoControllers[i].dispose();
    }
  }

  predispose(mediaType.Media? media) {
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

  disposeObject(mediaType.Media? media) {
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

  pause(String seed) {
    if (videoControllers.isNotEmpty) {
      int index =
          videoControllers.indexWhere((element) => element.seed == seed);

      if (index != -1) {
        videoControllers[index].pause();
      }
    }
  }

  //is there a controller initialized for this video?
  VideoController? fetchController(String seed) {
    if (videoControllers.isNotEmpty) {
      int index =
          videoControllers.indexWhere((element) => element.seed == seed);

      if (index != -1) {
        if (!videoControllers[index].disposed)
          return videoControllers[index].videoController;
      }
      // if (videoControllers[videoControllers.length - 1].seed == seed) {
      //   if (!videoControllers[videoControllers.length - 1].disposed)
      //     return videoControllers[videoControllers.length - 1].videoController;
      // }
    }

    return null;
  }

  mediakit.Player? fetchPlayer(String seed) {
    if (videoControllers.isNotEmpty) {
      if (videoControllers[videoControllers.length - 1].seed == seed) {
        if (!videoControllers[videoControllers.length - 1].disposed)
          return videoControllers[videoControllers.length - 1].videoPlayer;
      }
    }

    return null;
  }
}

class _VideoController {
  late VideoController? videoController;
  late mediakit.Player videoPlayer;
  String? seed;
  String oldSeed = '';
  bool disposed = false;

  init(mediaType.Media video, bool autoPlay, Function callback) async {
    // final media = await Media.memory(videoBytes);
    // player.open(media);

    // videoPlayer = mediakit.Player(
    //   configuration: mediakit.PlayerConfiguration(
    //     // Supply your options:
    //    // title: 'My awesome package:media_kit application',
    //     ready: () async {
    //       videoController = VideoController(videoPlayer);
    //       await Future.delayed(const Duration(milliseconds: 250));
    //
    //       seed = video.seed;
    //       video.videoState = constants.VideoStateIC.VIDEO_READY;
    //
    //       await videoPlayer.open(mediakit.Media(video.path));
    //
    //       await Future.delayed(const Duration(milliseconds: 250));
    //
    //       callback(video);
    //     },
    //   ),
    // );

    videoPlayer = mediakit.Player();
    seed = video.seed;
    video.videoState = VideoStateIC.VIDEO_READY;

    // await Future.delayed(const Duration(milliseconds: 500));

    videoController = VideoController(videoPlayer);

    callback(video);

    // chewieController = ChewieController(
    //   allowFullScreen: true,
    //   allowedScreenSleep: false,
    //   //fullScreenByDefault: true,
    //   videoPlayerController: videoPlayerController,
    //   autoPlay: autoPlay,
    //   looping: false,
    //   showControlsOnInitialize: false,
    //   allowPlaybackSpeedChanging: false,
    // );
  }

  initPreview(File preview) async {
    await videoPlayer.open(mediakit.Media(preview.path));
  }

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
