import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/stablediffusionprompt.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class StableDiffusionModelHelp extends StatefulWidget {
  final PromptType promptType;
  final StableDiffusionPrompt prompt;

  const StableDiffusionModelHelp({
    required this.promptType,
    required this.prompt,
    Key? key,
  }) : super(key: key);

  @override
  _LocalState createState() {
    return _LocalState();
  }
}

class _LocalState extends State<StableDiffusionModelHelp> {
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
    // final makeBottom = Padding(
    //     padding: const EdgeInsets.only(top: 0, bottom: 0),
    //     child: Row(children: <Widget>[
    //       Expanded(
    //           child: GradientButton(
    //         text: 'NEXT',
    //         onPressed: _next,
    //       )),
    //     ]));

    final makeBody = Container(
        padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 0),
        child: Scrollbar(
            controller: _scrollController,
            //thumbVisibility: true,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              controller: _scrollController,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    header(AppLocalizations.of(context)!.imageGenerationModels),
                    detail(AppLocalizations.of(context)!.whatIsAModel1
                            ),
                    const Padding(padding: EdgeInsets.only(top:10)),
                    detail(AppLocalizations.of(context)!.whatIsAModel2),
                    const Padding(padding: EdgeInsets.only(top:10)),
                    widget.promptType == PromptType.generate
                        ? detail(AppLocalizations.of(context)!.whatIsAModel3)
                        : Container(),
                    const Padding(padding: EdgeInsets.only(top:10)),
                    widget.promptType == PromptType.generate
                        ? Row(
                            children: [
                              const Spacer(),
                              GradientButtonDynamic(
                                text: AppLocalizations.of(context)!.tryPrompt,
                                onPressed: _setPrompt,
                              ),
                            ],
                          )
                        : Container(),
                  ]),
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
              ? AppLocalizations.of(context)!.imageGenerationModelsTitle
              : AppLocalizations.of(context)!.inpaintingModelsTitle,
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
    widget.prompt.prompt =
        "8k portrait of beautiful cyborg with brown hair, intricate, elegant, highly detailed, majestic, digital photography, art by artgerm and ruan jia and greg rutkowski surreal painting gold butterfly filigree, broken glass, (masterpiece, sidelighting, finely detailed beautiful eyes: 1.2), hdr,";
    widget.prompt.negativePrompt =
        "cleavage, large breasts, canvas frame, cartoon, 3d, ((disfigured)), ((bad art)), ((deformed)),((extra limbs)),((close up)),((b&w)), weird colors, blurry, (((duplicate))), ((morbid)), ((mutilated)), [out of frame], extra fingers, mutated hands, ((poorly drawn hands)), ((poorly drawn face)), (((mutation))), (((deformed))), ((ugly)), blurry, ((bad anatomy)), (((bad proportions))), ((extra limbs)), cloned face, (((disfigured))), out of frame, ugly, extra limbs, (bad anatomy), gross proportions, (malformed limbs), ((missing arms)), ((missing legs)), (((extra arms))), (((extra legs))), mutated hands, (fused fingers), (too many fingers), (((long neck))), signature, video game, ugly, tiling, poorly drawn hands, poorly drawn feet, poorly drawn face, out of frame, mutation, mutated, extra limbs, extra legs, extra arms, disfigured, deformed, cross-eye, body out of frame, blurry, bad art, bad anatomy, 3d render";
    widget.prompt.seed = 3923809331; //1642447576;
    widget.prompt.steps = 150;
    widget.prompt.height = 512;
    widget.prompt.width = 512;
    widget.prompt.promptType = PromptType.generate;
    widget.prompt.upscale = 1;
    widget.prompt.guidance = 11;
    widget.prompt.loraOne = "";
    widget.prompt.loraTwo = "";
    widget.prompt.model = "cyberrealistic_3_3";
    widget.prompt.sampler = "dpmpp_2m_karras";

    Navigator.pop(context, true);
  }
}
