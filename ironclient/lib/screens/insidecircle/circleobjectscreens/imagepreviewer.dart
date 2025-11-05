import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
import 'package:ironcirclesapp/blocs/videocontrollermedia_bloc.dart';
import 'package:ironcirclesapp/blocs/videocontrollermedia_desktop_bloc.dart';
import 'package:ironcirclesapp/encryption/encryptblob.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/stablediffusionprompt.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/filter.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/markup.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/select_thumbnail.dart';
import 'package:ironcirclesapp/screens/insidecircle/dialogdisappearing.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circlefilewidget.dart';
import 'package:ironcirclesapp/screens/payment/premiumfeaturecheck.dart';
import 'package:ironcirclesapp/screens/stablediffusion/inpainting_tabs.dart';
import 'package:ironcirclesapp/screens/themes/mastertheme.dart';
import 'package:ironcirclesapp/screens/widgets/addcaptiontextbutton.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/dialogselectnetwork.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';
import 'package:ironcirclesapp/screens/widgets/selectnetworkstextbutton.dart';
import 'package:ironcirclesapp/screens/widgets/videomedia.dart';
import 'package:ironcirclesapp/screens/widgets/videomediakit.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/videocache_service.dart';
import 'package:ironcirclesapp/utils/fileutil.dart';
import 'package:ironcirclesapp/utils/imageutil.dart';
import 'package:media_kit/media_kit.dart' as mediakit;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:toggle_switch/toggle_switch.dart' as Toggle;

class ImagePreviewer extends StatefulWidget {
  final MediaCollection media;
  final String screenName;
  final int selectedIndex;
  final bool hiRes;
  final bool streamable;
  final Function? redo;
  final bool wall;
  final List<UserFurnace> userFurnaces;
  final Function? setNetworks;
  final String caption;
  final bool showCaption;
  final bool emojiDisplay;
  final int timer;
  final DateTime? scheduledDate;
  final Function? setScheduled;
  final Function? setTimer;
  final ImageType imageType;

  const ImagePreviewer(
      {Key? key,
      this.imageType = ImageType.image,
      this.selectedIndex = 0,
      required this.media,
      this.screenName = '',
      this.setScheduled,
      this.scheduledDate,
      this.timer = 0,
      this.setTimer,
      required this.hiRes,
      required this.streamable,
      this.wall = false,
      this.userFurnaces = const [],
      this.redo,
      this.caption = '',
      this.showCaption = false,
      this.emojiDisplay = false,
      this.setNetworks})
      : super(key: key);

  @override
  _ImagePreviewerState createState() => _ImagePreviewerState();
}

class _ImagePreviewerState extends State<ImagePreviewer> {
  final ScrollController _scrollController = ScrollController();
  late TransformationController _transformationController;
  final VideoControllerMediaBloc _videoControllerBloc =
      VideoControllerMediaBloc();
  final VideoControllerMediaDesktopBloc _videoControllerMediaDesktopBloc =
      VideoControllerMediaDesktopBloc();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Media? _lastVideoPlayed;
  final int height = 100;
  final int width = 100;
  int _initialIndex = 0;
  int _initialStreamableIndex = 0;
  bool _hiRes = false;
  bool album = false;
  bool _streamable = false;
  List<UserFurnace> _selectedNetworks = [];
  DateTime? _scheduledDate;

  //List<bool> _album = [true, false];

  final spinkit = SpinKitThreeBounce(
    size: 20,
    color: globalState.theme.threeBounce,
  );

  late MediaCollection _images;
  late Media _preview;
  int _selectedIndex = 0;

  bool _showScrolller = false;

  double _heightWithScroller = 390;
  double _heightWithoutScroller = 290;
  double _heightWithoutScrollerHorizontal = 300;
  double _heightWithScrollerHorizontal = 195;

  final double _heightOfNetworkSelector = 20;
  final double _heightOfCaptionSelector = 20;
  String _caption = '';

  late int _timer;

