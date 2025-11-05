import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';

CircleVote circleVoteFromJson(String str) =>
    CircleVote.fromJson(json.decode(str));

String circleVoteToJson(CircleVote data) => json.encode(data.toJson());

/*


circle: { type: mongoose.Schema.Types.ObjectId, ref: 'Circle', required: true},
  question: String,
  open: {type:Boolean, default:true},
  type: {type: String, default: 'standard'}, //standard, invitation, remove
  model: {type: String, default: 'unanimous'},  //versus majority controlled
  winner: CircleVoteOptionSchema,
  options: [CircleVoteOptionSchema]



*/

class CircleVote /*extends CircleObject*/ {
  String? question;
  String? type;
  String? model;
  String? description;
  bool? open;
  String? object;
  int? itemChecked;
  CircleVoteOption? winner;
  List<CircleVoteOption>? options;
  //bool userVoted = false;

  CircleVote({
    this.question,
    this.type,
    this.model,
    this.description,
    this.open,
    this.object,
    this.itemChecked,
    this.winner,
    this.options,
  });

  /*
  bool _setUserVote(User user) {
    bool retValue = false;

    for (CircleVoteOption option in options) {
      if (option.usersVotedFor.contains(user)) retValue = true;
    }

    return retValue;
  }
*/

  factory CircleVote.fromJson(Map<String, dynamic> json) => CircleVote(
        question: json["question"],
        type: json["type"],
        model: json["model"],
        description: json["description"],
        open: json["open"],
        object: json["object"],
        winner: json["winner"] == null
            ? null
            : CircleVoteOption.fromJson(json["winner"]),
        itemChecked: json["itemChecked"],

        options: json["options"] == null
            ? null
            : CircleVoteOptionCollection.fromJSON(json, "options")
                .circleVoteOptions,

        //userVoted: options.u

        //options: List<CircleVoteOption>.from(json["options"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "question": question,
        "type": type,
        "model": model,
        "description": description,
        "open": open,
        "object": object,
        "winner": winner?.toJson(),
        "itemChecked": itemChecked,
        "options":
            options == null ? null : List<dynamic>.from(options!.map((x) => x)),
      };

  mapDecryptedFields(Map<String, dynamic> json) {
    question = json["question"];
    description = json["description"];
    winner = json["winner"] == null
        ? null
        : CircleVoteOption.fromJson(json["winner"]);
    options = json["options"] == null
        ? null
        : CircleVoteOptionCollection.fromJSON(json, "options")
            .circleVoteOptions;
  }

  Map<String, dynamic> fetchFieldsToEncrypt() => {
        "question": question,
        "description": description,
        "winner": winner?.toJson(),
        "options":
            options == null ? null : List<dynamic>.from(options!.map((x) => x)),
      };

