// To parse this JSON data, do
//
//     final circleObjectCache = circleObjectCacheFromJson(jsonString);

import 'dart:convert';

EmojiUsage emojiUsageCacheFromJson(String str) =>
    EmojiUsage.fromJson(json.decode(str));

String emojiUsageCacheToJson(EmojiUsage data) => json.encode(data.toJson());

class EmojiUsage {
  int? pk;
  String? emoji;
  int usage;

  EmojiUsage({
    this.pk,
    this.emoji,
    this.usage=0,
  });

  factory EmojiUsage.fromJson(Map<String, dynamic> json) => EmojiUsage(
        pk: json["pk"],
        emoji: json["emoji"],
        usage: json["usage"],
      );

  Map<String, dynamic> toJson() => {
        //"pk": pk,
        "emoji": emoji,
        "usage": usage,
      };


  static List<String?> convertToStringList(List<EmojiUsage> emojiUsageList){
    List<String?> retValue = [];

    for (EmojiUsage emojiUsage in emojiUsageList){
      retValue.add(emojiUsage.emoji);
    }

    return retValue;

  }

}

