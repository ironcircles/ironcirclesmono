import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:uuid/uuid.dart';

CircleList circleListFromJson(String str) =>
    CircleList.fromJson(json.decode(str));

String circleListToJson(CircleList data) => json.encode(data.toJson());

class CircleList /*extends CircleObject*/ {
  String? name;
  bool complete = false;
  DateTime? lastUpdate;
  DateTime? created;
  bool checkable = true;
  String? template;
  User? lastEdited;

//  int itemChecked;
  List<CircleListTask>? tasks = [];
  List<CircleListTask> tempCompleted = [];
  //bool userVoted = false;

  CircleList({
    this.name,
    required this.complete,
    this.tasks,
    this.lastUpdate,
    this.created,
    required this.checkable,
    this.template,
    this.lastEdited,
  });

  factory CircleList.fromJson(Map<String, dynamic> json) => CircleList(
        name: json["name"],
        template: json["template"],
        lastEdited: json["lastEdited"] == null
            ? null
            : User.fromJson(json["lastEdited"]),
        tasks: json["tasks"] == null
            ? null
            : CircleListTaskCollection.fromJSON(json, "tasks").circleListTasks,
        lastUpdate: json["lastUpdate"] == null
            ? null
            : DateTime.parse(json["lastUpdate"]).toLocal(),
        created: json["created"] == null
            ? null
            : DateTime.parse(json["created"]).toLocal(),
        complete: json["complete"] ? true : false,
        checkable: json["checkable"] == null
            ? true
            : json["checkable"]
                ? true
                : false,
        //userVoted: options.u

        //options: List<CircleVoteOption>.from(json["options"].map((x) => x)),
      );

  static CircleList deepCopy(CircleList circleList) {
    return CircleList(
        name: circleList.name,
        template: circleList.template,
        complete: circleList.complete,
        checkable: circleList.checkable,
        //tasks: List.from(circleList.tasks),
        tasks: circleList.tasks == null
            ? null
            : CircleListTask.deepCopyTasks(circleList.tasks!),
        lastUpdate: circleList.lastUpdate,
        created: circleList.created);
  }

  static bool deepCompareChanged(CircleList a, CircleList b) {
    if (a.name != null && a.name!.isNotEmpty && a.name != b.name)
      return true;
    else if (b.name != null && b.name!.isNotEmpty && a.name != b.name)
      return true;
    else if ((a.complete != b.complete))
      return true;
    else if ((a.checkable != b.checkable))
      return true;
    else {
      return CircleListTask.deepCompareChanged(a.tasks, b.tasks);
    }
  }

  /*
  factory CircleList.deepCopy(CircleList circleList) => CircleList(
        name: circleList.name,
        complete: circleList.complete,
        tasks: List.from(circleList.tasks),
    //tasks: _deepCopyTasks(circleList.tasks);
      );
*/

  mapDecryptedFields(Map<String, dynamic> json) {
    name = json["list"]["name"];

    for (CircleListTask task in tasks!) {
      task.name = json["list"]["tasks"][task.seed];
    }
  }

  void blankEncryptionFields() {
    name = '';

    for (CircleListTask task in tasks!) {
      task.name = '';
    }
  }

  void revertEncryptionFields(CircleList original) {
    name = original.name;

    for (CircleListTask encryptedTask in tasks!) {
      for (CircleListTask originalTask in original.tasks!) {
        if (originalTask.seed == encryptedTask.seed) {
          encryptedTask.name = originalTask.name;
          break;
        }
      }
    }
  }

  Map<String, dynamic> fetchFieldsToEncrypt() {
    try {
      //set the seed value as we are about to remove the list and task names
      Map<String, dynamic> retValue = <String, dynamic>{};

      retValue["name"] = name;

      Map<String, dynamic> reducedTasks = <String, dynamic>{};

      for (CircleListTask task in tasks!) {
        reducedTasks[task.seed!] = task.name;
      }

      retValue["tasks"] = reducedTasks;

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleList.fetchFieldsToEncrypt: ${err.toString()}');
      throw Exception(err);
    }
  }

  static CircleList initFromTemplate(CircleListTemplate circleListMaster) {
    late CircleList circleList;

    if (circleListMaster.id == null) {
      circleList = CircleList(complete: false, checkable: true, tasks: []);
    } else {
      circleList = CircleList(
          checkable: circleListMaster.checkable,
          complete: false,
          template: circleListMaster.id,
          name: circleListMaster.name,
          tasks:
              CircleListTask.initFromTemplateTaskList(circleListMaster.tasks!));
    }

    circleList.initUIControls();

    return circleList;
  }

  ingestDeepCopy(CircleList circleList) {
    name = circleList.name;
    complete = circleList.complete;
    tasks = circleList.tasks;
    lastUpdate = circleList.lastUpdate;
    created = circleList.created;
    checkable = circleList.checkable;
  }

