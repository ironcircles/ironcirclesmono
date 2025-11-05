import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/utilities/icpainter.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/utils/fileutil.dart';
import 'package:ironcirclesapp/utils/permissions.dart';
//import 'package:painter2/painter2.dart';

class Markup extends StatefulWidget {
  final File? source;

  const Markup(
      {Key? key,
      this.source})
      : super(key: key);

  @override
  MarkupState createState() => MarkupState();
}

class MarkupState extends State<Markup> {
  late bool _finished;
  PainterController? _controller;

  //CircleImageBloc _circleImageBloc = CircleImageBloc();

  @override
  void initState() {
    super.initState();
    _finished = false;
    _controller = newController();
  }

  PainterController newController() {
    PainterController controller = PainterController();
    controller.thickness = 5.0;
    controller.backgroundColor = globalState.theme.bottomIcon;
    controller.drawColor = globalState.theme.imageMarkup;

    if (widget.source != null) {
      controller.backgroundImage = Image.file(
        widget.source!,
        fit: BoxFit.contain,
      );
    }

    //controller.backgroundImage = Image.network(
    //'https://cdn-images-1.medium.com/max/1200/1*5-aoK8IBmXve5whBQM90GA.png');
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> actions;
    if (_finished) {
      actions = <Widget>[
        IconButton(
          icon: const Icon(Icons.content_copy),
          tooltip: 'New Painting',
          onPressed: () => setState(() {
            _finished = false;
            _controller = newController();
          }),
        ),
      ];
    } else {
      actions = <Widget>[
        IconButton(
          icon: const Icon(Icons.image),
          tooltip: 'Select image',
          onPressed: () {
            _selectImage();
          },
        ),
        IconButton(
          icon: const Icon(Icons.undo),
          tooltip: 'Undo',
          onPressed: () {
            if (_controller!.canUndo) _controller!.undo();
          },
        ),
        IconButton(
          icon: const Icon(Icons.redo),
          tooltip: 'Redo',
          onPressed: () {
            if (_controller!.canRedo) _controller!.redo();
          },
        ),
        IconButton(
          icon: const Icon(Icons.clear),
          tooltip: 'Clear',
          onPressed: () => _controller!.clear(),
        ),
        /*
        IconButton(
            icon: Icon(Icons.check),
            onPressed: () async {
              setState(() {
                _finished = true;
              });
              Uint8List bytes = await _controller.exportAsPNGBytes();
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (BuildContext context) {
                return Scaffold(
                  appBar: AppBar(
                    title: Text('View your image'),
                  ),
                  body: Container(
                    child: Image.memory(bytes),
                  ),
                );
              }));
            }),*/
      ];
    }
    return Scaffold(
        backgroundColor: globalState.theme.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(75),
          child: ICAppBar(
            title: AppLocalizations.of(context)!.markup,
            actions: actions,
            bottom: DrawBar(_controller),
          ),
        ),
        body: Center(
            child:
                AspectRatio(aspectRatio: 1.0, child: ICPainter(_controller!))),
        floatingActionButton: FloatingActionButton(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(30.0))
          ),
          onPressed: _cache,
          backgroundColor: globalState.theme.background,
          child: Icon(Icons.check_circle,
              size: 45, color: globalState.theme.bottomIcon),
        ));
  }

  _selectImage() async {
    final picker = ImagePicker();

    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          //File _image = ICIO.File(pickedFile.path);

          _controller!.backgroundImage = Image.file(
            File(pickedFile.path),
            fit: BoxFit.cover,
          );
        });

        return;
      }
    } catch (err, trace) {
      if (err.toString().contains('photo_access_denied')) {
        Permissions.askOpenSettings(context);
      } else {
        LogBloc.insertError(err, trace);
        debugPrint('_selectImage: $err');
      }
    }
  }

  _cache() async {
    //String? tempPath = widget.userCircleCache!.circlePath;

    Uint8List bytes = await _controller!.exportAsPNGBytes();

    File markup = await cacheMarkup(bytes);

    Navigator.pop(context, markup);
  }

  Future<File> cacheMarkup(Uint8List bytes) async {
    try {
      String filePath = await FileSystemService.returnTempPathAndImageFile();

      File? file = await FileUtil.writeBytesToFile(filePath, bytes);

      if (file == null) throw ('could not create markup');

      return file;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("CircleImageService.cacheTempAssets: $err");
      rethrow;
    }
  }
}

class DrawBar extends StatelessWidget {
  final PainterController? _controller;

  const DrawBar(this._controller);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Flexible(child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Slider(
            value: _controller!.thickness,
            onChanged: (value) => setState(() {
          _controller!.thickness = value;
            }),
            min: 1.0,
            max: 20.0,
            activeColor: globalState.theme.imageMarkupSlider,
          );
        })),
        ColorPickerButton(_controller, false),
        ColorPickerButton(_controller, true),
      ],
    );
  }
}

class ColorPickerButton extends StatefulWidget {
  final PainterController? _controller;
  final bool _background;

  const ColorPickerButton(this._controller, this._background);

  @override
  _ColorPickerButtonState createState() => _ColorPickerButtonState();
}

class _ColorPickerButtonState extends State<ColorPickerButton> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(_iconData,
          color: widget._background
              ? widget._controller!.backgroundColor
              : widget._controller!.drawColor),
      //icon: Icon(_iconData, color: Colors.white),
      tooltip:
          widget._background ? 'Change background color' : 'Change draw color',
      onPressed: () => _pickColor(),
    );
  }

  void _pickColor() {
    Color pickerColor = _color;
    Navigator.of(context)
        .push(MaterialPageRoute(
            fullscreenDialog: false,
            builder: (BuildContext context) {
              return Scaffold(
                  appBar: ICAppBar(title: AppLocalizations.of(context)!.pickColor),
                  body: Container(
                      alignment: Alignment.center,
                      child: ColorPicker(
                        pickerColor: pickerColor,
                        onColorChanged: (Color c) => pickerColor = c,
                      )));
            }))
        .then((_) {
      setState(() {
        _color = pickerColor;
      });
    });
  }

  Color get _color => widget._background
      ? widget._controller!.backgroundColor
      : widget._controller!.drawColor;

  IconData get _iconData =>
      widget._background ? Icons.format_color_fill : Icons.brush;

  set _color(Color color) {
    if (widget._background) {
      widget._controller!.backgroundColor = color;
    } else {
      widget._controller!.drawColor = color;
    }
  }
}
