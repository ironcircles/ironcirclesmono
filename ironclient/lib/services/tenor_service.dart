import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' show Client;
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/constants.dart';
import 'package:ironcirclesapp/constants/urls.dart';

class GiphyOption {
  String url = '';
  String preview = '';
  int? height;
  int? width;
  int? previewHeight;
  int? previewWidth;

  GiphyOption(
      {required this.url,
      required this.preview,
      this.height,
      this.width,
      this.previewHeight,
      this.previewWidth});
}

class TenorCategory {
  String term = '';
  String path = '';
  String image;

  TenorCategory({
    required this.term,
    required this.path,
    required this.image,
  });
}

class TenorService {
  Client client = Client();

  Future<List<String>> autoComplete(String phrase) async {
    try {
      List<String> retValue = [];

      //phrase = phrase.replaceAll("GIPHY ", "").trim();

      if (phrase.isEmpty) {
        return [];
        //throw Exception('No phrase entered');
      }

      String url = Urls.TENOR_AUTOCOMPLETE;
      url = "$url?q=${phrase.replaceAll(" ", "+")}";
      url = "$url&key=${Urls.TENORKEY}";
      url = "$url&q=${phrase.replaceAll(" ", "+")}";
      url = "$url&limit=75";
      // url = url + "&weirdness=10";

      //debugPrint("Giphy URL = " + url);

      final response = await client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        //debugPrint(response.body);

        var jsonResponse = json.decode(response.body);

        //fixed_width_downsampled
        //fixed_width_small
        //downsized_medium

        for (var url in jsonResponse["results"]) {
          //if (url["images"]["fixed_width"]["url"] == null ||
          //     url["images"]["fixed_width_downsampled"]["url"] == null) continue;

          try {
            retValue.add(url);

            //debugPrint('break');
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint('TenorService.searchGiphy: $err');

            //rethrow;
          }
        }

        //return retValue;

        // If the call to the server was successful, parse the JSON
        //return User.fromJson(json.decode(response.body));
      } else {
        debugPrint(response.statusCode.toString());
        // If that call was not successful, throw an error.
        //throw Exception('Tenor search failed');
      }

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TenorService.searchGiphy: $err');
      rethrow;
    }

