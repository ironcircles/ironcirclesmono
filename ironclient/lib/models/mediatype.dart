import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ironcirclesapp/models/album_item.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/filecache_service.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
import 'package:ironcirclesapp/services/cache/videocache_service.dart';
import 'package:ironcirclesapp/services/tenor_service.dart';
import 'package:mime/mime.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
//import 'package:share_handler/share_handler.dart';
import 'package:uuid/uuid.dart';

enum MediaType { image, video, file, gif, recipe, list, credential, event }

Media mediaFromJson(String str) => Media.fromJson(json.decode(str));

String mediaToJson(Media data) => json.encode(data.toJson());

class Media {
  String path = '';
  String storageID;
  String thumbnail = '';
  late File file;
  MediaType mediaType;
  int? videoState;
  bool streamable = false;
  int thumbIndex;
  late String seed;
  bool requireStreaming = false;
  bool tooLarge = false;
  CircleObject? object;
  Object? attachment;
  bool fromCamera;
  int height;
  int width;
  String name;

  Media({
    this.path = '',
    required this.mediaType,
    this.thumbnail = '',
    this.thumbIndex = 0,
    this.storageID = '',
    this.object,
    this.attachment,
    this.requireStreaming = false,
    this.height = 0,
    this.width = 0,
    this.name = '',
    this.fromCamera = false,
  }) {
    file = File(path);
    seed = const Uuid().v4();
  }

  setFromFile(File file, MediaType mediaType) {
    path = file.path;

    this.file = file;

    this.mediaType = mediaType;
  }

  Map<String, dynamic> toJson() => {
        "mediaType": mediaType.index,
        "path": path,
        "storageID": storageID,
        "thumbnail": thumbnail,
        "thumbIndex": thumbIndex,
        "requireStreaming": requireStreaming,
      };

  factory Media.fromJson(Map<String, dynamic> jsonMap) => Media(
        mediaType: MediaType.values.elementAt(jsonMap["mediaType"]),
        path: jsonMap["path"],
        thumbnail: jsonMap["thumbnail"] ?? '',
        storageID: jsonMap["storageID"] ?? '',
        thumbIndex: jsonMap["thumbIndex"],
        requireStreaming: jsonMap["requireStreaming"],
      );
}

class MediaCollection {
  MediaCollection();

  bool album = false;

  List<Media> media = [];

  MediaCollection.fromJSON(Map<String, dynamic> json, String key)
      : media =
            (json[key] as List).map((json) => Media.fromJson(json)).toList();

  /*List<File> getFiles(MediaType mediaType) {
    List<File> files = [];

    for (Media sharedMedia in media) {
      if (sharedMedia.mediaType == mediaType) files.add(File(sharedMedia.path));
    }

    return files;
  }*/

  List<Media> getCollection(MediaType mediaType) {
    return media.where((element) => element.mediaType == mediaType).toList();
  }

  add(Media media) {
    this.media.add(media);
  }

  remove(Media media) {
    this.media.remove(media);
  }

  bool get isNotEmpty {
    return media.isNotEmpty;
  }

  bool get isEmpty {
    return media.isEmpty;
  }

  populateFromSharedMediaFile(List<SharedMediaFile> sharedMediaFiles) {
    for (SharedMediaFile sharedMediaFile in sharedMediaFiles) {
      if (sharedMediaFile.type == SharedMediaType.IMAGE)
        media
            .add(Media(path: sharedMediaFile.path, mediaType: MediaType.image));
      else if (sharedMediaFile.type == SharedMediaType.VIDEO)
        media.add(Media(
            path: sharedMediaFile.path,
            mediaType: MediaType.video,
            thumbnail: sharedMediaFile.thumbnail!));
      else if (sharedMediaFile.type == SharedMediaType.FILE)
        media.add(Media(
          path: sharedMediaFile.path,
          mediaType: MediaType.file,
        ));
    }
  }

  /*
  static MediaCollection populateFromSharedMediaFile(
    SharedMedia sharedMedia,
  )  {
    MediaCollection media = MediaCollection();

    if (sharedMedia.attachments != null) {
      for (SharedAttachment? sharedAttachment in sharedMedia.attachments!) {
        if (sharedAttachment != null) {


          if (sharedAttachment.type == SharedAttachmentType.image)
            media.add(
                Media(path: sharedAttachment.path, mediaType: MediaType.image));
          else if (sharedAttachment.type == SharedAttachmentType.video)
            media.add(Media(
              path: sharedAttachment.path,
              mediaType: MediaType.video,
              //thumbnail: (await VideoCacheService.cacheTempVideoPreview(
                     // sharedAttachment.path, 0))
                  //.path,
            ));
        }
      }
    }

    return media;
  }

   */

  populateFromXFile(List<XFile> xFiles, MediaType mediaType) {
    for (XFile xFile in xFiles) {
      media.add(Media(path: xFile.path, mediaType: mediaType));
    }
  }

