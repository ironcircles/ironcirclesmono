import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/circlerecipe_bloc.dart';
import 'package:ironcirclesapp/blocs/circlerecipetemplate_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/models/circlerecipetemplate.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circlerecipescreeningredientstab.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circlerecipescreeninstructionsstab.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circlerecipescreenoverviewtab.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circlerecipetemplatescreen.dart';
import 'package:ironcirclesapp/screens/widgets/dialogselectnetwork.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';
import 'package:ironcirclesapp/screens/widgets/selectnetworkstextbutton.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';

class CircleRecipeScreen extends StatefulWidget {
  final UserCircleCache? userCircleCache;
  final UserFurnace? userFurnace;
  final List<UserFurnace> userFurnaces;
  final Function? setNetworks;
  final CircleObject? circleObject;
  final CircleObjectBloc circleObjectBloc;
  final CircleRecipeTemplate? template;
  final int screenMode;
  final CircleRecipeBloc circleRecipeBloc;
  final GlobalEventBloc globalEventBloc;
  final int timer;
  final DateTime? scheduledFor;
  final CircleObject? replyObject;
  final int? increment;
  final bool wall;

  const CircleRecipeScreen({
    Key? key,
    this.circleObject,
    this.template,
    this.userCircleCache,
    required this.userFurnace,
    required this.userFurnaces,
    this.setNetworks,
    required this.screenMode,
    required this.circleRecipeBloc,
    required this.circleObjectBloc,
    required this.globalEventBloc,
    required this.timer,
    this.scheduledFor,
    this.increment,
    this.wall = false,
    required this.replyObject,
  }) : super(key: key);

  @override
  CircleRecipeScreenState createState() => CircleRecipeScreenState();
}

class CircleRecipeScreenState extends State<CircleRecipeScreen> {
  bool _expand = true;

  //bool _saveList = true;

  //ScrollController _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final CircleRecipeTemplateBloc _circleRecipeTemplateBloc =
      CircleRecipeTemplateBloc();

  //List<String> _members = [];
  // List<User> _membersList = [];

  late CircleRecipe _circleRecipe;
  late CircleRecipe _validateChanged;

  final TextEditingController _name = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  final TextEditingController _prepTime = TextEditingController();
  final TextEditingController _cookTime = TextEditingController();
  final TextEditingController _totalTime = TextEditingController();
  final TextEditingController _servings = TextEditingController();

  final List<String> _furnaceList = [];
  String? _furnace = '';
  //String _saveTemplateQuestion = "save template?";
  bool _boolSaveTemplate = true;

  File? _image;

  final double _iconSize = 45;

  List<UserFurnace> _selectedNetworks = [];

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  bool _popping = false;

  _initControllers() {
    if (_circleRecipe.name != null) _name.text = _circleRecipe.name!;

    if (_circleRecipe.notes != null) _notes.text = _circleRecipe.notes!;

    if (_circleRecipe.prepTime != null)
      _prepTime.text = _circleRecipe.prepTime!;

    if (_circleRecipe.cookTime != null)
      _cookTime.text = _circleRecipe.cookTime!;

    if (_circleRecipe.totalTime != null)
      _totalTime.text = _circleRecipe.totalTime!;

    if (_circleRecipe.servings != null)
      _servings.text = _circleRecipe.servings!;
  }

