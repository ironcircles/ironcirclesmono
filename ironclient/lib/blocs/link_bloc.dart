import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/circleobject_service.dart';
import 'package:ironcirclesapp/services/linkpreview_service.dart';
import 'package:rxdart/rxdart.dart';

class LinkBloc {
  final _linkService = LinkPreviewService();
  final _linkResult = PublishSubject<CircleLink?>();
  final _circleObjectService = CircleObjectService();

  Stream<CircleLink?> get fetchLinkResults => _linkResult.stream;

  fetchLink(CircleObject circleObject, UserFurnace? userFurnace) async {
    try {
      CircleLink? retValue =
          await _linkService.fetchPreview(circleObject.link!.url!);

      if (retValue != null) {
        circleObject.link!.body = retValue.body;
        circleObject.link!.title = retValue.title;
        circleObject.link!.image = retValue.image;
        circleObject.link!.description = retValue.description;

        //update the cache
        await _circleObjectService.cacheCircleObject(circleObject);

        ///TODO This caused a 500 error because the member is not the creator
        ///Also update the server so others users don't have to hit the preview service
        // await _circleObjectService.updateCircleObject(
        //circleObject, userFurnace!);
      }

      _linkResult.sink.add(retValue);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
      _linkResult.sink.addError(error);
    }
  }

  Future<CircleObject?> unfurlLink(CircleObject circleObject) async {
    CircleLink? preview;

    preview = await _fetchLinkSync(circleObject.link!.url!, circleObject.body);

    if (preview != null) {
      circleObject.link!.body = preview.body;
      circleObject.link!.title = preview.title;
      circleObject.link!.description = preview.description;
      circleObject.link!.image = preview.image;

      //update the cache
      await _circleObjectService.cacheCircleObject(circleObject);

      return circleObject;
    }

    return null;
  }

  Future<CircleLink?> _fetchLinkSync(String url, String? body) async {
    CircleLink? retValue;

    try {
      retValue = await _linkService.fetchPreview(url);
      retValue!.body = body;

      //_linkResult.sink.add(retValue);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
      //_linkResult.sink.addError(error);
    }

    return retValue;
  }

  dispose() async {
    await _linkResult.drain();
    _linkResult.close();
  }
}
