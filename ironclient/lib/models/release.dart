import 'dart:convert';

import 'package:flutter/material.dart';



Release releaseFromJson(String str) => Release.fromJson(json.decode(str));

class Release {
  String id;
  String version;
  int build;
  DateTime released;
  List<String> notes;
  int? minimumBuild;
  final GlobalKey key = GlobalKey();

  Release({
    required this.id,
    required this.version,
    required this.build,
    required this.notes,
    required this.released,
    this.minimumBuild,
  });

  factory Release.fromJson(Map<String, dynamic> json) => Release(
        id: json["_id"],
        version: json["version"],
        build: json["build"],
        notes: List<String>.from(json["notes"].map((x) => x)),
        released: DateTime.parse(json["released"]).toLocal(),
        minimumBuild: json["minimumBuild"]
      );
}

class ReleaseCollection {
  final List<Release> releases;

  ReleaseCollection.fromJSON(Map<String, dynamic> json)
      : releases = (json['releases'] as List)
            .map((json) => Release.fromJson(json))
            .toList();
}
