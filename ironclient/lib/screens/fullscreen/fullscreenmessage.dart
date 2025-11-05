import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/gradientbutton.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/utils/launchurls.dart';

class CircleMessageFullScreen extends StatefulWidget {
  final String body;
  final Color messageColor;
  final CircleObject? object;
  final Function? fileHandler;

  const CircleMessageFullScreen({
    Key? key,
    required this.body,
    required this.messageColor,
    this.object,
    this.fileHandler,
  }) : super(key: key);
  // final String title;

  @override
  _CircleMessageFullScreenState createState() =>
      _CircleMessageFullScreenState();
}

class _CircleMessageFullScreenState extends State<CircleMessageFullScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = globalState.setScaler(MediaQuery.of(context).size.width,
      mediaScaler: MediaQuery.textScalerOf(context));
    double maxWidth = InsideConstants.getDisappearingMessagesWidth(screenWidth);

    _networkImage(image) {
      return SizedBox(
          width: maxWidth,
          child: Center(
              child: Container(
                  constraints: BoxConstraints(maxWidth: maxWidth - 10),
                  child: Padding(
                      padding: const EdgeInsets.only(top: 5, bottom: 10),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: image, fit: BoxFit.scaleDown,
                            errorWidget: (context, url, error) => Container(),
                          )
                      )
                  )
              )
          )
      );
    }

    final makeBody = Container(
        // decoration: BoxDecoration(color: Color.fromRGBO(58, 66, 86, 1.0)),
        padding: const EdgeInsets.only(left: 8, right: 10, top: 0, bottom: 10),
        child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
              constraints: const BoxConstraints(),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    widget.object != null && widget.object!.type == CircleObjectType.CIRCLELINK
                      ? Padding(
                        padding: const EdgeInsets.only(),
                        child: InkWell(
                          onTap: () =>
                              LaunchURLs.launchURLForCircleObject(
                            context, widget.object!),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  widget.object!.link == null
                                    ? Text(
                                    AppLocalizations.of(context)!.couldNotLoadLink,
                                    textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                  )
                                      : widget.object!.link!.image!.isEmpty
                                        ? _networkImage(widget.object!.link!.url)
                                        : _networkImage(widget.object!.link!.image)
                                ]
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Padding(
                                    padding: EdgeInsets.only(left: 0)
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(),
                                    child: Column(
                                      children: <Widget>[
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: maxWidth
                                          ),
                                          child: widget.object!.link == null
                                            ? Container()
                                            : Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: <Widget>[
                                              widget.object!.link!.title!.isNotEmpty
                                                ? Padding(
                                                  padding: const EdgeInsets.only(bottom: 3, left: 10, right: 5),
                                                child: Text(
                                                  widget.object!.link!.title!,
                                                  textScaler: TextScaler.linear(globalState.messageScaleFactor),
                                                  maxLines: 4,
                                                  textAlign: TextAlign.left,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(fontSize: 14, color: globalState.theme.linkTitle),
                                                ))
                                                  : Container(),
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 3, left: 10, right: 5),
                                                child: Text(
                                                  widget.object!.link!.url!,
                                                  textAlign: TextAlign.left,
                                                  textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                                  style: TextStyle(fontSize: widget.object!.link!.title == "" ? 14 : 11, color: globalState.theme.url),
                                                )
                                              )
                                            ]
                                          )
                                        )
                                      ]
                                    )
                                  )
                                ]
                              )
                            ]
                          )
                        )
                      )
                      : Container(),
                    Padding(
                        padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 20),
                        child: Text(
                          widget.body,
                          style: TextStyle(
                              fontSize: 16, color: widget.messageColor),
                        )),
                    widget.fileHandler == null
                      ? Container()
                      : Row(
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: GradientButton(
                            width: MediaQuery.of(context).size.width,
                            text: AppLocalizations.of(context)!.vIEWFILE,
                            onPressed: () {
                              widget.fileHandler!(widget.object);
                            }
                            )
                        )
                      ]
                    )
                  ])),
        ));

    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: globalState.theme.background,
        appBar: ICAppBar(
          title: AppLocalizations.of(context)!.oneTimeViewMessage,
        ),
        body: SafeArea(
          left: false,
          top: false,
          right: false,
          bottom: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(child: makeBody),
            ],
          ),
        ));
  }
}