  @override
  void initState() {
    _timer = widget.timer;

    _caption = widget.caption;

    if (widget.wall && widget.userFurnaces.length > 1) {
      _heightWithScroller = _heightWithScroller + _heightOfNetworkSelector;

      ///size of the furnace selector
      _heightWithoutScroller =
          _heightWithoutScroller + _heightOfNetworkSelector;

      _heightWithScrollerHorizontal =
          _heightWithScrollerHorizontal + _heightOfNetworkSelector;

      ///size of the furnace selector
      _heightWithoutScrollerHorizontal =
          _heightWithoutScrollerHorizontal + _heightOfNetworkSelector;
    }

    if (widget.showCaption) {
      _heightWithScroller = _heightWithScroller + _heightOfCaptionSelector;

      ///size of the furnace selector
      _heightWithoutScroller =
          _heightWithoutScroller + _heightOfCaptionSelector;

      _heightWithScrollerHorizontal =
          _heightWithScrollerHorizontal + _heightOfCaptionSelector;

      ///size of the furnace selector
      _heightWithoutScrollerHorizontal =
          _heightWithoutScrollerHorizontal + _heightOfCaptionSelector;
    }

    if (globalState.isDesktop()) {
      _heightWithScroller = _heightWithScroller + 83;
      //_heightWithoutScroller = _heightWithoutScroller + 83;
      _heightWithScrollerHorizontal = _heightWithScrollerHorizontal + 83;
      //_heightWithoutScrollerHorizontal = _heightWithoutScrollerHorizontal + 83;
    }

    _transformationController = TransformationController();

    ///comment out to turn off album
    //if (widget.media.media.length > 1) album = true;

    for (var media in widget.media.media) {
      if (media.mediaType == MediaType.video) {
        media.videoState = VideoStateIC.NEEDS_CHEWIE;

        if (media.file.lengthSync() >= EncryptBlob.maxForEncrypted) {
          media.streamable = true;
          media.requireStreaming = true;
          _streamable = true;
        }
      } else if (media.mediaType != MediaType.gif) {
        if (media.file.lengthSync() >= EncryptBlob.maxForEncrypted) {
          media.tooLarge = true;
        }
      }
    }

    _hiRes = widget.hiRes;

    _selectedIndex = widget.selectedIndex;
    _images = widget.media;
    _preview = _images.media[_selectedIndex];
    //_videoControllerBloc.add(_preview);

    if (widget.media.media.length > 1) _showScrolller = true;

    super.initState();
  }

  _takeScreenShot() {}
  void _predispose(Media media) {
    if (media.videoState == VideoStateIC.VIDEO_READY) {
      _videoControllerBloc.predispose(media);
      _videoControllerMediaDesktopBloc.predispose(media);
      if (mounted)
        // setState(() {
        media.videoState = VideoStateIC.NEEDS_CHEWIE;
      //  });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _videoControllerBloc.disposeLast();

      if (globalState.isDesktop()) {
        _videoControllerMediaDesktopBloc.disposeAll();
      }
    });

