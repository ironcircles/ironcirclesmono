import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:permission_handler/permission_handler.dart';

class Permissions {
  /// Check if the user has granted the permission to disable battery optimization
  // static Future<bool> batteryOptimizationGranted(BuildContext context) async {
  //   bool granted =
  //       await Permission.ignoreBatteryOptimizations.request().isGranted;
  //
  //   if (granted) {
  //     return true;
  //   } else {
  //     PermissionStatus permissionStatus =
  //         await Permission.ignoreBatteryOptimizations.request();
  //
  //     if (permissionStatus.isPermanentlyDenied) {
  //       if (context.mounted) {
  //         await askOpenSettings(context);
  //       }
  //     }
  //   }
  //
  //   return false;
  // }

  static Future<bool> imagesGranted(BuildContext context) async {
    return await Permission.photosAddOnly.request().isGranted;
  }

  static Future<bool> askImages(BuildContext context) async {
    var status = await Permission.photos.status;

    //var values = Permission.values;

    if (status.isDenied) {
      //return (await Permission.mediaLibrary.request().isGranted);
      if (context.mounted) {
        await askOpenSettings(context);
      }
    }

    return true;
  }

  static final scaffoldKey = GlobalKey<ScaffoldState>();
  static Future<void> askOpenSettings(
    BuildContext context,
  ) async {
    // flutter defined function
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          surfaceTintColor: Colors.transparent,
          title: Center(
              child: Text(
            "Permissions needed",
            style: TextStyle(color: globalState.theme.bottomIcon),
          )),
          content: const Text(
              "You previously denied permissions to the photos.\n\nWould you like to open app settings and change?"),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog

            TextButton(
              child: Text(
                "Dismiss",
                style: TextStyle(
                    fontSize: 18, color: globalState.theme.bottomIcon),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                "Open App Settings",
                style: TextStyle(
                    fontSize: 18, color: globalState.theme.bottomIcon),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
                //confirmed();
              },
            ),
          ],
        );
      },
    );
  }
}
