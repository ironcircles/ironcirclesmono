import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
import 'package:ironcirclesapp/blocs/database_bloc.dart';
import 'package:ironcirclesapp/blocs/ironcoin_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/stablediffusionai_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/stablediffusionprompt.dart';
import 'package:ironcirclesapp/screens/fullscreen/fullscreenimagefromfile.dart';
import 'package:ironcirclesapp/screens/payment/ironstore_ironcoin.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/logic/image_writer.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/logic/mask_generator.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/pages/mask_previewer_page.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/structs/SelectionWithTool.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/structs/image_details.dart';
import 'package:ironcirclesapp/screens/stablediffusion/prompthistory.dart';
import 'package:ironcirclesapp/screens/stablediffusion/stablediffusion_inpainting_configuration.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/gradientbuttonironcoin.dart';
import 'package:ironcirclesapp/screens/widgets/icprogressdialog.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:ndialog/ndialog.dart';

class StableDiffusionMaskWidget extends StatefulWidget {
  final UserFurnace userFurnace;
  final String initialPrompt;
  final ImageType imageGenType;
  final int timer;
  final Function? setTimer;
  final String previewScreenName;
  final Function? redo;
  final bool wall;
  final List<UserFurnace> userFurnaces;
  final Function? setNetworks;
  late File original;
  late File base;
  StableDiffusionPrompt prompt;

  StableDiffusionMaskWidget({
    Key? key,
    required this.userFurnace,
    required this.imageGenType,
    this.previewScreenName = '',
    this.timer = 0,
    this.setTimer,
    this.initialPrompt = "",
    required this.original,
    required this.base,
    this.wall = false,
    this.userFurnaces = const [],
    this.redo,
    this.setNetworks,
    required this.prompt,
  }) : super(key: key);

  @override
  _LocalState createState() {
    return _LocalState();
  }
}

class _LocalState extends State<StableDiffusionMaskWidget> {
  StableDiffusionAIBloc stableDiffusionAIBloc = StableDiffusionAIBloc();
  final _promptController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final databaseBloc = DatabaseBloc();
  ProgressDialog? importingData;
  String assigned = '';
  bool validatedOnceAlready = false;
  File? _img;
  late File _original;
  //double radius = 225 - (globalState.scaleDownTextFont * 2);
  bool _genImage = false;
  ICProgressDialog icProgressDialog = ICProgressDialog();
  final IronCoinBloc _ironCoinBloc = IronCoinBloc();
  late UserFurnace authFurnace;
  List<int> imageDimensions = [320, 512, 768, 1024];
  double temporaryCost = 0;
  // bool _firstBuildComplete = false;
  int generateCost = 0;
  // bool _drawing = true;
  // int _initialIndex = 0;
  bool _scroll = false;
  //late ThumbnailDimensions _thumbnailDimensions;
  //late ThumbnailDimensions thumbnailDimensions;

  late ImageDetails _imageDetails;

  // late int _generateTab;
  late double storeHeight;
  late double storeWidth;

  File? maskImage;

  int getFixedSize(int size) {
    int retValue = 1024;

    // if (size >= 1024)
    //   retValue = 1024;
    // else if (size >= 768)
    //   retValue = 768;
    // else if (size >= 512)
    //   retValue = 512;
    // else
    //   retValue = 320;

    if (size <= 320)
      retValue = 320;
    else if (size <= 512)
      retValue = 512;
    else if (size <= 768) retValue = 768;

    return retValue;
  }

  @override
  void initState() {
    super.initState();
    _original = widget.original;

    _setDimensions(false);

    generateCost =
        globalState.stableDiffusionPricing.calculateCharge(widget.prompt);

    if (widget.initialPrompt.isNotEmpty) {
      _promptController.text = widget.initialPrompt;
      widget.prompt.prompt = widget.initialPrompt;
    }

    if (widget.prompt.maskImage != null) {
      maskImage = widget.prompt.maskImage;
    }
    if (widget.prompt.prompt.isNotEmpty) {
      _promptController.text = widget.prompt.prompt;
    }
    if (widget.prompt.generatedImage != null) {
      _img = widget.prompt.generatedImage;
    }

    authFurnace = widget.userFurnace;

    _ironCoinBloc.recentCoinPayment.listen((payment) {
      _imageGeneration();
    }, onError: (err) {
      icProgressDialog.dismiss();
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);

      if (err.contains(AppLocalizations.of(context)!.notEnoughIronCoin)) {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const IronStoreIronCoin(),
            ));
      }

