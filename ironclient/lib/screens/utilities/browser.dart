import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:url_launcher/url_launcher.dart';

class Browser extends StatefulWidget {
  final String? url;

  const Browser({this.url});
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<Browser> {
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;
  InAppWebViewSettings options = InAppWebViewSettings(
    useShouldOverrideUrlLoading: true,
    mediaPlaybackRequiresUserGesture: false,
    useHybridComposition: true,
    allowsInlineMediaPlayback: true,
  );

  late PullToRefreshController pullToRefreshController;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();

  @override
  void initState() {
    super.initState();

    pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (didPop) {
          return;
        }
        /* widget.url == null
            ? await Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => Home()),
                (Route<dynamic> route) => false)
            : Navigator.pop(context);

        */

        if (widget.url != null) Navigator.pop(context);

      },
      child: Scaffold(
          appBar: widget.url == null
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(40.0),
                  child: ICAppBar(title: AppLocalizations.of(context)!.incognitoBrowser))
              : Platform.isIOS
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(40.0),
                      child: AppBar(
                          backgroundColor: globalState.theme.background,
                          leading: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.pop(context),
                          ),
                          iconTheme: IconThemeData(
                            color: globalState.theme.menuIcons,
                          )))
                  : null, //change your color here),*/
          backgroundColor: globalState.theme.background,
          body: SafeArea(
              child: Stack(children: <Widget>[
            Column(children: <Widget>[
              widget.url == null
                  ? const Row(children: [
                      /*Expanded(
                              child:TextField(
                            cursorColor: globalState.theme.menuIcons,
                            style:
                                TextStyle(color: globalState.theme.menuIcons),
                            decoration: InputDecoration(
                                focusColor: globalState.theme.menuIcons,
                                //hintText: hintText,
                                counterText: '',
                                labelStyle: TextStyle(
                                    color: globalState.theme.textFieldLabel),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: globalState.theme.textField),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: globalState.theme.textField),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: globalState.theme.menuIcons,
                                )),
                            controller: urlController,
                            keyboardType: TextInputType.url,
                            onSubmitted: (value) {
                              var url = Uri.parse(value);
                              if (url.scheme.isEmpty) {
                                url = Uri.parse(
                                    "https://duckduckgo.com//search?q=" +
                                        value);
                              }
                              webViewController?.loadUrl(
                                  urlRequest: URLRequest(url: url));
                            },
                          ))*/
                      /*Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                              padding: EdgeInsets.only(top: 0, left: 2),
                              child: IconButton(
                                icon: Icon(Icons.home,
                                    color: globalState.theme.menuIcons),
                                onPressed: () async {
                                  await Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => Home()),
                                      (Route<dynamic> route) => false);
                                },
                              ))),*/
                    ])
                  : Container(),
              Expanded(
                child: Stack(
                  children: [
                    InAppWebView(
                      key: webViewKey,
                      initialUrlRequest: URLRequest(
                          url: WebUri.uri(Uri.parse(widget.url == null
                              ? "https://start.duckduckgo.com/"
                              : widget.url!))),
                      initialSettings: options,
                      pullToRefreshController: pullToRefreshController,
                      onWebViewCreated: (controller) {
                        webViewController = controller;
                      },
                      onLoadStart: (controller, url) {
                        setState(() {
                          this.url = url.toString();
                          urlController.text = this.url;
                        });
                      },
                      onPermissionRequest: (controller, request) async {
                        return PermissionResponse(
                          resources: request.resources,
                          action: PermissionResponseAction.GRANT);
                      },
                      shouldOverrideUrlLoading:
                          (controller, navigationAction) async {
                        var uri = navigationAction.request.url!;

                        if (![
                          "http",
                          "https",
                          "file",
                          "chrome",
                          "data",
                          "javascript",
                          "about"
                        ].contains(uri.scheme)) {
                          Uri uri = Uri.parse(url);

                          if (await canLaunchUrl(uri)) {
                            // Launch the App
                            await launchUrl(
                              uri,
                            );
                            // and cancel the request
                            return NavigationActionPolicy.CANCEL;
                          }
                        }

                        return NavigationActionPolicy.ALLOW;
                      },
                      onLoadStop: (controller, url) async {
                        pullToRefreshController.endRefreshing();
                        setState(() {
                          this.url = url.toString();
                          urlController.text = this.url;
                        });
                      },
                      onReceivedError: (controller, url, code) {
                        pullToRefreshController.endRefreshing();
                      },
                      onProgressChanged: (controller, progress) {
                        if (progress == 100) {
                          pullToRefreshController.endRefreshing();
                        }
                        setState(() {
                          this.progress = progress / 100;
                          urlController.text = this.url;
                        });
                      },
                      onUpdateVisitedHistory:
                          (controller, url, androidIsReload) {
                        setState(() {
                          this.url = url.toString();
                          urlController.text = this.url;
                        });
                      },
                      onConsoleMessage: (controller, consoleMessage) {
                        debugPrint(consoleMessage.toString());
                      },
                    ),
                    progress < 1.0
                        ? LinearProgressIndicator(value: progress)
                        : Container(),
                  ],
                ),
              ),
              widget.url == null
                  ? ButtonBar(
                      alignment: MainAxisAlignment.center,
                      children: <Widget>[
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: globalState.theme.background),
                          child: Icon(
                            Icons.arrow_back,
                            color: globalState.theme.buttonIcon,
                          ),
                          onPressed: () {
                            webViewController?.goBack();
                          },
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: globalState.theme.background),
                          child: Icon(Icons.arrow_forward,
                              color: globalState.theme.buttonIcon),
                          onPressed: () {
                            webViewController?.goForward();
                          },
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: globalState.theme.background),
                          child: Icon(Icons.refresh,
                              color: globalState.theme.buttonIcon),
                          onPressed: () {
                            webViewController?.reload();
                          },
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: globalState.theme.background),
                          child: Icon(Icons.home,
                              color: globalState.theme.buttonIcon),
                          onPressed: () {
                            webViewController?.loadUrl(
                                urlRequest: URLRequest(
                                    url: WebUri.uri(Uri.parse(
                                        "https://start.duckduckgo.com/"))));
                          },
                        ),

                        /*

                        IconButton(
                                icon: Icon(Icons.home,
                                    color: globalState.theme.menuIcons),
                                onPressed: () async {
                                  await Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => Home()),
                                      (Route<dynamic> route) => false);
                                },
                              ))
                         */
                      ],
                    )
                  : Container(),
            ]),
            /*Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                        padding: EdgeInsets.only(top: 50, left: 2),
                        child: FloatingActionButton(
                            heroTag: "back",
                            backgroundColor: Colors.transparent,
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Icon(Icons.arrow_back_ios,
                                color: globalState.theme.buttonDisabled))))*/
          ]))),
    );
  }
}
