import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart' show Client;
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/encryption/encryptapitraffic.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/stablediffusionprompt.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/table_prompt.dart';

class StableDiffusionAIService {
  Client client = Client();

  static Future<String> getKey(UserFurnace userFurnace) async {
    try {
      String url = userFurnace.url! + Urls.DEZGO_KEY;
      debugPrint(url);

      Map map = {
        'apikkey': urls.forgeAPIKEY,
      };

      Device device = await globalState.getDevice();

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.post(Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse =
            await EncryptAPITraffic.decryptJson(response.body);
        return jsonResponse['key'];
      }
    } catch (e, trace) {
      LogBloc.insertError(e, trace);
    }

    return '';
  }

  static Future<String> getKeyForRegistration() async {
    try {
      String url = urls.forge + Urls.DEZGO_KEY_FOR_REGISTRATION;

      Map map = {
        'apikkey': urls.forgeAPIKEY,
      };

      debugPrint(url);

      Device device = await globalState.getDevice();

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.post(Uri.parse(url),
          headers: {
            'Content-Type': "application/json",
          },
          body: json.encode(map));

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse =
            await EncryptAPITraffic.decryptJson(response.body);
        return jsonResponse['key'];
      }
    } catch (e, trace) {
      LogBloc.insertError(e, trace);
    }