    super.dispose();
  }

  void _shutdownLastController() {
    if (_lastVideoPlayed != null) {
      _videoControllerBloc.pauseLast();
      _videoControllerMediaDesktopBloc
          .pause(_images.media[_selectedIndex].seed);

      _videoControllerBloc.predispose(_lastVideoPlayed);
      _videoControllerMediaDesktopBloc.predispose(_lastVideoPlayed);
      setState(() {
        _lastVideoPlayed!.videoState = VideoStateIC.NEEDS_CHEWIE;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _videoControllerBloc.disposeObject(_lastVideoPlayed);
        _videoControllerMediaDesktopBloc.disposeObject(_lastVideoPlayed);
      });
    }
  }

  _pauseControllers() async {
    if (globalState.isDesktop()) {
      _videoControllerMediaDesktopBloc
          .pause(widget.media.media[_selectedIndex].seed);
    } else if (_lastVideoPlayed != null) {
      _videoControllerBloc.pauseLast();
    }
  }

  void _playVideo(Media media) async {
    if (globalState.isDesktop()) {
      await _videoControllerMediaDesktopBloc.add(
          media, true, _playVideoCallback);
    } else {
      _shutdownLastController();
      await _videoControllerBloc.add(media, true);

      _playVideoCallback(media);
    }

    // if (globalState.isDesktop()) {
    //   mediakit.Player? videoPlayer =
    //       _videoControllerMediaDesktopBloc.fetchPlayer(media.seed);
    //
    //   if (videoPlayer != null) {
    //     // final mediakit.Media media =
    //     // await mediakit.Media.file(circleObject.video!.videoBytes!);
    //
    //     await videoPlayer.open(mediakit.Media(media.path));
    //
    //     setState(() {});
    //   }
    // }
  }

  void _playVideoCallback(Media media) async {
    _lastVideoPlayed = media;

    setState(() {
      media.videoState = VideoStateIC.VIDEO_READY;
    });

    if (globalState.isDesktop()) {
      mediakit.Player? videoPlayer =
          _videoControllerMediaDesktopBloc.fetchPlayer(_preview.seed);

      if (videoPlayer != null) {
        await videoPlayer.open(mediakit.Media(media.path));

        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    double textScale = MediaQuery.textScalerOf(context).scale(1);

    Widget image(Media media, BoxFit boxFit) {
      return media.object != null && media.object!.image!.imageBytes != null
          ? Image.memory(
              media.object!.image!.imageBytes!,
              fit: boxFit,
            )
          : Image.file(
              File(media.path),
              fit: boxFit,
            );
    }

    final _scroller = Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 0),
      child: Column(children: <Widget>[
        SizedBox(
            height: 100, //isPortrait ? height + 5.0 : height - 50
            width: MediaQuery.of(context).size.width - 20,
            child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: ReorderableListView.builder(
                    onReorder: (int oldIndex, int newIndex) {
                      setState(() {
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }
                        final Media item = _images.media.removeAt(oldIndex);
                        _images.media.insert(newIndex, item);
                      });
                    },
                    itemCount: _images.media.length,
                    padding: const EdgeInsets.only(right: 0, left: 0),
                    scrollController: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (BuildContext context, int index) {
                      return Padding(
                          key: Key(_images.media[index].seed),
                          padding: const EdgeInsets.only(right: 10),
                          child: InkWell(
                              onTap: () {
                                debugPrint('on tap');

                                _selectedIndex = index;

                                if (globalState.isDesktop()) {
                                  _pauseControllers();
                                } else {
                                  _videoControllerBloc.predispose(_preview);
                                }
                                // _videoControllerBloc.disposeObject(_preview);
                                _preview.videoState = VideoStateIC.NEEDS_CHEWIE;
                                _preview = _images.media[index];
                                _transformationController =
                                    TransformationController();

                                if (mounted) setState(() {});

                                if (globalState.isDesktop() &&
                                    _preview.mediaType == MediaType.video) {
                                  VideoController? videoController =
                                      _videoControllerMediaDesktopBloc
                                          .fetchController(_preview.seed);

                                  if (videoController != null) {
                                    videoController.player.jump(0);
                                    videoController.player.play();
                                  }
                                }

                                // _videoControllerBloc.add(_preview);
                              },
                              child: ConstrainedBox(
                                  //is this the actual image display in chat?
                                  constraints: const BoxConstraints(
                                      maxHeight: 170, maxWidth: 250),
                                  child: _images.media[index].mediaType ==
                                          MediaType.image
                                      ? image(
                                          _images.media[index], BoxFit.cover)
                                      : _images.media[index].mediaType ==
                                              MediaType.gif
                                          ? CachedNetworkImage(
                                              fit: BoxFit.contain,
                                              imageUrl:
                                                  _images.media[index].path,
                                              placeholder: (context, url) =>
                                                  spinkit,
                                              errorWidget: (context, url,
                                                      error) =>
                                                  const Icon(Icons
                                                      .error), /*Image.network(
                                  circleObject.gif!.giphy!,
                                ),*/
                                            )
                                          : _images.media[index].mediaType ==
                                                  MediaType.video
                                              ? Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                      Image.file(
                                                        File(_images
                                                            .media[index]
                                                            .thumbnail),
                                                        fit: BoxFit.cover,
                                                      ),
                                                      const Icon(
                                                          Icons.play_arrow)
                                                    ])
                                              : _images.media[index].mediaType ==
                                                      MediaType.file
                                                  ? CircleFileWidget(
                                                      maxWidth: 150,
                                                      suppressFilename: true,
                                                      textColor: globalState
                                                          .theme.userObjectText,
                                                      backgroundColor: globalState
                                                          .theme
                                                          .userObjectBackground,
                                                      fileSize: _images
                                                          .media[index].file
                                                          .lengthSync(),
                                                      extension:
                                                          FileSystemService.getExtension(
                                                              _images
                                                                  .media[index]
                                                                  .path),
                                                      name: FileSystemService.getFilename(
                                                          _images.media[index].path)) //Text(FileSystemService.getExtension(_preview.path))
                                                  : Container())));

                      // ]));
                    }))),
      ]),
    );

    final _makeToggle = _preview.mediaType == MediaType.image
        ? Align(
            alignment: Alignment.center,
            child: Toggle.ToggleSwitch(
              minWidth: 90.0,
              //minHeight: 70.0,
              initialLabelIndex: _initialIndex,
              cornerRadius: 20.0,
              activeFgColor: Colors.white,
              inactiveBgColor: Colors.grey,
              inactiveFgColor: Colors.white,
              totalSwitches: 2,
              radiusStyle: true,
              labels: [
                AppLocalizations.of(context)!.efficient,
                AppLocalizations.of(context)!.hires
              ],
              customTextStyles: [
                TextStyle(fontSize: 12 / textScale),
                TextStyle(fontSize: 12 / textScale)
              ],
              //iconSize: 30.0,
              activeBgColors: const [
                [
                  Colors.tealAccent,
                  Colors.teal,
                ],
                [Colors.yellow, Colors.orange]
              ],
              animate: true,
              // with just animate set to true, default curve = Curves.easeIn
              curve: Curves.bounceInOut,
              // animate must be set to true when using custom curve
              onToggle: (index) {
                debugPrint('switched to: $index');
                //_hiRes = !_hiRes;

                setState(() {
                  _hiRes = !_hiRes;
                  _initialIndex = index!;
                });
              },
            ))
        : _preview.mediaType == MediaType.video
            ? Align(
                alignment: Alignment.center,
                child: Toggle.ToggleSwitch(
                  minWidth: 120.0,
                  //minHeight: 70.0,
                  initialLabelIndex: _initialStreamableIndex,
                  cornerRadius: 20.0,
                  activeFgColor: Colors.white,
                  inactiveBgColor: Colors.grey,
                  inactiveFgColor: Colors.white,
                  totalSwitches: 2,
                  radiusStyle: true,
                  labels: [
                    AppLocalizations.of(context)!.e2EEncrypted,
                    AppLocalizations.of(context)!.streamable
                  ],
                  customTextStyles: [
                    TextStyle(fontSize: 12 / textScale),
                    TextStyle(fontSize: 12 / textScale)
                  ],
                  activeBgColors: const [
                    [
                      Colors.tealAccent,
                      Colors.teal,
                    ],
                    [Colors.yellow, Colors.orange]
                  ],
                  animate: true,
                  // with just animate set to true, default curve = Curves.easeIn
                  curve: Curves.bounceInOut,
                  // animate must be set to true when using custom curve
                  onToggle: (index) {
                    debugPrint('switched to: $index');
                    //_hiRes = !_hiRes;
                    setState(() {
                      if (PremiumFeatureCheck.canStreamVideo(context)) {
                        _streamable = !_streamable;
                        _initialStreamableIndex = index!;
                      } else {
                        _streamable = false;
                        _initialStreamableIndex = 0;
                      }

                      if (_selectedIndex != -1) {
                        _images.media[_selectedIndex].streamable = _streamable;
                      }
                    });
                  },
                ))
            : Container();

    final _makeStreamOnly = Column(children: [
      Align(
          alignment: Alignment.center,
          child: Toggle.ToggleSwitch(
            minWidth: 220.0,
            //minHeight: 70.0,
            initialLabelIndex: _initialStreamableIndex,
            cornerRadius: 20.0,
            activeFgColor: Colors.white,
            inactiveBgColor: Colors.grey,
            inactiveFgColor: Colors.white,
            totalSwitches: 1,
            radiusStyle: true,
            labels: const ['video size requires streaming'],
            customTextStyles: [
              TextStyle(
                  fontSize: 12 / MediaQuery.textScalerOf(context).scale(1)),
              //TextStyle(fontSize: 12 / globalState.mediaScaleFactor)
            ],
            activeBgColors: const [
              [Colors.yellow, Colors.orange]
            ],
            animate: true,
            // with just animate set to true, default curve = Curves.easeIn
            curve: Curves.bounceInOut,
            // animate must be set to true when using custom curve
            onToggle: (index) {
              debugPrint('switched to: $index');
              //_hiRes = !_hiRes;

              setState(() {
                _streamable = !_streamable;
                _initialStreamableIndex = index!;
                if (_selectedIndex != -1) {
                  _images.media[_selectedIndex].streamable = _streamable;
                }
              });
            },
          )),
    ]);

    final _makePreview = Stack(alignment: Alignment.topRight, children: [
      Column(children: [
        //Spacer(),
        _preview.mediaType == MediaType.image
            ? ConstrainedBox(
                constraints: BoxConstraints.expand(
                    height: isPortrait
                        ? MediaQuery.of(context).size.height -
                            (_showScrolller
                                ? _heightWithScroller
                                : _heightWithoutScroller)
                        : MediaQuery.of(context).size.height -
                            (_showScrolller
                                ? _heightWithScrollerHorizontal
                                : _heightWithoutScrollerHorizontal)),
                child: InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 0.1,
                    maxScale: 5,
                    child: image(_preview, BoxFit.contain)))
            : _preview.mediaType == MediaType.gif
                ? ConstrainedBox(
                    constraints: BoxConstraints.expand(
                        height: isPortrait
                            ? MediaQuery.of(context).size.height -
                                (_showScrolller
                                    ? _heightWithScroller
                                    : _heightWithoutScroller)
                            : MediaQuery.of(context).size.height -
                                (_showScrolller
                                    ? _heightWithScrollerHorizontal
                                    : _heightWithoutScrollerHorizontal)),
                    child: CachedNetworkImage(
                        fit: BoxFit.contain,
                        imageUrl: _preview.path,
                        placeholder: (context, url) => spinkit,
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error)))
                : _preview.mediaType == MediaType.video
                    ? Center(
                        child: ConstrainedBox(
                        constraints: BoxConstraints.expand(
                            height: isPortrait
                                ? MediaQuery.of(context).size.height -
                                    (_showScrolller
                                        ? _heightWithScroller
                                        : _heightWithoutScroller)
                                : MediaQuery.of(context).size.height -
                                    (_showScrolller
                                        ? _heightWithScrollerHorizontal
                                        : _heightWithoutScrollerHorizontal)),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          globalState
                                  .isDesktop() //Platform.isLinux || Platform.isWindows || Platform.isAndroid
                              ? VideoMediaKitWidget(
                                  width:
                                      (MediaQuery.of(context).size.width - 50),
                                  height: isPortrait
                                      ? MediaQuery.of(context).size.height -
                                          (_showScrolller
                                              ? _heightWithScroller
                                              : _heightWithoutScroller) -
                                          68
                                      : MediaQuery.of(context).size.height -
                                          (_showScrolller
                                              ? _heightWithScrollerHorizontal
                                              : _heightWithoutScrollerHorizontal) -
                                          68,
                                  video: _preview,
                                  play: _playVideo,
                                  videoController:
                                      _videoControllerMediaDesktopBloc
                                          .fetchController(_preview.seed),
                                  videoControllerBloc:
                                      _videoControllerMediaDesktopBloc,
                                  dispose: _predispose)
                              : VideoMediaWidget(
                                  width:
                                      (MediaQuery.of(context).size.width - 50),
                                  height: isPortrait
                                      ? MediaQuery.of(context).size.height -
                                          (_showScrolller
                                              ? _heightWithScroller
                                              : _heightWithoutScroller) -
                                          68
                                      : MediaQuery.of(context).size.height -
                                          (_showScrolller
                                              ? _heightWithScrollerHorizontal
                                              : _heightWithoutScrollerHorizontal) -
                                          68,
                                  video: _preview,
                                  play: _playVideo,
                                  chewieController: _videoControllerBloc
                                      .fetchController(_preview),
                                  videoControllerBloc: _videoControllerBloc,
                                  dispose: _predispose),
                          globalState.isDesktop()
                              ? Container()
                              : TextButton(
                                  child: Text(
                                    AppLocalizations.of(context)!
                                        .selectThumbnail,
                                    textScaler: const TextScaler.linear(1.0),
                                    style: TextStyle(
                                        color: globalState.theme.buttonIcon),
                                  ),
                                  /*iconSize: 22,*/
                                  //constraints: BoxConstraints(maxHeight: 20),
                                  onPressed: () async {
                                    _selectThumbnail();
                                  },
                                )
                        ]),
                      ))
                    : _preview.mediaType == MediaType.file
                        ? Center(
                            child: ConstrainedBox(
                            constraints:
                                const BoxConstraints.expand(height: 150),
                            child: CircleFileWidget(
                                largePreview: true,
                                maxWidth:
                                    MediaQuery.of(context).size.width - 100,
                                textColor: globalState.theme.userObjectText,
                                backgroundColor:
                                    globalState.theme.userObjectBackground,
                                fileSize: _preview.file.lengthSync(),
                                extension: FileSystemService.getExtension(
                                    _preview.path),
                                name: FileSystemService.getFilename(
                                    _preview.path)),
                          ))
                        : Container(),
      ]),
      (_preview.tooLarge)
          ? Container(
              padding: const EdgeInsets.all(InsideConstants.MESSAGEPADDING),
              //color: globalState.theme.dropdownBackground,
              decoration: const BoxDecoration(
                  color: Colors.red,
                  // .circleObjectBackground,
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(5.0),
                      bottomRight: Radius.circular(5.0),
                      topLeft: Radius.circular(5.0),
                      topRight: Radius.circular(5.0))),
              child: const Text("too large",
                  style: TextStyle(color: Colors.white)))
          : Container()
    ]);

    final topAppBar = AppBar(
      elevation: 0,
      toolbarHeight: 40,
      centerTitle: false,
      titleSpacing: 0.0,
      iconTheme: IconThemeData(
        color: globalState.theme.menuIcons, //change your color here
      ),
      backgroundColor: globalState.theme.appBar,
      leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.redo != null) {
              Navigator.pop(context);
              widget.redo!();
            } else {
              Navigator.pop(
                  context,
                  SelectedMedia(
                    hiRes: false,
                    streamable: false,
                    album: album,
                    mediaCollection: widget.emojiDisplay == true
                        ? _images
                        : MediaCollection(),
                  ));
            }
          }),
      //backgroundColor: Colors.black,
      title: Text(widget.screenName,
          textScaler: TextScaler.linear(globalState.screenNameScaleFactor),
          style: ICTextStyle.getStyle(
              context: context,
              color: globalState.theme.textTitle,
              fontSize: ICTextStyle.appBarFontSize)),
      // actions: <Widget>[
      //
      // ],
    );

    final lowerAppBar = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(),
        _preview.mediaType == MediaType.image
            ? Padding(
                padding: const EdgeInsets.only(
                  right: 5,
                ),
                child: InkWell(
                  onTap: _inpainting,
                  child: ICText(
                    AppLocalizations.of(context)!.inpaint,
                    color:
                        globalState.theme.buttonGenerate, // .withOpacity(.2),
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ))
            : Container(),
        // _preview.mediaType == MediaType.image
        //     ? IconButton(
        //         icon: const Icon(Icons.filter_vintage_outlined),
        //         onPressed: _filter)
        //     : Container(),
        IconButton(
            icon: Icon(Icons.remove, color: globalState.theme.menuIcons),
            onPressed: _drop),
        _preview.mediaType == MediaType.image
            ? IconButton(
                icon: Icon(Icons.brush, color: globalState.theme.menuIcons),
                onPressed: _markup)
            : Container(),
        _preview.mediaType == MediaType.image
            ? IconButton(
                icon: Icon(Icons.crop, color: globalState.theme.menuIcons),
                onPressed: _crop)
            : Container()
      ],
    );
    return SafeArea(
      left: false,
      top: false,
      right: true,
      bottom: true,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        //need this to be called only once if someone sends more than 3 photos?
        backgroundColor: globalState.theme.background,
        // resizeToAvoidBottomInset: false,
        key: _scaffoldKey,
        appBar: topAppBar, // ICAppBar(title:widget.screenName,), //topAppBar,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            lowerAppBar,
            isPortrait == false &&
                    _showScrolller &&
                    (Platform.isAndroid || Platform.isIOS)
                ? Container()
                : Expanded(child: _makePreview),
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
            ),
            _showScrolller ? _scroller : const SizedBox(),
            Padding(
              padding: EdgeInsets.only(top: isPortrait ? 10 : 0, bottom: 0),
            ),

            ///select a furnace to post to
            widget.userFurnaces.length > 1 &&
                    widget.wall &&
                    widget.setNetworks != null
                ? Row(children: <Widget>[
                    Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 3, left: 10, right: 10),
                          child: SelectNetworkTextButton(
                            userFurnaces: widget.userFurnaces,
                            selectedNetworks: _selectedNetworks,

                            ///always make the user choose the network
                            callback: _setNetworks,
                          ),
                        ))
                  ])
                : Container(),

            ///add a caption
            widget.showCaption
                ? WrapperWidget(
                    child: Padding(
                        padding: const EdgeInsets.only(
                            left: 15, right: 15, bottom: 10),
                        child: Container(
                            padding: const EdgeInsets.only(
                              left: 10,
                            ),
                            height: _timer == UserDisappearingTimer.OFF &&
                                    _scheduledDate == null
                                ? 40
                                : 46,
                            decoration: BoxDecoration(
                                color: globalState.theme.labelTextSubtle
                                    .withOpacity(.2),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(10))),
                            child: Row(children: <Widget>[
                              Expanded(
                                  flex: 2,
                                  child: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 3, left: 10, right: 0),
                                      child: AddCaptionTextButton(
                                          existingCaption: _caption,
                                          callback: _setCaption))),
                              widget.wall == false
                                  ? _timer == UserDisappearingTimer.OFF &&
                                          _scheduledDate == null
                                      ? SizedBox(
                                          width: 30,
                                          child: IconButton(
                                            icon: Icon(Icons.timer,
                                                color: globalState
                                                    .theme.buttonDisabled),
                                            iconSize: 24,
                                            onPressed: () {
                                              _showTimer();
                                            },
                                          ))
                                      : Padding(
                                          padding: const EdgeInsets.only(
                                              top: 5, right: 10, left: 12),
                                          child: _scheduledDate != null
                                              ? buildButtonColumn(
                                                  Icons.timer,
                                                  globalState.theme
                                                      .bottomHighlightIcon,
                                                  _showTimer,
                                                  GlobalKey(),
                                                  iconSize: 24)
                                              : InkWell(
                                                  onTap: _showTimer,
                                                  child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons.timer,
                                                          color: globalState
                                                              .theme
                                                              .bottomHighlightIcon,
                                                          size: 24 -
                                                              globalState
                                                                  .scaleDownIcons,
                                                        ),
                                                        Text(
                                                          _getShortTimerString(),
                                                          textScaler:
                                                              const TextScaler
                                                                  .linear(1.0),
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              color: globalState
                                                                  .theme
                                                                  .bottomHighlightIcon),
                                                        )
                                                      ])))
                                  : Container(),
                              // widget.media.media.length > 1
                              //     ? Padding(
                              //         padding: const EdgeInsets.only(left: 5),
                              //         child: SizedBox(
                              //             width: 30,
                              //             child: IconButton(
                              //               icon: Icon(Icons.photo_album,
                              //                   color: album
                              //                       ? globalState.theme
                              //                           .bottomHighlightIcon
                              //                       : globalState
                              //                           .theme.buttonDisabled),
                              //               iconSize: 24,
                              //               onPressed: () {
                              //                 _toggleAlbum();
                              //               },
                              //             )))
                              //     : Container(),
                              const Padding(
                                padding: EdgeInsets.only(right: 15),
                              ),
                            ]))))
                : Container(),

            Row(children: [
              //Padding(padding: EdgeInsets.only(left:10),),
              //Padding(padding: EdgeInsets.only(left: 50)),
              widget.redo != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: FloatingActionButton(
                        heroTag: "redo",
                        onPressed: () {
                          Navigator.pop(context);
                          widget.redo!();
                        },
                        backgroundColor: globalState.theme.background,
                        child: Icon(
                          Icons.redo,
                          size: 30,
                          color: globalState.theme.menuIcons,
                        ),
                      ))
                  : Container(), //const Spacer(),
              const Spacer(),
              widget.imageType == ImageType.image
                  ? _preview.requireStreaming
                      ? _makeStreamOnly
                      : _makeToggle
                  : Container(),
              const Spacer(),
              FloatingActionButton(
                onPressed: () {
                  _checkNetworkAndSizes();
                },
                backgroundColor: globalState.theme.background,
                elevation: 0,
                child: widget.imageType == ImageType.image
                    ? Icon(
                        Icons.send_rounded,
                        size: 30 - globalState.scaleDownIcons,
                        color: globalState.theme.button,
                      )
                    : ICText(
                        "SET",
                        color: globalState.theme.button,
                      ),
              ),
            ]),
            //_makeToggle,
            // Padding(
            //   padding: EdgeInsets.only(bottom: isPortrait ? 8 : 0),
            // ),
          ],
        ),
      ),
    );
  }

  _crop() async {
    if (globalState.isDesktop() && _preview.object != null) {
      await _cacheToFileForDesktop();
    }

    File? croppedFile = await ImageUtil.cropImage(context, File(_preview.path));

    if (croppedFile != null) {
      _images.media[_selectedIndex].path = croppedFile.path;
      _preview.setFromFile(File(croppedFile.path), MediaType.image);
      //state = AppState.cropped;
      if (mounted) setState(() {});
    }
  }

  _cacheToFileForDesktop() async {
    String filePath = await FileSystemService.returnTempPathAndImageFile();
    File? image = await FileUtil.writeBytesToFile(
        filePath, _preview.object!.image!.imageBytes!);

    if (image == null) {
      return;
    } else {
      _preview.file = image;
      _preview.object = null;
    }
  }

  _inpainting() async {
    if (globalState.isDesktop() && _preview.object != null) {
      await _cacheToFileForDesktop();
    }

    SelectedMedia? selectedMedia = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InPaintingTabs(
          original: _preview.file,
          userFurnace: globalState.userFurnace!,
          imageGenType: ImageType.image,
        ),
      ),
    );

    if (selectedMedia != null &&
        selectedMedia.mediaCollection.media.isNotEmpty) {
      _images.media[_selectedIndex].path =
          selectedMedia.mediaCollection.media[0].file.path;
      _preview.setFromFile(
          File(selectedMedia.mediaCollection.media[0].file.path),
          MediaType.image);
    }






    if (mounted) {
      setState(() {});
    }
  }


  _filter() async {

    return;
    //
    // if (globalState.isDesktop() && _preview.object != null) {
    //   await _cacheToFileForDesktop();
    // }
    //
    // File? result = await Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //         builder: (context) => Filter(
    //               image: _preview.file,
    //             )));
    //
    // if (result != null) {
    //   setState(() {
    //     _images.media[_selectedIndex].setFromFile(result, MediaType.image);
    //     _preview.setFromFile(result, MediaType.image);
    //   });
    // }
  }

  _markup() async {
    if (globalState.isDesktop() && _preview.object != null) {
      await _cacheToFileForDesktop();
    }

    File? result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Markup(
                  source: _preview.file,
                ))); //.then(_circleObjectBloc.requestNewerThan(

    if (result != null) {
      setState(() {
        _images.media[_selectedIndex].setFromFile(result, MediaType.image);
        _preview.setFromFile(result, MediaType.image);
      });
    }
  }

  _drop() {
    _images.media.removeAt(_selectedIndex);

    if (_images.media.isEmpty) {
      Navigator.pop(context);
    } else {
      setState(() {
        if (_selectedIndex == 0)
          _preview = _images.media[_selectedIndex];
        else {
          _selectedIndex = _selectedIndex - 1;
          _preview = _images.media[_selectedIndex];
        }
      });
    }
  }

  _selectThumbnail() async {
    if (_videoControllerBloc.fetchController(_preview) == null) {
      await _videoControllerBloc.add(_preview, false);
    }

    _lastVideoPlayed = _preview;

    Duration duration = _videoControllerBloc
        .fetchController(_preview)!
        .videoPlayerController
        .value
        .duration;

    int durationInSeconds = duration.inSeconds;

    if (mounted) {
      _preview.thumbIndex = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SelectThumbnail(
              video: File(_preview.path),
              startFrame: 0,
              duration: durationInSeconds,
            ),
          ));

      _preview.thumbnail = (await VideoCacheService.cacheTempVideoPreview(
              _preview.path, _preview.thumbIndex))
          .path;

      if (globalState.isDesktop() == false) {
        _shutdownLastController();
      }

      setState(() {});
    }
  }

  _checkNetworkAndSizes() {
    bool canContinue =
        PremiumFeatureCheck.checkFileSizeRestriction(context, _hiRes, _images);

    if (canContinue) {
      if (widget.wall &&
          widget.userFurnaces.length > 1 &&
          _selectedNetworks.isEmpty) {
        DialogSelectNetworks.selectNetworks(
            context: context,
            networks: widget.userFurnaces,
            callback: _setNetworksAndPost,
            existingNetworksFilter: _selectedNetworks);
      } else {
        //UserFurnace userFurnace = _selected!.object as UserFurnace;

        Navigator.pop(
            context,
            SelectedMedia(
                //userFurnace: widget.userFurnaces[0],
                userFurnace: widget.userFurnaces[0],
                hiRes: _hiRes,
                caption: _caption,
                album: album,
                streamable: _streamable,
                mediaCollection: _images));
      }
    } else
      setState(() {});
  }

  ///callback for the automatic popup
  _setNetworksAndPost(List<UserFurnace> newlySelectedNetworks) {
    if (widget.setNetworks != null) {
      widget.setNetworks!(newlySelectedNetworks);

      //UserFurnace userFurnace = _selected!.object as UserFurnace;

      _selectedNetworks = newlySelectedNetworks;
      Navigator.pop(
          context,
          SelectedMedia(
              userFurnace: newlySelectedNetworks[0],
              hiRes: _hiRes,
              album: album,
              streamable: _streamable,
              mediaCollection: _images,
              caption: _caption));
    }
  }

  ///callback for the ui control tap
  _setNetworks(List<UserFurnace> newlySelectedNetworks) {
    if (widget.setNetworks != null) {
      widget.setNetworks!(newlySelectedNetworks);
      setState(() {
        _selectedNetworks = newlySelectedNetworks;
      });
    }
  }

  ///callback for the caption collector
  _setCaption(String newCaption) {
    setState(() {
      _caption = newCaption;
    });
  }

  _showTimer() {
    _closeKeyboard();
    DialogDisappearing.setTimer(context, _timerCallback, _getDateTimeSchedule);
  }

  _timerCallback(int timer) {
    _timer = timer;
    widget.setTimer!(_timer);
  }

  String _getShortTimerString() {
    if (_timer == UserDisappearingTimer.ONE_TIME_VIEW) return 'OTV';
    if (_timer == UserDisappearingTimer.TEN_SECONDS) return '10s';
    if (_timer == UserDisappearingTimer.THIRTY_SECONDS) return '30s';
    if (_timer == UserDisappearingTimer.ONE_MINUTE) return '1m';
    if (_timer == UserDisappearingTimer.FIVE_MINUTES) return '5m';
    if (_timer == UserDisappearingTimer.ONE_HOUR) return '1h';
    if (_timer == UserDisappearingTimer.EIGHT_HOURS) return '8h';
    if (_timer == UserDisappearingTimer.ONE_DAY) return '24h';

    return '';
  }

  _closeKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  _getDateTimeSchedule() async {
    DateTime? date = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate:
          DateTime(DateTime.now().year + 5), //should maximum be less than that?
      initialDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1),
            ),
            child: globalState.theme.themeMode == ICThemeMode.dark
                ? Theme(
                    data: ThemeData.dark().copyWith(
                      primaryColor: globalState.theme.button,
                      //accentColor:  globalState.theme.button,
                      colorScheme:
                          ColorScheme.dark(primary: globalState.theme.button),
                      buttonTheme: const ButtonThemeData(
                          textTheme: ButtonTextTheme.primary),
                    ),
                    child: child!,
                  )
                : Theme(
                    data: ThemeData.light().copyWith(
                      primaryColor: globalState.theme.button,
                      //accentColor:  globalState.theme.button,
                      colorScheme:
                          ColorScheme.light(primary: globalState.theme.button),
                      buttonTheme: const ButtonThemeData(
                          textTheme: ButtonTextTheme.primary),
                    ),
                    child: child!,
                  ));
      },
    );

    if (date != null) {
      TimeOfDay? time = await showTimePicker(
          initialTime: TimeOfDay.now(),
          context: context,
          builder: (BuildContext context, Widget? child) {
            return MediaQuery(
                data: const MediaQueryData(
                  textScaler: TextScaler.linear(1),
                ),
                child: globalState.theme.themeMode == ICThemeMode.dark
                    ? Theme(
                        data: ThemeData.dark().copyWith(
                          primaryColor: globalState.theme.button,
                          //accentColor:  globalState.theme.button,
                          colorScheme: ColorScheme.dark(
                              primary: globalState.theme.button),
                          buttonTheme: const ButtonThemeData(
                              textTheme: ButtonTextTheme.primary),
                        ),
                        child: child!,
                      )
                    : Theme(
                        data: ThemeData.light().copyWith(
                          primaryColor: globalState.theme.button,
                          //accentColor:  globalState.theme.button,
                          colorScheme: ColorScheme.light(
                              primary: globalState.theme.button),
                          buttonTheme: const ButtonThemeData(
                              textTheme: ButtonTextTheme.primary),
                        ),
                        child: child!,
                      ));
          });

      if (time != null) {
        setState(() {
          _scheduledDate =
              DateTime(date.year, date.month, date.day, time.hour, time.minute);
          if (_scheduledDate!.isBefore(DateTime.now())) {
            _scheduledDate = null;
            DialogNotice.showNotice(context, "Invalid Time",
                "Select a time past now.", "", "", "", false);
          } else {
            widget.setScheduled!(_scheduledDate);
          }
        });
      }
    }
  }

  IconButton buildButtonColumn(
      IconData icon, Color? color, Function onClick, Key key,
      {double iconSize = 37}) {
    // Color color = Theme.of(context).primaryColor;

    return IconButton(
      key: key,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      iconSize: iconSize - globalState.scaleDownIcons,
      icon: Icon(
        icon,
        size: iconSize - globalState.scaleDownIcons,
      ),
      onPressed: onClick as void Function()?,

      color: color,
      //size: iconSize,
    );
  }

  _toggleAlbum() {
    setState(() {
      album = !album;
    });
  }
}
