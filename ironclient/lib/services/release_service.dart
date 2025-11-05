import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/release.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';

class ReleaseService {

  Future<List<Release>> get(UserFurnace userFurnace) async {
    String url = userFurnace.url! + Urls.RELEASES;

    final response = await http.get(Uri.parse(url),
        headers: {
          'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        },
        );

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);

      ReleaseCollection releases =
      ReleaseCollection.fromJSON(jsonResponse);


      return releases.releases;

    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);
      return [];
    }else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      throw Exception(jsonResponse['msg']);
    }

  }

}
