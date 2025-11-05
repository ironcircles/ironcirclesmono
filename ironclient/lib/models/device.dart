import 'package:ironcirclesapp/models/export_models.dart';

class Device {
  String? id;
  String? uuid;
  String? identity;
  String? platform;
  String? manufacturer;
  String manufacturerID;
  String? name;
  String? model;
  String? appPath;
  String? pushToken;
  String? ownerID;
  String? userID;
  String? kyberSharedSecret;

  ///used for sql only
  int? build;
  bool activated;
  DateTime? lastAccessed;
  bool warningShown;

  //UI only
  UserFurnace? userFurnace;
  String? oldID;

  Device({
    this.id,
    this.uuid,
    this.platform,
    this.identity,
    this.manufacturer,
    this.manufacturerID = '',
    this.name,
    this.model,
    this.ownerID,
    this.userID,
    this.pushToken,
    this.appPath,
    this.build,
    this.kyberSharedSecret,
    this.activated = true,
    this.warningShown = false,
    this.lastAccessed,
    this.userFurnace,
  });

  factory Device.fromJson(Map<String, dynamic> json, UserFurnace userFurnace) =>
      Device(
        id: json['_id'],
        uuid: json['uuid'],
        platform: json['platform'],
        manufacturer: json['manufacturer'],
        //manufacturerID: json['manufacturerID'],
        name: json['name'],
        model: json['model'],
        ownerID: json['ownerID'],
        identity: json['identity'],
        kyberSharedSecret: json['kyberSharedSecret'],
        pushToken: json['pushToken'],
        build: json['build'],
        activated: json['activated'],
        lastAccessed: json["lastUpdate"] == null
            ? DateTime(1900)
            : DateTime.parse(json["lastUpdate"]).toLocal(),
        userFurnace: userFurnace,
      );

  factory Device.fromMemberJson(Map<String, dynamic> json) => Device(
        uuid: json['uuid'],
        platform: json['platform'],
        manufacturer: json['manufacturer'],
        //manufacturerID: json['manufacturerID'],
        name: json['name'],
        model: json['model'],
        warningShown: json.containsKey('warningShown')
            ? json["warningShown"] == 1
                ? true
                : false
            : false,
        ownerID: json['ownerID'],
        userID: json['userID'],
        identity: json['identity'],
        //build: json['build'],
      );

  factory Device.fromJsonSQL(Map<String, dynamic> json) => Device(
        uuid: json['uuid'],
        manufacturerID: json['manufacturerID'] ?? '',
        pushToken: json['pushToken'],
        kyberSharedSecret:
            json['kyberSharedSecret'] == '' ? null : json['kyberSharedSecret'],
      );

  Map<String, dynamic> toJsonSQL() => {
        'uuid': uuid,
        'manufacturerID': manufacturerID,
        'pushToken': pushToken,
        'kyberSharedSecret': kyberSharedSecret ?? '',
      };

  Map<String, dynamic> toMemberJsonSQL() => {
        'uuid': uuid,
        'ownerID': ownerID,
        'userID': userID,
        'identity': identity,
        //'kyberSharedSecret': kyberSharedSecret,
        'model': model,
        'build': build,
        'platform': platform,
        'warningShown': warningShown ? 1 : 0,
        'manufacturer': manufacturer,
        'name': name,
      };
}

class DeviceCollection {
  final List<Device> devices;

  DeviceCollection.fromJSONAddFurnace(
      Map<String, dynamic> json, String key, UserFurnace userFurnace)
      : devices = (json[key] as List)
            .map((json) => Device.fromJson(json, userFurnace))
            .toList();

  DeviceCollection.fromJSON(Map<String, dynamic> json)
      : devices =
            (json as List).map((json) => Device.fromMemberJson(json)).toList();
}
