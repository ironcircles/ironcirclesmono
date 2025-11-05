import 'dart:io';
import 'dart:typed_data';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class SelectThumbnail extends StatefulWidget {
  final File video;
  final int startFrame;
  final int duration;

  const SelectThumbnail({
    Key? key,
    required this.video,
    this.startFrame = 0,
    this.duration = 300,
  }) : super(key: key);

  @override
  State<SelectThumbnail> createState() => _SelectThumbnailState();
}

class _SelectThumbnailState extends State<SelectThumbnail> {
  double _value = 0;
  Uint8List? _thumbnail;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    //_thumbnail = VideoThumbnail.thumbnailData(video: widget.video.path);

    _value = widget.startFrame.toDouble();

    _getThumbnail();

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final makeBottom = Container(
      //height: 120.0,
      //width: 250,
      child: Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 5),
        child: Column(
            //crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Row(children: <Widget>[
                Expanded(
                  flex: 1,
                  child: GradientButton(
                      text: AppLocalizations.of(context)!.selectUC,
                      onPressed: () {
                        _select();
                        // _createList();
                      }),
                ),
              ]),
            ]),
      ),
    );

    return Scaffold(
      backgroundColor: globalState.theme.background,
      key: _scaffoldKey,
      appBar: ICAppBar(
        title: AppLocalizations.of(context)!.selectThumbnailTitle,
      ),
      body: SafeArea(
        left: false,
        top: false,
        right: false,
        bottom: true,
        child: Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, bottom: 0),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Row(children: [
                      IconButton(
                          icon: Icon(Icons.arrow_back_ios_rounded,
                              color: globalState.theme.buttonIcon),
                          iconSize: 25,
                          /*iconSize: 22,*/
                          //constraints: BoxConstraints(maxHeight: 20),
                          onPressed: () {
                            _value = _value - 1;

                            if (_value < 0) _value = 0.0;

                            _getThumbnail();
                          }),
                      Expanded(
                          child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor:
                                    globalState.theme.sliderActive,
                                inactiveTrackColor:
                                    globalState.theme.sliderInactive,
                                trackShape: const RoundedRectSliderTrackShape(),
                                trackHeight: 4.0,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 12.0),
                                thumbColor: globalState.theme.sliderActive,
                                overlayColor: Colors.red.withAlpha(32),
                                overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 28.0),
                                tickMarkShape: const RoundSliderTickMarkShape(),
                                activeTickMarkColor:
                                    globalState.theme.sliderActive,
                                inactiveTickMarkColor:
                                    globalState.theme.sliderInactive,
                                valueIndicatorShape:
                                    const PaddleSliderValueIndicatorShape(),
                                valueIndicatorColor:
                                    globalState.theme.sliderActive,
                                valueIndicatorTextStyle: TextStyle(
                                  color: globalState.theme.sliderLabel,
                                ),
                              ),
                              child: Slider(
                                divisions: widget.duration,
                                label: (_value / 60).toStringAsFixed(2),
                                value: _value,
                                min: 0,
                                max: widget.duration.toDouble(),
                                onChanged: (value) {
                                  setState(() {
                                    _value = value;
                                  });
                                },
                                onChangeEnd: (value) {
                                  _getThumbnail();
                                },
                              ))),
                      IconButton(
                          icon: Icon(Icons.arrow_forward_ios_rounded,
                              color: globalState.theme.buttonIcon),
                          iconSize: 25,
                          /*iconSize: 22,*/
                          //constraints: BoxConstraints(maxHeight: 20),
                          onPressed: () {
                            _value = _value + 1;

                            if (_value > widget.duration)
                              _value = widget.duration.toDouble();

                            _getThumbnail();
                          }),
                    ]),
                    _thumbnail == null
                        ? Container()
                        : ConstrainedBox(
                            constraints: BoxConstraints(
                                maxWidth:
                                    (MediaQuery.of(context).size.width - 10),
                                maxHeight:
                                    MediaQuery.of(context).size.height - 260),
                            child: Image.memory(_thumbnail!),
                          ),
                    const Spacer(),
                    Container(
                      //  color: Colors.white,
                      padding: const EdgeInsets.all(0.0),
                      child: makeBottom,
                    ),
                  ],
                ),
                _showSpinner ? Center(child: spinkit) : Container(),
              ],
            )),
      ),
    );
  }

  _select() {
    Navigator.pop(context, (_value * 1000).toInt());
  }

  _getThumbnail() async {
    try {

      //return;

      /*debugPrint(widget.startFrame);
      debugPrint(widget.duration);
      debugPrint(_value);
      debugPrint((_value * 1000).toInt());

       */

      _thumbnail = await VideoThumbnail.thumbnailData(
        video: widget.video.path,
        timeMs: (_value * 1000).toInt(), /*quality: 100*/
      );

      setState(() {});
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("SelectThumbnail._getThumbail: $err");
      rethrow;
    }
  }
}
