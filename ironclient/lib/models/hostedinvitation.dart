import 'package:ironcirclesapp/models/circle.dart';
import 'package:ironcirclesapp/models/hostedfurnace.dart';
import 'package:ironcirclesapp/models/user.dart';

class HostedInvitation {
  String link;
  User inviter;
  Circle? circle;
  HostedFurnace hostedFurnace;

  HostedInvitation({
    required this.link,
    required this.inviter,
    required this.circle,
    required this.hostedFurnace,
  });

  factory HostedInvitation.fromJson(Map<String, dynamic> json) =>
      HostedInvitation(
        link: json['link'],
        inviter: User.fromJson(json["inviter"]),
        circle: json["circle"] == null ? null : Circle.fromJson(json["circle"]),
        hostedFurnace: HostedFurnace.fromJson(json["hostedFurnace"]),
      );

  /*Map<String, dynamic> toJson() => {
        'token': token,
        'inviter': inviter,
        'circle': circle,
        'hostedFurnace': hostedFurnace,
      };

   */
}

class HostedInvitationCollection {
  final List<HostedInvitation> objects;

  HostedInvitationCollection.fromJSON(Map<String, dynamic> json, String key)
      : objects = (json[key] as List)
            .map((json) => HostedInvitation.fromJson(json))
            .toList();
}
