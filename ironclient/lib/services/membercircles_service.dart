import 'dart:async';

import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/table_membercircle.dart';

class MemberCircleService {
  static Future<List<MemberCircle>> getForCircles(
      List<UserCircleCache> userCircleCaches) async {
    ///get list of users for connected furnaces
    return await TableMemberCircle.getForCircles(userCircleCaches);
  }

  static Future<void> upsert(MemberCircle memberCircle) async {
    ///get list of users for connected furnaces
    await TableMemberCircle.upsert(memberCircle);

    return;
  }

  static Future<void> deleteAllForCircle(String circleID) async {
    ///get list of users for connected furnaces
    await TableMemberCircle.deleteAllForCircle(circleID);

    return;
  }


}
