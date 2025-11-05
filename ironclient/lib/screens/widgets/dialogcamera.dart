import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/capturemedia.dart';

class DialogCamera {
  //static AuthenticationBloc _authBloc = AuthenticationBloc();
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  static showCameraDialog(
    BuildContext context,
    //Function success,
    CameraController? controller,
    CaptureState captureState,
  ) async {
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) => _SystemPadding(
        child: AlertDialog(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30.0))),
          contentPadding: const EdgeInsets.all(10.0),
          content: CameraOptions(scaffoldKey, controller, captureState),
          alignment: Alignment.topCenter,
          actions: const <Widget>[],
        ),
      ),
    );
  }
}

class _SystemPadding extends StatelessWidget {
  final Widget? child;

  const _SystemPadding({Key? key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        //padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        duration: const Duration(milliseconds: 300),
        child: Padding(padding: const EdgeInsets.only(top: 50), child: child));
  }
}

class CameraOptions extends StatefulWidget {
  final scaffoldKey;
  final CameraController? controller;
  final CaptureState captureState;

  const CameraOptions(
    this.scaffoldKey,
    this.controller,
    this.captureState,
    /* this.circleObject,
      this.showAvatar,
      this.showDate,
      this.showTime,
      this.messageColor,
      this.userFurnace,
      this.copy,
      this.share,*/
  );

  _CameraOptionsState createState() => _CameraOptionsState();
}

class _CameraOptionsState extends State<CameraOptions> {
  @override
  void initState() {
    super.initState();
  }

  void onSetFlashModeButtonPressed(FlashMode mode) {
    setFlashMode(mode).then((_) {
      if (mounted) {
        setState(() {});
      }
      //howInSnackBar('Flash mode set to ${mode.toString().split('.').last}');
    });
  }

  void onSetExposureModeButtonPressed(ExposureMode mode) {
    setExposureMode(mode).then((_) {
      if (mounted) {
        setState(() {});
      }
      //showInSnackBar('Exposure mode set to ${mode.toString().split('.').last}');
    });
  }

  void onSetFocusModeButtonPressed(FocusMode mode) {
    setFocusMode(mode).then((_) {
      if (mounted) {
        setState(() {});
      }
      //showInSnackBar('Focus mode set to ${mode.toString().split('.').last}');
    });
  }

  Future<void> setFlashMode(FlashMode mode) async {
    if (widget.controller == null) {
      return;
    }

    try {
      globalState.captureState.flashMode = mode;
      await widget.controller!.setFlashMode(mode);
    } on CameraException catch (e) {
      debugPrint(e.description);
      //_showCameraException(e);
      rethrow;
    }
  }

  Future<void> setExposureMode(ExposureMode mode) async {
    if (widget.controller == null) {
      return;
    }

    try {
      globalState.captureState.exposureMode = mode;
      await widget.controller!.setExposureMode(mode);

      if (mode == ExposureMode.auto) {
        widget.captureState.currentExposureOffset = 0.0;
      }

      await widget.controller!
          .setExposureOffset(widget.captureState.currentExposureOffset);
    } on CameraException catch (e) {
      debugPrint(e.description);
      //_showCameraException(e);
      rethrow;
    }
  }

  Future<void> setExposureOffset(double offset) async {
    if (widget.controller == null) {
      return;
    }

    setState(() {
      widget.captureState.currentExposureOffset = offset;
    });
    try {
      offset = await widget.controller!.setExposureOffset(offset);
    } on CameraException catch (e) {
      debugPrint(e.description);
      // _showCameraException(e);
      rethrow;
    }
  }

