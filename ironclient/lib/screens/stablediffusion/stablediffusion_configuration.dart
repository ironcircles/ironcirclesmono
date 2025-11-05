import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/stablediffusionai_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/stablediffusionprompt.dart';
import 'package:ironcirclesapp/screens/stablediffusion/stablediffusion_help.dart';
import 'package:ironcirclesapp/screens/stablediffusion/stablediffusion_models.dart';
import 'package:ironcirclesapp/screens/widgets/formatteddropdownobject.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';

class StableDiffusionConfiguration extends StatefulWidget {
  StableDiffusionPrompt prompt;
  final bool freeGen;
  final ImageType imageGenType;
  final Function? refreshPrompt;

  StableDiffusionConfiguration({
    Key? key,
    required this.prompt,
    required this.freeGen,
    required this.imageGenType,
    this.refreshPrompt,
  }) : super(key: key);

  @override
  _LocalState createState() {
    return _LocalState();
  }
}

class _LocalState extends State<StableDiffusionConfiguration> {
  // final StableDiffusionPrompt widget.prompt =
  //     StableDiffusionPrompt(promptType: PromptType.generate);
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _negativePromptController =
      TextEditingController();
  final TextEditingController _stepsController = TextEditingController();
  final TextEditingController _seedController = TextEditingController();
  final TextEditingController _LoRAController = TextEditingController();
  final TextEditingController _LoRA2Controller = TextEditingController();
  double _currentSliderValue = 4;
  final ScrollController _scrollController = ScrollController();
  double _currentStepsSliderValue = 30;
  // double _resolution = 4;

  List<int> dimensions = [320, 512, 768, 1024];
  List<double> fractions = [0, (4 / 3), (8 / 3), 4];
  late double _width;
  late double _height;

  late ListItem? _selectedModel;
  late ListItem? _sampler;
  double _currentGuidanceSliderValue = 7;
  bool _upscale = false;

  @override
  void initState() {
    _initScreenWidgets();

    super.initState();
  }

