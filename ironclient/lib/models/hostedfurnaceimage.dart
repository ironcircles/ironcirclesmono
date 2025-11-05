import 'dart:convert';

HostedFurnaceImage hostedFurnaceImageFromJson(String str) => HostedFurnaceImage.fromJson(json.decode(str));

String hostedFurnaceImageToJson(HostedFurnaceImage data) => json.encode(data.toJson());

class HostedFurnaceImage {
  String id;
  String location;
  String name;
  int size;
  int? thumbnailTransferState;
  int retries;

  HostedFurnaceImage({
    this.id = '',
    this.location = '',
    this.name = '',
    this.size = -1,
    this.thumbnailTransferState,
    this.retries = 0,
  });

  factory HostedFurnaceImage.fromJson(Map<String, dynamic> json) =>
      HostedFurnaceImage(
        id: json["_id"] ?? '',
        location: json["location"] ?? '',
        name: json["name"] ?? '',
        size: json["size"] ?? -1,
        thumbnailTransferState: json["thumbnailTransferState"],
        retries: json["retries"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "location": location,
    "name": name,
    "size": size,
    "thumbnailTransferState": thumbnailTransferState,
    "retries": retries,
  };

}