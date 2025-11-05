import 'dart:io';
import 'dart:typed_data';

import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/stablediffusionprompt.dart';
import 'package:ironcirclesapp/screens/widgets/formatteddropdownobject.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/stablediffusion_service.dart';
import 'package:rxdart/subjects.dart';

final List<ListItem> aspectRatio = [
  ListItem(object: '1:1', name: '1:1'),
  ListItem(object: '3:2', name: '3:2'),
  ListItem(object: '4:3', name: '4:3'),
  ListItem(object: '3:4', name: '3:4'),
  ListItem(object: '16:9', name: '16:9'),
  ListItem(object: '9:16', name: '9:16'),
];

final List<ListItem> inpaintingModels = [
  ListItem(
      object: 'absolute_reality_1_8_1_inpaint',
      name: 'AbsoluteReality 1.8.1 Inpaint'),
  ListItem(
      object: 'anything_4_5_inpaint', name: 'Anything 4.5 Inpaint (anime)'),
  ListItem(
      object: 'cyberrealistic_3_3_inpaint', name: 'CyberRealistic 3.3 Inpaint'),
  ListItem(object: 'dreamshaper_8_inpaint', name: 'DreamShaper 8 Inpaint'),
  ListItem(object: 'icbinp_seco_inpaint', name: 'ICBINP SECO Inpaint'),
  ListItem(
      object: 'realistic_vision_5_1_inpaint',
      name: 'Realistic Vision 5.1 Inpaint'),
  ListItem(
      object: 'stablediffusion_inpaint_1', name: 'Stable Diffusion Inpaint 1'),
  ListItem(
      object: 'stablediffusion_inpaint_2', name: 'Stable Diffusion Inpaint 2'),
];

