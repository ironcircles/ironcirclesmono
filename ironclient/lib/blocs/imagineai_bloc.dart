// import 'dart:typed_data';
// import 'package:ironcirclesapp/blocs/log_bloc.dart';
// import 'package:ironcirclesapp/screens/widgets/formatteddropdownobject.dart';
// import 'package:ironcirclesapp/services/imagineai_service.dart';
// import 'package:rxdart/subjects.dart';
//
// final List<ListItem> styles = [
//   ListItem(object: 21, name: 'Anime'),
//   ListItem(object: 26, name: 'Portrait'),
//   ListItem(object: 29, name: 'Realistic'),
//   ListItem(object: 27, name: 'Imagine V1'),
//   ListItem(object: 28, name: 'Imagine V3'),
//   ListItem(object: 30, name: 'Imagine V4'),
//   ListItem(object: 31, name: 'Imagine V4 (Creative)'),
//   ListItem(object: 32, name: 'Imagine V4.1'),
//   ListItem(object: 33, name: 'Imagine V5'),
//   ListItem(object: 34, name: 'Anime V5'),
//   ListItem(object: 122, name: 'SDXL 1.0'),
// ];
//
// final List<ListItem> aspectRatio = [
//   ListItem(object: '1:1', name: '1:1'),
//   ListItem(object: '3:2', name: '3:2'),
//   ListItem(object: '4:3', name: '4:3'),
//   ListItem(object: '3:4', name: '3:4'),
//   ListItem(object: '16:9', name: '16:9'),
//   ListItem(object: '9:16', name: '9:16'),
// ];
//
// class ImagineAIParams {
//   String prompt;
//   String negativePrompt;
//   int style;
//   String aspectRatio;
//   double cfg;
//   int seed;
//   int steps;
//   int hiRes;
//
//   ImagineAIParams({
//     this.prompt = '',
//     this.negativePrompt = '',
//     this.style = 31,
//     this.aspectRatio = '1:1',
//     this.cfg = 7.5,
//     this.seed = 1,
//     this.steps = 30,
//     this.hiRes = 0,
//   });
//
//   deepCopy(ImagineAIParams params) {
//     prompt = params.prompt;
//     negativePrompt = params.negativePrompt;
//     style = params.style;
//     aspectRatio = params.aspectRatio;
//     cfg = params.cfg;
//     seed = params.seed;
//     steps = params.steps;
//     hiRes = params.hiRes;
//   }
// }
//
// class ImagineAIBloc {
//   final _generateImageComplete = PublishSubject<bool>();
//   Stream<bool> get generateImageComplete => _generateImageComplete.stream;
//
//   Future<Uint8List?> generateImage(
//       ImagineAIParams imageGeneratorParams) async {
//     try {
//       if (imageGeneratorParams.prompt.isEmpty) {
//         throw "prompt is empty";
//       }
//
//       return await ImagineAIService.generateImage(imageGeneratorParams);
//     } catch (e, trace) {
//       LogBloc.insertError(e, trace);
//       _generateImageComplete.addError(e);
//     }
//
//     return null;
//   }
//
//   dispose() async {
//     await _generateImageComplete.drain();
//     _generateImageComplete.close();
//   }
// }