  Future<void> setFocusMode(FocusMode mode) async {
    if (widget.controller == null) {
      return;
    }

    try {
      globalState.captureState.focusMode = mode;
      await widget.controller!.setFocusMode(mode);
      setState(() {});
    } on CameraException catch (e) {
      debugPrint(e.description);
      //_showCameraException(e);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle styleAuto = TextButton.styleFrom(
      foregroundColor:
          widget.controller?.value.exposureMode == ExposureMode.auto
              ? globalState.theme.cameraOptionSelected
              : globalState.theme.cameraOptionNotSelected,
    );
    final ButtonStyle styleLocked = TextButton.styleFrom(
      foregroundColor:
          widget.controller?.value.exposureMode == ExposureMode.locked
              ? globalState.theme.cameraOptionSelected
              : globalState.theme.cameraOptionNotSelected,
    );

    final ButtonStyle styleAutoFocus = TextButton.styleFrom(
      foregroundColor: widget.controller?.value.focusMode == FocusMode.auto
          ? globalState.theme.cameraOptionSelected
          : globalState.theme.cameraOptionNotSelected,
    );
    final ButtonStyle styleLockedFocus = TextButton.styleFrom(
      foregroundColor: widget.controller?.value.focusMode == FocusMode.locked
          ? globalState.theme.cameraOptionSelected
          : globalState.theme.cameraOptionNotSelected,
    );

    final _makeFlash =
        Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(
        AppLocalizations.of(context)!.flash,
        style: const TextStyle(color: Colors.white),
        textScaler: const TextScaler.linear(1.0)
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //Padding(padding: EdgeInsets.only(right: 10)),
          IconButton(
              icon: const Icon(Icons.flash_off),
              color: widget.controller?.value.flashMode == FlashMode.off
                  ? globalState.theme.cameraOptionSelected
                  : globalState.theme.cameraOptionNotSelected,
              onPressed: widget.controller != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.off)
                  : null),
          IconButton(
              icon: const Icon(Icons.flash_auto),
              color: widget.controller?.value.flashMode == FlashMode.auto
                  ? globalState.theme.cameraOptionSelected
                  : globalState.theme.cameraOptionNotSelected,
              onPressed: widget.controller != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.auto)
                  : null),
          IconButton(
              icon: const Icon(Icons.flash_on),
              color: widget.controller?.value.flashMode == FlashMode.always
                  ? globalState.theme.cameraOptionSelected
                  : globalState.theme.cameraOptionNotSelected,
              onPressed: widget.controller != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.always)
                  : null),
          IconButton(
              icon: const Icon(Icons.highlight),
              color: widget.controller?.value.flashMode == FlashMode.torch
                  ? globalState.theme.cameraOptionSelected
                  : globalState.theme.cameraOptionNotSelected,
              onPressed: widget.controller != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.torch)
                  : null)
        ],
      )
    ]);

    final makeExposure = Column(
      children: <Widget>[
        Center(
          child: Text(AppLocalizations.of(context)!.exposureMode,
              style: const TextStyle(color: Colors.white),
              textScaler: const TextScaler.linear(1.0)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            TextButton(
                style: styleAuto,
                onPressed: widget.controller != null
                    ? () => onSetExposureModeButtonPressed(ExposureMode.auto)
                    : null,
                onLongPress: () {
                  if (widget.controller != null) {
                    widget.controller!.setExposurePoint(null);
                    //showInSnackBar('Resetting exposure point');
                  }
                },
                child: Text(
                  AppLocalizations.of(context)!.auto,
                  textScaler: const TextScaler.linear(1.0),
                  style:
                      TextStyle(fontSize: 14 - globalState.scaleDownTextFont),
                )),
            TextButton(
              style: styleLocked,
              onPressed: widget.controller != null
                  ? () => onSetExposureModeButtonPressed(ExposureMode.locked)
                  : null,
              child: Text(
                AppLocalizations.of(context)!.locked,
                textScaler: const TextScaler.linear(1.0),
                style: TextStyle(fontSize: 14 - globalState.scaleDownTextFont),
              ),
            ),
            TextButton(
              style: styleLocked,
              onPressed: widget.controller != null
                  ? () {
                      setState(() {
                        widget.captureState.currentExposureOffset = 0.0;
                        widget.controller!.setExposureOffset(0.0);
                      });
                    }
                  : null,
              child: Text(
                AppLocalizations.of(context)!.resetOffset,
                textScaler: const TextScaler.linear(1.0),
                style: TextStyle(fontSize: 14 - globalState.scaleDownTextFont),
              ),
            ),
          ],
        ),
        widget.controller?.value.exposureMode != ExposureMode.auto
            ? Center(
                child: Text(
                  AppLocalizations.of(context)!.exposureOffset,
                  style: const TextStyle(color: Colors.white),
                  textScaler: const TextScaler.linear(1.0),
                ),
              )
            : Container(),
        widget.controller?.value.exposureMode != ExposureMode.auto
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Text(
                    widget.captureState.minAvailableExposureOffset.toString(),
                    textScaler: const TextScaler.linear(1.0),
                    style:
                        TextStyle(fontSize: 14 - globalState.scaleDownTextFont),
                  ),
                  Slider(
                    activeColor: globalState.theme.cameraOptionSelected,
                    value: widget.captureState.currentExposureOffset,
                    min: widget.captureState.minAvailableExposureOffset,
                    max: widget.captureState.maxAvailableExposureOffset,
                    label: widget.captureState.currentExposureOffset.toString(),
                    onChanged: widget.captureState.minAvailableExposureOffset ==
                            widget.captureState.maxAvailableExposureOffset
                        ? null
                        : setExposureOffset,
                  ),
                  Text(
                    widget.captureState.maxAvailableExposureOffset.toString(),
                    textScaler: const TextScaler.linear(1.0),
                    style:
                        TextStyle(fontSize: 14 - globalState.scaleDownTextFont),
                  ),
                ],
              )
            : Container(),
      ],
    );

    Widget _makeFocus = Column(
      children: <Widget>[
        Center(
          child: Text(AppLocalizations.of(context)!.focusMode,
              textScaler: const TextScaler.linear(1.0),
              style: const TextStyle(color: Colors.white)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            TextButton(
              style: styleAutoFocus,
              onPressed: widget.controller != null
                  ? () => onSetFocusModeButtonPressed(FocusMode.auto)
                  : null,
              onLongPress: () {
                if (widget.controller != null) {
                  widget.controller!.setFocusPoint(null);
                }
                //showInSnackBar('Resetting focus point');
              },
              child: Text(
                AppLocalizations.of(context)!.auto,
                textScaler: const TextScaler.linear(1.0),
                style: TextStyle(fontSize: 14 - globalState.scaleDownTextFont),
              ),
            ),
            TextButton(
              style: styleLockedFocus,
              onPressed: widget.controller != null
                  ? () => onSetFocusModeButtonPressed(FocusMode.locked)
                  : null,
              child: Text(
                AppLocalizations.of(context)!.locked,
                textScaler: const TextScaler.linear(1.0),
                style: TextStyle(fontSize: 14 - globalState.scaleDownTextFont),
              ),
            ),
          ],
        ),
      ],
    );

    return SizedBox(
        //width: 200,
        height: widget.controller?.value.exposureMode != ExposureMode.auto
            ? 270
            : 210,
        child: Scaffold(
          backgroundColor: const Color.fromRGBO(0, 0, 0, 0.5),
          key: widget.scaffoldKey,
          resizeToAvoidBottomInset: true,
          body: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                //Spacer(),
                const Padding(padding: EdgeInsets.only(top: 10)),
                _makeFlash,
                makeExposure,
                _makeFocus,
              ]),
        ));
  }
}
