import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/album_item.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/table_circleobject.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';
import 'package:ironcirclesapp/utils/network.dart';
import 'package:uuid/uuid.dart';

import '../constants/enums.dart';

/*
EDIT:

Actually, pause/resume also works, but you have to supply the header range:1222-19238, then append the files.
This downloads the file where you left off at (you will have to calculate the downloaded file size)
 */

class BlobService {
  /*Future<bool> putByteByByte(UserFurnace userFurnace, String url, File file,
      {required CircleObject circleObject,
      required UserCircleCache userCircleCache,
      required Function progressCallback}) async {
    try {
     Dio dio = createInstance();

      debugPrint(
          'BlobService.put: ${circleObject.seed}  file: ${FileSystemService.getFilename(file.path)}');

      //add the CircleID as a hitchhiker for the progress indicator callback
      circleObject.circle = Circle(id: userCircleCache.circle);
      circleObject.userCircleCache = userCircleCache;
      //circleObject.addToken(cancelToken);

      int progress = 0;
      int retries = 0;
      int broadcastProgress = 0;

      int fileLength = file.lengthSync();
      int progressBytes = 0;

      while (retries <= RETRIES.MAX_IMAGE_UPLOAD_RETRIES) {
        debugPrint('while:progressBytes: $progressBytes');

        try {
          Response response = await dio.put(url,
              data: file.openRead(),
              cancelToken: circleObject.cancelToken,
              options: Options(
                //contentType: "application/octet-stream",
                contentType: "multipart/form-data",
                headers: {
                  "Content-Length": file.lengthSync(),
                  //'Range': 'bytes = $progressBytes-',
                  'Range': 'bytes=$progressBytes-$fileLength',
                },
                responseType: ResponseType.json,
              ), onSendProgress: (int sentBytes, int totalBytes) {
            // if (circleObject.type != CircleObjectType.CIRCLEALBUM) {
            double progressPercent = sentBytes / totalBytes * 100;

            progress = progressPercent.round();
            progressBytes = sentBytes;

            debugPrint('onSendProgress:progress $progress');
            debugPrint('onSendProgress:sentBytes $sentBytes');

            if (progress < 100) {
              if (progress > broadcastProgress) {
                broadcastProgress = progress;
                progressCallback(
                  userFurnace,
                  circleObject,
                  userCircleCache,
                  broadcastProgress,
                );
              }
            }
          });

          if (response.statusCode == 200 || response.statusCode == 201) {
            /*if (circleObject.type == CircleObjectType.CIRCLEALBUM) {
              circleObject.albumCount = circleObject.albumCount + 1;

              double progressPercent =
                  (circleObject.albumCount / circleObject.album!.length) * 100;

              progressCallback(userFurnace, circleObject, userCircleCache,
                  progressPercent.round(), postFailed, callbackBloc);
            } */

