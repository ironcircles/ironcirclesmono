import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:ironcirclesapp/blocs/stablediffusionai_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/stablediffusionprompt.dart';
import 'package:ironcirclesapp/screens/stablediffusion/promptdetail.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';

class PromptHistory extends StatefulWidget {
  final PromptType promptType;

  const PromptHistory({
    Key? key,
    required this.promptType,
  }) : super(key: key);

  @override
  _LocalState createState() {
    return _LocalState();
  }
}

class _LocalState extends State<PromptHistory> {
  List<StableDiffusionPrompt> _prompts = [];
  final StableDiffusionAIBloc _stableDiffusionAIBloc = StableDiffusionAIBloc();

  @override
  void initState() {
    super.initState();

    _stableDiffusionAIBloc.promptHistory.listen((prompts) {
      if (mounted) {
        setState(() {
          _prompts = prompts;
        });
      }
    }, onError: (err) {
      debugPrint("CoinLedgerViewer.initState: $err");
    }, cancelOnError: false);

    _stableDiffusionAIBloc.getPromptHistory(
        globalState.user.id!, widget.promptType);
  }

  TableRow _buildTableRow(StableDiffusionPrompt prompt) {
    return TableRow(
        decoration: BoxDecoration(
            color: globalState.theme.tableBackground, border: Border.all()),
        children: [
          InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PromptDetail(
                        stableDiffusionPrompt: prompt,
                        deletePrompt: _deletePrompt,
                      ),
                    ));
              },
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: SizedBox(
                            height: 50,
                            child: Center(
                              child: Text(
                                  prompt.promptType == PromptType.generate
                                      ? AppLocalizations.of(context)!.generationLC
                                      : AppLocalizations.of(context)!.inpaintingLC,
                                  textScaler: const TextScaler.linear(1),
                                  style: TextStyle(
                                      color: globalState.theme.tableText)),
                            ))),
                    SizedBox(
                        height: 50,
                        child: Center(
                          child: Text(
                              prompt.created != null
                                  ? DateFormat.yMMMd().format(prompt.created!)
                                  : '',
                              textScaler: const TextScaler.linear(1),
                              style: TextStyle(
                                  color: globalState.theme.tableText)),
                        )),
                    SizedBox(
                        height: 50,
                        child: Center(
                            child: Row(children: [
                          Text(
                              prompt.created != null
                                  ? DateFormat.jm()
                                      .format(prompt.created!.toLocal())
                                  : '',
                              textScaler: const TextScaler.linear(1),
                              style: TextStyle(
                                  color: globalState.theme.tableText)),
                        ]))),
                    const SizedBox(
                        height: 50,
                        child: Center(
                          child: Icon(Icons.arrow_forward_ios_sharp),
                        )),
                  ]))
        ]);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        left: false,
        top: false,
        right: false,
        bottom: true,
        child:Scaffold(
      backgroundColor: globalState.theme.background,
      appBar: ICAppBar(
        title: AppLocalizations.of(context)!.promptHistory,
      ),
      body: _prompts.isEmpty
          ?  Padding(
              padding: EdgeInsets.all(10),
              child: Center(
                  child: ICText(
                    AppLocalizations.of(context)!.noPromptHistory,
                fontSize: 18,
              )))
          : SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  scrollDirection: Axis.vertical,
                  child: WrapperWidget(child:Table(
                      children: _prompts
                          .map((item) => _buildTableRow(item))
                          .toList())),
            )),
    ));
  }

  _deletePrompt(StableDiffusionPrompt prompt) {
    _stableDiffusionAIBloc.deletePrompt(prompt);
    _prompts.removeWhere((element) => element.id == prompt.id);
    setState(() {});
  }
}
