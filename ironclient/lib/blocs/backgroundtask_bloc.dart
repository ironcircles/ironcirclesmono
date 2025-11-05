import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/encryption/encryptapitraffic.dart';
import 'package:ironcirclesapp/models/backgroundtask.dart';
import 'package:ironcirclesapp/models/globalstate.dart';
import 'package:ironcirclesapp/models/userfurnace.dart';
import 'package:ironcirclesapp/services/cache/table_backgroundtask.dart';
import 'package:ironcirclesapp/services/cache/table_userfurnace.dart';



class BackgroundTaskBloc{


  static processUpdate(GlobalEventBloc globalEventBloc, TaskUpdate update) async {

    try {
      if (update is TaskStatusUpdate) {
        switch (update.status) {
          case TaskStatus.complete:
            debugPrint('Task complete');

            ///load the background task
            BackgroundTask backgroundTask =
            await TableBackgroundTask.read(update.task.taskId);

            Map<String, dynamic> map =
                await EncryptAPITraffic.decryptJson(update.responseBody!);


            switch(backgroundTask.type){

              case BackgroundTaskType.postCircleObject:


                UserFurnace userFurnace = globalState.userFurnaces.firstWhere((element) => element.pk == backgroundTask.networkID, orElse: () => UserFurnace());

                if (userFurnace.pk !=backgroundTask.networkID ){
                  ///load it from the database
                  userFurnace = await TableUserFurnace.read(backgroundTask.networkID);

                }

                CircleObjectBloc.processPost(globalEventBloc, userFurnace, map, backgroundTask);

                break;

              case BackgroundTaskType.init:
                // TODO: Handle this case.
                break;
              case BackgroundTaskType.putCircleObject:
                // TODO: Handle this case.
                break;
            }
            break;

          case TaskStatus.enqueued:
          // TODO: Handle this case.
            break;
          case TaskStatus.running:
          // TODO: Handle this case.
            break;
          case TaskStatus.notFound:
          // TODO: Handle this case.
            break;
          case TaskStatus.failed:
            debugPrint('Task failed');
          // TODO: Handle this case.
            break;
          case TaskStatus.canceled:
          // TODO: Handle this case.
            break;
          case TaskStatus.waitingToRetry:
            debugPrint('Task waiting to retry');
          // TODO: Handle this case.
            break;
          case TaskStatus.paused:
            debugPrint('Task paused');
          // TODO: Handle this case.
            break;
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace,source: 'App._initBackgroundListener');
    }
  }

  static Future<void> testIsolate() async {
    compute(_testIsolate, '');

  }

}

Future<String> _testIsolate(String param) async {


  ///print number in loop and pause for 2 seconds each time
  for (int i = 0; i < 100000; i++) {
    debugPrint(i.toString());
    await Future.delayed(const Duration(seconds: 2));
  }

  return '';


}
