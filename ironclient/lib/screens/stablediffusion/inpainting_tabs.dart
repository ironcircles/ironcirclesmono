import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/stablediffusionprompt.dart';
import 'package:ironcirclesapp/screens/stablediffusion/stablediffusion_help.dart';
import 'package:ironcirclesapp/screens/stablediffusion/stablediffusion_inpainting.dart';
import 'package:ironcirclesapp/screens/stablediffusion/stablediffusion_mask.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';

class InPaintingTabs extends StatefulWidget {
  final File original;
  final UserFurnace userFurnace;
  final ImageType imageGenType;

  const InPaintingTabs({
    Key? key,
    required this.original,
    required this.userFurnace,
    required this.imageGenType,
  }) : super(key: key);

  @override
  _InPaintingTabsState createState() => _InPaintingTabsState();
}

class _InPaintingTabsState extends State<InPaintingTabs> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final int tab = 0;

  StableDiffusionPrompt textPrompt = StableDiffusionPrompt(promptType: PromptType.inpaint);
  StableDiffusionPrompt imagePrompt = StableDiffusionPrompt(promptType: PromptType.inpaint);

  late File originalText;
  late File originalImage;

  @override
  void initState() {
    super.initState();

    originalText = File.fromUri(widget.original.uri);
    originalImage = File.fromUri(widget.original.uri);
  }

  @override
  Widget build(BuildContext context) {
    final body = DefaultTabController(
        length: 2,
        initialIndex: tab,
        child: Scaffold(
            backgroundColor: globalState.theme.background,
            appBar: PreferredSize(
                preferredSize: const Size(30.0, 40.0),
                child: TabBar(
                    dividerHeight: 0.0,
                    padding: const EdgeInsets.only(left: 3, right: 3),
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorPadding:
                        const EdgeInsets.symmetric(horizontal: -10.0),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 10.0),
                    //tabAlignment: TabAlignment.start,
                    unselectedLabelColor: globalState.theme.unselectedLabel,
                    labelColor: globalState.theme.buttonIcon,
                   // isScrollable: true,
                    indicatorColor: Colors.black,
                    indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.lightBlueAccent.withOpacity(.1)),
                    tabs:  [
                      Tab(
                          child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                AppLocalizations.of(context)!.drawingUC,
                                textScaler: TextScaler.linear(1.0),
                                style: TextStyle(fontSize: 15.0),
                              ))),
                      Tab(
                          child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                AppLocalizations.of(context)!.textUC,
                                textScaler: TextScaler.linear(1.0),
                                style: TextStyle(fontSize: 15.0),
                              ))),
                    ])),
            body: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  StableDiffusionMaskWidget(
                      prompt: imagePrompt,
                      userFurnace: widget.userFurnace,
                      imageGenType: widget.imageGenType,
                      base: widget.original,
                      original: originalImage),
                  StableDiffusionInpaintingWidget(
                      prompt: textPrompt,
                      userFurnace: widget.userFurnace,
                      imageGenType: widget.imageGenType,
                      base: widget.original,
                      original: originalText),
                ])));

    return Scaffold(
        key: _scaffoldKey,
        appBar: ICAppBar(
            title: AppLocalizations.of(context)!.inpaintingTitle,
          actions: [
            IconButton(
              constraints: const BoxConstraints(),
              icon: Icon(Icons.help, color: globalState.theme.menuIcons),
              onPressed: () {
                ///open the help screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StableDiffusionHelp(
                      promptType: PromptType.inpaint
                    )
                  )
                );
              }
            )
          ]
        ),
        backgroundColor: globalState.theme.background,
        body: Padding(
            padding:
                const EdgeInsets.only(left: 10, right: 10, bottom: 5, top: 10),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(child: body),
                ])));
  }
}
