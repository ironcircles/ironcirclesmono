import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/metric.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';

class MetricsService {
  Future<MetricsCollection> get(UserFurnace userFurnace) async {
    String url = userFurnace.url! + Urls.METRICS;

    debugPrint(url);

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': userFurnace.token!,
        'Content-Type': "application/json",
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);

      MetricsCollection result = MetricsCollection.fromJSON(jsonResponse);

      if (jsonResponse.containsKey('subscriptionCount')) {
        result.subscribedCount = jsonResponse['subscriptionCount'];
      } else {
        result.subscribedCount = 16;
      }

      if (jsonResponse.containsKey('accountsDeleted')) {
        result.accountsDeleted = jsonResponse['accountsDeleted'];
      } else {
        result.accountsDeleted = 6;
      }

      if (jsonResponse.containsKey('metricsLastFourteen')) {
        result.activeInLastFourteen = jsonResponse['metricsLastFourteen'];
      } else {
        result.activeInLastFourteen = -1;
      }

      return result;
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);
      return MetricsCollection(metrics: [], subscribedCount: 0, accountsDeleted: 0);
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      throw Exception(jsonResponse['msg']);
    }
  }
}
