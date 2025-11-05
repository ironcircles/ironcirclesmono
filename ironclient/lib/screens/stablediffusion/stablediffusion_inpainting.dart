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
import 'package:ironcirclesapp/screens/stablediffusion/prompthistory.dart';
import 'package:ironcirclesapp/screens/stablediffusion/stablediffusion_inpainting_configuration.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/gradientbuttonironcoin.dart';
import 'package:ironcirclesapp/screens/widgets/icprogressdialog.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:ndialog/ndialog.dart';

class StableDiffusionInpaintingWidget extends StatefulWidget {
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

  StableDiffusionInpaintingWidget({
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

class _LocalState extends State<StableDiffusionInpaintingWidget> {
  StableDiffusionAIBloc stableDiffusionAIBloc = StableDiffusionAIBloc();
  final _promptController = TextEditingController();
  final _maskPromptController = TextEditingController();

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
  bool _firstBuildComplete = false;
  int generateCost = 0;
  //bool _drawing = true;
  int _initialIndex = 0;
  double _reduce = 300;

  late ThumbnailDimensions _thumbnailDimensions;
  late ThumbnailDimensions thumbnailDimensions;

  late int _generateTab;

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

    thumbnailDimensions =
        ThumbnailDimensions.getDimensionsFromFile(_original, reduceSize: false);

    _thumbnailDimensions = ThumbnailDimensions(
        width: thumbnailDimensions.width, height: thumbnailDimensions.height);

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

    widget.prompt.width = getFixedSize(thumbnailDimensions.width);
    widget.prompt.height = getFixedSize(thumbnailDimensions.height);

    generateCost =
        globalState.stableDiffusionPricing.calculateCharge(widget.prompt);

    if (widget.initialPrompt.isNotEmpty) {
      _promptController.text = widget.initialPrompt;
      widget.prompt.prompt = widget.initialPrompt;
    }

    if (widget.prompt.maskPrompt.isNotEmpty) {
      _maskPromptController.text = widget.prompt.maskPrompt;
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

  // _genAfterFirstLoad(BuildContext context) {
  //   if (_firstBuildComplete == false) {
  //     _firstBuildComplete = true;
  //     _generate();
  //   }
  // }

  @override
  Widget build(BuildContext context) {
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

    final generateButton = Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GradientButtonIronCoin(
        cost: generateCost.toString(),
        balance: globalState.ironCoinWallet.balance,
        genImage: _genImage,
        onPressed: _generate,
        configure: _showConfigure,
      ),
    );

    final finalImageDescription = ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 125),
        child: Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 45,
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
                    .toLowerCase())));

