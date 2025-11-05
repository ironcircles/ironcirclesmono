// To parse this JSON data, do
//
//     final linkPreview = linkPreviewFromJson(jsonString);
import 'package:ironcirclesapp/models/hostedfurnace.dart';

class Violation {
  String violatedTerms;
  String comments;
  String? violator;
  String reporter;
  String? circleObject;
  HostedFurnace? hostedFurnace;
  String? replyObject;

  Violation({
    required this.violatedTerms,
    this.comments = '',
    this.violator,
    required this.reporter,
    this.circleObject,
    this.hostedFurnace,
    this.replyObject,
  });

  Map<String, dynamic> toJson() => {
        "comments": comments.isEmpty ? null : comments,
        "violatedTerms": violatedTerms,
        "violator": violator,
        "reporter": reporter,
        "circleObject": circleObject,
        "hostedFurnace": hostedFurnace,
        "replyObject": replyObject,
      };
}
