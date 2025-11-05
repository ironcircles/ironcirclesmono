import 'package:flutter/cupertino.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/album_item.dart';

class CircleAlbum {
  List<AlbumItem> media = [];
  DateTime? lastUpdate;
  DateTime? created;
  int bytesTotal;
  int bytesTransferred;

  CircleAlbum({
    required this.media,
    this.lastUpdate,
    this.created,
    this.bytesTotal = 0,
    this.bytesTransferred = 0,
});

  factory CircleAlbum.fromJson(Map<String, dynamic> json) => CircleAlbum(
    ///does it need null check??
    media: AlbumItemCollection.fromJSON(json, "media").albumItems,
    lastUpdate: json["lastUpdate"] == null
      ? null
        : DateTime.parse(json["lastUpdate"]).toLocal(),
    created: json["created"] == null
      ? null
        : DateTime.parse(json["created"]).toLocal(),
  );

  Map<String, dynamic> toJson() => {
    "lastUpdate": lastUpdate?.toUtc().toString(),
    "created": created?.toUtc().toString(),
    "media": media == null
      ? null
      : List<dynamic>.from(media.map((x) => x)),
  };

  mapDecryptedFields(Map<String, dynamic> json) {
    try {
      var album = json["album"];

      lastUpdate = DateTime.parse(album["lastUpdate"]).toLocal();
      created = DateTime.parse(album["created"]).toLocal();

    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleAlbum.mapDecryptedFields: $error');
      rethrow;
    }
  }

  Map<String, dynamic> fetchFieldsToEncrypt() {
    try {
      Map<String, dynamic> retValue = Map<String, dynamic>();

      retValue["lastUpdate"] = lastUpdate?.toUtc().toString();
      retValue["created"] = created?.toUtc().toString();

      return retValue;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleAlbum.fetchFieldsToEncrypt: $error");
      rethrow;
    }
  }

}