    return '';
  }

  static getInpaintingFormData(StableDiffusionPrompt prompt) async {
    Map<String, dynamic> payload = {
      'prompt': prompt.prompt,
      'model': prompt.model,
      'negative_prompt': prompt.negativePrompt,
      'guidance': prompt.guidance.toString(),
      'steps': prompt.steps.toString(),
      'sampler': prompt.sampler,
      'upscale': prompt.upscale.toString(),
      'format': 'jpg',
      'init_image': await MultipartFile.fromFile(prompt.initImage!.path,
          filename: FileSystemService.getFilename(prompt.initImage!.path)),
      'mask_prompt': prompt.maskPrompt,
    };

    if (prompt.seed > 1) {
      payload['seed'] = prompt.seed;
    }

    return FormData.fromMap(payload);
  }

  static getImageFormData(StableDiffusionPrompt prompt) async {
    Map<String, dynamic> payload = {
      'prompt': prompt.prompt,
      'model': prompt.model,
      'negative_prompt': prompt.negativePrompt,
      'guidance': prompt.guidance.toString(),
      'steps': prompt.steps.toString(),
      'sampler': prompt.sampler,
      'upscale': prompt.upscale.toString(),
      'format': 'jpg',
      'init_image': await MultipartFile.fromFile(prompt.initImage!.path,
          filename: FileSystemService.getFilename(prompt.initImage!.path)),
      'mask_image': await MultipartFile.fromFile(prompt.maskImage!.path,
          filename: FileSystemService.getFilename(prompt.maskImage!.path)),
    };

    if (prompt.seed > 1) {
      payload['seed'] = prompt.seed;
    }

    return FormData.fromMap(payload);
  }

  static getFormData(StableDiffusionPrompt prompt) async {
    Map<String, dynamic> payload = {
      'prompt': prompt.prompt,
      'model': prompt.model,
      'negative_prompt': prompt.negativePrompt,
      'guidance': prompt.guidance.toString(),
      'steps': prompt.steps.toString(),
      'sampler': prompt.sampler,
      'upscale': prompt.upscale.toString(),
      'format': 'jpg',
      'lora1': prompt.loraOne,
      'lora2': prompt.loraTwo,
      'lora1_strength': prompt.loraOneStrength,
      'lora2_strength': prompt.loraTwoStrength,
      'width': prompt.width,
      'height': prompt.height,
    };

    if (prompt.seed >= 1) {
      payload['seed'] = prompt.seed;
    }

    return FormData.fromMap(payload);
  }

  static Future<Uint8List?> inpaintWithText(
      StableDiffusionPrompt prompt, UserFurnace userFurnace) async {
    try {
      String url = 'https://api.dezgo.com/text-inpainting';

      debugPrint(url);

      String apiKey = await globalState.getDezgoKey(userFurnace);

      if (apiKey.isEmpty) {
        throw ("image generation service unavailable, please try again later.");
      }

      Map<String, dynamic> headers = {
        'X-Dezgo-Key': apiKey,
        'Content-Type': 'multipart/form-data'
      };

      FormData formData = await getInpaintingFormData(prompt);

      Dio dio = Dio();
      dio.options =
          BaseOptions(headers: headers, responseType: ResponseType.bytes);

      final response = await dio.post(url, data: formData);
      if (response.statusCode == 200) {
        if (response.headers['x-input-seed'] != null) {
          prompt.seed = int.parse(response.headers['x-input-seed']!.first);
        }
        if (response.headers['x-dezgo-job-id'] != null) {
          prompt.jobID = response.headers['x-dezgo-job-id']!.first;
        }

        prompt.created = DateTime.now();
        await TablePrompt.upsert(prompt);

        ///move the seed to visual only so a regen creates a new image
        prompt.visualOnlySeed = prompt.seed;
        prompt.seed = -1;

        updatePrompt(
            userFurnace, prompt.id, prompt.visualOnlySeed, prompt.jobID);

        return response.data;
      } else if (response.statusCode == 400) {
        debugPrint(response.statusMessage);
      }
    } on DioException catch (e) {
      debugPrint(e.message);
      if (e.type == DioExceptionType.badResponse &&
          e.message != null &&
          e.message!.contains("400")) {
        throw ("Something went wrong - could not generate image");
      }
    } catch (e, trace) {
      LogBloc.insertError(e, trace);
      rethrow;
    }

    return null;
  }

  static Future<Uint8List?> inpaintWithImage(
      StableDiffusionPrompt prompt, UserFurnace userFurnace) async {
    try {
      String url = 'https://api.dezgo.com/inpainting';

      debugPrint(url);

      String apiKey = await globalState.getDezgoKey(userFurnace);

      if (apiKey.isEmpty) {
        throw ("image generation service unavailable, please try again later.");
      }

      Map<String, dynamic> headers = {
        'X-Dezgo-Key': apiKey,
        'Content-Type': 'multipart/form-data'
      };

      FormData formData = await getImageFormData(prompt);

      Dio dio = Dio();
      dio.options = BaseOptions(
          headers: headers,
          responseType: ResponseType.bytes,
          receiveDataWhenStatusError: true);

      final response = await dio.post(url, data: formData);
      if (response.statusCode == 200) {
        if (response.headers['x-input-seed'] != null) {
          prompt.seed = int.parse(response.headers['x-input-seed']!.first);
        }
        if (response.headers['x-dezgo-job-id'] != null) {
          prompt.jobID = response.headers['x-dezgo-job-id']!.first;
        }

        prompt.created = DateTime.now();
        await TablePrompt.upsert(prompt);

        ///move the seed to visual only so a regen creates a new image
        prompt.visualOnlySeed = prompt.seed;
        prompt.seed = -1;

        updatePrompt(
            userFurnace, prompt.id, prompt.visualOnlySeed, prompt.jobID);

        return response.data;
      } else if (response.statusCode == 400) {
        debugPrint(response.statusMessage);
      }
    } on DioException catch (e) {
      debugPrint(e.message);
      if (e.type == DioExceptionType.badResponse &&
          e.message != null &&
          e.message!.contains("400")) {
        throw ("Something went wrong - could not generate image");
      }
    } catch (e, trace) {
      LogBloc.insertError(e, trace);
      rethrow;
    }
    return null;
  }

  static Future<Uint8List?> generateImageForRegistration(
      StableDiffusionPrompt prompt) async {
    try {
      String url = 'https://api.dezgo.com/text2image';

      debugPrint(url);

      String apiKey = await globalState.getDezgoKeyForRegistration();

      if (apiKey.isEmpty) {
        throw ("image generation service unavailable, please try again later.");
      }

      Map<String, dynamic> headers = {
        'X-Dezgo-Key': apiKey,
        'Content-Type': 'multipart/form-data'
      };

      FormData formData = await getFormData(prompt);

      Dio dio = Dio();
      dio.options =
          BaseOptions(headers: headers, responseType: ResponseType.bytes);

      final response = await dio.post(url, data: formData);
      if (response.statusCode == 200) {
        int seed = prompt.seed;
        if (response.headers['x-input-seed'] != null) {
          seed = int.parse(response.headers['x-input-seed']!.first);
        }
        if (response.headers['x-dezgo-job-id'] != null) {
          prompt.jobID = response.headers['x-dezgo-job-id']!.first;
        }

        ///move the seed to visual only so a regen creates a new image
        prompt.visualOnlySeed = seed;
        return response.data;
      }
    } catch (e, trace) {
      LogBloc.insertError(e, trace);
      rethrow;
    }

    return null;
  }

  static Future<Uint8List?> generateImage(
      UserFurnace userFurnace, StableDiffusionPrompt prompt) async {
    try {
      String url = 'https://api.dezgo.com/text2image';

      debugPrint(url);

      String apiKey = await globalState.getDezgoKeyForRegistration();

      if (apiKey.isEmpty) {
        throw ("image generation service unavailable, please try again later.");
      }

      Map<String, dynamic> headers = {
        'X-Dezgo-Key': apiKey,
        'Content-Type': 'multipart/form-data'
      };

      FormData formData = await getFormData(prompt);

      Dio dio = Dio();
      dio.options =
          BaseOptions(headers: headers, responseType: ResponseType.bytes);

      final response = await dio.post(url, data: formData);

      if (response.statusCode == 200) {
        int seed = prompt.seed;
        if (response.headers['x-input-seed'] != null) {
          prompt.seed = int.parse(response.headers['x-input-seed']!.first);
        }
        if (response.headers['x-dezgo-job-id'] != null) {
          prompt.jobID = response.headers['x-dezgo-job-id']!.first;
        }

        ///move the seed to visual only so a regen creates a new image
        prompt.visualOnlySeed = prompt.seed;
        prompt.created = DateTime.now();
        await TablePrompt.upsert(prompt);

        ///set the prompt back so the user can regen
        prompt.seed = seed;

        updatePrompt(
            userFurnace, prompt.id, prompt.visualOnlySeed, prompt.jobID);
        return response.data;
      } else {
        throw Exception("Something went wrong. Please try again later.");
      }
    } catch (e, trace) {
      LogBloc.insertError(e, trace);
      rethrow;
    }

    return null;
  }

  static Future<List<StableDiffusionPrompt>> getPromptHistory(
      String userID, int amount, PromptType promptType) async {
    List<UserFurnace> userFurnaces =
        await UserFurnaceBloc().requestConnected(globalState.user.id!);
    List<String> userIDs = [];

    for (UserFurnace userFurnace in userFurnaces) {
      userIDs.add(userFurnace.userid!);
    }
    return await TablePrompt.readHistory(userIDs, amount, promptType);
  }

  static updatePrompt(
      UserFurnace userFurnace, String promptID, int seed, String jobID) async {
    try {
      String url = urls.forge + Urls.UPDATE_PROMPT;

      Map map = {
        'promptID': promptID,
        'seed': seed,
        'jobID': jobID,
      };

      map = await EncryptAPITraffic.encrypt(map);

      debugPrint(url);

      final response = await http.put(Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));

      if (response.statusCode == 200) {
        // Map<String, dynamic> jsonResponse =
        // await EncryptAPITraffic.decryptJson(response.body);
        return;
      } else {
        throw ("Something went wrong. Please try again later");
      }
    } catch (e, trace) {
      LogBloc.insertError(e, trace);
    }
  }

  static deletePrompt(
      UserFurnace userFurnace, StableDiffusionPrompt prompt) async {
    try {
      await TablePrompt.delete(prompt);

      String url = urls.forge + Urls.DELETE_PROMPT;

      Map map = {
        'promptID': prompt.id,
      };

      debugPrint(url);

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.delete(Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));

      if (response.statusCode == 200) {
        // Map<String, dynamic> jsonResponse =
        // await EncryptAPITraffic.decryptJson(response.body);
        return;
      } else {
        throw ("Something went wrong. Please try again later");
      }
    } catch (e, trace) {
      LogBloc.insertError(e, trace);
    }
  }
}

// class DezgoResponse {
//   final String seed;
//   final String jobID;
//   final Uint8List? image;
//
//   DezgoResponse({required this.seed, required this.jobID, required this.image});
// }
