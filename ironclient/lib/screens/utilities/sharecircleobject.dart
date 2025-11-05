import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/encryption/encryptblob.dart';
import 'package:ironcirclesapp/models/album_item.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/filecache_service.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
import 'package:ironcirclesapp/services/cache/videocache_service.dart';
import 'package:ironcirclesapp/services/tenor_service.dart';
import 'package:share_plus/share_plus.dart';

class ShareCircleObject {
  static void shareToDestination(
    BuildContext context,
    UserCircleCache userCircleCache,
    CircleObject circleObject,
    bool inside,
  ) async {
    try {
      if (circleObject.type == CircleObjectType.CIRCLEFILE) {
        if (inside) {
          MediaCollection mediaCollection = MediaCollection();
          mediaCollection.add(
            Media(
              path: FileCacheService.returnFilePath(
                userCircleCache.circlePath!,
                '${circleObject.seed!}.${circleObject.file!.extension!}',
              ),
              mediaType: MediaType.file,
            ),
          );

          globalState.globalEventBloc.broadcastPopToHomeAndOpenShare(
            SharedMediaHolder(message: '', sharedMedia: mediaCollection),
          );
          // Navigator.pushAndRemoveUntil(
          //     context,
          //     MaterialPageRoute(
          //         builder: (context) =>
          //             ReceiveShare(sharedMedia: mediaCollection)),
          //     ModalRoute.withName("/home"));
        } else {
          String internalPath = FileCacheService.returnFilePath(
            userCircleCache.circlePath!,
            '${circleObject.seed!}.${circleObject.file!.extension!}',
          );

          String externalPath = internalPath;
          File internal = File(internalPath);
          XFile externalX = XFile(internalPath);

          int sizeInBytes = File(internalPath).lengthSync();
          double sizeInMb = sizeInBytes / (1024 * 1024);

          if (sizeInMb < 15) {
            File external = File(
              FileCacheService.returnFilePath(
                userCircleCache.circlePath!,
                circleObject.file!.name!,
              ),
            );
            externalX = XFile(external.path);

            internal.copy(external.path);

            externalPath = external.path;
          }
          Share.shareXFiles([externalX]);
        }
      } else if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
        if (inside) {
          MediaCollection mediaCollection = MediaCollection();
          mediaCollection.add(
            Media(
              storageID: circleObject.storageID ?? '',
              path: VideoCacheService.returnVideoPath(
                circleObject,
                userCircleCache.circlePath!,
                circleObject.video!.extension!,
              ),
              mediaType: MediaType.video,
            ),
          );

          globalState.globalEventBloc.broadcastPopToHomeAndOpenShare(
            SharedMediaHolder(message: '', sharedMedia: mediaCollection),
          );

          // Navigator.pushAndRemoveUntil(
          //     context,
          //     MaterialPageRoute(
          //         builder: (context) =>
          //             ReceiveShare(sharedMedia: mediaCollection)),
          //     ModalRoute.withName("/home"));
        } else {
          if (Platform.isMacOS) {
            ///the file has an extension of .enc
            String encPath = VideoCacheService.returnVideoPath(
              circleObject,
              userCircleCache.circlePath!,
              circleObject.video!.extension!,
            );

            String copyPath = encPath.replaceAll(
              // ".enc", ".${circleObject.video!.extension!}");
              ".enc",
              ".mp4",
            );

            if (circleObject.video!.streamableCached == true) {
              File enc = File(encPath);
              enc.copy(copyPath);
            } else {
              ///decrypt the video
              await EncryptBlob.decryptBlobToFile(
                DecryptArguments(
                  encrypted: circleObject.video!.videoFile!,
                  nonce: circleObject.video!.fullCrank!,
                  mac: circleObject.video!.fullSignature!,
                  key: circleObject.secretKey,
                ),
                copyPath,
              );
            }

            await Share.shareXFiles([XFile(copyPath)], text: circleObject.body);

            File copy = File(copyPath);

            ///wait 30 seconds then delete
            Future.delayed(const Duration(seconds: 30), () {
              copy.delete();
            });
          } else {
            Share.shareXFiles([
              XFile(
                VideoCacheService.returnVideoPath(
                  circleObject,
                  userCircleCache.circlePath!,
                  circleObject.video!.extension!,
                ),
              ),
            ], text: circleObject.body);
          }
        }
      } else if (circleObject.type == CircleObjectType.CIRCLEIMAGE) {
        if (inside) {
          MediaCollection mediaCollection = MediaCollection();
          mediaCollection.add(
            Media(
              object: circleObject,
              storageID: circleObject.storageID ?? '',
              path: ImageCacheService.returnFullImagePath(
                userCircleCache.circlePath!,
                circleObject,
              ),
              mediaType: MediaType.image,
            ),
          );

          globalState.globalEventBloc.broadcastPopToHomeAndOpenShare(
            SharedMediaHolder(message: '', sharedMedia: mediaCollection),
          );

          // Navigator.pushAndRemoveUntil(
          //     context,
          //     MaterialPageRoute(
          //         builder: (context) =>
          //             ReceiveShare(sharedMedia: mediaCollection)),
          //     ModalRoute.withName("/home"));
        } else {
          Share.shareXFiles([
            XFile(
              ImageCacheService.returnFullImagePath(
                userCircleCache.circlePath!,
                circleObject,
              ),
            ),
          ], text: circleObject.body);
        }
      } else if (circleObject.type == 'circlegif') {
        GiphyOption giphyOption = GiphyOption(
          height: circleObject.gif!.height,
          width: circleObject.gif!.width,
          url: circleObject.gif!.giphy!,
          preview: circleObject.gif!.giphy!,
        );

        if (inside) {
          globalState.globalEventBloc.broadcastPopToHomeAndOpenShare(
            SharedMediaHolder(message: '', sharedGif: giphyOption),
          );
          // Navigator.pushAndRemoveUntil(
          //     context,
          //     MaterialPageRoute(
          //         builder: (context) => ReceiveShare(
          //               sharedGif: giphyOption,
          //             )),
          //     ModalRoute.withName("/home"));
        } else {
          Share.share(circleObject.gif!.giphy!);
        }
      } else if (circleObject.type == CircleObjectType.CIRCLERECIPE) {
        MediaCollection recipe = MediaCollection();
        CircleObject shareObject = CircleObject(ratchetIndexes: []);
        shareObject.recipe = CircleRecipe.deepCopy(circleObject.recipe!);

        if (circleObject.recipe!.image != null) {
          shareObject.recipe!.image!.thumbnailFile = File(
            ImageCacheService.returnThumbnailPath(
              userCircleCache.circlePath!,
              circleObject,
            ),
          );
        }

        recipe.add(Media(mediaType: MediaType.recipe, object: shareObject));

        if (inside) {
          globalState.globalEventBloc.broadcastPopToHomeAndOpenShare(
            SharedMediaHolder(message: '', sharedMedia: recipe),
          );
          // Navigator.pushAndRemoveUntil(
          //     context,
          //     MaterialPageRoute(
          //         builder: (context) => ReceiveShare(
          //               sharedMedia: recipe,
          //             )),
          //     ModalRoute.withName("/home"));
        }
      } else if (circleObject.type == CircleObjectType.CIRCLELIST) {
        MediaCollection list = MediaCollection();
        CircleObject shareObject = CircleObject(ratchetIndexes: []);
        shareObject.list = CircleList.deepCopy(circleObject.list!);

        list.add(Media(mediaType: MediaType.list, object: shareObject));

        if (inside) {
          globalState.globalEventBloc.broadcastPopToHomeAndOpenShare(
            SharedMediaHolder(message: '', sharedMedia: list),
          );
          // Navigator.pushAndRemoveUntil(
          //     context,
          //     MaterialPageRoute(
          //         builder: (context) => ReceiveShare(
          //               sharedMedia: list,
          //             )),
          //     ModalRoute.withName("/home"));
        }
      } else if (circleObject.subType == SubType.LOGIN_INFO) {
        MediaCollection credential = MediaCollection();
        CircleObject shareObject = CircleObject(ratchetIndexes: []);
        shareObject.circle = circleObject.circle;
        shareObject.subType = circleObject.subType;
        shareObject.body =
            circleObject.body; // Include JSON data for custom fields
        shareObject.subString1 = circleObject.subString1;
        shareObject.subString2 = circleObject.subString2;
        shareObject.subString3 = circleObject.subString3;
        shareObject.subString4 = circleObject.subString4;

        credential.add(
          Media(mediaType: MediaType.credential, object: shareObject),
        );

        if (inside) {
          globalState.globalEventBloc.broadcastPopToHomeAndOpenShare(
            SharedMediaHolder(message: '', sharedMedia: credential),
          );
          // Navigator.pushAndRemoveUntil(
          //     context,
          //     MaterialPageRoute(
          //         builder: (context) => ReceiveShare(
          //               sharedMedia: credential,
          //             )),
          //     ModalRoute.withName("/home"));
        }
      } else if (circleObject.type == "circleevent") {
        MediaCollection event = MediaCollection();
        CircleObject shareObject = CircleObject(ratchetIndexes: []);
        shareObject.event = CircleEvent.deepCopyForShare(circleObject.event!);

        event.add(Media(mediaType: MediaType.event, object: shareObject));

        if (inside) {
          globalState.globalEventBloc.broadcastPopToHomeAndOpenShare(
            SharedMediaHolder(message: '', sharedMedia: event),
          );
          // Navigator.pushAndRemoveUntil(
          //     context,
          //     MaterialPageRoute(
          //         builder: (context) => ReceiveShare(
          //               sharedMedia: event,
          //             )),
          //     ModalRoute.withName("/home"));
        }
      } else if (circleObject.type == 'circlealbum') {
        ///used for sharing individual items from album
        if (circleObject.image != null) {
          if (inside) {
            MediaCollection mediaCollection = MediaCollection();
            mediaCollection.add(
              Media(
                storageID: circleObject.storageID ?? '',
                path: ImageCacheService.returnExistingAlbumImagePath(
                  userCircleCache.circlePath!,
                  circleObject,
                  circleObject.image!.fullImage!,
                ),
                mediaType: MediaType.image,
              ),
            );

            globalState.globalEventBloc.broadcastPopToHomeAndOpenShare(
              SharedMediaHolder(message: '', sharedMedia: mediaCollection),
            );
          } else {
            Share.shareXFiles([
              XFile(
                ImageCacheService.returnExistingAlbumImagePath(
                  userCircleCache.circlePath!,
                  circleObject,
                  circleObject.image!.fullImage!,
                ),
              ),
            ], text: circleObject.body);
          }
        } else if (circleObject.video != null) {
          if (inside) {
            MediaCollection mediaCollection = MediaCollection();
            mediaCollection.add(
              Media(
                storageID: circleObject.storageID ?? '',
                path: VideoCacheService.returnExistingAlbumVideoPath(
                  userCircleCache.circlePath!,
                  circleObject,
                  circleObject.video!.video!,
                ),
                mediaType: MediaType.video,
                thumbnail: VideoCacheService.returnExistingAlbumVideoPath(
                  userCircleCache.circlePath!,
                  circleObject,
                  circleObject.video!.preview!,
                ),
              ),
            );

            globalState.globalEventBloc.broadcastPopToHomeAndOpenShare(
              SharedMediaHolder(message: '', sharedMedia: mediaCollection),
            );
          } else {
            Share.shareXFiles([
              XFile(
                VideoCacheService.returnExistingAlbumVideoPath(
                  userCircleCache.circlePath!,
                  circleObject,
                  circleObject.video!.video!,
                ),
              ),
            ], text: circleObject.body);
          }
        } else if (circleObject.gif != null) {
          GiphyOption giphyOption = GiphyOption(
            height: circleObject.gif!.height,
            width: circleObject.gif!.width,
            url: circleObject.gif!.giphy!,
            preview: circleObject.gif!.giphy!,
          );

          if (inside) {
            globalState.globalEventBloc.broadcastPopToHomeAndOpenShare(
              SharedMediaHolder(message: '', sharedGif: giphyOption),
            );
          } else {
            Share.share(circleObject.gif!.giphy!);
          }
        } else if (circleObject.album != null) {
          ///used for sharing entire album (from inside circle, etc)
          if (inside) {
            MediaCollection mediaCollection = MediaCollection();
            List<AlbumItem> loop = List.from(circleObject.album!.media);
            loop.sort((a, b) => a.index.compareTo(b.index));
            for (AlbumItem item in loop) {
              if (item.removeFromCache == false) {
                if (item.type == AlbumItemType.IMAGE) {
                  mediaCollection.add(
                    Media(
                      storageID: circleObject.storageID ?? '',
                      path: ImageCacheService.returnExistingAlbumImagePath(
                        userCircleCache.circlePath!,
                        circleObject,
                        item.image!.fullImage!,
                      ),
                      mediaType: MediaType.image,
                    ),
                  );
                } else if (item.type == AlbumItemType.VIDEO) {
                  mediaCollection.add(
                    Media(
                      storageID: circleObject.storageID ?? '',
                      path: VideoCacheService.returnExistingAlbumVideoPath(
                        userCircleCache.circlePath!,
                        circleObject,
                        item.video!.video!,
                      ),
                      mediaType: MediaType.video,
                      thumbnail: VideoCacheService.returnExistingAlbumVideoPath(
                        userCircleCache.circlePath!,
                        circleObject,
                        item.video!.preview!,
                      ),
                    ),
                  );
                } else if (item.type == AlbumItemType.GIF) {
                  mediaCollection.add(
                    Media(
                      path: item.gif!.giphy!,
                      height: item.gif!.height!,
                      width: item.gif!.width!,
                      mediaType: MediaType.gif,
                      thumbnail: item.gif!.giphy!,
                    ),
                  );
                }
              }
            }
            globalState.globalEventBloc.broadcastPopToHomeAndOpenShare(
              SharedMediaHolder(message: '', sharedMedia: mediaCollection),
            );
          } else {
            List<XFile> files = [];
            for (AlbumItem item in circleObject.album!.media) {
              if (item.type == AlbumItemType.IMAGE) {
                files.add(
                  XFile(
                    ImageCacheService.returnExistingAlbumImagePath(
                      userCircleCache.circlePath!,
                      circleObject,
                      circleObject.image!.fullImage!,
                    ),
                  ),
                );
              } else if (item.type == AlbumItemType.VIDEO) {
                files.add(
                  XFile(
                    VideoCacheService.returnExistingAlbumVideoPath(
                      userCircleCache.circlePath!,
                      circleObject,
                      circleObject.video!.video!,
                    ),
                  ),
                );
              } else if (item.type == AlbumItemType.GIF) {
                files.add(XFile(item.gif!.giphy!));
              }
            }
            Share.shareXFiles(files, text: circleObject.body);
          }
        }
      } else {
        String? text;

        if (circleObject.type == 'circlemessage') {
          text = circleObject.body;
        } else if (circleObject.type == 'circlelink') {
          text = circleObject.link!.url;
        }

        if (text != null) {
          if (inside) {
            globalState.globalEventBloc.broadcastPopToHomeAndOpenShare(
              SharedMediaHolder(message: '', sharedText: text),
            );
            // Navigator.pushAndRemoveUntil(
            //     context,
            //     MaterialPageRoute(
            //         builder: (context) => ReceiveShare(
            //               sharedText: text,
            //             )),
            //     ModalRoute.withName("/home"));
          } else {
            Share.share(text);
          }
        }
      }
    } catch (e) {
      debugPrint('_shareObject: $e');
    }
  }
}

