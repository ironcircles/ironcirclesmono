import 'package:ironcirclesapp/models/hostedfurnace.dart';
import 'package:ironcirclesapp/models/user.dart';

class NetworkRequest {
  String? id;
  int status;
  HostedFurnace hostedFurnace;
  User user;
  String description;

  NetworkRequest({
    this.id,
    required this.status,
    required this.hostedFurnace,
    required this.user,
    required this.description,
  });

  factory NetworkRequest.fromJson(Map<String, dynamic> jsonMap) =>
      NetworkRequest(
        id: jsonMap['_id'] == null
            ? null
            : jsonMap['_id'],
        status: jsonMap['status'],
        hostedFurnace: HostedFurnace.fromJson(jsonMap['hostedFurnace']),
        user: User.fromJson(jsonMap['user']),
        description: jsonMap['description'] == null
            ? ''
            : jsonMap['description'],
      );

  Map<String, dynamic> toJson() => {
    '_id': id == null ? null : id,
    'status': status,
    'hostedFurnace': hostedFurnace?.toJson(),
    'user': user?.toJson(),
    'description': description == null ? '' : description,
  };
}

class NetworkRequestCollection {
  final List<NetworkRequest> objects;

  NetworkRequestCollection.fromJSON(Map<String, dynamic> json, String key)
    : objects = (json[key] as List)
      .map((json) => NetworkRequest.fromJson(json))
      .toList();
}