  @override
  void initState() {
    super.initState();

    if (widget.screenMode == ScreenMode.TEMPLATE) {
      _circleRecipe = CircleRecipe.initFromTemplate(widget.template!);
      _validateChanged = CircleRecipe.deepCopy(_circleRecipe);
      _initControllers();

      if (widget.template!.id == null) {
        for (UserFurnace userFurnace in widget.userFurnaces) {
          if (userFurnace.connected!) _furnaceList.add(userFurnace.alias!);
        }
        _furnace = _furnaceList[0];
      } else {
        _furnace = widget.userFurnace!.alias!;
      }
    } else {
      if (widget.screenMode == ScreenMode.ADD && widget.circleObject == null) {
        _circleRecipe = CircleRecipe();
        _validateChanged = CircleRecipe.deepCopy(_circleRecipe);
        _circleRecipe.init();
      } else {
        _circleRecipe = CircleRecipe.deepCopy(widget.circleObject!.recipe!);

        if (_circleRecipe.image != null) {
          if (widget.screenMode == ScreenMode.ADD) {
            //widget.circleObject!.recipe!.image = CircleImage();
            _image = widget.circleObject!.recipe!.image!.thumbnailFile;
            _circleRecipe.image!.thumbnailFile = _image;
          } else {
            File file = File(ImageCacheService.returnThumbnailPath(
                widget.userCircleCache!.circlePath!, widget.circleObject!));
            if (file.existsSync()) _image = file;
          }
        }
        _validateChanged = widget.circleObject!.recipe!;
        _initControllers();
      }
    }

    _circleRecipeTemplateBloc.upsertFinished.listen((object) {
      if (mounted) {
        _closeKeyboard();
        //Navigator.of(context).pop(object);
      }
    }, onError: (err) {
      debugPrint("error $err");
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);

      setState(() {
        _showSpinner = false;
      });
    }, cancelOnError: false);

