import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/webmedia_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';


class DialogCaching {
  static Future<void> showCaching(BuildContext context, String title,
      String url, bool isFile, Function success) async {

    //title = NotificationLocalization.getLocalizedString(title, context);

    if (isFile)
      _cacheFile(context, url, success);
    else
      _cacheUrl(context, url, success);

    // flutter defined function
    return showDialog<void>(
      barrierColor: Colors.black.withOpacity(.8),
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          surfaceTintColor: Colors.transparent,
          backgroundColor: globalState.theme.dialogTransparentBackground,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30.0))),
          title: Center(
              child: Text(
            title,
            style: TextStyle(color: globalState.theme.bottomIcon),
          )),
          content: Text(
            AppLocalizations.of(context)!.cachingMedia,
            style: TextStyle(color: globalState.theme.labelText),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: TextStyle(
                    fontSize: 18, color: globalState.theme.bottomIcon),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static _cacheUrl(BuildContext context, String url, Function success) async {
    try {
      String temp = await WebMediaBloc.getMedia(url);
      Navigator.of(context).pop();
      success(temp);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);

      Navigator.of(context).pop();
    }
  }

  static _cacheFile(BuildContext context, String uri, Function success) async {
    try {
      String path =
          await FileSystemService.returnTempPathAndFileKeepFilename(uri);

      File incoming = File.fromUri(Uri.parse(uri));
      //File incoming = File(uri.replaceFirst('file://', ''));

      debugPrint(path);
      debugPrint(uri);
      debugPrint(incoming.path);

      if (incoming.existsSync()) {
        await incoming.copy(path);
        success(path);
      }

      Navigator.of(context).pop();
    } catch (error, trace) {
      LogBloc.insertError(error, trace);

      Navigator.of(context).pop();
    }
  }
}