    /*
  JSONObject jsonResponse = (JSONObject) response;

                                jsonResponse = jsonResponse.getJSONObject("data");
                                jsonResponse = jsonResponse.getJSONObject("images");
                                jsonResponse = jsonResponse.getJSONObject("downsized");
                                String url = jsonResponse.getString("url");
   */
  }

  Future<List<GiphyOption>> search(String phrase, int queryNumber) async {
    try {
      List<GiphyOption> retValue = [];

      //phrase = phrase.replaceAll("GIPHY ", "").trim();

      if (phrase.isEmpty) {
        return [];
        //throw Exception('No phrase entered');
      }

      int position = 0;
      if (queryNumber > 0) {
        position = queryNumber * 50;
      }

      String url = Urls.TENOR_URL;
      url = "$url?q=${phrase.replaceAll(" ", "+")}";
      url = "$url&key=${Urls.TENORKEY}";
      url = "$url&q=${phrase.replaceAll(" ", "+")}";
      url = "$url&limit=50";
      url = "$url&pos=$position";
      // url = url + "&weirdness=10";

      //debugPrint("Giphy URL = " + url);

      final response = await client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        //debugPrint(response.body);

        var jsonResponse = json.decode(response.body);

        //fixed_width_downsampled
        //fixed_width_small
        //downsized_medium

        for (var url in jsonResponse["results"]) {
          //if (url["images"]["fixed_width"]["url"] == null ||
          //     url["images"]["fixed_width_downsampled"]["url"] == null) continue;

          try {
            var level1 = url["media"];
            var level2 = level1[0];
            var tinyUrl1 = level2['tinygif']; //nanogif
            var tinyUrl2 = tinyUrl1['url'];
            var tinyDims = tinyUrl1['dims'];
            int tinyWidth = tinyDims[0];
            int tinyHeight = tinyDims[1];
            var gifUrl1 = level2['mediumgif'];
            var gifUrl2 = gifUrl1['url'];

            // debugPrint('break');

            var dims = gifUrl1['dims'];

            // debugPrint('break');

            int width = dims[0];
            int height = dims[1];

            // debugPrint('break');

            if (width > InsideConstants.MESSAGEBOXSIZE) {
              double ratio = width / InsideConstants.MESSAGEBOXSIZE;
              width = InsideConstants.MESSAGEBOXSIZE.toInt();

              height = (height ~/ ratio);
            }

            retValue.add(GiphyOption(
                url: gifUrl2,
                height: height,
                width: width,
                preview: tinyUrl2,
                previewHeight: tinyHeight,
                previewWidth: tinyWidth));
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint('TenorService.searchGiphy: $err');

            //rethrow;
          }
        }

        //return retValue;

        // If the call to the server was successful, parse the JSON
        //return User.fromJson(json.decode(response.body));
      } else {
        debugPrint(response.statusCode.toString());
        // If that call was not successful, throw an error.
        throw Exception('Tenor search failed');
      }

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TenorService.searchGiphy: $err');
      rethrow;
    }
  }

  Future<List<GiphyOption>> trending() async {
    try {
      List<GiphyOption> retValue = [];

      String url = 'https://g.tenor.com/v1/trending?key=${Urls.TENORKEY}';

      final response = await client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        //debugPrint(response.body);

        var jsonResponse = json.decode(response.body);

        //fixed_width_downsampled
        //fixed_width_small
        //downsized_medium

        for (var url in jsonResponse["results"]) {
          //if (url["images"]["fixed_width"]["url"] == null ||
          //     url["images"]["fixed_width_downsampled"]["url"] == null) continue;

          try {
            var level1 = url["media"];
            var level2 = level1[0];
            var tinyUrl1 = level2['tinygif'];
            var tinyUrl2 = tinyUrl1['url'];
            var tinyDims = tinyUrl1['dims'];
            int tinyWidth = tinyDims[0];
            int tinyHeight = tinyDims[1];

            var gifUrl1 = level2['mediumgif'];
            var gifUrl2 = gifUrl1['url'];

            // debugPrint('break');

            var dims = gifUrl1['dims'];

            // debugPrint('break');

            int width = dims[0];
            int height = dims[1];

            // debugPrint('break');

            if (width > InsideConstants.MESSAGEBOXSIZE) {
              double ratio = width / InsideConstants.MESSAGEBOXSIZE;
              width = InsideConstants.MESSAGEBOXSIZE.toInt();

              height = (height ~/ ratio);
            }

            retValue.add(GiphyOption(
                url: gifUrl2,
                height: height,
                width: width,
                preview: tinyUrl2,
                previewHeight: tinyHeight,
                previewWidth: tinyWidth));
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint('TenorService.trending: $err');
          }
        }
      } else {
        debugPrint(response.statusCode.toString());
        // If that call was not successful, throw an error.
        throw Exception('Tenor search failed');
      }

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TenorService.trending: $err');
      rethrow;
    }

    /*
  JSONObject jsonResponse = (JSONObject) response;

                                jsonResponse = jsonResponse.getJSONObject("data");
                                jsonResponse = jsonResponse.getJSONObject("images");
                                jsonResponse = jsonResponse.getJSONObject("downsized");
                                String url = jsonResponse.getString("url");
   */
  }

  //https://g.tenor.com/v1/categories?<parameters>

  Future<List<TenorCategory>> category(int category) async {
    try {
      List<TenorCategory> retValue = [];

      String path = '';

      if (category == 0)
        path = 'categories';
      else if (category == 1) path = 'trending';

      String url = 'https://g.tenor.com/v1/$path?key=${Urls.TENORKEY}';

      final response = await client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        //debugPrint(response.body);

        var jsonResponse = json.decode(response.body);

        //fixed_width_downsampled
        //fixed_width_small
        //downsized_medium

        for (var result in jsonResponse["tags"]) {
          //if (url["images"]["fixed_width"]["url"] == null ||
          //     url["images"]["fixed_width_downsampled"]["url"] == null) continue;

          try {
            retValue.add(TenorCategory(
              term: result["searchterm"],
              path: result["path"],
              image: result["image"],
            ));
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint('TenorService.category: $err');

            //rethrow;
          }
        }

        //return retValue;

        // If the call to the server was successful, parse the JSON
        //return User.fromJson(json.decode(response.body));
      } else {
        debugPrint(response.statusCode.toString());
        // If that call was not successful, throw an error.
        throw Exception('Tenor search failed');
      }

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TenorService.searchGiphy: $err');
      rethrow;
    }
  }
}
