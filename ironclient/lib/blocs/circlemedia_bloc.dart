import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:ironcirclesapp/blocs/circlefile_bloc.dart';
import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/circlevideo_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class CircleMediaBloc {
  final CircleImageBloc circleImageBloc;
  final CircleVideoBloc circleVideoBloc;
  final CircleFileBloc circleFileBloc;

  CircleMediaBloc(
      {required this.circleImageBloc,
      required this.circleVideoBloc,
      required this.circleFileBloc});

  String getType(Media media) {
    String type = '';

    if (media.mediaType == MediaType.image) {
      type = CircleObjectType.CIRCLEIMAGE;
    } else if (media.mediaType == MediaType.video) {
      type = CircleObjectType.CIRCLEVIDEO;
    } else if (media.mediaType == MediaType.file) {
      type = CircleObjectType.CIRCLEFILE;
    } else if (media.mediaType == MediaType.gif) {
      type = CircleObjectType.CIRCLEGIF;
    }

    return type;
  }

  /// create the circle objects
  processAndUploadMedia(
      UserCircleCache userCircleCache,
      UserFurnace userFurnace,
      CircleObject circleObject,
      List<Media> mediaCollection,
      CircleObjectBloc callbackBloc,
      bool hiRes,
      Function sendAndClear) async {
    try {
      bool first = true;

      for (Media media in mediaCollection) {
        late CircleObject individual;

        if (first) {
          individual = circleObject;
          if (individual.body != null)
            individual.body = individual.body!.trim();
          first = false;
        } else {
          String type = getType(media);

          individual = CircleObject.prepNewCircleObject(
              userCircleCache, userFurnace, '', 0, null,
              type: type);
          individual.timer = circleObject.timer;
        }

        individual.storageID = media.storageID;

        if (media.mediaType == MediaType.image) {
          await circleImageBloc.cacheObjectUpdateScreen(userCircleCache,
              userFurnace, individual, callbackBloc, File(media.path), hiRes);
        } else if (media.mediaType == MediaType.video) {
          await circleVideoBloc.cacheObjectUpdateScreen(
              userCircleCache,
              userFurnace,
              individual,
              callbackBloc,
              File(media.path),
              media.thumbnail,
              media.streamable,
              media.thumbIndex,
              false);
        } else if (media.mediaType == MediaType.file) {
          await circleFileBloc.cacheObjectUpdateScreen(userCircleCache,
              userFurnace, individual, callbackBloc, File(media.path),
              name: media.name);
        } else if (media.mediaType == MediaType.gif) {
          individual.gif = CircleGif();
          individual.gif!.giphy = media.path;
          individual.gif!.width = media.width;
          individual.gif!.height = media.height;

          sendAndClear(individual);
        }
      }

      ///kickoff the queues
      circleImageBloc.processQueue(userCircleCache, userFurnace, callbackBloc);
      circleVideoBloc.processQueue(userCircleCache, userFurnace, callbackBloc);
      circleFileBloc.processQueue(userCircleCache, userFurnace, callbackBloc);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectBloc.saveCircleImagesFromAssets: $error");
    }

    return;
  }
}
