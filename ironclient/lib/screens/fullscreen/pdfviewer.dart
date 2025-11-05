import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/dialogshareto.dart';
import 'package:ironcirclesapp/screens/utilities/sharecircleobject.dart';
import 'package:ironcirclesapp/screens/widgets/dialogdownload.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';
import 'package:ironcirclesapp/services/cache/filecache_service.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';

class PDFViewer extends StatefulWidget {
  final String? name;
  final String path;
  final UserCircleCache userCircleCache;
  final CircleObject circleObject;

  const PDFViewer(
      {Key? key,
      this.name,
      required this.path,
      required this.userCircleCache,
      required this.circleObject})
      : super(key: key);

  @override
  _PDFScreenState createState() => _PDFScreenState();
}

class _PDFScreenState extends State<PDFViewer> with WidgetsBindingObserver {
  final Completer<PDFViewController> _controller =
      Completer<PDFViewController>();
  int? pages = 0;
  int? currentPage = 0;
  bool isReady = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    if (globalState.isDesktop()) {
      ///delete the decrypted file after viewing
      File external = File(FileCacheService.returnFilePath(
          widget.userCircleCache.circlePath!, widget.circleObject.file!.name!));

      FileSystemService.safeDelete(external);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ICAppBar(
        title: widget.name ?? "PDF",
        actions: <Widget>[
          Platform.isAndroid
              ? IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () async {
                    await DialogDownload.showAndDownloadFiles(
                        context,
                        AppLocalizations.of(context)!.downloadingFile,
                        [File(widget.path)]);

                    if (mounted) {
                      DialogNotice.showNoticeOptionalLines(
                          context,
                          AppLocalizations.of(context)!.downloadCompleteTitle,
                          AppLocalizations.of(context)!.downloadCompleteMessage,
                          false);
                    }
                  },
                )
              : Container(),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              DialogShareTo.shareToPopup(context, widget.userCircleCache,
                  widget.circleObject, ShareCircleObject.shareToDestination);

              /*Share.shareFiles(
                [widget.path!], /*text: 'pdf'*/
              );

               */
            },
          ),
        ],
      ),
      backgroundColor: globalState.theme.background,
      body: Stack(
        children: <Widget>[
          PDFView(
            filePath: widget.path,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: false,
            pageFling: false,
            pageSnap: false,
            defaultPage: currentPage!,
            fitPolicy: FitPolicy.BOTH,
            preventLinkNavigation:
                false, // if set to true the link is handled in flutter
            onRender: (_pages) {
              setState(() {
                pages = _pages;
                isReady = true;
              });
            },
            onError: (error) {
              setState(() {
                errorMessage = error.toString();
              });
              debugPrint(error.toString());
            },
            onPageError: (page, error) {
              setState(() {
                errorMessage = '$page: ${error.toString()}';
              });
              if (kDebugMode) {
                debugPrint('$page: ${error.toString()}');
              }
            },
            onViewCreated: (PDFViewController pdfViewController) {
              _controller.complete(pdfViewController);
            },
            onLinkHandler: (String? uri) {
              if (kDebugMode) {
                debugPrint('goto uri: $uri');
              }
            },
            onPageChanged: (int? page, int? total) {
              if (kDebugMode) {
                debugPrint('page change: $page/$total');
              }
              setState(() {
                currentPage = page;
              });
            },
          ),
          errorMessage.isEmpty
              ? !isReady
                  ? Center(
                      child: CircularProgressIndicator(
                        color: globalState.theme.button,
                      ),
                    )
                  : Container()
              : Center(
                  child: ICText(errorMessage),
                )
        ],
      ),
      /*floatingActionButton: FutureBuilder<PDFViewController>(
        future: _controller.future,
        builder: (context, AsyncSnapshot<PDFViewController> snapshot) {
          if (snapshot.hasData) {
            return FloatingActionButton.extended(
              label: Text("Go to ${pages! ~/ 2}"),
              onPressed: () async {
                await snapshot.data!.setPage(pages! ~/ 2);
              },
            );
          }

          return Container();
        },
      ),*/
    );
  }
}
