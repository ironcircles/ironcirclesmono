class HostedFurnaceStorage {
  /*String accessKey;
  String secretKey;
  String avatarBucket;
  String mediaBucket;
   */
  String location;

  HostedFurnaceStorage({
    /*required this.accessKey,
    required this.secretKey,
    required this.avatarBucket,
    required this.mediaBucket,*/
    required this.location,
  });

  factory HostedFurnaceStorage.fromJson(Map<String, dynamic> json) =>
      HostedFurnaceStorage(
        /*accessKey: json['accessKey'],
        secretKey: json['secretKey'],
        avatarBucket: json['avatarBucket'],
        mediaBucket: json['mediaBucket'],*/
        location: json['location'],
      );

  Map<String, dynamic> toJson() => {
        /*'accessKey': accessKey,
        'secretKey': secretKey,
        'avatarBucket': avatarBucket,
        'mediaBucket': mediaBucket,*/
        'location': location,
      };
}

class HostedFurnaceStorageCollection {
  final List<HostedFurnaceStorage> objects;

  HostedFurnaceStorageCollection.fromJSON(Map<String, dynamic> json, String key)
      : objects = (json[key] as List)
            .map((json) => HostedFurnaceStorage.fromJson(json))
            .toList();
}