            return true;
          } else if (response.statusCode == 401) {
            await navService.logout(userFurnace);
          } else {
            debugPrint('BlobService.put failed: ${response.statusCode}');
            debugPrint(response.data);
            /*progressCallback(
              userFurnace,
              circleObject,
              userCircleCache,
              -1,
            );

             */
          }
        } on DioError catch (e, trace) {
          // The request was made and the server responded with a status code
          // that falls out of the range of 2xx and is also not 304.
          if (e.response != null) {
            debugPrint(e.response!.data);
            debugPrint(e.response!.headers.toString());
          } else {
            // Something happened in setting up or sending the request that triggered an Error
            debugPrint(e.message);

            debugPrint("BlobService.put " + e.toString());
          }

          if (retries == RETRIES.MAX_IMAGE_UPLOAD_RETRIES) {
            //LogBloc.insertError(e, trace);
            //progressCallback(userFurnace, circleObject, userCircleCache, -1,
            //postFailed, callbackBloc);
            rethrow;
          }
        } catch (err, trace) {
          debugPrint("BlobService.put " + err.toString());
          if (retries == RETRIES.MAX_IMAGE_UPLOAD_RETRIES) {
            //LogBloc.insertError(err, trace);
            //progressCallback(userFurnace, circleObject, userCircleCache, -1,
            //postFailed, callbackBloc);
            rethrow;
          }
        }

        //if (progressBytes == fileLength) return true;
        await Future.delayed(const Duration(milliseconds: 100));
        retries = retries + 1;
      }

      throw ('failed to upload image');
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("BlobService.put " + err.toString());

      rethrow;
    }
  }

   */

  Dio createInstance() {
    var dio = Dio();

    if (Platform.isWindows) {
      dio.httpClientAdapter = IOHttpClientAdapter(
        onHttpClientCreate: (client) {
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
          return client;
        },
      );
    }

    return dio;
  }

  Future<bool> putWithRetry(UserFurnace userFurnace, String url, File file,
      {required CircleObject circleObject,
      required UserCircleCache userCircleCache,
      required Function progressCallback,
      int broadcastProgress = 0,
      bool broadcastQuarterOnly = false,
      int maxRetries = RETRIES.MAX_IMAGE_UPLOAD_RETRIES,
      String loggingTag = ''}) async {
    try {
      Dio dio = createInstance();

      debugPrint(
          "${loggingTag.isNotEmpty ? '$loggingTag ' : ''}maxRetries: $maxRetries");

      debugPrint(
          "${loggingTag.isNotEmpty ? '$loggingTag ' : ''}BlobService.putWithRetry: ${circleObject.seed}  file: ${FileSystemService.getFilename(file.path)}");

      if (circleObject.circle == null || circleObject.circle!.id == null) {
        circleObject.circle = Circle(id: userCircleCache.circle);
      }
      //add the CircleID as a hitchhiker for the progress indicator callback

      circleObject.userCircleCache = userCircleCache;
      //circleObject.addToken(cancelToken);

      int progress = 0;
      //int broadcastProgress = 0;
      int retries = 0;

      int fileLength = file.lengthSync();
      int progressBytes = fileLength;

      while (retries <= maxRetries) {
        ///test to see if there is a connection
        if (await Network.isConnected() == false) {
          throw ('no connection');
        }

        debugPrint(
            "${loggingTag.isNotEmpty ? '$loggingTag ' : ''}retry: $retries, time: ${DateTime.now()}");

        debugPrint(
            "${loggingTag.isNotEmpty ? '$loggingTag ' : ''}BlobService.putWithRetry: ${circleObject.seed}  file: ${FileSystemService.getFilename(file.path)}");

        debugPrint(
            "${loggingTag.isNotEmpty ? '$loggingTag ' : ''}while:progressBytes: $progressBytes");

        debugPrint("${loggingTag.isNotEmpty ? '$loggingTag ' : ''} url: $url");

        debugPrint(
            "${loggingTag.isNotEmpty ? '$loggingTag ' : ''} file path: ${file.path}");

        try {
          Response response = await dio.put(url,
              data: file.openRead(),
              cancelToken: circleObject.cancelToken,
              options: Options(
                //contentType: "application/octet-stream",
                contentType: "multipart/form-data",
                //sendTimeout: const Duration(seconds: 30),
                headers: {
                  "Content-Length": file.lengthSync(),
                  'Range': 'bytes = $progressBytes-',
                },
                responseType: ResponseType.json,
              ), onSendProgress: (int sentBytes, int totalBytes) {
            // if (circleObject.type != CircleObjectType.CIRCLEALBUM) {
            double progressPercent = sentBytes / totalBytes * 100;

            progress = progressPercent.round();
            progressBytes = sentBytes;

            debugPrint(
                "${loggingTag.isNotEmpty ? '$loggingTag ' : ''}onSendProgress.progress $progress, onSendProgress.sentBytes: $sentBytes, time: ${DateTime.now()}");

            if (circleObject.type == CircleObjectType.CIRCLEALBUM) {
              if (progress < 100) {
                if (progress > broadcastProgress) {
                  broadcastProgress = progress;

                  circleObject.album!.bytesTransferred =
                      circleObject.album!.bytesTransferred + sentBytes;
                  circleObject.transferPercent =
                      ((circleObject.album!.bytesTransferred /
                                  circleObject.album!.bytesTotal) *
                              100)
                          .round();

                  progressCallback(
                    userFurnace,
                    circleObject,
                    userCircleCache,
                    circleObject.transferPercent,
                  );
                }
              }
            } else if (broadcastQuarterOnly) {
              if (progress < 26)
                broadcastProgress = progress;
              else
                broadcastProgress = 25;

              progressCallback(
                userFurnace,
                circleObject,
                userCircleCache,
                broadcastProgress,
              );
            } else {
              if (progress < 100) {
                if (progress > broadcastProgress) {
                  broadcastProgress = progress;

                  debugPrint('EVENT RAISED');

                  progressCallback(
                    userFurnace,
                    circleObject,
                    userCircleCache,
                    broadcastProgress,
                  );
                }
              }
            }
          });

          if (response.statusCode == 200 || response.statusCode == 201) {
            /*if (circleObject.type == CircleObjectType.CIRCLEALBUM) {
              circleObject.albumCount = circleObject.albumCount + 1;

              double progressPercent =
                  (circleObject.albumCount / circleObject.album!.length) * 100;

              progressCallback(userFurnace, circleObject, userCircleCache,
                  progressPercent.round(), postFailed, callbackBloc);
            } */

            return true;
          } else if (response.statusCode == 401) {
            await navService.logout(userFurnace);
          } else {
            debugPrint(
                "${loggingTag.isNotEmpty ? '$loggingTag ' : ''}BlobService.putWithRetry failed: ${response.statusCode}");
            debugPrint(response.data);
            /*progressCallback(
              userFurnace,
              circleObject,
              userCircleCache,
              -1,
            );

             */
          }
        } on DioException catch (e) {
          debugPrint('loggingTag: $loggingTag ${e.toString()}');

          /// stop retries
          if (e.type == DioExceptionType.cancel) {
            rethrow;
          }

          if (e.response != null) {
            debugPrint(e.response!.data);
            debugPrint(e.response!.headers.toString());
          } else {
            // Something happened in setting up or sending the request that triggered an Error
            debugPrint(e.message);

            debugPrint("BlobService.putWithRetry $e");
          }

          if (retries == maxRetries) {
            debugPrint(
                "BlobService.putWithRetry $e = maxRetries, time: ${DateTime.now()}");
            rethrow;
          }
        } catch (err) {
          debugPrint(
              "${loggingTag.isNotEmpty ? '$loggingTag ' : ''}BlobService.putWithRetry $err");
          if (retries == maxRetries ||
              err.toString().contains(('DioErrorType.cancel'))) {
            debugPrint(
                "${loggingTag.isNotEmpty ? '$loggingTag ' : ''}BlobService.putWithRetry $err = maxRetries || DioErrorType.cancel");

            //LogBloc.insertError(err, trace);
            //progressCallback(userFurnace, circleObject, userCircleCache, -1,
            //postFailed, callbackBloc);
            rethrow;
          }
        }

        //if (progressBytes == fileLength) return true;
        await Future.delayed(const Duration(milliseconds: 100));
        retries = retries + 1;
        circleObject.unstable = true;
        progressCallback(
          userFurnace,
          circleObject,
          userCircleCache,
          broadcastProgress,
        );
      }

      throw ("${loggingTag.isNotEmpty ? '$loggingTag ' : ''}failed to upload image");
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint(
          "${loggingTag.isNotEmpty ? '$loggingTag ' : ''}BlobService.putWithRetry $err");

      rethrow;
    }
  }

  Future<bool> put(UserFurnace userFurnace, String url, File file,
      {required CircleObject circleObject,
      required UserCircleCache userCircleCache,
      required Function progressCallback,
      required Function postFailed,
      required CircleObjectBloc callbackBloc}) async {
    try {
      Dio dio = createInstance();

      CancelToken cancelToken = CancelToken();

      debugPrint(
          'BlobService.put: ${circleObject.seed}  file: ${FileSystemService.getFilename(file.path)}');

      if (circleObject.circle == null || circleObject.circle!.id == null) {
        //add the CircleID as a hitchhiker for the progress indicator callback
        circleObject.circle = Circle(id: userCircleCache.circle);
      }
      
      circleObject.userCircleCache = userCircleCache;
      circleObject.addToken(cancelToken);

      int progress = 0;
      int broadcastProgress = 0;
      int retries = 0;

      int fileLength = file.lengthSync();
      int progressBytes = fileLength;

      while (retries <= RETRIES.MAX_IMAGE_UPLOAD_RETRIES) {
        debugPrint('while:progressBytes: $progressBytes');

        try {
          Response response = await dio.put(url,
              data: file.openRead(),
              cancelToken: cancelToken,
              options: Options(
                contentType: "application/octet-stream",
                sendTimeout: const Duration(seconds: 10),
                headers: {
                  "Content-Length": file.lengthSync(),
                  'Range': 'bytes = $progressBytes-',
                },
                responseType: ResponseType.json,
              ), onSendProgress: (int sentBytes, int totalBytes) {
            // if (circleObject.type != CircleObjectType.CIRCLEALBUM) {
            double progressPercent = sentBytes / totalBytes * 100;

            progress = progressPercent.round();
            progressBytes = sentBytes;

            debugPrint(
                "BlobService.put: onSendProgress.progress $progress, onSendProgress.sentBytes: $sentBytes, time: ${DateTime.now()}");

            if (progress < 100) {
              if (progress > broadcastProgress) {
                debugPrint('EVENT RAISED');
                broadcastProgress = progress;
                progressCallback(userFurnace, circleObject, userCircleCache,
                    progress, postFailed, callbackBloc);
              }
            }
            // }
          });

          if (response.statusCode == 200 || response.statusCode == 201) {
            if (circleObject.type == CircleObjectType.CIRCLEALBUM) {
              circleObject.albumCount = circleObject.albumCount + 1;

              double progressPercent =
                  (circleObject.albumCount / circleObject.album!.media.length) *
                      100;

              progressCallback(userFurnace, circleObject, userCircleCache,
                  progressPercent.round(), postFailed, callbackBloc);
            } else
              progressCallback(userFurnace, circleObject, userCircleCache, 100,
                  postFailed, callbackBloc);

            return true;
          } else if (response.statusCode == 401) {
            await navService.logout(userFurnace);
          } else {
            debugPrint('BlobService.put failed: ${response.statusCode}');
            debugPrint(response.data);
            progressCallback(userFurnace, circleObject, userCircleCache, -1,
                postFailed, callbackBloc);
          }
        } on DioException catch (e) {
          // The request was made and the server responded with a status code
          // that falls out of the range of 2xx and is also not 304.
          if (e.response != null) {
            debugPrint(e.response!.data);
            debugPrint(e.response!.headers.toString());
          } else {
            // Something happened in setting up or sending the request that triggered an Error
            debugPrint(e.message);

            debugPrint("BlobService.put $e");
          }

          if (retries == RETRIES.MAX_IMAGE_UPLOAD_RETRIES) {
            //LogBloc.insertError(e, trace);
            //progressCallback(userFurnace, circleObject, userCircleCache, -1,
            //postFailed, callbackBloc);
            rethrow;
          }
        } catch (err) {
          debugPrint("BlobService.put $err");
          if (retries == RETRIES.MAX_IMAGE_UPLOAD_RETRIES) {
            //LogBloc.insertError(err, trace);
            //progressCallback(userFurnace, circleObject, userCircleCache, -1,
            //postFailed, callbackBloc);
            rethrow;
          }
        }
        await Future.delayed(const Duration(milliseconds: 100));
        retries++;
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("BlobService.put $err");

      progressCallback(userFurnace, circleObject, userCircleCache, -1,
          postFailed, callbackBloc);
    }

    return false;
  }

  Future<bool> putGridFSDual(
      UserFurnace userFurnace,
      String url,
      String authID,
      File full,
      File thumbnail,
      CircleObject? circleObject,
      UserCircleCache? userCircleCache,
      Function progressCallback,
      Function progressThumbnailCallback) async {
    try {
      Dio dio = createInstance();

      CancelToken cancelToken = CancelToken();

      //add the CircleID as a hitchhiker for the progress indicator callback
      circleObject!.circle = Circle(id: userCircleCache!.circle);
      circleObject.userCircleCache = userCircleCache;
      circleObject.addToken(cancelToken);

      FormData formData = FormData.fromMap({
        "thumbnail": await MultipartFile.fromFile(
          thumbnail.path,
          filename: "thumbnail",
        ),
        "full": await MultipartFile.fromFile(
          full.path,
          filename: "full",
        ),
      });

      debugPrint(url);

      Response response = await dio.post(url,
          data: formData,
          cancelToken: cancelToken,
          options: Options(
            contentType: "application/octet-stream",
            headers: {
              'Authorization': userFurnace.token,
              'authid': authID,
              'type': circleObject.type,
            },
            responseType: ResponseType.json,
          ), onSendProgress: (int sentBytes, int totalBytes) {
        double progressPercent = sentBytes / totalBytes * 100;

        int progress = progressPercent.round();

        if (progress < 100) {
          progressThumbnailCallback(
              userFurnace, circleObject, userCircleCache, progress);

          progressCallback(
              userFurnace, circleObject, userCircleCache, progress);
        }
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (circleObject.type == CircleObjectType.CIRCLEIMAGE) {
          circleObject.image!.fullImage = response.data["full"];
          circleObject.image!.thumbnail = response.data["thumbnail"];
        } else if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
          circleObject.video!.video = response.data["full"];
          circleObject.video!.preview = response.data["thumbnail"];

          //circleObject.video!.videoState = VideoStateIC.VIDEO_UPLOADED;
        }

        progressThumbnailCallback(
            userFurnace, circleObject, userCircleCache, 100);

        progressCallback(userFurnace, circleObject, userCircleCache, 100);

        return true;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        debugPrint('BlobService.put failed: ${response.statusCode}');
        debugPrint(response.data);
      }
    } on DioException catch (e) {
// The request was made and the server responded with a status code
// that falls out of the range of 2xx and is also not 304.
      if (e.response != null) {
        debugPrint(e.response!.data);
        debugPrint(e.response!.headers.toString());
      } else {
// Something happened in setting up or sending the request that triggered an Error

        debugPrint(e.message);

        debugPrint("BlobService.put $e");
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("BlobService.put $err");

      rethrow;
    }

    return false;
  }

  Future<bool> putGridFS(
      UserFurnace userFurnace,
      String url,
      String authID,
      File file,
      CircleObject? circleObject,
      UserCircleCache? userCircleCache,
      Function progressCallback) async {
    try {
      Dio dio = createInstance();

      CancelToken cancelToken = CancelToken();

      //add the CircleID as a hitchhiker for the progress indicator callback
      circleObject!.circle = Circle(id: userCircleCache!.circle);
      circleObject.userCircleCache = userCircleCache;
      circleObject.addToken(cancelToken);

      FormData formData = FormData.fromMap({
        "full": await MultipartFile.fromFile(
          file.path,
          filename: "full",
        ),
      });

      debugPrint(url);

      Response response = await dio.post(url,
          data: formData,
          cancelToken: cancelToken,
          options: Options(
            contentType: "application/octet-stream",
            headers: {
              'Authorization': userFurnace.token,
              'authid': authID,
              'type': circleObject.type,
            },
            responseType: ResponseType.json,
          ), onSendProgress: (int sentBytes, int totalBytes) {
        double progressPercent = sentBytes / totalBytes * 100;

        int progress = progressPercent.round();

        if (progress < 100) {
          progressCallback(
              userFurnace, circleObject, userCircleCache, progress);
        }
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (circleObject.type == CircleObjectType.CIRCLERECIPE) {
          circleObject.recipe!.image!.thumbnail = response.data["full"];
        }

        progressCallback(userFurnace, circleObject, userCircleCache, 100);

        return true;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        debugPrint('BlobService.putGridFS failed: ${response.statusCode}');
        debugPrint(response.data);
      }
    } on DioException catch (e) {
// The request was made and the server responded with a status code
// that falls out of the range of 2xx and is also not 304.
      if (e.response != null) {
        debugPrint(e.response!.data);
        debugPrint(e.response!.headers.toString());
      } else {
// Something happened in setting up or sending the request that triggered an Error

        debugPrint(e.message);

        debugPrint("BlobService.putGridFS $e");
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("BlobService.putGridFS $err");

      rethrow;
    }

    return false;
  }

  static safeCancelTokens(CircleObject circleObject) {
    try {
      if (circleObject.cancelToken != null) {
        circleObject.cancelToken!.cancel();
      } else {
        if (circleObject.cancelTokens == null) return;

        for (CancelToken cancelToken in circleObject.cancelTokens!) {
          try {
            if (!cancelToken.isCancelled) {
              cancelToken.cancel();
            }
          } catch (err) {
            //LogBloc.insertError(err, trace);
            debugPrint('BlobService.safeCancelTokens: $err');
          }
        }
      }
    } catch (err) {
      //LogBloc.insertError(err, trace);
      debugPrint('BlobService.safeCancelTokens: $err');
    }
  }

  static safeCancel(CancelToken cancelToken) {
    try {
      if (!cancelToken.isCancelled) {
        cancelToken.cancel();
      }
    } catch (err) {
      //LogBloc.insertError(err, trace);
      debugPrint('BlobService.safeCancel: $err');
    }
  }

  Future<bool> getItem(
    AlbumItem item,
    UserFurnace userFurnace,
    String location,
    String url,
    String filePath,
    String authID, {
    required CircleObject circleObject,
    required UserCircleCache userCircleCache,
    required Function progressCallback,
    required Function failedCallback,
  }) async {
    CancelToken cancelToken = CancelToken();

    try {
      Dio dio = createInstance();

      //add the CircleID as a hitchhiker for the progress indicator callback
      circleObject.circle ??= Circle(id: userCircleCache.circle);
      circleObject.userCircleCache = userCircleCache;
      circleObject.addToken(cancelToken);
      int broadcastProgress = 0;
      //throw('failed');

      if (await Network.isConnected()) {
        Response response = await dio.download(
          url,
          '${filePath}enc',
          cancelToken: cancelToken,
          options: Options(
            responseType: ResponseType.bytes,
            headers: //circleObject == null
                //? {} //S3
                (location == BlobLocation.S3 ||
                        location == BlobLocation.PRIVATE_S3 ||
                        location == BlobLocation.PRIVATE_WASABI)
                    ? {}
                    : {
                        'Authorization': userFurnace.token,
                        'authid': authID,
                        'type': circleObject.type,
                      },
          ),
          onReceiveProgress: (int sentBytes, int totalBytes) {
            if (totalBytes == -1) {
              if (circleObject.type == CircleObjectType.CIRCLEIMAGE)
                totalBytes = circleObject.image!.fullImageSize!;
              else if (circleObject.type == CircleObjectType.CIRCLEVIDEO)
                totalBytes = circleObject.video!.videoSize!;
              else if (circleObject.type == CircleObjectType.CIRCLERECIPE)
                totalBytes = circleObject.recipe!.image!.thumbnailSize!;
            }

            if (totalBytes > 0) {
              double progressPercent = sentBytes / totalBytes * 100;

              int progress = progressPercent.round();

              if (progress < 100) {
                if (progress > broadcastProgress) {
                  debugPrint(
                      "BlobService.getItem: onSendProgress.progress $progress, onSendProgress.sentBytes: $sentBytes, time: ${DateTime.now()}");
                  broadcastProgress = progress;
                  debugPrint('EVENT RAISED');
                  progressCallback(userFurnace, circleObject, item,
                      userCircleCache, progress, failedCallback, cancelToken);
                }
              }
            } else {
              progressCallback(userFurnace, circleObject, item, userCircleCache,
                  0, failedCallback, cancelToken);
            }

            //throw('failed');
          },
        );

        if (response.statusCode == 200) {
          //if (progressCallback != null) {
          //progressCallback(circleObject, 100, true);
          // }

          progressCallback(userFurnace, circleObject, item, userCircleCache,
              100, failedCallback, cancelToken);
          return true;
        } else if (response.statusCode == 401) {
          await navService.logout(userFurnace);
          return false;
        } else {
          debugPrint('BlobService.get failed: ${response.statusCode}');
          debugPrint(response.data);

          safeCancel(cancelToken);

          failedCallback(userFurnace, userCircleCache, circleObject, item);
          return false;
        }
      }
    } on DioException catch (e) {
      if (!(e.type == DioExceptionType.cancel)) {
        // The request was made and the server responded with a status code
        // that falls out of the range of 2xx and is also not 304.
        if (e.response != null) {
          debugPrint('BlobService.get failed');
          debugPrint(e.response!.data);
          debugPrint(e.response!.headers.toString());
        } else {
          // Something happened in setting up or sending the request that triggered an Error
          debugPrint('BlobService.get failed');

          debugPrint(e.message);
        }

        safeCancel(cancelToken);
        if (e.response != null &&
            e.response!.data.contains("The specified key does not exist")) {
          failedCallback(userFurnace, userCircleCache, circleObject, item,
              reason: DownloadFailedReason.keyDoesNotExist);
        } else {
          failedCallback(userFurnace, userCircleCache, circleObject, item);
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('BlobService.get: $err');

      safeCancel(cancelToken);

      failedCallback(userFurnace, userCircleCache, circleObject, item);
    }
    return false;
  }

  get(
    UserFurnace userFurnace,
    String location,
    String url,
    String filePath,
    String authID, {
    required CircleObject circleObject,
    required UserCircleCache userCircleCache,
    required Function progressCallback,
    required Function failedCallback,
  }) async {
    CancelToken cancelToken = CancelToken();

    try {
      Dio dio = createInstance();

      //add the CircleID as a hitchhiker for the progress indicator callback
      circleObject.circle ??= Circle(id: userCircleCache.circle);
      circleObject.userCircleCache = userCircleCache;
      circleObject.addToken(cancelToken);
      int broadcastProgress = 0;
      //throw('failed');

      if (await Network.isConnected()) {
        debugPrint(url);

        Response response = await dio.download(
          url,
          '${filePath}enc',
          cancelToken: cancelToken,
          options: Options(
            responseType: ResponseType.bytes,
            headers: //circleObject == null
                //? {} //S3
                (location == BlobLocation.S3 ||
                        location == BlobLocation.PRIVATE_S3 ||
                        location == BlobLocation.PRIVATE_WASABI)
                    ? {}
                    : {
                        'Authorization': userFurnace.token,
                        'authid': authID,
                        'type': circleObject.type,
                      },
          ),
          onReceiveProgress: (int sentBytes, int totalBytes) {
            if (totalBytes == -1) {
              if (circleObject.type == CircleObjectType.CIRCLEIMAGE)
                totalBytes = circleObject.image!.fullImageSize!;
              else if (circleObject.type == CircleObjectType.CIRCLEVIDEO)
                totalBytes = circleObject.video!.videoSize!;
              else if (circleObject.type == CircleObjectType.CIRCLERECIPE)
                totalBytes = circleObject.recipe!.image!.thumbnailSize!;
            }

            if (totalBytes > 0) {
              double progressPercent = sentBytes / totalBytes * 100;

              int progress = progressPercent.round();

              if (progress < 100) {
                if (progress > broadcastProgress) {
                  debugPrint(
                      "BlobService.get: onSendProgress.progress $progress, onSendProgress.sentBytes: $sentBytes, time: ${DateTime.now()}");
                  broadcastProgress = progress;
                  debugPrint('EVENT RAISED');
                  progressCallback(userFurnace, circleObject, userCircleCache,
                      progress, failedCallback, cancelToken);
                }
              }
            } else {
              progressCallback(userFurnace, circleObject, userCircleCache, 0,
                  failedCallback, cancelToken);
            }

            //throw('failed');
          },
        );

        if (response.statusCode == 200) {
          //if (progressCallback != null) {
          //progressCallback(circleObject, 100, true);
          // }

          progressCallback(userFurnace, circleObject, userCircleCache, 100,
              failedCallback, cancelToken);
        } else if (response.statusCode == 401) {
          await navService.logout(userFurnace);
        } else {
          debugPrint('BlobService.get failed: ${response.statusCode}');
          debugPrint(response.data);

          safeCancel(cancelToken);

          failedCallback(userFurnace, userCircleCache, circleObject);
        }
      }
    } on DioException catch (e) {
      if (!(e.type == DioExceptionType.cancel)) {
        // The request was made and the server responded with a status code
        // that falls out of the range of 2xx and is also not 304.
        if (e.response != null) {
          debugPrint('BlobService.get failed');
          debugPrint(e.response!.data);
          debugPrint(e.response!.headers.toString());
        } else {
          // Something happened in setting up or sending the request that triggered an Error
          debugPrint('BlobService.get failed');

          debugPrint(e.message);
        }

        safeCancel(cancelToken);

        failedCallback(userFurnace, userCircleCache, circleObject);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('BlobService.get: $err');

      safeCancel(cancelToken);

      failedCallback(userFurnace, userCircleCache, circleObject);
    }
  }

  Future<CircleObject> cacheCircleBlob(CircleObject circleObject) async {
    //create a local id for caching in the event the network is down
    if (circleObject.id == null) {

      circleObject.seed ??= const Uuid().v4();
      await TableCircleObjectCache.updateCacheSingleObject('', circleObject);
    }

    return circleObject;
  }
}
