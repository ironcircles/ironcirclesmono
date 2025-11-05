import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
import 'package:ironcirclesapp/blocs/database_bloc.dart';
import 'package:ironcirclesapp/blocs/ironcoin_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/stablediffusionai_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/stablediffusionprompt.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/imagepreviewer.dart';
import 'package:ironcirclesapp/screens/payment/ironstore_ironcoin.dart';
import 'package:ironcirclesapp/screens/stablediffusion/prompthistory.dart';
import 'package:ironcirclesapp/screens/stablediffusion/stablediffusion_configuration.dart';
import 'package:ironcirclesapp/screens/stablediffusion/stablediffusion_help.dart';
import 'package:ironcirclesapp/screens/themes/mastertheme.dart';
import 'package:ironcirclesapp/screens/widgets/gradientbuttonironcoin.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/icprogressdialog.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:ndialog/ndialog.dart';

class StableDiffusionWidget extends StatefulWidget {
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
  final Function? setScheduled;

  const StableDiffusionWidget(
      {Key? key,
      required this.userFurnace,
      required this.imageGenType,
      this.previewScreenName = '',
      this.timer = 0,
      this.setTimer,
      this.initialPrompt = "",
      this.setScheduled,
      this.wall = false,
      this.userFurnaces = const [],
      this.redo,
      this.setNetworks})
      : super(key: key);

  @override
  _StableDiffusionWidgetState createState() {
    return _StableDiffusionWidgetState();
  }
}

class _StableDiffusionWidgetState extends State<StableDiffusionWidget> {
  StableDiffusionPrompt prompt =
      StableDiffusionPrompt(promptType: PromptType.generate);
  StableDiffusionAIBloc stableDiffusionAIBloc = StableDiffusionAIBloc();
  final _promptController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final databaseBloc = DatabaseBloc();
  ProgressDialog? importingData;
  String assigned = '';
  bool validatedOnceAlready = false;
  File? _img;
  //double radius = 250 - (globalState.scaleDownTextFont * 2);
  bool _genImage = false;
  ICProgressDialog icProgressDialog = ICProgressDialog();
  final IronCoinBloc _ironCoinBloc = IronCoinBloc();

  int generateCost = 0;
  double temporaryCost = 0;
  List<int> imageDimensions = [320, 512, 768, 1024];

  bool _firstBuildComplete = false;

