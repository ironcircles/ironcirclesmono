import 'package:ironcirclesapp/models/circlegif.dart';
import 'package:ironcirclesapp/models/circleimage.dart';
import 'package:ironcirclesapp/models/circleobjectlineitem.dart';
import 'package:ironcirclesapp/models/circlevideo.dart';

class AlbumItem {
  String? id;
  CircleImage? image;
  CircleVideo? video;
  CircleGif? gif;
  String type;
  int retries;
  int? thumbnailTransferState;
  int? fullTransferState;
  bool removeFromCache;
  int index;

  CircleObjectLineItem? encryptedLineItem;

  AlbumItem({
    this.id,
    this.image,
    this.video,
    this.gif,
    this.retries = 0,
    this.thumbnailTransferState,
    this.fullTransferState,
    this.removeFromCache = false,
    required this.index,
    required this.type,
    this.encryptedLineItem});

  factory AlbumItem.fromJson(Map<String, dynamic> jsonMap) => AlbumItem(
    id: jsonMap["_id"],
    image: jsonMap["image"] == null
        ? null
        : CircleImage.fromJson(jsonMap["image"]),
    video: jsonMap["video"] == null
      ? null
      : CircleVideo.fromJson(jsonMap["video"]),
    gif: jsonMap["gif"] == null
      ? null
      : CircleGif.fromJson(jsonMap["gif"]),
    retries: jsonMap["retries"] ?? 0,
    thumbnailTransferState: jsonMap["thumbnailTransferState"],
    fullTransferState: jsonMap["fullTransferState"],
    type: jsonMap["type"],
    removeFromCache: jsonMap["removeFromCache"] ?? false,
    index: jsonMap["index"],
    encryptedLineItem: jsonMap["encryptedLineItem"] == null
      ? null
        : CircleObjectLineItem.fromJson(jsonMap["encryptedLineItem"]),
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "image": image?.toJson(),
    "video": video?.toJson(),
    "gif": gif?.toJson(),
    "retries": retries,
    "thumbnailTransferState": thumbnailTransferState,
    "fullTransferState": fullTransferState,
    "type": type,
    "removeFromCache": removeFromCache,
    "index": index,
    "encryptedLineItem": encryptedLineItem,
  };

  void revertEncryptionFields(AlbumItem original) {
    image = original.image;
    video = original.video;
    gif = original.gif;
    retries = original.retries;
    thumbnailTransferState = original.thumbnailTransferState;
    fullTransferState = original.fullTransferState;
  }
}

class AlbumItemCollection {
  final List<AlbumItem> albumItems;

  AlbumItemCollection.fromJSON(Map<String, dynamic> json, String key)
    : albumItems = (json[key] as List)
      .map((json) => AlbumItem.fromJson(json))
      .toList();
}