final List<ListItem> models = [
  ListItem(
      object: 'absolute_reality_1', name: 'AbsoluteReality 1.0 (realistic)'),
  ListItem(
      object: 'absolute_reality_1_6', name: 'AbsoluteReality 1.6 (realistic)'),
  ListItem(
      object: 'absolute_reality_1_8_1',
      name: 'AbsoluteReality 1.8.1 (realistic)'),
  ListItem(object: 'abyss_orange_mix_2', name: 'AbyssOrangeMix 2 (anime)'),
  ListItem(object: 'analog_diffusion', name: 'Analog Diffusion (general)'),
  ListItem(object: 'analogmadness_7', name: 'Analog Madness 7 (realistic)'),
  ListItem(object: 'anylora', name: 'AnyLora (general)'),
  ListItem(object: 'anything_3_0', name: 'Anything 3.0 (anime)'),
  ListItem(object: 'anything_4_0', name: 'Anything 4.0 (anime)'),
  ListItem(object: 'anything_5_0', name: 'Anything 5.0 (anime)'),
  ListItem(object: 'basil_mix', name: 'Basil Mix (general)'),
  ListItem(object: 'blood_orange_mix', name: 'BloodOrangeMix (anime)'),
  ListItem(
      object: 'cyberrealistic_1_3', name: 'CyberRealistic 1.3 (realistic)'),
  ListItem(
      object: 'cyberrealistic_3_1', name: 'CyberRealistic 3.1 (realistic)'),
  ListItem(
      object: 'cyberrealistic_3_3', name: 'CyberRealistic 3.3 (realistic)'),
  ListItem(object: 'deliberate', name: 'Deliberate 1 (general)'),
  ListItem(object: 'deliberate_2', name: 'Deliberate 2 (general)'),
  ListItem(object: 'dh_classicanime', name: 'DH ClassicAnime (anime)'),
  ListItem(object: 'disco_diffusion_style', name: 'Disco Diffusion Style'),
  ListItem(
      object: 'double_exposure_diffusion', name: 'Double Exposure Diffusion'),
  ListItem(object: 'dreamix_1', name: 'Dreamix 1 (3d_render)'),
  ListItem(object: 'dreamshaper', name: 'DreamShaper 2.52 (general)'),
  ListItem(object: 'dreamshaper_5', name: 'DreamShaper 5 (general)'),
  ListItem(object: 'dreamshaper_6', name: 'DreamShaper 6 (general)'),
  ListItem(object: 'dreamshaper_7', name: 'DreamShaper 7 (general)'),
  ListItem(object: 'dreamshaper_8', name: 'DreamShaper 8 (general)'),
  ListItem(object: 'duchaiten_anime', name: 'DucHaitenAnime (anime)'),
  ListItem(object: 'duchaiten_darkside', name: 'DucHaitenDarkside (general)'),
  ListItem(object: 'duchaiten_dreamworld', name: 'DucHaitenDreamWorld (anime)'),
  ListItem(
      object: 'eimis_anime_diffusion_1', name: 'Eimis Anime Diffusion (anime)'),
  ListItem(object: 'ely_orange_mix', name: 'ElyOrangeMix (anime)'),
  ListItem(object: 'emoji_diffusion', name: 'Emoji Diffusion'),
  ListItem(object: 'epic_diffusion_1', name: 'Epîc Diffusion 1.0 (general)'),
  ListItem(object: 'epic_diffusion_1_1', name: 'Epîc Diffusion 1.1 (general)'),
  ListItem(
      object: 'foto_assisted_diffusion',
      name: 'Foto Assisted Diffusion (general)'),
  ListItem(object: 'furrytoonmix', name: 'FurryToonMix (drawing)'),
  ListItem(object: 'future_diffusion', name: 'Future Diffusion'),
  ListItem(object: 'hasdx', name: 'HASDX (general)'),
  ListItem(object: 'icbinp', name: 'ICBINP (realistic)'),
  ListItem(object: 'icbinp_seco', name: 'ICBINP SECO (realistic)'),
  ListItem(
      object: 'iconsmi_appiconsmodelforsd', name: 'IconsMI App icons (icons)'),
  ListItem(object: 'inkpunk_diffusion', name: 'Inkpunk Diffusion'),
  ListItem(object: 'kidsmix', name: 'KidsMix (drawing)'),
  ListItem(object: 'lowpoly_world', name: 'Lowpoly World'),
  ListItem(object: 'nightmareshaper', name: 'NightmareShaper (general)'),
  ListItem(object: 'openjourney', name: 'OpenJourney (general)'),
  ListItem(object: 'openjourney_2', name: 'OpenJourney v2 (general)'),
  ListItem(object: 'openniji', name: 'OpenNiji (anime)'),
  ListItem(object: 'paint_journey_2_768px', name: 'Paint Journey 2 (painting)'),
  ListItem(object: 'papercut', name: 'Papercut'),
  ListItem(object: 'pastel_mix', name: 'Pastel Mix (anime)'),
  ListItem(object: 'portrait_plus', name: 'Portrait Plus (portrait)'),
  ListItem(object: 'realcartoon3d_13', name: 'RealCartoon3D 13 (artistic)'),
  ListItem(object: 'realcartoonanime_10', name: 'RealCartoonAnime 10 (anime)'),
  ListItem(object: 'realdream_12', name: 'RealDream 12 (realistic)'),
  ListItem(
      object: 'realistic_vision_1_3', name: 'Realistic Vision 1.3 (realistic)'),
  ListItem(
      object: 'realistic_vision_5_1', name: 'Realistic Vision 5.1 (realistic)'),
  ListItem(
      object: 'redshift_diffusion', name: 'Redshift Diffusion (3d_render)'),
  ListItem(
      object: 'redshift_diffusion_768px',
      name: 'Redshift Diffusion (768px) (3d_render)'),
  ListItem(object: 'rpg_5', name: 'RPG 5 (artistic)'),
  ListItem(object: 'something_2', name: 'Something 2 (anime)'),
  ListItem(
      object: 'stable_diffusion_fluidart', name: 'Stable Diffusion FluidArt'),
  ListItem(
      object: 'stable_diffusion_papercut', name: 'Stable Diffusion PaperCut'),
  ListItem(
      object: 'stable_diffusion_voxelart', name: 'Stable Diffusion VoxelArt'),
  ListItem(
      object: 'stablediffusion_1_4', name: 'Stable Diffusion 1.4 (general)'),
  ListItem(
      object: 'stablediffusion_1_5', name: 'Stable Diffusion 1.5 (general)'),
  ListItem(
      object: 'stablediffusion_2_0_512px',
      name: 'Stable Diffusion 2.0 (512px) (general)'),
  ListItem(
      object: 'stablediffusion_2_0_768px',
      name: 'Stable Diffusion 2.0 (768px) (general)'),
  ListItem(
      object: 'stablediffusion_2_1_512px',
      name: 'Stable Diffusion 2.1 (512px) (general)'),
  ListItem(
      object: 'stablediffusion_2_1_768px',
      name: 'Stable Diffusion 2.1 (768px) (general)'),
  ListItem(object: 'steampunk_diffusion', name: 'Steampunk Diffusion'),
  ListItem(object: 'synthwavepunk_v2', name: 'Synthwavepunk v2 (cyberpunk)'),
  ListItem(object: 'texture_diffusion', name: 'Texture Diffusion'),
  ListItem(object: 'toonify_2', name: 'Toonify 2 (drawing)'),
  ListItem(object: 'trinart_2_0', name: 'Trinart 2.0 (anime)'),
  ListItem(object: 'tshirt_diffusion', name: 'T-shirt Diffusion'),
  ListItem(object: 'vectorartz_diffusion', name: 'Vectorartz Diffusion'),
  ListItem(
      object: 'vintedois_diffusion_v0_1',
      name: 'Vintedois Diffusion (simple, general)'),
  ListItem(object: 'vox_2', name: 'Vox 2'),
  ListItem(object: 'waifudiffusion_1_3', name: 'Waifu Diffusion 1.3 (anime)'),
  ListItem(object: 'waifudiffusion_1_4', name: 'Waifu Diffusion 1.4 (anime)'),
  ListItem(object: 'yesmix_4', name: 'YesMix 4 (anime)'),
];

