import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/table_circlelastlocalupdate.dart';
import 'package:ironcirclesapp/services/cache/table_circleobject.dart';

class CacheBloc {
  static clearCircleCache(
      GlobalEventBloc globalEventBloc,
      UserCircleCache userCircleCache,
      String circleID,
      String circlePath) async {
    globalEventBloc.removeObjectsForCircle(circleID);

    //CircleLastUpdate.delete(userCircleCache.circle!);

    await FileSystemService.deleteCircleCache(circlePath);

    await TableCircleObjectCache.deleteAllForCircle(circleID);
    await TableCircleLastLocalUpdate.delete(circleID);
    //await TableUserCircleEnvelope.deleteByID(userCircleCache.usercircle!, userCircleCache.user!);
    //await TableUserCircleCache.deleteByID(userCircleCache.usercircle!);

    var db = await DatabaseProvider.db.database;
    await db!.execute("DROP VIEW ${TableCircleObjectCache.byCircleIDView}");
    await db.execute("CREATE VIEW ${TableCircleObjectCache.byCircleIDView} AS SELECT ${TableCircleObjectCache.pk}, ${TableCircleObjectCache.circleid}, ${TableCircleObjectCache.circleObjectid}, ${TableCircleObjectCache.pinned}, ${TableCircleObjectCache.draft}, ${TableCircleObjectCache.read}, ${TableCircleObjectCache.circleObjectJson}, ${TableCircleObjectCache.seed}, ${TableCircleObjectCache.type}, ${TableCircleObjectCache.creator}, ${TableCircleObjectCache.thumbnailTransferState}, ${TableCircleObjectCache.fullTransferState}, ${TableCircleObjectCache.created}, ${TableCircleObjectCache.lastUpdate}, ${TableCircleObjectCache.retryDecrypt} FROM ${TableCircleObjectCache.tableName} ORDER BY ${TableCircleObjectCache.created} DESC");

    return;
  }
}
