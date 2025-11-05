

class MemberCircle {
  int? pk;
  String memberID;
  String userID;
  String circleID;

  //String username;
  bool dm;

  MemberCircle({
    required this.memberID,
    this.pk,
    required this.userID,
    required this.circleID,

    //required this.username,
    required this.dm,
  });

  factory MemberCircle.fromJson(Map<String, dynamic> json) => MemberCircle(
        pk: json['pk'],
        memberID: json['memberID'],
        userID: json['userID'],
        circleID: json['circleID'],

        //username: json['username'],
        dm: (json['dm'] == 1 || json['dm'] == true) ? true : false,
      );

  Map<String, dynamic> toJson() => {
        //'pk': pk,
        'memberID': memberID,
        'userID': userID,
        'circleID': circleID,

        'dm': dm ? 1 : 0,
        // 'username': username,
      };
}

class MemberCircleCollection {
  final List<MemberCircle> membersCircles;

  MemberCircleCollection.fromJSON(Map<String, dynamic> json, String key)
      : membersCircles = (json[key] as List)
            .map((json) => MemberCircle.fromJson(json))
            .toList();
}