  NumberFormat formatter = NumberFormat.decimalPatternDigits(
    locale: 'en_us',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();

    debugPrint("index = ${prompt.promptType.index}");

    generateCost = globalState.stableDiffusionPricing.calculateCharge(prompt);

    if (widget.initialPrompt.isNotEmpty) {
      // WidgetsBinding.instance
      //     .addPostFrameCallback((_) => _genAfterFirstLoad(context));

      _promptController.text = widget.initialPrompt;
      prompt.prompt = widget.initialPrompt;
    }

    _ironCoinBloc.recentCoinRefund.listen((payment) {
      globalState.ironCoinWallet.balance += payment.amount;

      setState(() {});
    }, onError: (err) {
      debugPrint("recentCoinRefund.listen: $err");
    }, cancelOnError: false);

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
          context, err.toString(), "", 2, false);
    });
    prompt.negativePrompt =
        "ugly, tiling, poorly drawn hands, poorly drawn feet, poorly drawn face, out of frame, extra limbs, disfigured, deformed, body out of frame, blurry, bad anatomy, blurred, watermark, grainy, signature, cut off, draft";
  }

  // _genAfterFirstLoad(BuildContext context) {
  //   if (_firstBuildComplete == false) {
  //     _firstBuildComplete = true;
  //     _generate();
  //   }
  // }

  bool _justGenned = true;
  double width = 512;
  double height = 512;

  @override
  Widget build(BuildContext context) {
    //double radius = MediaQuery.of(context).size.width - 10;

    if (_justGenned) {
      _justGenned = false;
      double availableWidth = MediaQuery.of(context).size.width - 10;
      width = availableWidth;
      height = availableWidth;

      if (_img != null) {
        if (prompt.width <= availableWidth) {
          ///scale up
          double ratio = availableWidth / prompt.width;

          width = availableWidth;

          height = (prompt.height * ratio).toDouble();
        } else if (prompt.width >= availableWidth) {
          ///scale down
          double ratio = prompt.width / availableWidth;

          width = availableWidth;

          height = (prompt.height / ratio).toDouble();
        }
      }
    }

    final image = Padding(
        padding: const EdgeInsets.only(top: 5, left: 0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              GradientButtonIronCoin(
                  cost: generateCost.toString(),
                  balance: globalState.ironCoinWallet.balance,
                  genImage: _genImage,
                  onPressed: _generate,
                  configure: _showConfigure),
              const Padding(
                padding: EdgeInsets.only(
                  bottom: 10,
                ),
              ),
              prompt.visualOnlySeed != -1
                  ? Row(
                      children: [
                        const Spacer(),
                        ICText(
                          "${AppLocalizations.of(context)!.seed}: ",
                          color: globalState.theme.labelText,
                        ),
                        SelectableText(
                          prompt.visualOnlySeed.toString(),
                          textScaler: const TextScaler.linear(1.0),
                          style: TextStyle(color: globalState.theme.labelText),
                        ),
                        const Spacer()
                      ],
                    )
                  : Container(),
              InkWell(
                  onTap: () async {
                    _next();
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
                              splashColor: Colors.transparent,
                              child: _img != null
                                  ? Image.file(
                                      _img!,
                                      // height: radius,
                                      // width: radius,
                                      fit: BoxFit.cover,
                                    )
                                  : Opacity(
                                      opacity: .1,
                                      child: Image.asset(
                                        globalState.theme.themeMode ==
                                                ICThemeMode.dark
                                            ? 'assets/images/noimage-light.png'
                                            : 'assets/images/noimage.png',
                                        // height: radius,
                                        // width: radius,
                                        fit: BoxFit.cover,
                                      )),
                              // Container(
                              //     width: radius,
                              //     color:
                              //         globalState.theme.overlay),
                            ))
                        : widget.imageGenType == ImageType.circle
                            ? ClipOval(
                                child: InkWell(
                                    splashColor: Colors.transparent,
                                    child: _img != null
                                        ? Image.file(
                                            _img!,
                                            // height: radius,
                                            // width: radius,
                                            fit: BoxFit.fitWidth,
                                          )
                                        : Stack(children: <Widget>[
                                            ClipOval(
                                                child: Image.asset(
                                              'assets/images/iron.jpg',
                                              width: width,
                                              height: height,
                                              fit: BoxFit.fitWidth,
                                            )),
                                            Container(
                                              width: width,
                                              height: height,
                                              color: globalState.theme.overlay,
                                            ),
                                          ])))
                            : widget.imageGenType == ImageType.avatar
                                ? ClipOval(
                                    child: InkWell(
                                        splashColor: Colors.transparent,
                                        child: _img != null
                                            ? Image.file(
                                                _img!,
                                                width: width,
                                                height: height,
                                                fit: BoxFit.fitWidth,
                                              )
                                            : Stack(children: <Widget>[
                                                Image.asset(
                                                  'assets/images/avatar.jpg',
                                                  width: width,
                                                  height: height,
                                                  fit: BoxFit.fitWidth,
                                                ),
                                                Container(
                                                  width: width,
                                                  height: height,
                                                  color:
                                                      globalState.theme.overlay,
                                                ),
                                              ])))
                                : ClipOval(
                                    child: InkWell(
                                        splashColor: Colors.transparent,
                                        child: _img != null
                                            ? Image.file(
                                                _img!,
                                                // width: width,
                                                // height: height,
                                                fit: BoxFit.cover,
                                              )
                                            : Stack(children: <Widget>[
                                                Image.asset(
                                                  'assets/images/ios_icon.png',
                                                  // width: width,
                                                  // height: height,
                                                  fit: BoxFit.fitWidth,
                                                ),
                                                Container(
                                                  width: width,
                                                  height: height,
                                                  color:
                                                      globalState.theme.overlay,
                                                ),
                                              ]))),
                  )),
            ]));

    final makeBottom = Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 0),
        child: Row(children: <Widget>[
          Expanded(
              child: GradientButton(
            text: AppLocalizations.of(context)!.next,
            onPressed: _next,
          )),
        ]));

    final makeBody = Container(
        padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 5),
        child: Scrollbar(
            controller: _scrollController,
            //thumbVisibility: true,
            child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                controller: _scrollController,
                child: WrapperWidget(
                  child: Column(children: <Widget>[
                    const SizedBox(height: 5),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxHeight: 125),
                                  child: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 20,
                                        right: 0,
                                      ),
                                      child: ExpandingLineText(
                                          onChanged: (String value) {
                                            prompt.prompt = value;
                                          },
                                          maxLines: 3,
                                          maxLength: 1000,
                                          controller: _promptController,
                                          labelText:
                                              AppLocalizations.of(context)!
                                                  .enterYourPromptRequired)))),
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
                    image,
                    _img != null && globalState.isDesktop() == true
                        ? Row(children: [const Spacer(), SizedBox(
                            width: ScreenSizes.getMaxButtonWidth(width, false),
                            child: makeBottom)])
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
        appBar: ICAppBar(
          title:
              '${AppLocalizations.of(context)!.generate} ${widget.imageGenType == ImageType.avatar ? AppLocalizations.of(context)!.avatar : widget.imageGenType == ImageType.network ? AppLocalizations.of(context)!.networkImage : widget.imageGenType == ImageType.circle ? AppLocalizations.of(context)!.background : AppLocalizations.of(context)!.imageWord}',
          actions: [
            IconButton(
                //padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.help, color: globalState.theme.menuIcons),
                onPressed: () async {
                  ///open the help screen
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StableDiffusionHelp(
                            prompt: prompt, promptType: PromptType.generate),
                      ));

                  refreshScreen();
                }),
          ],
        ),
        body: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                const Padding(padding: EdgeInsets.only(bottom: 5)),
                Expanded(
                  child: makeBody,
                ),
                /*new Container(
                    padding: EdgeInsets.all(0.0),
                    child: makeBottom,
                  ),

                   */
                _img != null && globalState.isDesktop() == false
                    ? makeBottom
                    : Container(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _generate() async {
    try {
      _closeKeyboard();

      debugPrint("generate index = ${prompt.promptType.index}");

      icProgressDialog.show(
          context, AppLocalizations.of(context)!.generatingImage,
          barrierDismissable: true);

      ///check if user has enough coins
      if (globalState.ironCoinWallet.balance >= generateCost) {
        ///prompt is required
        if (prompt.prompt.isEmpty) {
          icProgressDialog.dismiss();
          FormattedSnackBar.showSnackbarWithContext(
              context, 'Please enter a prompt', '', 2, false);
          return;
        } else {
          ///charge includes creation of coinPayment and change of user's coin total
          globalState.ironCoinWallet.balance =
              globalState.ironCoinWallet.balance - generateCost;
          _ironCoinBloc.coinPaymentProcess(
              generateCost, CoinPaymentType.IMAGE_GENERATION,
              prompt: prompt);
        }
      } else {
        icProgressDialog.dismiss();
        FormattedSnackBar.showSnackbarWithContext(
            context, "Not enough IronCoin", "", 3, false);

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

  _imageGeneration() async {
    try {
      _genImage = true;
      _justGenned = true;
      _img = await stableDiffusionAIBloc.generateImage(
          imageGeneratorParams: prompt, registering: false);
      //_genImage = await _imagineAIBloc.generateImage(params);

      icProgressDialog.dismiss();
    } catch (error, trace) {
      _ironCoinBloc.coinPaymentRefund(
          generateCost, CoinPaymentType.REFUND_IRONCOIN);
      icProgressDialog.dismiss();
      LogBloc.insertError(error, trace);
      FormattedSnackBar.showSnackbarWithContext(
          context, error.toString(), "", 2, false);
    }
  }

  _closeKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  refreshScreen() {
    setState(() {
      generateCost = globalState.stableDiffusionPricing.calculateCharge(prompt);

      _promptController.text = prompt.prompt;
    });
  }

  _doNothing() {}

  _next() async {
    _closeKeyboard();
    //Navigator.pop(context, _img);

    if (_img != null) {
      MediaCollection mediaCollection = MediaCollection();
      await mediaCollection.populateFromFiles([_img!], MediaType.image);

      SelectedMedia? selectedImages = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImagePreviewer(
              hiRes: false,
              streamable: false,
              timer: widget.timer,
              setScheduled: widget.setScheduled ?? _doNothing,
              setTimer: widget.setTimer,
              imageType: widget.imageGenType,
              media: mediaCollection,
              screenName: widget.previewScreenName,
              wall: widget.wall,
              userFurnaces:
                  widget.wall ? widget.userFurnaces : [widget.userFurnace],
              //selectedNetworks: _selectedNetworks,
              setNetworks: widget.setNetworks,
            ),
          ));

      if (selectedImages != null &&
          selectedImages.mediaCollection.media.isNotEmpty) {
        Navigator.pop(context, selectedImages);
      }
    }
  }

  _history() async {
    StableDiffusionPrompt? reusePrompt = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const PromptHistory(promptType: PromptType.generate),
        ));

    if (reusePrompt != null) {
      setState(() {
        prompt = reusePrompt;

        if (widget.imageGenType != ImageType.image) {
          prompt.width = 512;
          prompt.height = 512;
        }

        _promptController.text = prompt.prompt;
      });
    }
  }

  _refreshPrompt(StableDiffusionPrompt newPrompt) {
    setState(() {
      prompt = newPrompt;
    });
    refreshScreen;
  }

  _showConfigure() async {
    _closeKeyboard();

    await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StableDiffusionConfiguration(
              prompt: prompt,
              freeGen: false,
              imageGenType: widget.imageGenType,
              refreshPrompt: _refreshPrompt),
        ));

    refreshScreen();
  }
}
