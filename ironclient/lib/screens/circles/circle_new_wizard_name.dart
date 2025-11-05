import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ironcirclesapp/blocs/circle_bloc.dart';
import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/stablediffusionprompt.dart';
import 'package:ironcirclesapp/screens/circles/circle_new_wizard_settings.dart';
import 'package:ironcirclesapp/screens/insidecircle/dialogchoosebackground.dart';
import 'package:ironcirclesapp/screens/payment/premiumfeaturecheck.dart';
import 'package:ironcirclesapp/screens/stablediffusion/stablediffusion_generate.dart';
import 'package:ironcirclesapp/screens/utilities/stringhelper.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/formatteddropdownobject.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:ironcirclesapp/utils/imageutil.dart';
import 'package:ironcirclesapp/utils/permissions.dart';

class CircleNewWizardName extends StatefulWidget {
  final List<UserFurnace> userFurnaces;
  final List<ListItem> circleTypeList;
  // final Function next;

  const CircleNewWizardName({
    required this.userFurnaces,
    required this.circleTypeList,
    //required this.next
  });
  @override
  _CircleNewWizardNameState createState() => _CircleNewWizardNameState();
}

class _CircleNewWizardNameState extends State<CircleNewWizardName> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _circleName = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _password2 = TextEditingController();
  final bool _hidden = false;
  final String _ownershipModel = 'members';
  final List<ListItem> _furnaceList = [];
  final CircleBloc _circleBloc = CircleBloc();
  //final double radius = 183;

  WizardVariables _wizardVariables = WizardVariables(
      circle: Circle(
          dm: false,
          name: '',
          privacyShareImage: true,
          privacyShareGif: true,
          privacyCopyText: true,
          privacyShareURL: true,
          toggleEntryVote: false),
      members: []);

  ListItem? _selected;
  ListItem? _selectedType;
  bool _clicked = false;
  bool _isVault = false;

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  List<String> _timerValues = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timerValues = [
        AppLocalizations.of(context)!.off,
        AppLocalizations.of(context)!.hours4,
        AppLocalizations.of(context)!.hours8,
        AppLocalizations.of(context)!.day1,
        AppLocalizations.of(context)!.week1,
        AppLocalizations.of(context)!.days30,
        AppLocalizations.of(context)!.days90,
        AppLocalizations.of(context)!.months6,
        AppLocalizations.of(context)!.year1,
      ];
    });

    _circleBloc.createdWithInvites.listen((success) {
      if (mounted) {
        if (success) {
          FormattedSnackBar.showSnackbarWithContext(
              context,
              AppLocalizations.of(context)!.successfullyCreatedVault,
              "",
              2,
              false);

          Navigator.pop(context);
        } else {
          FormattedSnackBar.showSnackbarWithContext(context,
              AppLocalizations.of(context)!.errorCreatingVault, "", 2, false);

          setState(() {
            _showSpinner = false;
            _clicked = false;
          });
        }
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      setState(() {
        _showSpinner = false;
        _clicked = false;
      });

      debugPrint("error $err");
    }, cancelOnError: false);

    _selected = ListItem();

    for (UserFurnace userFurnace in widget.userFurnaces) {
      if (userFurnace.connected!) {
        if (userFurnace.role == Role.OWNER ||
            userFurnace.role == Role.ADMIN ||
            userFurnace.memberAutonomy == true) {
          _furnaceList.add(ListItem(
              object: userFurnace,
              name:
                  '${StringHelper.truncate(userFurnace.alias!, 30)} (${StringHelper.truncate(userFurnace.username!, 18)})'));
        }
      }
    }
    _selected = _furnaceList[0];

    _selectedType = widget.circleTypeList[0];
  }

  @override
  void dispose() {
    _circleName.dispose();
    _password.dispose();
    _password2.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    final image = Padding(
        padding: const EdgeInsets.only(top: 5, left: 0),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Column(children: [
                InkWell(
                    onTap: () async {
                      if (_wizardVariables.image != null) {
                        File? cropped = await ImageUtil.cropImage(
                            context, _wizardVariables.image);
                        if (cropped != null) {
                          setState(() {
                            _wizardVariables.image = cropped;
                          });
                        }
                      }
                    },
                    child: Container(
                        width: ScreenSizes.getMaxImageWidth(width) -
                            ICPadding.GENERATE_BUTTONS,
                        height: ScreenSizes.getMaxImageWidth(width) -
                            ICPadding.GENERATE_BUTTONS,
                        constraints: BoxConstraints(
                            maxHeight: ScreenSizes.getMaxImageWidth(width) -
                                ICPadding.GENERATE_BUTTONS,
                            maxWidth: ScreenSizes.getMaxImageWidth(width) -
                                ICPadding.GENERATE_BUTTONS),
                        child: ClipOval(
                            child: InkWell(
                          child: _wizardVariables.image == null &&
                                  _wizardVariables.pickerColor == null
                              ? _isVault
                                  ? Image.asset(
                                      'assets/images/vault.jpg',
                                      fit: BoxFit.fitWidth,
                                    )
                                  : Image.asset(
                                      'assets/images/iron.jpg',
                                      fit: BoxFit.fitWidth,
                                    )
                              : _wizardVariables.pickerColor != null
                                  ? Container(
                                      height:
                                          width - ICPadding.GENERATE_BUTTONS,
                                      width: width - ICPadding.GENERATE_BUTTONS,
                                      color: _wizardVariables.pickerColor)
                                  : Image.file(_wizardVariables.image!,
                                      height:
                                          width - ICPadding.GENERATE_BUTTONS,
                                      width: width - ICPadding.GENERATE_BUTTONS,
                                      fit: BoxFit.cover),
                        )))),
              ]),
              const Padding(
                padding: EdgeInsets.only(
                  right: 5,
                ),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                  GradientButtonDynamic(
                    text: AppLocalizations.of(context)!.generateImage,
                    fontSize: 14,
                    color: globalState.theme.buttonGenerate,
                    onPressed: _generate,
                  ),
                ]),
                const Padding(
                  padding: EdgeInsets.only(top: 0, bottom: 10),
                ),
                Row(children: [
                  GradientButtonDynamic(
                    text: AppLocalizations.of(context)!.selectFromDevice,
                    fontSize: 14,
                    color: globalState.theme.buttonGenerate,
                    onPressed: () async {
                      File? image = await ImageUtil.selectImage(context);

                      if (image != null) {
                        setState(() {
                          _wizardVariables.pickerColor = null;
                          _wizardVariables.image = image;
                        });
                      }
                    },
                  ),
                ]),
                const Padding(
                  padding: EdgeInsets.only(top: 0, bottom: 10),
                ),
                Row(children: [
                  GradientButtonDynamic(
                    text: AppLocalizations.of(context)!.selectAColor,
                    fontSize: 14,
                    color: globalState.theme.buttonGenerate,
                    onPressed: () async {
                      _pickColor();
                    },
                  ),
                ]),
              ])
            ]));

    final makeBottom = SizedBox(
      height: 55.0,
      child: Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 2, right: 10),
        child: Row(children: <Widget>[
          const Spacer(),
          GradientButtonDynamic(
            text: _isVault
                ? AppLocalizations.of(context)!.create
                : AppLocalizations.of(context)!.next,
            onPressed: _next,
          ),
        ]),
      ),
    );

    final makeBody = Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 10),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ConstrainedBox(
          constraints: const BoxConstraints(),
          child: WrapperWidget(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(
                      top: 5, bottom: 0, left: 10, right: 3),
                  child: Row(children: <Widget>[
                    Expanded(
                      flex: 20,
                      child: FormattedText(
                        labelText: AppLocalizations.of(context)!
                            .enterCircleName, //'enter circle name',
                        maxLength: 25,
                        controller: _circleName,
                        maxLines: 1,
                        validator: (value) {
                          if (value.toString().isEmpty) {
                            return AppLocalizations.of(context)!
                                .nameIsRequired; //'name is required';
                          }
                          return null;
                        },
                      ),
                    )
                  ]),
                ),
                Padding(
                    padding: const EdgeInsets.only(left: 10, top: 5, bottom: 0),
                    child: Row(children: [
                      Text(
                        AppLocalizations.of(context)!
                            .onWhichNetwork, //"On which Network?",
                        textScaler:
                            TextScaler.linear(globalState.labelScaleFactor),
                        style: TextStyle(
                            fontSize: 16, color: globalState.theme.labelText),
                      ),
                    ])),
                Padding(
                    padding: const EdgeInsets.only(left: 10, top: 5, bottom: 0),
                    child: Row(children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: FormattedDropdownObject(
                          hintText: '',
                          expanded: true,
                          list: _furnaceList,
                          dropdownTextColor: globalState.theme.textFieldText,
                          fontSize: 16,
                          selected: _selected,
                          //errorText: state.hasError ? state.errorText : null,
                          onChanged: (ListItem? newValue) {
                            setState(() {
                              _wizardVariables.members.clear();
                              _selected = newValue!;
                            });
                          },
                        ),
                      ),
                    ])),
                Padding(
                    padding:
                        const EdgeInsets.only(left: 10, top: 10, bottom: 0),
                    child: Row(children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: FormattedDropdownObject(
                          hintText: '',
                          //expanded: true,
                          list: widget.circleTypeList,
                          //dropdownTextColor: globalState.theme.textFieldText,
                          fontSize: 16,
                          selected: _selectedType,
                          //errorText: state.hasError ? state.errorText : null,
                          onChanged: (ListItem? newValue) {
                            setState(() {
                              if (newValue!.object == CircleType.OWNER) {
                                if (!PremiumFeatureCheck.canCreateOwnerCircle(
                                    context)) {
                                  return;
                                }
                              } else if (newValue.object ==
                                  CircleType.TEMPORARY) {
                                if (!PremiumFeatureCheck
                                    .canCreateTemporaryCircle(context)) {
                                  return;
                                }
                              }
                              _selectedType = newValue;

                              if (_selectedType!.object == CircleType.VAULT) {
                                _isVault = true;
                              } else {
                                _isVault = false;
                              }
                            });
                          },
                        ),
                      ),
                      IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            DialogNotice.showCircleTypeHelp(context);
                          },
                          icon: const Icon(Icons.help, size: 20))
                    ])),
                Padding(
                    padding:
                        const EdgeInsets.only(left: 10, top: 15, bottom: 0),
                    child: Row(children: [
                      Text(
                        AppLocalizations.of(context)!
                            .selectABackground, // "Select a background",
                        textScaler:
                            TextScaler.linear(globalState.labelScaleFactor),
                        style: TextStyle(
                            fontSize: 16, color: globalState.theme.labelText),
                      ),
                    ])),
                image,
                // InkWell(
                //     onTap: () =>
                //         _backgroundChoice(context, _backgroundTypeCallback),
                //     child: Padding(
                //       padding: const EdgeInsets.only(
                //           top: 2, bottom: 10, left: 10, right: 10),
                //       child: Text(
                //         AppLocalizations.of(context)
                //             .tapCircleToChange, //'(tap circle to change)',
                //         style: TextStyle(
                //             fontSize: 14,
                //             color: globalState.theme.buttonDisabled),
                //         textScaleFactor: 1.0,
                //       ),
                //     )),
                Container(
                  //  color: Colors.white,
                  padding: const EdgeInsets.all(0.0),
                  child: makeBottom,
                ),
              ])),
        ),
      ),
    );

    return Form(
        key: _formKey,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: globalState.theme.background,
          appBar: ICAppBar(
            title: AppLocalizations.of(context)!.createCircleTitle,
          ),
          //drawer: NavigationDrawer(),
          body: SafeArea(
            left: false,
            top: false,
            right: false,
            bottom: true,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(
                      child: makeBody,
                    ),
                  ],
                ),
                _showSpinner ? Center(child: spinkit) : Container(),
              ],
            ),
          ),
        ));
  }

  void changeColor(Color color) {
    setState(() {
      _wizardVariables.pickerColor = color;
      _wizardVariables.image = null;
    });
  }

  _backgroundChoice(context, _shareHandler) {
    DialogChooseBackground.chooseBackgroundPopup(context, _shareHandler);
  }

  _pickColor() {
    _wizardVariables.pickerColor = Colors.lightBlueAccent;
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        surfaceTintColor: Colors.transparent,
        title: ICText(
          AppLocalizations.of(context)!.selectAColor, //'Select a color',
          fontSize: 20,
        ),
        content: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ColorPicker(
            pickerColor: _wizardVariables.pickerColor!,
            onColorChanged: changeColor,
          ),
        ),
        actions: <Widget>[
          GradientButtonDynamic(
            /*style: ElevatedButton.styleFrom(
              backgroundColor: globalState.theme.buttonIcon,
            ),*/
            onPressed: () {
              Navigator.of(context).pop();
            },
            text: AppLocalizations.of(context)!.selectAColor, // 'Select color',
            fontSize: 16,
          ),
        ],
      ),
    );
  }

  _selectImage() async {
    try {
      ImagePicker imagePicker = ImagePicker();
      _wizardVariables.pickerColor = null;

      var imageFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (imageFile != null) // debugPrint (imageFile.path);
        setState(() {
          _wizardVariables.image = File(imageFile.path);
        });
    } catch (err, trace) {
      if (err.toString().contains('photo_access_denied')) {
        Permissions.askOpenSettings(context);
      } else {
        LogBloc.insertError(err, trace);
        debugPrint('NewCircle.selectImage: $err');
      }
    }
  }

  // Future<void> _cropImage() async {
  //   if (_wizardVariables.image == null) return;
  //
  //   File? croppedFile = await Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //         builder: (context) => DartImageCropper(source: _wizardVariables.image!)),
  //   );
  //
  //   if (croppedFile != null) {
  //     setState(() {
  //       _wizardVariables.image = croppedFile;
  //       //state = AppState.cropped;
  //     });
  //   }
  // }

  // Future<void> _cropImage() async {
  //   if (_wizardVariables.image == null) return;
  //
  //   ImageCropper imageCropper = ImageCropper();
  //
  //   CroppedFile? croppedFile = await imageCropper.cropImage(
  //       sourcePath: _wizardVariables.image!.path,
  //       aspectRatioPresets: Platform.isAndroid
  //           ? [
  //               CropAspectRatioPreset.square,
  //               CropAspectRatioPreset.ratio3x2,
  //               CropAspectRatioPreset.original,
  //               CropAspectRatioPreset.ratio4x3,
  //               CropAspectRatioPreset.ratio16x9
  //             ]
  //           : [
  //               CropAspectRatioPreset.original,
  //               CropAspectRatioPreset.square,
  //               CropAspectRatioPreset.ratio3x2,
  //               CropAspectRatioPreset.ratio4x3,
  //               CropAspectRatioPreset.ratio5x3,
  //               CropAspectRatioPreset.ratio5x4,
  //               CropAspectRatioPreset.ratio7x5,
  //               CropAspectRatioPreset.ratio16x9
  //             ],
  //       uiSettings: [
  //         AndroidUiSettings(
  //             toolbarTitle: AppLocalizations.of(context)!.adjustImage,
  //             backgroundColor: globalState.theme.background,
  //             activeControlsWidgetColor: Colors.blueGrey[600],
  //             toolbarColor: globalState.theme.background,
  //             statusBarColor: globalState.theme.background,
  //             toolbarWidgetColor: globalState.theme.menuIcons,
  //             initAspectRatio: CropAspectRatioPreset.original,
  //             lockAspectRatio: false),
  //         IOSUiSettings(
  //           title: AppLocalizations.of(context)!.adjustImage,
  //         )
  //       ]);
  //   if (croppedFile != null) {
  //     setState(() {
  //       _wizardVariables.image = File(croppedFile.path);
  //       //state = AppState.cropped;
  //     });
  //   }
  // }

  _next() async {
    try {
      if (_formKey.currentState!.validate()) {
        if (_clicked == false) {
          _clicked = true;

          _wizardVariables.circle.name = _circleName.text;
          _wizardVariables.circle.type = _selectedType!.name!;

          FocusScope.of(context).requestFocus(FocusNode());

          if (_isVault) {
            ///override the default
            _wizardVariables.circle.privacyShareImage = true;
            _createCircle(
                widget.userFurnaces.firstWhere(
                  (element) => element.pk == _selected!.object.pk,
                ),
                _wizardVariables.circle);
          } else {
            if (_wizardVariables.circle.type == CircleType.OWNER) {
              _wizardVariables.circle.ownershipModel = CircleOwnership.OWNER;
            } else {
              _wizardVariables.circle.ownershipModel = CircleOwnership.MEMBERS;
            }

            //  widget.next(_wizardVariables, _selected, _timerValues);
            WizardVariables? result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => CircleNewWizardSettings(
                          userFurnace: widget.userFurnaces.firstWhere(
                            (element) => element.pk == _selected!.object.pk,
                          ),
                          wizardVariables: _wizardVariables,
                          timerValues: _timerValues,
                        )));

            if (result != null) _wizardVariables = result;

            _clicked = false;
          }
        }
      } else {
        FormattedSnackBar.showSnackbarWithContext(context,
            AppLocalizations.of(context)!.nameIsRequired, '', 2, false);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('NewCircle._createCircle: $err');
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      _clicked = false;
    }
  }

  _createCircle(
    UserFurnace userFurnace,
    Circle circle,
  ) {
    try {
      if (_formKey.currentState!.validate()) {
        setState(() {
          _showSpinner = true;
        });

        _circleBloc.createAndSentInvitations(
            userFurnace,
            circle,
            _wizardVariables.image,
            _wizardVariables.members,
            _wizardVariables.pickerColor);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('NewCircle._createCircle: $err');
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      _clicked = false;
    }
  }

  _backgroundTypeCallback(BuildContext context, bool inside) {
    if (inside) {
      _selectImage();
    } else {
      _pickColor();
    }
  }

  _closeKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  _generate() async {
    _closeKeyboard();

    if (_formKey.currentState!.validate()) {
      SelectedMedia? selectedMedia = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StableDiffusionWidget(
              userFurnace: globalState.userFurnace!,
              imageGenType: ImageType.circle,

              //previewScreenName: 'Preview',
              initialPrompt:
                  StableDiffusionPrompt.getCirclePrompt(_circleName.text)),
        ),
      );

      if (selectedMedia != null &&
          selectedMedia.mediaCollection.media.isNotEmpty) {
        setState(() {});
        _wizardVariables.pickerColor = null;
        _wizardVariables.image = selectedMedia.mediaCollection.media[0].file;
      }
    }
  }
}

class WizardVariables {
  final Circle circle;
  final List<Member> members;
  File? image;
  Color? pickerColor;

  WizardVariables(
      {required this.circle,
      required this.members,
      this.image,
      this.pickerColor});
}