class ShareCircleObjects {
  static void shareToDestination(
    BuildContext context,
    //UserCircleCache userCircleCache,
    List<CircleObject> circleObjects,
    bool inside,
  ) async {
    try {
      if (inside) {
        MediaCollection mediaCollection = MediaCollection();

        mediaCollection.populateFromCircleObjects(circleObjects);

        globalState.globalEventBloc.broadcastPopToHomeAndOpenShare(
          SharedMediaHolder(message: '', sharedMedia: mediaCollection),
        );
      } else {
        List<String> filePaths = [];
        List<XFile> files = [];
        bool foundFile = false;
        bool foundURL = false;

        //get list of file paths
        for (CircleObject circleObject in circleObjects) {
          String circlePath = '';

          if (circleObject.userCircleCache!.circlePath != null)
            circlePath = circleObject.userCircleCache!.circlePath!;
          else
            circlePath = await FileSystemService.returnCirclesDirectory(
              circleObject.creator!.id!,
              circleObject.circle!.id!,
            );

          if (circleObject.type == CircleObjectType.CIRCLEIMAGE) {
            if (!foundURL) {
              filePaths.add(
                ImageCacheService.returnFullImagePath(circlePath, circleObject),
              );
              files.add(
                XFile(
                  ImageCacheService.returnFullImagePath(
                    circlePath,
                    circleObject,
                  ),
                ),
              );
              foundFile = true;
            }
          } else if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
            if (!foundURL) {
              filePaths.add(
                VideoCacheService.returnVideoPath(
                  circleObject,
                  circlePath,
                  'mp4',
                ),
              );
              files.add(
                XFile(
                  VideoCacheService.returnVideoPath(
                    circleObject,
                    circlePath,
                    'mp4',
                  ),
                ),
              );
              foundFile = true;
            }
          } else if (circleObject.type == CircleObjectType.CIRCLEGIF) {
            if (!foundFile) {
              filePaths.add(circleObject.gif!.giphy!);
              files.add(XFile(circleObject.gif!.giphy!));
              foundURL = true;
            }
          } else if (circleObject.type == CircleObjectType.CIRCLELINK) {
            if (!foundFile) {
              filePaths.add(circleObject.link!.url!);
              foundURL = true;
            }
          }
        }

        if (foundURL) {
          Share.share(filePaths[0]);
        } else {
          Share.shareXFiles(files);
        }
      }
    } catch (e) {
      debugPrint('_shareObject: $e');
    }

    // setState(() {
    //  if (_lastSelected != null) _lastSelected!.showOptionIcons = false;
    //});
  }
}
