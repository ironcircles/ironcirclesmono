import 'package:ironcirclesapp/models/stablediffusionprompt.dart';

// StableDiffusionPricing releaseFromJson(String str) => StableDiffusionPricing.fromJson(json.decode(str));

class StableDiffusionPricing {
  double baseLora;
  double stepsSmall;
  double stepsMedium;
  double stepsLarge;
  double stepsXLarge;
  double sizeSmall;
  double sizeMedium;
  double sizeLarge;
  double sizeXLarge;
  double markup;
  double upscaleSmall;
  double upscaleMedium;
  double upscaleLarge;
  double upscaleXLarge;
  int coinMultiplier;

  StableDiffusionPricing({
    this.baseLora = 0.0012,
    this.stepsSmall = 0.0000335,
    this.stepsMedium = 0.0000335,
    this.stepsLarge = 0.00001455,
    this.stepsXLarge = 0.00003025,
    this.sizeSmall = 0.000950,
    this.sizeMedium = 0.000950,
    this.sizeLarge = 0.004350,
    this.sizeXLarge = 0.009050,
    this.markup = 1.2,
    this.upscaleSmall = 0.00025,
    this.upscaleMedium = 0.0006,
    this.upscaleLarge = 0.00145,
    this.upscaleXLarge = 0.00255,
    this.coinMultiplier = 10000,
  });

  factory StableDiffusionPricing.fromJson(Map<String, dynamic> json) =>
      StableDiffusionPricing(
        baseLora: json["baseLora"],
        stepsSmall: json["stepsSmall"],
        stepsMedium: json["stepsMedium"],
        stepsLarge: json["stepsLarge"],
        stepsXLarge: json["stepsXLarge"],
        sizeSmall: json["sizeSmall"],
        sizeMedium: json["sizeMedium"],
        sizeLarge: json["sizeLarge"],
        sizeXLarge: json["sizeXLarge"],
        markup: json["markup"] == 1 ? 1.0 : json["markup"],
        upscaleSmall: json["upscaleSmall"],
        upscaleMedium: json["upscaleMedium"],
        upscaleLarge: json["upscaleLarge"],
        upscaleXLarge: json["upscaleXLarge"],
      );

  int calculateCharge(StableDiffusionPrompt prompt) {
    double charge = 0;

    ///calculate sizes
    charge = charge + _calculateSizeCharge(prompt.height);
    charge = charge + _calculateSizeCharge(prompt.width);

    ///calculate steps
    charge = charge + _calculateStepCharge(prompt.height, prompt.steps);
    charge = charge + _calculateStepCharge(prompt.width, prompt.steps);

    ///calculate upscale
    if (prompt.upscale == 2) {
      charge = charge + (_calculateUpscaleMultiplier(prompt.height));
      charge = charge + ( _calculateUpscaleMultiplier(prompt.width));
    }

    charge = charge * coinMultiplier;
    charge = charge * markup;
    return charge.round();
  }

  double _calculateSizeCharge(int size) {
    double charge = 0;

    if (size == 1024) {
      charge = sizeXLarge;
    } else if (size == 768) {
      charge = sizeLarge;
    } else if (size == 512) {
      charge = sizeMedium;
    } else if (size == 320) {
      charge = sizeSmall;
    }

    return charge;
  }

  double _calculateStepCharge(int size, int steps) {
    double charge = 0;

    if (size == 1024) {
      charge = stepsXLarge * (steps - 30);
    } else if (size == 768) {
      charge = stepsLarge * (steps - 30);
    } else if (size == 512) {
      charge = stepsMedium * (steps - 30);
    } else if (size == 320) {
      charge = stepsSmall * (steps - 30);
    }

    return charge;
  }

  double _calculateUpscaleMultiplier(int size) {
    double charge = 1;

    if (size == 1024) {
      charge = upscaleXLarge;
    } else if (size == 768) {
      charge = upscaleLarge;
    } else if (size == 512) {
      charge = upscaleMedium;
    } else if (size == 320) {
      charge = upscaleSmall;
    }

    return charge;
  }
}