  Map<String, dynamic> toJson() => {
        "name": name,
        "complete": complete,
        "checkable": checkable,
        "template": template,
        "lastEdited": lastEdited?.toJson(),
        "tasks":
            tasks == null ? null : List<dynamic>.from(tasks!.map((x) => x)),
        "created": created?.toUtc().toString(),
        "lastUpdate":
            lastUpdate?.toUtc().toString(),
      };

  initUIControls() {
    tasks ??= [];
    for (CircleListTask circleListTask in tasks!) {
      circleListTask.controller =
          TextEditingController(text: circleListTask.name);
      circleListTask.focusNode = FocusNode();

      if (circleListTask.assignee != null || circleListTask.due != null)
        circleListTask.expanded = true;
      else
        circleListTask.expanded = false;
    }
  }

  CircleListTask addNewTask() {
    tasks ??= [];

    CircleListTask circleListTask = CircleListTask(
        seed: const Uuid().v4(),
        complete: false,
        expanded: false,
        order: tasks!.length + 1,
        controller: TextEditingController(),
        focusNode: FocusNode());

    tasks!.add(circleListTask);

    return circleListTask;
  }

  addAboveIndex(int index) {
    CircleListTask circleListTask = CircleListTask(
        complete: false,
        expanded: false,
        order: index + 1,
        controller: TextEditingController(),
        focusNode: FocusNode());

    //bump the order on everything higher in the list
    for (int i = 0; i < tasks!.length; i++) {
      if (i >= index) {
        tasks![i].order++;
      }
    }

    tasks!.insert(index, circleListTask);

    sortList();
  }

  sortTop() {
    tempCompleted = tasks!.sublist(0, tasks!.length);
    tempCompleted.removeWhere((element) => element.complete != true);

    tasks!.removeWhere((element) => element.complete == true);
    tasks!.sort((a, b) => a.order.compareTo(b.order));
  }

  sortBottom() {
    tempCompleted.sort((a, b) => a.order.compareTo(b.order));

    //add the sublist to the end of the master list
    for (CircleListTask circleListTask in tempCompleted) {
      tasks!.add(circleListTask);
    }
  }

  sortListByCompleted() {
    List<CircleListTask> complete = tasks!.sublist(0, tasks!.length);

    //debugPrint('breakpoint');

    //remove not completed tasks from the sublist
    complete.removeWhere((element) => element.complete != true);

    //debugPrint('breakpoint');
    //remove completed tasks from master list
    tasks!.removeWhere((element) => element.complete == true);

    //debugPrint('breakpoint');

    //sort the master list by order
    tasks!.sort((a, b) => a.order.compareTo(b.order));
    //widget.circleObject.list.tasks.sort((a, b) => a.created.compareTo(b.created));

    //debugPrint('breakpoint');

    //sort the sublist by order
    //complete.sort((a, b) => a.completed.compareTo(b.completed));
    complete.sort((a, b) => b.completed!.compareTo(a.completed!));

    //add the sublist to the end of the master list
    for (CircleListTask circleListTask in complete) {
      tasks!.add(circleListTask);
    }

    //debugPrint('breakpoint');
  }

  setOrder(CircleList subList) {
    for (CircleListTask circleListTask in tasks!) {
      int index = subList.tasks!
          .indexWhere((element) => element.seed == circleListTask.seed);

      circleListTask.order = tasks!.indexOf(circleListTask) + 1;

      if (index != -1) {
        subList.tasks![index].order = circleListTask.order;
      }
    }
  }

  sortList() {
    /*
    List<CircleListTask> complete = tasks!.sublist(0, tasks!.length);

    debugPrint('hit sortList');

    ///remove not completed tasks from the sublist
    complete.removeWhere((element) => (element.originalComplete == null || element.originalComplete == false));

    debugPrint('only complete');

    ///remove completed tasks from master list
    tasks!.removeWhere((element) => element.complete == true && element.originalComplete == true);

    debugPrint('only not complete');

    //sort the master list by order
    tasks!.sort((a, b) => a.order.compareTo(b.order));
    //widget.circleObject.list.tasks.sort((a, b) => a.created.compareTo(b.created));

    //debugPrint('breakpoint');

    //sort the sublist by order
    //complete.sort((a, b) => a.completed.compareTo(b.completed));
    complete.sort((a, b) => a.order.compareTo(b.order));

    //add the sublist to the end of the master list
    for (CircleListTask circleListTask in complete) {
      tasks!.add(circleListTask);
    }

    //debugPrint('breakpoint');

     */

    tasks!.sort((a, b) => a.order.compareTo(b.order));
  }

  disposeUIControls() {
    for (CircleListTask circleListTask in tasks!) {
      if (circleListTask.controller != null)
        circleListTask.controller!.dispose();
    }
  }

  /*
  List<String> getOptions() {
    List<String> optionsList = [];

    for (CircleVoteOption circleVoteOption in options) {
      optionsList.add(circleVoteOption.option);
    }

    return optionsList;
  }
  */
}

/*

{
    "question": "",
    "voteType":"" ,
    "model": "" ,
    "open": false,
    "itemChecked":0,
    "options": [""]
}





 */
