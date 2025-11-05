import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/utils/permissions.dart';

class CircleRecipeScreenOverviewTab extends StatefulWidget {
  final CircleRecipe circleRecipe;
  final File? image;
  final TextEditingController? controller;
  final int? screenMode;

  const CircleRecipeScreenOverviewTab({
    Key? key,
    required this.circleRecipe,
    this.image,
    this.controller,
    this.screenMode,
  }) : super(key: key);

  @override
  _CircleRecipeScreenOverviewTabState createState() =>
      _CircleRecipeScreenOverviewTabState();
}

class _CircleRecipeScreenOverviewTabState
    extends State<CircleRecipeScreenOverviewTab> {
  File? _image;

  @override
  void initState() {
    _image = widget.image;

    if (_image == null) {
      if (widget.circleRecipe.image != null) {
        _image = widget.circleRecipe.image!.thumbnailFile;
      }
    }

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return  Container(
            padding: const EdgeInsets.only(left: 0, right: 0),
            color: globalState.theme.tabBackground,
            child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                    constraints: const BoxConstraints(),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Padding(
                            padding: const EdgeInsets.only(top: 12, left: 10, right: 10),
                           child:
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 100),
                            child: ExpandingLineText(
                                maxLength: TextLength.Large,
                                textColor: globalState.theme.textTabFieldText,
                                readOnly:
                                    widget.screenMode == ScreenMode.READONLY
                                        ? true
                                        : false,
                                controller: widget.controller,
                                hintSize: 14,
                                labelText: AppLocalizations.of(context)!.recipeOverview.toLowerCase(),
                                expands: true),
                          )),
                          const Padding(
                            padding: EdgeInsets.only(top: 10),
                          ),
                          Padding(
                              padding:
                                  const EdgeInsets.only(top: 0, bottom: 10),
                              child: InkWell(
                                  onTap: _selectImage,
                                  child: _image != null
                                      ? Image.file(_image!,
                                          width: 600, fit: BoxFit.cover)
                                      : widget.circleRecipe.image !=
                                              null //loading
                                          ? SizedBox(
                                              //width: 150,
                                              height: 150,
                                              child: Container(
                                                color: globalState
                                                    .theme.tabBackground,
                                              ))
                                          : widget.screenMode ==
                                                  ScreenMode.READONLY
                                              ? Container()
                                              : Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 15,
                                                          bottom: 0,
                                                          left: 17),
                                                  child: ICText(
                                                      AppLocalizations.of(context)!.tapToAddImage.toLowerCase(),
                                                      textScaleFactor:
                                                          globalState
                                                              .labelScaleFactor,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      fontSize: 14,
                                                      color: globalState.theme
                                                          .buttonIconHighlight),
                                                ))),
                        ]))));
  }

  _selectImage() async {
    if (widget.screenMode == ScreenMode.READONLY) return;
    ImagePicker imagePicker = ImagePicker();

    try {
      var imageFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: ImageConstants.CIRCLEBACKGROUND_QUALITY,
      );

      if (imageFile != null)
        setState(() {
          _image = File(imageFile.path);

          widget.circleRecipe.image ??= CircleImage();

          widget.circleRecipe.image!.thumbnailFile = _image;
          widget.circleRecipe.imageChanged = true;
        });
    } catch (err, trace) {
      if (err.toString().contains('photo_access_denied')) {
        Permissions.askOpenSettings(context);
      } else {
        LogBloc.insertError(err, trace);
        debugPrint('CircleRecipeScreenOverview._selectImage: $err');
      }
    }
  }
}