    widget.circleRecipeBloc.created.listen((circleObject) {
      if (mounted) {
        if (circleObject.id == null) {
          _exit(circleObject: circleObject);
        }
      }
    }, onError: (err) {
      debugPrint("error $err");
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);

      setState(() {
        _showSpinner = false;
      });
    }, cancelOnError: false);

    widget.globalEventBloc.recipeUpdated.listen((circleObject) {
      if (mounted) {
        _exit(circleObject: circleObject);
      }
    }, onError: (err) {
      debugPrint(
          "CircleRecipeScreen.widget.circleRecipeBloc.update.listen:  $err");
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);

      setState(() {
        _showSpinner = false;
      });
    }, cancelOnError: false);
  }

  @override
  void dispose() {
    _circleRecipe.disposeUIControls();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final makeHeader =
        Column(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
      widget.screenMode == ScreenMode.TEMPLATE
          ? widget.template!.id != null
              ? Container()
              : Padding(
                  padding: const EdgeInsets.only(left: 11, top: 4, bottom: 0),
                  child: _expand
                      ? Row(children: <Widget>[
                          Expanded(
                            flex: 20,
                            child: FormField(
                              builder: (FormFieldState<String> state) {
                                return FormattedDropdown(
                                  hintText: AppLocalizations.of(context)!
                                      .selectANetwork
                                      .toLowerCase(),
                                  list: _furnaceList,
                                  selected: _furnace,
                                  expanded: true,
                                  errorText:
                                      state.hasError ? state.errorText : null,
                                  onChanged: (String? value) {
                                    setState(() {
                                      if (value != null) {
                                        _furnace = value!;
                                        if (value!.isEmpty) value = null;
                                        state.didChange(value);
                                      }
                                    });
                                  },
                                );
                              },
                              validator: (dynamic value) {
                                return _furnace == null
                                    ? AppLocalizations.of(context)!
                                        .selectANetwork
                                        .toLowerCase()
                                    : null;
                              },
                            ),
                          )
                        ])
                      : Container(),
                )
          : Container(),
      Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        child: _expand
            ? Row(children: <Widget>[
                Expanded(
                  flex: 2,
                  child: ExpandingLineText(
                    maxLength: TextLength.Smallest,
                    counterText: '',
                    readOnly:
                        widget.screenMode == ScreenMode.READONLY ? true : false,
                    labelText: AppLocalizations.of(context)!
                        .nameOfRecipe
                        .toLowerCase(),
                    maxLines: 1,
                    hintSize: 13,
                    controller: _name,
                    validator: (value) {
                      if (value.toString().isEmpty) {
                        return AppLocalizations.of(context)!
                            .requiredToSaveRecipe
                            .toLowerCase();
                      }
                      return null;
                    },
                  ),
                ),
                widget.screenMode == ScreenMode.ADD
                    ? ClipOval(
                        child: Material(
                          color: globalState.theme.background, // button color
                          child: InkWell(
                            splashColor: globalState
                                .theme.buttonIconSplash, // inkwell color
                            child: SizedBox(
                                width: _iconSize,
                                height: _iconSize,
                                child: Icon(
                                  Icons.search,
                                  color: globalState.theme.menuIcons,
                                )),
                            onTap: () {
                              _search();
                            },
                          ),
                        ),
                      )
                    : Container(),
                Expanded(
                  flex: 1,
                  child: ExpandingLineText(
                    counterText: '',
                    maxLength: TextLength.Smallest,
                    readOnly:
                        widget.screenMode == ScreenMode.READONLY ? true : false,
                    labelText:
                        AppLocalizations.of(context)!.servings.toLowerCase(),
                    maxLines: 1,
                    controller: _servings,
                    hintSize: 13,
                    validator: (value) {
                      return null;
                    },
                  ),
                ),
              ])
            : Container(),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 0),
        child: _expand
            ? Row(children: <Widget>[
                Expanded(
                  flex: 1,
                  child: ExpandingLineText(
                    counterText: '',
                    maxLength: TextLength.Smallest,
                    readOnly:
                        widget.screenMode == ScreenMode.READONLY ? true : false,
                    labelText:
                        AppLocalizations.of(context)!.prepTime.toLowerCase(),
                    hintSize: 13,
                    maxLines: 1,
                    controller: _prepTime,
                    validator: (value) {
                      /* if (value.toString().isEmpty) {
                      return 'required to save recipe';
                    }*/
                      return null;
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 0, right: 5),
                ),
                Expanded(
                  flex: 1,
                  child: ExpandingLineText(
                    counterText: '',
                    maxLength: TextLength.Smallest,
                    hintSize: 13,
                    labelText:
                        AppLocalizations.of(context)!.cookTime.toLowerCase(),
                    readOnly:
                        widget.screenMode == ScreenMode.READONLY ? true : false,
                    maxLines: 1,
                    controller: _cookTime,
                    validator: (value) {
                      /* if (value.toString().isEmpty) {
                      return 'required to save recipe';
                    }*/
                      return null;
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 0, right: 5),
                ),
                Expanded(
                  flex: 1,
                  child: ExpandingLineText(
                    counterText: '',
                    maxLength: TextLength.Smallest,
                    labelText:
                        AppLocalizations.of(context)!.totalTime.toLowerCase(),
                    hintSize: 13,
                    readOnly:
                        widget.screenMode == ScreenMode.READONLY ? true : false,
                    maxLines: 1,
                    controller: _totalTime,
                    validator: (value) {
                      /* if (value.toString().isEmpty) {
                      return 'required to save recipe';
                    }*/
                      return null;
                    },
                  ),
                ),
              ])
            : Container(),
      ),
    ]);

    final body = DefaultTabController(
      length: 3,
      initialIndex: 0,
      child: Scaffold(
          backgroundColor: globalState.theme.background,
          appBar: TabBar(
            tabAlignment: TabAlignment.start,
            dividerHeight: 0.0,
            isScrollable: true,
            indicatorPadding: const EdgeInsets.symmetric(horizontal: -10.0),
            labelPadding: const EdgeInsets.symmetric(horizontal: 10.0),
            unselectedLabelColor: globalState.theme.unselectedLabel,
            labelColor: globalState.theme.tabIndicatorRecipe,
            indicatorColor: globalState.theme.tabIndicatorRecipe,
            indicator: BoxDecoration(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10)),
                color: globalState.theme.tabBackground),
            tabs: [
              Tab(
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    AppLocalizations.of(context)!.overview,
                    textScaler: TextScaler.linear(1.0),
                  ), // , style: TextStyle(color: globalState.theme.tabText),),
                ),
              ),
              Tab(
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    AppLocalizations.of(context)!.ingredients,
                    textScaler: TextScaler.linear(1.0),
                  ),
                ),
              ),
              Tab(
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    AppLocalizations.of(context)!.instructions,
                    textScaler: TextScaler.linear(1.0),
                  ),
                ),
              ),
            ],
          ),
          body: TabBarView(
            children: [
              CircleRecipeScreenOverviewTab(
                circleRecipe: _circleRecipe,
                screenMode: widget.screenMode,
                controller: _notes,
                image: _image,
              ),
              CircleRecipeIngredientsTab(
                circleRecipe: _circleRecipe,
                screenMode: widget.screenMode,
              ),
              CircleRecipeInstructionsTab(
                circleRecipe: _circleRecipe,
                screenMode: widget.screenMode,
              ),
            ],
          )),
    );

    final makeBottom = widget.screenMode == ScreenMode.READONLY
        ? Container()
        : SizedBox(
            height: 70,
            child: Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 0),
                child: Column(
                    //crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Row(children: <Widget>[
                        Expanded(
                            flex: 1,
                            child: Center(
                                child: Container(
                                    constraints: BoxConstraints(
                                        maxWidth: ScreenSizes.getMaxButtonWidth(
                                            width, true),
                                        maxHeight: 70),
                                    child: GradientButton(
                                        text: widget.screenMode ==
                                                    ScreenMode.ADD ||
                                                (widget.screenMode ==
                                                        ScreenMode.TEMPLATE &&
                                                    _circleRecipe
                                                        .template!.isEmpty)
                                            ? AppLocalizations.of(context)!
                                                .createRecipe
                                                .toUpperCase()
                                            : AppLocalizations.of(context)!
                                                .updateRecipe
                                                .toUpperCase(),
                                        onPressed: () {
                                          _save();
                                        }))))
                      ])
                    ])));

    final topAppBar = AppBar(
      iconTheme: IconThemeData(
        color: globalState.theme.menuIcons, //change your color here
      ),
      elevation: 0,
      toolbarHeight: 45,
      centerTitle: false,
      titleSpacing: 0.0,
      backgroundColor: globalState.theme.appBar,
      leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _pop(_prepObject());
          }),
      title: widget.screenMode == ScreenMode.ADD
          ? Text(AppLocalizations.of(context)!.newRecipe,
              style: ICTextStyle.getStyle(
                  context: context,
                  color: globalState.theme.textTitle,
                  fontSize: ICTextStyle.appBarFontSize))
          : Text(AppLocalizations.of(context)!.recipe,
              style: ICTextStyle.getStyle(
                  context: context,
                  color: globalState.theme.textTitle,
                  fontSize: ICTextStyle.appBarFontSize)),
      actions: <Widget>[
        globalState.isDesktop()
            ? Container()
            : ClipOval(
                child: Material(
                  color: globalState.theme.background, // button color
                  child: InkWell(
                    splashColor:
                        globalState.theme.buttonIconSplash, // inkwell color
                    child: SizedBox(
                        width: _iconSize,
                        height: _iconSize,
                        child: Icon(
                          _expand ? Icons.expand_less : Icons.expand_more,
                          color: globalState.theme.menuIcons,
                        )),
                    onTap: () {
                      setState(() {
                        _expand = !_expand;
                      });
                    },
                  ),
                ),
              ),
      ],
    );

    final _formWidget = Form(
      key: _formKey,
      child: Scaffold(
        backgroundColor: globalState.theme.background,
        key: _scaffoldKey,
        appBar: topAppBar,
        body: SafeArea(
            left: false,
            top: false,
            right: false,
            bottom: true,
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 5),
              child: Stack(
                children: [
                  WrapperWidget(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      makeHeader,
                      const Padding(
                        padding: EdgeInsets.only(top: 15),
                      ),
                      Expanded(child: body),

                      ///select a furnace to post to
                      widget.userFurnaces.length > 1 &&
                              widget.wall &&
                              widget.setNetworks != null
                          ? Row(children: <Widget>[
                              Expanded(
                                  flex: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        top: 10, left: 2, right: 2),
                                    child: SelectNetworkTextButton(
                                      userFurnaces: widget.userFurnaces,
                                      selectedNetworks: _selectedNetworks,
                                      callback: _setNetworks,
                                    ),
                                  ))
                            ])
                          : Container(),
                      makeBottom,
                    ],
                  )),
                  _showSpinner ? Center(child: spinkit) : Container(),
                ],
              ),
            )),
      ),
    );

    return PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) {
          if (didPop) {
            return;
          }
          _pop(_prepObject());
        },
        child: Platform.isIOS
            ? GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.velocity.pixelsPerSecond.dx > 200) {
                    _pop(_prepObject());
                  }
                },
                child: _formWidget)
            : _formWidget);

    // return WillPopScope(
    //     onWillPop: () {
    //       _pop(_prepObject());
    //       return Future<bool>.value(false);
    //     },
    //     child: Platform.isIOS
    //         ? GestureDetector(
    //             onHorizontalDragEnd: (details) {
    //               if (details.velocity.pixelsPerSecond.dx > 200) {
    //                 _pop(_prepObject());
    //               }
    //             },
    //             child: _formWidget)
    //         : _formWidget);
  }

  _pop(CircleObject prepObject) {
    if (widget.wall == false &&
        (widget.screenMode == ScreenMode.ADD ||
            CircleRecipe.deepCompareChanged(
                widget.circleObject!.recipe!, prepObject.recipe!))) {
      DialogYesNo.askYesNo(
          context,
          widget.screenMode == ScreenMode.ADD
              ? widget.circleObject == null || widget.circleObject!.id != null
                  ? AppLocalizations.of(context)!.saveDraftTitle
                  : AppLocalizations.of(context)!.updateDraftTitle
              : AppLocalizations.of(context)!.saveChangesTitle,
          widget.screenMode == ScreenMode.ADD
              ? widget.circleObject == null || widget.circleObject!.id != null
                  ? AppLocalizations.of(context)!.saveDraftMessage
                  : AppLocalizations.of(context)!.updateDraftMessage
              : AppLocalizations.of(context)!.saveChangesMessage,
          widget.screenMode == ScreenMode.ADD ? _saveDraft : _save,
          _exitCheckToSave,
          false);
    } else {
      _exitCheckToSave();
    }
  }

  _save() async {
    if (_showSpinner == false && _formKey.currentState!.validate()) {
      _showSpinner = true;
      setState(() {});

      if (widget.screenMode == ScreenMode.TEMPLATE)
        _saveTemplate();
      else if (widget.wall) {
        if (_selectedNetworks.isEmpty) {
          if (widget.userFurnaces.length == 1) {
            _setNetworksAndPost(widget.userFurnaces);
          } else {
            List<UserFurnace>? selectedNetworks =
                await DialogSelectNetworks.selectNetworks(
                    context: context,
                    networks: widget.userFurnaces,
                    callback: _setNetworksAndPost,
                    existingNetworksFilter: _selectedNetworks);

            if (selectedNetworks == null) {
              setState(() {
                _showSpinner = false;
              });
            }
          }
        } else {
          _saveCircleObject();
        }
      } else {
        _saveCircleObject();
      }
    }
  }

  _saveTemplate() {
    late UserFurnace userFurnace;

    if (widget.template!.id == null) {
      for (UserFurnace testFurnace in widget.userFurnaces) {
        if (testFurnace.alias == _furnace) {
          userFurnace = testFurnace;
          break;
        }
      }
    } else
      userFurnace = widget.userFurnace!;

    _circleRecipeTemplateBloc.put(_circleRecipe, userFurnace);
  }

  CircleObject _prepObject() {
    _circleRecipe.name = _name.text;
    _circleRecipe.prepTime = _prepTime.text;
    _circleRecipe.cookTime = _cookTime.text;
    _circleRecipe.totalTime = _totalTime.text;
    _circleRecipe.servings = _servings.text;
    _circleRecipe.notes = _notes.text;

    for (CircleRecipeInstruction circleRecipeInstruction
        in _circleRecipe.instructions!) {
      circleRecipeInstruction.name = circleRecipeInstruction.controller!.text;
    }

    for (CircleRecipeIngredient circleRecipeIngredient
        in _circleRecipe.ingredients!) {
      circleRecipeIngredient.name = circleRecipeIngredient.controller!.text;
    }
    //remove any ingredients or instructions that were left blank by the user
    _circleRecipe.instructions!.removeWhere((element) => element.name!.isEmpty);
    _circleRecipe.ingredients!.removeWhere((element) => element.name!.isEmpty);
    _circleRecipe.instructions!.removeWhere((element) => element.name == null);
    _circleRecipe.ingredients!.removeWhere((element) => element.name == null);

    CircleObject newObject = CircleObject.prepNewCircleObject(
        widget.userCircleCache!,
        widget.userFurnace!,
        null,
        0,
        widget.replyObject, type: CircleObjectType.CIRCLERECIPE);
    //newObject.type = CircleObjectType.CIRCLERECIPE;
    newObject.body = _circleRecipe.name;
    newObject.recipe = _circleRecipe;

    return newObject;
  }

  _saveCircleObject() {
    if (widget.screenMode == ScreenMode.ADD) {
      CircleObject newObject = _prepObject();

      if (widget.timer != UserDisappearingTimer.OFF) {
        newObject.timer = widget.timer;
      }
      if (widget.scheduledFor != null) {
        newObject.scheduledFor = widget.scheduledFor;
        newObject.dateIncrement = widget.increment!;
      }

      if (widget.wall) {
        ///Don't save the object if it's a wall post. The User might have selected multiple networks
        //_pop(newObject);
        _exit(circleObject: newObject);
      } else {
        widget.circleRecipeBloc.create(
            widget.userCircleCache!,
            newObject,
            widget.userFurnace!,
            _boolSaveTemplate,
            !(widget.screenMode == ScreenMode.ADD &&
                widget.circleObject != null));
      }
    } else if (widget.screenMode == ScreenMode.EDIT) {
      CircleObject circleObject = widget.circleObject!;
      CircleObject recipeObject = _prepObject();
      circleObject.recipe = recipeObject.recipe;
      circleObject.body = _circleRecipe.name;
      widget.circleRecipeBloc
          .update(widget.userCircleCache!, circleObject, widget.userFurnace!);
    }
  }

  _search() async {
    CircleRecipeTemplate? recipeTemplate = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              CircleRecipeTemplateScreen(userFurnaces: widget.userFurnaces)),
    );

    if (recipeTemplate != null) {
      setState(() {
        _circleRecipe = CircleRecipe.initFromTemplate(recipeTemplate);
        _initControllers();
        //_saveTemplateQuestion = "update library?";
      });
    }
  }

  _saveDraft() async {
    CircleObject circleObject = _prepObject();

    await widget.circleObjectBloc.saveDraft(
        widget.userFurnace!, widget.userCircleCache!, '', null, null,
        preppedObject: circleObject);

    _exit();
  }

  _exitCheckToSave() async {
    if (widget.circleObject != null && widget.circleObject!.draft) {
      await widget.circleObjectBloc.saveDraft(
          widget.userFurnace!, widget.userCircleCache!, '', null, null,
          preppedObject: widget.circleObject!);
    }

    _exit();
  }

  _exit({CircleObject? circleObject}) {
    _closeKeyboard();
    if (circleObject != null) {
      if (_popping == false) {
        _popping = true;
        Navigator.of(context).pop(circleObject);
      }
    } else {
      if (_popping == false) {
        _popping = true;
        Navigator.pop(context);
      }
    }
  }

  _closeKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  ///callback for the automatic popup
  _setNetworksAndPost(List<UserFurnace> newlySelectedNetworks) {
    if (widget.setNetworks != null) {
      widget.setNetworks!(newlySelectedNetworks);
      _selectedNetworks = newlySelectedNetworks;

      _saveCircleObject();
    }
  }

  ///callback for the ui control tap
  _setNetworks(List<UserFurnace> newlySelectedNetworks) {
    if (widget.setNetworks != null) {
      widget.setNetworks!(newlySelectedNetworks);
      _selectedNetworks = newlySelectedNetworks;
      setState(() {});
    }
  }
}
