import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/stablediffusionai_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/stablediffusionprompt.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';

class PromptDetail extends StatefulWidget {
  final StableDiffusionPrompt stableDiffusionPrompt;
  final Function deletePrompt;

  const PromptDetail({
    Key? key,
    required this.stableDiffusionPrompt,
    required this.deletePrompt,
  }) : super(key: key);

  @override
  _LocalState createState() {
    return _LocalState();
  }
}

class _LocalState extends State<PromptDetail> {
  final StableDiffusionAIBloc _stableDiffusionAIBloc = StableDiffusionAIBloc();
  //final double _width = 80;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final div = Padding(
        padding: const EdgeInsets.only(top: 5, bottom: 5),
        child: Divider(
          color: globalState.theme.divider,
          height: 20,
          thickness: 1,
          indent: 0,
          endIndent: 0,
        ));

    final prompt =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ICText(
        "${AppLocalizations.of(context)!.prompt}:",
        fontWeight: FontWeight.w700,
      ),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: SelectableText(
          widget.stableDiffusionPrompt.prompt,
          textScaler: const TextScaler.linear(1.0),
          style: TextStyle(color: globalState.theme.labelText),
        ))
      ]),
      // Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      //   const Spacer(),
      //   IconButton(onPressed: () {}, icon: const Icon(Icons.copy)),
      // ]),
      div,
    ]);

    final negativePrompt =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ICText(
        "${AppLocalizations.of(context)!.negativePrompt}:",
        fontWeight: FontWeight.w700,
      ),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: SelectableText(
          widget.stableDiffusionPrompt.negativePrompt,
          textScaler: const TextScaler.linear(1.0),
          style: TextStyle(color: globalState.theme.labelText),
        ))
      ]),
      // Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      //   const Spacer(),
      //   IconButton(onPressed: () {}, icon: const Icon(Icons.copy)),
      // ]),
      div,
    ]);

    final maskPrompt =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ICText(
        "${AppLocalizations.of(context)!.maskPrompt}:",
        fontWeight: FontWeight.w700,
      ),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: SelectableText(
          widget.stableDiffusionPrompt.maskPrompt,
          textScaler: const TextScaler.linear(1.0),
          style: TextStyle(color: globalState.theme.labelText),
        ))
      ]),
      // Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      //   const Spacer(),
      //   IconButton(onPressed: () {}, icon: const Icon(Icons.copy)),
      // ]),
      div,
    ]);

    return SafeArea(
        left: false,
        top: false,
        right: false,
        bottom: true,
        child: Scaffold(
          backgroundColor: globalState.theme.background,
          appBar: ICAppBar(
            title: AppLocalizations.of(context)!.promptDetail,
          ),
          body: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                scrollDirection: Axis.vertical,
                child: WrapperWidget(child:Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    child: Column(
                      children: [
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Spacer(),
                              GradientButtonDynamic(
                                text: AppLocalizations.of(context)!.reusePrompt,
                                onPressed: () {
                                  widget.stableDiffusionPrompt.id = '';
                                  widget.stableDiffusionPrompt.jobID = '';
                                  widget.stableDiffusionPrompt.created = null;
                                  widget.stableDiffusionPrompt.seed = -1;
                                  Navigator.pop(context);
                                  Navigator.pop(
                                      context, widget.stableDiffusionPrompt);
                                },
                              ),
                              const Spacer(),
                              GradientButtonDynamic(
                                text:
                                    AppLocalizations.of(context)!.reuseWithSeed,
                                onPressed: () {
                                  widget.stableDiffusionPrompt.id = '';
                                  widget.stableDiffusionPrompt.jobID = '';
                                  widget.stableDiffusionPrompt.created = null;
                                  Navigator.pop(context);
                                  Navigator.pop(
                                      context, widget.stableDiffusionPrompt);
                                },
                              ),
                              const Spacer(),
                            ]),
                        const Padding(padding: EdgeInsets.only(top: 20)),
                        widget.stableDiffusionPrompt.maskPrompt.isNotEmpty
                            ? maskPrompt
                            : Container(),
                        prompt,
                        widget.stableDiffusionPrompt.negativePrompt.isNotEmpty
                            ? negativePrompt
                            : Container(),
                        widget.stableDiffusionPrompt.promptType ==
                                PromptType.generate
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    ICText(
                                        "${AppLocalizations.of(context)!.width}:"),
                                    const Padding(
                                      padding: EdgeInsets.only(left: 5),
                                    ),
                                    Expanded(
                                        child: ICText(widget
                                            .stableDiffusionPrompt.width
                                            .toString()))
                                  ])
                            : Container(),
                        widget.stableDiffusionPrompt.promptType ==
                                PromptType.generate
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    ICText(
                                        "${AppLocalizations.of(context)!.height}:"),
                                    const Padding(
                                      padding: EdgeInsets.only(left: 5),
                                    ),
                                    Expanded(
                                        child: ICText(widget
                                            .stableDiffusionPrompt.height
                                            .toString()))
                                  ])
                            : Container(),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ICText("${AppLocalizations.of(context)!.model}:"),
                              const Padding(
                                padding: EdgeInsets.only(left: 5),
                              ),
                              Expanded(
                                  child: SelectableText(
                                widget.stableDiffusionPrompt.model,
                                textScaler: const TextScaler.linear(1),
                              ))
                            ]),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ICText(
                                  "${AppLocalizations.of(context)!.variance}:"),
                              const Padding(
                                padding: EdgeInsets.only(left: 5),
                              ),
                              Expanded(
                                  child: ICText(widget
                                      .stableDiffusionPrompt.guidance
                                      .toString()))
                            ]),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ICText("${AppLocalizations.of(context)!.steps}:"),
                              const Padding(
                                padding: EdgeInsets.only(left: 5),
                              ),
                              Expanded(
                                  child: ICText(widget
                                      .stableDiffusionPrompt.steps
                                      .toString()))
                            ]),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ICText(
                                  "${AppLocalizations.of(context)!.sampler}:"),
                              const Padding(
                                padding: EdgeInsets.only(left: 5),
                              ),
                              Expanded(
                                  child: ICText(
                                      widget.stableDiffusionPrompt.sampler))
                            ]),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ICText(
                                  "${AppLocalizations.of(context)!.upscale}:"),
                              const Padding(
                                padding: EdgeInsets.only(left: 5),
                              ),
                              Expanded(
                                  child: ICText(widget
                                      .stableDiffusionPrompt.upscale
                                      .toString()))
                            ]),
                        widget.stableDiffusionPrompt.promptType ==
                                PromptType.generate
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    const ICText("LoRA 1:"),
                                    const Padding(
                                      padding: EdgeInsets.only(left: 5),
                                    ),
                                    Expanded(
                                        child: ICText(widget
                                            .stableDiffusionPrompt.loraOne
                                            .toString()))
                                  ])
                            : Container(),
                        widget.stableDiffusionPrompt.promptType ==
                                PromptType.generate
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    const ICText("LoRA 2:"),
                                    const Padding(
                                      padding: EdgeInsets.only(left: 5),
                                    ),
                                    Expanded(
                                        child: ICText(widget
                                            .stableDiffusionPrompt.loraTwo
                                            .toString()))
                                  ])
                            : Container(),
                        // Row(
                        //     crossAxisAlignment: CrossAxisAlignment.start,
                        //     children: [
                        //       const ICText("lora 1 strength:"),
                        //       const Padding(
                        //         padding: EdgeInsets.only(left: 5),
                        //       ),
                        //       Expanded(
                        //           child: ICText(widget
                        //               .stableDiffusionPrompt.loraOneStrength
                        //               .toString()))
                        //     ]),
                        // Row(
                        //     crossAxisAlignment: CrossAxisAlignment.start,
                        //     children: [
                        //       const ICText("lora 2 strength:"),
                        //       const Padding(
                        //         padding: EdgeInsets.only(left: 5),
                        //       ),
                        //       Expanded(
                        //           child: ICText(widget
                        //               .stableDiffusionPrompt.loraTwoStrength
                        //               .toString()))
                        //     ]),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ICText("${AppLocalizations.of(context)!.seed}:"),
                              const Padding(
                                padding: EdgeInsets.only(left: 5),
                              ),
                              Expanded(
                                  child: ICText(widget
                                      .stableDiffusionPrompt.seed
                                      .toString()))
                            ]),
                        const Padding(
                          padding: EdgeInsets.only(top: 5),
                        ),
                        div,
                        const Padding(
                          padding: EdgeInsets.only(top: 5),
                        ),
                        Row(children: [
                          Expanded(
                              child: GradientButton(
                            text: AppLocalizations.of(context)!.deletePromptUC,
                            onPressed: _askToDeletePrompt,
                          ))
                        ]),
                      ],
                    )))),
          ),
        ));
  }

  _askToDeletePrompt() {
    DialogYesNo.askYesNo(
        context,
        AppLocalizations.of(context)!.deletePrompt,
        AppLocalizations.of(context)!.deletePromptMessage,
        _deletePrompt,
        null,
        false);
  }

  _deletePrompt() {
    Navigator.pop(context);
    widget.deletePrompt(widget.stableDiffusionPrompt);
  }
}