  populateFromFiles(List<File> files, MediaType mediaType) async {
    for (File file in files) {
      String? mime = lookupMimeType(file.path);

      if (mime != null) {
        if (mime.contains('image'))
          media.add(Media(path: file.path, mediaType: MediaType.image));
        else if (mime.contains('video')) {
          Media video = Media(path: file.path, mediaType: MediaType.video);

          video.thumbnail =
              (await VideoCacheService.cacheTempVideoPreview(video.path, 0))
                  .path;

          media.add(video);
        } else {
          media.add(Media(path: file.path, mediaType: MediaType.file));
        }
      } else {
        throw ('Unsupported file type');
      }
    }

    if (media.isEmpty) throw ('Unsupported file type');
  }

  populateFromFilePicker(List<PlatformFile> files, MediaType mediaType) async {
    for (PlatformFile file in files) {
      String? mime = lookupMimeType(file.path!);

      if (mime != null) {
        if (mime.contains('image'))
          media.add(Media(path: file.path!, mediaType: MediaType.image));
        else if (mime.contains('video')) {
          Media video = Media(path: file.path!, mediaType: MediaType.video);

          video.thumbnail =
              (await VideoCacheService.cacheTempVideoPreview(video.path, 0))
                  .path;

          media.add(video);
        } else {
          media.add(Media(path: file.path!, mediaType: MediaType.file));
        }
        //else if (mime.contains('audio'))
        // media.add(Media(path: file.path!, mediaType: MediaType.video));
        //else if (mime.contains('text'))
        //media.add(Media(path: file.path!, mediaType: MediaType.file));
      } else {
        throw ('Unsupported file type');
      }
    }

    if (media.isEmpty) throw ('Unsupported file type');
  }

  populateFromGiphyOption(GiphyOption giphyOption) async {
    media.add(Media(
        path: giphyOption.url,
        mediaType: MediaType.gif,
        height: giphyOption.height!,
        width: giphyOption.width!,
        thumbnail: giphyOption.preview));
  }

  populateFromCircleObjects(List<CircleObject> circleObjects) async {
    ///need to update this to cache to a file for desktop before sharing

    for (CircleObject circleObject in circleObjects) {
      String circlePath = '';

      if (circleObject.userCircleCache!.circlePath != null)
        circlePath = circleObject.userCircleCache!.circlePath!;
      else
        circlePath = await FileSystemService.returnCirclesDirectory(
            circleObject.creator!.id!, circleObject.circle!.id!);

      if (circleObject.type == CircleObjectType.CIRCLEIMAGE) {
        media.add(Media(
            path:
                ImageCacheService.returnFullImagePath(circlePath, circleObject),
            mediaType: MediaType.image));
      } else if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
        media.add(Media(
            path: VideoCacheService.returnVideoPath(
                circleObject, circlePath, 'mp4'),
            mediaType: MediaType.video,
            thumbnail:
                VideoCacheService.returnPreviewPath(circleObject, circlePath)));
      } else if (circleObject.type == CircleObjectType.CIRCLEGIF) {
        media.add(Media(
            path: circleObject.gif!.giphy!,
            height: circleObject.gif!.height!,
            width: circleObject.gif!.width!,
            mediaType: MediaType.gif,
            thumbnail: circleObject.gif!.giphy!));
      } else if (circleObject.type == CircleObjectType.CIRCLEFILE) {
        media.add(Media(
          name: circleObject.file!.name!,
          path: FileCacheService.returnFilePath(
              circlePath, circleObject.file!.file!),
          mediaType: MediaType.file,
        ));
      } else if (circleObject.type == CircleObjectType.CIRCLEALBUM) {
        for (AlbumItem item in circleObject.album!.media) {
          if (item.type == AlbumItemType.IMAGE) {
            media.add(Media(
                path: ImageCacheService.returnExistingAlbumImagePath(
                    circlePath, circleObject, item.image!.fullImage!),
                mediaType: MediaType.image));
          } else if (item.type == AlbumItemType.GIF) {
            media.add(Media(
                path: item.gif!.giphy!,
                height: item.gif!.height!,
                width: item.gif!.width!,
                mediaType: MediaType.gif,
                thumbnail: item.gif!.giphy!));
          } else if (item.type == AlbumItemType.VIDEO) {
            media.add(Media(
              path: VideoCacheService.returnExistingAlbumVideoPath(
                  circlePath, circleObject, item.video!.video!),
              mediaType: MediaType.video,
              thumbnail: VideoCacheService.returnExistingAlbumVideoPath(
                  circlePath, circleObject, item.video!.preview!),
            ));
          }
        }
      }
    }
  }
}

class SharedMediaHolder {
  MediaCollection? sharedMedia;
  File? sharedVideo;
  String? sharedText;
  GiphyOption? sharedGif;
  String message;

  SharedMediaHolder(
      {this.sharedMedia,
      this.sharedVideo,
      this.sharedText,
      this.sharedGif,
      required this.message});

  clear() {
    sharedMedia = null;
    sharedVideo = null;
    sharedText = null;
    sharedGif = null;
    if (globalState.isDesktop()) {
      globalState.selectedCircleTabIndex = 0;
    } else {
      globalState.selectedCircleTabIndex = 1;
    }
  }

  bool isCleared() {
    return (sharedMedia == null &&
        sharedVideo == null &&
        sharedText == null &&
        sharedGif == null);
  }
}
