import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/dialogcamera.dart';
import 'package:ironcirclesapp/screens/widgets/formattedsnackbar.dart';
import 'package:toggle_switch/toggle_switch.dart' as Toggle;

enum CameraEntryMode {
  insideCircle,
  library,
}

class CapturedMediaResults {
  //final bool isVideo;
  //final bool isShrunk;
  //final String path;
  final MediaCollection mediaCollection;

  CapturedMediaResults(
      {required this.mediaCollection /*, required this.isShrunk*/});
}

class CaptureMedia extends StatefulWidget {
  @override
  _CaptureMediaState createState() {
    return _CaptureMediaState();
  }
}

class CaptureState {
  double minAvailableExposureOffset;
  double maxAvailableExposureOffset;
  double currentExposureOffset;
  FocusMode focusMode;
  FlashMode flashMode;
  ExposureMode exposureMode;

  CaptureState(
      {this.minAvailableExposureOffset = 0.0,
      this.maxAvailableExposureOffset = 0.0,
      this.currentExposureOffset = 0.0,
      this.focusMode = FocusMode.auto,
      this.flashMode = FlashMode.off,
      this.exposureMode = ExposureMode.auto});
}

class _CaptureMediaState extends State<CaptureMedia>
    with WidgetsBindingObserver {
  CameraController? controller;
  //String videoPath = '';

  //CaptureState _captureState = CaptureState();

  List<CameraDescription>? cameras;
  int? selectedCameraIdx;
  bool enableAudio = true;
  bool _showSend = false;
  bool _recording = false;
  bool _shrink = false;
  bool _capturing = false;
  int _initialIndex = 0;
  bool _video = false;
  bool _cameraDialogOpen = false;

  int _pointers = 0;
  double _minAvailableZoom = 1;
  double _maxAvailableZoom = 1;
  double _currentScale = 1;
  double _baseScale = 1;
  MediaCollection _mediaCollection = MediaCollection();

  //FlashMode flashMode = FlashMode.auto;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    globalState.globalEventBloc.applicationStateChanged.listen((msg) {
      handleAppLifecycleState(msg);
    }, onError: (error, trace) {
      LogBloc.insertError(error, trace);
    }, cancelOnError: false);

    WidgetsBinding.instance.addPostFrameCallback((_) => initCam());

    //WidgetsBinding.instance!.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    //_ambiguate(WidgetsBinding.instance)?.removeObserver(this);
    //_flashModeControlRowAnimationController.dispose();
    //_exposureModeControlRowAnimationController.dispose();
    super.dispose();
  }

  handleAppLifecycleState(AppLifecycleState msg) {
    final CameraController? cameraController = controller;
    if (cameraController != null && cameraController.value.isInitialized) {
      switch (msg) {
        case AppLifecycleState.paused:
          break;
        case AppLifecycleState.inactive:
          cameraController.dispose();
          break;
        case AppLifecycleState.resumed:
          onNewCameraSelected(cameraController.description);
          break;
        case AppLifecycleState.detached:
          break;
        case AppLifecycleState.hidden:
          break;
      }
    }
  }

  /*initCam() {
    selectedCameraIdx = 0;

    onNewCameraSelected(
        globalState.cameras![selectedCameraIdx!]); //.then((void v) {});
  }

   */

  initCam() {
    // Get the listonNewCameraSelected of available cameras.
    // Then set the first camera as selected.
    availableCameras().then((availableCameras) {
      cameras = availableCameras;

      if (cameras!.isNotEmpty) {
        setState(() {
          selectedCameraIdx = 0;
        });

        onNewCameraSelected(cameras![selectedCameraIdx!]).then((void v) {});
      }
    }).catchError((err) {
      debugPrint('Error: $err.code\nError Message: $err.message');
    });
  }

  @override
  Widget build(BuildContext context) {
    var isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    final _makeToggle = Toggle.ToggleSwitch(
      //minWidth: 90.0,
      //minHeight: 70.0,
      customWidths: const [55, 55],
      initialLabelIndex: _initialIndex,
      cornerRadius: 20.0,
      activeFgColor: Colors.white,
      inactiveBgColor: Colors.grey,
      inactiveFgColor: Colors.white,
      totalSwitches: 2,
      radiusStyle: true,
      icons: const [Icons.camera_alt, Icons.videocam],
      iconSize: 30,
      //labels: ['camera', 'video'],
      //iconSize: 30.0,
      activeBgColors: const [
        [
          Colors.tealAccent,
          Colors.teal,
        ],
        [Colors.red, Colors.redAccent]
      ],
      animate:
          true, // with just animate set to true, default curve = Curves.easeIn
      curve: Curves
          .bounceInOut, // animate must be set to true when using custom curve
      onToggle: (index) {
        debugPrint('switched to: $index');
        //_hiRes = !_hiRes;

        setState(() {
          _video = !_video;
          _initialIndex = index!;
        });
      },
    );

    Stack _showCamera() {
      return Stack(children: [
        Column(children: <Widget>[
          Expanded(
            child: Container(
              child: isPortrait
                  ? Center(child: _cameraPreviewWidget())
                  : Padding(
                      padding: const EdgeInsets.only(left: 80),
                      child: _cameraPreviewWidget()),
            ),
          )
        ]),
        isPortrait
            ? Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: 0, bottom: 0, left: 5, right: 5),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(child: SizedBox()),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Spacer(),
                            _cameraTogglesRowWidget(),
                            const Spacer(),
                            _captureControlRowWidget(isPortrait),
                            const Spacer(),
                            _showSend
                                ? _toggleSend(isPortrait)
                                : const SizedBox(width: 45),
                            const Spacer(),
                          ],
                        ),
                        _makeToggle,
                      ]),
                ))
            : Align(
                alignment: Alignment.centerRight,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Spacer(),
                      //Expanded(child: SizedBox()),
                      _showSend
                          ? Padding(
                              padding: const EdgeInsets.only(top: 20, right: 5),
                              child: _toggleSend(isPortrait))
                          : const SizedBox(height: 75),

                      const Spacer(),
                      _captureControlRowWidget(isPortrait),
                      _makeToggle,
                      const Spacer(),
                      Padding(
                          padding: const EdgeInsets.only(right: 5, bottom: 20),
                          child: _cameraTogglesRowWidget()),

                      //Expanded(child: SizedBox()),
                    ])),
        Align(
            alignment: Alignment.topCenter,
            child: Padding(
                padding: EdgeInsets.only(top: isPortrait ? 40 : 20, left: 0),
                child: InkWell(
                    onTap: () {
                      _showCameraDialog();
                    },
                    child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.settings,
                                  color: globalState.theme.buttonIcon),
                              Icon(
                                  _cameraDialogOpen
                                      ? Icons.keyboard_arrow_up_sharp
                                      : Icons.keyboard_arrow_down_sharp,
                                  color: globalState.theme.buttonIcon),
                            ]))))),
        Align(
            alignment: Alignment.topLeft,
            child: Padding(
                padding: const EdgeInsets.only(top: 50, left: 2),
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios,
                      color: globalState.theme.buttonDisabled),
                  onPressed: () {
                    Navigator.pop(context);

                    if (controller != null) {
                      controller!.dispose();
                      controller = null;
                    }
                  },
                ))),
        Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
                padding: const EdgeInsets.only(top: 50, left: 12),
                child: IconButton(
                  //splashColor: globalState.theme.buttonDisabled,
                  //highlightColor: globalState.theme.buttonDisabled,
                  //color: globalState.theme.buttonDisabled,
                  icon: Icon(Icons.question_mark,
                      color: globalState.theme.buttonDisabled),
                  onPressed: () {
                    setState(() {
                      _shrink = !_shrink;
                      //onNewCameraSelected(controller!.description);
                    });
                  },
                ))),
      ]);
    }

    return SafeArea(
        left: false,
        top: false,
        right: false,
        bottom: true,
        child: Scaffold(
            backgroundColor: Colors.black, //globalState.theme.background,
            key: _scaffoldKey,
            body: OrientationBuilder(
              builder: (context, orientation) {
                return _showCamera();
              },
            )));
  }

  void _showCameraDialog() async {
    setState(() {
      _cameraDialogOpen = true;
    });

    await DialogCamera.showCameraDialog(
        context, controller, globalState.captureState);

    setState(() {
      _cameraDialogOpen = false;
    });
  }

  void logError(String code, String message) =>
      debugPrint('Error: $code\nError Message: $message');

  // Display 'Loading' text when the camera is still loading.
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller!.value.isInitialized) {
      return Text(
        '', //'''Loading',
        style: TextStyle(
          color: globalState.theme.initializingText,
          fontSize: 20.0,
          fontWeight: FontWeight.w900,
        ),
      );
    }

    if (controller == null)
      return Container();
    else {
      return _shrink
          ? Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              const Spacer(),
              !_capturing
                  ? Padding(
                      padding: const EdgeInsets.only(left: 40, right: 40),
                      child: Text(
                        AppLocalizations.of(context)!
                            .welcomeToTheIronCirclesCamera,
                        style: TextStyle(
                            color: globalState.theme.buttonIcon, fontSize: 20),
                      ))
                  : Container(),
              !_capturing
                  ? const SizedBox(
                      height: 20,
                    )
                  : Container(),
              !_capturing
                  ? Padding(
                      padding: const EdgeInsets.only(left: 40, right: 40),
                      child: Text(
                        AppLocalizations.of(context)!
                            .theGearAtTheTopIncludesSettingsForFlashExposureAndFocus,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: globalState.theme.buttonIcon, fontSize: 16),
                      ))
                  : Container(),
              !_capturing
                  ? const SizedBox(
                      height: 20,
                    )
                  : Container(),
              !_capturing
                  ? Padding(
                      padding: const EdgeInsets.only(left: 40, right: 40),
                      child: Text(
                        AppLocalizations.of(context)!
                            .theSelectorAtTheBottomSwitchesFromCameraToVideo,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: globalState.theme.buttonIcon, fontSize: 16),
                      ))
                  : Container(),
              !_capturing
                  ? const SizedBox(
                      height: 20,
                    )
                  : Container(),
              !_capturing
                  ? Padding(
                      padding: const EdgeInsets.only(left: 40, right: 40),
                      child: Text(
                        AppLocalizations.of(context)!
                            .theRecycleIconFlipsBetweenFrontAndBackCameras,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: globalState.theme.buttonIcon, fontSize: 16),
                      ))
                  : Container(),
              SizedBox(width: 1, child: CameraPreview(controller!)),
              const Spacer(),
            ])
          : Listener(
              onPointerDown: (_) => _pointers++,
              onPointerUp: (_) => _pointers--,
              child: CameraPreview(
                controller!,
                child: LayoutBuilder(builder:
                    (BuildContext context, BoxConstraints constraints) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onScaleStart: _handleScaleStart,
                    onScaleUpdate: _handleScaleUpdate,
                    onTapDown: (TapDownDetails details) =>
                        onViewFinderTap(details, constraints),
                  );
                }),
              ),
            );
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
// When there are not exactly two fingers on screen don't scale
    if (controller == null || _pointers != 2) {
      return;
    }

    _currentScale = (_baseScale * details.scale)
        .clamp(_minAvailableZoom, _maxAvailableZoom);

    await controller!.setZoomLevel(_currentScale);
  }

  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (controller == null) {
      return;
    }

    final CameraController cameraController = controller!;

    final Offset offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    cameraController.setExposurePoint(offset);
    cameraController.setFocusPoint(offset);
  }

  /// Display a row of toggle to select the camera (or a message if no camera is available).
  Widget _toggleSend(bool isPortrait) {
    /*if (!_showSend) {
      return Expanded(child: SizedBox());
    }

     */

    return IconButton(
        onPressed: () {
          Navigator.pop(
              context, CapturedMediaResults(mediaCollection: _mediaCollection));

          controller!.dispose();
          controller = null;
        },
        icon: Icon(Icons.check,
            size: 30, color: globalState.theme.recordingIcons));
  }

  /// Display a row of toggle to select the camera (or a message if no camera is available).
  Widget _cameraTogglesRowWidget() {
    return IconButton(
      icon: Icon(Icons.autorenew_rounded,
          size: 30, color: globalState.theme.recordingIcons),
      onPressed: () async {
        _onSwitchCamera();
      },
    );
  }

  /// Display the control bar with buttons to record videos.
  Widget _captureControlRowWidget(bool isPortrait) {
    return InkWell(
      onTap: () {
        if (_recording) {
          _recording = false;
          _onStopButtonPressed();
        } else {
          setState(() {
            _showSend = false;
          });
          _onCaptureButtonPressed();
        }
      },
      child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(75),
              border: Border.all(width: 2, color: Colors.white)),
          child: _recording
              ? Icon(Icons.fiber_manual_record,
                  size: 45, color: globalState.theme.recording)
              : Icon(Icons.fiber_manual_record,
                  size: 45,
                  color: _capturing
                      ? const Color(0x00000000)
                      : globalState.theme.recordingIcons)),
    );
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller!.dispose();
    }

    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.max,
      enableAudio: enableAudio,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    controller = cameraController;

    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (cameraController.value.hasError) {
        //showInSnackBar(
        // 'Camera error ${cameraController.value.errorDescription}');
      }
    });

    try {
      await cameraController.initialize();

      await Future.wait(<Future<Object?>>[
        cameraController.getMinExposureOffset().then((double value) =>
            globalState.captureState.minAvailableExposureOffset = value),
        cameraController.getMaxExposureOffset().then((double value) =>
            globalState.captureState.maxAvailableExposureOffset = value),
        cameraController
            .getMaxZoomLevel()
            .then((double value) => _maxAvailableZoom = value),
        cameraController
            .getMinZoomLevel()
            .then((double value) => _minAvailableZoom = value),
        //cameraController.lockCaptureOrientation(DeviceOrientation.portraitUp),
      ]);

      await cameraController.setFlashMode(globalState.captureState.flashMode);
      await cameraController
          .setExposureMode(globalState.captureState.exposureMode);
      await cameraController.setFocusMode(globalState.captureState.focusMode);
      await cameraController
          .setExposureOffset(globalState.captureState.currentExposureOffset);
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _onSwitchCamera() async {
    if (controller != null && !controller!.value.isRecordingVideo) {
      selectedCameraIdx =
          selectedCameraIdx! < cameras!.length - 1 ? selectedCameraIdx! + 1 : 0;
      CameraDescription selectedCamera = cameras![selectedCameraIdx!];

      await onNewCameraSelected(selectedCamera);

      setState(() {
        selectedCameraIdx = selectedCameraIdx;
      });
    }
  }

  void _onCaptureButtonPressed() {
    if (_video == true) {
      _recording = true;
      _startVideoRecording().then((_) {
        if (mounted) setState(() {});
      });
    } else {
      onTakePictureButtonPressed();
    }
  }

  void _onStopButtonPressed() {
    _stopVideoRecording().then((file) {
      if (mounted) setState(() {});
      if (file != null) {
        //showInSnackBar('Video recorded to ${file.path}');

        _mediaCollection.add(Media(
            path: file.path, mediaType: MediaType.video, fromCamera: true));
        //videoPath = file.path;
        //_startVideoPlayer();
        _showSend = true;
      }
    });
  }

  XFile? previewFile;

  Future<XFile?> takePicture() async {
    // final CameraController? cameraController = controller;
    if (controller == null || !controller!.value.isInitialized) {
      return null;
    }

    if (controller!.value.isTakingPicture) {
// A capture is already pending, do nothing.
      return null;
    }

    if (!_shrink) {
      setState(() {
        _capturing = true;
      });
    }

    try {
      final XFile file = await controller!.takePicture();
      return file;
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  void onTakePictureButtonPressed() {
    takePicture().then((XFile? file) async {
      if (mounted && file != null) {
        _mediaCollection.media
            .add(Media(path: file.path, mediaType: MediaType.image));

        if (!_shrink) {
          setState(() {
            _showSend = true;
            _capturing = true;
            _shrink = true;
          });

          await Future.delayed(const Duration(milliseconds: 100));

          setState(() {
            // _showSend = true;
            _capturing = false;
            _shrink = false;
          });
        } else {
          setState(() {
            _showSend = true;
            _capturing = false;
          });
        }

        /*if (globalState.captureState.flashMode != FlashMode.off &&
            globalState.captureState.flashMode != FlashMode.torch) {
          await controller!.setFlashMode(FlashMode.torch);
          await controller!.setFlashMode(FlashMode.off);
          await controller!.setFlashMode(globalState.captureState.flashMode);
        }

         */
      }
    });
  }

  Future<void> _startVideoRecording() async {
    if (!controller!.value.isInitialized) {
      FormattedSnackBar.showSnackbarWithContext(
          context, AppLocalizations.of(context)!.initializing, "", 2, false);

      return;
    }

    // Do nothing if a recording is on progress
    if (controller!.value.isRecordingVideo) {
      return;
    }

    try {
      await controller!.startVideoRecording();
      //videoPath = filePath;
    } on CameraException catch (e) {
      _showCameraException(e);
      return;
    }

    return;
  }

  /*
  /// Toggle recording audio
  Widget _toggleAudioWidget() {
    return Padding(
      padding: const EdgeInsets.only(left: 25),
      child: Row(
        children: <Widget>[
          const Text('Enable Audio:'),
          Switch(
            value: enableAudio,
            onChanged: (bool value) {
              enableAudio = value;
              if (controller != null) {
                onNewCameraSelected(controller!.description);
              }
            },
          ),
        ],
      ),
    );
  }

   */

  Future<XFile?> _stopVideoRecording() async {
    if (!controller!.value.isRecordingVideo) {
      return null;
    }

    try {
      return await controller!.stopVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  void _showCameraException(CameraException e) {
    String errorText = 'Error: ${e.code}\nError Message: ${e.description}';
    debugPrint(errorText);

    FormattedSnackBar.showSnackbarWithContext(
        context, 'Error: ${e.code}\n${e.description}', "", 2, false);
  }
}

//T? _ambiguate<T>(T? value) => value;
