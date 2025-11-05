import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:store_redirect/store_redirect.dart';

class AppStoreLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Platform.isAndroid
        ? InkWell(
          child: const Padding(
            padding: EdgeInsets.only(bottom: 15, right: 5),
            child: (Text(
              'Launch Google Play Store',
              textScaler: TextScaler.linear(1.0),
              style: TextStyle(color: Colors.pink, fontSize: 20),
            )),
          ),
          onTap: () {
            // LaunchReview.launch(
            //   writeReview: false,
            //   androidAppId: "com.ironcircles.ironcirclesapp",
            //   //iOSAppId: "585027354",
            // );

            StoreRedirect.redirect(
              androidAppId: "com.ironcircles.ironcirclesapp",
              iOSAppId: "585027354",
            );
          },
        )
        : Platform.isIOS
        ? InkWell(
          child: const Padding(
            padding: EdgeInsets.only(bottom: 15, right: 5),
            child: (Text(
              'Launch App Store',
              textScaler: TextScaler.linear(1.0),
              style: TextStyle(color: Colors.pink, fontSize: 20),
            )),
          ),
          onTap: () {
            launchUrl(
              Uri.parse('https://apps.apple.com/app/id/1634856740'),
              mode: LaunchMode.externalApplication,
            );
          },
        )
        : Container();
  }
}
