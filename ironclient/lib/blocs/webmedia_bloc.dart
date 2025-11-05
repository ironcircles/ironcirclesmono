import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/services/webmedia_service.dart';

class WebMediaBloc {
  static Future<String> getMedia(String url) async {
    try {
      return await WebMediaService.downloadMedia(url);

    } catch (error, trace) {
      LogBloc.insertError(error, trace);

      rethrow;
    }
  }
}