    final image = Padding(
        padding: const EdgeInsets.only(top: 5, left: 0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          generateButton,
          widget.prompt.visualOnlySeed != -1
              ? Row(children: [
                  const Spacer(),
                  ICText(
                    "${AppLocalizations.of(context)!.seed}: ",
                    color: globalState.theme.labelText,
                  ),
                  SelectableText(
                    widget.prompt.visualOnlySeed.toString(),
                    textScaler: const TextScaler.linear(1),
                    style: TextStyle(color: globalState.theme.labelText),
                  ),
                ])
              : Container(),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            InkWell(
                splashColor: Colors.transparent,
                onTap: () {
                  fullScreen(_original);
                },
                child:  Container(
                    width: ScreenSizes.getMaxImageWidth(width) -
                        _reduce,
                    height: ScreenSizes.getMaxImageWidth(width) -
                        _reduce,
                    constraints: BoxConstraints(
                        maxHeight: ScreenSizes.getMaxImageWidth(width) -
                            _reduce,
                        maxWidth: ScreenSizes.getMaxImageWidth(width) -
                            _reduce),
                    child: widget.imageGenType == ImageType.image
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: InkWell(
                                child: Image.file(
                              _original,
                              // height: radius,
                              // width: radius,
                              fit: BoxFit.fitHeight,
                            )))
                        : ClipOval(
                            child: InkWell(
                                child: Image.file(
                            _original,
                            //height: radius,
                            // width: radius,
                            fit: BoxFit.fitHeight,
                          ))))),
            _img != null ? const Spacer() : Container(),
            _img != null
                ? InkWell(
                    splashColor: Colors.transparent,
                    onTap: () {
                      if (_img != null) fullScreen(_img!);
                    },
                    child:  Container(
                        width: ScreenSizes.getMaxImageWidth(width) -
                            _reduce,
                        height: ScreenSizes.getMaxImageWidth(width) -
                            _reduce,
                        constraints: BoxConstraints(
                            maxHeight: ScreenSizes.getMaxImageWidth(width) -
                                _reduce,
                            maxWidth: ScreenSizes.getMaxImageWidth(width) -
                                _reduce),
                        child:widget.imageGenType == ImageType.image
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: InkWell(
                                    child: _img != null
                                        ? Image.file(
                                            _img!,

                                            //width: wi,
                                            fit: BoxFit.fitHeight,
                                          )
                                        : Container()))
                            : ClipOval(
                                child: InkWell(
                                    child: _img != null
                                        ? Image.file(
                                            _img!,

                                            // width: radius,
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
                      "<- ${AppLocalizations.of(context)!.slideOver}",
                      color: globalState.theme.buttonGenerate,
                    ),
                    onPressed: () {
                      widget.original = _img!;
                      widget.prompt.generatedImage = null;
                      _original = _img!;
                      _img = null;
                      setState(() {});
                    },
                    //icon: const Icon(Icons.arrow_back)
                  )
                : Container(),
            const Spacer(),
          ]),
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


    final makeBody = Container(
        padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 5),
        child: Scrollbar(
            controller: _scrollController,
            //thumbVisibility: true,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              controller: _scrollController,
              child: WrapperWidget(
                child: Column(children: <Widget>[
                const SizedBox(height: 5),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                                    widget.prompt.maskPrompt = value;
                                  },
                                  maxLines: 3,
                                  maxLength: 1000,
                                  controller: _maskPromptController,
                                  labelText: AppLocalizations.of(context)!
                                      .describeObjectToChange)))),
                  IconButton(
                    onPressed: () {
                      _history();
                    },
                    icon: Icon(
                      Icons.history,
                      color: globalState.theme.buttonGenerate,
                    ),
                  )
                ]),
                finalImageDescription,
                image,
                  widget.original.path != widget.base.path || _img != null
                      ? makeBottom
                      : Container(),
              ]),
            ))));

    return SafeArea(
      left: false,
      top: false,
      right: false,
      bottom: true,
      child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: globalState.theme.background,
          body: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    const Padding(padding: EdgeInsets.only(bottom: 0)), //5
                    Expanded(
                      child: makeBody,
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

      _img = await stableDiffusionAIBloc.inpaintWithText(widget.prompt);
      widget.prompt.generatedImage = _img!;
      //_genImage = await _imagineAIBloc.generateImage(params);

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
      _maskPromptController.text = widget.prompt.maskPrompt;
    });
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

  // _promptIronCoin() {
  //   DialogYesNo.askYesNo(
  //     context,
  //     "Not enough IronCoin",
  //     "Would you like to buy more?",
  //     _buyIronCoin,
  //     null,
  //     false,
  //   );
  // }
  //
  // _buyIronCoin() {
  //   Navigator.of(context).push(MaterialPageRoute(
  //       builder: (context) => Settings(
  //             tab: 1,
  //           )));
  // }

  _history() async {
    StableDiffusionPrompt? reusePrompt = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const PromptHistory(promptType: PromptType.inpaint),
        ));

    if (reusePrompt != null) {
      setState(() {
        widget.prompt = reusePrompt;
        _promptController.text = widget.prompt.prompt;
        _maskPromptController.text = widget.prompt.maskPrompt;
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
                drawing: false,
                prompt: widget.prompt,
                freeGen: false,
                imageGenType: widget.imageGenType),
          ));

      _stableDiffusionConfigureCallback();
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
        ///prompt is required
        if (widget.prompt.prompt.isEmpty || widget.prompt.maskPrompt.isEmpty) {
          icProgressDialog.dismiss();
          FormattedSnackBar.showSnackbarWithContext(
              context, 'Please enter both prompts', '', 2, false);
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
}
