import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/stablediffusionai_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/stablediffusionprompt.dart';
import 'package:ironcirclesapp/screens/fullscreen/fullscreenimagefromasset.dart';
import 'package:ironcirclesapp/screens/stablediffusion/stablediffusion_model_help.dart';
import 'package:ironcirclesapp/screens/widgets/formatteddropdownobject.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class StableDiffusionModels extends StatefulWidget {
  final StableDiffusionPrompt prompt;
  final PromptType promptType;

  const StableDiffusionModels({
    Key? key,
    required this.prompt,
    required this.promptType,
  }) : super(key: key);

  @override
  _LocalState createState() {
    return _LocalState();
  }
}

class _LocalState extends State<StableDiffusionModels> {
  int _selectedIndex = 0;
  final ItemScrollController _controller = ItemScrollController();
  List<ListItem> _models = [];

  @override
  void initState() {
    if (widget.promptType == PromptType.generate) {
      _models = models;
    } else {
      _models = inpaintingModels;
    }

    _selectedIndex =
        _models.indexWhere((element) => element.object == widget.prompt.model);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.jumpTo(index: _selectedIndex);
    });

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      left: false,
      top: false,
      right: false,
      bottom: true,
      child: Scaffold(
        //key: _scaffoldKey,
        backgroundColor: globalState.theme.background,
        appBar: ICAppBar(
          title:AppLocalizations.of(context)!.selectAModel,
          actions: [
           // widget.promptType == PromptType.generate
            //    ?
            IconButton(
                    //padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.help, color: globalState.theme.menuIcons),
                    onPressed: () async {
                      ///open the help screen
                      bool? popAgain = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StableDiffusionModelHelp(
                                prompt: widget.prompt,
                                promptType: widget.promptType),
                          ));

                      if (popAgain != null && popAgain == true) {
                        Navigator.pop(context);
                      }
                    })
               // : Container()
          ],
        ),
        body: Stack(
          children: [
            Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  //mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Expanded(
                        child: ScrollablePositionedList.separated(
                            itemScrollController: _controller,
                            separatorBuilder: (context, index) {
                              return Divider(
                                height: 10,
                                color: globalState.theme.background,
                              );
                            },
                            itemCount: _models.length,
                            itemBuilder: (BuildContext context, int index) {
                              String assetPath =
                                  '${'assets/images/models/${_models[index].object}'}.webp';

                              return WrapperWidget(child: Container(
                                  color: index == _selectedIndex
                                      ? globalState.theme.button
                                      : globalState.theme.background,
                                  child: Padding(
                                      padding: const EdgeInsets.all(2),
                                      child: InkWell(
                                          onTap: () {
                                            widget.prompt.model =
                                                _models[index].object;
                                            Navigator.pop(context);
                                          },
                                          child: Row(children: [
                                            SizedBox(
                                                height: 100,
                                                width: 100,
                                                child: InkWell(
                                                    onTap: () {
                                                      Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                FullScreenImageAsset(
                                                              assetPath:
                                                                  assetPath,
                                                            ),
                                                          ));
                                                    },
                                                    child: Image.asset(
                                                        assetPath))),
                                            const Padding(
                                                padding:
                                                    EdgeInsets.only(left: 10)),
                                            Expanded(
                                                child: ICText(
                                              _models[index].name!,
                                              color:
                                                  globalState.theme.labelText,
                                              fontSize: 16,
                                            ))
                                          ])))));
                            })),
                    // const Padding(
                    //     padding:
                    //     EdgeInsets.only(top: 5)),
                    //   const Row(
                    //     children: [
                    //       Spacer(),
                    //      ICText("Try the prompt that generated these models"),
                    //     ],
                    //   ),
                    //   const Row(
                    //     children: [
                    //       Spacer(),
                    //       GradientButtonDynamic(text: "try prompt")
                    //     ],
                    //   ),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  _setPrompt() {
    widget.prompt.prompt =
        "portrait+ style, 8k portrait of beautiful cyborg with brown hair, intricate, elegant, highly detailed, majestic, digital photography, art by artgerm and ruan jia and greg rutkowski surreal painting gold butterfly filigree, broken glass, (masterpiece, sidelighting, finely detailed beautiful eyes: 1.2), hdr,";
    widget.prompt.negativePrompt =
        "canvas frame, cartoon, 3d, ((disfigured)), ((bad art)), ((deformed)),((extra limbs)),((close up)),((b&w)), weird colors, blurry, (((duplicate))), ((morbid)), ((mutilated)), [out of frame], extra fingers, mutated hands, ((poorly drawn hands)), ((poorly drawn face)), (((mutation))), (((deformed))), ((ugly)), blurry, ((bad anatomy)), (((bad proportions))), ((extra limbs)), cloned face, (((disfigured))), out of frame, ugly, extra limbs, (bad anatomy), gross proportions, (malformed limbs), ((missing arms)), ((missing legs)), (((extra arms))), (((extra legs))), mutated hands, (fused fingers), (too many fingers), (((long neck))), signature, video game, ugly, tiling, poorly drawn hands, poorly drawn feet, poorly drawn face, out of frame, mutation, mutated, extra limbs, extra legs, extra arms, disfigured, deformed, cross-eye, body out of frame, blurry, bad art, bad anatomy, 3d render";
    widget.prompt.seed = 3923809331; //1642447576;
    widget.prompt.steps = 30;
    widget.prompt.height = 512;
    widget.prompt.width = 512;
    widget.prompt.promptType = PromptType.generate;
    widget.prompt.upscale = 1;
    widget.prompt.guidance = 7;
    widget.prompt.loraOne = "";
    widget.prompt.loraTwo = "";
    widget.prompt.guidance = 1;
    widget.prompt.model = "cyberrealistic_1_3";
    widget.prompt.sampler = "dpmpp_2m_karras";

    Navigator.pop(context);
  }
}
