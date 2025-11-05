import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/circleobject.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/login/applink.dart';
import 'package:ironcirclesapp/screens/utilities/browser.dart';
import 'package:url_launcher/url_launcher.dart';

class LaunchURLs {
  static void openExternalBrowserUrl(BuildContext context, String url) async {
    Uri uri = Uri.parse(url);

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('Could not launch $url');
    }
  }

  static void openEmailTo(BuildContext context, String email) async {
    Uri uri = Uri.parse(email);

    try {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('Could not launch $email');
    }
  }

  static void openExternalBrowser(
      BuildContext context, CircleObject circleObject) async {
    if (circleObject.link!.url == null) return;

    Uri uri = Uri.parse(circleObject.link!.url!);

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('Could not launch ${circleObject.link!.url}');
    }
  }

  static void launchURLForCircleObject(
      BuildContext context, CircleObject circleObject) async {
    try {
      if (circleObject.link!.url != null) {
        String url = circleObject.link!.url!;
        if (url.contains('ironcircles.page.link')) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AppLink(
                      link: url,
                      fromApp: true,
                    )),
          ); //.then(_circleObjectBloc.requestNewerThan(

          return;
        } else if (url.contains('www.tiktok.com') ||
            url.contains('maps.app.goo.gl') ||
            url.contains('youtu.be') ||
            url.contains('amazon') ||
            url.contains('apple') ||
            url.contains('wefunder.com') ||
            url.contains('https://a.co/') ||
            url.contains('instagram.com') ||
            url.contains('facebook.com') ||
            url.contains('www.linkedin.com') ||
            url.contains('maps.apple.com') ||
            url.contains('http:') ||
            url.contains('microsoft:') ||
            url.contains('twitter:') ||
            url.contains('zoom') ||
            url.contains('slack') ||
            url.contains('doxy') ||
            url.contains('google') ||
            url.contains('trello.com') ||
            url.contains('youtube') ||
            Platform.isWindows ||
            Platform.isMacOS ||
            Platform.isLinux) {
          openExternalBrowserUrl(context, url);
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Browser(url: url)),
          ); //.then(_circleObjectBloc.requestNewerThan(

          return;
        }
      }

      debugPrint('Could not launch ${circleObject.link!.url}');
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
    }
  }
}
