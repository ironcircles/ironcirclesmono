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

class StableDiffusionInpaintingConfiguration extends StatefulWidget {
  final StableDiffusionPrompt prompt;
  final bool freeGen;
  final ImageType imageGenType;
  final bool drawing;

  const StableDiffusionInpaintingConfiguration({
    Key? key,
    required this.drawing,
    required this.prompt,
    required this.freeGen,
    required this.imageGenType,
  }) : super(key: key);

  @override
  _LocalState createState() {
    return _LocalState();
  }
}

class _LocalState extends State<StableDiffusionInpaintingConfiguration> {
  // final StableDiffusionPrompt widget.prompt =
  //     StableDiffusionPrompt(promptType: PromptType.generate);
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _maskController = TextEditingController();
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
    _selectedModel = inpaintingModels
        .singleWhere((element) => element.object == widget.prompt.model);
    _sampler = samplers
        .singleWhere((element) => element.object == widget.prompt.sampler);
    _promptController.text = widget.prompt.prompt;
    _maskController.text = widget.prompt.maskPrompt;
    _negativePromptController.text = widget.prompt.negativePrompt;
    _seedController.text =
        widget.prompt.seed < 1 ? "" : widget.prompt.seed.toString();
    _currentGuidanceSliderValue = widget.prompt.guidance;
    _upscale = widget.prompt.upscale == 2 ? true : false;
    _stepsController.text = widget.prompt.steps.toString();
    _currentStepsSliderValue = widget.prompt.steps.toDouble();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double radius = MediaQuery.of(context).size.width - 10;

    // final makeBottom = Padding(
    //     padding: const EdgeInsets.only(top: 0, bottom: 0),
    //     child: Row(children: <Widget>[
    //       Expanded(
    //           child: GradientButton(
    //         text:AppLocalizations.of(context)!.next,
    //         onPressed: _next,
    //       )),
    //     ]));

    final makeBody = Container(
        padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 5),
        child: Scrollbar(
            controller: _scrollController,
            //thumbVisibility: true,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              controller: _scrollController,
              child: WrapperWidget(child:Column(children: <Widget>[
                const Padding(padding: EdgeInsets.only(top: 10)),
                widget.drawing == true
                  ? Container()
                  : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 125),
                    child: Padding(
                        padding: const EdgeInsets.only(
                          left: 10,
                          right: 10,
                        ),
                        child: ExpandingLineText(
                            onChanged: (value) {
                              widget.prompt.maskPrompt = value;
                            },
                            maxLines: 3,
                            maxLength: 1000,
                            controller: _maskController,
                            labelText: AppLocalizations.of(context)!.describeObjectToChange))),
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
                            labelText: AppLocalizations.of(context)!.describeFinalImage.toLowerCase()))),
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
                            labelText: AppLocalizations.of(context)!.negativePromptOptional))),
                Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                          child: Padding(
                              padding: const EdgeInsets.only(
                                  top: 15, bottom: 0, right: 10, left: 10),
                              child: ICText(
                                "${AppLocalizations.of(context)!.selectAModel}:",
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
                      child: Container(
                          // alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                              color: globalState.theme.menuBackground,
                              border: Border.all(
                                  color: Colors.lightBlueAccent.withOpacity(.1),
                                  width: 2.0),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12.0),
                                topRight: Radius.circular(12.0),
                                bottomLeft: Radius.circular(12.0),
                                bottomRight: Radius.circular(12.0),
                              )),
                          padding: const EdgeInsets.only(
                              top: 5, bottom: 5, left: 10, right: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
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
                                      inpaintingModels[inpaintingModels
                                              .indexWhere((element) =>
                                                  element.object ==
                                                  widget.prompt.model)]
                                          .name!,
                                      textAlign: TextAlign.left,
                                      //softWrap: true,
                                      //textWidthBasis: TextWidthBasis.parent,
                                      textScaler: const TextScaler.linear(1.0),
                                      style: TextStyle(
                                        fontSize:
                                            16 - globalState.scaleDownTextFont,
                                        color: globalState.theme.labelText,
                                      ))),
                              //const Spacer(),
                              Icon(Icons.keyboard_arrow_right,
                                  color: globalState.theme.labelText,
                                  size: 25.0),
                            ],
                          )),
                    )),
                widget.imageGenType == ImageType.image
                    ? const SizedBox(height: 15)
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
                    : widget.freeGen
                        ? Container()
                        : Row(children: [
                            const Spacer(),
                            ICText("${AppLocalizations.of(context)!.steps}: ${widget.prompt.steps}"),
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
                widget.freeGen ? Container() : const SizedBox(height: 15),
                widget.freeGen
                    ? Container()
                    : SwitchListTile(
                        inactiveThumbColor:
                            globalState.theme.inactiveThumbColor,
                        inactiveTrackColor:
                            globalState.theme.inactiveTrackColor,
                        trackOutlineColor: MaterialStateProperty.resolveWith(
                            globalState.getSwitchColor),
                        title: ICText(
                          AppLocalizations.of(context)!.upscaleImage,
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
                            underline: globalState.theme.bottomHighlightIcon,
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
                        labelText: AppLocalizations.of(context)!.seedOptional)),
                widget.freeGen ? Container() : const SizedBox(height: 15),
                const Padding(padding: EdgeInsets.only(top: 10)),
              ])),
            )));

    return SafeArea(
      left: false,
      top: false,
      right: false,
      bottom: true,
      child: Scaffold(
        //key: _scaffoldKey,
        backgroundColor: globalState.theme.background,
        appBar: ICAppBar(
          title: AppLocalizations.of(context)!.configureInpainting,
          actions: [
            IconButton(
                //padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.help, color: globalState.theme.menuIcons),
                onPressed: () {
                  ///open the help screen
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StableDiffusionHelp(
                            prompt: widget.prompt,
                            promptType: PromptType.inpaint),
                      ));
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
        ),
      ),
    );
  }

  _closeKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  _doNothing() {}

  _next() async {
    _closeKeyboard();
  }

  _selectModel() async {
    await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StableDiffusionModels(
            promptType: PromptType.inpaint,
            prompt: widget.prompt,
          ),
        ));

    setState(() {});
  }
}
