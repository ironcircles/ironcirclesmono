import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/structs/SelectionWithTool.dart';
import 'package:ironcirclesapp/services/cache/table_prompt.dart';

enum ImageType { image, avatar, network, circle }

enum PromptType { generate, inpaint }

class StableDiffusionPrompt {
  int? pk;
  String id;
  String userID;
  String jobID;
  String prompt;
  String negativePrompt;
  String model;
  int seed;
  int steps;
  double guidance;
  String sampler;
  int upscale;
  String loraOne;
  String loraTwo;
  double loraOneStrength;
  double loraTwoStrength;
  int width;
  int height;
  DateTime? created;
  PromptType promptType;
  String maskPrompt;
  File? initImage;
  int visualOnlySeed;
  File? maskImage;
  File? generatedImage;
  List<SelectionWithTool>? screenPoints;

  StableDiffusionPrompt({
    this.pk,
    this.id = '',
    this.userID = '',
    this.jobID = '',
    this.prompt = '',
    this.maskPrompt = '',
    this.negativePrompt = '',
    this.model = 'dreamshaper_8',
    this.seed = -1,
    this.steps = 30,
    this.guidance = 7.0,
    this.sampler = 'dpmpp_2m_karras',
    this.upscale = 1,
    this.loraOne = '',
    this.loraTwo = '',
    this.loraOneStrength = .7,
    this.loraTwoStrength = .7,
    this.width = 512,
    this.height = 512,
    this.created,
    this.visualOnlySeed = -1,
    required this.promptType,
  }) {
    if (promptType == PromptType.inpaint) {
      model = 'dreamshaper_8_inpaint';
    }
  }

  factory StableDiffusionPrompt.fromJson(Map<String, dynamic> json) =>
      StableDiffusionPrompt(
        //pk: json[TablePrompt.pk],
        promptType: PromptType.values
            .firstWhere((element) => element.index == json["promptType"]),
        id: json['_id'] ?? (json['id']),
        prompt: json[TablePrompt.prompt],
        userID: json[TablePrompt.userID],
        jobID: json[TablePrompt.jobID] ?? '',
        negativePrompt: json[TablePrompt.negativePrompt],
        maskPrompt: json[TablePrompt.maskPrompt] ?? '',
        model: json[TablePrompt.model],
        seed: json[TablePrompt.seed],
        steps: json[TablePrompt.steps],
        guidance: json[TablePrompt.guidance].toDouble(),
        sampler: json[TablePrompt.sampler],
        upscale: json[TablePrompt.upscale],
        loraOne: json[TablePrompt.loraOne],
        loraTwo: json[TablePrompt.loraTwo],
        loraOneStrength: json[TablePrompt.loraOneStrength],
        loraTwoStrength: json[TablePrompt.loraTwoStrength],
        width: json[TablePrompt.width],
        height: json[TablePrompt.height],
        created: json[TablePrompt.created] == null
            ? null
            : json[TablePrompt.created] is String
                ? DateTime.parse(json[TablePrompt.created]).toLocal()
                : DateTime.fromMillisecondsSinceEpoch(json["created"])
                    .toLocal(),
      );

  Map<String, dynamic> toJson() => {
        TablePrompt.id: id,
        TablePrompt.userID: userID,
        TablePrompt.jobID: jobID,
        TablePrompt.prompt: prompt,
        TablePrompt.maskPrompt: maskPrompt,
        TablePrompt.promptType: promptType.index,
        TablePrompt.negativePrompt: negativePrompt,
        TablePrompt.model: model,
        TablePrompt.seed: seed,
        TablePrompt.steps: steps,
        TablePrompt.guidance: guidance,
        TablePrompt.sampler: sampler,
        TablePrompt.upscale: upscale,
        TablePrompt.loraOne: loraOne,
        TablePrompt.loraTwo: loraTwo,
        TablePrompt.loraOneStrength: loraOneStrength,
        TablePrompt.loraTwoStrength: loraTwoStrength,
        TablePrompt.width: width,
        TablePrompt.height: height,
        TablePrompt.created: created?.millisecondsSinceEpoch,
        //DateTime.parse(TablePrompt.created]).toLocal() :    created,
      };

  setPrompt(String value, ImageType type) {
    switch (type) {
      case ImageType.avatar:
        prompt = getAvatarPrompt(value);
        break;
      case ImageType.network:
        prompt = getNetworkPrompt(value);
        break;
      case ImageType.image:
      case ImageType.circle:
        break;
    }
  }

  static String getAvatarPrompt(String value) {
    return 'digital avatar for social media user, username is ($value)++, HDR, cinematic, masterpiece';
  }

  static String getAvatarNegativePrompt() {
    return 'words, text, writing, letters, ugly, tiling, poorly drawn hands, poorly drawn feet, poorly drawn face, out of frame, extra limbs, disfigured, deformed, body out of frame, blurry, bad anatomy, blurred, watermark, grainy, signature, cut off, draft';
  }

  static String getNetworkPrompt(String value) {
    return '($value)++, cinematic, HDR, best quality, masterpiece';
  }

  static String getNetworkNegativePrompt() {
    return 'words, text, writing, letters, ugly, tiling, poorly drawn hands, poorly drawn feet, poorly drawn face, out of frame, extra limbs, disfigured, deformed, body out of frame, blurry, bad anatomy, blurred, watermark, grainy, signature, cut off, draft';
  }

  static String getCirclePrompt(String value) {
    return '($value)++, HDR, cinematic, best quality, masterpiece';
  }

  static String getCircleNegativePrompt() {
    return 'words, text, writing, letters, ugly, tiling, poorly drawn hands, poorly drawn feet, poorly drawn face, out of frame, extra limbs, disfigured, deformed, body out of frame, blurry, bad anatomy, blurred, watermark, grainy, signature, cut off, draft';
  }

  setNegativePrompt(ImageType type) {
    switch (type) {
      case ImageType.avatar:
        negativePrompt = getAvatarNegativePrompt();
        break;
      case ImageType.network:
        negativePrompt = getNetworkNegativePrompt();
        break;
      case ImageType.image:
      case ImageType.circle:
        break;
    }
  }

  deepCopy(StableDiffusionPrompt params) {
    prompt = params.prompt;
    maskPrompt = params.maskPrompt;
    negativePrompt = params.negativePrompt;
    model = params.model;
    seed = params.seed;
    steps = params.steps;
    upscale = params.upscale;
    guidance = params.guidance;
    loraOne = params.loraOne;
    loraTwo = params.loraTwo;
    loraOneStrength = params.loraOneStrength;
    loraTwoStrength = params.loraTwoStrength;
    width = params.width;
    height = params.height;
    userID = params.userID;
    id = params.id;
    jobID = params.jobID;
    maskPrompt = params.maskPrompt;
    created = params.created;
  }

  String resolutionString(BuildContext context) {
    if (width == height) {
      return AppLocalizations.of(context)!.square;
    } else if (width > height) {
      return AppLocalizations.of(context)!.landscape;
    } else {
      return AppLocalizations.of(context)!.portrait;
    }
  }
}

class StableDiffusionPromptCollection {
  final List<StableDiffusionPrompt> prompts;

  StableDiffusionPromptCollection.fromJSON(Map<String, dynamic> json)
      : prompts = (json as List)
            .map((json) => StableDiffusionPrompt.fromJson(json))
            .toList();
}
