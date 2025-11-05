class OfficialNotification {
  String? id;
  String title;
  String message;
  bool enabled;

  OfficialNotification({
    this.id,
    required this.title,
    required this.message,
    required this.enabled,
  });

  factory OfficialNotification.fromJson(Map<String, dynamic> jsonMap) =>
      OfficialNotification(
        id: jsonMap['_id'],
        title: jsonMap['title'],
        message: jsonMap['message'],
        enabled: jsonMap['enabled']
      );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'title': title,
    'message': message,
    'enabled': enabled,
  };
}