  static bool didUserVote(CircleVote circleVote, String? userID) {
    try {
      for (CircleVoteOption circleVoteOption in circleVote.options!) {
        if (circleVoteOption.usersVotedFor != null) {
          for (User user in circleVoteOption.usersVotedFor!) {
            if (user.id == userID) return true;
          }
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleVote.didUserVote: $err');

      throw err;
    }

    return false;
  }

  static bool didUserVotedForOption(
      CircleVoteOption circleVoteOption, String? userID) {
    try {
      for (User user in circleVoteOption.usersVotedFor!) {
        if (user.id == userID) return true;
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleVote.didUserVote: $err');

      throw err;
    }
    return false;
  }

  static int getUserVotedForIndex(CircleVote circleVote, String? userID) {
    for (int i = 0; i < circleVote.options!.length; i++) {
      for (int j = 0; j < circleVote.options![i].usersVotedFor!.length; j++) {
        //for (User user in circleVoteOption.usersVotedFor) {
        if (circleVote.options![i].usersVotedFor![j].id == userID) return i;
      }
    }

    return -1;
  }

  static bool isWinner(
      CircleVoteOption circleVoteOption, CircleVote circleVote) {
    bool retValue = false;

    if (circleVote.winner != null) if (circleVoteOption.id ==
        circleVote.winner!.id) retValue = true;

    return retValue;
  }

  static bool canUserVote(CircleVote circleVote, String? userID) {
    bool retValue = true;

    if (circleVote.object != null) if (circleVote.object == userID)
      retValue = false;

    return retValue;
  }

  String getTitle(BuildContext context) {
    String retValue = ""; // = circleVote.question;

    if (model == CircleVoteModel.POLL) {
      if (open!)
        retValue = AppLocalizations.of(context)!.pollOpen;
      else
        retValue = AppLocalizations.of(context)!.pollClosed;
    } else if (model == CircleVoteModel.UNANIMOUS) {
      if (open!)
        retValue = AppLocalizations.of(context)!.unanimousVoteOpen;
      else {
        if (winner != null)
          retValue = AppLocalizations.of(context)!.closedWithUnanimousDecision;
        else
          retValue = AppLocalizations.of(context)!.unanimousVoteFailed;
      }
    } else if (model == CircleVoteModel.MAJORITY) {
      if (open!)
        retValue = AppLocalizations.of(context)!.simpleMajorityVoteOpen;
      else {
        if (winner != null)
          retValue = AppLocalizations.of(context)!.closedWithMajorityDecision;
        else
          retValue = AppLocalizations.of(context)!.simpleMajorityVoteFailed;
      }
    }

    return retValue;
  }

  String getQuestion(BuildContext context) {

    if (type == CircleVoteType.PRIVACY_SETTING ||
        type == CircleVoteType.PRIVACY_SETTING_MODEL) {
      return AppLocalizations.of(context)!.noticeAllowCircleSettingsChanges;
    } else {
      return question!;
    }
  }

  String getDescription(BuildContext context) {
    String retValue = description!; // = circleVote.question;

    if (type == CircleVoteType.PRIVACY_SETTING ||
        type == CircleVoteType.PRIVACY_SETTING_MODEL) {
      retValue = retValue.replaceAll(
          "false", AppLocalizations.of(context)!.off.toLowerCase());
      retValue = retValue.replaceAll(
          "true", AppLocalizations.of(context)!.on.toLowerCase());
      retValue = retValue.replaceAll(
          "to", AppLocalizations.of(context)!.to.toLowerCase());
      retValue = retValue.replaceAll(
          "toggleEntryVote", AppLocalizations.of(context)!.toggleEntryVote);
      retValue = retValue.replaceAll("toggleMemberPosting",
          AppLocalizations.of(context)!.toggleMemberPosting);
      retValue = retValue.replaceAll("toggleMemberReacting",
          AppLocalizations.of(context)!.toggleMemberReacting);
      retValue = retValue.replaceAll(
          "privacyShareImage", AppLocalizations.of(context)!.privacyShareImage);
      retValue = retValue.replaceAll("privacyVotingModel",
          AppLocalizations.of(context)!.privacyVotingModel);
      retValue = retValue.replaceAll(
          "privacyShareURL", AppLocalizations.of(context)!.privacyShareURL);
      retValue = retValue.replaceAll(
          "privacyShareGif", AppLocalizations.of(context)!.privacyShareGif);
      retValue = retValue.replaceAll(
          "privacyCopyText", AppLocalizations.of(context)!.privacyCopyText);
      retValue = retValue.replaceAll("privacyDisappearingTimer",
          AppLocalizations.of(context)!.privacyDisappearingTimer);
    }
    return retValue;
  }

  static CircleVote? deepCopy(CircleVote circleVote,
      {bool includeVotes = false}) {
    CircleVote? retValue;

    try {
      retValue = CircleVote(
        question: circleVote.question,
        type: circleVote.type,
        model: circleVote.model,
        open: circleVote.open,
        winner: circleVote.winner,
        itemChecked: circleVote.itemChecked,

        //tasks: Recipe.from(circleRecipe.tasks),
        options: CircleVoteOption.deepCopy(circleVote.options!,
            includeVotes: includeVotes),
      );
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleRecipe.deepCopy: $err');
    }

    return retValue;
  }

  /*
  List<String> getOptions() {
    List<String> optionsList = [];

    for (CircleVoteOption circleVoteOption in options) {
      optionsList.add(circleVoteOption.option);
    }

    return optionsList;
  }
  */
}

/*

{
    "question": "",
    "voteType":"" ,
    "model": "" ,
    "open": false,
    "itemChecked":0,
    "options": [""]
}





 */
