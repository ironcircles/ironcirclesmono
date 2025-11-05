import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/stablediffusionprompt.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:ironcirclesapp/utils/launchurls.dart';

class StableDiffusionHelp extends StatefulWidget {
  final PromptType promptType;
  final StableDiffusionPrompt? prompt;

  const StableDiffusionHelp({
    required this.promptType,
    this.prompt,
    Key? key,
  }) : super(key: key);

  @override
  _LocalState createState() {
    return _LocalState();
  }
}

class _LocalState extends State<StableDiffusionHelp> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 0),
        child: Scrollbar(
            controller: _scrollController,
            //thumbVisibility: true,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              controller: _scrollController,
              child:  WrapperWidget(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    widget.promptType == PromptType.generate
                        ? Container()
                        : header(AppLocalizations.of(context)!.whatIsInpainting),
                    widget.promptType == PromptType.generate
                        ? Container()
                        : detail(
                        AppLocalizations.of(context)!.inpaintingIs),
                    widget.promptType == PromptType.generate
                        ? Container()
                        : header(AppLocalizations.of(context)!.maskPrompt),
                    widget.promptType == PromptType.generate
                        ? Container()
                        : detail(AppLocalizations.of(context)!.inpaintingIsDetail),
                    header(AppLocalizations.of(context)!.prompt),
                    detail(widget.promptType == PromptType.generate
                        ? AppLocalizations.of(context)!.goodPrompt
                        : AppLocalizations.of(context)!.describeFinalImage),
                    widget.promptType == PromptType.generate
                        ?  Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Center(child: ICText(AppLocalizations.of(context)!.samplePrompt)))
                        : Container(),
                    widget.promptType == PromptType.generate
                        ? detailIndent(
                            "Imagine a serene sweeping vista of steep snow covered mountains in the distance, with the soft glow of the setting sun reflecting of the distant mountain peaks. In the foreground are cherry blossom trees with cherry blossoms gently falling to the ground next to a high mountain lake. The vibrant colors of this scene evoke a dreamlike quality. HDR, sunrays, 4k, cinematic")
                        : Container(),
                    widget.promptType == PromptType.generate
                        ? Row(
                            children: [
                              const Spacer(),
                              GradientButtonDynamic(
                                text: AppLocalizations.of(context)!.tryThisPrompt,
                                onPressed: _setPrompt,
                              ),
                            ],
                          )
                        : Container(),
                    header(AppLocalizations.of(context)!.negativePrompt),
                    detail(
                        AppLocalizations.of(context)!.negativePromptDetail),
                    header(AppLocalizations.of(context)!.model),
                    detail(
                        AppLocalizations.of(context)!.modelToUse), //. Here is a link with visuals for each model:"),
                    // Padding(
                    //     padding: const EdgeInsets.only(left: 30),
                    //     child: TextButton(
                    //         onPressed: () {
                    //           LaunchURLs.openExternalBrowserUrl(
                    //               context, 'https://ironcircles.com/models');
                    //         },
                    //         child: Text(
                    //           'www.ironcircles.com/models',
                    //           textScaler: TextScaler.linear(
                    //               globalState.labelScaleFactor),
                    //           style: const TextStyle(color: Colors.blue),
                    //         ))),
                    header( AppLocalizations.of(context)!.variance),
                    detail( AppLocalizations.of(context)!.varianceDetail),

                    header(AppLocalizations.of(context)!.upscaleImage),
                    detail(AppLocalizations.of(context)!.upscaleDetail),
                    header(AppLocalizations.of(context)!.steps),
                    detail(AppLocalizations.of(context)!.stepsDetail),
                    header(AppLocalizations.of(context)!.sampler),
                    detail(AppLocalizations.of(context)!.samplerDetail),

                    header(AppLocalizations.of(context)!.seed),
                    detail(AppLocalizations.of(context)!.seedDetail),
                    widget.promptType == PromptType.generate
                        ? header("LoRA")
                        : Container(),
                    widget.promptType == PromptType.generate
                        ? detail(AppLocalizations.of(context)!.loraDetail
                            )
                        : Container(),
                    widget.promptType == PromptType.generate
                        ? Padding(
                            padding: const EdgeInsets.only(left: 30),
                            child: TextButton(
                                onPressed: () {
                                  LaunchURLs.openExternalBrowserUrl(
                                      context, 'https://civitai.com/');
                                },
                                child: Text(
                                  'www.civitai.com',
                                  textScaler: TextScaler.linear(
                                      globalState.labelScaleFactor),
                                  style: const TextStyle(color: Colors.blue),
                                )))
                        : Container(),
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
          title: widget.promptType == PromptType.generate
              ? AppLocalizations.of(context)!.imageGenerationHelp
              : AppLocalizations.of(context)!.imageInpaintingHelp,
        ),
        body:Stack(
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

  static Widget header(String header) {
    return Padding(
        padding: const EdgeInsets.only(top: 10, right: 0, left: 10),
        child: SelectableText(
          header,
          textScaler: TextScaler.linear(globalState.dialogScaleFactor),
          style: TextStyle(fontSize: 16, color: globalState.theme.button),
        ));
  }

  static Widget detail(String detail) {
    return Padding(
        padding: const EdgeInsets.only(top: 0, right: 0, left: 10),
        child: SelectableText(
          detail,
          textScaler: TextScaler.linear(globalState.dialogScaleFactor),
          style: TextStyle(fontSize: 16, color: globalState.theme.dialogLabel),
        ));
  }

  static Widget detailIndent(String detail) {
    return Padding(
        padding: const EdgeInsets.only(top: 0, right: 40, left: 40),
        child: SelectableText(
          detail,
          textScaler: TextScaler.linear(globalState.dialogScaleFactor),
          style: TextStyle(fontSize: 16, color: globalState.theme.dialogLabel),
        ));
  }

  _closeKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  _doNothing() {}

  _next() async {
    _closeKeyboard();
  }

  _setPrompt() {
    widget.prompt!.prompt =
        "Imagine a serene sweeping vista of steep snow covered mountains in the distance, with the soft glow of the setting sun reflecting of the distant mountain peaks. In the foreground are cherry blossom trees with cherry blossoms gently falling to the ground next to a high mountain lake. The vibrant colors of this scene evoke a dreamlike quality. HDR, sunrays, 4k, cinematic";
    widget.prompt!.negativePrompt =
        "canvas frame, cartoon, 3d, ((disfigured)), ((bad art)), ((deformed)),((extra limbs)),((close up)),((b&w)), weird colors, blurry, (((duplicate))), ((morbid)), ((mutilated)), [out of frame], extra fingers, mutated hands, ((poorly drawn hands)), ((poorly drawn face)), (((mutation))), (((deformed))), ((ugly)), blurry, ((bad anatomy)), (((bad proportions))), ((extra limbs)), cloned face, (((disfigured))), out of frame, ugly, extra limbs, (bad anatomy), gross proportions, (malformed limbs), ((missing arms)), ((missing legs)), (((extra arms))), (((extra legs))), mutated hands, (fused fingers), (too many fingers), (((long neck))), signature, video game, ugly, tiling, poorly drawn hands, poorly drawn feet, poorly drawn face, out of frame, mutation, mutated, extra limbs, extra legs, extra arms, disfigured, deformed, cross-eye, body out of frame, blurry, bad art, bad anatomy, 3d render";
    widget.prompt!.seed = 3966581831; //1642447576;
    widget.prompt!.steps = 30;
    widget.prompt!.height = 512;
    widget.prompt!.width = 512;
    widget.prompt!.promptType = PromptType.generate;
    widget.prompt!.upscale = 1;
    widget.prompt!.guidance = 1;
    widget.prompt!.loraOne = "";
    widget.prompt!.loraTwo = "";
    widget.prompt!.model = "cyberrealistic_1_3";
    widget.prompt!.sampler = "dpmpp_2m_karras";

    Navigator.pop(context);
  }
}
