import 'package:ironcirclesapp/blocs/circlefile_bloc.dart';
import 'package:ironcirclesapp/blocs/circlevideo_bloc.dart';
import 'package:ironcirclesapp/models/album_item.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class ProcessCircleObjectEvents {
  static _putGenericAttributes(
      List<CircleObject> objects, CircleObject circleObject, int index) {
    objects[index].id = circleObject.id;
    objects[index].created = circleObject.created;
    objects[index].secretKey = circleObject.secretKey;
    objects[index].senderRatchetPublic = circleObject.senderRatchetPublic;
    objects[index].crank = circleObject.crank;
    objects[index].signature = circleObject.signature;
    objects[index].ratchetIndexes = circleObject.ratchetIndexes;
  }

  static putCircleRecipe(
      List<CircleObject> objects, CircleObject circleObject) {
    int index = objects.indexWhere((param) => param.seed == circleObject.seed);

    if (index >= 0) {
      objects[index].transferPercent = circleObject.transferPercent;
      objects[index].unstable = circleObject.unstable;
      objects[index].editing = circleObject.editing;

      if (circleObject.transferPercent == 100) {
        //don't overwrite the id
        if (objects[index].id == null) {
          objects[index].recipe = circleObject.recipe;
          //objects[index].image!.id = circleObject.image!.id;
          _putGenericAttributes(objects, circleObject, index);
        }
        objects[index].retries = circleObject.retries;

        if (objects[index].recipe!.image == null) {
          objects[index].thumbnailTransferState = BlobState.READY;
        } else {
          objects[index].recipe!.image!.thumbnailFile =
              circleObject.recipe!.image!.thumbnailFile;
          objects[index].thumbnailTransferState = BlobState.READY;
        }

        // objects[index].recipe!.image!.thumbnailFile =
        //     circleObject.recipe!.image!.thumbnailFile;
        // objects[index].thumbnailTransferState = BlobState.READY;
      } else {
        objects[index].retries = circleObject.retries;
        objects[index].thumbnailTransferState =
            circleObject.thumbnailTransferState;
      }
      objects[index].thumbnailTransferState = BlobState.READY;
    } else {
      objects[index].retries = circleObject.retries;
      objects[index].thumbnailTransferState =
          circleObject.thumbnailTransferState;
    }
  }

  static putCircleImage(
      List<CircleObject> objects, CircleObject circleObject, bool isFull) {
    int index = objects.indexWhere((param) => param.seed == circleObject.seed);

    if (index >= 0) {
      objects[index].transferPercent = circleObject.transferPercent;
      objects[index].unstable = circleObject.unstable;
      objects[index].editing = circleObject.editing;

      if (circleObject.transferPercent == 100) {
        //don't overwrite the id
        if (objects[index].id == null) {
          objects[index].image = circleObject.image;
          DateTime created = objects[index].created!;

          _putGenericAttributes(objects, circleObject, index);
          objects[index].created = created;
        }

        /* if (circleObject.image!.thumbnailSize != null) {
          objects[index].image!.thumbnailSize =
              circleObject.image!.thumbnailSize;
          objects[index].image!.fullImageSize =
              circleObject.image!.fullImageSize;
          objects[index].image!.height = circleObject.image!.height;
          objects[index].image!.width = circleObject.image!.width;
        }

        */

        if (isFull) {
          objects[index].nonUIRetries = circleObject.nonUIRetries;

          objects[index].image!.fullImage = circleObject.image!.fullImage;

          objects[index].fullTransferState = BlobState.READY;
        } else {
          objects[index].retries = circleObject.retries;

          objects[index].image!.thumbnailFile =
              circleObject.image!.thumbnailFile;
          objects[index].thumbnailTransferState = BlobState.READY;
        }
      } else {
        if (isFull) {
          objects[index].nonUIRetries = circleObject.nonUIRetries;
          objects[index].fullTransferState = circleObject.fullTransferState;
        } else {
          objects[index].retries = circleObject.retries;
          objects[index].thumbnailTransferState =
              circleObject.thumbnailTransferState;
        }
      }
    }
  }

  static putCircleAlbum(
      List<CircleObject> objects, CircleObject circleObject, bool isFull) {
    int index = objects.indexWhere((param) => param.seed == circleObject.seed);

    if (index >= 0) {
      objects[index].transferPercent = circleObject.transferPercent;

      if (circleObject.transferPercent == 100) {
        //don't overwrite the id
        if (objects[index].id == null) {
          //objects[index].image = circleObject.image;
          _putGenericAttributes(objects, circleObject, index);
        }
      } else {
        if (isFull) {
          objects[index].fullTransferState = circleObject.fullTransferState;
        } else {
            objects[index].thumbnailTransferState =
                circleObject.thumbnailTransferState;
          }
      }
    }
  }

  static putCircleVideo(List<CircleObject> objects, CircleObject circleObject,
      CircleVideoBloc circleVideoBloc) {
    int index = objects.indexWhere((param) => param.seed == circleObject.seed);

    if (index >= 0) {
      //objects[index] = circleObject;

      if (circleObject.id != null) {
        objects[index].video = circleObject.video;

        DateTime created = objects[index].created!;

        _putGenericAttributes(objects, circleObject, index);
        objects[index].created = created;

        objects[index].retries = circleObject.retries;

        objects[index].thumbnailTransferState =
            circleObject.thumbnailTransferState;
        objects[index].fullTransferState = circleObject.fullTransferState;
        objects[index].transferPercent = circleObject.transferPercent;
        //objects[index].thumbnailTransferState = BlobState.READY;
        //objects[index].fullTransferState = BlobState.READY;
      } else {
        objects[index] = circleObject;
      }

      if (circleObject.transferPercent == 100) {
        circleVideoBloc.cleanCache([], circleObject);
      }
    }
  }

  static putAlbumVideo(CircleObject circleObject, AlbumItem item, CircleVideoBloc circleVideoBloc) {
    int index = circleObject.album!.media!.indexWhere((param) => param.id == item.id);

    if (index >= 0) {
      if (item.id != null) {
        circleObject.album!.media[index].video = item.video;

        //DateTime created = circleObject.album!.media[index].created!;

        circleObject.album!.media[index].thumbnailTransferState = item.thumbnailTransferState;
        circleObject.album!.media[index].fullTransferState = item.fullTransferState;
        //circleObject.album!.media[index].transferPercent;
      } else {
        circleObject.album!.media![index] = item;
      }

      // if (circleObject.transferPercent == 100) {
      //   circleVideoBloc.cleanCache([], circleObject);
      // }
    }
  }

  static putCircleFile(List<CircleObject> objects, CircleObject circleObject,
      CircleFileBloc circleFileBloc) {
    int index = objects.indexWhere((param) => param.seed == circleObject.seed);

    if (index >= 0) {
      //objects[index] = circleObject;

      if (circleObject.id != null) {
        objects[index].file = circleObject.file;

        DateTime created = objects[index].created!;

        _putGenericAttributes(objects, circleObject, index);
        objects[index].created = created;

        objects[index].retries = circleObject.retries;
        objects[index].transferPercent = circleObject.transferPercent;
      } else {
        objects[index] = circleObject;
      }

      if (circleObject.transferPercent == 100) {
        objects[index].fullTransferState = BlobState.READY;
        circleFileBloc.cleanCache([], circleObject);
      }
    }
  }
}