  _initScreenWidgets() {
    //widget.prompt.deepCopy(widget.prompt);

    _selectedModel =
        models.singleWhere((element) => element.object == widget.prompt.model);
    _sampler = samplers
        .singleWhere((element) => element.object == widget.prompt.sampler);

    // _resolution = widget.prompt.resolution;
    _currentSliderValue = 4;
    _currentStepsSliderValue = widget.prompt.steps.toDouble();
    _promptController.text = widget.prompt.prompt;
    _negativePromptController.text = widget.prompt.negativePrompt;
    _seedController.text =
        widget.prompt.seed == -1 ? "" : widget.prompt.seed.toString();
    _currentGuidanceSliderValue = widget.prompt.guidance;
    _upscale = widget.prompt.upscale == 2 ? true : false;
    _LoRAController.text = widget.prompt.loraOne;
    _LoRA2Controller.text = widget.prompt.loraTwo;
    _stepsController.text = widget.prompt.steps.toString();
    _height = fractions[dimensions.indexOf(widget.prompt.height)];
    _width = fractions[dimensions.indexOf(widget.prompt.width)];
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double radius = MediaQuery.of(context).size.width - 10;

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
                    const Padding(padding: EdgeInsets.only(top: 10)),
                    ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 125),
                        child: Padding(
                            padding: const EdgeInsets.only(
                              left: 10,
                              right: 10,
                            ),
                            child: ExpandingLineText(
                                onChanged: (value) {
                                  widget.prompt.prompt = value;
                                },
                                maxLines: 3,
                                maxLength: 1000,
                                controller: _promptController,
                                labelText: AppLocalizations.of(context)!
                                    .enterYourPromptRequired))), //"enter your prompt (required)"))),
                    ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 125),
                        child: Padding(
                            padding: const EdgeInsets.only(
                              left: 10,
                              right: 10,
                              top: 8,
                            ),
                            child: ExpandingLineText(
                                onChanged: (value) {
                                  widget.prompt.negativePrompt = value;
                                },
                                maxLines: 3,
                                maxLength: 1000,
                                controller: _negativePromptController,
                                labelText: AppLocalizations.of(context)!
                                    .negativePromptOptional))), //"negative prompt (optional)"))),
                    // Row(children: <Widget>[
                    //   Expanded(
                    //       flex: 1,
                    //       child: Padding(
                    //           padding: const EdgeInsets.only(
                    //               left: 10, right: 10, bottom: 0, top: 10),
                    //           child: FormattedDropdownObject(
                    //             hintText: 'model',
                    //             selected: _selectedModel,
                    //             list: models,
                    //             // selected: _selectedOne,
                    //             underline: globalState.theme.bottomHighlightIcon,
                    //             onChanged: (ListItem? value) {
                    //               setState(() {
                    //                 _selectedModel = value;
                    //                 widget.prompt.model = value!.name!;
                    //               });
                    //             },
                    //           ))),
                    // ]),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                              child: Padding(
                                  padding: const EdgeInsets.only(
                                      top: 15, bottom: 0, right: 10, left: 10),
                                  child: ICText(
                                    '${AppLocalizations.of(context)!.selectAModel}:',
                                    color: globalState.theme.labelText,
                                  )))
                        ]),
                    Padding(
                        padding: const EdgeInsets.only(
                            top: 2, bottom: 0, right: 10, left: 10),
                        child: InkWell(
                            onTap: () {
                              _selectModel();
                            },
                            child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Expanded(
                                      child: Container(
                                          decoration: BoxDecoration(
                                              color: globalState
                                                  .theme.menuBackground,
                                              border: Border.all(
                                                  color: Colors.lightBlueAccent
                                                      .withOpacity(.1),
                                                  width: 2.0),
                                              borderRadius:
                                                  const BorderRadius.only(
                                                topLeft: Radius.circular(12.0),
                                                topRight: Radius.circular(12.0),
                                                bottomLeft:
                                                    Radius.circular(12.0),
                                                bottomRight:
                                                    Radius.circular(12.0),
                                              )),
                                          padding: const EdgeInsets.only(
                                              top: 5,
                                              bottom: 5,
                                              left: 10,
                                              right: 10),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              SizedBox(
                                                  height: 50,
                                                  width: 50,
                                                  child: Image.asset(
                                                      '${'assets/images/models/${widget.prompt.model}'}.webp')),
                                              const Padding(
                                                  padding: EdgeInsets.only(
                                                left: 10,
                                              )),
                                              Expanded(
                                                  child: Text(
                                                      models[models.indexWhere(
                                                              (element) =>
                                                                  element
                                                                      .object ==
                                                                  widget.prompt
                                                                      .model)]
                                                          .name!,
                                                      textScaler:
                                                          const TextScaler
                                                              .linear(1.0),
                                                      style: TextStyle(
                                                        fontSize: 16 -
                                                            globalState
                                                                .scaleDownTextFont,
                                                        color: globalState
                                                            .theme.labelText,
                                                      ))),
                                              //const Spacer(),
                                              Icon(Icons.keyboard_arrow_right,
                                                  color: globalState
                                                      .theme.labelText,
                                                  size: 25.0),
                                            ],
                                          ))),
                                ]))),
                    const SizedBox(height: 15),
                    const Padding(
                        padding: EdgeInsets.only(
                      top: 10,
                    )),
                    widget.imageGenType == ImageType.image
                        ? Padding(
                            padding: const EdgeInsets.only(left: 0),
                            child: ICText(
                                '${AppLocalizations.of(context)!.shape}: ${widget.prompt.resolutionString(context)}'))
                        : Container(),
                    widget.imageGenType == ImageType.image
                        ? const SizedBox(height: 15)
                        : Container(),
                    widget.imageGenType == ImageType.image
                        ? Padding(
                            padding: const EdgeInsets.only(left: 0),
                            child: ICText(
                                '${AppLocalizations.of(context)!.width}: ${widget.prompt.width.toString()}'))
                        : Container(),
                    widget.imageGenType == ImageType.image
                        ? Slider(
                            activeColor: globalState.theme.button,
                            value: _width,
                            max: 4,
                            min: 0,
                            divisions: 3,
                            onChanged: (double value) {
                              setState(() {
                                _width = value;
                              });
                            },
                            onChangeEnd: (double value) {
                              setState(() {
                                int index = fractions.indexOf(value);
                                widget.prompt.width = dimensions[index];
                              });
                            },
                          )
                        : Container(),
                    widget.imageGenType == ImageType.image
                        ? Padding(
                            padding: const EdgeInsets.only(top: 15),
                            child: ICText(
                                '${AppLocalizations.of(context)!.height}: ${widget.prompt.height.toString()}'))
                        : Container(),
                    widget.imageGenType == ImageType.image
                        ? Slider(
                            activeColor: globalState.theme.button,
                            value: _height,
                            max: 4,
                            min: 0,
                            divisions: 3,
                            onChanged: (double value) {
                              setState(() {
                                _height = value;
                              });
                            },
                            onChangeEnd: (double value) {
                              setState(() {
                                int index = fractions.indexOf(value);
                                widget.prompt.height = dimensions[index];
                              });
                            },
                          )
                        : Container(),
                    const SizedBox(height: 15),
                    Padding(
                        padding: const EdgeInsets.only(left: 0),
                        child: ICText(
                            '${AppLocalizations.of(context)!.variance} ${widget.prompt.guidance.round().toString()}')),
                    Slider(
                      activeColor: globalState.theme.button,
                      value: _currentGuidanceSliderValue,
                      max: 20,
                      min: -20,
                      divisions: 40,
                      label: _currentGuidanceSliderValue.round().toString(),
                      onChanged: (double value) {
                        setState(() {
                          _currentGuidanceSliderValue = value;
                        });
                      },
                      onChangeEnd: (double value) {
                        setState(() {
                          widget.prompt.guidance = value;
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    widget.freeGen
                        ? Container()
                        : Row(children: [
                            const Spacer(),
                            ICText(
                                "${AppLocalizations.of(context)!.steps}: ${widget.prompt.steps}"),
                            const Spacer(),
                          ]),

                    widget.freeGen
                        ? Container()
                        : Slider(
                            activeColor: globalState.theme.button,
                            value: _currentStepsSliderValue,
                            max: 150,
                            min: 10,
                            divisions: 40,
                            label: _currentStepsSliderValue.round().toString(),
                            onChanged: (double value) {
                              setState(() {
                                _currentStepsSliderValue = value;
                                widget.prompt.steps = value.toInt();
                              });
                            },
                            onChangeEnd: (double value) {
                              setState(() {
                                widget.prompt.steps = value.toInt();
                              });
                            },
                          ),
                    // : Row(children: [
                    //     const Spacer(),
                    //     IconButton(
                    //         icon: const Icon(Icons.remove),
                    //         onPressed: () {
                    //           widget.prompt.steps = widget.prompt.steps - 1;
                    //
                    //           if (widget.prompt.steps < 10) {
                    //             widget.prompt.steps = 10;
                    //           }
                    //
                    //           _stepsController.text =
                    //               widget.prompt.steps.toString();
                    //
                    //           setState(() {});
                    //         }),
                    //     Expanded(
                    //         child: ExpandingLineText(
                    //             counterText: '',
                    //             onChanged: (value) {
                    //               if (value.toString().isNotEmpty) {
                    //                 int? steps = int.tryParse(value);
                    //                 if (steps != null) {
                    //                   if (steps < 10) {
                    //                     widget.prompt.steps = 10;
                    //                   } else if (steps > 150) {
                    //                     widget.prompt.steps = 150;
                    //                   } else {
                    //                     widget.prompt.steps = steps;
                    //                   }
                    //                 }
                    //               }
                    //             },
                    //             numbersOnly: true,
                    //             maxLength: 3,
                    //             controller: _stepsController,
                    //             labelText: "")),
                    //     IconButton(
                    //         icon: const Icon(Icons.add),
                    //         onPressed: () {
                    //           widget.prompt.steps = widget.prompt.steps + 1;
                    //
                    //           if (widget.prompt.steps > 150) {
                    //             widget.prompt.steps = 150;
                    //           }
                    //
                    //           setState(() {
                    //             _stepsController.text =
                    //                 widget.prompt.steps.toString();
                    //           });
                    //         }),
                    //     const Spacer(),
                    //   ]),
                    widget.freeGen ? Container() : const SizedBox(height: 15),
                    widget.freeGen
                        ? Container()
                        : SwitchListTile(
                            inactiveThumbColor:
                                globalState.theme.inactiveThumbColor,
                            inactiveTrackColor:
                                globalState.theme.inactiveTrackColor,
                            trackOutlineColor:
                                MaterialStateProperty.resolveWith(
                                    globalState.getSwitchColor),
                            title: ICText(
                              AppLocalizations.of(context)!
                                  .upscaleImage, //'Upscale image',
                              textScaleFactor: globalState.labelScaleFactor,
                              fontSize: 16 - globalState.scaleDownTextFont,
                            ),
                            activeColor: globalState.theme.button,
                            value: _upscale,
                            onChanged: (bool value) {
                              setState(() {
                                _upscale = value;
                                widget.prompt.upscale = value == true ? 2 : 1;
                              });
                            },
                          ),
                    const SizedBox(height: 15),
                    Row(children: <Widget>[
                      Expanded(
                          flex: 1,
                          child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 10, right: 10, bottom: 0),
                              child: FormattedDropdownObject(
                                hintText: AppLocalizations.of(context)!.sampler,
                                selected: _sampler,
                                list: samplers,
                                // selected: _selectedOne,
                                underline:
                                    globalState.theme.bottomHighlightIcon,
                                onChanged: (ListItem? value) {
                                  setState(() {
                                    _sampler = value;
                                    widget.prompt.sampler = value!.name!;
                                  });
                                },
                              ))),
                    ]),
                    const SizedBox(height: 15),
                    Padding(
                        padding: const EdgeInsets.only(
                          left: 10,
                          right: 10,
                        ),
                        child: ExpandingLineText(
                            onChanged: (value) {
                              int? seed = int.tryParse(value);
                              if (seed != null) {
                                widget.prompt.seed = seed;
                              }
                            },
                            numbersOnly: true,
                            maxLength: 10,
                            controller: _seedController,
                            labelText:
                                AppLocalizations.of(context)!.seedOptional)),
                    widget.freeGen ? Container() : const SizedBox(height: 15),
                    widget.freeGen
                        ? Container()
                        : Padding(
                            padding: const EdgeInsets.only(
                              left: 10,
                              right: 10,
                            ),
                            child: ExpandingLineText(
                                counterText: '',
                                onChanged: (value) {
                                  widget.prompt.loraOne = value;
                                },
                                maxLines: 3,
                                maxLength: 1000,
                                controller: _LoRAController,
                                labelText:
                                    "LoRA hash (${AppLocalizations.of(context)!.optional})")),
                    widget.freeGen ? Container() : const SizedBox(height: 15),
                    widget.freeGen
                        ? Container()
                        : Padding(
                            padding: const EdgeInsets.only(
                              left: 10,
                              right: 10,
                            ),
                            child: ExpandingLineText(
                                counterText: '',
                                onChanged: (value) {
                                  widget.prompt.loraTwo = value;
                                },
                                maxLines: 3,
                                maxLength: 1000,
                                controller: _LoRA2Controller,
                                labelText:
                                    "LoRA 2 hash (${AppLocalizations.of(context)!.optional})")),

                    const Padding(padding: EdgeInsets.only(top: 10)),

                    widget.freeGen && widget.refreshPrompt != null
                        ? Container()
                        : GradientButtonDynamic(
                            text: "RESET", onPressed: _resetConfiguration),
                  ]),
                ))));

    return SafeArea(
      left: false,
      top: false,
      right: false,
      bottom: true,
      child: Scaffold(
          //key: _scaffoldKey,
          backgroundColor: globalState.theme.background,
          appBar: ICAppBar(
            title: AppLocalizations.of(context)!.configureImageGeneration,
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
                              prompt: widget.prompt,
                              promptType: PromptType.generate),
                        ));

                    _refreshScreen();
                  }),
            ],
          ),
          body: Stack(
            children: [
              Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      const Padding(padding: EdgeInsets.only(bottom: 5)),
                      Expanded(
                        child: makeBody,
                      ),
                    ],
                  )),
            ],
          )),
    );
  }

  _closeKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  _resetConfiguration() {
    widget.prompt = StableDiffusionPrompt(promptType: PromptType.generate);
    widget.refreshPrompt!(widget.prompt);
    _refreshScreen();
  }

  _refreshScreen() {
    _initScreenWidgets();
    setState(() {});
  }

  _selectModel() async {
    await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StableDiffusionModels(
            promptType: PromptType.generate,
            prompt: widget.prompt,
          ),
        ));

    _refreshScreen();
  }
}