      debugPrint("recentCoinPayment.listen: $err");
    }, cancelOnError: false);

    stableDiffusionAIBloc.generateImageComplete.listen((event) {},
        onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
    });
    widget.prompt.negativePrompt =
        "ugly, tiling, poorly drawn hands, poorly drawn feet, poorly drawn face, out of frame, extra limbs, disfigured, deformed, body out of frame, blurry, bad anatomy, blurred, watermark, grainy, signature, cut off, draft";
  }

  _checkScroll() {
    if (_scroll) {
      _scroll = false;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(seconds: 1),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScroll();
    });

    double availableWidth = MediaQuery.of(context).size.width - 20;
    double width = availableWidth;
    double height = availableWidth;

    if (widget.prompt.width <= availableWidth) {
      ///scale up
      double ratio = availableWidth / widget.prompt.width;

      width = availableWidth;

      height = (widget.prompt.height * ratio).toDouble();
    } else if (widget.prompt.width >= availableWidth) {
      ///scale down
      double ratio = widget.prompt.width / availableWidth;

      width = availableWidth;

      height = (widget.prompt.height / ratio).toDouble();
    }

    storeHeight = height;
    storeWidth = width;

    final drawButton = Row(children: [
      ICText(
        "${AppLocalizations.of(context)!.step1}: ",
        color: globalState.theme.labelText,
        fontSize: 16,
      ),
      Expanded(
          child: Padding(
              padding: const EdgeInsets.only(
                  top: 5, bottom: 10, right: 10, left: 15),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                        child: InkWell(
                            onTap: () {
                              _drawMask();
                            },
                            child: Container(
                                decoration: BoxDecoration(
                                    color: globalState.theme.menuBackground,
                                    border: Border.all(
                                        color: Colors.lightBlueAccent
                                            .withOpacity(.1),
                                        width: 2.0),
                                    borderRadius: BorderRadius.circular(12.0)),
                                padding: const EdgeInsets.only(
                                    top: 10, bottom: 10, left: 15, right: 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(AppLocalizations.of(context)!.drawMask,
                                        textScaler:
                                            const TextScaler.linear(1.0),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: globalState.theme.labelText,
                                        )),
                                    Icon(Icons.keyboard_arrow_right,
                                        color: globalState.theme.labelText,
                                        size: 25.0),
                                  ],
                                )))),
                  ])))
    ]);

    final generateButton =
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.only(top: 15),
          child: ICText(
            "${AppLocalizations.of(context)!.step3}: ",
            color: globalState.theme.labelText,
            fontSize: 16,
          )),
      Expanded(
          child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GradientButtonIronCoin(
            cost: generateCost.toString(),
            balance: globalState.ironCoinWallet.balance,
            genImage: _genImage,
            onPressed: _generate,
            configure: _showConfigure),
      ))
    ]);

    final finalImageDescription =
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.only(top: 15),
          child: ICText(
            "${AppLocalizations.of(context)!.step2}: ",
            color: globalState.theme.labelText,
            fontSize: 16,
          )),
      Expanded(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 125),
              child: Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 0,
                  ),
                  child: ExpandingLineText(
                    onChanged: (String value) {
                      widget.prompt.prompt = value;
                    },
                    maxLines: 3,
                    maxLength: 1000,
                    controller: _promptController,
                    labelText: AppLocalizations.of(context)!
                        .describeFinalImage
                        .toLowerCase(),
                  ))))
    ]);

    final image = Padding(
        padding: const EdgeInsets.only(top: 5, left: 0, bottom: 15),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          InkWell(
              splashColor: Colors.transparent,
              onTap: () {
                fullScreen(_original);
              },
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Stack(children: [
                  Container(
                      width: ScreenSizes.getMaxImageWidth(width) -
                          ICPadding.GENERATE_BUTTONS,
                      height: ScreenSizes.getMaxImageWidth(width) -
                          ICPadding.GENERATE_BUTTONS,
                      constraints: BoxConstraints(
                          maxHeight: ScreenSizes.getMaxImageWidth(width) -
                              ICPadding.GENERATE_BUTTONS,
                          maxWidth: ScreenSizes.getMaxImageWidth(width) -
                              ICPadding.GENERATE_BUTTONS),
                      child: widget.imageGenType == ImageType.image
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: InkWell(
                                  child: Image.file(
                                _original,
                                fit: BoxFit.fitHeight,
                              )))
                          : ClipOval(
                              child: InkWell(
                                  child: Image.file(
                              _original,
                              fit: BoxFit.fitHeight,
                            )))),
                  Container(
                      width: ScreenSizes.getMaxImageWidth(width) -
                          ICPadding.GENERATE_BUTTONS,
                      height: ScreenSizes.getMaxImageWidth(width) -
                          ICPadding.GENERATE_BUTTONS,
                      constraints: BoxConstraints(
                          maxHeight: ScreenSizes.getMaxImageWidth(width) -
                              ICPadding.GENERATE_BUTTONS,
                          maxWidth: ScreenSizes.getMaxImageWidth(width) -
                              ICPadding.GENERATE_BUTTONS),
                      child: widget.imageGenType == ImageType.image
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: InkWell(
                                  child: maskImage != null
                                      ? Image.file(maskImage!,
                                          color: const Color.fromRGBO(
                                              255, 255, 255, 0.5),
                                          colorBlendMode: BlendMode.modulate,
                                          fit: BoxFit.fitHeight)
                                      : Container()))
                          : ClipOval(
                              child: InkWell(
                                  child: maskImage != null
                                      ? Image.file(
                                          maskImage!,
                                          color: const Color.fromRGBO(
                                              255, 255, 255, 0.5),
                                          colorBlendMode: BlendMode.modulate,
                                          fit: BoxFit.fitHeight,
                                        )
                                      : Container())))
                ]),
              ])),
        ]));

    final makeBottom = Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 0),
        child: globalState.isDesktop()
            ? Row(children: <Widget>[
                const Spacer(),
                SizedBox(
                    height: 55,
                    width: 300,
                    child: GradientButton(
                      text:
                          AppLocalizations.of(context)!.postImage.toUpperCase(),
                      onPressed: _next,
                    ))
              ])
            : Row(children: <Widget>[
                Expanded(
                    child: GradientButton(
                  text: AppLocalizations.of(context)!.postImage.toUpperCase(),
                  onPressed: _next,
                )),
              ]));

    final generatedImage = Padding(
        padding: const EdgeInsets.only(top: 5, left: 0, bottom: 15),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _img != null
                ? InkWell(
                    splashColor: Colors.transparent,
                    onTap: () {
                      if (_img != null) fullScreen(_img!);
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
                        child: widget.imageGenType == ImageType.image
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: InkWell(
                                    child: _img != null
                                        ? Image.file(
                                            _img!,
                                            fit: BoxFit.fitHeight,
                                          )
                                        : Container()))
                            : ClipOval(
                                child: InkWell(
                                    child: _img != null
                                        ? Image.file(
                                            _img!,
                                            fit: BoxFit.fitHeight,
                                          )
                                        : Container()))))
                : Container(),
          ]),
          Row(children: [
            const Spacer(),
            const Padding(
              padding: EdgeInsets.only(left: 100),
            ),
            _img != null
                ? TextButton(
                    child: ICText(
                      "^ inpaint this image",
                      color: globalState.theme.buttonGenerate,
                    ),
                    onPressed: () {
                      setState(() {
                        widget.original = _img!;
                        _original = _img!;
                        _img = null;
                        PaintingBinding.instance.imageCache.clear();
                        imageCache.clear();
                        _setDimensions(true);
                      });
                    },
                    //icon: const Icon(Icons.arrow_back)
                  )
                : Container(),
            const Spacer(),
          ]),
        ]));

    final bodyWidget = Container(
        child: Scrollbar(
            // thumbVisibility: false,
            controller: _scrollController,
            child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                controller: _scrollController,
                child: WrapperWidget(
                    child:Column(children: <Widget>[
                  ///make drawing
                  drawButton,

                  ///see mask and original
                  image,

                  ///final image description
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: finalImageDescription,
                    ),
                    IconButton(
                        onPressed: () {
                          _history(context);
                        },
                        icon: Icon(
                          Icons.history,
                          color: globalState.theme.buttonGenerate,
                        ))
                  ]),

                  ///generate
                  generateButton,

                  ///seed
                  widget.prompt.visualOnlySeed != -1
                      ? Row(children: [
                          const Spacer(),
                          ICText(
                            "Seed: ",
                            color: globalState.theme.labelText,
                          ),
                          SelectableText(
                            widget.prompt.visualOnlySeed.toString(),
                            textScaler: const TextScaler.linear(1),
                            style:
                                TextStyle(color: globalState.theme.labelText),
                          ),
                        ])
                      : Container(),

                  ///display generated image
                  _img != null ? generatedImage : Container(),
                  widget.original.path != widget.base.path || _img != null
                      ? makeBottom
                      : Container(),
                ])))));

    return SafeArea(
      left: false,
      top: false,
      right: false,
      bottom: true,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: globalState.theme.background,
        body:  Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                const Padding(padding: EdgeInsets.only(bottom: 0)), //5
                Expanded(
                  child: bodyWidget,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _imageGeneration() async {
    try {
      _genImage = true;
      widget.prompt.initImage = _original;

      File? newImg =
          await stableDiffusionAIBloc.inpaintWithImage(widget.prompt);

      setState(() {
        _scroll = true;
        _img = newImg!;
      });

      widget.prompt.generatedImage = _img!;

      icProgressDialog.dismiss();
    } catch (error, trace) {
      icProgressDialog.dismiss();
      LogBloc.insertError(error, trace);
      FormattedSnackBar.showSnackbarWithContext(
          context, error.toString(), "", 2, false);
    }
  }

  _closeKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  _stableDiffusionConfigureCallback() {
    setState(() {
      generateCost =
          globalState.stableDiffusionPricing.calculateCharge(widget.prompt);
      _promptController.text = widget.prompt.prompt;
    });
  }

  _setDimensions(bool afterChange) async {
    ThumbnailDimensions thumbnailDimensions =
        ThumbnailDimensions.getDimensionsFromFile(_original, reduceSize: false);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (thumbnailDimensions.errorOccurred == true) {
        DialogNotice.showNotice(
            context,
            AppLocalizations.of(context)!.thumbnailDimensionsErrorTitle,
            AppLocalizations.of(context)!.thumbnailDimensionsErrorLine1,
            "",
            "",
            "",
            false);
      }
    });
    //_thumbnailDimensions = ThumbnailDimensions(width: thumbnailDimensions.width, height: thumbnailDimensions.height);
    // _imageDetails = ImageDetails(
    //   widget.original.path,
    //   thumbnailDimensions.width,
    //   thumbnailDimensions.height,
    //   widget.original,
    // );

    if (thumbnailDimensions.width > thumbnailDimensions.height &&
        thumbnailDimensions.width > 1024) {
      double ratio = thumbnailDimensions.width / 1024;
      thumbnailDimensions.width = 1024;

      thumbnailDimensions.height = (thumbnailDimensions.height ~/ ratio);
    } else if (thumbnailDimensions.height > 1024) {
      double ratio = thumbnailDimensions.height / 1024;
      thumbnailDimensions.height = 1024;

      thumbnailDimensions.width = (thumbnailDimensions.width ~/ ratio);
    }

    _imageDetails = ImageDetails(
      widget.original.path,
      thumbnailDimensions.width,
      thumbnailDimensions.height,
      widget.original,
    );

    widget.prompt.width = getFixedSize(thumbnailDimensions.width);
    widget.prompt.height = getFixedSize(thumbnailDimensions.height);

    if (afterChange) {
      generateMask(context, widget.prompt.screenPoints!);
    }
  }

  _next() async {
    _closeKeyboard();
    File? inpaintedImage;

    if (_img != null) {
      inpaintedImage = _img;
    } else if (_original != widget.original) {
      inpaintedImage = _original;
    }

    if (inpaintedImage != null) {
      MediaCollection mediaCollection = MediaCollection();
      await mediaCollection
          .populateFromFiles([inpaintedImage], MediaType.image);

      Navigator.pop(
          context,
          SelectedMedia(
              mediaCollection: mediaCollection,
              hiRes: true,
              album: false,
              streamable: false));
    }
  }

  fullScreen(File image) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenImageFile(
            file: image,
          ),
        ));
  }

  _history(BuildContext context) async {
    StableDiffusionPrompt? reusePrompt = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const PromptHistory(promptType: PromptType.inpaint),
        ));

    if (reusePrompt != null) {
      setState(() {
        List<SelectionWithTool>? points = widget.prompt.screenPoints;
        //screenPointsWithTool = widget.prompt.screenPoints;
        widget.prompt = reusePrompt;
        // widget.prompt.screenPoints = points;
        _promptController.text = widget.prompt.prompt;
        generateMask(context, points!);
      });
    }
  }

  _showConfigure() async {
    {
      _closeKeyboard();

      await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StableDiffusionInpaintingConfiguration(
                drawing: true,
                prompt: widget.prompt,
                freeGen: false,
                imageGenType: widget.imageGenType),
          ));

      _stableDiffusionConfigureCallback();
    }
  }

  _drawMask() async {
    _closeKeyboard();
    try {
      StableDiffusionPrompt? promptFetched = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MaskPreviewerStackPage(
                    _imageDetails,
                    widget.prompt,
                  )));

      if (promptFetched != null) {
        setState(() {
          widget.prompt = promptFetched;
          maskImage = widget.prompt.maskImage;
          PaintingBinding.instance.imageCache.clear();
          imageCache.clear();
        });
      }
    } catch (error, trace) {
      icProgressDialog.dismiss();
      LogBloc.insertError(error, trace);
      FormattedSnackBar.showSnackbarWithContext(
          context, error.toString(), "", 2, false);
    }
  }

  _generate() async {
    try {
      _closeKeyboard();

      icProgressDialog.show(
          context, AppLocalizations.of(context)!.inpaintingImage,
          barrierDismissable: true);

      ///check if user has enough coins
      if (globalState.ironCoinWallet.balance >= generateCost) {
        ///mask image is required
        if (widget.prompt.maskImage == null) {
          icProgressDialog.dismiss();
          FormattedSnackBar.showSnackbarWithContext(
              context, 'Please mark the area you want changed', '', 2, false);
          return;
        } else if (widget.prompt.prompt.isEmpty) {
          ///prompt is required
          icProgressDialog.dismiss();
          FormattedSnackBar.showSnackbarWithContext(
              context, 'Please enter prompt', '', 2, false);
          return;
        } else {
          ///charge includes creation of coinPayment and change of user's coin total
          globalState.ironCoinWallet.balance =
              globalState.ironCoinWallet.balance - generateCost;
          _ironCoinBloc.coinPaymentProcess(
              generateCost, CoinPaymentType.INPAINTING,
              prompt: widget.prompt);
        }
      } else {
        icProgressDialog.dismiss();
        FormattedSnackBar.showSnackbarWithContext(
            context, "Not enough IronCoin", "", 2, true);

        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const IronStoreIronCoin(),
            ));
      }
    } catch (error, trace) {
      icProgressDialog.dismiss();
      LogBloc.insertError(error, trace);
      FormattedSnackBar.showSnackbarWithContext(
          context, error.toString(), "", 2, false);
    }
  }

  generateMask(BuildContext context,
      List<SelectionWithTool> screenPointsWithTool) async {
    debugPrint("Regenerating mask...");
    final imageBytes1 = await MaskGenerator.generateMask(
        context, screenPointsWithTool, _imageDetails);

    String path =
        await ImageWriter.saveImageBytesToAppDirectory(imageBytes1, "mask.png");
    widget.prompt.screenPoints = screenPointsWithTool;

    setState(() {
      widget.prompt.maskImage = File(path);
      widget.prompt.generatedImage = null;
    });
  }
}
