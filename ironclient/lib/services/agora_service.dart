import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/models/userfurnace.dart';
import 'package:ironcirclesapp/encryption/encryptapitraffic.dart';
import 'package:ironcirclesapp/models/circleagoracall.dart';

class TokenService {
  //final String baseUrl;

  TokenService();

  Future<CircleAgoraCall> startCall(String circleID, UserFurnace userFurnace) async {
    String url = userFurnace.url! + Urls.START_AGORA_CALL;

    Map map = {'circleID': circleID};

    map = await EncryptAPITraffic.encrypt(map);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        },
        body: json.encode(map),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = await EncryptAPITraffic.decryptJson(
          response.body,
        );

        return CircleAgoraCall.fromJson(jsonResponse);
      } else {
        // Handle non-200 responses
        //LogBloc.insertError(e, trace);
      }
    } catch (e, trace) {
      LogBloc.insertError(e, trace);
    }

    return CircleAgoraCall();
  }
}
