import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/hostedfurnaceimage.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';
import 'package:ironcirclesapp/utils/network.dart';

class BlobGenericService {
  Future<bool> put(UserFurnace userFurnace, String url, String key,
      String location, File file,
      {required Function progressCallback,
      GlobalEventBloc? globalEventBloc}) async {
    try {
      Dio dio = Dio();

      CancelToken cancelToken = CancelToken();

      int broadcastProgress = 0;

      Response response = await dio.put(url,
          data: file.openRead(),
          cancelToken: cancelToken,
          options: Options(
            contentType: "application/octet-stream",
            headers: {
              "Content-Length": file.lengthSync(),
            },
            responseType: ResponseType.json,
          ), onSendProgress: (int sentBytes, int totalBytes) {
        double progressPercent = sentBytes / totalBytes * 100;

        int progress = progressPercent.round();
        if (progress < 100) {
          if (progress > broadcastProgress) {
            broadcastProgress = progress;
            debugPrint('BlobGeneric.put: $broadcastProgress EVENT RAISED');
            if (globalEventBloc != null)
              progressCallback(userFurnace, '', key, location, true, progress,
                  globalEventBloc);
            else
              progressCallback(userFurnace, '', key, location, true, progress);
          }
        }
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (globalEventBloc != null)
          progressCallback(
              userFurnace,
              FileSystemService.getFilename(file.path),
              key,
              location,
              true,
              100,
              globalEventBloc);
        else
          progressCallback(
              userFurnace,
              FileSystemService.getFilename(file.path),
              key,
              location,
              true,
              100);

        return true;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        debugPrint('BlobGenericService.put failed: ${response.statusCode}');
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

        debugPrint("BlobGenericService.put $e");
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("BlobGenericService.put $err");

      throw (err);
    }

    return false;
  }

  Future<bool> getImage(
    UserFurnace userFurnace,
    HostedFurnace network,
    String location,
    String url,
    String filePath,
    String authID,
    HostedFurnaceImage img, {
    required Function progressCallback,
    required Function failedCallback,
  }) async {
    try {
      Dio dio = Dio();
      CancelToken cancelToken = CancelToken();
      int broadcastProgress = 0;

      if (await Network.isConnected()) {
        debugPrint(url);

        Response response = await dio.download(
          url,
          '${filePath}enc',
          cancelToken: cancelToken,
          options: Options(
            responseType: ResponseType.bytes,
            headers: (location == BlobLocation.S3 ||
                    location == BlobLocation.PRIVATE_S3 ||
                    location == BlobLocation.PRIVATE_WASABI)
                ? {}
                : {
                    'Authorization': userFurnace.token,
                    'authid': authID,
                  },
          ),
          onReceiveProgress: (int sentBytes, int totalBytes) {
            if (totalBytes == -1) {
              totalBytes = File(filePath).lengthSync();
            }

            if (totalBytes > 0) {
              double progressPercent = sentBytes / totalBytes * 100;

              int progress = progressPercent.round();

              debugPrint(progress.toString());

              if (progress < 100) {
                if (progress > broadcastProgress) {
                  broadcastProgress = progress;
                  debugPrint(
                      'BlobGeneric.getImage: $broadcastProgress EVENT RAISED');
                  progressCallback(img, network, userFurnace, '', '', location,
                      false, progress, failedCallback);
                }
              }
            }
            /*else {
              progressCallback(userFurnace, 0);
            }*/
          },
        );

        if (response.statusCode == 200) {
          //if (progressCallback != null) {
          //progressCallback(circleObject, 100, true);
          // }

          progressCallback(img, network, userFurnace, '', '', location, false,
              100, failedCallback);

          return true;
        } else if (response.statusCode == 401) {
          await navService.logout(userFurnace);
        } else {
          debugPrint('BlobGenericService.getImage failed: ${response.statusCode}');
          debugPrint(response.data);
        }
      }
    } on DioException catch (e) {
      // The request was made and the server responded with a status code
      // that falls out of the range of 2xx and is also not 304.
      if (e.response != null) {
        debugPrint('BlobGenericService.getImage failed');
        debugPrint(e.response!.data);
        debugPrint(e.response!.headers.toString());
      } else {
        // Something happened in setting up or sending the request that triggered an Error
        debugPrint('BlobGenericService.getImage failed');

        debugPrint(e.message);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('BlobGenericService.getImage: $err');
    }

    //something went wrong
    //progressCallback(userFurnace, -1);
    progressCallback(
        img, network, userFurnace, '', '', location, false, -1, failedCallback);

    return false;
  }

  Future<bool> getUnauthorizedImage(
      HostedFurnace network,
      String location,
      String url,
      String filePath,
      HostedFurnaceImage img, {
        required Function progressCallback,
        required Function failedCallback,
  }) async {
    try {
      Dio dio = Dio();
      CancelToken cancelToken = CancelToken();
      int broadcastProgress = 0;

      if (await Network.isConnected()) {
        debugPrint(url);

        Response response = await dio.download(
          url,
          '${filePath}enc',
          cancelToken: cancelToken,
          options: Options(
            responseType: ResponseType.bytes,
            headers: (location == BlobLocation.S3 ||
              location == BlobLocation.PRIVATE_S3 ||
              location == BlobLocation.PRIVATE_WASABI)
              ? {}
                : {
              'Authorization': urls.forgeAPIKEY,
            },
          ),
          onReceiveProgress: (int sentBytes, int totalBytes) {
            if (totalBytes == -1) {
              totalBytes = File(filePath).lengthSync();
            }

            if (totalBytes > 0) {
              double progressPercent = sentBytes / totalBytes * 100;

              int progress = progressPercent.round();

              debugPrint(progress.toString());

              if (progress < 100) {
                if (progress > broadcastProgress) {
                  broadcastProgress = progress;
                  debugPrint(
                    'BlobGeneric.getUnauthorizedImage: $broadcastProgress EVENT RAISED');
                  progressCallback(img, network, null, '', '', location,
                    false, progress, failedCallback);
                }
              }
            }
          }
        );

        if (response.statusCode == 200) {
          progressCallback(img, network, null, '', '', location, false,
           100, failedCallback);

          return true;
        } else if (response.statusCode == 401) {
          //await navService.logout(userFurnace);
        } else {
          debugPrint('BlobGenericService.getUnauthorizedImage failed: ${response.statusCode}');
          debugPrint(response.data);
        }
      }
    } on DioException catch (e) {
      // The request was made and the server responded with a status code
      // that falls out of the range of 2xx and is also not 304.
      if (e.response != null) {
        debugPrint('BlobGenericService.getUnauthorizedImage failed');
        debugPrint(e.response!.data);
        debugPrint(e.response!.headers.toString());
      } else {
        // Something happened in setting up or sending the request that triggered an Error
        debugPrint('BlobGenericService.getUnauthorizedImage failed');

        debugPrint(e.message);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('BlobGenericService.getUnauthorizedImage: $err');
    }

    //something went wrong
    //progressCallback(userFurnace, -1);
    progressCallback(
        img, network, null, '', '', location, false, -1, failedCallback);

    return false;
  }

  Future<bool> get(
    //HostedFurnaceImage? img,
    UserFurnace userFurnace,
    String location,
    String url,
    String filePath,
    String authID, {
    required Function progressCallback,
  }) async {
    try {
      Dio dio = Dio();
      CancelToken cancelToken = CancelToken();

      int broadcastProgress = 0;

      if (await Network.isConnected()) {
        debugPrint(url);

        Response response = await dio.download(
          url,
          '${filePath}enc',
          cancelToken: cancelToken,
          options: Options(
            responseType: ResponseType.bytes,
            headers: (location == BlobLocation.S3 ||
                    location == BlobLocation.PRIVATE_S3 ||
                    location == BlobLocation.PRIVATE_WASABI)
                ? {}
                : {
                    'Authorization': userFurnace.token,
                    'authid': authID,
                  },
          ),
          onReceiveProgress: (int sentBytes, int totalBytes) {
            if (totalBytes == -1) {
              totalBytes = File(filePath).lengthSync();
            }

            if (totalBytes > 0) {
              double progressPercent = sentBytes / totalBytes * 100;

              int progress = progressPercent.round();

              debugPrint(progress.toString());

              if (progress < 100) {
                if (progress > broadcastProgress) {
                  broadcastProgress = progress;
                  debugPrint(
                      'BlobGeneric.get: $broadcastProgress EVENT RAISED');
                  progressCallback(
                      userFurnace, '', '', location, false, progress);
                }
              }
            }
            /*else {
              progressCallback(userFurnace, 0);
            }*/
          },
        );

        if (response.statusCode == 200) {
          //if (progressCallback != null) {
          //progressCallback(circleObject, 100, true);
          // }

          progressCallback(userFurnace, '', '', location, false, 100);

          return true;
        } else if (response.statusCode == 401) {
          await navService.logout(userFurnace);
        } else {
          debugPrint('BlobGenericService.get failed: ${response.statusCode}');
          debugPrint(response.data);
        }
      }
    } on DioException catch (e) {
      // The request was made and the server responded with a status code
      // that falls out of the range of 2xx and is also not 304.
      if (e.response != null) {
        debugPrint('BlobGenericService.get failed');
        debugPrint(e.response!.data);
        debugPrint(e.response!.headers.toString());
      } else {
        // Something happened in setting up or sending the request that triggered an Error
        debugPrint('BlobGenericService.get failed');

        debugPrint(e.message);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('BlobGenericService.get: $err');
    }

    //something went wrong
    //progressCallback(userFurnace, -1);
    progressCallback(userFurnace, '', '', location, false, -1);

    return false;
  }

  Future<bool> getFromWeb(String url, String filePath) async {
    try {
      Dio dio = Dio();
      CancelToken cancelToken = CancelToken();

      if (await Network.isConnected()) {
        debugPrint(url);

        Response response = await dio.download(
          url,
          filePath,
          cancelToken: cancelToken,
          options: Options(responseType: ResponseType.bytes, headers: {}),
          onReceiveProgress: (int sentBytes, int totalBytes) {
            if (totalBytes == -1) {
              totalBytes = File(filePath).lengthSync();
            }

            if (totalBytes > 0) {
              double progressPercent = sentBytes / totalBytes * 100;

              int progress = progressPercent.round();

              debugPrint(progress.toString());

              if (progress < 100) {
                // progressCallback(
                //  userFurnace, '', '', location, false, progress);
              }
            }
          },
        );

        if (response.statusCode == 200) {
          return true;
        } else if (response.statusCode == 401) {
          LogBloc.insertLog(
              response.statusMessage!, 'BlobGenericService.getFromWeb failed');
        } else {
          debugPrint(
              'BlobGenericService.getFromWeb failed: ${response.statusCode}');
          debugPrint(response.data);
          LogBloc.insertLog(
              response.statusMessage!, 'BlobGenericService.getFromWeb failed');
        }
      }
    } on DioException catch (e, trace) {
      // The request was made and the server responded with a status code
      // that falls out of the range of 2xx and is also not 304.
      if (e.response != null) {
        debugPrint('BlobGenericService.getFromWeb failed');
        debugPrint(e.response!.data);
        debugPrint(e.response!.headers.toString());
      } else {
        // Something happened in setting up or sending the request that triggered an Error
        debugPrint('BlobGenericService.getFromWeb failed');
        debugPrint(e.message);
      }
      LogBloc.insertError(e, trace);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('BlobGenericService.getFromWeb: $err');
    }

    return false;
  }
}