final List<ListItem> samplers = [
  ListItem(object: 'ddim', name: 'ddim'),
  ListItem(object: 'dpm', name: 'dpm'),
  ListItem(object: 'dpmpp_2m_karras', name: 'dpmpp_2m_karras'),
  ListItem(object: 'euler', name: 'euler'),
  ListItem(object: 'euler_a', name: 'euler_a'),
  ListItem(object: 'k_lms', name: 'k_lms'),
  ListItem(object: 'pndm', name: 'pndm'),
];

enum GenType { avatar, network }

class StableDiffusionAIBloc {
  final _generateImageComplete = PublishSubject<bool>();
  Stream<bool> get generateImageComplete => _generateImageComplete.stream;

  final _promptHistory = PublishSubject<List<StableDiffusionPrompt>>();
  Stream<List<StableDiffusionPrompt>> get promptHistory =>
      _promptHistory.stream;

  Future<File?> generateImage({
      required StableDiffusionPrompt imageGeneratorParams, required bool registering}) async {
    try {
      if (imageGeneratorParams.prompt.isEmpty) {
        throw "prompt is empty";
      }

      Uint8List? result;

      if (registering) {
        result = await StableDiffusionAIService.generateImageForRegistration(
            imageGeneratorParams);

      } else {
        result = await StableDiffusionAIService.generateImage(
            globalState.userFurnace!, imageGeneratorParams);
      }

      ///save to temp_images
      if (result != null) {
        File file = await FileSystemService.getNewTempImageFile();
        file.writeAsBytesSync(result);
        return file;
      } else {
        throw "unable to generate image. please try again later.";
      }
    } catch (e, trace) {
      LogBloc.insertError(e, trace);
      //throw ("unable to generate image. please try again later.");
      rethrow;
    }
  }

  Future<File?> inpaintWithText(StableDiffusionPrompt prompt) async {
    try {
      if (prompt.prompt.isEmpty) {
        throw "prompt is empty";
      }
      if (prompt.maskPrompt.isEmpty) {
        throw "object to change is empty";
      }
      Uint8List? result;

      result = await StableDiffusionAIService.inpaintWithText(
        prompt,
        globalState.userFurnace!,
      );

      ///save to temp_images
      if (result != null) {
        File file = await FileSystemService.getNewTempImageFile();
        file.writeAsBytesSync(result);
        return file;
      } else {
        throw "unable to inpaint image. please try again later.";
      }
    } catch (e, trace) {
      LogBloc.insertError(e, trace);
      rethrow;
    }
  }

  Future<File?> inpaintWithImage(StableDiffusionPrompt prompt) async {
    try {
      if (prompt.initImage == null) {
        throw "missing init image";
      }
      if (prompt.maskImage == null) {
        throw "missing mask image";
      }
      if (prompt.prompt.isEmpty) {
        throw "prompt is empty";
      }
      Uint8List? result;

      result = await StableDiffusionAIService.inpaintWithImage(
          prompt,
          globalState.userFurnace!,
      );

      ///save to temp_images
      if (result != null) {
        File file = await FileSystemService.getNewTempImageFile();
        file.writeAsBytesSync(result);
        return file;
      } else {
        throw "unable to inpaint image. please try again later.";
      }
    } catch (e, trace) {
      LogBloc.insertError(e, trace);
      rethrow;
    }
  }

  dispose() async {
    await _generateImageComplete.drain();
    _generateImageComplete.close();
  }

  getPromptHistory(String userID, PromptType promptType) async {
    List<StableDiffusionPrompt> prompts =
        await StableDiffusionAIService.getPromptHistory(
            userID, 5000, promptType);
    _promptHistory.sink.add(prompts);
  }

  deletePrompt(StableDiffusionPrompt prompt) {
    StableDiffusionAIService.deletePrompt(globalState.userFurnace!, prompt);
  }
}
