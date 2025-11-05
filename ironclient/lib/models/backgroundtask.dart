import 'dart:io';

import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/table_backgroundtask.dart';

enum BackgroundTaskType { init, postCircleObject, putCircleObject }

enum BackgroundTaskStatus { init, pending, complete }

class BackgroundTask {
  int? pk;
  String taskID;
  int networkID;
  String circleID;
  String userCircleID;
  String userID;
  String seed;
  String path;
  BackgroundTaskType type;
  BackgroundTaskStatus status;

  BackgroundTask({
    this.pk,
    this.taskID = '',
    this.networkID = -1,
    this.path = '',
    this.circleID = '',
    this.userCircleID = '',
    this.userID = '',
    this.seed = '',
    this.type = BackgroundTaskType.init,
    this.status = BackgroundTaskStatus.init,
  });

  factory BackgroundTask.fromJson(Map<String, dynamic> json) => BackgroundTask(
        pk: json['pk'],
        taskID: json['taskID'],
        path: json['path'],
        networkID: json['networkID'],
        circleID: json['circleID'],
        userCircleID: json['userCircleID'],
        userID: json['userID'],
        seed: json['seed'],
        type: BackgroundTaskType.values.elementAt(json['type']),
        status: BackgroundTaskStatus.values.elementAt(json['status']),
      );

  Map<String, dynamic> toJson() => {
        //'pk': pk,
        'taskID': taskID,
        'path': path,
        'networkID': networkID,
        'circleID': circleID,
        'userCircleID': userCircleID,
        'userID': userID,
        'seed': seed,
        'type': type.index,
        'status': status.index,
      };

  markComplete() async {
    status = BackgroundTaskStatus.complete;
    await TableBackgroundTask.upsert(this);

    if (path.isNotEmpty) {
      await FileSystemService.safeDelete(File(path));
    }
  }
}

class BackgroundTaskCollection {
  final List<BackgroundTask> tasks;

  BackgroundTaskCollection.fromJSON(Map<String, dynamic> json)
      : tasks = (json as List)
            .map((json) => BackgroundTask.fromJson(json))
            .toList();
}
