import 'package:ironcirclesapp/models/hostedfurnaceimage.dart';

class HostedFurnace {
  String name;
  String key;
  String id;
  HostedFurnaceImage? hostedFurnaceImage;
  String description;
  String link;
  bool adultOnly;
  bool memberAutonomy;
  bool override;
  bool approved;
  bool discoverable;
  bool enableWall;

  HostedFurnace({
    required this.name,
    required this.key,
    this.hostedFurnaceImage,
    required this.id,
    required this.description,
    required this.link,
    required this.adultOnly,
    required this.memberAutonomy,
    required this.override,
    required this.approved,
    required this.discoverable,
    required this.enableWall,
  });

  factory HostedFurnace.fromJson(Map<String, dynamic> jsonMap) => HostedFurnace(
        name: jsonMap['name'],
        key: jsonMap['key'] ?? '',
        id: jsonMap['_id'],
        hostedFurnaceImage: jsonMap["hostedFurnaceImage"] == null
            ? null
            : HostedFurnaceImage.fromJson(jsonMap["hostedFurnaceImage"]),
        description:
            jsonMap["description"] == null ? '' : jsonMap['description'],
        link:
            jsonMap["link"] == null ? '' : jsonMap["link"],
        adultOnly: jsonMap["adultOnly"],
        memberAutonomy: jsonMap["memberAutonomy"] ?? true,
        override: jsonMap["override"]== null ? false : jsonMap["override"],
        approved: jsonMap["approved"] == null ? false : jsonMap["approved"],
        discoverable: jsonMap["discoverable"],
        enableWall: jsonMap["enableWall"],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'key': key,
        '_id': id,
        'hostedFurnaceImage':
            hostedFurnaceImage == null ? null : hostedFurnaceImage!.toJson(),
        'description': description,
        'link': link,
        'adultOnly': adultOnly ? true : false,
        'memberAutonomy': memberAutonomy,
        'override': override ? true : false,
        'approved': approved ? true : false,
        'discoverable': discoverable,
        'enableWall': enableWall,
      };
}

class HostedFurnaceCollection {
  final List<HostedFurnace> objects;

  HostedFurnaceCollection.fromJSON(Map<String, dynamic> json, String key)
      : objects = (json[key] as List)
            .map((json) => HostedFurnace.fromJson(json))
            .toList();
}
