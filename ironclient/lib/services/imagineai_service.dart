// import 'dart:async';
// import 'dart:convert';
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' show Client;
// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';
// import 'dart:typed_data';
//
// import 'package:ironcirclesapp/blocs/imagineai_bloc.dart';
// import 'package:ironcirclesapp/blocs/log_bloc.dart';
//
// class ImagineAIService {
//   Client client = Client();
//
//   static Future<Uint8List?> generateImage(ImagineAIParams params) async {
//     try {
//       String url = 'https://api.vyro.ai/v1/imagine/api/generations';
//       Map<String, dynamic> headers = {
//         'Authorization':
//
//       };
//
//       debugPrint(params.prompt);
//       debugPrint(params.negativePrompt);
//
//       Map<String, dynamic> payload = {
//         'prompt': params.prompt,
//         'negative_prompt': params.negativePrompt,
//         'style_id': params.style.toString(),
//         'aspect_ratio': params.aspectRatio.toString(), //'1:1',
//         'cfg': params.cfg.toString(), //'3',
//         'seed': params.seed.toString(),
//         'high_res_results': '0'
//       };
//
//       FormData formData = FormData.fromMap(payload);
//
//       Dio dio = Dio();
//       dio.options =
//           BaseOptions(headers: headers, responseType: ResponseType.bytes);
//
//       final response = await dio.post(url, data: formData);
//       if (response.statusCode == 200) {
//         log(response.data.runtimeType.toString());
//         log(response.data.toString());
//         Uint8List uint8List = Uint8List.fromList(response.data);
//         return uint8List;
//       } else {
//         return null;
//       }
//     } catch (e, trace) {
//       LogBloc.insertError(e, trace);
//     }
//   }
// }
