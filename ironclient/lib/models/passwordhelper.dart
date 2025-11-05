import 'dart:convert';

import 'package:ironcirclesapp/models/export_models.dart';

///User for password and remote wipe users
UserHelper passwordHelperFromJson(String str) =>
    UserHelper.fromJson(json.decode(str));


class UserHelper /*extends CircleObject*/ {
  List<User>? helpers;
  List<User>? members;

  //bool userVoted = false;

  UserHelper(
      {this.helpers,
        this.members,
});

  factory UserHelper.fromJson(Map<String, dynamic> json) => UserHelper(

    helpers: json["helpers"] == null
        ? null
        : UserCollection.fromJSON(json, "helpers").users,

    members: json["members"] == null
        ? null
        : UserCollection.fromJSON(json, "members").users,


  );

  Map<String, dynamic> toJson() => {
    "helpers": helpers == null
        ? null
        : List<dynamic>.from(helpers!.map((x) => x)),
  };

/*
  addNewTask() {
    CircleListTask circleListTask = CircleListTask(
        complete: false,
        expanded: false,
        order: tasks.length + 1,
        controller: TextEditingController());

    tasks.add(circleListTask);

    sortList();
  }
*/
  /*
  sortList() {
    List<CircleListTask> complete = tasks.sublist(0, tasks.length);

    debugPrint('breakpoint');

    //remove not completed tasks from the sublist
    complete.removeWhere((element) => element.complete != true);

    debugPrint('breakpoint');
    //remove completed tasks from master list
    tasks.removeWhere((element) => element.complete == true);

    debugPrint('breakpoint');

    //sort the master list by order
    tasks.sort((a, b) => a.order.compareTo(b.order));
    //widget.circleObject.list.tasks.sort((a, b) => a.created.compareTo(b.created));

    debugPrint('breakpoint');

    //sort the sublist by order
    //complete.sort((a, b) => a.completed.compareTo(b.completed));
    complete.sort((a, b) => a.order.compareTo(b.order));

    //add the sublist to the end of the master list
    for (CircleListTask circleListTask in complete) {
      tasks.add(circleListTask);
    }

    debugPrint('breakpoint');
  }
*/

}
