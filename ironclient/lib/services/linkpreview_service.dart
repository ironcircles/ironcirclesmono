import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' show Client;
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/utils/network.dart';

class LinkPreviewService {
  Client client = Client();


  Future<CircleLink?> fetchPreview(String url) async {
    if (url.isEmpty) {
      throw Exception('invalid url');
    }

    if (url.contains('ironcircles.page.link')){

      return CircleLink(image: Urls.WEB_ICON, title: 'Invitation to an IronCircles network', description: '', url: url);
    }


    if (await Network.isConnected()) {
      url = Urls.LINKPREVIEWURL + url;

      debugPrint(url);

      final response = await client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);

        return CircleLink.fromJson(jsonResponse);
      //} else if (response.statusCode == 401) {
        ///await navService.logout(userFurnace);
      }else {
        debugPrint(
            'Error for link preview service - statusCode: ${response.statusCode}  body: ${response.body}');
        // If that call was not successful, throw an error.
        throw Exception('Linkpreview search failed');
      }
    }

    return null;
  }


   /*

  Future<CircleLink> fetchPreview(String url) async {

    CircleLink retValue;

    if (url.isEmpty) {
      throw Exception('invalid url');
    }

      try {


        PreviewResponse previewResponse = await LinkPreview.getPreview(url);

        if (previewResponse.status == PreviewStatus.success) {
          retValue.title = previewResponse.title;
          retValue.description = previewResponse.description;
          retValue.image = previewResponse.image;
          retValue.url = url;

        }
      } catch (err, trace) { LogBloc.insertError(err, trace);
        debugPrint('$err');
      }
    }

    return retValue;
  }
  */


/****
 *
 *
 *
 * "title":"Google",
    "description":"Search webpages, images, videos and more.",
    "image":"https:\/\/www.google.com\/images\/logo.png",
    "url":"https:\/\/www.google.com"
 */

}
