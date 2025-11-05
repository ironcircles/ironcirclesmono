import 'dart:convert';

Tutorial tutorialFromJson(String str) => Tutorial.fromJson(json.decode(str));

class Tutorial {
  String id;
  String title;
  List<TutorialLineItem> lineItems;
  String? video;
  //int order;

  Tutorial({
    required this.id,
    required this.title,
    required this.lineItems,
    required this.video,
    //required this.order,
  });

  factory Tutorial.fromJson(Map<String, dynamic> json) => Tutorial(
        id: json["_id"],
        title: json["title"],
        lineItems: TutorialLineItemCollection.fromJSON(json).lineItems,
        video: json["video"],
      );
}

class TutorialCollection {
  final List<Tutorial> tutorials;

  TutorialCollection.fromJSON(Map<String, dynamic> json)
      : tutorials = (json['tutorials'] as List)
            .map((json) => Tutorial.fromJson(json))
            .toList();
}

class Topic {
  String id;
  String topic;
  List<Tutorial> tutorials;
  int order;

  Topic({
    required this.id,
    required this.topic,
    required this.tutorials,
    required this.order,
  });

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
        id: json["_id"],
        topic: json["topic"],
        tutorials: TutorialCollection.fromJSON(json).tutorials,
        order: json["order"],
      );
}

class TopicCollection {
  final List<Topic> topics;

  TopicCollection.fromJSON(Map<String, dynamic> json)
      : topics = (json['topics'] as List)
            .map((json) => Topic.fromJson(json))
            .toList();
}

class TutorialLineItem {
  String id;
  String item;
  bool subTitle;

  String? video;
  //int order;

  TutorialLineItem({
    required this.id,
    required this.item,
    required this.video,
    this.subTitle = false,
    //required this.order,
  });

  factory TutorialLineItem.fromJson(Map<String, dynamic> json) =>
      TutorialLineItem(
        id: json["_id"],
        item: json["item"],
        video: json["video"],
        subTitle: json["subTitle"],
        //order: json["order"],
      );
}

class TutorialLineItemCollection {
  final List<TutorialLineItem> lineItems;

  TutorialLineItemCollection.fromJSON(Map<String, dynamic> json)
      : lineItems = (json['lineItems'] as List)
            .map((json) => TutorialLineItem.fromJson(json))
            .toList();
}
